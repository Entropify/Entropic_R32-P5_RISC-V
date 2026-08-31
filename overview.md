\## Overview



Entropic R32-P5 takes the fully-verified single-cycle Entropic R32-SC and reworks it into a standard 5-stage pipeline (IF → ID → EX → MEM → WB). It also contains everything a real pipeline needs to stay correct and efficient: full operand forwarding, load-use hazard detection with stalling, control-hazard flushing, branch resolution moved into ID for a 1-cycle misprediction penalty, and a dynamic branch predictor with a 64 entries branch target buffer.



Every submodule from the single-cycle core (`alu.v`, `alu\_control.v`, `branch\_comp.v`, `control\_unit.v`, `imm\_gen.v`, `load\_filter.v`, `store\_mask.v`) carries over unmodified. The pipeline is built entirely by adding pipeline registers, forwarding/hazard logic, and a predictor around the existing, already-verified datapath pieces.



The chip features:

\- Full RV32I instruction coverage, same as the single-cycle

\- Each pipeline capability built and verified as its own phase, each with a dedicated self-checking assembly program that checks \*\*all pipeline hazards / forwarding behavior / edge cases\*\* and a cocotb driver, each phase built on previous phases and thus everything is \*\*regression tested\*\* every single phase

\- Five benchmark programs (standard looping, alternating branching, divisibility check (heavy nested looping), periodic branch, and recursive Fibonacci) measured for CPI and branch-prediction accuracy at two optimization levels

\- A working \*\*C toolchain\*\*: RISC-V GCC → `crt0.s` startup → linker script → `.o` → `.elf` → `.hex` → simulated on the real CPU, running actual compiled programs (loops, recursion) rather than only hand-written assembly

\- Synthesized and physically implemented through the full RTL-to-GDSII flow using \[OpenLane2](https://github.com/efabless/openlane2) and the \[SKY130 PDK](https://github.com/google/skywater-pdk), ran locally in a Docker + WSL environment



