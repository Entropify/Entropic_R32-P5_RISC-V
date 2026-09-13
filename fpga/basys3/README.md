# Entropic R32-P5 — Basys3 FPGA Bring-Up

Takes the already-verified **Entropic R32-P5** (5-stage pipelined RV32I core,
with forwarding, hazard detection, branch prediction and a real halt) onto a
**Digilent Basys3** board (Xilinx Artix-7 `xc7a35tcpg236-1`) using Vivado.

Target board: Basys3 (Artix-7 xc7a35tcpg236-1), 100 MHz onboard oscillator (W5).
Toolchain: **Vivado 2026.1** (installed at `X:\AMDDesignTools\2026.1\Vivado`).

---

## First milestone — "it's alive"

The self-check program (`prog.s`) exercises the core — ALU, register
forwarding, taken/not-taken branches, a counted loop, and a load/store
round-trip — then writes `x10 = 1` on success (an error code on failure) and
halts via `ecall` (the core's real, sticky halt).

On the board:

| LED | Meaning |
|-----|---------|
| `led[15]` | CPU halted (program reached `ecall`). Lit = finished. |
| `led[7:0]` | `x10` return code. `1` = PASS. Anything else = error code. |

**Expected on a working board:** press `btnC` (reset), then immediately
`led[15]` lights and `led[0]` lights (showing `x10 = 1`). If instead you see a
different value on `led[7:0]`, that's the failure code.

The program is deliberately self-contained (no preloaded data RAM), so it runs
with no setup on real hardware.

---

## Files

| File | Purpose |
|------|---------|
| `basys3_top.v`            | Board top: clock divider (100→50 MHz), reset sync, LED readout. |
| `basys3.xdc`              | Basys3 pin constraints (clk W5, btnC U18, LEDs) + `create_generated_clock`. |
| `build.tcl`               | Vivado batch flow: synth → opt/place/route → write_bitstream. |
| `build_synth.tcl`         | Faster synthesis-only run (utilization/timing sanity check). |
| `prog.s`                  | Self-checking hardware test program (RISC-V assembly). |
| `fpga_prog.hex`           | The assembled program loaded into instruction ROM at synthesis. |
| `tb_basys3.v`             | Testbench to functionally verify `basys3_top` (run in WSL Icarus). |
| `sim_bfm.v`               | Icarus-only stub for the Xilinx `BUFG` primitive. |
| `r32p5_basys3.bit`        | **Output bitstream** to program the board. |

---

## How to program the board

The generated bitstream is `r32p5_basys3.bit`. Either:

**Vivado GUI**
1. Open the project (`fpga/basys3/proj/r32p5_basys3.xpr`).
2. `Open Hardware Manager` → `Open Target` → `Auto Connect`.
3. Right-click the part → `Program Device`, select `r32p5_basys3.bit`, Program.

**Command line (with a board attached via Digilent USB/JTAG)**
```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {X:/Entropic_R32-P5_RISC-V/fpga/basys3/r32p5_basys3.bit} [current_hw_device]
program_hw_devices [current_hw_device]
```

---

## Building from scratch

```bash
# from the fpga/basys3 directory
X:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source build.tcl
```

Result: `r32p5_basys3.bit` + `report_utilization_impl.rpt` / `report_timing_route.rpt`.

Synthesis-only sanity check:
```bash
X:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source build_synth.tcl
```

### Resources (place & route, 50 MHz)
- **Slice LUTs:** 4694 / 20800 (22.6%)
- **Slice Registers:** 4718 / 41600 (11.3%)
- **Block RAM:** 0 (instruction ROM / data RAM infer as distributed LUTRAM)
- **Timing:** all constraints met at 50 MHz (worst setup slack ≈ +0.2 ns)
  - *The design does NOT close at 100 MHz (worst path ≈ 15.8 ns), so the CPU is
    clocked at 100/2 = 50 MHz via a register divider + BUFG.*

---

## Changing the program

1. Edit `prog.s`. (RISC-V GNU tools live in WSL.)
2. Reassemble:
   ```bash
   wsl -e bash -c "cd /mnt/x/Entropic_R32-P5_RISC-V/fpga/basys3 && \
     riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o prog.o prog.s && \
     riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x00000000 -o prog.elf prog.o && \
     riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 prog.elf fpga_prog.hex"
   ```
3. Re-run `build.tcl`.

The program path is threaded from `basys3_top` → `soc_top` → `instruction_mem`
via the `INSTR_MEM_FILE` parameter (default points at `fpga_prog.hex`).

---

## Functional verification (simulation)

`tb_basys3.v` drives the 100 MHz clock and reset button and checks that the CPU
halts with `x10 = 1`:

```bash
wsl -e bash -c "cd /mnt/x/Entropic_R32-P5_RISC-V/fpga/basys3 && \
  iverilog -o basys3_sim.vvp -s tb_basys3 /mnt/x/Entropic_R32-P5_RISC-V/rtl/*.v \
    basys3_top.v tb_basys3.v sim_bfm.v && vvp basys3_sim.vvp"
```
Expected output: `CPU HALTED ... x10 (led[7:0]) = 1 ... PASS`.

---

## RTL changes made for the FPGA target

These are backward-compatible add-ons (the Icarus/cocotb and OpenLane flows
still build and behave identically):

- `rtl/reg_file.v` — added `x10_debug` output (`= internal_reg[10]`).
- `rtl/rv32i_core.v` — added `x10_debug` output, wired from `reg_file`.
- `rtl/instruction_mem.v` — added `parameter INIT_FILE` for the `$readmemh` path.
- `rtl/soc_top.v` — added `parameter INSTR_MEM_FILE` (threaded to the ROM) and
  `x10_debug` output.

The design has pre-existing forward-reference warnings
(`ex_actual_result` used before declared, etc.) that Vivado synthesis tolerates
but the strict `xsim` parser rejects — so the functional TB is run with Icarus.
