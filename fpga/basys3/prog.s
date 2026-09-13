# Entropic R32-P5 — Basys3 (Xilinx Artix-7) hardware bring-up self-check
# Self-contained: no preloaded data RAM needed (only writes to memory before reading it back).
# On SUCCESS x10 = 1 and the CPU halts via ecall (real, sticky halt).
# On failure x10 holds an error code and the CPU halts.
#
# Exercises: addi (ALU-immediate), add (ALU), register forwarding into ALU,
#            taken branch (beq), not-taken branch, a counted loop (bne),
#            and a load/store round-trip (sw then lw, tests MEM stage + load-use).
#
# Assemble with the RISC-V GNU toolchain:
#   riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o prog.o prog.s
#   riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x00000000 -o prog.elf prog.o
#   riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 prog.elf fpga_prog.hex

.text
.global _start
_start:
    # ---- constants ----
    addi x1, x0, 1          # x1 = 1
    addi x2, x0, 2          # x2 = 2
    add  x3, x1, x2         # x3 = 3     (ALU add; reads x1,x2 forwarded into EX)
    addi x5, x0, 3          # x5 = 3

    # ---- taken branch check (3 == 3) ----
    beq  x3, x5, t1         # 3==3 -> taken
    addi x10, x0, 2         # error 2: branch was NOT taken
    ecall

t1:
    # ---- counted loop: x4 = 3 down to 0 ----
    addi x4, x0, 3          # x4 = 3
loop:
    addi x4, x4, -1         # x4--
    bne  x4, x0, loop       # loop until x4 == 0
    beq  x4, x0, t2         # x4 == 0 -> continue
    addi x10, x0, 4         # error 4: loop did not reach 0
    ecall

t2:
    # ---- load/store round-trip ----
    sw   x3, 0(x0)          # mem[0] = 3
    lw   x6, 0(x0)          # x6 = 3
    beq  x6, x3, pass       # x6 == 3 -> pass
    addi x10, x0, 5         # error 5: load/store round-trip failed
    ecall

pass:
    addi x10, x0, 1         # SUCCESS: x10 = 1
    ecall

    .end
