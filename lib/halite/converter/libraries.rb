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

require 'fileutils'


module Halite
  module Converter
    # Converter methods for gem library code (ex. files under lib/).
    #
    # @since 1.0.0
    # @api private
    module Libraries
      # Generate the bootstrap code for the Chef cookbook.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param entry_points [Array<String>] Zero or more entry points to be
      #   automatically loaded.
      # @return [String]
      def self.generate_bootstrap(gem_data, entry_points)
        ''.tap do |buf|
          buf << gem_data.license_header
          buf << <<-EOH
raise 'Halite is not compatible with no_lazy_load false, please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/halite_gem', __FILE__)
EOH
          entry_points.each do |entry_point|
            buf << "require #{entry_point.inspect}\n"
          end
        end
      end

      # Copy all library code to the files/halite_gem/ directory in the cookbook.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @return [void]
      def self.write_libraries(gem_data, output_path)
        dest_path = File.join(output_path, 'files', 'halite_gem')
        FileUtils.mkdir_p(dest_path)
        gem_data.each_library_file do |path, rel_path|
          dir_path = File.dirname(rel_path)
          FileUtils.mkdir_p(File.join(dest_path, dir_path)) unless dir_path == '.'
          FileUtils.copy(path, File.join(dest_path, rel_path), preserve: true)
        end
      end

      # Find any default entry points (files name cheftie.rb) in the gem.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @return [Array<String>]
      def self.find_default_entry_points(gem_data)
        [].tap do |entry_points|
          gem_data.each_library_file do |path, rel_path|
            if File.basename(rel_path) == 'cheftie.rb'
              # Trim the .rb for cleanliness.
              entry_points << rel_path[0..-4]
            end
          end
        end
      end

      # Create the bootstrap code in the cookbook.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @param entry_point [String, Array<String>] Entry point(s) for the
      #   bootstrap. These are require paths that will be loaded automatically
      #   during a Chef converge.
      # @return [void]
      def self.write_bootstrap(gem_data, output_path, entry_point=nil)
        # Default entry point.
        entry_point ||= gem_data.spec.metadata['halite_entry_point'] || find_default_entry_points(gem_data)
        # Parse and cast.
        entry_point = Array(entry_point).map {|s| s.split }.flatten
        # Write bootstrap file.
        lib_path = File.join(output_path, 'libraries')
        FileUtils.mkdir_p(lib_path)
        IO.write(File.join(lib_path, 'default.rb'), generate_bootstrap(gem_data, entry_point))
      end

      # Write out the library code for the cookbook.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @return [void]
      def self.write(gem_data, output_path, entry_point=nil)
        write_libraries(gem_data, output_path)
        write_bootstrap(gem_data, output_path, entry_point)
      end

    end
  end
end
