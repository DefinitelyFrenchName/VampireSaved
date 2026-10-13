THE PACKET

Decision kind: recommendation
Subject: #265: put to the maintainer — audit_mask_window_ff42a2's release SKIP; three options, A recommended
Claim (the working agent's sentence): Recommend to the maintainer (build/agent199/t265/report.md) that audit_mask_window_ff42a2 move from scope `out` to `ondemand` with a new reason keyword (option A), with option B (an approved exception the audit and the runner can read) and option C (an instrument outside tests/) offered; nothing is decided. Measured at the HEAD in head.txt: run bare, the instrument prints its SKIP and exits 0 at tests/audit_mask_window_ff42a2.sh:106-112, before its first MAME call (tools/run_replay_mame.sh, line 131); `--scope all` selects every row but `ondemand` (tests/run_all_emulator.sh:224); `python3 tools/audit_emulator_staleness.py --cadence release` exits 1 listing this SKIP and audit_release_linux_desktop's (stale_release.txt) and never judges an `ondemand` row (tools/audit_emulator_staleness.py:412-413); the `ondemand` reason keyword is enforced as `pristine:` only (tests/test_emulator_runner.sh:378-379); the 2026-09-06 standing exception was recorded in prose and the release was asked again at 14z-153, 14z-174 and 14z-198 (DECISIONS_HISTORY.md). NOT TESTED: no option is built — each cost is read from the files named, not measured on an edit; the other five `momentary:` rows were not read for whether they run bare to a verdict; audit_release_linux_desktop's SKIP is outside the ticket, so A alone does not make the release-cadence audit green; whether `ondemand`'s meaning should widen to an instrument with no default subject is the maintainer's call.
Artifacts (read every one, in full):
  - build/agent199/t265/report.md
  - build/agent199/t265/issue265.md
  - build/agent199/t265/head.txt
  - build/agent199/t265/stale_release.txt
  - tests/audit_mask_window_ff42a2.sh
  - tests/ci_emulator.tsv.lines-1-110 (lines 1-110 of tests/ci_emulator.tsv)
  - tests/ci_emulator.tsv.lines-150-150 (lines 150-150 of tests/ci_emulator.tsv)
  - tests/run_all_emulator.sh.lines-28-75 (lines 28-75 of tests/run_all_emulator.sh)
  - tests/run_all_emulator.sh.lines-220-226 (lines 220-226 of tests/run_all_emulator.sh)
  - tools/audit_emulator_staleness.py.lines-1-75 (lines 1-75 of tools/audit_emulator_staleness.py)
  - tools/audit_emulator_staleness.py.lines-405-416 (lines 405-416 of tools/audit_emulator_staleness.py)
  - tests/test_emulator_runner.sh.lines-370-381 (lines 370-381 of tests/test_emulator_runner.sh)
  - DECISIONS_HISTORY.md.lines-997-1003 (lines 997-1003 of DECISIONS_HISTORY.md)
  - DECISIONS_HISTORY.md.lines-3360-3404 (lines 3360-3404 of DECISIONS_HISTORY.md)
  - DECISIONS_HISTORY.md.lines-1747-1760 (lines 1747-1760 of DECISIONS_HISTORY.md)
  - DECISIONS_HISTORY.md.lines-6596-6612 (lines 6596-6612 of DECISIONS_HISTORY.md)
