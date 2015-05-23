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

require 'halite/gem'
require 'berkshelf/source'
require 'berkshelf/api_client/remote_cookbook'


module Halite
  module Berkshelf
    # Berkshelf global source to find all Halite cookbooks in the current
    # gems environment.
    #
    # @since 1.0.0
    # @api private
    class Source < ::Berkshelf::Source
      def initialize
        # Pretend our URL is set even though it isn't used. Otherwise berks
        # complains.
        super 'https://supermarket.chef.io'
      end

      def build_universe
        # Scan all gems
        ::Gem::Specification.stubs.map do |spec|
          Gem.new(spec)
        end.select do |cook|
          cook.is_halite_cookbook?
        end.map do |cook|
          # Build a fake "remote" cookbook
          ::Berkshelf::APIClient::RemoteCookbook.new(
            cook.cookbook_name,
            cook.cookbook_version,
            {
              location_type: 'halite',
              location_path: cook.name,
              dependencies: cook.cookbook_dependencies.inject({}) {|memo, dep| memo[dep.name] = dep.requirement; memo },
            },
          )
        end
      end

      # Show "... from Halite gems" when installing.
      def to_s
        "Halite gems"
      end
      alias :uri :to_s
    end

  end
end
