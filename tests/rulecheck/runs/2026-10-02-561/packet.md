THE PACKET

Decision kind: recommendation
Subject: #188: wire route A (the static-tier carry-forward predictor) now that the strace test reads no miss
Claim (the working agent's sentence): Recommendation to the maintainer for #188: build route A's wiring — tests/run_all_static.sh re-running, after a red, only the failed gates and the gates tools/static_confirm.py marks stale since the red run's commit, carrying the rest — because the ruled condition for wiring it (DECISIONS_HISTORY.md:294-300, the predictor stays unwired until a Linux run of the tier under strace shows no gate reads a file the predictor misses) is met on the trace taken at 4e1859d9 (trace_meta.txt): 195 of 195 gates analysed, 36,722 (gate, tracked file) reads and 0 misses (capped4.tsv), the predictor's selftest and controls passing (test_static_confirm.log) and its backtest catching all three recorded reds (backtest.log). NOT TESTED: eleven gates exited non-zero under strace — seven with exit 1 and four with exit 77 (done4.tsv) — so their traced reads may fall short of a passing run's; reads are counted by path only (open, openat, execve), relative paths resolved at the repository root only, and reads of git-ignored files not counted (trace_meta.txt, analyse_mp.py's docstring); a gate added or changed after 4e1859d9 is untraced; the wiring itself is neither designed nor built, so its cost and its failure modes are unmeasured; and what share of the gates a close's fix re-runs was measured on five one-file changes only, 71 to 107 of 195 (share.txt).
Artifacts (read every one, in full):
  - build/agent188/t188/capped4.tsv
  - build/agent188/t188/done4.tsv
  - build/agent188/t188/trace_meta.txt
  - build/agent188/t188/test_static_confirm.log
  - build/agent188/t188/backtest.log
  - build/agent188/t188/share.txt
  - DECISIONS_HISTORY.md.lines-294-300 (lines 294-300 of DECISIONS_HISTORY.md)
