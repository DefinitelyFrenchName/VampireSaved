THE PACKET

Decision kind: expectation
Subject: #229: freeze tests/audit_vanilla_pursuits.sh's expectations (the 75-event pursuit map with its signature hashes, the connect-band edges, the game clocks) on pristine vsavj, for registration — after run 2026-10-25-1313
Claim (the working agent's sentence): CLAIM: tests/expected/vanilla_pursuits.tsv (75 events: sheet, event, started, flag, ES stock spent, chain_as_pair, and SHA-256 signatures of the numeric and engine-tick figures, never the figures), tests/expected/vanilla_pursuit_bands.tsv (each pursuit's connect-band edges on the gate's own knockdown rig) and tests/expected/instr_gameclock/audit_vanilla_pursuits.tsv are the expectations of tests/audit_vanilla_pursuits.sh on the pristine vsavj ROM and may enter the tree as frozen: the gate's plain run on the Mac at 14z-209 prints tests/lib/pristine_vsavj.sh's rom, mame and rompath lines (ROMDIR all match against docs/checksums.txt; the vsavj fingerprint equal to the registry row; the analysed image and build/out's views equal to vsavj.zip decrypted afresh; MAME_ROMPATH unset, so the -rompath tools/run_mame.sh hands MAME is ROMDIR; the MAME the pin's release; the gate's legs call tools/run_mame.sh, tools/run_replay_guarded.sh (which launches through tools/run_mame.sh, its line 45, with no MAME_BIN or rompath of its own) or tests/lib/instr_align.sh's reference and staging legs (which launch through tools/run_mame.sh, its lines 66 and 128, a rompath '-' meaning ROMDIR, MAME_BIN from the leg's env word or else the environment; this gate writes its legs' env words with no MAME_BIN and its manifest rows with rompath '-', tests/audit_vanilla_pursuits.sh:250, :254, :279)) and reads PASS with its thirteen declared controls FIRED in-gate, on the stock reference MAME (build/agent209/t229/v6/vanilla_pursuits.log) and again on the CPS-2 WIDE MAME a tier exports (build/agent209/t229/v6/wide_vanilla_pursuits.log); each of the thirteen as a CONTROL= mode exits 1 on a FAIL (build/agent209/t229/v6/vanilla_pursuits@*.log); every one of the 141 distinct files the gate follows (its whole # FOLLOWS: block with directories expanded, its expectations, and what those files source or import, transitively) was last modified before the first of those logs (build/agent209/t229/asrun/vanilla_pursuits_files.txt), each log is dated and the logs carry the two controls only the current version declares (build/agent209/t229/asrun/vanilla_pursuits_version.txt; tests/lib/controls.sh's vs_ctl_mode refuses an undeclared mode); the three files are whole-file equal to their members of the pre-edit backup tar (listed Oct 20 01:03-02:39) (build/agent209/t229/asrun/vanilla_pursuits_vs_tar.txt); today's code reproduces them, which is all the PASS shows about them; the identity rests on the maintainer's read of F6's capture sheets — the Q1 answer covered both sheet versions ("Both", DECISIONS_HISTORY.md 8301-8308; the answer itself 8271-8282), the 9-tile remakes named by the doc's table (build/agent209/t229/asrun/q1_doc_excerpt.txt) and confirmed for all 15 characters (DECISIONS_HISTORY.md 7404-7442), the 14z-194 sheets before them (DECISIONS_HISTORY.md 704-719) — drawn by cap9.py sheet from cap9/plan.json, which it reads, the plan last written before every one of the 15 sheets and unchanged since, the capture legs' P2 HP equal to the trace leg's at all 711 snap frames (build/agent209/t229/asrun/f6_set.txt; build/agent205/t229/f6_pursuits/cap9/REPORT.md); the frozen map is the map those sheets were drawn from: for each of the 75 events its started column, ES stock spent and chain_as_pair equal what the sheet's row header carries, and the compare's three perturbed-copy controls each FIRED (build/agent209/t229/sheetmap/cmp_f6.py, cmp_f6.out) — lineage, not an independent identity, the plan having been written from the same gate run's analysis; the identity is the maintainer's reading of the images. NOT TESTED: the gate header's own list (tests/audit_vanilla_pursuits.sh:36-41): the characters forced by the early-window poke, positions, P2's HP and P1's stock and meter re-pinned before each event (the ROM is pristine, the RAM is not), one offset per character and button, the 8K and 8KK band edges not frozen, the victim Victor (Demitri for Victor) only, recovery, FBNeo, what the sheet's active counts, a record staged at the object-hit applier not read; and besides it: the flag column, the signature hashes' columns and the band file, which no sheet shows (the row headers carry row, input, chain, pursuit / NO pursuit, stock spent, falls and hits landed) (the band edges are the rig's geometry); that each PNG's pixels show its plan (the link is the tool's reading and the files' dates); that the 14z-205 capture legs and gate run behind the sheets loaded pristine vsavj on the pinned MAME (the provenance check postdates them); any host but the Mac; that the pinned MAMEs were built from the pinned commit (their -version reads the release only, tests/lib/mame_ident.sh); a romset that passes docs/checksums.txt but differs elsewhere; the logs carry no script hash of their own; the control modes ran on the stock build only.
Artifacts (read every one, in full):
  - tests/audit_vanilla_pursuits.sh
  - tests/lib/pristine_vsavj.sh
  - tests/lib/mame_ident.sh
  - tests/lib/controls.sh
  - tools/run_mame.sh
  - tools/run_replay_guarded.sh
  - tests/lib/instr_align.sh
  - tests/expected/vanilla_pursuits.tsv
  - tests/expected/vanilla_pursuit_bands.tsv
  - tests/expected/instr_gameclock/audit_vanilla_pursuits.tsv
  - build/agent209/t229/v6/vanilla_pursuits.log
  - build/agent209/t229/v6/wide_vanilla_pursuits.log
  - build/agent209/t229/v6/vanilla_pursuits@drift-clock.log
  - build/agent209/t229/v6/vanilla_pursuits@first-frame-skip.log
  - build/agent209/t229/v6/vanilla_pursuits@es-no-stock.log
  - build/agent209/t229/v6/vanilla_pursuits@control-as-pursuit.log
  - build/agent209/t229/v6/vanilla_pursuits@foreign-record.log
  - build/agent209/t229/v6/vanilla_pursuits@class-raw.log
  - build/agent209/t229/v6/vanilla_pursuits@tick-dropped.log
  - build/agent209/t229/v6/vanilla_pursuits@band-moved.log
  - build/agent209/t229/v6/vanilla_pursuits@phantom-record.log
  - build/agent209/t229/v6/vanilla_pursuits@foreign-image.log
  - build/agent209/t229/v6/vanilla_pursuits@foreign-romset.log
  - build/agent209/t229/v6/vanilla_pursuits@foreign-rompath.log
  - build/agent209/t229/v6/vanilla_pursuits@foreign-mame.log
  - build/agent209/t229/asrun/vanilla_pursuits_version.txt
  - build/agent209/t229/asrun/vanilla_pursuits_vs_tar.txt
  - build/agent209/t229/asrun/vanilla_pursuits_files.txt
  - build/agent209/t229/asrun/q1_doc_excerpt.txt
  - build/agent205/t229/f6_pursuits/cap9/REPORT.md
  - build/agent209/t229/asrun/f6_set.txt
  - build/agent209/t229/sheetmap/cmp_f6.py
  - build/agent209/t229/sheetmap/cmp_f6.out
  - DECISIONS_HISTORY.md.lines-8271-8282 (lines 8271-8282 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer in the questions doc — the sheets of")
  - DECISIONS_HISTORY.md.lines-8301-8308 (lines 8301-8308 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-25 (14z-209) — #229 Q1: the maintainer's answer covered both the first sheets and th")
  - DECISIONS_HISTORY.md.lines-7404-7442 (lines 7404-7442 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-20 (14z-205b) — #229: Q3 and Q4 answered in the questions doc; Q1 confirmed for the ")
  - DECISIONS_HISTORY.md.lines-704-719 (lines 704-719 of DECISIONS_HISTORY.md: its INDEX entry "## Read 2026-10-07 (14z-194) — #229: the pilot's three pursuits are each character's pursuit and ES ")
