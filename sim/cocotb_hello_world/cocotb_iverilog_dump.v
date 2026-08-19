module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/x/Entropic_R32-P5_RISC-V/sim/c_hello_world/../cocotb_hello_world/soc_top.fst");
    $dumpvars(0, soc_top);
end
endmodule
