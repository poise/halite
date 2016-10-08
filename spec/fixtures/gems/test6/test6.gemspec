# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'test6/version'

Gem::Specification.new do |spec|
  spec.name = 'test6'
  spec.version = Test6::VERSION
  spec.authors = ['Noah Kantrowitz']
  spec.email = %w{noah@coderanger.net}
  spec.description = %q||
  spec.summary = %q||
  spec.homepage = 'http://example.com/'
  spec.license = 'Apache 2.0'

  spec.files = `cd #{File.expand_path('..', __FILE__)} && git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  spec.add_development_dependency 'rake'
end
