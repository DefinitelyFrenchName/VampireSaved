# BUILD-DIR DECISION PACKAGE — 14z-101 (2026-08-21)

## RULED AND EXECUTED 14z-102 (maintainer, 2026-08-21)

**The ruling:** delete C + B2 + B3 + B4 + B1, plus the 14z-102 probe
duplicates (hui_probe_row31 / merged_probe_row31 / probe_window — each
bit-identical to a kept frozen build — and hui_probe_tint, a
one-line-delta rehearsal with its recipe in the records). Keep A1
(rolled to the m10 generation at the 14z-102 freeze), A2, A3, and the
m9 generation as the one-back safety net. **A4 is NOT bulk-ruled**: it
gets a pin-cleanup pass in a fresh session — retire/re-point each
stale reference first, then the dirs fall to zero-reference and are
deleted mechanically at the next census.

**STANDING POLICY adopted with the ruling:** at every freeze, the N-2
generation's build dirs are deleted (keep current + one back). That is
what prevents this package from regrowing.

**Executed:** 85 dirs (8.1 GB) moved to `../build_attic_14z102`
(REVERSIBLE — outside the repo; delete the attic after the maintainer's
next playtest cycle confirms nothing is missed). build/ 13 GB -> 4.4 GB.
**DELETED 2026-08-22 (14z-106, maintainer-ruled):** two playtest cycles
(14z-103, 14z-105) passed green with nothing missed; the attic is gone
and its contents are recoverable only via git history + freeze tags.
**Second attic, `../build_attic_14z105`** (created 14z-106, REVERSIBLE):
the 14z-105 rehearsal probes `merged_probe_w6` (155 MB) +
`probe_stock_w6` (71 MB) — merged-m6 is bit-for-bit the first, recorded
in HANDOFF / patch_notes / test_m3a_reproducible. Same deletion rule.
Verification on the pruned tree: `run_all_static --strict` **PASS
97/0/0 with ZERO skips** (strict makes a lost input fatal — nothing
anywhere depended on a moved dir) + the M2 battery re-run green.
Tracked metadata inside the moved dirs is deleted from the working tree
in the same commit; it remains recoverable from git history and the
freeze tags, which is the B4 classification's meaning.

## A4 PIN-CLEANUP PASS EXECUTED 14z-103 (2026-08-21)

Every A4 reference was read for intent and dispositioned ("re-point the
ones that meant 'the current build', leave the ones that meant 'that
build'" — the rot gate's own rule). Verification: every re-pointed gate
was RUN GREEN on its new default in-session (the emulator audits
included); `test_build_ref_rot.sh` PASS; the full strict static tier at
the close.

