# Halite Changelog

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
