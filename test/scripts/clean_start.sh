#!/usr/bin/env sh

# !! NON-POSIX feature available in BSD, GNU/Linux and MacOS: options -f for command "readlink"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

"$SCRIPT_DIR/build.sh" "$1" && "$SCRIPT_DIR/start.sh" "$1"

