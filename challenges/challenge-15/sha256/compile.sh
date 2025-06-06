#!/bin/bash
# filepath: compile_sv.sh
# Script to compile SystemVerilog files using iverilog

# Define output file
OUTPUT="sim.vvp"

# Define source directory
SRC_DIR="src"

# Check if compile.txt exists
if [ ! -f "complie.txt" ]; then
    echo "Error: complie.txt file not found!"
    exit 1
fi

# Read the file list from complie.txt
FILES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    if [[ ! -z "$line" ]] && [[ ! "$line" =~ ^// ]]; then
        FILES+=("$SRC_DIR/$line")
    fi
done < "complie.txt"

# Check if any files were found
if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No files to compile found in complie.txt"
    exit 1
fi

echo "Compiling ${#FILES[@]} SystemVerilog files..."

# Build iverilog command with all files
iverilog_cmd="iverilog -g2012 -o $OUTPUT"

# Add each file to the command
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Adding $file"
        iverilog_cmd="$iverilog_cmd $file"
    else
        echo "Warning: File $file not found, skipping"
    fi
done

# Execute iverilog command
echo "Running: $iverilog_cmd"
$iverilog_cmd

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful! Output file: $OUTPUT"
    echo "Run 'vvp $OUTPUT' to execute the simulation"
else
    echo "Compilation failed!"
    exit 1
fi