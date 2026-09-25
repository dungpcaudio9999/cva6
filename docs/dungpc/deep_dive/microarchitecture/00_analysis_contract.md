# 00 — Analysis Contract

## Baseline

- Repository: CVA6 checkout at `/home/dungpc9/ndmoney4porche/projects/cva6`.
- Git commit: `df65dd38e11417849dd4213a8e8e548b282f30c6`.
- Selected configuration: `cv64a6_imafdc_sv39`.
- Core top: `cva6`, using its default `CVA6Cfg=build_config(cva6_cfg)` parameter. [RTL](../../../../core/cva6.sv#L18)
- Integration top for the standard harness: `ariane_testharness`; integration runtime is outside the established evidence because the RISC-V toolchain and simulator license are unavailable.
- Dependency state: all Git submodules initialized at the commits recorded in [baseline manifest](evidence/build/baseline_manifest.txt).

## Reproducibility record

The selected package appears in the official core file list through `${TARGET_CFG}_config_pkg.sv`. [File list](../../../../core/Flist.cva6#L89) The default Makefile target is `cv64a6_imafdc_sv39`, and `TARGET_CFG` is exported from `target` only when the environment does not already define it. [Makefile](../../../../Makefile#L101)

The analysis invocation explicitly set:

```text
CVA6_REPO_DIR=<repository root>
TARGET_CFG=cv64a6_imafdc_sv39
HPDCACHE_DIR=<repository root>/core/cache_subsystem/hpdcache
```

The shell environment initially had neither `TARGET_CFG` nor `RISCV`. This matters because a pre-existing `TARGET_CFG` could silently select another package, while the Makefile refuses to proceed without `RISCV` even for a dry run.

## Executed experiments

### EXP-B01 — Configuration package compilation

`fpnew_pkg`, `config_pkg`, the target configuration package, `build_config_pkg`, and a configuration probe compiled with zero errors and zero warnings. [Compile log](evidence/build/config_compile.log) This establishes type correctness and constant-expression compatibility in the installed compiler. Runtime `$display` values were not observed because `vsim` could not obtain a license. [Run log](evidence/build/config_run.log)

### EXP-B02 — Complete core file-list compilation

Every source in `core/Flist.cva6` compiled with zero errors. The 1,275 warnings are predominantly old-compiler input-port and deferred `always_comb` checks; they are not treated as a lint pass. [Compile log](evidence/build/core_compile.log)

### EXP-B03 — Core elaboration attempt

`vopt` loaded 199 design units and the active hierarchy down through frontend, issue, execution, LSU, CSR, MMU, FPU, and WT cache blocks. It then failed during backend code generation with `vopt-1981` and `vopt-2064`; `fpnew_fma_multi` also referenced an undefined `fmalza` module. [Elaboration log](evidence/build/core_elaboration.log) This is partial hierarchy evidence, not a successful elaboration gate.

## Claim labels

- **COMPILE-ESTABLISHED:** accepted by the complete core compile.
- **RTL-ESTABLISHED:** established by exact source logic and selected constants.
- **DYNAMICALLY ESTABLISHED:** requires a passing simulation/formal witness; none currently exist in this directory.
- **INFERRED:** follows from several RTL facts but lacks an end-to-end proof.
- **OPEN:** evidence is insufficient or a tool gate failed.

## Scope exclusions

- HPDCache and write-back cache behavior outside inactive compilation alternatives.
- RV32, hypervisor, vector, superscalar, FPGA, OpenPiton, and other target configurations.
- Physical timing, PPA, clock frequency, bounded interrupt latency, and memory-system fairness.
- ISA compliance beyond the directly inspected implementation paths.

## Completion assessment

Static level-3 analysis may proceed because the target package, default core parameter, complete file-list compile, and loaded WT hierarchy agree. Level-4 claims remain gated by a licensed simulator or formal tool, a runnable test program/toolchain, and observed traces.
