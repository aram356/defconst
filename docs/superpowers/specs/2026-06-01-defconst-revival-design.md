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
the version bump to `0.2.5`, and an `ex_doc` resolution bump to `0.21.2` **in `mix.lock`
only** — the `mix.exs` constraint stays `~> 0.20`. So `master` is **behind** what
is published. **All three introspection functions (`constants/0`, `constant_of/1`,
`value_of/1`) already shipped in 0.2.5** — they are NOT new in 0.3.0.

Aging issues to address:

- `config/config.exs` uses `use Mix.Config`, deprecated since Elixir 1.9.
- Dev dependencies (`ex_doc` constraint `~> 0.20`, lock-resolved 0.21.2; plus `earmark`,
  `makeup`, `nimble_parsec`) are from 2019–2020
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

| Decision             | Choice                                                                                                                                                                                                     |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Intent               | Revive & prepare for republish (broadest scope)                                                                                                                                                            |
| Release version      | `0.3.0`                                                                                                                                                                                                    |
| Changelog baseline   | "since **0.2.5**" (the published version)                                                                                                                                                                  |
| Reconcile 0.2.5      | Bring `master` up to published 0.2.5 (`aram356/udpdate_ex_doc`) **via a PR**, not a direct push, then base the work branch on it. Locally fast-forward only to base the work; never push `master` directly |
| Support floor        | **Keep `elixir: "~> 1.15"`**, made honest by testing 1.15 and 1.16 in CI                                                                                                                                   |
| Verification         | Install Erlang/OTP locally **and** add CI (both)                                                                                                                                                           |
| CI matrix            | Elixir 1.15/1.16/1.17/1.18/1.19 (pairs: 1.15/26, 1.16/26, 1.17/26, 1.18/27, 1.19/28)                                                                                                                       |
| Local OTP pin        | Pin a real **OTP ≥ 28.1** (Elixir 1.19 requires 28.1+); no placeholder version                                                                                                                             |
| `config/config.exs`  | Delete (pure-macro lib has no runtime config)                                                                                                                                                              |
| `constant_of` return | Keep behavior; **document AND add tests** (list / `nil` paths)                                                                                                                                             |
| `CHANGELOG.md`       | Create **and** add to `package.files`; validate with `mix hex.build` / dry-run                                                                                                                             |
| Commits              | Targeted `git add <paths>` only; never `git add -A`; gitignore OS files (`.DS_Store`, `Thumbs.db`); preflight a clean worktree before branch ops                                                                                                                                 |
| Delivery             | All 0.3.0 work on a feature branch via a pull request (MR)                                                                                                                                                 |
| Publish              | Gated hand-off to maintainer; not done autonomously                                                                                                                                                        |

## Workstreams

Each workstream is independently verifiable. WS0 reconciles the published baseline; WS1
establishes the green toolchain; WS2–6 are the changes; WS7 is delivery; WS8 is the gated publish.

### 0. Reconcile published 0.2.5 onto master (via PR)

- Locally fast-forward `master` to `origin/aram356/udpdate_ex_doc` **only to base the work
  branch on the published 0.2.5 state** — do not push `master` directly (respects branch
  protection / the PR delivery model).
- Reconcile `master` on the remote through a PR: either merge the existing
  `aram356/udpdate_ex_doc` branch via its own small PR, or fold those two commits into the
  revival PR and call out that `master` was behind Hex.
- Rebase the `revive-and-modernize` work branch onto the reconciled 0.2.5 baseline.

**Verify:** local `master`/work-branch base shows `@version "0.2.5"`; reconciliation is
delivered through a PR, not a direct `git push origin master`.

### 1. Toolchain & green baseline

- Ensure the asdf `elixir` plugin + `1.19.5-otp-28` are installed (verify-or-install); add
  asdf `erlang` plugin; install OTP ≥ 28.1; commit `.tool-versions`
  (`elixir 1.19.5-otp-28` + the installed `erlang 28.1+`).
