#!/usr/bin/env sh

# !!! NON-POSIX feature available in BSD, GNU/Linux and MacOS: options -f for command "readlink"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
IMAGE="$1"

if [ -f "$SCRIPT_DIR/../dockerfiles/$IMAGE.dockerfile" ]; then
	docker build -t "confman:$IMAGE" -f "$SCRIPT_DIR/../dockerfiles/$IMAGE.dockerfile" .
	docker image prune -f
else
	echo "ERROR: Cannot find dockerfile $IMAGE.dockerfile" >&2 && exit 1
fi

