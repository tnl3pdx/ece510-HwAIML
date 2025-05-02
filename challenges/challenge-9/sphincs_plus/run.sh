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
<<com
if [ "$(find "$DIR/my_profiles" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    if [[ -n "$(ls -A "$DIR/my_profiles")" ]]; then
        echo "The directory '$DIR/my_profiles' is not empty."
        read -p "Are you sure you want to remove all files in '$DIR/my_profiles'? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm -rf "$DIR/my_profiles/*"
            echo "All files removed from '$DIR/my_profiles'."
        else
            echo "Operation canceled. No files were removed."
        fi
    else
        echo "The directory '$DIR/my_profiles' is empty. Continuing..."
    fi
else
    echo "The directory '$DIR/_myprofiles' does not exist. Creating it..."
    mkdir -p "$DIR/my_profiles"
fi
com

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

