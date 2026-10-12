//------------------------------------------------------------------------------
// Copyright (c) 2026 FPT Telecom. All rights reserved.
//

// This RTL source code and the associated design are the proprietary
// and confidential information of FPT Telecom.
// Any unauthorized use, reproduction, or disclosure is strictly prohibited.
//------------------------------------------------------------------------------
// Author : DungPC9
// Email : dungpc9@fpt.com
// Created Date : 2026-09-26
// Description: CVA6 RTOS configuration, derived from cv32a60x and adjusted per
// the official FU3 configuration in "CVA6_Info.docx" and the memory map in
// "FU3_Hardware_Architecture_Specification_v2.0.docx".
//
// Notes / assumptions:
// 1. The base cv32a6_rtos target keeps its original HPDcache configuration.
//    cv32a6_rtos_v1 includes this package with CVA6_RTOS_NOCACHE defined and
//    selects the direct-to-AXI no-cache subsystem instead. DSRAM, ISRAM, QSPI
//    XIP and MMIO stay non-cacheable in both targets.
// 2. PLEN is internally fixed to 34 bits for XLEN=32 in build_config_pkg.sv
//    (not a user-configurable field). The official 32-bit physical address
//    requirement is enforced at the AXI boundary (AxiAddrWidth=32 below).
// 3. Cache geometry fields are retained for structural compatibility with the
//    shared CVA6 configuration record. They do not instantiate cache memories
//    or cache control logic when CVA6_RTOS_NOCACHE is defined.
// 4. FU3 spec v2.0 reserves the top 4 KiB of CVA6_ISRAM
//    (0x0001_F000-0x0001_FFFF) for CVA6 debug code. DmBaseAddress points
//    there; HaltAddress and ExceptionAddress are offsets from it, producing
//    the absolute entry addresses 0x0001_F000 and 0x0001_F008.
// 5. CVA6 executes only from CVA6_ISRAM and QSPI XIP 0x3000_0000-0x3001_FFFF.
//    The boot ROM is Ibex-only, DSRAM is non-executable and HyperRAM is
//    data-only. QSPI remains uncacheable. Peripheral interrupts are
//    aggregated by the FU3 PLIC; this CVA6 revision does not implement local
//    fast-interrupt or NMI input ports.
//
// Evolution History:
// Date Version Author Description
// 2026-10-12 2.0 DungPC9 Align debug address, executable and non-idempotent
//                        regions with FU3 spec v2.0 memory map.
//------------------------------------------------------------------------------


