#!/bin/bash

containerName="strandersson"

if [ -z "$1" ]; then
  echo "no tag specified. Do you want to use 'latest'."
  echo "(this will overwrite the current latest image and DEPLOY to production.)"
  read -p "y/n: " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "using 'latest'"
    tag="latest"
  else
    echo "no tag specified. Exiting"
    exit 1
  fi
else
  tag=$1
fi

# generate env variables
export COMMIT_HASH=$(git rev-parse --short HEAD)
export BUILD_TIME=$(date '+%Y%m%d')
export BUILD_TAG="$BUILD_TIME<$COMMIT_HASH>"

# check env variables
echo "ENVIRONMENT VARIABLES:"
for e in BUILD_TIME COMMIT_HASH BUILD_TAG; do
  if [ -z "${!e}" ]; then
    echo "$e is not set. Exiting..."
    exit 1
  fi
  echo "- $e: ${!e}"
done

# generate tags
buildTime=$BUILD_TIME
commitHash=$COMMIT_HASH

echo ""
echo " BUILDING (build tag: $BUILD_TAG)"
if ! docker build \
  --build-arg BUILD_TAG \
  --build-arg BUILD_TIME \
  --build-arg COMMIT_HASH \
  -t $containerName \
  .; then
  echo "BUILD FAILED"
  exit 1
fi

echo ""
echo "TAGGING$t"
for t in $commitHash $buildTime $tag; do
  echo "tagging: $t"
  if ! docker tag $containerName registry.digitalocean.com/johan-st/$containerName:$t; then
    echo "TAG $t FAILED"
    exit 1
  fi
done

echo ""
echo "PUSHING"
if ! docker push --all-tags registry.digitalocean.com/johan-st/$containerName; then
  echo "PUSH FAILED"
  exit 1
fi
