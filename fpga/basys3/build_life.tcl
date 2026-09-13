# Bitstream build with a timing-directed place & route.
#
# Why this exists: the core closes at roughly 51 MHz, so at 50 MHz the result
# depends on placement luck -- the same sources have produced WNS +0.39, +0.28,
# +0.03 and -0.34. Rather than reroll the default flow, try progressively more
# aggressive strategies and stop at the first one that goes non-negative.
#
# Each attempt reopens a checkpoint taken before placement, because
# place_design cannot be re-run on an already-routed design.

set proj_dir "X:/Entropic_R32-P5_RISC-V_UART/fpga/basys3"
set rtl_dir  "X:/Entropic_R32-P5_RISC-V_UART/rtl"
set part     "xc7a35tcpg236-1"

if {[file exists "$proj_dir/proj_life"]} {
    file delete -force "$proj_dir/proj_life"
}

create_project r32p5_life "$proj_dir/proj_life" -part $part -force
add_files -norecurse [glob "$rtl_dir/*.v"]
add_files -norecurse [glob "$proj_dir/basys3_top.v"]
add_files -fileset constrs_1 -norecurse "$proj_dir/basys3.xdc"
set_property top basys3_top [current_fileset]
update_compile_order -fileset sources_1

synth_design -top basys3_top -part $part
opt_design

# checkpoint to restart each attempt from
write_checkpoint -force "$proj_dir/pre_place.dcp"

set strategies {
    {ExtraTimingOpt   AggressiveExplore}
    {ExtraNetDelayOpt NoTimingRelaxation}
    {Explore          Explore}
}

set attempt 0
set wns -999.0

foreach strat $strategies {
    incr attempt
    set place_dir [lindex $strat 0]
    set route_dir [lindex $strat 1]

    open_checkpoint "$proj_dir/pre_place.dcp"
    place_design -directive $place_dir
    phys_opt_design
    route_design -directive $route_dir

    set wns [get_property SLACK [get_timing_paths -max_paths 1 -setup]]
    puts "=== ATTEMPT $attempt: place=$place_dir route=$route_dir -> WNS=$wns ns ==="

    if {$wns >= 0} {
        puts "=== TIMING MET on attempt $attempt ==="
        break
    }
}

report_timing_summary -file "$proj_dir/report_timing_life.rpt"
report_utilization    -file "$proj_dir/report_util_life.rpt"
write_bitstream -force "$proj_dir/r32p5_life.bit"

puts "=== LIFE BUILD COMPLETE: WNS=$wns ns ==="
