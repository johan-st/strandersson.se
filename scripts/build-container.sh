#!/bin/bash

# check if image name is specified
if [ -z "$1" ]; then
    echo " - no container name is specified -"
    echo "first argument must be the container name"
    exit 1
else
    containerName=$1
fi

# check if environment variables are set
echo
echo "ENVIRONMENT VARIABLES:"
for e in BUILD_TIME COMMIT_HASH BUILD_TAG; do
    if [ -z "${!e}" ]; then
        echo " - $e is not set -"
        exit 1
    fi
    echo "- $e: ${!e}"
done

echo
echo "BUILDING CONTAINER"
if ! docker build \
    --build-arg BUILD_TAG="${BUILD_TAG}" \
    --build-arg BUILD_TIME="${BUILD_TIME}" \
    --build-arg COMMIT_HASH="${COMMIT_HASH}" \
    -t $containerName \
    .; then
    echo " - failed to build $containerName - "
    exit 1
fi
