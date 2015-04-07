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

describe Halite::Converter::Misc do
  describe '#write' do
    let(:files) { [] }
    let(:gem_data) do
      instance_double('Halite::Gem').tap do |d|
        allow(d).to receive(:find_misc_path) do |name|
          if files.include?(name)
            "/source/#{name}"
          else
            nil
          end
        end
      end
    end
    subject { described_class.write(gem_data, '/test') }

    context 'with no files' do
      it do
        expect(FileUtils).to_not receive(:copy)
        subject
      end
    end # /context with no files

    context 'with a Readme' do
      let(:files) { 'Readme' }

      it do
        expect(FileUtils).to receive(:copy).with('/source/Readme', '/test/Readme', preserve: true)
        subject
      end
    end # /context with a Readme

    context 'with multiple files' do
      let(:files) { %w{Readme License} }

      it 'writes out a README' do
        expect(FileUtils).to receive(:copy).with('/source/Readme', '/test/Readme', preserve: true)
        expect(FileUtils).to receive(:copy).with('/source/License', '/test/License', preserve: true)
        subject
      end
    end # /context with multiple files
  end # /describe #write
end
