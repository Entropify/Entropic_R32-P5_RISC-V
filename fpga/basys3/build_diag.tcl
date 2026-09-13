# Diagnostic build: PC-on-LEDs + reset-CDC fix.
# Paths generated programmatically from the real folder name (verified).

set proj_dir "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3"
set rtl_dir  "X:/Entropic_R32-P5_RISC-V_UART/rtl"
set part     "xc7a35tcpg236-1"

if {[file exists "$proj_dir/proj_diag"]} {
    file delete -force "$proj_dir/proj_diag"
}

create_project r32p5_diag "$proj_dir/proj_diag" -part $part -force
add_files -norecurse [glob "$rtl_dir/*.v"]
add_files -norecurse [glob "$proj_dir/basys3_top.v"]
add_files -fileset constrs_1 -norecurse "$proj_dir/basys3.xdc"
set_property top basys3_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top basys3_top -part $part

opt_design
place_design
phys_opt_design
route_design

report_timing_summary -file "$proj_dir/report_timing_diag.rpt"
write_bitstream -force "$proj_dir/r32p5_basys3_diag.bit"
puts "=== DIAG BUILD COMPLETE ==="
