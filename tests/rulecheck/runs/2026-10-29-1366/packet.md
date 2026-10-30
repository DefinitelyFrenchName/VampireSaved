THE PACKET

Decision kind: recommendation
Subject: close #333 as done (14z-212): every mktemp -d site in tests/, tests/lib/ and tools/ stops on failure, the census holds the count at zero, the changed gates re-traced on PILOT
Claim (the working agent's sentence): CLAIM: close #333 as done (14z-212): the closing comment closing_comment.md and the row ticket_row_333.tsv state the resolution. Every `mktemp -d` site in tests/*.sh, tests/lib/*.sh and tools/*.sh now stops when mktemp fails, and a static check holds the unguarded count at zero; the edits land in this session's commit with #334's. It rests on:
1. THE CENSUS: census_before.txt (14z-211, before the guards: 440 assignments, 106 unguarded, 8 that also rm -rf or mkdir -p "$X/<sub>") against census_now.txt (tools/tmp_hygiene.py on today's tree: 0 carrying on after a failed mktemp -d, 461 mktemp -d lines read).
2. THE GATE: test_tmp_hygiene.log (tests/test_tmp_hygiene.sh, PASS on the tree); mode_planted-unguarded.log (a planted unguarded gate named UNGUARDED, FAIL) and mode_shim-blind.log (the dynamic check with the failing mktemp left off the PATH FAILs), both on today's tree; mode_mktemp.txt and mode_shim.txt (the same controls at 14z-211).
3. THE RE-TRACE (the #315 method, required because each changed script's blob changed): pilot_*_overlap.txt and pilot_*_classes.tsv (PILOT, the tree 6829e446 per pilot_head.txt: 46 static and 22 emulator gates SAFE, none SHARED; four first HOLLOW on clone setup, re-traced SAFE; every control run classed HONOURED); cc_static_census.txt and cc_emu_census.txt (tools/controls_concurrent.py on today's tree: 0 rows named of 99 and 60); tests/controls_concurrent.txt, tests/controls_concurrent_emu.txt (the rows and their TRACES lines).
4. THE RELEASE SHAPE: eris_release_results.tsv (ERIS, the #333-only tree 505c3257, --scope all --strict --controls: 417 PASS, 4 SKIP — release binaries not built on that host, no pw-record, no podman).
5. THE RECORDS: docs/platform/gotchas.md.lines-3512-3522, docs/project/gotchas.md.lines-7778-7790; the rulings DECISIONS_HISTORY.md.lines-8503-8540 and .lines-8596-8605; tools/tmp_hygiene.py, tests/test_tmp_hygiene.sh.
NOT TESTED: scripts outside tests/, tests/lib/ and tools/; a Python tempfile failure (the census reads Python makers for clean-up only); the guards' behaviour on a real full disk on every gate — the dynamic check puts a failing mktemp first on PATH for a synthetic script and the guarded gates it runs, not for every one of the 106; ERIS's release-shape run was on the #333-only tree, before #334's knobs, and the emulator gates on the combined tree rest on the 61 timed on ERIS (PASS on both sides) and the tier; the static tier on the staged tree has not run yet: it runs before the commit.
Artifacts (read every one, in full):
  - build/agent212/t333/closure/closing_comment.md
  - build/agent212/t333/closure/ticket_row_333.tsv
  - build/agent212/t333/closure/census_before.txt
  - build/agent212/t333/closure/census_now.txt
  - build/agent212/t333/closure/test_tmp_hygiene.log
  - build/agent212/t333/closure/mode_planted-unguarded.log
  - build/agent212/t333/closure/mode_shim-blind.log
  - build/agent212/t333/closure/mode_mktemp.txt
  - build/agent212/t333/closure/mode_shim.txt
  - build/agent212/t333/closure/pilot_head.txt
  - build/agent212/t333/closure/pilot_t212r_static_out_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_static_out_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_emu_out_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_emu_out_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_fix_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_fix_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_fix_emu_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_fix_emu_classes.tsv
  - build/agent212/t333/closure/cc_static_census.txt
  - build/agent212/t333/closure/cc_emu_census.txt
  - build/agent212/t333/closure/eris_release_results.tsv
  - tests/controls_concurrent.txt
  - tests/controls_concurrent_emu.txt
  - docs/platform/gotchas.md.lines-3512-3522 (lines 3512-3522 of docs/platform/gotchas.md)
  - docs/project/gotchas.md.lines-7778-7790 (lines 7778-7790 of docs/project/gotchas.md)
  - DECISIONS_HISTORY.md.lines-8503-8540 (lines 8503-8540 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #321: a control mode's environment error is DIED; the emulator runne", and the entries after it up to line 8540)
  - DECISIONS_HISTORY.md.lines-8596-8605 (lines 8596-8605 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 1: all 35 settings timed on PILOT; #333's re-trace waits f")
  - tools/tmp_hygiene.py
  - tests/test_tmp_hygiene.sh
