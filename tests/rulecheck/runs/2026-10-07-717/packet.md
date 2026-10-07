THE PACKET

Decision kind: expectation
Subject: #235: Pyron's air throw added to audit_tenant_throw_geometry, its no-hold victims declared
Claim (the working agent's sentence): Add Pyron's air throw (j.6MP and j.6HP, rows ('11','airm') and ('11','airh')) to tests/audit_tenant_throw_geometry.sh for #235, frozen at seq {10}, tail (0,0), no damage residue, arc set {73,74,75,76,77,84,93}, over the 13 victims that hold, with victims 00 05 06 0d 0e DECLARED no-hold: a declared victim must show no captured frame on either leg AND both of its legs must be proven live (all 320 window frames dumped with Pyron's and the victim's +0x60 base), an undeclared victim that never holds stays VOID. The five existing rows are byte-identical (build/agent194/t235b/EXPECTATION_DIFF.md). The frozen values come from the #235 measurement on ERIS (an_main.txt, PROVENANCE.sha1: merged-m23 vs native vs2 at level 06 and RNG 0000, the 2026-09-25 ruled equalised input) and are re-measured by the gate itself on ERIS on the fork commit 84416c7d (gate_normal.log PASS; the runner with --controls GREEN, PASS 7, emu_235b/results.tsv), whose gate and replays are byte-identical to the ones staged here (provenance_main_vs_fork.txt). Three new controls (nohold-dropped, nohold-overdeclared, nohold-dead-leg) each fire in-gate and reach the gate's own FAIL as a mode. NOT TESTED: why the five victims never hold (both games agree); other leads and press offsets; that the held move carries the name Galactic Throw beyond its input and the seq at the first held frame; FBNeo and MiSTer. Pyron and Donovan have no kick throw and Donovan no air throw (measured in an_main.txt's companion runs of the #235 fork: those inputs give normals on both games), so no other rows are added.
Artifacts (read every one, in full):
  - tests/audit_tenant_throw_geometry.sh
  - tests/replays/judge/05_air_throw_mp.rpl
  - tests/replays/judge/06_air_throw_hp.rpl
  - build/agent194/t235b/EXPECTATION_DIFF.md
  - build/agent194/t235b/gate_full.diff
  - build/agent194/t235b/an_main.txt
  - build/agent194/t235b/PROVENANCE.sha1
  - build/agent194/t235b/cmp_inputs.sh
  - build/agent194/t235b/gate_normal.log
  - build/agent194/t235b/runner.log
  - build/agent194/t235b/emu_235b/results.tsv
  - build/agent194/t235b/emu_235b/audit_tenant_throw_geometry@nohold-dropped.log
  - build/agent194/t235b/emu_235b/audit_tenant_throw_geometry@nohold-overdeclared.log
  - build/agent194/t235b/emu_235b/audit_tenant_throw_geometry@nohold-dead-leg.log
  - build/agent194/t235b/provenance_main_vs_fork.txt
