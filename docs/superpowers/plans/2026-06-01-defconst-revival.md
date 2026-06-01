# Defconst Revival & Republish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revive the dormant `defconst` Elixir library — reconcile the published 0.2.5 onto master, fix deprecations, modernize dev dependencies, add tests + CI, and prepare a `0.3.0` release delivered via a pull request, with Hex publish gated to the maintainer.

**Architecture:** A small (~280 LOC) pure-macro Elixir library with no runtime dependencies. The published 0.2.5 lives on an unmerged branch; we reconcile it to `master` first, then layer the 0.3.0 modernization on top. The existing ExUnit + doctest suite (plus new `constant_of/1` tests) is the regression gate — run it after every change.

**Tech Stack:** Elixir 1.19 / Erlang OTP 28.1+, Mix, ExUnit, ex_doc, asdf, GitHub Actions (`erlef/setup-beam`).

**Spec:** `docs/superpowers/specs/2026-06-01-defconst-revival-design.md`

**Branch:** 0.3.0 work lands on `revive-and-modernize` (created off the _reconciled_ master). The spec is already committed there and will be carried across the rebase in Task 1.

---

## File Structure

- `master` branch — **Reconciled via PR.** Bring it up to published 0.2.5 (`origin/aram356/udpdate_ex_doc`) through a pull request, not a direct push. Locally fast-forward only to base the work branch.
- `.tool-versions` — **Create.** Pins `elixir 1.19.5-otp-28` + real `erlang 28.1+`.
- `.gitignore` — **Modify.** Add `.DS_Store`.
- `config/config.exs` — **Delete.** Deprecated `use Mix.Config`; no runtime config exists.
- `lib/defconst.ex` — **Modify.** Fix `value_of` doc example, rename `normalize_contant`, document `constant_of` return shape.
- `test/defconst_test.exs` — **Modify.** Add `constant_of/1` list + nil coverage.
- `mix.exs` — **Modify.** Bump `ex_doc`, raise `elixir:` floor, bump version, add CHANGELOG to `package.files`.
- `mix.lock` — **Delete + regenerate.**
- `.github/workflows/ci.yml` — **Create.** CI matrix.
- `CHANGELOG.md` — **Create.** Baseline "since 0.2.5".
- `README.md` — **Modify.** Fix version drift, document introspection functions.

---

## Task 1: Reconcile published 0.2.5 onto master, rebase work branch

**Files:** git operations only.

- [ ] **Step 1: Confirm the published-baseline branch and its relationship to master**

```bash
git fetch origin
git log --oneline master..origin/aram356/udpdate_ex_doc
git show origin/aram356/udpdate_ex_doc:mix.exs | grep '@version'
```

Expected: exactly two commits ahead (`d6f5c3d Updated ex_doc`, `7b91238 Bump version`); version shows `0.2.5`. Confirms a clean fast-forward is possible.

- [ ] **Step 2: Locally fast-forward master to base the work on 0.2.5**

This is a **local** base-update only — it is NOT pushed. Remote `master` is reconciled via a PR (Step 5 / Task 8), respecting branch protection.

```bash
git checkout master
git merge --ff-only origin/aram356/udpdate_ex_doc
git log --oneline -1
```

Expected: local `master` now points at `7b91238` (0.2.5). If `--ff-only` is refused, STOP and report — do not force; the branch may have diverged unexpectedly.

- [ ] **Step 3: Rebase the work branch onto the reconciled base**

```bash
git checkout revive-and-modernize
git rebase master
```

Expected: the spec commit replays cleanly on top of 0.2.5. No conflicts are expected (only `docs/` was added on the branch).

- [ ] **Step 4: Verify reconciled state**

```bash
grep '@version' mix.exs
grep -n 'constant_of\|value_of' lib/defconst.ex | head
```

Expected: version `0.2.5`; `constant_of`/`value_of` present (they already shipped in 0.2.5).

- [ ] **Step 5: Commit the implementation plan (required)**

The plan must travel with the PR, so commit it now with a targeted add:

```bash
git add docs/superpowers/plans/2026-06-01-defconst-revival.md
git commit -m "Add 0.3.0 implementation plan"
```

> Remote `master` reconciliation (merging the published 0.2.5 commits) is delivered through
> a PR — see Task 8 Step 1. Do not `git push origin master` directly anywhere in this plan.

---

## Task 2: Toolchain & green baseline

**Files:**

