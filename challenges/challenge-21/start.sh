#!/bin/bash
GITDIR="$(git rev-parse --show-toplevel)"
DIR="$(pwd)"

echo "Copying source files to $DIR/tmpsrc/"

rm -rf "$DIR/tmpsrc/"

cp -a "$GITDIR/challenges/project/src/." "$DIR/tmpsrc/"

# Check if the src directory has files
if [ -z "$(ls -A "$DIR/tmpsrc")" ]; then
    echo "Error: The tmpsrc directory is empty. Please check the source path."
    exit 1
fi
echo "Source files copied successfully."
