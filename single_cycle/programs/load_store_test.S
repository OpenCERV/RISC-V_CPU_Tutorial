    .option norvc
    .section .text
    .globl _start
_start:
    lui  x3, 0x10000
    addi x1, x0, 10
    sw   x1, 0(x3)
    lw   x2, 0(x3)
done:
    jal  x0, done
