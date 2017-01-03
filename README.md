# Halite

[![Build Status](https://img.shields.io/travis/poise/halite.svg)](https://travis-ci.org/poise/halite)
[![Gem Version](https://img.shields.io/gem/v/halite.svg)](https://rubygems.org/gems/halite)
[![Coverage](https://img.shields.io/codecov/c/github/poise/halite.svg)](https://codecov.io/github/poise/halite)
[![Gemnasium](https://img.shields.io/gemnasium/poise/halite.svg)](https://gemnasium.com/poise/halite)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Write as a gem, release as a cookbook.

## Quick Start

Create a gem as per normal and add a dependency on `halite`. Add
`require 'halite/rake_tasks'` to your Rakefile. Run `rake build` and the
converted cookbook will be written to `pkg/`.

All Ruby code in the gem will be converted in to `libraries/` files. You can
add cookbook-specific files by add them to a `chef/` folder in the root of the
gem.

## Why?

Developing cookbooks as gems allows using the full Ruby development ecosystem
and tooling more directly. This includes things like Simplecov for coverage
testing, YARD for documentation, and Gemnasium for dependency monitoring. For
a cookbook that is already mostly library files, this is a natural transition,
with few cookbook-specific pieces to start with. This also allows using Bundler
to manage versions instead of Berkshelf.

## Cookbook Dependencies

To add cookbook dependencies either add them to the gem requirements or use
the `halite_dependencies` metadata field:

```ruby
Gem::Specification.new do |spec|
  spec.requirements = %w{apache2 mysql}
  # or
  spec.metadata['halite_dependencies'] = 'php >= 2.0.0, chef-client'
end
```

Additionally if you gem depends on other Halite-based gems those will
automatically converted to cookbook dependencies.

## Cookbook Files

Any files under `chef/` in the gem will be written as is in to the cookbook.
For example you can add a recipe to your gem via `chef/recipes/default.rb`.

## Chef Version

By default cookbooks will be generated with `chef_version '~> 12'` to require
Chef 12.x. This can be overridden using the `halite_chef_version` metadata field:

```ruby
Gem::Specification.new do |spec|
  spec.metadata['halite_chef_version'] = '>= 12.0.0'
end
```

## Rake Tasks

The `halite/rake_tasks` module provides quick defaults. Gem name will be
auto-detected from the `.gemspec` file and the cookbook name will be based
on the gem name.

### `rake build`

The build command will convert the gem to a cookbook and write it to the `pkg/`
folder.

### Advanced Usage

You can also pass custom arguments to the Rake tasks. All parameters are
optional:

```ruby
require 'halite/rake_helper'
Halite::RakeHelper.install_tasks(
  gem_name: 'name', # Name of the gem to convert
  base: File.basename(__FILE__), # Base folder for the gem
)
```

## Berkshelf Extension

Halite includes a Berkshelf extension to pull in any gem-based cookbooks that
are available on the system.

To activate it, include the extension in your `Berksfile`:

```ruby
extension 'halite'
```

## Spec Helper

Halite includes a set of helpers for RSpec tests. You can enable them in your
`spec_helper.rb`:

```ruby
require 'halite/spec_helper'

RSpec.configure do |config|
  config.include Halite::SpecHelper
end
```

### `recipe`

Recipes to converge for the test can be defined inline on example groups:

```ruby
describe 'cookbook recipe' do
  recipe 'myrecipe'
  it { is_expected.to create_file('/myfile') }
end

describe 'inline recipe' do
  recipe do
    file '/myfile' do
      content 'mycontent'
    end
  end
  it { is_expected.to create_file('/myfile') }
end
```

### `step_into`

A resource can be added to the list to step in to via the `step_into` helper:

```ruby
describe 'mycookbook' do
  recipe 'mycookbook::server'
  step_into :mycookbook_lwrp
  it { is_expected.to ... }
end
```

### `resource` and `provider`

For testing mixin-based cookbooks, new resource and provider classes can be
declared on an example group:

```ruby
describe MyMixin do
  resource(:test_resource) do
    include MyMixin
    def foo(val=nil)
      set_or_return(:foo, val, {})
    end
  end
  provider(:test_resource) do
    def action_run
      # ...
    end
  end
  recipe do
    test_resource 'test' do
      foo 1
      action :run
    end
  end
  it { is_expected.to ... }
end
```

These helper resources and providers are only available within the scope of
recipes defined on that example group or groups nested inside it. Helper
resources are automatically `step_into`'d.

## Using a Pre-release Version of a Cookbook

When a Halite-based cookbook is released, a converted copy is generally uploaded
to [the Supermarket](https://supermarket.chef.io/). To use unreleased versions,
you need to pull in the code from git via bundler and then tell the Berkshelf
extension to convert it for you.

To grab the pre-release gem, add a line like the following to your Gemfile:

```ruby
gem 'poise-application', github: 'poise/application'
```

You will need one `gem` line for each Halite-based cookbook you want to use,
possibly including dependencies if you want to use pre-release versions of
those as well.

Next you need to use Berkshelf to convert the gem to its cookbook form:

```ruby
source 'https://supermarket.chef.io/'
extension 'halite'
cookbook 'application', gem: 'poise-application'
```

Again you will need one `cookbook` line per Halite based cookbook you want to
use. Also make sure to check the correct names for the gem and cookbook, they
may not be the same though for other Poise cookbooks they generally follow the
same pattern.

If you are using something that integrates with Berkshelf like Test-Kitchen or
ChefSpec, this is all you need to do. You could use `berks upload` to push a
converted copy of all cookbooks to a Chef Server, though running pre-release
code in production should be done with great care.

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
