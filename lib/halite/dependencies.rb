require 'halite/error'

module Halite
  module Dependencies
    class InvalidDependencyError < Error; end

    Dependency = Struct.new(:name, :requirement, :type) do
      def spec
        Gem.new(name, requirement)
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
        Gem.new(dep).is_halite_cookbook?
      end.map do |dep|
        [Gem.new(dep).cookbook_name] + dep.requirements_list
      end
    end

    def self.clean_and_tag(deps, tag)
      deps.map do |dep|
        dep = clean(dep)
        Dependency.new(dep[0], dep[1], tag)
      end
    end


    def self.clean(dep)
      # Convert to an array of strings
      dep = Array(dep).map {|obj| obj.to_s.strip }
      # Unpack single strings like 'foo >= 1.0'
      dep = dep.first.split(/\s+/, 2) if dep.length == 1
      # Default version constraint to match rubygems behavior when sourcing from simple strings
      dep << '>= 0' if dep.length == 1
      raise InvalidDependencyError.new("Chef only supports a single version constraint on each dependency: #{dep}") if dep.length > 2 # ಠ_ಠ
      dep[1] = clean_requirement(dep[1])
      dep
    end

    def self.clean_requirement(req)
      req = ::Gem::Requirement.create(req)
      req.requirements[0][1] = clean_version(req.requirements[0][1])
      req.to_s
    end

    def self.clean_version(ver)
      segments = ver.segments
      # Various ways Chef differs from Rubygems
      raise InvalidDependencyError.new("Chef only supports two or three version segments: #{ver}") if segments.length < 1 || segments.length > 3
      segments.each {|s| raise InvalidDependencyError.new("Chef does not support pre-release version numbers: #{ver}") unless s.is_a?(Integer) }
      segments << 0 if segments.length == 1
      ::Gem::Version.new(segments.join('.'))
    end
  end
end
