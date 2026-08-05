# make sure in sim folder
# run:
# riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o ../tb/programs/tb_instruction_mem.o ../tb/programs/tb_instruction_mem.s
# riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x00000000 -o ../tb/programs/tb_instruction_mem.elf ../tb/programs/tb_instruction_mem.o
# riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 ../tb/programs/tb_instruction_mem.elf ../tb/programs/tb_program.hex

.global _start

_start:
    add x3, x1, x2
    sub x4, x1, x2
    and x5, x1, x2
    or  x6, x1, x2

    sw  x3, 8(x0)
    sw  x4, 12(x0)
    sw  x5, 16(x0)
    sw  x6, 20(x0)

    beq x0, x0, 0
