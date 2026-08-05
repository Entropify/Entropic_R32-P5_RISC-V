# Copyright (c) 2026 Zhiyuan (Jerry) Jiang
# SPDX-License-Identifier: Apache-2.0

# btw jerry use make top_tb to build to hex

.global _start

_start:

    lw x1, 0(x0)    # x1 = 1
    lw x2, 4(x0)    # x2 = 2
    lw x3, 8(x0)    # x3 = 3

    # test alu
    add x4, x1, x2  # x4 = 1 + 2 = 3

    # test beq (should take branch)
    # it should jump to pass_beq since 3 = 3 (wow rlly?)
    beq x4, x3, pass_beq
    
    # if it fails to jump, write error code 3 to x10 and halt
    add x10, x0, x4
    beq x0, x0, halt

pass_beq:
    # test beq (should not take branch)
    beq x1, x2, fail_2
    beq x0, x0, pass_not_take_beq  # jump over the error trap

fail_2:
    # if it did jump (chud cpu), write error code 2 to x10 and halt
    add x10, x0, x2
    beq x0, x0, halt

pass_not_take_beq:
    # test lw and sw
    # store 3 from x4 into a blank space in RAM (address 12)
    sw x4, 12(x0)
    # read it back into a new register to see if it worked
    lw x5, 12(x0)
    
    # check if RAM preserved the 3
    beq x5, x3, pass_lw_sw

    # if sw or lw failed, write error code 5 to x10 and halt
    add x10, x2, x3 
    beq x0, x0, halt

pass_lw_sw:

    # validate addi without using addi to build the answer.

    add  x6, x4, x3
    addi x5, x1, 5          # 1 + 5 = 6
    beq  x5, x6, pass_addi

    add x10, x1, x3         # error code 4
    beq x0, x0, halt

pass_addi:

    # addi is now trusted :)

    # andi

    andi x5, x2, 3           # 2 & 3 = 2
    beq  x5, x2, pass_andi
    addi x10, x0, 6
    beq  x0, x0, halt

pass_andi:

    # ori
    ori  x5, x0, 3           # 0 | 3 = 3
    beq  x5, x3, pass_ori
    addi x10, x0, 7
    beq  x0, x0, halt

pass_ori:

    # xor
    xor  x5, x1, x0          # 1 ^ 0 = 1
    beq  x5, x1, pass_xor
    addi x10, x0, 8
    beq  x0, x0, halt

pass_xor:

    # xori
    xori x5, x3, 0           # 3 ^ 0 = 3
    beq  x5, x3, pass_xori
    addi x10, x0, 9
    beq  x0, x0, halt

pass_xori:

    addi x4, x1, 3           # x4 = 1 + 3 = 4

    # sll
    sll  x5, x1, x2          # 1 << 2 = 4
    beq  x5, x4, pass_sll
    addi x10, x0, 10
    beq  x0, x0, halt

pass_sll:

    # slli
    slli x5, x1, 2           # 1 << 2 = 4
    beq  x5, x4, pass_slli
    addi x10, x0, 11
    beq  x0, x0, halt
    
pass_slli:

    # srl
    srl  x5, x4, x2          # 4 >> 2 = 1
    beq  x5, x1, pass_srl
    addi x10, x0, 12
    beq  x0, x0, halt
pass_srl:

    # srli
    srli x5, x4, 2            # 4 >> 2 = 1
    beq  x5, x1, pass_srli
    addi x10, x0, 13
    beq  x0, x0, halt
pass_srli:


    sub  x17, x0, x1          # x17 = 0 - 1 = -1

    # sra
    sra  x5, x17, x1          # -1 >>> 1 = -1 (sign preserved)
    beq  x5, x17, pass_sra
    addi x10, x0, 14
    beq  x0, x0, halt

pass_sra:

    # srai
    srai x5, x17, 1            # -1 >>> 1 = -1
    beq  x5, x17, pass_srai
    addi x10, x0, 15
    beq  x0, x0, halt

pass_srai:


    # slt -1 < 1 = 1 (x5)
    slt  x5, x17, x1
    beq  x5, x1, pass_slt
    addi x10, x0, 16
    beq  x0, x0, halt

pass_slt:

    # sltu 0xFFFFFFFF < 1 = false = 0
    sltu x5, x17, x1
    beq  x5, x0, pass_sltu
    addi x10, x0, 17
    beq  x0, x0, halt

pass_sltu:

    # slti -1 < 1 = true = 1
    slti x5, x17, 1
    beq  x5, x1, pass_slti
    addi x10, x0, 18
    beq  x0, x0, halt

pass_slti:

    # sltiu 0xFFFFFFFF < 1 = false = 0
    sltiu x5, x17, 1
    beq   x5, x0, pass_sltiu
    addi  x10, x0, 19
    beq   x0, x0, halt

pass_sltiu:


    # bne 1 != 2 should take
    bne x1, x2, pass_bne
    addi x10, x0, 20
    beq  x0, x0, halt

pass_bne:

    # bne 1 != 1 should not take
    bne  x1, x1, fail_bne2
    beq  x0, x0, pass_bne2

fail_bne2:

    addi x10, x0, 21
    beq  x0, x0, halt

