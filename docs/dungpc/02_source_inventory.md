# 02 — Bản đồ nguồn

Snapshot có 1.764 tracked regular files ngoài `docs/dungpc`; [inventory.json](evidence/BASE-01/inventory.json) phân bố theo directory/extension. Số file repository không phải số module active.

| Nhóm | Nguồn | Vai trò và origin | Trạng thái trong CFG-01 |
|---|---|---|---|
| Cấu hình | `core/include/config_pkg.sv`, target package, `build_config_pkg.sv` | Handwritten type/input/derived config | Đã compile riêng; cấu hình CPU chưa elaborated |
| Core top | `core/cva6.sv` | Handwritten kết nối pipeline/cache/CSR | Source candidate active |
| Wrapper | `corev_apu/src/ariane.sv` | Đóng loại AXI/RVFI/CVXIF và chọn copro | Source candidate active |
| Harness | `corev_apu/tb/ariane_testharness.sv`, `ariane_tb.sv`, `ariane_tb.cpp` | TB, clocks/host/memory/debug | Verilator top là harness, SV top là tb |
| Frontend | `core/frontend/`, `instr_realign.sv`, `compressed_decoder.sv` | PC, prediction, queue và decode instruction | Theo feature generate |
| Pipeline | `id_stage`, `issue_stage`, `issue_read_operands`, `raw_checker`, `scoreboard`, `ex_stage`, `commit_stage`, `controller` | Handwritten hazard/execute/retire/recovery | Ưu tiên đọc sâu |
| LSU/MMU | `load_store_unit`, `load_unit`, `store_unit`, `store_buffer`, `amo_buffer`, `core/cva6_mmu/`, `core/pmp/` | Translation, ordering, buffering, permission | MMU/PMP/RVA bật |
| Cache | `core/cache_subsystem/wt_*`, `cva6_icache.sv`, `core/axi_shim.sv` | WT path và bus adaptation | Nhánh dự kiến được chọn |
| Cache khác | `std_cache_subsystem.sv`, `std_nbdcache.sv`, HPDCache wrapper | WB/HPDCache alternatives | Không instantiate theo source CFG-01; không phải obsolete |
| FPU/CVXIF | `fpu_wrap.sv`, `core/cvfpu`, `cvxif_fu.sv`, `cvxif_example/` | FPU external IP; extension boundary/example | FPU thiếu submodule; copro example không chọn |
| APU | `corev_apu/tb/ariane_soc_pkg.sv`, `ariane_peripherals.sv`, `clint/` | Address map, peripherals, RTC timer | Một số peripheral bị thay bằng mock/error |
| Vendor | `vendor/pulp-platform/axi`, `common_cells`, `tech_cells_generic` | Third-party source in tree | Phải hash cùng core; FIFO/arb/reset/memory |
| External | `riscv-dbg`, `rv_plic`, `axi_mem_if`, `register_interface` | Submodule, API boundary | Nguồn chưa initialized |
| Memory/firmware | `common/local/util/sram.sv`, `sram_cache.sv`, `corev_apu/bootrom/` | Memory model; ROM generator/input/output | Chưa regenerate/boot-run |
| Verification | `verif/tb/core`, `verif/tb/uvmt`, `verif/tests`, `verif/tb/csr_unit` | UVM/ISS/assertions/directed tests | Có source/checker; chưa execution evidence |
| Build | `Makefile`, `core/Flist.cva6`, `Flist.ariane`, `Bender.yml`, `ariane.core`, `src_files.yml` | Nhiều build flows, manifest khác nhau | Chỉ Makefile/core flist là trọng tâm |
| Platform | `corev_apu/fpga`, `corev_apu/altera`, `pd`, `spyglass` | Wrappers, constraints, synthesis/lint scripts | Context inventory; không active sign-off target |

Các đường dẫn không viết extension trong bảng là `.sv` thuộc `core/`. [Flist preflight](evidence/BASE-01/flist-preflight.json) giữ line, source/include, exists cho từng entry; chưa có cây instance do elaboration sinh.

## Nguồn mô tả và generated sources

[README gốc](../../README.md) mô tả core 6-stage, single-issue/in-order và đưa hướng dẫn smoke-tests. Đó là [SPEC:DECLARED] ở README của BASE-01, không áp lên mọi cấu hình; source có `SuperscalarEn`. Đường `verif/regress/smoke-tests.sh` README nhắc không tồn tại trong checkout này: cần tìm entrypoint đang được duy trì trước làm theo (OQ-10).

ROM có `bootrom.S`, `ariane.dts`, `gen_rom.py`, Makefile và `bootrom.sv`/`bootrom.h`; existence không xác nhận outputs khớp inputs. `config/gen_from_riscv_config/` là flow generate config/linker khác; chưa dùng để sinh CFG-01. Thư mục vendor có file mang tên deprecated nhưng vẫn có thể được manifest liệt kê; không kết luận globally unused từ tên.

## Đọc sâu

Thứ tự ưu tiên: target/build → `cva6.sv`/harness → commit/scoreboard → load/store/controller → WT adapter → CSR/CLINT/reset. FPU arithmetic, full decoder opcode audit và từng cell helper không thuộc độ sâu phiên này. [Module index](10_module_analysis/README.md) nối từng nhóm với flows và gaps.
