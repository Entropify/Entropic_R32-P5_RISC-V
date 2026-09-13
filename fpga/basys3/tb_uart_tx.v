/*
 * tb_uart_tx.v — unit test for uart_tx (Icarus);
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Feeds bytes and decodes the serial line back, checking start/data/stop.
 */

`timescale 1ns/1ps
`default_nettype none

module tb_uart_tx;

    localparam CLKS   = 8;            // clocks per bit (small for fast sim)
    localparam BIT_NS = CLKS * 10;    // 10 ns clock -> 80 ns per bit

    reg        clk = 0;
    reg        rst_n = 0;
    reg        tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire       tx;
    wire       tx_busy;

    uart_tx #(.CLKS_PER_BIT(CLKS)) dut (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx), .tx_busy(tx_busy)
    );

    always #5 clk = ~clk;

    reg [7:0] rx;
    integer   i;
    integer   errors = 0;

    task send_and_check(input [7:0] b);
        begin
            while (tx_busy) @(negedge clk);
            @(negedge clk);
            tx_data  = b;
            tx_start = 1;
            @(negedge clk);
            tx_start = 0;

            @(negedge tx);                    // start bit begins
            #(BIT_NS + BIT_NS/2);             // mid of data bit 0
            for (i = 0; i < 8; i = i + 1) begin
                rx[i] = tx;
                #(BIT_NS);
            end

            if (tx !== 1'b1) begin
                $display("  stop bit error for 0x%02x", b);
                errors = errors + 1;
            end
            if (rx !== b) begin
                $display("  DATA error: sent 0x%02x got 0x%02x", b, rx);
                errors = errors + 1;
            end else begin
                $display("  OK 0x%02x", b);
            end

            #(BIT_NS);
        end
    endtask

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        #100;

        $display("[tb_uart_tx] sending test bytes");
        send_and_check(8'h48);   // 'H'
        send_and_check(8'h69);   // 'i'
        send_and_check(8'h0A);   // '\n'
        send_and_check(8'hA5);   // bit pattern
        send_and_check(8'h00);
        send_and_check(8'hFF);

        if (errors == 0) $display("UART_TX UNIT TEST: PASS");
        else             $display("UART_TX UNIT TEST: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
