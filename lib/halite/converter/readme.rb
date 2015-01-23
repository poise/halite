module Halite
  module Converter
    module Readme

      def self.write(spec, base_path)
        readme_path = %w{README.md README README.txt readme.md readme readme.txt}.map do |name|
          File.join(spec.full_gem_path, name)
        end.find {|path| File.exists?(path) }
        if readme_path
          File.open(readme_path, 'rb') do |in_f|
            File.open(File.join(base_path, File.basename(readme_path)), 'wb') do |out_f|
              IO.copy_stream(in_f, out_f)
            end
          end
        end
      end

    end
  end
end
