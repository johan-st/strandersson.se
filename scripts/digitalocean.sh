# echo "BUILDING: strandersson" 
# docker build --build-arg=BUILD_TAG -t strandersson  .

echo "TAGGING: registry.digitalocean.com/johan-st/strandersson"
docker tag strandersson registry.digitalocean.com/johan-st/strandersson

echo "PUSHING: registry.digitalocean.com/johan-st/strandersson"
docker push registry.digitalocean.com/johan-st/strandersson