- Create: `.tool-versions`

- [ ] **Step 1: Add the Erlang asdf plugin**

Run: `asdf plugin add erlang`
Expected: plugin added (or "already added" — both fine).

- [ ] **Step 2: Install a compatible OTP (≥ 28.1)**

Elixir 1.19 requires OTP **28.1+**. Install the latest 28.1.x:

```bash
asdf install erlang latest:28.1
asdf list erlang
```

Expected: an OTP `28.1.x` (or newer 28.x) version installed and listed. Note the exact version string for the next step.

> NOTE: Erlang builds from source via kerl and can take several minutes plus build deps (autoconf, OpenSSL, wxWidgets). If the build fails for missing tooling, `brew install autoconf openssl wxwidgets` and retry. One-time setup.

- [ ] **Step 3: Create `.tool-versions`**

Create `/Users/ag/projects/defconst/.tool-versions` (replace `28.1.2` with the exact version from Step 2):

```
elixir 1.19.5-otp-28
erlang 28.1.2
```

- [ ] **Step 4: Verify the toolchain resolves**

Run (from the project dir): `elixir --version`
Expected: prints Erlang/OTP 28 (28.1+) and Elixir 1.19.5 — no "erl: not found", no "No version is set".

- [ ] **Step 5: Capture the green baseline**

Run: `mix deps.get && mix test`
Expected: deps fetch, all tests pass. Record the pass count.

> If tests fail on the reconciled baseline, STOP and report — do not proceed.

- [ ] **Step 6: Commit `.tool-versions` (targeted)**

```bash
git add .tool-versions
git commit -m "Pin toolchain: Elixir 1.19.5 / OTP 28.1+"
```

---

## Task 3: Deprecation & hygiene fixes

**Files:**

- Delete: `config/config.exs`
- Modify: `lib/defconst.ex`, `.gitignore`

- [ ] **Step 1: Reconcile the OS-ignore lines in `.gitignore`**

> NOTE: the worktree **already contains** an uncommitted edit to `.gitignore` that appended
> `# OS` / `.DS_Store` / `Thumbs.db` **without a trailing newline**. Don't blindly stage it.
> Normalize it to the exact block below (single `# OS` header, both entries, **trailing
> newline restored**) so the commit in Step 8 doesn't carry a malformed file.

Ensure the end of `/Users/ag/projects/defconst/.gitignore` reads exactly:

```
# OS
.DS_Store
Thumbs.db
```

(with a terminating newline). Verify there is no duplicate header and the file ends in a
newline:

```bash
tail -3 .gitignore
test -z "$(tail -c1 .gitignore)" && echo "ends with newline" || echo "MISSING trailing newline — fix it"
```

- [ ] **Step 2: Confirm the config is inert, then delete it**

```bash
grep -n '^[^#]*config ' config/config.exs   # expect: no output (all examples are commented)
grep -rn 'Mix.Config' lib mix.exs            # expect: no output
git rm config/config.exs
```

- [ ] **Step 3: Run the suite to confirm deletion is safe**

Run: `mix test`
Expected: all tests still pass; no "could not load config" error.

- [ ] **Step 4: Fix the `value_of` doc copy-paste bug**

In `lib/defconst.ex`, the `value_of` function's `@doc` example wrongly calls `constant_of` with constant keys. Change _only that `iex>` call_ from `constant_of` to `value_of`:

```elixir
      ## Examples:
          iex> #{__MODULE__}.value_of(#{
        unquote(constants)
        |> Keyword.keys()
        |> List.first()
        |> Kernel.inspect()
      })
          #{unquote(constants) |> Keyword.values() |> List.first() |> Kernel.inspect()}
```

(Keep the surrounding heredoc indentation as it exists post-0.2.5 reformat. The semantic fix is `constant_of` → `value_of`; the body already passes a key via `Keyword.keys()` and shows the value via `Keyword.values()`.)

- [ ] **Step 5: Rename the `normalize_contant` typo**

```bash
sed -i '' 's/normalize_contant/normalize_constant/g' lib/defconst.ex
grep -c 'normalize_constant' lib/defconst.ex   # expect: 3
grep -c 'normalize_contant'  lib/defconst.ex   # expect: 0
```

- [ ] **Step 6: Document `constant_of/1`'s polymorphic return**

In `lib/defconst.ex`, add a `## Returns:` block inside the `constant_of` `@doc`, immediately before its `## Examples:` line:

