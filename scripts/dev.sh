#!/bin/sh

# Symlink distrobox shims
./distrobox-shims.sh

# Add repos
sudo dnf install dnf5-plugins
# Github cli repo https://github.com/cli/cli/blob/trunk/docs/install_linux.md#rpm
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo

# Update the container and install packages
dnf update -y
grep -v '^#' ./dev.packages | xargs dnf install -y
