/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */


 // resolves lw followed by sw immediately

`default_nettype none

 module mem_forwarding_unit(
    input wire [4:0] ex_mem_rs2_addr,
    input wire [4:0] mem_wb_rd_addr,
    input wire mem_wb_reg_write,

    output reg sel //1 means forward in mem stage, 0 means nah uh
 );


 always @(*) begin
    
    if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) 
    && (mem_wb_rd_addr == ex_mem_rs2_addr)) sel = 1'b1;

    else sel = 1'b0;

 end


 endmodule
