require 'spec_helper'

describe Halite::Converter do
  describe '#generate_metadata' do
    let(:gem_name) { 'mygem' }
    let(:version) { '1.0.0' }
    let(:license_header) { '' }
    let(:spec) { double(name: gem_name, version: version, license_header: license_header) }
    subject { described_class.new(spec, '') }

    context 'with simple data' do
      its(:generate_metadata) do
        is_expected.to eq <<-EOH
name "mygem"
version "1.0.0"
EOH
      end
    end # /context with simple data

    context 'with a license header' do
      let(:license_header) { "# header\n" }
      its(:generate_metadata) do
        is_expected.to eq <<-EOH
# header
name "mygem"
version "1.0.0"
EOH
      end
    end # /context with a license header

  end # /describe #generate_metadata

  describe '#generate_library_file' do
    let(:data) { '' }
    let(:entry_point) { false }
    subject { described_class.new(double(name: 'mygem'), '').generate_library_file(data, entry_point) }

    context 'something' do
      let(:data) { "x = 1\nrequire 'mygem/version'\n" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD']; x = 1
require_relative 'mygem__version'
end
EOH
    end

    context 'else' do
      let(:data) { "require 'mygem/foo/bar'\nrequire 'another'" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD']; require_relative 'mygem__foo__bar'
require 'another'
end
EOH
    end

  end # /describe #generate_library_file
end
