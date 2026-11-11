THE PACKET

Decision kind: expectation
Subject: #369 migration batch 1: 210 gates off the debt list (310 rows to 100), every declared mode honoured only on its own CONTROL CAUGHT line, and piece 5 (the dead-leg and crash-sweep tables name the speaker) wired
Claim (the working agent's sentence): #369's migration batch 1 can land on main as M369_scope.md states it, once a strict --confirm tier of the staged tree 0a83169a (scratch 7381fed0) reads GREEN, which the pre-commit guard requires and which has not run yet: 210 gates leave the shrink-only debt list (debt_list.diff.txt, 310 rows to 100; the 100 left are the gates piece 5's frozen dead-leg and crash-sweep columns tie to), each declared mode of each of the 210 now ends in vs_ctl_caught on its main check's finding (caught_sites.txt, from the staged tree), and piece 5 is wired as the maintainer ruled "Name the speaker (Recommended)" (RULING.txt; lib_tools.diff.txt: classify.sh's speaker and vs_ctl_class_word, read by crash_sweep.sh (lines 120-130), test_dead_leg_unjudged (lines 140-225) and test_plants_not_applied (lines 50-60), and the acceptors of the new class word, probed in acceptors_probe.txt). Of the 831 declared modes (ledger_compact.tsv), 829 read HONOURED on their own CONTROL CAUGHT line on a host. The 555 static modes ran on PILOT (ledger_compact.tsv column pilot: 552 HONOURED, plus test_history_index's 3, starved by a stale index that was then regenerated and re-run HONOURED on the Mac, mac_rerun_history.tsv) and on the Mac, through worker and fix reports, mac_rerun_orch.tsv and mac_pinned2.txt. The 276 emulator modes ran on ERIS (eris_runA.out.txt and eris_runB.out.txt, 255, at scratch f0007e54, its checkout and the diff over all 73 gates in eris_runner_tree.txt; eris_guard_cancels_rest.tsv and eris_mame_parity_rest.tsv, 6), on the Mac (mac_emu_staged.txt, 11, re-run at the staged tree with that tree pinned, for gates that SKIP or go red on ERIS for lack of host inputs) and on PILOT (pilot_merged_vec3.txt, 2); the ERIS-rest and PILOT runs used clean checkouts (f0007e54, fd0bdf05) whose gate and library blobs equal the staged tree's (run_trees.txt). The plain runs of the two emulator gates that were not green on ERIS were run on the Mac: test_mame_parity PASS and audit_pool_drop PASS (ledger_compact.tsv, column eris, "(mac)"), re-run pinned at the staged tree with r6's re-runs (mac_pinned2.txt: start and end PIN lines both index tree 0a83169a, every gate blob listed). Six independent review rounds (reviews.tsv lines 1-140, fix rounds lines 141-289; rules REVIEW_rules.md): r1-r5 read 207 of the 210 gates and r6 the other three, the hand-migrated ones (review_coverage.tsv: no gate read by no round); r6, a fresh reviewer, re-judged every point the orchestrator had closed itself (all six CONFIRMED FIXED), and its BLOCK (test_tickets state-disagrees) and three piece-5 CHECKs were fixed and re-run on the Mac, pinned at the staged tree (fix_r6 rows; mac_pinned2.txt). The strict confirm tier was GREEN on bc279bb8 (tier5_tail.txt), the tree before r6's six edits. Not tested, and named in M369_scope.md:
- audit_dead_leg_linux's two modes never ran (they need podman and the maintainer's GNOME login on PILOT); their EREs are review only.
- That each mode reads UNJUDGED when its finding is absent is review for most gates, and each ERE's tightness is review, as the #369 contract states (must_fire_contract.md lines 161-163, "a per-mode ERE that still matches any failure of the check" is review); that is the contract's text and this session's limit, not a maintainer ruling.
- That each vs_ctl_caught call is handed the main check's output under its mode, and not a copy's or the in-gate section's (review rule R1), is review only: no lint, helper or run-time rule holds it (must_fire_contract.md line 161), a limit the maintainer accepted, "(a) Accept them as stated limits." (RULING.txt: "a `vs_ctl_caught` call handed the wrong file is review"); most gates were read by one review round (review_coverage.tsv), and reviews found two such defects only by reading (test_release_os_metadata, audit_guard_cancels node-shift, both fixed).
- Review r6's other eight CHECKs (reviews.tsv rows 132-139) are kept as named limits, not fixed (fix_r6.tsv: six LIMIT rows, the last covering three of the eight).
- ERIS ran at scratch f0007e54, which differs from the staged tree in three files: audit_crash_sweep_emu (re-run on the Mac, pinned at the staged tree, plain and all three modes, mac_pinned2.txt), audit_dead_leg_linux (one echo line, a gate never run here) and tools/crash_sweep.py (r6's class set).
- audit_merged_vec3's plain run was not seen green in this batch (it died on ERIS in a cross-gate race on build/merged1, a #370 finding, and fails on PILOT's stale merged1 before every changed line).
- Four plain runs were not PASS on PILOT, each named: test_history_index (the stale index, since regenerated), test_packet_check and test_emulator_staleness (host and script reasons; both PASS in the Mac tier), and test_retraction_reach, whose red predates this batch.
- No tracked row carries the class word UNJUDGED-CAUGHT yet, so the dead-leg and crash-sweep legs that would produce it run end to end only when a gate on those tables migrates (must_fire_contract.md step 7: re-measured in that batch). What did run on it: test_plants_not_applied's plants on its three migrated targets read UNJUDGED-CAUGHT through vs_ctl_class_word (mac_rerun_orch.tsv rows 12-14), and the static acceptors were probed on planted inputs at the staged tree (acceptors_probe.txt): tools/crash_sweep.py check takes a planted UNJUDGED-CAUGHT kb with 0 problems and refuses a planted UNJUDGED-BOGUS, and both helper-neutered EREs (test_crash_sweep, audit_crash_sweep_emu) match UNJUDGED-CAUGHT and not UNJUDGED or UNJUDGED-BOGUS. test_dead_leg_unjudged's acceptance (its nj-stripped WANT and the frozen-class check, test_dead_leg_unjudged.sh lines 200-225) is shown, never run on such a row.
- The staged tree 0a83169a has had no strict tier yet; the commit waits on it.
Artifacts (read every one, in full):
  - build/agent225/m369/rc/M369_scope.md
  - build/agent225/m369/rc/REVIEW_rules.md
  - build/agent225/m369/rc/RULING.txt
  - build/agent225/m369/rc/contract.diff.txt
  - build/agent225/m369/rc/debt_left_check.txt
  - build/agent225/m369/rc/debt_list.diff.txt
  - build/agent225/m369/rc/eris_guard_cancels_rest.tsv
  - build/agent225/m369/rc/eris_mame_parity_rest.tsv
  - build/agent225/m369/rc/eris_runA.out.txt
  - build/agent225/m369/rc/eris_runB.out.txt
  - build/agent225/m369/rc/eris_runner_tree.txt
  - build/agent225/m369/rc/lib_tools.diff.txt
  - build/agent225/m369/rc/mac_emu_staged.txt
  - build/agent225/m369/rc/mac_rerun_history.tsv
  - build/agent225/m369/rc/mac_rerun_orch.tsv
  - build/agent225/m369/rc/mac_pinned2.txt
  - build/agent225/m369/rc/pilot_merged_vec3.txt
  - build/agent225/m369/rc/review_coverage.tsv
  - build/agent225/m369/rc/run_trees.txt
  - build/agent225/m369/rc/tier5_tail.txt
  - build/agent225/m369/rc/reviews.tsv.lines-1-140 (lines 1-140 of build/agent225/m369/rc/reviews.tsv)
  - build/agent225/m369/rc/reviews.tsv.lines-141-289 (lines 141-289 of build/agent225/m369/rc/reviews.tsv)
  - build/agent225/m369/rc/ledger_compact.tsv.lines-1-210 (lines 1-210 of build/agent225/m369/rc/ledger_compact.tsv)
  - build/agent225/m369/rc/ledger_compact.tsv.lines-211-420 (lines 211-420 of build/agent225/m369/rc/ledger_compact.tsv)
  - build/agent225/m369/rc/ledger_compact.tsv.lines-421-630 (lines 421-630 of build/agent225/m369/rc/ledger_compact.tsv)
  - build/agent225/m369/rc/ledger_compact.tsv.lines-631-840 (lines 631-840 of build/agent225/m369/rc/ledger_compact.tsv)
  - build/agent225/m369/rc/ledger_compact.tsv.lines-841-1042 (lines 841-1042 of build/agent225/m369/rc/ledger_compact.tsv)
  - build/agent225/m369/rc/caught_sites.txt.lines-1-300 (lines 1-300 of build/agent225/m369/rc/caught_sites.txt)
  - build/agent225/m369/rc/caught_sites.txt.lines-301-600 (lines 301-600 of build/agent225/m369/rc/caught_sites.txt)
  - build/agent225/m369/rc/caught_sites.txt.lines-601-900 (lines 601-900 of build/agent225/m369/rc/caught_sites.txt)
  - build/agent225/m369/rc/caught_sites.txt.lines-901-1209 (lines 901-1209 of build/agent225/m369/rc/caught_sites.txt)
  - docs/project/must_fire_contract.md.lines-155-176 (lines 155-176 of docs/project/must_fire_contract.md)
  - tests/audit_pool_drop.sh.lines-84-110 (lines 84-110 of tests/audit_pool_drop.sh)
  - build/agent225/m369/rc/acceptors_probe.txt
  - tests/lib/crash_sweep.sh.lines-120-130 (lines 120-130 of tests/lib/crash_sweep.sh)
  - tests/test_dead_leg_unjudged.sh.lines-140-225 (lines 140-225 of tests/test_dead_leg_unjudged.sh)
  - tests/test_plants_not_applied.sh.lines-50-60 (lines 50-60 of tests/test_plants_not_applied.sh)
