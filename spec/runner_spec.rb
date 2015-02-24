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

# This file is not named spec/spec_helper/runner_spec.rb because that seems confusing.

require 'spec_helper'

require 'halite/spec_helper/runner'

describe Halite::SpecHelper::Runner do
  let(:options) { Hash.new }
  subject { described_class.new(options) }

  describe 'Runner.converge' do
    let(:instance) { double('Runner instance') }
    before do
      expect(described_class).to receive(:new).with(options).and_return(instance)
    end

    context 'with a block' do
      it do
        expect(instance).to receive(:converge) do |&block|
          expect(block).to be_a(Proc)
        end
        described_class.converge { ruby_block 'test' }
      end
    end # /context with a block

    context 'with a recipe' do
      it do
        expect(instance).to receive(:converge).with('test')
        described_class.converge('test')
      end
    end # /context with a recipe

    context 'with options' do
      let(:options) { {dry_run: true} }
      it do
        expect(instance).to receive(:converge).with('test')
        described_class.converge('test', dry_run: true)
      end
    end # /context with options
  end # /describe Runner.converge

  describe '#initialize' do

    context 'with a simple option' do
      let(:options) { {dry_run: true} }
      its(:dry_run?) { is_expected.to be_truthy }
    end # /context with a simple option

    context 'with default_attributes' do
      let(:options) { {default_attributes: {halite: 'test'}} }
      it { expect(subject.node.default['halite']).to eq('test') }
      it { expect(subject.node['halite']).to eq('test') }
    end # /context with default_attributes

    context 'with normal_attributes' do
      let(:options) { {normal_attributes: {halite: 'test'}} }
      it { expect(subject.node.normal['halite']).to eq('test') }
      it { expect(subject.node['halite']).to eq('test') }
    end # /context with normal_attributes

    context 'with override_attributes' do
      let(:options) { {override_attributes: {halite: 'test'}} }
      it { expect(subject.node.override['halite']).to eq('test') }
      it { expect(subject.node['halite']).to eq('test') }
    end # /context with override_attributes
  end # /describe #initialize

  describe '#converge' do
    context 'with a block' do
      it do
        sentinel = [false]
        subject.converge { sentinel[0] = true }
        expect(sentinel[0]).to eq(true)
      end
    end # /context with a block

    context 'with a recipe' do
      let(:options) { {dry_run: true} }

      it do
        expect(subject.node.run_list).to receive(:add).with('test')
        subject.converge('test')
      end
    end # /context with a recipe

    context 'with both a block and a recipe' do
      it do
        expect { subject.converge('test') { } }.to raise_error(Halite::Error)
      end
    end # /context with both a block and a recipe
  end # /describe #converge
end
