require 'spec_helper'

describe Halite::Converter do
  describe '#write' do
    it 'should call all submodules' do
      expect(Halite::Converter::Metadata).to receive(:write).ordered
      expect(Halite::Converter::Library).to receive(:write).ordered
      described_class.write(nil, '/test')
    end
  end
end
