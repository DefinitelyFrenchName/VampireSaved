THE PACKET

Decision kind: recommendation
Subject: #345, #346, #356, #357, #358 and #363 closed done against the M26 release published from the freeze commit bb10ce97 (14z-222), after runs 2026-11-07-1697 to -1702
Claim (the working agent's sentence): #345, #346, #356, #357, #358 and #363 can close done on the M26 release, with the closing comments closing_345.md, closing_346.md, closing_356.md, closing_357.md, closing_358.md and closing_363.md. Each issue's condition is met: #345, #346 and #356 close with the release that ships M25 (their 14z-220 comments), M25's changes are in M26 and M25 was never published; #357 and #363 close when the freeze holding them ships (their 14z-221c comments), and they are frozen in M26; #358 closes with #363 by the maintainer's ruling (DECISIONS_HISTORY.md, ruled 2026-11-05), on the 14z-221c sheets by the maintainer's answer "Close on the 221c sheets" (maintainer_words.txt), the sheets' build m34x carrying the released program 2c594c29 (registry.tsv's merged-m26 row). The release is published: upload.log shows the GitHub release on freeze/merged-m26 created, its 9 assets uploaded and re-verified from GitHub, and merged-m24's 9 zips pruned; closures_evidence.txt shows freeze/merged-m26 resolving to bb10ce97 locally and on origin, the release neither draft nor prerelease with 9 assets, merged-m24 holding 0 assets, and the jtcores fork holding the pinned commit e11729fe. The published zips are the commit's release: zips_vs_tree.txt (the 9 zips downloaded back) reads 241 tracked files equal, 61 binaries equal to their BINARY.txt rows, 6 BINARY.txt differing only by the asset line, 0 mismatches; applied_all9.txt shows each of the 9 packages building merged-m26 de548a9e mark M26, one set, its 25 patched members equal to build/m3b_merged34; build_identity.txt shows the build each host's release runs judged is that set (each run's MERGED fingerprint equal at start and end and to its host's build/m3b_merged34 now, the three hosts' 25 members equal, the fingerprints differing by the zip container only); the three comparator controls each fail (closures_evidence.txt). Every release run at bb10ce97 is green on what it judges: ERIS's release emulator run PASS 458 SKIP 4 FAIL 0 with 260 control rows, the 4 SKIPs host-bound and each PASS with controls on the Mac and PILOT at the same commit; the Mac's parity and MiSTer lane PASS; the static release tier PASS 240 SKIP 1 FAIL 0 with 601 controls honoured, its SKIP the launcher's Windows half, PASS on ERIS, accepted by the maintainer (maintainer_words.txt). Each closing comment names the ticket's gates with their rows in ERIS's run and their controls (gate_rows.txt lists every named gate's rows and control rows from ERIS's run and the static tier, and audit_merged_legacy's build/merged1 carrying merged-m26's program 2c594c29 at bb10ce97), the gates' NOT COVERED items as their headers state them (the header ranges given), and what was not tested at this release; #358's says no capture was framed on Cecil and no gate compares the figure. #345's and #346's list audit_merged_legacy among their gates and give every gate's NOT COVERED items as its header states them, or say the header names none (audit_pass_overrun, audit_move_parity_attribution); every multi-gate closing (#356, #357, #363) does the same for each of its gates (audit_effect_class_rows names none; test_dead_span's and test_dead_span_reach's "Stated, not tested" items are quoted, the run-time reach of an accepted base or row to #363's span among them; #363's closing gives test_dead_span_reach's measured verdicts for #363's span on the five builds from a re-run at HEAD, gate, table and tool unchanged since bb10ce97 (dead_span_reach_head.log: REACHED ONLY by row 0x4F on merged and Phobos, DEAD on the other three, judged-pairs 10), names its header's stale one-span text and that its 22 controls plant on #294's span only); audit_don_trail_nodraw's "MEASURED, not asserted" counts are named; #358's says the record does not show anyone reading Cecil as native's on the sheets, the maintainer's answer the basis.
Artifacts (read every one, in full):
  - build/agent222/m26/release/close/closing_345.md
  - build/agent222/m26/release/close/closing_346.md
  - build/agent222/m26/release/close/closing_356.md
  - build/agent222/m26/release/close/closing_357.md
  - build/agent222/m26/release/close/closing_358.md
  - build/agent222/m26/release/close/closing_363.md
  - build/agent222/m26/release/close/issue345.md
  - build/agent222/m26/release/close/issue346.md
  - build/agent222/m26/release/close/issue356.md
  - build/agent222/m26/release/close/issue357.md
  - build/agent222/m26/release/close/issue358.md
  - build/agent222/m26/release/close/issue363.md
  - build/agent222/m26/release/upload.log
  - build/agent222/m26/release/close/closures_evidence.txt
  - build/agent222/m26/release/close/zips_vs_tree.txt
  - build/agent222/m26/release/close/applied_all9.txt
  - build/agent222/m26/release/close/build_identity.txt
  - build/agent222/m26/release/close/gate_rows.txt
  - build/agent222/m26/release/close/maintainer_words.txt
  - build/agent222/m26/release/close/dead_span_reach_head.log
  - build/agent222/m26/release/close/dead_span_reach_at_bb10ce97.tsv
  - DECISIONS_HISTORY.md.lines-9772-9831 (lines 9772-9831 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted; A1b freezes in M25 with #3", and the entries after it up to line 9831)
  - tests/expected/registry.tsv.lines-201-201 (lines 201-201 of tests/expected/registry.tsv)
  - tests/audit_don_trail_nodraw.sh.lines-1-33 (lines 1-33 of tests/audit_don_trail_nodraw.sh)
  - tests/audit_don_speed_lines.sh.lines-1-36 (lines 1-36 of tests/audit_don_speed_lines.sh)
  - tests/audit_guard_orbs.sh.lines-1-40 (lines 1-40 of tests/audit_guard_orbs.sh)
  - tests/audit_beam_slide.sh.lines-1-44 (lines 1-44 of tests/audit_beam_slide.sh)
  - tests/audit_rng_forms.sh.lines-1-40 (lines 1-40 of tests/audit_rng_forms.sh)
  - tests/audit_move_parity.sh.lines-1-140 (lines 1-140 of tests/audit_move_parity.sh)
  - tests/audit_pass_overrun.sh.lines-1-44 (lines 1-44 of tests/audit_pass_overrun.sh)
  - tests/audit_move_parity_attribution.sh.lines-1-56 (lines 1-56 of tests/audit_move_parity_attribution.sh)
  - tests/audit_lag_budget.sh.lines-1-45 (lines 1-45 of tests/audit_lag_budget.sh)
  - tests/audit_merged_legacy.sh.lines-1-130 (lines 1-130 of tests/audit_merged_legacy.sh)
  - tests/audit_effect_class_rows.sh.lines-1-81 (lines 1-81 of tests/audit_effect_class_rows.sh)
  - tests/test_dead_span.sh.lines-1-44 (lines 1-44 of tests/test_dead_span.sh)
  - tests/test_dead_span_reach.sh.lines-1-58 (lines 1-58 of tests/test_dead_span_reach.sh)
