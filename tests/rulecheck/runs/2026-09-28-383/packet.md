THE PACKET

Decision kind: expectation
Subject: build/manifest/walker_ghost.toml re-frozen on the live stack; tests/audit_walker_ghost.sh re-stated (#143, ruled "Freeze the real ranges")
Claim (the working agent's sentence): Freeze build/manifest/walker_ghost.toml to the LIVE walker stack ranges, and commit tests/audit_walker_ghost.sh re-stated as the maintainer ruled. The ruling (maintainer_143.txt): asked what the ghost gate should check, the maintainer first asked "what's the cost/benefit analysis of all 3 options, given all the existing gates and instruments?", then chose "Freeze the real ranges (Recommended)". The findings it rests on passed rule-checker run 2026-09-28-382.
WHAT CHANGES.
- tests/lua/walker_sp.lua (walker_sp_lua.diff) reads the live pointer by SR's S bit, SP or USP, where it read `A7 or SP`. It adds MODE and RET lines per site. WALKER_SP_READ=sp forces the old read, for the control only.
- tools/walker_ghost.py (new) reads the runs with four checks:
  (a) LIVE: the site fired;
  (b) GROUND: every long on top of the read stack ends a `jsr abs.l` to the walker (site - 0x1E) in the vsavj opcode image;
  (c) VISIBLE: the push [min-4, max-1] overlaps no range of the union of tests/expected/**/mask;
  (d) FROZEN: (sp_min, sp_max) equal walker_ghost.toml's.
- tests/audit_walker_ghost.sh (audit_walker_ghost.before.sh, audit_walker_ghost.after.sh) runs the same corpus as before on pristine vsavj (every replay with a vanilla basis log, 56), plus one control run. Its header RETRACTS the inside-the-mask premise, and three MUST-FIRE controls are declared.
- walker_ghost.toml (walker_ghost_toml.diff): 0x54476 goes from 0xff7ff6..0xff7ff6 to 0xff06de..0xff06de; 0x5e548 from 0xff7ff6..0xff7ff6 to 0xff055e..0xff06de, with hits 315,008 in 56 replays.
THE RUNS.
- Before the freeze (gate_before_freeze.log): (a) (b) (c) pass at both sites; (d) FAILs against the old 0xff7ff6 on both.
- The freeze (gate_freeze.log) and a plain run after it (gate_plain.log): PASS, "frozen ... — as measured" at both sites.
- In-gate controls, all FIRED (gate_plain.log):
  - supervisor-read: the SP read of 21_don_mash reads "0 of 624 longs ... end a `jsr abs.l 0x054458`";
  - range-moved: the frozen sp_min shifted by 2;
  - mask-covers: an extra mask ff0550-ff06e0.
- CONTROL=supervisor-read, CONTROL=range-moved and CONTROL=mask-covers each FAIL the gate (gate_ctl_*.log).
- tests/audit_walker_repoint.sh, the instrument's other consumer, still PASSes on merged-m20 with its reference hit counts 1243 / 40236 (repoint.log).
THE RETRACTION. The inside-the-mask claim is marked RETRACTED, with what replaced it, in engine_internals.md, build/manifest/donovan.toml's comment, gen_donovan_patch.py's comment, the gate header and the gotcha entries. retraction_regrep.txt lists every remaining hit: correct facts about the supervisor stack, text marked retracted, and one unrelated masked-blob fact (gen_donovan_patch.py:4537).
NOT covered (the gate says so): the legacy oracle's window, composite and flicker verdicts tolerate divergences inside ratified ranges, and whether a push survives to a checksum there is not measured. Not covered either: FBNeo and MiSTer; the replays outside the corpus.
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
  - build/agent185/t143/retraction_regrep.txt
  - tools/walker_ghost.py
  - build/manifest/walker_ghost.toml
