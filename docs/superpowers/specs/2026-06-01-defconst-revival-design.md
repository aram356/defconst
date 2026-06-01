# Defconst Revival & Republish — Design Spec

**Date:** 2026-06-01
**Status:** Approved (pending spec review)
**Goal:** Revive the dormant `defconst` Elixir library — fix deprecations, modernize
dependencies, add CI, and publish a fresh `0.3.0` release to Hex.

## Background

`defconst` is a small (~280 LOC) Elixir library providing `defconst`/`defenum` macros
for constants and enums usable in guards. It has been dormant since May 2019. The core
code is correct and idiomatic, but the toolchain, dependencies, and config have aged out:

- `config/config.exs` uses `use Mix.Config`, deprecated since Elixir 1.9.
- Dev dependencies (`ex_doc 0.20`, `earmark 1.3`, `makeup 0.8`, `nimble_parsec 0.5`)
  are from 2018–2019 and will not build docs on modern OTP.
- No CI, no `.tool-versions`, no git tags despite `version: 0.2.4` in `mix.exs`.
- README tells consumers to depend on `~> 0.2.2` (version drift).
- A doc copy-paste bug and a function-name typo exist in `lib/defconst.ex`.

Runtime code has **zero dependencies** — all stale deps are `only: :dev, runtime: false`,
so consumers are unaffected at runtime today. The work is low-risk modernization.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Intent | Revive & republish (broadest scope) |
| Release version | `0.3.0` (minor bump; reflects `constant_of`/`value_of` added since last publish) |
| Verification | Install Erlang/OTP locally **and** add CI (both) |
| CI matrix | Recent 3 Elixir (1.17/1.18/1.19) with matching OTP (26/27/28) |
| `config/config.exs` | Delete (pure-macro lib has no runtime config) |
| `constant_of` polymorphic return | Keep behavior, document explicitly (avoid breaking consumers) |
| Delivery | All changes on a feature branch via a pull request (MR) |
| Publish | Gated hand-off to maintainer; not done autonomously |

## Workstreams

Each workstream is independently verifiable. Order matters: 1 establishes the baseline,
2–5 are the changes, 6 is delivery, 7 is the gated publish.

### 1. Toolchain & green baseline
- Install Erlang/OTP 28 via asdf; confirm `elixir`/`erl` resolve.
- Commit `.tool-versions` pinning `elixir 1.19.5-otp-28` and `erlang 28.x`.
- Run `mix deps.get && mix test` **before any source change** to capture a known-green
  starting point. Record results.
- Create feature branch (e.g. `revive-and-modernize`) off `master`.

**Verify:** all tests pass on the untouched code.

### 2. Deprecation & hygiene fixes
- Delete `config/config.exs` (100% boilerplate, no active config).
- Fix `value_of` doc example in `lib/defconst.ex` (currently wrongly calls `constant_of`).
- Rename `normalize_contant` → `normalize_constant` (all references).
- Add an explicit doc note to `constant_of` describing its polymorphic return
  (single atom for unique values, list when multiple constants share a value).

**Verify:** `mix test` green, `mix format --check-formatted` clean.

### 3. Dependency modernization
- Bump `ex_doc "~> 0.20"` → `"~> 0.34"` in `mix.exs` (stays `only: :dev, runtime: false`).
- Delete `mix.lock`; regenerate via `mix deps.get` (pulls modern
  `earmark_parser`/`makeup`/`nimble_parsec`, drops legacy `earmark`).
- Build docs to confirm tooling works on OTP 28.

**Verify:** `mix test` green, `mix docs` builds without error.

### 4. Continuous integration
- Add `.github/workflows/ci.yml` using `erlef/setup-beam`.
- Matrix: Elixir 1.17/1.18/1.19 against compatible OTP 26/27/28.
- Steps: `mix deps.get`, `mix format --check-formatted`, `mix test`.
- Triggers: push and pull_request targeting `master`.

**Verify:** workflow file is valid YAML; jobs run and pass once pushed.

### 5. Release prep
- Bump `version: "0.2.4"` → `"0.3.0"` in `mix.exs`.
- Add `CHANGELOG.md` documenting `constant_of`/`value_of` and the modernization.
- Update `README.md`: dependency hint `~> 0.2.2` → `~> 0.3.0`; document new functions.

**Verify:** `mix test` green; README/CHANGELOG reviewed.

### 6. Delivery (MR)
- Push the feature branch.
- Open a pull request (MR) against `master` summarizing all workstreams.
- Ensure CI passes on the PR.

**Verify:** PR opened, CI green, ready for review/merge.

### 7. Publish (gated hand-off)
- After the PR is merged to `master`: tag `v0.3.0` and `git push --tags`.
- `mix hex.publish` requires the maintainer's Hex credentials and is an irreversible,
  outward-facing action. **This step is handed to the maintainer**; the agent will stage
  everything and, if asked, walk through the publish — but will not publish autonomously.

**Verify:** tag pushed; publish performed by maintainer.

## Out of scope
- Changing the `defconst`/`defenum`/generator public API or macro behavior.
- Changing `constant_of`'s return shape (documented, not changed).
- Unrelated refactoring of the macro internals.

## Success criteria
- `mix test`, `mix format --check-formatted`, and `mix docs` all succeed locally on
  OTP 28 and across the CI matrix.
- No deprecation warnings on current Elixir.
- A `0.3.0` PR is merged and tagged, ready for the maintainer to publish to Hex.
