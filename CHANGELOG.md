# Changelog

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
