# Chapter 00 — Introduction

[Home](../README.md) | [Next: RISC-V basics](01_riscv_basics.md) →

## What you will learn

You will identify the parts of a CPU and the path an instruction takes through a single-cycle RV32I design.

## Concept

A CPU is a state machine that repeatedly:

1. reads the instruction at the program counter (PC);
2. interprets the instruction fields;
3. computes a result or address;
4. optionally reads or writes memory;
5. writes a result to a register;
6. chooses the next PC.

RISC-V is an instruction set architecture (ISA). An ISA is the contract between software and hardware: it defines registers, instruction encodings, and the visible effects of each instruction. `RV32I` means the 32-bit base integer instruction set.

This tutorial uses a single-cycle implementation. “Single-cycle” describes the timing model: one instruction completes between two rising clock edges. It does not mean the CPU has only one module.

```text
               +----------------------+
Instruction -->|                      |
               |     RV32I CPU        |----> register result
Clock -------->|                      |
Reset -------->|                      |----> data memory
               +----------------------+
```

The actual core is the existing `RV32I_Single_Cycle` implementation from [`RISCV_core_rv32i`](https://github.com/WilliamHHL/RISCV_core_rv32i). This repository adds a learning path and a self-checking wrapper around it.

## Implementation

The tutorial copy keeps the upstream module boundaries:

```text
PC_reg → IF/imem → ID → reg_file + immgen → EX → MEM → WB → reg_file
   └────────────────────────────── next-PC feedback ─────────────────────┘
```

The upstream memory model loads instruction bytes from `program.hex`. Data memory begins at address `0x1000_0000`.

## Try it

On Ubuntu, install the simulation tools once:

```bash
sudo apt update
sudo apt install git build-essential verilator gtkwave
```

Check that Verilator is available:

```bash
verilator --version
```

Then clone the repository and run the first test:

```bash
git clone https://github.com/WilliamHHL/RISC-V_CPU_Tutorial.git
cd RISC-V_CPU_Tutorial/single_cycle
make sim
```

## Expected result

The supplied program computes `5 + 7`, stores and reloads the result, exercises branches and jumps, and ends in a harmless self-loop. The testbench prints register checks and finishes with:

```text
PASS: upstream single-cycle RV32I tutorial program completed
```

## Checkpoint

You should now be able to explain the difference between an ISA and a CPU implementation, and why this tutorial starts with one instruction completing in one cycle.

[← Home](../README.md) | [Next →](01_riscv_basics.md)
