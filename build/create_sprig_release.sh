#!/bin/bash

cd "$(dirname "$0")/.."

ARCHIVE_NAME="sprig"
VERSION_FILE="sprig/version"
DESTINATION_DIR="dist"
VERSION=

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: could not find file $VERSION_FILE"
    exit 1
fi

VERSION=$(< "$VERSION_FILE")

if [ "$VERSION" == "" ]; then
    echo "Error: failed to retrieve version from $VERSION_FILE"
    exit 1
fi

mkdir -p "$DESTINATION_DIR"

OUTPUT_7Z="${DESTINATION_DIR}/${ARCHIVE_NAME}V${VERSION}.7z"

if [ -f "$OUTPUT_7Z" ]; then
    echo "Removing already existing $OUTPUT_7Z"
    rm "$OUTPUT_7Z"
fi

# Exclude unnecessary files from the MainPyUI submodule:
7z a -t7z -mx=9 \
    -xr!.git* \
    -xr!build \
    -x!.gitignore \
    -x!.gitattributes \
    -x!justfile \
    -x!main \
    -x!TODO.txt \
    -xr!'App/PyUI/MainPyUI/onionOS' \
    -xr!'App/PyUI/MainPyUI/muOS' \
    -xr!'App/PyUI/MainPyUI/miyoo_mini_flip' \
    -xr!'App/PyUI/MainPyUI/docs' \
    -xr!'App/PyUI/MainPyUI/Themes' \
    -xr!'App/PyUI/MainPyUI/misc' \
    -xr!'App/PyUI/MainPyUI/main-ui' \
    -xr!'App/PyUI/MainPyUI/lang' \
    -x!'App/PyUI/MainPyUI/README.md' \
    -x!'App/PyUI/MainPyUI/LICENSE.md' \
    "$OUTPUT_7Z" *

if [ $? -ne 0 ]; then
    echo "Error: failed to create 7z archive"
    exit 1
fi

echo "7z archive $OUTPUT_7Z created successfully"
exit 0
