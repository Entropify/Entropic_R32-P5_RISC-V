/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o alu_test ../tb/modules/tb_alu.sv ../rtl/alu.v"
 * Then: "vvp alu_test"
 * Then: "gtkwave tb_alu.vcd tb_alu.gtkw" to view waveform
 */


`default_nettype none
`timescale 1ns/1ps


/* OOP NOT WORKING I HATE ICARUS AHHHHHHHHHHHHHHHHHHHHHHHHHHHH

 class alu_item;

 rand logic [31:0] data_1_r;
 rand logic [31:0] data_2_r;
 rand logic [3:0] alu_control_r;

 constraint valid_operations {

        alu_control inside {
            4'b0000, //AND
            4'b0001, //OR
            4'b0010, //ADD
            4'b0011, //SRL
            4'b0100, //SLL
            4'b0101, //SRA
            4'b0110, //SUB
            4'b0111, //SLT
            4'b1000, //SLTU
            4'b1001  //XOR
        };
    }

 endclass

 */



function automatic bit [31:0] golden_model (
    logic [31:0] d1,
    logic [31:0] d2,
    logic [3:0] control);

bit [31:0] result;

case(control)

    4'b0000: result = d1 & d2;
    4'b0001: result = d1 | d2;
    4'b0010: result = d1 + d2;
    4'b0110: result = d1 - d2;

    4'b1001: result = d1 ^ d2;

    4'b0100: result = d1 << d2[4:0];
    4'b0011: result = d1 >> d2[4:0];

    4'b0101: result = $signed(d1) >>> d2[4:0];

    4'b0111: result = ($signed(d1) < $signed(d2)) ? 32'd1 : 32'd0;

    4'b1000: result = (d1 < d2) ? 32'd1 : 32'd0;

    default: result = 32'h0000_0000;

endcase

return result;

 endfunction


 
 module tb_alu;

    logic [31:0] tb_data_1;
    logic [31:0] tb_data_2;
    logic [3:0]  tb_alu_control;

    logic [31:0] tb_alu_result;
    logic tb_zero;

    alu dut (
        .data_1(tb_data_1),
        .data_2(tb_data_2),
        .alu_control(tb_alu_control),
        .alu_result(tb_alu_result),
        .zero(tb_zero)
    );

    initial begin

        int flag;

        bit [31:0] expected_out;

        logic [3:0] valid_ops [0:9];

        valid_ops[0] = 4'b0000;
        valid_ops[1] = 4'b0001;
        valid_ops[2] = 4'b0010;
        valid_ops[3] = 4'b0011;
        valid_ops[4] = 4'b0100;
        valid_ops[5] = 4'b0101;
        valid_ops[6] = 4'b0110;
        valid_ops[7] = 4'b0111;
        valid_ops[8] = 4'b1000;
        valid_ops[9] = 4'b1001;

        //output files setup

        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        //clearing chip signals

        tb_data_1 = 32'd0;
        tb_data_2 = 32'd0;
        tb_alu_control = 4'b0000;
        
        #10;

        $display("Starting ALU tests...");

        $display("CRT Tests:");


        //CRT

        //alu_item crt_test = new();

        // 10000 RANDOM TESTS YESSIR


        for (int i = 0; i < 10000; i ++) begin

            /* icarus i will delete u >:(

            flag = crt_test.randomize();

            if (!flag) begin
                $fatal(1, "Randomization failed");
            end

            data_1 = crt_test.data_1_r;
            data_2 = crt_test.data_2_r;
            alu_control = crt_test.alu_control_r;

            */

            tb_data_1 = $urandom();
            tb_data_2 = $urandom();

            tb_alu_control = valid_ops[$urandom_range(0, 9)];




            #10;

            expected_out = golden_model(tb_data_1, tb_data_2, tb_alu_control);

            assert (tb_alu_result == expected_out) begin

                if ((i + 1) % 1000 == 0) begin
                    $display("CRT test %0d / 10000 passed", i + 1);
                end

            end

            else begin
                $fatal(1, "CRT test %0d failed. ALU Control: %0b, D1: %0h, D2: %0h, Expected: %0h, Got: %0h", 
                   i+1, tb_alu_control, tb_data_1, tb_data_2, expected_out, tb_alu_result);
            end

        end



        //DIRECTED TESTS BELOWWW

        //test 1 ADD 15 + 25 = 40

        tb_data_1 = 32'd15;
        tb_data_2 = 32'd25; 
        tb_alu_control = 4'b0010;
        
        #100;

        $display("Directed Tests:");

        $display("Test 1 (ADD): 15 + 25 = 40");

        assert (tb_alu_result == 32'd40) begin
            $display("Test 1 passed");
        end 

        else begin
            $fatal (1, "Error: ALU autput is wrong. Expected 15 + 25 = 40, got %d", tb_alu_result);
        end
        


        //test 2 SUB 100 - 100 = 0

        tb_data_1 = 32'd100;
        tb_data_2 = 32'd100;
        tb_alu_control = 4'b0110;
        
        #10;

        $display("Test 2 (SUB): 100 - 100 = 0");

        assert (tb_alu_result == 32'd0) begin
            $display("Test 2 output passed");
        end 

        else begin
            $fatal (1, "Error: ALU autput is wrong. Expected 100 - 100 = 0, got %d", tb_alu_result);
        end

        assert (tb_zero == 1'b1) begin
            $display("Test 2 zero flag passed");  
        end 

        else begin
            $fatal (1, "Error: Zero flag is wrong. Expected zero flag of 1 when 100 - 100 = 0, got %b", tb_zero);
        end

        $display("Test 2 passed");



        //test 3 AND 1100 & 1010 = 1000

        tb_data_1 = 32'b1100;
        tb_data_2 = 32'b1010;
        tb_alu_control = 4'b0000;
        
        #10;

        $display("Test 3 (AND): 1100 & 1010 = 1000");

        assert (tb_alu_result == 32'b1000) begin
            $display("Test 3 passed");
        end 

        else begin
            $fatal (1, "Error: ALU autput is wrong. Expected 1100 & 1010 = 1000, got %b", tb_alu_result);
        end



        //test 4 OR 1001 | 0110 = 1111

        tb_data_1 = 32'b1001;
        tb_data_2 = 32'b0110;
        tb_alu_control = 4'b0001;
        
        #10;

        $display("Test 4 (OR): 1001 | 0110 = 1111");

        assert (tb_alu_result == 32'b1111) begin
            $display("Test 4 passed");
        end 

        else begin
            $fatal (1, "Error: ALU autput is wrong. Expected 1001 | 0110 = 1111, got %b", tb_alu_result);
        end


        //test 5 invalid control signal 1111

        tb_data_1 = 32'b1000;
        tb_data_2 = 32'b1110;
        tb_alu_control = 4'b1111;

        #10;

        $display("Test 5 (invalid control signal): 1111");

        assert (tb_alu_result == 32'h0000_0000) begin
            $display("Test 5 passed");
        end 

        else begin
            $fatal (1, "Error: ALU autput is wrong. Expected output 32'h0000_0000 for invalid control signal 1111, got %b", tb_alu_result);
        end


        $display("All ALU tests successful, use 'gtkwave tb_alu.vcd tb_alu.gtkw' to open waveform.");

        
        $finish;

    end

endmodule
