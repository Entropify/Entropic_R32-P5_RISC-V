/*
 * hello_uart.c — UART bring-up demo for the Entropic R32-P5 on Basys3
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Compiled to an instruction-ROM image and printed over the USB-UART bridge.
 * Open a serial terminal on the board's COM port at 115200 baud, 8N1.
 *
 * String literals work because data_mem is preloaded with the same program
 * image the instruction ROM uses (see rtl/data_mem.v), which puts .rodata
 * into the data RAM where the CPU can actually read it.
 */

#include "uart.h"

int fib(int n) {
    return (n < 2) ? n : (fib(n - 1) + fib(n - 2));
}

int main(void) {
    int i;

    uart_puts("Hello from the Entropic R32-P5 on Basys3!\r\n");

    for (i = 0; i <= 10; i = i + 1) {
        uart_puts("fib(");
        uart_putint(i);
        uart_puts(") = ");
        uart_putint(fib(i));
        uart_puts("\r\n");
    }

    uart_puts("--- done ---\r\n");

    return 1;   /* x10 = 1 -> pass */
}
