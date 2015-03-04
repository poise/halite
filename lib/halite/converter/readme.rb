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
