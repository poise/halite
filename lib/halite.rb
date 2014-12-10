require 'logify'

require 'halite/converter'
require 'halite/gem'

module Halite
  include Logify

  def self.convert(gem_name, base_path)
    Converter.write(Gem.new(gem_name), base_path)
  end
end
