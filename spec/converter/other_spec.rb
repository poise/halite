require 'spec_helper'
require 'halite/converter/other'

describe Halite::Converter::Other do

  describe '#write' do
    let(:files) { [] }
    let(:input) { [] }
    let(:output) { [] }
    let(:spec) do
      spec = double(name: 'mygem')
      allow(spec).to receive(:each_file) do |&block|
        files.each {|path| block.call(File.join('/source', path), path) }
      end
      spec
    end
    before do
      files.each do |path|
        input_sentinel = double("content of #{path}")
        output_sentinel = double("generated output for #{path}")
        allow(File).to receive(:open).with(File.join('/source', path), 'rb').and_yield(input_sentinel)
        input << input_sentinel
        output << output_sentinel
      end
    end

    context 'with a single file' do
      let(:files) { ['recipes/default.rb'] }

      it 'writes a single file' do
        expect(FileUtils).to receive(:mkdir_p).with('/test/recipes')
        expect(File).to receive(:open).with('/test/recipes/default.rb', 'wb').and_yield(output[0])
        expect(IO).to receive(:copy_stream).with(input[0], output[0])
        described_class.write(spec, '/test')
      end
    end # /context with a single file

    context 'with multiple files' do
      let(:files) { ['attributes.rb', 'recipes/default.rb', 'templates/default/conf.erb'] }

      it 'writes multiple files' do
        expect(FileUtils).to receive(:mkdir_p).with('/test/recipes')
        expect(FileUtils).to receive(:mkdir_p).with('/test/templates/default')
        expect(File).to receive(:open).with('/test/attributes.rb', 'wb').and_yield(output[0])
        expect(IO).to receive(:copy_stream).with(input[0], output[0])
        expect(File).to receive(:open).with('/test/recipes/default.rb', 'wb').and_yield(output[1])
        expect(IO).to receive(:copy_stream).with(input[1], output[1])
        expect(File).to receive(:open).with('/test/templates/default/conf.erb', 'wb').and_yield(output[2])
        expect(IO).to receive(:copy_stream).with(input[2], output[2])
        described_class.write(spec, '/test')
      end
    end # /context with a single file

  end # /describe #write

end