pass_bne2:

    # blt (signed) -1 < 1 should take
    blt  x17, x1, pass_blt
    addi x10, x0, 22
    beq  x0, x0, halt

pass_blt:

    # bltu 0xFFFFFFFF < 1 should not take
    bltu x17, x1, fail_bltu
    beq  x0, x0, pass_bltu

fail_bltu:

    addi x10, x0, 23
    beq  x0, x0, halt

pass_bltu:

    # bge (signed) -1 >= 1 should not take gng
    bge  x17, x1, fail_bge
    beq  x0, x0, pass_bge

fail_bge:

    addi x10, x0, 24
    beq  x0, x0, halt
    
pass_bge:

    # bgeu: 0xFFFFFFFF >= 1 should take
    bgeu x17, x1, pass_bgeu
    addi x10, x0, 25
    beq  x0, x0, halt


pass_bgeu:

    # and
    and x7, x6, x17          # 6 & ffffffff = 6
    beq  x7, x6, pass_and
    addi x10, x0, 26
    beq  x0, x0, halt

pass_and:

    # or
    or x8, x7, x17           # 6 | fffffffff = fffffffff
    beq  x8, x17, pass_or
    addi x10, x0, 27
    beq  x0, x0, halt

pass_or:

    # lb
    # store x17 (0xffffffff) so every byte in the word is 0xff

    sw x17, 16(x0)         # mem[16...19] = ff ff ff ff

    lb x21, 16(x0)         # byte0 = 0xFF, sign-extended -> 0xffffffff
    beq x21, x17, pass_lb
    addi x10, x0, 28
    beq x0, x0, halt

pass_lb:

    #lbu

    lbu x21, 16(x0)        # byte0 = 0xFF, zero-extended -> 0x000000FF
    addi x22, x0, 255
    beq x21, x22, pass_lbu
    addi x10, x0, 29
    beq x0, x0, halt

pass_lbu:

    #lh
    lh x21, 16(x0)         # halfword0 = 0xffff, sign-extended -> 0xffffffff
    beq x21, x17, pass_lh
    addi x10, x0, 30
    beq x0, x0, halt

pass_lh:

    #lhu

    lhu x21, 16(x0)        # halfword0 = 0xffff, zero-extended -> 0x0000ffff
    srli x22, x17, 16      # build 0x0000ffff
    beq x21, x22, pass_lhu
    addi x10, x0, 31
    beq x0, x0, halt

pass_lhu:

    #sb
    # write a all-ff word, overwrite only byte0

    sw x17, 20(x0)         # mem[20..23] = ff ff ff ff

    sb x2, 20(x0)     # byte0 = x2 (2)

    lb x21, 21(x0)    # byte1 should still be untouched 0xFF -> sign-ext 0xFFFFFFFF
    beq x21, x17, sb_byte1_ok
    addi x10, x0, 32
    beq x0, x0, halt

sb_byte1_ok:
    lbu x21, 20(x0)        # byte0 should now read back as 2
    beq x21, x2, pass_sb
    addi x10, x0, 32
    beq x0, x0, halt

pass_sb:

    # sh
    sw x17, 24(x0)   # mem[24..27] = ff ff ff ff

    sh x3, 24(x0)     # halfword0 = x3 (3)

    lh x21, 26(x0)        # halfword2 should still be untouched 0xffff -> sign-ext 0xffffffff
    beq x21, x17, sh_half_ok
    addi x10, x0, 33
    beq x0, x0, halt

sh_half_ok:
    lhu x21, 24(x0)    # halfword0 should now read back as 3
    beq x21, x3, pass_sh
    addi x10, x0, 33
    beq x0, x0, halt

pass_sh:

    # jal/jalr
    #use jal to jump first then 
    #verify if jalr is able to bring pc back to value in return reg correctly


    addi x19, x0, 0        

    jal x16, jal_target   # x16 = link = address of mark_return

mark_return:
    addi x19, x0, 1      # only executes if jalr landed here correctly
    beq x0, x0, check_jal

jal_target:
    jalr x0, x16, 0      # jump back using the link register

check_jal:
    beq x19, x1, pass_jal_jalr  #if it went to mark_retrun properly x19 sjould be 1 :)
    addi x10, x0, 34
    beq x0, x0, halt

pass_jal_jalr:

    # lui
    #lui loads a 20-bit imm into bits [31:12] and zeros bits [11:0]


    lui x24, 1               # x24 = 1 << 12 = 00 00 10 00

    addi x25, x0, 1
    slli x25, x25, 12        # x25 = 1 << 12

    beq x24, x25, pass_lui
    addi x10, x0, 35
    beq x0, x0, halt

pass_lui:

    # auipc
    # two back 2 back auipc should have a difference of 4 since every clk, pc + 4

    auipc x26, 0
    auipc x27, 0

    sub  x28, x27, x26
    addi x29, x0, 4

    beq x28, x29, pass_auipc
    addi x10, x0, 36
    beq x0, x0, halt


pass_auipc:
    ebreak
    ecall






all_pass:
    # write success code 1 to x10
    add x10, x0, x1



halt:
    # infinite loop for python my boo to detect
    beq x0, x0, halt
    

