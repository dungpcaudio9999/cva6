# 01 — Repository baseline BASE-01

## Source snapshot

- Repository: `/home/dungpc9/ndmoney4porche/projects/cva6`.
- HEAD: `f591a3972e65c22ff1b79c9aab955784e6916151`.
- Initial `git status --short` trước tạo tài liệu: sạch. Snapshot collector chạy sau khi bắt đầu tài liệu nên log status có file phân tích untracked; đó không phải pre-existing RTL changes.
- `git diff HEAD --binary` loại `docs/dungpc` rỗng, SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
- 1.764 tracked regular files ngoài thư mục phân tích có trên disk. [source-sha256.txt](evidence/BASE-01/source-sha256.txt) hash từng file, gồm package, vendor, build, firmware và constraints có sẵn. Manifest digest: `c9574ee895b71cc170fc3a5c3f14afe11009d3fb568ad1c81b4215ba5593cb2a`.
- Analysis revision: bản bàn giao 2026-09-08, chưa commit; identity được lưu bằng [artifact manifest](evidence/artifacts.sha256). Không giả định đã có analysis git commit.

## Dependencies

[submodules.log](evidence/BASE-01/submodules.log) lưu 18 gitlink đều có dấu `-`, tức chưa initialized. Một số dependency quan trọng:

| Dependency | Gitlink dự kiến | Ảnh hưởng |
|---|---|---|
| `core/cvfpu` | `3eb6afeab2cb33f7d8689222955d0171aeb3a801` | FP package/RTL thiếu; cấu hình F/D bật |
| `core/cache_subsystem/hpdcache` | `f404e7ebbda8baa4af3729535f520a6b12a06d03` | Nhánh HPDCache không chọn, nhưng flist vẫn có dependency |
| `corev_apu/riscv-dbg` | `e19d69efe7d7e4da6c25ed91d5e7f501ab52dd68` | DMI/JTAG/debug module |
| `corev_apu/rv_plic` | `5b5c5a4c1c15c3d7bb833071d344b2c2bc5f599d` | Nội bộ PLIC chưa đọc được |
| `corev_apu/axi_mem_if` | `b494701501886ad71ba0c128560cc371610bcf1a` | `axi2mem` cho ROM/RAM |
| `verif/core-v-verif`, `verif/sim/dv` | Xem log đầy đủ | UVM agent, generator và ISS flow thiếu |

Gitlink ghi revision **được yêu cầu**, không chứng minh recursive tree đã tồn tại. Vendor AXI/common_cells được giữ trong tree chính; Bender có nguồn dependency riêng, không thay thế gitlink/bản vendor một cách tự động trong kết luận. Recursive dependency bên trong submodule chưa initialized vẫn UNKNOWN (OQ-02).

## Execution snapshot

Host Linux x86_64; tool versions trong các `tool-*.log`; Questa compiler/runtime 10.7c (2018.08). Chỉ ghi environment chọn lọc trong [baseline.json](evidence/BASE-01/baseline.json); không dump license/credentials.

`CVA6_REPO_DIR`, `TARGET_CFG`, `RISCV`, `VERILATOR_INSTALL_DIR`, `HPDCACHE_DIR`, `SPIKE_TANDEM` đều unset tại preflight. Target dự kiến được chỉ định tường minh trong command; không đồng nhất với môi trường chạy thành công.

- **EXP-01:** `make -n verilate target=cv64a6_imafdc_sv39` trả 2: Verilator không tìm thấy và Makefile dừng tại `RISCV not set`. Đây là dry-run thất bại, chưa compile CPU.
- **EXP-02:** textual preflight với 3 biến thay thế cụ thể: 182 nguồn, 63 nguồn thiếu, chưa preprocess hoặc resolve hierarchy.
- **EXP-03:** `vlog` compile 3 package thật và `tb_config` thành công (0 errors, 0 warnings); `vsim` trả 4, `Invalid license environment`. Các assertion trong initial chưa chạy; negative check NOT-RUN.

Firmware ELF: chưa chọn/chưa build. Boot ROM SV/S/DT source có trong manifest nhưng chưa regenerate, chưa đối chiếu binary. DPI/Spike libraries chưa được xác lập. Không có seed runtime, waveform, model hierarchy, coverage, CDC, synthesis, STA hay silicon result cho baseline này.

## Tái lập và re-baseline

Từ root repository:

```bash
python3 docs/dungpc/evidence/collect_baseline.py --out /tmp/cva6-baseline-recheck
python3 docs/dungpc/evidence/run_config_probe.py --out /tmp/cva6-config-recheck
```

Các script ghi vào output riêng, không fetch/install. Để dựng CPU sau này: khởi tạo dependency đúng gitlink; xác lập toolchain + simulator + model/DPI; chọn firmware; chạy command Makefile; lưu expanded invocation, hierarchy và report. Đây là **thủ tục cần thực hiện**, không phải log thành công hiện tại.

Khi đổi RTL, config, flist, macro, generator, vendor/model, tool hoặc firmware: tạo BASE mới, giữ bằng chứng cũ, so digest transitive dependency; đánh dấu affected findings NEEDS-RECHECK. Không dùng một HEAD giống nhau để bỏ qua dirty source/model khác nhau.
