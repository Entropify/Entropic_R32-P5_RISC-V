/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module branch_comp(
    input wire [31:0] data_1,
    input wire [31:0] data_2,
    input wire [2:0] func_3,
    output reg take_branch
 );

 always @(*) begin
    
    case(func_3)

        3'b000: take_branch = (data_1 == data_2) ? 1'b1 : 1'b0;

        3'b001: take_branch = (data_1 != data_2) ? 1'b1 : 1'b0;

        3'b100: take_branch = ($signed(data_1) < $signed(data_2)) ? 1'b1 : 1'b0;

        3'b101: take_branch = ($signed(data_1) >= $signed(data_2)) ? 1'b1 : 1'b0;

        3'b110: take_branch = (data_1 < data_2) ? 1'b1 : 1'b0;

        3'b111: take_branch = (data_1 >= data_2) ? 1'b1 : 1'b0;

        default: take_branch = 1'b0;

    endcase

 end



 endmodule