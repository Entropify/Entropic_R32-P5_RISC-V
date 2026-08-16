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


  wire stall;

// IF stage


  wire [31:0] pc_out;
  wire [31:0] pc_next;
  wire [31:0] pc_plus_4;

  assign instr_address = pc_out;
  assign pc_plus_4 = pc_out + 32'd4;

  pc cpu_pc(
    .clk(clk),
    .rst_n(rst_n),
    .pc_in(pc_next),
    .pc_out(pc_out),
    .freeze(stall)
  );

wire predict_taken;
wire [31:0] predict_target;


  branch_predictor cpu_branch_predictor(
    .clk(clk),
    .rst_n(rst_n),

    .fetch_pc(pc_out),
    .predict_taken(predict_taken),
    .predict_target(predict_target),

    .update_en((branch_d || pc_src_d == 2'b01 || pc_src_d == 2'b10)),
    .update_pc(if_id_pc),
    .update_taken(real_taken),
    .update_target(real_target)
  );


// IF/ID


  wire [31:0] if_id_instruction;
  wire [31:0] if_id_pc;
  wire [31:0] if_id_pc_plus_4;

  wire if_id_predicted_taken;
  wire [31:0] if_id_predicted_target;

  if_id_reg cpu_if_id (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .instruction_in(instruction),
    .pc_in(pc_out),
    .pc_plus_four_in(pc_plus_4),
    .predicted_taken_in(predict_taken),
    .predicted_target_in(predict_target),

    .instruction_out(if_id_instruction),
    .pc_out(if_id_pc),
    .pc_plus_four_out(if_id_pc_plus_4),
    .predicted_taken_out(if_id_predicted_taken),
    .predicted_target_out(if_id_predicted_target),

    .freeze(stall)
  );


// ID stage




  wire branch_d, mem_read_d, mem_write_d, alu_src1_d, alu_src2_d, reg_write_d, halt_d;
  wire [1:0] mem_to_reg_d, alu_op_d, pc_src_d;

  control_unit cpu_control (
    .control_in(if_id_instruction[6:0]),
    .branch(branch_d),
    .mem_read(mem_read_d),
    .mem_to_reg(mem_to_reg_d),
    .alu_op(alu_op_d),
    .mem_write(mem_write_d),
    .alu_src1(alu_src1_d),
    .alu_src2(alu_src2_d),
    .reg_write(reg_write_d),
    .pc_src(pc_src_d),
    .halt(halt_d)
  );

  wire [31:0] imm_gen_out_d;

  imm_gen cpu_imm_gen (
    .instruction_in(if_id_instruction),
    .imm_gen_out(imm_gen_out_d)
  );

  wire [4:0] rs1_addr_d = if_id_instruction[19:15];
  wire [4:0] rs2_addr_d = if_id_instruction[24:20];
  wire [4:0] rd_addr_d = if_id_instruction[11:7];
  wire [2:0] func3_d = if_id_instruction[14:12];
  wire func7_d = if_id_instruction[30];

  wire [31:0] read_data1_d, read_data2_d;


  // reg file address / write / enable signals, these come from WB but ima declare here cus lowk I might forgor


  wire [31:0] writeback_data;
  wire [4:0] mem_wb_rd_addr;
  wire mem_wb_reg_write;

  reg_file cpu_reg_file (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(rs1_addr_d),
    .rs2_address(rs2_addr_d),
    .rd_address(mem_wb_rd_addr),
    .write_data(writeback_data),
    .reg_write(mem_wb_reg_write),
    .rs1_data(read_data1_d),
    .rs2_data(read_data2_d)
  );

  wire [1:0] id_src1, id_src2;

  id_forwarding_unit cpu_id_forwarding_unit(
    .rs1_addr_d(rs1_addr_d),
    .rs2_addr_d(rs2_addr_d),

    .id_ex_rd_addr(id_ex_rd_addr),
    .id_ex_reg_write(id_ex_reg_write),

    .ex_mem_rd_addr(ex_mem_rd_addr),
    .ex_mem_reg_write(ex_mem_reg_write),

    .forward_src1(id_src1),
    .forward_src2(id_src2)
 );





  wire take_branch_signal;

  reg [31:0] branch_comp_1, branch_comp_2;

  

  always @(*) begin


      case(id_src1)

      2'd2: branch_comp_1 = alu_result;
      2'd1: branch_comp_1 = ex_mem_alu_result;
      2'd0: branch_comp_1 = read_data1_d;
      default: branch_comp_1 = read_data1_d;

      endcase

  end

  always @(*) begin


      case(id_src2)

      2'd2: branch_comp_2 = alu_result;
      2'd1: branch_comp_2 = ex_mem_alu_result;
      2'd0: branch_comp_2 = read_data2_d;
      default: branch_comp_2 = read_data2_d;

      endcase

  end

  branch_comp cpu_branch_comp (
    .data_1(branch_comp_1),
    .data_2(branch_comp_2),
    .func_3(func3_d),
    .take_branch(take_branch_signal)
  );

 wire [31:0] real_target = (pc_src_d == 2'b10) ? {jalr_target_full[31:1], 1'b0} : pc_branch_target;
 wire real_taken = take_branch || (pc_src_d == 2'b10) || (pc_src_d == 2'b01);
 
  wire mispredicted = (if_id_predicted_taken != real_taken) ||
                     (if_id_predicted_taken && real_taken && (if_id_predicted_target != real_target));

  wire take_branch = branch_d && take_branch_signal;
  wire [31:0] pc_branch_target = if_id_pc + imm_gen_out_d;

  wire [31:0] jalr_target_full = branch_comp_1 + imm_gen_out_d; //uses same forwarding branch comp uses

  // resolved in id now so penalty cycle is only 1, this feeds all the way back to the pc mux in if
 /* assign pc_next = (take_branch || pc_src_d == 2'b01) ? pc_branch_target :
  (pc_src_d == 2'b10) ? {jalr_target_full[31:1], 1'b0} : 
  (predict_taken) ? predict_target : pc_plus_4;
  */

  assign pc_next = mispredicted
    ? (real_taken ? real_target : if_id_pc_plus_4)
    : (predict_taken ? predict_target : pc_plus_4);


