#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd -P)"
. "${script_dir}/lib/log.sh"

usage() {
  cat <<'USAGE'
Usage: update-mason-lock.sh [profile|all]

Profiles:
  base-dev
  notes
  all

Runs Neovim against a temporary copy of the selected profile config, installs
all Mason tools configured by that profile, writes mason-lock.json, then copies
it back to the matching dot_config profile in this repo.
USAGE
}

profile="${1:-base-dev}"

if [[ $# -gt 1 ]]; then
  log_error "Unexpected argument: $2"
  usage >&2
  exit 1
fi

case "${profile}" in
  -h | --help)
    usage
    exit 0
    ;;
  base-dev | notes | all) ;;
  *)
    log_error "Unknown profile: ${profile}"
    usage >&2
    exit 1
    ;;
esac

command -v nvim >/dev/null 2>&1 || die "nvim is required but was not found in PATH"

profile_module() {
  case "$1" in
    base-dev) printf '%s' 'base_dev.mason_tools' ;;
    notes) printf '%s' 'notes.mason_tools' ;;
    *) die "No Mason module configured for profile: $1" ;;
  esac
}

update_profile_lock() {
  local profile_name="$1"
  local profile_config_dir="${repo_root}/dot_config/${profile_name}/.config/nvim"
  local lockfile="${profile_config_dir}/mason-lock.json"
  local module_name
  local tmp_root

  if [[ ! -d "${profile_config_dir}" ]]; then
    die "Neovim config profile not found: ${profile_config_dir}"
  fi

  module_name="$(profile_module "${profile_name}")"
  tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/boxkit-mason-lock.${profile_name}.XXXXXX")"
  cleanup() {
    rm -rf "${tmp_root}"
  }
  trap cleanup RETURN

  mkdir -p "${tmp_root}/config" "${tmp_root}/data" "${tmp_root}/state"
  cp -a "${profile_config_dir}" "${tmp_root}/config/nvim"

  log_step "Installing Mason tools and updating ${profile_name} Mason lockfile in temporary XDG dirs"
  XDG_CONFIG_HOME="${tmp_root}/config" \
    XDG_DATA_HOME="${tmp_root}/data" \
    XDG_STATE_HOME="${tmp_root}/state" \
    nvim --headless \
      "+lua require('${module_name}').install_all()" \
      "+lua require('${module_name}').write_lockfile()" \
      "+qa"

  if [[ ! -f "${tmp_root}/config/nvim/mason-lock.json" ]]; then
    die "Neovim did not generate mason-lock.json for profile: ${profile_name}"
  fi

  cp "${tmp_root}/config/nvim/mason-lock.json" "${lockfile}"
  log_info "Updated ${lockfile}"
}

if [[ "${profile}" == "all" ]]; then
  update_profile_lock base-dev
  update_profile_lock notes
else
  update_profile_lock "${profile}"
fi
