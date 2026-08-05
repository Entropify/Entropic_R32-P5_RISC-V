/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

 module alu_control (
    input wire [1:0] alu_op,
    input wire func7,
    input wire [2:0] func3,
    output reg [3:0] alu_control_out
 );

 always @(*) begin

    if (alu_op == 2'b00) begin  // I/S-type (and jalr, jal too)
        alu_control_out = 4'b0010;
    end

    else if (alu_op == 2'b01) begin// B-type
        alu_control_out = 4'b0110;
    end

    else if (alu_op == 2'b10 || alu_op == 2'b11) begin // R-type and I-type math

        if (func3 == 3'b000) begin 

            if (alu_op == 2'b10 && func7 == 1'b1) begin 
                alu_control_out = 4'b0110; // sub
            end 
            else begin
                alu_control_out = 4'b0010; // add & addi
            end
        end

        else if (func3 == 3'b111) begin // and & andi
            alu_control_out = 4'b0000;
        end

        else if (func3 == 3'b110) begin // or & ori
            alu_control_out = 4'b0001;
        end

        else if (func3 == 3'b001) begin // sll & slli
            alu_control_out = 4'b0100;
        end

        else if (func3 == 3'b010) begin // slt & slti
            alu_control_out = 4'b0111;
        end

        else if (func3 == 3'b011) begin // sltu & sltiu
            alu_control_out = 4'b1000;
        end

        else if (func3 == 3'b101) begin 

            if (func7 == 1'b1) begin
                alu_control_out = 4'b0101; // sra & srai
            end 
            else begin
                alu_control_out = 4'b0011; // srl & srli
            end
        end

        else if (func3 == 3'b100) begin // xor & xori
            alu_control_out = 4'b1001;
        end

        else begin // safety for unknown R or I type signal
            alu_control_out = 4'b0000;
        end

    end

    else begin // safety for unknown alu_op signal
            alu_control_out = 4'b0000;
        end
        
    end


 endmodule
 