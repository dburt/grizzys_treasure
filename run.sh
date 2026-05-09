#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
GODOT_BIN="${GODOT:-$(command -v godot || echo /opt/godot/Godot_v4.6.2-stable_linux.x86_64)}"
exec "$GODOT_BIN" --path . "$@"
