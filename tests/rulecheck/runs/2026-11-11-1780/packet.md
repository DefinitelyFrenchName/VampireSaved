THE PACKET

Decision kind: recommendation
Subject: #364/#371: recommend design R (the emulator runner reaps each gate's session and removes its TMPDIR) without the lint, over the 276-file trap patch (after runs 2026-11-11-1778 and -1779)
Claim (the working agent's sentence): Recommend design R for #364 and #371 (the emulator runner starts each gate in a session of its own with a TMPDIR of its own, and after the gate returns TERMs what is left in that session, waits up to 10 s, KILLs the rest and removes the TMPDIR), without the lint for new files, over G (the split trap form in 276 files), as the design to BUILD, its behaviour then measured before its commit: the choice rests on PILOT's runner runs where the split form still left a recreated work directory and the runner's temp directory (build/agent225/t364/pilot_t364b.out) and where three TERM-catching cps2 processes outlived their gates (build/agent225/t364/design.md fact 4), which a gate-side trap cannot reach, on the static runner having no timeout wrapper (tests/run_all_static.sh line 503), and on the maintainer's words on #310 "greenfield a solution instead of piling on patches" (DECISIONS_HISTORY.md, 14z-223). WHAT WAS MEASURED UNDER R IS EXACTLY THESE ROWS AND NOTHING ELSE: on PILOT through the real runner (build/agent225/t364/pilot_t371.out), the planted gate (0 survivors, KILL needed for 4 sleep-plant processes), audit_command_throws timed out twice (TERM ended 2 cps2 each time, KILL needed for 0, 0 survivors, its TMPDIR removed) and the passing gates audit_df_gold and audit_air_gc_legacy (PASS), each a plain run; on the Mac, session_run.py called directly on the plant, outside the runner (build/agent226/t364/mac_t371.out: KILL needed for 4, 0 left). NOT TESTED is everything else about R, among it: the verdicts of the other registered emulator gates, any CONTROL= run (the runner's line 681), any real gate through R on the Mac or through the Mac's runner, R's KILL step against a cps2 that survives TERM, ERIS, the pooled lanes at --jobs N, the two Linux desktop gates and the Verilator lane. Known limits: on the Mac the TMPDIR removal misses a gate's bare mktemp -d directory (docs/platform/gotchas.md), and a manual kill under dash still leaves an EXIT-only gate's directory.
Artifacts (read every one, in full):
  - build/agent226/t364/recommendation.md
  - build/agent225/t364/design.md
  - build/agent225/t364/pilot_t364.out
  - build/agent225/t364/pilot_t364b.out
  - build/agent225/t364/pilot_t371.out
  - build/agent225/t364/session_run.py
  - build/agent225/t364/census364.txt
  - build/agent226/t364/mac_t371.sh
  - build/agent226/t364/mac_t371.out
  - build/agent226/t364/issue_364.md
  - build/agent226/t364/issue_364_comments.txt
  - build/agent226/t364/issue_371.md
  - DECISIONS_HISTORY.md.lines-9883-9900 (lines 9883-9900 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-08 (14z-223) — #310: a post-mortem and a greenfield proposal before any batch 6")
  - docs/platform/gotchas.md.lines-3420-3432 (lines 3420-3432 of docs/platform/gotchas.md)
  - tests/run_all_emulator.sh.lines-620-685 (lines 620-685 of tests/run_all_emulator.sh)
  - tests/run_all_static.sh.lines-498-506 (lines 498-506 of tests/run_all_static.sh)
