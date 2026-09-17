THE PACKET

Decision kind: expectation
Subject: freeze tests/expected/move_parity_events.tsv (per-event verdicts, 506 events, pin frames excluded) and tests/expected/same_data_p2.tsv (0 of 12 same-data, exclusions stated) — corrected after run 24
Claim (the working agent's sentence): Two expectations are frozen at 14z-164 under the maintainer's ruling of 2026-09-17 (DECISIONS_HISTORY.md "Ruled 2026-09-17 (14z-164)", propositions 1 and 2): (A) tests/expected/move_parity_events.tsv — tests/audit_move_parity.sh now judges every EVENT of the 30 naming-rig parts of the three tenants (27 parts the per-part gate ran plus Donovan's hit/block parts 9-11) in its own window, ours (build/m3b_merged26) vs native vsav2, both legs real cursor picks, speed level 6 and the RNG pinned as before, over the tenant's ten fields plus the meter fraction RAM:$FF850A and Victor's HP RAM:$FF8850, with the four cumulative fields (meter, both HPs, stock) compared as their change from the previous sample and the rig's own pin frames excluded per field, and every "in DF" event asserted in Dark Force on both legs — the freeze reads 506 events: 377 IDENT, 103 DIFF, 25 NOT-IN-DF, 1 VOID (the zero-length "P2 blocks" setup event of donovan_11), and it REPLACES the per-part move_parity.tsv (27 rows, deleted) whose rule left 103 events unjudged; (B) tests/expected/same_data_p2.tsv — tests/test_same_data_p2.sh freezes, for the 12 legacy ids both games carry, tools/audit_same_data_p2.py's verdict that 0 of 12 carry the same character data on vsavj and vsav2 (bank value rows, every anim node's resolved boxes and attack record over tables a/a2/b/c/proj, the defense-curve row) and which chains differ per table, with Demitri (table a same; b:0x10/0x71/0x74, c:0x2e/0x2f) and Bishamon (a:0x1d/0x3e, b:0x10/0x74) the nearest for a victim role and Victor's b:0x00-0x05 hitstun head hurtbox retuned on vs2. NOT TESTED: (A) run 2026-09-17-24 of this packet found the cumulative-field comparison turned the rig's own periodic HP pin into a DIFF at the pin frame (pyron_4 Cosmo Disruption [KK held] +50); the comparator now compares cumulative fields as their change from the previous sample with the frames the rig itself pins them (its P2 HP pin every 400 frames, its stock poke, from the schedule json) excluded per field, the table was re-frozen and verified (freeze3, verify3: 377 IDENT, 103 DIFF, 25 NOT-IN-DF, 1 VOID; that row now reads +167 and its [PP held] twin +156, the genuine 2-versus-4-hit difference); (A) was frozen from one run and its verify run is the second run of the same rig on the same host (run-to-run determinism of the legs, not an independent measurement); a DIFF row's ATTRIBUTION (which side, which mechanism) is not part of the freeze — a DIFF is frozen as measured and the re-labelled table on GitHub #136 is the only attribution, itself unverified by capture; 30 of the 103 DIFF rows differ first on the meter within the window and the meter's mechanism is not root-caused; a window IDENT after an earlier DIFF is bit-identical in that window but its coupling to the earlier DIFF is unmeasured (coupled column); the NOT-IN-DF threshold (90% of the window's frames with the flag up) is a chosen number; the two controls (no-translation, unpinned-level) prove the comparator sees the placement translation and the level pin, not that any DIFF is the tenant's rather than Victor's; P2 is still Victor; the rig's per-event X pins reach the compared x on both legs by the gate's design (agreement on a pinned frame is by construction), and the P2 HP pin and stock poke are now excluded from the cumulative comparison on their frames, which is the only handling of them; (B) compares data only — not compared, stated per row in the frozen table: the 21 code_ptr rows (the character's own routines), the 19 auto rows of the bank map (kind unknown; a differing auto row is counted in its own column, 10 of 12 characters have at least one, and it is never classed as data or pointer), and five data_ptr rows the tool does not decode (capture_kf_ptr, tail_data_ptr, ai_script_0-3); the projectile chains are resolved through the projectile hitbox tables since run 24 (Bulleta's proj count fell from 22 to 1); a "same-data" verdict would cover a standing, hit P2 and never the character as an attacker, the chain walker's and hitbox reader's decodings are trusted as instruments (their own gates: test_anim_node_walk, test_hitbox_encoding) and the same-data verdict for a chain rests on the fields those decoders expose (duration, flags, shadow, script-op bytes, sfx, link, resolved boxes and record content) with the hit id and sprite pointer excluded; its self-compare control proves the audit reads SAME-DATA when handed one image twice, not that a real cross-game difference of a kind the decoders do not expose would be seen. No behavioural conclusion about how any move plays is drawn by either freeze.
Artifacts (read every one, in full):
  - tests/audit_move_parity.sh
  - tools/move_parity.py
  - tests/expected/move_parity_events.tsv
  - tests/test_same_data_p2.sh
  - tools/audit_same_data_p2.py
  - tests/expected/same_data_p2.tsv
  - build/gates_14z164/move_parity_freeze3.log
  - build/gates_14z164/move_parity_verify3.log
  - build/gates_14z164/move_parity_ctl_notrans3.log
  - build/gates_14z164/move_parity_ctl_unpinned3.log
  - build/move_parity_census_14z164/same_data_p2.txt
  - build/move_parity_census_14z164/same_data_detail.py
  - build/move_parity_census_14z164/same_data_detail.txt
  - build/move_parity_census_14z164/p2_state_classify.py
  - build/move_parity_census_14z164/p2_state_classify.txt
  - tests/expected/PROVENANCE.md.lines-77-77 (lines 77-77 of tests/expected/PROVENANCE.md)
  - DECISIONS_HISTORY.md.lines-30-52 (lines 30-52 of DECISIONS_HISTORY.md)
  - docs/project/tables/defense_rows.md.lines-1-12 (lines 1-12 of docs/project/tables/defense_rows.md)
  - tools/name_moves.py.lines-1-140 (lines 1-140 of tools/name_moves.py)
  - tools/name_moves.py.lines-640-720 (lines 640-720 of tools/name_moves.py)
  - build/manifest/bank_map.toml.lines-1-80 (lines 1-80 of build/manifest/bank_map.toml)
  - tests/replays/naming/donovan_1.json
  - tests/replays/naming/donovan_10.json
  - tests/replays/naming/donovan_11.json
  - tests/replays/naming/donovan_12.json
  - tests/replays/naming/donovan_13.json
  - tests/replays/naming/donovan_14.json
  - tests/replays/naming/donovan_2.json
  - tests/replays/naming/donovan_3.json
  - tests/replays/naming/donovan_4.json
  - tests/replays/naming/donovan_5.json
  - tests/replays/naming/donovan_6.json
  - tests/replays/naming/donovan_7.json
  - tests/replays/naming/donovan_8.json
  - tests/replays/naming/donovan_9.json
  - tests/replays/naming/huitzil_1.json
  - tests/replays/naming/huitzil_10.json
  - tests/replays/naming/huitzil_2.json
  - tests/replays/naming/huitzil_3.json
  - tests/replays/naming/huitzil_4.json
  - tests/replays/naming/huitzil_5.json
  - tests/replays/naming/huitzil_6.json
  - tests/replays/naming/huitzil_7.json
  - tests/replays/naming/huitzil_8.json
  - tests/replays/naming/huitzil_9.json
  - tests/replays/naming/pyron_1.json
  - tests/replays/naming/pyron_2.json
  - tests/replays/naming/pyron_3.json
  - tests/replays/naming/pyron_4.json
  - tests/replays/naming/pyron_5.json
  - tests/replays/naming/pyron_6.json
  - tests/lib/decrypt_cache.sh.lines-1-40 (lines 1-40 of tests/lib/decrypt_cache.sh)
  - tests/rulecheck/runs/2026-09-17-24/verdict_real.txt
