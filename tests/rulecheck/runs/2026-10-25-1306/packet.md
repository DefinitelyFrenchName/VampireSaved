THE PACKET

Decision kind: expectation
Subject: #229: freeze tests/audit_vanilla_specials_a.sh's expectations (the 148-row identity map, the column verdicts, the game clocks) on pristine vsavj, for registration — after runs 2026-10-25-1302, -1303 and -1305 (run -1304 withdrawn unspawned)
Claim (the working agent's sentence): CLAIM: tests/expected/vanilla_specials_a.tsv (148 rows: tab, key, chain sequence, spawned types, P2 hits, facing), tests/expected/vanilla_specials_a_verdicts.tsv (the column verdicts against the workbook, the live-vs-derived tick agreement and the SHA-256 of the joined values, values outside the tree) and tests/expected/instr_gameclock/audit_vanilla_specials_a.tsv are the expectations of tests/audit_vanilla_specials_a.sh on the pristine vsavj ROM and may enter the tree as frozen: the gate's plain run on the Mac at 14z-209 prints tests/lib/pristine_vsavj.sh's rom, mame and rompath lines (ROMDIR all match against docs/checksums.txt; the vsavj fingerprint equal to the registry row; the analysed image and build/out's views equal to vsavj.zip decrypted afresh; MAME_ROMPATH unset, so the legs' tools/run_mame.sh -rompath is ROMDIR; the MAME the pin's release) and reads PASS with its ten declared controls FIRED in-gate, on the stock reference MAME (build/agent209/t229/v5/vanilla_specials_a.log) and again on the CPS-2 WIDE MAME a tier exports (build/agent209/t229/v5/wide_vanilla_specials_a.log); each of the ten as a CONTROL= mode exits 1 on a FAIL (build/agent209/t229/v5/vanilla_specials_a@*.log); every one of the 62 files the gate follows (its whole # FOLLOWS: block, directories expanded, and its expectations) was last modified before the first of those logs (build/agent209/t229/asrun/vanilla_specials_a_files.txt), each log is dated and the logs carry the two controls only the current version declares (build/agent209/t229/asrun/vanilla_specials_a_version.txt; tests/lib/controls.sh's vs_ctl_mode refuses an undeclared mode); the three files are whole-file equal to their members of the pre-edit backup tar (listed Oct 20 23:02-23:04) (build/agent209/t229/asrun/vanilla_specials_a_vs_tar.txt); today's code reproduces them, which is all the PASS shows about them; the identity rests on the maintainer's read of F1's capture sheets — the doc's Q1 table names build/agent205/t229/f1_specials_a/cap9/sheets/ (build/agent209/t229/asrun/q1_doc_excerpt.txt), which F1's report draws with sheet9.py from cap9/frames.json (build/agent205/t229/f1_specials_a/cap9/REPORT.md) — and of the re-rigged Tsuji Hayate sheet BI^_9.png (DECISIONS_HISTORY.md 7589-7596), which the 14z-205c report draws, with BI_9.png (the three 236P-from-neutral rows, also on F1's original sheets), from build/agent205c/t229/f1cap/cap9/frames.json (build/agent205c/t229/REPORT.md:35-38; its 6 events, 3+3); the frozen map is the map those sheets were drawn from: it names each of the 151 events of the two sheet files (named, with their counts, in cmp_f1.out) by the chain the sheet carries, every one of its 148 rows on a sheet (build/agent209/t229/sheetmap/cmp_f1.py, cmp_f1.out) — lineage, not an independent identity, since the sheets' chain labels were written by the same tools/specials_a_rigs.py analysis as the map; the identity is the maintainer's reading of the images. NOT TESTED: the gate header's own list (tests/audit_vanilla_specials_a.sh:28-33): the characters forced by the early-window poke and positions and P2's HP re-pinned before each event (the ROM is pristine, the RAM is not), one victim (Victor), one speed level, one rig cadence per move (BI's Kienzen 623P never fires, declared open), a projectile's own frames and moves that connect at the whiff pin (their timing UNCOMPARABLE), FBNeo, the game clock a witness modulo 256 frames; and besides it: that the verdicts are right against the community (the page's classifier over this run's values and the workbook; the workbook's identity is not printed by the gate — its sha1 on the Mac is in build/agent209/t229/asrun/workbook.txt); any host but the Mac; that the pinned MAMEs were built from the pinned commit (their -version reads the release only, tests/lib/mame_ident.sh); a romset that passes docs/checksums.txt but differs elsewhere; that each sheet tile shows the gate's own measured event (the tiles come from separate capture legs of the same rig, snap9.sh, and only their snapshot count was checked: build/agent205/t229/f1_specials_a/cap9/REPORT.md:7, :15); the logs carry no script hash of their own; the control modes ran on the stock build only; the legs' teardown segfaults (exit 139, #320) the gate accepts when every output line is present.
Artifacts (read every one, in full):
  - tests/audit_vanilla_specials_a.sh
  - tests/lib/pristine_vsavj.sh
  - tests/lib/mame_ident.sh
  - tests/lib/controls.sh
  - tools/run_mame.sh
  - tests/expected/vanilla_specials_a.tsv
  - tests/expected/vanilla_specials_a_verdicts.tsv
  - tests/expected/instr_gameclock/audit_vanilla_specials_a.tsv
  - build/agent209/t229/v5/vanilla_specials_a.log
  - build/agent209/t229/v5/wide_vanilla_specials_a.log
  - build/agent209/t229/v5/vanilla_specials_a@drift-clock.log
  - build/agent209/t229/v5/vanilla_specials_a@first-frame-skip.log
  - build/agent209/t229/v5/vanilla_specials_a@dead-tap.log
  - build/agent209/t229/v5/vanilla_specials_a@swapped-chains.log
  - build/agent209/t229/v5/vanilla_specials_a@hidden-normal.log
  - build/agent209/t229/v5/vanilla_specials_a@sheet-hits.log
  - build/agent209/t229/v5/vanilla_specials_a@foreign-image.log
  - build/agent209/t229/v5/vanilla_specials_a@foreign-romset.log
  - build/agent209/t229/v5/vanilla_specials_a@foreign-rompath.log
  - build/agent209/t229/v5/vanilla_specials_a@foreign-mame.log
  - build/agent209/t229/asrun/vanilla_specials_a_version.txt
  - build/agent209/t229/asrun/vanilla_specials_a_vs_tar.txt
  - build/agent209/t229/asrun/vanilla_specials_a_files.txt
  - build/agent209/t229/asrun/workbook.txt
  - build/agent209/t229/asrun/q1_doc_excerpt.txt
  - build/agent205/t229/f1_specials_a/cap9/REPORT.md
  - build/agent205c/t229/REPORT.md
  - build/agent209/t229/sheetmap/cmp_f1.py
  - build/agent209/t229/sheetmap/cmp_f1.out
  - DECISIONS_HISTORY.md.lines-8269-8279 (lines 8269-8279 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer in the questions doc — the sheets of")
  - DECISIONS_HISTORY.md.lines-7589-7596 (lines 7589-7596 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-21 (14z-205c) — #229's two re-rigged sheets are correct; #229 stays open for Q2")
