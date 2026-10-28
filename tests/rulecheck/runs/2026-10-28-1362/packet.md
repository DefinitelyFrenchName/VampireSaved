THE PACKET

Decision kind: expectation
Subject: land the throw-recovery gate's ground and air families and their frozen hash sets (14z-211, #330 stays open)
Claim (the working agent's sentence): CLAIM: land tests/audit_throw_recovery.sh (ground and air families), tools/throw_recovery_rigs.py, tools/throw_recovery_sheet.py and the seven frozen hash sets tests/expected/throw_recovery.tsv, _v01.tsv, _v0e.tsv (the ground throws on Victor, Demitri, Lilith), _air.tsv, _air_h-3.tsv, _air_h+3.tsv, _air_h+6.tsv (the air throws at four heights), with the ground and air rows classified on docs/project/tables/community_crosscheck.md, in the 14z-211 close commit; #330 STAYS OPEN (its command throws are not frozen). It rests on:
1. THE RULINGS AND READINGS: DECISIONS_HISTORY.md.lines-8582-8696 — "First accepted input (Recommended)", "New gate, Victor only (Recommended)", "Against the 3-victim range (Recommended)", "Against a height range (Recommended)", "Now, before the close", "Measure them too", "Commit ground+air, rest next (Recommended)", and the maintainer's reading of the capture sheets ending "Yes, commit them".
2. THE CAPTURES: throw_recovery_tech.png (TECH. HIT on the k = 1 and k = 7 rows, none at k = 8 or untouched), throw_recovery_ground.png and throw_recovery_air-lp.png (each LP pair with the presser's +0x04 dumped under every tile by the same run: the normal's state from A in the ON rows, never in the BEFORE rows), throw_recovery_air-throw.png (the air throw from the jump: the #229 level-6 rig against the gate's level-0 one, three characters), drawn by tools/throw_recovery_sheet.py from the gate's own rigs.
3. THE MEASUREMENT: notes.md — probes 1-7b (the pilot's mode-byte predicate refused on 22 of 42, the acceptance scans, the first-event artifact), the air sections (the level-0 re-timing: y and dx at the commit equal the level-6 rigs'; the heights), the captures section (the state captions; the command defect).
4. THE GATE: gate_run5.log (the default run, ground 42 and air 28 events, every clause, every full line equal to its hash, the in-gate controls FIRED, PASS); gate_mode4_*.log (each mode FIRED on every applicable ground and air event); verify_ground_v03.log, verify_ground_v01.log, verify_ground_v0e.log and verify_air_h-3.log, verify_air_h3.log, verify_air_h6.log (each on-demand set PASS, its controls fired).
5. THE CLASSIFICATION: xc_tr_ground.txt and xc_tr_air.txt carried onto docs/project/tables/community_crosscheck.md.lines-441-517 (the command rows, .lines-601-621, say not measured yet and why); the classifier fixtures, test_crosscheck_229.log (48 cases, seven controls fired).
6. THE RECORDS: docs/game/engine_internals.md.lines-3613-3642, docs/project/gotchas.md.lines-7724-7768.
NOT TESTED: FBNeo; speed levels other than 0 for the gate (the pilot measured the window and recovery level-independent in ticks on one throw, probe 2); mashed throws; the air throws on victims other than Victor and Demitri-for-Victor (the first runs on Demitri and Lilith failed and are not landed: air_victims.out) — the ground throws' tech advantage moves with the victim by up to 4 ticks, so the air tech classification rests on heights alone; the air throws at heights other than the four; the characters picked by the cursor (forced by poke). The captures show the timing on six events (FE 6MP thrower and victim, QB 6MP, VI 6MK teched, FE j.6MP, AU 6MP) and the tech on two throws, not on all 70; the other events rest on the gate's acceptance clauses alone. The picture lags the dumped state by 2-4 frames, read from those rows, not measured as a rule. The command throws' measurements (gate_run4.log's command section) are not landed: 28 of their whiffs were normals. The static tier on the staged tree has not run yet: it runs after this check, before the commit.
Artifacts (read every one, in full):
  - build/agent211/t330/closure/notes.md
  - build/agent211/t330/closure/gate_run5.log
  - build/agent211/t330/closure/gate_mode4_tick-early.log
  - build/agent211/t330/closure/gate_mode4_lp-tech.log
  - build/agent211/t330/closure/gate_mode4_late-window.log
  - build/agent211/t330/closure/verify_ground_v03.log
  - build/agent211/t330/closure/verify_ground_v01.log
  - build/agent211/t330/closure/verify_ground_v0e.log
  - build/agent211/t330/closure/verify_air_h-3.log
  - build/agent211/t330/closure/verify_air_h3.log
  - build/agent211/t330/closure/verify_air_h6.log
  - build/agent211/t330/closure/xc_tr_ground.txt
  - build/agent211/t330/closure/xc_tr_air.txt
  - build/agent211/t330/closure/test_crosscheck_229.log
  - build/agent211/t330/closure/throw_recovery_tech.png
  - build/agent211/t330/closure/throw_recovery_ground.png
  - build/agent211/t330/closure/throw_recovery_air-lp.png
  - build/agent211/t330/closure/throw_recovery_air-throw.png
  - DECISIONS_HISTORY.md.lines-8582-8696 (lines 8582-8696 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-211) — #330: "actionable" is the engine's return to its neutral state; the ", and the entries after it up to line 8696)
  - docs/project/tables/community_crosscheck.md.lines-441-517 (lines 441-517 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-601-621 (lines 601-621 of docs/project/tables/community_crosscheck.md)
  - docs/game/engine_internals.md.lines-3613-3642 (lines 3613-3642 of docs/game/engine_internals.md)
  - docs/project/gotchas.md.lines-7724-7768 (lines 7724-7768 of docs/project/gotchas.md)
  - tests/audit_throw_recovery.sh
  - tools/throw_recovery_rigs.py
  - tools/throw_recovery_sheet.py
  - build/agent211/t330/air_victims.out
