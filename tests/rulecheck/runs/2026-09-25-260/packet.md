THE PACKET

Decision kind: recommendation
Subject: 14z-183 CLOSE, checklist item 6 — the documentation packet: every finding (a)-(aa) of the findings table has a live home in the tracked tree, and each test's reach stated (after runs 251-259)
Claim (the working agent's sentence): THE DOCUMENTATION PACKET of 14z-183: every finding (a)-(aa) of STATE.md row '(15) THE FINDINGS TABLE' has a live home in a tracked file — or, for a session event ((q), (z)), a STATE row, the place a session's record lives — and each test the table names is quoted with its line in packet_homes_14z183.txt. packet_verify.py re-opens every quote from the tree: 57 match, 0 mismatch; its plant (one quote altered, one line number moved, on a copy) reports both (packet_quotes_verified.txt). class_letters.py reads the finding letters from the STATE row itself (27) and finds each in exactly one class of the packet header (b, c, e split by halves), its plant (a letter dropped, a letter doubled) reporting both (class_letters.txt). close_findings_14z183.txt reports no GAP, REVIEW or PROMISE after its one GAP (0x02231E, first missed by my filter) and three REVIEW addresses were homed (both stated in STATE.md's CLOSE row); homes_tracked exits 0 over 36 backticked file tokens (33 distinct files), one document cited in prose and 11 ticket rows; the retraction grep (17 patterns, 13 retracted) finds every reach control, and classing_cover.py finds every hit file of every retracted pattern named in its classing line, 0 unclassed, its plant reported (classing_coverage.txt). (aa) is new since run 259: audit_move_parity's header said 506 events over 30 parts where its table has 526 over 32 since 14z-181; that header, two more gate headers and two PROVENANCE rows corrected, gate_coverage.md regenerated. WHAT EACH TEST DOES is the header's classification: REPLAYS THE FINDING (a), (f), (l); RUNS THE FIXED OR CURRENT STATE ONLY — fails on a regression, never replays the defect, the move or the old state — (b) meter half, (c) images, (d), (e) chosen offset, (g), (j), (n), (u), (x), (y); NO TEST (b) damage half, (c) 'nothing else', (e) band, (h), (i), (k), (m) (its gate is pinned to M19), (o) (tracked recordings, no gate), (p), (q), (r), (s), (t) (the VOID rule never reproduces the fault; whether it is the known teardown class was not checked), (v), (w), (z), (aa). UNCHECKED BY ANY TOOL: whether each class assignment is right (class_letters checks only that every letter has exactly one); the table's completeness (close_findings sees addresses only; homes_tracked and the packet check only what the row names; my check was a full re-read of rows (1)-(14)); the retraction pattern list's completeness (the reach controls prove the grep reaches files, not that every retracted wording has a pattern); whether a classing line's class is right (classing_cover checks only that the file is named); whether a quoted line's CONTENT is still true (the quote check matches text, as run 259's stale 506 showed) — all of that, and whether each home is ENOUGH for a reader, is judged here.
Artifacts (read every one, in full):
  - STATE.md
  - build/agent183/packet_homes_14z183.txt
  - build/agent183/packet_verify.py
  - build/agent183/packet_quotes_verified.txt
  - build/agent183/class_letters.py
  - build/agent183/class_letters.txt
  - build/agent183/close_findings_14z183.txt
  - build/agent183/homes_tracked.txt
  - build/agent183/retraction_greps_14z183.txt
  - build/agent183/classing_cover.py
  - build/agent183/classing_coverage.txt
  - docs/project/gotchas.md
