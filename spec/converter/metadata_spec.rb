require 'spec_helper'
require 'halite/converter/metadata'
require 'halite/dependencies'

describe Halite::Converter::Metadata do
  describe '#generate' do
    let(:gem_name) { 'mygem' }
    let(:version) { '1.0.0' }
    let(:license_header) { '' }
    let(:cookbook_dependencies) { [] }
    let(:spec) { double(name: gem_name, version: version, license_header: license_header, cookbook_dependencies: cookbook_dependencies.map {|dep| Halite::Dependencies::Dependency.new(*dep) }) }
    subject { described_class.generate(spec) }

    context 'with simple data' do
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
EOH
    end # /context with simple data

    context 'with a license header' do
      let(:license_header) { "# header\n" }
      it { is_expected.to eq <<-EOH }
# header
name "mygem"
version "1.0.0"
EOH
    end # /context with a license header

    context 'with one dependency' do
      let(:cookbook_dependencies) { [['other', '>= 0']] }
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
depends "other", ">= 0"
EOH
    end # /context with one dependency

    context 'with two dependencies' do
      let(:cookbook_dependencies) { [['other', '~> 1.0'], ['another', '~> 2.0.0']] }
      it { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
depends "other", "~> 1.0"
depends "another", "~> 2.0.0"
EOH
    end # /context with two dependencies
  end # /describe #generate

  describe '#write' do
    let(:output) { double('output') } # sentinel
    before { allow(described_class).to receive(:generate).and_return(output) }

    it 'should write out metadata' do
      expect(IO).to receive(:write).with('/test/metadata.rb', output)
      described_class.write(nil, '/test')
    end
  end # /describe #write
end
