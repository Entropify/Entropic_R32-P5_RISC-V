/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o pc_test ../tb/modules/tb_pc.sv ../rtl/pc.v"
 * Then: "vvp pc_test"
 * Then: "gtkwave tb_pc.vcd tb_pc.gtkw" to view waveform
 */


`default_nettype none
`timescale 1ns/1ps


module tb_pc;

    logic clk;
    logic rst_n;
    logic [31:0] pc_in;
    
    logic [31:0] pc_out;


    pc dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );


    //clk
    initial clk = 0;
    always #5 clk = ~clk; 


    initial begin

        //output files setup
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);


        //clearing chip signals
        rst_n = 1'b0;
        pc_in = 32'd0;
        #20; 


        //rst off
        rst_n = 1'b1;
        #10;

        $display("Starting Program Counter tests...");


        //test 1 reset behavior check
        $display("Test 1: Reset Behavior");
        #1; 

        assert (pc_out == 32'h00000000) begin
            $display("Test 1 passed");
        end 
        else begin
            $fatal(1, "Error: Reset failed. Expected 00000000, got %h", pc_out);
        end


        //test 2 normal +4 increment behavior
        $display("Test 2: Normal Increment (+4)");
        pc_in = 32'h00000004;
        @(posedge clk);
        #1;

        assert (pc_out == 32'h00000004) begin
            $display("Test 2 passed");
        end 
        else begin
            $fatal(1, "Error: PC did not update to 4. Got %h", pc_out);
        end


        //test 3 another normal increment
        $display("Test 3: Normal Increment (+8)");
        pc_in = 32'h00000008;
        @(posedge clk);
        #1;

        assert (pc_out == 32'h00000008) begin
            $display("Test 3 passed");
        end 
        else begin
            $fatal(1, "Error: PC did not update to 8. Got %h", pc_out);
        end


        //test 4 branch/jump arbitrary address target

        $display("Test 4: Branch/Jump Target Update");
        pc_in = 32'hFADED420;
        @(posedge clk);
        #1;

        assert (pc_out == 32'hFADED420) begin
            $display("Test 4 passed");
        end 
        else begin
            $fatal(1, "Error: Branch update failed. Expected FADED420, got %h", pc_out);
        end


        $display("All Program Counter tests successful, use 'gtkwave tb_pc.vcd tb_pc.gtkw' to open waveform.");
        
        #4;

        $finish;

    end

endmodule
