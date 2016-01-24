#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# Library to convert a Ruby gem to a Chef cookbook.
#
# @since 1.0.0
# @see convert
module Halite
  autoload :Converter, 'halite/converter'
  autoload :Dependencies, 'halite/dependencies'
  autoload :Error, 'halite/error'
  autoload :Gem, 'halite/gem'
  autoload :SpecHelper, 'halite/spec_helper'
  autoload :VERSION, 'halite/version'

  # Convert a Ruby gem to a Chef cookbook.
  #
  # @param gem_name [String, Gem::Specification] Gem to convert.
  # @param base_path [String] Output path.
  # @return [void]
  # @example Converting a gem by name
  #   Halite.convert('mygem', 'dest')
  # @example Converting a gem from a loaded gemspec
  #   Halite.convert(Bundler.load_gemspec('mygem.gemspec'), 'dest')
  def self.convert(gem_name, base_path)
    gem_data = if gem_name.is_a?(Gem)
      gem_name
    else
      Gem.new(gem_name)
    end
    Converter.write(gem_data, base_path)
  end
end
