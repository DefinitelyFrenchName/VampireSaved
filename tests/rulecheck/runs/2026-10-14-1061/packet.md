THE PACKET

Decision kind: recommendation
Subject: #269: land the turned-around static tier on #274, with the three-gate core the maintainer ruled (C first)
Claim (the working agent's sentence): Recommendation: land #269 as one commit on HEAD cd94791f (which carries #274) — tools/static_confirm.py (plan re-runs a `# CONFIRM: always` core and any gate whose base row has fewer controls honoured than declared), tests/run_all_static.sh e75fd0b8 (--confirm refused at any cadence but session), tests/test_static_runner.sh a4078945 (sections 20-21, three controls), the core line in test_commit_subject 12834c0c, test_close_tools 25ac4357 and test_rule_checker f166540d, the regenerated docs/project/gate_coverage.md, HANDOFF, must_fire_contract WHEN, STATE's header and standing ruling, the superseded rulings marked in place and the 2026-10-14 ruling entered in DECISIONS_HISTORY.md — the core being the three gates the maintainer ruled with *"C first"* ("Hold #269 until PILOT is re-traced with the missing tools; then land with A"), the re-trace done (build/agent200/t274/report.md section 6) — and leave #269 open until this sitting's close has run that tier, since its done-when (issue269.md line 14) reads "A session close runs the predicted set and the core, its readout names every gate it did not run and why, and a freeze/release run is unchanged; the predictor's miss rate is measured on the new selection." Against this sitting's strict run of 8e1e4bbc (204 rows, none with fewer controls honoured than declared) the plan re-runs the gates and carries the rest as measure_return5.txt C2 gives, 3 of the re-runs as the core; the five gates #269 touches pass and its three controls each exit 1 as a mode (C3-C4), and the eight gates that read the documents it edits (test_superseded_pins, test_state_open_lists, test_rulings_verbatim, test_checkdocs, test_docshape, test_tickets, test_must_fire_census, test_gate_coverage_current) pass on the same tree (measure_return6.txt). Every figure is a FIG line of build/agent200/t269/measure_return.txt through measure_return6.txt or core_cost_return.txt. NOT TESTED: the full static tier on the #269 commit (thirteen gates are run on the tree here, not the 222), and the confirm tier as a session close on real data — both run first at this sitting's close; the refusal at --cadence release and ondemand (the same line as freeze, which section 20 exercises); whether the three core gates are the only ones whose inputs a path change cannot show — the re-trace left four gates not clean on PILOT (test_applier_page section 3b, test_applier_page_browser's control run, test_release_roundtrip, test_emulator_staleness), whose reads may be short of a passing run's — and every trace that scored the predictor ran on PILOT (Linux) while a session close carries gates on this Mac, so no test shows a Linux run's reads stand for a Mac run's (build/agent200/t274/report.md section 5); how long a verdict may ride a chain of confirm runs (unbounded between freezes); a quieter sitting's plan; the figures above are measure_return5.txt's, re-run on static_confirm.py as it lands (its sha1 in C1), after a docstring edit moved it from the d4ba7b9c measure_return4.txt ran.
Artifacts (read every one, in full):
  - build/agent200/t269/report.md
  - build/agent200/t269/measure_return.txt
  - build/agent200/t269/spec_measure.md
  - build/agent200/t269/diff_static_confirm_vs_274.txt
  - build/agent200/t269/diff_run_all_static.txt
  - build/agent200/t269/diff_test_static_runner.txt
  - build/agent200/t269/diff_core_gates.txt
  - build/agent200/t269/diff_docs.txt
  - build/agent200/t269/plan_real.tsv
  - build/agent200/t269/plan_real.time
  - build/agent200/t269/measure_return2.txt
  - build/agent200/t269/spec_measure2.md
  - build/agent200/t269/measure_return3.txt
  - build/agent200/t269/spec_measure3.md
  - build/agent200/t269/issue269.md
  - build/agent200/t269/measure_return4.txt
  - build/agent200/t269/spec_measure4.md
  - build/agent200/t269/measure_return5.txt
  - build/agent200/t269/spec_measure5.md
  - build/agent200/t269/measure_return6.txt
  - build/agent200/t269/spec_measure6.md
  - build/agent200/t269/core_cost_return.txt
  - build/agent200/t269/core_cost.py
  - build/agent200/t274/report.md
  - build/agent199/t269/report.md
