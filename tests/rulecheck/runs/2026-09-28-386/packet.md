THE PACKET

Decision kind: expectation
Subject: build/manifest/walker_ghost.toml re-frozen on the live stack; tests/audit_walker_ghost.sh re-stated with a relocated leg (#143, ruled "Freeze the real ranges"; re-checked after 385)
Claim (the working agent's sentence): Freeze build/manifest/walker_ghost.toml to the LIVE walker stack ranges, and commit tests/audit_walker_ghost.sh re-stated as the maintainer ruled. The ruling (maintainer_143.txt): asked what the ghost gate should check, the maintainer first asked "what's the cost/benefit analysis of all 3 options, given all the existing gates and instruments?", then chose "Freeze the real ranges (Recommended)". The findings it rests on passed rule-checker run 2026-09-28-382.
WHAT CHANGES.
- tests/lua/walker_sp.lua (walker_sp_lua.diff) reads the live pointer by SR's S bit, SP or USP, where it read `A7 or SP`. It adds MODE and RET lines per site. WALKER_SP_READ=sp forces the old read, for the control only.
- tools/walker_ghost.py (new) reads the runs with four checks:
  (a) LIVE: the site fired;
  (b) GROUND: every long on top of the read stack ends a `jsr abs.l` to the walker (site - 0x1E) in the vsavj opcode image;
  (c) VISIBLE: the push [min-4, max-1] overlaps no range of the union of tests/expected/**/mask. That is all it checks; it does not measure that the oracle compares every byte outside those masks. One byte was planted once (plant_ctl.sh, plant_ctl.log): at $FF06DA, under the oracle's own replay.lua and mask, on the exact replay 01_attract_long, it moved the checksum. The rest of $FF055A-$FF06DD and the other replays were not planted.
  (d) FROZEN: (sp_min, sp_max) equal walker_ghost.toml's.
- tests/audit_walker_ghost.sh (audit_walker_ghost.before.sh, audit_walker_ghost.after.sh) runs the same corpus as before on pristine vsavj (every replay with a vanilla basis log, 56), plus one control run. Its header RETRACTS the inside-the-mask premise, and three MUST-FIRE controls are declared. Its WHAT line says the push lands outside every mask, "so no mask hides it from the per-frame oracle's checksum"; whether the oracle's verdicts catch a differing byte there is pointed to NOT covered.
- It also runs a RELOCATED leg: the same corpus on the build under test (default build/m3b_merged28, which is merged-m20 per HANDOFF.md:1610), at the relocated walkers' `jsr (A0)` sites. The sites are derived from the build's own call sites 0x0053F6 and 0x009436: copy + 0x1E. The reader checks that leg against the build's own opcode image, and --map compares each relocated site's live range with its vanilla site's frozen range.
- walker_ghost.toml (walker_ghost_toml.diff): 0x54476 goes from 0xff7ff6..0xff7ff6 to 0xff06de..0xff06de; 0x5e548 from 0xff7ff6..0xff7ff6 to 0xff055e..0xff06de, with hits 315,008 in 56 replays.
THE RUNS.
- Every log below except gate_before_freeze.log was produced AFTER the last edit to tests/audit_walker_ghost.sh, tools/walker_ghost.py and tests/lua/walker_sp.lua (the logs of rule-checker run 385's packet are kept as *.pre385.log and are not artifacts).
- Before the freeze (gate_before_freeze.log, vanilla leg only, run before the relocated leg existed): (a) (b) (c) pass at both sites; (d) FAILs against the old 0xff7ff6 on both. That run also predates the reader's bounds guard (tools/walker_ghost.py's w16 treats a value beyond the image as no code address). Its supervisor-read control crashed there with IndexError and read DEAD; with the guard it FIRES (gate_plain.log).
- The freeze (gate_freeze.log, re-run on the final code: walker_ghost.toml came out byte-identical, cmp) and a plain run (gate_plain.log, 88 s): PASS, "frozen ... — as measured" at both vanilla sites. The relocated leg (gate_plain.log) is also clean at both sites, 0x4C12AE and 0x4C141E: the S bit is clear on every hit; ground truth holds on 8,591 of 8,591 and 313,113 of 313,113 longs, each ending a `jsr abs.l` to the relocated copy (0x4C1290 / 0x4C1400); and each live range equals its vanilla site's frozen range.
- In-gate controls, all FIRED (gate_plain.log):
  - supervisor-read: the SP read of 21_don_mash reads "0 of 624 longs ... end a `jsr abs.l 0x054458`". Its MODE now forces the SP read on BOTH legs, and GROUND fails at all four sites, vanilla 0x54476/0x5E548 and relocated 0x4C12AE/0x4C141E (gate_ctl_supervisor-read.log);
  - range-moved: the frozen sp_min shifted by 2;
  - mask-covers: an extra mask ff0550-ff06e0.
- CONTROL=supervisor-read, CONTROL=range-moved and CONTROL=mask-covers each FAIL the gate (gate_ctl_*.log).
- tests/audit_walker_repoint.sh, the instrument's other consumer, still PASSes (repoint.log). On build/m3b_merged28 (merged-m20) the vanilla walkers are reached 0 times and the relocated ones 1140 and 39934 times. On the un-relocated reference build/don_m5 the vanilla ones are reached 1243 and 40236 times.
THE RETRACTION. The inside-the-mask claim is marked RETRACTED, with what replaced it, in engine_internals.md, build/manifest/donovan.toml's comment, gen_donovan_patch.py's comment, the gate header and the gotcha entries. The 14z-91 inference "not inside the window, so not bit-identical: the design stops" is marked too, in walker_sp.lua's WHY paragraph and the gate's WHY block: the relocation is live on merged-m20 and tests/audit_merged_legacy.sh lands all 53 legacy pairings on their ratified classes there (merged_legacy_m20base.log). retraction_regrep.txt is produced by regrep.sh, which prints its pattern, scope and the sha1 of each carrier as searched, run after the last edit. It lists every remaining hit: correct facts about the supervisor stack, text inside a RETRACTED marker's scope, the STATE row describing the retraction, and one unrelated masked-blob fact (gen_donovan_patch.py:4537).
NOT covered (the gate says so): the legacy oracle's window, composite and flicker verdicts tolerate divergences inside ratified ranges, and whether a push survives to a checksum there is not measured. Not covered either: that the oracle compares every byte outside its masks (only the one planted byte is measured); FBNeo and MiSTer; the replays outside the corpus.
Artifacts (read every one, in full):
  - build/agent185/t143/maintainer_143.txt
  - build/agent185/t143/walker_sp_lua.diff
  - build/agent185/t143/audit_walker_ghost.before.sh
  - build/agent185/t143/audit_walker_ghost.after.sh
  - build/agent185/t143/walker_ghost_toml.diff
  - build/agent185/t143/gate_before_freeze.log
  - build/agent185/t143/gate_freeze.log
  - build/agent185/t143/gate_plain.log
  - build/agent185/t143/gate_ctl_supervisor-read.log
  - build/agent185/t143/gate_ctl_range-moved.log
  - build/agent185/t143/gate_ctl_mask-covers.log
  - build/agent185/t143/repoint.log
  - build/agent185/t143/regrep.sh
  - build/agent185/t143/retraction_regrep.txt
  - build/agent185/t143/merged_legacy_m20base.log
  - build/agent185/t143/plant_ctl.sh
  - build/agent185/t143/plant_ctl.log
  - tools/walker_ghost.py
  - build/manifest/walker_ghost.toml
  - HANDOFF.md.lines-1610-1610 (lines 1610-1610 of HANDOFF.md)
