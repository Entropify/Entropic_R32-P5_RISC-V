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

 reg valid [0:63];
 reg [23:0] tag [0:63]; // 24 bit tag, 32 - 2 (always byte aligned) - 6 (index bit, 2^6 = 64)
 reg [31:0] target [0:63];
 reg [1:0] counter [0:63];


 always @(*) begin
    
    if (valid[fetch_index] == 1 && tag[fetch_index] == fetch_tag) begin
        predict_taken = counter[fetch_index][1];
        predict_target = counter[fetch_index][1] ? target[fetch_index] : 32'b0;
    end

    else begin
        predict_taken = 1'b0;
        predict_target = 32'b0;
    end
    
 end

  reg [1:0] next_counter;

 always @(*) begin

    if (tag[update_index] == update_tag && valid[update_index] == 1'b1) begin

        if (update_taken && counter[update_index] < 2'b11)
            next_counter = counter[update_index] + 1;

        else if (!update_taken && counter[update_index] > 2'b00)
            next_counter = counter[update_index] - 1;

        else
            next_counter = counter[update_index];
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
            tag[i] <= 24'b0;
    end
    else if (update_en) begin
        tag[update_index] <= update_tag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            target[i] <= 32'b0;
    end
    else if (update_en) begin
        target[update_index] <= update_target;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i <= 63; i = i + 1)
            counter[i] <= 2'b00;
    end
    else if (update_en) begin
        counter[update_index] <= next_counter;
    end
end


endmodule
