# Copyright (c) 2026 Zhiyuan (Jerry) Jiang
# SPDX-License-Identifier: Apache-2.0

# this skibidi assembly test is padded with NOP for phase 1 test so no hazards for now!

# these r for simulator only

#addi x1, x0, 1

#addi x2, x0, 2

#addi x3, x0, 3

#sw x1, 0(x0)

#sw x2, 4(x0)

#sw x3, 8(x0)




.macro NOP
    addi x0, x0, 0    # nop for padding
.endm


.global _start

_start:


    lw x1, 0(x0)    # x1 = 1

    lw x2, 4(x0)    # x2 = 2

    NOP
    NOP

    lw x3, 8(x0)    # x3 = 3

    # test alu
    add x4, x1, x2  # x4 = 1 + 2 = 3

    # test beq (should take branch)
    # it should jump to pass_beq since 3 = 3 (wow rlly?)

    NOP
    NOP

    beq x4, x3, pass_beq
    
    NOP
    NOP

    # if it fails to jump, write error code 3 to x10 and halt
    add x10, x0, x4
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_beq:
    # test beq (should not take branch)
    NOP
    NOP


    beq x1, x2, fail_2
    
    NOP
    NOP

    beq x0, x0, pass_not_take_beq  # jump over the error trap
    
    NOP
    NOP


fail_2:

    NOP
    NOP

    # if it did jump (chud cpu), write error code 2 to x10 and halt
    add x10, x0, x2
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_not_take_beq:

    NOP
    NOP

    # test lw and sw
    # store 3 from x4 into a blank space in RAM (address 12)
    sw x4, 12(x0)
    
    NOP
    NOP

    # read it back into a new register to see if it worked
    lw x5, 12(x0)
    
    NOP
    NOP

    
    # check if RAM preserved the 3
    beq x5, x3, pass_lw_sw
    
    NOP
    NOP


    # if sw or lw failed, write error code 5 to x10 and halt
    add x10, x2, x3 
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lw_sw:

    NOP
    NOP


    # validate addi without using addi to build the answer.

    add  x6, x4, x3
    
    NOP
    NOP

    addi x5, x1, 5          # 1 + 5 = 6
    
    NOP
    NOP

    beq  x5, x6, pass_addi
    
    NOP
    NOP


    add x10, x1, x3         # error code 4
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_addi:

    NOP
    NOP


    # addi is now trusted :)

    # andi

    andi x5, x2, 3           # 2 & 3 = 2
    
    NOP
    NOP

    beq  x5, x2, pass_andi
    
    NOP
    NOP

    addi x10, x0, 6
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_andi:

    NOP
    NOP


    # ori
    ori  x5, x0, 3           # 0 | 3 = 3
    
    NOP
    NOP

    beq  x5, x3, pass_ori
    
    NOP
    NOP

    addi x10, x0, 7
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_ori:

    NOP
    NOP


    # xor
    xor  x5, x1, x0          # 1 ^ 0 = 1
    
    NOP
    NOP

    beq  x5, x1, pass_xor
    
    NOP
    NOP

    addi x10, x0, 8
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_xor:

    NOP
    NOP


    # xori
    xori x5, x3, 0           # 3 ^ 0 = 3
    
    NOP
    NOP

    beq  x5, x3, pass_xori
    
    NOP
    NOP

    addi x10, x0, 9
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_xori:

    NOP
    NOP


    addi x4, x1, 3           # x4 = 1 + 3 = 4
    
    NOP
    NOP


    # sll
    sll  x5, x1, x2          # 1 << 2 = 4
    
    NOP
    NOP

    beq  x5, x4, pass_sll
    
    NOP
    NOP

    addi x10, x0, 10
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_sll:

    NOP
    NOP


    # slli
    slli x5, x1, 2           # 1 << 2 = 4
    
    NOP
    NOP

    beq  x5, x4, pass_slli
    
    NOP
    NOP

    addi x10, x0, 11
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP

    
pass_slli:

    NOP
    NOP


    # srl
    srl  x5, x4, x2          # 4 >> 2 = 1
    
    NOP
    NOP

    beq  x5, x1, pass_srl
    
    NOP
    NOP

    addi x10, x0, 12
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP

pass_srl:

    NOP
    NOP


    # srli
    srli x5, x4, 2            # 4 >> 2 = 1
    
    NOP
    NOP

    beq  x5, x1, pass_srli
    
    NOP
    NOP

    addi x10, x0, 13
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP

pass_srli:

    NOP
    NOP



    sub  x17, x0, x1          # x17 = 0 - 1 = -1
    
    NOP
    NOP


    # sra
    sra  x5, x17, x1          # -1 >>> 1 = -1 (sign preserved)
    
    NOP
    NOP

    beq  x5, x17, pass_sra
    
    NOP
    NOP

    addi x10, x0, 14
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_sra:

    NOP
    NOP


    # srai
    srai x5, x17, 1            # -1 >>> 1 = -1
    
    NOP
    NOP

    beq  x5, x17, pass_srai
    
    NOP
    NOP

    addi x10, x0, 15
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_srai:

    NOP
    NOP



    # slt -1 < 1 = 1 (x5)
    slt  x5, x17, x1
    
    NOP
    NOP

    beq  x5, x1, pass_slt
    
    NOP
    NOP

    addi x10, x0, 16
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_slt:

    NOP
    NOP


    # sltu 0xFFFFFFFF < 1 = false = 0
    sltu x5, x17, x1
    
    NOP
    NOP

    beq  x5, x0, pass_sltu
    
    NOP
    NOP

    addi x10, x0, 17
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_sltu:

    NOP
    NOP


    # slti -1 < 1 = true = 1
    slti x5, x17, 1
    
    NOP
    NOP

    beq  x5, x1, pass_slti
    
    NOP
    NOP

    addi x10, x0, 18
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_slti:

    NOP
    NOP


    # sltiu 0xFFFFFFFF < 1 = false = 0
    sltiu x5, x17, 1
    
    NOP
    NOP

    beq   x5, x0, pass_sltiu

    NOP
    NOP

    addi  x10, x0, 19

    NOP
    NOP

    beq   x0, x0, halt
    
    NOP
    NOP


pass_sltiu:

    NOP
    NOP



    # bne 1 != 2 should take
    bne x1, x2, pass_bne
    
    NOP
    NOP

    addi x10, x0, 20
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_bne:

    NOP
    NOP


    # bne 1 != 1 should not take
    bne  x1, x1, fail_bne2
    
    NOP
    NOP

    beq  x0, x0, pass_bne2
    
    NOP
    NOP


fail_bne2:

    NOP
    NOP


    addi x10, x0, 21
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_bne2:

    NOP
    NOP


    # blt (signed) -1 < 1 should take
    blt  x17, x1, pass_blt
    
    NOP
    NOP

    addi x10, x0, 22
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_blt:

    NOP
    NOP


    # bltu 0xFFFFFFFF < 1 should not take
    bltu x17, x1, fail_bltu
    
    NOP
    NOP

    beq  x0, x0, pass_bltu
    
    NOP
    NOP


fail_bltu:

    NOP
    NOP


    addi x10, x0, 23
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_bltu:

    NOP
    NOP


    # bge (signed) -1 >= 1 should not take gng
    bge  x17, x1, fail_bge
    
    NOP
    NOP

    beq  x0, x0, pass_bge
    
    NOP
    NOP


fail_bge:

    NOP
    NOP


    addi x10, x0, 24
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP

    
pass_bge:

    NOP
    NOP


    # bgeu: 0xFFFFFFFF >= 1 should take
    bgeu x17, x1, pass_bgeu
    
    NOP
    NOP

    addi x10, x0, 25
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP



