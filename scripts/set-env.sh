#!/bin/bash

# use 'source $(dirname "$0")/set-env.sh' to call this script from another script in the same folder

echo
echo "SETTING UP ENVIRONMENT VARIABLES"
export COMMIT_HASH="$(git rev-parse --short HEAD)"
export BUILD_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
export BUILD_TAG="$BUILD_TIME <$COMMIT_HASH>"

echo
FILE=$(dirname "$0")/../.env
if ! [ -f "$FILE" ]; then
    echo "no '.env' file found... skipping... (looked at $FILE)"
else
    # set up environment variables from .env
    count=0
    for e in $(cat $FILE | xargs); do
        export $e
        count=$((count + 1))
    done
    echo "$count variables loaded from '.env'"
fi
