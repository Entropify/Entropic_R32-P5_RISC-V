/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


module ex_mem_reg(

    input wire clk,
    input wire rst_n,

    input wire [31:0] alu_result_in,    //data mem address or mux candidate
    input wire [31:0] read_data2_in, //im gon forget but this is for storemask
    input wire [4:0] rd_addr_in,
    input wire [2:0] func3_in, //alu_control consumed back in ex, but storemask and loadfilter both need again
    input wire mem_read_in,
    input wire mem_write_in,
    input wire [1:0] mem_to_reg_in,
    input wire reg_write_in,
    input wire halt_in,
    input wire [31:0] pc_plus_four_in,
    input wire [31:0] imm_gen_out_in,   //these 2 are wb mux candidates (pls vote for them)
    input wire [4:0] rs2_addr_in,


    output reg [31:0] alu_result_out,
    output reg [31:0] read_data2_out,
    output reg [4:0] rd_addr_out,
    output reg [2:0] func3_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg reg_write_out,
    output reg halt_out,
    output reg [31:0] pc_plus_four_out,
    output reg [31:0] imm_gen_out_out,
    output reg [4:0] rs2_addr_out

);

 always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        alu_result_out <= 32'h0000_0000;
        read_data2_out <= 32'h0000_0000;
        rd_addr_out <= 5'd0;
        func3_out <= 3'd0;
        mem_read_out <= 1'b0;
        mem_write_out <= 1'b0;
        mem_to_reg_out <= 2'b00;
        reg_write_out <= 1'b0;
        halt_out <= 1'b0;
        pc_plus_four_out <= 32'h0000_0000;
        imm_gen_out_out <= 32'h0000_0000;
        rs2_addr_out <= 5'b0;


    end


    else begin

        alu_result_out <= alu_result_in;
        read_data2_out <= read_data2_in;
        rd_addr_out <= rd_addr_in;
        func3_out <= func3_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        reg_write_out <= reg_write_in;
        halt_out <= halt_in;
        pc_plus_four_out <= pc_plus_four_in;
        imm_gen_out_out <= imm_gen_out_in;
        rs2_addr_out <= rs2_addr_in;


    end


end








endmodule
