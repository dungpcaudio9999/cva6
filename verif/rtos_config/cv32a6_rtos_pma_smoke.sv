//------------------------------------------------------------------------------
// Focused elaboration/runtime audit for the official FU3 RTOS memory map from
// doc_dungpc/CVA6_Info.docx.
// Compile this file after core/Flist.cva6 with TARGET_CFG=cv32a6_rtos.
//------------------------------------------------------------------------------

module cv32a6_rtos_pma_smoke;

  localparam config_pkg::cva6_cfg_t Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  task automatic expect_execute(input logic [63:0] address, input bit expected);
    assert (config_pkg::is_inside_execute_regions(Cfg, address) == expected)
    else $fatal(1, "execute PMA mismatch at 0x%016h", address);
  endtask

  task automatic expect_cached(input logic [63:0] address, input bit expected);
    assert (config_pkg::is_inside_cacheable_regions(Cfg, address) == expected)
    else $fatal(1, "cacheable PMA mismatch at 0x%016h", address);
  endtask

  task automatic expect_device(input logic [63:0] address, input bit expected);
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, address) == expected)
    else $fatal(1, "non-idempotent PMA mismatch at 0x%016h", address);
  endtask

  initial begin
    config_pkg::check_cfg(Cfg);

    assert (Cfg.XLEN == 32 && Cfg.VLEN == 32 && Cfg.AxiAddrWidth == 32 &&
            Cfg.AxiDataWidth == 32 && Cfg.AxiIdWidth == 2)
    else $fatal(1, "unexpected core/AXI widths");
    assert (!Cfg.RVF && !Cfg.RVD && !Cfg.RVA && Cfg.RVB && Cfg.RVC &&
            !Cfg.RVV && !Cfg.RVS && !Cfg.RVU && !Cfg.RVH &&
            !Cfg.MmuPresent && !Cfg.CvxifEn)
    else $fatal(1, "unexpected ISA/privilege configuration");
    assert (Cfg.ICACHE_LINE_WIDTH == 32 && Cfg.ICACHE_SET_ASSOC == 2 &&
            Cfg.FETCH_WIDTH == 32)
    else $fatal(1, "unexpected instruction fetch geometry");
    assert (Cfg.NrLoadBufEntries == 2 && Cfg.MaxOutstandingStores == 2 &&
            Cfg.NR_SB_ENTRIES == 4 && Cfg.NrLoadPipeRegs == 1 &&
            Cfg.NrStorePipeRegs == 1 && Cfg.RASDepth == 2 &&
            Cfg.BTBEntries == 16 && Cfg.BHTEntries == 32)
    else $fatal(1, "unexpected pipeline/predictor configuration");
    assert (Cfg.NrPMPEntries == 8 && Cfg.PMPNapotEn && Cfg.DebugEn &&
            !Cfg.PerfCounterEn && Cfg.SoftwareInterruptEn)
    else $fatal(1, "unexpected protection/debug/interrupt configuration");
    assert (Cfg.DmBaseAddress == 64'h0000_1000 &&
            Cfg.HaltAddress == 64'h800 && Cfg.ExceptionAddress == 64'h808)
    else $fatal(1, "unexpected Debug Module map");
    assert (Cfg.DmBaseAddress + Cfg.HaltAddress == 64'h0000_1800 &&
            Cfg.DmBaseAddress + Cfg.ExceptionAddress == 64'h0000_1808)
    else $fatal(1, "unexpected absolute Debug Mode entry address");
    assert (Cfg.Sdtrig && Cfg.SdtrigNrTriggers == 2 &&
            Cfg.SdtrigMcontrol6 && Cfg.SdtrigMcontrol6ExecAddr &&
            Cfg.SdtrigMcontrol6LoadAddr && Cfg.SdtrigMcontrol6Store)
    else $fatal(1, "debug trigger configuration mismatch");

    assert (Cfg.NrExecuteRegionRules == 4 &&
            Cfg.NrNonIdempotentRules == 3 &&
            Cfg.NrCachedRegionRules == 0)
    else $fatal(1, "unexpected PMA rule counts");

    // Boot ROM: 4 KiB, executable, uncached, normal/idempotent memory.
    expect_execute(64'h0000_0000, 1);
    expect_execute(64'h0000_0fff, 1);
    expect_cached (64'h0000_0000, 0);
    expect_device (64'h0000_0000, 0);

    // Debug execution region: 4 KiB and normal/idempotent in the official map.
    expect_execute(64'h0000_1000, 1);
    expect_execute(64'h0000_1800, 1);
    expect_execute(64'h0000_1808, 1);
    expect_execute(64'h0000_1fff, 1);
    expect_cached (64'h0000_1000, 0);
    expect_device (64'h0000_1000, 0);

    // ISRAM: 64 KiB, executable, conservatively uncached.
    expect_execute(64'h0001_0000, 1);
    expect_execute(64'h0001_ffff, 1);
    expect_cached (64'h0001_0000, 0);
    expect_cached (64'h0001_ffff, 0);

    // DSRAM: 64 KiB, non-executable and uncached.
    expect_execute(64'h0100_0000, 0);
    expect_execute(64'h0100_ffff, 0);
    expect_cached (64'h0100_0000, 0);
    expect_device (64'h0100_0000, 0);

    // QSPI XIP: 128 KiB, executable but conservatively uncached.
    expect_execute(64'h3000_0000, 1);
    expect_execute(64'h3001_ffff, 1);
    expect_cached (64'h3000_0000, 0);
    expect_cached (64'h3001_ffff, 0);
    expect_device (64'h3000_0000, 0);

    // Official FU3 device apertures.
    expect_device (64'h4000_0000, 1);
    expect_device (64'h4001_ffff, 1);
    expect_device (64'h4400_0000, 1);
    expect_device (64'h4410_ffff, 1);
    expect_device (64'h5000_0000, 1);
    expect_device (64'h5010_ffff, 1);

    // Boundary/gap and removed-provisional-aperture checks.
    expect_execute(64'h0000_2000, 0);
    expect_execute(64'h0002_0000, 0);
    expect_execute(64'h3002_0000, 0);
    expect_device (64'h0200_0000, 0);
    expect_device (64'h0c00_0000, 0);
    expect_device (64'h4002_0000, 0);
    expect_device (64'h4411_0000, 0);
    expect_device (64'h5011_0000, 0);

    $display("PASS: cv32a6_rtos config/PMA smoke");
    $finish;
  end

endmodule
