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
      def initialize(options={})
        # Store the gemspec for later use
        @halite_gemspec = options[:halite_gemspec]
        super
      end

      def preload!
      end

      def converge(*args, &block)
        super(*args) do |node|
          add_halite_cookbooks(node, @halite_gemspec) if @halite_gemspec
          block.call(node) if block
        end
      end

      private

      def add_halite_cookbooks(node, gemspecs)
        Array(gemspecs).each do |gemspec|
          gem_data = Halite::Gem.new(gemspec)
          # Catch any dependency loops.
          next if run_context.cookbook_collection.include?(gem_data.cookbook_name) && run_context.cookbook_collection[gem_data.cookbook_name].respond_to?(:halite_root)
          run_context.cookbook_collection[gem_data.cookbook_name] = gem_data.as_cookbook_version
          gem_data.cookbook_dependencies.each do |dep|
            add_halite_cookbooks(node, dep.spec) if dep.spec
          end
          # Add to the compiler for RunContext#unreachable_cookbook?
          cookbook_order = run_context.instance_variable_get(:@cookbook_compiler).cookbook_order
          name_sym = gem_data.cookbook_name.to_sym
          cookbook_order << name_sym unless cookbook_order.include?(name_sym)
          # Load attributes if any.
          gem_data.each_file('chef/attributes') do |_full_path, rel_path|
            raise Halite::Error.new("Chef does not support nested attribute files: #{rel_path}") if rel_path.include?(File::SEPARATOR)
            name = File.basename(rel_path, '.rb')
            node.include_attribute("#{gem_data.cookbook_name}::#{name}")
          end
        end
      end

      # Override the normal cookbook loading behavior.
      def cookbook
        if @halite_gemspec
          halite_gem = Halite::Gem.new(Array(@halite_gemspec).first)
          Chef::Cookbook::Metadata.new.tap do |metadata|
            metadata.name(halite_gem.cookbook_name)
          end
        else
          super
        end
      end

      # Don't try to autodetect the calling cookbook.
      def calling_cookbook_path(*args)
        File.expand_path('../empty', __FILE__)
      end

      # Inject a better chefspec_cookbook_root option.
      def apply_chef_config!
        super
        if @halite_gemspec
          Chef::Config[:chefspec_cookbook_root] = Array(@halite_gemspec).first.full_gem_path
        end
      end

    end
  end
end
