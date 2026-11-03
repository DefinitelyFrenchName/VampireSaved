THE PACKET

Decision kind: recommendation
Subject: #347 and #353 closed done: run_all_emulator.sh --stale --freeze asks the staleness audit at freeze cadence (audit_emulator_staleness.py --names honours --cadence), and a --log directory that already holds a run is refused; gated by test_emulator_runner sections 24-25 and test_emulator_staleness section 2i with controls log-reused, stale-default-cadence, stale-cadence-refused, names-unfiltered (14z-218)
Claim (the working agent's sentence): #347 and #353 can close done with closing_347.md and closing_353.md. #353 (issue353.md): a --log directory holding a run was appended to; the fixed runner refuses it (fix_committed.diff, run_all_emulator.sh) and on the real 14z-217 directory prints REFUSED and exits 1, the directory's listing md5 unchanged (evidence_347_353.txt E3). #347 (issue347.md): --stale --freeze refused 22 ondemand names because --names ignored --cadence; the fixed tool prints only what a freeze judges with a NOTE for the rest, and the runner asks at freeze cadence; on the real tree old exit 1 REFUSED, new exit 0 (E4). The new sections fail against the code before the fix (E5, E6). On PILOT, on a clone of the commit's tree 8834baab, test_emulator_runner PASS 20/20 controls fired and all 20 modes HONOURED, test_emulator_staleness PASS 11/11 and all 11 modes HONOURED (E2). NOT TESTED: two runs racing past the --log check at the same instant; a plain --stale (no --cadence) still refuses when an ondemand row is stale, left undecided; the closing comments name both.
Artifacts (read every one, in full):
  - build/agent218/t353/close/../../t353/close/issue353.md
  - build/agent218/t347/close/issue347.md
  - build/agent218/t353/close/fix_committed.diff
  - build/agent218/t353/close/evidence_347_353.txt
  - build/agent218/t353/close/closing_353.md
  - build/agent218/t347/close/closing_347.md
