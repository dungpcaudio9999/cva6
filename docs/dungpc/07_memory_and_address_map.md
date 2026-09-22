# 07 — Bộ nhớ và address map

## Decode của APU harness

Ranges dùng quy ước **[start, end)**, end không thuộc vùng, theo [addr_decode.sv](../../vendor/pulp-platform/common_cells/src/addr_decode.sv#L92). Nguồn base/length: [ariane_soc_pkg](../../corev_apu/tb/ariane_soc_pkg.sv#L37); nối thực tế dự kiến: [harness addr_map](../../corev_apu/tb/ariane_testharness.sv#L501). CFG-01 không đặt `NEXYS_VIDEO`.

| Vùng | Start | End exclusive | Target trong harness |
|---|---|---|---|
| Debug | 0x00000000 | 0x00001000 | Debug memory subordinate, IP thiếu |
| ROM | 0x00010000 | 0x00020000 | axi2mem → bootrom |
| CLINT | 0x02000000 | 0x020C0000 | CLINT timer/software IRQ |
| PLIC | 0x0C000000 | **0x0FFFFFFF** | Peripheral bridge → PLIC IP thiếu |
| UART | 0x10000000 | 0x10001000 | VERILATOR chọn mock UART |
| Timer | 0x18000000 | 0x18001000 | APB timer dependency thiếu |
| SPI | 0x20000000 | 0x20800000 | Disabled branch trong harness |
| Ethernet | 0x30000000 | 0x30010000 | Disabled branch trong harness |
| GPIO | 0x40000000 | 0x40001000 | Explicit error subordinate |
| DRAM | 0x80000000 | 0xC0000000 | SRAM behavioral, không phải DDR IP |

`PLICLength=0x03FFFFFF`, không phải `0x04000000`; vì end exclusive nên byte cuối decode là `0x0FFFFFFE`. Đây là literal-derived boundary cần test, không tự sửa thành kích thước tròn (OQ-08). HPSBase có trong package nhưng HPS index không nằm `NB_PERIPHERALS=Debug+1` và không có rule trong harness này.

Unmapped address: default port disabled; [axi_xbar](../../vendor/pulp-platform/axi/src/axi_xbar.sv#L155) đưa decode-error vào error slave cấu hình DECERR. **Bus-level error response không xác nhận core trap**, xem FND-AXI-01.

## FND-MEM-01 — DRAM window và SRAM capacity khác nhau

**Support:** SUPPORTED ở cấu hình và phép cắt địa chỉ, chưa SIM. **Scope/evidence:** harness `NUM_WORDS=2**25`, AXI data=64, SRAM `.addr_i(addr[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)])` ở [479](../../corev_apu/tb/ariane_testharness.sv#L479). [RTL:ESTABLISHED]

Capacity = 2^25 × 8 = 2^28 bytes = **256 MiB**, trong khi DRAM decode length = **1 GiB**. SRAM word index lấy bits `[27:3]`; do đó `0x80000000`, `0x90000000`, `0xA0000000`, `0xB0000000` có cùng index. Đây là alias của đường địa chỉ ở SRAM boundary. Chưa kiểm tra behavioral read/write xuyên axi2mem (submodule thiếu), không quy thành silicon memory bug.

Device tree [ariane.dts](../../corev_apu/bootrom/ariane.dts#L29) khai 0x10000000 bytes RAM tại 0x80000000, phù hợp capacity 256 MiB. Nếu firmware chỉ dùng vùng DT thì không bắt buộc chạm alias; still cần giới hạn ELF/load/map khi test (OQ-07).

## Boot, translation và attributes

Core boot vector do input quyết định. Harness nối `boot_addr_i=ROMBase=0x10000`; [bootrom.S](../../corev_apu/bootrom/bootrom.S#L1) tạo `s0=1<<31`, đọc mhartid vào a0, lấy DTB vào a1 và `jr s0` tới **0x80000000**. Không mặc định PC đi thẳng vào ELF entry. ROM output chưa regenerate/so byte với assembly (OQ-09).

Reset privilege M; satp reset zero nên translation chưa bật. `build_config` đặt Sv39/PLEN56, source có ITLB/DTLB/PTW/PMP. Cacheability rules của core: [0x80000000,0xC0000000). Execute rules: debug [0,0x1000), ROM [0x10000,0x20000), DRAM [0x80000000,0xC0000000). Cached/execute ranges không thay thế access privilege/PMP/PTE checks và không đồng nghĩa peripheral hiện hữu.

**FND-MEM-02:** `NonIdemPotenceEn=0` từ `NrNonIdempotentRules=2` nhưng lengths bằng 0. **Support:** SUPPORTED; [target](../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L148), [derived guard](../../core/include/build_config_pkg.sv#L151), [load guard](../../core/load_unit.sv#L237). [RTL:ESTABLISHED] Platform có MMIO side effect phải review treatment của speculative accesses; chỉ “uncached” không chứng minh “non-speculative”. OQ-07.

## Alignment, byte enables và software consistency

Bus 64-bit có 8 byte strobes; WT adapter tạo be/size cho byte, halfword, word, doubleword; LSU kiểm tra alignment/translation và mang exception. D-cache index/tag tách từ physical address, load/store hazard so page-offset bits `[11:3]` gây conservative collision ngay cả khác page.

`verif/bsp/link.ld` khai elf32 RAM tại 0 và boot 0x80, khác APU CFG-01. Đây là **khác test environment**, không tự kết luận RTL/linker mâu thuẫn. Khi chạy APU cần ELF phù hợp DRAM 0x80000000 và boot convention; chưa chọn exact ELF/linker. Default executable Makefile chỉ là đường dự kiến, không evidence file tồn tại.

Endianness/unaligned bus behavior ngoài các paths đã đọc và permission matrix toàn bộ peripheral chưa được chứng minh; scope này không phát hành driver-ready memory contract. [OQ-04, OQ-07, OQ-08, OQ-09](13_open_questions.md).