- Run `mix deps.get && mix test` on the reconciled baseline to capture a known-green start.

**Verify:** `elixir --version` resolves OTP 28.1+; all tests pass before changes.

### 2. Deprecation & hygiene fixes

- Delete `config/config.exs`.
- Fix the `value_of` doc example (currently calls `constant_of`).
- Rename `normalize_contant` → `normalize_constant`.
- Document `constant_of/1`'s polymorphic return.
- Add OS files (`.DS_Store`, `Thumbs.db`) to `.gitignore`.

**Verify:** `mix test` green; `mix format --check-formatted` clean.

### 3. Test `constant_of/1` contract (characterization / regression)

- Add tests: colliding values return a **list** of names; absent value returns **`nil`**.
- Use a fixture module with duplicate constant values.
- Note: the behavior already exists in the source, so these are characterization tests that
  lock the documented contract in place — they are expected to pass on first run, not
  red-green TDD.

**Verify:** new tests pass; full suite green. (If any unexpectedly fail, that is a real
behavior bug — stop and report before changing source.)

### 4. Dependency & support modernization

- Bump `ex_doc` to the **latest** line `~> 0.40` (`only: :dev, runtime: false`). Because it
  is dev-only, CI test jobs fetch with `mix deps.get --only test` and never resolve it on the
  1.15/1.16 jobs; `mix docs` is verified locally on 1.19. This keeps the `~> 1.15` floor honest.
- Keep `elixir:` requirement at `~> 1.15` (verified by the 1.15/1.16 CI jobs).
- Delete & regenerate `mix.lock`.
- Build docs to confirm tooling works on OTP 28.1+.

**Verify:** `mix test` green; `mix docs` builds; lockfile uses `earmark_parser`, not legacy `earmark`.

### 5. Continuous integration

- Add `.github/workflows/ci.yml` (`erlef/setup-beam`); matrix 1.15/26, 1.16/26, 1.17/26,
  1.18/27, 1.19/28.
- Test matrix runs with job-level `MIX_ENV: test`; steps: `mix deps.get --only test`,
  `mix compile`, `mix test` (no formatter — see below). The test env ensures compile/test
  never expect the dev-only ex_doc. The 1.15/1.16 jobs are the **consumer-compatibility
  proof** for the `~> 1.15` floor (lib compiles + tests pass with runtime deps only — there
  are none).
- A separate single-version `format` job (Elixir 1.19) runs `mix format --check-formatted`,
  since formatter output can differ between Elixir releases.

**Verify:** valid YAML; jobs pass once pushed.

### 6. Release prep

- Bump version to `0.3.0`.
- Create `CHANGELOG.md` (baseline "since 0.2.5"); add it to **both** `package.files` and the
  docs `extras` (so `mix docs` renders it).
- Update README: dependency hint → `~> 0.3.0`; document introspection functions.
- Validate the package tarball: `mix hex.build` (and review `mix hex.publish --dry-run`).
- Before publishing, the maintainer also runs `mix docs` (on Elixir 1.19) — `mix hex.publish`
  builds docs as part of publishing, so doc-build failures are caught beforehand.

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

- Locally on OTP 28.1+ / Elixir 1.19: `mix test`, `mix format --check-formatted`,
  `mix docs`, and `mix hex.build` all succeed. In CI: `mix test` passes across the matrix
  and the dedicated `format` job is clean. (CI does **not** run `mix docs` or `mix hex.build`
  by design — those are dev/release-time checks.)
- No deprecation warnings on current Elixir.
- The `~> 1.15` support floor applies to **runtime and test** usage; doc generation (and
  thus a full dev `mix deps.get` that pulls dev-only ex_doc) is maintained on Elixir 1.19.
- Repo `master` matches published 0.2.5 before 0.3.0 is layered on.
- A `0.3.0` PR is merged and tagged, ready for the maintainer to publish to Hex.
