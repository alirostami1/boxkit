#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"

export DEBIAN_FRONTEND=noninteractive

log_step "Updating apt metadata and installing repository prerequisites"
sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

# GitHub CLI repo https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-and-ubuntu-based-linux-distributions
log_step "Adding GitHub CLI APT repository"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
printf "deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n" "$(dpkg --print-architecture)" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update

packages="$(grep -v '^#' ./ubuntu-dev.packages)"
installable=""
log_step "Resolving installable Ubuntu packages"
for pkg in ${packages}; do
  if apt-cache show "${pkg}" >/dev/null 2>&1; then
    installable="${installable} ${pkg}"
  else
    log_warn "Skipping unavailable package: ${pkg}"
  fi
done

if [ -n "${installable}" ]; then
  log_step "Installing Ubuntu packages from ubuntu-dev.packages"
  sudo apt-get install -y --no-install-recommends ${installable}
fi

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
    nvim --headless "+lua vim.pack.update(nil, { force = true, target = 'lockfile' })" "+lua require('aros.mason_tools').restore_from_lockfile()" "+qa"
  else
    nvim --headless "+lua vim.pack.update(nil, { force = true, target = 'lockfile' })" "+qa"
  fi
}

log_step "Installing tmux and Neovim plugins"
install_editor_plugins

# Reduce image size by clearing package and tool caches.
log_step "Cleaning Ubuntu package and tool caches"
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
rm -rf "${HOME}/.npm/_cacache" "${HOME}/.npm/_logs"
rm -rf "${HOME}/.cache/go-build"
rm -rf "${HOME}/.cargo/registry" "${HOME}/.cargo/git"
log_info "Ubuntu development setup complete"
