/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

  module rv32i_core (
    input wire clk,
    input wire rst_n,

    output wire [31:0] instr_address,    // instruction mem i/o
    input wire [31:0] instruction,

    output wire [31:0] data_address,  // data mem i/o
    output wire [31:0] data_write,
    input wire [31:0] data_read,
    output wire [3:0] write_mask,

    output wire mem_write,       // control signals
    output wire mem_read,

    output wire halt
    
  );

// declaring these here because i need them for module instantiations and i don't want icarus to scream at me :(

  wire [3:0] alu_ctrl_out;
  wire [31:0] imm_gen_out;
  wire [31:0] alu_result;
  wire zero_flag;
  
  wire branch;
  wire [1:0] mem_to_reg;
  wire [1:0] alu_op;
  wire alu_src1;
  wire alu_src2;
  wire reg_write;
  wire [1:0] pc_src;

  wire [31:0] read_data1;
  wire [31:0] read_data2;
  wire [31:0] writeback_data;

  wire take_branch_signal;

  wire [31:0] filtered_data;

//load filter

  load_filter cpu_load_filter(
    .func3(instruction[14:12]),
    .ram_data(data_read),
    .byte_offset(alu_result[1:0]),
    .filtered_data(filtered_data)
  );

//store mask

  store_mask cpu_store_mask(
    .func3(instruction[14:12]),
    .byte_offset(alu_result[1:0]),
    .rs2_data(read_data2),
    .write_mask(write_mask),
    .store_data(data_write)
  );

// branch comp

  branch_comp cpu_branch_comp(
    .data_1(read_data1),
    .data_2(read_data2),
    .func_3(instruction[14:12]),
    .take_branch(take_branch_signal)
  );


// pc

  wire [31:0] pc_out;
  wire [31:0] pc_next;
  wire [31:0] pc_plus_4;
  wire [31:0] pc_branch_target;
  

  assign instr_address = pc_out;

  pc cpu_pc(
    .clk(clk),
    .rst_n(rst_n),
    .pc_in(pc_next),
    .pc_out(pc_out)
  );

  wire take_branch = branch && take_branch_signal;

  assign pc_plus_4 = pc_out + 32'd4;
  assign pc_branch_target = pc_out + imm_gen_out;
  assign pc_next = (take_branch || pc_src == 2'b01) ? pc_branch_target : 
                    (pc_src == 2'b10) ? {alu_result[31:1], 1'b0} : pc_plus_4;


// control unit



  control_unit cpu_control (
    .control_in(instruction[6:0]),
    .branch(branch),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .alu_op(alu_op),
    .mem_write(mem_write),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .reg_write(reg_write),
    .pc_src(pc_src),
    .halt(halt)
  );


// reg file

  

  reg_file cpu_reg_file (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(instruction[19:15]),
    .rs2_address(instruction[24:20]),
    .rd_address(instruction[11:7]),
    .write_data(writeback_data),
    .reg_write(reg_write),
    .rs1_data(read_data1),
    .rs2_data(read_data2)
  );

  assign writeback_data = (mem_to_reg == 2'b01) ? filtered_data : 
                          (mem_to_reg == 2'b10) ? pc_plus_4 : 
                          (mem_to_reg == 2'b11) ? imm_gen_out : alu_result;


// imm gen


  imm_gen cpu_imm_gen (
    .instruction_in(instruction),
    .imm_gen_out(imm_gen_out)
  );


// alu

  
  

  alu cpu_alu (
    .data_1((alu_src1) ?  pc_out : read_data1),
    .data_2((alu_src2) ? imm_gen_out : read_data2),
    .alu_control(alu_ctrl_out),
    .alu_result(alu_result),
    .zero(zero_flag)
  );

  assign data_address = alu_result;


// alu control

  

  alu_control cpu_alu_ctrl (
    .alu_op(alu_op),
    .func7(instruction[30]),
    .func3(instruction[14:12]),
    .alu_control_out(alu_ctrl_out)
  );


  endmodule
  