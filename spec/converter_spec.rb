require 'spec_helper'
require 'halite/converter'

describe Halite::Converter do
  describe '#write' do
    it 'should call all submodules' do
      expect(Halite::Converter::Metadata).to receive(:write).ordered
      expect(Halite::Converter::Libraries).to receive(:write).ordered
      expect(Halite::Converter::Other).to receive(:write).ordered
      described_class.write(nil, '/test')
    end
  end
end
