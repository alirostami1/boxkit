#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"

# GitHub CLI repo https://github.com/cli/cli/blob/trunk/docs/install_linux.md#rpm
log_step "Adding GitHub CLI RPM repository"
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo

# Update the container and install packages
log_step "Installing Fedora packages from fedora-dev.packages"
grep -v '^#' ./fedora-dev.packages | xargs sudo dnf install -y

# Node-based CLI tools
log_step "Installing Node-based CLI tools"
: "${NPM_CONFIG_PREFIX:=${HOME}/.npm-global}"
mkdir -p "${NPM_CONFIG_PREFIX}"
npm config set prefix "${NPM_CONFIG_PREFIX}"
npm install -g --no-fund --no-audit \
  @openai/codex@0.77.0

# Standalone tools
log_step "Installing standalone tools"
sh ./install-bob.sh v4.1.6
sh ./install-marksman.sh 2026-02-08

: "${NEOVIM_VERSION:=stable}"
log_step "Installing Neovim ${NEOVIM_VERSION} through bob"
bob install "${NEOVIM_VERSION}"
bob use "${NEOVIM_VERSION}"
ln -sf "${HOME}/.local/share/bob/nvim-bin/nvim" "${HOME}/.local/bin/nvim"

install_editor_plugins() {
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  tmux_plugin_dir="${TMUX_PLUGIN_MANAGER_PATH:-${config_home}/tmux/plugins}"

  mkdir -p "${tmux_plugin_dir}"
  if [ ! -d "${tmux_plugin_dir}/tpm" ]; then
    log_info "Cloning tmux plugin manager"
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

  if [ -f "${config_home}/nvim/mason-lock.json" ]; then
    nvim --headless "+lua vim.pack.update(nil, { force = true, target = 'lockfile' })" "+lua require('base_dev.mason_tools').restore_from_lockfile()" "+qa"
  else
    nvim --headless "+lua vim.pack.update(nil, { force = true, target = 'lockfile' })" "+qa"
  fi
}

log_step "Installing tmux and Neovim plugins"
install_editor_plugins

# Reduce image size by clearing package and tool caches.
log_step "Cleaning Fedora package and tool caches"
sudo dnf clean all
sudo rm -rf /var/cache/dnf /var/lib/dnf
rm -rf "${HOME}/.npm/_cacache" "${HOME}/.npm/_logs"
rm -rf "${HOME}/.cache/go-build"
rm -rf "${HOME}/.cargo/registry" "${HOME}/.cargo/git"
log_info "Fedora development setup complete"
