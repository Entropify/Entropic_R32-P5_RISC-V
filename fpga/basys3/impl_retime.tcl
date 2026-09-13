# Full flow with aggressive directives, to try to recover the 50 MHz margin.
set proj_dir "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3"
set rtl_dir  "X:/Entropic_R32-P5_RISC-V_UART/rtl"
set part     "xc7a35tcpg236-1"

if {[file exists "$proj_dir/proj_retime"]} {
    file delete -force "$proj_dir/proj_retime"
}

create_project r32p5_retime "$proj_dir/proj_retime" -part $part -force
add_files -norecurse [glob "$rtl_dir/*.v"]
add_files -norecurse [glob "$proj_dir/basys3_top.v"]
add_files -fileset constrs_1 -norecurse "$proj_dir/basys3.xdc"
set_property top basys3_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top basys3_top -part $part

opt_design    -directive Explore
place_design  -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design  -directive AggressiveExplore

report_timing_summary -file "$proj_dir/report_timing_retimed.rpt"
write_bitstream -force "$proj_dir/r32p5_basys3.bit"

puts "=== RETIME BUILD COMPLETE ==="
