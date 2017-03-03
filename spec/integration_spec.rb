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
require 'rspec-command'

describe 'integration tests' do
  include RSpecCommand
  include RSpecCommand::Rake
  let(:extra_gems) { [] }
  let(:recipes) { [] }
  let(:expect_output) { }

  shared_examples 'an integration test' do |gem_name, version, stub_cookbooks=[]|
    describe 'Halite.convert' do
      subject { Halite.convert(gem_name, temp_path) }
      it { is_expected.to match_fixture("cookbooks/#{gem_name}") }
    end # /describe Halite.convert

    describe 'run it with chef-solo', slow: true do
      file('solo.rb') { "cookbook_path '#{temp_path}'" }
      file 'runner/metadata.rb', "name 'runner'\ndepends '#{gem_name}'"
      file 'runner/recipes/default.rb', ''
      # Write out a stub cookbooks for dependency testing.
      stub_cookbooks.each do |(stub_name, stub_version)|
        file "#{stub_name}/metadata.rb", "name '#{stub_name}'\nversion '#{stub_version}'"
      end
      before do
        ([gem_name] + extra_gems).each do |name|
          cookbook_path = File.join(temp_path, name)
          Dir.mkdir(cookbook_path)
          Halite.convert(name, cookbook_path)
        end
      end
      command { "chef-solo -l debug -c solo.rb -o #{(['runner']+recipes).map{|r| "recipe[#{r}]"}.join(',')}" }

      it do
        # Force the command to run at least once.
        subject
        Array(expect_output).each do |output|
          expect(subject.stdout).to include(output), "'#{output}' not found in the output of #{subject.command}:\n#{subject.stdout}"
        end
      end
    end # /describe run it with chef-solo

    describe 'run rake chef:build' do
      fixture_file "gems/#{gem_name}"
      rake_task 'chef:build'
      it { is_expected.to match_fixture("cookbooks/#{gem_name}", "pkg/#{gem_name}-#{version}") }
    end # /describe run rake chef:build
  end # /shared_examples an integration test

  context 'with test1 gem', integration: true do
    it_should_behave_like 'an integration test', 'test1', '1.2.3'
  end # /context with test1 gem

  context 'with test2 gem', integration: true do
    it_should_behave_like 'an integration test', 'test2', '4.5.6', [['testdep', '1.0.0']]
  end # /context with test2 gem

  context 'with test3 gem', integration: true do
    let(:extra_gems) { ['test2'] }
    let(:recipes) { ['test3'] }
    let(:expect_output) { '!!!!!!!!!!test34.5.6' }
    it_should_behave_like 'an integration test', 'test3', '7.8.9', [['testdep', '1.0.0']]
  end # /context with test3 gem

  context 'with test4 gem', integration: true do
    it_should_behave_like 'an integration test', 'test4', '2.3.1.rc.1'
  end # /context with test1 gem
end
