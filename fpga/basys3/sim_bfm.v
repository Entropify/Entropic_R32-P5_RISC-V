// Icarus-only stub for the Xilinx BUFG primitive, so basys3_top.v can be
// simulated in Icarus Verilog (which does not know the Xilinx cell library).
module BUFG(input wire I, output wire O);
    assign O = I;
endmodule
