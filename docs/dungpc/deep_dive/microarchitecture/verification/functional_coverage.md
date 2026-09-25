# Functional Coverage Plan

**Status:** specified, not collected.

| Cover group | Coverpoints | Required crosses |
|---|---|---|
| Issue/forwarding | FU type; source register class; RAW distance; source from RF/writeback/scoreboard | FU × forwarding source × stall length |
| Scoreboard | allocation ID; completion order; occupancy 0..8; commit width 0/1/2 | occupancy × completion inversion × commit width |
| Branch | type; predicted direction/target; actual direction; queue occupancy | mispredict kind × younger occupancy × older outstanding FU |
| Load | hit/miss; DTLB hit/miss; buffer ID; size/sign; flush phase | hit/miss × dependency × response-after-flush |
| Store | size; queue occupancy; merge; flush before/after commit; AXI backpressure | ownership stage × flush × error response |
| PTW | requester I/D; level 2/1/0; leaf/pointer/invalid; PMP allow; flush state | level × PTE class × concurrent SFENCE |
| PMP | entry 0..7/no match; OFF/TOR/NA4/NAPOT; R/W/X; M/S/U; lock | mode × privilege × access × boundary result |
| Cache | I/D hit/miss/NC; killed stage; refill error; flush | miss × kill point × response timing |
| AXI | channel; ready delay; outstanding depth; response code; reset epoch | AW/W ordering × B delay; AR × R beats × reset |
| Trap | exception cause; interrupt cause; source stage; target privilege | cause × privilege × concurrent redirect/debug |
| Debug | entry cause; current privilege; WFI/memory stall; pending interrupt | cause × pending IRQ × DRET destination |
| Fence | FENCE/FENCE.I/SFENCE; store/PTW occupancy | subtype × waited resource × wait cycles |

## Coverage completion rule

Each required trace must hit its named cross and its paired assertion. Coverage bins that cannot occur under CFG-01, including hypervisor, vector, Zcmt, and configured non-idempotent-region behavior, must be marked excluded with the configuration expression as justification.
