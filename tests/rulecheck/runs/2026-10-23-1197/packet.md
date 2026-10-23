THE PACKET

Decision kind: recommendation
Subject: #313 closed done: the confirm planner's build/sheets stall fixed (lane F, 14z-207)
Claim (the working agent's sentence): #313 can close done when this session's commit lands (closing_comment.md): its three to-dos (issue313.md) are met by lane F's fix, whose code in the main tree equals the fork's tip 949a8feb (f207_313_code.patch; 949a8feb differs from the traced and tiered 1a2210f6 by a header comment, REPORT.md). build/sheets/ joined N-D scratch on a PILOT trace of 229 of 229 gates at 1a2210f6 with the sheet replica present (F/pilot/trace_setup.log: 23,552 replica files, 20,271 untracked under build/sheets), 88,235 read pairs, MISSES 0, the over-narrowed control firing with 102 misses (F/pilot/trace_all.log); the bounding keeps verdicts: the gate run here on the main tree PASSes with its controls firing (gate_main.log), and the committed and bounded planners' outputs are byte-identical on two Mac change sets of 3 and 188 paths (mac_equiv_cmp.txt) and IDENTICAL on three PILOT chunks (F/pilot/equiv2/diff_0.log, diff_1.log, diff_2.log); with the replica present the committed planner hit its 1,800 s timeout and the fixed one judged 20,297 changed paths in 22.1 s (F/pilot/tier.log, F/pilot/confirm_tier.log). Not tested: the full 23,552-path old-against-new equivalence (stopped; samples only); a tier through run_on_snapshot.sh (PILOT's tiers ran in its clone for lack of disk); a whole-tier run of this session's tree, which happens before the commit and is not in this packet; the trace counted file opens only, not reads through git; four gates exited non-zero under the trace and in PILOT's tiers (test_applier_page, test_applier_page_browser, test_release_roundtrip, test_emulator_staleness), attributed in REPORT.md to open tickets #279, #280, #281 and PILOT's stale emulator records, so their traced reads may be short of a passing run's.
Artifacts (read every one, in full):
  - build/agent207/t313/closing_comment.md
  - build/agent207/t313/issue313.md
  - build/agent207/t313/REPORT.md
  - build/agent207/t313/f207_313_code.patch
  - build/agent207/t313/gate_main.log
  - build/agent207/t313/mac_equiv_cmp.txt
  - build/agent207/t313/F/pilot/trace_setup.log
  - build/agent207/t313/F/pilot/trace_all.log
  - build/agent207/t313/F/pilot/tier.log
  - build/agent207/t313/F/pilot/confirm_tier.log
  - build/agent207/t313/F/pilot/equiv2/diff_0.log
  - build/agent207/t313/F/pilot/equiv2/diff_1.log
  - build/agent207/t313/F/pilot/equiv2/diff_2.log
