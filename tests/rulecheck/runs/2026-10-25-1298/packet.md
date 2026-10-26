THE PACKET

Decision kind: expectation
Subject: #229: freeze tests/audit_vanilla_specials_b.sh's expectations (the 80-row identity map, the timing hash, the game clocks) on pristine vsavj, for registration — after runs 2026-10-25-1294 and -1295
Claim (the working agent's sentence): CLAIM: tests/expected/vanilla_specials_b.tsv (80 rows: tab, workbook move, input as performed, special chain, first chain, status), tests/expected/vanilla_specials_b_ticks.sha256 (the SHA-256 of the 80-row timing table in engine passes, values outside the tree) and tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv are the expectations of tests/audit_vanilla_specials_b.sh on pristine vsavj and may enter the tree as frozen: the gate's plain run on the Mac at 14z-209, on the script as registered, prints tests/lib/pristine_vsavj.sh's rom, mame and rompath lines (ROMDIR all match against docs/checksums.txt; the vsavj fingerprint equal to the registry row; the analysed image and build/out's views equal to vsavj.zip decrypted afresh; MAME_ROMPATH unset, so the legs' tools/run_mame.sh -rompath is ROMDIR; the MAME the pin's release) and reads PASS with the map and the timing hash equal, the legs at their frozen game clocks and the ten declared controls FIRED in-gate (build/agent209/t229/v4/vanilla_specials_b.log); each of the ten as a CONTROL= mode on the same script exits 1 on a FAIL (build/agent209/t229/v4/vanilla_specials_b@*.log); the files the gate follows, with dates and hashes, are build/agent209/t229/asrun/specials_b_files.txt, and today's code reproduces the expectations frozen on 2026-10-20, which is all the PASS shows about them; the identity rests on the maintainer's read of F2's capture sheets (DECISIONS_HISTORY.md 8268-8278) and the frozen map still names each of the 80 sheet events by the chain its sheet showed (build/agent209/t229/sheetmap/cmp_f23.py, cmp_f23.out). NOT TESTED: FBNeo; victims other than an idle Victor; the timing values against the workbook (classified for the community page by tools/crosscheck_229.py, nothing here freezes them); any host but the Mac; that the pinned MAME was built from the pinned commit (its -version reads the release only, tests/lib/mame_ident.sh); a romset that passes docs/checksums.txt but differs elsewhere (the reference manifest is the bound).
Artifacts (read every one, in full):
  - tests/audit_vanilla_specials_b.sh
  - tests/lib/pristine_vsavj.sh
  - tests/lib/mame_ident.sh
  - tools/run_mame.sh
  - tests/expected/vanilla_specials_b.tsv
  - tests/expected/vanilla_specials_b_ticks.sha256
  - tests/expected/instr_gameclock/audit_vanilla_specials_b.tsv
  - tests/lua/specials_b_trace.lua
  - build/agent209/t229/v4/vanilla_specials_b.log
  - build/agent209/t229/v4/vanilla_specials_b@swapped-strengths.log
  - build/agent209/t229/v4/vanilla_specials_b@unsigned-offsets.log
  - build/agent209/t229/v4/vanilla_specials_b@window-at-event.log
  - build/agent209/t229/v4/vanilla_specials_b@p1-clock.log
  - build/agent209/t229/v4/vanilla_specials_b@drift-clock.log
  - build/agent209/t229/v4/vanilla_specials_b@first-frame-skip.log
  - build/agent209/t229/v4/vanilla_specials_b@foreign-image.log
  - build/agent209/t229/v4/vanilla_specials_b@foreign-romset.log
  - build/agent209/t229/v4/vanilla_specials_b@foreign-rompath.log
  - build/agent209/t229/v4/vanilla_specials_b@foreign-mame.log
  - build/agent209/t229/asrun/specials_b_files.txt
  - build/agent209/t229/sheetmap/cmp_f23.py
  - build/agent209/t229/sheetmap/cmp_f23.out
  - DECISIONS_HISTORY.md.lines-8268-8278 (lines 8268-8278 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer in the questions doc — the sheets of")
