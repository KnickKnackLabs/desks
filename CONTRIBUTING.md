# Contributing to desks

`desks` is being prepared as a KnickKnackLabs tool repo for the desks lane.
This initial state is infrastructure only: product behavior, command names, and workflow semantics still belong to the desks lead/sibling.

## Structure

```text
desks/
├── mise.toml              # Tools, settings, codebase lint config
├── README.tsx             # Source for generated README.md
├── README.md              # Generated; keep in sync with README.tsx
├── CONTRIBUTING.md        # Repo orientation surface
├── .mise/tasks/test       # Canonical BATS runner
├── .mise/tasks/doctor     # Local health checks + optional hook status
├── lib/                   # Shared runtime code once multiple tasks need it
└── test/                  # BATS tests and helpers
```

## Local setup

```bash
mise trust
mise install
mise run test
mise run doctor
```

`doctor` reports whether the optional local `codebase pre-commit` hook is installed.
Install it in your clone when you want convention lints to run before every commit:

```bash
codebase pre-commit
```

The hook lives under `.git/hooks/`, so it is intentionally not tracked by the repo.

## README workflow

Edit `README.tsx`, then regenerate and check the output:

```bash
readme build
readme build --check
```

CI also checks that `README.md` matches `README.tsx`.

## Product boundary

Do not treat this skeleton as approval for a specific desks product shape.
Before adding real behavior, start from the desks concept owner/lead handoff and agree on the first workflow slice.

## Validation before merge

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```
