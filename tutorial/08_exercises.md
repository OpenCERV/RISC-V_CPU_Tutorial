# Chapter 08 — Exercises and further exploration

[← Previous: Running programs](07_running_programs.md) | [Home](../README.md)

## What you will learn

This chapter turns the working CPU into a small laboratory. Change one thing, run a short program, and observe the result.

## Beginner

- Change `simple_add.S` to compute a different sum.
- Add an `ori`, `xori`, or `slli` instruction and check its destination register.
- Add a new `[PASS]` check to `tb/tb_top.v`.
- Watch `uut.u_EX.alu_core_result` while stepping through a logical instruction.
- Write a branch test where `BEQ` is taken and another where it is not taken.
- Try writing to `x0` and confirm that it remains zero.

## Intermediate

- Add `SLT` and `SLTU` cases to a test program.
- Create a Fibonacci loop and check several result registers.
- Add a cycle counter or instruction counter to the testbench.
- Add a test for `BLT`, `BGE`, `BLTU`, or `BGEU`.
- Compile a tiny freestanding program with the RISC-V GNU toolchain and convert its `.text` section to the upstream byte-wide HEX format.

## Advanced

Do not add these features to the Tutorial 1 datapath as a prerequisite. Instead, compare the existing research implementations after you understand the single-cycle signal flow:

- multicycle control;
- five-stage pipelining;
- forwarding and hazard detection;
- dynamic branch prediction;
- RV32M;
- caches and external memory interfaces;
- synthesis and RTL-to-GDS.

The starting point is [advanced/README.md](../advanced/README.md), which points to the original `RISCV_core_rv32i` repository.

## Checkpoint

Choose one beginner exercise and record:

1. the assembly change;
2. the expected register or memory result;
3. the testbench check;
4. the waveform signal that demonstrates the operation.

That is the complete Tutorial 1 loop: change RTL inputs, run a program, observe state, and verify a result.

[← Previous](07_running_programs.md) | [Home](../README.md)
