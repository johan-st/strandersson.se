#!/bin/bash

source $(dirname "$0")/set-env.sh
if ! $(dirname "$0")/check-env.sh; then
    exit 1
fi

echo
echo "starting dev server..."
BUILD_TAG=hello_moto parcel --no-autoinstall --port 8080
