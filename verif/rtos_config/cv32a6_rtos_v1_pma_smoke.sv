//------------------------------------------------------------------------------
// Focused configuration/PMA audit for the cacheless FU3 RTOS v1 target.
//------------------------------------------------------------------------------

module cv32a6_rtos_v1_pma_smoke;

  localparam config_pkg::cva6_cfg_t Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  initial begin
    config_pkg::check_cfg(Cfg);

    assert (Cfg.XLEN == 32 && Cfg.VLEN == 32 &&
            Cfg.AxiAddrWidth == 32 && Cfg.AxiDataWidth == 32 &&
            Cfg.AxiIdWidth == 2)
    else $fatal(1, "unexpected core/AXI widths");

    assert (Cfg.DCacheType == config_pkg::NOCACHE)
    else $fatal(1, "cv32a6_rtos_v1 did not select the no-cache data path");

    assert (!Cfg.RVF && !Cfg.RVD && !Cfg.RVA && Cfg.RVB && Cfg.RVC &&
            !Cfg.RVV && !Cfg.RVS && !Cfg.RVU && !Cfg.RVH &&
            !Cfg.MmuPresent && !Cfg.CvxifEn)
    else $fatal(1, "unexpected ISA/privilege configuration");

    assert (Cfg.NrExecuteRegionRules == 2 &&
            Cfg.NrNonIdempotentRules == 6 &&
            Cfg.NrCachedRegionRules == 0)
    else $fatal(1, "unexpected PMA rule counts");

    // FU3 spec v2.0: CVA6 debug code in the top 4 KiB of CVA6_ISRAM.
    assert (Cfg.DmBaseAddress + Cfg.HaltAddress == 64'h0001_F000 &&
            Cfg.DmBaseAddress + Cfg.ExceptionAddress == 64'h0001_F008)
    else $fatal(1, "unexpected debug halt/exception address");

    // Executable: CVA6_ISRAM and QSPI XIP only.
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0001_0000));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0001_F000));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0001_FFFC));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h3000_0000));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h3001_FFFC));
    // Not executable: Ibex-only ROM, removed debug window, IBEX_ISRAM, DSRAM,
    // past the XIP window, and data-only HyperRAM.
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0000_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0000_1800));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0002_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0100_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h3002_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h6000_0000));
    assert (!config_pkg::is_inside_cacheable_regions(Cfg, 64'h0001_0000));
    assert (!config_pkg::is_inside_cacheable_regions(Cfg, 64'h0100_0000));
    // Device windows.
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h1A11_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3010_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4000_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4010_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4010_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4400_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h440F_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5001_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5010_FFFC));
    // Memories and reserved holes are idempotent.
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h0001_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h0100_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3000_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4001_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4410_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5000_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h6000_0000));

    $display("PASS: cv32a6_rtos_v1 cacheless config/PMA smoke");
    $finish;
  end

endmodule
