/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o instruction_mem_test ../tb/modules/tb_instruction_mem.sv ../rtl/instruction_mem.v"
 * Then: "vvp instruction_mem_test"
 * Then: "gtkwave tb_instruction_mem.vcd tb_instruction_mem.gtkw" to view waveform
 */


`default_nettype none
`timescale 1ns/1ps


module tb_instruction_mem;

    logic [31:0] address;
    
    logic [31:0] instruction;


    //the golden reference model (shadow memory)
    logic [31:0] expected_rom [0:1023];
    integer i;


    instruction_mem dut (
        .address(address),
        .instruction(instruction)
    );


    initial begin

        //output files setup
        $dumpfile("tb_instruction_mem.vcd");
        $dumpvars(0, tb_instruction_mem);


        //clearing chip signals
        address = 32'd0;
        #20; 


        //load the exact same hex file into the testbench's memory
        $readmemh("../tb/programs/tb_program.hex", expected_rom);


        $display("Starting Dynamic Instruction Memory tests...");


        //test 1 dynamic auto-verifying loop
        //this loops through every index until it hits an uninitialized 'x' value
        $display("Test 1: Auto-loop Verification");
        
        for (i = 0; expected_rom[i] !== 32'bx; i = i + 1) begin
            
            //calculate the exact RISC-V byte address for this index (multiply by 4)
            address = i * 4;
            #10;

            assert (instruction == expected_rom[i]) begin
                $display("Address %0d (Index %0d) passed: %h", address, i, instruction);
            end 
            else begin
                $fatal(1, "Error: Mismatch at address %0d. Expected %h, got %h", address, expected_rom[i], instruction);
            end

        end


        //test 2 word alignment check [31:2]
        //reading an unaligned address (e.g., 3) should still map to the 0th word
        $display("Test 2: Word Alignment Check (Address 3)");
        address = 32'd3;
        #10;

        assert (instruction == expected_rom[0]) begin
            $display("Test 2 passed");
        end 
        else begin
            $fatal(1, "Error: Word alignment [31:2] failed. Expected %h, got %h", expected_rom[0], instruction);
        end


        $display("All Dynamic Instruction Memory tests successful, use 'gtkwave tb_instruction_mem.vcd tb_instruction_mem.gtkw' to open waveform.");
        
        $finish;

    end

endmodule
