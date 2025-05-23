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

for file in "$INPUT_DIR"/*.sv; do
    base_name=$(basename "$file" .sv)
    sv2v "$file" > "$OUTPUT_DIR/$base_name.v"
done