#!/bin/bash
GITDIR="$(git rev-parse --show-toplevel)"
DIR="$(pwd)"

echo "Copying source files to $DIR/tmpsrc/"

cp -a "$GITDIR/challenges/project/src/." "$DIR/tmpsrc/"

# Check if the tmpsrc directory has files
if [ -z "$(ls -A "$DIR/tmpsrc")" ]; then
    echo "Error: The tmpsrc directory is empty. Please check the source path."
    exit 1
fi
echo "Source files copied successfully."

# Check if venv directory exists
if [ ! -d "$DIR/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$DIR/.venv"
fi

# Activate the virtual environment
echo "Activating virtual environment..."
source "$DIR/.venv/bin/activate"

# Install requirements if requirements.txt exists
if [ -f "$DIR/requirements.txt" ]; then
    echo "Installing requirements..."
    python3 -m pip install -r "$DIR/requirements.txt"
else
    echo "Warning: requirements.txt not found."
fi


echo "Setup complete. Virtual environment is activated."
echo "Note: To keep the virtual environment activated after the script completes,"
echo "you should run this script using 'source ./start.sh' instead of './start.sh'"