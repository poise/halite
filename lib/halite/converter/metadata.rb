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
    module Metadata

      def self.generate(spec)
        buf = spec.license_header
        buf << "name #{spec.cookbook_name.inspect}\n"
        buf << "version #{spec.version.inspect}\n"
        spec.cookbook_dependencies.each do |dep|
          buf << "depends #{dep.name.inspect}"
          buf << ", #{dep.requirement.inspect}" if dep.requirement != '>= 0'
          buf << "\n"
        end
        buf
      end

      def self.write(spec, base_path)
        IO.write(File.join(base_path, 'metadata.rb'), generate(spec))
      end

    end
  end
end
