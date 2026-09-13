/* t_char.c — no string literals (chars are immediates) */
#include "uart.h"

int main(void) {
    uart_putc('H');
    uart_putc('i');
    uart_putc('\r');
    uart_putc('\n');
    return 1;
}
