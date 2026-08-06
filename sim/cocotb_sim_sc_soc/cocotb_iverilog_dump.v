module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/x/Entropic_R32-P5_RISC-V/sim/sc_soc_test/../cocotb_sim_sc_soc/soc_top.fst");
    $dumpvars(0, soc_top);
end
endmodule
