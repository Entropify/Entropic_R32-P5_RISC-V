/*
 * tb_uart_life.v — run the compiled program and decode everything it prints.
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Generic UART-output capture: collects bytes until the line goes idle (the
 * program finished) or MAXCH characters arrive (the program is still running
 * and we only wanted the opening frames). Prints what it got, so the Life
 * fields can be read straight out of the simulation log.
 *
 * Run from fpga/basys3 with the image to test already built into
 * fpga_prog.hex:
 *   iverilog -o tb_uart_life.vvp tb_uart_life.v <the rtl sources>
 *   vvp tb_uart_life.vvp
 */

`timescale 1ns/1ps
`default_nettype none

module tb_uart_life;

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
    localparam MAXCH  = 2600;              // enough for a short (-DGENS=3) run

    reg [7:0] rx;
    reg [7:0] got [0:MAXCH-1];
    integer   i, guard, nchars;
    reg       done;

    initial begin
        rst_n = 0;
        #200;
        rst_n = 1;

        nchars = 0;
        done   = 1'b0;
        while (!done && nchars < MAXCH) begin
            guard = 0;
            /* The line being idle this long means the program has stopped
               printing. It has to comfortably exceed the program's own
               startup (tests, seeding, first frame preparation) or we give up
               before the first byte - the Life seed loop alone runs ~300 us. */
            while (uart_tx && guard < 200000) begin
                @(posedge clk);
                guard = guard + 1;
            end

            if (uart_tx) begin
                /* line idle this long: the program has stopped printing */
                done = 1'b1;
            end else begin
                #(BIT_NS + BIT_NS/2);              // mid start bit
                for (i = 0; i < 8; i = i + 1) begin rx[i] = uart_tx; #(BIT_NS); end
                got[nchars] = rx;
                nchars = nchars + 1;
            end
        end

        $display("");
        $display("------ UART output (%0d bytes) ------", nchars);
        for (i = 0; i < nchars; i = i + 1) $write("%c", got[i]);
        $display("-------------------------");
        $display("[TB] %0d bytes; x10=%0d halt=%b", nchars, x10_debug, halt);

        /* raw bytes to a file, so the run can be diffed against a native
           build of the same C program */
        begin : dump
            integer fd;
            fd = $fopen("uart_out.bin", "wb");
            for (i = 0; i < nchars; i = i + 1) $fwrite(fd, "%c", got[i]);
            $fclose(fd);
            $display("[TB] raw output written to uart_out.bin");
        end

        /* a full 20x20 frame plus the live-generation counter */
        if (nchars > 400)
            $display("LIFE TEST: got %0d bytes (a frame is ~%0d)", nchars, 22 + 20*21);
        else
            $display("LIFE TEST: FAIL - no frame");

        if (halt && x10_debug == 32'd1)
            $display("LIFE TEST: program halted cleanly (x10=1)");
        else
            $display("LIFE TEST: still running (no halt yet) - expected for a long run");

        $finish;
    end

    initial begin
        #400000000;                        // 400 ms of sim time
        $display("[TB] *** TIMEOUT *** (got %0d bytes)", nchars);
        $finish;
    end

endmodule
