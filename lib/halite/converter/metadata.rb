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
    # Converter module to create the metadata.rb for the cookbook.
    #
    # @since 1.0.0
    # @api private
    module Metadata
      # Generate a cookbook metadata file.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @return [String]
      def self.generate(gem_data)
        ''.tap do |buf|
          buf << gem_data.license_header
          buf << "name #{gem_data.cookbook_name.inspect}\n"
          buf << "version #{gem_data.cookbook_version.inspect}\n"
          if gem_data.spec.description && !gem_data.spec.description.empty?
            buf << "description #{gem_data.spec.description.inspect}\n"
          end
          if readme_path = gem_data.find_misc_path('Readme') # rubocop:disable Lint/AssignmentInCondition
            buf << "long_description #{IO.read(readme_path).inspect}\n"
          end
          buf << "maintainer #{gem_data.spec.authors.join(', ').inspect}\n" unless gem_data.spec.authors.empty?
          buf << "maintainer_email #{Array(gem_data.spec.email).join(',').inspect}\n" if gem_data.spec.email
          buf << "source_url #{gem_data.spec.homepage.inspect} if defined?(source_url)\n" if gem_data.spec.homepage
          buf << "license #{gem_data.spec.licenses.join(', ').inspect}\n" unless gem_data.spec.licenses.empty?
          gem_data.cookbook_dependencies.each do |dep|
            buf << "depends #{dep.name.inspect}"
            buf << ", #{dep.requirement.inspect}" if dep.requirement != '>= 0'
            buf << "\n"
          end
          buf << "chef_version #{(gem_data.spec.metadata['halite_chef_version'] || '~> 12').inspect} if defined?(chef_version)\n"
        end
      end

      # Write out a cookbook metadata file.
      #
      # @param gem_data [Halite::Gem] Gem to generate from.
      # @param output_path [String] Output path for the cookbook.
      # @return [void]
      def self.write(gem_data, output_path)
        IO.write(File.join(output_path, 'metadata.rb'), generate(gem_data))
      end

    end
  end
end
