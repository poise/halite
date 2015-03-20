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
          if @halite_gemspec
            cook = Halite::Gem.new(@halite_gemspec)
            run_context.cookbook_collection[cook.cookbook_name] = cook.as_cookbook_version
          end
          if block
            recipe = Chef::Recipe.new(nil, nil, run_context)
            recipe.instance_exec(&block)
          end
        end
      end

      private

      # Don't try to autodetect
      def calling_cookbook_path(kaller)
        File.expand_path('../empty', __FILE__)
      end
    end
  end
end
