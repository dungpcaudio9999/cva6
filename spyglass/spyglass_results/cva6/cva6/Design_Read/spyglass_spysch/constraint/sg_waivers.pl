################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'51',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive -file_line "/home/dungpc/FU/shot1/cva6/common/local/util/sram_cache.sv" 55 -severity "ERROR" -rule "ErrorAnalyzeBBox"%',
                       "-file_line"=>'"/home/dungpc/FU/shot1/cva6/common/local/util/sram_cache.sv" 55',
                       "-rule"=>'"ErrorAnalyzeBBox"',
                       "-severity"=>'"ERROR"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'9'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive -file_line "/home/dungpc/FU/shot1/cva6/common/local/util/sram_cache.sv" 85 -severity "ERROR" -rule "ErrorAnalyzeBBox"%',
                       "-file_line"=>'"/home/dungpc/FU/shot1/cva6/common/local/util/sram_cache.sv" 85',
                       "-rule"=>'"ErrorAnalyzeBBox"',
                       "-severity"=>'"ERROR"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'10'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q!waive -file q%/home/dungpc/FU/shot1/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv% -severity "ERROR" -rule "ErrorAnalyzeBBox"!',
                       "-file"=>'q%/home/dungpc/FU/shot1/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv%',
                       "-rule"=>'"ErrorAnalyzeBBox"',
                       "-severity"=>'"ERROR"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'11'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q!waive -file q%/home/dungpc/FU/shot1/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv% -severity "ERROR" -rule "SYNTH_5251"!',
                       "-file"=>'q%/home/dungpc/FU/shot1/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv%',
                       "-rule"=>'"SYNTH_5251"',
                       "-severity"=>'"ERROR"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'12'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'5',
                       "waiverCmd"=>'q%waive -file "/home/dungpc/FU/shot1/cva6/common/local/util/tc_sram_wrapper_cache_techno.sv" -du "tc_sram_wrapper_cache_techno" -severity "ERROR" -rule "ErrorAnalyzeBBox"%',
                       "-file"=>'"/home/dungpc/FU/shot1/cva6/common/local/util/tc_sram_wrapper_cache_techno.sv"',
                       "-du"=>'"tc_sram_wrapper_cache_techno"',
                       "-rule"=>'"ErrorAnalyzeBBox"',
                       "-severity"=>'"ERROR"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'13'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'6',
                       "waiverCmd"=>'q!waive -file m%/home/dungpc/FU/shot1/cva6/core/cache_subsystem/*% -regexp !',
                       "-file"=>'m%/home/dungpc/FU/shot1/cva6/core/cache_subsystem/*%',
                       "-regexp"=>'1',
                       "violations_waived"=>'6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'15'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'7',
                       "waiverCmd"=>'q%waive  -rule "W240" -comment "Created by akassimi on 26-Jul-2024 18:36:59"%',
                       "-rule"=>'"W240"',
                       "-comment"=>'"Created by akassimi on 26-Jul-2024 18:36:59"',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'17'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'8',
                       "waiverCmd"=>'q%waive  -rule "W528" -comment "Remove Set but not read warning as it happens very often for disable features such as PMP, Accelerator, ..."%',
                       "-rule"=>'"W528"',
                       "-comment"=>'"Remove Set but not read warning as it happens very often for disable features such as PMP, Accelerator, ..."',
                       "violations_waived"=>'',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"./sg_setup/cva6/cva6_waiver.awl"',
                       "waiverline"=>'18'
                      );

spyWaiversDataCount("totalWaivers"=>'8',
"totalWaiversApplied"=>'8',
"totalWaiversWithRegExp"=>'1',
"totalWaiversWithRuleSpecified"=>'7',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'6',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
