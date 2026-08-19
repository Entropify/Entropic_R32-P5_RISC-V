import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()

async def hello_world_test(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    dut._log.info("CPU on. Running hello_world...")

    cycles = 0
    while cycles < 1000:

        await RisingEdge(dut.clk)

        if dut.halt.value == 1:
            break

        cycles += 1

    if cycles >= 1000:
        dut._log.error("Timed out, CPU never halted.")

    return_code = dut.cpu.cpu_reg_file.internal_reg[10].value.integer

    dut._log.info(f"x10 = {return_code} after {cycles} cycles")

    assert return_code == 3, f"Expected x10 == 3 (1+2), got {return_code}"

    dut._log.info("SUCCESS first C program ran correctly on the CPU!!! IM ALIVEEE")

