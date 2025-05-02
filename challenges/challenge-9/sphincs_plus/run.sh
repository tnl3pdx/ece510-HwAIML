#!/bin/bash

# Get the directory where the script is run from
DIR="$(pwd)"

# Obtain input args to the script
if [ $# -eq 0 ]; then
    echo "No arguments provided. Please provide the input file to encrypt."
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "File $1 does not exist."
    exit 1
fi

if [[ -n "$(ls -A "$DIR/myprofiles")" ]]; then
    echo "The directory '$DIR/myprofiles' is not empty. Removing all files..."
    rm -rf "$DIR/myprofiles/*"
else
    echo "The directory '$DIR/myprofiles' is empty. Continuing..."
fi

if [ -f "$DIR/sphincs_plus.py" ]; then
    echo "sphincs_plus.py exists. Proceeding with encryption."
else
    echo "sphincs_plus.py does not exist. Please ensure the file is in the current directory."
    exit 1
fi

# Generate a random key
python sphincs_plus.py --keygen 
python sphincs_plus.py --sign --input $1 --signature signature.bin
python sphincs_plus.py --verify --input $1 --signature signature.bin

