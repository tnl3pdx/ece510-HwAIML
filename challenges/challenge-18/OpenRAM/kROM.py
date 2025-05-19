
# Data word size
word_size = 1

# Enable LVS/DRC checking
check_lvsdrc = True

# Path to input data. Either binary file or hex.
rom_data = "K_256byte.hex"
# Format type of input data
data_type = "hex"

# Technology to use in $OPENRAM_TECH, currently only sky130 is supported
tech_name = "sky130"

# Output directory for the results
output_path = "temp/kROM"

# Output file base name
output_name = "kROM_256byte"

# Only nominal process corner generation is currently supported
nominal_corner_only = True

# Add a supply ring to the generated layout
route_supplies = "ring"