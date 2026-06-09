#!/usr/bin/env bats

load test_helper

setup() {
  export DESKS_ROOT="$BATS_TEST_TMPDIR/desks"
  unset DESK_ROOT
  unset DESKS_CALLER_PWD
}

@test "new creates a minimal desk registry" {
  run desks new --id alpha
  [ "$status" -eq 0 ]

  desk_root="$output"
  [ -d "$desk_root/.desk" ]
  [ -f "$desk_root/.desk/registry.json" ]

  run jq -r '.schema, .id, .root, (.created_at | test("^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"))' "$desk_root/.desk/registry.json"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "1" ]
  [ "${lines[1]}" = "alpha" ]
  [ "${lines[2]}" = "$desk_root" ]
  [ "${lines[3]}" = "true" ]
}

@test "new generates a path-safe id when omitted" {
  run desks new
  [ "$status" -eq 0 ]

  desk_root="$output"
  id="${desk_root##*/}"
  [[ "$id" == desk-* ]]

  run jq -r '.id' "$desk_root/.desk/registry.json"
  [ "$status" -eq 0 ]
  [ "$output" = "$id" ]
}

@test "new rejects invalid and duplicate ids" {
  run desks new --id bad/id
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid desk id"* ]]

  run desks new --id alpha
  [ "$status" -eq 0 ]

  run desks new --id alpha
  [ "$status" -ne 0 ]
  [[ "$output" == *"desk already exists: alpha"* ]]
}

@test "list is quiet for an empty store and can emit JSON" {
  run desks list
  [ "$status" -eq 0 ]
  [ "$output" = "" ]

  run desks list --json
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]

  mkdir -p "$DESKS_ROOT"
  run desks list --json
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "list shows accessible desk ids" {
  run desks new --id beta
  [ "$status" -eq 0 ]
  run desks new --id alpha
  [ "$status" -eq 0 ]

  run desks list
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "alpha" ]
  [ "${lines[1]}" = "beta" ]

  run desks list --json
  [ "$status" -eq 0 ]
  run jq -r 'length, .[0].id, .[1].id' <<< "$output"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "2" ]
  [ "${lines[1]}" = "alpha" ]
  [ "${lines[2]}" = "beta" ]
}

@test "path and show inspect another accessible desk" {
  run desks new --id alpha
  [ "$status" -eq 0 ]
  desk_root="$output"

  run desks path alpha
  [ "$status" -eq 0 ]
  [ "$output" = "$desk_root" ]

  run desks show alpha
  [ "$status" -eq 0 ]
  run jq -r '.id, .root' <<< "$output"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "alpha" ]
  [ "${lines[1]}" = "$desk_root" ]
}

@test "mine resolves current desk from nested caller cwd" {
  run desks new --id alpha
  [ "$status" -eq 0 ]
  desk_root="$output"
  nested="$desk_root/some/nested/path"
  mkdir -p "$nested"

  cd "$nested"
  run desks mine
  [ "$status" -eq 0 ]
  [ "$output" = "$desk_root" ]

  run desks mine --json
  [ "$status" -eq 0 ]
  run jq -r '.id' <<< "$output"
  [ "$status" -eq 0 ]
  [ "$output" = "alpha" ]
}

@test "mine can use DESK_ROOT override and fails clearly outside desks" {
  run desks mine
  [ "$status" -ne 0 ]
  [[ "$output" == *"not inside a desk"* ]]

  run desks new --id alpha
  [ "$status" -eq 0 ]
  desk_root="$output"

  DESK_ROOT="$desk_root" run desks mine
  [ "$status" -eq 0 ]
  [ "$output" = "$desk_root" ]
}

@test "relative DESKS_ROOT and DESK_ROOT resolve against caller cwd" {
  workspace="$BATS_TEST_TMPDIR/workspace"
  mkdir -p "$workspace"
  cd "$workspace"

  DESKS_ROOT="local-desks" run desks new --id alpha
  [ "$status" -eq 0 ]
  desk_root="$output"
  canonical_workspace="$(cd "$workspace" && pwd -P)"
  [ "$desk_root" = "$canonical_workspace/local-desks/alpha" ]

  DESKS_ROOT="local-desks" run desks path alpha
  [ "$status" -eq 0 ]
  [ "$output" = "$desk_root" ]

  DESK_ROOT="local-desks/alpha" run desks mine
  [ "$status" -eq 0 ]
  [ "$output" = "$desk_root" ]
}
