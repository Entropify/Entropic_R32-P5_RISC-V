/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

  module if_id_reg(

    input wire clk,
    input wire rst_n,

    input wire [31:0] instruction_in,
    input wire [31:0] pc_in,
    input wire [31:0] pc_plus_four_in,

    output reg [31:0] instruction_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_four_out
 );


 always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        instruction_out <= 32'h0000_0000;
        pc_out <= 32'h0000_0000;
        pc_plus_four_out <= 32'h0000_0000;

    end

    else begin

        pc_out <= pc_in;
        instruction_out <= instruction_in;
        pc_plus_four_out <= pc_plus_four_in;

    end
    
 end



 endmodule
 