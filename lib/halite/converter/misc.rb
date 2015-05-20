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
    # Converter module for miscellanous project-level files like README.md
    # and LICENSE.txt.
    #
    # @since 1.0.0
    # @api private
    module Misc
      # Copy miscellaneous project-level files.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @return [void]
      def self.write(gem_data, output_path)
        %w{Readme License Copying Contributing}.each do |name|
          if path = gem_data.find_misc_path(name)
            FileUtils.copy(path, File.join(output_path, File.basename(path)), preserve: true)
          end
        end
      end

    end
  end
end