```elixir
      ## Returns:
        * the matching constant name when the value is unique
        * a list of constant names when multiple constants share the value
        * `nil` when no constant has the value

```

- [ ] **Step 7: Run the suite + formatter**

Run: `mix test && mix format --check-formatted`
Expected: tests pass; formatter clean. If formatter complains, `mix format` then re-check.

- [ ] **Step 8: Commit (targeted)**

The `config/config.exs` deletion was already staged by Step 2's `git rm`. Stage the rest with targeted adds (do **not** re-run `git rm` — the path is already gone from the index and the command would error). Confirm the `.gitignore` you stage is the **normalized** version from Step 1 (both OS entries, trailing newline) — review `git diff .gitignore` before adding:

```bash
git diff .gitignore   # confirm: only the # OS / .DS_Store / Thumbs.db block, ends in newline
git add lib/defconst.ex .gitignore
git commit -m "Remove deprecated Mix.Config, fix value_of doc, rename typo, document constant_of, ignore OS files"
```

> If for any reason the deletion is not yet staged, stage it with `git add -u config/config.exs` (records the removal) rather than another `git rm`.

---

## Task 4: Test the `constant_of/1` contract (characterization / regression)

**Files:**

- Modify: `test/defconst_test.exs`

> These are characterization tests: the behavior already exists in the source, so they are
> expected to **pass on first run**. They lock the documented `constant_of/1` contract in
> place — this is not red-green TDD.

- [ ] **Step 1: Write the characterization tests**

Add a new `describe` block to `test/defconst_test.exs` with a fixture module that has a duplicate value, covering the list and `nil` paths:

```elixir
  describe "constant_of edge cases" do
    defmodule TestDupConst do
      use Defconst

      defconst :a, 1
      defconst :b, 2
      defconst :c, 1
    end

    test "returns a list when multiple constants share a value" do
      require TestDupConst
      assert TestDupConst.constant_of(1) == [:a, :c]
    end

    test "returns the single constant when the value is unique" do
      require TestDupConst
      assert TestDupConst.constant_of(2) == :b
    end

    test "returns nil when no constant has the value" do
      require TestDupConst
      assert TestDupConst.constant_of(999) == nil
    end
  end
```

- [ ] **Step 2: Run the new tests to confirm current behavior**

