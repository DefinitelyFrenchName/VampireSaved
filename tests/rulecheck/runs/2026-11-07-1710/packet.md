THE PACKET

Decision kind: recommendation
Subject: close #365 and #366 done: the sheet census's missing declaration, the two stale gate headers and the reach gate's blind fall-through control (14z-223)
Claim (the working agent's sentence): #365 and #366 can be closed done, with the closing comments build/agent223/t366/closing_365.md and build/agent223/t366/closing_366.md, on the staged change (build/agent223/t366/staged.diff.txt; the five regenerated index files left out of that diff). #365: tests/audit_crash_sweep_emu.sh declares `# SHEET: none — an instrument, emulator, release or host check; no leg of our build compared with a reference set`, and tests/test_sheet_census.sh, run alone, PASSes with 0 gates on the debt list and its 7 controls FIRED (sheet_census.log), so no gate of tests/ci_emulator.tsv lacks a line. #366: tests/test_dead_span_reach.sh's header states both frozen spans (#294's and #363's), each span's verdict per track, and judged-pairs 10; tests/audit_pass_overrun.sh's header, tests/ci_emulator.tsv's row, docs/game/engine_internals.md and docs/project/sheet_notes.md state ours has no overrun since M25, as tests/expected/pass_overrun.tsv's ours rows (none on all three parts) hold. The issue's open question is answered yes, on a measurement: the 22 plants run by hand on #363's span with the tool as it stood (span2_plants_before_fix/) show fall-through REACHED ONLY with the fence held, because the plant nopped the 4 bytes before the span and #363's fence is a 6-byte jmp.l at PRG:0x029CB4; the plant now overwrites every reached instruction ending at the span start, whole, and the gate plants every control on every span, FIRED only when it fails every span by its own rule, the modes on the first span. At the working tree the gate PASSes with judged-pairs 10 and 22 of 22 controls FIRED on both spans (reach_after.log), the fall-through mode reaches its own FAIL (mode_fall-through.log), and tests/test_dead_span.sh, the tool's other reader, PASSes (dead_span.log). Both changed scripts on the concurrent-controls lists were write-traced on PILOT at the scratch commit 3d90dfaa: test_dead_span_reach 22 HONOURED SAFE, test_release_binaries 4 HONOURED SAFE (pilot/rt223_meta/), and their rows name the traced blobs. The gotcha is in docs/project/gotchas.md. NOT TESTED: audit_pass_overrun was not re-run (its code and frozen data are unchanged; only header words moved); the reach gate's own "Stated, not tested" items (an address formed at run time from no constant; run-time reach of an accepted base or row; what each jump does; code outside the declared ranges); the control modes plant on the first span only; the census's ondemand cadence still lets a later gate without a line go unseen until someone runs it.
Artifacts (read every one, in full):
  - build/agent223/t366/closing_365.md
  - build/agent223/t366/closing_366.md
  - build/agent223/t366/staged.diff.txt
  - build/agent223/t366/audit_dead_span.py.txt
  - build/agent223/t366/test_dead_span_reach.sh.txt
  - build/agent223/t366/audit_pass_overrun.sh.txt
  - build/agent223/t366/audit_crash_sweep_emu.sh.txt
  - build/agent223/t366/reach_before.log
  - build/agent223/t366/reach_after.log
  - build/agent223/t366/mode_fall-through.log
  - build/agent223/t366/dead_span.log
  - build/agent223/t366/sheet_census.log
  - build/agent223/t366/span2_plants_before_fix/fallthrough.out
  - build/agent223/t366/span2_plants_before_fix/jsr.out
  - build/agent223/t366/span2_plants.sh
  - build/agent223/t366/pilot/rt223_meta/prep
  - build/agent223/t366/pilot/rt223_meta/classes.tsv
  - build/agent223/t366/pilot/rt223_meta/score_static.txt
  - build/agent223/t366/pilot/rt223_meta/score_emu.txt
  - tests/expected/pass_overrun.tsv
  - tests/expected/dead_span_reach.tsv
