# Much inspiration from Bundler's GemHelper. Thanks!
require 'tmpdir'
require 'thor/shell'

require 'halite'
require 'halite/error'

module Halite
  class RakeHelper
    include Rake::DSL if defined? Rake::DSL

    def self.install_tasks(*args)
      new(*args).install
    end

    attr_accessor :gem_name, :base, :cookbook_name

    def initialize(gem_name=nil, base=nil, no_gem=nil, no_foodcritic=nil, no_kitchen=nil)
      if gem_name.is_a?(Hash)
        opts = gem_name.inject({}) {|memo, (key, value)| memo[key.to_s] = value; memo }
        gem_name = opts['gem_name']
        base = opts['base']
        no_gem = opts['no_gem']
        no_foodcritic = opts['no_foodcritic']
        no_kitchen = opts['no_kitchen']
      end
      # Order is important, find_gem_name needs base to be set
      @base = base || if defined? Rake
        Rake.original_dir
      else
        Dir.pwd
      end
      @gem_name = gem_name || find_gem_name
      @gemspec = Bundler.load_gemspec(@gem_name+'.gemspec')
      @no_gem = no_gem
      @no_foodcritic = no_foodcritic
      @no_kitchen = no_kitchen
    end

    def find_gem_name
      specs = Dir[File.join(base, '*.gemspec')]
      raise Error.new("Unable to automatically determine gem name from specs in #{base}. Please set the gem name via Halite::RakeHelper.install_tasks(gem_name: 'name').") if specs.length != 1
      File.basename(specs.first, '.gemspec')
    end

    def pkg_path
      @pkg_path ||= File.join(base, 'pkg', "#{@gem_name}-#{@gemspec.version}")
    end

    def shell
      @shell ||= if @no_color || !STDOUT.tty?
        Thor::Shell::Basic
      else
        Thor::Base.shell
      end.new
    end

    def install
      # Core Halite tasks
      desc "Convert #{@gem_name}-#{@gemspec.version} to a cookbook in the pkg directory"
      task 'chef:build' do
        build_cookbook
      end

      desc "Push #{@gem_name}-#{@gemspec.version} to Supermarket"
      task 'chef:release' => ['chef:build'] do
        release_cookbook
      end

      # Patch the core gem tasks to run ours too
      if !@no_gem
        task 'build' => ['chef:build']
        task 'release' => ['chef:release']
      end

      # Foodcritic doesn't have a config file, so just always try to add it.
      if !@no_foodcritic
        install_foodcritic
      end

      # If a .kitchen.yml exists, install the Test Kitchen tasks.
      if !@no_kitchen && File.exists?(File.join(@base, '.kitchen.yml'))
        install_kitchen
      end
    end

    def install_foodcritic
      require 'foodcritic'

      desc 'Run Foodcritic linter'
      task 'chef:foodcritic' do
        Dir.mktmpdir('halite_test') do |path|
          Halite.convert(gem_name, path)
          sh("foodcritic -f any '#{path}'")
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
        sh 'kitchen test -d always'
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
      shell.say("#{@gem_name} #{@gemspec.version} converted to pkg/#{@gem_name}-#{@gemspec.version}/.", :green)
    end

    def release_cookbook
      Dir.chdir(pkg_path) do
        #sh('stove --sign')
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
