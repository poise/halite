require 'spec_helper'

describe Halite::Converter do
  describe '#generate_metadata' do
    let(:gem_name) { 'mygem' }
    let(:version) { '1.0.0' }
    let(:license_header) { '' }
    let(:spec) { double(name: gem_name, version: version, license_header: license_header) }
    subject { described_class.new(spec, '') }

    context 'with simple data' do
      its(:generate_metadata) { is_expected.to eq <<-EOH }
name "mygem"
version "1.0.0"
EOH
    end # /context with simple data

    context 'with a license header' do
      let(:license_header) { "# header\n" }
      its(:generate_metadata) { is_expected.to eq <<-EOH }
# header
name "mygem"
version "1.0.0"
EOH
    end # /context with a license header

  end # /describe #generate_metadata

  describe '#generate_library_file' do
    let(:data) { '' }
    let(:entry_point) { false }
    subject { described_class.new(double(name: 'mygem'), '').generate_library_file(data, entry_point) }

    context 'with a single require' do
      let(:data) { "x = 1\nrequire 'mygem/version'\n" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD']; x = 1
require_relative 'mygem__version'
end
EOH
    end # /context with a single require

    context 'with two requires' do
      let(:data) { "require 'mygem/foo/bar'\nrequire 'another'" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD']; require_relative 'mygem__foo__bar'
require 'another'
end
EOH
    end # /context with two requires

    context 'with an entry point' do
      let(:data) { "x = 1\nrequire 'mygem/version'\n" }
      let(:entry_point) { true }
      it { is_expected.to eq <<-EOH }
ENV['HALITE_LOAD'] = '1'; begin; x = 1
require_relative 'mygem__version'
ensure; ENV.delete('HALITE_LOAD'); end
EOH
    end # /context with an entry point

    context 'with a big script' do
      let(:data) { <<-EOH }
require 'mygem/something'
require 'mygem/utils'
require 'activesupport' # ಠ_ಠ
class Resource
  attribute :source
end
EOH
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD']; require_relative 'mygem__something'
require_relative 'mygem__utils'
require 'activesupport' # ಠ_ಠ
class Resource
  attribute :source
end
end
EOH
    end # /context with a big script

  end # /describe #generate_library_file
end
