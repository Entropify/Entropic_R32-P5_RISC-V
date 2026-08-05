/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o store_mask_test ../tb/modules/tb_store_mask.sv ../rtl/store_mask.v"
 * Then: "vvp store_mask_test"
 * Then: "gtkwave tb_store_mask.vcd tb_store_mask.gtkw" to view waveform
 */

`default_nettype none
`timescale 1ns/1ps


task automatic golden_model (
    input logic [2:0] f3,
    input logic [31:0] rs2_data,
    input logic [1:0] byte_offset,
    output bit [31:0] expected_data,
    output bit [3:0] expected_mask 
);

    logic [7:0] raw_byte = rs2_data[7:0];
    logic [15:0] raw_half = rs2_data[15:0];

    expected_data = 32'b0;
    expected_mask = 4'b0000;

    case(f3)

        3'b010: begin // sw
            expected_mask = 4'b1111;
            expected_data = rs2_data;
        end

        3'b000: begin // sb lut

            case (byte_offset)
                2'd0: begin 
                    expected_mask = 4'b0001; 
                    expected_data = rs2_data; 
                end
                2'd1: begin 
                    expected_mask = 4'b0010; 
                    expected_data = {rs2_data[23:0], 8'h00}; 
                end
                2'd2: begin 
                    expected_mask = 4'b0100; 
                    expected_data = {rs2_data[15:0], 16'h0000}; 
                end
                2'd3: begin 
                    expected_mask = 4'b1000; 
                    expected_data = {rs2_data[7:0], 24'h000000}; 
                end
            endcase

        end

        3'b001: begin // sh lut

            if (byte_offset == 2'd0) begin
                expected_mask = 4'b0011; 
                expected_data = rs2_data;
            end

            else if (byte_offset == 2'd2) begin
                expected_mask = 4'b1100; 
                expected_data = {rs2_data[15:0], 16'h0000};
            end

        end

    endcase

endtask

module tb_store_mask;

    logic [31:0] write_data_in;
    logic [2:0] func3;
    logic [1:0] byte_offset;

    logic [31:0] masked_data_out;
    logic [3:0] write_mask_out;

    store_mask dut (
        .rs2_data(write_data_in),
        .func3(func3),
        .byte_offset(byte_offset),
        .store_data(masked_data_out),
        .write_mask(write_mask_out)
    );

    initial begin

        bit [31:0] expected_data;
        bit [3:0] expected_mask;

        // output files setup
        $dumpfile("tb_store_mask.vcd");
        $dumpvars(0, tb_store_mask);

        // clearing chip signals
        write_data_in = 32'd0;
        func3 = 3'd0;
        byte_offset = 2'd0;
        #20;

        $display("Starting Store Mask tests...");

        $display("CRT Tests:");

        for (int i = 0; i < 10000; i++) begin

            write_data_in = $urandom();
            func3 = $urandom_range(0, 7);
            byte_offset = $urandom_range(0, 3);

            golden_model(func3, write_data_in, byte_offset, expected_data, expected_mask);

            #10;

            assert ((expected_data == masked_data_out) && (expected_mask == write_mask_out)) begin

                if ((i + 1) % 1000 == 0) begin
                    $display("CRT test %0d / 10000 passed", i+1);
                end

            end

            else begin

                $fatal(1, "CRT test %0d failed. Func3: %0b, Write Data: %0h, Offset: %0d, Expected Write: %0h, Got Write: %0h, Expected Mask: %0b, Got Mask: %0b",
                i+1, func3, write_data_in, byte_offset, expected_data, masked_data_out, expected_mask, write_mask_out);

            end


        end


        #100;

        $display("Directed Tests:");

        // test 1: sw
        $display("Test 1: Store Word (SW)");
        func3 = 3'b010;
        byte_offset = 2'b00;
        write_data_in = 32'hDEADBEEF;
        #10;
        assert(write_mask_out == 4'b1111 && masked_data_out == 32'hDEADBEEF) begin
            $display("Test 1 passed");
        end else begin
            $fatal(1, "Error: SW failed. Expected Mask: 1111, Data: DEADBEEF. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 2: sh offset 0
        $display("Test 2: Store Halfword (SH) Offset 0");
        func3 = 3'b001;
        byte_offset = 2'b00;
        write_data_in = 32'h0000BEEF;
        #10;
        assert(write_mask_out == 4'b0011 && masked_data_out[15:0] == 16'hBEEF) begin
            $display("Test 2 passed");
        end else begin
            $fatal(1, "Error: SH Offset 0 failed. Expected Mask: 0011, Data[15:0]: BEEF. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 3: sh offset 2
        $display("Test 3: Store Halfword (SH) Offset 2");
        func3 = 3'b001;
        byte_offset = 2'b10;
        write_data_in = 32'h0000BEEF; 
        #10;
        assert(write_mask_out == 4'b1100 && masked_data_out[31:16] == 16'hBEEF) begin
            $display("Test 3 passed");
        end else begin
            $fatal(1, "Error: SH Offset 2 failed. Expected Mask: 1100, Data[31:16]: BEEF. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 4: sb offset 0
        $display("Test 4: Store Byte (SB) Offset 0");
        func3 = 3'b000;
        byte_offset = 2'b00;
        write_data_in = 32'h000000AA; 
        #10;
        assert(write_mask_out == 4'b0001 && masked_data_out[7:0] == 8'hAA) begin
            $display("Test 4 passed");
        end else begin
            $fatal(1, "Error: SB Offset 0 failed. Expected Mask: 0001, Data[7:0]: AA. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 5: sb offset 1
        $display("Test 5: Store Byte (SB) Offset 1");
        func3 = 3'b000;
        byte_offset = 2'b01;
        write_data_in = 32'h000000BB; 
        #10;
        assert(write_mask_out == 4'b0010 && masked_data_out[15:8] == 8'hBB) begin
            $display("Test 5 passed");
        end else begin
            $fatal(1, "Error: SB Offset 1 failed. Expected Mask: 0010, Data[15:8]: BB. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 6: sb offset 3
        $display("Test 6: Store Byte (SB) Offset 3");
        func3 = 3'b000;
        byte_offset = 2'b11;
        write_data_in = 32'h000000CC; 
        #10;
        assert(write_mask_out == 4'b1000 && masked_data_out[31:24] == 8'hCC) begin
            $display("Test 6 passed");
        end else begin
            $fatal(1, "Error: SB Offset 3 failed. Expected Mask: 1000, Data[31:24]: CC. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end
        

        // test 7: invalid func3
        $display("Test 7: Invalid func3");
        func3 = 3'b111;
        byte_offset = 2'b01;
        write_data_in = 32'h000000CC; 
        #10;
        assert(write_mask_out == 4'b0000 && masked_data_out == 32'b0) begin
            $display("Test 7 passed");
        end else begin
            $fatal(1, "Error: Invalid func3 failed. Expected Mask: 0000, Data: 0x00000000. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end

        // test 8: invalid half word alignment
        $display("Test 8: Invalid Half Word Alignment");
        func3 = 3'b001;
        byte_offset = 2'b01;
        write_data_in = 32'h0000DEAD; 
        #10;
        assert(write_mask_out == 4'b0000 && masked_data_out == 32'b0) begin
            $display("Test 8 passed");
        end else begin
            $fatal(1, "Error: Invalid half word alignment failed. Expected Mask: 0000, Data: 0x00000000. Got Mask: %b, Data: %h", write_mask_out, masked_data_out);
        end


        $display("All Store Mask tests successful, use 'gtkwave tb_store_mask.vcd tb_store_mask.gtkw' to open waveform.");
        


        $finish;

    end

endmodule
