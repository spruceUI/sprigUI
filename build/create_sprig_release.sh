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

if [ -z "$VERSION" ]; then
    echo "Error: failed to retrieve version from $VERSION_FILE"
    exit 1
fi

mkdir -p "$DESTINATION_DIR"

OUTPUT_7Z="${DESTINATION_DIR}/${ARCHIVE_NAME}V${VERSION}.7z"
OUTPUT_ZIP="${DESTINATION_DIR}/${ARCHIVE_NAME}V${VERSION}.zip"

# Clean old archives if they exist
for file in "$OUTPUT_7Z" "$OUTPUT_ZIP"; do
    if [ -f "$file" ]; then
        echo "Removing existing $file"
        rm "$file"
    fi
done

# Common exclusion rules
EXCLUDES=(
    '-xr!.git*'
    '-xr!build'
    '-x!.gitignore'
    '-x!.gitattributes'
    '-x!justfile'
    '-x!main'
    '-x!TODO.txt'
)

echo "Creating 7z archive..."
7z a -t7z -mx=9 "${EXCLUDES[@]}" "$OUTPUT_7Z" * || {
    echo "Error: failed to create 7z archive"
    exit 1
}

echo "Creating zip archive..."
# zip uses different exclusion syntax
zip -r -9 "$OUTPUT_ZIP" . -x \
    "*.git*" \
    "build/*" \
    ".gitignore" \
    ".gitattributes" \
    "justfile" \
    "main" \
    "TODO.txt" \
    "dist/*" || {
    echo "Error: failed to create zip archive"
    exit 1
}

echo
echo "✅ Archives created successfully:"
echo " - $OUTPUT_7Z"
echo " - $OUTPUT_ZIP"
exit 0
