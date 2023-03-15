#!/bin/bash

# generate env variables
export COMMIT_HASH=$(git rev-parse --short HEAD)
export BUILD_TIME=$(date '+%Y%m%d-%H%M%S')
export BUILD_TAG="$BUILD_TIME<$COMMIT_HASH>"

echo "ENVIRONMENT VARIABLES:"
echo " - BUILD_TAG: $BUILD_TAG"
echo " - BUILD_TIME: $BUILD_TIME"
echo " - COMMIT_HASH: $COMMIT_HASH"
echo ""

echo "RUNNING (port 8080)..."
BUILD_TAG=hello_moto parcel --no-autoinstall --port 8080
