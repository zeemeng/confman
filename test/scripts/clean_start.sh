#!/usr/bin/env sh

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

"$SCRIPT_DIR/build.sh" "$1" && "$SCRIPT_DIR/start.sh" "$1"

