#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'halite/error'

module Halite
  class UnknownEntryPointError < Error; end

  module Converter
    module Libraries

      # Chef doesn't allow subfolders under libraries/ currently
      def self.flatten_filename(path)
        path.gsub(/\//, '__')
      end

      def self.lib_path(path)
        if path.end_with?('.rb')
          path[0..-4]
        else
          path
        end
      end

      def self.generate(spec, data, entry_point=false)
        # No newline on the header so that line numbers in the files aren't changed.
        buf = (entry_point ? "ENV['HALITE_LOAD'] = '#{spec.name}'; begin; " : "if ENV['HALITE_LOAD'] == '#{spec.name}'; ")
        # Rewrite requires to require_relative as needed.
        spec.each_library_file do |full_path, rel_path|
          data = data.gsub(/require ['"](#{lib_path(rel_path)})['"]/) { "require_relative '#{flatten_filename($1)}'" }
        end
        spec.cookbook_dependencies.each do |dep|
          next unless dep.type == :dependencies
          # This is kind of gross, but not sure what else to do
          dep.spec.each_library_file do |full_path, rel_path|
            data = data.gsub(/require ['"]#{lib_path(rel_path)}['"]/) { "# #{$&}" }
          end
        end
        buf << data.rstrip
        # Match up with the header. All files get one line longer. ¯\_(ツ)_/¯
        buf << (entry_point ? "\nensure; ENV.delete('HALITE_LOAD'); end\n" : "\nend\n")
        buf
      end

      def self.default_entry_point(spec)
        if spec.metadata.include?('halite_entry_point')
          # Explicit default
          spec.metadata['halite_entry_point']
        else
          # Try to find a single file in the lib/ folder
          root_files = []
          spec.each_library_file do |full_path, rel_path|
            root_files << rel_path if rel_path == File.basename(rel_path)
          end
          raise UnknownEntryPointError.new("Unable to find entry point for #{spec.name}. Please set metadata['halite_entry_point'] in the gemspec.") unless root_files.length == 1
          root_files.first
        end
      end

      def self.write(spec, base_path, entry_point_name=nil)
        entry_point_name ||= default_entry_point(spec)
        # Handle both cases, with .rb and without
        entry_point_name += '.rb' unless entry_point_name.end_with?('.rb')
        lib_path = File.join(base_path, 'libraries')
        # Create cookbook's libraries folder
        Dir.mkdir(lib_path) unless File.directory?(lib_path)
        spec.each_library_file do |path, rel_path|
          IO.write(File.join(lib_path, flatten_filename(rel_path)), generate(spec, IO.read(path), entry_point_name == rel_path))
        end
      end

    end
  end
end
