#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"
. "${script_dir}/lib/arch.sh"

: "${LUALS_VERSION:=3.18.1}"
: "${LUALS_INSTALL_DIR:=${HOME}/.local/share/lua-language-server}"
: "${LUALS_BIN_DIR:=${HOME}/.local/bin}"

if [ "$(uname -s)" != "Linux" ]; then
  die "LuaLS install only supports Linux in this image build."
fi

if [ -n "${1:-}" ]; then
  LUALS_VERSION="$1"
fi

luals_arch="$(arch_map "x64" "arm64")"

version_file="${LUALS_INSTALL_DIR}/.version"
if [ -f "${version_file}" ] && [ "$(cat "${version_file}")" = "${LUALS_VERSION}" ]; then
  log_info "lua-language-server ${LUALS_VERSION} already installed at ${LUALS_INSTALL_DIR}"
  exit 0
fi

asset="lua-language-server-${LUALS_VERSION}-linux-${luals_arch}.tar.gz"
url="https://github.com/LuaLS/lua-language-server/releases/download/${LUALS_VERSION}/${asset}"

log_step "Installing lua-language-server ${LUALS_VERSION}"
mkdir -p "${LUALS_INSTALL_DIR}" "${LUALS_BIN_DIR}"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

curl -fsSL -o "${tmpdir}/${asset}" "${url}"
rm -rf "${LUALS_INSTALL_DIR}"
mkdir -p "${LUALS_INSTALL_DIR}"
tar -xzf "${tmpdir}/${asset}" -C "${LUALS_INSTALL_DIR}"

echo "${LUALS_VERSION}" > "${version_file}"
ln -sf "${LUALS_INSTALL_DIR}/bin/lua-language-server" "${LUALS_BIN_DIR}/lua-language-server"
log_info "Installed lua-language-server ${LUALS_VERSION} to ${LUALS_BIN_DIR}/lua-language-server"
