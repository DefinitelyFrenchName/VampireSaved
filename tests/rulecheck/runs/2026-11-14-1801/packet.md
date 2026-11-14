THE PACKET

Decision kind: recommendation
Subject: #373: close done — the known-crash rig re-timed for the emulated clock, its mode honoured only on the tripwire's line, its gate off the debt list
Claim (the working agent's sentence): Close #373 `done` with this change, on the maintainer's word ("Do #373 then close", STATE.md line 50; the ticket filed on "a ticket", DECISIONS_HISTORY.md "Ruled 2026-11-13 (14z-227) — the known-crash firing line is a ticket of its own"). Cause: bisected on the Mac with one build/hui41 and one MAME binary (build/agent227/bis/res_*.txt): ce64cb0e (replay_guard.lua on the emulated clock) gives CRASH 20100 vec3 PC 01afb6 and its parent 4980bd96 (build/agent227/kc373/bisect_commits.txt) gives CRASH 14767 vec4 PC 0fb6e0, as do the five other commits sampled back to 79dc2d03 (a7b608c3, ecd67c8a, 34c84efe, d1d90167: each side of the window's earlier changes to the rig's tracked inputs, listed in bisect_commits.txt). At the working tree (build/agent227/rt/res_*.txt): INSTR_CLOCK=frame_done gives CRASH 14767 vec4 PC 0fb6e0; the replay and picks shifted 0/1/2/3/4 frames earlier give vec3 20100 / vec4 14765 PC 0fb6e0 / vec3 9194 / END / END. Fix (tests/audit_guard_corpus.sh): the shift of 1 built at run time by kc_replay (awk; byte-identical to the measured k1 replay: build/agent227/kc373/kc_replay_cmp.txt); the mode HONOURED only through vs_ctl_caught on the soak's findings with KC_WANT 'TRIPWIRE for unresolved 0x494de$'; the plain run executes the rig and prints CONTROL FIRED only when the crash PC's hui41 patch-notes row matches KC_WANT, else CONTROL DEAD and FAIL; the gate's row removed from tests/expected/ctl_caught_debt.tsv; its dead-leg row's stripped class HONOURED -> UNJUDGED-CAUGHT. Evidence, all runs on the gate as it was before its last edit, which changed one comment only (build/agent227/kc373/gate_after_runs.diff against the as-run copy audit_guard_corpus.as_run.sh): Mac (build/agent227/kc373/): mode CAUGHT, classified HONOURED (classes.txt, under sh); plain run with ONLY=107_four_directions LEGS=none FIRED on CRASH 14765 vec4 PC 0fb6e0; a copy with KC_SHIFT=0: mode NOT JUDGED (UNJUDGED-CAUGHT), plain CONTROL DEAD and exit 1; mode with MAME_BIN=/usr/bin/false UNJUDGED, speaker own; test_dead_leg_unjudged with DLU_TABLE holding only this row PASS. PILOT (build/agent227/kc373/pilot/): the gate as a scratch copy (tests/zz_audit_guard_corpus_373.sh) on its 6dea53bc checkout, whose copies of the replay, tools/run_replay_guarded.sh, tests/lua/replay_guard.lua, emu_clock.lua, clock_check.lua, tools/run_mame.sh, tests/lib/controls.sh, classify.sh and build/hui41's patch notes and vsavjw.zip have the Mac's sha1 (build/agent227/kc373/pilot_inputs.txt): full plain soak 388 runs 388 clean with CONTROL FIRED, exit 0; mode CAUGHT, exit 1. NOT TESTED: 259 of the 264 commits in 79dc2d03..4980bd96 (bisect_commits.txt; the five run are a7b608c3, ecd67c8a, 34c84efe, d1d90167, 4980bd96); the full plain soak on the Mac (one replay only) and any run on ERIS; the gate under tests/run_all_emulator.sh (the classification is vs_classify_control called directly); test_dead_leg_unjudged over its whole table (one row); PILOT's runs used a scratch name, so vs_ctl_debt_listed read it unlisted as the staged tree does, but PILOT's own debt list still had the row; the PILOT mode's class was read from its lines, not classified by script; other rigs timed under -debug before 14z-197 not surveyed; why the unshifted rig reaches PC 01afb6 not studied; the shift is exact, so a later timing change to the guard moves the rig again (it would now read DEAD/NOT JUDGED).
Artifacts (read every one, in full):
  - tests/audit_guard_corpus.sh
  - build/agent227/kc373/audit_guard_corpus.as_run.sh
  - build/agent227/kc373/gate_after_runs.diff
  - build/agent227/kc373/bisect_commits.txt
  - build/agent227/kc373/kc_replay_cmp.txt
  - build/agent227/kc373/pilot_inputs.txt
  - build/agent227/bis/res_79dc2d03.txt
  - build/agent227/bis/res_a7b608c3.txt
  - build/agent227/bis/res_ecd67c8a.txt
  - build/agent227/bis/res_34c84efe.txt
  - build/agent227/bis/res_d1d90167.txt
  - build/agent227/bis/res_4980bd96.txt
  - build/agent227/bis/res_ce64cb0e.txt
  - build/agent227/bis/one.sh
  - build/agent227/rt/res_fd.txt
  - build/agent227/rt/res_k0.txt
  - build/agent227/rt/res_k1.txt
  - build/agent227/rt/res_k2.txt
  - build/agent227/rt/res_k3.txt
  - build/agent227/rt/res_k4.txt
  - build/agent227/rt/one.sh
  - build/agent227/rt/shift.py
  - build/agent227/kc373/mode.log
  - build/agent227/kc373/plain.log
  - build/agent227/kc373/mode_shift0.log
  - build/agent227/kc373/plain_shift0.log
  - build/agent227/kc373/mode_dead.log
  - build/agent227/kc373/classes.txt
  - build/agent227/kc373/dlu_one.log
  - build/agent227/kc373/dlu_one.tsv
  - build/agent227/kc373/pilot/plain.log
  - build/agent227/kc373/pilot/mode.log
  - build/agent227/kc373/pilot_soak.sh
  - tests/expected/ctl_caught_debt.tsv
  - tests/expected/dead_leg_unjudged.tsv.lines-105-115 (lines 105-115 of tests/expected/dead_leg_unjudged.tsv)
  - STATE.md.lines-41-52 (lines 41-52 of STATE.md)
  - STATE.md.lines-79-91 (lines 79-91 of STATE.md)
  - docs/platform/gotchas.md.lines-204-232 (lines 204-232 of docs/platform/gotchas.md)
  - DECISIONS_HISTORY.md.lines-10182-10191 (lines 10182-10191 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-13 (14z-227) — the known-crash firing line is a ticket of its own (#373)")
  - build/agent227/close/c373.md
