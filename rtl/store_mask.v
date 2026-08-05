/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


 module store_mask (
    input wire [2:0] func3,
    input wire [1:0] byte_offset,
    input wire [31:0] rs2_data,
    output reg [3:0] write_mask,
    output reg [31:0] store_data
 );

 reg [31:0] shifted_data;

 always @(*) begin

    
    shifted_data = rs2_data << ({byte_offset, 3'b000});
    
    case(func3)

    3'b010: begin //sw
        write_mask = 4'b1111;
        store_data = rs2_data;
    end

    3'b000: begin //sb
        write_mask = 4'b0001 << byte_offset;
        store_data = shifted_data;
    end

    3'b001: begin //sh

        if (byte_offset == 2'd2 || byte_offset == 2'd0) begin // making sure no misaligned half words >:)
            write_mask = 4'b0011 << byte_offset;
            store_data = shifted_data;
        end

        else begin
            write_mask = 4'b0000;
            store_data = 32'b0;
        end
    end

    default: begin
        write_mask = 4'b0000;
        store_data = 32'b0;
    end

    endcase

 end



 endmodule