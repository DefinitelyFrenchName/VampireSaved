THE PACKET

Decision kind: expectation
Subject: 14z-181 #136: Donovan's and Pyron's guard cancels rigged (donovan_15, pyron_7) and frozen — move_naming (+10 lines each), move_parity_events (526 events of 32 parts), move_parity_attribution (DMG-OPEN on both defense tables, #161's residual generalised and then measured on a legacy pair: vsavj 12 / vs2 11 on Victor), x2b7ef4_reach_m18 (+2 rows) — the second packet, after run 157's findings (the threshold byte, the capture, the legacy measurement)
Claim (the working agent's sentence): Donovan's and Pyron's guard cancels — the #136 census item "Donovan's and Pyron's guard cancels ... measured ours-vs-native nowhere" — are rigged, named and parity-measured: tools/name_moves.py gains DONOVAN["15"] and PYRON["7"] (ten events each, templated on the Phobos recipes that FIRED Reflect Wall on native — P2 Demitri's 5HP blocked at a near pin, back held to hit+1, 623+button from hit+2 — for LP/MP/HP/LK/MK/HK/PP, a pre-hit buffered variant, a P2-HK variant and a no-block control), the two rigs generated and committed; on native vs2 the naming gate reads Ifrit Sword a2:0x2d/0x2e/0x2f and Zodiac Fire a2:0x2e/0x2f/0x30 (+ the tail a2:0x35) by punch strength after the block (a:0x13) and blockstun (b:0x0c) chains, PP the LP version on both, a kick in blockstun cancelling nothing (block only), the no-block control a hit (b:0x05) — test_move_naming re-frozen for both tenants (+10 lines each, no other line changed) and verified; tests/audit_move_parity.sh re-frozen ALL=1 (526 events of 32 parts, was 506 of 30) and verified with its four controls firing: every guard-cancel row IDENT on both legs and two DIFF rows per tenant, both a hit TAKEN (the buffered variant's pre-hit frames, the no-block control): P1's HP alone, +6, 12 native / 13 ours on Donovan and on Pyron — #161's residual (Phobos 11/12) on a second and third tenant with BOTH tables the damage chain indexes by the victim's id already vs2's on the build (the 32-byte curve row AND the rally-threshold byte, measured for 0x10, 0x13 and 0x11 against build/out/vsav2_data.bin: all equal, thresholds 0x28/0x30/0x30), so tools/move_parity_attribution.py's Phobos-only class is generalised (DMG-OPEN: the same signature on Donovan or Pyron with both tables already vs2's, the check per tenant over curve row and threshold byte) and the attribution table re-frozen (161 rows, no OTHER, no UNATTRIBUTED) and verified twice with its no-ablation control firing; AND the +1 was then measured where no port is in the loop — Demitri's 5HP on VICTOR, real picks on pristine vsavj and pristine vsav2 at RNG pins 0000/1234/5a5a, reads 12 on vsavj and 11 on vs2, two hits per leg on the same frames, Victor's rows byte-identical between the games — promoted into tests/audit_phobos_dmg_residual.sh as the frozen `legacy` rows (tests/replays/judge/04_demitri_5hp_victor.rpl) with a `legacy-same` control (vsav2's step in vsavj's place must fail the frozen compare), frozen, verified, both modes at FAIL — so the residual is the two ENGINES' damage pipelines, put to the maintainer under STATE "Decisions pending" as a recommendation to close #161 as not-ours; tests/audit_lag_budget.sh reads no new zero-pass frame on either part with its lag-planted control firing; tests/audit_x2b7ef4_reach_m18.sh gains both parts' rows (0 hits) frozen and verified; the move lists carry the measurement; the finding is posted on #161 (the comment as GitHub shows it is an artifact); a capture of Donovan's Ifrit Sword guard cancel on both legs (event 0 of donovan_15, +0..+60) was produced and sent to the maintainer AFTER the measurement, its delivery id recorded, their read not yet given — the move-list notes state chains entered and HP steps read from RAM, and no visual conclusion is drawn. NOT tested: whether the guard cancel's ES version exists for these two (PP gave the LP version, as for Phobos), the guard cancel from a jumping block or against a kick, the meter/stock cost of the guard cancel (no stock poke, as the Phobos parts that fired), the guard cancel's DAMAGE when it lands (P2's HP is compared as its change from the previous sample — every gc row read IDENT on that too, but the moves whiff at the far spacing after the block push and no gc hit was staged); the DMG-OPEN attribution rests on the row comparison the tool makes from the build's own data view against build/out/vsav2_data.bin at the vsavj/vs2 table addresses (the 14z-170 rows) and on the events table's p1hp step — the mechanism of the +1 — WHERE in vsavj's pipeline the point enters — is not measured (and under 'vanilla wins ties' no fix would follow); the legacy pair is ONE attacker and one victim (Demitri's 5HP on Victor), so 'the two engines differ by +1 on every hit' is not shown, only on this hit; the parity gates' per-frame level and RNG pins are the shared equalised input (accepted in writing at runs 153-156, before the maintainer); the new parts' rigs were tuned in one pass — the Phobos template fired on the first try for both, so no spacing was searched.
Artifacts (read every one, in full):
  - build/agent181/name_moves_gc_14z181.diff
  - tests/replays/naming/donovan_15.json
  - tests/replays/naming/pyron_7.json
  - build/agent181/move_naming_gc_run1.log
  - build/agent181/move_naming_gc_freeze.log
  - build/agent181/move_naming_gc_verify.log
  - build/agent181/move_naming_gc_14z181.diff
  - build/agent181/move_parity_gc_freeze.log
  - build/agent181/move_parity_gc_verify.log
  - build/agent181/move_parity_events_gc_14z181.diff
  - build/agent181/attribution_tool_14z181.diff
  - build/agent181/attribution_gc_freeze3.log
  - build/agent181/attribution_gc_verify2.log
  - build/agent181/move_parity_attribution_gc_14z181.diff
  - build/agent181/attr_gc_rows.tsv
  - build/agent181/lag_budget_gc.log
  - build/agent181/x2b7ef4_reach_gc_freeze.log
  - build/agent181/x2b7ef4_reach_gc_verify.log
  - build/agent181/moves_toml_gc_14z181.diff
  - build/agent181/issue161_posted.txt
  - build/agent181/cap_gc_donovan_ifrit.png
  - build/agent181/captures_sent_14z181.txt
  - build/agent181/residual_gate_14z181.diff
  - build/agent181/residual_table_14z181.diff
  - tests/replays/judge/04_demitri_5hp_victor.rpl
  - build/agent181/residual_legacy_freeze.log
  - build/agent181/residual_legacy_verify.log
  - build/agent181/residual_mode_residual-gone.log
  - build/agent181/residual_mode_legacy-same.log
  - tests/expected/move_naming_huitzil.txt
  - tests/rulecheck/runs/2026-09-25-157/verdict_real.txt
  - build/agent181/resolve157.txt
  - docs/project/tables/defense_rows.md.lines-1-40 (lines 1-40 of docs/project/tables/defense_rows.md)
  - tests/audit_move_parity.sh.lines-160-200 (lines 160-200 of tests/audit_move_parity.sh)
  - tools/move_parity_attribution.py.lines-140-215 (lines 140-215 of tools/move_parity_attribution.py)
  - STATE.md.lines-201-232 (lines 201-232 of STATE.md)
