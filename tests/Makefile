# Copyright (c) 2016 Technische Universitaet Dresden, Germany
# Chair for VLSI-Design, Diagnostic and Architecture
# Author: Martin Zabel
# All rights reserved.

all:

CWD = $(shell pwd)

SIM ?= icarus
TOPLEVEL_LANG ?= verilog


VERILOG_SOURCES = $(CWD)/../hdl/*.v


TOPLEVEL = single_cycle_riscv
MODULE := single_cycle_riscv_test
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

CUSTOM_SIM_DEPS += instructions.hex
instructions.hex:
	cp ../hdl/instructions.hex .

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
