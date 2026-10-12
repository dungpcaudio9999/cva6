################################################################################
#This is an internally genertaed by spyglass for Message Tagging Support
################################################################################


        use spyglass;
    use SpyGlass;
    use SpyGlass::Objects;
    spyRebootMsgTagSupport();

    spySetMsgTagCount(97,49);
spyParseTextMessageTagFile("./spyglass_results/cva6/cva6/lint/lint_rtl/spyglass_spysch/sg_msgtag.txt");

spyMessageTagTestBenchmark(1234,"./spyglass_results/cva6/cva6/lint/lint_rtl/spyglass.vdb");

1;