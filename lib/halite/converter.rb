require 'halite/converter/library'
require 'halite/converter/metadata'

module Halite
  module Converter

    def self.write(spec, base_path)
      Metadata.write(spec, base_path)
      Library.write(spec, base_path)
    end

  end
end
