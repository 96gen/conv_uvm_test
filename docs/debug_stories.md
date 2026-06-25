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

## Debug Discipline Used Across the Project

1. Separate simulator crashes from UVM failures.
2. Require an exact checker ID, not merely a nonzero error count.
3. Pair every negative test with a clean baseline.
4. Keep expected-fail tests at `UVM_FATAL : 0`.
5. Reuse the same environment for clean and buggy DUT variants.
6. Check end-state correctness after recovery scenarios.
