THE PACKET

Decision kind: recommendation
Subject: #269: close done on its done-when, the last clause measured as the miss rate of the 14z-200 close tiers' carried selections
Claim (the working agent's sentence): #269's done-when is met and #269 can be put to the maintainer for closing `done`: the 14z-200 close ran the predicted set and the three-gate core, named every gate it carried, and left freeze/release runs unchanged (STATE 14z-200 row (6)); and the last clause, the predictor's miss rate on the new selection, is measured as 0 misses among the 56 gates carried at 5648e530 and 0 among the 80 carried at 344ebc5e — each carried gate's normal run traced under strace on PILOT at its tier's head and its reads intersected with that tier's tracked change set by four readers, each added after a rule-checker run found a form the previous one dropped: the trace tool's own reader; a reader keeping strace's split open lines and failed opens (after run 2026-10-14-1073); a census of every relative path the repo root does not hold (after 1075: 37 and 53 distinct, none matching a changed path, none `../`); and a census of openat calls relative to a directory fd (resolved through the same process's fds, or matched by name when the fd was inherited) and of directory listings where a path was added, deleted or renamed (after 1077: no hit and no name match on the carried gates); and, after 1079, every git command the carried gates ran listed from their argv: three gates, each reading commit-pinned content, the unmoved `emu/jtcores` submodule, or HEAD's sha — with controls: a planted read that fired on both tiers; synthetic traces for a split line, cwd-relative reads (one `../`), a dirfd read and a changed listing, each found, and an unchanged pair not; and the gates each tier re-ran under rule R2, where the readers find changed-file reads (15 of 33, 11 of 36) and the census finds hits and name matches; every carried gate exited 0 and printed a verdict line. NOT TESTED: the traces ran on PILOT (Linux) while the tiers ran on the Mac; only each carried gate's normal run was traced, not its control modes, whose verdicts the confirm tier also carries; a process strace did not follow is unseen; a relative path the repo root holds is taken as opened from the root, and an inherited-fd dirfd open is placed only by name; reads through git are judged from the git commands' argv (cut at 32 characters), not from what git read, and test_close_checks' dependence on HEAD's sha is not tested; reads outside the repo, stat-only checks and the environment are not scored; untracked changes are not in the change set (the tiers ran on snapshots); two selections from one sitting are not a rate over many closes.
Artifacts (read every one, in full):
  - build/agent201/t269/report.md
  - build/agent201/t269/claim.txt
  - build/agent201/t269/check_git_calls.txt
  - tools/close_checks.py
  - build/agent201/t269/spec_measure4.md
  - build/agent201/t269/measure_return4.txt
  - build/agent201/t269/dir_census.py
  - build/agent201/t269/pilot_dir.sh
  - build/agent201/t269/dir_census.log
  - build/agent201/t269/synth_dir.sh
  - build/agent201/t269/check_synth_dir.txt
  - build/agent201/t269/spec_measure3.md
  - build/agent201/t269/measure_return3.txt
  - build/agent201/t269/rel_census.py
  - build/agent201/t269/pilot_rel.sh
  - build/agent201/t269/rel_census.log
  - build/agent201/t269/check_dotdot.txt
  - build/agent201/t269/check_synth_rel.txt
  - build/agent201/t269/spec_measure2.md
  - build/agent201/t269/measure_return2.txt
  - build/agent201/t269/carried_hits2.py
  - build/agent201/t269/pilot_trace2.sh
  - build/agent201/t269/pilot_trace2.log
  - build/agent201/t269/check_unfinished.txt
  - build/agent201/t269/check_synth_split.txt
  - build/agent201/t269/check_five_rows.txt
  - build/agent201/t269/verdict_tails.txt
  - build/agent201/t269/rerunR2_5648e530.txt
  - build/agent201/t269/rerunR2_344ebc5e.txt
  - tests/rulecheck/ledger.tsv
  - build/agent201/t269/issue269.md
  - build/agent201/t269/spec_measure.md
  - build/agent201/t269/measure_return.txt
  - build/agent201/t269/check_miss_rows.txt
  - build/agent201/t269/carried_hits.py
  - build/agent201/t269/pilot_trace.sh
  - build/agent201/t269/pilot_trace.log
  - build/agent201/t269/carried_5648e530.txt
  - build/agent201/t269/carried_344ebc5e.txt
  - build/agent201/t269/pilot/tr_5648e530/done.tsv
  - build/agent201/t269/pilot/tr_344ebc5e/done.tsv
  - build/snapshot_runs/20261014T180024-5648e5305ca3/runner.log
  - build/snapshot_runs/20261014T191725-344ebc5e39d7/runner.log
  - STATE.md
  - tools/trace_static_reads.py
