#!/bin/bash

# set up environment variables
source $(dirname "$0")/set-env.sh

npm run build-prod
