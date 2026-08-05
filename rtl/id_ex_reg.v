/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module id_ex_reg(
    
    input wire clk,
    input wire rst_n,

    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] imm_gen_out_in,               //data and imm
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_gen_out_out,

    input wire [31:0] pc_out_in,
    input wire [31:0] pc_plus_four_in,          //pc stuff
    output reg [31:0] pc_out_out,
    output reg [31:0] pc_plus_four_out,

    input wire [4:0] rs1_addr_in,
    input wire [4:0] rs2_addr_in,
    input wire [4:0] rd_addr_in,                //regfile addresses
    output reg [4:0] rs1_addr_out,
    output reg [4:0] rs2_addr_out,
    output reg [4:0] rd_addr_out,

    input wire branch_in,
    input wire mem_read_in,
    input wire [1:0] mem_to_reg_in,
    input wire [1:0] alu_op_in,
    input wire mem_write_in,
    input wire alu_src1_in,
    input wire alu_src2_in,
    input wire reg_write_in,
    input wire [1:0] pc_src_in,
    input wire halt_in,                                 //control shinanigans
    output reg branch_out,
    output reg mem_read_out,
    output reg [1:0] mem_to_reg_out,
    output reg [1:0] alu_op_out,
    output reg mem_write_out,
    output reg alu_src1_out,
    output reg alu_src2_out,
    output reg reg_write_out,
    output reg [1:0] pc_src_out,
    output reg halt_out,

    input wire [2:0] func3_in,
    input wire func7_in,

    output reg [2:0] func3_out,
    output reg func7_out
 );


 always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        read_data1_out <= 32'h0000_0000;
        read_data2_out <= 32'h0000_0000;
        imm_gen_out_out <= 32'h0000_0000;

        pc_out_out <= 32'h0000_0000;
        pc_plus_four_out <= 32'h0000_0000;

        rs1_addr_out <= 5'd0;
        rs2_addr_out <= 5'd0;
        rd_addr_out <= 5'd0;

        branch_out <= 1'b0;
        mem_read_out <= 1'b0;
        mem_to_reg_out <= 2'b00;
        alu_op_out <= 2'b00;
        mem_write_out <= 1'b0;
        alu_src1_out <= 1'b0;
        alu_src2_out <= 1'b0;
        reg_write_out <= 1'b0;
        pc_src_out <= 2'b00;
        halt_out <= 1'b0;

        func3_out <= 3'd0;
        func7_out <= 1'b0;

    end

    else begin

        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        imm_gen_out_out <= imm_gen_out_in;

        pc_out_out <= pc_out_in;
        pc_plus_four_out <= pc_plus_four_in;

        rs1_addr_out <= rs1_addr_in;
        rs2_addr_out <= rs2_addr_in;
        rd_addr_out <= rd_addr_in;

        branch_out <= branch_in;
        mem_read_out <= mem_read_in;
        mem_to_reg_out <= mem_to_reg_in;
        alu_op_out <= alu_op_in;
        mem_write_out <= mem_write_in;
        alu_src1_out <= alu_src1_in;
        alu_src2_out <= alu_src2_in;
        reg_write_out <= reg_write_in;
        pc_src_out <= pc_src_in;
        halt_out <= halt_in;

        func3_out <= func3_in;
        func7_out <= func7_in;

    end
    
 end



 endmodule
 