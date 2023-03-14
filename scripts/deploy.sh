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

# generate container tags
commitHash=$(git rev-parse --short HEAD)
buildTime=$(date '+%Y-%m-%d')
BUILD_TAG="$(date '+%Y%m%d-%H%M%S') <$commitHash>"

echo ""
echo "BUILD_TAG: $BUILD_TAG"
echo " - BUILDING - "
docker build --build-arg=BUILD_TAG --build-arg=buildTime --build-arg=commitHash -t $containerName .

echo ""
echo " - TAGGING - $t"
for t in $commitHash $buildTime $tag; do
  echo "tagging: $t"
  docker tag $containerName registry.digitalocean.com/johan-st/$containerName:$t
done

echo ""
echo " - PUSHING - "
docker push --all-tags registry.digitalocean.com/johan-st/$containerName
