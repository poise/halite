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
            patch_priority_map(name, klass) do
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
      end

      # Perform any post-class-creation cleanup tasks to deal with compile time
      # global registrations.
      #
      # @since 1.0.4
      # @param name [String, Symbol] Name of the class that was created in
      #   snake-case (eg. :my_name).
      # @param klass [Class] Newly created class.
      # @return [void]
      def self.post_create_cleanup(name, klass)
        # Remove from DescendantsTracker.
        Chef::Mixin::DescendantsTracker.direct_descendants(klass.superclass).delete(klass)
        # Remove from the priority maps.
        if priority_map = priority_map_for(klass)
          # Make sure we add name in there too because anonymous classes don't
          # get a priority map registration by default.
          removed_keys = remove_from_node_map(priority_map, klass) | [name.to_sym]
          # This ivar is used down in #patch_priority_map to re-add the correct
          # keys based on the class definition.
          klass.instance_variable_set(:@halite_original_priority_keys, removed_keys)
        end
        # Remove from the global node map.
        if defined?(Chef::Resource.node_map)
          removed_keys = remove_from_node_map(Chef::Resource.node_map, klass)
          # Used down in patch_node_map.
          klass.instance_variable_set(:@halite_original_nodemap_keys, removed_keys)
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

      # Patch a class in to its node_map. This is not used in 12.4+.
      #
      # @param name [Symbol] Name to patch in.
      # @param klass [Class] Resource class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_node_map(name, klass, &block)
        return block.call unless defined?(klass.node_map)
        begin
          # Technically this is set to true on >=12.4, but this should work.
          keys = klass.instance_variable_get(:@halite_original_nodemap_keys) | [name.to_sym]
          keys.each do |key|
            klass.node_map.set(key, klass)
          end
          block.call
        ensure
          remove_from_node_map(klass.node_map, klass)
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

      # Patch a class in to the correct priority map for the duration of a code
      # block. This is a no-op before Chef 12.4.
      #
      # @since 1.0.4
      # @param name [Symbol] Name to patch in.
      # @param klass [Class] Resource or provider class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_priority_map(name, klass, &block)
        priority_map = priority_map_for(klass)
        return block.call unless priority_map
        begin
          # Unlike patch_node_map, this has to be an array!
          klass.instance_variable_get(:@halite_original_priority_keys).each do |key|
            priority_map.set(key, [klass])
          end
          block.call
        ensure
          remove_from_node_map(priority_map, klass)
        end
      end

      private

      # Find the global priority map for a class.
      #
      # @since 1.0.4
      # @param klass [Class] Resource or provider class to look up.
      # @return [nil, Chef::Platform::ResourcePriorityMap, Chef::Platform::ProviderPriorityMap]
      def self.priority_map_for(klass)
        if defined?(Chef.resource_priority_map) && klass < Chef::Resource
          Chef.resource_priority_map
        elsif defined?(Chef.provider_priority_map) && klass < Chef::Provider
          Chef.provider_priority_map
        end
      end

      # Remove a value from a Chef::NodeMap. Returns the keys that were removed.
      #
      # @since 1.0.4
      # @param node_map [Chef::NodeMap] Node map to remove from.
      # @param value [Object] Value to remove.
      # @return [Array<Symbol>]
      def self.remove_from_node_map(node_map, value)
        # Sigh.
        removed_keys = []
        # 12.4.1+ switched this to a private accessor and lazy init.
        map = if node_map.respond_to?(:map)
          node_map.send(:map)
        else
          node_map.instance_variable_get(:@map)
        end
        map.each do |key, matchers|
          matchers.delete_if do |matcher|
            # In 12.4+ this value is an array of classes, before that it is the class.
            if matcher[:value].is_a?(Array)
              matcher[:value].include?(value)
            else
              matcher[:value] == value
            end && removed_keys << key # Track removed keys in a hacky way.
          end
        end
        removed_keys
      end

    end
  end
end
