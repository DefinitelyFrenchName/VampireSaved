THE PACKET

Decision kind: recommendation
Subject: close #335 as done (14z-213), after runs 2026-10-30-1413, -1417, -1418 and -1419: the session ledger dashboard shows the first-run OK rate per decision and the questions violated on first runs, labelled with the collector's class; what is not counted shown apart and gated; five new controls; the maintainer accepted the section
Claim (the working agent's sentence): CLAIM: close #335 as done (14z-213), after rule-checker runs 2026-10-30-1413, -1417, -1418 and -1419 (each VIOLATED Q1, Q4; each resolved in the ledger). The closing comment closing_comment.md and the row ticket_row_335.tsv state the resolution. The ticket (issue_335.md) asked the session ledger dashboard (#264) to show, per action, the first-run OK rate and which question fails first, each figure labelled MEASURED or DERIVED with its source and rule, tests/test_session_metrics.sh covering the new figures with a control, and the definitions recorded where the tool documents them. It rests on:
1. THE DEFINITIONS: ruled 14z-212 (DECISIONS_HISTORY.md lines 8787-8801 filed, 8861-8876 ruled: 'Link, else wording', 'Every question', 'Excluded, shown apart'); documented in docs/project/rule_checker.md lines 109-122 and tools/rc_actions.py lines 1-30 (the docstring).
2. THE GATE: gate.diff — tests/test_session_metrics.sh gains five shadow-tool controls: lowest-question, later-run-questions, calibration-counted, not-run-ignored, void-only-dropped (a control may also require a line to be ABSENT); its synthetic ledger gains a lone freeze whose plant died (an action of VOID runs only), expected as 14z-10 actions_void_only 1. gate_mac.log: PASS on the Mac (header: blobs), all twelve CONTROL FIRED lines, 0 CONTROL DEAD; control_modes_mac.txt and mode_*.log: the modes void-first, same-run-hours, lowest-question, later-run-questions, calibration-counted, not-run-ignored, void-only-dropped each exit 1 with an expected line missing.
3. THE PAGE: index_live_v6.json — the live page as read back (store files/index.html, version 6). page_checks.py / page_checks.txt (reads that page, s0.js and figures.json): the two dash.calc verbatim in the page; each chart note's stated class (ESTIMATED) equals the class the collector gives all 806 action figures; quoted from the page: the section's tiles (ACT_TILES, including 'Actions of VOID runs only (not counted)' and 'Packets never run (not counted)'), its prose on calibration, the chart code reading act_decision and act_questions, and the every-figure table listing all of a session's figures; from figures.json: the rc_calibration figure ('Runs: calibration', MEASURED, 7 sessions), the not_run figure (13 packets on 3 sessions, equal to the 13 run directories holding NOT-RUN.txt), actions_void_only on 0 sessions; void_rows.txt (awk over the ledger, no collector code): its 3 VOID rows are all calibration rows, so no action has a VOID run; and two planted controls (one character changed in the calc code: not found; a note saying DERIVED: disagrees). The tiles' class chip and rule come from figures.json (the renderer was quoted in run 1417's packet).
4. THE DATA: live_page_check.txt — the page's datasets 'actions' and 'figures' point at two assets whose SHA-256, read back, equals build/agent212/metrics/actions.json and figures.json. calc_check.js / calc_check.txt: the calcs in node on those files, 635 per-session values equal the collector's figures (0 mismatches), 171 session totals equal their decision rows' sums; calc_control.sh / calc_control.txt: a planted figure change gives exactly 1 mismatch. all_rows_indep.py / all_rows_indep.txt: the 'all' rows counted in plain python from actions.json equal the calcs' 'all' rows (0 differences); all_rows_control.txt: on a copy with one action's first-run verdict flipped, 4 differences.
5. THE WINDOW: actions_window.txt — the whole ledger links 339 actions (21 OK first); the dashboard's actions.json holds 306 (18 OK first) over 57 sessions; the 33 others by their first run's session field (32 under a transcript id or '-', 1 of 14z-213). public_page_exclusion.txt: the public page's sentence stating that exclusion.
6. ACCEPTANCE: DECISIONS_HISTORY.md lines 9159-9165: the maintainer, 'The dashboard new sections are fine' (given on store version 2; the note edits, versions 3-6, came after, text only).
NOT TESTED: the dashboard page was not rendered in a browser by a tool after the note edits (the calc code was checked in node, not in the dashboard runtime; the page was read as text), so no tile was seen drawn with its number; actions.json and figures.json are the 14z-212 close's datasets, drawn before this session's runs; the 33 actions outside the window are excluded from the dashboard and not shown apart on it; whether a transcript-id session field can be mapped to a session was not attempted; the WORDING link rule is ESTIMATED and its error rate was not measured; the maintainer's acceptance predates the note edits; the VOID-only tile has no figure in the real dataset, so it has never shown a number on the page (the figure itself is gated on the synthetic ledger); test_session_metrics is on the concurrent-controls list and its five new controls have NOT yet been re-traced on PILOT (required before the session commit); any change to how packets are prepared is out of scope (a separate decision, per the issue).
Artifacts (read every one, in full):
  - build/agent213/t335/closure/closing_comment.md
  - build/agent213/t335/closure/ticket_row_335.tsv
  - build/agent213/t335/closure/issue_335.md
  - build/agent213/t335/closure/gate.diff
  - build/agent213/t335/closure/gate_mac.log
  - build/agent213/t335/closure/control_modes_mac.txt
  - build/agent213/t335/closure/mode_lowest-question.log
  - build/agent213/t335/closure/mode_later-run-questions.log
  - build/agent213/t335/closure/mode_calibration-counted.log
  - build/agent213/t335/closure/mode_not-run-ignored.log
  - build/agent213/t335/closure/mode_void-only-dropped.log
  - build/agent213/t335/closure/index_live_v6.json
  - build/agent213/t335/closure/page_checks.py
  - build/agent213/t335/closure/page_checks.txt
  - build/agent213/t335/closure/void_rows.txt
  - build/agent213/t335/closure/live_page_check.txt
  - build/agent213/t335/closure/s0.js
  - build/agent213/t335/closure/calc_check.js
  - build/agent213/t335/closure/calc_check.txt
  - build/agent213/t335/closure/calc_control.sh
  - build/agent213/t335/closure/calc_control.txt
  - build/agent213/t335/closure/all_rows_indep.py
  - build/agent213/t335/closure/all_rows_indep.txt
  - build/agent213/t335/closure/all_rows_control.txt
  - build/agent213/t335/closure/actions_window.txt
  - build/agent213/t335/closure/public_page_exclusion.txt
  - DECISIONS_HISTORY.md.lines-8787-8801 (lines 8787-8801 of DECISIONS_HISTORY.md: its INDEX entry "## Filed 2026-10-28 (14z-212) — #335: the session ledger's first-run OK rate per action, and which q", and the entries after it up to line 8801)
  - DECISIONS_HISTORY.md.lines-8861-8876 (lines 8861-8876 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #335: an action's first run, the questions it fails, and what is sho")
  - DECISIONS_HISTORY.md.lines-9159-9165 (lines 9159-9165 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
  - docs/project/rule_checker.md.lines-109-122 (lines 109-122 of docs/project/rule_checker.md)
  - tools/rc_actions.py.lines-1-30 (lines 1-30 of tools/rc_actions.py)
