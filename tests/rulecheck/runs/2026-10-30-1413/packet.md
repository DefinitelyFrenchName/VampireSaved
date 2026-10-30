THE PACKET

Decision kind: recommendation
Subject: close #335 as done (14z-213): the session ledger dashboard shows each session's first-run OK rate per decision and the questions violated on first runs; the maintainer accepted the section
Claim (the working agent's sentence): CLAIM: close #335 as done (14z-213). The closing comment closing_comment.md and the row ticket_row_335.tsv state the resolution. The ticket (issue_335.md) asked the session ledger dashboard (#264) to show, per action, the first-run OK rate and which question fails first, each figure labelled MEASURED or DERIVED with its source and rule, tests/test_session_metrics.sh covering the new figures with a control, and the definitions recorded where the tool documents them. It rests on:
1. THE DEFINITIONS: ruled 14z-212 (DECISIONS_HISTORY.md lines 8786-8800 filed, 8860-8875 ruled: 'Link, else wording', 'Every question', 'Excluded, shown apart'); documented in docs/project/rule_checker.md lines 109-122 and tools/rc_actions.py lines 1-30 (the docstring).
2. THE COLLECTOR AND ITS GATE: tools/rc_actions.py and tools/session_metrics.py (committed at 14z-212, d6393610). gate_mac.log: tests/test_session_metrics.sh PASS on the Mac (its header carries the blobs), its CONTROL FIRED lines include unnamed-link, meta-ignored and void-first; control_modes_mac.txt: the modes void-first and same-run-hours each exit 1 (FAIL as they must).
3. THE PAGE: the dashboard artifact's page (store files/index.html, version 2). live_page_check.txt: the live page read back equals the page published, carries the section 'Actions: OK at the first check', and holds s0.js (its two dash.calc, act_decision and act_questions) verbatim. calc_check.js runs those two calcs in node on the collector's own actions.json and compares them to the collector's figures.json: calc_check.txt '635 calc values ... 0 mismatches' and '171 session totals' equal to their decision rows' sums, plus the 'all' rows quoted in the comment.
4. THE WINDOW: actions_window.txt — the whole ledger links 339 actions (21 OK first); the dashboard's actions.json holds 306 (18 OK first) over 57 sessions; the 33 others by their first run's session field (32 under a transcript id or '-', 1 of 14z-213).
5. ACCEPTANCE: DECISIONS_HISTORY.md lines 9158-9164: the maintainer, 'The dashboard new sections are fine'.
NOT TESTED: the page's rendering in a browser after the maintainer's look was not re-checked by a tool (the calc code was checked in node, not in the dashboard runtime); actions.json is the 14z-212 close's dataset (drawn before this session's runs); the 33 actions outside the window are excluded from the dashboard and not shown apart on it (the public page states the exclusion in prose); whether a transcript-id session field can be mapped to a session was not attempted; the WORDING link rule is ESTIMATED and its error rate was not measured; any change to how packets are prepared is out of scope (a separate decision, per the issue).
Artifacts (read every one, in full):
  - build/agent213/t335/closure/closing_comment.md
  - build/agent213/t335/closure/ticket_row_335.tsv
  - build/agent213/t335/closure/issue_335.md
  - build/agent213/t335/closure/gate_mac.log
  - build/agent213/t335/closure/control_modes_mac.txt
  - build/agent213/t335/closure/live_page_check.txt
  - build/agent213/t335/closure/s0.js
  - build/agent213/t335/closure/calc_check.js
  - build/agent213/t335/closure/calc_check.txt
  - build/agent213/t335/closure/actions_window.txt
  - DECISIONS_HISTORY.md.lines-8786-8800 (lines 8786-8800 of DECISIONS_HISTORY.md: its INDEX entry "## Filed 2026-10-28 (14z-212) — #335: the session ledger's first-run OK rate per action, and which q", and the entries after it up to line 8800)
  - DECISIONS_HISTORY.md.lines-8860-8875 (lines 8860-8875 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #335: an action's first run, the questions it fails, and what is sho")
  - DECISIONS_HISTORY.md.lines-9158-9164 (lines 9158-9164 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
  - docs/project/rule_checker.md.lines-109-122 (lines 109-122 of docs/project/rule_checker.md)
  - tools/rc_actions.py.lines-1-30 (lines 1-30 of tools/rc_actions.py)
