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

# Message Buffer Instance
python3 $OPENRAM_HOME/../sram_compiler.py -v -p "temp/mBuf" -o mBuf $OPENRAM_HOME/../macros/sram_configs/sky130_sram_1kbyte_1r1w_8x1024_8.py 

python3 $OPENRAM_HOME/../rom_compiler.py -v kROM.py

python3 $OPENRAM_HOME/../sram_compiler.py -v wRAM.py

