// EXP-03: exercise the actual configuration packages, without CPU/IP stubs.
module tb_config;
  localparam config_pkg::cva6_cfg_t C =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
  int checks = 0;
  task automatic check_value(string name, longint actual, longint expected);
    checks++;
    if (actual != expected) begin
      $error("CONFIG_MISMATCH %s actual=%0d expected=%0d", name, actual, expected);
      $fatal(1, "configuration check failed");
    end
    $display("CHECK %s=%0d", name, actual);
  endtask
  initial begin
    check_value("XLEN", C.XLEN, $test$plusargs("CORRUPT_EXPECTATION") ? 32 : 64);
    check_value("PLEN", C.PLEN, 56);
    check_value("NrIssuePorts", C.NrIssuePorts, 1);
    check_value("NrCommitPorts", C.NrCommitPorts, 2);
    check_value("NR_SB_ENTRIES", C.NR_SB_ENTRIES, 8);
    check_value("TRANS_ID_BITS", C.TRANS_ID_BITS, 3);
    check_value("NrWbPorts", C.NrWbPorts, 5);
    check_value("DCacheType", C.DCacheType, config_pkg::WT);
    check_value("NonIdemPotenceEn", C.NonIdemPotenceEn, 0);
    check_value("ICACHE_INDEX_WIDTH", C.ICACHE_INDEX_WIDTH, 12);
    check_value("DCACHE_INDEX_WIDTH", C.DCACHE_INDEX_WIDTH, 12);
    check_value("DCACHE_OFFSET_WIDTH", C.DCACHE_OFFSET_WIDTH, 4);
    check_value("PtLevels", C.PtLevels, 3);
    check_value("FLen", C.FLen, 64);
    check_value("CvxifEn", C.CvxifEn, 1);
    check_value("CoproType", C.CoproType, config_pkg::COPRO_NONE);
    $display("PASS CONFIG checks=%0d", checks);
    $finish;
  end
endmodule
