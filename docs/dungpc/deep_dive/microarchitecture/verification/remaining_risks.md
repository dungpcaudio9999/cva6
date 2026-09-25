# Remaining Risks and Closure Order

## Critical

1. **No dynamic evidence.** Whole-core compilation succeeded, but Questa simulation cannot obtain a license. None of the level-4 targets is closed.
2. **Reset with outstanding AXI traffic.** Local state resets, while response isolation depends on integration reset/quiescence or an unproven epoch mechanism.
3. **Stale PTW fill around SFENCE.VMA.** Static kill/drain paths exist, but grant/response/flush coincidences need assertion or waveform proof.
4. **Late store errors.** Stores retire before AXI B completion; precise architectural handling of a late error is not established.
5. **Stale long-latency completion.** FPU/divider/CVXIF/load outputs must never alias a recycled scoreboard ID after flush/reset.

## High

6. AW and W independent backpressure and write-ID accounting.
7. Load grant on the same edge as flush.
8. Debug request concurrent with interrupt/trap/maintenance halt.
9. CSR hardware update colliding with software write, especially pending interrupts, counters, and FP flags.
10. Exact fence relation to AXI B completion.

## Medium

11. Predictor state update during wider frontend flush.
12. Write-buffer byte merging and newest-byte forwarding.
13. Dual-commit restriction coverage under all FU pairs.
14. PMP boundary and locked-entry semantics.
15. Error response conversion on I-cache/D-cache/PTW paths.

## Closure order

1. Restore a licensed Questa run or install a supported Verilator flow and RISC-V toolchain.
2. Bind ownership/side-effect assertions before collecting performance traces.
3. Run traces 05, 06, 10, 16, and 18 first because they test cancellation and stale identity.
4. Run forwarding, branch, fence, interrupt, debug, and AMO traces.
5. Archive exact command, seed, binary hash, log, waveform, and assertion/coverage summary for each run.

Until then, the analysis is level 3 for principal static paths and level 2 to 3 for integration-dependent reset/error semantics.
