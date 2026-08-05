/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


 module mem_wb_reg(

    input wire clk,
    input wire rst_n,

    input wire [31:0] filtered_data_in,

    input wire [31:0] alu_result_in,

    input wire [31:0] pc_plus_four_in,
    input wire [31:0] imm_gen_out_in,
    input wire [1:0] mem_to_reg_in,

    input wire [4:0] rd_addr_in,
    input wire reg_write_in,

    input wire halt_in,

    output reg [31:0] filtered_data_out,

    output reg [31:0] alu_result_out,

    output reg [31:0] pc_plus_four_out,
    output reg [31:0] imm_gen_out_out,
    output reg [1:0] mem_to_reg_out,

    output reg [4:0] rd_addr_out,
    output reg reg_write_out,

    output reg halt_out


 );


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        filtered_data_out <= 32'h0000_0000;
        alu_result_out <= 32'h0000_0000;
        pc_plus_four_out <= 32'h0000_0000;
        imm_gen_out_out <= 32'h0000_0000;

        mem_to_reg_out <= 2'b00;

        reg_write_out <= 1'b0;
        rd_addr_out <= 5'd0;

        halt_out <= 1'b0;


        

    end

    else begin

        filtered_data_out <= filtered_data_in;
        alu_result_out <= alu_result_in;
        pc_plus_four_out <= pc_plus_four_in;
        imm_gen_out_out <= imm_gen_out_in;

        mem_to_reg_out <= mem_to_reg_in;

        reg_write_out <= reg_write_in;
        rd_addr_out <= rd_addr_in;

        halt_out <= halt_in;
    end

end




 endmodule
