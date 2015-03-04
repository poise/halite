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

  describe '#lib_path' do
    let(:path) { }
    subject { described_class.lib_path(path) }

    context 'with foo.rb' do
      let(:path) { 'foo.rb' }
      it { is_expected.to eq 'foo' }
    end # /context with foo.rb

    context 'with foo' do
      let(:path) { 'foo' }
      it { is_expected.to eq 'foo' }
    end # /context with foo

    context 'with foo/bar.rb' do
      let(:path) { 'foo/bar.rb' }
      it { is_expected.to eq 'foo/bar' }
    end # /context with foo/bar.rb
  end # /describe #lib_path

  describe '#generate' do
    let(:data) { '' }
    let(:entry_point) { false }
    let(:cookbook_dependencies) { [] }
    let(:cookbook_files) { %w{mygem.rb mygem/version.rb mygem/something.rb mygem/utils.rb mygem/foo/bar.rb} }
    subject do
      deps = cookbook_dependencies.map do |dep|
        dep_spec = double(name: dep)
        allow(dep_spec).to receive(:each_library_file).and_yield("lib/#{dep}.rb", "#{dep}.rb")
        double(name: dep, requirement: nil, type: :dependencies, spec: double(), cookbook: dep_spec)
      end
      spec = double(name: 'mygem', cookbook_dependencies: deps)
      allow(spec).to receive(:each_library_file) do |&block|
        cookbook_files.each do |path|
          block.call("lib/#{path}", path)
        end
      end
      described_class.generate(spec, data, entry_point)
    end

    context 'with a single require' do
      let(:data) { "x = 1\nrequire 'mygem/version'\n" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD'] == 'mygem'; x = 1
require_relative 'mygem__version'
end
EOH
    end # /context with a single require

    context 'with two requires' do
      let(:data) { "require 'mygem/foo/bar'\nrequire 'another'" }
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD'] == 'mygem'; require_relative 'mygem__foo__bar'
require 'another'
end
EOH
    end # /context with two requires

    context 'with an entry point' do
      let(:data) { "x = 1\nrequire 'mygem/version'\n" }
      let(:entry_point) { true }
      it { is_expected.to eq <<-EOH }
ENV['HALITE_LOAD'] = 'mygem'; begin; x = 1
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
if ENV['HALITE_LOAD'] == 'mygem'; require_relative 'mygem__something'
require_relative 'mygem__utils'
require 'activesupport' # ಠ_ಠ
class Resource
  attribute :source
end
end
EOH
    end # /context with a big script

    context 'with external dependencies' do
      let(:cookbook_dependencies) { ['other'] }
      let(:data) { <<-EOH }
require 'mygem/something'
require 'mygem/utils'
require "mygem"
require 'other'
class Resource
  attribute :source
end
EOH
      it { is_expected.to eq <<-EOH }
if ENV['HALITE_LOAD'] == 'mygem'; require_relative 'mygem__something'
require_relative 'mygem__utils'
require_relative 'mygem'
# require 'other'
class Resource
  attribute :source
end
end
EOH
    end # /context with a big script
  end # /describe #generate

  describe '#default_entry_point' do
    let(:library_files) { [] }
    let(:spec) do
      spec = double(name: 'mygem', metadata: {})
      allow(spec).to receive(:each_library_file) do |&block|
        library_files.each {|path| block.call(File.join('lib', path), path) }
      end
      spec
    end
    subject { described_class.default_entry_point(spec) }

    context 'with an explicit entry point' do
      let(:spec) { double(metadata: {'halite_entry_point' => 'openseasame'}) }
      it { is_expected.to eq 'openseasame' }
    end # /context with an explicit entry point

    context 'with a single top-level file' do
      let(:library_files) { %w{mygem.rb mygem/version.rb} }
      it { is_expected.to eq 'mygem.rb' }
    end # /context with a single top-level file

    context 'with two top-level files' do
      let(:library_files) { %w{my-gem.rb my_gem.rb my_gem/version.rb} }
      it { expect { subject }.to raise_error Halite::UnknownEntryPointError }
    end # /context with two top-level files

    context 'with no files' do
      it { expect { subject }.to raise_error Halite::UnknownEntryPointError }
    end # /context with no files
  end # /describe #default_entry_point

  describe '#write' do
    let(:library_files) { [] }
    let(:output) { [] }
    let(:spec) do
      spec = double(name: 'mygem')
      allow(spec).to receive(:each_library_file) do |&block|
        library_files.each {|path| block.call(File.join('/source', path), path) }
      end
      spec
    end
    before do
      first = true
      library_files.each do |path|
        input_sentinel = double("content of #{path}")
        output_sentinel = double("generated output for #{path}")
        allow(IO).to receive(:read).with(File.join('/source', path)).and_return(input_sentinel)
        allow(described_class).to receive(:generate).with(spec, input_sentinel, first).and_return(output_sentinel)
        first = false
        output << output_sentinel
      end
      allow(File).to receive(:directory?).and_return(false) # Always blank
      allow(described_class).to receive(:default_entry_point).and_return(library_files.first) # As above, first is always the entry point
    end

    context 'with a single file' do
      let(:library_files) { ['mygem.rb'] }

      it 'writes a single file' do
        expect(Dir).to receive(:mkdir).with('/test/libraries')
        expect(IO).to receive(:write).with('/test/libraries/mygem.rb', output[0])
        described_class.write(spec, '/test')
      end
    end # /context with a single file

    context 'with multiple files' do
      let(:library_files) { ['mygem.rb', 'mygem/one.rb', 'mygem/two.rb'] }

      it 'writes multiple files' do
        expect(Dir).to receive(:mkdir).with('/test/libraries')
        expect(IO).to receive(:write).with('/test/libraries/mygem.rb', output[0])
        expect(IO).to receive(:write).with('/test/libraries/mygem__one.rb', output[1])
        expect(IO).to receive(:write).with('/test/libraries/mygem__two.rb', output[2])
        described_class.write(spec, '/test')
      end
    end # /context with multiple files

    context 'with an explicit entry point name' do
      let(:library_files) { ['mygem.rb', 'other.rb'] }

      it 'selects the correct entry point' do
        expect(Dir).to receive(:mkdir).with('/test/libraries')
        expect(IO).to receive(:write).with('/test/libraries/mygem.rb', output[0])
        expect(IO).to receive(:write).with('/test/libraries/other.rb', output[1])
        described_class.write(spec, '/test', 'mygem')
      end
    end # /context with an explicit entry point name

    context 'with an explicit entry point name ending in .rb' do
      let(:library_files) { ['mygem.rb', 'other.rb'] }

      it 'selects the correct entry point' do
        expect(Dir).to receive(:mkdir).with('/test/libraries')
        expect(IO).to receive(:write).with('/test/libraries/mygem.rb', output[0])
        expect(IO).to receive(:write).with('/test/libraries/other.rb', output[1])
        described_class.write(spec, '/test', 'mygem.rb')
      end
    end # /context with an explicit entry point name

  end # /describe #write
end
