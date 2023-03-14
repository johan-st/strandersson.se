#if the first argument is not provided, ask for it
if [ -z "$1" ]
then
  echo "container tag not provided, please provide a tag as the first argument"
  echo "tag 'production' deploys to production (info checked 2023-03-14)"
  echo "tag 'staging' deploys to staging (info checked 2023-03-14)"
  exit 1
fi

# set container tag to the first argument (required)
tag=$1


# if no tag is provided, use the current git commit hash
if [ -z "$buildTag" ]
then
  buildTag=$(git rev-parse --short HEAD)
else
  buildTag=$(date '+%Y%m%d-%H%M%S')
fi

BUILD_TAG=$buildTag



echo "container tag: $tag"
echo "build tag: $BUILD_TAG"

echo ""
echo "BUILDING: strandersson:$tag" 
docker build --build-arg=BUILD_TAG -t strandersson:$tag  .

echo ""
echo "TAGGING: registry.digitalocean.com/johan-st/strandersson:$tag"
docker tag strandersson:$tag registry.digitalocean.com/johan-st/strandersson:$tag

echo ""
echo "PUSHING: registry.digitalocean.com/johan-st/strandersson:$tag"
docker push registry.digitalocean.com/johan-st/strandersson:$tag