THE PACKET

Decision kind: recommendation
Subject: 14z-170 close, checklist item 6 for the findings added after run 62 (table rows 27-31), after the resolution of 2026-09-19-79; then post the #163 comment, commit the close, run the static tier, tag and push
Claim (the working agent's sentence): The five findings added to the 14z-170 findings table after the documentation packet of run 2026-09-19-62 (build/rc170/findings_table_14z170.tsv, the last five rows) each have a live home, and a reproducing test or a stated reason there is none: (27) tools/attribute_patch_delta.py counted an in-place relocation as SAME and never listed it — fixed as its own RELOCATED class, its classes planted at the freeze (tool_plants.txt) and its listing shown to carry every in-place relocation it counts, 114 of 114 on merged-m19 (attr_listing_check.sh, its outputs attr_listing_merged.txt and attr_listing_check.txt), and SAME made listable (tools/attribute_patch_delta.py --same, its default output unchanged): every listed SAME pair verified identical in kind, address and bytes on all six tracks, and a relocated long planted into a SAME op leaving SAME for RELOCATED (in place), counted and listed (same_class_check.py, same_class_check.txt), homed in docs/project/gotchas.md 'A CLASS THAT ABSORBS ANOTHER CLASS HIDES IT FROM EVERY LISTING'; (28) the freeze's deletion check read directory mtimes, which show only a directory's last change, and the inventory skipped a missing gate-named file — the removal side checked directly (removals_check.txt, its plant removals_check_plant.txt, removals_classified.txt): every FULL path named in a gate's script or in a file the script names directly (one level), with 341 cut short by a variable or a glob checked by their directory only, homed in 'A DIRECTORY'S MODIFICATION TIME HIDES A REMOVAL BEHIND ANY LATER ADDITION'; (29) the captures the maintainer read were shot on scratch builds and one sheet's build was shown by nothing — every ours leg re-shot on build/m3b_merged27, 78/78 and the KO sheet 8/8 plus every frame's whole-RAM checksum identical (recap.log, recap_ko.log), homed in 'A CAPTURE IS EVIDENCE FOR THE BUILD IT WAS SHOT ON' and STATE row (14); (30) the merged-m19 registry note's 'the column and the trap equal native' was measured on a grounded victim only (the trap gate asserts the ground case's marker 0x38) — the note scoped for both (registry.tsv line 169), the airborne case open as #163, whose live GitHub issue names it for the column (issue_163_live.txt, fetched now) and a drafted comment extends to the trap (comment_163_trap.md); (31) only the answer of the freeze ruling had been recorded, in STATE row (8), never in DECISIONS_HISTORY.md — recorded there, its question, options and times quoted from the session's own records of the question and the answer (freeze_ruling_source.txt). STATE row (14) records the freeze check (runs 61 and 63-76, the last OK; 77, 78 and 79 this packet's earlier runs, 80 this one) and the CLOSE row's table count (31) and ON TRIAL figures (30 quoted, 8 promoted, 22 not, each unpromoted script with its reason, the listing and SAME checks among them). close_findings re-run: GAPS none, the two REVIEW addresses answered in the CLOSE row, the one PROMISE fulfilled. The recommendation: post the drafted #163 comment (comment_163_trap.md) as mechanyaa-ai, commit this close record, then run the static tier strict with every control executed, tag the four freeze marks and push the fork before main. NOT tested: rows 27-29's scripts have no gate of their own (named in the table and the ON TRIAL list); a gate-read file reached only through a variable-built path or a glob, or by no name at all, or named only in a file the gate reaches through a variable, an import or a second-level file, and removed during the window, is not seen by the removals check; the column and the trap on an AIRBORNE victim (#163); the static tier runs after this check; no new GitHub post follows from these rows.
Artifacts (read every one, in full):
  - build/rc170/findings_table_14z170.tsv
  - build/rc170/close_findings_4.txt
  - STATE.md.lines-53-73 (lines 53-73 of STATE.md)
  - DECISIONS_HISTORY.md.lines-70-77 (lines 70-77 of DECISIONS_HISTORY.md)
  - docs/project/gotchas.md.lines-5292-5342 (lines 5292-5342 of docs/project/gotchas.md)
  - tests/expected/registry.tsv.lines-169-169 (lines 169-169 of tests/expected/registry.tsv)
  - build/rc170/freeze_ruling_source.txt
  - build/rc170/gh/issue_163_live.txt
  - build/rc170/gh/comment_163_trap.md
  - build/rc170/freeze/rc_final/removals_check.txt
  - build/rc170/freeze/rc_final/removals_check_plant.txt
  - build/rc170/freeze/rc_final/removals_classified.txt
  - build/rc170/freeze/rc_final/recap/recap.log
  - build/rc170/freeze/rc_final/recap/recap_ko.log
  - build/rc170/freeze/rc_final/fix170_b_vs_m19.txt
  - build/rc170/freeze/rc_final/tool_plants.txt
  - build/rc170/freeze/rc_final/attr_listing_check.sh
  - build/rc170/freeze/rc_final/attr_listing_merged.txt
  - build/rc170/freeze/rc_final/attr_listing_check.txt
  - tools/attribute_patch_delta.py
  - build/rc170/freeze/rc_final/same_class_check.py
  - build/rc170/freeze/rc_final/same_class_check.txt
  - tests/audit_trap_shock.sh.lines-1-40 (lines 1-40 of tests/audit_trap_shock.sh)
