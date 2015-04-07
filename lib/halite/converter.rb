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


module Halite
  # (see Converter.write)
  module Converter
    autoload :Chef, 'halite/converter/chef'
    autoload :Libraries, 'halite/converter/libraries'
    autoload :Metadata, 'halite/converter/metadata'
    autoload :Misc, 'halite/converter/misc'

    # Convert a cookbook gem to a normal Chef cookbook.
    #
    # @since 1.0.0
    # @param gem_data [Halite::Gem] Gem to convert.
    # @param output_path [String] Output path.
    # @return [void]
    # @example
    #   Halite::Converter.write(Halite::Gem.new(gemspec), 'dest')
    def self.write(gem_data, output_path)
      Chef.write(gem_data, output_path)
      Libraries.write(gem_data, output_path)
      Metadata.write(gem_data, output_path)
      Misc.write(gem_data, output_path)
    end
  end
end
