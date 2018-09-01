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
require 'chef/version'


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
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch(name, klass, &block)
        patch_handler_map(name, klass) do
          patch_recipe_dsl(name, klass) do
            block.call
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
        # Remove from DSL.
        Chef::DSL::Resources.remove_resource_dsl(name) if defined?(Chef::DSL::Resources.remove_resource_dsl)
        # Remove from the handler map.
        {handler: handler_map_for(klass)}.each do |type, map|
          if map
            # Make sure we add name in there too because anonymous classes don't
            # get a handler map registration by default.
            removed_keys = remove_from_node_map(map, klass) | [name.to_sym]
            # This ivar is used down in #patch_*_map to re-add the correct
            # keys based on the class definition.
            klass.instance_variable_set(:"@halite_original_#{type}_keys", removed_keys)
          end
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

      # Patch a class in to the correct handler map for the duration of a code
      # block. This is a no-op before Chef 12.4.1.
      #
      # @since 1.0.7
      # @param name [Symbol] Name to patch in.
      # @param klass [Class] Resource or provider class to patch in.
      # @param block [Proc] Block to execute while the patch is available.
      # @return [void]
      def self.patch_handler_map(name, klass, &block)
        handler_map = handler_map_for(klass)
        return block.call unless handler_map
        begin
          klass.instance_variable_get(:@halite_original_handler_keys).each do |key|
            handler_map.set(key, klass)
          end
          block.call
        ensure
          remove_from_node_map(handler_map, klass)
        end
      end

      private

      # Find the global handler map for a class.
      #
      # @since 1.0.7
      # @param klass [Class] Resource or provider class to look up.
      # @return [nil, Chef::Platform::ResourceHandlerMap, Chef::Platform::ProviderHandlerMap]
      def self.handler_map_for(klass)
        if defined?(Chef.resource_handler_map) && klass < Chef::Resource
          Chef.resource_handler_map
        elsif defined?(Chef.provider_handler_map) && klass < Chef::Provider
          Chef.provider_handler_map
        end
      end

      # Remove a value from a Chef::NodeMap. Returns the keys that were removed.
      #
      # @since 1.0.4
      # @param node_map [Chef::NodeMap] Node map to remove from.
      # @param value [Object] Value to remove.
      # @return [Array<Symbol>]
      def self.remove_from_node_map(node_map, value)
        # Chef sometime after 13.7.16 supports Chef::NodeMap#delete_class
        return node_map.delete_class(value).keys if node_map.respond_to?(:delete_class)

        # Sigh.
        removed_keys = []
        # 12.4.1+ switched this to a private accessor and lazy init.
        map = if node_map.respond_to?(:map, true)
          node_map.send(:map)
        else
          node_map.instance_variable_get(:@map)
        end
        map.each do |key, matchers|
          matchers.delete_if do |matcher|
            # in 13.7.16 the :value key in the hash was renamed to :klass
            vkey = matcher.key?(:klass) ? :klass : :value

            # In 12.4+ this value is an array of classes, before that it is the class.
            if matcher[vkey].is_a?(Array)
              matcher[vkey].include?(value)
            else
              matcher[vkey] == value
            end && removed_keys << key # Track removed keys in a hacky way.
          end
          # Clear empty matchers entirely.
          map.delete(key) if matchers.empty?
        end
        removed_keys
      end

    end
  end
end
