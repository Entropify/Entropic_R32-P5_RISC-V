/* t_str.c — uses a string literal (lives in .rodata) */
#include "uart.h"

int main(void) {
    uart_puts("Hi\r\n");
    return 1;
}
