/*
 * uart_hello.s — UART bring-up self-check
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Writes "Hi\n" to the UART MMIO at 0x1000_0000 (polling tx_busy between
 * bytes), then sets x10 = 1 and halts with ebreak.
 */

    .section .text
    .global _start

_start:
    li   sp, 0xF00          # stack top (unused, but conventional)
    lui  t0, 0x10000        # t0 = 0x1000_0000 (UART MMIO)

    li   t1, 72             # 'H'
    jal  ra, uart_putc
    li   t1, 105            # 'i'
    jal  ra, uart_putc
    li   t1, 10             # '\n'
    jal  ra, uart_putc

    li   a0, 1              # x10 = 1 (pass)
    mv   x10, a0
    j    done

# wait until the UART is not busy, then send t1
uart_putc:
    lw   t2, 0(t0)          # status word: bit0 = tx_busy
    andi t2, t2, 1
    bne  t2, x0, uart_putc  # spin while busy
    sw   t1, 0(t0)          # low byte -> TX
    ret

done:
    ebreak
