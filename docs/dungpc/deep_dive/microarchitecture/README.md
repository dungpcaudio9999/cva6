# CVA6 Microarchitecture Analysis — CFG-01

This directory implements the deep-analysis plan for `cv64a6_imafdc_sv39` at Git commit `df65dd38e11417849dd4213a8e8e548b282f30c6`. It extends the parent [RTL walkthrough](../README.md) with exact state boundaries, next-state priority, transaction ownership, FSMs, and verification obligations.

## Evidence status

- **COMPILE-ESTABLISHED:** all sources in `core/Flist.cva6` compiled with Questa `vlog 10.7c`; zero errors and 1,275 warnings. See [core compile log](evidence/build/core_compile.log).
- **PARTIALLY ELABORATED:** `vopt` loaded the active CVA6 hierarchy, including the WT cache path, but code generation failed with `vopt-1981/2064`. See [elaboration log](evidence/build/core_elaboration.log).
- **NOT DYNAMICALLY ESTABLISHED:** `vsim` could not check out a license. No waveform or observed-cycle trace was produced. See [configuration run log](evidence/build/config_run.log).
- **RTL-ESTABLISHED:** source claims are tied to exact files and line anchors. They describe the selected default parameter set where compile/elaboration evidence is sufficient.
- **OPEN:** runtime ordering, latency, and concurrent-event claims that require simulation or formal proof remain explicitly open.

## Navigation

- [Analysis contract](00_analysis_contract.md)
- [Configuration](01_elaborated_configuration.md)
- [Hierarchy](02_elaborated_hierarchy.md)
- [Pipeline occupancy](03_pipeline_occupancy_model.md)
- [Pipeline register inventory](04_pipeline_register_inventory.md)
- [Global stall and flush matrix](05_global_stall_flush_matrix.md)
- [Plan completion and evidence matrix](06_completion_matrix.md)
- [Block analyses](blocks/README.md)
- [Memory analyses](memory/README.md)
- [Exceptional control](control/README.md)
- [Trace specifications and evidence status](traces/README.md)
- [Verification closure](verification/README.md)

## Achieved depth

The static material reaches **level 3** for the principal pipeline, scoreboard, load/store ownership, WT cache, PTW, redirect, retirement, and side-effect paths. The dynamic target remains **open** because the installed simulator cannot obtain a license and no alternative simulator is installed. Therefore, no document calls an abstract event sequence cycle-accurate.

The package contains 72 files, including 37 Mermaid diagrams, 12 block analyses, 10 memory analyses, 7 control analyses, 18 trace specifications, 4 verification documents, and captured build evidence.

## Reading rule

Diagrams use active RTL module and signal names. A solid arrow denotes a payload or handshake path. A dotted arrow denotes control, cancellation, or observation. Diagrams are structural unless their caption explicitly says that observed cycles were used.
