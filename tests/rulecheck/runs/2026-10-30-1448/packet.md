THE PACKET

Decision kind: recommendation
Subject: close #339 as done (14z-214), after run 2026-10-30-1446: the 37 ledger rows reading session '-' keyed beside the append-only ledger with their evidence, and the collector stopping on any row it cannot key; gated with the control unkeyed-dropped
Claim (the working agent's sentence): CLAIM: close #339 as done (14z-214). The closing comment closing_comment.md and the row ticket_row_339.tsv state the resolution. The ticket (issue_339.md) reported 37 ledger rows with session '-' dropped silently by both ledger pages and left two choices, which the maintainer answered "either is fine, just make it future proof" and "no" (records.diff, the DECISIONS_HISTORY entry quoting them). It rests on:
1. THE FIX: fix.diff (550958ad..working tree: tools/session_metrics.py read_corrections/key_rows and the stop in collect; tests/test_session_metrics.sh the UNKEYED section, its synthetic '-' row and correction, the control unkeyed-dropped) and session_corrections.tsv (the 37 rows, each with its evidence).
2. THE EVIDENCE FOR EACH KEY: manifest_dirs.txt (each run directory's manifest.tsv classed: every artifact a run staged from a sitting's working directory is from the keyed sitting's, build/agent185 or build/rc185 for the 13 of 14z-185, build/agent187b for 13, build/agent188 for 11, none from another's); ledger_rows.txt (the 37 '-' rows at HEAD and their keyed neighbours); state_history_cites.txt (14z-185's record citing runs 383-387, 389-391 and 392-401, and naming build/rc185/ in its M21 freeze row).
3. THE GATE AND ITS CONTROL: test_session_metrics.log (PASS: the corrected row counted under 14z-8, a misaimed correction refused, the collector stopping with the correction gone; every control fired) and mode_unkeyed-dropped.log (the control as a mode: the copy collects silently and the gate FAILs); each log opens with HEAD, host and the blobs it ran.
4. THE REAL LEDGER: collect_now.log (the collector over 14z-163..14z-213 exits 0 with the corrections) and datasets_compare.txt (against the 14z-213 close's datasets: 14z-185 55 -> 68 runs, 14z-187b 24 -> 37, 14z-188 17 -> 28, actions 310 -> 315).
5. THAT PREPARE CANNOT WRITE '-': rulecheck_session_key.txt (tools/rulecheck.py's session_key: prepare dies without --session and on a non-14z-N key, #209).
NOT TESTED: the published pages are not refreshed here (the close's dashboard and ledger-page steps); the action count's rise of 5 is not itemised (the ticket counted 7 actions whose first run read '-'; how the other two now link is not traced); the 37 keys rest on the runs' manifests, read by the project's naming (build/agentNNN/ is sitting 14z-NNN's working directory; build/rc185/ is named in 14z-185's record), and on the cited chains, not on the sittings' transcripts (no transcript id is matched to a run; transcript dd342b19 is claimed by more than one session's commits, so it is not used); readers of the ledger other than session_metrics (rc_actions is called from it; close_findings, packet_check, recurrence_alarm and the rest read the ledger for other purposes) do not apply the corrections; a hand edit to the ledger writing '-' would be refused by the collector, not prevented.
Artifacts (read every one, in full):
  - build/agent214/t339/closure/closing_comment.md
  - build/agent214/t339/closure/ticket_row_339.tsv
  - build/agent214/t339/closure/issue_339.md
  - build/agent214/t339/closure/fix.diff
  - build/agent214/t339/closure/session_corrections.tsv
  - build/agent214/t339/closure/manifest_dirs.txt
  - build/agent214/t339/closure/ledger_rows.txt
  - build/agent214/t339/closure/state_history_cites.txt
  - build/agent214/t339/closure/test_session_metrics.log
  - build/agent214/t339/closure/mode_unkeyed-dropped.log
  - build/agent214/t339/closure/collect_now.log
  - build/agent214/t339/closure/datasets_compare.txt
  - build/agent214/t339/closure/rulecheck_session_key.txt
  - build/agent214/t339/closure/records.diff
