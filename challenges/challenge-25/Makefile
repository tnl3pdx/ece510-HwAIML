# Makefile for SPI CocoTB tests

# Specify top-level module and language
TOPLEVEL_LANG ?= verilog
TOPLEVEL = SPI
MODULE ?= hwsw_tb

# Path to source files
VERILOG_SOURCES = $(PWD)/src_sv/SPI/SPI.sv \
                  $(PWD)/src_sv/SPI/SPI_Controller.sv \
                  $(PWD)/src_sv/SPI/SPI_Periphery.sv

# Set simulator specific options (optional)
SIM ?= icarus

# Include cocotb's make rules to handle the simulation
include $(shell cocotb-config --makefiles)/Makefile.sim