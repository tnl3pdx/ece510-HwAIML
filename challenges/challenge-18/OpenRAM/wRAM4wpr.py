# Data word size
word_size = 32
# Number of words in the memory
num_words = 64

words_per_row = 4
#write_size = 32

# Port configuration
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0
num_spare_rows = 1
num_spare_cols = 1
ports_human = '1rw'

# Technology to use in $OPENRAM_TECH
tech_name = "sky130"

nominal_corner_only = True

# Output directory for the results
output_path = "temp/wRAM4wpr"

# Output file base name
output_name = "wRAM4wpr_32x64"

route_supplies = "ring"

check_lvsdrc = True

uniquify = True
