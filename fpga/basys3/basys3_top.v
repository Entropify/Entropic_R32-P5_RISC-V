/*
 * Entropic R32-P5 — Basys3 (Xilinx Artix-7 xc7a35tcpg236-1) top-level
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Bring-up harness:
 *   - clk     : 100 MHz oscillator on W5 (Basys3).
 *   - rst_btn : push-button btnC (active-high).
 *   - uart_tx : UART transmit line -> FT2232HQ RXD (PC COM port). Pin A18.
 *   - led     : status readout, see the LED section below.
 *
 * Clocking: the pipelined core needs ~20 ns per stage, so the CPU runs at
 * 100/2 = 50 MHz via a register divider + BUFG (see XDC create_generated_clock).
 *
 * Reset: asynchronous assert, but the DE-ASSERT is synchronised to cpu_clk —
 * the clock domain it actually resets. (Synchronising it to the 100 MHz input
 * clock instead would release the CPU's flops asynchronously to their own
 * clock, which can leave the pipeline in an inconsistent state at start-up.)
 *
 * The program image is loaded into instruction_mem via $readmemh at synthesis.
 */

`default_nettype none

module basys3_top #(
    parameter INSTR_MEM_FILE = "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3/fpga_prog.hex"
)(
    input  wire        clk,      // 100 MHz (W5)
    input  wire        rst_btn,  // btnC, active-high push button (pin U18)
    output wire [15:0] led,      // status: {halt, 7'b0, x10[7:0]}
    output wire        uart_tx   // UART TX to the PC (pin A18, RsTx)
);

    // ---- 100 MHz -> 50 MHz CPU clock divider ----
    reg clk_div;
    initial clk_div = 1'b0;   // FPGA flops init to 0 via GSR; explicit so sim matches
    always @(posedge clk) begin
        clk_div <= ~clk_div;
    end

    wire cpu_clk;
    BUFG bufg_cpu (
        .I(clk_div),
        .O(cpu_clk)
    );

    // ---- reset: async assert on btnC, sync de-assert in the CPU clock domain ----
    reg [1:0] rst_sync;
    always @(posedge cpu_clk or posedge rst_btn) begin
        if (rst_btn) rst_sync <= 2'b00;               // pressed (or bouncing) -> hold in reset
        else         rst_sync <= {rst_sync[0], 1'b1}; // released -> release reset, 2 cpu_clk edges later
    end
    wire rst_n = rst_sync[1];

    // ---- SoC: pipelined RISC-V core + instruction ROM + data RAM + UART ----
    wire        halt;
    wire [31:0] x10_debug;

    soc_top #(
        .INSTR_MEM_FILE(INSTR_MEM_FILE)
    ) cpu_soc (
        .clk(cpu_clk),
        .rst_n(rst_n),
        .halt(halt),
        .x10_debug(x10_debug),
        .uart_tx(uart_tx)
    );

    // ---- LED readout ----
    // led[15]      = halted (the program reached its end)
    // led[14:8]    = spare (0)
    // led[7:0]     = x10 return code (1 = pass)
    assign led = {halt, 7'b0, x10_debug[7:0]};

endmodule
