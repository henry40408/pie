#!/bin/sh
# Runs inside the VM. Idempotent. Adds codemode to pi's default tools without touching other settings.
set -eu
. "$HOME/.config/pie/env"

# node is already pinned by mise; Debian ships no jq.
node - "$PI_CODING_AGENT_DIR/settings.json" <<'EOF'
const fs = require("fs");
const file = process.argv[2];
const settings = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
const tools = settings.defaultTools ?? ["+codemode"];
if (!tools.some((t) => t === "codemode" || t === "+codemode")) tools.push("+codemode");
settings.defaultTools = tools;
fs.writeFileSync(`${file}.new`, JSON.stringify(settings, null, 2) + "\n");
fs.renameSync(`${file}.new`, file);
EOF
