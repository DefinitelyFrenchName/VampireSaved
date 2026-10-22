THE PACKET

Decision kind: recommendation
Subject: #296 closed done: the reused-sandbox refusal, with every emulator lane run under it (14z-206), after run 1179
Claim (the working agent's sentence): #296 can close done: its done-when (issue_296_body.md) is met. Both steps landed: the opt-in sandbox inventory in 3b85b623 (14z-205) and the refusal in a8fa5350 (14z-206), tools/run_mame.sh refusing a run whose sandbox already holds MAME state unless MAME_SANDBOX_REUSE=1 (t296.diff, tools/run_mame.sh, tests/test_mame_sandbox_log.sh with control refusal-removed). Every declared reuse names its reason because there are none: outside documentation MAME_SANDBOX_REUSE appears only in run_mame.sh's own check, test_mame_sandbox_log's stub runs and comments (reuse_grep.txt). The emulator lanes ran with MAME_SANDBOX_LOG on and MAME_SANDBOX_REUSE unset on 04a53769: ERIS's fbneo and mame lanes, all and ondemand, and its prereq lane, which has release-scope rows only (remote/eris/REPORT.md, remote/eris3/REPORT.md, remote/pilot3/mister/prereq_scopes.txt: 23 release rows in tests/ci_emulator.tsv), and PILOT's mister lane, GREEN 8 of 8 (remote/pilot3/mister/run_mister/results.tsv, run_mister_resume.out), with 4,775 MAME runs all logged fresh (4,463 + 308 + 4: the two ERIS reports and pilot3/mister/sandbox.log) and no REFUSED line from run_mame.sh in any gate log (ERIS's: the two reports; PILOT's: every mister gate log as its last run left it, mister/refused_grep.txt, while test_mister_obj_oracle's cut-short first run left no log of its own and is recorded only in sandbox.log, as fresh). The four red rows are none of them the refusal's, each named with its cause in the closing comment (test_wide_profile's host mtime, audit_marionette_cost's #302 drift, test_mame_parity without a reference MAME on ERIS, test_proof_sheets' #309), and "green with refusal on" is counted as no red caused by the refusal by the maintainer's ruling ("Close, reds named (Recommended)", DECISIONS_HISTORY.md). The mister lane's one void row, test_mister_gfxc_fetch's FAIL 221 exit 143 (results.before_resume.tsv), is void: a session fork, cleaning up, deleted the jtsim scratch slot the gate had just started on and its Verilator compile died (remote/pilot3/REPORT.md); the row was deleted and the gate re-run under --resume to PASS (resume_gfxc.sh, whose header's "the orchestrator's kill of a gate fork" is that same event, worded before the fork's report had it exactly). Not covered, as the comment's last paragraph says: the lanes on 8b82d5d2's tree, the mister ondemand scope, and run_inp_guarded.sh and run_inp_probe.sh, which bypass run_mame.sh.
Artifacts (read every one, in full):
  - build/agent206/t296/closing_comment.md
  - build/agent206/t296/issue_296_body.md
  - build/agent206/t296/REPORT.md
  - build/agent206/t296/t296.diff
  - build/agent206/t296/reuse_grep.txt
  - tools/run_mame.sh
  - tests/test_mame_sandbox_log.sh
  - build/agent206/remote/eris/REPORT.md
  - build/agent206/remote/eris3/REPORT.md
  - build/agent206/remote/pilot3/REPORT.md
  - build/agent206/remote/pilot3/mister/sandbox.log
  - build/agent206/remote/pilot3/mister/lanes.log
  - build/agent206/remote/pilot3/mister/lanes_p3.sh
  - build/agent206/remote/pilot3/mister/resume_gfxc.sh
  - build/agent206/remote/pilot3/mister/run_mister.out
  - build/agent206/remote/pilot3/mister/run_mister_resume.out
  - build/agent206/remote/pilot3/mister/run_mister/results.tsv
  - build/agent206/remote/pilot3/mister/run_mister/results.before_resume.tsv
  - build/agent206/remote/pilot3/mister/run_mister/commit.txt
  - build/agent206/remote/pilot3/mister/refused_grep.txt
  - build/agent206/remote/pilot3/mister/prereq_scopes.txt
  - DECISIONS_HISTORY.md.lines-7662-7672 (lines 7662-7672 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-22 (14z-206) — #296: "the emulator lanes are green with refusal on" is met with no ")
