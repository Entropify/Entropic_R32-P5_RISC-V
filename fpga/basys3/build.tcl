# Entropic R32-P5 -> Basys3 (xc7a35tcpg236-1) batch build
# Usage (from the fpga/basys3 directory):
#   vivado -mode batch -source build.tcl
# Produces: r32p5_basys3.bit plus synthesis/implementation reports.

set proj_dir  "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3"
set rtl_dir   "X:/Entropic_R32-P5_RISC-V_UART/rtl"
set part      "xc7a35tcpg236-1"

# --- clean any previous project ---
set proj_file "$proj_dir/proj/r32p5_basys3.xpr"
if {[file exists "$proj_dir/proj"]} {
    file delete -force "$proj_dir/proj"
}

# --- create project ---
create_project r32p5_basys3 "$proj_dir/proj" -part $part -force

# --- add RTL sources ---
add_files -norecurse [glob "$rtl_dir/*.v"]
add_files -norecurse [glob "$proj_dir/basys3_top.v"]

# --- add constraints ---
add_files -fileset constrs_1 -norecurse "$proj_dir/basys3.xdc"

# --- set top module ---
set_property top basys3_top [current_fileset]

update_compile_order -fileset sources_1

# --- synthesis ---
synth_design -top basys3_top -part $part
report_utilization -file "$proj_dir/report_utilization_synth.rpt"
report_timing_summary -file "$proj_dir/report_timing_synth.rpt"

# --- implementation ---
opt_design
place_design
phys_opt_design
route_design

report_utilization -file "$proj_dir/report_utilization_impl.rpt"
report_timing_summary -file "$proj_dir/report_timing_route.rpt"

write_bitstream -force "$proj_dir/r32p5_basys3.bit"

puts "=== BUILD COMPLETE ==="
puts "Bitstream: $proj_dir/r32p5_basys3.bit"
