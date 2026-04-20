#!/bin/sh
# Installer for claude-burn.
set -eu

PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
SRC="$(cd "$(dirname "$0")" && pwd)/bin/claude-burn"

if [ ! -f "$SRC" ]; then
  echo "install.sh: cannot find $SRC" >&2
  exit 1
fi

for dep in ccusage jq; do
  command -v "$dep" >/dev/null 2>&1 || {
    echo "install.sh: warning — missing dependency: $dep" >&2
    echo "  install via: bun add -g ccusage  (or: npm i -g ccusage)" >&2
  }
done

if [ ! -w "$BIN_DIR" ]; then
  echo "install.sh: $BIN_DIR is not writable — retrying with sudo"
  sudo install -m 0755 "$SRC" "$BIN_DIR/claude-burn"
else
  install -m 0755 "$SRC" "$BIN_DIR/claude-burn"
fi

echo "Installed: $BIN_DIR/claude-burn"
echo
echo "Next step — wire into Claude Code:"
echo "  add to ~/.claude/settings.json:"
echo '    "statusLine": { "type": "command", "command": "claude-burn" }'
