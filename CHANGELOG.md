# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [0.9.0]

### Added

* Added Rake task and RSpec matcher for Assess. ActiveStash Assess is a tool to identify where sensitive data lives in your Rails 7 app's database, and tracking your progress on encrypting it.

## [0.8.0]

### Added

* Check for workspace arg when logging in
* Support for filter parameters.
* Error handling on StashRB errors returned when logging in.

## [0.7.1]

### Fixed

* Fixed a bug where Rake tasks would not load correctly if users had a `tasks/active_stash.rake` file defined within a project.
* Issue where incorrect indexes were being created for ActiveRecord encrypted fields.

## [0.7.0]

* Added basic support for counts on `ActiveStash::Relation`

## [0.6.2]

### Fixed

* Ensure GVB is loaded before looking it up.

## [0.6.1]

### Fixed

* Remove bundler gem helpers to avoid conflicts with git release task.

## [0.6.0]

### Added

* Added encryption compatible uniqueness validations via ActiveStash::Validations.
* Use git version bump.

## [0.5.0]

### Added

* Add the ability to specify a unique constraint on range and exact indexes.
* Add CI job for running specs against main branch of Ruby client

## [0.4.5]

### Added

* Add ability to retrieve just stash IDs.

### Changed

* Update readme to remove usage of count in example query.
* Update rake signup task redirect flow.

### Fixed

* Duplicate loading of ActiveRecord models.

## [0.4.4]

### Changed

* Add more information detailing next steps, to output of signup rake task.

## [0.4.3]

### Fixed

* Issue where queries would break due to an incompatible change in the ruby-client

## [0.4.2]

### Fixed

* Add net-http as a runtime dep for Ruby versions < 3.1, to stop net-protocol warnings.

## [0.4.1]

### Added

* Rake task to launch signup

## [0.4.0]

### Added

* Now supports Rails 6 (by backporting `ActiveRecord::Relation.in_order_of`)

## [0.3.0]

### Fixed

* Fixed an issue where calling `joins` or `includes` before (or after) `query` fails
* Ensure that `stash_id` is set if `cs_put` is called outside of a callback

### Changed

* Indexes must now be specified via `stash_index` and/or `stash_match_all`
* Don't call `save` when bulk reindexing to avoid updating timestamps unnecessarily
* ActiveStash now detects if your model settings have diverged from the server configuration

## [0.2.0]

### Added

* Added support for [dynamic-match](https://docs.cipherstash.com/reference/index-types/dynamicmatch.html) indexes
* Free-text queries across all strings using `query(str)`

## [0.1.2]

### Changed

Indexing now ignores `json`, `jsonb` and `uuid` types. These may be added later.

## [0.1.1]

First public release
