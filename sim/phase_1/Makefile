#run make clean then make sim btw future jerry


# default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# grab all the verilog hardware files
VERILOG_SOURCES += $(PWD)/../../rtl/*.v

# top-level Verilog module name
TOPLEVEL = soc_top

# python test file (without the .py extension)
MODULE = phase_1

# tell Cocotb where to find python file since it's not in the sim/ folder
export PYTHONPATH := $(PWD)/../../tb/top:$(PYTHONPATH)

# Force Icarus to dump the waveform file for GTKWave
export WAVES = 1

SIM_BUILD = $(PWD)/../cocotb_sim_phase_1

# Software Compilation Target
top_tb:
	# read the source from tb/top/, but spit the binaries into tb/programs/
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o ../../tb/programs/phase_1.o ../../tb/top/phase_1.s
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x00000000 -o ../../tb/programs/phase_1.elf ../../tb/programs/phase_1.o
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 ../../tb/programs/phase_1.elf ../../tb/programs/tb_program.hex

sim: top_tb

# Include Cocotb's standard make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
