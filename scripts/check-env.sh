#!/bin/bash

# Check that environment variables are set
echo
echo "ENVIRONMENT VARIABLES:"
for e in COMMIT_HASH BUILD_TIME BUILD_TAG; do
    if [ -z "${!e}" ]; then
        echo "$e is not set - Exiting..."
        exit 1
    fi
    echo "- $e: ${!e}"
done
