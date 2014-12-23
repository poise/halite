module Halite
  module Converter
    module Metadata

      def self.generate(spec)
        buf = spec.license_header
        buf << "name #{spec.name.inspect}\n"
        buf << "version #{spec.version.inspect}\n"
        spec.cookbook_dependencies.each do |dep|
          buf << "depends #{dep.name.inspect}, #{dep.requirement.inspect}\n"
        end
        buf
      end

      def self.write(spec, base_path)
        IO.write(File.join(base_path, 'metadata.rb'), generate(spec))
      end

    end
  end
end
