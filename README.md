<div align="center">

# desks

**A prepared KKL tool repo for the desks lane.**

The room is wired; the workbench is still intentionally empty.

![shape: mise + BATS](https://img.shields.io/badge/shape-mise%20%2B%20BATS-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![tests: 3](https://img.shields.io/badge/tests-3-brightgreen?style=flat)](test/)
![lints: 9](https://img.shields.io/badge/lints-9-blue?style=flat)
![README: TSX](https://img.shields.io/badge/README-TSX-f472b6?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

<br />

## What this is

`desks` is currently infrastructure-only repo prep for the desks lane: mise-managed tasks, BATS tests, codebase convention lints, generated README, CI, and a `doctor` task that tells you whether your clone has the optional local pre-commit hook installed.

It intentionally does **not** define the desks product behavior yet. The desks lead/sibling owns that direction; this repo just makes the empty room safe to work in.

## Quick start

```bash
gh repo clone KnickKnackLabs/desks
cd desks

mise trust
mise install
mise run test
mise run doctor

# Optional local safety net: installs .git/hooks/pre-commit.d/codebase
codebase pre-commit
```

## Goodies baked in

| Goodie            | Why it exists                                                                                            | Where                        |
| ----------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------- |
| Generated README  | TSX can count tests, list tasks, and keep docs honest in CI.                                             | `README.tsx`                 |
| Doctor hook check | Local pre-commit hooks are clone-local, so the repo can report them without pretending they are tracked. | `mise run doctor`            |
| Convention lints  | Best-practice drift gets caught as code, not folklore.                                                   | `[_.codebase].lint`          |
| Real test path    | BATS tests call tasks through `mise run`, not raw scripts.                                               | `test/test_helper.bash`      |
| Mac + Linux CI    | Bash and tooling differences show up before merge.                                                       | ubuntu-latest + macos-latest |

## Scaffold inventory

| Path                         | Status | Purpose                                     |
| ---------------------------- | ------ | ------------------------------------------- |
| `mise.toml`                  | ✓      | tools, settings, and codebase lint config   |
| `README.tsx`                 | ✓      | programmable README source                  |
| `CONTRIBUTING.md`            | ✓      | repo-entry orientation surface              |
| `.mise/tasks/test`           | ✓      | canonical BATS runner                       |
| `.mise/tasks/doctor`         | ✓      | local health check plus hook hint           |
| `.github/workflows/test.yml` | ✓      | Ubuntu/macOS CI                             |
| `test/`                      | ✓      | BATS smoke coverage                         |
| `lib/`                       | ✓      | shared runtime code starts here when needed |

## Tasks

| Task              | Description                   |
| ----------------- | ----------------------------- |
| `mise run doctor` | Check local development setup |
| `mise run test`   | Run BATS tests                |

## When product work starts

1. Keep the first behavior slice small enough to validate with BATS.
2. Add real task files under `.mise/tasks/`; use `$MISE_CONFIG_ROOT` inside tasks only.
3. Put shared Bash helpers in `lib/` only once multiple tasks need them.
4. If the installed tool resolves caller-relative paths, read the shiv-provided `DESKS_CALLER_PWD` variable, not generic `CALLER_PWD`.
5. Update this README from repo-prep language to actual user workflows once those workflows exist.

<details>
<summary><b>Current convention checks</b></summary>

This repo currently asks [codebase](https://github.com/KnickKnackLabs/codebase) to run these lint rules:

```
mise-settings
bats-test-helper
bats-test-task
mcr-scope
or-true
shellcheck
gum-table
caller-pwd-contract
github-actions
```

</details>

## Validation

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```

The starter suite currently has **3 tests** and **2 public tasks**. Those numbers are read from the repo at README build time.

<div align="center">

---

<sub>
This README was generated from `README.tsx` with [KnickKnackLabs/readme](https://github.com/KnickKnackLabs/readme).<br />A wired room is not a product, but it is a better place to start one.
</sub></div>
