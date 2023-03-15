#!/bin/bash
containerName="strandersson-dev"

# set up environment variables
source $(dirname "$0")/set-env.sh

# build container
if ! $(dirname "$0")/build-container.sh $containerName; then
    exit 1
fi

echo ""
echo " - RUNNING (on port 8080) - "
if ! docker run \
    --rm \
    -p 8080:80 \
    $containerName; then
    echo " - failed to run $containerName - "
    exit 1
fi
