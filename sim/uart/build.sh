#!/usr/bin/env bash
# Compile a C program to an instruction-ROM image for the Basys3 build.
# Copyright (c) 2026 Zhiyuan (Jerry) Jiang
# SPDX-License-Identifier: Apache-2.0
#
# Usage (from WSL):
#   bash /mnt/x/Entropic_R32-P5_RISC-V_UART/sim/uart/build.sh life
#   bash .../build.sh life -DGENS=3        # extra flags are passed through
#
# The image must fit the 4 KB instruction ROM (1024 words). -Os keeps the code
# compact and --gc-sections drops startup/libgcc routines the program never
# calls; the size check below refuses to emit an image the ROM cannot hold.
#
# Notes:
#  - rv32i has no hardware divide, so / and % pull in libgcc's __udivsi3 /
#    __umodsi3. Even with -nostdlib we must link libgcc, or any C code that
#    divides fails to link.
#  - -nostdlib also means no memset/memcpy, yet GCC will still lower loops
#    into calls to them at higher optimisation levels. minilib.c supplies the
#    few that turn up.

set -e
cd "$(dirname "$0")" || exit 1

SRC="${1:-hello_uart}"
EXTRA="${2:-}"                       # extra flags, e.g. -DGENS=3 for a fast sim
CFLAGS="-march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -Os \
        -ffunction-sections -fdata-sections -Wall $EXTRA"
LIBGCC=$(riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -print-libgcc-file-name)

riscv64-unknown-elf-gcc $CFLAGS -c "${SRC}.c" -o "${SRC}.o"
riscv64-unknown-elf-gcc $CFLAGS -c minilib.c -o minilib.o
riscv64-unknown-elf-gcc $CFLAGS -c ../c_hello_world/crt0.s -o crt0.o
riscv64-unknown-elf-ld -m elf32lriscv --gc-sections -T ../c_hello_world/link.ld \
    crt0.o "${SRC}.o" minilib.o "$LIBGCC" -o "${SRC}.elf"
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 "${SRC}.elf" ../../fpga/basys3/fpga_prog.hex

# report the image size, and refuse to hand the ROM something it cannot hold
SIZE=$(riscv64-unknown-elf-size "${SRC}.elf")
IMAGE=$(echo "$SIZE" | awk 'NR==2 {print $1 + $2}')
echo "$SIZE" | sed -n '1,2p'
printf 'rom image: %s bytes of 4096 (%s%%)\n' "$IMAGE" "$((IMAGE * 100 / 4096))"
if [ "$IMAGE" -gt 4096 ]; then
    echo "ERROR: image exceeds the 4 KB instruction ROM" >&2
    exit 1
fi

echo "wrote ../../fpga/basys3/fpga_prog.hex from ${SRC}.c"
