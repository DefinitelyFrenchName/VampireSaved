THE PACKET

Decision kind: recommendation
Subject: #269: land the turned-around static tier (the confirm run as the session close, the three-gate core) on #274
Claim (the working agent's sentence): Recommendation: land #269 as one commit on the #274 commit a4c246f7 (HEAD) — tools/static_confirm.py dc4eea12 (plan re-runs a `# CONFIRM: always` core and any gate whose base row has fewer controls honoured than declared), tests/run_all_static.sh e75fd0b8 (--confirm refused at any cadence but session), tests/test_static_runner.sh a4078945 (sections 20-21, three controls), the core line in test_commit_subject 12834c0c, test_close_tools 25ac4357 and test_rule_checker f166540d, the regenerated docs/project/gate_coverage.md, and HANDOFF, must_fire_contract WHEN, STATE's header and standing ruling and the three superseded rulings marked in place in DECISIONS_HISTORY.md — and leave #269 open until this sitting's close has run that tier, since its done-when names a session close. On the 14z-199 close's results (204 rows, none with fewer controls honoured than declared) the plan re-runs 165 of 222 gates (67 R5, 43 R3, 33 R2, 18 absent — exactly the 18 gates tests/ci_cadence.tsv lists — 3 the core, 1 SKIP, test_release_launcher_bat) and carries 57, in 211 s; test_static_runner passes with section 20's three properties and ten controls fired, and the three new ones each exit 1 as a mode. Every figure is a FIG line of build/agent200/t269/measure_return.txt, measure_return2.txt or measure_return3.txt (222: the plan's 222 lines, one per gate, and the registries' 130 portable + 92 static, measure_return3.txt C2-C3); the files the plan ran with are those whose sha1s measure_return2.txt C2 gives, last written before the plan finished (C1), and tools/battery_reach.py, last written 2026-10-02 and equal to HEAD's (measure_return3.txt C1), and the plan prints no predictor identity. NOT TESTED: the confirm tier itself on real data (tests/run_all_static.sh --strict --confirm), which this sitting's close runs first, and no static tier has run on the #269 commit, which does not exist yet; the refusal at --cadence release and ondemand (the same line as freeze, which section 20 exercises); whether the three core gates are the only ones whose inputs a path change cannot show — the rest of the 114 off-tree readers of the 14z-199 search (a sweep, not a trace) are carried when no followed path changed, until a freeze or release; how long a verdict may ride a chain of confirm runs (unbounded between freezes); a quieter sitting's plan (this one edits the predictor and its gates); the plan ran with this sitting's #274 and #269 changes uncommitted in the tree, and test_static_runner.sh was edited (11:00:56) while it ran — the plan re-ran it either way (STALE by R5, measure_return2.txt C3).
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
  - build/agent199/t269/report.md
