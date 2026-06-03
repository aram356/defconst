# Hex Release CI — Design Spec

**Date:** 2026-06-02
**Status:** Approved
**Goal:** Publish `defconst` to Hex (package + docs) automatically from CI when a GitHub
Release is published, with a tag/version safety gate.

## Background

The 0.3.0 revival (see `2026-06-01-defconst-revival-design.md`) left publishing as a manual
maintainer hand-off. This adds an automated release path so `mix hex.publish` runs in CI on
release, rather than from a maintainer's machine.

## Decisions

| Decision    | Choice                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------- |
| Trigger     | GitHub **Release published** (`on: release: types: [published]`)                            |
| Scope       | Package **and** docs (`mix hex.publish --yes`)                                              |
| Safety gate | Two gates, both fail-hard: (1) release tag (minus leading `v`) equals `mix.exs` `@version`; (2) the released commit is an ancestor of `origin/main` (no off-mainline publish) |
| Auth        | `HEX_API_KEY` repo secret, passed as env to the publish step                                |
| Toolchain   | From `.tool-versions` (`version-file` + `version-type: strict`); docs publishing needs dev-only ex_doc |
| Deps        | Full `mix deps.get` (dev deps incl. ex_doc) — NOT `--only test`, because docs are published |
| Existing CI | `ci.yml` unchanged; this is a separate release-only workflow                                |

## Component

`.github/workflows/release.yml`, one `publish` job:

1. `actions/checkout@v6` with `fetch-depth: 0` (full history for the ancestry check).
2. `erlef/setup-beam@v1` with `version-file: .tool-versions`, `version-type: strict`.
3. **Safety gate 1 (tag == version)** — parse `@version` from `mix.exs` via grep (no compile
   needed), strip the leading `v` from `GITHUB_REF_NAME`, fail with `::error::` if they differ.
4. **Safety gate 2 (on main)** — `git fetch --no-tags origin main`, then
   `git merge-base --is-ancestor "$GITHUB_SHA" origin/main`; fail if the released commit is not
   on `main`. This makes the workflow itself reject an off-mainline release (e.g. a tag on a
   docs-only commit), rather than relying on the maintainer's manual SHA check.
5. `mix deps.get`.
6. `mix hex.publish --yes` with `env: HEX_API_KEY: ${{ secrets.HEX_API_KEY }}`.

## One-time maintainer setup (outside this repo)

Generate a write-scoped Hex key and store it as the `HEX_API_KEY` GitHub Actions secret:

```bash
mix hex.user key generate --key-name defconst-ci --permission api:write
# Repo → Settings → Secrets and variables → Actions → New secret: HEX_API_KEY
```

## Verification

- `actionlint` + YAML parse of `release.yml`.
- Local unit test of the version-gate shell logic: matching tag passes, mismatched tag exits
  non-zero.
- End-to-end publish is exercised only by a real GitHub Release; the tag gate + `--yes` make
  an accidental/incorrect publish safe to prevent (mismatch aborts before publishing).

## Out of scope

- Changing `ci.yml`.
- Auto-creating the git tag / GitHub Release (the maintainer creates the Release; CI reacts).
- Version bumping or changelog automation.

## Success criteria

- Publishing a GitHub Release whose tag matches `mix.exs` `@version` publishes the package +
  docs to Hex via CI, with no local `mix hex.publish` needed.
- A release whose tag does not match `@version` fails the workflow before publishing.
- A release on a commit not on `origin/main` fails the workflow before publishing.
- `actionlint` is clean; the version-gate logic is unit-tested locally.
