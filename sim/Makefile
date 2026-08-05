#run make clean then make sim btw future jerry
# also jerry use gtkwave cocotb_sim/soc_top.fst soc_top.gtkw

# default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# grab all the verilog hardware files
VERILOG_SOURCES += $(PWD)/../rtl/*.v

# top-level Verilog module name
TOPLEVEL = soc_top

# python test file (without the .py extension)
MODULE = tb_top_soc

# tell Cocotb where to find python file since it's not in the sim/ folder
export PYTHONPATH := $(PWD)/../tb/top:$(PYTHONPATH)

# Force Icarus to dump the waveform file for GTKWave
export WAVES = 1

SIM_BUILD = cocotb_sim

# Software Compilation Target
top_tb:
	# read the source from tb/top/, but spit the binaries into tb/programs/
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o ../tb/programs/tb_top_soc.o ../tb/top/tb_top_soc.s
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x00000000 -o ../tb/programs/tb_top_soc.elf ../tb/programs/tb_top_soc.o
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 ../tb/programs/tb_top_soc.elf ../tb/programs/tb_program.hex

# Include Cocotb's standard make rules
include $(shell cocotb-config --makefiles)/Makefile.sim