//wire flush = !stall && (take_branch || pc_src_d == 2'b01 || pc_src_d == 2'b10 || pc_next != pc_plus_4);
 
    wire flush = !stall && mispredicted;

// ID/EX


  wire [31:0] id_ex_read_data1, id_ex_read_data2, id_ex_imm_gen_out;
  wire [31:0] id_ex_pc, id_ex_pc_plus_4;
  wire [4:0] id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rd_addr;
  wire id_ex_branch, id_ex_mem_read, id_ex_mem_write;
  wire id_ex_alu_src1, id_ex_alu_src2, id_ex_reg_write, id_ex_halt;
  wire [1:0] id_ex_mem_to_reg, id_ex_alu_op, id_ex_pc_src;
  wire [2:0] id_ex_func3;
  wire id_ex_func7;

  id_ex_reg cpu_id_ex (
    .clk(clk),
    .rst_n(rst_n),

    .read_data1_in(read_data1_d),
    .read_data2_in(read_data2_d),
    .imm_gen_out_in(imm_gen_out_d),
    .read_data1_out(id_ex_read_data1),
    .read_data2_out(id_ex_read_data2),
    .imm_gen_out_out(id_ex_imm_gen_out),

    .pc_out_in(if_id_pc),
    .pc_plus_four_in(if_id_pc_plus_4),
    .pc_out_out(id_ex_pc),
    .pc_plus_four_out(id_ex_pc_plus_4),

    .rs1_addr_in(rs1_addr_d),
    .rs2_addr_in(rs2_addr_d),
    .rd_addr_in(rd_addr_d),
    .rs1_addr_out(id_ex_rs1_addr),
    .rs2_addr_out(id_ex_rs2_addr),
    .rd_addr_out(id_ex_rd_addr),

    .branch_in(branch_d),
    .mem_read_in(mem_read_d),
    .mem_to_reg_in(mem_to_reg_d),
    .alu_op_in(alu_op_d),
    .mem_write_in(mem_write_d),
    .alu_src1_in(alu_src1_d),
    .alu_src2_in(alu_src2_d),
    .reg_write_in(reg_write_d),
    .pc_src_in(pc_src_d),
    .halt_in(halt_d),
    .branch_out(id_ex_branch),
    .mem_read_out(id_ex_mem_read),
    .mem_to_reg_out(id_ex_mem_to_reg),
    .alu_op_out(id_ex_alu_op),
    .mem_write_out(id_ex_mem_write),
    .alu_src1_out(id_ex_alu_src1),
    .alu_src2_out(id_ex_alu_src2),
    .reg_write_out(id_ex_reg_write),
    .pc_src_out(id_ex_pc_src),
    .halt_out(id_ex_halt),

    .func3_in(func3_d),
    .func7_in(func7_d),
    .func3_out(id_ex_func3),
    .func7_out(id_ex_func7),

    .bubble(stall)
  );


