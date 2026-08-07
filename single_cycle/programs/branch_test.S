    .option norvc
    .section .text
    .globl _start
_start:
    addi x1, x0, 0
    addi x2, x0, 5
loop:
    addi x1, x1, 1
    bne  x1, x2, loop
done:
    jal  x0, done
