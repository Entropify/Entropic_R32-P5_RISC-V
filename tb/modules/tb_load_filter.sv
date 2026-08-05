/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o load_filter_test ../tb/modules/tb_load_filter.sv ../rtl/load_filter.v"
 * Then: "vvp load_filter_test"
 * Then: "gtkwave tb_load_filter.vcd tb_load_filter.gtkw" to view waveform
 */

`default_nettype none
`timescale 1ns/1ps

function automatic bit [31:0] golden_model (
    logic [2:0]  f3,
    logic [31:0] ram_data,
    logic [1:0]  byte_offset
);
    logic [31:0] temp;
    logic [7:0]  raw_byte;
    logic [15:0] raw_half;

    temp = ram_data >> (byte_offset * 8);
    raw_byte = temp[7:0];
    raw_half = temp[15:0];

    case(f3)

        3'b010: return ram_data;
        3'b100: return (temp & 32'h000000FF);
        3'b101: return (temp & 32'h0000FFFF);
        

        3'b000: begin

            if (raw_byte[7] == 1'b1) return {24'hFFFFFF, raw_byte};

            else return {24'h000000, raw_byte};
        end
        
        3'b001: begin

            if (raw_half[15] == 1'b1) return {16'hFFFF, raw_half};

            else return {16'h0000, raw_half};
        end
        
        default: return 32'b0;

    endcase
endfunction



module tb_load_filter;

    logic [2:0]  func3;
    logic [31:0] ram_data;
    logic [1:0]  byte_offset;

    logic [31:0] filtered_data;

    



    load_filter dut (
        .func3(func3),
        .ram_data(ram_data),
        .byte_offset(byte_offset),
        .filtered_data(filtered_data)
    );

    initial begin

        bit [31:0] expected_out;


        // output files setup
        $dumpfile("tb_load_filter.vcd");
        $dumpvars(0, tb_load_filter);

        // clearing chip signals
        func3 = 3'd0;
        ram_data = 32'd0;
        byte_offset = 2'd0;

        #20;

        $display("Starting Load Filter tests...");

        $display("CRT Tests:");


        //CRT 10000 tests

        for (int i = 0; i < 10000; i++) begin

            func3 = $urandom_range(0, 7);
            ram_data = $urandom();
            byte_offset = $urandom_range(0, 3);

            expected_out = golden_model(func3, ram_data, byte_offset);

            #10;

            assert (filtered_data == expected_out) begin

                if ((i + 1) % 1000 == 0) begin
                    $display("CRT test %0d / 10000 passed", i+1);
                end
            end

            else begin
                $fatal(1, "CRT test %0d failed. Func3: %0b, RAM Data: %0h, Offset: %0d, Expected: %0h, Got: %0h", 
                i+1, func3, ram_data, byte_offset, filtered_data, expected_out);

            end



        end

        //DIRECTED TESTS

        #100;

        $display("Directed Tests:");

        // test 1: lw
        $display("Test 1: Load Word (LW)");
        func3 = 3'b010;
        byte_offset = 2'b00;
        ram_data = 32'h89ABCDEF;
        #10;
        assert(filtered_data == 32'h89ABCDEF) begin
            $display("Test 1 passed");
        end else begin
            $fatal(1, "Error: LW failed. Expected 89ABCDEF, got %h", filtered_data);
        end

        // test 2: lbu offset 1
        $display("Test 2: Load Byte Unsigned (LBU) Offset 1");
        func3 = 3'b100;
        byte_offset = 2'b01;
        ram_data = 32'h89ABCDEF; // byte 1 is CD
        #10;
        assert(filtered_data == 32'h000000CD) begin
            $display("Test 2 passed");
        end else begin
            $fatal(1, "Error: LBU Offset 1 failed. Expected 000000CD, got %h", filtered_data);
        end

        // test 3: lb offset 3
        $display("Test 3: Load Byte (LB) Negative Offset 3");
        func3 = 3'b000;
        byte_offset = 2'b11;
        ram_data = 32'h89ABCDEF; // msb 1
        #10;
        assert(filtered_data == 32'hFFFFFF89) begin
            $display("Test 3 passed");
        end else begin
            $fatal(1, "Error: LB Negative Offset 3 failed. Expected FFFFFF89, got %h", filtered_data);
        end

        // test 4: lb offset 0
        $display("Test 4: Load Byte (LB) Positive Offset 0");
        func3 = 3'b000;
        byte_offset = 2'b00;
        ram_data = 32'h89ABCD7F; // msb 0
        #10;
        assert(filtered_data == 32'h0000007F) begin
            $display("Test 4 passed");
        end else begin
            $fatal(1, "Error: LB Positive Offset 0 failed. Expected 0000007F, got %h", filtered_data);
        end

        // test 5: lhu offset 2
        $display("Test 5: Load Halfword Unsigned (LHU) Offset 2");
        func3 = 3'b101;
        byte_offset = 2'b10;
        ram_data = 32'h89ABCDEF;
        #10;
        assert(filtered_data == 32'h000089AB) begin
            $display("Test 5 passed");
        end else begin
            $fatal(1, "Error: LHU Offset 2 failed. Expected 000089AB, got %h", filtered_data);
        end

        // test 6: lh negative offset 2
        $display("Test 6: Load Halfword (LH) Negative Offset 2");
        func3 = 3'b001; 
        byte_offset = 2'b10;
        ram_data = 32'h89ABCDEF; // msb is 1
        #10;
        assert(filtered_data == 32'hFFFF89AB) begin
            $display("Test 6 passed");
        end else begin
            $fatal(1, "Error: LH Negative Offset 2 failed. Expected FFFF89AB, got %h", filtered_data);
        end
        
        // test 7: default
        $display("Test 7: Default Opcode Fallback");
        func3 = 3'b111;
        byte_offset = 2'b00;
        ram_data = 32'hFFFFFFFF; 
        #10;
        assert(filtered_data == 32'h00000000) begin
            $display("Test 7 passed");
        end else begin
            $fatal(1, "Error: Default fallback failed. Expected 00000000, got %h", filtered_data);
        end

        $display("All Load Filter tests successful, use 'gtkwave tb_load_filter.vcd tb_load_filter.gtkw' to open waveform.");
        
        $finish;

    end

endmodule
