THE PACKET

Decision kind: recommendation
Subject: close #328 as done (14z-210): both gates take the current freeze builds; a clean clone on ERIS builds and passes them
Claim (the working agent's sentence): CLAIM: close #328 as done with the comment build/agent210/closures/final/c328.md (fixed in commit 86d1ca10; the clean-clone run at e4aa32ee). Its done-when (build/agent210/closures/issues/328.md): "each takes a build the commit itself provides (as #306 did) or names in its header how its build is made, and a clean-clone run no longer depends on another gate or a copied directory." The maintainer asked for that run before the close: "Clean-clone run on ERIS (Recommended)" (DECISIONS_HISTORY.md lines 8498-8507, in the working tree, riding the session's close commit).
1. A build the commit provides, through the runner: tests/ci_emulator.tsv line 162 gives test_shim_charid %DON% and line 273 gives audit_trap_sound %HUI%. tests/run_all_emulator.sh lines 227-231 expand them to DON=build/don_m27 and HUI=build/hui61, the M23 freeze builds whose fingerprints the registry records (tests/expected/registry.tsv lines 186-187: 167d870f, cc9c4b68). The code defaults are the same builds: tests/audit_trap_sound.sh line 62 and tests/test_shim_charid.sh line 90.
2. The clean clone: build/agent210/t328c/clone.sh and clone_state.txt show HEAD e4aa32ee with an empty `git status --porcelain`. build/agent210/t328c/build.sh and build_summary.txt show build/wide0, don_m27, hui61 and out absent before; audit_roms exit 0 (audit_roms.log: "verified 76 members against checksums.txt: all match"); then wide0, don_m27 and hui61 built by the commands of HANDOFF.md lines 170-184, each exit 0, with fingerprints 167d870f and cc9c4b68. build/agent210/t328c/gates.sh and gates_summary.txt show both gates run through tests/run_all_emulator.sh. runner_audit_trap_sound.out and runner_test_shim_charid.out each read "GREEN — every selected emulator-tier gate passed" (PASS 12 s and 86 s; c328_trap/build/c328_trap/results.tsv and c328_shim/build/c328_shim/results.tsv; commit.txt e4aa32ee). gates_summary.txt's post-run `git status --porcelain` lists four untracked dirs, c328_shim, c328_trap, don_m27 and hui61. Its ls marks those and out, tmp and wide0 as made there, and build.sh and gates.sh copy nothing in.
3. The Mac runs on those builds: build/agent210/t328/summary.txt and the three logs PASS. test_shim_charid's staging reference leg reads 146bc0c38b8dae29 at frame 5320 on the Mac (t328/shim_don_m27.log) and on ERIS (c328_shim/build/c328_shim/test_shim_charid.log). tests/expected/instr_gameclock/test_shim_charid.tsv keeps its two clock rows.
NOT TESTED: the instrument is ERIS's existing WIDE MAME (~/.cache/vampire-saved/mame/cps2, dated Sep 30 in gates_summary.txt), not built by the clone: clone_state.txt shows the submodules uninitialised. The clone came from a bundle of e4aa32ee, not from GitHub. HANDOFF.md's four-track block still names older output dirs (don_m18, hui52); the clone ran the same commands into don_m27 and hui61. test_shim_charid's header names its build as "the current donovan freeze build" but not the recipe. The done-when's first branch (a build the commit provides) is what the clone shows, so the header branch is not relied on.
Artifacts (read every one, in full):
  - build/agent210/closures/final/c328.md
  - build/agent210/closures/issues/328.md
  - DECISIONS_HISTORY.md.lines-8498-8507 (lines 8498-8507 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #320 closes on the two gates that test for 139; #328 waits for a cle")
  - tests/ci_emulator.tsv.lines-162-162 (lines 162-162 of tests/ci_emulator.tsv)
  - tests/ci_emulator.tsv.lines-273-273 (lines 273-273 of tests/ci_emulator.tsv)
  - tests/run_all_emulator.sh.lines-220-231 (lines 220-231 of tests/run_all_emulator.sh)
  - tests/expected/registry.tsv.lines-186-187 (lines 186-187 of tests/expected/registry.tsv)
  - tests/audit_trap_sound.sh.lines-36-66 (lines 36-66 of tests/audit_trap_sound.sh)
  - tests/test_shim_charid.sh.lines-50-91 (lines 50-91 of tests/test_shim_charid.sh)
  - HANDOFF.md.lines-14-18 (lines 14-18 of HANDOFF.md)
  - HANDOFF.md.lines-144-150 (lines 144-150 of HANDOFF.md)
  - HANDOFF.md.lines-170-184 (lines 170-184 of HANDOFF.md)
  - build/agent210/t328c/clone.sh
  - build/agent210/t328c/clone_state.txt
  - build/agent210/t328c/build.sh
  - build/agent210/t328c/build_summary.txt
  - build/agent210/t328c/audit_roms.log
  - build/agent210/t328c/gates.sh
  - build/agent210/t328c/gates_summary.txt
  - build/agent210/t328c/runner_audit_trap_sound.out
  - build/agent210/t328c/runner_test_shim_charid.out
  - build/agent210/t328c/c328_trap/build/c328_trap/results.tsv
  - build/agent210/t328c/c328_trap/build/c328_trap/commit.txt
  - build/agent210/t328c/c328_shim/build/c328_shim/results.tsv
  - build/agent210/t328c/c328_shim/build/c328_shim/commit.txt
  - build/agent210/t328c/c328_shim/build/c328_shim/test_shim_charid.log
  - build/agent210/t328/summary.txt
  - build/agent210/t328/run.sh
  - build/agent210/t328/shim_don_m27.log
  - build/agent210/t328/shim_m5_wide.log
  - build/agent210/t328/trap_hui61.log
  - tests/expected/instr_gameclock/test_shim_charid.tsv
