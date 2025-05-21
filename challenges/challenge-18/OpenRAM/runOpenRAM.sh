#!/bin/bash

DIR="$(pwd)"
CONDADIR="$OPENRAM_HOME/../miniconda"

echo $CONDADIR
echo $OPENRAM_HOME
echo $PDK_ROOT

# Open conda shell from OpenRAM
if [ -d "$CONDADIR" ]; then
    echo "Activating conda environment..."
    source "$CONDADIR/bin/activate" 
else
    echo "Warning: conda environment not found."
    exit 1
fi

# Start OpenRAM Compiler Scripts

python3 $OPENRAM_HOME/../sram_compiler.py -v -p "temp/wRAM" -o wRAM wRAM.py

: '
# Check if the first argument is provided
if [ -z "$1" ]; then
    echo "No argument provided. Please provide a script name."
    exit 1
fi

# Run all scripts
if [ $1 = "all" ]; then
    echo "Running all scripts..."
    python3 $OPENRAM_HOME/../sram_compiler.py -v -p "temp/mBuf" -o mBuf $OPENRAM_HOME/../macros/sram_configs/sky130_sram_1kbyte_1r1w_8x1024_8.py 

elif  [ $1 = "mBuf" ]; then
    echo "Running mBuf script..."
    python3 $OPENRAM_HOME/../sram_compiler.py -v -p "temp/mBuf" -o mBuf $OPENRAM_HOME/../macros/sram_configs/sky130_sram_1kbyte_1r1w_8x1024_8.py 

elif [ $1 = "kROM" ]; then
    echo "Running kROM script..."
    python3 $OPENRAM_HOME/../rom_compiler.py -v -p "temp/kROM" -o kROM kROM.py

elif [ $1 = "wRAM" ]; then
    echo "Running wRAM script..."
    python3 $OPENRAM_HOME/../sram_compiler.py -v -p "temp/wRAM" -o wRAM wRAM.py

fi
'
