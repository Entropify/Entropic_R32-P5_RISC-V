/*
 * minilib.c — the few freestanding routines the compiler still expects.
 * Copyright (c) 2026 Zhiyuan (Jerry) Jiang
 * SPDX-License-Identifier: Apache-2.0
 *
 * Built with -nostdlib there is no libc, but GCC will happily lower a loop
 * into a call to memset/memcpy — it did exactly that to the Life field's
 * clearing loop at -Os. Define them here so such programs still link.
 *
 * size_t is written as unsigned int because that is what it is on rv32i; this
 * keeps the file header-free and matches the compiler's own prototype.
 */

void *memset(void *dst, int value, unsigned int n) {
    unsigned char *d = (unsigned char *)dst;
    while (n--) *d++ = (unsigned char)value;
    return dst;
}

void *memcpy(void *dst, const void *src, unsigned int n) {
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) *d++ = *s++;
    return dst;
}

void *memmove(void *dst, const void *src, unsigned int n) {
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;

    if (d < s) {
        while (n--) *d++ = *s++;
    } else {
        d = d + n;
        s = s + n;
        while (n--) *--d = *--s;
    }
    return dst;
}
