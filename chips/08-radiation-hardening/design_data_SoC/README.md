# Croc SoC (croctop)

> [!IMPORTANT]  
> ⚠️ The Croc SoC must be built using the link down below.

The Croc SoC must be built using [IHK Open PDK PR 819](https://github.com/IHP-GmbH/IHP-Open-PDK/pull/819), otherwise the physical design run produces 4000+ DRC errors.  

> [!IMPORTANT]  
> ⚠️ At the time of submission, the SoC still contains known issues and is NOT ready for tape-out!

At the time of submission, the SoC still contains known issues in the physical design flow. We were not able to validate the full SoC on the target FPGA board (Arty) before the course ended. However, the end-to-end SoC functionality was successfully verified in simulation using Verilator.

## Pin List

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

## Notes

The JTAG inputs are provided as a 4-bit bus and mapped as `{tck, trst_ni, tms, tdi}`.  
GPIO pins are bidirectional: each bit of `gpio_io` acts as input or output depending on the SoC-controlled output-enable.