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
        @version = spec.version.to_s
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
  end
end
