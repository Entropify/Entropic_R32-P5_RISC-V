/*
 * Entropic R32-P5 — Basys3 (Xilinx Artix-7 xc7a35tcpg236-1) top-level
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Bring-up harness:
 *   - clk     : 100 MHz oscillator on W5 (Basys3).
 *   - rst_btn : push-button btnC (active-high) -> synchronized active-low reset.
 *   - led[15] : CPU halted (lit when the program reaches ecall/ebreak).
 *   - led[7:0]: x10 return code (1 = pass; any other value = error code).
 *
 * Clocking: the pipelined core's longest combinational path (branch-resolve ->
 * PC feedback) needs ~16 ns, so the CPU is clocked at 100/2 = 50 MHz via a
 * register divider + BUFG (see XDC create_generated_clock).
 *
 * The program image is loaded into instruction_mem via $readmemh at synthesis.
 */

`default_nettype none

module basys3_top #(
    parameter INSTR_MEM_FILE = "X:/Entropic_R32-P5_RISC-V/fpga/basys3/fpga_prog.hex"
)(
    input  wire       clk,      // 100 MHz (W5)
    input  wire       rst_btn,  // btnC, active-high push button (pin U18)
    output wire [15:0] led
);

    // ---- reset synchronizer (btnC active-high; drive active-low rst_n) ----
    reg [2:0] rst_n_sync;
    always @(posedge clk) begin
        rst_n_sync <= {rst_n_sync[1:0], ~rst_btn};
    end
    wire rst_n = rst_n_sync[2];

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

    // ---- SoC: pipelined RISC-V core + instruction ROM + data RAM ----
    wire       halt;
    wire [31:0] x10_debug;

    soc_top #(
        .INSTR_MEM_FILE(INSTR_MEM_FILE)
    ) cpu_soc (
        .clk(cpu_clk),
        .rst_n(rst_n),
        .halt(halt),
        .x10_debug(x10_debug)
    );

    // ---- LED readout ----
    // led[15]      = halted
    // led[14:8]    = spare (0)
    // led[7:0]     = x10 return code
    assign led = {halt, 7'b0, x10_debug[7:0]};

endmodule
