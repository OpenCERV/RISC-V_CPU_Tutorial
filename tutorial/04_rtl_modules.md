# Chapter 04 — Reading the RTL modules

[← Previous: Datapath](03_single_cycle_datapath.md) | [Home](../README.md) | [Next: Integration](05_cpu_integration.md) →

## What you will learn

You will match each conceptual datapath block to the existing Verilog file. The source is intentionally not rewritten into a second tutorial CPU.

## `PC_reg.v`

`PC_reg` is the state-holding program counter:

```verilog
always @(posedge clk) begin
    if (rst)
        pc <= 32'b0;
    else
        pc <= pc_next;
end
```

Reset starts fetching at byte address zero. `pc_next` is computed by the top-level datapath.

## `imem.v` and `IF.v`

`IF.v` is a small wrapper around `imem.v`. The memory is byte-wide and loads `program.hex` with `$readmemh`. Four adjacent bytes are assembled in little-endian order:

```verilog
assign data = { mem[addr + 3], mem[addr + 2],
                mem[addr + 1], mem[addr + 0] };
```

That is why the tutorial’s HEX converter emits one byte per line.

## `ID.v`

The decoder reads `opcode`, `funct3`, and `funct7`, then produces control signals. Important outputs are:

- `rs1_addr`, `rs2_addr`, `rd_addr`;
- `imm_type`;
- `alu_op` and `alu_rs2_imm`;
- `reg_write`;
- `mem_read` and `mem_write`;
- `branch`, `jal`, and `jalr`;
- `wb_sel`.

The decoder is a good place to add one instruction as an exercise, but first trace an existing `ADDI` case from opcode to control signals.

## `reg_file.v`

The register file has combinational reads and a clocked write. The read muxes explicitly return zero for address `x0`; the write logic ignores `rd_addr == 0`.

```verilog
assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
```

The testbench can inspect `uut.u_regfile.regs[index]` because the array is useful during simulation.

## `immgen.v`

`immgen` selects I, S, B, U, or J extraction. Sign extension is part of immediate generation, not an ALU feature. For example, an I-type immediate is:

```verilog
imm = {{20{inst[31]}}, inst[31:20]};
```

## `EX.v`

`EX` contains the ALU, branch comparison, branch target, jump target, and `PC+4`. The ALU supports add, subtract, logical operations, comparisons, and shifts. The `alu_rs2_imm` mux chooses between `rs2` and the generated immediate.

## `MEM.v`

`MEM` models 128 KiB of byte-wide data memory at `0x1000_0000`. It assembles byte, halfword, and word loads and performs clocked stores. It also retains the upstream UART address hook at `0x2000_0000`.

For Tutorial 1, focus on aligned `LW` and `SW`. The range and alignment checks are useful debugging messages when an assembly program uses a bad address.

## `WB.v`

`WB` is a two-input mux between the EX-side candidate and `mem_data`. The upstream `top.v` prepares the EX-side candidate for ordinary ALU results, `PC+4`, `LUI`, and `AUIPC` before it reaches `WB`.

## `csr_read.v` and `dpi_uart.cc`

These are existing side features of the upstream simulation core. `csr_read.v` exposes the low `mcycle` value. `dpi_uart.cc` supplies the C function used by the upstream UART store hook. They are included by the Verilator Makefile, but they are not needed to understand `ADD`.

## Try it

Use the source navigation above and then run:

```bash
cd single_cycle
make sim
```

## Checkpoint

Point to the exact upstream module responsible for each action:

| Action | Module |
| --- | --- |
| hold/update PC | `PC_reg.v` |
| choose control signals | `ID.v` |
| read `x1` and `x2` | `reg_file.v` |
| rearrange a branch immediate | `immgen.v` |
| compare branch operands | `EX.v` |
| write a loaded word | `MEM.v` and `WB.v` |

[← Previous](03_single_cycle_datapath.md) | [Home](../README.md) | [Next →](05_cpu_integration.md)
