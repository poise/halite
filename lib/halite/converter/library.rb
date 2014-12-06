module Halite
  module Converter
    module Library

      def self.generate(spec, data, entry_point=false)
        # No newline on the header so that line numbers in the files aren't changed.
        buf = (entry_point ? "ENV['HALITE_LOAD'] = '1'; begin; " : "if ENV['HALITE_LOAD']; ")
        buf << data.gsub(/require ['"](#{spec.name}[^'"]+)['"]/) {|match| "require_relative '#{$1.gsub(/\//, '__')}'" }.rstrip
        buf << (entry_point ? "\nensure; ENV.delete('HALITE_LOAD'); end\n" : "\nend\n")
        buf
      end

      def self.write(spec, base_path, entry_point_name=nil)

      end

    end
  end
end
