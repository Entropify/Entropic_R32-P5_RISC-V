/*
 * tb_uart_soc.v — integration test: run uart_hello on the SoC and decode the
 * UART line back out. Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps
`default_nettype none

module tb_uart_soc;

    // CPU clock: 50 MHz (20 ns period), matching basys3_top's divider
    reg clk = 0;
    always #10 clk = ~clk;

    reg        rst_n = 0;
    wire       halt;
    wire [31:0] x10_debug;
    wire       uart_tx;

    soc_top #(
        .INSTR_MEM_FILE("uart_hello.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .halt(halt),
        .x10_debug(x10_debug),
        .uart_tx(uart_tx)
    );

    localparam CLKS   = 434;              // matching uart_tx default @ 50 MHz
    localparam BIT_NS = CLKS * 20;        // 8680 ns per bit

    reg [7:0] rx;
    integer   i;
    integer   nchars = 0;
    reg [7:0] got [0:15];

    task decode_byte;
        begin
            @(negedge uart_tx);                    // start bit
            #(BIT_NS + BIT_NS/2);                  // mid of data bit 0
            for (i = 0; i < 8; i = i + 1) begin
                rx[i] = uart_tx;
                #(BIT_NS);
            end
            got[nchars] = rx;
            $display("[TB] byte %0d = 0x%02x '%c'", nchars, rx, rx);
            nchars = nchars + 1;
        end
    endtask

    initial begin
        rst_n = 0;
        #200;
        rst_n = 1;

        decode_byte();   // 'H'
        decode_byte();   // 'i'
        decode_byte();   // '\n'

        $display("[TB] received %0d bytes; x10=%0d halt=%b", nchars, x10_debug, halt);

        if (nchars == 3 && got[0] == 8'h48 && got[1] == 8'h69 && got[2] == 8'h0A)
            $display("UART SOC TEST: PASS");
        else
            $display("UART SOC TEST: FAIL");

        $finish;
    end

    initial begin
        #40000000;
        $display("[TB] *** TIMEOUT *** (received %0d bytes)", nchars);
        $finish;
    end

endmodule
