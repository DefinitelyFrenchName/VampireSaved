THE PACKET

Decision kind: recommendation
Subject: 14z-170 close, checklist item 6 for the findings added after run 62 (table rows 27-31): each has a live home and a reproducing test, or is an open item; then commit the close, run the static tier, tag and push
Claim (the working agent's sentence): The five findings added to the 14z-170 findings table after the documentation packet of run 2026-09-19-62 (build/rc170/findings_table_14z170.tsv, the last five rows) each have a live home, and a reproducing test or a stated reason there is none: (27) tools/attribute_patch_delta.py counted an in-place relocation as SAME and never listed it — fixed as its own RELOCATED class, its classes planted at the freeze, homed in docs/project/gotchas.md 'A CLASS THAT ABSORBS ANOTHER CLASS HIDES IT FROM EVERY LISTING'; (28) the freeze's deletion check read directory mtimes, which show only a directory's last change, and the inventory skipped a missing gate-named file — the removal side checked directly (removals_check.txt, removals_classified.txt), homed in 'A DIRECTORY'S MODIFICATION TIME HIDES A REMOVAL BEHIND ANY LATER ADDITION'; (29) the captures the maintainer read were shot on scratch builds and one sheet's build was shown by nothing — every ours leg re-shot on build/m3b_merged27, 78/78 and the KO sheet 8/8 plus every frame's whole-RAM checksum identical (recap.log, recap_ko.log), homed in 'A CAPTURE IS EVIDENCE FOR THE BUILD IT WAS SHOT ON' and STATE row (14); (30) the merged-m19 registry note's 'the column equals native' was measured on a grounded victim only — the note scoped (registry.tsv line 169), the airborne case open as #163, whose GitHub issue already names it; (31) the freeze ruling sat only in STATE row (8) — moved verbatim to DECISIONS_HISTORY.md. STATE row (14) records the freeze check (runs 61 and 63-76, the last OK) and the CLOSE row's table count (31) and ON TRIAL figures (28 quoted, 8 promoted, 20 not, each unpromoted script with its reason). close_findings re-run: GAPS none, the two REVIEW addresses answered in the CLOSE row, the one PROMISE fulfilled. The recommendation: commit this close record, then run the static tier strict with every control executed, tag the four freeze marks and push the fork before main. NOT tested: rows 27-29's scripts have no gate of their own (named in the table and the ON TRIAL list); the static tier runs after this check; no new GitHub post follows from these rows.
Artifacts (read every one, in full):
  - build/rc170/findings_table_14z170.tsv
  - build/rc170/close_findings_4.txt
  - STATE.md.lines-53-73 (lines 53-73 of STATE.md)
  - DECISIONS_HISTORY.md.lines-70-77 (lines 70-77 of DECISIONS_HISTORY.md)
  - docs/project/gotchas.md.lines-5292-5336 (lines 5292-5336 of docs/project/gotchas.md)
  - tests/expected/registry.tsv.lines-169-169 (lines 169-169 of tests/expected/registry.tsv)
  - build/rc170/freeze/rc_final/removals_check.txt
  - build/rc170/freeze/rc_final/removals_classified.txt
  - build/rc170/freeze/rc_final/recap/recap.log
  - build/rc170/freeze/rc_final/recap/recap_ko.log
  - build/rc170/freeze/rc_final/fix170_b_vs_m19.txt
  - build/rc170/freeze/rc_final/tool_plants.txt
  - build/rc170/gh/issue_column_trap.md
