/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


 module hazard_unit(
    input wire id_ex_mem_read,
    input wire [4:0] id_ex_rd_addr,
    input wire [4:0] rs1_addr_d,
    input wire [4:0] rs2_addr_d,
    input wire ex_mem_mem_read,
    input wire [4:0] ex_mem_rd_addr,
    input wire branch_d,
    output reg stall
 );

 always @(*) begin
    
    if ((id_ex_mem_read) && ((id_ex_rd_addr == rs1_addr_d) || 
    (id_ex_rd_addr == rs2_addr_d)) && (id_ex_rd_addr != 5'd0)) begin
        stall = 1'b1;
    end

    else if ((ex_mem_mem_read) && (branch_d) && (ex_mem_rd_addr != 5'b0) && 
    ((ex_mem_rd_addr == rs1_addr_d) || (ex_mem_rd_addr == rs2_addr_d))) begin
        stall = 1'b1;
    end

    else begin
        stall = 1'b0;
    end

 end



 endmodule
