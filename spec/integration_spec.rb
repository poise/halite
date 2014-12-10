require 'spec_helper'
require 'tmpdir'
require 'halite/converter'

describe 'integration tests' do
  around do |example|
    Dir.mktmpdir('halite_test') do |path|
      example.metadata[:halite_temp_path] = path
      example.run
    end
  end
  let(:temp_path) do |example|
    example.metadata[:halite_temp_path]
  end
  let(:gem_name) { '' }
  let(:fixture_path) { File.expand_path("../data/integration_cookbooks/#{gem_name}", __FILE__) }

  context 'with test1 gem' do
    let(:gem_name) { 'test1' }
    it do
      Halite.convert(gem_name, temp_path)
      temp_files = Dir[File.join(temp_path, '**', '*')]
      fixture_files = Dir[File.join(fixture_path, '**', '*')]
      expect(temp_files.map {|path| path[temp_path.length..-1] }).to eq fixture_files.map {|path| path[fixture_path.length..-1] }
      temp_files.zip(fixture_files).each do |temp_file, fixture_file|
        next unless File.file?(temp_file)
        expect(IO.read(temp_file)).to eq IO.read(fixture_file)
      end
    end
  end # /context with test1 gem

end
