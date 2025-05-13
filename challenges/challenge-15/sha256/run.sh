#!/bin/bash

# Check for at least one argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <verilog_or_systemverilog_files>"
    exit 1
fi

# Output file name
OUT="sim.vvp"

# Collect valid Verilog/SystemVerilog files
SRC_FILES=()
for file in "$@"; do
    ext="${file##*.}"
    if [[ "$ext" == "v" || "$ext" == "sv" ]]; then
        if [ -f "$file" ]; then
            SRC_FILES+=("$file")
        else
            echo "Warning: File '$file' does not exist."
        fi
    else
        echo "Warning: Skipping '$file' (not a .v or .sv file)"
    fi
done

if [ "${#SRC_FILES[@]}" -eq 0 ]; then
    echo "Error: No valid Verilog/SystemVerilog files provided."
    exit 2
fi

# Compile with iverilog
iverilog -g2012 -Wall -o "$OUT" "${SRC_FILES[@]}"
if [ $? -ne 0 ]; then
    echo "Error: iverilog compilation failed."
    exit 3
fi

# Run the simulation
vvp "$OUT"