/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */


 // for branch comparator in id

`default_nettype none

 module id_forwarding_unit(
    input wire [4:0] rs1_addr_d,
    input wire [4:0] rs2_addr_d,

    input wire [4:0] id_ex_rd_addr,
    input wire id_ex_reg_write,

    input wire [4:0] ex_mem_rd_addr,
    input wire ex_mem_reg_write,

    output reg [1:0] forward_src1, // 0 is no forward, 2 is forward from id/ex (priority since ts is newer data), 1 is forward from ex/mem
    output reg [1:0] forward_src2
 );

 
 always @(*) begin

    if (id_ex_reg_write && (id_ex_rd_addr != 5'b0) && (id_ex_rd_addr == rs1_addr_d)) forward_src1 = 2;    
    
    else if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == rs1_addr_d)) forward_src1 = 1;

    else forward_src1 = 0;

    end


 always @(*) begin

    if (id_ex_reg_write && (id_ex_rd_addr != 5'b0) && (id_ex_rd_addr == rs2_addr_d)) forward_src2 = 2;    
    
    else if (ex_mem_reg_write && (ex_mem_rd_addr != 5'b0) && (ex_mem_rd_addr == rs2_addr_d)) forward_src2 = 1;

    else forward_src2 = 0;

    end




 endmodule
