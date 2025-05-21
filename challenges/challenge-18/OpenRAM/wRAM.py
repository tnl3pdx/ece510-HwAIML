# Data word size
word_size = 32
# Number of words in the memory
num_words = 64

human_byte_size = "{:.0f}kbytes".format((word_size * num_words)/1024/8)

write_size = 32

# Port configuration
num_rw_ports = 0
num_r_ports = 1
num_w_ports = 1
ports_human = '1r1w'

# Technology to use in $OPENRAM_TECH
tech_name = "sky130"

nominal_corner_only = True

# Output directory for the results
output_path = "temp/wSRAM"

# Output file base name
output_name = "wSRAM_32x64"

route_supplies = "ring"

check_lvsdrc = True

uniquify = True
