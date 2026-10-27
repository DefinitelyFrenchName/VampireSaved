THE PACKET

Decision kind: recommendation
Subject: close #321 as done (14z-210): each avenue measured or ruled out, four defaults raised, the release shape 12,575 -> 7,947 s; the remainder is #334
Claim (the working agent's sentence): CLAIM: close #321 as done with the comment build/agent210/closures/final/c321.md (688edef8, 86d1ca10, e4aa32ee). Its done-when (build/agent210/closures/issues/321.md): "1. Each avenue above is measured or ruled out with a reason. 2. Each gate whose default changes has its new default derived from the host (capped), with the seconds before and after on the hosts that run it, and the battery's verdicts unchanged. 3. The tier's wall time is measured before and after." The maintainer ruled how it closes (DECISIONS_HISTORY.md lines 8510-8517, "Close; file the remainder (Recommended)"). Item 1 rests on "measured or ruled out" per avenue, and #334 carries what was asked but not measured (docs/project/tickets.tsv line 74, tickets_github.tsv line 7, tickets.md line 20). The ruling, the #334 rows and docs/project/operations.md lines 681-683, 709-714 and 718-719 are working-tree changes that ride the session's close commit. The record is operations.md lines 659-697 and 699-734.
1. Avenues, each measured or ruled out:
   (1) The job knobs: four defaults raised (item 2 below). The rest were measured inside ERIS's freeze tier at 688edef8 (busy 0.546 / 0.764 / 0.820 by thirds) and alone, and were not raised, by the ruling in DECISIONS_HISTORY.md lines 8439-8459 (operations.md 705-708).
   (2) Gates with no knob: test_mame_wide took WIDE_JOBS (tests/test_mame_wide.sh lines 50-58), ruled with the 14z-209 phase-2 speed-ups (DECISIONS_HISTORY.md lines 8334-8351).
   (3) Controls: emulator controls as pool jobs, ruled in DECISIONS_HISTORY.md lines 8407-8422 and listed from a PILOT write trace (tests/controls_concurrent_emu.txt, 60 rows, header lines 1-16; audit_release_linux_cleanhost left off for podman's /etc/X11 writes). The six SHARED static gates are ruled out at "at most 60 s per tier" (operations.md 720-721).
   (4) The freeze and close tools: SUITE_JOBS, 1662 s at 1, 425 s at 4 and 290 s at 8 (build/agent210/t321suite/times.tsv, by measure.sh). The three outputs are identical, and each ends "SUITE RED" with 8 NO-EXPECTATION lines (build/agent210/closures/final/e321_suite_cmp.txt). The close tools take seconds (operations.md 731-733).
2. The four changed defaults, each host-derived and capped, before against after:
   - audit_guard_corpus JOBS, min(8, CPUs/3): tests/audit_guard_corpus.sh lines 53-56 (ERIS: 3,106 s at 2 against 1,138 s at 8 alone; 4,827 s at 2 in the 14z-208b tier against 1,679 s at 8) and lines 88-92 (the code). The Mac: build/agent210/t321mac/times.tsv has 1906 s at JOBS=2 against 984 s at the default (run.sh calls them "the old count" and "the default"; the j4 log reads JOBS=4), both PASS 388 guarded runs.
   - test_mame_parity PARITY_JOBS, min(16, CPUs x 2/3): tests/test_mame_parity.sh lines 66-72 (ERIS: 2,485 s at 1 against 244 s at 16) and 98-100 (the code). PILOT: build/agent210/t321p/parity/times.tsv, 2067 s at 1 against 548 s at the default. The Mac: the issue body's 1,749 s serial against build/agent210/t321par/run/results.tsv's PASS 342 s at the default (run.out GREEN; build/agent210/t321par/ncpu.txt reads 12, so the default is 8 by lines 98-100).
   - test_mame_wide WIDE_JOBS, min(6, CPUs/4): tests/test_mame_wide.sh lines 53-58 and the issue body (3,746 s in 14z-208b's freeze on ERIS) against build/agent210/t321k/results_tier.tsv's PASS 682 s at 688edef8 (k_setup.sh). The Mac: t321mac/times.tsv has 1385 s at 1 against 490 s at the default, with outeq.out reading SAME.
   - audit_merged_legacy MERGED_JOBS, min(6, CPUs/4) (tests/audit_merged_legacy.sh lines 418-425): the Mac build/agent210/book/mq/times.tsv has 713 s at 1 against 432 s (outeq.out SAME). ERIS: PASS 1832 s in t321k/results_tier.tsv against PASS 971 s in build/agent210/t321e2/freeze_results.tsv.
   - The PASSes per host: the Mac logs (t321mac/*.log, book/mq/*.log, t321par) and ERIS's freeze tiers (t321k, t321e2) read PASS for each gate. Battery verdicts: build/agent210/t321e2/compare2.txt, "421 shared rows, 0 differ".
3. Wall time: build/agent210/t321e2/SUMMARY.md and compare2.txt, the release shape on ERIS, 7,947 s at 86d1ca10 against 14z-208b's 12,575 s; no row over half its cap (max 0.47). The freeze tier took 4,233 s against fork K's 4,361 s (t321k/tier.meta), and 4,208 s at --jobs 12. The side fixes and #333 are in DECISIONS_HISTORY.md lines 8486-8498, build/agent210/closures/final/e321_commits.txt and e321_mktemp.txt (106 sites, 101 files).
NOT TESTED: what #334 holds. The knobs that were not raised were not measured on PILOT, nor on the Mac under a tier's load, and the knob-less gates other than test_mame_wide were not surveyed. The ERIS figures for audit_guard_corpus, test_mame_parity and test_mame_wide come from the gates' own headers (14z-209, fork A, build/agent209/t321/), not from a run in this packet. The Mac parity run's job count (8) is derived from ncpu.txt and the code; its log does not print it. test_mame_parity is PARTIAL on PILOT by design and is not run on ERIS ("Parity only on the Mac"). The Mac parity run records a dirty working tree (t321par/run/commit.txt lists the uncommitted files), and t321mac and book/mq record no commit at all. The ERIS release run 1 on a full tmpfs is not a measurement (SUMMARY.md).
Artifacts (read every one, in full):
  - build/agent210/closures/final/c321.md
  - build/agent210/closures/issues/321.md
  - DECISIONS_HISTORY.md.lines-8510-8517 (lines 8510-8517 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #321 closes on what is measured; its two survey gaps become a new ti")
  - DECISIONS_HISTORY.md.lines-8334-8351 (lines 8334-8351 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-26 (14z-209) — #321 phase 2: all four speed-ups, parity on the Mac only, #305 with ")
  - DECISIONS_HISTORY.md.lines-8407-8422 (lines 8407-8422 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-26 (14z-210) — #321: emulator controls as pool jobs, proven by a PILOT write trace;")
  - DECISIONS_HISTORY.md.lines-8439-8459 (lines 8439-8459 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-26 (14z-210) — #321 avenue 1: the merged-legacy queue only; the guard-cancel table ")
  - DECISIONS_HISTORY.md.lines-8486-8498 (lines 8486-8498 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #321: a control mode's environment error is DIED; the emulator runne")
  - docs/project/tickets.tsv.lines-74-74 (lines 74-74 of docs/project/tickets.tsv)
  - docs/project/tickets_github.tsv.lines-7-7 (lines 7-7 of docs/project/tickets_github.tsv)
  - docs/project/tickets.md.lines-20-20 (lines 20-20 of docs/project/tickets.md)
  - docs/project/operations.md.lines-659-697 (lines 659-697 of docs/project/operations.md)
  - docs/project/operations.md.lines-699-734 (lines 699-734 of docs/project/operations.md)
  - tests/audit_guard_corpus.sh.lines-49-56 (lines 49-56 of tests/audit_guard_corpus.sh)
  - tests/audit_guard_corpus.sh.lines-88-92 (lines 88-92 of tests/audit_guard_corpus.sh)
  - tests/test_mame_parity.sh.lines-66-72 (lines 66-72 of tests/test_mame_parity.sh)
  - tests/test_mame_parity.sh.lines-98-100 (lines 98-100 of tests/test_mame_parity.sh)
  - tests/test_mame_wide.sh.lines-50-58 (lines 50-58 of tests/test_mame_wide.sh)
  - tests/test_mame_wide.sh.lines-93-96 (lines 93-96 of tests/test_mame_wide.sh)
  - tests/audit_merged_legacy.sh.lines-418-425 (lines 418-425 of tests/audit_merged_legacy.sh)
  - tests/controls_concurrent_emu.txt.lines-1-16 (lines 1-16 of tests/controls_concurrent_emu.txt)
  - build/agent210/t321mac/times.tsv
  - build/agent210/t321mac/run.sh
  - build/agent210/t321mac/outeq.out
  - build/agent210/t321mac/guard_corpus_j2.log
  - build/agent210/t321mac/guard_corpus_j4.log
  - build/agent210/t321p/parity/times.tsv
  - build/agent210/t321par/ncpu.txt
  - build/agent210/t321par/run/results.tsv
  - build/agent210/t321par/run.out
  - build/agent210/t321par/run/test_mame_parity.log
  - build/agent210/t321par/run/commit.txt
  - build/agent210/t321suite/times.tsv
  - build/agent210/t321suite/measure.sh
  - build/agent210/closures/final/e321_suite_cmp.txt
  - build/agent210/book/mq/times.tsv
  - build/agent210/book/mq/outeq.out
  - build/agent210/book/run_mq.sh
  - build/agent210/t321k/results_tier.tsv
  - build/agent210/t321k/tier.meta
  - build/agent210/t321k/k_setup.sh
  - build/agent210/t321e2/freeze_results.tsv
  - build/agent210/t321e2/SUMMARY.md
  - build/agent210/t321e2/compare2.txt
  - build/agent210/closures/final/e321_commits.txt
  - build/agent210/closures/final/e321_mktemp.txt
