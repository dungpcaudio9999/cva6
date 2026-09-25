# Trace-to-Checker Matrix

| Trace | Primary assertions | Coverage target | Reference model / end check |
|---|---|---|---|
| 01 ALU WB forwarding | live WB ID; forwarded value equality | WB forwarding source | x5/x6 register values |
| 02 scoreboard forwarding | live completed owner; stored-result equality | scoreboard forwarding source | x5/x6 and commit order |
| 03 load hit dependency | response owns live buffer; ID conservation | hit × RAW dependency | memory and x5/x6 |
| 04 load miss dependency | MSHR/ID stability; no early issue | miss × stall length | refill and x5/x6 |
| 05 grant with flush | new entry marked flushed; no writeback | grant × flush same edge | no destination update |
| 06 response after flush | flushed response suppressed and freed | response delay after flush | no stale-ID effect |
| 07 correct prediction | no mispredict flush | correct taken/not-taken | committed PC stream |
| 08 misprediction | exact narrow flush; no wrong-path effect | direction/target miss × occupancy | committed PC stream |
| 09 store to AXI | ownership conservation; channel stability | AW/W order × B delay | external memory bytes |
| 10 store precommit flush | no commit on flush; no downstream request | ownership stage × flush | memory unchanged |
| 11 instruction fault | exception excludes side effect | page/PMP fault × privilege | EPC/cause/tval/vector |
| 12 data protection fault | deny excludes cache request | page/PMP × load/store | destination/memory unchanged |
| 13 IRQ during stall | precise acceptance and ordering | IRQ type × stall length | saved EPC/cause |
| 14 debug plus IRQ | single winner/capture; IRQ preservation | debug cause × IRQ | DPC/DCSR and resume |
| 15 FENCE.I | drain before ack; I-cache invalidation | WT occupancy × I$ line state | new instruction retires |
| 16 SFENCE with PTW | no stale fill; flush completion gate | PTW state × flush | post-fence translation |
| 17 AMO | one request/result; commit waits completion | AMO op × backpressure | old/new memory and rd |
| 18 reset with AXI | epoch isolation; no stale response match | channel × reset phase | no post-reset ghost effect |

All matrix rows are **planned**. No checker or trace has passed until simulation/formal logs are stored under `evidence/logs` and waves under `evidence/waves`.
