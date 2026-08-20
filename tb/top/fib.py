import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer


@cocotb.test()
async def fibonacci_test(dut):

    clock = Clock(dut.clk, 5, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    dut._log.info("CPU on. Running fibonacci...")

    cycles = 0
    stall_cycles = 0
    flush_cycles = 0
    total_predictions = 0
    correct_predictions = 0

    while cycles < 10000000:
        await RisingEdge(dut.clk)
        '''
        sp_val = dut.cpu.cpu_reg_file.internal_reg[2].value.integer
        if cycles % 500 == 0:
            dut._log.info(f"cycle {cycles}: sp={sp_val:#x}")
        if sp_val == 0xEC0:  # or track "has sp been stuck at EC0 for N cycles in a row"
            dut._log.info(f"cycle {cycles}: pc={dut.cpu.cpu_pc.pc_out.value.integer:#x} halted={dut.cpu.halted.value.integer} i={dut.ram.mem_array[0xEEC//4].value.integer}")
        '''
        if dut.cpu.stall.value.integer == 1:
            stall_cycles += 1
        if dut.cpu.flush.value.integer == 1:
            flush_cycles += 1

        resolving = (dut.cpu.branch_d.value.integer == 1) or (dut.cpu.pc_src_d.value.integer in (1, 2))
        if resolving:
            total_predictions += 1
            if dut.cpu.mispredicted.value.integer == 0:
                correct_predictions += 1

        if dut.halt.value == 1:
            break

        cycles += 1

    if cycles >= 10000000:
        dut._log.error("Timed out — CPU never halted.")

    return_code = dut.cpu.cpu_reg_file.internal_reg[10].value.integer
    dut._log.info(f"x10 = {return_code} after {cycles} cycles")
    assert return_code == 610, f"Expected x10 == 610, got {return_code}"

    retired_instructions = cycles - stall_cycles - flush_cycles
    cpi = cycles / retired_instructions if retired_instructions > 0 else float('inf')
    accuracy = 100 * correct_predictions / total_predictions if total_predictions > 0 else 0

    dut._log.info(f"Total cycles: {cycles}")
    dut._log.info(f"Stall cycles: {stall_cycles}, Flush cycles: {flush_cycles}")
    dut._log.info(f"Approx. retired instructions: {retired_instructions}")
    dut._log.info(f"CPI: {cpi:.3f}")
    dut._log.info(f"Branch predictions: {total_predictions}, correct: {correct_predictions}")
    dut._log.info(f"Prediction accuracy: {accuracy:.2f}%")

    dut._log.info("SUCCESS - fibonacci ran correctly on the CPU!")
