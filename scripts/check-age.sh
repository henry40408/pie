#!/bin/sh
# Runs inside the VM. Usage: check-age.sh <npm-package> <version> [min-days]
# Fails if the version was published less than min-days ago (default 7).
set -eu
. "$HOME/.config/pie/env"
pkg=$1 ver=$2 min=${3:-7}
published=$(npm view "$pkg" "time[$ver]")
[ -n "$published" ] || { echo "version $ver of $pkg not found" >&2; exit 1; }
age=$(( ( $(date +%s) - $(date -d "$published" +%s) ) / 86400 ))
echo "$pkg@$ver published $published ($age days ago)"
[ "$age" -ge "$min" ] || { echo "refusing: younger than $min days" >&2; exit 1; }
