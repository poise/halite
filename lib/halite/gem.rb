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

require 'halite/dependencies'

module Halite
  class Gem
    # name can be either a string name, Gem::Dependency, or Gem::Specification
    def initialize(name, version=nil)
      name = name.to_spec if name.is_a?(::Gem::Dependency) # Allow passing either
      if name.is_a?(::Gem::Specification)
        raise Error.new("Cannot pass version when using an explicit specficiation") if version
        @spec = name
        @name = spec.name
      else
        @name = name
        @version = version
        raise Error.new("Gem #{name}#{version ? " v#{version}" : ''} not found") unless spec
      end
    end

    def spec
      @spec ||= ::Gem::Dependency.new(@name, ::Gem::Requirement.new(@version)).to_spec
    end

    def method_missing(*args)
      spec.send(*args)
    end

    def version
      spec.version.to_s
    end

    def cookbook_name
      if spec.metadata.include?('halite_name')
        spec.metadata['halite_name']
      else
        spec.name.gsub(/(^(chef|cookbook)[_-])|([_-](chef|cookbook))$/, '')
      end
    end

    # The Rubygems API is shit and just assumes the file layout
    def spec_file
      File.join(spec.full_gem_path, spec.name + '.gemspec')
    end

    def license_header
      IO.readlines(spec_file).take_while { |line| line.strip.empty? || line.strip.start_with?('#') }.join('')
    end

    def each_file(prefix_paths=nil, &block)
      files = []
      spec.files.each do |path|
        prefix = if prefix_paths
          Array(prefix_paths).map {|p| p.end_with?('/') ? p : p + '/' }.find {|p| path.start_with?(p) }
        else
          ''
        end
        next unless prefix # No match
        value = [
          File.join(spec.full_gem_path, path), # Full path
          path[prefix.length..-1], # Relative path
        ]
        files << value
        block.call(*value) if block
      end
      files.sort! # To be safe
    end

    # Special case of the above using spec's require paths
    def each_library_file(&block)
      each_file(spec.require_paths, &block)
    end

    def cookbook_dependencies
      @cookbook_dependencies ||= Dependencies.extract(spec)
    end

    # Is this gem really a cookbook? (anything that depends directly on halite and doesn't have the ignore flag)
    def is_halite_cookbook?
      spec.dependencies.any? {|subdep| subdep.name == 'halite'} && !spec.metadata.include?('halite_ignore')
    end

  end
end
