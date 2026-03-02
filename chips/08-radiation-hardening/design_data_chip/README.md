# Chip

## Pin List

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