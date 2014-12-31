# Much inspiration from Bundler's GemHelper. Thanks!
require 'halite'
require 'halite/error'

module Halite
  class RakeHelper
    include Rake::DSL if defined? Rake::DSL

    def self.install_tasks(*args)
      new(*args).install
    end

    attr_accessor :gem_name, :base, :cookbook_name

    def initialize(gem_name=nil, base=nil)
      if gem_name.is_a?(Hash)
        opts = gem_name.inject({}) {|memo, (key, value)| memo[key.to_s] = value; memo }
        gem_name = opts['gem_name']
        base = opts['base']
      end
      # Order is important, find_gem_name needs base to be set
      @base = base || if defined? Rake
        Rake.original_dir
      else
        Dir.pwd
      end
      @gem_name = gem_name || find_gem_name
    end

    def find_gem_name
      specs = Dir[File.join(base, '*.gemspec')]
      raise Error.new("Unable to automatically determine gem name from specs in #{base}. Please set the gem name via Halite::GemHelper.install_tasks(gem_name: 'name').") if specs.length != 1
      File.basename(specs.first, '.gemspec')
    end

    def install
      desc 'Convert the gem to a cookbook in the pkg directory'
      task 'build' do
        build_cookbook
      end
    end

    def build_cookbook
      # Make sure pkg/ exists and is empty
      pkg_path = File.join(base, 'pkg')
      FileUtils.mkdir_p(pkg_path)
      remove_files_in_folder(pkg_path)
      Halite.convert(gem_name, pkg_path)
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
