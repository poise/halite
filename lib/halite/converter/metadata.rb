module Halite
  module Converter
    module Metadata

      def self.generate(spec)
        buf = spec.license_header
        buf << "name #{spec.name.inspect}\n"
        buf << "version #{spec.version.inspect}\n"
        buf
      end

      def self.write(spec, base_path)
        IO.write(File.join(base_path, 'metadata.rb'), generate_metadata(spec))
      end

    end
  end
end
