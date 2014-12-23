require 'spec_helper'
require 'halite/gem'
require 'halite/version'

describe Halite::Gem do
  subject { described_class.new(gem_name, gem_version) }
  let(:gem_name) { 'halite' }
  let(:gem_version) { nil }

  context 'when loading halite' do
    its(:name) { is_expected.to eq 'halite' }
    its(:version) { is_expected.to eq Halite::VERSION }
    its(:description) { is_expected.to be_a String }
    its(:files) { is_expected.to include 'halite.gemspec' }
    its(:files) { is_expected.to include 'lib/halite/gem.rb' }
  end

  context 'when loading halite with a version' do
    let(:gem_version) { Halite::VERSION }
    its(:name) { is_expected.to eq 'halite' }
    its(:version) { is_expected.to eq Halite::VERSION }
    its(:description) { is_expected.to be_a String }
  end

  context 'when loading rspec' do
    let(:gem_name) { 'rspec' }
    its(:name) { is_expected.to eq 'rspec' }
    its(:description) { is_expected.to be_a String }
  end

  context 'when loading test1' do
    let(:gem_name) { 'test1' }
    its(:name) { is_expected.to eq 'test1' }
    its(:version) { is_expected.to eq '1.2.3' }
    its(:files) { is_expected.to include 'test1.gemspec' }
    its(:files) { is_expected.to include 'lib/test1.rb' }
    its(:license_header) { is_expected.to eq "# coding: utf-8\n# Awesome license\n" }
    its(:each_library_file) { is_expected.to eq [
      [File.expand_path('../data/gems/test1/lib/test1.rb', __FILE__), 'test1.rb'],
      [File.expand_path('../data/gems/test1/lib/test1/version.rb', __FILE__), 'test1/version.rb'],
    ] }
    its(:cookbook_dependencies) { is_expected.to eq [] }

    describe '#each_file' do
      context 'with no prefixes' do
        it 'returns all files' do
          expect(subject.each_file).to eq [
            [File.expand_path('../data/gems/test1/Rakefile', __FILE__), 'Rakefile'],
            [File.expand_path('../data/gems/test1/lib/test1.rb', __FILE__), 'lib/test1.rb'],
            [File.expand_path('../data/gems/test1/lib/test1/version.rb', __FILE__), 'lib/test1/version.rb'],
            [File.expand_path('../data/gems/test1/test1.gemspec', __FILE__), 'test1.gemspec'],
          ]
        end
      end

      context 'with a prefix that overlaps a filename' do
        it 'returns only files in that folder' do
          expect(subject.each_file('lib/test1')).to eq [
            [File.expand_path('../data/gems/test1/lib/test1/version.rb', __FILE__), 'version.rb'],
          ]
        end
      end
    end
  end # /context when loading test1

  context 'when loading test2' do
    let(:gem_name) { 'test2' }
    its(:name) { is_expected.to eq 'test2' }
    its(:version) { is_expected.to eq '4.5.6' }
    its(:files) { is_expected.to include 'test2.gemspec' }
    its(:files) { is_expected.to include 'lib/test2.rb' }
    its(:license_header) { is_expected.to eq "# coding: utf-8\n" }
    its(:each_library_file) { is_expected.to eq [
      [File.expand_path('../data/gems/test2/lib/test2.rb', __FILE__), 'test2.rb'],
      [File.expand_path('../data/gems/test2/lib/test2/resource.rb', __FILE__), 'test2/resource.rb'],
      [File.expand_path('../data/gems/test2/lib/test2/version.rb', __FILE__), 'test2/version.rb'],
    ] }
    its(:cookbook_dependencies) { is_expected.to eq [Halite::Dependencies::Dependency.new('testdep', '>= 0.0', :requirements)] }

    describe '#each_file' do
      context 'with no prefixes' do
        it 'returns all files' do
          expect(subject.each_file).to eq [
            [File.expand_path('../data/gems/test2/Rakefile', __FILE__), 'Rakefile'],
            [File.expand_path('../data/gems/test2/chef/attributes.rb', __FILE__), 'chef/attributes.rb'],
            [File.expand_path('../data/gems/test2/chef/recipes/default.rb', __FILE__), 'chef/recipes/default.rb'],
            [File.expand_path('../data/gems/test2/chef/templates/default/conf.erb', __FILE__), 'chef/templates/default/conf.erb'],
            [File.expand_path('../data/gems/test2/lib/test2.rb', __FILE__), 'lib/test2.rb'],
            [File.expand_path('../data/gems/test2/lib/test2/resource.rb', __FILE__), 'lib/test2/resource.rb'],
            [File.expand_path('../data/gems/test2/lib/test2/version.rb', __FILE__), 'lib/test2/version.rb'],
            [File.expand_path('../data/gems/test2/test2.gemspec', __FILE__), 'test2.gemspec'],
          ]
        end
      end

      context 'with a prefix of chef' do
        it 'returns only files in that folder' do
          expect(subject.each_file('chef')).to eq [
            [File.expand_path('../data/gems/test2/chef/attributes.rb', __FILE__), 'attributes.rb'],
            [File.expand_path('../data/gems/test2/chef/recipes/default.rb', __FILE__), 'recipes/default.rb'],
            [File.expand_path('../data/gems/test2/chef/templates/default/conf.erb', __FILE__), 'templates/default/conf.erb'],
          ]
        end
      end
    end
  end # /context when loading test2

  context 'when loading test3' do
    let(:gem_name) { 'test3' }
    its(:cookbook_dependencies) { is_expected.to eq [Halite::Dependencies::Dependency.new('test2', '~> 4.5.6', :dependencies)] }
  end # /context when loading test3
end
