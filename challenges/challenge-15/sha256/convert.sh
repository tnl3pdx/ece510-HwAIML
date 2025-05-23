#!/bin/bash

# Usage: ./convert_sv_to_v.sh <input_sv_folder>

INPUT_DIR="$1"
OUTPUT_DIR="converted"

# Check if sv2v is installed
if ! command -v sv2v &> /dev/null; then
    echo "Error: sv2v is not installed or not in PATH."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

SV_FILES=("$INPUT_DIR"*.sv)

echo ${SV_FILES[@]}

sv2v --write=$OUTPUT_DIR ${SV_FILES[@]}
