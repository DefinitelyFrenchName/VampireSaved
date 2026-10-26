THE PACKET

Decision kind: expectation
Subject: #229: freeze tests/audit_es_ex.sh's expectations (the 208-event identity map with its record hashes, the game clocks) on pristine vsavj, for registration — after run 2026-10-25-1309
Claim (the working agent's sentence): CLAIM: tests/expected/es_ex.tsv (208 events over the far and near legs: sheet, leg, key, status, move, first chain, stock paid, the count and a hash of the staged records, never their values) and tests/expected/instr_gameclock/audit_es_ex.tsv are the expectations of tests/audit_es_ex.sh on the pristine vsavj ROM and may enter the tree as frozen: the gate's plain run on the Mac at 14z-209 prints tests/lib/pristine_vsavj.sh's rom, mame and rompath lines (ROMDIR all match against docs/checksums.txt; the vsavj fingerprint equal to the registry row; the analysed image and build/out's views equal to vsavj.zip decrypted afresh; MAME_ROMPATH unset, so the legs' tools/run_mame.sh -rompath is ROMDIR; the MAME the pin's release) and reads PASS with its nine declared controls FIRED in-gate, on the stock reference MAME (build/agent209/t229/v4/es_ex.log) and again on the CPS-2 WIDE MAME a tier exports (build/agent209/t229/wide/es_ex.log); each of the nine as a CONTROL= mode exits 1 on a FAIL (build/agent209/t229/v4/es_ex@*.log); every one of the 109 distinct files the gate follows (its whole # FOLLOWS: block with directories expanded, its expectations, and what those files source or import, transitively) was last modified before the first of those logs (build/agent209/t229/asrun/es_ex_files.txt), each log is dated and the logs carry the two controls only the current version declares (build/agent209/t229/asrun/es_ex_version.txt; tests/lib/controls.sh's vs_ctl_mode refuses an undeclared mode); both files are whole-file equal to their members of the pre-edit backup tar (listed Oct 20 23:23 and 23:39) (build/agent209/t229/asrun/es_ex_vs_tar.txt); today's code reproduces them, which is all the PASS shows about them; the identity rests on the maintainer's read of F3's 9-tile sheets of the 104 near-leg events — the Q1 answer covered both sheet versions ("Both", DECISIONS_HISTORY.md 8300-8306; the answer itself 8270-8280), the doc's table names build/agent205/t229/f3_es_ex/cap9/sheets/ (build/agent209/t229/asrun/q1_doc_excerpt.txt), drawn by F3's run.sh with cap9.py sheet, which reads plan/<tab>.json, every one of the 15 plans last written before its sheet and unchanged since (build/agent209/t229/asrun/f3_set.txt), and whose capture legs dumped P1's node at every one of the 936 snapshots, all equal to the field trace's node on that frame (build/agent205/t229/f3_es_ex/cap9/REPORT.md:3-9) — together with the reads of individual rows (DECISIONS_HISTORY.md 7442-7500: Bulleta's ES Cool Hunting, Felicia's ES Please Help Me, Aulbath's Direct Scissors; Jedah's first J.63214KK row read as ES Ira Spinta) and of the 14z-205c re-rigged Jedah sheet esex9_JE.png, whose J.63214KK~PP row is ES Ira Piano ("both are correct", DECISIONS_HISTORY.md 7590-7597; drawn from build/agent205c/t229/f3cap/cap9/plan/JE.json: build/agent209/t229/asrun/f3cap_set.txt); the frozen map is the map those sheets were drawn from: for each of the 104 near-leg events (the 14z-205c JE plan replacing the first JE plan) its status, move chain (its first chain where it has no move) and stock paid equal the sheet's row header, every near-leg row on a sheet, and the compare's three perturbed-copy controls each FIRED (build/agent209/t229/sheetmap/cmp_f3_full.py, cmp_f3_full.out) — lineage, not an independent identity, since the plans were written from the same gate run's analysis; the identity is the maintainer's reading of the images. NOT TESTED: the gate header's own list (tests/audit_es_ex.sh:27-30): identity by eye (the capture sheets are the maintainer's), the FIELD legs not on the alignment manifest, the probe legs' -debug stops able to move the game so their records are compared as a list, never by frame, the characters forced by the early-window poke, P2 Victor (Demitri for Victor) only, FBNeo, PILOT/ERIS; and besides it: the 104 far-leg events, which no sheet draws; the record count and record hash columns, which no sheet shows; that each PNG's pixels show its plan (the maintainer read the PNGs; the link is the tool's reading and the files' dates); any host but the Mac; that the pinned MAMEs were built from the pinned commit (their -version reads the release only, tests/lib/mame_ident.sh); a romset that passes docs/checksums.txt but differs elsewhere; the logs carry no script hash of their own; the control modes ran on the stock build only.
Artifacts (read every one, in full):
  - tests/audit_es_ex.sh
  - tests/lib/pristine_vsavj.sh
  - tests/lib/mame_ident.sh
  - tests/lib/controls.sh
  - tools/run_mame.sh
  - tests/expected/es_ex.tsv
  - tests/expected/instr_gameclock/audit_es_ex.tsv
  - build/agent209/t229/v4/es_ex.log
  - build/agent209/t229/wide/es_ex.log
  - build/agent209/t229/v4/es_ex@drift-clock.log
  - build/agent209/t229/v4/es_ex@first-frame-skip.log
  - build/agent209/t229/v4/es_ex@unsigned-offsets.log
  - build/agent209/t229/v4/es_ex@empty-bank.log
  - build/agent209/t229/v4/es_ex@swapped-move.log
  - build/agent209/t229/v4/es_ex@foreign-image.log
  - build/agent209/t229/v4/es_ex@foreign-romset.log
  - build/agent209/t229/v4/es_ex@foreign-rompath.log
  - build/agent209/t229/v4/es_ex@foreign-mame.log
  - build/agent209/t229/asrun/es_ex_version.txt
  - build/agent209/t229/asrun/es_ex_vs_tar.txt
  - build/agent209/t229/asrun/es_ex_files.txt
  - build/agent209/t229/asrun/q1_doc_excerpt.txt
  - build/agent205/t229/f3_es_ex/cap9/REPORT.md
  - build/agent209/t229/asrun/f3_set.txt
  - build/agent209/t229/asrun/f3cap_set.txt
  - build/agent205c/t229/REPORT.md
  - build/agent209/t229/sheetmap/cmp_f3_full.py
  - build/agent209/t229/sheetmap/cmp_f3_full.out
  - DECISIONS_HISTORY.md.lines-8270-8280 (lines 8270-8280 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer in the questions doc — the sheets of")
  - DECISIONS_HISTORY.md.lines-8300-8306 (lines 8300-8306 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer covered both the first sheets and th")
  - DECISIONS_HISTORY.md.lines-7442-7500 (lines 7442-7500 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-20 (14z-205c) — #229 Q1: Bulleta's and Lei-Lei's guard cancels, Aulbath's Direct Sci")
  - DECISIONS_HISTORY.md.lines-7590-7597 (lines 7590-7597 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-21 (14z-205c) — #229's two re-rigged sheets are correct; #229 stays open for Q2")
