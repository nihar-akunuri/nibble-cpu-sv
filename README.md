# Nibble CPU — RTL Design & SystemVerilog Verification

A nibble-serial interface controls a 32-bit command-driven CPU with a 4,096-word memory space. This repository contains the RTL implementation and a class-based SystemVerilog verification environment built around randomized transactions, a driver/monitor flow, a reference-model scoreboard, and functional coverage.

The testbench evolved incrementally: it began as a basic Verilog testbench, and new features and verification capabilities were added week by week. That gradual development transformed it into the fully SystemVerilog-based testbench available in the repository today.

> **Project scope:** This is a custom nibble-programmed CPU, not a RISC-V processor. The verification environment uses SystemVerilog classes and mailboxes.

## Contents

- [Highlights](#highlights)
- [Architecture](#architecture)
- [Command set](#command-set)
- [Repository layout](#repository-layout)
- [Verification environment](#verification-environment)
- [Simulation and coverage](#simulation-and-coverage)
- [Tools](#tools)

## Highlights

- 4-bit serial programming input and 4-bit serial result output.
- 12-bit address bus, giving 4,096 addressable memory locations.
- 32-bit data path and memory words.
- Command controller implemented as a finite-state machine.
- RTL split into serial input handling, command execution, output serialization, completion signalling, and memory model.
- Class-based testbench with constrained-random transactions, mailboxes, and a self-checking scoreboard.
- Functional coverage for command opcodes, operand values, address ranges, overflow-related cases, and selected opcode/operand/address crosses.

## Architecture

The top-level module is `rtl/cpu_top.sv`. It connects the following blocks:

| RTL file | Responsibility |
|---|---|
| `rtl/cpu_top.sv` | Integrates the CPU interface, command controller, output serializer, and completion generator. |
| `rtl/serial_interface.sv` | Collects incoming nibbles and assembles an address, command, and 32-bit data field into a command frame. |
| `rtl/cmd_controller.sv` | Decodes commands, controls execution and memory accesses, and reports result/error status. |
| `rtl/output_serializer.sv` | Serializes a 32-bit result onto the 4-bit output, least-significant nibble first. |
| `rtl/done_generator.sv` | Generates the command-completion indication. |
| `rtl/memory_model.sv` | Simulation memory model containing 4,096 32-bit words. |

### Command frame

The input interface assembles a 13-nibble frame:

| Field | Width | Meaning |
|---|---:|---|
| Address | 12 bits (3 nibbles) | Memory address associated with the command |
| Command | 8 bits (2 nibbles) | Operation code |
| Data | 32 bits (8 nibbles) | Data payload |

The RTL receives address, command, and data nibbles least-significant nibble first. A 32-bit serialized result is emitted as eight 4-bit nibbles, also least-significant nibble first.

The memory model is a simulation model, not a claim of a synthesized SRAM macro.

## Command set

The command opcodes are defined in `rtl/cmd_controller.sv` and mirrored as an enum in `testbench/nibble_cpu_tb_pkg.sv`.

| Opcode | Operation | Description |
|---|---|---|
| `0x00` | `FILL0` | Fill memory from the specified address with zeroes. |
| `0x01` | `FILL1` | Fill memory from the specified address with ones (`0xFFFFFFFF`). |
| `0x02` | `WRITE` | Write a 32-bit word to an address. |
| `0x03` | `READ` | Read a word from an address. |
| `0x04` | `WRITE_INC` | Write while incrementing the address. |
| `0x05` | `READ_SEQ` | Read a sequence of memory locations. |
| `0x06` | `INC_ACC` | Increment operation supported by the command controller. |
| `0x10` | `ADD` | Addition. |
| `0x11` | `SUB` | Subtraction. |
| `0x12` | `MUL` | Multiplication; the implementation uses two words for the 64-bit product. |
| `0x13` | `DIV` | Division; the implementation also handles a remainder word and division-by-zero error. |
| `0x14` | `INV` | Bitwise inversion. |
| `0x15` | `AND` | Bitwise AND. |
| `0x16` | `OR` | Bitwise OR. |
| `0x17` | `XOR` | Bitwise XOR. |

For the arithmetic/logical operations, the testbench driver writes the operands to adjacent memory addresses, issues the operation, and reads back the result. Check the RTL and testbench before relying on boundary-address behavior or assuming every command is included in the current random regression.

## Repository layout

```text
.
├── rtl/
│   ├── cmd_controller.sv
│   ├── cpu_top.sv
│   ├── done_generator.sv
│   ├── memory_model.sv
│   ├── output_serializer.sv
│   └── serial_interface.sv
├── testbench/
│   ├── Makefile
│   ├── nibble_cpu_tb_pkg.sv
│   ├── transactor.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── coverage.sv
│   ├── environment.sv
│   ├── prog_if.sv
│   ├── mem_if.sv
│   ├── test_random.sv
│   └── tb_top.sv
├── CPU Specification.pdf
└── README.md
```

## Verification environment

The verification code is under `testbench/` and is organized into reusable class-based components:

- **Transactor** — stores randomized command, address, and operand fields; calculates expected metadata.
- **Generator** — creates transactions and distributes them to the driver, scoreboard, and coverage path through mailboxes.
- **Driver** — converts a transaction into serial command frames and drives the programming interface.
- **Monitor** — captures the serialized result from the DUT and sends observations to the scoreboard.
- **Scoreboard** — predicts expected operation results using a reference model and compares them with observed results.
- **Coverage** — samples command opcodes, operand/address ranges, special data patterns, overflow-related cases, and selected cross coverage.
- **Environment** — constructs the components and mailboxes and coordinates reset, test execution, and end-of-test reporting.
- **`test_random`** — configures the current randomized test to generate 1,000 transactions.

The current constrained-random transaction constraint allows `ADD`, `SUB`, `MUL`, `DIV`, `AND`, `OR`, `XOR`, `WRITE`, `READ`, `FILL0`, and `FILL1`. Although additional commands exist in the RTL and some testbench code, they are not all enabled by the current random transaction constraint.

## Simulation and coverage

The testbench has been simulated using **QuestaSim**, and the simulation runs successfully with the testbench passing. The checked-in `testbench/Makefile` targets QuestaSim/ModelSim and defines these targets:

| Target | Purpose |
|---|---|
| `make comp_basic` | Compile the basic test configuration. |
| `make comp_rand` | Compile with `+define+RAND`. |
| `make run` | Compile and run `work.tb_top` in command-line mode. |
| `make run_rand` | Compile with the randomization define and run `work.tb_top`. |
| `make gui` | Compile and launch the GUI target defined in the Makefile. |
| `make gui_rand` | Compile with the randomization define and launch the GUI target. |
| `make covreport` | Generate reports from the expected Questa coverage database. |
| `make clean` | Remove the work library and selected simulation outputs. |
| `make help` | Print the targets documented by the Makefile. |

The Makefile sets the default seed to `500`; it can be overridden, for example, with `make run SEED=123`. Coverage reporting expects a database named `coverage_<SEED>.ucdb`.

Run the simulation using the project setup and Makefile targets described above. The exact invocation depends on the working directory and how the source paths are configured in your local QuestaSim workspace.

## Tools

- **Language:** Verilog/SystemVerilog
- **Simulator used:** QuestaSim
- **Build orchestration:** GNU Make
- **Verification techniques:** class-based testbench, constrained randomization, mailboxes, reference-model checking, functional coverage
