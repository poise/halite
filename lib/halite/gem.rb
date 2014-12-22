module Halite
  class Gem
    def initialize(name, version=nil)
      @name = name
      @version = version
      raise "Gem #{name}#{version ? " v#{version}" : ''} not found" unless spec
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
      files
    end

    # Special case of the above using spec's require paths
    def each_library_file(&block)
      each_file(spec.require_paths, &block)
    end

    def cookbook_dependencies
      deps = []
      # Find any simple dependencies
      deps += spec.requirements
      # Fine any dependencies in the metadata, must be a string so split on comma
      deps += spec.metadata['halite_dependencies'].split(/,/) if spec.metadata.include?('halite_dependencies')
      # Find any gem dependencies (anything that depends directly on halite and doesn't have the ignore flag)
      deps += spec.dependencies.select do |dep|
        dep_spec = dep.to_spec
        dep_spec.dependencies.any? {|subspec| subspec.name == 'halite'} && !dep_spec.metadata.include?('halite_ignore')
      end.map {|dep| [dep.name] + dep.requirements_list}
      # Convert all deps to [[name, version], ...] format
      deps.map do |dep|
        dep = Array(dep).map {|obj| obj.to_s.strip }
        dep = dep.first.split(/\s+/, 2) if dep.length == 1 # Unpack single strings like 'foo >= 1.0'
        dep << ::Gem::Requirement.default.to_s if dep.length == 1 # Default version constraint to match rubygems behavior when sourcing from simple strings
        raise "Chef only supports a single version constraint on each dependency" if dep.length > 2 # ಠ_ಠ
        dep
      end
    end
  end
end
