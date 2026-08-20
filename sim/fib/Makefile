
# default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# grab all the verilog hardware files
VERILOG_SOURCES += $(PWD)/../../rtl/*.v

# top-level Verilog module name
TOPLEVEL = soc_top

# python test file (without the .py extension)
MODULE = fib

# tell Cocotb where to find python file since it's not in the sim/ folder
export PYTHONPATH := $(PWD)/../../tb/top:$(PYTHONPATH)

# Force Icarus to dump the waveform file for GTKWave
# export WAVES = 1

SIM_BUILD = $(PWD)/../cocotb_fib

# Software Compilation Target
top_tb:
	# read the source from tb/top/, but spit the binaries into tb/programs/
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O0 -c fib.c -o fib.o
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -c crt0.s -o crt0.o
	riscv64-unknown-elf-ld -m elf32lriscv -T link.ld crt0.o fib.o -o fib.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 fib.elf ../../tb/programs/tb_program.hex

sim: top_tb

# Include Cocotb's standard make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
