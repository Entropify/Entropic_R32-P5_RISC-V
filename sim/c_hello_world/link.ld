MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rw)  : ORIGIN = 0x00000000, LENGTH = 4K
}

/* The instruction ROM and the data RAM are two SEPARATE 4 KB memories that
 * both sit at address 0x0: the CPU fetches from the ROM, but reads data over
 * the data bus, which lands in the RAM. So this single "address space" is
 * really two overlapping ones and the linker cannot tell them apart.
 *
 * That matters because data_mem is preloaded with this same image, so that
 * .rodata string literals are readable at run time. If .data/.bss started at
 * 0x0 they would sit on top of that preloaded image, and the program's own
 * writes to its globals would corrupt its own string literals.
 *
 * So the read/write sections are pushed up to 0x800:
 *
 *   0x000 - 0x7FF   code + .rodata   (keep the image under 2 KB)
 *   0x800 - ...     .data + .bss     (globals, arrays)
 *   0xF00 -> down   stack            (crt0 sets sp = 0xF00)
 *
 * Note: the ROM still has 4 KB, so the image itself may grow past 0x800 and
 * overlap these addresses *in the ROM's* space -- harmless, since the ROM and
 * the RAM are physically different memories. Only the RAM layout matters here.
 */

ENTRY(_start)          /* ALSO the root for --gc-sections: without it the
                          garbage collector finds no live code and emits an
                          ELF with no sections at all */

SECTIONS
{
    .text : { *(.text*) } > IMEM
    .rodata : { *(.rodata*) *(.srodata*) } > IMEM

    .data 0x800 : { *(.data*) *(.sdata*) } > DMEM
    .bss : { *(.bss*) *(.sbss*) *(COMMON) } > DMEM
}
