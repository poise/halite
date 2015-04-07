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

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'halite/version'

Gem::Specification.new do |spec|
  spec.name = 'halite'
  spec.version = Halite::VERSION
  spec.authors = ['Noah Kantrowitz']
  spec.email = %w{noah@coderanger.net}
  spec.description = 'A set of helpers to write Chef cookbooks as Ruby gems.'
  spec.summary = spec.description
  spec.homepage = 'https://github.com/coderanger/halite'
  spec.license = 'Apache 2.0'

  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  spec.add_dependency 'chef', '>= 11.0'
  spec.add_dependency 'stove', '~> 3.2', '>= 3.2.3'
  spec.add_dependency 'bundler' # Used for Bundler.load_gemspec
  spec.add_dependency 'thor' # Used for Thor::Shell

  spec.add_development_dependency 'poise', '~> 1.1'
  spec.add_development_dependency 'poise-boiler', '~> 1.0'
  spec.add_development_dependency 'rspec-command', '~> 1.0'
end
