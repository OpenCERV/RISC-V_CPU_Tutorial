# Chapter 05 — CPU integration

[← Previous: RTL modules](04_rtl_modules.md) | [Home](../README.md) | [Next: Simulation](06_simulation.md) →

## What you will learn

You will read `top.v` by signal flow instead of trying to understand every line at once.

## 1. PC path

`PC_reg u_PC` receives `pc_next` and produces `pc`. The default path is:

```text
pc → pc_plus4 → pc_next → PC_reg
```

`EX` can replace the default with a branch or jump target.

## 2. Instruction fetch

`IF u_IF` passes the current byte-addressed PC to `imem`. The resulting 32-bit `instr` is visible as a top-level output and in the waveform.

## 3. Decode

`ID u_ID` splits `instr` into register addresses and function fields, then creates control signals. It does not store an instruction in a pipeline register; this is a single-cycle datapath.

## 4. Register reads

`reg_file u_regfile` reads `rs1_data` and `rs2_data` using the addresses supplied by `ID`. The same instance receives `wb_data` and `wb_wen` for the one write port.

## 5. Immediate generation

`immgen u_immgen` receives the instruction and `imm_type` from `ID`. Its `imm` output fans out to EX and the writeback candidate for `LUI`/`AUIPC` handling.

## 6. Execution

`EX u_EX` receives the PC, register values, immediate, and ALU controls. It produces:

- `alu_core_result` for arithmetic and addresses;
- `pc_plus4` for ordinary sequencing and jump links;
- `auipc_result`;
- `branch_target`;
- `branch_taken`.

## 7. Memory

`MEM u_MEM` uses `alu_core_result` as the effective address and `rs2_data` as store data. `mem_read` and `mem_write` come directly from `ID`.

## 8. Writeback

`top.v` builds the ALU-side candidate, then `WB u_WB` selects either that candidate or `mem_data` according to `wb_sel`. The result is sent to `u_regfile`.

The writeback cases are:

```text
WB_ALU  → ALU result
WB_MEM  → data memory
WB_PC4  → PC + 4
WB_IMM  → U-type immediate
```

## 9. Next-PC selection

The final selection is intentionally visible:

```verilog
assign pc_next = branch_taken ? branch_target : pc_plus4;
```

`EX` makes `branch_taken` true for a taken conditional branch, `JAL`, or `JALR`. For a `JALR`, the target is `(rs1 + imm) & 32'hFFFF_FFFE`.

## Try it

Open a waveform after running `make sim`:

```bash
make wave
```

At the cycle where `instr` is `add x3,x1,x2`, follow `u_ID`, `u_regfile`, `u_EX`, and `u_WB`. Then do the same for the `sw` and `beq` instructions.

## Checkpoint

Draw the signal path for `lw x6, 0(x5)` using only module names and signals. Your path should include `u_ID.mem_read`, `u_EX.alu_core_result`, `u_MEM.mem_data`, `u_WB.wb_data`, and `u_regfile.regs[6]`.

[← Previous](04_rtl_modules.md) | [Home](../README.md) | [Next →](06_simulation.md)
