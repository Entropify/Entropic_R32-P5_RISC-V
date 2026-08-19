

//cpu: hello world! hi mom im alive!

/*
run these in order: :p

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O0 -c hello_world.c -o hello_world.o
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -c crt0.s -o crt0.o
riscv64-unknown-elf-ld -m elf32lriscv -T link.ld crt0.o hello_world.o -o hello_world.elf
riscv64-unknown-elf-objcopy -O binary hello_world.elf hello_world.bin
python3 hex_convert.py hello_world.bin ../../tb/programs/tb_program.hex



gtkwave ../cocotb_hello_world/soc_top.fst  ../phase5.gtkw
*/


int main() {
    int x = 1 + 2;
    return x;
}

