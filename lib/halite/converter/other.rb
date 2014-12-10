module Halite
  module Converter
    module Other

      def self.write(spec, base_path)
        spec.each_file('chef') do |path, rel_path|
          dir_path = File.dirname(rel_path)
          FileUtils.mkdir_p(File.join(base_path, dir_path)) unless dir_path == '.'
          IO.open(path) do |in_f|
            IO.open(File.join(base_path, rel_path)) do |out_f|
              IO.copy_stream(in_f, out_f)
            end
          end
        end
      end

    end
  end
end
