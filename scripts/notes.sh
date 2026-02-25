#!/bin/sh
set -e

grep -v '^#' ./notes.packages | xargs sudo dnf install -y

# Node-based tools and formatters
: "${NPM_CONFIG_PREFIX:=${HOME}/.npm-global}"
mkdir -p "${NPM_CONFIG_PREFIX}"
npm config set prefix "${NPM_CONFIG_PREFIX}"
npm install -g --no-fund --no-audit \
  @fsouza/prettierd@0.26.2 \
  prettier@3.3.3

install_marksman() {
  arch="$(uname -m)"
  case "${arch}" in
  x86_64) asset_name="marksman-linux-x64" ;;
  aarch64) asset_name="marksman-linux-arm64" ;;
  *)
    echo "Unsupported architecture for marksman: ${arch}" >&2
    exit 1
    ;;
  esac

  release_json="$(curl -sSL https://api.github.com/repos/artempyanykh/marksman/releases/latest)"
  download_url="$(printf "%s" "${release_json}" | jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .browser_download_url')"

  if [ -z "${download_url}" ] || [ "${download_url}" = "null" ]; then
    echo "Could not find marksman asset ${asset_name} in latest release." >&2
    exit 1
  fi

  install -d "${HOME}/.local/bin"
  curl -sSL "${download_url}" -o /tmp/marksman
  install -m 0755 /tmp/marksman "${HOME}/.local/bin/marksman"
  rm -f /tmp/marksman
}

install_marksman

install_typst() {
  arch="$(uname -m)"
  case "${arch}" in
  x86_64) target="x86_64-unknown-linux-musl" ;;
  aarch64) target="aarch64-unknown-linux-musl" ;;
  *)
    echo "Unsupported architecture for typst: ${arch}" >&2
    exit 1
    ;;
  esac

  release_json="$(curl -sSL https://api.github.com/repos/typst/typst/releases/latest)"
  asset_name="$(printf "%s" "${release_json}" | jq -r --arg target "${target}" '.assets[] | select(.name | test("^typst-" + $target + "\\.tar\\.(xz|gz)$")) | .name' | head -n 1)"

  if [ -z "${asset_name}" ] || [ "${asset_name}" = "null" ]; then
    echo "Could not find a Linux typst archive for ${target} in latest release." >&2
    exit 1
  fi

  download_url="$(printf "%s" "${release_json}" | jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .browser_download_url')"
  if [ -z "${download_url}" ] || [ "${download_url}" = "null" ]; then
    echo "Could not find download URL for typst asset ${asset_name}." >&2
    exit 1
  fi

  install -d "${HOME}/.local/bin"
  tmp_dir="$(mktemp -d)"
  archive_path="${tmp_dir}/${asset_name}"

  curl -sSL "${download_url}" -o "${archive_path}"
  tar -xf "${archive_path}" -C "${tmp_dir}"

  bin_path="$(find "${tmp_dir}" -type f -name typst | head -n 1)"
  if [ -z "${bin_path}" ]; then
    echo "typst binary not found in downloaded archive." >&2
    rm -rf "${tmp_dir}"
    exit 1
  fi

  install -m 0755 "${bin_path}" "${HOME}/.local/bin/typst"
  rm -rf "${tmp_dir}"
}

install_typst

install_editor_plugins() {
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  tmux_plugin_dir="${TMUX_PLUGIN_MANAGER_PATH:-${config_home}/tmux/plugins}"

  mkdir -p "${tmux_plugin_dir}"
  if [ ! -d "${tmux_plugin_dir}/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "${tmux_plugin_dir}/tpm"
  fi

  export XDG_CONFIG_HOME="${config_home}"
  export TMUX_PLUGIN_MANAGER_PATH="${tmux_plugin_dir}"

  tmux start-server
  tmux new-session -d -s tpm-install
  tmux set-environment -g XDG_CONFIG_HOME "${config_home}"
  tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "${tmux_plugin_dir}"
  tmux source-file "${config_home}/tmux/tmux.conf"
  "${tmux_plugin_dir}/tpm/bin/install_plugins"
  tmux kill-session -t tpm-install || true
  tmux kill-server || true

  nvim --headless "+Lazy! sync" "+qa"
}

install_editor_plugins

sudo dnf clean all
sudo rm -rf /var/cache/dnf /var/lib/dnf
