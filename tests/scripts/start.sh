#/usr/bin/env

IMAGE="confman:$1"
CONTAINER="confman_$1"

docker container inspect "$CONTAINER" >/dev/null 2>&1 &&
	docker stop "$CONTAINER" &&
	docker rm -vf "$CONTAINER"

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
	docker run --name "$CONTAINER" -it "$IMAGE"
else
	echo "ERROR: Cannot find Docker image $IMAGE" >&2 && exit 1
fi

