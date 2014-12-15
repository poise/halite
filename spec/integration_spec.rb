require 'spec_helper'
require 'tmpdir'
require 'mixlib/shellout'
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
  let(:recipes) { [] }
  let(:fixture_path) { File.expand_path("../data/integration_cookbooks/#{gem_name}", __FILE__) }

  shared_examples 'an integration test' do
    it 'matches the fixture' do
      # Convert gem
      Halite.convert(gem_name, temp_path)
      # Check that all files match the fixture data
      temp_files = Dir[File.join(temp_path, '**', '*')]
      fixture_files = Dir[File.join(fixture_path, '**', '*')]
      expect(temp_files.map {|path| path[temp_path.length..-1] }).to eq fixture_files.map {|path| path[fixture_path.length..-1] }
      temp_files.zip(fixture_files).each do |temp_file, fixture_file|
        next unless File.file?(temp_file)
        expect(IO.read(temp_file)).to eq IO.read(fixture_file)
      end
    end

    it 'is a valid cookbook', slow: true do
      # Write out a solo config with the path
      solo_rb = File.join(temp_path, 'solo.rb')
      IO.write(solo_rb, "cookbook_path '#{temp_path}'")
      # Write out a cookbook that depends on our gem cookbook
      runner_path = File.join(temp_path, 'runner')
      Dir.mkdir(runner_path)
      IO.write(File.join(runner_path, 'metadata.rb'), "name 'runner'\ndepends '#{gem_name}'")
      Dir.mkdir(File.join(runner_path, 'recipes'))
      IO.write(File.join(runner_path, 'recipes', 'default.rb'), '')
      # Convert gem
      cookbook_path = File.join(temp_path, gem_name)
      Dir.mkdir(cookbook_path)
      Halite.convert(gem_name, cookbook_path)
      # Run solo
      cmd = Mixlib::ShellOut.new("bundle exec chef-solo -c #{solo_rb} -o #{(['runner']+recipes).map{|r| "recipe[#{r}]"}.join(',')}", cwd: File.expand_path('../..', __FILE__))
      cmd.run_command
      expect(cmd.error?).to be_falsey, "Running #{cmd.command} failed (#{cmd.exitstatus} #{cmd.error?}):\n#{cmd.stderr.empty? ? cmd.stdout : cmd.stderr}"
    end
  end

  context 'with test1 gem', integration: true do
    let(:gem_name) { 'test1' }
    it_should_behave_like 'an integration test'
  end

  context 'with test2 gem', integration: true do
    let(:gem_name) { 'test2' }
    it_should_behave_like 'an integration test'
  end

end
