module Halite
  class Loader
    def initialize(name, version=nil)
      @name = name
      @version = version
    end

    def spec
      @spec ||= Gem::Dependency.new(@name, Gem::Requirement.new(@version)).matching_specs.max_by { |s| s.version }
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
  end
end
