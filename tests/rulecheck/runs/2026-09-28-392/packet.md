THE PACKET

Decision kind: expectation
Subject: M21 freeze: the battery's reds attributed and re-frozen (placement +0x40, build rows, #159's parity and ring moves), and the static pins re-pinned
Claim (the working agent's sentence): Re-freeze the expectations the M21 freeze battery found moved, each attributed first. The battery ran on the M21 builds (build/emu_freeze_m21_p1 and build/emu_freeze_m21_mister, drivers emu_p1.driver.log and emu_mister.driver.log, whose headers name every build under test with its program fingerprint). Its result: 159 PASS and 11 FAIL in prereq/fbneo/mame, 2 PASS and 1 FAIL in MiSTer, no timeouts. The legacy oracle (audit_merged_legacy), audit_lag_budget, audit_pass_overrun, audit_walker_ghost, test_fbneo_legacy_oracle, test_dualtrack and test_wide_profile all PASS. Every red was re-run on the M20 build (build/rc185/m20ab/status.tsv): all 11 PASS there, so each red is M21's (battery_reds.txt has each red's M21 lines and its M20 verdict).
THE ATTRIBUTION, per red:
- (A) The merged placement shift (deltas_measurer.txt: 325 MOVED, 109 RELOCATED, every relocation target content-identical). Pyron's placed code and data moved +0x40.
  - audit_roster_pairings and test_tenant_pairings: Pyron's hitbox base 0x4ae8bc -> 0x4ae8fc. tests/expected/roster_pairings/bases.tsv is re-derived from the merged image's own table at PRG:0x0BD97A, data view (bases_derivation.txt). The same read reproduces all 19 merged-m20 rows and differs on merged-m21 in Pyron's row only.
  - audit_throw_registration, audit_df_modes, audit_df_field_readers_live and audit_reaction_class_live: only writer or reader PCs inside Pyron's code, each +0x40.
  - test_mister_prg_window: first_addr 4c1400 -> 4c1440 and max +0x40 (the relocated OBJ walker's placement); every counter unchanged.
- (B) Build identity only: audit_column_flash and audit_phobos_dmg_residual change one row, "ours build merged-m20 c707b25e" -> "merged-m21 a97d1ace".
- (C) #159's fix:
  - audit_move_parity_attribution VOIDs because donovan_3 event 6 now reads IDENT, where the frozen table had DIFF +1 x.
  - The full parity table (audit_move_parity ALL=1 on M21, parity/all_m21.log, parity/diff_m21.txt) differs from move_parity_events.tsv in exactly donovan_3 events 6-14. Events 6-10 go DIFF -> IDENT, events 11-13 lose their "after:6" coupling, and event 14 stays DIFF (DF-STOCK) without the coupling. No other of the 526 rows moves.
  - The frozen attribution named donovan_3:5, Killshread Summon (ES), P2-DISPLACEMENT, as the root of rows 6-10 (tests/expected/move_parity_attribution.tsv).
  - The freeze re-freezes move_parity_events.tsv and then move_parity_attribution.tsv.
- (D) audit_pyron_ring: the mash stream now agrees merged vs solo for the whole run (364 events), where merged-m20 diverges at f4742.
  - The move is attributed by measurement to #159 (ring/*.log): the #159-only probe (build/agent185/probe159/out, e4d712eb) agrees whole-run, and the #182-only probe (build/agent185/merged_182, f9f6f2fc) diverges at f4742 like merged-m20.
  - The gate is re-stated (pyron_ring_gate.diff): its mash onset 4741 -> None (whole-run), and its control onset-earlier, DEAD once nothing diverges, is replaced by stream-shifted.
  - The redesigned gate PASSes on M21, its mode FAILs, and it FAILs on M20 (ring/new_m21.log, new_m21_ctl.log, new_m20.log).
- (E) audit_defense_row_reads: its naming of Pyron's base follows bases.tsv, as in (A). Its suite leg's counts moved. Per replay (defreads_per_replay.txt: the suite leg run on merged-m20 and merged-m21 with the work dir kept, by a copy of the gate that differs only in keeping W and pinning REPO), 87 of the 88 replays read identical defense-table reads. The one that differs is 110_don_arcade_mash, a Donovan arcade run against the CPU (tenant content, no .masked spec), from f8394 on (1104 -> 1278 reads). No legacy replay moved. The same replay's self-frozen .sha1 moved in the suite freeze, donovan-m25 first differing frame 3183 (build/rc185/suite/carry_and_suite.txt).
THE STATIC PINS, re-pinned and passing:
- test_m3a_reproducible: every EXPECT and MANI line; the tree rebuilds all five bit-exact (m3a_repro.log).
- test_phasec_spaces: the stock twin (phasec.log).
- tests/expected/charmap_pages.sha256: the three HTML pages move by one line each, the build path; the anim pages are unchanged (charmap_html_diff.txt).
HOW: each gate's own FREEZE writer (or --freeze), then a plain verify run, then its CONTROL modes.
NOT TESTED:
- The mechanism by which #159's hook moves the mash ring event (the candidate is its added cycles on the shared facing resolver; not measured).
- The bitstream-cadence MiSTer gates (dropped by the romset cadence, as at M20).
- The out-of-scope rows (--scope all).
- Behaviour outside the corpus.
Artifacts (read every one, in full):
  - build/agent185/maintainer_queue_14z185.txt
  - build/agent185/m21/deltas_measurer.txt
  - build/rc185/emu_p1.driver.log
  - build/emu_freeze_m21_p1/results.tsv
  - build/rc185/emu_mister.driver.log
  - build/emu_freeze_m21_mister/results.tsv
  - build/rc185/m20ab/status.tsv
  - build/rc185/battery_reds.txt
  - build/rc185/bases_derivation.txt
  - build/rc185/parity/all_m21.log
  - build/rc185/parity/diff_m21.txt
  - tests/expected/move_parity_attribution.tsv
  - build/rc185/ring/build_agent185_merged_182.log
  - build/rc185/ring/build_agent185_probe159_out.log
  - build/rc185/ring/build_m3b_merged28.log
  - build/rc185/ring/build_m3b_merged29.log
  - build/rc185/ring/new_m21.log
  - build/rc185/ring/new_m21_ctl.log
  - build/rc185/ring/new_m20.log
  - build/rc185/pyron_ring_gate.diff
  - build/rc185/defreads_per_replay.txt
  - build/rc185/defreads/gate_keep.sh
  - build/rc185/suite/carry_and_suite.txt
  - build/rc185/m3a_repro.log
  - build/rc185/phasec.log
  - build/rc185/charmap_html_diff.txt
