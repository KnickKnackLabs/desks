# Contributing to desks

`desks` creates and discovers bounded filesystem work surfaces.

The first behavior slice is intentionally generic: desks have ids, roots, and minimal registry metadata. Core `desks` does not know about agents, sessions, homes, briefs, `chat`, or fold harvest policy.

## Structure

```text
desks/
├── mise.toml              # Tools, settings, codebase lint config
├── README.tsx             # Source for generated README.md
├── README.md              # Generated; keep in sync with README.tsx
├── CONTRIBUTING.md        # Repo orientation surface
├── .mise/tasks/new        # Create a desk
├── .mise/tasks/mine       # Resolve the current desk
├── .mise/tasks/list       # List accessible desks
├── .mise/tasks/show       # Show desk registry metadata
├── .mise/tasks/path       # Print a desk root path
├── .mise/tasks/test       # Canonical BATS runner
├── .mise/tasks/doctor     # Local health checks + optional hook status
├── lib/desks.sh           # Shared task logic
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

## Core boundary

Keep core `desks` generic.

Do not add agent, session, home, brief, or transport semantics to core metadata just because a current caller happens to be an agent workflow. Higher-level tools can create their own files under a desk or maintain their own metadata keyed by desk id.

Current MVP registry shape:

```json
{
  "schema": 1,
  "id": "demo",
  "root": "/path/to/demo",
  "created_at": "2026-06-07T03:15:00Z"
}
```

If you want to add a field, first ask whether it belongs to core desks or to a caller/provisioner layer.

## Validation before merge

```bash
mise run test
mise run doctor
codebase lint "$PWD"
readme build --check
git diff --check
```
