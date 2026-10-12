/*
 * FU3 cv32a6_rtos boot smoke test.
 *
 * Minimal directed test for the "does the core boot with the FU3 memory
 * map" question (see doc_dungpc/flow_test/boot_test_fu3_memmap.md):
 *  - crt0 must reach main() at all (proves ISRAM 0x1_0000 is fetchable).
 *  - a const array in .rodata must read back correctly (proves ISRAM data
 *    path, not just instruction fetch).
 *  - a global array in .data/.bss must be writable and readable (proves
 *    DSRAM 0x0100_0000 is real, working memory, not an unmapped hole).
 *
 * Pass/fail is reported through the standard tohost mechanism (main's
 * return value), consistent with every other custom test in this tree.
 */

#include <stdint.h>

static const uint32_t isram_pattern[4] __attribute__((aligned(4))) = {
    0xdeadbeef, 0x12345678, 0xa5a5a5a5, 0x0000ffff
};

static volatile uint32_t dsram_scratch[4] __attribute__((aligned(4)));

int main(void) {
    int fail = 0;

    /* ISRAM (.rodata) read check. */
    if (isram_pattern[0] != 0xdeadbeef) fail |= 0x1;
    if (isram_pattern[1] != 0x12345678) fail |= 0x2;
    if (isram_pattern[2] != 0xa5a5a5a5) fail |= 0x4;
    if (isram_pattern[3] != 0x0000ffff) fail |= 0x8;

    /* DSRAM (.data/.bss) read/write check. */
    for (int i = 0; i < 4; i++) {
        dsram_scratch[i] = isram_pattern[i] ^ 0xffffffffu;
    }
    for (int i = 0; i < 4; i++) {
        if (dsram_scratch[i] != (isram_pattern[i] ^ 0xffffffffu)) {
            fail |= (0x10u << i);
        }
    }

    /*
     * Keep this test independent of a proxy-kernel/host syscall agent.
     * The common bare-metal exit path converts main's return value into
     * the standard odd tohost pass/fail value consumed by the testbench.
     */
    return fail;
}
