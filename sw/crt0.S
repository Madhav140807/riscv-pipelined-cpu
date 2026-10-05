# Startup code: runs before main
    .section .text.start
    .globl _start
_start:
    li   sp, 0x1000          # stack starts at the top of data memory
    call main                # run the C program
    li   t0, 0xFFFFFFF0      # halt address
    sw   a0, 0(t0)           # halt (main's return value stays in a0)
1:  j    1b