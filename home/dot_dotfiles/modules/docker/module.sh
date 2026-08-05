#!/bin/bash

# Source remote helpers if available
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "${SCRIPT_DIR}/../../remote/remote_helpers.sh" ]; then
    . "${SCRIPT_DIR}/../../remote/remote_helpers.sh"
fi
