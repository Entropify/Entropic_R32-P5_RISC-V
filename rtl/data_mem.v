/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


 module data_mem (
    input wire clk,
    input wire mem_write,
    input wire mem_read,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [3:0] write_mask,
    output wire [31:0] read_data
 );

reg [31:0] mem_array [0:1023];

always @(posedge clk) begin

    if (mem_write) begin

        if (write_mask[0]) mem_array[address[31:2]][7:0] <= write_data[7:0];
    
        if (write_mask[1]) mem_array[address[31:2]][15:8] <= write_data[15:8];
        
        if (write_mask[2]) mem_array[address[31:2]][23:16] <= write_data[23:16];
        
        if (write_mask[3]) mem_array[address[31:2]][31:24] <= write_data[31:24];

    end
end

assign read_data = (mem_read) ? mem_array[address[31:2]] : 32'b0;

 endmodule
 