THE PACKET

Decision kind: expectation
Subject: #369 pieces 1-3: the positive-evidence classifier rule, the vs_ctl_caught helper, the lint and the shrink-only debt list
Claim (the working agent's sentence): #369 pieces 1-3, as ruled ("A1, B1, c1", RULING.txt, on design.md), can land on main: (1) tests/lib/classify.sh reads a control mode HONOURED only on a `CONTROL CAUGHT: <mode> — ` line in the mode's log and UNJUDGED otherwise, unless the gate's basename is on tests/expected/ctl_caught_debt.tsv, which keeps the pre-#369 fall-through (lib.diff.txt); (2) tests/lib/controls.sh's vs_ctl_caught prints that line only when the given ERE matches the check's own output and refuses a catch-all ERE, vs_ctl_fired under a mode off the list prints NOT JUDGED instead of a firing line, and vs_ctl_read reads RED a CAUGHT line in a plain run (lib.diff.txt); (3) tools/ctl_caught_lint.py and tests/test_ctl_caught_lint.sh hold the literal to the helper, refuse catch-all EREs and the mode variable as a firing name, require every mode-declaring gate to call the helper or be listed, require a `$` in a multi-mode gate's ERE, and keep the list shrink-only against 8464fa3f (ctl_caught_lint.py.txt, test_ctl_caught_lint.sh.txt; 7 planted shapes named and a near miss passing, test_ctl_caught_lint_plain.log, which reports 517 gates, 313 declaring modes, 3 migrated, 310 listed). The classifier carries a control for the new rule (test_control_classifier's fallthrough-honoured mode, rule_tests.diff.txt). Shown working: on PILOT at scratch 17f4f67f the 3 migrated gates' 16 modes read HONOURED on their own CAUGHT line and the 5 listed consumer gates' 61 modes HONOURED by the listed fall-through, all 8 SAFE (pilot_17f4f67f_*); the discovery tier at scratch fe484dd2 read PASS 160 FAIL 6 with 575 executed controls HONOURED (discovery_*), and the six reds are fixed as bookkeeping.txt says, one of them (test_release_reuse) the new rule reading an unlisted stub's mode UNJUDGED (discovery_red_test_release_reuse.log); the two listed gates whose scripts then changed re-traced SAFE with every mode HONOURED (pilot_4aac3c9a_*, pilot_9ad0f0ff_*) and re-pinned (concurrent_list.diff.txt). The commit waits for a strict GREEN static tier of the staged tree, which `tools/git-hooks/green_guard.py` (the pre-commit hook) requires. NOT TESTED: the 310 listed gates are still honoured without positive evidence — that is the debt the ruling accepts, and their migration (and piece 5, the crash_sweep and dead-leg classes) is not designed or done; the emulator tier was not run, so no emulator gate's mode ran under the new classifier (all its mode-declaring gates are listed, per the lint, so they take the old path); no emulator --controls run and no release run; the lint reads gates by pattern and a call it cannot parse is not checked; whether a migrated gate's ERE matches only its perturbation's finding rests on the gate author, with rule [e] checking only the `$` anchor; the final tier on the staged tree has not run yet.
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
  - build/agent224/t369/rc/registry_docs.diff.txt
  - build/agent224/t369/rc/rule_tests.diff.txt
  - build/agent224/t369/rc/test_control_classifier_plain.log
  - build/agent224/t369/rc/test_ctl_caught_lint.sh.txt
  - build/agent224/t369/rc/test_ctl_caught_lint_plain.log
  - build/agent224/t369/rc/test_release_reuse_after_fix.log