// EX stage


  wire [3:0] alu_ctrl_out;
  wire [31:0] alu_result;
  wire zero_flag;

  wire [1:0] forward_src1, forward_src2;

  reg [31:0] alu_actual_in1, alu_actual_in2;

  reg [31:0] forwarded_read_data1_no_alu;
  reg [31:0] forwarded_read_data2_no_alu; //for write mask AND BRANCH COMP AHHHH

  hazard_unit cpu_hazard_unit(
    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_rd_addr(id_ex_rd_addr),
    .rs1_addr_d(rs1_addr_d),
    .rs2_addr_d(rs2_addr_d),
    .ex_mem_mem_read(ex_mem_mem_read),
    .ex_mem_rd_addr(ex_mem_rd_addr),
    .branch_d(branch_d),
    .stall(stall)
  );



  forwarding_unit cpu_forwarding_unit(
    .id_ex_rs1_addr(id_ex_rs1_addr),
    .id_ex_rs2_addr(id_ex_rs2_addr),

    .ex_mem_rd_addr(ex_mem_rd_addr),
    .ex_mem_reg_write(ex_mem_reg_write),

    .mem_wb_rd_addr(mem_wb_rd_addr),
    .mem_wb_reg_write(mem_wb_reg_write),

    .forward_src1(forward_src1),
    .forward_src2(forward_src2)
  );

  always @(*) begin


      case(forward_src1)

      2'd2: forwarded_read_data1_no_alu = ex_mem_alu_result;
      2'd1: forwarded_read_data1_no_alu = writeback_data;
      2'd0: forwarded_read_data1_no_alu = id_ex_read_data1;
      default: forwarded_read_data1_no_alu = id_ex_read_data1;

      endcase

    end

  always @(*) begin

      if (id_ex_alu_src1 == 1'b1) alu_actual_in1 = id_ex_pc;

      else alu_actual_in1 = forwarded_read_data1_no_alu;

    end

  always @(*) begin


      case(forward_src2)

      2'd2: forwarded_read_data2_no_alu = ex_mem_alu_result;
      2'd1: forwarded_read_data2_no_alu = writeback_data;
      2'd0: forwarded_read_data2_no_alu = id_ex_read_data2;
      default: forwarded_read_data2_no_alu = id_ex_read_data2;

      endcase

    end

  always @(*) begin

      if (id_ex_alu_src2 == 1'b1) alu_actual_in2 = id_ex_imm_gen_out;

      else alu_actual_in2 = forwarded_read_data2_no_alu;

    end

    


  alu_control cpu_alu_ctrl (
    .alu_op(id_ex_alu_op),
    .func7(id_ex_func7),
    .func3(id_ex_func3),
    .alu_control_out(alu_ctrl_out)
  );

  alu cpu_alu (
    .data_1(alu_actual_in1),
    .data_2(alu_actual_in2),
    .alu_control(alu_ctrl_out),
    .alu_result(alu_result),
    .zero(zero_flag)
  );




// EX/MEM

  

  wire [31:0] ex_mem_alu_result, ex_mem_read_data2;
  wire [31:0] ex_mem_pc_plus_4, ex_mem_imm_gen_out;
  wire [4:0] ex_mem_rd_addr;
  wire [2:0] ex_mem_func3;
  wire ex_mem_mem_read, ex_mem_mem_write, ex_mem_reg_write, ex_mem_halt;
  wire [1:0] ex_mem_mem_to_reg;
  wire [4:0] ex_mem_rs2_addr;

  ex_mem_reg cpu_ex_mem (
    .clk(clk),
    .rst_n(rst_n),

    .alu_result_in(alu_result),
    .read_data2_in(forwarded_read_data2_no_alu),
    .rd_addr_in(id_ex_rd_addr),
    .func3_in(id_ex_func3),
    .mem_read_in(id_ex_mem_read),
    .mem_write_in(id_ex_mem_write),
    .mem_to_reg_in(id_ex_mem_to_reg),
    .reg_write_in(id_ex_reg_write),
    .halt_in(id_ex_halt),
    .pc_plus_four_in(id_ex_pc_plus_4),
    .imm_gen_out_in(id_ex_imm_gen_out),
    .rs2_addr_in(id_ex_rs2_addr),

    .alu_result_out(ex_mem_alu_result),
    .read_data2_out(ex_mem_read_data2),
    .rd_addr_out(ex_mem_rd_addr),
    .func3_out(ex_mem_func3),
    .mem_read_out(ex_mem_mem_read),
    .mem_write_out(ex_mem_mem_write),
    .mem_to_reg_out(ex_mem_mem_to_reg),
    .reg_write_out(ex_mem_reg_write),
    .halt_out(ex_mem_halt),
    .pc_plus_four_out(ex_mem_pc_plus_4),
    .imm_gen_out_out(ex_mem_imm_gen_out),
    .rs2_addr_out(ex_mem_rs2_addr)
  );


// MEM stage


  wire [31:0] filtered_data;

  wire mem_forward_sel;

  assign data_address = ex_mem_alu_result;
  assign mem_read = ex_mem_mem_read;
  assign mem_write = ex_mem_mem_write;

  mem_forwarding_unit cpu_mem_forwarding_unit(
    .ex_mem_rs2_addr(ex_mem_rs2_addr),
    .mem_wb_rd_addr(mem_wb_rd_addr),
    .mem_wb_reg_write(mem_wb_reg_write),
    .sel(mem_forward_sel)
  );

  load_filter cpu_load_filter(
    .func3(ex_mem_func3),
    .ram_data(data_read),
    .byte_offset(ex_mem_alu_result[1:0]),
    .filtered_data(filtered_data)
  );

  store_mask cpu_store_mask(
    .func3(ex_mem_func3),
    .byte_offset(ex_mem_alu_result[1:0]),
    .rs2_data(mem_forward_sel ? writeback_data : ex_mem_read_data2),
    .write_mask(write_mask),
    .store_data(data_write)
  );


// MEM/WB


  wire [31:0] mem_wb_filtered_data, mem_wb_alu_result;
  wire [31:0] mem_wb_pc_plus_4, mem_wb_imm_gen_out;
  wire [1:0] mem_wb_mem_to_reg;
  wire mem_wb_halt;

  mem_wb_reg cpu_mem_wb (
    .clk(clk),
    .rst_n(rst_n),

    .filtered_data_in(filtered_data),
    .alu_result_in(ex_mem_alu_result),
    .pc_plus_four_in(ex_mem_pc_plus_4),
    .imm_gen_out_in(ex_mem_imm_gen_out),
    .mem_to_reg_in(ex_mem_mem_to_reg),
    .rd_addr_in(ex_mem_rd_addr),
    .reg_write_in(ex_mem_reg_write),
    .halt_in(ex_mem_halt),

    .filtered_data_out(mem_wb_filtered_data),
    .alu_result_out(mem_wb_alu_result),
    .pc_plus_four_out(mem_wb_pc_plus_4),
    .imm_gen_out_out(mem_wb_imm_gen_out),
    .mem_to_reg_out(mem_wb_mem_to_reg),
    .rd_addr_out(mem_wb_rd_addr),
    .reg_write_out(mem_wb_reg_write),
    .halt_out(mem_wb_halt)
  );


// WB stage


  assign writeback_data = (mem_wb_mem_to_reg == 2'b01) ? mem_wb_filtered_data :
                          (mem_wb_mem_to_reg == 2'b10) ? mem_wb_pc_plus_4 :
                          (mem_wb_mem_to_reg == 2'b11) ? mem_wb_imm_gen_out : mem_wb_alu_result;

  assign halt = mem_wb_halt;

  endmodule
