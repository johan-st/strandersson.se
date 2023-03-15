#!/bin/bash

$(dirname "$0")/check-env.sh

BUILD_TAG=${BUILD_TAG} BUILD_TIME=${BUILD_TIME} COMMIT_HASH=${COMMIT_HASH} parcel build --no-autoinstall
