# Chapter 07 — Running programs

[← Previous: Simulation](06_simulation.md) | [Home](../README.md) | [Next: Exercises](08_exercises.md) →

## What you will learn

You will connect handwritten assembly, machine code, instruction memory, and the Verilog CPU.

## Program 1 — arithmetic

`single_cycle/programs/simple_add.S` contains:

```asm
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
```

Expected state:

```text
x1 = 5
x2 = 7
x3 = 12
```

## Program 2 — load/store

The upstream data memory begins at `0x1000_0000`, so the test program first builds that address:

```asm
lui  x3, 0x10000
addi x1, x0, 10
sw   x1, 0(x3)
lw   x2, 0(x3)
```

Expected state:

```text
x2 = 10
memory[0x10000000] = 10
```

## Program 3 — branch

```asm
addi x1, x0, 0
addi x2, x0, 5
loop:
addi x1, x1, 1
bne  x1, x2, loop
```

Expected state:

```text
x1 = 5
```

The full `tutorial_demo.S` combines these ideas with logical operations, `LUI`, `AUIPC`, `JAL`, and `JALR`. Its checked-in `program.hex` is the byte-wide machine-code image used by `imem.v`.

## The software path

```text
assembly (.S)
       ↓ riscv64-unknown-elf-as
object (.o)
       ↓ objcopy -O binary
flat binary
       ↓ bin_to_byte_hex.py
program.hex
       ↓ $readmemh
upstream imem.v
       ↓
single-cycle CPU
```

The toolchain is optional for the tutorial because `program.hex` is checked in. If it is installed, regenerate the default image with:

```bash
cd single_cycle
make assemble
make sim
```

To use a different handwritten program, overwrite the image used by the simulation:

```bash
make assemble PROGRAM=programs/simple_add.S
make sim
```

Restore the complete demonstration with `make assemble`.

The Makefile copies the generated image to `single_cycle/program.hex` at simulation time because the upstream `imem.v` opens `program.hex` relative to its working directory. This is a path convention, not a change to the upstream core.

## Try it

Modify `simple_add.S` so the third instruction adds different values. Assemble it, run the test, and update the testbench only if you intentionally changed the expected architectural state.

## Expected result

For the default image:

```text
[PASS] x1 = 5
[PASS] x2 = 7
[PASS] x3 = 12
...
PASS: upstream single-cycle RV32I tutorial program completed
```

## Checkpoint

You should be able to explain all four transformations below:

```text
addi x1, x0, 5 → encoded instruction → bytes in program.hex
program.hex → imem.mem[] → instr
instr → decoder/ALU/memory/writeback
writeback → x1 on a rising edge
```

[← Previous](06_simulation.md) | [Home](../README.md) | [Next →](08_exercises.md)
