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

require 'chef/mixin/shell_out' # ಠ_ಠ Missing upstream require
require 'chef/recipe'
require 'chefspec/mixins/normalize' # ಠ_ಠ Missing upstream require
require 'chefspec/solo_runner'

require 'halite/error'
require 'halite/gem'


module Halite
  module SpecHelper
    # ChefSpec runner class with Halite customizations. This adds attribute
    # options, Halite synthetic cookbook injection, and block-based recipes.
    #
    # @since 1.0.0
    class Runner < ChefSpec::SoloRunner
      def self.converge(*recipe_names, &block)
        options = if recipe_names.last.is_a?(Hash)
          # Was called with options
          recipe_names.pop
        else
          {}
        end
        new(options).tap do |instance|
          instance.converge(*recipe_names, &block)
        end
      end

      def initialize(options={})
        super(options) do |node|
          # Allow inserting arbitrary attribute data in to the node
          node.attributes.default = Chef::Mixin::DeepMerge.merge(node.attributes.default, options[:default_attributes]) if options[:default_attributes]
          node.attributes.normal = Chef::Mixin::DeepMerge.merge(node.attributes.normal, options[:normal_attributes]) if options[:normal_attributes]
          node.attributes.override = Chef::Mixin::DeepMerge.merge(node.attributes.override, options[:override_attributes]) if options[:override_attributes]
          # Store the gemspec for later use
          @halite_gemspec = options[:halite_gemspec]
        end
      end

      def converge(*recipe_names, &block)
        raise Halite::Error.new('Cannot pass both recipe names and a recipe block to converge') if !recipe_names.empty? && block
        super(*recipe_names) do
          add_halite_cookbook(node, @halite_gemspec) if @halite_gemspec
          if block
            recipe = Chef::Recipe.new(nil, nil, run_context)
            recipe.instance_exec(&block)
          end
        end
      end

      private

      def add_halite_cookbook(node, gemspec)
        gem_data = Halite::Gem.new(gemspec)
        # Catch any dependency loops.
        return if run_context.cookbook_collection.include?(gem_data.cookbook_name)
        run_context.cookbook_collection[gem_data.cookbook_name] = gem_data.as_cookbook_version
        gem_data.cookbook_dependencies.each do |dep|
          add_halite_cookbook(node, dep.spec) if dep.spec
        end
        # Load attributes if any.
        gem_data.each_file('chef/attributes') do |full_path, rel_path|
          raise Halite::Error.new("Chef does not support nested attribute files: #{rel_path}") if rel_path.include?(File::SEPARATOR)
          name = File.basename(rel_path, '.rb')
          node.include_attribute("#{gem_data.cookbook_name}::#{name}")
        end
      end

      # Don't try to autodetect the calling cookbook.
      def calling_cookbook_path(kaller)
        File.expand_path('../empty', __FILE__)
      end
    end
  end
end
