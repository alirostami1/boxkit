#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"
. "${script_dir}/lib/arch.sh"

: "${BOB_VERSION:=v4.1.6}"
: "${BOB_INSTALL_DIR:=${HOME}/.local/share/bob_bin}"
: "${BOB_BIN_DIR:=${HOME}/.local/bin}"

if [ -n "${1:-}" ]; then
  BOB_VERSION="$1"
fi

if [ "$(uname -s)" != "Linux" ]; then
  die "Bob install only supports Linux in this image build."
fi

if ! command -v unzip >/dev/null 2>&1; then
  die "'unzip' is required but not installed."
fi

bob_arch="$(arch_map "x86_64" "arm")"
asset="bob-linux-${bob_arch}.zip"
url="https://github.com/MordechaiHadad/bob/releases/download/${BOB_VERSION}/${asset}"

version_file="${BOB_INSTALL_DIR}/.version"
if [ -f "${version_file}" ] && [ "$(cat "${version_file}")" = "${BOB_VERSION}" ]; then
  log_info "bob ${BOB_VERSION} already installed at ${BOB_INSTALL_DIR}"
  exit 0
fi

log_step "Installing bob ${BOB_VERSION}"
mkdir -p "${BOB_INSTALL_DIR}" "${BOB_BIN_DIR}"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

zip_file="${tmpdir}/${asset}"
extract_dir="${tmpdir}/extract"

curl -fsSL -o "${zip_file}" "${url}"
mkdir -p "${extract_dir}"
unzip -q "${zip_file}" -d "${extract_dir}"

bob_bin="$(find "${extract_dir}" -type f -name bob -print -quit)"
if [ -z "${bob_bin}" ]; then
  die "Could not find 'bob' executable in zip."
fi

source_dir="$(dirname "${bob_bin}")"

rm -rf "${BOB_INSTALL_DIR}"
mkdir -p "${BOB_INSTALL_DIR}"
cp -R "${source_dir}/." "${BOB_INSTALL_DIR}/"

chmod +x "${BOB_INSTALL_DIR}/bob"
ln -sf "${BOB_INSTALL_DIR}/bob" "${BOB_BIN_DIR}/bob"

echo "${BOB_VERSION}" > "${version_file}"
log_info "Installed bob ${BOB_VERSION} to ${BOB_BIN_DIR}/bob"
