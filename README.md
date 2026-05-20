# Single-Cycle RISC-V CPU Core Design & Verification

## Project Overview
This repository contains the RTL design and verification environment for a 32-bit single-cycle CPU core based on the RISC-V instruction set architecture. The goal of this project was to implement a clean, synthesizable microarchitecture and verify its functional correctness using constrained-random testing.

## Directory Structure
* `rtl/`: Synthesizable Verilog source files (ALU, Control Unit, Register File, Program Counter, Decoder).
* `testbench/`: SystemVerilog-based verification environment including testbench top, virtual interfaces, and test stimulus.
* `docs/`: Contains the complete `CPU Specification.pdf` detailing the block diagrams and architectural design parameters.

## Verification Strategy
The design is verified using a target-driven testbench architecture that applies:
* Directed test cases for basic instruction verification (ALU operations, load/store, conditional branching).
* Constrained-random test sequences to maximize corner-case toggle coverage.
* Self-checking scoreboard mechanisms to automatically validate memory states and architectural register updates against execution results.

## How to Run Simulations
To compile the design and run the test suite locally using an EDA toolchain (e.g., Vivado/ModelSim/VCS), navigate to the testbench directory and execute:
```bash
# Run the complete verification regression suite
make run
