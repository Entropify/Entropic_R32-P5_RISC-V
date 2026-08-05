/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o branch_comp_test ../tb/modules/tb_branch_comp.sv ../rtl/branch_comp.v"
 * Then: "vvp branch_comp_test"
 * Then: "gtkwave tb_branch_comp.vcd tb_branch_comp.gtkw" to view waveform
 */



`default_nettype none
`timescale 1ns/1ps

function automatic bit golden_model (
    logic [31:0] d1,
    logic [31:0] d2,
    logic [2:0] f3 
    );

bit result;

case(f3)

        3'b000: result = (d1 == d2);

        3'b001: result = (d1 != d2);

        3'b100: result = ($signed(d1) < $signed(d2));

        3'b101: result = ($signed(d1) >= $signed(d2));

        3'b110: result = (d1 < d2);

        3'b111: result = (d1 >= d2);

        default: result = 1'b0;
endcase

return result;


endfunction

module tb_branch_comp;

    logic [31:0] data_1;
    logic [31:0] data_2;
    logic [2:0]  func_3;
    
    logic take_branch;

    branch_comp dut (
        .data_1(data_1),
        .data_2(data_2),
        .func_3(func_3),
        .take_branch(take_branch)
    );

    initial begin

        bit expected_out;

        logic [2:0] valid_func3 [0:5];

        valid_func3[0] = 3'b000;
        valid_func3[1] = 3'b001;
        valid_func3[2] = 3'b100;
        valid_func3[3] = 3'b101;
        valid_func3[4] = 3'b110;
        valid_func3[5] = 3'b111;

        

        $dumpfile("tb_branch_comp.vcd");
        $dumpvars(0, tb_branch_comp);

        data_1 = 32'd0;
        data_2 = 32'd0;
        func_3 = 3'd0;
        #20;

        $display("Starting Branch Comparator tests...");

        $display("CRT Tests:");


        //10000 CRT

        for (int i = 0; i < 10000; i++) begin

            data_1 = $urandom();
            data_2 = $urandom();

            func_3 = valid_func3[$urandom_range(0, 5)];

            #10;

            expected_out = golden_model(data_1, data_2, func_3);

            assert (take_branch == expected_out) begin

                if ((i + 1) % 1000 == 0) begin
                    $display("CRT test %0d / 10000 passed", i + 1);
                end

            end

            else begin
                $fatal(1, "CRT test %0d failed. Func3: %0b, D1: %0h, D2: %0h, Expected: %0b, Got %0b", 
                i+1, func_3, data_1, data_2, expected_out, take_branch);
            end



        end

        // beq true
        func_3 = 3'b000; 
        data_1 = 32'd10; 
        data_2 = 32'd10; 
        #100;

        $display("Directed Tests:");

        assert(take_branch == 1'b1) $display("Test 1 passed");
            
        else $fatal(1, "BEQ True failed");
        

        // beq false

        func_3 = 3'b000; 
        data_1 = 32'd10; 
        data_2 = 32'd20; 
        #10;
        assert(take_branch == 1'b0) $display("Test 2 passed");
            
        else $fatal(1, "BEQ False failed");

        // bne
        func_3 = 3'b001; 
        data_1 = 32'd10; 
        data_2 = 32'd20; 
        #10;
        assert(take_branch == 1'b1) $display("Test 3 passed");
            
        else $fatal(1, "BNE True failed");

        // blt (signed -1 < 5)
        func_3 = 3'b100; 
        data_1 = 32'hFFFFFFFF; 
        data_2 = 32'd5; 
        #10;
        assert(take_branch == 1'b1) $display("Test 4 passed");
            
        else $fatal(1, "BLT True failed");

        // bge (signed 5 >= -1)
        func_3 = 3'b101; 
        data_1 = 32'd5; 
        data_2 = 32'hFFFFFFFF; 
        #10;
        assert(take_branch == 1'b1) $display("Test 5 passed");
            
        else $fatal(1, "BGE True failed");

        // bltu (unsigned 0xFFFFFFFF < 5)
        func_3 = 3'b110; 
        data_1 = 32'hFFFFFFFF; 
        data_2 = 32'd5; 
        #10;
        assert(take_branch == 1'b0) $display("Test 6 passed");
            
        else $fatal(1, "BLTU False failed");

        // bgeu (unsigned 0xFFFFFFFF >= 5)
        func_3 = 3'b111; 
        data_1 = 32'hFFFFFFFF;
        data_2 = 32'd5; 
        #10;
        assert(take_branch == 1'b1) $display("Test 7 passed");
            
        else $fatal(1, "BGEU True failed");

        // Default fallback (invalid func3)
        func_3 = 3'b010; 
        data_1 = 32'd0; 
        data_2 = 32'd0; 
        #10;
        assert(take_branch == 1'b0) $display("Test 8 passed");
            
        else $fatal(1, "Default fallback failed");

        $display("All Branch Comparator tests successful, use 'gtkwave tb_branch_comp.vcd tb_branch_comp.gtkw' to open waveform.");
        
        $finish;

    end

endmodule
