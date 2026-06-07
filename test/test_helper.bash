#!/usr/bin/env bash
# Shared fixtures for desks tests.

# Run a repo task through mise so tests exercise the real task path.
desks() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f desks
