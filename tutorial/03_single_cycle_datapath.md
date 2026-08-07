# Chapter 03 — The single-cycle datapath

[← Previous: Instructions](02_rv32i_instructions.md) | [Home](../README.md) | [Next: RTL modules](04_rtl_modules.md) →

## What you will learn

You will trace arithmetic, memory, branch, and jump instructions through the hardware before reading the top-level Verilog.

## Datapath

```text
                         +------------------+
                    +--->|   PC_reg         |<--- next PC
                    |    +--------+---------+
                    |             |
                    |             v
                    |    +------------------+
                    |    | IF / instruction |
                    |    | memory           |
                    |    +--------+---------+
                    |             |
                    |             v
                    |    +------------------+
                    |    | ID: decode       |
                    |    +---+----------+---+
                    |        |          |
                 rs1/rs2     |          +--> immediate generator
                    |        v                    |
                    |  +-----------+              |
                    +->| reg_file  |----+---------+
                       +-----------+    |
                                         v
                              +------------------+
                              | EX: ALU and     |
                              | branch comparator|
                              +----+--------+----+
                                   |        |
                                   v        +----> branch/jump next PC
                              +---------+
                              | MEM     |
                              +----+----+
                                   |
                                   v
                              +---------+
                              | WB      |----> reg_file write port
                              +---------+
```

The diagram is a combinational path between clock edges. State is stored in the PC, register file, and data memory. `top.v` wires the modules together; it does not add pipeline registers.

## ADD

```text
read rs1, rs2
      ↓
EX computes rs1 + rs2
      ↓
WB selects ALU result
      ↓
write rd on the clock edge
```

The decoder sets `reg_write=1`, `alu_rs2_imm=0`, and `wb_sel=ALU`.

## ADDI

```text
read rs1
      ↓
immgen sign-extends instruction[31:20]
      ↓
EX computes rs1 + immediate
      ↓
write rd
```

The only datapath difference from `ADD` is the ALU’s second-input mux: `alu_rs2_imm=1`.

## LW

```text
read base register rs1
      ↓
EX computes rs1 + offset
      ↓
MEM reads four bytes at that address
      ↓
WB selects memory data
      ↓
write rd
```

For the upstream core, a valid load address must be in the data-memory map beginning at `0x1000_0000` and must be aligned for a word load.

## SW

```text
read base rs1 and store value rs2
      ↓
immgen builds the S-type offset
      ↓
EX computes rs1 + offset
      ↓
MEM writes rs2 on the rising edge
```

`SW` has no register writeback. It is still a complete single-cycle instruction because the memory write happens at the edge ending the cycle.

## BEQ

```text
read rs1 and rs2
      ↓
EX compares them
      ↓
if equal: PC = PC + B-immediate
else:     PC = PC + 4
```

`EX.v` also handles `BNE`, signed/unsigned less-than branches, `JAL`, and `JALR`. `JAL` writes `PC+4` to `rd`; `JALR` masks bit zero of its target.

## Try it

Read `single_cycle/rtl/top.v` and find, in order:

1. the `PC_reg` instance;
2. the `IF` instance;
3. the decoder and register-file instances;
4. `immgen` and `EX`;
5. `MEM` and `WB`;
6. `assign pc_next = branch_taken ? branch_target : pc_plus4`.

## Checkpoint

Without looking at the code, answer: which instruction uses the memory-to-writeback path, which instruction uses the `PC+4` writeback path, and which instruction has no writeback path at all?

[← Previous](02_rv32i_instructions.md) | [Home](../README.md) | [Next →](04_rtl_modules.md)
