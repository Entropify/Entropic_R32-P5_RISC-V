# Rebuild from the current sources into a PRIVATE project dir (proj_build) so a
# GUI session holding proj/ cannot block it, and write a NEW bitstream name so
# the known-good r32p5_basys3.bit stays untouched.

set proj_dir "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3"
set rtl_dir  "X:/Entropic_R32-P5_RISC-V_UART/rtl"
set part     "xc7a35tcpg236-1"

if {[file exists "$proj_dir/proj_build"]} {
    file delete -force "$proj_dir/proj_build"
}

create_project r32p5_build "$proj_dir/proj_build" -part $part -force
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

report_timing_summary -file "$proj_dir/report_timing_build.rpt"
write_bitstream -force "$proj_dir/r32p5_basys3_rebuild.bit"
puts "=== REBUILD COMPLETE ==="
