THE PACKET

Decision kind: recommendation
Subject: close #332 as done (14z-210): a missing out-of-tree table reads NOT JUDGED
Claim (the working agent's sentence): CLAIM: close #332 as done with the comment build/agent210/closures/final/c332.md (fixed in commit 86d1ca10; the gate re-frozen for #331 in e4aa32ee; the header lines 25-27 of tests/audit_guard_cancels.sh are in the working tree and ride the session's close commit). Line numbers below are the working tree's, which has two more header lines than HEAD from line 28 on. Its done-when (build/agent210/closures/issues/332.md): "a missing out-of-tree table is reported as such, never as "0 lines differ". The mode run says `NOT JUDGED:` and the control is not read as dead. The header names the input and how to make it (`FREEZE=1`, or a copy from a host that has it). A control proves the missing-table path is caught."
1. Reported as such: tests/audit_guard_cancels.sh lines 257-263, the `node-shift` judgement, test for the table first and print "NOT JUDGED: the frozen table … is not on this host (out of tree: FREEZE=1 here, or copy it from a host whose table hashes as …)" with return 3, before the diff of line 266 that read a missing table as 0 (build/agent210/closures/final/e332_diff.txt is the 86d1ca10 change). ERIS's dead reading is build/agent210/t321k/gc_diag.log line 27, "0 of 271 lines differ".
2. The mode run: build/agent210/t332m/node-shift_no_table.log, the `node-shift` mode with FRAMEDATA_OUT an empty dir, has one line starting "NOT JUDGED: the frozen table", no CONTROL DEAD or REFUSED line, and ends FAIL. Its exit is recorded beside it: build/agent210/t332m/node-shift_no_table.rc reads "exit 1", then vs_classify_control -> UNJUDGED. build/agent210/closures/final/e332_classify.txt (by e332_classify.sh, which takes the rc from that file) reproduces the reading: tests/lib/classify.sh's vs_classify_control reads the log UNJUDGED (tests/lib/classify.sh lines 126-130, 163-164). Lines 307-309 are the mode path. In the plain run, lines 341-342 turn a NOT JUDGED judgement into a FAIL naming the table, never a CONTROL DEAD. build/agent210/book/verify2/audit_guard_cancels@table-absent.log (FRAMEDATA_OUT empty) shows "FAIL  control node-shift the frozen table … is not on this host" and no DEAD line.
3. The header: tests/audit_guard_cancels.sh lines 25-27 name the input (FRAMEDATA_OUT, default ../charpages/framedata/guard_cancels.tsv) and how a host without it gets one: FREEZE=1 "(after the rule-checker, as any freeze)" or a copy from a host whose table hashes as tests/expected/guard_cancels.sha256. Usage line 75 lists FREEZE=1.
4. The control: `table-absent` (MUST-FIRE line 54; in-gate lines 349-353; mode lines 96-97). On the Mac at 271 events, build/agent210/book/verify2/results.tsv (run by book/run_verify2.sh) has plain PASS, `node-shift` HONOURED with "159 of 271 lines differ" (audit_guard_cancels@node-shift.log line 35) and `table-absent` HONOURED; the plain log has `table-absent` FIRED. After #331, at 291 events, build/agent210/t331f/plain.log lines 28-30 have `node-shift` FIRED, "171 of 291 lines differ from the frozen table", `table-absent` FIRED and PASS. t331f/modes.out (run by t331f/verify.sh) has every mode exit 1, and mode_table-absent.log and mode_node-shift.log show their own findings.
NOT TESTED: the command that re-ran the no-table mode and wrote node-shift_no_table.rc is not among the artifacts; the log's first line names the mode, and e332_classify.txt re-reads the log with the recorded rc. The fixed gate was not rerun on ERIS, the host that read DEAD. The header lines 25-27 are uncommitted, and the session's close commit is what carries them. The 271-event Mac runs ran on the working tree before 86d1ca10 was made, and no artifact ties that copy to the committed blob.
Artifacts (read every one, in full):
  - build/agent210/closures/final/c332.md
  - build/agent210/closures/issues/332.md
  - tests/audit_guard_cancels.sh.lines-20-28 (lines 20-28 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-51-55 (lines 51-55 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-72-76 (lines 72-76 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-94-98 (lines 94-98 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-257-268 (lines 257-268 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-302-311 (lines 302-311 of tests/audit_guard_cancels.sh)
  - tests/audit_guard_cancels.sh.lines-335-355 (lines 335-355 of tests/audit_guard_cancels.sh)
  - build/agent210/closures/final/e332_diff.txt
  - tests/lib/classify.sh.lines-120-131 (lines 120-131 of tests/lib/classify.sh)
  - tests/lib/classify.sh.lines-158-166 (lines 158-166 of tests/lib/classify.sh)
  - build/agent210/t321k/gc_diag.log
  - build/agent210/t332m/node-shift_no_table.log
  - build/agent210/t332m/node-shift_no_table.rc
  - build/agent210/closures/final/e332_classify.sh
  - build/agent210/closures/final/e332_classify.txt
  - build/agent210/book/verify2/results.tsv
  - build/agent210/book/run_verify2.sh
  - build/agent210/book/verify2/audit_guard_cancels@plain.log
  - build/agent210/book/verify2/audit_guard_cancels@node-shift.log
  - build/agent210/book/verify2/audit_guard_cancels@table-absent.log
  - build/agent210/t331f/plain.log
  - build/agent210/t331f/modes.out
  - build/agent210/t331f/verify.sh
  - build/agent210/t331f/mode_table-absent.log
  - build/agent210/t331f/mode_node-shift.log
