`timescale 1ns/1ps
/*
 * Testbench for the Basys3 bring-up top module.
 *
 * Drives the 100 MHz input clock and the active-high reset button, then waits
 * for the CPU to halt and checks that x10 (mirrored onto led[7:0]) == 1.
 *
 * The program image is pointed at the /mnt/x copy because this TB is run in
 * the WSL Icarus environment. For the Vivado build the default X:/ path in
 * basys3_top.v is used instead.
 */
module tb_basys3;

    reg  clk;
    reg  rst_btn;
    wire [15:0] led;

    basys3_top #(
        .INSTR_MEM_FILE("/mnt/x/Entropic_R32-P5_RISC-V_UART/fpga/basys3/fpga_prog.hex")
    ) dut (
        .clk(clk),
        .rst_btn(rst_btn),
        .led(led)
    );

    // 100 MHz input clock (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer cycles;
    initial begin
        cycles = 0;
        rst_btn = 1'b1;       // assert reset (active-high button)
        #40;                  // hold reset ~4 clock cycles
        rst_btn = 1'b0;       // release reset
        $display("[TB] Reset released; program running...");

        forever begin
            #10;              // one 100 MHz cycle
            cycles = cycles + 1;
            if (led[15] == 1'b1) begin
                $display("[TB] CPU HALTED after %0d cycles (100MHz). x10 (led[7:0]) = %0d", cycles, led[7:0]);
                if (led[7:0] == 8'd1)
                    $display("[TB] *** PASS: x10 == 1 (led[0] lit, led[15] halt lit) ***");
                else
                    $display("[TB] *** FAIL: x10 = %0d ***", led[7:0]);
                $finish;
            end
            if (cycles > 200000) begin
                $display("[TB] *** TIMEOUT: CPU never halted. led = %04h ***", led);
                $finish;
            end
        end
    end

    initial begin
        $dumpfile("basys3_sim.vcd");
        $dumpvars(0, tb_basys3);
    end

endmodule
