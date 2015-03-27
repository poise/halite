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
require 'halite/dependencies'

describe Halite::Dependencies do
  def fake_gem(name='name', version='1.0.0', &block)
    Gem::Specification.new do |s|
      s.name = name
      s.version = Gem::Version.new(version)
      block.call(s) if block
    end
  end

  let(:gem_stubs) do
    [
      fake_gem('gem1'),
      fake_gem('gem2') {|s| s.requirements << 'dep2' },
      fake_gem('gem3') {|s| s.add_dependency 'halite' },
    ]
  end

  before do
    allow(Gem::Specification).to receive(:stubs).and_return(gem_stubs)
  end

  describe '#extract_from_requirements' do
    let(:requirements) { [] }
    subject { described_class.extract_from_requirements(fake_gem {|s| s.requirements += requirements }) }

    context 'with []' do
      it { is_expected.to eq [] }
    end

    context 'with [req1]' do
      let(:requirements) { ['req1'] }
      it { is_expected.to eq ['req1'] }
    end

    context 'with [req1, req2]' do
      let(:requirements) { ['req1', 'req2'] }
      it { is_expected.to eq ['req1', 'req2'] }
    end
  end # /describe #extract_from_requirements


  describe '#extract_from_metadata' do
    let(:metadata) { nil }
    subject { described_class.extract_from_metadata(fake_gem {|s| s.metadata = {'halite_dependencies' => metadata} if metadata }) }

    context 'with no metadata' do
      it { is_expected.to eq [] }
    end

    context 'with req1' do
      let(:metadata) { 'req1' }
      it { is_expected.to eq ['req1'] }
    end

    context 'with req1,req2' do
      let(:metadata) { 'req1,req2' }
      it { is_expected.to eq ['req1', 'req2'] }
    end
  end # /describe #extract_from_metadata

  describe '#extract_from_dependencies' do
    let(:gemspec) { }
    subject { described_class.extract_from_dependencies(gemspec) }

    context 'with a halite-ish dependency' do
      let(:gemspec) { fake_gem {|s| s.add_dependency 'gem3' } }
      it { is_expected.to eq [['gem3', '>= 0', gem_stubs[2]]] }
    end

    context 'with a development dependency' do
      let(:gemspec) { fake_gem {|s| s.add_development_dependency 'gem3' } }
      it { is_expected.to eq [] }
    end

    context 'with a non-halite dependency' do
      let(:gemspec) { fake_gem {|s| s.add_development_dependency 'gem1' } }
      it { is_expected.to eq [] }
    end
  end # /describe #extract_from_dependencies

  describe '#clean' do
    let(:dependency) { nil }
    subject { described_class.clean(dependency) }
    before { allow(described_class).to receive(:clean_requirement) {|arg| arg.to_s } }

    context 'with name' do
      let(:dependency) { 'name' }
      it { is_expected.to eq ['name', '>= 0'] }
    end

    context 'with name 1.0.0' do
      let(:dependency) { 'name 1.0.0' }
      it { is_expected.to eq ['name', '1.0.0'] }
    end

    context 'with name = 1.0.0' do
      let(:dependency) { 'name = 1.0.0' }
      it { is_expected.to eq ['name', '= 1.0.0'] }
    end

    context 'with [name]' do
      let(:dependency) { ['name'] }
      it { is_expected.to eq ['name', '>= 0'] }
    end

    context 'with [name, = 1.0.0]' do
      let(:dependency) { ['name', '= 1.0.0'] }
      it { is_expected.to eq ['name', '= 1.0.0'] }
    end

    context 'with [name, = 1.0.0, = 1.0.0]' do
      let(:dependency) { ['name', '= 1.0.0', '= 1.0.0'] }
      it { expect { subject }.to raise_error Halite::InvalidDependencyError }
    end
  end # /describe #clean

  describe '#clean_requirement' do
    let(:requirement) { nil }
    subject { described_class.clean_requirement(requirement) }
    before { allow(described_class).to receive(:clean_version) {|arg| arg } }

    context 'with = 1.0.0' do
      let(:requirement) { '= 1.0.0' }
      it { is_expected.to eq '= 1.0.0' }
    end

    context 'with 1.0.0' do
      let(:requirement) { '1.0.0' }
      it { is_expected.to eq '= 1.0.0' }
    end

    context 'with =  1.0.0' do
      let(:requirement) { '=  1.0.0' }
      it { is_expected.to eq '= 1.0.0' }
    end

    context 'with =1.0.0' do
      let(:requirement) { '=1.0.0' }
      it { is_expected.to eq '= 1.0.0' }
    end

    context 'with ~> 1.0.0' do
      let(:requirement) { '~> 1.0.0' }
      it { is_expected.to eq '~> 1.0.0' }
    end

    context 'with >= 1.0.0' do
      let(:requirement) { '>= 1.0.0' }
      it { is_expected.to eq '>= 1.0.0' }
    end

    context 'with <= 1.0.0' do
      let(:requirement) { '<= 1.0.0' }
      it { is_expected.to eq '<= 1.0.0' }
    end
  end # /describe #clean_requirement

  describe '#clean_version' do
    let(:version) { nil }
    subject { described_class.clean_version(::Gem::Version.new(version)).to_s }

    context 'with 1.0.0' do
      let(:version) { '1.0.0' }
      it { is_expected.to eq '1.0.0' }
    end

    context 'with 1.0' do
      let(:version) { '1.0' }
      it { is_expected.to eq '1.0' }
    end

    context 'with 1' do
      let(:version) { '1' }
      it { is_expected.to eq '1.0' }
    end

    context 'with 0' do
      let(:version) { '0' }
      it { is_expected.to eq '0' }
    end

    context 'with 0.0' do
      let(:version) { '0.0' }
      it { is_expected.to eq '0' }
    end

    context 'with 1.0.a' do
      let(:version) { '1.0.a' }
      it { expect { subject }.to raise_error Halite::InvalidDependencyError }
    end

    context 'with 1.2.3.4' do
      let(:version) { '1.2.3.4' }
      it { expect { subject }.to raise_error Halite::InvalidDependencyError }
    end

    context 'with 1.2.3' do
      let(:version) { '1.2.3' }
      it { is_expected.to eq '1.2.3' }
    end
  end # /describe #clean_version
end
