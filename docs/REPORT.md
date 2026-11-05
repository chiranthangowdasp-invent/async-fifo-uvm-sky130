# Design and Verification Report: Asynchronous FIFO

## 1. Design
Parameters: `DATA_WIDTH = 8`, `ADDR_WIDTH = 4` (16 entries). Pointers are 5 bits wide and Gray coded.
Each Gray pointer passes through a two-flop synchronizer into the opposite domain.
- `full` (write domain): next Gray write pointer equals the synchronized read pointer with its two
  top bits inverted.
- `empty` (read domain): next Gray read pointer equals the synchronized write pointer.
- Memory is written on `wclk` when `winc & ~wfull` and is read combinationally (first-word fall-through).

## 2. Verification
### 2.1 Environment
- Simulator: Questa Altera Starter FPGA Edition 2025.3, built-in UVM 1.1d.
- Interface with clocking blocks; separate write and read agents (driver, monitor, sequencer).
- Scoreboard: reference queue. Each accepted write is pushed, each accepted read is popped and compared.
  A read with an empty queue is an error, and entries left unread at the end are an error.
- Monitors report only operations the DUT actually accepted (`winc && !wfull`, `rinc && !rempty`).
- Clock periods are variables in the interface, so a test can change the clock ratio.
- The Starter Edition has no license for `randomize()`, so stimulus uses `$urandom_range`.

### 2.2 Tests and results
| Test | Clocks (write / read) | Writes / reads | Blocked write / read attempts | Sim time | Result |
|---|---|---|---|---|---|
| `basic_rw_test` | 100 / 76.9 MHz | 8 / 8 | 0 / 0 | 717.5 ns | Pass |
| `fill_full_test` | 100 / 76.9 MHz | 16 / 16 | 3 / 0 | 1432.5 ns | Pass |
| `drain_empty_test` | 100 / 76.9 MHz | 10 / 10 | 0 / 3 | 1276.5 ns | Pass |
| `fast_write_slow_read_test` | 250 / 50 MHz | 64 / 64 | 441 / 3 | 3526 ns | Pass |
| `slow_write_fast_read_reset_test` | 50 / 250 MHz | 50 / 40 | 0 / 445 | 3334 ns | Pass |

All tests: 0 scoreboard errors, `UVM_ERROR : 0`, `UVM_FATAL : 0`.

Checks per test:
- Data integrity and ordering: every test (scoreboard).
- Flag behaviour: `wfull` and `rempty` are checked at defined points (after reset, after fill, after drain).
- Overflow and underflow protection: forced operations on a full or empty FIFO are counted by the
  blocked-attempt counters (3 each in `fill_full_test` and `drain_empty_test`), and the data read
  afterwards is intact.
- Reset: in `slow_write_fast_read_reset_test`, 10 words are written, both domains are reset, the flags
  are checked, and the 8 words written afterwards are read back with no stale data. The 10 discarded
  words explain 50 writes versus 40 reads.

### 2.3 Findings during verification
1. **Driver alignment bug.** `drain_empty_test` first showed 9 writes / 9 reads instead of the intended
   10 / 10. Clocking-block drives take effect one skew after the next clock edge, so the first item of
   a sequence that started mid-cycle with zero idle cycles was judged accepted one edge too early and
   never reached the DUT. Fix: the test helper tasks align sequence start to a clock edge. After the
   fix the test shows 10 / 10 and the previously missing word appears.
2. **Blocked-attempt counters.** Added to the interface so that "the FIFO blocked it" is shown by
   evidence in the logs rather than assumed.

## 3. Physical implementation
- Flow: LibreLane 3.0.17 (Classic flow, Docker), SKY130 sky130A, standard cells `sky130_fd_sc_hd`.
- Constraints (`librelane/fifo.sdc`): `wclk` 10 ns, `rclk` 13 ns, asynchronous clock groups,
  2 ns input and output delays.
- Results (`docs/results/metrics.json`):

| Metric | Value |
|---|---|
| Die bounding box | 0 0 128.975 139.695 um |
| Core bounding box | 5.52 10.88 123.28 127.84 um |
| Core utilization | 58.2% |
| Instance count | 2395 |
| Worst setup slack | +3.79 ns (ss, 100 C, 1.60 V) |
| Worst hold slack | +0.226 ns (ff, -40 C, 1.95 V) |
| Estimated total power | 3.27 mW (default switching activity, indicative only) |
| DRC / LVS / antenna | Pass / Pass / Pass |

Setup and hold slack are positive at all analysed corners (tt, ss, ff with min, nominal and max
parasitics). The flow reported 4 lint warnings (`docs/results/lint.log`).

## 4. Limitations and future work
- Add functional coverage (fill levels, clock ratios, back-to-back traffic, reset timing).
- Add SystemVerilog assertions: Gray pointers change by one bit, `full` and `empty` never both active
  incorrectly, no overflow or underflow.
- Reset while operations are in flight.
- CDC lint, plus a bounded-delay constraint on the Gray pointer crossings (the current SDC leaves them untimed).
- Gate-level simulation with SDF back-annotation.
- Power analysis with simulation-derived switching activity.
