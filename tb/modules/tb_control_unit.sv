/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o control_unit_test ../tb/modules/tb_control_unit.sv ../rtl/control_unit.v"
 * Then: "vvp control_unit_test"
 * Then: "gtkwave tb_control_unit.vcd tb_control_unit.gtkw" to view waveform
 */

`default_nettype none
`timescale 1ns/1ps

module tb_control_unit;

    logic [6:0] control_in;
    
    logic branch;
    logic mem_read;
    logic [1:0] mem_to_reg;
    logic [1:0] alu_op;
    logic mem_write;
    logic alu_src1;
    logic alu_src2;
    logic reg_write;
    logic [1:0] pc_src;
    logic halt;

    control_unit dut (
        .control_in(control_in),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .reg_write(reg_write),
        .pc_src(pc_src),
        .halt(halt)
    );

    initial begin

        //output files setup
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        //clearing chip signals
        control_in = 7'b0000000;
        #20; 

        $display("All control signals concatenated in the order: branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt");
        $display("Starting Control Unit tests...");

        //test 1 R-type (add, sub, and, or)
        $display("Test 1: R-Type");
        control_in = 7'b0110011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_10_0_0_0_1_00_0) begin
            $display("Test 1 passed");
        end 
        else begin
            $fatal(1, "Error: R-Type failed.");
        end

        //test 2 I-type (lw)
        $display("Test 2: I-Type (Load)");
        control_in = 7'b0000011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_1_01_00_0_0_1_1_00_0) begin
            $display("Test 2 passed");
        end 
        else begin
            $fatal(1, "Error: I-Type Load failed.");
        end

        //test 3 S-type (sw)
        $display("Test 3: S-Type (Store)");
        control_in = 7'b0100011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_00_1_0_1_0_00_0) begin
            $display("Test 3 passed");
        end 
        else begin
            $fatal(1, "Error: S-Type failed.");
        end

        //test 4 B-type (beq)
        $display("Test 4: B-Type (Branch)");
        control_in = 7'b1100011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b1_0_00_01_0_0_0_0_00_0) begin
            $display("Test 4 passed");
        end 
        else begin
            $fatal(1, "Error: B-Type failed.");
        end

        //test 5 I-type (alu math)
        $display("Test 5: I-Type (ALU Math)");
        control_in = 7'b0010011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_11_0_0_1_1_00_0) begin
            $display("Test 5 passed");
        end 
        else begin
            $fatal(1, "Error: I-Type ALU failed.");
        end

        //test 6 jalr I-type jump
        $display("Test 6: JALR");
        control_in = 7'b1100111;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_10_00_0_0_1_1_10_0) begin
            $display("Test 6 passed");
        end 
        else begin
            $fatal(1, "Error: JALR failed.");
        end

        //test 7 auipc U-type
        $display("Test 7: AUIPC");
        control_in = 7'b0010111;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_00_0_1_1_1_00_0) begin
            $display("Test 7 passed");
        end 
        else begin
            $fatal(1, "Error: AUIPC failed.");
        end

        //test 8 lui U-type
        $display("Test 8: LUI");
        control_in = 7'b0110111;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_11_00_0_0_0_1_00_0) begin
            $display("Test 8 passed");
        end 
        else begin
            $fatal(1, "Error: LUI failed.");
        end

        //test 9 jal UJ-type
        $display("Test 9: JAL");
        control_in = 7'b1101111;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_10_00_0_0_0_1_01_0) begin
            $display("Test 9 passed");
        end 
        else begin
            $fatal(1, "Error: JAL failed.");
        end

        //test 10 fence
        $display("Test 10: FENCE");
        control_in = 7'b0001111;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_00_0_0_0_0_00_0) begin
            $display("Test 10 passed");
        end 
        else begin
            $fatal(1, "Error: FENCE failed.");
        end

        //test 11 system (ecall/ebreak)
        $display("Test 11: SYSTEM");
        control_in = 7'b1110011;
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_00_0_0_0_0_00_1) begin
            $display("Test 11 passed");
        end 
        else begin
            $fatal(1, "Error: SYSTEM failed.");
        end

        //test 12 unknown instruction fallback
        $display("Test 12: Unknown Instruction Fallback");
        control_in = 7'b1111111; 
        #10;
        assert ({branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src1, alu_src2, reg_write, pc_src, halt} == 13'b0_0_00_00_0_0_0_0_00_0) begin
            $display("Test 12 passed");
        end 
        else begin
            $fatal(1, "Error: Fallback failed.");
        end

        $display("All control unit tests successful, use 'gtkwave tb_control_unit.vcd tb_control_unit.gtkw' to open waveform.");
        
        $finish;

    end
endmodule
