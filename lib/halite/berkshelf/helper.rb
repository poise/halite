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
require 'halite/berkshelf/source'
require 'berkshelf/berksfile'
require 'berkshelf/downloader'

module Halite
  module Berkshelf

    class Helper
      def self.install(*args)
        new(*args).install
      end

      def initialize
      end

      def install

        # Switch this to use Module#prepend at some point when I stop caring about Ruby 1.9.
        ::Berkshelf::Berksfile.class_exec do
          old_sources = instance_method(:sources)
          define_method(:sources) do
            original_sources = begin
              old_sources.bind(self).()
            rescue ::Berkshelf::NoAPISourcesDefined
              # We don't care, there will be a source
              []
            end
            # Make sure we never add two halite sources.
            original_sources.reject {|s| s.is_a?(::Halite::Berkshelf::Source) } + [::Halite::Berkshelf::Source.new]
          end
        end

        # Inject support for the :halite location type
        ::Berkshelf::Downloader.class_exec do
          old_try_download = instance_method(:try_download)
          define_method(:try_download) do |source, name, version|
            remote_cookbook = source.cookbook(name, version)
            if remote_cookbook && remote_cookbook.location_type == :halite
              tmp_dir = Dir.mktmpdir
              Halite.convert(remote_cookbook.location_path, tmp_dir)
              tmp_dir
            else
              old_try_download.bind(self).()
            end
          end
        end

      end
    end

  end
end
