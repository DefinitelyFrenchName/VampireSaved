THE PACKET

Decision kind: recommendation
Subject: #372/#370: close both with the runner's run temp outside the repo and token holders run alone after the pool
Claim (the working agent's sentence): Close #372 and #370 `done` with this change, as the maintainer ruled ("yes, that's the best way forward"; DECISIONS_HISTORY.md "Ruled 2026-11-13 (14z-227) — the family's finish line"). #372: with no TMPDIR from the caller, tests/run_all_emulator.sh makes its run temp under ${XDG_CACHE_HOME:-$HOME/.cache}/vampire-saved/tmp/ instead of the repo's build/tmp/ (runner.diff); tests/test_emulator_runner.sh section 21 shows the gate's TMPDIR outside the repo and removed after the run, and its new control tmp-in-repo (the old base restored) FAILs the section; on PILOT with TMPDIR unset, test_mister_wide_inert, which refused at once at 14z-226, PASSed in 2932 s with its RAM dumps under ~/.cache/vampire-saved/tmp/, and test_mister_gfxc_fetch got past its refusal into its legs (evidence_b.md). #370: in a pooled lane a gate whose # SHARES: line names a token of tests/shares.tsv is held back and run after the pool, one at a time (runner.diff); section 18f shows two stub holders of release-assets start 3 s apart after the pool's none gate, and its control token-serial-off (the rule disabled) starts them 0 s apart and FAILs the section; the emulator token scheduler of #370's design is not built and its write audit is declined, as ruled. NOT TESTED: the three Linux release gates that hold tokens (audit_dead_leg_linux, audit_release_linux_cleanhost, audit_release_linux_desktop) were not run under the rule; the rule is shown on stub gates on the Mac only; a token holder is never pooled even beside a gate holding a different token (a cost, not checked); test_mister_gfxc_fetch's verdict was not awaited and the other six MiSTer gates were not run; the PILOT run set JTSIM_SCRATCH, so the default scratch path (now under the run temp outside the repo; test_mister_obj_oracle refused it at 14z-226) was not exercised; ERIS was not run; a host whose $HOME/.cache is not writable was not tried; the Mac never reaches the new base (its TMPDIR is always set).
Artifacts (read every one, in full):
  - build/agent227/close/evidence_b.md
  - build/agent227/close/runner.diff
  - build/agent227/close/test_runner.diff
  - build/agent227/fin/ter_plain.log
  - build/agent227/fin/ter@token-serial-off.log
  - build/agent227/fin/ter@tmp-in-repo.log
  - build/agent227/fin/pilot/test_mister_wide_inert.log
  - build/agent227/fin/pilot/gfxc_fetch_head.log
  - build/agent226/r371/mister_fail_lines.txt
  - tests/shares.tsv
  - DECISIONS_HISTORY.md.lines-10192-10208 (lines 10192-10208 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-13 (14z-227) — the family's finish line: #372 fixed, #370's token holders run alone")
  - docs/project/operations.md.lines-694-706 (lines 694-706 of docs/project/operations.md)
  - build/agent227/close/c370.md
  - build/agent227/close/c372.md
