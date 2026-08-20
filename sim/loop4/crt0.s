

.global _start

_start:
    li sp, 0xF00       
    call main            
    mv x10, a0
halt:
    ebreak

