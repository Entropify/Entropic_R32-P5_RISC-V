MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rw)  : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    .text : { *(.text*) } > IMEM
    .rodata : { *(.rodata*) } > IMEM

    .data : { *(.data*) } > DMEM
    .bss : { *(.bss*) } > DMEM
}
