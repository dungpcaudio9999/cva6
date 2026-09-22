# 00 — Phạm vi và cấu hình

## Ranh giới

Đối tượng là core CVA6 và wrapper APU testharness trong repository tại commit `f591a3972e65c22ff1b79c9aab955784e6916151`. `make target=cv64a6_imafdc_sv39` chọn package trong [Makefile](../../../Makefile#L108) và [file list](../../../core/Flist.cva6#L83); package đầu vào ở [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L11), hàm tạo tham số ở [build_config](../../../core/include/build_config_pkg.sv#L3). `TARGET_CFG` đặt sẵn có thể override đường chọn; vì thế cần ghi cả environment khi chạy thực tế.

## Hợp đồng kiến trúc đã chọn

| Thành phần | Giá trị theo source | Chứng cứ |
|---|---|---|
| XLEN / địa chỉ | XLEN 64, VLEN container 64, PLEN 56; Sv39 3 mức | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L13), [derived](../../../core/include/build_config_pkg.sv#L35) |
| Issue / retire | 1 issue, tối đa 2 commit; scoreboard 8 entry, transaction slot ID 3 bit | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L53), [derived](../../../core/include/build_config_pkg.sv#L55) |
| ISA | RV64I, M/A/F/D/C; B/ZKN/Zcb/ZiCond bật; V/H/Zcmp/Zicbom tắt | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L15) |
| Đặc quyền | M/S/U, debug bật, PMP 8 entry, MMU và TLB I/D 16 entry | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L73) |
| Cache/bus | I 16 KiB 4-way, D WT 32 KiB 8-way, line 16 B; AXI data/address 64, ID 4 bit | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L33) |
| Prediction | RAS 2, BTB 32, BHT 128; loại BHT | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L62) |
| CV-X-IF | Port bật, `CoproType=COPRO_NONE`; không suy có coprocessor nhận instruction | [config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L110) |

Đây là **source-established configuration**, chưa phải parameter dump của elaborated design. Các giá trị khác như `NrLoadBufEntries=2`, `WtDcacheWbufDepth=8`, `MEM_TID_WIDTH=2` biểu diễn tài nguyên khác nhau, không được gộp thành “8 outstanding loads/stores”. [Config](../../../core/include/cv64a6_imafdc_sv39_config_pkg.sv#L50), [derived](../../../core/include/build_config_pkg.sv#L173).

## Phân loại thay đổi cấu hình

`RVC`, `RVA`, `RVF/RVD`, `RVS/RVU`, `RVH`, `RVV`, `RVZCB`, `RVZiCond`, PMP count và MMU presence có thể thay đổi opcode/CSR/trap quan sát được. Kích thước cache, RAS/BTB/BHT và scoreboard chủ yếu đổi timing, throughput hoặc khả năng giữ việc đang bay; vẫn phải tái kiểm chứng tính trong suốt kiến trúc. `DCacheType=WT` quyết định đường store/cache; WB/HPDCache là thiết kế khác, không dùng kết luận cụ thể của tài liệu này. [Build config](../../../core/include/build_config_pkg.sv#L65), [core generate](../../../core/cva6.sv#L1465).