pass_bgeu:

    NOP
    NOP


    # and
    and x7, x6, x17          # 6 & ffffffff = 6
    
    NOP
    NOP

    beq  x7, x6, pass_and
    
    NOP
    NOP

    addi x10, x0, 26
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_and:

    NOP
    NOP


    # or
    or x8, x7, x17           # 6 | fffffffff = fffffffff
    
    NOP
    NOP

    beq  x8, x17, pass_or
    
    NOP
    NOP

    addi x10, x0, 27
    
    NOP
    NOP

    beq  x0, x0, halt
    
    NOP
    NOP


pass_or:

    NOP
    NOP


    # lb
    # store x17 (0xffffffff) so every byte in the word is 0xff

    sw x17, 16(x0)         # mem[16...19] = ff ff ff ff
    
    NOP
    NOP


    lb x21, 16(x0)         # byte0 = 0xFF, sign-extended -> 0xffffffff
    
    NOP
    NOP

    beq x21, x17, pass_lb
    
    NOP
    NOP

    addi x10, x0, 28
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lb:

    NOP
    NOP


    #lbu

    lbu x21, 16(x0)        # byte0 = 0xFF, zero-extended -> 0x000000FF
    
    NOP
    NOP

    addi x22, x0, 255
    
    NOP
    NOP

    beq x21, x22, pass_lbu
    
    NOP
    NOP

    addi x10, x0, 29
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lbu:

    NOP
    NOP


    #lh
    lh x21, 16(x0)         # halfword0 = 0xffff, sign-extended -> 0xffffffff
    
    NOP
    NOP

    beq x21, x17, pass_lh
    
    NOP
    NOP

    addi x10, x0, 30
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lh:

    NOP
    NOP


    #lhu

    lhu x21, 16(x0)        # halfword0 = 0xffff, zero-extended -> 0x0000ffff
    
    NOP
    NOP

    srli x22, x17, 16      # build 0x0000ffff
    
    NOP
    NOP

    beq x21, x22, pass_lhu
    
    NOP
    NOP

    addi x10, x0, 31
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lhu:

    NOP
    NOP


    #sb
    # write a all-ff word, overwrite only byte0

    sw x17, 20(x0)         # mem[20..23] = ff ff ff ff
    
    NOP
    NOP


    sb x2, 20(x0)     # byte0 = x2 (2)
    
    NOP
    NOP


    lb x21, 21(x0)    # byte1 should still be untouched 0xFF -> sign-ext 0xFFFFFFFF
    
    NOP
    NOP

    beq x21, x17, sb_byte1_ok
    
    NOP
    NOP

    addi x10, x0, 32
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


sb_byte1_ok:

    NOP
    NOP

    lbu x21, 20(x0)        # byte0 should now read back as 2
    
    NOP
    NOP

    beq x21, x2, pass_sb
    
    NOP
    NOP

    addi x10, x0, 32
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_sb:

    NOP
    NOP


    # sh
    sw x17, 24(x0)   # mem[24..27] = ff ff ff ff
    
    NOP
    NOP


    sh x3, 24(x0)     # halfword0 = x3 (3)
    
    NOP
    NOP


    lh x21, 26(x0)        # halfword2 should still be untouched 0xffff -> sign-ext 0xffffffff
    
    NOP
    NOP

    beq x21, x17, sh_half_ok
    
    NOP
    NOP

    addi x10, x0, 33
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


sh_half_ok:

    NOP
    NOP

    lhu x21, 24(x0)    # halfword0 should now read back as 3
    
    NOP
    NOP

    beq x21, x3, pass_sh
    
    NOP
    NOP

    addi x10, x0, 33
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_sh:

    NOP
    NOP


    # jal/jalr
    #use jal to jump first then 
    #verify if jalr is able to bring pc back to value in return reg correctly


    addi x19, x0, 0        
    
    NOP
    NOP


    jal x16, jal_target   # x16 = link = address of mark_return
    
    NOP
    NOP


mark_return:

    NOP
    NOP

    addi x19, x0, 1      # only executes if jalr landed here correctly
    
    NOP
    NOP

    beq x0, x0, check_jal
    
    NOP
    NOP


jal_target:

    NOP
    NOP

    jalr x0, x16, 0      # jump back using the link register
    
    NOP
    NOP


