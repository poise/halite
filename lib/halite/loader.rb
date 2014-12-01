module Halite
  class Loader
    attr_reader :name, :version

    def initialize(name, version=nil)
      @name = name
      @version = version
    end

    def spec
      #require 'pry'; binding.pry
      @spec ||= Gem::Dependency.new(@name, Gem::Requirement.new(@version)).matching_specs.max_by { |s| s.version }
    end

    def method_missing(*args)
      spec.send(*args)
    end

    def version
      spec.version.to_s
    end
  end
end
