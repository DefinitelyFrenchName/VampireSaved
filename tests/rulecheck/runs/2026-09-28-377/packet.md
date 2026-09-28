THE PACKET

Decision kind: recommendation
Subject: #143: walker_sp.lua reads the live stack by SR; audit_walker_ghost's inside-the-mask premise retracted and re-stated (the walker sites run in user mode, measured)
Claim (the working agent's sentence): Recommend to the maintainer, for #143: change tests/lua/walker_sp.lua to read the LIVE stack, chosen by SR's S bit, and re-state tests/audit_walker_ghost.sh on the live stack. The maintainer filed #143 with "yes but we probably want to be cautious when solving it" (DECISIONS_HISTORY.md:1503-1506), and queued it: "do #160, #155, #143 and #182 in that order" (maintainer_queue_14z185.txt). The issue's first three steps were done with the instrument UNCHANGED.
WHICH STACK IS LIVE. A probe copy of walker_sp.lua (walker_sp_probe.lua; its diff only ADDS the SR, SP and USP reads and the long at each) ran the ghost audit's own legs: probe.sh, every legacy replay with a vanilla basis log (56), pristine vsavj, sites 0x54476 and 0x5E548. aggregate.log:
- Every hit ran in USER mode: the S bit is clear on all 8,586 hits at 0x54476 and all 315,008 at 0x5E548, set on none.
- walker_sp.lua's own read (A7 or SP) is 0xFF7FF6 at both sites, the same as SP, the supervisor stack. That is the value build/manifest/walker_ghost.toml froze (sp_min = sp_max = 0xff7ff6).
- USP, the user stack, reads 0xFF06DE at 0x54476 and 0xFF055E..0xFF06DE at 0x5E548.
GROUND TRUTH (ground_truth.log, the vsavj opcode image). A genuine return address is preceded by a call ending exactly on it. The long at USP is, on 323,594 of 323,594 hits: 10 distinct values, each the return of a `jsr abs.l` to a walker (0x05E52A or 0x054458). The long at SP is, on 0 of 323,594: three work-RAM addresses (0xFF027C, 0xFF029C, 0xFF02DC).
WHAT EACH CONSUMER MEASURED.
- tests/audit_walker_repoint.sh uses only HIT COUNTS (its total_for sums the hits field), so no stack value reaches its verdict.
- tests/audit_walker_ghost.sh asserts the relocated `jsr (A0)` push, [A7-4, A7-1], lies inside the masked dead-stack window $FF7F00-$FF7FFF. Its A7 was the idle supervisor stack, so its PASS says nothing about the walker's push. On the live stack the push lands at USP-4..USP-1: $FF06DA-$FF06DD at 0x54476, and within $FF055A-$FF06DD at 0x5E548. That is outside the window, so the premise does not hold.
- The relocation is live on merged-m20 (relocation_m20.log): the ten walker call sites jump to 0x4C1400 / 0x4C1290 there, against 0x05E52A / 0x054458 on pristine vsavj.
- The merged legacy oracle's mask (oracle_mask.txt: 043c-043d,4182-41a2,41c2-41e2,4222-4262,7f00-8000) does not cover $FF055A-$FF06DD. On M20 it passed "53/53 legacy pairings evaluated" (merged_legacy_m20base.log). So on those 53 replays the pushed value is gone by every compared frame; the mechanism (a later write to the same slot) is inferred, not measured.
THE RECOMMENDATION.
(1) walker_sp.lua reads `(SR & 0x2000) ~= 0 and SP or USP`, the rule docs/platform/gotchas.md:2653-2673 already states. The ground truth above goes into the gate that consumes it.
(2) audit_walker_ghost.sh's "inside the mask" premise is RETRACTED, in its header, walker_ghost.toml and the docs. The gate re-freezes walker_ghost.toml to the live ranges through its own --freeze, and asserts the push lands OUTSIDE every legacy-oracle mask, so a ghost that survived to a checksum would fail the oracle.
(3) Today's duplicate gotcha (the #176 entry on SP and USP) is reconciled with the 14z-158 entry.
NOT tested: which write replaces each pushed slot before the checksum; FBNeo, where $FF06D0-$FF06EF is a ratified phase class; MiSTer; replays outside the 56 and the 53.
Artifacts (read every one, in full):
  - build/agent185/t143/walker_sp_probe.lua
  - build/agent185/t143/probe.sh
  - build/agent185/t143/aggregate.log
  - build/agent185/t143/ground_truth.log
  - build/agent185/t143/relocation_m20.log
  - build/agent185/t143/oracle_mask.txt
  - build/agent185/t143/merged_legacy_m20base.log
  - build/agent185/maintainer_queue_14z185.txt
  - tests/lua/walker_sp.lua
  - tests/audit_walker_ghost.sh
  - tests/audit_walker_repoint.sh
  - build/manifest/walker_ghost.toml
  - docs/platform/gotchas.md.lines-2653-2673 (lines 2653-2673 of docs/platform/gotchas.md)
  - DECISIONS_HISTORY.md.lines-1503-1506 (lines 1503-1506 of DECISIONS_HISTORY.md)
