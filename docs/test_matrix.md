# Verification Test Matrix

## Final Regression

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_final_regression.ps1
```

The final gate contains 16 ordered cases. `run_final_regression.ps1` retries a failed case once by default because ModelSim ASE 10.5b can intermittently crash while loading a design.

## Baseline and Functional Gates

| Order | Test key | DUT | Required proof |
|---:|---|---|---|
| 1 | `all` | `CONV.v` | Eleven base smoke cases pass |
| 2 | `l0_expected` | `CONV.v` | Layer0 golden compare passes 4096/4096 |
| 3 | `l1_expected` | `CONV.v` | Layer1 golden compare passes 1024/1024 |
| 4 | `l0_addr_map` | `CONV.v` | 4096 unique Layer0 addresses |
| 5 | `l1_addr_map` | `CONV.v` | 1024 unique Layer1 addresses |
| 6 | `reset_inflight` | `CONV.v` | Reset during busy, restart, Layer1 golden compare 1024/1024 |
| 7 | `reset_protocol` | `CONV.v` | No `busy/cwr/crd` activity while reset is asserted |
| 8 | `ready_busy_liveness` | `CONV.v` | Busy observed within one cycle after ready |

## Expected-Fail DUT Fault Gates

Expected-fail means the regression case returns PASS only when the intended defect is detected.

| Order | Test key | Compile macro | Expected checker evidence | Expected UVM errors |
|---:|---|---|---|---:|
| 9 | `fault_l0_data` | `FI_BUG1_L0_DATA` | Layer0 mismatch at address 123 and compare failure | 2 |
| 10 | `fault_l1_data` | `FI_BUG2_L1_DATA` | Layer1 mismatch at address 17 and compare failure | 2 |
| 11 | `fault_illegal_csel` | `FI_ASSERT_ILLEGAL_CSEL` | `[CWR_ILLEGAL_CSEL]`, `csel=010` | 1 |
| 12 | `fault_missing_l0` | `FI_BUG3_MISSING_L0` | `[L0_ADDR_MISSING]`, address 123 | 1 |
| 13 | `fault_duplicate_l1` | `FI_BUG4_L1_DUP_ADDR` | Duplicate address 0 and missing address 1 | 2 |
| 14 | `fault_l1_addr_oob` | `FI_ASSERT_L1_ADDR_OOB` | `[L1_ADDR_OOB]`, address 1024 | 1 |
| 15 | `fault_reset_protocol` | `FI_ASSERT_RESET_PROTOCOL` | `[RESET_CWR]` once during reset | 1 |
| 16 | `fault_ready_busy_timeout` | `FI_ASSERT_READY_BUSY_TIMEOUT` | `[READY_BUSY_TIMEOUT]` after eight cycles | 1 |

Every fault gate also requires:

```text
UVM_FATAL : 0
```

## Base `all` Subcases

| Test key | Primary purpose |
|---|---|
| `clean` | Basic reusable environment and three ready transactions |
| `short` | One-item scenario |
| `long` | Five-item scenario |
| `dat` | `.dat` file open and parse |
| `dut_input` | Real `idata` drive using DUT addresses |
| `layer0_write` | Observe Layer0 write path |
| `layer1_path` | Observe Layer0 write/read and Layer1 write |
| `l0_mem_feedback` | Store Layer0 data and serve DUT reads |
| `protocol` | Clean protocol path |
| `protocol_negative` | Inject ready while busy and require `[READY_WHILE_BUSY]` |
| `negative` | Corrupt monitor transactions and require scoreboard errors |

## Checker Ownership

| Defect class | Owner |
|---|---|
| Wrong output data | Golden scoreboard |
| Missing or duplicate address | Address-map scoreboard |
| Illegal `csel`, reset output, address range | Procedural protocol checker |
| Ready accepted without timely busy response | Liveness checker |
| Missing observed transaction | Scoreboard count closure |

## Result Interpretation

- A clean case passes only with its required functional anchors, the exact UVM error count, and `UVM_FATAL : 0`.
- A fault case passes only when its specific checker ID appears.
- A simulator `SIGSEGV` before UVM starts is a tool failure, not a DUT or checker result.
- Per-case logs are under `reports/smoke_<timestamp>/`.
- Final console logs and the matrix summary are under `reports/final_<timestamp>/`.
