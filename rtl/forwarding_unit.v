/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module forwarding_unit(
    input wire [4:0] id_ex_rs1_addr,
    input wire [4:0] id_ex_rs2_addr,

    input wire [4:0] ex_mem_rd_addr,
    input wire ex_mem_reg_write,

    input wire [4:0] mem_wb_rd_addr,
    input wire mem_wb_reg_write,

    output reg [1:0] forward_src1, // 0 is no forward, 2 is forward from ex/mem (priority since ts is newer data), 1 is forward from mem/wb
    output reg [1:0] forward_src2 // same as src1

 );


 always @(*) begin

    if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs1_addr)) forward_src1 = 2;    
    
    else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs1_addr)) forward_src1 = 1;

    else forward_src1 = 0;

    end


 always @(*) begin

    if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == id_ex_rs2_addr)) forward_src2 = 2;    
    
    else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'b0) && (mem_wb_rd_addr == id_ex_rs2_addr)) forward_src2 = 1;

    else forward_src2 = 0;

    end








 endmodule
