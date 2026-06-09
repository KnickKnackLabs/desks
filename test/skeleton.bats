#!/usr/bin/env bats

load test_helper

@test "standard skeleton surfaces exist" {
  for path in \
    mise.toml \
    README.tsx \
    README.md \
    CONTRIBUTING.md \
    .mise/tasks/new \
    .mise/tasks/mine \
    .mise/tasks/list \
    .mise/tasks/show \
    .mise/tasks/path \
    .mise/tasks/test \
    .mise/tasks/doctor \
    .github/workflows/test.yml \
    lib/desks.sh
  do
    [ -e "$REPO_DIR/$path" ]
  done
}

@test "README.md is generated from README.tsx" {
  run bash -c 'cd "$REPO_DIR" && readme build --check'
  [ "$status" -eq 0 ]
}

@test "doctor reports optional pre-commit hook state" {
  run desks doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"pre-commit"* ]]
}
