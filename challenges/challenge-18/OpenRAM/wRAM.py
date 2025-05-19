# Data word size
word_size = 32
# Number of words in the memory
num_words = 64

# Port configuration
num_rw_ports = 0
num_r_ports = 1
num_w_ports = 1

# Technology to use in $OPENRAM_TECH
tech_name = "sky130"
# Process corners to characterize
process_corners = [ "TT" ]
# Voltage corners to characterize
supply_voltages = [ 3.3 ]
# Temperature corners to characterize
temperatures = [ 25 ]

# Output directory for the results
output_path = "temp/wSRAM"

# Output file base name
output_name = "wSRAM_32x64"

route_supplies = "ring"

check_lvsdrc = True

uniquify = True

# Disable analytical models for full characterization (WARNING: slow!)
# analytical_delay = False

# To force this to use magic and netgen for DRC/LVS/PEX
# Could be calibre for FreePDK45
drc_name = "magic"
lvs_name = "netgen"
pex_name = "magic"