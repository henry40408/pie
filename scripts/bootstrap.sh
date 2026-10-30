#!/bin/sh
# Runs inside the VM as the login user. Idempotent. Needs MISE_VERSION, MISE_SHA256_ARM64.
set -eu

BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.config/pie" "$HOME/.config/mise"

if [ "$("$BIN/mise" --version 2>/dev/null | cut -d' ' -f1)" != "$MISE_VERSION" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/mise.tgz" \
    "https://github.com/jdx/mise/releases/download/v$MISE_VERSION/mise-v$MISE_VERSION-linux-arm64.tar.gz"
  echo "$MISE_SHA256_ARM64  $tmp/mise.tgz" | sha256sum -c -
  tar -xzf "$tmp/mise.tgz" -C "$tmp"
  install -m 0755 "$tmp/mise/bin/mise" "$BIN/mise"
  rm -rf "$tmp"
fi

cat > "$HOME/.config/pie/env" <<'ENVEOF'
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export PI_CODING_AGENT_DIR=/mnt/lima-pi-config
export PI_SKIP_VERSION_CHECK=1
export NPM_CONFIG_IGNORE_SCRIPTS=true
export MISE_YES=1
ENVEOF

# shellcheck disable=SC2016  # literal $HOME is written to .profile on purpose
line='. "$HOME/.config/pie/env"'
for rc in "$HOME/.profile" "$HOME/.bashrc"; do
  touch "$rc"
  if ! grep -qxF "$line" "$rc"; then
    { printf '%s\n' "$line"; cat "$rc"; } > "$rc.new"
    mv "$rc.new" "$rc"
  fi
done