package cva6_config_pkg;

  localparam CVA6ConfigXlen = 32;

  localparam CVA6ConfigRvfiTrace = 1;

  localparam CVA6ConfigAxiIdWidth = 2;  // axi_pkg.sv
  localparam CVA6ConfigAxiAddrWidth = 32;  // axi_pkg.sv
  localparam CVA6ConfigAxiDataWidth = 32;  // axi_pkg.sv
  localparam CVA6ConfigDataUserWidth = 32;  // axi_pkg.sv

  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
      XLEN: unsigned'(CVA6ConfigXlen),
      VLEN: unsigned'(32),
      FpgaEn: bit'(0),
      FpgaAlteraEn: bit'(0),
      TechnoCut: bit'(1),
      SuperscalarEn: bit'(0),
      ALUBypass: bit'(0),
      NrCommitPorts: unsigned'(1),
      AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
      AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
      AxiIdWidth: unsigned'(CVA6ConfigAxiIdWidth),
      AxiUserWidth: unsigned'(CVA6ConfigDataUserWidth),
      MemTidWidth: unsigned'(CVA6ConfigAxiIdWidth),
      NrLoadBufEntries: unsigned'(2),
      RVF: bit'(0),
      RVD: bit'(0),
      XF16: bit'(0),
      XF16ALT: bit'(0),
      XF8: bit'(0),
      RVA: bit'(0),
      RVB: bit'(1),
      ZKN: bit'(0),
      RVV: bit'(0),
      RVC: bit'(1),
      RVH: bit'(0),
      RVZCMT: bit'(0),
      RVZCB: bit'(0),
      RVZCMP: bit'(0),
      XFVec: bit'(0),
      CvxifEn: bit'(0),
      CoproType: config_pkg::COPRO_NONE,
      RVZiCond: bit'(0),
      RVZiCbom: bit'(0),
      RVZicntr: bit'(0),
      RVZihpm: bit'(0),
      NrScoreboardEntries: unsigned'(4),
      PerfCounterEn: bit'(0),
      MmuPresent: bit'(0),
      RVS: bit'(0),
      RVU: bit'(0),
      SoftwareInterruptEn: bit'(1),
      // Offsets from DmBaseAddress: absolute 0x0001_F000 (halt) and
      // 0x0001_F008 (exception in Debug Mode), FU3 spec v2.0.
      HaltAddress: 64'h0,
      ExceptionAddress: 64'h8,
      RASDepth: unsigned'(2),
      BTBEntries: unsigned'(16),
      BPType: config_pkg::BHT,
      BHTEntries: unsigned'(32),
      BHTHist: unsigned'(3),
      // CVA6 debug code lives in the top 4 KiB of CVA6_ISRAM.
      DmBaseAddress: 64'h0001_F000,
      TvalEn: bit'(0),
      DirectVecOnly: bit'(1),
      NrPMPEntries: unsigned'(8),
      PMPCfgRstVal: {64{64'h0}},
      PMPAddrRstVal: {64{64'h0}},
      PMPEntryReadOnly: 64'd0,
      PMPNapotEn: bit'(1),
      NOCType: config_pkg::NOC_TYPE_AXI4_ATOP,
      // Device/non-idempotent apertures from the FU3 spec v2.0 memory map:
      // Ibex Debug Module, EDHOC OSCORE, AES, PLIC, PERIBUS_0
      // (0x4400_0000-0x440F_FFFF) and PERIBUS_1 (0x5001_0000-0x5010_FFFF).
      // Reserved address ranges are not PMA device rules; the SoC
      // interconnect is responsible for decode errors.
      NrNonIdempotentRules: unsigned'(6),
      NonIdempotentAddrBase: 1024'({
        64'h1A11_0000,
        64'h3010_0000,
        64'h4000_0000,
        64'h4010_0000,
        64'h4400_0000,
        64'h5001_0000
      }),
      NonIdempotentLength: 1024'({
        64'h0000_1000,
        64'h0001_0000,
        64'h0001_0000,
        64'h0001_0000,
        64'h0010_0000,
        64'h0010_0000
      }),
      // Executable regions: CVA6_ISRAM (program image and debug code) and
      // QSPI XIP. The Ibex-only boot ROM, DSRAM and HyperRAM (data only) are
      // not executable by CVA6.
      NrExecuteRegionRules: unsigned'(2),
      ExecuteRegionAddrBase: 1024'({64'h0001_0000, 64'h3000_0000}),
      ExecuteRegionLength: 1024'({64'h0001_0000, 64'h0002_0000}),
      // No region is cacheable until ISRAM/QSPI controller behavior is signed
      // off. The arrays retain a zero placeholder because the config structure
      // has a fixed maximum size; NrCachedRegionRules controls their use.
      NrCachedRegionRules: unsigned'(0),
      CachedRegionAddrBase: 1024'({64'h0}),
      CachedRegionLength: 1024'({64'h0}),
      MaxOutstandingStores: unsigned'(2),
      DebugEn: bit'(1),
      // Two address-comparison triggers per the spreadsheet. Support the
      // common execute breakpoint and load/store watchpoint use cases.
      Sdtrig: bit'(1),
      SdtrigMcontrol6: bit'(1),
      SdtrigMcontrol6ExecAddr: bit'(1),
      SdtrigMcontrol6ExecData: bit'(0),
      SdtrigMcontrol6Store: bit'(1),
      SdtrigMcontrol6LoadAddr: bit'(1),
      SdtrigMcontrol6LoadData: bit'(0),
      SdtrigIcount: bit'(0),
      SdtrigEtrigger: bit'(0),
      SdtrigItrigger: bit'(0),
      SdtrigNrTriggers: int'(2),
      SdtrigTriggerChaining: bit'(0),
      // action[0]=breakpoint exception, action[1]=enter Debug Mode;
      // match[0]=exact address match.
      SdtrigSupportedActions: 2'b11,
      SdtrigSupportedMatch: 10'b00_0000_0001,
      SdtrigSupportTextra: bit'(0),
      AxiBurstWriteEn: bit'(0),
      // Cache geometry is active for cv32a6_rtos and inert for the v1 target.
      IcacheByteSize: unsigned'(4096),
      IcacheSetAssoc: unsigned'(2),
      IcacheLineWidth: unsigned'(32),
      // v1 overrides the cache selection while retaining these record fields.
`ifdef CVA6_RTOS_NOCACHE
      DCacheType: config_pkg::NOCACHE,
`else
      DCacheType: config_pkg::HPDCACHE_WT,
`endif
      DcacheByteSize: unsigned'(2028),
      DcacheSetAssoc: unsigned'(2),
      DcacheLineWidth: unsigned'(128),
      DcacheFlushOnFence: bit'(0),
      DcacheFlushOnFenceI: bit'(0),
      DcacheInvalidateOnFlush: bit'(0),
      DcacheEccEnable: bit'(0),
      DcacheEccScrubberEnable: bit'(0),
      DataUserEn: unsigned'(1),
      // Reduced from cv32a60x's 8 to fit AxiIdWidth=2 (mem ID width, tied to
      // MemTidWidth below): HPDcache requires 2**AxiIdWidth-1 >= wbuf depth.
      // Sufficient for this single-issue, low-outstanding baseline.
      WtDcacheWbufDepth: int'(2),
      FetchUserWidth: unsigned'(32),
      FetchUserEn: unsigned'(1),
      InstrTlbEntries: int'(0),
      DataTlbEntries: int'(0),
      UseSharedTlb: bit'(0),
      SvnapotEn: bit'(0),
      SharedTlbDepth: int'(64),
      NrLoadPipeRegs: int'(1),
      NrStorePipeRegs: int'(1),
      DcacheIdWidth: int'(1)
  };

endpackage
