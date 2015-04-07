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
    its(:spec) { is_expected.to be_a Gem::Specification }
  end

  context 'when loading halite with a version' do
    let(:gem_version) { Halite::VERSION }
    its(:name) { is_expected.to eq 'halite' }
    its(:version) { is_expected.to eq Halite::VERSION }
    its(:spec) { is_expected.to be_a Gem::Specification }
  end

  context 'when loading rspec' do
    let(:gem_name) { 'rspec' }
    its(:name) { is_expected.to eq 'rspec' }
    its(:spec) { is_expected.to be_a Gem::Specification }
    its(:is_halite_cookbook?) { is_expected.to be_falsey }
  end

  context 'when loading test1' do
    let(:gem_name) { 'test1' }
    its(:name) { is_expected.to eq 'test1' }
    its(:version) { is_expected.to eq '1.2.3' }
    its(:cookbook_name) { is_expected.to eq 'test1' }
    its(:license_header) { is_expected.to eq "# coding: utf-8\n# Awesome license\n" }
    its(:each_library_file) { is_expected.to eq [
      [File.expand_path('../fixtures/gems/test1/lib/test1.rb', __FILE__), 'test1.rb'],
      [File.expand_path('../fixtures/gems/test1/lib/test1/version.rb', __FILE__), 'test1/version.rb'],
    ] }
    its(:cookbook_dependencies) { is_expected.to eq [] }
    its(:is_halite_cookbook?) { is_expected.to be_truthy }

    describe '#each_file' do
      context 'with no prefixes' do
        it 'returns all files' do
          expect(subject.each_file).to eq [
            [File.expand_path('../fixtures/gems/test1/Rakefile', __FILE__), 'Rakefile'],
            [File.expand_path('../fixtures/gems/test1/lib/test1.rb', __FILE__), 'lib/test1.rb'],
            [File.expand_path('../fixtures/gems/test1/lib/test1/version.rb', __FILE__), 'lib/test1/version.rb'],
            [File.expand_path('../fixtures/gems/test1/test1.gemspec', __FILE__), 'test1.gemspec'],
          ]
        end
      end

      context 'with a prefix that overlaps a filename' do
        it 'returns only files in that folder' do
          expect(subject.each_file('lib/test1')).to eq [
            [File.expand_path('../fixtures/gems/test1/lib/test1/version.rb', __FILE__), 'version.rb'],
          ]
        end
      end
    end
  end # /context when loading test1

  context 'when loading test2' do
    let(:gem_name) { 'test2' }
    its(:name) { is_expected.to eq 'test2' }
    its(:version) { is_expected.to eq '4.5.6' }
    its(:cookbook_name) { is_expected.to eq 'test2' }
    its(:license_header) { is_expected.to eq "# coding: utf-8\n" }
    its(:each_library_file) { is_expected.to eq [
      [File.expand_path('../fixtures/gems/test2/lib/test2.rb', __FILE__), 'test2.rb'],
      [File.expand_path('../fixtures/gems/test2/lib/test2/resource.rb', __FILE__), 'test2/resource.rb'],
      [File.expand_path('../fixtures/gems/test2/lib/test2/version.rb', __FILE__), 'test2/version.rb'],
    ] }
    its(:cookbook_dependencies) { is_expected.to eq [Halite::Dependencies::Dependency.new('testdep', '>= 0', :requirements)] }
    its(:is_halite_cookbook?) { is_expected.to be_truthy }

    describe '#each_file' do
      context 'with no prefixes' do
        it 'returns all files' do
          expect(subject.each_file).to eq [
            [File.expand_path('../fixtures/gems/test2/Rakefile', __FILE__), 'Rakefile'],
            [File.expand_path('../fixtures/gems/test2/chef/attributes.rb', __FILE__), 'chef/attributes.rb'],
            [File.expand_path('../fixtures/gems/test2/chef/recipes/default.rb', __FILE__), 'chef/recipes/default.rb'],
            [File.expand_path('../fixtures/gems/test2/chef/templates/default/conf.erb', __FILE__), 'chef/templates/default/conf.erb'],
            [File.expand_path('../fixtures/gems/test2/lib/test2.rb', __FILE__), 'lib/test2.rb'],
            [File.expand_path('../fixtures/gems/test2/lib/test2/resource.rb', __FILE__), 'lib/test2/resource.rb'],
            [File.expand_path('../fixtures/gems/test2/lib/test2/version.rb', __FILE__), 'lib/test2/version.rb'],
            [File.expand_path('../fixtures/gems/test2/test2.gemspec', __FILE__), 'test2.gemspec'],
          ]
        end
      end

      context 'with a prefix of chef' do
        it 'returns only files in that folder' do
          expect(subject.each_file('chef')).to eq [
            [File.expand_path('../fixtures/gems/test2/chef/attributes.rb', __FILE__), 'attributes.rb'],
            [File.expand_path('../fixtures/gems/test2/chef/recipes/default.rb', __FILE__), 'recipes/default.rb'],
            [File.expand_path('../fixtures/gems/test2/chef/templates/default/conf.erb', __FILE__), 'templates/default/conf.erb'],
          ]
        end
      end
    end
  end # /context when loading test2

  context 'when loading test3' do
    let(:gem_name) { 'test3' }
    its(:cookbook_name) { is_expected.to eq 'test3' }
    its(:cookbook_dependencies) { is_expected.to eq [Halite::Dependencies::Dependency.new('test2', '~> 4.5.6', :dependencies)] }
    its(:is_halite_cookbook?) { is_expected.to be_truthy }
  end # /context when loading test3

  describe '#cookbook_name' do
    let(:metadata) { {} }
    subject { described_class.new(Gem::Specification.new {|s| s.name = gem_name; s.metadata.update(metadata) }).cookbook_name }

    context 'with a gem named mygem' do
      let(:gem_name) { 'mygem' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem with an override' do
      let(:metadata) { {'halite_name' => 'other' } }
      it { is_expected.to eq 'other' }
    end

    context 'with a gem named chef-mygem' do
      let(:gem_name) { 'chef-mygem' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem named cookbook-mygem' do
      let(:gem_name) { 'cookbook-mygem' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem named mygem-chef' do
      let(:gem_name) { 'mygem-chef' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem named mygem-cookbook' do
      let(:gem_name) { 'mygem-cookbook' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem named chef-mygem-cookbook' do
      let(:gem_name) { 'chef-mygem-cookbook' }
      it { is_expected.to eq 'mygem' }
    end

    context 'with a gem named mycompany-mygem' do
      let(:gem_name) { 'mycompany-mygem' }
      it { is_expected.to eq 'mycompany-mygem' }
    end
  end
end
