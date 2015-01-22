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
  let(:stub_cookbooks) { [] }
  let(:extra_gems) { [] }
  let(:recipes) { [] }
  let(:fixture_path) { File.expand_path("../data/integration_cookbooks/#{gem_name}", __FILE__) }
  let(:expect_output) { nil }

  shared_examples 'an integration test' do
    def directories_match(temp_path, fixture_path)
      temp_files = Dir[File.join(temp_path, '**', '*')].sort
      fixture_files = Dir[File.join(fixture_path, '**', '*')].sort
      expect(temp_files.map {|path| path[temp_path.length..-1] }).to eq fixture_files.map {|path| path[fixture_path.length..-1] }
      temp_files.zip(fixture_files).each do |temp_file, fixture_file|
        next unless File.file?(temp_file)
        expect(IO.read(temp_file)).to eq IO.read(fixture_file)
      end
    end

    it 'matches the fixture' do
      # Convert gem
      Halite.convert(gem_name, temp_path)
      # Check that conversion matches the fixture
      directories_match(temp_path, fixture_path)
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
      # Write out a stub cookbooks for dependency testing
      stub_cookbooks.each do |(stub_name, stub_version)|
        stub_path = File.join(temp_path, stub_name)
        Dir.mkdir(stub_path)
        IO.write(File.join(stub_path, 'metadata.rb'), "name '#{stub_name}'\nversion '#{stub_version}'")
      end
      # Convert gems
      ([gem_name] + extra_gems).each do |name|
        cookbook_path = File.join(temp_path, name)
        Dir.mkdir(cookbook_path)
        Halite.convert(name, cookbook_path)
      end
      # Run solo
      cmd = Mixlib::ShellOut.new("bundle exec chef-solo -l debug -c #{solo_rb} -o #{(['runner']+recipes).map{|r| "recipe[#{r}]"}.join(',')}", cwd: temp_path)
      cmd.run_command
      expect(cmd.error?).to be_falsey, "Running #{cmd.command} failed (#{cmd.exitstatus} #{cmd.error?}):\n#{cmd.stderr.empty? ? cmd.stdout : cmd.stderr}"
      Array(expect_output).each do |output|
        expect(cmd.stdout).to include(output), "'#{output}' not found in the output of #{cmd.command}:\n#{cmd.stdout}"
      end
    end

    it 'can run rake chef:build', slow: true do
      # Copy the test gem to the temp path
      FileUtils.cp_r(File.join(File.expand_path(File.join('..', 'data', 'gems', gem_name), __FILE__), '.'), temp_path)
      # Run rake build
      cmd = Mixlib::ShellOut.new("bundle exec rake chef:build", cwd: temp_path)
      cmd.run_command
      expect(cmd.error?).to be_falsey, "Running #{cmd.command} failed (#{cmd.exitstatus} #{cmd.error?}):\n#{cmd.stderr.empty? ? cmd.stdout : cmd.stderr}"
      # Check that conversion matches the fixture
      directories_match(File.join(temp_path, 'pkg'), fixture_path)
    end
  end

  context 'with test1 gem', integration: true do
    let(:gem_name) { 'test1' }
    it_should_behave_like 'an integration test'
  end

  context 'with test2 gem', integration: true do
    let(:gem_name) { 'test2' }
    let(:stub_cookbooks) { [['testdep', '1.0.0']] }
    it_should_behave_like 'an integration test'
  end

  context 'with test3 gem', integration: true do
    let(:gem_name) { 'test3' }
    let(:extra_gems) { ['test2'] }
    let(:stub_cookbooks) { [['testdep', '1.0.0']] }
    let(:recipes) { ['test3'] }
    let(:expect_output) { '!!!!!!!!!!test34.5.6' }
    it_should_behave_like 'an integration test'
  end

end
