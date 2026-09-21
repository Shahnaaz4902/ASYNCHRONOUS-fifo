# Asynchronous FIFO — Verilog RTL

A parameterized **asynchronous FIFO (Async FIFO)** implemented in Verilog for reliable data transfer between two independent clock domains.

The design uses **Gray-coded read/write pointers** and **two-flop synchronizers** to safely communicate FIFO status information across asynchronous clock domains.

## Features

- Asynchronous FIFO with independent read and write clocks
- Parameterized data width and FIFO depth
- Default data width: **8 bits**
- Default address width: **4 bits**
- Default FIFO depth: **16 entries**
- Independent read and write reset signals
- Gray-code pointer synchronization
- Two-stage clock-domain synchronizers
- Full and empty flag generation
- Separate read and write control logic
- Synthesizable Verilog RTL
- Self-contained simulation testbench
- Tested with different read/write clock frequencies

## Architecture

```text
                         WRITE CLOCK DOMAIN
                    +-------------------------+
                    |                         |
      wdata ------->|      FIFO Memory        |
      winc -------->|                         |
                    +------------+------------+
                                 ^
                                 |
                              waddr
                                 |
                    +------------+------------+
                    |   Write Pointer &       |
                    |   FULL Generation      |
                    +------------+------------+
                                 |
                              wptr
                                 |
                         +-------+-------+
                         | 2-FF Sync     |
                         | Write -> Read |
                         +-------+-------+
                                 |
                                 v

                    +-------------------------+
                    |      FIFO Memory        |
                    |                         |
                    +-------------------------+
                                 |
                              rdata
                                 |
                    +------------+------------+
                    |   Read Pointer &        |
                    |   EMPTY Generation     |
                    +------------+------------+
                                 |
                              rptr
                                 |
                         +-------+-------+
                         | 2-FF Sync     |
                         | Read -> Write |
                         +-------+-------+

                          READ CLOCK DOMAIN
```

## FIFO Parameters

The top-level FIFO is parameterized as:

```verilog
module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)
```

For the default configuration:

| Parameter | Value |
|---|---:|
| Data width | 8 bits |
| Address width | 4 bits |
| FIFO depth | 16 entries |
| Pointer width | 5 bits |
| Write clock | 10 ns period |
| Read clock | 14 ns period |

FIFO depth is calculated as:

```text
DEPTH = 2^ASIZE
```

Therefore:

```text
ASIZE = 4
DEPTH = 16
```

## Why Gray Code?

The read and write pointers operate in different clock domains.

Directly transferring a multi-bit binary counter between asynchronous clock domains can result in multiple bits changing simultaneously and potentially being sampled inconsistently.

This design converts the binary pointer to Gray code:

```text
Gray = Binary ^ (Binary >> 1)
```

Only one bit changes between consecutive Gray-code values, reducing the risk of an invalid intermediate pointer being observed by the receiving clock domain.

## Clock-Domain Crossing

The read pointer is synchronized into the write clock domain:

```text
Read Pointer
     |
     v
+-----------+
| Flip-Flop |
+-----------+
     |
     v
+-----------+
| Flip-Flop |
+-----------+
     |
     v
Write Clock Domain
```

Similarly, the write pointer is synchronized into the read clock domain.

The project uses dedicated modules:

- `sync_r2w.v`
- `sync_w2r.v`

Each implements a two-flop synchronizer.

## Empty Detection

The FIFO is empty when the next read pointer equals the synchronized write pointer.

Conceptually:

```text
next_read_gray == synchronized_write_gray
```

When the FIFO is empty:

```text
rempty = 1
```

A read request is ignored while `rempty` is asserted.

## Full Detection

The FIFO is full when the next write pointer reaches the synchronized read pointer with the appropriate Gray-code MSB inversion.

Conceptually:

```text
next_write_gray ==
{~read_ptr[MSBs], read_ptr[remaining_bits]}
```

When the FIFO is full:

```text
wfull = 1
```

A write request is ignored while `wfull` is asserted.

## Project Structure