**Re-pointed to the m10/m19/m13/merged-m5 generation (the dirs fall to
zero-live-reference and go mechanically at the next census):**
hui43 (7 gates + 3 shared files), hui42/hui40 (region_overlap trio +
prose), hui37/hui38 (trap audits), hui31 (gfx_chain -> hui32, the A2
pipeline input; audit_gfx_merged.py --build-h likewise), don_m7,
m3b_merged + m3b_merged9 (8 gates + identity/member gates), m5_stock ->
m5_stock5 (dualtrack STOCK + battery leg + wide_render_content +
tenant_row_owner), m5_wide -> don_m10 (dualtrack WIDE default only; the
dir itself stays A2), pyron17/pyron25/pyron26-default/pyron27,
don_m5-defaults (voice_borrow, gfx_menus pair, legacy_pairings trio,
frozen_rompath_guard SRC -> don_m10). `test_region_overlap` section 5
constants re-measured on the new trio (2012 -> 2033, unique 13 -> 14 =
the #109 row-31 huitzil-only region; control's sed re-anchored).
`audit_flicker_attribution` re-derived: its mask pin named the REMOVED
donovan-m7 set dir, so it had been SKIPping quietly — now resolves the
set from the build fingerprint (the #96 mechanism) and PASSES on m10.
`test_m2a_flicker_gate` SET pin rolled to donovan-m10-stock.

**Kept as DELIBERATE EVIDENCE PINS (reclassify A4 -> A3; annotated in
the gates themselves):** `don_m5` (audit_walker_repoint's REQUIRED
un-relocated negative control — nothing newer can serve), `pyron26`
(test_decode_stage_banners' frozen #92 defect carrier, with hui41).

**Reclassified OPERATIONAL (gates build into them; not stale pins):**
`donovan` (m2a stage 1-4 pipeline output), `donovan_stage4_gate` (the
stage-4 gate's own build target), `hui4` (regenerable stage-4 dir; its
gate prints the rebuild recipe on absence).

**Zero-live-reference already (prose/registry/README mentions only):**
probe_window, hui26, don_m8, m5_stock2, m5_stock3, pyron16, pyron18,
pyron22, hui9/hui11/hui12/hui13/hui14/hui17/hui20 (run_hui_behavior's
PING-ladder history), probe_104 (its stale "fix NOW STAGED" comment
corrected to SHIPPED-14z-99).

**Found by the pass, beyond the pins:**
- GitHub #110: audit_fg_damage + audit_pool_free_byte RED on every
  build since 14z-87 (bisected merged6 PASS / merged7 FAIL on attic
  dirs); both annotated known-red, constants not absorbed.
- audit_legacy_pairings surfaced four LEGACY-verdict replays on
  self-frozen .sha1 (94/103/105/106 — all authored after its last run):
  promoted to `window vsavj/masked-v2 889 2091` on all three sets
  (measured; the ratified select-window class), except 103 on the
  hui/pyron sets (picks the unbacked cell 0x13, no vanilla oracle —
  .legacy-exempt per the 61/62 precedent) and 103 on donovan-m10
  (measured TENANT, +0x60 = the ported record; .sha1 correct).
- test_hui_grab_victim's default expectation had been the PRE-FIX
  `differs` since the gate's birth (the 14z-73 fix landed the same
  session; freezes always passed =matches explicitly) — default now
  `matches`, measured Δ=0 on hui46.
- The m3b_merged11 (one-back) audit defaults — continue_ladder/switch,
  don_grab_pose, don_ko_writer, don_lilith_ko, hui_grunt,
  kill_poke_shape, roster_pairings, win_pal_auto, tenant_pairings —
  are correct TODAY but must join the freeze re-point sweep, or the
  N-2 deletion policy will rot them at the next freeze. **DONE — every
  freeze since has carried the sweep (14z-113: 54 defaults
  `m3b_merged16` -> `m3b_merged17`; `test_build_ref_rot.sh` polices it).**

The original decision input follows, unchanged.

143 dirs under build/, 11.7 GB total.
Classification: A = keep, B = candidate (judgement attached), C = delete-safe.
Nothing has been moved or deleted; this is the decision input only.

## A1 current freeze / operational — 13 dirs, 0.51 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| m3b_merged11 | 155 | 2026-08-20 | tests/audit_continue_ladder.sh; tests/audit_continue_switch.sh; tests/audit_don_grab_pose.sh; tests/audit_don_ |
| hui45 | 79 | 2026-08-20 | tests/audit_merged_legacy.sh; tests/audit_tripwire_reach.sh; tests/test_escape_triage.sh; tests/test_merged_re |
| pyron29 | 79 | 2026-08-20 | tests/audit_merged_legacy.sh; tests/audit_tripwire_reach.sh; tests/test_escape_triage.sh; tests/test_merged_re |
| don_m9 | 78 | 2026-08-20 | tests/audit_merged_legacy.sh; tests/audit_tripwire_reach.sh; tests/test_escape_triage.sh; tests/test_merged_re |
| m5_stock4 | 70 | 2026-08-20 |  |
| out | 24 | 2026-08-13 | tests/audit_don_grab_pose.sh; tests/audit_voice_borrow.sh; tests/audit_walker_repoint.sh; tests/lib/decrypt_ca |
| gate_failures | 22 | 2026-08-21 | tests/audit_merged_legacy.sh; tests/lib/m2a_common.sh; tests/test_mame_determinism.sh; tests/test_mame_parity. |
| wide_canary | 9 | 2026-08-03 | tests/test_mame_wide.sh; tests/test_wide_profile.sh; tools/build_wide_romset.py |
| don_m9_s4 | 7 | 2026-08-20 |  |
| manifest | 1 | 2026-08-19 | tests/audit_dispatch_census.sh; tests/audit_effect_class_rows.sh; tests/audit_empty_tiles.sh; tests/audit_flic |
| wide0 | 1 | 2026-08-09 | tests/audit_hitclass_map_cost.sh; tests/audit_merged_legacy.sh; tests/audit_phase_mode_cost.sh; tests/audit_qs |
| guard_corpus | 0 | 2026-08-21 | tests/audit_guard_corpus.sh |
| legacy_pairings | 0 | 2026-08-16 | tests/audit_legacy_pairings.sh |

## A2 pinned pipeline input (regenerable) — 3 dirs, 0.23 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| hui32 | 78 | 2026-08-18 | tests/audit_df_gold.sh; tests/audit_merged_legacy.sh; tests/test_build_ref_rot.sh; tests/test_m3a_reproducible |
| m5_wide | 77 | 2026-08-09 | tests/audit_merged_legacy.sh; tests/audit_phase_mode_cost.sh; tests/audit_type_writes.sh; tests/test_dualtrack |
| pyron21 | 77 | 2026-08-12 | tests/audit_hitclass_map_cost.sh; tests/audit_merged_legacy.sh; tests/audit_type_writes.sh; tests/test_effect_ |

## A3 evidence / ground-truth reference — 12 dirs, 0.79 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| m5w | 84 | 2026-08-09 | tools/run_wide.sh |
| hui41 | 79 | 2026-08-16 | tests/audit_guard_corpus.sh; tests/audit_hitclass_map_cost.sh; tests/test_decode_stage_banners.sh; tests/test_ |
| don_m4 | 78 | 2026-08-14 | tests/audit_voice_borrow.sh; tests/test_frozen_rompath_guard.sh; tools/build_donovan.sh |
| hui25 | 78 | 2026-08-09 | tests/test_beam_anim_walk.sh; tests/test_beam_list_type6.sh; tests/test_beam_variants.sh; tests/test_hui_df_st |
| hui27 | 78 | 2026-08-09 | tests/test_shared_writes.sh; tests/test_thunk_addr_literal.sh; tests/test_variant_dispatch.sh |
| hui29 | 78 | 2026-08-11 | tools/audit_type_stamps.py |
| hui30 | 78 | 2026-08-12 | tests/audit_merged_legacy.sh; tests/audit_merged_vec3.sh; tests/audit_objhook_owner_census.sh; tests/audit_tra |
| pyron19 | 77 | 2026-08-10 | tests/expected/registry.tsv |
| pyron20 | 77 | 2026-08-10 | tests/audit_hitclass_map_cost.sh; tests/expected/registry.tsv; tools/audit_type_stamps.py |
| donovan6 | 70 | 2026-08-20 | tests/audit_mask_window_ff4182.sh; tests/run_all_static.sh; tests/run_battery_m2.sh; tests/test_don_accent.sh; |
| donovan5 | 23 | 2026-07-28 | tests/test_m2a_flavor_selector.sh |
| merged1 | 9 | 2026-08-20 | tests/audit_merged_legacy.sh; tests/audit_merged_vec3.sh; tests/audit_type_dispatch_range.sh; tests/expected/m |

## A4 live-referenced (verify role) — 34 dirs, 2.56 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| probe_window | 155 | 2026-08-20 | tests/expected/registry.tsv |
| m3b_merged | 154 | 2026-08-13 | tests/audit_fg_damage.sh; tests/audit_fg_parity.sh; tests/audit_pool_free_byte.sh; tests/audit_pyron_ring.sh;  |
| m3b_merged9 | 154 | 2026-08-17 | tests/audit_fg_damage.sh; tests/audit_fg_parity.sh; tests/audit_ladder_selector.sh; tests/audit_pool_free_byte |
| hui40 | 79 | 2026-08-15 | tests/audit_effect_class_rows.sh; tests/audit_legacy_pairings.sh; tests/test_gfx_menus.sh; tests/test_gfx_menu |
| hui42 | 79 | 2026-08-16 | tests/test_voice_row_range.sh |
| hui43 | 79 | 2026-08-17 | tests/audit_df_gold.sh; tests/test_beam_anim_walk.sh; tests/test_beam_variants.sh; tests/test_gfx_layout_field |
| don_m5 | 78 | 2026-08-16 | tests/audit_legacy_pairings.sh; tests/audit_voice_borrow.sh; tests/audit_walker_repoint.sh; tests/test_frozen_ |
| don_m7 | 78 | 2026-08-16 | tests/audit_flicker_attribution.sh; tests/test_build_ref_rot.sh; tests/test_decode_stage_banners.sh; tests/tes |
| don_m8 | 78 | 2026-08-18 | tests/expected/donovan-m9-stock/README.md |
| hui11 | 78 | 2026-08-09 | tests/test_hui_df_style.sh; tests/test_pcrel_escapes.sh; tools/run_hui_behavior.sh; tools/verify_pcrel_data.py |
| hui12 | 78 | 2026-08-08 | tools/run_hui_behavior.sh |
| hui13 | 78 | 2026-08-08 | tools/run_hui_behavior.sh |
| hui14 | 78 | 2026-08-08 | tools/run_hui_behavior.sh |
| hui17 | 78 | 2026-08-09 | tests/test_beam_anim_walk.sh; tools/run_hui_behavior.sh |
| hui20 | 78 | 2026-08-09 | tools/run_hui_behavior.sh |
| hui26 | 78 | 2026-08-09 | tests/expected/registry.tsv |
| hui31 | 78 | 2026-08-12 | tests/audit_hitclass_map_cost.sh; tests/test_gfx_chain.sh; tests/test_merged_render_content.sh; tools/audit_gf |
| hui37 | 78 | 2026-08-14 | tests/audit_trap_shock.sh |
| hui38 | 78 | 2026-08-14 | tests/audit_trap_parity.sh |
| hui9 | 78 | 2026-08-09 | tools/run_hui_behavior.sh |
| pyron22 | 78 | 2026-08-13 | tests/audit_pyron_ring.sh; tests/test_build_ref_rot.sh |
| pyron25 | 78 | 2026-08-15 | tests/audit_legacy_pairings.sh; tests/test_region_overlap.sh; tests/test_region_overlap_control.sh |
| pyron26 | 78 | 2026-08-16 | tests/test_decode_stage_banners.sh; tests/test_pyron_blink.sh; tests/test_voice_row_range.sh |
| pyron27 | 78 | 2026-08-17 | tests/audit_pyron_ring.sh; tests/test_gfx_layout_fields_live.sh; tests/test_pyron_cosmo.sh; tests/test_voice_r |
| pyron16 | 77 | 2026-08-10 | tools/check_pyron_blink.py |
| pyron17 | 77 | 2026-08-10 | tests/test_pyron_blink.sh; tests/test_variant_dispatch.sh |
| pyron18 | 77 | 2026-08-10 | tests/test_build_ref_rot.sh; tests/test_pyron_cosmo.sh |
| m5_stock | 70 | 2026-08-09 | tests/run_battery_m2.sh; tests/test_dualtrack.sh; tests/test_m2a_target_resolution.sh; tests/test_tenant_row_o |
| m5_stock2 | 70 | 2026-08-16 | tests/test_phasec_spaces.sh |
| m5_stock3 | 70 | 2026-08-18 | tests/expected/donovan-m9-stock/README.md; tests/expected/registry.tsv |
| donovan | 48 | 2026-08-07 | tests/test_m2a_stage1_nullreloc.sh; tests/test_m2a_stage2_data.sh; tests/test_m2a_stage3_anim.sh; tests/test_m |
| hui4 | 9 | 2026-08-07 | tests/test_hui_oracle.sh; tools/force_pick_probe.sh |
| probe_104 | 9 | 2026-08-20 | tests/audit_don_grab_pose.sh |
| donovan_stage4_gate | 7 | 2026-08-17 | tests/run_all_static.sh; tests/test_m2a_stage4_code.sh; tests/test_no_tracked_mutation.sh |

## B1 previous freeze generation (tagged) — 3 dirs, 0.30 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| m3b_merged10 | 154 | 2026-08-18 |  |
| hui44 | 79 | 2026-08-18 |  |
| pyron28 | 78 | 2026-08-18 |  |

## B2 probe evidence (reproducible from STATE) — 11 dirs, 0.84 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| probe_105f | 154 | 2026-08-20 |  |
| probe_103_don | 78 | 2026-08-19 |  |
| probe_103_don2 | 78 | 2026-08-19 |  |
| probe_both | 78 | 2026-08-15 |  |
| probe_comp | 78 | 2026-08-15 |  |
| probe_fixture | 78 | 2026-08-15 |  |
| probe_gates | 78 | 2026-08-15 |  |
| probe_halfA | 78 | 2026-08-15 |  |
| probe_noobj | 78 | 2026-08-15 |  |
| probe_nosel | 78 | 2026-08-15 |  |
| probe_105 | 9 | 2026-08-20 |  |

## B3 scratch — 1 dirs, 1.90 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| scratch | 1949 | 2026-08-18 |  |

## B4 doc/history-only — 21 dirs, 2.11 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| m3b_merged2 | 154 | 2026-08-13 |  |
| m3b_merged3 | 154 | 2026-08-14 |  |
| m3b_merged5 | 154 | 2026-08-14 |  |
| m3b_merged6 | 154 | 2026-08-14 |  |
| m3b_merged7 | 154 | 2026-08-15 |  |
| m3b_merged8 | 154 | 2026-08-16 |  |
| qs93_probe | 154 | 2026-08-18 |  |
| hui39 | 79 | 2026-08-14 |  |
| hui10 | 78 | 2026-08-09 |  |
| hui15 | 78 | 2026-08-08 |  |
| hui33 | 78 | 2026-08-13 |  |
| hui34 | 78 | 2026-08-13 |  |
| hui36 | 78 | 2026-08-14 |  |
| hui7 | 78 | 2026-08-07 |  |
| pyron23 | 78 | 2026-08-13 |  |
| pyron24 | 78 | 2026-08-14 |  |
| hui6 | 77 | 2026-08-09 |  |
| m3a_selrec | 77 | 2026-08-06 |  |
| m3a_wheel | 77 | 2026-08-06 |  |
| pyron15 | 77 | 2026-08-10 |  |
| m3a | 76 | 2026-08-09 |  |

## C zero-reference — 45 dirs, 2.46 GB

| dir | MB | last touched | refs (tests/tools) |
|---|---|---|---|
| m3b_merged4 | 154 | 2026-08-14 |  |
| m5_nounstub | 84 | 2026-08-09 |  |
| anim_wide_hui | 78 | 2026-08-11 |  |
| hui16 | 78 | 2026-08-09 |  |
| hui18 | 78 | 2026-08-09 |  |
| hui19 | 78 | 2026-08-09 |  |
| hui21 | 78 | 2026-08-09 |  |
| hui22 | 78 | 2026-08-09 |  |
| hui23 | 78 | 2026-08-09 |  |
| hui24 | 78 | 2026-08-09 |  |
| hui28 | 78 | 2026-08-11 |  |
| hui35 | 78 | 2026-08-14 |  |
| hui8 | 78 | 2026-08-08 |  |
| anim_wide_don | 77 | 2026-08-11 |  |
| anim_wide_pyr | 77 | 2026-08-11 |  |
| pyron10 | 77 | 2026-08-10 |  |
| pyron11 | 77 | 2026-08-10 |  |
| pyron12 | 77 | 2026-08-10 |  |
| pyron13 | 77 | 2026-08-10 |  |
| pyron14 | 77 | 2026-08-10 |  |
| pyron6 | 77 | 2026-08-09 |  |
| pyron7 | 77 | 2026-08-09 |  |
| pyron8 | 77 | 2026-08-09 |  |
| pyron9 | 77 | 2026-08-09 |  |
| chk_wide | 76 | 2026-08-06 |  |
| ab_clearon | 70 | 2026-07-31 |  |
| ab_prethunk | 70 | 2026-07-30 |  |
| chk_stock | 70 | 2026-08-06 |  |
| chk_stock_w | 70 | 2026-08-06 |  |
| m5_stock_v | 70 | 2026-08-14 |  |
| throwtest_a | 70 | 2026-07-30 |  |
| prgall | 9 | 2026-08-03 |  |
| prgneg | 9 | 2026-08-03 |  |
| wide_prg | 9 | 2026-08-03 |  |
| wide_prgneg | 9 | 2026-08-03 |  |
| hui4d | 7 | 2026-08-07 |  |
| pyron5 | 7 | 2026-08-09 |  |
| hui1 | 6 | 2026-08-07 |  |
| hui2 | 6 | 2026-08-07 |  |
| hui3 | 6 | 2026-08-07 |  |
| wt | 6 | 2026-08-09 |  |
| wide_zero | 1 | 2026-08-03 |  |
| 14z91 | 0 | 2026-08-16 |  |
| owner_tag_evidence | 0 | 2026-08-13 |  |
| rebuild_revert | 0 | 2026-08-15 |  |

## Recommendation

**What can go, and how much it buys:**
- **C zero-reference** — nothing anywhere in tests/tools/docs names them. Delete-safe on the evidence; ~3.0 GB.
- **B2 probe evidence** — their own records call them "UNREGISTERED evidence, reproducible from STATE"; the recipes are written down. Delete-safe by their own description.
- **B3 scratch** — 1.9 GB; inspect once, then delete.
- **B4 doc/history-only** — referenced only in narrative (STATE_HISTORY rows, HANDOFF history). Mostly superseded intermediates (m3b_merged2..8, old hui/pyron rungs). Each has a freeze tag or a recorded recipe where it mattered. Bulk of the reclaim (~4.8 GB with B1).
- **B1 previous freeze generation** — tagged (`freeze/*`), and the tags carry rebuild recipes; the disk copies are cheap bisect insurance until the next window lands. Suggest: keep until the #107 window freezes, then they roll into B4.

**What must stay:** A1 (current freeze + operational dirs), A2 (`m5_wide`/`hui32`/`pyron21` — the merged pipeline's pinned extract inputs; regenerable via `ensure_merged_inputs.sh` but operationally live), A3 (known-bad evidence and ground-truth-failing references the audits are pointed at: `m5w`, `merged1`, `hui34`/`hui36`, `hui41`, `don_m4`, ...), and A4 pending a per-dir look (live-referenced; some references are historical defaults `test_build_ref_rot.sh` already tracks as superseded-but-loadable).

**The safe procedure (reversible, one ruling):**
1. `mkdir build/_attic && git mv`-nothing — these are untracked; plain `mv` the ruled classes into `build/_attic/`.
2. Run `ROMDIR=... tests/run_all_static.sh --strict` + the M2 battery + one guard-corpus soak. Anything that breaks NAMES its dependency (SKIP counts as failure under --strict, so a gate that quietly lost its build dir goes red, not silent).
3. Delete `build/_attic` after a soak period of your choosing.

**Standing guard afterwards:** `test_build_ref_rot.sh` already reports default-currency; if the attic pass turns up a gate that depended on a dir nobody named, that gate gets a re-point and the register a row — the #94 class, caught deliberately instead of by rot.

## **[VSP-98]** Recordings (`tests/inp/`, `~/.cache/vampire-saved/inp/`) — 14z-111, maintainer-ruled

- A hand-played MAME recording is tracked under `tests/inp/<what>-<freeze set>-NN/`
  (the freeze it was played on; `NOTE` says what it exercises) the moment it
  has a consumer (`tests/test_inp_corpus.sh` replays all of them at every
  freeze). The `~/.cache/.../inp/<name>/` original is deleted once tracked.
- A recording with no consumer — a plain-play attempt, an aborted take, a
  smoke run nothing names — is deleted after `grep -rn <name> tests tools
  docs HANDOFF.md STATE.md CLAUDE.md` comes back empty. Applied at close
  14z-111: `crash_m8` (82 KB, plays clean on merged-m8), `crash_m9` (~500
  frames, abort), `smoketest` (14z-9x, unreferenced) deleted; `crash_m10`
  renamed to `crash-merged-m8-01` and its cache copy deleted.

## **[VSP-96]** BEFORE DELETING A BUILD DIR, GREP FOUR PLACES — NOT TWO (14z-112, paid for)

The N-2 sweep of 14z-112 deleted 27 generations and broke one gate, because
the reference scan covered `tests/` and `tools/` only. The complete list:

1. `tests/` and `tools/` — **excluding comment lines**. A first pass that
   counted `#` mentions made almost every dir look load-bearing (31 of 62)
   and hid the 2.5 GB that was actually free. Filtering comments is what made
   the sweep possible at all.
2. **`build/manifest/`** — this is the one that bit. `shared_writes.toml`
   carries `build = "build/don_m7"` rows that `tests/test_shared_writes.sh`
   consumes, so deleting `don_m7` turned that gate into a SKIP — and under
   `--strict` a SKIP is a failure, because a skipped gate asserts nothing.
   The gate did not fail loudly; it quietly stopped testing.
3. `docs/` — but READ the hit before acting: `gfx_layout3.toml`'s
   `build/hui43` and `build/pyron27` are provenance notes ("measured on"),
   not inputs, and those dirs were correctly deleted.
4. The freeze policy itself: keep CURRENT + ONE BACK per track
   (`don_*`, `hui*`, `pyron*`, `m3b_merged*`, `m5_stock*`), whatever the
   grep says.

**And run `tests/run_all_static.sh --strict` BEFORE committing the deletion.**
It is the only instrument that catches a gate degrading to SKIP. Deleting is
cheap to redo — `git checkout HEAD -- build/<dir>` restores a tracked one in
seconds — so the sweep is safe as long as the suite gates the commit.

### **[VSP-97]** THE DEEPER FLAW THE SWEEP EXPOSED: "tracked" build dirs are only PARTLY tracked

`build/don_m7` is a TRACKED build dir — 18 files — but
`tests/test_shared_writes.sh` needs the 23 generator outputs
(`patch/fixed_*.bin`, `effect_lists.bin`, …) that are NOT tracked. Deleting
the dir therefore removed a gate fixture that git could not restore:
`git checkout HEAD -- build/don_m7` brought back the 18 and the gate went
from SKIP (14z-112's first strict run) to FAIL (its second).

**It was recoverable, and the recovery is the recipe if it happens again:**

    git worktree add --detach <tmp> 05ce63a          # the commit that froze don_m7
    cp -R build/wide0 <tmp>/build/                   # the WIDE overlay it merges
    cd <tmp> && ROMDIR=... KEY_SET=vsavj \
      GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
      tools/build_donovan.sh 6 build/don_m7_rb
    # -> fingerprint c90b60c3 = donovan-m7 exactly; copy the missing
    #    patch/* into build/don_m7/patch/, tracked files untouched.

The frozen inventory matching afterwards is what PROVES the rebuild was
right — the gate validated its own fixture.

**The standing lesson:** a gate whose fixture is an old build dir depends on
UNTRACKED bytes, and no policy in this repo protects those. Before deleting
any tracked build dir, either confirm no gate consumes it or accept that
restoring it means a historical rebuild. The cheap alternative — re-pointing
the gate at a current build — was measured and REFUSED here: `don_m14` shows
103 shared-surface writes against the frozen row's reviewed set, so
re-freezing would have laundered an unreviewed inventory into the very gate
that exists to prevent exactly that.

## THE 14z-115 SWEEP (select-wheel freeze) — applied under the policy

Deleted at the freeze (N-2 per track, grep-four-places read for intent,
`run_all_static --strict` before the commit): `don_m13`, `hui46`, `hui47`,
`pyron30`, `pyron31`, `m3b_merged16`, `m5_stock8` (tracked metadata `git
rm`'d; recoverable via `freeze/*` tags + a historical rebuild), plus the
untracked probe `probe_wheel_e2`. Two usage EXAMPLES re-pointed rather than
left dangling (`tools/verify_pcrel_data.py` docstring, HANDOFF's
`mister_mra.sh` recipes). Kept: `m3b_merged15` (the deferred
`test_inp_crash_merged_m8_01` defect-mode item — the maintainer's call),
`m5_stock3` (evidence). Current + one back now: `don_m14/m15`,
`hui48/49`, `pyron32/33`, `m3b_merged17/18`, `m5_stock9/10`.

## THE 14z-117 SWEEP (Pyron-medallion freeze) — applied under the policy

Deleted at the freeze (N-2 per track, grep-four-places read for intent,
`run_all_static --strict` before the commit): `don_m14`, `hui48`, `pyron32`,
`m3b_merged17`, `m5_stock9` (tracked metadata `git rm`'d; recoverable via
`freeze/*` tags + a historical rebuild). The four-places grep found NO live
path reference to any of them — only three LABEL strings
(`test_merged_render_content.sh` "== don_m14"-style `chk` labels and
`test_region_overlap.sh`'s "CURRENT trio" banner) that the 14z-115 sweep had
left naming N-1 builds; re-labelled to the current names. Kept:
`m3b_merged15` (the deferred `test_inp_crash_merged_m8_01` defect-mode item —
the maintainer's call), `m5_stock3` (evidence). Current + one back now:
`don_m15/m16`, `hui49/50`, `pyron33/34`, `m3b_merged18/19`, `m5_stock10/11`.
