# Parameterized UART IP Core

A parameterized, synthesizable UART IP core designed in Verilog RTL.

The project includes a configurable baud-rate generator, UART transmitter,
UART receiver, self-checking verification environments, TX-to-RX loopback
verification, and Xilinx Vivado synthesis analysis.

## Current Status

- RTL Design: Complete
- TX Verification: Complete
- RX Verification: Complete
- TX-RX Loopback: Verified
- Behavioral Simulation: Passed
- Synthesis: Complete
- Synthesized Schematic: Verified
- Implementation: Complete

## Key Features

- Parameterized data width
- Parameterized baud rate
- Configurable parity
- Configurable stop bits
- UART TX FSM
- UART RX FSM
- RX input synchronization
- Mid-bit sampling
- Parity error detection
- Framing error detection
- Self-checking Verilog testbenches
- TX-to-RX loopback verification

## Tools

- Verilog HDL
- Xilinx Vivado 2025.2
- Behavioral Simulation
- RTL Synthesis
- Implementation

## Verification Result

The integrated UART top-level testbench successfully verified:

- `0x55`
- `0xAA`
- `0xA5`
- `0x00`

Result:

```text
Tests Executed : 4
Tests Passed   : 4
Tests Failed   : 0
