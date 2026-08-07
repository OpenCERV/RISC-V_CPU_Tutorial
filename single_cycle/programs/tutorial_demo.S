    .option norvc
    .section .text
    .globl _start

_start:
    addi x1,  x0, 5
    addi x2,  x0, 7
    add  x3,  x1, x2
    sub  x4,  x2, x1
    and  x15, x1, x2
    or   x16, x1, x2
    xor  x17, x1, x2
    addi x18, x0, 1
    sll  x19, x1, x18
    srl  x20, x2, x18

    lui  x5, 0x10000       # Existing core's data memory starts at 0x10000000.
    sw   x3, 0(x5)
    lw   x6, 0(x5)

    beq  x3, x6, branch_taken
    addi x7, x0, 99        # This instruction must be skipped.
branch_taken:
    addi x7, x0, 42

    addi x8, x0, 0
    addi x9, x0, 3
loop:
    addi x8, x8, 1
    bne  x8, x9, loop

    jal  x10, jal_target
    addi x11, x0, 99       # This instruction must be skipped.
jal_target:
    addi x11, x0, 42

    auipc x12, 0
    addi  x12, x12, 16
    jalr  x13, 0(x12)
    addi  x14, x0, 99      # This instruction must be skipped.
jalr_target:
    addi  x14, x0, 42

    addi x0, x0, 99        # x0 must remain zero.
done:
    jal  x0, done
