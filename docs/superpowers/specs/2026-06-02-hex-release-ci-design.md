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
| Safety gate | Verify the release tag (minus leading `v`) equals `mix.exs` `@version`; fail on mismatch    |
| Auth        | `HEX_API_KEY` repo secret, passed as env to the publish step                                |
| Toolchain   | Elixir 1.19 / OTP 28 (where ex_doc 0.40 builds; docs publishing needs dev-only ex_doc)      |
| Deps        | Full `mix deps.get` (dev deps incl. ex_doc) — NOT `--only test`, because docs are published |
| Existing CI | `ci.yml` unchanged; this is a separate release-only workflow                                |

## Component

New file `.github/workflows/release.yml`, one `publish` job:

1. `actions/checkout@v4` (checks out the released tag's commit).
2. `erlef/setup-beam@v1` with Elixir 1.19 / OTP 28.
3. **Safety gate** — parse `@version` from `mix.exs` via grep (no compile needed), strip the
   leading `v` from `GITHUB_REF_NAME`, fail with `::error::` if they differ.
4. `mix deps.get`.
5. `mix hex.publish --yes` with `env: HEX_API_KEY: ${{ secrets.HEX_API_KEY }}`.

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
- `actionlint` is clean; the version-gate logic is unit-tested locally.
