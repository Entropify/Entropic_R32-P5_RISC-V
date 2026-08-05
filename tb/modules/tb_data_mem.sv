/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o data_mem_test ../tb/modules/tb_data_mem.sv ../rtl/data_mem.v"
 * Then: "vvp data_mem_test"
 * Then: "gtkwave tb_data_mem.vcd tb_data_mem.gtkw" to view waveform
 */

`default_nettype none
`timescale 1ns/1ps

module tb_data_mem;

    logic clk;
    logic mem_write;
    logic mem_read;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [3:0] write_mask; // NEW SIGNAL
    
    logic [31:0] read_data;

    data_mem dut (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .address(address),
        .write_data(write_data),
        .write_mask(write_mask), // NEW CONNECTION
        .read_data(read_data)
    );

    //clk
    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin

        //output files setup
        $dumpfile("tb_data_mem.vcd");
        $dumpvars(0, tb_data_mem);

        //clearing chip signals
        mem_write = 1'b0;
        mem_read = 1'b0;
        address = 32'd0;
        write_data = 32'd0;
        write_mask = 4'b0000; // DEFAULT MASK TO 0
        #20; 

        $display("Starting data memory tests...");

        //test 1 basic write and read
        $display("Test 1: Basic Write and Read (Address 4)");
        address = 32'd4;
        write_data = 32'hDEADBEEF;
        write_mask = 4'b1111; // FULL WORD MASK
        mem_write = 1'b1;
        
        @(posedge clk);
        #1;
        mem_write = 1'b0;

        address = 32'd4;
        mem_read = 1'b1;
        #1;

        assert (read_data == 32'hDEADBEEF) begin
            $display("Test 1 passed");
        end 
        else begin
            $fatal(1, "Error: Write/Read failed. Expected DEADBEEF, got %h", read_data);
        end

        //test 2 mem_read disable test
        $display("Test 2: Memory Read Disable");
        mem_read = 1'b0;
        #1;

        assert (read_data == 32'h00000000) begin
            $display("Test 2 passed");
        end 
        else begin
            $fatal(1, "Error: mem_read disable failed. Expected 00000000, got %h", read_data);
        end

        //test 3 write isolation check
        $display("Test 3: Write Isolation Check (Address 8 vs 4)");
        //write to address 8
        address = 32'd8;
        write_data = 32'hDAD69420;
        write_mask = 4'b1111;
        mem_write = 1'b1;
        
        @(posedge clk);
        #1;
        mem_write = 1'b0;

        //read back address 4 to ensure it wasn't overwritten
        address = 32'd4;
        mem_read = 1'b1;
        #1;

        assert (read_data == 32'hDEADBEEF) begin
            $display("Test 3 passed");
        end 
        else begin
            $fatal(1, "Error: Memory corrupted. Address 4 was overwritten. Got %h", read_data);
        end

        //test 4 word alignment check [31:2]
        $display("Test 4: Word Alignment Check");
        //write to address 12
        address = 32'd12;
        write_data = 32'h12345678;
        write_mask = 4'b1111;
        mem_write = 1'b1;
        mem_read = 1'b0;
        
        @(posedge clk);
        #1;
        mem_write = 1'b0;

        //try reading from address 15 (should map to the exact same word as 12)
        address = 32'd15;
        mem_read = 1'b1;
        #1;

        assert (read_data == 32'h12345678) begin
            $display("Test 4 passed");
        end 
        else begin
            $fatal(1, "Error: Word alignment [31:2] failed. Expected 12345678, got %h", read_data);
        end

        //test 5 byte write (SB)
        $display("Test 5: Byte Write (Mask 4'b0001)");
        // first, write a full word of F's to address 16
        address = 32'd16;
        write_data = 32'hFFFFFFFF;
        write_mask = 4'b1111;
        mem_write = 1'b1;
        @(posedge clk);

        #1;
        
        // overwrite only the lowest byte with 0xAA
        write_data = 32'h000000AA;
        write_mask = 4'b0001; // enable byte 0
        @(posedge clk);
        #1;
        mem_write = 1'b0;
        
        // read it back
        mem_read = 1'b1;
        #1;
        
        assert (read_data == 32'hFFFFFFAA) begin
            $display("Test 5 passed");
        end 
        else begin
            $fatal(1, "Error: Byte write failed. Expected FFFFFFAA, got %h", read_data);
        end

        //test 6 halfword write (sh)
        $display("Test 6: Halfword Write (Mask 4'b1100)");

        //write upper halfword of address 16 with 0xBBBB
        // memory should become BBBBFFAA

        address = 32'd16;
        write_data = 32'hBBBB0000;
        write_mask = 4'b1100; // enable bytes 3 and 2
        mem_write = 1'b1;
        mem_read = 1'b0;
        @(posedge clk);
        #1;
        mem_write = 1'b0;
        
        // read
        mem_read = 1'b1;
        #1;
        
        assert (read_data == 32'hBBBBFFAA) begin
            $display("Test 6 passed");
        end 
        else begin
            $fatal(1, "Error: Halfword write failed. Expected BBBBFFAA, got %h", read_data);
        end

        $display("All Data Memory tests successful, use 'gtkwave tb_data_mem.vcd tb_data_mem.gtkw' to open waveform.");
        
        $finish;

    end

endmodule
