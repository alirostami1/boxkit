#!/bin/sh
set -e

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/lib/log.sh"

log_step "Installing Fedora packages from fedora-dev-science.packages"
grep -v '^#' ./fedora-dev-science.packages | xargs sudo dnf install -y

log_step "Cleaning Fedora package caches"
sudo dnf clean all
sudo rm -rf /var/cache/dnf /var/lib/dnf
log_info "Fedora science setup complete"
