require 'spec_helper'

describe Halite::Converter::Library do

  describe '#generate' do
    let(:data) { '' }
    let(:entry_point) { false }
    subject { described_class.generate(double(name: 'mygem'), data, entry_point) }

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

  end # /describe #generate
end
