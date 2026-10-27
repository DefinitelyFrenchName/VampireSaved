THE PACKET

Decision kind: recommendation
Subject: close #320 as done (14z-210): MAME 0.288's change-notifier teardown crash, the thread pinned; closes on the 139 gates as ruled
Claim (the working agent's sentence): CLAIM: close #320 as done with the comment build/agent210/closures/final/c320.md (fixed in commit 86d1ca10). Its done-when (build/agent210/closures/issues/320.md): "the cause is found and fixed in our Lua or recorded as MAME's (a reproduction of the teardown crash, the version named); every gate that accepts 139 names this ticket and requires its full output." The maintainer ruled how it closes (DECISIONS_HISTORY.md lines 8498-8507, "Close: the 2 are the 139 gates (Recommended)"). That entry is in the working tree and rides the session's close commit.
1. Cause, recorded as MAME's with the version named: docs/platform/gotchas.md lines 3477-3495, "MAME 0.288's `add_change_notifier` KEEPS ITS CALLBACK ON THE CALLING LUA THREAD" (the stack, the 24 macOS crash reports it cites, the rule), with the older tap entry pointing to it at lines 430-438. build/agent210/t320/crash_stacks_batch1.txt holds the ~notifier / luaL_unref stack from the batch's own reports.
2. A reproduction: build/agent210/closures/final/e320_check.txt section 1, read from build/agent210/t320/results.tsv by e320.sh, with the variants defined in build/agent210/t320/lua/tap_writes_v.lua and run by t320/batch.sh and t320/leg.sh. Forced GC (gc) exits 139 in 30 of 30 legs; the same with the thread pinned (pin+gc) in 0 of 30. The tree's unmodified specials_trace.lua (st) exits 139 in 12 of 60, pinned (st+pin) in 0 of 30. The unmodified tap_writes variant (base) exits 139 in 0 of 30. tap:remove() plus notifier:unsubscribe() before exit, with GC (hyp+gc), still gives 30 of 30.
3. Fixed in our Lua: e320_check.txt section 3. The same 13 files of tests/lua call add_change_notifier and carry the pin, one distinct line (the line build/agent210/t320/apply_pin.py inserts). Pinned output is byte-identical to unpinned: e320_check.txt section 2, one md5 per rig over every leg of base and pin, gc and pin+gc, st and st+pin.
4. The gates, as ruled: build/agent210/closures/final/e320_teardown.txt (by e320_teardown.sh, git grep on HEAD e4aa32ee) section D. Two emulator gates name #320 and let a leg exit 139. tests/audit_vanilla_specials_a.sh lines 222-238 test the exit for 0 or 139 and require the field, tick and ALIGN lines; tests/audit_vanilla_pursuits.sh lines 266-275 read no exit code and require each leg's END and FIELDSUMMARY lines. The other 26 emulator gates whose text mentions the segfault are listed in e320_teardown.txt by name with the line that says so; none names #320. The coordinator's search finds 31 files (section A): 26 emulator gates, 4 static gates and 1 library (section B). Its 29 (31 less the library and audit_vanilla_pursuits) include the 4 static runner tests, which run no MAME leg. The wider search (section C) adds audit_hitclass_map_cost and audit_vanilla_specials_a.
5. The comment's "all 61 emulator gates touched this session PASS on the Mac": build/agent210/book/emu/results.tsv, run by build/agent210/book/run_emu.sh, has 61 rows, 61 PASS and rc 0 on every row (e320_check.txt section 6). The 13 instruments it was run for (book/lua_changed.txt) are the pinned set.
NOT TESTED: that each of the 26 gates ignores MAME's exit and judges by its output is read from the one comment line e320_teardown.txt quotes per gate, not from tracing each gate's code. The ruling's question counted 29 where the measured split is 26 output-judging emulator gates plus 4 static runner tests, and it said two gates "test" for 139 where one does (audit_vanilla_pursuits accepts it without reading the exit). The batch, the 61-gate run and the crash-report count ran on the working tree before 86d1ca10 was made, and no artifact ties those copies to the committed blobs. The 24 crash reports sit outside the tree and are taken from gotchas.md. The batch ran on one Mac (rigs AN, DE, FE, JE of #229's specials, two legs at a time), not on Linux or under heavy load. FBNeo is not covered, as the ticket's "Not known" also leaves it.
Artifacts (read every one, in full):
  - build/agent210/closures/final/c320.md
  - build/agent210/closures/issues/320.md
  - DECISIONS_HISTORY.md.lines-8498-8507 (lines 8498-8507 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #320 closes on the two gates that test for 139; #328 waits for a cle")
  - docs/platform/gotchas.md.lines-3477-3495 (lines 3477-3495 of docs/platform/gotchas.md)
  - docs/platform/gotchas.md.lines-430-438 (lines 430-438 of docs/platform/gotchas.md)
  - build/agent210/t320/crash_stacks_batch1.txt
  - build/agent210/closures/final/e320_check.txt
  - build/agent210/closures/final/e320.sh
  - build/agent210/closures/final/e320_teardown.txt
  - build/agent210/closures/final/e320_teardown.sh
  - build/agent210/t320/lua/tap_writes_v.lua
  - build/agent210/t320/batch.sh
  - build/agent210/t320/leg.sh
  - build/agent210/t320/apply_pin.py
  - tests/audit_vanilla_specials_a.sh.lines-222-238 (lines 222-238 of tests/audit_vanilla_specials_a.sh)
  - tests/audit_vanilla_pursuits.sh.lines-266-275 (lines 266-275 of tests/audit_vanilla_pursuits.sh)
  - build/agent210/book/emu/results.tsv
  - build/agent210/book/run_emu.sh
  - build/agent210/book/lua_changed.txt
