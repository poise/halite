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

describe Halite::Converter::Metadata do
  describe '#generate' do
    let(:gem_name) { 'mygem' }
    let(:cookbook_name) { gem_name }
    let(:version) { '1.0.0' }
    let(:cookbook_version) { version }
    let(:cookbook_dependencies) { [] }
    let(:gem_metadata) { {} }
    let(:spec) do
      instance_double('Gem::Specification',
        author: nil,
        authors: [],
        description: '',
        email: nil,
        homepage: nil,
        license: nil,
        licenses: [],
        metadata: gem_metadata,
      )
    end
    let(:gem_data) do
      instance_double('Halite::Gem',
        cookbook_dependencies: cookbook_dependencies.map {|dep| Halite::Dependencies::Dependency.new(*dep) },
        cookbook_name: cookbook_name,
        find_misc_path: nil,
        license_header: '',
        name: gem_name,
        spec: spec,
        version: version,
        cookbook_version: cookbook_version,
      )
    end
    subject { described_class.generate(gem_data) }

    context 'with simple data' do
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with simple data

    context 'with a license header' do
      before do
        allow(gem_data).to receive(:license_header).and_return("# header\n")
      end
      it { is_expected.to eq <<-EOH }
# header
name "mygem"
version "1.0.0"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with a license header

    context 'with one dependency' do
      let(:cookbook_dependencies) { [['other', '>= 0']] }
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
depends "other"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with one dependency

    context 'with two dependencies' do
      let(:cookbook_dependencies) { [['other', '~> 1.0'], ['another', '~> 2.0.0']] }
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
depends "other", "~> 1.0"
depends "another", "~> 2.0.0"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with two dependencies

    context 'with a description' do
      before do
        allow(spec).to receive(:description).and_return('My awesome library!')
      end

      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
description "My awesome library!"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with a description

    context 'with a readme' do
      before do
        allow(gem_data).to receive(:find_misc_path).and_return('/source/README.md')
        allow(IO).to receive(:read).with('/source/README.md').and_return("My awesome readme!\nCopyright me.\n")
      end

      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
long_description "My awesome readme!\\nCopyright me.\\n"
chef_version "~> 12" if defined?(chef_version)
EOH
    end # /context with a readme

    context 'with a chef_version' do
      let(:gem_metadata) { {'halite_chef_version' => '>= 0'} }

      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
chef_version ">= 0" if defined?(chef_version)
EOH
    end # /context with a chef_version
  end # /describe #generate

  describe '#write' do
    let(:output) { double('output sentinel') }
    before { allow(described_class).to receive(:generate).and_return(output) }

    it 'should write out metadata' do
      expect(IO).to receive(:write).with('/test/metadata.rb', output)
      described_class.write(nil, '/test')
    end
  end # /describe #write
end