```text
asyn_fifo/
│
├── async_fifo.v
├── fifo_mem.v
├── rptr_empty.v
├── wptr_full.v
├── sync_r2w.v
├── sync_w2r.v
├── async_fifo_tb.v
│
├── async_fifo.qpf
├── async_fifo.qsf
│
└── output_design/
    └── simulation / design screenshots
```

## Module Description

### `async_fifo.v`

Top-level asynchronous FIFO module.

It connects:

- FIFO memory
- Read-pointer/empty logic
- Write-pointer/full logic
- Read-to-write pointer synchronizer
- Write-to-read pointer synchronizer

### `fifo_mem.v`

Implements the FIFO storage.

- Write operation occurs on `wclk`
- Read data is selected using the read address
- Write is enabled only when `winc` is asserted and FIFO is not full

### `wptr_full.v`

Implements:

- Binary write pointer
- Gray-coded write pointer
- Write address generation
- Full-flag generation

### `rptr_empty.v`

Implements:

- Binary read pointer
- Gray-coded read pointer
- Read address generation
- Empty-flag generation

### `sync_r2w.v`

Two-flop synchronizer for transferring the Gray-coded read pointer into the write-clock domain.

### `sync_w2r.v`

Two-flop synchronizer for transferring the Gray-coded write pointer into the read-clock domain.

### `async_fifo_tb.v`

Simulation testbench that generates independent read/write clocks and exercises the FIFO under different operating conditions.

## Verification

The testbench uses two independent clocks:

```text
Write Clock:
10 ns period

Read Clock:
14 ns period
```

The different clock frequencies create asynchronous clock domains.

### Test 1 — Write Data

Eight values are written into the FIFO:

```text
A0
A1
A2
A3
A4
A5
A6
A7
```

### Test 2 — Read Data

The previously written values are read from the FIFO to verify FIFO ordering.

### Test 3 — Fill FIFO

The FIFO is filled with 16 entries:

```text
0 ... 15
```

The testbench then checks:

```text
FIFO FULL = 1
```

### Test 4 — Empty FIFO

All 16 entries are read out.

The testbench then checks:

```text
FIFO EMPTY = 1
```

## Simulation

### Questa / ModelSim

Compile the Verilog files:

```tcl
vlog async_fifo.v
vlog fifo_mem.v
vlog rptr_empty.v
vlog wptr_full.v
vlog sync_r2w.v
vlog sync_w2r.v
vlog async_fifo_tb.v
```

Start the simulation:

```tcl
vsim async_fifo_tb
```

Run the complete test:

```tcl
run -all
```

The testbench prints FIFO activity and status information to the simulator console.

## Expected Behavior

During simulation, the monitor displays:

```text
TIME | WCLK | RCLK | WINC | RINC | FULL | EMPTY
```

Example:

```text
TIME=... | WCLK=1 | RCLK=0 | WINC=1 | RINC=0 | FULL=0 | EMPTY=0
```

The final verification sequence checks that:

1. Data can be written using the write clock.
2. Data can be read using the independent read clock.
3. FIFO ordering is maintained.
4. Writes are blocked when the FIFO is full.
5. Reads are blocked when the FIFO is empty.
6. Full and empty flags respond correctly to pointer movement.

## Key RTL Concepts Demonstrated

- Asynchronous FIFO architecture
- Clock-domain crossing (CDC)
- Gray-code counters
- Binary-to-Gray conversion
- Two-flop synchronizers
- FIFO full/empty detection
- Independent clock domains
- Parameterized RTL
- Memory modeling
- Reset handling
- Synthesizable Verilog
- Self-contained testbench verification

## Tools Used

- Verilog HDL
- Intel Quartus Prime
- Questa / ModelSim
- VCD/waveform-based simulation

## Possible Improvements

Future versions could include:

- Synchronous read memory implementation
- Programmable almost-full flag
- Programmable almost-empty flag
- Independent FIFO reset synchronization
- Assertion-based verification
- Randomized constrained testing
- Formal CDC verification
- AXI-Stream interface
- Parameterized reset behavior
- Additional data-integrity scoreboarding

## Author

**Shahnaaz Parveen**

M.Tech — Electrical Engineering  
Digital Design | RTL | Computer Architecture
