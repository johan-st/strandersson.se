#!/bin/bash
containerName="strandersson-dev"

# generate container tags
commitHash=$(git rev-parse --short HEAD)
buildTime=$(date '+%Y-%m-%d')
BUILD_TAG="$(date '+%Y%m%d-%H%M%S') <$commitHash>"

echo ""
echo "BUILD_TAG: $BUILD_TAG"
echo " - BUILDING - "
docker build --build-arg=BUILD_TAG --build-arg=buildTime --build-arg=commitHash -t $containerName .

echo ""
echo " - RUNNING - "
docker run --rm -p 8080:80 $containerName
