
# Clock period in ns
CLK_PERIOD = 15

# Widths for SPI communication
LONGESTWIDTH = 32  # Controller to Peripheral data width
PAUSE_CLK = 1  # Pause time
TRANSACTION_TIME = (LONGESTWIDTH * 2) + PAUSE_CLK + 4 # Total cycles for a transaction