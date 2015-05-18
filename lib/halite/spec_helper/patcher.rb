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

require 'chef/resource'


module Halite
  module SpecHelper
    # Utility methods to patch a resource or provider class in to Chef for the
    # duration of a block.
    #
    # @since 1.0.0
    # @api private
    module Patcher
      # Patch a class in to Chef for the duration of a block.
      #
      # @param name [String, Symbol] Name to create in snake-case (eg. :my_name).
      # @param klass [Class] Class to patch in.
      # @param mod [Module] Optional module to create a constant in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch(name, klass, mod=nil, &block)
        patch_descendants_tracker(klass) do
          patch_node_map(name, klass) do
            patch_recipe_dsl(name, klass) do
              if mod
                patch_module(mod, name, klass, &block)
              else
                block.call
              end
            end
          end
        end
      end

      # Patch an object in to a global namespace for the duration of a block.
      #
      # @param mod [Module] Namespace to patch in to.
      # @param name [String, Symbol] Name to create in snake-case (eg. :my_name).
      # @param obj Object to patch in.
      # @param block [Proc] Block to execute while the name is available.
      # @return [void]
      def self.patch_module(mod, name, obj, &block)
        class_name = Chef::Mixin::ConvertToClassName.convert_to_class_name(name.to_s)
        if mod.const_defined?(class_name, false)
          old_class = mod.const_get(class_name, false)
          # We are only allowed to patch over things installed by patch_module
          raise "#{mod.name}::#{class_name} is already defined" if !old_class.instance_variable_get(:@poise_patch_module)
          # Remove it before setting to avoid the redefinition warning
          mod.send(:remove_const, class_name)
        end
        # Tag our objects so we know we are allowed to overwrite those, but not other stuff.
        obj.instance_variable_set(:@poise_patch_module, true)
        mod.const_set(class_name, obj)
        begin
          block.call
        ensure
          # Same as above, have to remove before set because warnings
          mod.send(:remove_const, class_name)
          mod.const_set(class_name, old_class) if old_class
        end
      end

      # Patch an object in to Chef's DescendantsTracker system for the duration
      # of a code block.
      #
      # @param klass [Class] Class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_descendants_tracker(klass, &block)
        begin
          # Re-add to tracking.
          Chef::Mixin::DescendantsTracker.store_inherited(klass.superclass, klass)
          block.call
        ensure
          # Clean up after ourselves.
          Chef::Mixin::DescendantsTracker.direct_descendants(klass.superclass).delete(klass)
        end
      end

      # Patch a class in to its node_map.
      #
      # @param name [Symbol] Name to patch in.
      # @param klass [Class] Resource class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_node_map(name, klass, &block)
        begin
          # Technically this is set to true on >=12.4, but this should work.
          klass.node_map.set(name, klass)
          block.call
        ensure
          # Sigh.
          klass.node_map.instance_variable_get(:@map).delete(name)
        end
      end

      # Patch a resource in to Chef's recipe DSL for the duration of a code
      # block. This is a no-op before Chef 12.4.
      #
      # @param name [Symbol] Name to patch in.
      # @param klass [Class] Resource class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_recipe_dsl(name, klass, &block)
        return block.call unless defined?(Chef::DSL::Resources.add_resource_dsl) && klass < Chef::Resource
        begin
          Chef::DSL::Resources.add_resource_dsl(name)
          block.call
        ensure
          Chef::DSL::Resources.remove_resource_dsl(name)
        end
      end

    end
  end
end
