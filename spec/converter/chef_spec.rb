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

describe Halite::Converter::Chef do
  describe '#write' do
    let(:files) { [] }
    let(:gem_data) do
      instance_double('Halite::Gem').tap do |d|
        allow(d).to receive(:each_file) do |&block|
          files.each {|path| block.call(File.join('/source', path), path) }
        end
      end
    end
    subject { described_class.write(gem_data, '/test') }

    context 'with a single file' do
      let(:files) { ['recipes/default.rb'] }

      it do
        expect(FileUtils).to receive(:mkdir_p).with('/test/recipes')
        expect(FileUtils).to receive(:copy).with('/source/recipes/default.rb', '/test/recipes/default.rb', preserve: true)
        subject
      end
    end # /context with a single file

    context 'with multiple files' do
      let(:files) { ['attributes.rb', 'recipes/default.rb', 'templates/default/conf.erb'] }

      it do
        expect(FileUtils).to receive(:mkdir_p).with('/test/recipes')
        expect(FileUtils).to receive(:mkdir_p).with('/test/templates/default')
        expect(FileUtils).to receive(:copy).with('/source/attributes.rb', '/test/attributes.rb', preserve: true)
        expect(FileUtils).to receive(:copy).with('/source/recipes/default.rb', '/test/recipes/default.rb', preserve: true)
        expect(FileUtils).to receive(:copy).with('/source/templates/default/conf.erb', '/test/templates/default/conf.erb', preserve: true)
        subject
      end
    end # /context with multiple files
  end # /describe #write
end
