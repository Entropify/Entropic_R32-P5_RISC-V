/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module reg_file (
    input wire clk,
    input wire rst_n,
    input wire [4:0] rs1_address,
    input wire [4:0] rs2_address,
    input wire [4:0] rd_address,
    input wire [31:0] write_data,
    input wire reg_write,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
 );

 reg [31:0] internal_reg [0:31];

 assign rs1_data = (rs1_address == 0) ? 32'h0000_0000 : internal_reg[rs1_address];
 assign rs2_data = (rs2_address == 0) ? 32'h0000_0000 : internal_reg[rs2_address];

 integer i;

 always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        for (i = 0; i < 32; i = i + 1) begin
            internal_reg[i] <= 32'h0000_0000;
        end

    end

    else begin

        if (reg_write && rd_address != 5'b00000) begin
            internal_reg[rd_address] <= write_data;
        end
        
    end

 end


 endmodule
 