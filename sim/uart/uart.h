/*
 * uart.h — MMIO UART helpers for the Entropic R32-P5 SoC
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * The SoC maps a UART TX at 0x1000_0000 (see rtl/soc_top.v):
 *   - store a word there -> its low byte is transmitted (8N1, 115200 baud)
 *   - load  a word there -> {31'b0, tx_busy}
 *
 * Header-only (static inline) so it drops into the bare-metal (-nostdlib)
 * C programs unchanged.
 */

#ifndef UART_H
#define UART_H

#define UART_BASE 0x10000000u

/* send one byte, waiting for the transmitter to be free */
static inline void uart_putc(char c) {
    volatile unsigned int *uart = (volatile unsigned int *)UART_BASE;
    while (*uart & 1u) { }                      /* spin while tx_busy */
    *uart = (unsigned int)(unsigned char)c;
}

/* send a NUL-terminated string */
static inline void uart_puts(const char *s) {
    while (*s) uart_putc(*s++);
}

/* send a signed decimal integer */
static inline void uart_putint(int v) {
    char buf[12];
    int i = 0;
    unsigned int u;

    if (v < 0) { uart_putc('-'); u = (unsigned int)(0 - (unsigned int)v); }
    else       { u = (unsigned int)v; }

    if (u == 0) { uart_putc('0'); return; }

    while (u) { buf[i++] = (char)('0' + (u % 10u)); u /= 10u; }
    while (i) uart_putc(buf[--i]);
}

/* send an unsigned integer as 0xXXXXXXXX */
static inline void uart_puthex(unsigned int v) {
    const char *digits = "0123456789ABCDEF";
    char buf[8];
    int i;

    for (i = 7; i >= 0; i--) { buf[i] = digits[v & 0xFu]; v >>= 4; }

    uart_puts("0x");
    for (i = 0; i < 8; i++) uart_putc(buf[i]);
}

#endif /* UART_H */
