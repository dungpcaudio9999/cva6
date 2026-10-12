# FU3 CVA6 Configuration and RTL Changes

This document describes the CVA6 development source used to create the clean
FU3 RTL delivery, the active cacheless `cv32a6_rtos_v1` configuration, and the
local changes relative to the upstream CVA6 baseline.

## Source identity

- Upstream repository: `https://github.com/openhwfoundation/cva6.git`
- FU3 development fork: `git@github-personal:dungpcaudio9999/cva6.git`
- Development branch: `feature/my-cva6-work`
- Upstream base commit: `81245a47fad8fe1a5d562d953ef2662e099def76`
- FU3 configuration target: `cv32a6_rtos_v1`
- Configuration package: `core/include/cv32a6_rtos_v1_config_pkg.sv`
- Core manifest: `core/Flist.cv32a6_rtos_v1`

The FU3 CPU integration does not compile this Git working tree directly. A
clean source closure is exported to:

```text
cva6-fu3-delivery/rtl/cva6_rtos_v1_20261003_81245a47_rtl1
```

That clean delivery is copied into the real directory
`fu3/hw/rtl/ip/cpu/logical/latest`; FU3 does not compile this repository root
or follow a symlink to it. Changes here affect FU3 only after a new delivery is
created, verified and copied. Record the Git commit, working-tree diff and
submodule revisions for every delivery.

## Export and build selection

The export flow resolves the following variables while generating the source
closure:

```text
CVA6_REPO_DIR=<workspace>/cva6
TARGET_CFG=cv32a6_rtos_v1
FLIST=<workspace>/cva6/core/Flist.cv32a6_rtos_v1
```

The core manifest therefore selects
`core/include/cv32a6_rtos_v1_config_pkg.sv`. This package reuses the common
RTOS settings while selecting `config_pkg::NOCACHE`. The v1 manifest excludes
the I-cache, HPDcache, cache SRAMs and their support RTL, and includes
`core/nocache_subsystem/cva6_nocache_subsystem.sv` instead. `HPDCACHE_DIR` is
therefore not an input to the selected production closure.

The delivered `filelist.f` is self-contained and refers only to
`$CPU_PATH/logical/latest`. FU3-owned package, AXI adapter, clock/reset
integration, and wrapper files remain under `fu3/hw/rtl/ip/cpu/logical` and are
compiled after the delivered core manifest.

## Active CPU configuration

| Item | FU3 setting |
|---|---|
| Core width | RV32 (`XLEN=32`, `VLEN=32`) |
| Privilege/MMU | Machine mode only; MMU, S-mode and U-mode disabled |
| Enabled optional ISA features | RVC and RVB |
| Disabled major optional features | F, D, A, V, H and CV-X-IF |
| AXI | 32-bit address, 32-bit data, 2-bit ID, 32-bit user |
| Pipeline | Single issue/commit, two load-buffer entries |
| Branch prediction | BHT, 16 BTB entries, 32 BHT entries, history depth 3 |
| PMP | 8 entries, NAPOT enabled |
| Debug | Enabled, two address-comparison triggers |
| Software interrupt | Enabled |
| Performance counters | Disabled |
| I-cache | Disabled; instruction fetch goes directly to AXI |
| D-cache | Disabled; LSU traffic goes directly to AXI |
| Cache selection | `config_pkg::NOCACHE` |
| Cached PMA regions | None (`NrCachedRegionRules=0`) |
| AXI burst writes | Disabled |

The internal RV32 physical address width remains 34 bits as defined by CVA6,
while the FU3 AXI boundary is explicitly 32 bits.

## FU3 PMA and execution map

Executable regions configured in the core are:

| Region | Base | Length | End |
|---|---:|---:|---:|
| Boot ROM | `0x0000_0000` | `0x0000_1000` | `0x0000_0FFF` |
| Debug execution | `0x0000_1000` | `0x0000_1000` | `0x0000_1FFF` |
| ISRAM | `0x0001_0000` | `0x0001_0000` | `0x0001_FFFF` |
| QSPI XIP | `0x3000_0000` | `0x0002_0000` | `0x3001_FFFF` |

Device/non-idempotent regions are:

| Region | Base | Length | End |
|---|---:|---:|---:|
| AES and PLIC window | `0x4000_0000` | `0x0002_0000` | `0x4001_FFFF` |
| Peripheral bus 0 | `0x4400_0000` | `0x0011_0000` | `0x4410_FFFF` |
| Peripheral bus 1 | `0x5000_0000` | `0x0011_0000` | `0x5010_FFFF` |

The Debug Module base is `0x0000_1000`; the halt and exception offsets are
`0x800` and `0x808`, producing entry addresses `0x0000_1800` and
`0x0000_1808`.

## Production RTL changes from the upstream base

### Cacheless FU3 configuration

`core/include/cv32a6_rtos_v1_config_pkg.sv` selects the cacheless variant of
the common settings in `cv32a6_rtos_config_pkg.sv`. `Bender.yml` registers the
matching `cv32a6_rtos_v1` target and excludes cache RTL for that target.

### Direct-to-AXI subsystem

`core/nocache_subsystem/cva6_nocache_subsystem.sv` connects instruction-fetch
and LSU requests directly to the 32-bit AXI boundary. Reads are serialized and
stores are acknowledged to the core only after the AXI write response, which
preserves store/load ordering without cache machinery.

`core/cva6.sv`, `Bender.yml`, the Makefiles and the dedicated v1 filelist select
this subsystem when building `cv32a6_rtos_v1`. No source below
`core/cache_subsystem/` is part of the clean v1 delivery. The unchanged CVA6
top still uses a response type from `wt_cache_pkg.sv`; retaining that package
does not instantiate a cache.

The earlier `cv32a6_rtos` target and its cache-path width fixes remain in the
development tree for comparison, but they are not selected by the active FU3
production delivery.

## Verification-only and tooling changes

The working tree also contains changes outside the production RTL closure for:

- the focused config/PMA smoke test under `verif/rtos_config`;
- generated linker and Spike configuration under
  `config/gen_from_riscv_config/cv32a6_rtos_v1`;
- UVM environment and testbench selection for `cv32a6_rtos_v1`;
- AXI assertions and RVFI tracing used by FU3 regressions;
- custom-test runtime/tohost handling;
- the CVA6 simulation driver and SpyGlass flow.

These files support verification but are not compiled by the FU3 production
wrapper filelist unless explicitly selected by a verification target.

## Deliveries

The active clean RTL delivery is:

```text
../cva6-fu3-delivery/rtl/cva6_rtos_v1_20261003_81245a47_rtl1/
```

The earlier cached clean delivery and previous source closures remain under
`../cva6-fu3-delivery/rtl/` and `../cva6-fu3-delivery/snapshots/` for audit and
rollback. Do not edit a delivery in place; create a new revision after source
changes pass verification.

## FU3 build commands

```sh
cd ../fu3/hw/rtl/ip/cpu/logical
make check-wrapper
make compile-cva6
make pma-smoke
make compile-wrapper
```

Before recording a result, also capture:

```sh
git -C ../../../../../../cva6 rev-parse HEAD
git -C ../../../../../../cva6 status --short
git -C ../../../../../../cva6 submodule status --recursive
```
