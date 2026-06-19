# CONV UVM Smoke Testbench

This repository is a staged rebuild of a CONV UVM testbench. The current goal is not full DUT functional verification yet. The goal is to prove that the UVM architecture is wired correctly, configurable by test scenario, and able to catch expected checker failures.

## Current Architecture

```text
top.sv
  -> CONV DUT
  -> CONV_IF
  -> uvm_config_db virtual interface

conv_test
  -> conv_env
      -> conv_agent
          -> conv_sequencer
          -> conv_driver
          -> conv_monitor
      -> conv_scoreboard
      -> conv_coverage
```

The sequence creates `conv_seq_item` transactions. The driver consumes the item fields to control reset and ready timing. The monitor observes ready rising edges and publishes analysis transactions. The scoreboard checks each observed transaction and also performs an end-of-test count check. Coverage tracks and reports the number of ready transactions sampled.

## Smoke Regression

Run the full smoke regression with ModelSim:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_smoke.ps1
```

Run one case at a time:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_smoke.ps1 -Test clean
powershell -ExecutionPolicy Bypass -File .\run_smoke.ps1 -Test short
powershell -ExecutionPolicy Bypass -File .\run_smoke.ps1 -Test long
powershell -ExecutionPolicy Bypass -File .\run_smoke.ps1 -Test negative
```

Reports are written under:

```text
reports/smoke_<timestamp>/
```

## Passing Smoke Cases

```text
clean smoke              conv_test                 expected ready count = 3
short scenario smoke     conv_short_ready_test     expected ready count = 1
long scenario smoke      conv_long_ready_test      expected ready count = 5
negative checker smoke   conv_bad_ready_test       expected UVM_ERROR count = 3
```

The regression expects the negative checker smoke to report three scoreboard errors. That case is considered passing because it proves the checker is active and catches bad monitor transactions.

## What Is Proven

- Virtual interface delivery from `top.sv` into UVM components works.
- The same environment, agent, driver, monitor, scoreboard, and coverage are reused across multiple tests.
- Tests configure scenario size through `item_count` and `expected_ready_count`.
- `conv_basic_sequence` generates a configurable number of transactions.
- `conv_driver` consumes `conv_seq_item` timing fields instead of hardcoding the whole handshake.
- `conv_monitor` converts ready rising edges into analysis transactions.
- `conv_scoreboard` performs per-transaction checks and end-of-test observed-count closure.
- `conv_coverage` samples ready transactions and reports final coverage count.
- Negative smoke proves the scoreboard can fail when the observed transaction is intentionally marked bad.

## Not Yet Proven

- DUT convolution correctness is not checked against golden `.dat` outputs yet.
- Image/data stimulus fields are not connected into `conv_seq_item` yet.
- `top.sv` still has a TODO to convert DUT positional port connections to named connections.
- The current coverage is smoke-level event counting, not full functional coverage closure.

## Next Direction

The next technical milestone should connect real stimulus intent into `conv_seq_item`, such as an image file, mode field, or control fields that prepare the testbench for `.dat`-based functional checking.
