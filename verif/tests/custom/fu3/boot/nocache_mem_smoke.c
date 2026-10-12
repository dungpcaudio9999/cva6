/*
 * Focused memory-access smoke test for cv32a6_rtos_v1.
 * Exercises byte/halfword/word lanes, store-to-load ordering, and fences on
 * the direct-to-AXI path after the complete cache subsystem is removed.
 */

#include <stdint.h>

static volatile uint32_t words[8] __attribute__((aligned(16)));
static volatile uint8_t bytes[8] __attribute__((aligned(4)));
static volatile uint16_t halves[4] __attribute__((aligned(4)));

static inline void fence_rw_rw(void) {
    __asm__ volatile ("fence rw, rw" ::: "memory");
}

int main(void) {
    uint32_t fail = 0;

    for (uint32_t i = 0; i < 8; ++i) {
        words[i] = 0x10203040u ^ (i * 0x11111111u);
    }
    fence_rw_rw();
    for (uint32_t i = 0; i < 8; ++i) {
        if (words[i] != (0x10203040u ^ (i * 0x11111111u))) fail |= 0x1;
    }

    for (uint32_t i = 0; i < 8; ++i) bytes[i] = (uint8_t)(0xa0u + i);
    fence_rw_rw();
    for (uint32_t i = 0; i < 8; ++i) {
        if (bytes[i] != (uint8_t)(0xa0u + i)) fail |= 0x2;
    }

    halves[0] = 0x0123u;
    halves[1] = 0x4567u;
    halves[2] = 0x89abu;
    halves[3] = 0xcdefu;
    fence_rw_rw();
    if (halves[0] != 0x0123u || halves[1] != 0x4567u ||
        halves[2] != 0x89abu || halves[3] != 0xcdefu) fail |= 0x4;

    /* Repeated same-address store/load checks ordering without cache bypass. */
    for (uint32_t i = 0; i < 16; ++i) {
        words[0] = 0x55aa0000u | i;
        fence_rw_rw();
        if (words[0] != (0x55aa0000u | i)) fail |= 0x8;
    }

    __asm__ volatile ("fence.i" ::: "memory");

    /* Report through the bare-metal tohost exit path; no host I/O needed. */
    return (int)fail;
}
