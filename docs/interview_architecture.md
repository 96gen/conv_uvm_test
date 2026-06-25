# Interview Architecture Guide

## Project in One Sentence

This project uses one reusable UVM environment to validate a two-layer convolution accelerator across clean golden-data runs, reset/liveness scenarios, and expected-fail RTL fault injection.

## Architecture

```mermaid
flowchart LR
    subgraph TOP["top.sv"]
        IF["CONV_IF"]
        DUT["CONV.v or CONV_buggy.v"]
        PC["Procedural protocol checker"]
    end

    subgraph UVM["UVM environment"]
        TEST["Test"]
        SEQ["Sequence + seq_item"]
        AGENT["Agent"]
        DRV["Driver"]
        MON["Monitor"]
        SB["Scoreboard"]
        COV["Coverage"]
        MEM["Layer0 memory model"]
    end

    TEST --> SEQ
    SEQ --> AGENT
    AGENT --> DRV
    DRV --> IF
    IF --> DUT
    DUT --> IF
    IF --> MON
    MON --> SB
    MON --> COV
    MON --> MEM
    MEM --> IF
    IF --> PC
```

`CONV_IF` belongs in `top.sv`, not inside the agent. It represents the physical DUT boundary and is distributed to UVM components through `uvm_config_db`.

## Responsibility Boundaries

| Layer | Files | Responsibility |
|---|---|---|
| Scenario control | `conv_test.sv`, specialized tests | Select stimulus, duration, expected counts, checker modes, reset/fault scenarios |
| Transaction intent | `conv_seq_item.sv`, sequences | Carry timing, image, drive, and reset controls |
| Active agent | `conv_sequencer.sv`, `conv_driver.sv` | Sequence arbitration and pin-level stimulus |
| Observation | `conv_monitor.sv` | Convert ready/read/write activity into analysis transactions |
| External memory behavior | `conv_l0_mem_model.sv` | Store Layer0 writes and feed pooling reads back to the DUT |
| Data and structural checking | `conv_scoreboard.sv` | Golden compare, count checks, address completeness, duplicate/missing detection |
| Protocol and liveness checking | `conv_assertions.sv` | Reset rules, csel legality, address range, ready/busy exclusion, bounded response |
| Reach tracking | `conv_coverage.sv` | Transaction-level ready/read/write counters |
| Automation | `run_smoke.ps1`, `run_final_regression.ps1` | Compile selection, expected signatures, exact error gates, final matrix |

## Data Path

1. The driver loads `cnn_sti.dat`.
2. At each stable address boundary, it drives `idata` from the DUT's `iaddr`.
3. Layer0 writes are observed and stored by the memory model.
4. Pooling reads are served through `cdata_rd`.
5. The monitor publishes write/read transactions.
6. The scoreboard compares Layer0 and Layer1 writes against supplied golden files.
7. Address bitmaps prove completeness and detect duplicate/missing locations.

## Control and Protocol Path

- Reset and ready timing are transaction-controlled.
- Reset-in-flight asserts reset while the DUT is busy, then restarts the same environment.
- The procedural checker samples stable signals at `negedge clk`.
- Reset violations are reported once per reset episode.
- Ready-to-busy liveness starts on a ready request and requires busy within eight cycles.

## Fault-Injection Architecture

The test scenario and DUT implementation are selected independently:

```text
scenario selection: +UVM_TESTNAME=<test class>
DUT selection:       CONV.v or CONV_buggy.v
fault selection:     +define+FI_...
```

`run_smoke.ps1` compiles `CONV.v` for clean cases. A fault case compiles `CONV_buggy.v` with exactly one fault macro. The same monitor, scoreboard, memory model, and protocol checker validate both versions.

This separation is important: a fault test passes only when the intended checker signature appears with the exact expected UVM error count and zero UVM fatals.

## Strong Interview Claims

- The environment checks real DUT output, not only UVM component connectivity.
- Layer0 and Layer1 are fully compared against golden datasets.
- Total transaction count is not treated as address completeness.
- Reset recovery is followed by a complete Layer1 golden compare.
- Protocol faults and data faults are checked by different verification layers.
- Liveness is bounded, so a stalled DUT produces a deterministic failure instead of a hanging simulation.

## Deliberate Limitations

- `conv_assertions.sv` is a procedural checker, not a formal SVA library.
- Coverage is transaction-level rather than internal FSM/cross coverage.
- Golden closure currently uses one supplied image dataset.
- The scripts target Windows ModelSim ASE and a configured UVM 1.2 path.
