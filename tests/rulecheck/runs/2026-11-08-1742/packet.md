THE PACKET

Decision kind: recommendation
Subject: #370 design proposal (declared shares, scheduler, host claim, audit)
Claim (the working agent's sentence): A design proposal for #370 put to the maintainer before any code is written (build/agent224/t370/design.md). It describes what the tree does today: plain gate runs already run side by side and the runners keep no two apart (tests/lib/static_pool.py; tests/run_all_emulator.sh's FIFO slots), two guards in the gates' own code doing so for one resource each (tests/lib/desktop_session.sh's claim, tools/mister_mra.sh's jtsim lock), only a gate's own control modes are kept apart, by the allow-lists tests/controls_concurrent.txt (117 rows) and tests/controls_concurrent_emu.txt (60 rows) read at tests/lib/static_job.sh:50 and tests/run_all_emulator.sh:661-670; registered gates per build/agent224/t370/census.txt (static 254: 94 with no control, 34 with one, 126 with two or more, 117 listed and 9 not; emulator 258: 105, 46, 107, 60 and 47; no registered row without a script; the two registries intersected, none in both, 512 in all; list rows whose traced blob is not the script now: 7 static, all among the scripts #369's scratch commit changed (build/agent224/t370/changed_by_369.txt), and 0 emulator; the census's own control, planted inputs, reported as one missing row, one row in both tiers and one stale row); and the shares the lists' headers record, four of which cross gates (submodule index locks, release assets, desktop session, jtsim scratch). It proposes a `# SHARES:` field with a reserved `self` and a four-token resource registry, a token-aware scheduler shared by both runners, an atomic per-token host claim that absorbs tests/lib/desktop_session.sh and tools/mister_mra.sh's lock, a freeze-cadence cross-job strace audit replacing the lists and tests/test_controls_concurrent.sh, a census gate, and the ticket's overlap control; and asks three decisions, recommending A1 (land today's behaviour written down: listed gates none only when their row's traced blob is the script's when #370 lands, a stale row self, unlisted multi-control gates self, the known shares as tokens; so the cross-gate shares stop overlapping and a stale row's modes stop running side by side, and nothing else changes), B1 (every registered gate carries the line) and C1 (the host claim, re-entrant for a run nested under its holder as tests/lib/desktop_session.sh is today, whose refusal is exit 3: UNJUDGED under a control mode, red in a plain run; its control covers a sibling refused, a nested run let through, and a dead or other holder claimed normally). NOT TESTED: nothing is built; the share inventory was read by hand from the lists' headers and their git history, and nothing checks it is complete; A1's none for the 177 listed gates rests on traces that compared each gate's modes only with each other, so no cross-gate share among them has been looked for; the cost of a pooled tier under strace is not measured; the emulator runner's move to a Python scheduler is not sized; mkdir locks under ERIS's MINGW64 shell are not tested; test_dead_leg_unjudged's nine shared paths are not named; which plain runs share something no trace has seen is unknown.
Artifacts (read every one, in full):
  - build/agent224/t370/design.md
  - build/agent224/t370/issue370.md
  - build/agent224/t370/census.sh
  - build/agent224/t370/census.txt
  - build/agent224/t370/changed_by_369.txt
  - tests/controls_concurrent.txt
  - tests/controls_concurrent_emu.txt
  - tests/lib/static_pool.py
  - tests/lib/static_job.sh
  - tests/run_all_emulator.sh.lines-640-680 (lines 640-680 of tests/run_all_emulator.sh)
  - tests/run_all_emulator.sh.lines-700-855 (lines 700-855 of tests/run_all_emulator.sh)
  - tests/lib/desktop_session.sh
  - tools/mister_mra.sh.lines-88-118 (lines 88-118 of tools/mister_mra.sh)
  - tools/controls_overlap.py
  - DECISIONS_HISTORY.md.lines-9893-9905 (lines 9893-9905 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-08 (14z-223) — the #310 post-mortem's three recommendations: positive evidence, dec")
  - build/agent223/postmortem/postmortem_310.md
