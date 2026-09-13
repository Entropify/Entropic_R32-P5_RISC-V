/*
 * tb_cpu_c.v — run fpga_prog.hex and report the halt/x10 result (no UART).
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps
`default_nettype none

module tb_cpu_c;

    reg clk = 0;
    always #10 clk = ~clk;

    reg        rst_n = 0;
    wire       halt;
    wire [31:0] x10_debug;
    wire       uart_tx;

    soc_top #(
        .INSTR_MEM_FILE("fpga_prog.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n), .halt(halt), .x10_debug(x10_debug), .uart_tx(uart_tx)
    );

    initial begin
        rst_n = 0;
        #200;
        rst_n = 1;
        wait (halt);
        #200;
        $display("[TB] halted: x10=%0d (0x%08x)", x10_debug, x10_debug);
        $finish;
    end

    initial begin
        #20000000;
        $display("[TB] *** TIMEOUT *** x10=%0d (0x%08x) halt=%b", x10_debug, x10_debug, halt);
        $finish;
    end

endmodule
