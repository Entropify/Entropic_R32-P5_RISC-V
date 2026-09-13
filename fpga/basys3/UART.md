# UART bring-up (Basys3)

Adds a UART transmitter so the R32-P5 can print to the PC's serial terminal, and
so compiled C programs can produce visible output.

## Where the module lives

| Piece | File | Role |
|-------|------|------|
| `uart_tx` | `rtl/uart_tx.v` | 8N1 transmitter, `CLKS_PER_BIT` parameter |
| MMIO decode | `rtl/soc_top.v` | maps the UART at `0x1000_0000`, gates the RAM strobes |
| Pin + top | `fpga/basys3/basys3_top.v`, `basys3.xdc` | `uart_tx` -> pin **A18** (`RsTx`) |
| C helpers | `sim/uart/uart.h` | `uart_putc` / `uart_puts` / `uart_putint` / `uart_puthex` |

**Rule of thumb:** a peripheral is a new module under `rtl/`, instantiated inside
`soc_top.v` (the SoC-level wrapper) — never inside the RAM/ROM. The CPU talks to
it through the same data bus it uses for memory, and `soc_top` decodes which
address goes where. `data_mem` and `instruction_mem` are untouched.

## Memory map

| Address | Device |
|---------|--------|
| `0x0000_0000` – `0x0000_0FFF` | data RAM (4K); stack top = `0xF00` |
| `0x0000_0000` – `0x0000_0FFF` | instruction ROM (4K, separate memory) |
| `0x1000_0000` | UART TX — store = send byte (low 8 bits); load = `{31'b0, tx_busy}` |

Decode: `uart_sel = (data_address[31:28] == 4'h1)`.

### How software sees it

The ROM and the RAM both live at `0x0`, so the linker's single address space is
really two overlapping ones. `link.ld` splits them deliberately:

| Range | Contents |
|-------|----------|
| `0x000` – `0x7FF` | code, then `.rodata` (keep the image under 2 KB) |
| `0x800` – `...` | `.data`, then `.bss` (globals and arrays) |
| `0xF00` down | stack (`crt0.s` sets `sp = 0xF00`) |

`.data`/`.bss` sit at `0x800` rather than `0x0` because `data_mem` is preloaded
with the program image — globals at `0x0` would be written on top of that image
and corrupt the program's own string literals.

### Byte budget

The instruction ROM is **4 KB = 1024 instructions**. `build.sh` reports the image
size and refuses to emit one that will not fit. `-Os`, `-ffunction-sections
-fdata-sections` and `--gc-sections` keep it down; `ENTRY(_start)` in `link.ld`
is what gives `--gc-sections` a root to keep live (without it the collector emits
an ELF with no sections at all). `minilib.c` supplies `memset`/`memcpy`/
`memmove`, which GCC still calls under `-nostdlib` once it optimises a loop into
one.

## Protocol and wiring

- **115200 baud, 8N1.** `CLKS_PER_BIT = 434 = 50 MHz / 115200`.
- FPGA TX is pin **A18** (`RsTx`) — the FT2232HQ's RXD, i.e. towards the PC's COM
  port. Verified against Digilent's own Basys3 GPIO demo, which maps its
  `UART_TXD` output to pin A18.
- Open the board's COM port at **115200 8N1**.

## Printing from C

```c
#include "uart.h"

int main(void) {
    uart_putc('H'); uart_putc('i');
    uart_putc(' '); uart_putint(42);
    return 1;                 /* x10 = 1 -> pass */
}
```

Build a program with `bash sim/uart/build.sh <name>` — it compiles `<name>.c`
and writes `fpga/basys3/fpga_prog.hex`, which the ROM loads at synthesis.

### Division needs libgcc

rv32i has no hardware divide, so `/` and `%` pull in libgcc's `__udivsi3` and
`__umodsi3`. `build.sh` links libgcc explicitly; without it, any C code that
divides fails to link (undefined reference).

## String literals (fixed)

The instruction ROM and the data RAM are two *separate* 4K memories that both
live at address `0x0`. The CPU fetches instructions from the ROM, but reads data
(`.rodata` string literals included) over the data bus, which lands in the data
RAM. Originally the RAM had no initial contents, so `uart_puts("hello")` read
garbage.

**Fix:** `data_mem` now takes an `INIT_FILE` parameter and preloads the same
program image the instruction ROM uses (`$readmemh`), so `.rodata` — and any
initialised `.data` — really is present in RAM at run time. Normal string
literals now work:

```c
uart_puts("Hello from the Entropic R32-P5 on Basys3!\r\n");
```

**Caveat:** `.bss` is still not zeroed (the startup `crt0.s` is minimal), so give
globals explicit initialisers rather than relying on a zero default.

## Conway's Game of Life (`sim/uart/life.c`)

A 20x20 field drawn as ASCII, redrawn in place with `ESC[H` so it animates
rather than scrolling:

```
Gen 0
.......OO..O........
....OOO.......O.O..O
.OOO...O......OO....
```

- The field is padded to 22x22 with a permanently dead border, so the neighbour
  count needs no bounds checks at all. Two byte buffers, swapped each generation.
- Seed is a xorshift32 RNG with a fixed seed, so every build looks the same.
- Runs `GENS` generations then halts with `x10 = 1`; `-DGENS=<n>` overrides it
  for a quick simulation run.
- Paced by the UART itself — a frame is ~430 characters, so ~39 ms, about
  **25 frames per second**.
- **Verified** by compiling the identical C natively and comparing output: the
  core's UART stream is byte-for-byte identical to the native run (1813 bytes).

## Timing at 50 MHz

The core's critical path is the branch-resolve loop, which closes at roughly
51 MHz — so at 50 MHz the result depends on placement. The same sources have
produced WNS **+0.39, +0.28, +0.03 and −0.34** across runs. `build_life.tcl`
uses timing-directed place & route (`ExtraTimingOpt` + `AggressiveExplore`) and
escalates if the first pass misses; it reached **+0.73 ns**.

If a future change will not close, running the core at 25 MHz (divide by 4)
costs nothing visible — the UART, not the CPU, sets the frame rate.

## Tests

`bash fpga/basys3/run_uart_test.sh` (WSL + Icarus):

1. unit test of `uart_tx` — bit-level loopback of several bytes
2. SoC integration — an assembly program writes `Hi\n`
3. compiled C program — prints the fib sequence, checks the prefix and `x10`
4. Life — `tb_uart_life.v` runs `life.c` and also writes the raw bytes to
   `uart_out.bin`, so the run can be diffed against a native build
