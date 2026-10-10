THE PACKET

Decision kind: recommendation
Subject: #228 step 4: recommend running the alignment check ONCE (at the conversion) with a frozen game-clock tripwire, rather than recurring reference legs
Claim (the working agent's sentence): Recommendation A for #228 step 4 (build/agent197/t228/assessment.md): convert walker_sp, obj_record_bank_trace, trace_writes and replay_guard to the emulated clock, run the at-risk gates once with #213's reference legs and re-freeze what moves, then compare each breakpoint leg's RAM:$FF8080 with a frozen per-replay value instead of re-running reference legs; it rests on the maintainer's stated clock-time concern (DECISIONS_HISTORY.md lines 509-515), on the at-risk gates' registry scopes (18 release, 3 out, 3 ondemand, cadence romset; tests/ci_emulator.tsv header: romset runs at every freeze and release), and on the one measured reference-leg price, audit_marionette_cost on this Mac at JOBS 4, 227 s before #228 step 1 and 339 s after (x1.49, an upper bound since that commit also added the witness's live replay.lua run), with the at-risk gates at 3547 s of the M23 freeze run's 35236 s; NOT TESTED: the reference-leg price on the four other instruments (the ~1,750 s figure is an extrapolation), whether the converted instruments keep their breakpoint legs' game clock equal to the reference legs', how often a freeze would move a frozen $FF8080 value, which of the 24 gates' builds a freeze moves, a breakpoint stop that changes state without moving $FF8080 (a gap shared by the recurring options, tests/audit_marionette_cost.sh lines 25-34), and the conversion's own session cost.
Artifacts (read every one, in full):
  - build/agent197/t228/assessment.md
  - build/agent197/t228/measurer_costs_return.txt
  - build/agent197/t228/marionette_pre.log
  - build/agent197/t228/marionette_post.log
  - tests/audit_marionette_cost.sh.lines-20-50 (lines 20-50 of tests/audit_marionette_cost.sh)
  - tests/audit_marionette_cost.sh.lines-95-130 (lines 95-130 of tests/audit_marionette_cost.sh)
  - tests/ci_emulator.tsv.lines-14-60 (lines 14-60 of tests/ci_emulator.tsv)
  - DECISIONS_HISTORY.md.lines-509-515 (lines 509-515 of DECISIONS_HISTORY.md)
  - build/agent196/t228/step3/SUMMARY.txt
