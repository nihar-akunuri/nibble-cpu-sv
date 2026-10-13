# Nibble CPU — RTL Design & SystemVerilog Verification

A nibble-serial interface controls a 32-bit command-driven CPU with a 4,096-word memory space. This repository contains the RTL implementation and a class-based SystemVerilog verification environment built around randomized transactions, a driver/monitor flow, a reference-model scoreboard, and functional coverage.

> **Project scope:** This is a custom nibble-programmed CPU, not a RISC-V processor. The verification environment uses SystemVerilog classes and mailboxes; it is not currently a UVM environment.

## Contents

- [Highlights](#highlights)
- [Architecture](#architecture)
- [Command set](#command-set)
- [Repository layout](#repository-layout)
- [Verification environment](#verification-environment)
- [Simulation and coverage](#simulation-and-coverage)
- [Known setup note](#known-setup-note)
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

The checked-in `testbench/Makefile` targets Mentor Questa/ModelSim and defines these targets:

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

### Important: current Makefile paths

The repository keeps RTL sources in `rtl/` and testbench sources in `testbench/`, while the checked-in Makefile lists source files by bare filenames and says they should be in the current directory. Consequently, the Makefile commands may need source-path/include-path adjustments to work directly from this repository layout. The README documents the existing setup; it does not imply that the current Makefile has been validated or repaired.

No simulation result or coverage percentage is claimed here. Run the regression in your installed simulator and inspect its logs and coverage reports to confirm the current status.

## Tools

- **Language:** Verilog/SystemVerilog
- **Intended simulator:** Mentor QuestaSim / ModelSim
- **Build orchestration:** GNU Make
- **Verification techniques:** class-based testbench, constrained randomization, mailboxes, reference-model checking, functional coverage
