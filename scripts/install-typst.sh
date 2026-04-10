#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"
. "${script_dir}/lib/arch.sh"

: "${TYPST_VERSION:=latest}"
: "${TYPST_INSTALL_DIR:=${HOME}/.local/share/typst}"
: "${TYPST_BIN_DIR:=${HOME}/.local/bin}"

if [ -n "${1:-}" ]; then
  TYPST_VERSION="$1"
fi

if [ "$(uname -s)" != "Linux" ]; then
  die "Typst install only supports Linux in this image build."
fi

if ! command -v jq >/dev/null 2>&1; then
  die "'jq' is required but not installed."
fi

archive_target="$(arch_map "x86_64-unknown-linux-musl" "aarch64-unknown-linux-musl")"

if [ "${TYPST_VERSION}" = "latest" ]; then
  api_url="https://api.github.com/repos/typst/typst/releases/latest"
else
  api_url="https://api.github.com/repos/typst/typst/releases/tags/${TYPST_VERSION}"
fi

version_file="${TYPST_INSTALL_DIR}/.version"
if [ -f "${version_file}" ] && [ "$(cat "${version_file}")" = "${TYPST_VERSION}" ]; then
  log_info "typst ${TYPST_VERSION} already installed at ${TYPST_INSTALL_DIR}"
  exit 0
fi

log_step "Installing typst ${TYPST_VERSION}"
release_json="$(curl -fsSL "${api_url}")"
asset_name="$(printf "%s" "${release_json}" | jq -r --arg target "${archive_target}" '.assets[] | select(.name | test("^typst-" + $target + "\\.tar\\.(xz|gz)$")) | .name' | head -n 1)"

if [ -z "${asset_name}" ] || [ "${asset_name}" = "null" ]; then
  die "Could not find a Linux typst archive for ${archive_target} in ${TYPST_VERSION}."
fi

download_url="$(printf "%s" "${release_json}" | jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .browser_download_url')"
if [ -z "${download_url}" ] || [ "${download_url}" = "null" ]; then
  die "Could not find download URL for typst asset ${asset_name}."
fi

mkdir -p "${TYPST_INSTALL_DIR}" "${TYPST_BIN_DIR}"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

archive_path="${tmpdir}/${asset_name}"
curl -fsSL "${download_url}" -o "${archive_path}"

tar -xf "${archive_path}" -C "${tmpdir}"

bin_path="$(find "${tmpdir}" -type f -name typst -print -quit)"
if [ -z "${bin_path}" ]; then
  die "Typst binary not found in downloaded archive."
fi

install -m 0755 "${bin_path}" "${TYPST_INSTALL_DIR}/typst"

echo "${TYPST_VERSION}" > "${version_file}"
ln -sf "${TYPST_INSTALL_DIR}/typst" "${TYPST_BIN_DIR}/typst"
log_info "Installed typst ${TYPST_VERSION} to ${TYPST_BIN_DIR}/typst"
