#!/bin/bash

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
# 

echo "This script was generated under a different operating system."
echo "Please update the PATH and LD_LIBRARY_PATH variables below, before executing this script"
exit

if [ -z "$PATH" ]; then
  PATH=X:/AMDDesignTools/2026.1/Vitis/bin;X:/AMDDesignTools/2026.1/Vivado/ids_lite/ISE/bin/nt64;X:/AMDDesignTools/2026.1/Vivado/ids_lite/ISE/lib/nt64:X:/AMDDesignTools/2026.1/Vivado/bin
else
  PATH=X:/AMDDesignTools/2026.1/Vitis/bin;X:/AMDDesignTools/2026.1/Vivado/ids_lite/ISE/bin/nt64;X:/AMDDesignTools/2026.1/Vivado/ids_lite/ISE/lib/nt64:X:/AMDDesignTools/2026.1/Vivado/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='X:/Entropic_R32-P5_RISC-V/fpga/basys3/proj/r32p5_basys3.runs/impl_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

# pre-commands:
/bin/touch .init_design.begin.rst
EAStep vivado -log basys3_top.vdi -applog -m64 -product Vivado -messageDb vivado.pb -mode batch -source basys3_top.tcl -notrace


