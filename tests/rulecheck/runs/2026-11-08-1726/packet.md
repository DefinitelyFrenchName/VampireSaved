THE PACKET

Decision kind: recommendation
Subject: #310 group 7: the Linux dead-leg gate and its 5 rows, the desktop driver fix, the concurrent-list changes
Claim (the working agent's sentence): #310 group 7's five Linux-only rows can be frozen as tests/expected/dead_leg_unjudged_linux.tsv, judged by the new release-cadence gate tests/audit_dead_leg_linux.sh (registered in tests/ci_emulator.tsv with its measured runtime, frozen as a declaring gate in tests/expected/gate_follows.tsv), and reported on #310 with comment_310_lx.md; the desktop gate comes off tests/controls_concurrent_emu.txt for good, and test_release_roundtrip goes back on tests/controls_concurrent.txt, with test_emulator_runner's row moved to its new blob (lx_gates.diff.txt: the gates and table; lx_driver.diff.txt: the driver; lx_lists.diff.txt: the registry, the lists, the runners, the dead-leg gate and test_emulator_runner; docs.diff.txt: STATE row (7), the gotchas, the ticket row, NEXT_SESSION). The maintainer ruled where these rows run: "A. A small release-cadence emulator gate that judges the 5 rows on PILOT at release (my recommendation). It sits alongside the two gates it checks. Off Linux it SKIPs visibly, like they do, and a red blocks the release. -> agreed." (quoted whole in the new gate's WHY header, lx_gates.diff.txt; STATE.md row (5) quotes it shortened). Before the fix, on PILOT at 9b83394d, the unfixed gates read cleanhost's two modes and desktop's muted-stream and unlinked-recorder HONOURED with their instrument dead, and wrong-mark DIED on the driver's traceback (pre_fix_classes_9b83394d.tsv; pass1_prep.txt). The driver tools/desktop_session_play.py leaked: with xwd dead the old driver left 4 processes (2 emulators, 2 recorders) running (driver_D1_left.txt, driver_D1_D3_classes.tsv); the fixed driver beside them refused, its plain run exiting 1 with 5 "already on the session" lines (driver_D2_tail.txt, pass2_prep.txt), and after they were killed (0 left), with xwd dead it read UNJUDGED with both emulators' own-stream signal checks ok and 0 left (driver_D3.out.txt, driver_D1_D3_classes.tsv). At scratch 3ce6645c on PILOT under tests/run_all_emulator.sh --strict --controls: audit_release_linux_desktop plain PASS and its 3 modes HONOURED in 783 s, run one after another (desktop_runner_results.txt); audit_dead_leg_linux plain PASS in 2,024 s, nj-stripped HONOURED in 2,025 s, plain-loud HONOURED in 1,613 s, GREEN, nothing left running (deadleg_runner_results.txt, deadleg_plain.log, deadleg_nj_stripped.log, deadleg_plain_loud.log, pass2_prep.txt); its plain log shows each of the 5 rows UNJUDGED under every leg dead and under only its named PATH instrument dead, each target gate's plain run red and silent, and the nj-stripped and plain-loud firings (deadleg_plain.log); audit_release_linux_cleanhost at scratch 8a72ab50 with the same script blob 342b8b50: plain PASS and both modes HONOURED, GREEN (pass1_cleanhost_results.txt, pass1_prep.txt). The staged gate script and table differ from the blobs PILOT ran only in comment lines (pilot_vs_staged.txt; the staged blobs are in staged_blobs.txt, every other changed script's blob equal to PILOT's). Write traces at 3ce6645c, each run with SIGPIPE at its default (pilot_tr3.sh.txt, pilot_tr4.sh.txt; each script's shell SigIgn 0 in trace_*_sigign.txt): test_release_roundtrip 10 controls HONOURED, SAFE; test_emulator_runner 22 HONOURED, SAFE (trace_test_release_roundtrip_score.txt and _classes.tsv, trace_test_emulator_runner_score.txt and _classes.tsv); both first traces, in pilot_lx2.sh's T phase, ran with SIGPIPE ignored by gnome-session-inhibit and are void: the runner's read all 22 UNJUDGED on printf I/O errors, roundtrip's 10 HONOURED SAFE (trace_*_VOID_sigpipe_ignored_*); the T3 and T4 lines of pass2_prep.txt give the re-traces' walls; sigpipe_check.txt shows the inhibitor leaving SIGPIPE ignored, env --default-signal=PIPE restoring it, the I/O error reproduced, and 0 such lines in the pass-2 gate logs, the roundtrip trace, the re-run runner trace and the M26 desktop runs. tests/test_controls_concurrent.sh, test_gate_follows.sh, test_gate_index_current.sh, test_tickets.sh, test_live_budget.sh, test_gotchas_index_current.sh and test_checkdocs.sh PASS on the staged tree (bookkeeping.txt). The scripts that drove PILOT are pilot_lx.sh.txt, pilot_lx2.sh.txt, pilot_tr3.sh.txt and pilot_tr4.sh.txt (pilot_tr4.sh is pilot_tr3.sh with the gate, marker names and its first comment lines changed). NOT TESTED: the new gate has not run inside a full release tier, only alone (its plain run rewrites the two target gates' kept output dirs, so it must run after them, as its registry row says); only the first liveness exit each gate reaches runs dead, the other tagged exits are read in the diff; wrong-mark's neutered copy was not measured with the old driver beyond its DIED, so its frozen stripped class HONOURED is the neutered copy's under the fixed driver at 3ce6645c; the desktop and dead-leg gate runs of pass 2 ran with SIGPIPE ignored (their logs carry no I/O error line); the full static and emulator tiers have not run on this tree yet (the strict static tier follows this packet); the driver leak and the concurrent-list defect are kept under #310, not ticketed separately.
Artifacts (read every one, in full):
  - build/agent223/t310lx/rc/bookkeeping.txt
  - build/agent223/t310lx/rc/comment_310_lx.md
  - build/agent223/t310lx/rc/deadleg_nj_stripped.log
  - build/agent223/t310lx/rc/deadleg_plain.log
  - build/agent223/t310lx/rc/deadleg_plain_loud.log
  - build/agent223/t310lx/rc/deadleg_runner_results.txt
  - build/agent223/t310lx/rc/desktop_runner_results.txt
  - build/agent223/t310lx/rc/docs.diff.txt
  - build/agent223/t310lx/rc/driver_D1_D3_classes.tsv
  - build/agent223/t310lx/rc/driver_D1_left.txt
  - build/agent223/t310lx/rc/driver_D2_tail.txt
  - build/agent223/t310lx/rc/driver_D3.out.txt
  - build/agent223/t310lx/rc/lx_driver.diff.txt
  - build/agent223/t310lx/rc/lx_gates.diff.txt
  - build/agent223/t310lx/rc/lx_lists.diff.txt
  - build/agent223/t310lx/rc/pass1_cleanhost_results.txt
  - build/agent223/t310lx/rc/pass1_prep.txt
  - build/agent223/t310lx/rc/pass2_prep.txt
  - build/agent223/t310lx/rc/pass2_stages.txt
  - build/agent223/t310lx/rc/pilot_lx.sh.txt
  - build/agent223/t310lx/rc/pilot_lx2.sh.txt
  - build/agent223/t310lx/rc/pilot_tr3.sh.txt
  - build/agent223/t310lx/rc/pilot_tr4.sh.txt
  - build/agent223/t310lx/rc/pilot_vs_staged.txt
  - build/agent223/t310lx/rc/pre_fix_classes_9b83394d.tsv
  - build/agent223/t310lx/rc/sigpipe_check.txt
  - build/agent223/t310lx/rc/staged_blobs.txt
  - build/agent223/t310lx/rc/trace_test_emulator_runner_VOID_sigpipe_ignored_classes.tsv
  - build/agent223/t310lx/rc/trace_test_emulator_runner_VOID_sigpipe_ignored_score.txt
  - build/agent223/t310lx/rc/trace_test_emulator_runner_classes.tsv
  - build/agent223/t310lx/rc/trace_test_emulator_runner_score.txt
  - build/agent223/t310lx/rc/trace_test_emulator_runner_sigign.txt
  - build/agent223/t310lx/rc/trace_test_release_roundtrip_VOID_sigpipe_ignored_classes.tsv
  - build/agent223/t310lx/rc/trace_test_release_roundtrip_VOID_sigpipe_ignored_score.txt
  - build/agent223/t310lx/rc/trace_test_release_roundtrip_classes.tsv
  - build/agent223/t310lx/rc/trace_test_release_roundtrip_score.txt
  - build/agent223/t310lx/rc/trace_test_release_roundtrip_sigign.txt
  - tests/expected/dead_leg_unjudged_linux.tsv
