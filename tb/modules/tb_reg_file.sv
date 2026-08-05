/*
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 *
 * cd into sim first, then run wsl, then run the following:
 * "iverilog -g2012 -o reg_file_test ../tb/modules/tb_reg_file.sv ../rtl/reg_file.v"
 * Then: "vvp reg_file_test"
 * Then: "gtkwave tb_reg_file.vcd tb_reg_file.gtkw" to view waveform
 */


`default_nettype none
`timescale 1ns/1ps




module tb_reg_file;

    logic clk;
    logic rst_n;
    logic [4:0] rs1_address;
    logic [4:0] rs2_address;
    logic [4:0] rd_address;
    logic [31:0] write_data;
    logic reg_write;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;



    reg_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_address(rs1_address),
        .rs2_address(rs2_address),
        .rd_address(rd_address),
        .write_data(write_data),
        .reg_write(reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );


    //clk

    initial clk = 0;
    always #5 clk = ~clk; 


    initial begin

        //shadow mem reset

        logic [31:0] shadow_mem [0:31];
        logic [31:0] expected_val;
        logic [31:0] exp_rd;

        logic [4:0] rd_rn;

        logic [31:0] write_rn;

        //for readback over random amount of cycles because this tb not random enough >:)

        logic [6:0] cycle_count;

        for (int i = 0; i < 32; i++) begin
            shadow_mem[i] = 32'd0;
        end

        


        //output files setup

        $dumpfile("tb_reg_file.vcd");
        $dumpvars(0, tb_reg_file);


        //clearing chip signals

        rst_n = 1'b0;
        reg_write = 1'b0;
        rs1_address = 5'd0;
        rs2_address = 5'd0;
        rd_address = 5'd0;
        write_data = 32'd0;


        #20; 


        //rst off

        rst_n = 1'b1;
        #10;

        $display("Starting reg file tests...");

        $display("CRT Tests:");


        //CRT 10000 tests

        for (int i = 0; i < 1000; i++) begin

            /*
            basically this writes a data in one reg, remembers it, then fills the rest with 
            random crap repeated over a random number of clk cycles and sees if that one reg 
            retained the value stably. aka torturing flip flops >:)
            */

            cycle_count = $urandom_range(0, 100);

            rs1_address = $urandom_range(0, 31);
            rs2_address = $urandom_range(0, 31);
            rd_address = $urandom_range(0, 31);
            write_data = $urandom();
            reg_write = 1'b1;

            write_rn = write_data;

            rd_rn = rd_address;


            @(posedge clk);
            #1;

            expected_val = (rd_rn == 5'd0) ? 32'd0 : write_rn;



            for (int j = 0; j < cycle_count; j++) begin


                rs1_address = $urandom_range(0, 31);
                rs2_address = $urandom_range(0, 31);

                rd_address = $urandom_range(0, 31);

                while (rd_address == rd_rn) begin
                    rd_address = $urandom_range(0, 31);
                end

                write_data = $urandom();
                reg_write = $urandom_range(0, 1);

                @(posedge clk);

                #1;
            end

            rs1_address = rd_rn;
            rs2_address = rd_rn;

            @(posedge clk);
            #1;

            assert ((expected_val == rs1_data) && (expected_val == rs2_data)) begin

                if ((i + 1) % 100 == 0) begin
                    $display("CRT test %0d / 1000 passed", i+1);
                end

            end else begin

                $fatal(1, "CRT test %0d, memory retention failed!", i+1);

            end


        end

        #100;

        $display("Directed Tests:");


        //test 1 basic write and read (reg x5)

        $display("Test 1 basic write and read (reg x5)");

        rd_address = 5'd5;
        write_data = 32'hDEADBEEF; 
        reg_write = 1'b1;         
        
        @(posedge clk);
        #1; 
        reg_write = 1'b0;      

        rs1_address = 5'd5;
        #1; 

        assert (rs1_data == 32'hDEADBEEF) begin
            $display("Test 1 passed");
        end 
        else begin
            $fatal(1, "Error: Incorrect output. Expected DEADBEEF in x5, got %h", rs1_data);
        end



        //test 2 dual read (reg x6 and x7)

        $display("Test 2 dual read (reg x6 and x7)");


        rd_address = 5'd6;
        write_data = 32'hCAFEBABE;
        reg_write = 1'b1;
        @(posedge clk);
        #1;


        rd_address = 5'd7;
        write_data = 32'h12345678;
        reg_write = 1'b1;
        @(posedge clk);
        #1;
        reg_write  = 1'b0;


        rs1_address = 5'd6;
        rs2_address = 5'd7;
        #1;

        assert (rs1_data == 32'hCAFEBABE && rs2_data == 32'h12345678) begin
            $display("Test 2 passed");
        end 
        else begin
            $fatal(1, "Error: Incorrect dual read output. Expected CAFEBABE & 12345678, got %h & %h", rs1_data, rs2_data);
        end



        //test 3 x0 hardwire attempted overwrite test

        $display("Test 3 hardwired low attempted overwrite test (reg x0)");

        rd_address = 5'd0;
        write_data = 32'hFFFFFFFF;
        reg_write = 1'b1;

        @(posedge clk);
        #1;
        reg_write = 1'b0;

        rs1_address = 5'd0;
        #1;

        assert (rs1_data == 32'd0) begin
            $display("Test 3 passed");
        end 
        else begin
            $fatal(1, "Error: Reg x0 overwritten, it must always be 0. Got %h", rs1_data);
        end


        $display("All RegFile tests successful, use 'gtkwave tb_reg_file.vcd tb_reg_file.gtkw' to open waveform.");
        
        $finish;

    end

endmodule
