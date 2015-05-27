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
  # Error class for invalid dependencies.
  #
  # @since 1.0.0
  class InvalidDependencyError < Error; end

  # Methods to extract cookbook dependencies from a gem.
  #
  # @since 1.0.0
  module Dependencies
    Dependency = Struct.new(:name, :requirement, :type, :spec) do
      def ==(other)
        self.name == other.name && \
        self.requirement == other.requirement && \
        self.type == other.type
      end

      def cookbook
        Gem.new(spec) if spec
      end
    end

    def self.extract(spec)
      deps = []
      deps += clean_and_tag(extract_from_requirements(spec), :requirements)
      deps += clean_and_tag(extract_from_metadata(spec), :metadata)
      deps += clean_and_tag(extract_from_dependencies(spec), :dependencies)
      deps
    end

    def self.extract_from_requirements(spec)
      # Simple dependencies in the requirements array.
      spec.requirements
    end

    def self.extract_from_metadata(spec)
      # This will only work on Rubygems 2.0 or higher I think, gee thats just too bad.
      # The metadata can only be a single string, so split on comma.
      spec.metadata.fetch('halite_dependencies', '').split(/,/)
    end

    def self.extract_from_dependencies(spec)
      # Find any gem dependencies that are cookbooks in disguise.
      spec.dependencies.select do |dep|
        dep.type == :runtime && Gem.new(dep).is_halite_cookbook?
      end.map do |dep|
        gem = Gem.new(dep)
        [gem.cookbook_name] + dep.requirements_list + [gem.spec]
      end
    end

    def self.clean_and_tag(deps, tag)
      deps.map do |dep|
        dep = clean(dep)
        Dependency.new(dep[0], dep[1], tag, dep[2])
      end
    end

    def self.clean(dep)
      # Convert to an array of strings, remove the spec to be re-added later.
      dep = Array(dep)
      spec = if dep.last.is_a?(::Gem::Specification)
        dep.pop
      end
      dep = Array(dep).map {|obj| obj.is_a?(::Gem::Specification) ? obj : obj.to_s.strip }
      # Unpack single strings like 'foo >= 1.0'
      dep = dep.first.split(/\s+/, 2) if dep.length == 1
      # Default version constraint to match rubygems behavior when sourcing from simple strings
      dep << '>= 0' if dep.length == 1
      raise InvalidDependencyError.new("Chef only supports a single version constraint on each dependency: #{dep}") if dep.length > 2 # ಠ_ಠ
      dep[1] = clean_requirement(dep[1])
      # Re-add the spec
      dep << spec if spec
      dep
    end

    def self.clean_requirement(req)
      req = ::Gem::Requirement.create(req)
      req.requirements[0][1] = clean_version(req.requirements[0][1])
      req.to_s
    end

    def self.clean_version(ver)
      segments = ver.segments.dup
      # Various ways Chef differs from Rubygems.
      # Strip any pre-release tags in the version.
      segments = segments.take_while {|s| s.to_s =~ /^\d+$/ }
      # Must be x or x.y or x.y.z.
      raise InvalidDependencyError.new("Chef only supports two or three version segments: #{ver}") if segments.length < 1 || segments.length > 3
      # If x, convert to x.0 because Chef requires two segments.
      segments << 0 if segments.length == 1
      # Convert 0.0 or 0.0.0 to just 0.
      segments = [0] if segments.all? {|s| s == 0 }
      ::Gem::Version.new(segments.join('.'))
    end
  end
end
