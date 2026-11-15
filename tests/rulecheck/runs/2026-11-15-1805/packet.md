THE PACKET

Decision kind: recommendation
Subject: #348: close done — section 5 of the release gate and release/ in five FOLLOWS lines
Claim (the working agent's sentence): Close #348 `done`. Its proposal (build/agent229/close/issue348_body.md): a section in tests/test_release_roundtrip.sh requiring every release/<name>/<platform>/ manifest, apply_release.py and patch to equal the fresh package, with a must-fire control (a tracked copy from another build must FAIL), and release/ added to the Linux gates' FOLLOWS. The maintainer ruled the scope this sitting (DECISIONS_HISTORY.md "Ruled 2026-11-15 (14z-229)"): "Ticket scope only (Recommended)" (release/ declared by hand; REF_RE not taught the stem), "Legacy form, gate stays listed (Recommended)" (the new mode judged like the gate's other ten, the gate kept on tests/expected/ctl_caught_debt.tsv), "Cap at 4 active hours (Recommended)". Built (build/agent229/close/staged_change.diff): section 5 compares each of fbneo, mame, mister's manifest.json, apply_release.py and patches/ with section 1's fresh package (missing, extra and differing files each a FAIL; README.md and apply_release.html not compared, being generated per platform); control other-build-release checks the newest release/merged-mN below <name> and must fail; release/ appended to the FOLLOWS lines of audit_release_linux_desktop, audit_release_linux_cleanhost, audit_dead_leg_linux, test_readme_recording, test_release_binaries; declared() in tools/gate_follows.py now accepts the release/ prefix, without which test_gate_follows FAILed "a frozen declaring gate LOST its declaration" for those five (bk/before_declared_fix_test_gate_follows.log). Evidence: g348/plain.log on the Mac reads "ok: release/merged-m26: manifest.json, apply_release.py and 20 patches equal the fresh package on fbneo, mame and mister", "CONTROL FIRED: other-build-release — release/merged-m25 fails it: 27 file(s) differ or are missing" and "PASS: release package", rc=0; g348/mode.log (CONTROL=other-build-release) has no "FAIL:" line before section 5, 27 "FAIL:" lines naming release/merged-m25 (the manifest and 8 patches on each of three platforms, the 14z-228 estimate's measured 8 of 20), and ends "FAIL: release package", rc=1. On a clean checkout of the staged code (commit-tree 51bd1a64), bk2_*.log and bk3_*.log: test_gate_follows, test_must_fire_census, test_gate_descriptions, test_gate_coverage_current, test_gate_index_current, test_annotations_current, test_ctl_caught_lint, test_emulator_staleness, test_static_confirm, test_lane_carry, test_plants_not_applied all PASS. The closing comment is build/agent229/close/c348.md; the ticket row is set to done. NOT TESTED: the five emulator gates were not run (only their header line changed); section 5 ran on the Mac only, not on PILOT or ERIS; the mode carries no CONTROL CAUGHT line (the gate stays on the debt list, as ruled); no same-program different-set control this time; the tickets, state and live-budget gates and the whole strict tier run on the final staged tree only after this check (the green guard before the commit); the gate runs at release cadence, so a session tier defers it.
Artifacts (read every one, in full):
  - build/agent229/close/c348.md
  - build/agent229/close/issue348_body.md
  - build/agent229/close/staged_change.diff
  - build/agent229/g348/plain.log
  - build/agent229/g348/mode.log
  - build/agent229/bk/before_declared_fix_test_gate_follows.log
  - build/agent229/bk/bk2_test_gate_follows.log
  - build/agent229/bk/bk2_test_must_fire_census.log
  - build/agent229/bk/bk2_test_ctl_caught_lint.log
  - build/agent229/bk/bk2_test_emulator_staleness.log
  - build/agent229/bk/bk2_test_gate_descriptions.log
  - build/agent229/bk/bk2_test_gate_coverage_current.log
  - build/agent229/bk/bk2_test_gate_index_current.log
  - build/agent229/bk/bk2_test_annotations_current.log
  - build/agent229/bk/bk2_test_static_confirm.log
  - build/agent229/bk/bk3_test_lane_carry.log
  - build/agent229/bk/bk3_test_plants_not_applied.log
  - DECISIONS_HISTORY.md.lines-10274-10290 (lines 10274-10290 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-15 (14z-229) — #348 taken up in the ticket's scope, the new control in the legacy f")
