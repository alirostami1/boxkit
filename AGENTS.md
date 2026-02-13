# Agents

## Boxkit Onboarding

### Use This When
- You need to add or modify a ContainerFile image.
- You are wiring dotfiles into images or creating a new config variant.
- You need to adjust package lists, setup scripts, or build matrices.
- You need to understand how containers are created from built images.

### Project Map (Short)
- `ContainerFiles/` contains image definitions (Containerfile syntax).
- `packages/` contains package list files used by setup scripts.
- `scripts/` contains setup scripts and helper tooling.
- `dot_config/` contains baked dotfiles for each image profile.
- `Justfile` contains local build targets.
- `.github/workflows/build-boxkit.yml` drives CI image builds.
- `.containerignore` controls build context contents.

### Core Workflow: Add or Modify an Image
1) Decide if the image is a base image or a derivative.
2) Update the ContainerFile in `ContainerFiles/`.
3) Update package list(s) in `packages/` and the setup script in `scripts/`.
4) If needed, add or update a `dot_config/<profile>` and copy it in the ContainerFile.
5) Update build metadata:
   - Base images: `Justfile` bases section + CI matrix in `.github/workflows/build-boxkit.yml`.
   - Derivatives: `Justfile` derivatives section + CI derivatives matrix.

### Dotfiles Integration (Image-Baked Config)
- Configs live in `dot_config/<profile>/`.
- ContainerFiles should copy them into the user home:
  - `COPY --chown=${USERNAME}:${USERNAME} ../dot_config/<profile>/ /home/${USERNAME}/`
- `scripts/create-container.sh` defaults to image-baked config.
  - Use `--dev-home` only when you need host-mounted dotfiles.

### Editor Plugins (Neovim + Tmux)
- Neovim uses Lazy; tmux uses tpm.
- Setup scripts install plugins at build time:
  - Clone tpm into `${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm`.
  - Run `tpm/bin/install_plugins` after sourcing `~/.config/tmux/tmux.conf`.
  - Run `nvim --headless "+Lazy! sync" +qa`.
- Ensure required dependencies are installed (git, tmux, node, gcc, make).

### Local Build Commands
- `just build image=<name>` builds a single image.
- `just bases` or `just derivatives` builds grouped images.
- Build context is the repo root; `.containerignore` controls what is sent.

### Quick Checks
- New image name added to CI matrix.
- ContainerFiles copy the correct `dot_config/<profile>`.
- Package list and setup script are in sync.
- Plugin installation is compatible with the dotfiles.

### Path Map (Detailed)
#### Image Definitions
- `ContainerFiles/fedora-dev`: Fedora base image.
- `ContainerFiles/ubuntu-dev`: Ubuntu base image.
- `ContainerFiles/fedora-vimtex`: Fedora VimTex image.
- `ContainerFiles/*-ansible`: Derivative images that add Ansible.

#### Config Profiles
- `dot_config/base-dev`: Default dotfiles baked into base images.
- `dot_config/fedora-vimtex`: VimTex-focused dotfiles.

#### Package Lists
- `packages/fedora-dev.packages`: Fedora base package set.
- `packages/ubuntu-dev.packages`: Ubuntu base package set.
- `packages/fedora-vimtex.packages`: VimTex package set.

#### Setup Scripts
- `scripts/fedora-dev.sh`: Fedora base setup + plugin install.
- `scripts/ubuntu-dev.sh`: Ubuntu base setup + plugin install.
- `scripts/fedora-vimtex.sh`: VimTex setup + plugin install.
- `scripts/create-container.sh`: Run container with mounts (defaults to image-baked config).
- `scripts/create-derivative.sh`: Scaffold a derivative ContainerFile and related files.

#### Build and CI
- `Justfile`: Local build targets (`bases`, `derivatives`, `build`).
- `.github/workflows/build-boxkit.yml`: CI build matrix and push logic.
- `.containerignore`: Files excluded from build context.
