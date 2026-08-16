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
        
        if (counter[fetch_index] == 2'b00 || counter[fetch_index] == 2'b01) begin
            predict_taken = 1'b0;
            predict_target = 32'b0;
        end

        else if (counter[fetch_index] == 2'b10 || counter[fetch_index] == 2'b11) begin
            predict_taken = 1'b1;
            predict_target = target[fetch_index];
        end
    end

    else begin
        predict_taken = 1'b0;
        predict_target = 32'b0;
    end
    
 end

 integer i;

 always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
       
        for (i = 0; i <= 63; i = i + 1) begin
            valid[i] <= 1'b0;
            tag[i] <= 24'b0;
            target[i] <= 32'b0;
            counter [i] <= 2'b0;
        end

    end

    else if (update_en) begin
        
        valid[update_index] <= 1'b1;
        tag[update_index] <= update_tag;
        target[update_index] <= update_target;

        if (tag[update_index] == update_tag && valid[update_index] == 1'b1) begin

            if (update_taken && counter[update_index] < 2'b11) begin  //update the 2 bit very tuff fsm
                counter[update_index] <= counter[update_index] + 1;
            end

            else if (!update_taken && counter[update_index] > 2'b00) begin
                counter[update_index] <= counter[update_index] - 1;
            end
        end

        else begin //(tag[update_index] != update_tag || valid[update_index] == 1'b0)
            if (update_taken) begin
                counter[update_index] <= 2'b10;
            end
            else begin
                counter[update_index] <= 2'b01;
            end
        end


    end




 end


endmodule
