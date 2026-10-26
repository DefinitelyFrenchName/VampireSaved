THE PACKET

Decision kind: expectation
Subject: #302: re-freeze tests/expected/marionette_cost.tsv with the eight 118_* replays in its legs (65 legs, was 57), and close #302 done
Claim (the working agent's sentence): CLAIM: tests/audit_marionette_cost.sh takes as legs every replay with a vanilla basis log plus 128_shadow_vs_legacy_vsavj (its legs line: 57 in minus.log, 65 in full.log), commit 7c757b12 (14z-198) added the eight 118_* basis logs (commit_7c757b12.txt), and on fresh PILOT clones of 2aacebe8 the gate FAILs with all 65 legs and PASSes with those eight logs removed (57 legs) (build/agent209/t302/pilot/full.log, minus.log, minus_basis_logs.txt), so the red is those eight legs and the expectation, not the port; re-frozen with FREEZE=1 on the 65-leg clone and verified by a plain run PASS with its three controls FIRED (freeze.log, verify.log), the candidate's data rows equal the raw freeze's and differ from the frozen file on 12 of its 26 HIT rows only, each replay count +8, every max unchanged (rowdiff.txt); it replaces tests/expected/marionette_cost.tsv, its header line 2 naming this run, and the gate's usage comment gives 65 legs (usage_comment.diff, comment lines only, the verify run on the unedited script). NOT TESTED: the Mac or ERIS (PILOT only); FBNeo; whether the eight replays exercise the Marionette path the gate prices (they enter as legacy legs like the rest); the next basis log added turns the gate red the same way (a re-freeze per corpus change, as here).
Artifacts (read every one, in full):
  - tests/audit_marionette_cost.sh
  - build/agent209/t302/usage_comment.diff
  - tests/expected/marionette_cost.tsv
  - build/agent209/t302/marionette_cost.tsv.candidate
  - build/agent209/t302/rowdiff.txt
  - build/agent209/t302/pilot/full.log
  - build/agent209/t302/pilot/minus.log
  - build/agent209/t302/pilot/minus_basis_logs.txt
  - build/agent209/t302/pilot/freeze.log
  - build/agent209/t302/pilot/verify.log
  - build/agent209/t302/pilot/summary.txt
  - build/agent209/t302/commit_7c757b12.txt
  - build/agent209/t302/expectation_history.txt
  - build/agent209/t302/issue302.md
