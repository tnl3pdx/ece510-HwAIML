
word_size = 32
num_words = 256


write_size = 8 # Bits

# Single port
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0
num_spare_rows = 1
num_spare_cols = 1
ports_human = '1rw'

tech_name = "sky130"    
nominal_corner_only = True
route_supplies = "ring"
check_lvsdrc = True
uniquify = True

# Output directory for the results
output_path = "temp/mBuf"

# Output file base name
output_name = "mBuf_32x256"
