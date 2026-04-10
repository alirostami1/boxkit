#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"
. "${script_dir}/lib/arch.sh"

: "${MARKSMAN_VERSION:=latest}"
: "${MARKSMAN_INSTALL_DIR:=${HOME}/.local/share/marksman}"
: "${MARKSMAN_BIN_DIR:=${HOME}/.local/bin}"

if [ -n "${1:-}" ]; then
  MARKSMAN_VERSION="$1"
fi

if [ "$(uname -s)" != "Linux" ]; then
  die "Marksman install only supports Linux in this image build."
fi

if ! command -v jq >/dev/null 2>&1; then
  die "'jq' is required but not installed."
fi

marksman_arch="$(arch_map "x64" "arm64")"
asset_name="marksman-linux-${marksman_arch}"

if [ "${MARKSMAN_VERSION}" = "latest" ]; then
  api_url="https://api.github.com/repos/artempyanykh/marksman/releases/latest"
else
  api_url="https://api.github.com/repos/artempyanykh/marksman/releases/tags/${MARKSMAN_VERSION}"
fi

version_file="${MARKSMAN_INSTALL_DIR}/.version"
if [ -f "${version_file}" ] && [ "$(cat "${version_file}")" = "${MARKSMAN_VERSION}" ]; then
  log_info "marksman ${MARKSMAN_VERSION} already installed at ${MARKSMAN_INSTALL_DIR}"
  exit 0
fi

log_step "Installing marksman ${MARKSMAN_VERSION}"
release_json="$(curl -fsSL "${api_url}")"
download_url="$(printf "%s" "${release_json}" | jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .browser_download_url')"

if [ -z "${download_url}" ] || [ "${download_url}" = "null" ]; then
  die "Could not find marksman asset ${asset_name} for ${MARKSMAN_VERSION}."
fi

mkdir -p "${MARKSMAN_INSTALL_DIR}" "${MARKSMAN_BIN_DIR}"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

curl -fsSL "${download_url}" -o "${tmpdir}/marksman"
install -m 0755 "${tmpdir}/marksman" "${MARKSMAN_INSTALL_DIR}/marksman"

echo "${MARKSMAN_VERSION}" > "${version_file}"
ln -sf "${MARKSMAN_INSTALL_DIR}/marksman" "${MARKSMAN_BIN_DIR}/marksman"
log_info "Installed marksman ${MARKSMAN_VERSION} to ${MARKSMAN_BIN_DIR}/marksman"
