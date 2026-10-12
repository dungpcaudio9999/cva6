################################################################################
#This is an internally genertaed by spyglass for Message Tagging Support
################################################################################


        use spyglass;
    use SpyGlass;
    use SpyGlass::Objects;
    spyRebootMsgTagSupport();

    spySetMsgTagCount(2,47);
spyParseTextMessageTagFile("./spyglass_results/cva6/cva6/Design_Read/spyglass_spysch/sg_msgtag.txt");

spyMessageTagTestBenchmark(72,"./spyglass_results/cva6/cva6/Design_Read/spyglass.vdb");

1;