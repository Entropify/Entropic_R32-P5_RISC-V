module cocotb_iverilog_dump();
initial begin
    $dumpfile("cocotb_sim/soc_top.fst");
    $dumpvars(0, soc_top);
end
endmodule
