require 'spec_helper'
require 'halite/version'

describe Halite::Gem do
  subject { described_class.new(gem_name, gem_version) }
  let(:gem_name) { 'halite' }
  let(:gem_version) { nil }

  context 'when loading halite' do
    its(:name) { is_expected.to eq 'halite' }
    its(:version) { is_expected.to eq Halite::VERSION }
    its(:description) { is_expected.to be_a String }
    its(:files) { is_expected.to include 'halite.gemspec' }
    its(:files) { is_expected.to include 'lib/halite/gem.rb' }
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
    its(:license_header) { is_expected.to eq "# coding: utf-8\n# Awesome license\n" }
    its(:each_library_file) { is_expected.to eq [
      File.expand_path('../data/gems/test1/lib/test1.rb', __FILE__),
      File.expand_path('../data/gems/test1/lib/test1/version.rb', __FILE__),
    ] }
  end
end
