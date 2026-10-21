THE PACKET

Decision kind: recommendation
Subject: #292 closed declined: the self-test narrowing (N-K + planner self-exclusion) saves no gate on a STATE.md-only change, so the code stays out (14z-205c)
Claim (the working agent's sentence): #292 can close declined at the maintainer's word ('Close #292, keep code out'): measured on the PILOT trace at 779bc589, a STATE.md-only change marks 38 gates STALE (30 by R2 'names STATE.md', 11 of them opening STATE.md); the ruled narrowing was built in a scratch worktree, its gate passes with its two controls failing it as modes, and it leaves the STALE set at 38 because the same gates are STALE by R5 and R4 as well (all_rules_compact.txt); the remaining cost is 209 s of gate time and 5 control rows per close tier (14z-205b close). Not tested: R4 and R5 narrowing for these gates; the trace is at 779bc589, not at b91532d8; the trace sees opens by path only, so a gate reading STATE.md through git would be counted as not opening it.
Artifacts (read every one, in full):
  - build/agent205c/t292/closing_comment.md
  - build/agent205c/t292/predict_state_wt.txt
  - build/agent205c/t292/predict_state_nk2.txt
  - build/agent205c/t292/predict_state_nk3.txt
  - build/agent205c/t292/opens_state.txt
  - build/agent205c/t292/all_namers.txt
  - build/agent205c/t292/all_rules_compact.txt
  - build/agent205c/t292/gate_nk2.log
  - build/agent205c/t292/gate_mode_planner-self-off.log
  - build/agent205c/t292/gate_mode_selftest-scope-off.log
  - build/agent205b/close/tier_results.tsv
  - build/agent205b/close/tier_results.controls.tsv
  - DECISIONS_HISTORY.md.lines-7414-7443 (lines 7414-7443 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-20 (14z-205c) — #299's shared jtsim scratch collision: a lock in mister_mra.sh; #29", and the entries after it up to line 7443)
  - docs/project/gotchas.md.lines-7337-7347 (lines 7337-7347 of docs/project/gotchas.md)
  - docs/project/tickets.tsv.lines-20-73 (lines 20-73 of docs/project/tickets.tsv)
  - docs/project/tickets.tsv.lines-83-83 (lines 83-83 of docs/project/tickets.tsv)
  - STATE.md.lines-100-122 (lines 100-122 of STATE.md)
