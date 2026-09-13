#!/usr/bin/env bash
# Assemble uart_hello.s and run the UART unit + SoC integration tests.
# Copyright (c) 2026 Zhiyuan (Jerry) Jiang
# SPDX-License-Identifier: Apache-2.0
#
# Usage (from WSL):  bash /mnt/x/Entropic_R32-P5_RISC-V_UART/fpga/basys3/run_uart_test.sh

cd "$(dirname "$0")" || exit 1

echo "=== 1) assemble uart_hello.s ==="
cp ../../sim/c_hello_world/link.ld . || exit 1
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -c uart_hello.s -o uart_hello.o || exit 1
riscv64-unknown-elf-ld -m elf32lriscv -e _start -T link.ld uart_hello.o -o uart_hello.elf || exit 1
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 uart_hello.elf uart_hello.hex || exit 1
echo "--- uart_hello.hex ---"
cat uart_hello.hex

echo
echo "=== 2) uart_tx unit test ==="
iverilog -o tb_uart_tx.vvp tb_uart_tx.v ../../rtl/uart_tx.v && vvp tb_uart_tx.vvp

echo
echo "=== 3) SoC + UART integration test ==="
iverilog -o tb_uart_soc.vvp tb_uart_soc.v ../../rtl/*.v && vvp tb_uart_soc.vvp

echo
echo "=== 4) compiled C program over UART ==="
bash ../../sim/uart/build.sh hello_uart || exit 1
iverilog -o tb_uart_c.vvp tb_uart_c.v ../../rtl/*.v && vvp tb_uart_c.vvp
