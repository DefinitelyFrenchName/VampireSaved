THE PACKET

Decision kind: recommendation
Subject: close #330 as done (14z-212), after runs 2026-10-29-1364 and -1365: the command family re-measured (24 throw-check-gated grabs have no whiff, 54 whiffs frozen as the grab's own move, never holding), the air and command families on Demitri and Lilith, every family gated by default on one script and classified
Claim (the working agent's sentence): CLAIM: close #330 as done (14z-212), after runs 2026-10-29-1364 and -1365: the closing comment closing_comment.md and the row ticket_row_330.tsv state the resolution. The command family (82 events on Victor; 78 on Demitri, 76 on Lilith) and the air sets on Demitri (28) and Lilith (20) land as frozen hash sets of tests/audit_throw_recovery.sh, which now runs ground, air and command by default. 24 throw-check-gated grabs carry no whiff (CMD_GATED in tools/throw_recovery_rigs.py). Each remaining whiff must start the seq its own input starts when it connects (for the four ruled ES grabs, CMD_ES_WHIFF, their seq 0x12) and its control must never hold: the two clauses in cmd_clauses, held on all 54 in battery_default.log. Their controls fired as modes: gated-whiff on all 24, es-exemption-dropped on all four, whiff-at-contact on all 54 (battery_mode_*.log). The command rows and the air throw tech's victim range are classified on docs/project/tables/community_crosscheck.md, in this session's commit. It rests on:
1. THE RULINGS AND READINGS: DECISIONS_HISTORY.md.lines-8607-8790 — 14z-211's #330 rulings; 14z-212's "No whiff (Recommended)", "Yes, no whiff (Recommended)", "Yes, it is the whiff", the LP page's "Yes" and the gated pages' "Yes, it stands".
2. THE MEASUREMENT: notes.md §1-§3, §9, §10 — press_states.tsv, whiff_vs_grab.tsv, feas.tsv, feas8.tsv, probe_FE_cmd_1.txt, probe_AU_cmd_1.txt; the generators inrange_feas_gen.py, check_probe_gen.py.
3. THE CAPTURES: gated_page1.png, gated_page2.png (gated_sheet.py), es_page1.png, es_page2.png, es_page3.png (es_sheet.py), throw_recovery_command-lp.png; P1's state under every tile; each put to the maintainer and read (item 1).
4. THE GATE, ONE SCRIPT: verify_battery.sh ran every leg below on gate blob 7a611c5d and tool blob 54966f62, checked before and after (battery_blobs.txt), and each log's header names the script blob it ran: battery_default.log (ground 42, air 28, command 82, every clause, every in-gate control FIRED, PASS); battery_v01.log and battery_v0e.log (every family on Demitri and Lilith, PASS); battery_mode_*.log (tick-early, lp-tech, late-window, gated-whiff, es-exemption-dropped, whiff-at-contact, each FIRED on every applicable event). whiff_at_contact_first_try.log (the new control's first try, 53 of 54, and why). The FREEZES (freeze_cmd.log, vic_*.log, vic_air_hv0e_counts.txt) ran on earlier scripts, one of them (vic_cmd_v01.log) while I edited the gate's header; each frozen set they wrote is re-proved by the battery.
5. THE CLASSIFICATION: xc_tr_command.txt and xc_tr_air.txt carried onto docs/project/tables/community_crosscheck.md.lines-460-520 and .lines-600-625; test_crosscheck_229.log (49 cases, a new air-victim case, every control FIRED).
6. THE RECORDS: docs/game/engine_internals.md.lines-3613-3648, docs/project/gotchas.md.lines-7724-7777, tests/expected/PROVENANCE.md.lines-93-104; tests/audit_throw_recovery.sh, tools/throw_recovery_rigs.py, tools/throw_recovery_sheet.py, tools/crosscheck_229.py; rulecheck_1365_reader_a.txt (the stopping run).
NOT TESTED: FBNeo; speed levels other than 0 for the gate; mashed throws; other stage positions and the corner; the characters picked by the cursor (forced by poke). The command throws' tech with any other input or tick: only the victim's back + HP and back + HK at k = 1 and 7; Giga Shock's window 1-7 is read from those two, its edges unprobed. The "no whiff" of the 24 rests on two refused victim states (far away; Victor jumping at contact, four timings), the breakpoint on two of the 24 and captures of four, not on every one; a blocking or hit-stunned victim was not tried. A whiff that starts a DIFFERENT special sharing the grab's seq slot (seq bytes are per slot: Sasquatch's 632[4] LP and 360 LK both 0x0E) is not separated by the clause. The left-out victim events (AIR_NOHOLD_VICTIM, CMD_NOHOLD_VICTIM) are not re-timed to connect on those victims. Captures show the command whiff timing on two events, the ES whiffs and 360 jumps on six grabs and the gated normals on four, not on all. The static tier on the staged tree has not run yet: it runs before the commit.
Artifacts (read every one, in full):
  - build/agent212/t330/closure3/closing_comment.md
  - build/agent212/t330/closure3/ticket_row_330.tsv
  - build/agent212/t330/closure3/rulecheck_1365_reader_a.txt
  - build/agent212/t330/closure3/notes.md
  - build/agent212/t330/closure3/press_states.tsv
  - build/agent212/t330/closure3/whiff_vs_grab.tsv
  - build/agent212/t330/closure3/feas.tsv
  - build/agent212/t330/closure3/feas8.tsv
  - build/agent212/t330/closure3/probe_FE_cmd_1.txt
  - build/agent212/t330/closure3/probe_AU_cmd_1.txt
  - build/agent212/t330/closure3/inrange_feas_gen.py
  - build/agent212/t330/closure3/check_probe_gen.py
  - build/agent212/t330/closure3/gated_sheet.py
  - build/agent212/t330/closure3/es_sheet.py
  - build/agent212/t330/closure3/gated_page1.png
  - build/agent212/t330/closure3/gated_page2.png
  - build/agent212/t330/closure3/es_page1.png
  - build/agent212/t330/closure3/es_page2.png
  - build/agent212/t330/closure3/es_page3.png
  - build/agent212/t330/closure3/throw_recovery_command-lp.png
  - build/agent212/t330/closure3/verify_battery.sh
  - build/agent212/t330/closure3/battery_blobs.txt
  - build/agent212/t330/closure3/battery_default.log
  - build/agent212/t330/closure3/battery_v01.log
  - build/agent212/t330/closure3/battery_v0e.log
  - build/agent212/t330/closure3/battery_mode_tick-early.log
  - build/agent212/t330/closure3/battery_mode_lp-tech.log
  - build/agent212/t330/closure3/battery_mode_late-window.log
  - build/agent212/t330/closure3/battery_mode_gated-whiff.log
  - build/agent212/t330/closure3/battery_mode_es-exemption-dropped.log
  - build/agent212/t330/closure3/battery_mode_whiff-at-contact.log
  - build/agent212/t330/closure3/whiff_at_contact_first_try.log
  - build/agent212/t330/closure3/freeze_cmd.log
  - build/agent212/t330/closure3/vic_verify_air_v01.log
  - build/agent212/t330/closure3/vic_air_hv0e.log
  - build/agent212/t330/closure3/vic_air_hv0e_counts.txt
  - build/agent212/t330/closure3/vic_cmd_v01.log
  - build/agent212/t330/closure3/vic_cmd_v0e.log
  - build/agent212/t330/closure3/xc_tr_command.txt
  - build/agent212/t330/closure3/xc_tr_air.txt
  - build/agent212/t330/closure3/test_crosscheck_229.log
  - DECISIONS_HISTORY.md.lines-8607-8790 (lines 8607-8790 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #330: "actionable" is the first accepted input; a new gate on Victor", and the entries after it up to line 8790)
  - docs/project/tables/community_crosscheck.md.lines-460-520 (lines 460-520 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-600-625 (lines 600-625 of docs/project/tables/community_crosscheck.md)
  - docs/game/engine_internals.md.lines-3613-3648 (lines 3613-3648 of docs/game/engine_internals.md)
  - docs/project/gotchas.md.lines-7724-7777 (lines 7724-7777 of docs/project/gotchas.md)
  - tests/expected/PROVENANCE.md.lines-93-104 (lines 93-104 of tests/expected/PROVENANCE.md)
  - tests/audit_throw_recovery.sh
  - tools/throw_recovery_rigs.py
  - tools/throw_recovery_sheet.py
  - tools/crosscheck_229.py
