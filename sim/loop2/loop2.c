

//cpu: hello world! hi mom im alive!

/*

gtkwave ../cocotb_loop2/soc_top.fst  ../phase5.gtkw
*/


int main() {
    
    volatile int count = 0;
    volatile int flip = 0;

    for (int i = 0; i < 10000; i++) {
        if (i % 2 == 0) {
            count++;
        } else {
            count--;
        }
    }

    return count;
}

