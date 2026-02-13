#!/bin/sh
set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg

# GitHub CLI repo https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-and-ubuntu-based-linux-distributions
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
printf "deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n" "$(dpkg --print-architecture)" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update

packages="$(grep -v '^#' ./ubuntu-dev.packages)"
installable=""
for pkg in ${packages}; do
  if apt-cache show "${pkg}" >/dev/null 2>&1; then
    installable="${installable} ${pkg}"
  else
    echo "Skipping unavailable package: ${pkg}"
  fi
done

if [ -n "${installable}" ]; then
  sudo apt-get install -y --no-install-recommends ${installable}
fi

# Node-based tools and language servers
: "${NPM_CONFIG_PREFIX:=${HOME}/.npm-global}"
mkdir -p "${NPM_CONFIG_PREFIX}"
npm config set prefix "${NPM_CONFIG_PREFIX}"
npm install -g --no-fund --no-audit \
  @openai/codex@0.77.0 \
  @astrojs/language-server@2.16.2 \
  @fsouza/prettierd@0.26.2 \
  @tailwindcss/language-server@0.14.29 \
  eslint_d@14.3.0 \
  markdownlint-cli2@0.20.0 \
  pyright@1.1.407 \
  vscode-langservers-extracted@4.10.0 \
  yaml-language-server@1.19.2

# Go-based tools
export GOBIN="${HOME}/.go/bin"
mkdir -p "${GOBIN}"
go install github.com/a-h/templ/cmd/templ@v0.3.960
go install github.com/go-delve/delve/cmd/dlv@v1.26.0
go install github.com/google/yamlfmt/cmd/yamlfmt@v0.20.0

# Rust-based tools
cargo install --locked --root "${HOME}/.cargo" \
  selene@0.29.0 \
  stylua@2.3.1

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

# Reduce image size by clearing package and tool caches.
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
rm -rf "${HOME}/.npm/_cacache" "${HOME}/.npm/_logs"
rm -rf "${HOME}/.cache/go-build"
rm -rf "${HOME}/.cargo/registry" "${HOME}/.cargo/git"
