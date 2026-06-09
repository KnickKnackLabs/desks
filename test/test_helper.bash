#!/usr/bin/env bash
# Shared fixtures for desks tests.

# Run a repo task through mise so tests exercise the real task path.
# Preserve the caller cwd the way a shiv-installed desks command would.
desks() {
  local caller_pwd
  caller_pwd="$PWD"
  DESKS_CALLER_PWD="$caller_pwd" mise -C "$REPO_DIR" run -q "$@"
}
export -f desks
