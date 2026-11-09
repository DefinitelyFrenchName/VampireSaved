THE PACKET

Decision kind: expectation
Subject: #369 pieces 1-3: the positive-evidence classifier rule, the vs_ctl_caught helper, the lint and the shrink-only debt list
Claim (the working agent's sentence): #369 pieces 1-3, as ruled ("A1, B1, c1", RULING.txt, on design.md), can land on main, now with rule-checker run 2026-11-09-1743's two findings closed in code (rc1743_verdict_a.txt): (1) tests/lib/classify.sh reads a control mode HONOURED only on a `CONTROL CAUGHT: <mode> — ` line in the mode's log and UNJUDGED otherwise, unless the gate's basename is on tests/expected/ctl_caught_debt.tsv, which keeps the pre-#369 fall-through (lib.diff.txt); (2) tests/lib/controls.sh's vs_ctl_caught prints that line only when the given ERE matches the check's own output and refuses a catch-all ERE, vs_ctl_fired under a mode off the list prints NOT JUDGED instead of a firing line, and vs_ctl_read reads RED a CAUGHT line in a plain run (lib.diff.txt); (3) tools/ctl_caught_lint.py and tests/test_ctl_caught_lint.sh: rule [a] lets only the helper, the classifier and the lint carry the literal, and lets the six ground-truth gates (GROUND_TRUTH, ctl_caught_lint.py.txt) carry it only outside an unquoted, unredirected echo/printf that starts a printed line with it (control truth-echo, on a copy of test_control_classifier.sh); [b] refuses catch-all EREs, [c] the mode variable as a firing name, [d] a mode-declaring gate that neither calls the helper nor is listed, [e] a multi-mode gate's ERE without a `$`; [debt] refuses a row that is migrated, gone, declares no mode, did not exist at 8464fa3f, or is not on the list's first version (blob 9cf7c951, ORIGIN_BLOB in test_ctl_caught_lint.sh.txt, the same bytes as ctl_caught_debt.tsv) and on every committed version since (controls debt-unmigrated, debt-mode-gained, debt-returned, the last on a scratch two-commit history). test_ctl_caught_lint_plain.log: 11 planted shapes named, a near miss passing, 517 gates, 313 declaring modes, 3 migrated, 310 listed, 0 committed list versions yet; test_ctl_caught_lint_modes.txt: all 11 modes HONOURED on their own CAUGHT line. The classifier carries a control for the new rule (test_control_classifier's fallthrough-honoured mode, rule_tests.diff.txt). Shown working: on PILOT at scratch 17f4f67f the 3 migrated gates' 16 modes (the lint gate's then 7 among them) read HONOURED on their own CAUGHT line and the 5 listed consumer gates' 61 modes HONOURED by the listed fall-through, all 8 SAFE (pilot_17f4f67f_*); the lint gate's 11 modes again at scratch ed4a6d36, SAFE (pilot_ed4a6d36_*); the discovery tier at scratch fe484dd2 read PASS 160 FAIL 6 with 575 executed controls HONOURED (discovery_*), and the six reds are fixed as bookkeeping.txt says, one of them (test_release_reuse) the new rule reading an unlisted stub's mode UNJUDGED (discovery_red_test_release_reuse.log); the listed gates whose scripts then changed re-traced SAFE with every mode HONOURED (pilot_4aac3c9a_*, pilot_9ad0f0ff_*, pilot_ed4a6d36_*) and re-pinned (concurrent_list.diff.txt). The commit waits for a strict GREEN static tier of the staged tree, which `tools/git-hooks/green_guard.py` (the pre-commit hook) requires. NOT TESTED: the 310 listed gates are still honoured without positive evidence — that is the debt the ruling accepts, and their migration (and piece 5, the crash_sweep and dead-leg classes) is not designed or done; the emulator tier was not run, so no emulator gate's mode ran under the new classifier (all its mode-declaring gates are listed, per the lint, so they take the old path); no emulator --controls run and no release run; the lint reads gates by pattern, so a call it cannot parse is not checked, and an indirect print of the literal in a ground-truth gate (built in a variable or a function) passes rule [a] (named as review-only in registry_docs.diff.txt); the history half of [debt] has run only on the scratch history, since the list has no committed version yet, and a clone without the file's history checks the first version alone; whether a migrated gate's ERE matches only its perturbation's finding rests on the gate author, with rule [e] checking only the `$` anchor; the final tier on the staged tree has not run yet.
Artifacts (read every one, in full):
  - build/agent224/t369/rc/RULING.txt
  - build/agent224/t369/rc/bookkeeping.txt
  - build/agent224/t369/rc/concurrent_list.diff.txt
  - build/agent224/t369/rc/consumers.diff.txt
  - build/agent224/t369/rc/ctl_caught_debt.tsv
  - build/agent224/t369/rc/ctl_caught_lint.py.txt
  - build/agent224/t369/rc/design.md
  - build/agent224/t369/rc/discovery_red_test_release_reuse.log
  - build/agent224/t369/rc/discovery_results.controls.tsv
  - build/agent224/t369/rc/discovery_tier_results.tsv
  - build/agent224/t369/rc/discovery_tier_summary.txt
  - build/agent224/t369/rc/lib.diff.txt
  - build/agent224/t369/rc/pilot_17f4f67f_classes.tsv
  - build/agent224/t369/rc/pilot_17f4f67f_prep.txt
  - build/agent224/t369/rc/pilot_17f4f67f_score.txt
  - build/agent224/t369/rc/pilot_4aac3c9a_classes.tsv
  - build/agent224/t369/rc/pilot_4aac3c9a_prep.txt
  - build/agent224/t369/rc/pilot_4aac3c9a_score.txt
  - build/agent224/t369/rc/pilot_9ad0f0ff_classes.tsv
  - build/agent224/t369/rc/pilot_9ad0f0ff_prep.txt
  - build/agent224/t369/rc/pilot_9ad0f0ff_score.txt
  - build/agent224/t369/rc/pilot_ed4a6d36_classes.tsv
  - build/agent224/t369/rc/pilot_ed4a6d36_prep.txt
  - build/agent224/t369/rc/pilot_ed4a6d36_score.txt
  - build/agent224/t369/rc/rc1743_verdict_a.txt
  - build/agent224/t369/rc/registry_docs.diff.txt
  - build/agent224/t369/rc/rule_tests.diff.txt
  - build/agent224/t369/rc/test_control_classifier_plain.log
  - build/agent224/t369/rc/test_ctl_caught_lint.sh.txt
  - build/agent224/t369/rc/test_ctl_caught_lint_modes.txt
  - build/agent224/t369/rc/test_ctl_caught_lint_plain.log
  - build/agent224/t369/rc/test_release_reuse_after_fix.log
