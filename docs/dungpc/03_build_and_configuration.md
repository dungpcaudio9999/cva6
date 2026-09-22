# 03 — Build và cấu hình CFG-01

## Chuỗi lựa chọn

Nguồn: [Makefile](../../Makefile#L108), [core/Flist.cva6](../../core/Flist.cva6#L83), [target package](../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L11), [build_config](../../core/include/build_config_pkg.sv#L3), [harness](../../corev_apu/tb/ariane_testharness.sv#L26).

```text
make target=cv64a6_imafdc_sv39
  TARGET_CFG (chỉ export nếu chưa có)
  core/Flist.cva6: core/include/${TARGET_CFG}_config_pkg.sv
  cva6_config_pkg::cva6_cfg
  build_config_pkg::build_config(...) -> CVA6Cfg
  ariane_testharness -> ariane -> cva6
```

Đây là đường lựa chọn từ source, **không phải hierarchy dump**. `TARGET_CFG` sẵn trong environment có thể khác `target`; Makefile không ghi đè khi đã đặt. `XLEN` Makefile chỉ gán 64 khi target đúng chuỗi default, còn lại 32; không dùng biến đó để suy rộng mọi tên `cv64...`.

| Flow | Top được yêu cầu | Inputs/options | Evidence |
|---|---|---|---|
| `make verilate` | `ariane_testharness` | `--no-timing`, `--cc --vpi`, C++ harness, core flist + APU source | Dry-run dừng trước compile |
| SV simulation | `ariane_tb` default | `top_level`/`top_level_path`, vlog/vopt/vsim | Chưa chạy full target |
| Bender | Theo target tags | Dependency versions riêng, conditional source lists | Chưa resolve/chưa chạy |
| Config probe | `tb_config` | Ba package thật, không stub CPU/IP | Compile PASS; runtime license failure |

## Các giá trị có tác động kiến trúc

Các giá trị dưới đây là source-established evaluation cho CFG-01; probe runtime chưa xác nhận. [RTL:ESTABLISHED; FND-CFG-01]

| Nhóm | Input hoặc derived value | Hệ quả |
|---|---|---|
| Word/address | XLEN=64, VLEN=64, PLEN=56, Sv=39, PtLevels=3 | VLEN là container, không phải 64-bit translated VA |
| Issue/commit | SuperscalarEn=0, NrIssuePorts=1, NrCommitPorts=2 | Single issue, có thể retire hai entry hợp lệ với hạn chế |
| Scoreboard | NR_SB_ENTRIES=8, TRANS_ID_BITS=3, NrWbPorts=5 | ID slot, không phải AXI ID |
| ISA feature bits | F/D/A/C/B/ZKN/Zcb/ZiCond bật; V/H/Zcmp/Zicbom tắt | Tên `imafdc` chưa thể hiện hết feature; chưa chứng nhận opcode compliance |
| CV-X-IF | CvxifEn=1, CoproType=COPRO_NONE | Wrapper ready nhưng không accept extension instruction |
| Privilege/debug | RVS=1, RVU=1, DebugEn=1, Sdtrig=0 | M/S/U, debug port; trigger feature không chọn |
| Cache | I=16 KiB/4-way, D=32 KiB/8-way, line=128 bits | Mỗi cache 256 sets, 16-byte line |
| WT buffers | WtDcacheWbufDepth=8, MemTidWidth=2, DCACHE_MAX_TX=4 | 8 word entries và 4 transaction slots, hai tài nguyên khác nhau |
| Store/loads | DEPTH_SPEC=4, DEPTH_COMMIT=4; NrLoadBufEntries=2 | Store depths từ ariane_pkg, không bằng WbufDepth |
| Bus | AXI address/data=64, ID=4, AxiBurstWriteEn=0 | 16 mã ID biểu diễn; capacity phải đọc từng queue/adapter |
| Translation | ITLB=16, DTLB=16, UseSharedTlb=0, PMP entries=8 | Có PTW; không suy `shared_tlb` module bị loại chỉ từ flag storage |
| Prediction | RAS=2, BTB=32, BHT=128, BPType=BHT | Phân biệt entries với thông lượng branch |
| Memory attributes | Cached [0x80000000,0xC0000000); non-idempotent lengths=0 | `NonIdemPotenceEn=0` dù NrNonIdempotentRules=2 |
| Cache flush | DcacheFlushOnFence=0, DcacheFlushOnFenceI=0 | WT fence cần drain, không kích D-cache flush theo các flag này |

**FND-CFG-01:** Không thể mô tả cấu hình chính xác chỉ bằng target name. **Support:** SUPPORTED. **Evidence/scope:** package inputs và build_config BASE-01/CFG-01; chưa CPU elaboration. **Freshness:** CURRENT, phụ thuộc package/build/wrapper/overrides.

## Compile order, defines và generated inputs

Core flist đưa `fpnew_pkg` trước `ariane_pkg`, config/riscv/package trước core. Include dirs có `core/include`, common_cells, AXI, common/local/util và HPDCache ECC. Flist đưa nhiều alternative RTL vào compilation dù generate branch không chọn; missing file vẫn có thể chặn compiler trước elaboration. 63 file thiếu không có nghĩa 63 instance active thiếu.

Makefile Verilator dùng `-Wno-fatal` cùng các warning selections; warning suppression không phải lint-clean. `--assert` không xuất hiện trong `verilate_command` đã đọc: cần xác minh assertion enable ở command cuối trước dựa vào SVA. `SPIKE_TANDEM` thay trace/reference path; TRACE_FAST/TRACE_COMPACT đổi waveform; `VERILATOR` đổi UART model và SRAM init. PRELOAD phải kiểm tra invocation thực tế, không suy từ comment.

Không dùng Bender/FuseSoC và Makefile interchangeably: nguồn/order/version có thể khác. ROM generation và firmware ELF chưa được xác nhận. [OQ-01, OQ-02, OQ-09, OQ-10](13_open_questions.md).

## Active elaborated configuration

**Chưa có.** EXP-03 chỉ compile package và probe, không có log values sau `$display`. CPU hierarchy, actual parameter dump và macro-expanded source vẫn là gate LIMITED. Các cấu hình RV32, WB, HPDCache, hypervisor, superscalar và FPGA chưa được kiểm tra trong phiên này.
