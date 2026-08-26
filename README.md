<div align="center">

# desks

**Create and discover bounded working surfaces.**

A desk is a place to work, not a theory of who sits there.

![shape: mise + BATS](https://img.shields.io/badge/shape-mise%20%2B%20BATS-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![tests: 18](https://img.shields.io/badge/tests-18-brightgreen?style=flat)](test/)
![lints: 17](https://img.shields.io/badge/lints-17-blue?style=flat)
![README: TSX](https://img.shields.io/badge/README-TSX-f472b6?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

<br />

## What this is

`desks` creates small, discoverable filesystem work surfaces. A desk has an id, a root path, and a tiny `.desk/registry.json` file. Higher-level tools can decide whether that surface belongs to an agent, a shell, a project, or something else.

The first slice is intentionally generic: create desks, find the current desk, list accessible desks, inspect a registry, and print a desk path. Briefs, agent-home preparation, session launch, and fold harvest policy stay outside core for now.

## Quick start

```bash
# Intended installed usage after desks is registered with shiv:
# [tools]
# "shiv:desks" = "0.1"
# Then, after mise install, use the installed shim:
export DESKS_ROOT=/tmp/desks-demo
desk=$(desks new --id demo)
DESK_ROOT="$desk" desks mine
DESK_ROOT="$desk" desks mine --json

desks list
desks show demo
desks path demo

# Contributing to this repo still uses mise:
gh repo clone KnickKnackLabs/desks
cd desks
mise trust && mise install
mise run test
mise run doctor
```

## Goodies baked in

| Goodie            | Why it exists                                                                                            | Where                        |
| ----------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------- |
| Generic core      | Core metadata does not know about agents, sessions, homes, briefs, or chat.                              | `.desk/registry.json`        |
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
| `.mise/tasks/new`            | ✓      | create a desk                               |
| `.mise/tasks/mine`           | ✓      | resolve the current desk                    |
| `.mise/tasks/list`           | ✓      | list accessible desks                       |
| `.mise/tasks/show`           | ✓      | show a desk registry                        |
| `.mise/tasks/path`           | ✓      | print a desk root                           |
| `.mise/tasks/test`           | ✓      | canonical BATS runner                       |
| `.mise/tasks/doctor`         | ✓      | local health check plus hook hint           |
| `.github/workflows/test.yml` | ✓      | Ubuntu/macOS CI                             |
| `test/`                      | ✓      | BATS smoke coverage                         |
| `lib/`                       | ✓      | shared runtime code starts here when needed |

## Tasks

| Task              | Description                   |
| ----------------- | ----------------------------- |
| `mise run doctor` | Check local development setup |
| `mise run list`   | List accessible desks         |
| `mise run mine`   | Show the current desk         |
| `mise run new`    | Create a desk                 |
| `mise run path`   | Print a desk root path        |
| `mise run show`   | Show desk registry metadata   |
| `mise run test`   | Run BATS tests                |

## Core boundary

1. `desks` owns desk ids, roots, discovery, and minimal registry metadata.
2. It does not own agent identity, session identity, home checkout preparation, desk briefs, `chat` transport, or fold harvest policy.
3. Callers can put their own files under a desk after creating it.
4. Installed usage goes through the shiv-provided `desks` shim; repo tests use `mise run` only to exercise that task path locally.
5. Tasks use `$MISE_CONFIG_ROOT` inside the repo and `DESKS_CALLER_PWD` for caller-cwd discovery from the installed shim.

<details>
<summary><b>Current convention checks</b></summary>

This repo currently asks [codebase](https://github.com/KnickKnackLabs/codebase) to run these lint rules:

```
shellcheck
or-true
bash-empty-argv-forwarding
bash-empty-array-expansions
exec-stderr-persistence
gum-table
mise-settings
mise-usage-examples
variadic-args
mcr-scope
bats-test-helper
bats-test-task
bats-public-task-path
github-actions
ci-lint-enforcement
caller-pwd-contract
mise-shiv-plugin
```

</details>

## Validation

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```

The starter suite currently has **18 tests** and **7 public tasks**. Those numbers are read from the repo at README build time.

<div align="center">

---

<sub>
This README was generated from `README.tsx` with [KnickKnackLabs/readme](https://github.com/KnickKnackLabs/readme).<br />A desk is useful before it knows who will sit down.
</sub></div>
