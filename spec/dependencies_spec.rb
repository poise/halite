require 'spec_helper'
require 'halite/dependencies'

describe Halite::Dependencies, focus:true do
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
      it { expect { subject }.to raise_error Halite::Dependencies::InvalidDependencyError }
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
      it { expect { subject }.to raise_error Halite::Dependencies::InvalidDependencyError }
    end

    context 'with 1.2.3.4' do
      let(:version) { '1.2.3.4' }
      it { expect { subject }.to raise_error Halite::Dependencies::InvalidDependencyError }
    end

    context 'with 1.2.3' do
      let(:version) { '1.2.3' }
      it { is_expected.to eq '1.2.3' }
    end
  end # /describe #clean_version
end
