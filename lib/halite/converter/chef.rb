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

require 'fileutils'


module Halite
  module Converter
    # Converter module for cookbook-specific files. These are copied verbatim
    # from the chef/ directory in the gem.
    #
    # @since 1.0.0
    # @api private
    module Chef
      # Copy all files in the chef/ directory in the gem.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @return [void]
      def self.write(gem_data, output_path)
        gem_data.each_file('chef') do |path, rel_path|
          dir_path = File.dirname(rel_path)
          FileUtils.mkdir_p(File.join(output_path, dir_path)) unless dir_path == '.'
          FileUtils.copy(path, File.join(output_path, rel_path), preserve: true)
        end
      end

    end
  end
end
