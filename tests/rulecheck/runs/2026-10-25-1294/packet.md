THE PACKET

Decision kind: expectation
Subject: #229: freeze tests/audit_vanilla_specials_b.sh's expectations (the 80-row identity map, the timing hash, the game clocks) on pristine vsavj, for registration
Claim (the working agent's sentence): CLAIM: tests/expected/vanilla_specials_b.tsv (80 rows: tab, workbook move, input as performed, special chain, first chain, status), tests/expected/vanilla_specials_b_ticks.sha256 (the SHA-256 of the 80-row timing table in engine passes, values outside the tree) and tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv are the expectations of tests/audit_vanilla_specials_b.sh on pristine vsavj and may enter the tree as frozen: the gate's plain run on the Mac at 14z-209, on the script as it is registered, reads PASS with the map and the timing hash equal, the legs at their frozen game clocks and the six declared controls FIRED in-gate (build/agent209/t229/v2/vanilla_specials_b.log); each control as a CONTROL= mode reaches the gate's own FAIL (build/agent205/t229/f2_specials_b/mode_*.log, run 2026-10-20 on the script before the 14z-209 header edit, which is comment-only: build/agent209/t229/asrun/specials_b_header.diff); the identity rests on the maintainer's read of F2's capture sheets (DECISIONS_HISTORY.md 8267-8277) and the frozen map still names each of the 80 sheet events by the chain its sheet showed (build/agent209/t229/sheetmap/cmp_f23.py, cmp_f23.out). NOT TESTED: FBNeo; victims other than an idle Victor; the timing values against the workbook (the community page compares them, nothing here freezes them); a mode run on the header-edited script; any host but the Mac (the modes ran on the Mac too).
Artifacts (read every one, in full):
  - tests/audit_vanilla_specials_b.sh
  - tests/expected/vanilla_specials_b.tsv
  - tests/expected/vanilla_specials_b_ticks.sha256
  - tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv
  - tests/lua/specials_b_trace.lua
  - build/agent209/t229/v2/vanilla_specials_b.log
  - build/agent205/t229/f2_specials_b/mode_swapped-strengths.log
  - build/agent205/t229/f2_specials_b/mode_unsigned-offsets.log
  - build/agent205/t229/f2_specials_b/mode_window-at-event.log
  - build/agent205/t229/f2_specials_b/mode_p1-clock.log
  - build/agent205/t229/f2_specials_b/mode_drift-clock.log
  - build/agent205/t229/f2_specials_b/mode_first-frame-skip.log
  - build/agent209/t229/asrun/specials_b_header.diff
  - build/agent209/t229/sheetmap/cmp_f23.py
  - build/agent209/t229/sheetmap/cmp_f23.out
  - DECISIONS_HISTORY.md.lines-8267-8277 (lines 8267-8277 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer in the questions doc — the sheets of")
  - build/agent205/t229/f2_specials_b/REPORT_followup.md
