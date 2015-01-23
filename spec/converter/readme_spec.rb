require 'spec_helper'
require 'halite/converter/readme'

describe Halite::Converter::Readme do

  describe '#write' do
    let(:spec) { double(full_gem_path: '/source') }
    let(:readme_file) { }
    let(:input) { [] }
    let(:output) { [] }
    before do
      allow(File).to receive(:exists?).and_return(false)
      Array(readme_file).each do |path|
        input_sentinel = double("content of #{path}")
        output_sentinel = double("generated output for #{path}")
        allow(File).to receive(:exists?).with(File.join('/source', path)).and_return(true)
        allow(File).to receive(:open).with(File.join('/source', path), 'rb').and_yield(input_sentinel)
        input << input_sentinel
        output << output_sentinel
      end
    end

    context 'with a README.md' do
      let(:readme_file) { 'README.md' }

      it 'writes out a README.md' do
        expect(File).to receive(:open).with('/test/README.md', 'wb').and_yield(output[0])
        expect(IO).to receive(:copy_stream).with(input[0], output[0])
        described_class.write(spec, '/test')
      end
    end # /context with a README.md

    context 'with a README' do
      let(:readme_file) { 'README' }

      it 'writes out a README' do
        expect(File).to receive(:open).with('/test/README', 'wb').and_yield(output[0])
        expect(IO).to receive(:copy_stream).with(input[0], output[0])
        described_class.write(spec, '/test')
      end
    end # /context with a README

    context 'with multiple files' do
      let(:readme_file) { %w{README.txt readme.md} }

      it 'writes out a README' do
        expect(File).to receive(:open).with('/test/README.txt', 'wb').and_yield(output[0])
        expect(IO).to receive(:copy_stream).with(input[0], output[0])
        described_class.write(spec, '/test')
      end
    end # /context with multiple files

  end # /describe #write

end
