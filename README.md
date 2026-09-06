# CityUHK Open RISC-V Hub — RV32I CPU Tutorial

## Build Your First RISC-V Processor in Verilog

This repository is Tutorial 1 for the tentative CityUHK EE RISC-V Community. You will build and simulate a small **single-cycle RV32I processor**. The result is a real Verilog CPU: it fetches machine code from instruction memory, executes it, and updates registers and data memory.

The tutorial is written for readers who know basic digital logic and Verilog, but are new to CPU design. It focuses on visible cause and effect. A short assembly program becomes HEX, `$readmemh` loads the HEX, and the CPU executes one instruction per clock cycle.

## Start here

```text
Single-cycle RV32I tutorial
        ↓
read a program
        ↓
make sim
        ↓
inspect PASS and the waveform
```

The fastest first run on Ubuntu is:

```bash
# Install the required simulator and C++ build tools.
sudo apt update
sudo apt install git build-essential verilator gtkwave

git clone https://github.com/WilliamHHL/RISC-V_CPU_Tutorial.git
cd RISC-V_CPU_Tutorial/single_cycle
make sim
```

Expected ending:

```text
[PASS] x3 = 12
[PASS] memory[0] = 12
PASS: single-cycle RV32I tutorial program completed
```

## What you will build

The tutorial CPU contains:

- a program counter;
- instruction memory;
- an instruction decoder and immediate generator;
- a 32 × 32-bit register file;
- an ALU;
- word-addressed data memory;
- next-PC logic for branches and jumps;
- a self-checking Verilog testbench.

The supported Tutorial 1 instructions are:

| Group | Instructions |
| --- | --- |
| Integer ALU | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| Immediate ALU | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| Memory | `LW`, `SW` |
| Control flow | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JAL`, `JALR` |
| Upper immediate | `LUI`, `AUIPC` |

This first model uses zero-latency combinational memory reads. It is intended for learning and simulation, not for a realistic SRAM interface.

## Tutorial roadmap

1. [Introduction](tutorial/00_introduction.md)
2. [RISC-V basics](tutorial/01_riscv_basics.md)
3. [RV32I instruction formats](tutorial/02_rv32i_instructions.md)
4. [The single-cycle datapath](tutorial/03_single_cycle_datapath.md)
5. [Reading the RTL modules](tutorial/04_rtl_modules.md)
6. [CPU integration](tutorial/05_cpu_integration.md)
7. [Simulation and waveforms](tutorial/06_simulation.md)
8. [Running programs](tutorial/07_running_programs.md)
9. [Exercises](tutorial/08_exercises.md)

Each chapter has a small checkpoint. You do not need to understand pipelining, caches, synthesis, or physical design to complete Tutorial 1.

## Prerequisites and tools

Required for the supplied simulation:

- Git;
- GNU Make;
- Verilator.
- a C++ compiler (`g++`), used to build the upstream UART simulation helper.

Optional:

- GTKWave for waveform inspection;
- RISC-V binutils (`riscv64-unknown-elf-as` and `riscv64-unknown-elf-objcopy`) for assembling your own `.S` files;
- the RISC-V GCC package for compiling C programs.

## Install tools on Ubuntu

Install the required simulation tools before cloning or running the tutorial:

```bash
sudo apt update
sudo apt install git build-essential verilator gtkwave
```

Run this check before continuing:

```bash
verilator --version
make --version
g++ --version
```

To assemble the supplied `.S` examples, also install:

```bash
sudo apt install binutils-riscv64-unknown-elf
```

To compile a small C program later, install:

```bash
sudo apt install gcc-riscv64-unknown-elf
```

Toolchain package names vary by distribution. The checked-in `program.hex` means beginners can complete the first CPU simulation without the RISC-V toolchain.

## Tutorial track and research track

```text
TUTORIAL TRACK                         RESEARCH / ADVANCED TRACK
Single-cycle RV32I                     Multicycle RV32I
Simulation with Verilator              Five-stage pipeline
Small handwritten programs              Hazard handling and forwarding
                                        Dynamic branch prediction
                                        CoreMark and OpenLane
                                        SKY130 physical implementation
```

This repository is intentionally the beginner-facing tutorial track. The original conference project and its historical RTL/backend material are maintained separately in [`RISCV_core_rv32i`](https://github.com/WilliamHHL/RISCV_core_rv32i). See [advanced/README.md](advanced/README.md) before exploring those designs.

## Repository layout

```text
RISC-V_CPU_Tutorial/
├── README.md
├── tutorial/                 # Concepts, diagrams, commands, checkpoints
├── single_cycle/
│   ├── rtl/                  # Plain Verilog implementation
│   ├── tb/                   # Self-checking testbench
│   ├── programs/             # Assembly and pre-generated HEX
│   ├── tools/                # Optional binary-to-HEX helper
│   ├── Makefile
│   └── README.md
└── advanced/                 # Pointers to the separate research track
```

## Research / ICSPCC 2026

The related conference work is:

> Design, Verification, and ASIC Implementation of a Five-Stage Pipelined RV32I RISC-V Processor with Dynamic Branch Prediction

That work includes architecture evolution, CoreMark results, branch prediction, OpenLane, SKY130, and physical implementation. Those topics are valuable after the basic CPU is understood, but they are not prerequisites for this tutorial and are deliberately kept out of the main path.

## License

See [LICENSE](LICENSE).
