module Halite
  module Dependencies
    class InvalidDependencyError < Exception; end

    def self.extract(spec)
      deps = []
      deps += extract_from_requirements(spec)
      deps += extract_from_metadata(spec)
      deps += extract_from_dependencies(spec)
      deps.map {|dep| clean(dep) }
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
      # Find any gem dependencies that are cookbooks in disguise (anything that depends directly on halite and doesn't have the ignore flag)
      spec.dependencies.select do |dep|
        dep_spec = dep.to_spec
        dep_spec.dependencies.any? {|subdep| subdep.name == 'halite'} && !dep_spec.metadata.include?('halite_ignore')
      end.map do |dep|
        [dep.name] + dep.requirements_list
      end
    end

    def self.clean(dep)
      # Convert to an array of strings
      dep = Array(dep).map {|obj| obj.to_s.strip }
      # Unpack single strings like 'foo >= 1.0'
      dep = dep.first.split(/\s+/, 2) if dep.length == 1
      # Default version constraint to match rubygems behavior when sourcing from simple strings
      dep << ::Gem::Requirement.default if dep.length == 1
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
