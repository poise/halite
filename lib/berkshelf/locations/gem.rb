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

require 'halite'

module Berkshelf
  class GemLocation < BaseLocation
    attr_reader :gem_name

    def initialize(*args)
      super
      @gem_name = options[:gem]
    end


    # Always force the re-install.
    #
    # @see BaseLocation#installed?
    def installed?
      false
    end

    # Convert the gem.
    #
    # @see BaseLocation#install
    def install
      cache_path.rmtree if cache_path.exist?
      cache_path.mkpath
      Halite.convert(gem_name, cache_path)
      validate_cached!(cache_path)
    end

    # @see BaseLocation#cached_cookbook
    def cached_cookbook
      if cache_path.join('metadata.rb').exist?
        @cached_cookbook ||= CachedCookbook.from_path(cache_path)
      else
        nil
      end
    end

    # @see BaseLocation#to_lock
    def to_lock
      "    gem: #{gem_name}\n"
    end

    def ==(other)
      other.is_a?(GemLocation) && other.gem_name == gem_name
    end

    def to_s
      "gem from #{gem_name}"
    end

    def inspect
      "#<Berkshelf::GemLocation gem: #{gem_name}>"
    end

    # The path to the converted gem.
    #
    # @return [Pathname]
    def cache_path
      @cache_path ||= Pathname.new(Berkshelf.berkshelf_path).join('.cache', 'halite', dependency.name)
    end
  end
end
