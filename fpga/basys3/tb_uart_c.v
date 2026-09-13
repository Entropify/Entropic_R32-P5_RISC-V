/*
 * tb_uart_c.v — integration test: run the compiled C program (fpga_prog.hex)
 * and decode everything it prints. Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps
`default_nettype none

module tb_uart_c;

    reg clk = 0;
    always #10 clk = ~clk;                 // 50 MHz

    reg        rst_n = 0;
    wire       halt;
    wire [31:0] x10_debug;
    wire       uart_tx;

    soc_top #(
        .INSTR_MEM_FILE("fpga_prog.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n), .halt(halt), .x10_debug(x10_debug), .uart_tx(uart_tx)
    );

    localparam CLKS   = 434;
    localparam BIT_NS = CLKS * 20;

    reg [7:0] rx;
    reg [7:0] got [0:1023];
    integer   i, guard, nchars;
    reg       done;

    initial begin
        rst_n = 0;
        #200;
        rst_n = 1;

        nchars = 0;
        done   = 1'b0;
        while (!done && nchars < 1024) begin
            guard = 0;
            while (uart_tx && guard < 700) begin
                @(posedge clk);
                guard = guard + 1;
            end

            if (uart_tx) begin
                $display("[TB] line idle after %0d bytes", nchars);
                done = 1'b1;
            end else begin
                #(BIT_NS + BIT_NS/2);
                for (i = 0; i < 8; i = i + 1) begin rx[i] = uart_tx; #(BIT_NS); end
                got[nchars] = rx;
                nchars = nchars + 1;
            end
        end

        $display("");
        $display("------ UART output ------");
        for (i = 0; i < nchars; i = i + 1) $write("%c", got[i]);
        $display("-------------------------");
        $display("[TB] %0d bytes; x10=%0d halt=%b", nchars, x10_debug, halt);

        /* expect the output to start with "Hel" (see sim/uart/hello_uart.c) */
        if (nchars > 20 && x10_debug == 32'd1 &&
            got[0] == 8'h48 && got[1] == 8'h65 && got[2] == 8'h6C)
            $display("UART C TEST: PASS");
        else
            $display("UART C TEST: FAIL");

        $finish;
    end

    initial begin
        #60000000;
        $display("[TB] *** TIMEOUT *** (got %0d bytes)", nchars);
        $finish;
    end

endmodule
