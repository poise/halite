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
require 'halite/converter/libraries'

describe Halite::Converter::Libraries do
  describe '#generate_bootstrap' do
    let(:gem_data) { instance_double('Halite::Gem', license_header: '') }
    let(:entry_points) { [] }
    subject { described_class.generate_bootstrap(gem_data, entry_points) }

    context 'with defaults' do
      it { is_expected.to eq <<-EOH }
raise 'Halite is not compatible with no_lazy_load false, please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/halite_gem', __FILE__)
EOH
    end # /context with defaults

    context 'with a license header' do
      before do
        allow(gem_data).to receive(:license_header).and_return("# Copyright me.\n")
      end
      it { is_expected.to eq <<-EOH }
# Copyright me.
raise 'Halite is not compatible with no_lazy_load false, please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/halite_gem', __FILE__)
EOH
    end

    context 'with entry points' do
      let(:entry_points) { %w{mygem/one mygem/two} }
      it { is_expected.to eq <<-EOH }
raise 'Halite is not compatible with no_lazy_load false, please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/halite_gem', __FILE__)
require "mygem/one"
require "mygem/two"
EOH
    end # /context with entry points
  end # /describe #generate_bootstrap

  describe '#write_libraries' do
    let(:library_files) { [] }
    let(:gem_data) do
      instance_double('Halite::Gem').tap do |d|
        allow(d).to receive(:each_library_file) do |&block|
          library_files.each {|path| block.call(File.join('/source', path), path) }
        end
      end
    end
    subject { described_class.write_libraries(gem_data, '/test') }

    context 'with a single file' do
      let(:library_files) { %w{mygem.rb} }
      it do
        expect(FileUtils).to receive(:mkdir_p).with('/test/files/halite_gem')
        expect(FileUtils).to receive(:copy).with('/source/mygem.rb', '/test/files/halite_gem/mygem.rb', preserve: true)
        subject
      end
    end # /context with a single file

    context 'with a multiple files' do
      let(:library_files) { %w{mygem.rb mygem/one.rb mygem/two.rb} }
      it do
        expect(FileUtils).to receive(:mkdir_p).with('/test/files/halite_gem')
        expect(FileUtils).to receive(:mkdir_p).with('/test/files/halite_gem/mygem').twice
        expect(FileUtils).to receive(:copy).with('/source/mygem.rb', '/test/files/halite_gem/mygem.rb', preserve: true)
        expect(FileUtils).to receive(:copy).with('/source/mygem/one.rb', '/test/files/halite_gem/mygem/one.rb', preserve: true)
        expect(FileUtils).to receive(:copy).with('/source/mygem/two.rb', '/test/files/halite_gem/mygem/two.rb', preserve: true)
        subject
      end
    end # /context with a multiple files
  end # /describe #write_libraries

  describe '#find_default_entry_points' do
    let(:library_files) { [] }
    let(:gem_data) do
      instance_double('Halite::Gem').tap do |d|
        allow(d).to receive(:each_library_file) do |&block|
          library_files.each {|path| block.call(File.join('/source', path), path) }
        end
      end
    end
    subject { described_class.find_default_entry_points(gem_data) }

    context 'with no default entry points' do
      let(:library_files) { %w{mygem.rb} }
      it { is_expected.to eq [] }
    end # /context with no default entry points

    context 'with a single entry point' do
      let(:library_files) { %w{mygem.rb mygem/cheftie.rb} }
      it { is_expected.to eq ['mygem/cheftie'] }
    end # /context with a single entry point

    context 'with multiple entry points' do
      let(:library_files) { %w{mygem.rb mygem/cheftie.rb mygem/other.rb mygem/other/cheftie.rb} }
      it { is_expected.to eq ['mygem/cheftie', 'mygem/other/cheftie'] }
    end # /context with multiple entry points
  end # /describe #find_default_entry_points

  describe '#write_bootstrap' do
    let(:entry_point) { nil }
    let(:spec) { instance_double('Gem::Specification', metadata: {})}
    let(:gem_data) { instance_double('Halite::Gem', spec: spec) }
    let(:output) { double('output sentinel') }
    subject { described_class.write_bootstrap(gem_data, '/test', entry_point) }

    context 'with defaults' do
      it do
        expect(described_class).to receive(:find_default_entry_points).with(gem_data).and_return([])
        expect(FileUtils).to receive(:mkdir_p).with('/test/libraries')
        expect(described_class).to receive(:generate_bootstrap).with(gem_data, []).and_return(output)
        expect(IO).to receive(:write).with('/test/libraries/default.rb', output)
        subject
      end
    end # /context with defaults

    context 'with an explicit entry point' do
      let(:entry_point) { 'mygem/one' }
      it do
        expect(FileUtils).to receive(:mkdir_p).with('/test/libraries')
        expect(described_class).to receive(:generate_bootstrap).with(gem_data, ['mygem/one']).and_return(output)
        expect(IO).to receive(:write).with('/test/libraries/default.rb', output)
        subject
      end
    end # /context with an explicit entry point

    context 'with metadata entry points' do
      it do
        allow(spec).to receive(:metadata).and_return({'halite_entry_point' => 'mygem/one mygem/two'})
        expect(FileUtils).to receive(:mkdir_p).with('/test/libraries')
        expect(described_class).to receive(:generate_bootstrap).with(gem_data, ['mygem/one', 'mygem/two']).and_return(output)
        expect(IO).to receive(:write).with('/test/libraries/default.rb', output)
        subject
      end
    end # /context with metadata entry points
  end # /describe #write_bootstrap

  describe '#write' do
    it do
      expect(described_class).to receive(:write_libraries)
      expect(described_class).to receive(:write_bootstrap)
      described_class.write(nil, nil)
    end
  end # /describe #write
end
