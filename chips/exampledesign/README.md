# 00-librelane-chip

**Author:** Course Staff

## Description

Example chip featuring two independent 8-bit binary counters running in parallel. Both counters share a common clock and reset, and their outputs are routed to the chip's I/O pads. This design serves as a reference submission for the course — it does not implement any specific application.

## Pin List

| Pin | Direction | Description |
|---|---|---|
| `io_clock` | Input | Main clock |
| `io_reset` | Input | Synchronous reset (active high) |
| `uo[0]` | Output | Counter 0 — bit 0 |
| `uo[1]` | Output | Counter 0 — bit 1 |
| `uo[2]` | Output | Counter 0 — bit 2 |
| `uo[3]` | Output | Counter 0 — bit 3 |
| `uo[4]` | Output | Counter 0 — bit 4 |
| `uo[5]` | Output | Counter 0 — bit 5 |
| `uo[6]` | Output | Counter 0 — bit 6 |
| `uo[7]` | Output | Counter 0 — bit 7 |
| `uo[8]` | Output | Counter 1 — bit 0 |
| `uo[9]` | Output | Counter 1 — bit 1 |
| `uo[10]` | Output | Counter 1 — bit 2 |
| `uo[11]` | Output | Counter 1 — bit 3 |
| `uo[12]` | Output | Counter 1 — bit 4 |
| `uo[13]` | Output | Counter 1 — bit 5 |
| `uo[14]` | Output | Counter 1 — bit 6 |
| `uo[15]` | Output | Counter 1 — bit 7 |