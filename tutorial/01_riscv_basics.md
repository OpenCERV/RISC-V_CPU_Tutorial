# Chapter 01 — RISC-V basics

[← Previous: Introduction](00_introduction.md) | [Home](../README.md) | [Next: Instructions](02_rv32i_instructions.md) →

## What you will learn

- what the 32 registers and PC represent;
- why `x0` is special;
- how registers and memory differ;
- how a small assembly sequence changes architectural state.

## Concept

RV32I has thirty-two integer registers named `x0` through `x31`. Each register holds 32 bits. The register file in this project has two combinational read ports and one clocked write port.

`x0` always reads as zero. A write to `x0` is ignored. This makes constants and discarded results easy to encode:

```asm
addi x1, x0, 5       # x1 = 0 + 5
addi x0, x1, 99       # ignored; x0 is still 0
```

The program counter is a byte address. Normal instructions are 32 bits, so the normal next PC is `PC + 4`. A branch or jump replaces that value with a target address.

RISC-V is a load/store architecture. Arithmetic uses registers. Only load and store instructions access data memory:

```asm
lw  x2, 0(x5)         # x2 = memory[x5 + 0]
sw  x1, 0(x5)         # memory[x5 + 0] = x1
```

The existing core maps data memory at `0x1000_0000`. The tutorial demo uses `LUI` to place that address in `x5` before `LW` and `SW`.

## Example

```asm
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
```

After these instructions:

```text
x1 = 5
x2 = 7
x3 = 12
```

The write to `x1` occurs on one rising edge. The next instruction reads the updated value from the register file. In a single-cycle design, the read, ALU operation, and writeback for an instruction all happen in the combinational path before the next edge.

## Try it

Open `single_cycle/tb/tb_top.v`. Find the checks for `x1`, `x2`, and `x3`. Then inspect the corresponding instructions in `single_cycle/programs/tutorial_demo.S`.

Run:

```bash
cd single_cycle
make sim
```

## Expected result

```text
[PASS] x1 = 5
[PASS] x2 = 7
[PASS] x3 = 12
```

## Checkpoint

Explain why `addi x5, x3, 8` needs a register read, an immediate, an ALU addition, and a register write, but does not need data memory.

[← Previous](00_introduction.md) | [Home](../README.md) | [Next →](02_rv32i_instructions.md)
