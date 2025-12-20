#!/bin/sh

cd "$(dirname "$0")"

# Try to get version from git first
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    VERSION=$(git describe --tags --always --dirty 2>/dev/null)
    if [ -n "$VERSION" ]; then
        echo "$VERSION"
        exit 0
    fi
fi

# Fallback to functions.sh
. ./functions.sh
get_olx_version
