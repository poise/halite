require 'spec_helper'
require 'halite/dependencies'

describe Halite::Dependencies do
  before do
    allow(Gem::Specification).to receive(:stubs).and_return([
      Gem::Specification.new {|s| s.name = 'gem1'; s.version = Gem::Version.new('1.0.0') },
      Gem::Specification.new {|s| s.name = 'gem2'; s.version = Gem::Version.new('1.0.0'); s.requirements << 'dep2' },
    ])
  end

  describe '#extract_from_requirements' do
    let(:requirements) { [] }
    subject { described_class.extract_from_requirements(Gem::Specification.new {|s| s.name = 'name'; s.version = Gem::Version.new('1.0.0'); s.requirements += requirements }) }

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
    subject { described_class.extract_from_metadata(Gem::Specification.new {|s| s.name = 'name'; s.version = Gem::Version.new('1.0.0'); s.metadata = {'halite_dependencies' => metadata} if metadata}) }

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
      it { is_expected.to eq '0.0' }
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
