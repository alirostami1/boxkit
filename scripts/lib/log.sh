#!/bin/sh

log__timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log__supports_color() {
  [ -t 2 ] && [ "${TERM:-}" != "dumb" ]
}

log__level_value() {
  case "$1" in
    debug) printf '10' ;;
    info) printf '20' ;;
    warn) printf '30' ;;
    error) printf '40' ;;
    *) printf '20' ;;
  esac
}

log__enabled() {
  current_level="${BOXKIT_LOG_LEVEL:-info}"
  [ "$(log__level_value "$1")" -ge "$(log__level_value "$current_level")" ]
}

log__color() {
  if ! log__supports_color; then
    return 0
  fi

  case "$1" in
    debug) printf '\033[36m' ;;
    info) printf '\033[32m' ;;
    warn) printf '\033[33m' ;;
    error) printf '\033[31m' ;;
  esac
}

log__reset() {
  if log__supports_color; then
    printf '\033[0m'
  fi
}

log__emit() {
  level="$1"
  shift

  if ! log__enabled "$level"; then
    return 0
  fi

  prefix="$(log__timestamp) [${level}]"
  color="$(log__color "$level")"
  reset="$(log__reset)"

  if [ -n "$color" ]; then
    printf '%b%s%b %s\n' "$color" "$prefix" "$reset" "$*" >&2
  else
    printf '%s %s\n' "$prefix" "$*" >&2
  fi
}

log_debug() {
  log__emit debug "$@"
}

log_info() {
  log__emit info "$@"
}

log_warn() {
  log__emit warn "$@"
}

log_error() {
  log__emit error "$@"
}

log_step() {
  log_info "$@"
}

die() {
  log_error "$@"
  exit 1
}
