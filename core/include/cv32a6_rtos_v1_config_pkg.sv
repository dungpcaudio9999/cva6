//------------------------------------------------------------------------------
// Copyright (c) 2026 FPT Telecom. All rights reserved.
//
// CVA6 FU3 RTOS v1 configuration.
//
// This target is intentionally identical to cv32a6_rtos for ISA, pipeline,
// debug, PMA, memory map, and AXI geometry.  Its only architectural change is
// removal of the complete L1 cache subsystem: instruction fetches and data
// accesses use the dedicated direct-to-AXI no-cache bridge.
//------------------------------------------------------------------------------

`define CVA6_RTOS_NOCACHE
`include "cv32a6_rtos_config_pkg.sv"
`undef CVA6_RTOS_NOCACHE
