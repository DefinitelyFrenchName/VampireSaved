THE PACKET

Decision kind: recommendation
Subject: close #329 as done (14z-211): the half circles' minimal inputs are 6324 and 4123 from the handlers and measured; the motion test re-rigged and re-frozen; every changed row shown
Claim (the working agent's sentence): CLAIM: close #329 as done with the comment build/agent211/t329/closure/c329.md, and land the re-rigged motion test with its re-frozen expectations (tests/expected/command_throws.tsv, tests/expected/instr_gameclock/audit_command_throws.tsv) in the 14z-211 commit that marks the row done (docs/project/tickets.tsv:79). The ticket's done-when (issue329.md): "the minimal input each half-circle command accepts on vsavj is measured from the command handlers (not only by trying spellings), documented in the engine notes, and the frozen labels say whether each is the minimal one". It rests on:
1. THE HANDLERS' TABLES: decode_tables.txt (written by decode_tables.py from vsavj's and vsav2's data and opcode views, each sha1 printed) reads vsavj 0x2A684 and 0x2A68E as 6 3 2 4 with 17 jsr callers between them, 0x2A670 and 0x2A67A as 4 1 2 3 with 20, 0x2A698 as 6 3 2 1 4 and 0x2A722 as 4 1 2 3 6 with one caller each, and, for vs2, prints every helper of its helper family (opcode view 0x29114-0x291FF, a lea then bra.w / jmp.l / jmp (pc), whatever the dispatcher; "vs2 helpers found in the family: 30, every one printed above"), each table's raw words from the data view and each helper's jsr callers over the whole program: the half-circle direction tables among them are 0x299CE/0x299DA (4 1 2 3 6) and 0x299E6/0x29A06 (6 3 2 1 4) on the motion dispatcher 0x292A4, five steps each; the 0x2938A helpers point at charge tables (bit-7 mask steps) and the 0x29422 ones at button-sequence words; and over the WHOLE vs2 program 558 lea (d16,pc),An, 0 of them point into 0x299F2-0x29A05. The numpad reading uses the step codes toward 2, back 1, down 4, up 8 (see NOT TESTED).
2. THE MATCHING: dispatcher.txt (vsavj opcode view, 0x29F4A-0x2A030 and the shared tails): states 0 (0x29F5C) and 2 (0x29F96) compare the step's low nibble with the low nibble of the word at +0x12A by cmp.w unless the step's bit 7 is set; in state 2 a mismatch branches to 0x2A57C (d0 = 0, the state kept), a match to the advance at 0x2A524; a step with bit 4 set moves to state 4 (0x29FD6), which ANDs step & 0x7700 with +0x1AC|+0x1AE. So each listed direction must arrive in order and others are waited through: 6324 and 4123 are the shortest spellings these tables accept.
3. THE OLD RIG: tests/lua/replay.lua.lines-105-131 holds a token on every frame `for fr = a, b`. fed_frames.txt (fed_frames.py, reading each rig at git HEAD and in the tree) shows HEAD's AU "motion 624HP" fed 6 6 3 2 1 4 (sequence 63214) and the tree's fed 624; the same for 6214HP (HEAD 63214, tree 6214), 624HK, 426LP (HEAD 41236) and 4126LP; the tree's shared-frame control is fed 63214.
4. THE RE-FREEZE on PILOT (a worktree of scratch commits of this change on 432d5c7e): r1.log (FREEZE=1) 148 legs ended clean, FROZE 168 events, and 6 alignment problems, all on ct_AU_3 (lengthened by the control); r2.log (--freeze-clock) froze 111 game clocks; r3.log PASS with every control line FIRED. The labels then marked `minimal` (code_diff.txt): r4.log (FREEZE=1) FROZE 168 events, 168 checked 0 bad, every guarded leg at its frozen game clock (111 runs), PASS; r5.log (verify) 168 checked 0 bad, the same 111-run alignment line, 12 CONTROL FIRED lines, PASS. expect_diff.txt is the diff of tests/expected/command_throws.tsv against HEAD and the tally of the motion rows: the 6214, 624, 4126, 4236 and 426 rows hold no command move (P2 held only with move_kind throw: 8 of the 14 6214 rows, 10 of the 14 624 rows); the 6324, 6321, 63214, 4123 and 41236 rows keep their old held/kind/sig; the control row's line equals HEAD's "motion 624HK" line (sig 9bd3a7e490bb997f).
5. THE CONTROL COUNTS: derive_counts.txt (derive_counts.py over the full lines before, full_old_14z208b.tsv, and after, and r5's x_unsigned_r5.txt) gives 157 -> 159 events with a staged record and with a fall, 34 -> 29 spending stock (the five rows named), 10 of Sasquatch's 13 events changing under the unsigned read; code_diff.txt sets the five wants to those.
6. THE JOIN: code_diff.txt leaves the motion events out of `join` as it leaves the controls out; xc_oldjoin.txt and xc_newjoin.txt (tools/crosscheck_229.py ct on r3's legs, the old and the new join) differ only in the ROWS line (strengths differ 12 -> 1), and their red/white/gauge/startup lines carry the figures of the page's table, docs/project/tables/community_crosscheck.md.lines-589-596.
7. THE RECORDS: docs/game/engine_internals.md.lines-1514-1563 (the tracker paragraph, the punch/kick pairs and the retune example corrected) and .lines-1566-1618 (the section, the 14z-208b reading kept under RETRACTED, the maintainer's reading of the sheets); docs/project/gotchas.md.lines-7707-7722 (the trap, with overlap_census.out's census); the ruling, DECISIONS_HISTORY.md.lines-8537-8573 (the maintainer's "yes" to the plan, and the readings of the sheets below).
8. THE CAPTURES (runs 2026-10-27-1353, -1354, -1355 and -1359 stopped this closure on what had been shown, all resolved): four sets of sheets, nine tiles per event, were put to the maintainer (DECISIONS_HISTORY.md.lines-8537-8573). The first set, Aulbath's 6324HP, 6321HP, 6214HP, 624HP, the shared-frame 624HK and the true 624HK, and Q-Bee's 4123LP, 4126LP, 4236LP and 426LP (p211_snap.sh on PILOT: each rig's CAP leg as the gate runs it, its pokes, nine SNAP_FRAMES per event; sheet329.py drew the two pages on the Mac): "Do these pictures show what the labels say?" — "Yes, they do". The second set, 30 more events spelt 6214, 624, 4126, 4236 or 426 (tool_p3.out to tool_p6.out, drawn by tools/command_throw_sheet.py on PILOT): "Do these four pages show what their labels say?" — "Yes". The third, Aulbath's motion 6214HK, the one changed row the first two had missed (shown_census_before.txt; drawn by the instrument, tool_p7.out): "Does this page show what its label says?" — "yes it is correct (in all likeliness what came out of the input chain was 4+HK)". The fourth, the true 6324 on the thirteen other grabs, whose input the re-rig changed though their line did not (shown_census_before2.txt; tool_p8.out, tool_p9.out): "Do these two pages show what their labels say?" — "yes". shown_census.txt (shown_census.py over the frozen file and the rigs, at HEAD and in the tree, and shown.txt; it compares each row's frozen line AND the directions its rig feeds the game) reads: 37 rows with line and input changed, the new control and 14 rows with only the input changed, all shown; 2 rows unchanged and shown; 18 rows with line and input unchanged, unshown; no changed row unshown. sheets_manifest.txt holds every shown page's sha1. The capture is now the instrument tools/command_throw_sheet.py (in the tree; its catalogue row docs/project/operations.md.lines-38-38): rerun on PILOT at the tree's blob (sheets_manifest.txt), it drew the first set's two pages again (tool_p1.out, tool_p2.out) and tool_cmp.txt reads "90 same" — each of its 90 snapshots byte-identical, by cmp, to those on the pages shown.
NOT TESTED: the step-code mapping (toward 2, back 1, down 4, up 8) was not measured at this sitting — it is read from docs/game/atlas/ram.md's +0x12B row (+0x395's R1 L2 D4 U8 with L/R swapped by the flip source) and is consistent with the measured outcomes (4123 grabs, 426 and 4236 do not). No spelling shorter than the five per side was run (324, 634, 423 and the like rest on point 2 alone). The left-facing side, other cadences (slower steps, a release between directions) and vs2 in-game were not measured; vs2 references into 0x299F2-0x29A05 other than a PC-relative lea (an absolute address, a computed one) were not searched. Whether the rotation tracker (0x2A1B4) needs the cardinals alone is not measured: the 360/720 rigs still feed one-frame diagonals, and the engine notes now say so (engine_internals.md.lines-1566-1618). The gate and the instrument ran on PILOT only, not on the Mac or ERIS; the first set's pages shown were drawn by sheet329.py, not by the instrument, whose own versions of them were not shown (their snapshots are the shown ones, tool_cmp.txt); the second set was drawn by the instrument and shown as drawn. The 18 motion-test rows shown_census.txt reads unshown were not shown at this sitting: their frozen line AND their fed input are unchanged from HEAD's 14z-208b rows (shown_census.txt 'same' / 'input-same'), which the maintainer confirmed then (issue329.md). The static tier on the staged tree has not run yet: it runs after this check, before the commit. The frozen runs used scratch commits whose tree differs from the commit to come in the records (STATE.md, DECISIONS_HISTORY.md, docs, the ticket row and page, the generated indexes), not in the gate, the rigs, the generator or the expectations.
Artifacts (read every one, in full):
  - build/agent211/t329/closure/c329.md
  - build/agent211/t329/closure/issue329.md
  - build/agent211/t329/closure/decode_tables.py
  - build/agent211/t329/closure/decode_tables.txt
  - build/agent211/t329/closure/dispatcher.txt
  - build/agent211/t329/closure/fed_frames.py
  - build/agent211/t329/closure/fed_frames.txt
  - build/agent211/t329/closure/r1.log
  - build/agent211/t329/closure/r2.log
  - build/agent211/t329/closure/r3.log
  - build/agent211/t329/closure/r4.log
  - build/agent211/t329/closure/r5.log
  - build/agent211/t329/closure/expect_diff.txt
  - build/agent211/t329/closure/derive_counts.py
  - build/agent211/t329/closure/derive_counts.txt
  - build/agent211/t329/closure/full_old_14z208b.tsv
  - build/agent211/t329/closure/x_unsigned_r5.txt
  - build/agent211/t329/closure/code_diff.txt
  - build/agent211/t329/closure/xc_oldjoin.txt
  - build/agent211/t329/closure/xc_newjoin.txt
  - build/agent211/t329/closure/overlap_census.out
  - build/agent211/t329/closure/p211_snap.sh
  - build/agent211/t329/closure/sheet329.py
  - build/agent211/t329/closure/sheets_manifest.txt
  - build/agent211/t329/closure/tool_p1.out
  - build/agent211/t329/closure/tool_p2.out
  - build/agent211/t329/closure/tool_p3.out
  - build/agent211/t329/closure/tool_p4.out
  - build/agent211/t329/closure/tool_p5.out
  - build/agent211/t329/closure/tool_p6.out
  - build/agent211/t329/closure/tool_p7.out
  - build/agent211/t329/closure/tool_p8.out
  - build/agent211/t329/closure/tool_p9.out
  - build/agent211/t329/closure/tool_cmp.txt
  - build/agent211/t329/closure/shown_census.py
  - build/agent211/t329/closure/shown.txt
  - build/agent211/t329/closure/shown_census.txt
  - build/agent211/t329/closure/shown_before.txt
  - build/agent211/t329/closure/shown_census_before.txt
  - build/agent211/t329/closure/shown_census_before2.txt
  - tools/command_throw_sheet.py
  - build/agent205/t229/f4_throws/handlers.out
  - tests/lua/replay.lua.lines-105-131 (lines 105-131 of tests/lua/replay.lua)
  - docs/project/tables/community_crosscheck.md.lines-589-596 (lines 589-596 of docs/project/tables/community_crosscheck.md)
  - docs/project/operations.md.lines-38-38 (lines 38-38 of docs/project/operations.md)
  - docs/game/engine_internals.md.lines-1514-1563 (lines 1514-1563 of docs/game/engine_internals.md)
  - docs/game/engine_internals.md.lines-1566-1618 (lines 1566-1618 of docs/game/engine_internals.md)
  - docs/project/gotchas.md.lines-7707-7722 (lines 7707-7722 of docs/project/gotchas.md)
  - DECISIONS_HISTORY.md.lines-8537-8573 (lines 8537-8573 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-211) — #329: the motion test re-rigged, re-frozen on PILOT, the notes corre")
  - docs/project/tickets.tsv.lines-79-79 (lines 79-79 of docs/project/tickets.tsv)
