/*
 * life.c — Conway's Game of Life, 20x20, drawn as ASCII over the UART.
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Bare-metal program for the Entropic R32-P5 SoC. The field is two byte arrays
 * in RAM; each generation is computed into the spare array and then printed to
 * the UART as '.' (dead) and 'O' (alive), rewriting the screen in place:
 *
 *   Gen 0
 *   ..O......O..........
 *   ...O.....O..........
 *   .OOO..OOO...........
 *   ...
 *
 * Watch it on the board's COM port at 115200 8N1. The UART paces the animation
 * by itself: 20 characters plus CR/LF is about 1.8 ms per row, so a frame
 * lands every ~39 ms — roughly 25 frames per second.
 *
 * The field is padded to 22x22 with a permanently dead one-cell border, so the
 * inner loop reads all eight neighbours with no bounds check at all. That is
 * cheaper in both instructions and code size than testing the edges on every
 * single cell.
 *
 * Build: bash sim/uart/build.sh life
 *   (a short run for simulation: bash sim/uart/build.sh life -DGENS=3)
 */

#include "uart.h"

#define SIZE    20                  /* visible field */
#define FIELD   (SIZE + 2)          /* plus the dead border on each side */

#ifndef GENS
#define GENS    200                 /* generations to run before halting */
#endif

static unsigned char buf_a[FIELD * FIELD];
static unsigned char buf_b[FIELD * FIELD];

static unsigned char *cur = buf_a;  /* buffer holding the live field */
static unsigned char *nxt = buf_b;  /* buffer being computed into */

#define AT(p, r, c)  ((p)[(r) * FIELD + (c)])

/* xorshift32 — a tiny reproducible pseudo-random source, no libc needed */
static unsigned int rng = 0xACE1u;

static unsigned int rnd(void) {
    unsigned int x = rng;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng = x;
    return x;
}

/* advance one generation: cur -> nxt, then swap the buffers */
static void step(void) {
    int r, c;

    for (r = 1; r <= SIZE; r = r + 1) {
        for (c = 1; c <= SIZE; c = c + 1) {
            int n = AT(cur, r-1, c-1) + AT(cur, r-1, c) + AT(cur, r-1, c+1)
                  + AT(cur, r,   c-1) +                     AT(cur, r,   c+1)
                  + AT(cur, r+1, c-1) + AT(cur, r+1, c) + AT(cur, r+1, c+1);
            int alive = AT(cur, r, c);

            /* B3/S23: born on exactly 3 neighbours, survives on 2 or 3 */
            AT(nxt, r, c) = (unsigned char)((n == 3) || (alive && (n == 2)));
        }
    }

    {
        unsigned char *tmp = cur;
        cur = nxt;
        nxt = tmp;
    }
}

/* redraw in place: cursor home, then one line per row */
static void show(int gen) {
    int r, c;

    uart_puts("\033[H");                /* ANSI home — no scrolling */
    uart_puts("Gen ");
    uart_putint(gen);
    uart_puts("\r\n");

    for (r = 1; r <= SIZE; r = r + 1) {
        for (c = 1; c <= SIZE; c = c + 1)
            uart_putc(AT(cur, r, c) ? 'O' : '.');
        uart_puts("\r\n");
    }
}

int main(void) {
    int i, r, c, g;

    /* Clear just the dead border of both buffers. It has to read as dead in
       every generation, and while the FPGA's RAM powers up zeroed, a
       simulation's does not — clear it explicitly so the two agree. The
       interiors need no clearing: buf_a's is fully written by the seed pattern
       below, and buf_b's by the first step(). Keeping this loop small also
       stops GCC from rewriting it as a call to memset. */
    for (i = 0; i < FIELD; i = i + 1) {
        buf_a[i] = 0;                       buf_a[(SIZE + 1) * FIELD + i] = 0;
        buf_b[i] = 0;                       buf_b[(SIZE + 1) * FIELD + i] = 0;
        buf_a[i * FIELD] = 0;               buf_a[i * FIELD + SIZE + 1] = 0;
        buf_b[i * FIELD] = 0;               buf_b[i * FIELD + SIZE + 1] = 0;
    }

    /* random soup at the classic ~25% starting density */
    for (r = 1; r <= SIZE; r = r + 1)
        for (c = 1; c <= SIZE; c = c + 1)
            AT(buf_a, r, c) = (unsigned char)((rnd() & 3u) == 0u);

    uart_puts("\033[2J\033[H");         /* clear the screen, then home */

    for (g = 0; g <= GENS; g = g + 1) {
        show(g);
        if (g < GENS) step();
    }

    uart_puts("done\r\n");

    return 1;   /* x10 = 1 -> pass */
}
