# 08-radiation-hardening

**Author:** Benjamin Hecker, Christopher Wegener, Paul Linke, Simon Neumeier

## Description

Radiation-tolerant Sun-Tracking processor designed for CubeSat scenarios. The chip computes the sun direction from six brightness sensor inputs and provides the result through memory-mapped registers.

To achieve robustness against Single-Event Upsets, the core computation and control logic are protected using Triple Modular Redundancy (TMR) with majority voting and mismatch detection. In addition, Cyclic Redundancy Checks (CRC) secure input and output data to detect transmission or storage corruption.

The design supports controlled start/ready semantics, status flag reporting (including mismatch and uncorrectable states), and is fully synthesizable. It is intended for integration into the PULP Croc SoC and supports FPGA prototyping and end-to-end system validation via software-controlled register access.

## Project Repository

[LRZ-Gitlab Link to Project](https://gitlab.lrz.de/000000003B9CCC7D/DesignYourOwnChip)

This link points to the internal project repository (HM students only) containing the full source code of our group submission, including RTL, verification, and integration files for the block module.

## Pin List - Chip

| Pin | Direction | Description |
|---|---|---|
| `clk_PAD` | Input | Main clock |
| `rst_n_PAD` | Input | Asynchronous reset (active low) |
| `in_valid_PAD` | Input | Input data valid (asserted when `in_data_PADs` is valid) |
| `in_data_PADs[7:0]` | Input | 8-bit input data bus |
| `in_ready_PAD` | Output | Input ready (chip can accept data when high) |
| `out_valid_PAD` | Output | Output data valid (asserted when `out_data_PADs` is valid) |
| `out_ready_PAD` | Input | Output ready (receiver can accept data when high) |
| `out_data_PADs[7:0]` | Output | 8-bit output data bus |
||||
| `IOVDD` | Inout | I/O supply |
| `IOVSS` | Inout | I/O ground |
| `VDD` | Inout | Core supply |
| `VSS` | Inout | Core ground |

### Streaming Interface (`top.sv` to `chip.sv`)

`top.sv` only instantiates IO pad cells and connects them to the core module `chip.sv`.  
All functionality (CRC checking, TMR-protected computation, and result generation) is implemented in `chip.sv`.

#### Input Stream (`in_valid`, `in_ready`, `in_data`)

The core expects **7 input bytes** in the following order:

| Byte Index | Signal / Name | Description |
|---:|---|---|
| 0 | `BplusX` | Brightness sensor +X (signed 8-bit) |
| 1 | `BminX`  | Brightness sensor −X (signed 8-bit) |
| 2 | `BplusY` | Brightness sensor +Y (signed 8-bit) |
| 3 | `BminY`  | Brightness sensor −Y (signed 8-bit) |
| 4 | `BplusZ` | Brightness sensor +Z (signed 8-bit) |
| 5 | `BminZ`  | Brightness sensor −Z (signed 8-bit) |
| 6 | `crc_in` | CRC-8 over bytes 0..5 |

#### Output Stream (`out_valid`, `out_ready`, `out_data`)

After successful input CRC verification and computation, the core outputs **6 bytes**:

| Byte Index | Signal / Name | Description |
|---:|---|---|
| 0 | `psi_hi` | `omegaPsi[15:8]` (high byte) |
| 1 | `psi_lo` | `omegaPsi[7:0]` (low byte) |
| 2 | `th_hi`  | `omegaTheta[15:8]` (high byte) |
| 3 | `th_lo`  | `omegaTheta[7:0]` (low byte) |
| 4 | `crc_out` | CRC-8 over bytes 0..3 (Psi/Theta payload) |
| 5 | `flags` | Status/flags byte (see below) |

#### Flags Byte Layout (`out_buf[5]`)

The last output byte encodes status bits:

| Bit | Name | Meaning |
|---:|---|---|
| 0 | `crc_ok` | 1 if input CRC matched (`crc1_out == crc_in`) |
| 1 | `error_crc` | 1 if input CRC mismatch detected |
| 2 | `error_voter` | 1 if TMR mismatch detected (`tmr_mismatch`) |
| 3 | `error_uncorrectable` | 1 if TMR reported uncorrectable (`tmr_uncorrectable`) |
| 7:4 | — | Reserved (0) |

### Handshake Protocol

Data is transferred using a valid/ready handshake.  
An input byte is accepted when `in_valid_PAD` and `in_ready_PAD` are high in the same clock cycle.  
An output byte is transferred when `out_valid_PAD` and `out_ready_PAD` are high simultaneously.

## Pin List - Croc SoC (croctop)

> [!IMPORTANT]  
> ⚠️ At the time of submission, the SoC still contains known issues in the physical design flow (see _Notes_ section)

| Pin | Direction | Description |
|---|---|---|
| `clk_i` | Input | Main SoC clock |
| `rst_ni` | Input | Reset (active low) |
| `ref_clk_i` | Input | Reference clock input |
| `jtag_inputs_PAD[3:0]` | Input | JTAG inputs `{tck, trst_ni, tms, tdi}` |
| `jtag_tdo_o` | Output | JTAG TDO output |
| `uart_rx_i` | Input | UART receive |
| `uart_tx_o` | Output | UART transmit |
| `fetch_en_i` | Input | Fetch enable (starts CPU instruction fetch) |
| `status_o` | Output | SoC status output |
| `gpio_io[31:0]` | Inout | 32 GPIO pins (direction controlled by SoC) |
| `unused_o[3:0]` | Output | Unused outputs (reserved / not connected) |
||||
| `IOVDD` | Inout | I/O supply |
| `IOVSS` | Inout | I/O ground |
| `VDD` | Inout | Core supply |
| `VSS` | Inout | Core ground |

### Notes

The JTAG inputs are provided as a 4-bit bus and mapped as `{tck, trst_ni, tms, tdi}`.  
GPIO pins are bidirectional: each bit of `gpio_io` acts as input or output depending on the SoC-controlled output-enable.

The Croc SoC must be built using [IHK Open PDK PR 819](https://github.com/IHP-GmbH/IHP-Open-PDK/pull/819), otherwise the physical design run produces 4000+ DRC errors.  

At the time of submission, the SoC still contains known issues in the physical design flow. We were not able to validate the full SoC on the target FPGA board (Arty A7-100T) before the course ended. However, the end-to-end SoC functionality was successfully verified in simulation using Verilator.