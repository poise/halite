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
require 'halite/converter'

describe Halite::Converter do
  describe '#write' do
    it 'should call all submodules' do
      expect(Halite::Converter::Metadata).to receive(:write).ordered
      expect(Halite::Converter::Libraries).to receive(:write).ordered
      expect(Halite::Converter::Other).to receive(:write).ordered
      expect(Halite::Converter::Readme).to receive(:write).ordered
      described_class.write(nil, '/test')
    end
  end
end
