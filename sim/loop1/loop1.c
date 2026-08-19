

//cpu: hello world! hi mom im alive!

/*

gtkwave ../cocotb_loop1/soc_top.fst  ../phase5.gtkw
*/


int main() {
    
    volatile int count = 0;

    for (int i = 0; i < 10000; i++) {
        count++;
    }

    return count;
}

