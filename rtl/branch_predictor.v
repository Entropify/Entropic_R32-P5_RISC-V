/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


 module branch_predictor(
    input wire clk,
    input wire rst_n,

    input wire [31:0] fetch_pc,
    output reg predict_taken,
    output reg [31:0] predict_target,

    input wire update_en, //if instruction is act branch or jal or jalr
    input wire [31:0] update_pc, // instr's own address
    input wire update_taken, // actual outcome
    input wire [31:0] update_target // real target
 );

 wire [5:0] fetch_index = fetch_pc[7:2];
 wire [23:0] fetch_tag = fetch_pc[31:8];

 wire [5:0] update_index = update_pc[7:2];
 wire [23:0] update_tag = update_pc[31:8];

 reg [63:0] valid;        // 1 bit x 64 entries
 reg [24*64-1:0] tag_flat;    // 24 bits x 64 entries (24 bit tag, 32 - 2 (always byte aligned) - 6 (index bit, 2^6 = 64))
 reg [32*64-1:0] target_flat;     // 32 bits x 64 entries
 reg [2*64-1:0] counter_flat;   // 2 bits x 64 entries


 always @(*) begin

    if (valid[fetch_index] == 1 && tag_flat[fetch_index*24 +: 24] == fetch_tag) begin
        predict_taken = counter_flat[fetch_index*2 +: 2][1];
        predict_target = counter_flat[fetch_index*2 +: 2][1] ? target_flat[fetch_index*32 +: 32] : 32'b0;
    end

    else begin
        predict_taken = 1'b0;
        predict_target = 32'b0;
    end

 end

 reg [1:0] next_counter;

 always @(*) begin

    if (tag_flat[update_index*24 +: 24] == update_tag && valid[update_index] == 1'b1) begin

        if (update_taken && counter_flat[update_index*2 +: 2] < 2'b11)
            next_counter = counter_flat[update_index*2 +: 2] + 1;

        else if (!update_taken && counter_flat[update_index*2 +: 2] > 2'b00)
            next_counter = counter_flat[update_index*2 +: 2] - 1;

        else
            next_counter = counter_flat[update_index*2 +: 2];
    end

    else begin
        next_counter = update_taken ? 2'b10 : 2'b01;
    end

 end

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            valid[i] <= 1'b0;
    end
    else if (update_en) begin
        valid[update_index] <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            tag_flat[i*24 +: 24] <= 24'b0;
    end
    else if (update_en) begin
        tag_flat[update_index*24 +: 24] <= update_tag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            target_flat[i*32 +: 32] <= 32'b0;
    end
    else if (update_en) begin
        target_flat[update_index*32 +: 32] <= update_target;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            counter_flat[i*2 +: 2] <= 2'b00;
    end
    else if (update_en) begin
        counter_flat[update_index*2 +: 2] <= next_counter;
    end
end


endmodule