Run the whole file (ExUnit's `--only`/`-o` filters *tags*, not `describe`/`test` names, so a name filter would silently match zero tests):

```bash
mix test test/defconst_test.exs
```
To run only the inserted cases, target them by line number instead, e.g. `mix test test/defconst_test.exs:251` (use the actual line of each new `test`).

Expected: the three new tests **pass** because the existing `constant_of` already implements list/nil correctly. If any fail, that is a real behavior bug — STOP and report actual vs. expected before changing source.

> Note: `constant_of` already builds a `value_map` accumulating multiple names per value and returns `nil` for missing keys (the `case constants do [constant] -> ...; _ -> constants end` path returns the list, and `nil` falls through as `_`). These tests lock that documented contract in place.

- [ ] **Step 3: Commit (targeted)**

```bash
git add test/defconst_test.exs
git commit -m "Test constant_of/1 list and nil contract"
```

---

## Task 5: Dependency & support modernization

**Files:**

- Modify: `mix.exs`
- Delete + regenerate: `mix.lock`

- [ ] **Step 1: Bump `ex_doc` and set the Elixir floor**

In `mix.exs`, change the deps entry from `{:ex_doc, "~> 0.20", ...}` (the constraint is `~> 0.20` even post-reconcile — only `mix.lock` resolved to 0.21.2) to:

```elixir
    [{:ex_doc, "~> 0.40", only: :dev, runtime: false}]
```

Intent: **track the latest pre-1.0 ex_doc.** `~> 0.40` means `>= 0.40.0 and < 1.0.0`, so it
admits future `0.4x`/`0.5x` releases — not just `0.40.x`. That is deliberate (we always want
the newest doc tooling); the exact resolved version is pinned in `mix.lock` on regenerate.
(If you instead wanted to stay on the 0.40 patch line only, you would write `~> 0.40.0`.)

ex_doc is `only: :dev, runtime: false`, so it is needed only for `mix docs` on the dev
machine (OTP 28 / Elixir 1.19) — not by consumers and not by the CI test jobs (those use
`mix deps.get --only test`, see Task 6). This keeps the `~> 1.15` floor honest **for
runtime and test usage**: latest ex_doc may require a newer Elixir than 1.15, but it is
never resolved on the 1.15/1.16 CI jobs. Docs are maintained on Elixir 1.19 — a full
contributor `mix deps.get` (which pulls dev deps) is expected to run on 1.19, not 1.15.
Verify `mix docs` locally in Step 4.

And change the project's Elixir requirement from:

```elixir
      elixir: "~> 1.6",
```

to:

```elixir
      elixir: "~> 1.15",
```

- [ ] **Step 2: Regenerate the lockfile**

```bash
rm mix.lock
mix deps.get
grep -c 'earmark_parser' mix.lock   # expect: 1
grep '"earmark":' mix.lock          # expect: no output (legacy earmark gone)
```

- [ ] **Step 3: Confirm the suite still passes**

Run: `mix test`
Expected: all tests pass (runtime code unchanged).

- [ ] **Step 4: Confirm docs build on OTP 28**

Run: `mix docs`
Expected: docs generate into `doc/` (gitignored) with no errors.

- [ ] **Step 5: Commit (targeted)**

```bash
git add mix.exs mix.lock
git commit -m "Modernize ex_doc to ~> 0.40 (latest), set Elixir floor to ~> 1.15, regenerate lockfile"
```

---

## Task 6: Continuous integration

**Files:**

- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the workflow file**

Create `/Users/ag/projects/defconst/.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - elixir: "1.15"
            otp: "26"
          - elixir: "1.16"
            otp: "26"
          - elixir: "1.17"
            otp: "26"
          - elixir: "1.18"
            otp: "27"
          - elixir: "1.19"
            otp: "28"
    name: Test (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }})
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
      - name: Restore deps cache
        uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-
      - run: mix deps.get --only test
      - run: mix test

  format:
    runs-on: ubuntu-latest
    name: Format (Elixir 1.19 / OTP 28)
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19"
          otp-version: "28"
      - run: mix format --check-formatted
```

Formatter output can differ between Elixir releases, so `mix format --check-formatted` runs
in a **single** pinned `format` job (1.19), while compile/test runs across the full matrix.

- [ ] **Step 2: Validate the YAML locally**

Run: `ruby -ryaml -e "YAML.load_file('.github/workflows/ci.yml'); puts 'valid'"`
Expected: prints `valid`.

- [ ] **Step 3: Commit (targeted)**

```bash
git add .github/workflows/ci.yml
git commit -m "Add GitHub Actions CI matrix (Elixir 1.15-1.19 / OTP 26-28)"
```

> The dedicated `format` job runs `mix format --check-formatted` on a single Elixir version; the tree was formatted in Task 3 Step 7. The test matrix runs compile/test only.

---

## Task 7: Release prep

**Files:**

- Modify: `mix.exs`, `README.md`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Bump the project version**

In `mix.exs`, change `@version "0.2.5"` → `@version "0.3.0"`.

- [ ] **Step 2: Add `CHANGELOG.md` to the package files**

In `mix.exs`, update `package/0`'s `files:` list to include the changelog:

```elixir
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
```

- [ ] **Step 3: Create `CHANGELOG.md` (baseline "since 0.2.5")**

Create `/Users/ag/projects/defconst/CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-06-01

### Added

- GitHub Actions CI across Elixir 1.15–1.19 / OTP 26–28 (test matrix + dedicated format job).
- Pinned toolchain via `.tool-versions` (Elixir 1.19.5 / OTP 28.1+).
- Test coverage for `constant_of/1` duplicate-value (list) and missing-value (`nil`) paths.
- `CHANGELOG.md` (now shipped in the Hex package).

### Changed

- Declared minimum supported Elixir as `~> 1.15`, now verified in CI (was an unverified `~> 1.6`).
- Modernized `ex_doc` to the latest line, `~> 0.40` (dev-only; no runtime impact).

### Removed

- Deprecated `config/config.exs` (`use Mix.Config`); the library has no runtime config.

### Fixed

- Corrected the `value_of/1` documentation example (it referenced `constant_of`).
- Renamed internal `normalize_contant` typo to `normalize_constant`.
- Documented `constant_of/1`'s polymorphic return (name / list / `nil`).

## [0.2.5] - 2020-01-08

Last previously published release. Included `constants/0`, `constant_of/1`, `value_of/1`,
and `ex_doc 0.21`.
```

- [ ] **Step 4: Update the README**

In `README.md`: change `{:defconst, "~> 0.2.2"}` → `{:defconst, "~> 0.3.0"}`, then add an introspection section after the `### defconst` example:

````markdown
### Introspection

Modules that `use Defconst` also expose:

- `constants/0` — all constants as `[{name, value}, ...]`
- `value_of/1` — the value for a constant name
- `constant_of/1` — the constant name for a value (a list if several share the value, `nil` if none)

```elixir
ConstType1.constants()        #=> [{:one, 1}, {:two, 2}]
ConstType1.value_of(:one)     #=> 1
ConstType1.constant_of(2)     #=> :two
```
````

- [ ] **Step 5: Verify build, tests, formatting, and package tarball**

```bash
mix test
mix format --check-formatted
mix hex.build
```

Expected: tests pass; formatter clean; `mix hex.build` succeeds and its printed file list **includes `CHANGELOG.md`**. Optionally review `mix hex.publish --dry-run` (does not publish) to confirm metadata.

- [ ] **Step 6: Commit (targeted)**

```bash
git add mix.exs CHANGELOG.md README.md
git commit -m "Prepare 0.3.0 release: version bump, changelog, README, package files"
```

---

## Task 8: Delivery (MR / pull request)

**Files:** none (git/GitHub operations only)

- [ ] **Step 1: Reconcile remote master via PR, then push the feature branch**

Do **not** `git push origin master`. Reconcile the published 0.2.5 onto remote `master`
through a PR instead. Choose one:

- **Option A (separate reconcile PR, cleaner history):** open a PR from the existing
  published branch into master and merge it first:

  ```bash
  gh pr create --base master --head aram356/udpdate_ex_doc \
    --title "Reconcile published 0.2.5 onto master" \
    --body "master was behind Hex; this merges the published 0.2.5 commits (was on aram356/udpdate_ex_doc)."
  ```

  After it merges, the revival PR (Step 2) targets the reconciled master.

- **Option B (fold into the revival PR):** skip the separate PR; the revival PR already
  contains the 0.2.5 commits (the work branch was rebased onto them in Task 1). Call this
  out explicitly in the PR body.

Then push the work branch:

```bash
git push -u origin revive-and-modernize
```

Before opening the revival PR, **verify the diff against remote master** so you know exactly
what the PR will contain:

```bash
git fetch origin
git log --oneline origin/master..revive-and-modernize
```

- If you took **Option A** (remote master already reconciled): the list shows only the
  revival commits.
- If you took **Option B** (folding in): the list shows the **two 0.2.5 commits**
  (`d6f5c3d`, `7b91238`) **plus** the revival commits. Confirm both are present — that
  confirms the PR carries the reconciliation.

- [ ] **Step 2: Open the pull request**

```bash
gh pr create --base master --head revive-and-modernize \
  --title "Revive & modernize defconst for 0.3.0" \
  --body "$(cat <<'EOF'
Revives the dormant library and prepares a 0.3.0 release.

## Reconciliation
- master was behind the published 0.2.5 (it lived on aram356/udpdate_ex_doc). This work is based on the reconciled 0.2.5 baseline.

## Changes
- Pin toolchain (Elixir 1.19.5 / OTP 28.1+) via .tool-versions; ignore .DS_Store
- Remove deprecated config/config.exs (use Mix.Config)
- Fix value_of doc example; rename normalize_contant typo; document constant_of return shape
- Add tests for constant_of/1 list + nil paths
- Modernize ex_doc to latest ~> 0.40 (dev-only); keep Elixir floor at ~> 1.15 (CI-verified); regenerate mix.lock
- Add GitHub Actions CI: test matrix (Elixir 1.15-1.19 / OTP 26-28) + dedicated format job
- 0.3.0: version bump, CHANGELOG (since 0.2.5), README updates, CHANGELOG added to package files

## Verification
- mix test green locally on OTP 28.1+
- mix format --check-formatted clean
- mix docs builds; mix hex.build includes CHANGELOG.md

See docs/superpowers/specs/2026-06-01-defconst-revival-design.md for the design.
EOF
)"
```

Expected: PR URL printed.

- [ ] **Step 3: Confirm CI passes on the PR**

Run: `gh pr checks --watch`
Expected: all six jobs succeed — five test jobs (1.15/26, 1.16/26, 1.17/26, 1.18/27, 1.19/28) plus the format job (1.19/28). Fix-and-push on failure; do not proceed to publish until green.

---

## Task 9: Publish — GATED HAND-OFF (maintainer action)

**Do NOT execute autonomously.** `mix hex.publish` is outward-facing, irreversible, and requires the maintainer's Hex credentials. Performed by the maintainer after merge.

- [ ] **Step 1 (maintainer): Merge the PR to `master`.**

- [ ] **Step 2 (maintainer): Tag and push the release.**

```bash
git checkout master && git pull
git tag v0.3.0
git push origin v0.3.0
```

- [ ] **Step 3 (maintainer): Publish to Hex.**

```bash
mix hex.publish
```

Expected: prompts for confirmation and publishes `defconst 0.3.0`. Requires `mix hex.user auth` with the package owner's account.

---

## Self-Review

**Spec coverage:** WS0→Task 1, WS1→Task 2, WS2→Task 3, WS3→Task 4, WS4→Task 5, WS5→Task 6, WS6→Task 7, WS7→Task 8, WS8→Task 9. No gaps.

**Placeholder scan:** No TBD/TODO placeholders; every code/config step shows complete content and exact commands. The only intentional substitution is the exact OTP patch version in `.tool-versions` (Task 2), which depends on what `asdf install` resolves.

**Review-finding coverage (round 1):** (1) 0.2.5 reconciliation → Task 1; changelog baseline "since 0.2.5" + corrected "Added" list → Task 7 Step 3. (2) targeted `git add`, `.DS_Store` ignored → all commits + Task 3. (3) CHANGELOG in `package.files` + `mix hex.build` gate → Task 7 Steps 2/5. (4) OTP ≥ 28.1 pin → Task 2. (5) CI matrix aligned to spec → Task 6. (6) Elixir floor → Task 5. (7) `constant_of/1` tests → Task 4. (8) goal reworded → header + spec.

**Review-finding coverage (round 2):** (1) floor↔CI consistency → keep `~> 1.15`, CI now tests 1.15/1.16 (Task 5 + Task 6). (2) no direct `master` push → reconciliation via PR (Task 1 Step 2 note, Task 8 Step 1). (3) Task 3 commit no longer re-runs `git rm` (uses `git add -u` fallback). (4) ex_doc constraint corrected to `~> 0.20` → `~> 0.34` *(later superseded in round 3: now `~> 0.40`, latest)* (Task 5 Step 1). (5) TDD reworded to characterization (Task 4 / spec WS3). (6) plan commit now required (Task 1 Step 5). (7) spec 0.2.5 dep wording tightened (lock-only 0.21.2).

**Review-finding coverage (round 3):** (1) ex_doc → latest `~> 0.40` per "use latest libraries"; floor risk neutralized via `mix deps.get --only test` in CI (Task 5 Step 1, Task 6). (2) wrong `-o` test filter replaced with full-file / line-target run (Task 4 Step 2). (3) Task 4 heading + step reworded to characterization (no "failing"/"TDD"). (4) `mix format --check-formatted` moved to a single-version `format` job (Task 6). (5) changelog/toolchain say OTP 28.1+ (Task 5 Step 3 changelog, PR body). (6) explicit `origin/master..revive-and-modernize` diff check added before opening the PR (Task 8 Step 1).

**Review-finding coverage (round 4):** (1) Task 7 Markdown fence bug fixed — stray fence removed, bash block closed with triple backticks. (2) ex_doc `~> 0.40` prose clarified as "latest pre-1.0, admits future 0.4x+" (Task 5 Step 1). (3) support-floor semantics clarified — `~> 1.15` covers runtime/test; docs maintained on 1.19; full dev `deps.get` expected on 1.19 (Task 5 Step 1, spec success criteria). (4) `.gitignore` reconciled — worktree already had `.DS_Store`+`Thumbs.db` sans newline; Step 1 normalizes it, Step 8 reviews `git diff` before staging. (5) success criteria reworded — CI runs tests+format only, not docs/hex.build. (6) stale round-2 ex_doc `~> 0.34` log entry annotated as superseded.

**Type/name consistency:** `normalize_constant` consistent after rename; `constants`/`constant_of`/`value_of` match source and README; version `0.3.0` consistent across `mix.exs`, `CHANGELOG.md`, README, git tag; CI pairs are mutually compatible (1.15↔26, 1.16↔26, 1.17↔26, 1.18↔27, 1.19↔28).
