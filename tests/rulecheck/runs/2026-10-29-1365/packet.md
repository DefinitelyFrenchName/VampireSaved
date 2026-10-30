THE PACKET

Decision kind: recommendation
Subject: close #330 as done (14z-212), after run 2026-10-29-1364: the command family re-measured (24 throw-check-gated grabs have no whiff, 54 whiffs frozen as the grab's own move), the air and command families on Demitri and Lilith, every family gated by default and classified
Claim (the working agent's sentence): CLAIM: close #330 as done (14z-212): the closing comment closing_comment.md and the row ticket_row_330.tsv state the resolution. The command family (82 events on Victor; 78 on Demitri, 76 on Lilith) and the air sets on Demitri (28) and Lilith (20) land as frozen hash sets of tests/audit_throw_recovery.sh, which now runs ground, air and command by default. 24 throw-check-gated grabs carry no whiff (CMD_GATED in tools/throw_recovery_rigs.py). Each remaining whiff must start the seq its own input starts when it connects, or for the four ruled ES grabs (CMD_ES_WHIFF) their seq 0x12: the clause in cmd_clauses, held on all 54 in verify_default.log. Its controls fired: gated-whiff on all 24 in verify_mode_gated-whiff.log, es-exemption-dropped on all four in verify_mode_es-exemption-dropped.log. The command rows and the air throw tech's victim range are classified on docs/project/tables/community_crosscheck.md, in this session's commit. This follows run 2026-10-29-1364 (VIOLATED Q1 Q2 Q4, resolved; its reader's answer is rulecheck_1364_reader_b.txt). It rests on:
1. THE RULINGS AND READINGS: DECISIONS_HISTORY.md.lines-8606-8788 — 14z-211's #330 rulings, then 14z-212's "No whiff (Recommended)" (the 20 normals), "Yes, no whiff (Recommended)" (the four 360s), "Yes, it is the whiff" (the four ES grabs), the command-whiff LP page's reading ("Yes"), and after run 1364 the gated grabs' capture pages' reading ("Yes, it stands").
2. THE MEASUREMENT: notes.md §1-§3 and §9 — press_states.tsv, whiff_vs_grab.tsv (28 of 78 far whiffs do not start the connecting grab's seq: 20 normals, 4 jumps, 4 ES seq 0x12), feas.tsv and feas8.tsv (at contact against Victor jumping, 4 leads: the same normal, jump or 0x12, no hold), probe_FE_cmd_1.txt and probe_AU_cmd_1.txt (the throw check CPU:$029406 called in both outcomes, the commit only on the grounded victim); the generators inrange_feas_gen.py, check_probe_gen.py.
3. THE CAPTURES: gated_page1.png and gated_page2.png (gated_sheet.py: four of the 24 gated grabs CONNECTS / FAR / at contact with Victor JUMPING), es_page1.png, es_page2.png, es_page3.png (es_sheet.py: the ES grabs and the 360s CONNECTS / FAR), throw_recovery_command-lp.png (the command-whiff LP pair); P1's state under every tile; each put to the maintainer and read (item 1).
4. THE GATE, on one script (gate_blob.txt; every run below on that blob): verify_default.log (the default run: ground 42, air 28, command 82, every clause, ten in-gate controls FIRED, PASS); verify_ga_v01.log, verify_ga_v0e.log (ground and air on Demitri and Lilith, PASS); verify_cmd_v01.log, verify_cmd_v0e.log (the command family on both, PASS); verify_mode_*.log (tick-early, lp-tech, late-window, gated-whiff, es-exemption-dropped, each FIRED on every applicable event); freeze_cmd.log (the command freeze, 136 rigs); vic_*.log and vic_air_hv0e_counts.txt (the victim freezes: Lilith's air 22 refused, 22 scanned, 0 unresolved; the command freezes on both victims, the first refusing nothing).
5. THE CLASSIFICATION: xc_tr_command.txt and xc_tr_air.txt carried onto docs/project/tables/community_crosscheck.md.lines-460-520 and .lines-600-625; test_crosscheck_229.log (49 cases, a new air-victim case, every control FIRED).
6. THE RECORDS: docs/game/engine_internals.md.lines-3613-3648, docs/project/gotchas.md.lines-7724-7777, tests/expected/PROVENANCE.md.lines-93-104; tests/audit_throw_recovery.sh, tools/throw_recovery_rigs.py, tools/throw_recovery_sheet.py, tools/crosscheck_229.py.
NOT TESTED: FBNeo; speed levels other than 0 for the gate; mashed throws; other stage positions and the corner; the characters picked by the cursor (forced by poke). The command throws' tech with any other input or tick: only the victim's back + HP and back + HK at k = 1 and 7; Giga Shock's window 1-7 is read from those two, its edges unprobed. The "no whiff" of the 24 rests on two refused victim states (far away; Victor jumping at contact, four timings), the breakpoint on two of the 24 (Felicia 632[4] MK, Aulbath 6324 MP) and captures of four, not on every one; a blocking or hit-stunned victim was not tried. A whiff that starts a DIFFERENT special sharing the grab's seq slot (seq bytes are per slot: Sasquatch's 632[4] LP and 360 LK both 0x0E) is not separated by the clause. The left-out victim events (AIR_NOHOLD_VICTIM, CMD_NOHOLD_VICTIM) are not re-timed to connect on those victims. Captures show the command whiff timing on two events, the ES whiffs and 360 jumps on six grabs and the gated normals on four, not on all; the rest rest on the gate's acceptance and move clauses. The static tier on the staged tree has not run yet: it runs before the commit.
Artifacts (read every one, in full):
  - build/agent212/t330/closure2/closing_comment.md
  - build/agent212/t330/closure2/ticket_row_330.tsv
  - build/agent212/t330/closure2/rulecheck_1364_reader_b.txt
  - build/agent212/t330/closure2/notes.md
  - build/agent212/t330/closure2/press_states.tsv
  - build/agent212/t330/closure2/whiff_vs_grab.tsv
  - build/agent212/t330/closure2/feas.tsv
  - build/agent212/t330/closure2/feas8.tsv
  - build/agent212/t330/closure2/probe_FE_cmd_1.txt
  - build/agent212/t330/closure2/probe_AU_cmd_1.txt
  - build/agent212/t330/closure2/inrange_feas_gen.py
  - build/agent212/t330/closure2/check_probe_gen.py
  - build/agent212/t330/closure2/gated_sheet.py
  - build/agent212/t330/closure2/es_sheet.py
  - build/agent212/t330/closure2/gated_page1.png
  - build/agent212/t330/closure2/gated_page2.png
  - build/agent212/t330/closure2/es_page1.png
  - build/agent212/t330/closure2/es_page2.png
  - build/agent212/t330/closure2/es_page3.png
  - build/agent212/t330/closure2/throw_recovery_command-lp.png
  - build/agent212/t330/closure2/gate_blob.txt
  - build/agent212/t330/closure2/verify_default.log
  - build/agent212/t330/closure2/verify_ga_v01.log
  - build/agent212/t330/closure2/verify_ga_v0e.log
  - build/agent212/t330/closure2/verify_cmd_v01.log
  - build/agent212/t330/closure2/verify_cmd_v0e.log
  - build/agent212/t330/closure2/verify_mode_tick-early.log
  - build/agent212/t330/closure2/verify_mode_lp-tech.log
  - build/agent212/t330/closure2/verify_mode_late-window.log
  - build/agent212/t330/closure2/verify_mode_gated-whiff.log
  - build/agent212/t330/closure2/verify_mode_es-exemption-dropped.log
  - build/agent212/t330/closure2/freeze_cmd.log
  - build/agent212/t330/closure2/vic_verify_air_v01.log
  - build/agent212/t330/closure2/vic_air_hv0e.log
  - build/agent212/t330/closure2/vic_air_hv0e_counts.txt
  - build/agent212/t330/closure2/vic_cmd_v01.log
  - build/agent212/t330/closure2/vic_cmd_v0e.log
  - build/agent212/t330/closure2/xc_tr_command.txt
  - build/agent212/t330/closure2/xc_tr_air.txt
  - build/agent212/t330/closure2/test_crosscheck_229.log
  - DECISIONS_HISTORY.md.lines-8606-8788 (lines 8606-8788 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #330: "actionable" is the first accepted input; a new gate on Victor", and the entries after it up to line 8788)
  - docs/project/tables/community_crosscheck.md.lines-460-520 (lines 460-520 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-600-625 (lines 600-625 of docs/project/tables/community_crosscheck.md)
  - docs/game/engine_internals.md.lines-3613-3648 (lines 3613-3648 of docs/game/engine_internals.md)
  - docs/project/gotchas.md.lines-7724-7777 (lines 7724-7777 of docs/project/gotchas.md)
  - tests/expected/PROVENANCE.md.lines-93-104 (lines 93-104 of tests/expected/PROVENANCE.md)
  - tests/audit_throw_recovery.sh
  - tools/throw_recovery_rigs.py
  - tools/throw_recovery_sheet.py
  - tools/crosscheck_229.py
