#!/bin/bash

echo "ENVIRONMENT VARIABLES:"
for e in BUILD_TAG BUILD_TIME COMMIT_HASH; do
    if [ -z "${!e}" ]; then
        echo "$e is not set - Exiting..."
        exit 1
    fi
    echo "- $e: ${!e}"
done

BUILD_TAG=${BUILD_TAG} parcel build --no-autoinstall
