#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
. "${script_dir}/lib/log.sh"

usage() {
  cat <<'USAGE'
Usage: sync-base-dev-nvim.sh [target_dir]

Synchronizes the repo's base-dev Neovim config into the target directory.

Behavior:
- Preserves target lockfiles: mason-lock.json and nvim-pack-lock.json
- Removes every other top-level file/directory in the target
- Copies every top-level file/directory from dot_config/base-dev/.config/nvim
  except those same lockfiles

Arguments:
  target_dir   Destination config directory (default: ~/.config/nvim)
USAGE
}

target_dir="${1:-${HOME}/.config/nvim}"

if [[ $# -gt 1 ]]; then
  log_error "Unexpected argument: $2"
  usage >&2
  exit 1
fi

case "${target_dir}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

source_dir="${repo_root}/dot_config/base-dev/.config/nvim"

if [[ ! -d "${source_dir}" ]]; then
  die "Source Neovim config not found: ${source_dir}"
fi

mkdir -p "${target_dir}"

should_preserve() {
  case "$1" in
    mason-lock.json | nvim-pack-lock.json) return 0 ;;
    *) return 1 ;;
  esac
}

remove_target_entries() {
  local entry

  shopt -s dotglob nullglob
  for entry in "${target_dir}"/*; do
    if should_preserve "$(basename "${entry}")"; then
      log_info "Preserving $(basename "${entry}")"
      continue
    fi

    rm -rf "${entry}"
    log_info "Removed ${entry}"
  done
  shopt -u dotglob nullglob
}

copy_source_entries() {
  local entry
  local name

  shopt -s dotglob nullglob
  for entry in "${source_dir}"/*; do
    name="$(basename "${entry}")"

    if should_preserve "${name}"; then
      log_info "Skipping source lockfile ${name}"
      continue
    fi

    cp -a "${entry}" "${target_dir}/"
    log_info "Copied ${name} to ${target_dir}"
  done
  shopt -u dotglob nullglob
}

log_step "Syncing ${source_dir} -> ${target_dir}"
remove_target_entries
copy_source_entries
log_info "Neovim config sync complete"
