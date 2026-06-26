# Final Verification Record

## Release Candidate

- Verification completed: 2026-06-26 18:36:18 +08:00
- Tested source baseline: `63c0bcb` (`Add high-value and border-sensitive datasets`) plus the staged final-regression/documentation updates in this release commit
- Simulator: ModelSim Intel FPGA Edition 10.5b
- UVM: UVM 1.2 with `UVM_NO_DPI`
- Command:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_final_regression.ps1 -MaxAttempts 2
```

The release candidate passed all 19 ordered regression gates. Every case passed
on its first attempt, so the simulator retry path was not needed.

## Result Matrix

| Group | Test | Result | Attempts |
|---|---|---:|---:|
| Base | `all` | PASS | 1 |
| Golden | `l0_expected` | PASS | 1 |
| Golden | `l1_expected` | PASS | 1 |
| Dataset | `zero_dataset` | PASS | 1 |
| Dataset | `high_value_dataset` | PASS | 1 |
| Dataset | `border_dataset` | PASS | 1 |
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

Overall result: **PASS (19/19)** with zero failed gates.

## Evidence Anchors

The local regression report is stored at:

```text
reports/final_20260626_180903/final_regression_summary.md
```

Representative checker evidence includes:

- Supplied Layer0 golden comparison: `layer0 expected compare passed count=4096`.
- Supplied Layer1 golden comparison: `layer1 expected compare passed count=1024`.
- Generated zero dataset: Layer0 4096/4096 and Layer1 1024/1024 golden compare.
- High-value and border-sensitive generated datasets: `layer1 address map passed unique=1024 expected=1024`.
- SVA-backed protocol faults:
  `[SVA_CWR_ILLEGAL_CSEL]`, `[SVA_L1_ADDR_OOB]`,
  `[SVA_RESET_CWR]`, and `[SVA_READY_BUSY_TIMEOUT]`.
- Expected-fail cases require `fault_class=<name> id=<id> covered` and `UVM_FATAL : 0`.

Generated reports, generated datasets, simulator libraries, and logs remain
local under `reports/` and are excluded from Git.

## Release Note

The final source update adds SVA checker hooks, covergroup-ready coverage with a
ModelSim counter fallback, dataset-root plumbing, generated dataset smoke cases,
and updated interview documentation. It does not modify `CONV.v` or the checked-in
`.dat` files.
