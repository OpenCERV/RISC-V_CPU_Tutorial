# Chapter 06 — Simulation and waveforms

[← Previous: Integration](05_cpu_integration.md) | [Home](../README.md) | [Next: Running programs](07_running_programs.md) →

## What you will learn

- how the testbench creates a clock and reset;
- how the Makefile invokes Verilator;
- how a self-checking test ends with a clear result;
- how to inspect the same execution in GTKWave.

## Clock and reset

The testbench toggles the clock every 5 ns:

```verilog
always #5 clk = ~clk;
```

Reset is held high for two rising edges. The upstream `PC_reg` and `reg_file` use synchronous reset, so those edges initialize the PC and register array. After reset is released, instruction fetch starts at address zero.

## Run the test

The primary supported simulator is Verilator:

```bash
cd single_cycle
make sim
```

The Makefile compiles the upstream RTL files, the tutorial wrapper, and the upstream DPI UART helper. It also stages `programs/program.hex` and `programs/data.hex` at the working directory because the upstream memory modules read those exact filenames.

The testbench runs for a fixed number of cycles. The demo ends in a `jal x0, done` self-loop rather than using `EBREAK`, because the upstream simulation top treats `EBREAK` as a simulation stop event. After the timeout, the testbench reads the register file and data memory directly and reports each check.

## Waveform

`make sim` writes `build/cpu.vcd`. To open it:

```bash
make wave
```

Useful signals include:

```text
uut.pc
uut.instr
uut.u_ID.reg_write
uut.u_ID.mem_read
uut.u_ID.mem_write
uut.u_ID.branch
uut.u_ID.jal
uut.u_ID.jalr
uut.u_immgen.imm
uut.u_EX.alu_core_result
uut.u_EX.branch_taken
uut.u_MEM.mem_data
uut.u_WB.wb_data
uut.pc_next
```

The register array is under `uut.u_regfile.regs`. Data-memory bytes are under `uut.u_MEM.dmem`.

## Expected output

The important lines are:

```text
[PASS] x3 = 12
[PASS] memory[0x10000000] = 12
PASS: upstream single-cycle RV32I tutorial program completed
```

If an expected value changes, the testbench prints both the actual and expected hexadecimal values. That is faster to debug than inspecting a waveform first.

## Try it

1. Run `make sim`.
2. Open `build/cpu.vcd`.
3. Find the `beq` instruction by watching `uut.instr`.
4. Check whether `uut.u_EX.branch_taken` is high.
5. Confirm that `uut.pc_next` skips the wrong-path `addi`.

## Checkpoint

Explain why a register write is observed after a rising edge, while the ALU result and `pc_next` can be observed before that edge.

[← Previous](05_cpu_integration.md) | [Home](../README.md) | [Next →](07_running_programs.md)
