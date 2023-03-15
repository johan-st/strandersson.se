#!/bin/bash
containerName="strandersson-dev"

# generate env variables
export COMMIT_HASH=$(git rev-parse --short HEAD)
export BUILD_TIME=$(date '+%Y%m%d-%H%M%S')
export BUILD_TAG="$BUILD_TIME<$COMMIT_HASH>"

echo "ENVIRONMENT VARIABLES:"
for e in BUILD_TAG BUILD_TIME COMMIT_HASH; do
    if [ -z "${!e}" ]; then
        echo "$e is not set - Exiting..."
        exit 1
    fi
    echo "- $e: ${!e}"
done

echo ""
echo " - BUILDING - "
if ! docker build \
    --build-arg BUILD_TAG=${BUILD_TAG} \
    --build-arg BUILD_TIME=${BUILD_TIME} \
    --build-arg COMMIT_HASH=${COMMIT_HASH} \
    -t $containerName \
    .; then
    echo " - BUILD FAILED - "
    exit 1
fi

echo ""
echo " - RUNNING (on port 8080) - "
if ! docker run \
    --rm \
    -p 8080:80 \
    $containerName; then
    echo " - RUN FAILED - "
    exit 1
fi
