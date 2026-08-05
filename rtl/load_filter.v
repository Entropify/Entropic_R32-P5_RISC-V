/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


module load_filter (
    input wire [2:0] func3,
    input wire [31:0] ram_data,
    input wire [1:0] byte_offset,
    output reg [31:0] filtered_data
);

reg [31:0] shifted_data;

always @(*) begin

    
    shifted_data = ram_data >> ({byte_offset, 3'b000});

    case(func3)
    
    3'b010: filtered_data = ram_data; //lw

    3'b100: filtered_data = {24'b0, shifted_data[7:0]}; //lbu

    3'b101: filtered_data = {16'b0, shifted_data[15:0]}; //lhu

    3'b000: filtered_data = {{24{shifted_data[7]}}, shifted_data[7:0]}; //lb

    3'b001: filtered_data = {{16{shifted_data[15]}}, shifted_data[15:0]}; //lh





    default: filtered_data = 32'b0;


    endcase
end



endmodule