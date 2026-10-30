THE PACKET

Decision kind: recommendation
Subject: close #333 as done (14z-212), after runs 2026-10-29-1366, -1368, -1371, -1374 and -1379: every mktemp -d substitution in tests/, tests/lib/ and tools/ read by the census and stopping on failure, the changed gates re-traced on PILOT
Claim (the working agent's sentence): CLAIM: close #333 as done (14z-212), after runs 2026-10-29-1366, -1368, -1371, -1374 (not run: its reader's findings taken) and -1379: the closing comment closing_comment.md and the row ticket_row_333.tsv state the resolution. Every `mktemp -d` substitution in tests/*.sh, tests/lib/*.sh and tools/*.sh (`$( )` or backticks, -d, -dt or --directory) now stops when mktemp fails, or is a plain assignment on a line where `set -e` is in force: tools/tmp_hygiene.py sh_scan reads each one wherever it stands (census_now.txt: 0 carrying on, 487 substitutions read; census_reach.txt: every substitution not read is fixture text in a heredoc body or single quotes, in four gates; census_reach_indep.txt, a check sharing none of the census's patterns — every line with the token `mktemp` and a -d/-dt/--directory word, 556, against the lines the census read — names 70 it did not, all in the same four files), held by tests/test_tmp_hygiene.sh; the edits land in this session's commit with #334's. It rests on:
1. THE CENSUS: census_before.txt (14z-211's line-start census: 440 assignments, 106 unguarded, 8 that also rm -rf or mkdir -p "$X/<sub>"); census_now.txt (the widened census on today's tree). Its reading, in tools/tmp_hygiene.py sh_scan, on logical lines with `\` continuations joined: an assignment (at a line's start or after `;`, `&&`, `||`, `then`, `else`, `do`, a case arm's `)`) is guarded by a `||` whose own arm exits or returns (its `{ ... }` block or up to the next `;`, `&&` or `|` — not `|| true`), by a `[ -n "$X" ] ||` test whose arm stops, on one of the next three CODE lines before X is used, or by `set -e` in force at the line (the last `set -e` / `set +e` among the code lines before it, the last on a line winning) for a plain statement; `local`, `export`, `readonly`, an env prefix and an inline argument never are; heredoc bodies and single-quoted text are not read; an opener is never a here-string `<<<`, a quoted `<<` or the shift in `(( ))` / `$(( ))`. Since run 1379: an arm's `exit` / `return` counts only outside quotes; `return` stops only inside a function body (`name() {` / `function name {` to its closing brace) or at a sourced library's top level (tests/lib/); a `set -e` inside an open `( ... )` / `$( ... )` on its line is not the script's; `\"` no longer flips the quote state (the escape test compared one character with two).
2. THE GATE: test_tmp_hygiene.log (PASS on today's tree: thirty-two unguarded forms named — among them a top-level `|| return`, after a subshell's `set -e`, after an escaped quote's `set -e`, `exit` only in quotes, an else arm, `[ -n ] ||`, a case arm, an inline argument, after `;`, local, an env prefix, `-dt`, after an arithmetic `<<`, `export ||`, `|| true`, before `set -e`, after `set +e`, after a quoted `set -e`, after a here-string, after `(( << ))`, after a quoted `<<`, backticks, `--directory`, a continuation, a test after a use, and a mktemp that is not the substitution's first word — eighteen guarded forms read guarded (among them `|| return` in a one-line and a multi-line function and at a sourced library's top level), every control FIRED, the dynamic check with a failing mktemp first on PATH); mode_planted-unguarded.log (the planted gate and all thirty-two forms named, FAIL) and mode_shim-blind.log (the dynamic check without the shim FAILs).
3. THE RE-TRACE (the #315 method): pilot_t212r_*_overlap.txt / _classes.tsv (PILOT, tree 6829e446 per pilot_head.txt, emu/fbneo's patched working tree dirty as on every host: 46 static and 22 emulator gates SAFE, none SHARED; four gates' first pass SKIPped every control on clone setup — two emulator gates whose runs are classed LIES, two static gates whose exit-77 SKIPs the classifier read HONOURED — all four re-traced SAFE in pilot_t212r_fix_*); pilot_t212r2_* (tree 9aad2bae per pilot_head2.txt: the 3 gates run 1366's widening changed, SAFE, every run HONOURED); pilot_t212r3_static_* (tree 786dc723 per pilot_head3.txt: test_rompath_reject and test_tmp_hygiene after run 1368, SAFE, every run HONOURED); pilot_t212r4_static_* (tree b91b558d per its head.txt: test_tmp_hygiene after run 1371, SAFE, every run HONOURED); pilot_t212r5_static_* (tree e1b87efa per pilot_head5.txt, the census's fifth round and the sitting's other edits: test_tmp_hygiene and six more static gates, 64 control runs, SAFE, every run HONOURED); pilot_t212r7_static_* (tree 38fe3b27 per pilot_head7.txt: test_tmp_hygiene after run 1379, the gate PASSing there first, SAFE, every run HONOURED); cc_static_census.txt and cc_emu_census.txt (0 rows named of 99 and 60 on today's tree); tests/controls_concurrent.txt, tests/controls_concurrent_emu.txt.
4. THE RELEASE SHAPE: eris_run2_record_start.json lines 1-52 and eris_run2_results.tsv (ERIS: the run's own record, head 505c3257 — the first-round tree, before #334's knobs and before the widened census: eris_head_505c3257.txt, 112 guard exits in 108 files against 124 now, its census without SH_SUBST_D — argv `--scope all --strict --controls --jobs 8 --skip test_mame_parity`; 194 gate rows and 227 control rows, 417 PASS, 4 SKIP — release binaries not built on that host, no pw-record, no podman). eris_times.tsv, eris_setup.out and mtime_readers.txt (the 61 gates #334 changed, timed on ERIS on the #333/#334 tree 6829e446 against 33f85438 — eris_setup.out's HEAD lines — before the widened census, PASS both sides; of them only test_wide_profile reads a file's mtime, re-timed after the clone fix).
5. THE RECORDS: docs/platform/gotchas.md.lines-3512-3536, docs/project/gotchas.md.lines-7778-7791; the rulings DECISIONS_HISTORY.md.lines-8512-8524, .lines-8605-8616, .lines-8801-8826 and .lines-8906-8920; tools/tmp_hygiene.py, tests/test_tmp_hygiene.sh; rulecheck_1366_reader_a.txt, rulecheck_1368_reader_b.txt, rulecheck_1371_reader_a.txt, verdict_a_1374.txt (run 1374, not run: its reader A's answer, taken) and verdict_b_1379.txt (the stopping runs).
NOT TESTED: scripts outside tests/, tests/lib/ and tools/; a Python tempfile failure (the census reads Python makers for clean-up only); a real full disk on every gate — the dynamic check fails mktemp for one synthetic script and four guarded gates; a `mktemp -d` built by eval or by a variable holding the command (`$MK -d`), or with `-d` as a separately expanded word, which the census cannot see; a heredoc whose closing word is indented under `<<-` with tabs is read as the census reads the word (stripped); `set -e` read where a function body stands, not where it is called, and a `set -e` change and a site on the same line read with the line's final state; the 11 sites guarded after run 1366 have not run in a release-shape emulator tier (the static tier on the staged tree runs before the commit, the emulator ones at the next release); the combined tree's emulator tier; a `set -e` inside a subshell that spans lines (`(` on one line, `set -e` on a later one) is read as the script's; a function written as a subshell (`name() ( ... )`) is not tracked as a function, so its `|| return` reads unguarded; the brace count assumes `${...}` and `{ ...; }` balance on their line.
Artifacts (read every one, in full):
  - build/agent212/t333/closure/closing_comment.md
  - build/agent212/t333/closure/ticket_row_333.tsv
  - build/agent212/t333/closure/rulecheck_1366_reader_a.txt
  - build/agent212/t333/closure/rulecheck_1368_reader_b.txt
  - build/agent212/t333/closure/rulecheck_1371_reader_a.txt
  - build/agent212/t333/closure/verdict_a_1374.txt
  - build/agent212/t333/closure/verdict_b_1379.txt
  - build/agent212/t333/closure/census_before.txt
  - build/agent212/t333/closure/census_now.txt
  - build/agent212/t333/closure/census_reach.txt
  - build/agent212/t333/closure/census_reach.py
  - build/agent212/t333/closure/census_reach_indep.txt
  - build/agent212/t333/closure/census_reach_indep.py
  - build/agent212/t333/closure/test_tmp_hygiene.log
  - build/agent212/t333/closure/mode_planted-unguarded.log
  - build/agent212/t333/closure/mode_shim-blind.log
  - build/agent212/t333/closure/pilot_head.txt
  - build/agent212/t333/closure/pilot_head2.txt
  - build/agent212/t333/closure/pilot_head3.txt
  - build/agent212/t333/closure/pilot_t212r4_static_head.txt
  - build/agent212/t333/closure/pilot_head5.txt
  - build/agent212/t333/closure/pilot_head7.txt
  - build/agent212/t333/closure/pilot_t212r_static_out_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_static_out_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_emu_out_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_emu_out_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_fix_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_fix_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r_fix_emu_overlap.txt
  - build/agent212/t333/closure/pilot_t212r_fix_emu_classes.tsv
  - build/agent212/t333/closure/pilot_t212r2_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r2_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r2_emu_overlap.txt
  - build/agent212/t333/closure/pilot_t212r2_emu_classes.tsv
  - build/agent212/t333/closure/pilot_t212r3_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r3_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r4_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r4_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r5_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r5_static_classes.tsv
  - build/agent212/t333/closure/pilot_t212r7_static_overlap.txt
  - build/agent212/t333/closure/pilot_t212r7_static_classes.tsv
  - build/agent212/t333/closure/cc_static_census.txt
  - build/agent212/t333/closure/cc_emu_census.txt
  - build/agent212/t333/closure/eris_run2_results.tsv
  - build/agent212/t333/closure/eris_head_505c3257.txt
  - build/agent212/t333/closure/eris_times.tsv
  - build/agent212/t333/closure/eris_setup.out
  - build/agent212/t333/closure/mtime_readers.txt
  - build/agent212/t333/closure/eris_run2_record_start.json.lines-1-52 (lines 1-52 of build/agent212/t333/closure/eris_run2_record_start.json)
  - tests/controls_concurrent.txt
  - tests/controls_concurrent_emu.txt
  - docs/platform/gotchas.md.lines-3512-3536 (lines 3512-3536 of docs/platform/gotchas.md)
  - docs/project/gotchas.md.lines-7778-7791 (lines 7778-7791 of docs/project/gotchas.md)
  - DECISIONS_HISTORY.md.lines-8512-8524 (lines 8512-8524 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-27 (14z-210) — #321: a control mode's environment error is DIED; the emulator runne")
  - DECISIONS_HISTORY.md.lines-8605-8616 (lines 8605-8616 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 1: all 35 settings timed on PILOT; #333's re-trace waits f")
  - DECISIONS_HISTORY.md.lines-8801-8826 (lines 8801-8826 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #333: finish it now — every mktemp -d form read and guarded, the sta", and the entries after it up to line 8826)
  - DECISIONS_HISTORY.md.lines-8906-8920 (lines 8906-8920 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #333: the census's four logic gaps fixed now (round six)")
  - tools/tmp_hygiene.py
  - tests/test_tmp_hygiene.sh
