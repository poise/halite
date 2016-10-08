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

# Because Chef 12.0 never got a backport of https://github.com/chef/chef/commit/04ba9182cda51b79630aab2918bbc6bba2d99c23
# and requiring chef/cookbook_version below can trigger the bug if singleton
# already loaded. Remove this when dropping support for 12.0.
require 'singleton'

begin
  require 'bundler' # Pull in the bundler top-level because of missing requires.
  require 'bundler/stub_specification'
rescue LoadError
  # Bundler too old.
end
require 'chef/cookbook_version'

require 'halite/dependencies'
require 'halite/error'


module Halite
  # A model for a gem/cookbook within Halite.
  #
  # @since 1.0.0
  # @example
  #   g = Halite::Gem.new('chef-mycookbook', '1.1.0')
  #   puts(g.cookbook_name) #=> mycookbook
  class Gem
    attr_reader :name

    # name can be either a string name, Gem::Dependency, or Gem::Specification
    # @param name [String, Gem::Dependency, Gem::Specification]
    def initialize(name, version=nil)
      # Allow passing a Dependency by just grabbing its spec.
      name = dependency_to_spec(name) if name.is_a?(::Gem::Dependency)
      # Stubs don't load enough data for us, grab the real spec. RIP IOPS.
      name = name.to_spec if name.is_a?(::Gem::StubSpecification) || (defined?(Bundler::StubSpecification) && name.is_a?(Bundler::StubSpecification))
      if name.is_a?(::Gem::Specification)
        raise Error.new("Cannot pass version when using an explicit specficiation") if version
        @spec = name
        @name = spec.name
      else
        @name = name
        @version = version
        raise Error.new("Gem #{name}#{version ? " v#{version}" : ''} not found") unless spec
      end
    end

    def spec
      @spec ||= dependency_to_spec(::Gem::Dependency.new(@name, ::Gem::Requirement.new(@version)))
    end

    def version
      spec.version.to_s
    end

    def cookbook_name
      if spec.metadata.include?('halite_name')
        spec.metadata['halite_name']
      else
        spec.name.gsub(/(^(chef|cookbook)[_-])|([_-](chef|cookbook))$/, '')
      end
    end

    # Version of the gem sanitized for Chef. This means no non-numeric tags and
    # only three numeric components.
    #
    # @return [String]
    def cookbook_version
      if match = version.match(/^(\d+\.\d+\.(\d+)?)/)
        match[1]
      else
        raise Halite::Error.new("Unable to parse #{version.inspect} as a Chef cookbook version")
      end
    end

    # Path to the .gemspec for this gem. This is different from
    # Gem::Specification#spec_file because the Rubygems API is shit and just
    # assumes the file layout matches normal, which is not the case with Bundler
    # and path or git sources.
    #
    # @return [String]
    def spec_file
      File.join(spec.full_gem_path, spec.name + '.gemspec')
    end

    # License header extacted from the gemspec. Suitable for inclusion in other
    # Ruby source files.
    #
    # @return [String]
    def license_header
      IO.readlines(spec_file).take_while { |line| line.strip.empty? || line.strip.start_with?('#') }.join('')
    end

    # URL to the issue tracker for this project.
    #
    # @return [String, nil]
    def issues_url
      if spec.metadata['issues_url']
        spec.metadata['issues_url']
      elsif spec.homepage =~ /^http(s)?:\/\/(www\.)?github\.com/
        spec.homepage.chomp('/') + '/issues'
      end
    end

    # Iterate over all the files in the gem, with an optional prefix. Each
    # element in the iterable will be [full_path, relative_path], where
    # relative_path is relative to the prefix or gem path.
    #
    # @param prefix_paths [String, Array<String>, nil] Option prefix paths.
    # @param block [Proc] Callable for iteration.
    # @return [Array<Array<String>>]
    # @example
    #   gem_data.each_file do |full_path, rel_path|
    #     # ...
    #   end
    def each_file(prefix_paths=nil, &block)
      globs = if prefix_paths
        Array(prefix_paths).map {|path| File.join(spec.full_gem_path, path) }
      else
        [spec.full_gem_path]
      end
      [].tap do |files|
        globs.each do |glob|
          Dir[File.join(glob, '**', '*')].each do |path|
            next unless File.file?(path)
            val = [path, path[glob.length+1..-1]]
            block.call(*val) if block
            files << val
          end
        end
        # Make sure the order is stable for my tests. Probably overkill, I think
        # Dir#[] sorts already.
        files.sort!
      end
    end

    # Special case of the {#each_file} the gem's require paths.
    #
    # @param block [Proc] Callable for iteration.
    # @return [Array<Array<String>>]
    def each_library_file(&block)
      each_file(spec.require_paths, &block)
    end

    def cookbook_dependencies
      @cookbook_dependencies ||= Dependencies.extract_cookbooks(spec)
    end

    # List gem dependencies.
    def gem_dependencies
      @gem_dependencies ||= Dependencies.extract_gems(spec)
    end

    # Is this gem really a cookbook? (anything that depends directly on halite and doesn't have the ignore flag)
    def is_halite_cookbook?
      spec.dependencies.any? {|subdep| subdep.name == 'halite'} && !spec.metadata.include?('halite_ignore')
    end

    # Is this gem halite itself? We don't want to add this as a gem dep.
    def is_halite_gem?
      spec.name == 'halite'
    end

    # Create a Chef::CookbookVersion object that represents this gem. This can
    # be injected in to Chef to simulate the cookbook being available.
    #
    # @return [Chef::CookbookVersion]
    # @example
    #   run_context.cookbook_collection[gem.cookbook_name] = gem.as_cookbook_version
    def as_cookbook_version
      # Put this in a local variable for a closure below.
      path = spec.full_gem_path
      Chef::CookbookVersion.new(cookbook_name, File.join(path, 'chef')).tap do |c|
        c.attribute_filenames = each_file('chef/attributes').map(&:first)
        c.file_filenames = each_file('chef/files').map(&:first)
        c.recipe_filenames = each_file('chef/recipes').map(&:first)
        c.template_filenames = each_file('chef/templates').map(&:first)
        # Haxx, rewire the filevendor for this cookbook to look up in our folder.
        # This is touching two different internal interfaces, but ¯\_(ツ)_/¯
        c.send(:file_vendor).define_singleton_method(:get_filename) do |filename|
          File.join(path, 'chef', filename)
        end
        # Store the true root for use in other tools.
        c.define_singleton_method(:halite_root) { path }
      end
    end

    # Search for a file like README.md or LICENSE.txt in the gem.
    #
    # @param name [String] Basename to search for.
    # @return [String, Array<String>]
    # @example
    #   gem.misc_file('Readme') => /path/to/readme.txt
    def find_misc_path(name)
      [name, name.upcase, name.downcase].each do |base|
        ['.md', '', '.txt', '.html'].each do |suffix|
          path = File.join(spec.full_gem_path, base+suffix)
          return path if File.exist?(path) && Dir.entries(File.dirname(path)).include?(File.basename(path))
        end
      end
      # Didn't find anything
      nil
    end

    private

    # Find a spec given a dependency.
    #
    # @since 1.0.1
    # @param dep [Gem::Dependency] Dependency to solve.
    # @return [Gem::Specificiation]
    def dependency_to_spec(dep)
      # #to_spec doesn't allow prereleases unless the requirement is
      # for a prerelease. Just use the last valid spec if possible.
      spec = dep.to_spec || dep.to_specs.last
      raise Error.new("Cannot find a gem to satisfy #{dep}") unless spec
      spec
    rescue ::Gem::LoadError => ex
      raise Error.new("Cannot find a gem to satisfy #{dep}: #{ex}")
    end
  end
end
