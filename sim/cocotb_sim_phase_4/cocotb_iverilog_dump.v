module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/x/Entropic_R32-P5_RISC-V/sim/phase_4/../cocotb_sim_phase_4/soc_top.fst");
    $dumpvars(0, soc_top);
end
endmodule
