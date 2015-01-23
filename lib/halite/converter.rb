require 'halite/converter/libraries'
require 'halite/converter/metadata'
require 'halite/converter/other'
require 'halite/converter/readme'

module Halite
  module Converter

    def self.write(spec, base_path)
      Metadata.write(spec, base_path)
      Libraries.write(spec, base_path)
      Other.write(spec, base_path)
      Readme.write(spec, base_path)
    end

  end
end
