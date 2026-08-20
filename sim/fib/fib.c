

//cpu: hello world! hi mom im alive!

/*

gtkwave ../cocotb_loop4/soc_top.fst  ../phase5.gtkw
*/


int fib(int n) {
    if (n == 0 || n == 1) return n;
    else return fib(n-1) + fib(n-2);
}

int main() {
    int x = fib(15);
    return x;
}
