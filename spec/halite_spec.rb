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

describe Halite do
  describe '#convert' do
    let(:fake_gem) do
      double('Halite::Gem').tap do |g|
        allow(g).to receive(:is_a?).and_return(false)
        allow(g).to receive(:is_a?).with(Halite::Gem).and_return(true)
      end
    end

    context 'with a gem name' do
      before do
        allow(Halite::Gem).to receive(:new).with('mygem').and_return(fake_gem)
      end

      it do
        expect(Halite::Converter).to receive(:write).with(fake_gem, '/path')
        described_class.convert('mygem', '/path')
      end
    end # /context with a gem name

    context 'with a Gem object' do
      it do
        expect(Halite::Converter).to receive(:write).with(fake_gem, '/path')
        described_class.convert(fake_gem, '/path')
      end
    end # /context with a Gem object
  end # /describe #convert
end
