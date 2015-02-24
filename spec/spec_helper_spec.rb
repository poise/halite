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

require 'halite/spec_helper'

describe Halite::SpecHelper do
  include Halite::SpecHelper

  describe '#recipe' do
    context 'with a block' do
      recipe do
        ruby_block 'test'
      end

      it { is_expected.to run_ruby_block('test') }
    end # /context with a block

    context 'with a recipe' do
      let(:chefspec_options) { {dry_run: true} }
      recipe 'test'

      it do
        expect(chef_runner).to receive(:converge).with('test').and_call_original
        chef_run
      end
    end # /context with a recipe

    context 'with both a recipe and a block' do
      recipe 'test' do
        ruby_block 'test'
      end

      it { expect { chef_run }.to raise_error(Halite::Error) }
    end # /context with both a recipe and a block
  end # /describe #recipe

end
