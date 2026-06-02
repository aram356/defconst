# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-06-02

### Added
- GitHub Actions CI across Elixir 1.15–1.19 / OTP 26–28 (test matrix + dedicated format job).
- Automated Hex release workflow: publishing a GitHub Release (tag matching `@version`) publishes the package and docs via CI.
- Pinned toolchain via `.tool-versions` (Elixir 1.19.5 / OTP 28.1+).
- Test coverage for `constant_of/1` duplicate-value (list) and missing-value (`nil`) paths.
- `CHANGELOG.md` (now shipped in the Hex package and rendered in the docs).

### Changed
- Declared minimum supported Elixir as `~> 1.15`, now verified in CI (was an unverified `~> 1.6`).
- Modernized `ex_doc` to the latest line, `~> 0.40` (dev-only; no runtime impact).

### Removed
- Deprecated `config/config.exs` (`use Mix.Config`); the library has no runtime config.

### Fixed
- Corrected the `value_of/1` documentation example (it referenced `constant_of`).
- Renamed internal `normalize_contant` typo to `normalize_constant`.
- Documented `constant_of/1`'s polymorphic return (name / list / `nil`).
- Resolved a duplicate-`@doc` compile warning on `Defconst.Enum.DefaultGenerator.next_value/2`.

## [0.2.5] - 2020-01-08

Last previously published release. Included `constants/0`, `constant_of/1`, and `value_of/1`.
(Its `mix.lock` resolved the dev-only `ex_doc` to 0.21.2; the constraint stayed `~> 0.20`.)
