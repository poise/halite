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

require 'tmpdir'

require 'chef/version'

require 'halite'
require 'halite/error'
require 'halite/helper_base'


module Halite
  # Helper class to install Halite rake tasks.
  #
  # @since 1.0.0
  # @example Rakefile
  #   require 'halite/rake_helper'
  #   Halite::RakeHelper.install
  class RakeHelper < HelperBase
    # Install all Rake tasks.
    #
    # @return [void]
    def install
      extend Rake::DSL
      # Core Halite tasks
      unless options[:no_gem]
        desc "Convert #{gemspec.name}-#{gemspec.version} to a cookbook in the pkg directory"
        task 'chef:build' do
          build_cookbook
        end

        desc "Push #{gemspec.name}-#{gemspec.version} to Supermarket"
        task 'chef:release' => ['chef:build'] do
          release_cookbook(pkg_path)
        end

        # Patch the core gem tasks to run ours too
        task 'build' => ['chef:build']
        task 'release' => ['chef:release']
      else
        desc "Push #{gem_name} to Supermarket"
        task 'chef:release' do
          release_cookbook(base)
        end
      end

      # Foodcritic doesn't have a config file, so just always try to add it.
      unless options[:no_foodcritic]
        install_foodcritic
      end

      # If a .kitchen.yml exists, install the Test Kitchen tasks.
      unless options[:no_kitchen] || !File.exist?(File.join(@base, '.kitchen.yml'))
        install_kitchen
      end
    end

    private

    def pkg_path
      @pkg_path ||= File.join(base, 'pkg', "#{gemspec.name}-#{gemspec.version}")
    end

    def install_foodcritic
      require 'foodcritic'

      desc 'Run Foodcritic linter'
      task 'chef:foodcritic' do
        foodcritic_cmd = "foodcritic --chef-version #{Chef::VERSION} --epic-fail any --tags ~FC054 '%{path}'"
        if options[:no_gem]
          sh(foodcritic_cmd % {path: base})
        else
          Dir.mktmpdir('halite_test') do |path|
            Halite.convert(gemspec, path)
            sh(foodcritic_cmd % {path: path})
          end
        end
      end

      add_test_task('chef:foodcritic')
    rescue LoadError
      task 'chef:foodcritic' do
        raise "Foodcritic is not available. You can use Halite::RakeHelper.install_tasks(no_foodcritic: true) to disable it."
      end
    end

    def install_kitchen
      desc 'Run all Test Kitchen tests'
      task 'chef:kitchen' do
        sh(*%w{kitchen test -d always})
      end

      add_test_task('chef:kitchen')
    end

    def add_test_task(name)
      # Only set a description if the task doesn't already exist
      desc 'Run all tests' unless Rake.application.lookup('test')
      task :test => [name]
    end

    def build_cookbook
      # Make sure pkg/name-version exists and is empty
      FileUtils.mkdir_p(pkg_path)
      remove_files_in_folder(pkg_path)
      Halite.convert(gem_name, pkg_path)
      shell.say("#{gemspec.name} #{gemspec.version} converted to pkg/#{gemspec.name}-#{gemspec.version}/.", :green)
    end

    def release_cookbook(path)
      Dir.chdir(path) do
        sh('stove --no-git')
        shell.say("Pushed #{gemspec.name} #{gemspec.version} to supermarket.chef.io.", :green) unless options[:no_gem]
      end
    end

    # Remove everything in a path, but not the directory itself
    def remove_files_in_folder(base_path)
      existing_files = Dir.glob(File.join(base_path, '**', '*'), File::FNM_DOTMATCH).map {|path| File.expand_path(path)}.uniq.reverse # expand_path just to normalize foo/. -> foo
      existing_files.delete(base_path) # Don't remove the base
      # Fuck FileUtils, it is a confusing pile of fail for remove*/rm*
      existing_files.each do |path|
        if File.file?(path)
          File.unlink(path)
        elsif File.directory?(path)
          Dir.unlink(path)
        else
          # Because paranoia
          raise Error.new("Unknown type of file at '#{path}', possible symlink deletion attack")
        end
      end
    end
  end
end
