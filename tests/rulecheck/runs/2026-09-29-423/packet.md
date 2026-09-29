THE PACKET

Decision kind: recommendation
Subject: 14z-185 close: the documentation packet — the findings table (row 14) and the close checklist steps 2-5 (re-checked after 422)
Claim (the working agent's sentence): Record the 14z-185 documentation as complete: STATE row (14), THE FINDINGS TABLE (row14.txt), and the close checklist's steps 2-5 as the CLOSE row states them (close_row.txt).
(1) The table lists 23 findings (a)-(w). Each has a live home, and each has a test or an explicit "none" with the reason. home_texts.py reads each finding's home clause from the row itself and finds every quoted text in its named file (runs/home_texts.out: 23 findings, 27 pairs, 25 texts, 0 failures). Its two plants, a mistyped text and a missing file, each exit 1.
(2) close_findings.py 14z-185 exits 0: GAPS none, PROMISES none. Its two REVIEW addresses are finding (a)'s guard-cancel commit routines, first homed by this sitting's commit f17fa818 before the tool's base 18248b6a (evidence.txt section 3). homes_tracked.py exits 0.
retraction_grep.py also exits 0, but its exit gates only the reach and gone patterns, not a retracted wording's live hits. So every hit is classed by retraction_classes.py (runs/retraction_classes.out): 28 occurrences, ARCHIVE 8, MARKED 13, SCOPED-TRUE 1, SESSION 3, SITE 3, UNMARKED 0. Each occurrence is classed by its OWN unit (its paragraph; for a table row, its clause), against strong marks only, the SESSION class included; a unit-split check exits 2 if the per-file sum over units differs from the whole-file count. Its three plants are injected into real text and each exits 1 on exactly its planted copy: an unmarked paragraph in tests/audit_walker_ghost.sh, which carries a MARKED copy of the same wording; the same followed by a marked paragraph; an unmarked clause in the STATE row of this group that carries the wording's SESSION copy. The three wordings added at this close for the false "--stale re-runs it" claim have 0 hits.
tests/test_state_open_lists.sh PASSes. Every check and plant is run by run_checks.sh, which writes each exit code to runs/exits.tsv: 35 runs, 0 not as expected; a plant counts as FIRED only on exit 1 with no traceback in its output. run_checks.sh also regenerates, on every run, evidence.txt (from evidence.sh) and promotion_equivalence.txt (from promotion_equivalence.sh), each with a fingerprint line (the time and its script's sha256) and every result printed under the command that produced it, and pointers.txt (read from STATE.md at the run, each tail checked for a forward pointer), so every evidence file cited here is the current tools' output. Its last check, close_figures.py, reads from the row the figures it names in its docstring — the checks' figures, the MiSTer re-run's verdicts and times, the re-run's reach and walk figures, every promotion-count figure, and the promises' file and follower counts — and compares each with the output it came from (runs/close_figures.out: 0 mismatches or missing); its plant shifts the row's run total by +100 and exits 1.
(3) Pointers are set on 14z-184 row (8) and on this sitting's rows (2), (5), (6) and (9) (pointers.txt, from pointers.py: each row's tail read from STATE.md now, exit 1 on a missing row or a tail with no forward pointer).
(4) The tool lists no promises. The 14z-184 opener's two re-run promises are met gate by gate (evidence.txt section 4; runs/promises.out). promises.py parses promise 4's nine files from the promise's own text (the 14z-184 opener in docs/NEXT_SESSION_HISTORY.md, printed verbatim in runs/promises.out: every backticked token that is a tracked file, with the backticked tokens that are no file and every un-backticked token with a slash printed too) and promise 5's three from the two 14z-183 close commits (12571807, 1a20119e), and takes each file's followers from three finders: the tree's one FOLLOWS reader, tools/gate_follows.py; every registry gate whose own text names the file's path; else every registry gate naming its basename alone. tests/test_replay_stage_census.sh, which no emulator-tier gate follows, is itself a portable-tier gate and PASSed in the M21 freeze's tier (build/rc185/tier_freeze_m21.log). Every follower any finder names ran in the M21 battery: it passed, or it was a battery red that was re-frozen and verified PASS — 18 gates follow tests/audit_move_parity.sh alone, the gate itself included. The exception is audit_wide_phase_a (scope out), which was run at this close: PHASE A COMPLETE, 4 DECISION lines, exit 0, with 8 tolerated teardown segfaults. Its four plants, an unverified red, an unfollowed file in each promise, and a backticked tracked .py no gate follows written into promise 4's TEXT before the parse, each exit 1.
(5) ON TRIAL: five quoted scratch scripts, three promoted.
- tools/battery_reach.py is byte-identical across two hash seeds: seeds.sh (runs/seeds.out) prints its command, runs it on the M21 battery's inputs under PYTHONHASHSEED=1 and =2 and compares the WHOLE outputs, via lines included — 587 lines, 116 via lines each, one sha256; its plant alters one byte and exits 1. Its 7 non-via lines that differ from the scratch run are each explained by a measured tree change (promotion_equivalence.txt: the diff of the promoted run of record br1.out — its command shown from the transcript — against the scratch output, and each explanation under its git command); that diff leaves the via lines out because a via line names the first reference that reached a file, and the tree changed between the scratch and promoted runs. Its scanned-file count, 9740 -> 9770, is measured by promotion_count.py (runs/promotion_count.out): 35 files born between the two runs under both runs' index roots (tools/, tests/ and the sibling harness, the two runs' EXTRA_ROOTS asserted equal; the harness shows no commit between them and a clean tree), one a rewrite, so 34 new (runs 401-405's 30 files, the 3 new tools, pointer_flow/merged-m21.txt), and 4 gone; 789 + 3 born - 792 = 0, so none of the 4 is a program, and the tool follows only programs. Its plant, a phantom born program, exits 1.
- tools/attr_placement_moves.py and tools/patch_site_read.py differ from their scratch outputs by 0 lines.
- The equivalence run's exit 1 is the two NON-ADDRESS pairs, by design (evidence.txt section 6, which re-runs the tool on the five tier-red logs every time evidence.txt is regenerated).
RUN 341 was abandoned before any reader: it has no ledger row and no directory, one prepare call's result names it, and no Agent call in the transcript names it (evidence.txt section 1).
THE ORDERINGS: runs 374/375 and 399/400 were each a refused combined-label resolve, chained, that let the next prepare run first. Both are shown from the session transcript (evidence.txt section 2, which finds every call that runs rulecheck.py's resolve of run 374 or 399 — an invocation-only regex — and ties each to its own result by tool_use id, printing its label, whether the same command runs rulecheck.py prepare after the resolve, and whether its result names the next run as prepared), and the rule is recorded in docs/project/rule_checker.md.
THE MISTER RE-RUN on commit 28555610 is GREEN, PASS 3: its commit, its results.tsv, the driver log's summary and GREEN lines and prg_window's pair line are shown in evidence.txt section 7 and in the two files themselves. The 12 paths the driver log lists as DIRTIED during the run are a reach question, answered by reach_mister2.py over tools/battery_reach.py (runs/reach_mister2.out, runs/battery_reach_mister2.out): of 72 code lines in the reach naming a dirtied basename, those that open a file sit in four programs, each reached only through a comment or string mention and none in the STRICT set; test_skill_guides.sh's opens the undirtied docs/platform/gotchas.md; the jtcores tree names the files only in comments. Its plant, a STRICT program's line classed as a read, exits 1. A read through a directory walk or glob names no file, so walkers_mister2.py lists every walk, glob, listing or tree copy its pattern matches in the run's STRICT set (battery_reach's own closure, 53 files) — the pattern includes argument-list subprocess forms, copytree, cp -R, rsync, tar and zip: 32 lines, each judged by hand in walkers_table.py (what it walks, whether that holds a dirtied path, whether it ran in this re-run). None that ran walks a directory holding a dirtied path; the one that would, tools/audit_emulator_staleness.py:87 (the repo's changed and untracked file NAMES), runs only under --stale (tests/run_all_emulator.sh:197), and the re-run's own command, shown from the transcript in evidence.txt section 7, carries no --stale. Its plant, one judgement forgotten, exits 1; a recall control asserts the pattern matches five known forms before the scan, and a recall plant (a synthetic subprocess.run(["git", "ls-files", "docs"]) line) is found and exits 1.
THE RULINGS recorded are quoted in the maintainer's own words (evidence.txt section 5).
NEXT_SESSION is rewritten (NEXT_SESSION.md), with the maintainer's new queue quoted verbatim.
NOT TESTED:
- That the table is COMPLETE: that no finding of the sitting is missing. The tools check the homes of the findings listed, not the findings not listed, and close_findings.py sees addresses, not findings.
- The close's static tier, sweep, procedure-check part 8 and worker cap, which follow this check.
- Whether each quoted home text states its finding correctly (the check is text presence).
- That a strong mark in the same unit as a retracted wording refers to THAT wording: the classifier checks the mark's presence in the unit, not what it marks.
- RECALL, for every finder here (each is a pattern): a follower that names a promised file in none of the three ways (declared, path, basename), or reaches it through a third program; a walk, listing or copy written in a form the walk pattern does not match; a dirtied file read through a path assembled from variables without a walk (battery_reach lists the variable bases and cannot resolve them).
- That each finding's named test REPRODUCES the finding: homes_tracked.py checks only that the file is tracked.
- That no STATE row beyond those in pointers.txt needed a forward pointer: that is judged at the close, not checked.
- That walkers_table.py's judgements are right line by line: written by hand, every line printed for checking.
- That reach_mister2.py's READ/MENTION table is right line by line: it is written by hand from the 72 lines, all printed in its output for checking, and the tool finds lines, it does not judge them.
- The via lines of the scratch-vs-promoted comparison: not compared (the reason above); the seed check compares them between two runs of the promoted tool.
- Which 4 files were gone at the promoted run: untracked removals leave no record; only that none was a program is shown.
Artifacts (read every one, in full):
  - build/agent185/close/row14.txt
  - build/agent185/close/close_row.txt
  - build/agent185/close/pointers.txt
  - build/agent185/close/pointers.py
  - build/agent185/close/promotion_equivalence.txt
  - build/agent185/close/promotion_equivalence.sh
  - build/agent185/close/seeds.sh
  - build/agent185/close/runs/seeds.out
  - build/agent185/close/runs/seeds_plant.out
  - build/agent185/close/promotion_count.py
  - build/agent185/close/runs/promotion_count.out
  - build/agent185/close/runs/promotion_count_plant.out
  - build/agent185/close/evidence.txt
  - build/agent185/close/evidence.sh
  - build/agent185/close/promises.py
  - build/agent185/close/runs/promises.out
  - build/agent185/close/runs/promises_plant.out
  - build/agent185/close/runs/promises_plant_orphan.out
  - build/agent185/close/runs/promises_plant_orphan5.out
  - build/agent185/close/runs/promises_plant_parse.out
  - build/agent185/close/reach_mister2.py
  - build/agent185/close/runs/reach_mister2.out
  - build/agent185/close/runs/battery_reach_mister2.out
  - build/agent185/close/walkers_mister2.py
  - build/agent185/close/walkers_table.py
  - build/agent185/close/runs/walkers_mister2.out
  - build/agent185/close/runs/walkers_mister2_plant.out
  - build/agent185/close/runs/walkers_mister2_recall.out
  - build/agent185/close/home_texts.py
  - build/agent185/close/retraction_classes.py
  - build/agent185/close/close_figures.py
  - build/agent185/close/run_checks.sh
  - build/agent185/close/runs/exits.tsv
  - build/agent185/close/runs/home_texts.out
  - build/agent185/close/runs/close_findings.out
  - build/agent185/close/runs/homes_tracked.out
  - build/agent185/close/runs/retraction_grep.out
  - build/agent185/close/runs/retraction_classes.out
  - build/agent185/close/runs/retraction_classes_plant.out
  - build/agent185/close/runs/retraction_classes_plant_neighbour.out
  - build/agent185/close/runs/retraction_classes_plant_session.out
  - build/agent185/close/runs/close_figures.out
  - build/agent185/close/runs/close_figures_plant.out
  - build/agent185/close/runs/state_open_lists.out
  - build/agent185/close/runs/attr_placement_plant.out
  - build/agent185/close/runs/home_texts_plant.out
  - build/agent185/close/audit_wide_phase_a.log
  - build/emu_freeze_m21_mister2/results.tsv
  - build/rc185/emu_mister2.driver.log
  - build/rc185/tier_freeze_m21.log
  - docs/NEXT_SESSION.md
