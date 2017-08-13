# Halite Changelog

## v1.8.0

* Give recipes created using the block helper (`recipe do ... end`) a name when
  possible.
* Fix support for the Berkshelf plugin on Berks 6.1 and above.

## v1.7.0

* Allow specifying which platforms a cookbook supports via gem metadata:
  `spec.metadata['platforms'] = 'ubuntu centos'`.
* Support for automatic ChefSpec matchers in the future.

## v1.6.0

* Chef 13 compatibility.
* Structural supports for gathering development dependencies for cookbook gems.

## v1.5.0

* Set the default spec platform and version even when using the Halite runner
  API directly.
* Allow setting the chef_version constraints on a cookbook through a normal
  gem dependency on the `chef` gem.
* The default chef_version constraint has been changed from `~> 12.0` to `>= 12`
  to allow for better interaction with the upcoming Chef 13 release.
* Bump Stove dependency from 4.x to 5.x. This removes Ruby 2.0 compat. Sorry.
* No longer testing on Ruby 2.2, which happens to be entering security-maintenance
  mode today. Don't use it.

## v1.4.0

* Set a default platform and version in ChefSpec because Fauxhai is trying to
  deprecate the `chefspec` platform. This may break some tests that relied on
  the nil defaults.

## v1.3.0

* Include extended metadata with stove pushes.
* Fix `uninitialized constant Bundler::RemoteSpecification::MatchPlatform` when
  using the Berkshelf extension with ChefDK.

## v1.2.1

* Compatibility with Foodcritic 6.0. `issues_url` will be added to the generated
  `metadata.rb`. This can be set via `metadata['issues_url']` or auto-detected
  if the spec's `homepage` is set to a GitHub project.
* Compatibility with RubyGems 2.2.

## v1.2.0

* Allow passing a `Halite::Gem` object to `Halite.convert`.
* Allow disabling the stove push as part of `rake release` by setting
  `$cookbook_push=false` as an environment variable.
* Process `.foodcritic` when running `rake chef:foodcritic`.

## v1.1.0

* Support the new `chef_version` metadata field through gem metadata. Defaults
  to `~> 12` for now.
* Make spec helper resources look more like normal Chef resources when in auto
  mode.
* Add Halite's synthetic cookbooks to the cookbook compiler too, for
  include_recipe and friends.

## v1.0.13

* Additional cookbook metadata to work with Foodcritic 5.1.

## v1.0.12

* Further 12.0 fixes.

## v1.0.11

* Ensure Halite works under Chef 12.0.

## v1.0.10

* Fewer potential pitfalls when using the Halite spec helper in a non-gem
  cookbook. Still not 100%, but better.

## v1.0.9

* Additional `StubSpecifications` fixes.

## v1.0.8

* Expose `example_group` inside `SpecHelper`-created resources and providers.
* Handle `StubSpecifications` in the gem environment.

## v1.0.7

* More fixes for Chef 12.4.1.

## v1.0.6

* Minor fix for forward compatibility with 12.4.1+ and the spec helper's auto mode.

## v1.0.5

* Fix the spec helper for Chef <= 12.2.

## v1.0.4

* Fixes to work with Chef 12.4.

## v1.0.3

* Never try to do universe installs of pre-release gems in the Berkshelf extension.

## v1.0.2

* Handle converting cookbooks with pre-release version numbers and other
  non-Chef compatible components.
* Include a cookbook's changelog file in converted output.
* Handle OS X's case-insensitivity when converting misc. type files (README, etc).

## v1.0.1

* Fix issues with pre-release version numbers.

## v1.0.0

* Initial release!
