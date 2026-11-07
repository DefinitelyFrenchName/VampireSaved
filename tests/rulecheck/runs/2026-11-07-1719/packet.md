THE PACKET

Decision kind: recommendation
Subject: close #367 done (the classifier's TOOL-ERROR rule) and freeze #310 group 7 batch 4 (112 dead-leg rows over 29 gates); #368 filed (14z-223)
Claim (the working agent's sentence): #367 can be closed done with closing_367.md, and #310 group 7 batch 4 can be frozen as 112 new rows of tests/expected/dead_leg_unjudged.tsv (gate, mode, UNJUDGED, stripped class HONOURED, MAME_BIN) and reported on #310 with comment_310_b4.md. #367: tests/lib/classify.sh (classify.sh.txt; t367.diff.txt) reads DIED a control mode whose log ends on tool-error lines (VS_TOOL_ERR) with no gate FAIL line just before them and no NOT JUDGED line, read after the NOT-JUDGED branch; tests/test_emulator_runner.sh section 14o PASSes with g_ctool DIED, g_ctoolmid, g_ctoollike and g_ctooldiag honoured and g_ctoolnj UNJUDGED, and its tool-honoured control FIRED in-gate and reaches its own FAIL as a mode (runner_plain3.log, runner_mode_tool3.log); replayed over the 1,382 kept honoured mode logs the rule changes no verdict (replay3.txt and replay_head.txt name the same 25 LIES flips, from the classifier's earlier rules); marionette's pre-fix log reads DIED and test_hui_air's dead-run log UNJUDGED (hui_air_dead.out, stripped_shape.txt read HONOURED); test_emulator_runner was write-traced on PILOT at 663db341, 22 HONOURED, SAFE (pilot/t367_meta/), and tests/test_controls_concurrent.sh PASSes (controls_concurrent.log). Batch 4: the 30 group-7 gates on tests/controls_concurrent_emu.txt (audit_release_linux_desktop left for its host), 121 declared modes equal to candidates.tsv less that gate (evidence_b4.txt §1); on a dead emulator at c5fe01b4 with #367's rule 104 read HONOURED, 16 DIED, 1 UNJUDGED (base/classes.tsv); after the fix (batch4A.diff.txt, batch4B.diff.txt, batch4T.diff.txt) 113 read UNJUDGED and 8 HONOURED whose control fires on evidence no dead MAME_BIN removes (after/classes.tsv; evidence_b4.txt §1); the 112 rows exclude those 8 and audit_latch_reads tap-window-moved, UNJUDGED before the fix; tests/test_dead_leg_unjudged.sh PASSes on 203 rows with nj-stripped FIRED on 203 and plain-loud on 201 of 203 (dead_leg_gate3.log); live, ERIS ran 28 gates at 1ecdcc22, every plain run exit 0 and 111 of 112 modes HONOURED (eris/t310b4_live/classes.tsv), the Mac ran test_readme_recording, plain PASS and 5 modes HONOURED (mac_live/classes.tsv); the gates' blobs equal 1ecdcc22's (evidence_b4.txt §2); the concurrent-controls re-trace at 1ecdcc22 reads PILOT 15 SAFE with 75 HONOURED (pilotA/t310b4A_meta/) and ERIS 13 SAFE with 41 HONOURED and audit_flicker_attribution HOLLOW (eris/t310b4_meta/), whose row is taken off with #368 named. #368: in every kept release tier the shared-sandbox mode's replay-105 f5868 leg did not complete and the mode's CONTROL FIRED line follows it (evidence_b4.txt §3; issue_flicker_shared_sandbox.md). NOT TESTED: a set -e death that prints nothing, and a crash whose last tool-error line follows a line of the gate's starting FAIL, are not caught by the rule; the static tier's control logs were not replayed (only the emulator runner keeps per-mode logs); the dead check kills MAME_BIN from the start, so only the first liveness exit each gate reaches runs dead and the other tagged exits are read in the diff; the stripped class is the neutered copy's measured class; the batch-4 live run ran 8 modes at a time on ERIS, for gates whose own controls were traced safe to run together, not every pairing of different gates; audit_release_linux_desktop, audit_release_linux_cleanhost, the six held out and #368 are not in this batch; test_release_binaries was not edited and not re-run live; the two CONTROL DEAD lines of other controls inside audit_latch_reads tap-window-moved and audit_victim_parity no-translation, identical in the M26 release run, are not examined.
Artifacts (read every one, in full):
  - build/agent223/t367/closing_367.md
  - build/agent223/t310b4/comment_310_b4.md
  - build/agent223/t367/t367.diff.txt
  - build/agent223/t367/classify.sh.txt
  - build/agent223/t367/runner_plain3.log
  - build/agent223/t367/runner_mode_tool3.log
  - build/agent223/t367/replay3.txt
  - build/agent223/t367/replay_head.txt
  - build/agent223/t367/replay.sh.txt
  - build/agent223/t367/scan.py.txt
  - build/agent223/t367/hui_air_dead.out
  - build/agent223/t367/stripped_shape.txt
  - build/agent223/t367/pilot/t367_meta/prep
  - build/agent223/t367/pilot/t367_meta/score.txt
  - build/agent223/t367/pilot/t367_meta/classes.tsv
  - build/agent223/t367/controls_concurrent.log
  - build/agent223/t310b4/batch4A.diff.txt
  - build/agent223/t310b4/batch4B.diff.txt
  - build/agent223/t310b4/batch4T.diff.txt
  - build/agent223/t310b4/candidates.tsv
  - build/agent223/t310b4/evidence_b4.txt
  - build/agent223/t310b4/base/classes.tsv
  - build/agent223/t310b4/after/classes.tsv
  - build/agent223/t310b4/dead_leg_gate3.log
  - build/agent223/t310b4/eris/t310b4_live/classes.tsv
  - build/agent223/t310b4/mac_live/classes.tsv
  - build/agent223/t310b4/pilotA/t310b4A_meta/prep
  - build/agent223/t310b4/pilotA/t310b4A_meta/score.txt
  - build/agent223/t310b4/pilotA/t310b4A_meta/classes.tsv
  - build/agent223/t310b4/eris/t310b4_meta/prep
  - build/agent223/t310b4/eris/t310b4_meta/score.txt
  - build/agent223/t310b4/eris/t310b4_meta/classes.tsv
  - build/agent223/t310b4/issue_flicker_shared_sandbox.md
  - build/agent223/t310b4/controls_source_added.txt
  - tests/expected/dead_leg_unjudged.tsv
