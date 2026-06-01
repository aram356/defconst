# Defconst Revival & Republish — Design Spec

**Date:** 2026-06-01
**Status:** Approved (revised after review)
**Goal:** Revive the dormant `defconst` Elixir library — fix deprecations, modernize
dependencies, add CI, and **prepare a `0.3.0` release for the maintainer to publish** to Hex.

## Background

`defconst` is a small (~280 LOC) Elixir library providing `defconst`/`defenum` macros
for constants and enums usable in guards. The core code is correct and idiomatic, but the
toolchain, dependencies, and config have aged out.

**Published baseline (important):** The latest version on Hex is **0.2.5** (published
2020-01-08). That release does **not** live on `master` — it sits on an unmerged branch
`aram356/udpdate_ex_doc` (commit `7b91238`), two commits ahead of `master`. The
`master..0.2.5` diff is small: a whitespace-only reformat of two doctest `@doc` heredocs,
the version bump to `0.2.5`, and `ex_doc 0.20.2 → 0.21.2`. So `master` is **behind** what
is published. **All three introspection functions (`constants/0`, `constant_of/1`,
`value_of/1`) already shipped in 0.2.5** — they are NOT new in 0.3.0.

Aging issues to address:
- `config/config.exs` uses `use Mix.Config`, deprecated since Elixir 1.9.
- Dev dependencies (`ex_doc 0.21`, `earmark`, `makeup`, `nimble_parsec`) are from 2019–2020
  and will not build docs on modern OTP.
- No CI, no `.tool-versions`, no git tags.
- README tells consumers to depend on `~> 0.2.2` (version drift).
- A `value_of` doc copy-paste bug and a `normalize_contant` typo exist in `lib/defconst.ex`
  (the doc bug is present in published 0.2.5 too).
- `package.files` (mix.exs) omits `CHANGELOG.md`, so a changelog would not ship in the tarball.
- `mix.exs` declares `elixir: "~> 1.6"` — a support claim that has never been CI-verified.
- `constant_of/1`'s polymorphic return (list when values collide, `nil` when absent) is
  undocumented and untested.

Runtime code has **zero dependencies** — all stale deps are `only: :dev, runtime: false`,
so consumers are unaffected at runtime today. The work is low-risk modernization.

## Decisions (from brainstorming + review)

| Decision | Choice |
|---|---|
| Intent | Revive & prepare for republish (broadest scope) |
| Release version | `0.3.0` |
| Changelog baseline | "since **0.2.5**" (the published version) |
| Reconcile 0.2.5 | **Merge `aram356/udpdate_ex_doc` into `master` first**, then rebase the work branch on top so the repo matches Hex before layering 0.3.0 |
| Support floor | **Raise to `elixir: "~> 1.15"`** (honest, CI-verified minimum) |
| Verification | Install Erlang/OTP locally **and** add CI (both) |
| CI matrix | Elixir 1.17/1.18/1.19 with OTP **26/27/28** (pairs: 1.17/26, 1.18/27, 1.19/28) |
| Local OTP pin | Pin a real **OTP ≥ 28.1** (Elixir 1.19 requires 28.1+); no placeholder version |
| `config/config.exs` | Delete (pure-macro lib has no runtime config) |
| `constant_of` return | Keep behavior; **document AND add tests** (list / `nil` paths) |
| `CHANGELOG.md` | Create **and** add to `package.files`; validate with `mix hex.build` / dry-run |
| Commits | Targeted `git add <paths>` only; never `git add -A`; gitignore `.DS_Store` |
| Delivery | All 0.3.0 work on a feature branch via a pull request (MR) |
| Publish | Gated hand-off to maintainer; not done autonomously |

## Workstreams

Each workstream is independently verifiable. WS0 reconciles the published baseline; WS1
establishes the green toolchain; WS2–6 are the changes; WS7 is delivery; WS8 is the gated publish.

### 0. Reconcile published 0.2.5 onto master
- Fetch and fast-forward-merge `origin/aram356/udpdate_ex_doc` into `master` so `master`
  reflects published 0.2.5.
- Rebase the `revive-and-modernize` work branch onto the updated `master`.

**Verify:** `git show master:mix.exs | grep @version` shows `0.2.5`; work branch rebased cleanly.

### 1. Toolchain & green baseline
- Add asdf `erlang` plugin; install OTP ≥ 28.1; commit `.tool-versions`
  (`elixir 1.19.5-otp-28` + the installed `erlang 28.1+`).
- Run `mix deps.get && mix test` on the reconciled baseline to capture a known-green start.

**Verify:** `elixir --version` resolves OTP 28.1+; all tests pass before changes.

### 2. Deprecation & hygiene fixes
- Delete `config/config.exs`.
- Fix the `value_of` doc example (currently calls `constant_of`).
- Rename `normalize_contant` → `normalize_constant`.
- Document `constant_of/1`'s polymorphic return.
- Add `.DS_Store` to `.gitignore`.

**Verify:** `mix test` green; `mix format --check-formatted` clean.

### 3. Test `constant_of/1` contract (TDD)
- Add tests: colliding values return a **list** of names; absent value returns **`nil`**.
- Use a fixture module with duplicate constant values.

**Verify:** new tests fail first (red), pass after (green); full suite green.

### 4. Dependency & support modernization
- Bump `ex_doc` to `~> 0.34` (`only: :dev, runtime: false`).
- Raise `elixir:` requirement to `~> 1.15`.
- Delete & regenerate `mix.lock`.
- Build docs to confirm tooling works on OTP 28.

**Verify:** `mix test` green; `mix docs` builds; lockfile uses `earmark_parser`, not legacy `earmark`.

### 5. Continuous integration
- Add `.github/workflows/ci.yml` (`erlef/setup-beam`); matrix 1.17/26, 1.18/27, 1.19/28.
- Steps: `mix deps.get`, `mix format --check-formatted`, `mix test`.

**Verify:** valid YAML; jobs pass once pushed.

### 6. Release prep
- Bump version to `0.3.0`.
- Create `CHANGELOG.md` (baseline "since 0.2.5") **and** add it to `package.files`.
- Update README: dependency hint → `~> 0.3.0`; document introspection functions.
- Validate the package tarball: `mix hex.build` (and review `mix hex.publish --dry-run`).

**Verify:** `mix test` green; `mix hex.build` succeeds and the file list includes `CHANGELOG.md`.

### 7. Delivery (MR)
- Push the branch; open a PR against `master` summarizing all workstreams; ensure CI passes.

**Verify:** PR opened, CI green, ready for review/merge.

### 8. Publish (gated hand-off)
- After merge: tag `v0.3.0`, push tag.
- `mix hex.publish` requires the maintainer's Hex credentials and is irreversible and
  outward-facing. **Performed by the maintainer**, not autonomously.

**Verify:** tag pushed; publish performed by maintainer.

## Out of scope
- Changing the `defconst`/`defenum`/generator public API or macro behavior.
- Changing `constant_of`'s return shape (documented + tested, not changed).
- Unrelated refactoring of the macro internals.

## Success criteria
- `mix test`, `mix format --check-formatted`, `mix docs`, and `mix hex.build` all succeed
  locally on OTP 28.1+ and across the CI matrix.
- No deprecation warnings on current Elixir.
- Repo `master` matches published 0.2.5 before 0.3.0 is layered on.
- A `0.3.0` PR is merged and tagged, ready for the maintainer to publish to Hex.
