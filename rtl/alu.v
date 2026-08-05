/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module alu (
    input wire [31:0] data_1,
    input wire [31:0] data_2,
    input wire [3:0] alu_control,
    output reg [31:0] alu_result,
    output wire zero
 );

 always @(*) begin

   case (alu_control)

      4'b0000: alu_result = data_1 & data_2;
      4'b0001: alu_result = data_1 | data_2;
      4'b0010: alu_result = data_1 + data_2;
      4'b0110: alu_result = data_1 - data_2;

      4'b1001: alu_result = data_1 ^ data_2;

      4'b0100: alu_result = data_1 << data_2[4:0]; // sll & slli
      4'b0011: alu_result = data_1 >> data_2[4:0]; // srl & srli

      4'b0101: alu_result = $signed(data_1) >>> data_2[4:0]; // sra & srai

      4'b0111: alu_result = ($signed(data_1) < $signed(data_2)) ? 32'd1 : 32'd0; // slt & slti

      4'b1000: alu_result = (data_1 < data_2) ? 32'd1 : 32'd0; // sltu & sltiu


    default: alu_result = 32'h0000_0000;

    endcase


 end

 assign zero = (alu_result == 32'h0000_0000);


 endmodule
 