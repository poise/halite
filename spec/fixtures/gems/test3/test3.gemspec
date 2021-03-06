# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'test3/version'

Gem::Specification.new do |spec|
  spec.name = 'test3'
  spec.version = Test3::VERSION
  spec.authors = ['Noah Kantrowitz']
  spec.email = %w{noah@coderanger.net}
  spec.description = %q||
  spec.summary = %q||
  spec.homepage = 'http://example.com/'
  spec.license = 'Apache 2.0'
  spec.metadata['halite_entry_point'] = 'test3/dsl'
  spec.metadata['halite_chef_version'] = '>= 3'
  spec.metadata['platforms'] = 'ubuntu >= 16.04, redhat'

  spec.files = `cd #{File.expand_path('..', __FILE__)} && git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  spec.add_dependency 'halite'
  spec.add_dependency 'test2', '~> 4.5.6'
  spec.add_development_dependency 'rake'
end