check_jal:

    NOP
    NOP

    beq x19, x1, pass_jal_jalr  #if it went to mark_retrun properly x19 sjould be 1 :)
    
    NOP
    NOP

    addi x10, x0, 34
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_jal_jalr:

    NOP
    NOP


    # lui
    #lui loads a 20-bit imm into bits [31:12] and zeros bits [11:0]


    lui x24, 1               # x24 = 1 << 12 = 00 00 10 00
    
    NOP
    NOP


    addi x25, x0, 1
    
    NOP
    NOP

    slli x25, x25, 12        # x25 = 1 << 12
    
    NOP
    NOP


    beq x24, x25, pass_lui
    
    NOP
    NOP

    addi x10, x0, 35
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP


pass_lui:

    NOP
    NOP


    # auipc
    # two back 2 back auipc should have a difference of 4 since every clk, pc + 4

    auipc x26, 0
    

    auipc x27, 0
    
    NOP
    NOP


    sub  x28, x27, x26
    
    NOP
    NOP

    addi x29, x0, 4
    
    NOP
    NOP


    beq x28, x29, pass_auipc
    
    NOP
    NOP

    addi x10, x0, 36
    
    NOP
    NOP

    beq x0, x0, halt
    
    NOP
    NOP



pass_auipc:

    NOP
    NOP

    ebreak
    
    NOP
    NOP

    ecall
    
    NOP
    NOP

phase_2_0NOP:

    add x9, x1, x3
    sw x9, 28(x0)
    lw x11, 28(x0)

    NOP
    NOP

    beq x11, x4, pass_phase_2_0NOP

    NOP
    NOP

    addi x10, x0, 37
    
    NOP
    NOP

    beq x0, x0, halt

    NOP
    NOP



pass_phase_2_0NOP:

    NOP
    NOP

    add x5, x1, x2
    add x5, x1, x3



    beq x5, x4, pass_forward_hierarchy

    NOP
    NOP

    addi x10, x0, 38
    
    NOP
    NOP

    beq x0, x0, halt

    NOP
    NOP

exception_x0_failed:

    NOP
    NOP

    addi x10, x0, 39
    
    NOP
    NOP

    beq x0, x0, halt

    NOP
    NOP

pass_forward_hierarchy:

    NOP
    NOP

    add x0, x1, x2
    beq x0, x3, exception_x0_failed

    NOP
    NOP


lw_then_sw_no_NOP:

    
    
    lw x5, 8(x0)       #this gets 3 from ram
    sw x5, 32(x0)
    lw x9, 32(x0)

    NOP
    NOP
    
    beq x9, x3, load_then_alu

    NOP
    NOP

    addi x10, x0, 40

    beq x0, x0, halt


load_then_alu:

    NOP
    NOP

    lw x12, 8(x0)
    add x13, x12, x3

    NOP
    NOP

    beq x13, x6, load_then_branch

    NOP
    NOP

    addi x10, x0, 41

    beq x0, x0, halt


load_then_branch:

    NOP
    NOP

    lw x18, 16(x0)
    beq x18, x8, lw_sw_addr_operand

    NOP
    NOP

    addi x10, x0, 42

    beq x0, x0, halt

lw_sw_addr_operand:

    NOP
    NOP

    lw x20, 28(x0)
    sw x3, 32(x20)

    lw x12, 36(x0)

    beq x12, x3, b2b_stalls

    NOP
    NOP

    addi x10, x0, 43

    beq x0, x0, halt


b2b_stalls:

    NOP
    NOP

    lw x28, 28(x0) #pulls 4 from mem
    lw x29, 0(x28) #pulls 2 from addr 4
    add x30, x28, x29

    beq x30, x6, all_pass

    NOP
    NOP

    addi x10, x0, 44

    beq x0, x0, halt

    






all_pass:

    NOP
    NOP

    # write success code 1 to x10
    add x10, x0, x1





halt:


    # infinite loop for python my boo to detect
    beq x0, x0, halt
    
    NOP
    NOP
    
  

    

