#!/bin/sh
# Runs inside the VM. Installs the runtimes pinned in ~/.config/mise/config.toml.
set -eu
. "$HOME/.config/pie/env"
# Transitive npm dependencies must also be at least 7 days old.
NPM_CONFIG_BEFORE=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)
export NPM_CONFIG_BEFORE
mise install
mise reshim
pi --version
