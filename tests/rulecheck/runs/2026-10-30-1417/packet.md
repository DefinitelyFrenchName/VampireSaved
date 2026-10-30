THE PACKET

Decision kind: recommendation
Subject: close #335 as done (14z-213), after run 2026-10-30-1413: the session ledger dashboard shows the first-run OK rate per decision and the questions violated on first runs, each labelled; three new controls hold the question figures; the maintainer accepted the section
Claim (the working agent's sentence): CLAIM: close #335 as done (14z-213), after rule-checker run 2026-10-30-1413 (VIOLATED Q1, Q4; resolved). The closing comment closing_comment.md and the row ticket_row_335.tsv state the resolution. The ticket (issue_335.md) asked the session ledger dashboard (#264) to show, per action, the first-run OK rate and which question fails first, each figure labelled MEASURED or DERIVED with its source and rule, tests/test_session_metrics.sh covering the new figures with a control, and the definitions recorded where the tool documents them. It rests on:
1. THE DEFINITIONS: ruled 14z-212 (DECISIONS_HISTORY.md lines 8787-8801 filed, 8861-8876 ruled: 'Link, else wording', 'Every question', 'Excluded, shown apart'); documented in docs/project/rule_checker.md lines 109-122 and tools/rc_actions.py lines 1-30 (the docstring).
2. THE GATE: gate.diff — tests/test_session_metrics.sh gains three shadow-tool controls for the question and action figures: lowest-question (only the lowest-numbered question counted), later-run-questions (an action's questions taken from its last run), calibration-counted (calibration rows kept as actions); a control may also require a line to be ABSENT. gate_mac.log: PASS on the Mac (header: blobs), all ten CONTROL FIRED lines; control_modes_mac.txt and mode_*.log: the modes void-first, same-run-hours, lowest-question, later-run-questions, calibration-counted each exit 1 with the expected line missing.
3. THE PAGE AND ITS DATA: live_page_check.txt — the live page (store files/index.html version 4) holds s0.js (the two dash.calc) verbatim; its two chart cards' notes, quoted, say DERIVED with their dataset and rule; the tiles' renderer, quoted, shows each tile's class chip and rule read from figures.json; the page's datasets 'actions' and 'figures' point at two assets whose SHA-256, read back, equals build/agent212/metrics/actions.json and figures.json. calc_check.js / calc_check.txt: the calcs in node on those files, 635 per-session values equal the collector's figures (0 mismatches), 171 session totals equal their decision rows' sums, and the 'all' rows printed; calc_control.sh / calc_control.txt: one planted figure change is reported as exactly 1 mismatch. all_rows_indep.py / all_rows_indep.txt: the 'all' rows counted in plain python from actions.json equal the calcs' 'all' rows (0 differences).
4. THE WINDOW: actions_window.txt — the whole ledger links 339 actions (21 OK first); the dashboard's actions.json holds 306 (18 OK first) over 57 sessions; the 33 others by their first run's session field (32 under a transcript id or '-', 1 of 14z-213). public_page_exclusion.txt: the public page's sentence stating that exclusion.
5. ACCEPTANCE: DECISIONS_HISTORY.md lines 9159-9165: the maintainer, 'The dashboard new sections are fine' (given on store version 2; the two note edits came after, text only).
NOT TESTED: the dashboard page was not rendered in a browser by a tool after the note edits (the calc code was checked in node, not in the dashboard runtime, and the notes were read as page text); actions.json is the 14z-212 close's dataset, drawn before this session's runs; the 33 actions outside the window are excluded from the dashboard and not shown apart on it; whether a transcript-id session field can be mapped to a session was not attempted; the WORDING link rule is ESTIMATED and its error rate was not measured; the maintainer's acceptance predates the two note edits; test_session_metrics is on the concurrent-controls list and its three new controls have NOT yet been re-traced on PILOT (required before the session commit); any change to how packets are prepared is out of scope (a separate decision, per the issue).
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
  - build/agent213/t335/closure/live_page_check.txt
  - build/agent213/t335/closure/s0.js
  - build/agent213/t335/closure/calc_check.js
  - build/agent213/t335/closure/calc_check.txt
  - build/agent213/t335/closure/calc_control.sh
  - build/agent213/t335/closure/calc_control.txt
  - build/agent213/t335/closure/all_rows_indep.py
  - build/agent213/t335/closure/all_rows_indep.txt
  - build/agent213/t335/closure/actions_window.txt
  - build/agent213/t335/closure/public_page_exclusion.txt
  - DECISIONS_HISTORY.md.lines-8787-8801 (lines 8787-8801 of DECISIONS_HISTORY.md: its INDEX entry "## Filed 2026-10-28 (14z-212) — #335: the session ledger's first-run OK rate per action, and which q", and the entries after it up to line 8801)
  - DECISIONS_HISTORY.md.lines-8861-8876 (lines 8861-8876 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #335: an action's first run, the questions it fails, and what is sho")
  - DECISIONS_HISTORY.md.lines-9159-9165 (lines 9159-9165 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
  - docs/project/rule_checker.md.lines-109-122 (lines 109-122 of docs/project/rule_checker.md)
  - tools/rc_actions.py.lines-1-30 (lines 1-30 of tools/rc_actions.py)
