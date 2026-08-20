

//cpu: hello world! hi mom im alive!

/*

gtkwave ../cocotb_loop4/soc_top.fst  ../phase5.gtkw
*/


int main() {
    volatile int count = 0;

    for (int i = 0; i < 100000; i++) {
        if ((i & 3) != 3) count++;
    }

    return count;
}
