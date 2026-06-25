# Final Verification Record

## Release Candidate

- Verification completed: 2026-06-26 07:48:05 +08:00
- Tested commit: `7603212` (`Add interview architecture and debug guides`)
- Simulator: ModelSim Intel FPGA Edition 10.5b
- UVM: UVM 1.2 with `UVM_NO_DPI`
- Command:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_final_regression.ps1
```

The release candidate passed all 16 ordered regression gates. Every case passed
on its first attempt, so the simulator retry path was not needed.

## Result Matrix

| Group | Test | Result | Attempts |
|---|---|---:|---:|
| Base | `all` | PASS | 1 |
| Golden | `l0_expected` | PASS | 1 |
| Golden | `l1_expected` | PASS | 1 |
| Address | `l0_addr_map` | PASS | 1 |
| Address | `l1_addr_map` | PASS | 1 |
| Reset | `reset_inflight` | PASS | 1 |
| Baseline | `reset_protocol` | PASS | 1 |
| Baseline | `ready_busy_liveness` | PASS | 1 |
| Fault | `fault_l0_data` | PASS | 1 |
| Fault | `fault_l1_data` | PASS | 1 |
| Fault | `fault_illegal_csel` | PASS | 1 |
| Fault | `fault_missing_l0` | PASS | 1 |
| Fault | `fault_duplicate_l1` | PASS | 1 |
| Fault | `fault_l1_addr_oob` | PASS | 1 |
| Fault | `fault_reset_protocol` | PASS | 1 |
| Fault | `fault_ready_busy_timeout` | PASS | 1 |

Overall result: **PASS (16/16)** with zero failed gates.

## Evidence Anchors

The local regression report is stored at:

```text
reports/final_20260626_072312/final_regression_summary.md
```

Representative checker evidence includes:

- Layer1 golden comparison: `layer1 expected compare passed 1024`, with
  `UVM_ERROR : 0` and `UVM_FATAL : 0`.
- Duplicate Layer1 fault: `[L1_ADDR_DUPLICATE] address=0` together with
  `[L1_ADDR_MISSING] address=1`, with `UVM_FATAL : 0`.
- Ready-to-busy timeout fault: `[READY_BUSY_TIMEOUT] busy did not assert within
  8 cycles after ready`, with `UVM_FATAL : 0`.
- The clean reset, address-map, protocol, and liveness baselines all completed
  without UVM errors or fatals.

Generated reports and simulator logs remain local under `reports/` and are
excluded from Git. This document records the verified release state without
checking generated artifacts into the repository.

## Release Note

The verification run exercised commit `7603212`. The following release commit
adds only this record and its README link; it does not change RTL, UVM behavior,
test vectors, or expected data.
