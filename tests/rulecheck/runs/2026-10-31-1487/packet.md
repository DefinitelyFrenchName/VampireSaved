THE PACKET

Decision kind: recommendation
Subject: #310 groups 5-7 back to the maintainer as their own scope: recommend groups 5 and 6 this session, group 7 in later batches
Claim (the working agent's sentence): CLAIM: put #310's groups 5-7 to the maintainer as their own scope (question.txt), recommending option 1: groups 5 and 6 this session, group 7 in later batches, #310 open until group 7 is done. Rests on: the maintainer's ruling (ruling_310.txt: "Then groups 5-7 are measured at HEAD before any edit and come back to you as their own scope"); the census of the working tree, read-only (group5.tsv, group6.tsv, group7.tsv, new_instances.tsv, void_producers.tsv; SUMMARY.md written by the session from the census worker's report, since the harness refused the worker's own); counts.txt (the session's recount of every figure in question.txt: group 5 21 distinct gates PRESENT, group 6 3, group 7 104, union of 5 and 6 23; group 7's 93 gates / 282 modes equal nondet_other.txt's); tiers56.txt (the 23 gates groups 5-6 would edit and the lists each sits on: 15 on the static concurrent-controls list, 2 on the emulator list). The session read three of the census's claims in the source: test_release_binaries.sh:712 (a leg that did not complete read as CONTROL FIRED), audit_kill_poke_shape.sh:134 (the mode forces the FAIL whatever the legs did) and tests/lib/classify.sh:164-171 (own CONTROL DEAD tested before NOT JUDGED). NOT TESTED: every PRESENT/ABSENT verdict is a reading of the gate's text, none is a run; the ABSENT-by-twin rows rest on reading the twin's code, except test_rule_checker's 20 group-5 modes and test_defense_rows_census's 2 group-7 modes, which rest on REMAINING.md's earlier mapping, not re-read — question.txt and SUMMARY.md now count both as CANNOT TELL (group 5: 4, group 7: 8), and option 1 measures group 5's four first; the remaining CANNOT TELL gates are 11 (10 by reading plus test_rule_checker) — test_defense_rows_census is already a group-5 PRESENT gate;  the VOID meaning column is assigned from message words (regex plus 42 by hand); the group 5 sweep used a regex for copy-making and the group 7 sweep only ci_emulator.tsv gates with declared modes, so instances outside both can be missed; the "3-4 hours" in option 1 is the session's estimate, not a measurement; "5 more held only by their plain run" are the five gates SUMMARY.md names under group 6 (test_release_roundtrip, test_romset_path_guard, test_crash_guard, test_proof_sheets, test_rule_checker), read by the census, not by the session; the working tree changed during the census only in rule-checker runs, the ledger, STATE.md and the tickets files (the worker's report, not re-checked).
Artifacts (read every one, in full):
  - build/agent215/t310/census57/question.txt
  - build/agent215/t310/census57/SUMMARY.md
  - build/agent215/t310/census57/counts.txt
  - build/agent215/t310/census57/tiers56.txt
  - build/agent215/t310/census57/ruling_310.txt
  - build/agent215/t310/census57/group5.tsv.lines-1-64 (lines 1-64 of build/agent215/t310/census57/group5.tsv)
  - build/agent215/t310/census57/group5.tsv.lines-65-127 (lines 65-127 of build/agent215/t310/census57/group5.tsv)
  - build/agent215/t310/census57/group6.tsv.lines-1-56 (lines 1-56 of build/agent215/t310/census57/group6.tsv)
  - build/agent215/t310/census57/group6.tsv.lines-57-112 (lines 57-112 of build/agent215/t310/census57/group6.tsv)
  - build/agent215/t310/census57/group7.tsv.lines-1-95 (lines 1-95 of build/agent215/t310/census57/group7.tsv)
  - build/agent215/t310/census57/group7.tsv.lines-96-190 (lines 96-190 of build/agent215/t310/census57/group7.tsv)
  - build/agent215/t310/census57/group7.tsv.lines-191-283 (lines 191-283 of build/agent215/t310/census57/group7.tsv)
  - build/agent215/t310/census57/new_instances.tsv.lines-1-113 (lines 1-113 of build/agent215/t310/census57/new_instances.tsv)
  - build/agent215/t310/census57/new_instances.tsv.lines-114-226 (lines 114-226 of build/agent215/t310/census57/new_instances.tsv)
  - build/agent215/t310/census57/new_instances.tsv.lines-227-337 (lines 227-337 of build/agent215/t310/census57/new_instances.tsv)
  - build/agent215/t310/census57/void_producers.tsv
