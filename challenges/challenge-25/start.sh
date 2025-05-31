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
    echo "Installing requirements..."
    python3 -m pip install -r "$DIR/requirements.txt"
else
    echo "Warning: requirements.txt not found."
fi

# Clone SPI git repository if it doesn't exist
if [ ! -d "$DIR/src_sv/SPI" ]; then
    echo "Cloning SPI repository..."
    git clone https://github.com/tom-urkin/SPI.git "$DIR/src_sv/SPI"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone SPI repository."
        exit 1
    fi
else
    echo "SPI repository already exists."
fi

echo "Setup complete. Virtual environment is activated."
echo "Note: To keep the virtual environment activated after the script completes,"
echo "you should run this script using 'source ./start.sh' instead of './start.sh'"