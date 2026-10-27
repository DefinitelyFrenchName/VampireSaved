THE PACKET

Decision kind: recommendation
Subject: close #331 as done (14z-210): Demitri's guard cancels joined, the FE..JE section and the stale lines
Claim (the working agent's sentence): CLAIM: close #331 as done with the comment build/agent210/closures/final/c331.md (items 2 and 3 in 86d1ca10, item 1 in e4aa32ee). Its done-when (build/agent210/closures/issues/331.md): "all three are settled and the page regenerated (`tests/test_community_crosscheck.sh`)."
1. Item 1, Demitri's ES Demon Cradle GC: the maintainer ruled "new emulator rig" (DECISIONS_HISTORY.md lines 8460-8471). After the 18-tile pages, the maintainer said "Enough, integrate" (lines 8472-8485). build/agent210/t331b/mention.txt shows the game's "...CANCEL" banner on all 8 GC legs and on no reference leg. build/agent210/t331b/join.txt joins DE 27-30 (STATUS JOINED 4): startup +1, active +1 and recovery +2 on all four, with red, white, gauge whiff and gauge hit at delta +0. So vsavj gives Demitri a guard cancel on LP, MP, HP and PP, and the page's guard-cancel section (docs/project/tables/community_crosscheck.md lines 597-624) says so, "his kicks commit none". Frozen through rule-checker run 2026-10-27-1334: tests/rulecheck/ledger.tsv line 1200 (VIOLATED Q1 Q4, resolved in writing) and tests/rulecheck/runs/2026-10-27-1334/verdict_real.txt. What the freeze changed is in build/agent210/closures/final/e331_check.txt (by e331.sh). The CLOCKS file gains 32 data rows, all DE, and changes only its header comment (e331_check.txt section 1); the out-of-tree table gains 20 lines and loses 0, and hashes as the frozen 54947b5e. build/agent210/t331f/freeze.log ends rc=0. build/agent210/t331f/plain.log has PASS with `rows-absent` ("291 of 291 rigs read MISSING on the empty row set") and `node-shift` FIRED, and t331f/modes.out has each mode exit 1.
2. Item 2, the FE..JE section: page lines 493-534, "## The specials, FE AN AU BI BU DE GA JE". Its line 497 names tests/expected/vanilla_specials_a_verdicts.tsv as what "the table below is rendered from"; that file has six column rows for each of AN AU BI BU DE FE GA and none for JE (build/agent210/closures/final/e331_check.txt section 6). Jedah's reason is at line 524, "Jedah has no row in the table: every Jedah cell is UNCOMPARABLE as a column verdict.", with lines 525-530 explaining it: each of his two rows joins three events.
3. Item 3, the two stale lines: tools/crosscheck_framedata.py line 627 ("the method was rebuilt as a gate") and line 837 (the "not joined" line struck through, "JOINED"); on the page, lines 401 and 652. Section 5 of e331_check.txt shows the page and generator committed (no working-tree change).
4. The page regenerated: build/agent210/rc331/page_freeze.log ends PASS with its controls (a) and (b) ok, and build/agent210/rc331/test_crosscheck_229.log ends PASS. On the committed tree, build/agent210/tier4/tier_results.tsv has test_community_crosscheck PASS (line 120) and test_crosscheck_229 PASS (line 107), with tier4 GREEN (tier.log).
NOT TESTED: The guard-cancel identity rests on the maintainer's reading of the 18-tile pages. Those pages show the banner as far as "D CANCEL", never the full words "GUARD CANCEL" (mention.txt). The offsets +1/+1/+2 are named on the page, not adjudicated. The rig forces Demitri by poke against two victims; FBNeo, other victims and cursor picks are not covered. rc331/page_freeze.log ran on the working tree before e4aa32ee was made; the committed tree's evidence is the tier4 rows.
Artifacts (read every one, in full):
  - build/agent210/closures/final/c331.md
  - build/agent210/closures/issues/331.md
  - DECISIONS_HISTORY.md.lines-8460-8485 (lines 8460-8485 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-26 (14z-210) — #331's Demitri guard cancels get an emulator rig; #310's UNJUDGED cl", and the entries after it up to line 8485)
  - build/agent210/t331b/mention.txt
  - build/agent210/t331b/join.txt
  - docs/project/tables/community_crosscheck.md.lines-597-624 (lines 597-624 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-493-534 (lines 493-534 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-399-403 (lines 399-403 of docs/project/tables/community_crosscheck.md)
  - docs/project/tables/community_crosscheck.md.lines-650-654 (lines 650-654 of docs/project/tables/community_crosscheck.md)
  - tools/crosscheck_framedata.py.lines-627-627 (lines 627-627 of tools/crosscheck_framedata.py)
  - tools/crosscheck_framedata.py.lines-837-837 (lines 837-837 of tools/crosscheck_framedata.py)
  - tests/expected/vanilla_specials_a_verdicts.tsv
  - tests/rulecheck/ledger.tsv.lines-1200-1200 (lines 1200-1200 of tests/rulecheck/ledger.tsv)
  - tests/rulecheck/runs/2026-10-27-1334/verdict_real.txt
  - build/agent210/closures/final/e331.sh
  - build/agent210/closures/final/e331_check.txt
  - build/agent210/t331f/freeze.log
  - build/agent210/t331f/plain.log
  - build/agent210/t331f/modes.out
  - build/agent210/rc331/page_freeze.log
  - build/agent210/rc331/test_crosscheck_229.log
  - build/agent210/tier4/tier_results.tsv.lines-107-107 (lines 107-107 of build/agent210/tier4/tier_results.tsv)
  - build/agent210/tier4/tier_results.tsv.lines-120-120 (lines 120-120 of build/agent210/tier4/tier_results.tsv)
  - build/agent210/tier4/tier.log.lines-455-460 (lines 455-460 of build/agent210/tier4/tier.log)
