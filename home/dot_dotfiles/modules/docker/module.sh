#!/bin/bash

## @module docker
## @title Docker
## @description Provides Docker container management, inspection, and diagnostic helpers.
## @category Containers
## @requires docker
## @tags docker container containers images compose
## @source functions.sh

# Source remote helpers if available
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "${SCRIPT_DIR}/../../remote/remote_helpers.sh" ]; then
    . "${SCRIPT_DIR}/../../remote/remote_helpers.sh"
fi
