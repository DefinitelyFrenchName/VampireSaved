THE PACKET

Decision kind: expectation
Subject: #235: Pyron's air throw added to audit_tenant_throw_geometry, its no-hold victims declared and their attempt checked (after run 717)
Claim (the working agent's sentence): Add Pyron's air throw (j.6MP and j.6HP, rows ('11','airm') and ('11','airh')) to tests/audit_tenant_throw_geometry.sh for #235, after rule-checker run 2026-10-07-717 (VIOLATED Q1 Q2 Q4 Q5, resolved by work): frozen at seq {10}, tail (0,0), no damage residue, arc set {73,74,75,76,77,84,93}, over the 13 victims that hold, with victims 00 05 06 0d 0e DECLARED no-hold. In tests/audit_tenant_throw_geometry.sh a declared victim must show no captured frame on either leg, both of its legs must be live (every one of the 320 window frames dumped with Pyron's and the victim's +0x60 base), and Pyron must have attempted the throw on both legs (airborne at the press frame 3034, his seq entering 06.06 from 06.xx), checked by the controls nohold-dead-leg and nohold-no-attempt; an undeclared victim that never holds stays VOID, checked by nohold-dropped. The five existing rows are byte-identical (EXPECTATION_DIFF.md). The frozen values come from the #235 measurement on ERIS (an_main.txt; the replays it used and their input-line equality with judge/05 and judge/06 shown by command and output in Q1_PROVENANCE.txt) at speed level 06 and RNG 0000 on both legs, the ruled equalised input (DECISIONS_HISTORY.md lines 1098-1112), and are re-measured by the gate on ERIS on commit ec3a0a6b (FINAL_gate_normal_ec3a0a6b.log PASS; the runner with --controls GREEN, PASS 8, emu_ec3a0a6b/results.tsv), whose gate and replays are byte-identical to the ones staged here (provenance_main_vs_fork.txt). Four controls of the no-hold declaration (nohold-dropped, nohold-overdeclared, nohold-dead-leg, nohold-no-attempt) each fire in-gate and reach the gate's own FAIL as a mode (emu_ec3a0a6b/*.log). The maintainer read the keyframe-matched capture sheet (pyron_air_throw_j6hp_sheet.jpg: victims 03 and 0c held, 05 declared) as identical between ours and native vs2 (maintainer_read.txt, verbatim). NOT TESTED: why the five victims are never held (the maintainer: possibly impossible, possibly the throw box sitting high; both games agree); other leads and press offsets; that the held move carries the name Galactic Throw beyond its input and the seq at the first held frame; FBNeo and MiSTer; Pyron's and Donovan's kick throws and Donovan's air throw, which the #235 measurement found holding on 0 of 18 victims on both games and which therefore get no rows.
Artifacts (read every one, in full):
  - tests/audit_tenant_throw_geometry.sh
  - tests/replays/judge/05_air_throw_mp.rpl
  - tests/replays/judge/06_air_throw_hp.rpl
  - build/agent194/t235b2/EXPECTATION_DIFF.md
  - build/agent194/t235b2/gate_full.diff
  - build/agent194/t235b2/an_main.txt
  - build/agent194/t235b2/Q1_PROVENANCE.txt
  - build/agent194/t235b2/Q1_3_ANSWER.md
  - build/agent194/t235b2/FINAL_gate_normal_ec3a0a6b.log
  - build/agent194/t235b2/FINAL_runner_ec3a0a6b.log
  - build/agent194/t235b2/emu_ec3a0a6b/results.tsv
  - build/agent194/t235b2/emu_ec3a0a6b/audit_tenant_throw_geometry@nohold-dropped.log
  - build/agent194/t235b2/emu_ec3a0a6b/audit_tenant_throw_geometry@nohold-overdeclared.log
  - build/agent194/t235b2/emu_ec3a0a6b/audit_tenant_throw_geometry@nohold-dead-leg.log
  - build/agent194/t235b2/emu_ec3a0a6b/audit_tenant_throw_geometry@nohold-no-attempt.log
  - build/agent194/t235b2/provenance_main_vs_fork.txt
  - build/agent194/t235b2/maintainer_read.txt
  - build/agent194/t235b2/pyron_air_throw_j6hp_sheet.jpg
  - DECISIONS_HISTORY.md.lines-1098-1112 (lines 1098-1112 of DECISIONS_HISTORY.md)
