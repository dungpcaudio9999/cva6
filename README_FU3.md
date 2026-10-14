# FU3 CVA6 Configuration and RTL Changes

This document describes the CVA6 development source used to create the clean
FU3 RTL delivery, the active cacheless `cv32a6_rtos_v1` configuration, and the
local changes relative to the upstream CVA6 baseline.

Reference specification: `FU3_Hardware_Architecture_Specification_v2.0.docx`
(10/10/2026). In v2.0 CVA6 is the application CPU; Ibex is the boot CPU and
is the only CPU that executes the boot ROM.

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

The PMA follows the shared memory map of spec v2.0.

Executable regions configured in the core are:

| Region | Base | Length | End |
|---|---:|---:|---:|
| CVA6_ISRAM (60 KiB image + 4 KiB debug code) | `0x0001_0000` | `0x0001_0000` | `0x0001_FFFF` |
| QSPI XIP | `0x3000_0000` | `0x0002_0000` | `0x3001_FFFF` |

The Ibex-only boot ROM (`0x0000_0000`), IBEX_ISRAM, DSRAM and the HyperRAM
window (`0x6000_0000`, data only) are not executable by CVA6. A fetch outside
the regions above raises an instruction access fault (`mcause` 1) before any
bus access.

Device/non-idempotent regions are:

| Region | Base | Length | End |
|---|---:|---:|---:|
| Ibex Debug Module | `0x1A11_0000` | `0x0000_1000` | `0x1A11_0FFF` |
| EDHOC OSCORE | `0x3010_0000` | `0x0001_0000` | `0x3010_FFFF` |
| AES-256 | `0x4000_0000` | `0x0001_0000` | `0x4000_FFFF` |
| PLIC | `0x4010_0000` | `0x0001_0000` | `0x4010_FFFF` |
| PERIBUS_0 | `0x4400_0000` | `0x0010_0000` | `0x440F_FFFF` |
| PERIBUS_1 | `0x5001_0000` | `0x0010_0000` | `0x5010_FFFF` |

No region is cacheable (`NrCachedRegionRules=0`).

CVA6 debug code lives in the top 4 KiB of CVA6_ISRAM. `DmBaseAddress` is
`0x0001_F000`; the halt and exception offsets are `0x0` and `0x8`, producing
entry addresses `0x0001_F000` (halt) and `0x0001_F008` (exception in Debug
Mode). The former debug window `0x0000_1000-0x0000_1FFF` is reserved in v2.0.

### Integration requirements outside this core

These spec v2.0 items are not implemented by the CVA6 RTL and must be provided
by the FU3 top/bus:

- CVA6 `boot_addr_i = 0x0001_0000`.
- CVA6 reset is held by Ibex until its image is staged and DEBUG_EN is low.
- The bus denies CVA6 access to the boot ROM; only Ibex writes CVA6_ISRAM
  while staging the image.
- Debug code at `0x0001_F000` must be loaded by the debugger (JTAG-to-AXI)
  before asserting `debug_req_i`.

### Software-visible error reporting

- A load that receives an AXI error (SLVERR/DECERR) traps with `mcause` 19
  (`HARDWARE_ERROR`), not 5.
- A store that receives an AXI error completes silently; no exception is
  raised (same as the upstream write-through cache).
- A fetch that receives an AXI error traps with `mcause` 1.

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

The bridge follows the two-phase CVA6 data-cache request protocol. When the
load unit kills a granted request instead of sending its tag (a device load
that is not yet at commit time, a PMP/misaligned exception, or a flush), the
bridge closes the request with `data_rvalid` in the same cycle and issues no
AXI read, matching the upstream `wt_dcache_ctrl`.

Fix 2026-10-12 (`RD_D_TAG`): the bridge previously ignored `kill_req` and
issued every killed load on AXI. Consequences, both reproduced in simulation
and present in delivery `rtl1`:

- Device (non-idempotent) loads were read several times while waiting for
  commit (12 loads produced 48 AXI reads), breaking read-to-clear registers.
- The PMP/misaligned exception of a killed load was lost: a load to a
  PMP-locked page returned memory data without a trap.

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

- the focused config/PMA smoke test under `verif/rtos_config` (spec v2.0 map);
- FU3 directed tests in `verif/tests/testlist_fu3.yaml`, including
  `fu3_fetch_fault`, `fu3_device_load`, `fu3_load_fault` and
  `fu3_debug_entry` under `verif/tests/custom/fu3/`;
- `CVA6_RTOS_MEM_MAP` testharness support: a debug request raised when
  `mscratch` holds `0xFD0B_0001`, and a device-access checker that compares
  the core PMA with the spec device map, rejects speculative device loads,
  and rejects device AXI reads without a committed load (`$fatal`);
- generated linker and Spike configuration under
  `config/gen_from_riscv_config/cv32a6_rtos_v1` (60 KiB image region and a
  4 KiB `DBG` region at `0x0001_F000` for `.debug_code`);
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

`rtl1` predates spec v2.0 (old PMA/debug map) and contains the bridge
`kill_req` defect described above. The next delivery (`rtl2`) carries the
spec v2.0 PMA/debug configuration and the bridge fix.

The earlier cached clean delivery and previous source closures remain under
`../cva6-fu3-delivery/rtl/` and `../cva6-fu3-delivery/snapshots/` for audit and
rollback. Do not edit a delivery in place; create a new revision after source
changes pass verification.

## Verification status (2026-10-12)

Target `cv32a6_rtos_v1`, `vcs-testharness`, `+define+CVA6_RTOS_MEM_MAP`:

| Test | Result |
|---|---|
| `cv32a6_rtos_v1_pma_smoke` | PASS |
| `boot_smoke`, `nocache_mem_smoke`, `lsu_false_4k_alias`, `hello_world_fu3` | PASS |
| `fu3_fetch_fault`, `fu3_device_load`, `fu3_load_fault`, `fu3_debug_entry` | PASS |
| `interrupt_jump_to_zero` | FAIL (timeout, known since 2026-10-06, unrelated) |

SpyGlass `lint/lint_rtl` on `m_fpt_cpu_wrap` with these sources: 0 Fatal,
0 Error, 0 Warning reported. The previously waived `W240` on the bridge input
`kill_req` (the symptom of the defect) is gone; two `W415a` of the kind already
waived in the bridge were added.

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
