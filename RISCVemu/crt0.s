    .section .text
    .globl _start
    .type _start, @function

_start:
    # 2MB RAM at 0x00000000 -> stack top at 0x00200000.
    lui sp, 0x200

    # Enter C program.
    call main

# If main returns, stop here.
1:
    j 1b

    .size _start, . - _start
