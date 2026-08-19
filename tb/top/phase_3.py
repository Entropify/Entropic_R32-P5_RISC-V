import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer




# self checking testbench that runs until the CPU halts then checks x10
#cd into sim/sc_soc_test
# btw use make top_tb to build to hex cus i keep forgetting smh


@cocotb.test()
async def phase_3(dut):
    

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Flushing RAM...")

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    
    # flushing ram with basic values since we can't trust any inustructions yet since we havent tested them blah blah blah
    dut.ram.mem_array[0].value = 1  # address 0
    dut.ram.mem_array[1].value = 2  # address 4
    dut.ram.mem_array[2].value = 3  # address 8

    dut._log.info("RAM flushed with 1 @ address 0, 2 @ address 4, 3 @ address 8")
    
    dut.rst_n.value = 1
    dut._log.info("CPU on. Waiting for assembly to reach successful branch")

    current_pc = 0
   # prev_pc = -1
    cycles = 0
    
    history = []


    while cycles < 1000:

        await RisingEdge(dut.clk)
        
        try:
            current_pc = dut.cpu.cpu_pc.pc_out.value.integer
            #current_instr = dut.cpu.instruction.value.integer

            history.append(current_pc)

            if len(history) > 6 and history[-1] == history[-4] and history[-2] == history[-5] and history[-3] == history[-6]:
                break
                
            # prev_pc = current_pc

        except ValueError:
            pass

        cycles += 1

    # preventing program from stalling forever if soc is broken (big sad)
    if cycles >= 1000:
        dut._log.error("Simulation timed out. CPU never hit the expected infinite loop. dut._log.info.")



    # checking register x10 for return value, 1 = pass (wait 1 shouldn't show), anything else = FAIL!!!!

    return_code = dut.cpu.cpu_reg_file.internal_reg[10].value.integer



    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|\033[1m\033[34m                            Epic Error Codes Meaning Table Below                        \033[0m\033[0m|")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 2 = failed to not take branch during invalid beq                            |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 3 = failed to take branch during valid beq                                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 4 = failed addi instruction                                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 5 = failed to lw and sw properly                                            |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 6 = failed andi instruction                                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 7 = failed ori instruction                                                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 8 = failed xor instruction                                                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 9 = failed xori instruction                                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 10 = failed sll instruction (logical left)                                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 11 = failed slli instruction (logical left immediate)                       |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 12 = failed srl instruction (logical right)                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 13 = failed srli instruction (logical right immediate)                      |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 14 = failed sra instruction (arithmetic right sign not preserved)           |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 15 = failed srai instruction (arithmetic right immediate sign not preserved)|")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 16 = failed slt instruction (signed comparison)                             |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 17 = failed sltu instruction (unsigned comparison)                          |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 18 = failed slti instruction (signed immediate comparison)                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 19 = failed sltiu instruction (unsigned immediate comparison)               |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 20 = failed to take branch during valid bne                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 21 = failed to not take branch during invalid bne                           |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 22 = failed to take branch during valid blt (signed)                        |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 23 = failed to not take branch during invalid bltu (unsigned)               |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 24 = failed to not take branch during invalid bge (signed)                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 25 = failed to take branch during valid bgeu (unsigned)                     |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 26 = failed and instruction                                                 |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 27 = failed or instruction                                                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 28 = failed lb instruction (sign extension incorrect)                       |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 29 = failed lbu instruction (zero extension incorrect)                      |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 30 = failed lh instruction (sign extension incorrect)                       |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 31 = failed lhu instruction (zero extension incorrect)                      |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 32 = failed sb instruction (write incorrect or changed neighboring byte)    |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 33 = failed sh instruction (write incorrect or changed neighboring halfword)|")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 34 = failed jal/jalr instruction (link address or jump target incorrect)    |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 35 = failed lui instruction (upper immediate placement incorrect)           |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 36 = failed auipc instruction (pc relative upper immediate incorrect)       |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 37 = failed forwarding when 0 NOP between read after write                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 38 = failed forwarding hierarchy (ex/mem should have priority over mem/wb)  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 39 = failed forwarding exception for x0                                     |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 40 = failed MEM stage forwarding (lw then sw, same reg)                     |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 41 = failed use after load (lw, then immediately add, RAW)                  |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 42 = failed branch after load (lw then beq, same reg)                       |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 43 = failed lw then sw using loaded reg as address operand for sw           |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|Error code: 44 = failed back to back stalls (lw, lw, add)                               |")
    dut._log.info("------------------------------------------------------------------------------------------")
    dut._log.info("|\033[1m\033[34m                            Epic Error Codes Meaning Table Above                        \033[0m\033[0m|")
    dut._log.info("------------------------------------------------------------------------------------------")

    dut._log.info("To view waveform use \033[34mgtkwave ../cocotb_sim_phase_3/soc_top.fst ../phase3.gtkw\033[0m")


    assert return_code == 1, f'\033[31mTEST FAILED >:(\033[0m: assembly code returned error code: \033[31m{return_code}\033[0m'

    

    dut._log.info("If no error code please ignore but appreciate the above table (it took forever to type and format)")

    dut._log.info(f"Instruction loop detected at: program counter \033[34m{current_pc}\033[0m after \033[34m{cycles}\033[0m cycles.")

    dut._log.info("\033[32mTEST SUCCESS :D\033[0m Assembly program passed self checks and verified by python test function")
