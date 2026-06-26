# Debug Stories for Interviews

## Story 1: Reset Recovery Was Not Enough Until the Post-Reset Result Was Checked

### Initial risk

A reset-in-flight test can appear successful if reset toggles and the simulation ends without a fatal. That proves signal activity, not recovery.

### Verification approach

The driver asserts reset while `busy` is high, holds it for a configured number of cycles, deasserts reset, and sends a new ready pulse. The same environment then runs the complete workload again.

### Evidence

- The driver reports `observed reset during busy`.
- The restart path reports `restart after reset`.
- The monitor and scoreboard observe the second ready transaction.
- Layer1 produces 1024 writes after restart.
- The Layer1 golden comparison passes 1024/1024.

### Engineering lesson

Recovery should be judged by restored end-to-end behavior, not merely by observing reset deassertion.

### Interview version

> I injected reset during active processing, but I did not call the test complete when the FSM returned to idle. I required a full rerun and a 1024-word Layer1 golden comparison after reset. That turned reset testing from a waveform check into a functional recovery proof.

## Story 2: A Correct Write Count Hid a Duplicate Address

### Initial symptom

`FI_BUG4_L1_DUP_ADDR` changes the write intended for Layer1 address 1 into another write to address 0.

The total Layer1 write count remains 1024, so a count-only scoreboard passes.

### Root cause

Count closure answers "how many writes occurred." It does not answer "did every required address occur exactly once."

### Verification approach

The scoreboard maintains a 1024-bit Layer1 address map:

- First observation of an address marks it seen.
- A second observation reports `[L1_ADDR_DUPLICATE]`.
- `check_phase` scans the bitmap and reports `[L1_ADDR_MISSING]`.

### Evidence

```text
observed expected layer1 write count=1024
[L1_ADDR_DUPLICATE] duplicate layer1 write address=0
[L1_ADDR_MISSING] missing layer1 write address=1
unique=1023 duplicate=1 missing=1 expected=1024
```

### Engineering lesson

Volume checks and structural checks are different verification obligations. Both are required.

### Interview version

> One injected bug preserved the exact expected transaction count, so a normal count check was blind. I added an address bitmap and proved the difference between 1024 writes and 1024 unique writes. The checker then identified both sides of the defect: duplicate address 0 and missing address 1.

## Story 3: Liveness Turned a Potential Hang into a Deterministic Failure

### Initial risk

The buggy DUT under `FI_ASSERT_READY_BUSY_TIMEOUT` requires ready to remain high for 121 cycles before asserting busy. A normal one-cycle request is effectively ignored.

Without a liveness rule, the test can wait indefinitely or fail later with a vague missing-output symptom.

### Verification approach

The procedural checker records a ready request while busy is low. It then requires busy to assert within eight cycles:

- Normal DUT: busy is observed within one cycle.
- Fault DUT: `[READY_BUSY_TIMEOUT]` is reported at the eighth cycle.
- Reset clears any pending liveness request.

The dedicated test remains alive for 16 cycles after the ready pulse so the checker has enough time to prove the timeout.

### Evidence

```text
normal: ready-to-busy observed within 1 cycles
fault:  [READY_BUSY_TIMEOUT] busy did not assert within 8 cycles after ready
```

### Engineering lesson

A bounded response rule converts a hang into a local, reproducible, diagnosable protocol failure.

### Interview version

> I treated progress as a protocol requirement. Once ready is accepted as a request, busy must respond within eight cycles even if ready is only a pulse. The clean DUT responded in one cycle, while the injected DUT produced one exact timeout error instead of hanging the regression.

## Story 4: Tool Limits Changed the Checker Implementation, Not the Verification Intent

### Initial risk

The project needed SVA-style protocol evidence, but the local simulator is ModelSim ASE 10.5b. It compiles assertion syntax, yet full concurrent SVA and covergroup runtime features require Questa licenses in this environment.

### Verification approach

The checker was split into two layers:

- `conv_assertions.sv` remains the procedural checker used by the core regression.
- `conv_sva.sv` provides ModelSim-compatible immediate SV assertion hooks with fixed SVA-prefixed IDs.
- `conv_coverage.sv` keeps real covergroup bins behind `CONV_ENABLE_COVERGROUPS`, while local ModelSim runs use the same transaction categories as counter fallback.

### Evidence

The fault regression requires both checker families for selected protocol faults:

```text
CWR illegal csel: [CWR_ILLEGAL_CSEL] and [SVA_CWR_ILLEGAL_CSEL]
Layer1 OOB:       [L1_ADDR_OOB] and [SVA_L1_ADDR_OOB]
Reset protocol:   [RESET_CWR] and [SVA_RESET_CWR]
Ready timeout:    [READY_BUSY_TIMEOUT] and [SVA_READY_BUSY_TIMEOUT]
```

Each expected-fail test also requires:

```text
fault_class=<name> id=<id> covered
```

### Engineering lesson

Good verification work should separate intent from tool mechanics. The project keeps the assertion and coverage architecture visible, but it also keeps the regression runnable on the available simulator.

### Interview version

> I originally reached for concurrent SVA and covergroups, then confirmed that ModelSim ASE would not execute those features without Questa support. Rather than pretend the tool could do something it could not, I kept the SVA and coverage structure but added a ModelSim-compatible runtime path. The regression still proves the intended IDs and fault classes.

## Story 5: Dataset Expansion Was Staged to Avoid Fake Golden Confidence

### Initial risk

Adding more `.dat` inputs is easy. Claiming they are numerically verified is only valid if the expected output is independently trustworthy.

### Verification approach

Dataset support was staged:

- First, `+CONV_DATASET_ROOT` proved the test could select a dataset path.
- Then `zero_dataset` generated input and L0/L1 expected files under `reports/`; zero input has a simple known expected value of `01310` because the DUT still applies bias and rounding.
- Finally, high-value and border-sensitive datasets were added as path/count/address regressions, not as independent numerical golden closure.

### Evidence

```text
zero_dataset:       Layer0 4096/4096 and Layer1 1024/1024 golden compare
high_value_dataset: Layer1 address map passed unique=1024 expected=1024
border_dataset:     Layer1 address map passed unique=1024 expected=1024
```

### Engineering lesson

More data is useful only when the proof level is honest. A dataset can be valuable for path stress before it becomes a golden numerical regression.

### Interview version

> I expanded datasets in two layers. The zero dataset has a real expected-output proof, so it is a golden regression. The high-value and border-sensitive datasets currently prove that the driver, memory feedback, and address map survive new stimulus classes. I would only call them golden after adding an independent reference generator.

## Debug Discipline Used Across the Project

1. Separate simulator crashes from UVM failures.
2. Require an exact checker ID, not merely a nonzero error count.
3. Pair every negative test with a clean baseline.
4. Keep expected-fail tests at `UVM_FATAL : 0`.
5. Reuse the same environment for clean and buggy DUT variants.
6. Check end-state correctness after recovery scenarios.
7. Do not overstate a dataset's proof level.
