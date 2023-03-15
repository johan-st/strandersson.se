#!/bin/bash

# Set env from file
# for e in $(cat .env | xargs) ; do
#     export $e
# done

# generate env variables
export COMMIT_HASH=$(git rev-parse --short HEAD)
export BUILD_TIME=$(date '+%Y%m%d-%H%M%S')
export BUILD_TAG="$BUILD_TIME<$COMMIT_HASH>"

echo "handing off to build-script..."
npm run build-prod
