

//cpu: hello world! hi mom im alive!

/*

gtkwave ../cocotb_loop3/soc_top.fst  ../phase5.gtkw
*/


static inline int mod(int a, int b) {
    while (a >= b) a -= b;
    return a;
}

int main() {
    volatile int count = 0;

    for (int i = 0; i < 1000; i++) {
        if (mod(i, 2) == 0 || mod(i, 3) == 0 || mod(i, 5) == 0) count++;
    }

    return count;
}
