module Halite
  class Converter
    def initialize(spec, path)
      @spec = spec
      @path = path
    end

    def convert
      write_metadata
    end

    def generate_metadata
      buf = @spec.license_header
      buf << "name #{@spec.name.inspect}\n"
      buf << "version #{@spec.version.inspect}\n"
      buf
    end

    def write_metadata
      IO.write(File.join(@path, 'metadata.rb'), generate_metadata)
    end

    def generate_library_file(data, entry_point=false)
      # No newline on the header so that line numbers in the files aren't changed.
      buf = (entry_point ? "ENV['HALITE_LOAD'] = '1'; begin; " : "if ENV['HALITE_LOAD']; ")
      buf << data.gsub(/require ['"](#{@spec.name}[^'"]+)['"]/) {|match| "require_relative '#{$1.gsub(/\//, '__')}'" }.rstrip
      buf << (entry_point ? "\nensure; ENV.delete('HALITE_LOAD'); end\n" : "\nend\n")
    end
  end
end
