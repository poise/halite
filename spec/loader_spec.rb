require 'spec_helper'
require 'halite/version'

describe Halite::Loader do
  subject { described_class.new(gem_name, gem_version) }
  let(:gem_name) { 'halite' }
  let(:gem_version) { nil }

  context 'when loading halite' do
    its(:name) { is_expected.to eq 'halite' }
    its(:version) { is_expected.to eq Halite::VERSION }
    its(:description) { is_expected.to be_a String }
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
  end
end
