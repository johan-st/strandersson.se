#!/bin/bash

containerName="strandersson"

# check if tag is specified
if [ -z "$1" ]; then
  echo "no tag specified. Do you want to use 'latest'."
  echo "(this will overwrite the current latest image and DEPLOY to production.)"
  read -p "y/n: " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "using 'latest'"
    tag="latest"
  else
    echo " - no tag specified -"
    exit 1
  fi
else
  tag=$1
fi

# refuse deploy to production (tag 'latest') if not on main branch
if [ "$tag" == "latest" ]; then
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
    echo " - not on main branch -"
    exit 1
  fi
fi

# refuse deploy if working tree is not clean
if [ -n "$(git status --porcelain)" ]; then
  echo " - working tree is not clean -"
  echo "Use 'npm run docker' to run the container locally if you are not ready to commit."
  exit 1
fi

# set up environment variables
source $(dirname "$0")/set-env.sh

echo
echo "CONTAINER NAME: $containerName"

# generate tags
tagDate="$(date '+%Y-%m-%d')"
tagCommitHash="$(git rev-parse --short HEAD)"

echo
echo "CONTAINER IMAGE TAGS:"
for t in tagDate tagCommitHash tag; do
  if [ -z "${!t}" ]; then
    echo " - failed to create tag $t -"
    exit 1
  fi
  echo "- ${!t}"
done

# build container
echo
if ! $(dirname "$0")/build-container.sh $containerName; then
  exit 1
fi

echo
echo "TAGGING"
for t in $tagDate $tagHash $tag; do
  echo "tagging: $t"
  if ! docker tag $containerName registry.digitalocean.com/johan-st/$containerName:$t; then
    echo " - failed to tag $containerName:$t -"
    exit 1
  fi
done

echo
echo "PUSHING"
if ! docker push --all-tags registry.digitalocean.com/johan-st/$containerName; then
  echo " - failed to push -"
  exit 1
fi
