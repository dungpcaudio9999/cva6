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

    assert (Cfg.RVF && !Cfg.RVD && !Cfg.RVA && Cfg.RVB && Cfg.RVC &&
            !Cfg.RVV && !Cfg.RVS && !Cfg.RVU && !Cfg.RVH &&
            !Cfg.MmuPresent && !Cfg.CvxifEn)
    else $fatal(1, "unexpected ISA/privilege configuration");

    assert (Cfg.NrExecuteRegionRules == 1 &&
            Cfg.NrNonIdempotentRules == 5 &&
            Cfg.NrCachedRegionRules == 0)
    else $fatal(1, "unexpected PMA rule counts");

    // FU3 spec v2.4: CVA6 debug code in the last 4 KiB of CVA6_ISRAM.
    assert (Cfg.DmBaseAddress + Cfg.HaltAddress == 64'h0004_0000 &&
            Cfg.DmBaseAddress + Cfg.ExceptionAddress == 64'h0004_0008)
    else $fatal(1, "unexpected debug halt/exception address");

    // Executable: CVA6_ISRAM (192 KiB image + 4 KiB debug).
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0001_0000));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0003_FFFC));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0004_0000));
    assert (config_pkg::is_inside_execute_regions(Cfg, 64'h0004_0FFC));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h3000_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h30FF_FFFC));
    // Not executable: Ibex-only ROM, reserved gaps, IBEX_ISRAM, DSRAM, past
    // the XIP window, EDHOC and data-only HyperRAM.
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0000_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0000_1800));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0000_FFFC));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0004_1000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0005_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0006_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0100_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h0103_FFFC));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h3100_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h3101_0000));
    assert (!config_pkg::is_inside_execute_regions(Cfg, 64'h6000_0000));
    assert (!config_pkg::is_inside_cacheable_regions(Cfg, 64'h0001_0000));
    assert (!config_pkg::is_inside_cacheable_regions(Cfg, 64'h0100_0000));
    // Device windows.
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h1A11_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h1A11_0FFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3101_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3101_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3102_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3103_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4000_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4400_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4410_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4411_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4412_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4412_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5001_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5010_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5011_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5012_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5012_FFFC));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5013_0000));
    assert (config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5013_FFFC));
    // Memories and reserved holes are idempotent.
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h0001_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h0100_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3000_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3010_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h3104_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4001_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4010_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h4413_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5000_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h5014_0000));
    assert (!config_pkg::is_inside_nonidempotent_regions(Cfg, 64'h6000_0000));

    $display("PASS: cv32a6_rtos_v1 cacheless config/PMA smoke");
    $finish;
  end

endmodule
