# Single-cycle RV32I CPU

This directory is the executable part of Tutorial 1. The core in `rtl/` is copied from the `RV32I_Single_Cycle/` directory of [`RISCV_core_rv32i`](https://github.com/WilliamHHL/RISCV_core_rv32i). The tutorial does not replace that implementation with a new core. The CPU completes one instruction in one clock cycle. Instruction and data memory reads are modeled as combinational reads, which keeps the datapath easy to see in simulation.

The copied RTL corresponds to upstream commit `9d2219502c9f099e269007365a1699c9731f2ffc` at the time this tutorial was prepared. The file contents are retained byte-for-byte; only the tutorial wrapper and build files are new.

## Run the supplied program

From this directory:

```bash
make sim
```

The testbench loads `programs/program.hex`, runs the program, checks registers and `memory[0]`, and prints `[PASS]` or `[FAIL]` messages. The final line should be:

```text
PASS: upstream single-cycle RV32I tutorial program completed
```

Build output and the waveform are placed in `build/`.

```bash
make wave   # Run the test and open build/cpu.vcd in GTKWave
make clean  # Remove generated simulation files
```

## Files

| Path | Purpose |
| --- | --- |
| `rtl/PC_reg.v` | Clocked program counter |
| `rtl/imem.v` and `rtl/IF.v` | HEX-loaded instruction memory and fetch wrapper |
| `rtl/ID.v` | Opcode/funct field to control signals |
| `rtl/immgen.v` | I/S/B/U/J immediate extraction |
| `rtl/reg_file.v` | Two-read, one-write register file with hardwired `x0` |
| `rtl/EX.v` | Integer ALU, comparisons, and next-PC targets |
| `rtl/MEM.v` | Byte-wide data memory and load/store assembly |
| `rtl/WB.v` | Writeback mux |
| `rtl/top.v` | Upstream datapath integration |
| `tb/tb_top.v` | Tutorial clock, reset, waveform, and self-checks |
| `tb/upstream_tb_top.v` | Original upstream testbench, retained for reference |
| `programs/program.hex` | Default machine-code image |

Read the RTL in the same order as the tutorial. Start with `pc.v` and `reg_file.v`; read `top.v` only after the individual pieces are familiar.

## Assemble a different program

The handwritten programs are intentionally small:

- `programs/simple_add.S`
- `programs/load_store_test.S`
- `programs/branch_test.S`
- `programs/tutorial_demo.S`

The first three are examples for the tutorial. If the RISC-V GNU assembler is installed, generate the image used by `make sim` with:

```bash
make assemble PROGRAM=programs/simple_add.S HEX=programs/program.hex
make sim
```

The `assemble` target produces a flat `.text` binary and converts it to one byte per HEX line, which is the format expected by the upstream `imem.v`. Restore the full demonstration image with:

```bash
make assemble
```

The assembler is optional; the checked-in `program.hex` is enough for the default run.

## Memory model

The upstream core uses byte addresses. Instruction memory is a 128 KiB byte array. Data memory is a 128 KiB byte array mapped at `0x1000_0000`; `LW`/`SW` use aligned 32-bit accesses there. `LW` reads combinationally; `SW` writes on the rising clock edge. Stores to `0x2000_0000` are reserved for the upstream UART hook.

This is a teaching model. It does not model byte enables, misaligned accesses, wait states, caches, or external buses.

## Inspecting the waveform

Open `build/cpu.vcd` with GTKWave and add:

- `dut.pc` and `dut.instr`;
- `dut.u_ID` control signals;
- `dut.u_immgen.imm`;
- `dut.u_regfile.rs1_data` and `dut.u_regfile.rs2_data`;
- `dut.u_EX.alu_core_result`;
- `dut.u_WB.wb_data`;
- `dut.pc_next` and `dut.u_EX.branch_taken`.

The register file is visible as `dut.u_regfile.regs[0]` through `dut.u_regfile.regs[31]`; data memory bytes are visible as `dut.u_MEM.dmem[0]` through `dut.u_MEM.dmem[131071]`.
