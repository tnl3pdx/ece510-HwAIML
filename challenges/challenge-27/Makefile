# Makefile for SPI CocoTB tests

# Specify top-level module and language
TOPLEVEL_LANG ?= verilog
TOPLEVEL = sha256_reduced
MODULE = tests
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Set simulator specific options (optional)
SIM ?= icarus

# Path to source files
VERILOG_SOURCES =   $(PWD)/tmpsrc/compression_loop_parity.sv \
                    $(PWD)/tmpsrc/k_rom.sv \
                    $(PWD)/tmpsrc/message_controller.sv \
                    $(PWD)/tmpsrc/msg_ram.sv \
                    $(PWD)/tmpsrc/sha256_reduced.sv \
                    $(PWD)/tmpsrc/w_ram_half.sv 


# Include cocotb's make rules to handle the simulation
include $(shell cocotb-config --makefiles)/Makefile.sim
