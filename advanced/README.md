# Advanced and research implementations

Tutorial 1 is deliberately limited to the `single_cycle/` design. The linked conference repository contains the separate research material:

<https://github.com/WilliamHHL/RISCV_core_rv32i>

Suggested order after finishing Tutorial 1:

1. multicycle control and realistic one-cycle memory timing;
2. five-stage `IF`/`ID`/`EX`/`MEM`/`WB` pipelining;
3. forwarding and hazard detection;
4. dynamic branch prediction;
5. RV32M, caches, and SoC interfaces;
6. synthesis and RTL-to-GDS flows.

These are further exploration topics. They are not required to run the beginner CPU, and the Tutorial 1 documentation does not depend on an OpenLane or ASIC tool installation.
