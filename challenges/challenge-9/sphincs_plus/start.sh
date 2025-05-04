#!/bin/bash

# Get the directory where the script is run from
DIR="$(pwd)"

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
    echo "Checking for swig installation..."
    if ! command -v swig &> /dev/null; then
        echo "swig could not be found. Use the following command to install it:"
        echo "sudo apt-get install swig"
        echo "After installing swig, please run this script again."
        exit 1
    else
        echo "swig is already installed. Continuing..."
    fi
    echo "Installing requirements..."
    python3 -m pip install -r "$DIR/requirements.txt"
else
    echo "Warning: requirements.txt not found."
fi

echo "Setup complete. Virtual environment is activated."
echo "Note: To keep the virtual environment activated after the script completes,"
echo "you should run this script using 'source ./start.sh' instead of './start.sh'"