#!/usr/bin/env bash
# Shared helpers for desks tasks.

set -euo pipefail

DESKS_DEFAULT_ROOT="$HOME/desks"

_desks_fail() {
  printf 'desks: %s\n' "$*" >&2
  exit 1
}

_desks_require_jq() {
  command -v jq >/dev/null 2>&1 || _desks_fail "jq is required; run mise install"
}

_desks_now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_desks_random_hex4() {
  od -An -N2 -tx1 /dev/urandom | tr -d ' \n'
}

_desks_validate_id() {
  local id="$1"
  [ -n "$id" ] || _desks_fail "desk id is required"
  printf '%s\n' "$id" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$' \
    || _desks_fail "invalid desk id: $id (use letters, numbers, dot, underscore, or dash; no slashes)"
}

_desks_canonical_existing_dir() {
  local dir="$1"
  (cd "$dir" && pwd -P)
}

_desks_canonical_path() {
  local path="$1"
  local parent base

  if [ -d "$path" ]; then
    _desks_canonical_existing_dir "$path"
    return 0
  fi

  parent=${path%/*}
  base=${path##*/}
  if [ "$parent" = "$path" ]; then
    parent="."
  fi

  if [ -d "$parent" ]; then
    printf '%s/%s\n' "$(_desks_canonical_existing_dir "$parent")" "$base"
  else
    printf '%s\n' "$path"
  fi
}

_desks_caller_pwd() {
  if [ -n "${DESKS_CALLER_PWD:-}" ]; then
    printf '%s\n' "$DESKS_CALLER_PWD"
  else
    pwd -P
  fi
}

_desks_user_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$(_desks_canonical_existing_dir "$(_desks_caller_pwd)")" "$path" ;;
  esac
}

_desks_store_root_raw() {
  _desks_user_path "${DESKS_ROOT:-$DESKS_DEFAULT_ROOT}"
}

_desks_store_root() {
  _desks_canonical_path "$(_desks_store_root_raw)"
}

_desks_ensure_store_root() {
  local raw
  raw="$(_desks_store_root_raw)"
  mkdir -p "$raw"
  _desks_canonical_existing_dir "$raw"
}

_desks_registry_path() {
  local root="$1"
  printf '%s/.desk/registry.json\n' "$root"
}

_desks_is_desk_root() {
  [ -f "$(_desks_registry_path "$1")" ]
}

_desks_root_for_id() {
  local id="$1"
  _desks_validate_id "$id"
  printf '%s/%s\n' "$(_desks_store_root)" "$id"
}

_desks_find_current_root() {
  local dir desk_root

  if [ -n "${DESK_ROOT:-}" ]; then
    desk_root="$(_desks_user_path "$DESK_ROOT")"
    if _desks_is_desk_root "$desk_root"; then
      _desks_canonical_existing_dir "$desk_root"
      return 0
    fi
    _desks_fail "DESK_ROOT is set but does not contain .desk/registry.json: $DESK_ROOT"
  fi

  dir="$(_desks_canonical_existing_dir "$(_desks_caller_pwd)")"
  while :; do
    if _desks_is_desk_root "$dir"; then
      printf '%s\n' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && break
    dir=${dir%/*}
    [ -z "$dir" ] && dir="/"
  done

  _desks_fail "not inside a desk; set DESK_ROOT or cd under a directory containing .desk/registry.json"
}

_desks_registry_for_id() {
  local id="$1"
  local root
  root="$(_desks_root_for_id "$id")"
  [ -d "$root" ] || _desks_fail "desk not found: $id"
  [ -f "$(_desks_registry_path "$root")" ] || _desks_fail "desk registry missing for: $id"
  _desks_registry_path "$root"
}

_desks_generate_id() {
  local timestamp suffix
  timestamp=$(date -u +"%Y%m%d-%H%M%S")
  suffix="$(_desks_random_hex4)"
  printf 'desk-%s-%s\n' "$timestamp" "$suffix"
}

desks_new() {
  _desks_require_jq
  local id="$1"
  local store root registry created

  if [ -z "$id" ]; then
    id="$(_desks_generate_id)"
  fi
  _desks_validate_id "$id"

  store="$(_desks_ensure_store_root)"
  root="$store/$id"
  registry="$(_desks_registry_path "$root")"
  [ ! -e "$root" ] || _desks_fail "desk already exists: $id"

  mkdir -p "$root/.desk"
  root="$(_desks_canonical_existing_dir "$root")"
  created="$(_desks_now_utc)"

  jq -n \
    --arg id "$id" \
    --arg root "$root" \
    --arg created_at "$created" \
    '{schema: 1, id: $id, root: $root, created_at: $created_at}' \
    > "$registry"

  printf '%s\n' "$root"
}

desks_path() {
  local id="$1"
  local registry
  registry="$(_desks_registry_for_id "$id")"
  jq -r '.root' "$registry"
}

desks_show() {
  local id="$1"
  cat "$(_desks_registry_for_id "$id")"
}

desks_mine() {
  local json="$1"
  local root registry
  root="$(_desks_find_current_root)"
  registry="$(_desks_registry_path "$root")"

  if [ "$json" = "true" ]; then
    cat "$registry"
  else
    printf '%s\n' "$root"
  fi
}

desks_list() {
  _desks_require_jq
  local json="$1"
  local root file first files

  root="$(_desks_store_root)"
  if [ ! -d "$root" ]; then
    if [ "$json" = "true" ]; then
      printf '[]\n'
    fi
    return 0
  fi

  files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$root" -mindepth 3 -maxdepth 3 -path '*/.desk/registry.json' -print | sort)

  if [ "$json" = "true" ]; then
    if [ "${#files[@]}" -eq 0 ]; then
      printf '[]\n'
      return 0
    fi

    first=true
    printf '[\n'
    for file in ${files[@]+"${files[@]}"}; do
      if [ "$first" = "true" ]; then
        first=false
      else
        printf ',\n'
      fi
      jq '.' "$file"
    done
    printf '\n]\n'
  else
    for file in ${files[@]+"${files[@]}"}; do
      jq -r '.id' "$file"
    done
  fi
}
