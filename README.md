# Halite

[![Build Status](https://img.shields.io/travis/coderanger/halite.svg)](https://travis-ci.org/coderanger/halite)
[![Gem Version](https://img.shields.io/gem/v/halite.svg)](https://rubygems.org/gems/halite)
[![Code Climate](https://img.shields.io/codeclimate/github/coderanger/halite.svg)](https://codeclimate.com/github/coderanger/halite)
[![Coverage](https://img.shields.io/codeclimate/coverage/github/coderanger/halite.svg)](https://codeclimate.com/github/coderanger/halite)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Write as a gem, release as a cookbook.

## Quick Start

Create a gem as per normal and add a dependency on `halite`. Add
`require 'halite/rake_tasks'` to your Rakefile. Run `rake build` and the
converted cookbook will be written to `pkg/`.

All Ruby code in the gem will be converted in to `libraries/` files. You can
add cookbook-specific files by add them to a `chef/` folder in the root of the
gem.

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
