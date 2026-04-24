# RISC-V Single-Cycle CPU on DE2-115

A compact RISC-V RV32I-style processor implemented in SystemVerilog and integrated with Intel Quartus Prime for the DE2-115 FPGA board (Cyclone IV E).

This project includes:
- A single-cycle RISC-V core (`RISCV.sv`) with debug-friendly outputs.
- A board wrapper top module (`RISCV_FPGA.sv`) for on-hardware execution.
- Basic data memory and register file implementations.
- Standalone module and core testbenches in `tb/`.
- Quartus project files (`RISCV.qpf`, `RISCV.qsf`) with board pin assignments.
- RISCV emulator written in python to emulate the core. 
- Script to generate RISCV instructions from C code to run on this CPU.  

## Project Overview

This design is a **single-cycle** RISC-V CPU. The core executes one instruction per cycle, with combinational decode/execute/memory/writeback logic and a PC register updated on the clock edge.

There is also a testbench directory to simulate the behavior of the CPU using Qesta/Modelsim waveforms.

When used on an DE2-115 FPGA, the FPGA wrapper divides the DE2-115 `CLOCK_50` input down to a slower `core_clk`, making behavior easier to observe on LEDs and in timing/waveform debug.

## Implemented ISA Support

The decoder/ALU logic currently supports unprivilaged RV32I instruction formats and operations:

- `R`-type arithmetic/logic:
  - `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`
- `I`-type arithmetic/logic:
  - `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`
- Loads:
  - `LB`, `LH`, `LW`, `LBU`, `LHU`
- Stores:
  - `SB`, `SH`, `SW`
- Branches:
  - `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jumps:
  - `JAL`, `JALR`
- Upper-immediate instructions:
  - `LUI`, `AUIPC`


## Requirements

- Intel Quartus Prime Lite/Standard compatible with this project revision.
- Questa (Intel FPGA Edition) for simulation, if available/licensed.
- DE2-115 FPGA board (Cyclone IV E, EP4CE115F29C7) for hardware runs.



## Simulation in Altera Questa

First compile all the .sv files in the root and tb/ directory in Questa. then run the following commands.


```tcl
vopt +acc work.RISCV_tb -o RISCV_tb_opt
vsim work.RISCV_tb_opt
```

Then add all the signals in the region to the waveform and run the simulation for amount of time you want. 

<img width="2519" height="1137" alt="Image" src="https://github.com/user-attachments/assets/1d62e976-8be0-4b52-b8b2-af0460dcfeb2" />

## Build and Program FPGA (Quartus)


1. Open Quartus Prime.
2. Open project: `RISCV.qpf`.
3. Confirm top-level entity is `RISCV_FPGA`.
4. Compile the design.
5. Open Programmer and download the generated `.sof` to DE2-115.

https://github.com/user-attachments/assets/06d0a02c-f4a9-4740-9455-2a6b1824d1a1

## Board I/O Mapping

When compiling on Quartus make sure the top entity is the RISC-FPGA wrapper, it has the following assignments:

- Clock:
  - `CLOCK_50` drives the FPGA wrapper clock divider.
- Reset:
  - `KEY[1]` is used as active-low reset to the wrapper/core.
- Output:
  - `LEDR[17:0]` displays low 18 bits of core register `x10` (`a0`).

## Current Limitations and Notes

- Single-cycle core (no pipeline, no hazard/forwarding complexity).
- Instruction memory is hardcoded in RTL, not external ELF/HEX-loaded.
- Data memory is simple inferred storage with no memory-mapped peripherals.
- Data memory currently ignores address bits above `[15:0]`.



