#!/usr/bin/env bats

load test_helper

@test "test task selects Rush and preserves BATS arguments" {
  mock_dir="$BATS_TEST_TMPDIR/mock-bin"
  export BATS_LOG="$BATS_TEST_TMPDIR/bats.log"
  mkdir -p "$mock_dir"

  cat > "$mock_dir/bats" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'parallel=%s\n' "${BATS_PARALLEL_BINARY_NAME:-}" > "$BATS_LOG"
for argument in "$@"; do
  printf 'arg=%s\n' "$argument" >> "$BATS_LOG"
done
SH
  chmod +x "$mock_dir/bats"

  BATS_COMMAND="$mock_dir/bats" \
    run desks test --jobs 4 --filter doctor skeleton

  [ "$status" -eq 0 ]
  grep -Fx "parallel=rush" "$BATS_LOG"
  grep -Fx "arg=--print-output-on-failure" "$BATS_LOG"
  grep -Fx "arg=--jobs" "$BATS_LOG"
  grep -Fx "arg=4" "$BATS_LOG"
  grep -Fx "arg=--filter" "$BATS_LOG"
  grep -Fx "arg=doctor" "$BATS_LOG"
  grep -Fx "arg=$REPO_DIR/test/skeleton.bats" "$BATS_LOG"
  ! grep -Fx "arg=--no-parallelize-across-files" "$BATS_LOG"

  BATS_COMMAND="$mock_dir/bats" \
    run desks test --jobs 4 --filter "doctor output" skeleton

  [ "$status" -eq 0 ]
  grep -Fx "arg=doctor output" "$BATS_LOG"
  grep -Fx "arg=--no-parallelize-across-files" "$BATS_LOG"
}

@test "serial test path preserves a target containing whitespace" {
  probe_dir="$BATS_TEST_TMPDIR/serial probe"
  mkdir -p "$probe_dir"
  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"serial probe passes\" {"
    printf '%s\n' '  true' '}'
  } > "$probe_dir/passing test.bats"

  BATS_PARALLEL_BINARY_NAME=missing \
    run desks test --jobs 1 "$probe_dir/passing test.bats"

  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
}

@test "public test path runs tests within one BATS file concurrently" {
  probe_dir="$BATS_TEST_TMPDIR/within file probe"
  export PROBE_DIR="$BATS_TEST_TMPDIR/within-file-barrier"
  mkdir -p "$probe_dir" "$PROBE_DIR"

  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"first test observes second test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/one"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/two" ] || return 0
    sleep 0.05
  done
  false
}
BATS
    printf '%s\n' "$test_keyword \"second test observes first test\" {"
    cat <<'BATS'
  touch "$PROBE_DIR/two"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/one" ] || return 0
    sleep 0.05
  done
  false
}
BATS
  } > "$probe_dir/within-file.bats"

  run desks test --jobs 4 "$probe_dir/within-file.bats"

  [ "$status" -eq 0 ]
}
