# HANDOFF — HISTORY (blocks moved verbatim from `HANDOFF.md`)

Moved by the documentation rationalization pass (14z-123 onward), one
document commit at a time. Rules: historical entries are not rewritten
(CLAUDE.md §5 [VSP-13] step 4); a correction is made where the live claim
lives, in `HANDOFF.md`, and marked here only if it was already marked when
the block moved. Each block is headed by the section it left and the commit
that moved it. An "OPEN", "NOT yet frozen" or "awaiting playtest" here is
the status AS IT WAS WRITTEN — HANDOFF's live tables and STATE carry the
current one. No `**[PFX-N]**` anchor lives in this file.

## Build registry narratives

The 42 registry rows as they stood at 14z-123, newest first — each row's
full notes cell is the freeze's narrative. The live registry is the table
in `HANDOFF.md` "Build registry".

## [14z-123 G6 (1)] from «Build registry — the 42 rows as written»

| Build | SHA-1 (zip) | Notes |
|---|---|---|
| **THE 14z-119 PHYSICS-PORT FREEZE — donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (stock twin MOVED = donovan-m18-stock). Maintainer-ruled 2026-08-29 ("use VS2 parameters and not the shell character's", STATE 14z-118 charmap): `build/manifest/donovan.toml` `port_param32 = true` — his `param32_a` / `param32_b` / `jump_params` bank rows carry VS2's walk/jump values (walk 3.0/−2.625, VS2's three jump rows) instead of the vsavj alias row's (Victor's). Mark M12. **FIELD VERDICT GREEN 2026-08-30 (maintainer, MiSTer, 14z-121): "all green"**.** | donovan-m18 `7109f835` (`build/don_m18`, 339 ops — program identical to the validated probe `build/don_phys_probe`), huitzil-m25 `ae953657` (`build/hui52`, 370 — program UNCHANGED from m24, glyph tiles only), pyron-m19 `1222df18` (`build/pyron36`, 307 — likewise), merged-m14 `6649523a` (`build/m3b_merged21`, 826 ops = 823 + the three value ops, NO address moved, `bases.tsv` unchanged); stock twin `build/m5_stock13` `38e9cb2c` (MOVED from `d29fd062`: six data ops on stock slot 0x0F, `vm3j.04d` only) | Members moved vs 14z-117b: PROGRAM `vm3j.04d` (solos+merged: the three rows; stock: six), GROUP C `vsw.33m/37m` (the M12 glyph); QSound/Z80 untouched. Battery: three suites — every masked legacy class PASS, huitzil/pyron `.sha1`s bit-identical to their predecessors, Donovan's tenant rigs (103/108/110/112/113) moved and were ATTRIBUTED at the onset frame by DUMPS diff (`$FF8441/42` = P1's X-velocity word, `0x0280` -> `0x0300` = 2.5 -> 3.0, the change itself; 103 diverges f2980, 108 f3068, never re-converging = a different fight) and re-frozen; `audit_merged_legacy` 47/47; `audit_roster_pairings` 111/111 (`bases.tsv` unmoved); `audit_legacy_pairings` PASS; `audit_guard_corpus` (STATE); dualtrack, fbneo_legacy_oracle (NO refit), fbneo determinism, inp corpus, random_select_tenants, version_string (M12 pixel-exact), medallion, shadow, oboro, wheel gates, tenant_loop (re-frozen 339/615/826), pcrel (inventories IDENTICAL), escape_triage (25 verdicts identical), pointer_flow (baselines ALL IDENTICAL), m3a (re-pinned, five manifests), jtcores_twin, mister_mra_map, mra_parts, release_roundtrip — PASS. Release `release/merged-m14/{fbneo,mame,mister}/` (bitstream 18269 unchanged); fork `2bf41090` (catalogue: three CRCs), patch 0028, pin bumped; bundle `../mister_fieldtest_14z119/` (STOCK CONTROL MRA byte-identical). THE TELL IS M12. Detail: patch_notes 14z-119 / 14z-118 (charmap, 2); STATE 14z-119. Two traps paid: the re-point stamp on TOML header/key lines (`project/gotchas.md`) |
| **THE 14z-117b RANDOM-SELECT FREEZE — donovan-m17 / huitzil-m24 / pyron-m18 / merged-m13 (stock twin UNCHANGED = donovan-m13-stock). Maintainer-directed the same day ("do the random-select includes the tenants then"): the "?" cell's draw lists this build's tenants — TWO profile-gated site_thunks, `random_select_bound` (`0x020C74`, the wrap bound = 15 + tenants, re-entering `0x020C7C`) and `random_select_roster` (`0x020C80`, the table read + the routine's rts + an 18-entry table, hole b), ONE table filled per build by the new `roster_subst`; mark M11.** | `90a225ce` / `ae953657` / `1222df18` / merged program fingerprint `a1b7cb82`; stock twin `d29fd062` UNCHANGED (whole-artifact manifest identical) | `build/don_m17` (336 ops) / `build/hui51` (370) / `build/pyron35` (307) / `build/m3b_merged20` (823 ops) / `build/m5_stock12`; tags `freeze/{donovan-m17,huitzil-m24,pyron-m18,merged-m13}`. = the 14z-117 batch + the two thunks + `version_text` M11. **Members moved: solos `vm3j.03d` (the sites) + `vm3j.10b` (the bodies) + `vsw.33m/37m` (the M11 glyphs), don also `vsw.41`; merged additionally `vm3j.04d/07b` + `vsw.41/42` (ext allocations behind the two hole-b bodies: Phobos +0xC0, Pyron +0x30 — `bases.tsv` re-derived); QSound/Z80 untouched.** THE TRAP PAID FOR (game/gotchas.md, select_screen.md "THE WALKER HAS TWO PATHS"): a bound-only thunk let the walker's NON-tick frames read vanilla's table with cursor 15-17 (pad + code bytes as ids) and the figure refresh took an address error — measured on consecutive-frame DUMPS, fixed by displacing the read too. Gates at freeze: `test_random_select_tenants` (static shape / 91-frame sampled draw = 15 + tenants / confirm mid-plateau loads the tenant's own record / must-fire control on merged19) / version_string (M11) / pyron_medallion_2p / shadow_tenant / oboro / wheel gates / dualtrack / fbneo_legacy_oracle / inp corpus / m3a (re-pinned per member) / pointer_flow (merged: the two STRONG win_pal bases +0x30; solos identical) / pcrel + escape_triage (verdicts identical, three merged landings shifted) / tenant_loop (re-frozen 336/370/307, 823) / jtcores_twin / mister_mra_map / mra_parts / mister_page + map_fit (unchanged) / release_roundtrip (merged-m13) / audit_merged_legacy / audit_guard_corpus / audit_roster_pairings / audit_legacy_pairings / three full suites / strict — see STATE 14z-117 (2) for the numbers. Legacy cost: nine select replays BIT-IDENTICAL don_m16 vs the probe (no legacy replay hovers "?"). Release `release/merged-m13/`; MiSTer tail: fork `f997cfe1` (catalogue: eight CRCs), patch 0027, pin bumped; bundle `../mister_fieldtest_14z117b/` (`.rbf` unchanged) — **THE TELL IS M11.** **FIELD VERDICT GREEN (maintainer, MiSTer, 2026-08-29, 14z-118): "all green: behavior identical to emulation"** — random select cycles all 18 on "?" and confirming a tenant loads it; the M11 tell visible; no regression in play; the M10 sword/medallion trade re-observed (select screen only). STOCK CONTROL not re-run (`.rbf` 18269 unchanged — once-per-`.rbf`). |
| **THE 14z-117 PYRON-MEDALLION FREEZE — donovan-m16 / huitzil-m23 / pyron-m17 / merged-m12 (stock twin UNCHANGED = donovan-m13-stock). The 14z-116 fix, FIELD-VALIDATED on the board 2026-08-29 BEFORE freezing: `select_sword_pal_variant_id`'s P2 branch no longer writes palette row `0x1A` (ten in-place bytes, body length unchanged 126), so Pyron's medallion keeps its colours while P2 hovers a tenant; the accepted trade is the P2 select figure's sword drawing orange (select screen only). Mark M9 -> **M10** (three glyphs; `version_x` 340 -> 324 so the third does not clip at pixel 384).** | `7950c844` / `7ade3180` / `01b39c39` / merged program fingerprint `cde712e1`; stock twin `d29fd062` UNCHANGED (`only_variant_slot`, measured by rebuild: whole-artifact manifest identical) | `build/don_m16` (332 ops) / `build/hui50` (366) / `build/pyron34` (303) / `build/m3b_merged19` (819 ops) / `build/m5_stock11`; tags `freeze/{donovan-m16,huitzil-m23,pyron-m17,merged-m12}`. = the 14z-115 batch + the 14z-116 thunk edit + `version_text` M10 / `version_x` 324. **On every build only THREE ops changed content and NO address moved** (coord list +1 pair, record count `0x19 -> 0x1A`, thunk body). **Members moved: solos `vsw.31m/33m/35m/37m` (the third glyph tile) + `vsw.41`; merged additionally `vm3j.10b` (its thunk copy sits in hole b); QSound/Z80 untouched.** Gates at freeze: version_string (M10 pixel-exact at (324,202)) / pyron_medallion_2p / shadow_tenant / wheel_bank5 / select_wheel / tenant_select_records / oboro_select / dualtrack / fbneo_legacy_oracle (no refit needed) / inp corpus 6/6 / m3a (all pins + whole-artifact manifests re-attributed per member) / pointer_flow (re-frozen: WEAK data:long +1 per build = the new coord pair, STRONG unchanged) / pcrel + escape_triage (IDENTICAL) / jtcores_twin / mister_mra_map / mra_parts / release_roundtrip (merged-m12) / mister_page + map_fit (bank-5 count 6271 -> 6272, extent `0xFE41 -> 0xFE42`: the third glyph) / audit_merged_legacy **47/47** (leg b on the new solos) / audit_guard_corpus **344/344** / audit_roster_pairings **111/111** (`bases.tsv` re-derived: no row moved) / audit_legacy_pairings PASS / three full suite verifies: every masked legacy class PASS, the moved `.sha1`s all tenant/select rigs (the 14z-115 inventory + 113_shadow_vs_tenant frozen for the first time), attributed on 103 and 92 by DUMPS diff (`$FF06CD/D0/D1` execution position + dead stack at select frames; ZERO bytes at 5800 past the victory screen; the fix's own effect is in palette RAM, covered by the medallion gate) / strict tier — see STATE 14z-117. Release `release/merged-m12/` (M10, per-platform, round-trip PASS, bitstream 18269 unchanged). MiSTer tail: fork `80e08111` (catalogue: the six moved CRCs), patch 0026, pin bumped, twin PASS; board bundle `../mister_fieldtest_14z117/` (WIDE MRA regenerated; STOCK CONTROL MRA byte-identical to 14z-115's; `.rbf` unchanged) — **THE TELL IS M10.** ~~Field test on the board pending.~~ Field-tested GREEN 2026-08-29 (the sword trade validated — STATE Open bugs row) and re-observed under M11 at 14z-118; this row's tail contradicted its own header until 14z-118. |
| **THE 14z-115 SELECT-WHEEL SEPARATION FREEZE — donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11 (stock twin UNCHANGED = donovan-m13-stock). Maintainer-directed "E2" (2026-08-28): the three appended medallions repositioned by the maintainer's own pixel offsets (Phobos -1,+3 / Pyron 0,+7 / Donovan +1,+3 screen px), the hover-ring bases tuned by eye on MAME snapshots (Phobos +8 x, Pyron +3 x), and one authored 1px near-black OUTLINE sprite per cell interleaved before its medallion in the wheel record (36 tiles at group C 0x1F800+, pen 0 of row 0x19 — no palette content change); M9 mark. APPROVED ON EMULATOR SNAPSHOTS; FIELD VERDICT GREEN on the board 2026-08-28 (maintainer, CRT: wheel "almost perfect", Shadow, Dark Gallon — STATE hidden-character block; this row said NOT YET FIELD-TESTED until 14z-118).** | `38a4becb` / `7bb36d0c` / `7177229a` / merged program fingerprint `dea2c918`; stock twin `d29fd062` UNCHANGED (profile-gated, measured by rebuild) | `build/don_m15` (332 ops) / `build/hui49` (366) / `build/pyron33` (303) / `build/m3b_merged18` (819 ops — count unchanged, the record/coord data ops grew) / `build/m5_stock10`; tags `freeze/{donovan-m15,huitzil-m22,pyron-m16,merged-m11}`. = the 14z-111 batch + `wheel_layout_proposed.json` pos/highlight_base + `[[select_wheel]]` `cell_outline`/`outline_base`/`outline_pal` (generator 2a, build_gfx outline pass, `check_wheel_bank5` taught the interleave) + `version_text` M9. **Members moved: PROGRAM `vm3j.03d/04d/07b/10b`, `vsw.41/42`; GROUP C `vsw.31m/33m/35m/37m`; QSound/Z80 untouched.** Gates at freeze: wheel_bank5 / select_wheel / tenant_select_records (host-pick window 889-2415 held) / version_string (M9 pixel-exact) / oboro_select / jtcores_twin / mister_mra_map / mra_parts / release_roundtrip / pointer_flow (re-frozen, attributed) / pcrel + escape_triage (inventories IDENTICAL) / tenant_loop / m3a (all pins + whole-artifact manifests re-attributed per member) / inp corpus 6/6 on merged18 / audit_merged_legacy 47/47 — see STATE 14z-115. **Suites: every moved `.sha1` is a tenant-content or select-rig replay; attributed on 103 and 109 (don_m14 vs don_m15 at four frames): the OBJ-builder execution-position words `$FF06CC/CD/D1` and record cursor `$FF06B7/B9`, the dead-stack window, the QSound latch phase, and the P1/P2 RING OBJECTS' position bytes `$FFBA11/15` / `$FFBC11/15` — the change itself; no gameplay field.** Release `release/merged-m11/` (M9, per-platform, round-trip PASS, bitstream 18269 hash-verified). MiSTer tail: fork `202fc3e6` (catalogue, patch 0025, pin bumped — NOT pushed), board bundle `../mister_fieldtest_14z115/` (`_Arcade/` WIDE + STOCK CONTROL MRAs, `games/mame/` zips; `.rbf` unchanged) — **THE TELL IS M9.** |
| **THE 14z-113 ONE-ZIP PACKAGING FREEZE — merged-m10 (M8 mark UNCHANGED; donovan-m14 / huitzil-m21 / pyron-m15 and the stock twin CARRIED, untouched). Maintainer-ruled 2026-08-28 after bundle 14z112's field verdict (no regression; stock Vampire Savior coexists on the same SD card). PACKAGING, NOT CONTENT.** | `vsavjw.zip` sha1 `5aeefbec…` (merged16's was `eee7e4b1…` — the zip gained the four patched group-A members); program fingerprint **`32007911` UNCHANGED** from merged-m9 | `build/m3b_merged17` (tracked, 45 files; rompath holds ONE zip — no `vsav.zip`, the patched `vm3.13m/15m/17m/19m` live inside `vsavjw.zip`, the parent is the PRISTINE dump). Tag `freeze/merged-m10`. = merged-m9 byte-for-byte in every program, gfx and QSound MEMBER (m3a whole-artifact manifest `c1197c36 25`, MANI_STOCK unchanged); only the container changed. **Because the fingerprint and every member CRC are unchanged, the expectation sets, the fork catalogue (`gen_vsavjw_xml.py --check` ok) and the `.rbf` all carry over with NO change — the MiSTer tail of this freeze is empty.** Release `release/merged-m10/` — **the FIRST release in the per-platform format ruled 2026-08-28** (`fbneo/`, `mame/`, `mister/`, each self-sufficient; round-trip PASS: 20 patched members, 5 pristine copies; `docs/project/release_format.md`) — `mister/` holding the WIDE and `[STOCK CONTROL]` MRAs (31/31 and 22/22 parts resolve against merged-m10 + pristine dumps) and `BITSTREAM.txt` (seed 18269, slack +0.066, sha256 `46fc74af…`) **plus `jtcps2w.rbf` itself (CORRECTED 14z-114: this row said the `.rbf` was "still on the synthesis box" and the release format "the open item" — both were retired the same day by the post-close commit `09e4961`: the bitstream is in-tree at `release/bitstreams/18269/` and hash-verified into `mister/` by the packager; the format is ruled, see the RELEASE PACKAGING section)**. Gates at freeze: `run_all_static --strict`, inp corpus, version string and render-content on merged17 — see STATE 14z-113. Re-point sweep: 54 gate defaults `m3b_merged16` -> `m3b_merged17`. Field: bundle `../mister_fieldtest_14z112/` IS this set (same `vsavjw.zip` sha1). |
| **THE 14z-111 #99 ROOT-CAUSE FIX FREEZE — donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9 (+ stock twin UNCHANGED = donovan-m13-stock). Maintainer chose option A 2026-08-27. The field crash (Donovan 1P -> beat Bishamon -> CPU Phobos, every time, board AND MAME by hand) was CPU-Phobos playing DEMITRI's AI: the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + THE SAME 16 REPEATED, so tenant classes read the aliased row; Demitri's jump command writes sub-state 0x0E and Phobos's private vs2 jump handler (5 sub-states) indexes off its table into data -> line-F at `PRG:0x422BAC`. Captured on the maintainer's `.inp` (`tests/inp/crash-merged-m8-01`) with the new `tools/run_inp_guarded.sh`; the 110/110b fixes had never touched this path.** | `772d8052` / `cd362ca4` / `c403a283` / merged program fingerprint `32007911`; stock twin `d29fd062` UNCHANGED (the port is WIDE-only; M8 mark is gfx-only) | `build/don_m14` (332 ops) / `build/hui48` (366) / `build/pyron32` (303) / `build/m3b_merged16` (819 ops) / `build/m5_stock9`; tags `freeze/{donovan-m14,huitzil-m21,pyron-m15,merged-m9}`. = the 14z-110b batch + **bank_map `ai_script_0..3`** (data_ptr, the new `region = "auto"`, `optional = true` for the stock track) + **one DATA extra root per tenant** for his vs2 AI script block (H `0x100000:0xE3C`, P `0x100E3C:0xC8E`, D `0x101ACA:0x10CE` — vhunt2 twin shift 0, 0 pointer fields; Donovan's at the wide_ext HEAD via `region_space`, so the ext regions behind it shift uniformly +0x10D0/+0x1ED0/+0x2B60) + **four `reconciliation_huitzil` rows** (`0x2CBDE->0x2D3F2`, `0x2CE0A->0x2D5B2`, `0x2CE3E->0x2D5E6`, `0x364A->0x364A`: the tripwires Phobos's OWN AI reaches in his jump handler — the R1 loop's first fire) + **the M8 mark**. Zero code. **Acceptance: `tests/test_inp_crash_merged_m8_01.sh` MODE=clean (default now) PASS — the maintainer's recording plays through with no exception; MODE=defect still reproduces it on merged15.** Gates at freeze: audit_don_vs_cpu PASS (three CPU legs on the tenants' OWN AI), audit_merged_legacy PASS 47/47 (the superset proof for the alias-half rows), guard corpus 332/332 on merged16, stage-4 gate PASS (target unchanged), m3a PASS (every pin incl. whole-artifact manifests re-attributed per member), tenant_loop re-frozen (+5/tenant, -4 hui), pointer_flow/pcrel/escape_triage re-frozen with attribution, MiSTer twin + mra-map gates PASS. **Suites: donovan-m14 GREEN — 12 tenant-content .sha1s moved, ALL by the same two execution-position bytes `$FF06CC/CD` (a return-address word one slot below the ratified OBJ-builder secondary-stack window) at select entry (frame 890, one frame) and match-start phases (2410-2596 / 2470-2473 / 5793-5971), work RAM otherwise byte-identical (measured on 36_pick_tenant_cell at 890/891/900/1100/2412/2450/2500/2596/3000); huitzil-m21 GREEN; pyron-m15 see STATE.** Release `release/merged-m9/` (M8, round-trip). MiSTer: fork `63496069` (catalogue: 8 members, pushed), pin bumped, patch 0024; **board bundle `../mister_fieldtest_14z111/` = merged-m9, WIDE 31/31, .rbf unchanged — THE TELL IS M8.** **FIELD VERDICT GREEN (maintainer, 2026-08-27): the board on this bundle (M8 on the wheel) does NOT crash on the Bishamon > Phobos route that crashed 100% on M6/M7, despite every effort; MAME agrees on four hand-played recordings (`tests/inp/play-merged-m9-01`, `run-merged-m9-02..04`, all guard-clean) covering the first-match, Anakaris>Victor>Phobos and Bishamon>Phobos routes, a full arcade run to the ending, and a lost-then-continued Phobos fight. #99 CLOSED (maintainer, 2026-08-27).** Interpreter equivalence + byte detail: patch_notes 14z-111; mechanism: engine_internals "The CPU AI action-script system"; GitHub #99. |
| **THE 14z-110b REMAP FREEZE — donovan-m13 / merged-m8 (+ stock update; huitzil-m20 / pyron-m14 CARRIED). The residual #99 (board crash after Donovan 1P -> Bishamon; the Victor KO-neutral) root-caused to the STORED state 0x51 over-running a SECOND dispatcher `PRG:0x2384E`; fixed by renaming the six deity node bytes 0x51 -> 0x44 (five-consumer equivalence measured). Maintainer-conditioned GO 2026-08-26.** | `ec86330f` / merged program fingerprint `73690f21` / stock twin `d29fd062` (MOVED — data edit, not profile-gated) | `build/don_m13` / `build/m3b_merged15` / `build/m5_stock8`. = the 14z-110 batch + six `region_fix` bytes in vm3j.10b (whole-artifact delta on every track = that one member; H/P untouched). Expectation set carried donovan-m12 -> donovan-m13: **12 of 13 .sha1s IDENTICAL, only 110_don_arcade_mash moved** (the remap's behavioral footprint — deity content engaged by CPU opponents). MAME: audit_merged_legacy on merged15 **PASS 47/47 on the ratified classes**; stage-4 gate PASS; continue_switch / don_vs_cpu / dualtrack PASS; census EMPTY + gates PASS on all three builds. **FBNeo partial legacy oracle is RED on m12 AND m13 byte-identically, PASS on m11 — root-caused to the ruled 14z-110 d2-window cycles shifting FBNeo's execution phase, the remap exonerated (m12==m13 RAM at the failing frame); reduced refit RULED (per-replay frame overrides, drop 26_don_arcade_mash, documented) — recipe + measured clean frames in STATE 14z-110b CLOSE.** Release: `release/merged-m8/` (round-trip PASS). MiSTer: fork `f5a3391a` (pushed), pin bumped, patch 0023, twin + mra gates PASS; **board bundle `../mister_fieldtest_14z110/` = merged-m8 (WIDE 31/31; .rbf unchanged)** — supersedes the stale-bundle note on the 14z-110 row. **ACCEPTED 14z-111: suite verify SUITE GREEN (65 PASS), guard corpus 332/332 clean, FBNeo oracle refit PASS x2 exact, static strict 110/0/0; tags `freeze/{donovan-m13,merged-m8}` cut (local).** **FIELD RED (2026-08-26): the board STILL CRASHES on the same protocol with this bundle (CRC-verified loaded), and the SAME protocol crashes on MAME by hand on merged15 — the remap is NOT the crash's fix; #99 is OPEN (STATE 14z-111 "THE #99 CRASH IS NOT FIXED").** |
| **THE 14z-110 #99-FIX FREEZE — donovan-m12 / merged-m7 (+ stock update; huitzil-m20 / pyron-m14 CARRIED, rebuilt bit-exact). Maintainer-ruled 2026-08-26, order FIX -> AUDIT -> RE-FREEZE; audits green (STATE 14z-110 (3)).** | `60b55a12` / merged program fingerprint `761fd35a` / stock twin **`cf455760` (MOVED — the fix is not profile-gated)** | `build/don_m12` (327 ops) / `build/m3b_merged14` (808 ops) / `build/m5_stock7`; stage-4 target `653e315c`. = the 14z-105 batch + **the reaction_hook D2 WINDOW** (the #99 fix: the thunk's bne-arm — the only entry into dispatcher 2 at `PRG:0x018508` — gains the 0x50-0x53 window via a SECOND ext table to vs2's dispatcher-2 twin `0x016DE4` handlers VERBATIM; data stays native 0x51; vanilla dispatcher byte-untouched; thunk 50->82 bytes at `0x3FFD50`, six 0x3FFDxx allocs +0x60) + **the M7 version mark** (gfx-only: vsw.33m/37m; program fingerprints held). Whole-artifact deltas attributed: WIDE = vm3j.03d/04d/10b + vsw.41 PROGRAM + vsw.33m/37m GROUP C; STOCK = the three program members only. **Expectation set carried-renamed donovan-m11 -> donovan-m12 and re-frozen MEASURED IDENTICAL (all 9 .sha1s byte-equal — the fix is RAM-invisible on select/2P content).** Gates: test_reaction_hook_d2 (reconstruction + 3 controls) + test_fsm_census (6/6 native) + RH-43 A/B (pre-fix FORCE->vec3 PC 01850E ADDR 18511, post-fix copy handler clean); audits: FBNeo legacy oracle, dualtrack (onsets held), audit_merged_legacy (flicker inventories HELD with the added compares), audit_don_vs_cpu (venue-steered Phobos/Bishamon), audit_continue_switch (re-measured schedule, assertion 5 venue-steered deterministic, validated x2), guard corpus 332/332 clean. Release: `release/merged-m7/` (round-trip PASS). MiSTer tail: fork `fc04a8ec` (catalogue CRCs, 2 commits, PUSHED), pin bumped, patches 0021+0022, test_jtcores_twin + test_mister_mra_map PASS — **`../mister_fieldtest_14z108/` is STALE; regenerate the board bundle from merged14 before the next field test.** |
| **THE 14z-105 WINDOW FREEZE — donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 (FROZEN 14z-105; FIELD-CONFIRMED AND PUSHED 2026-08-22 — "Tests confirm Oboro Bishamon and the M6 mark"; Oboro's long intro is vanilla's own). W1 the Oboro select hook + W2 the version string in one window.** | `1de9a027` / `24a27940` / `6bf265ab` / merged program fingerprint `64426955` | `build/don_m11` (325 ops) / `build/hui47` (365) / `build/pyron31` (298) / `build/m3b_merged13` (806 ops = 804 + the one deduped thunk's body + site); stock twin `build/m5_stock6` **`883e7d17` UNCHANGED** (both features profile-gated — measured by rebuild, whole-artifact manifest identical 30/30); tags `freeze/{donovan-m11,huitzil-m20,pyron-m14,merged-m6}`; merged-m6 = tag + this row, NO registry.tsv row per the merged convention. **m3b_merged13 is BIT-FOR-BIT the rehearsed `build/merged_probe_w6` (attic'd 14z-106 -> `../build_attic_14z105`).** = the 14z-102 batch + **(W1)** `oboro_select_hook` — a profile-gated `site_thunk` at `PRG:0x020B9C` (every manifest, deduped): Bishamon's cell + START held at confirm commits vanilla vsavj's Oboro `0x18` (base `0x0B3450`), vanilla's own Gallon-variant idiom one cell over; the Start bit MEASURED (`+0x394` = `$8000`) before authoring; gate `test_oboro_select.sh` (P1, P2, other-cell, no-hold and STOCK legs) + **(W2)** the select-screen VERSION STRING "M6" — two AUTHORED glyph sprites appended to the roster21 wheel record (group C `0x1FE40/41`, pal row 0x19, screen (340,202)); gate `test_version_string.sh` (static + live OBJ list + pixel-exact snapshot). On the way: `gfx_tiles.decode` had every 8-pixel half MIRRORED since it was written (first authored tile exposed it; fixed both ways, gate `test_gfx_tile_codec.sh`, platform gotcha). Placements: huitzil +0x10, pyron +0x30 (the thunk allocates ahead of the regions) — bases.tsv, pcrel [merged_*], pointer_flow baselines re-derived. Whole-artifact manifests: program members + the four GROUP C members (the glyph tiles) moved; no QSound member. Gates at freeze: see STATE 14z-105. |
| **THE 14z-102 WINDOW FREEZE — donovan-m10 / huitzil-m19 / pyron-m13 / merged-m5 (FROZEN 14z-102, maintainer "go" 2026-08-21). #107 + #109 in one window; the #109 fix field-confirmed on the rehearsal probe BEFORE the freeze.** | `c6a02cb0` / `1a7249d6` / `dbce705b` / merged program fingerprint `393f92a5` | `build/don_m10` (323 ops) / `build/hui46` (363 = 361 + the row-31 code_ptr + region op) / `build/pyron30` (296) / `build/m3b_merged12` (804 ops); stock twin `build/m5_stock5` `883e7d17` (#107 rides the shared map — not profile-gated); battery legs donovan-m10-stock `883e7d17` / donovan-m10-stage4 `d32059e1`; tags `freeze/{donovan-m10,huitzil-m19,pyron-m13,merged-m5}`; merged-m5 = tag + this row, NO registry.tsv row per the merged convention. **hui46 and m3b_merged12 are BIT-FOR-BIT the rehearsed probes (`build/hui_probe_row31` / `build/merged_probe_row31`).** = the 14z-99 batch + **(#107)** reconciliation row `0x0448a6 -> 0x04367a` (verified, callsite-anchored, re-derived at the flip: 6/0x2E all-operand diffs, farm callsites unique both games) + **(#109)** THE CLONE-BEAM FIX: vsavj ships effect-class ROW 31 as a stub and row 31 is the DF clone-mode per-frame beam emitter — ported root `0x926e4:0x11e:t0x922f0` (vh2-oracled, 6/0x11E operand-only diffs) + `beam_effect_class31` code_ptr at `PRG:0x080B28` (slot 0 vanilla reads incl. both long mash marathons, 2418-hit control). THE ROOT CHANGED EXTRACTION: `build/hui32/extract` regenerated (old kept `extract.pre-14z102`), hui placements shifted, op counts re-frozen (363; 598/648; 804/901), tenant bases re-derived (phobos `0x4595a0`, pyron `0x4ac8dc`). Gold tint KEPT (maintainer ruling). Gate: `audit_clone_beam_lines.sh` default EXPECT_LINES=1 (defect signature was frozen on merged-m4 BEFORE the fix; fix-mode PASS solo + merged; strobe phase gotcha in the header). #109-B closed: sweep inventory frozen (`test_biased_list_inventory.sh`, ci_static). Detail: patch_notes 14z-102; STATE 14z-102. |
| **THE 14z-99 WINDOW FREEZE — donovan-m9 / huitzil-m18 / pyron-m12 / merged-m4 (FROZEN 14z-99, maintainer "go" 2026-08-20). #43(b) + #103 + #104 + #105 in one rehearsed window.** | `428fc0c9` / `c4bbb375` / `4c3c072b` / merged program fingerprint `2343607a` | `build/don_m9` (323 ops) / `build/hui45` (361) / `build/pyron29` (296) / `build/m3b_merged11` (802 ops = 764 + 32 #104 + 6 #105; #103's pieces relocate, net 0); tags `freeze/{donovan-m9,huitzil-m18,pyron-m12,merged-m4}`; merged-m4 = tag + this row, NO registry.tsv row per the merged convention. **The merged artifact is BIT-FOR-BIT the rehearsed `build/probe_window` (`2343607a`).** = the 14z-96 batch + **(#103)** the Donovan lose-flow fix (recon_overlay INSIDE `[[tenant]]` + pcrel_escape_fix `x026142` pad 0x60 / `x05c800` pad 0x20 — a ported pc-rel escape pinned his WHITE HP to 1 so the round judge's sign test never fired on his death; **NOT profile-gated by design, so the STOCK TWIN MOVED for the first time since 14z-91**: `build/m5_stock4` `16da59b6`) + **(#104)** the 15 capture_kf slot_rows per manifest (attackers' per-victim capture keyframe blocks ported whole from vs2 — the variant-row alias class; tenants hold NATIVE capture records, Victor's grab holds them upright) + **(#105)** win_pal `colors = 8 -> 10` all three (the AUTO sets port; AUTO winners' portraits colored) + **(#43(b))** `ALLOW_FALLBACK=True` (tool state: the ruled movement decayed to ONE row `0x028122 -> 0x028e42` plausible-0.90, ZERO build effect). Gates at freeze: suite GREEN x3 on re-frozen sets (every legacy masked replay on its EXACT frozen class; combined legacy cost = the single f890 class-4 select pointer-cache frame); all four flip-audits green at their new defaults (grab_pose EXPECT_MATCH=1 11/26/11; win_pal_auto EXPECT_WHITE=0; don_lilith_ko EXPECT_STALL=0 + WEAKEN_P1=1 FLOWED 2880; don_ko_writer EXPECT_DEFECT=0 + WEAKEN_P1=1 kill-commit f6561); merged gates all green (select-bank, trap parity, FG parity native-exact, render-content bands byte-equal to the new solos, audit_merged_legacy leg a 47/47 leg b guard-clean); m3a_reproducible all five artifacts bit-exact; M2 battery 23/23. New replays classified at the freeze per the 14z-78 ruling (96/104 masked §4 v3 window classes; 103 tenant .sha1). Byte detail: patch_notes 14z-99; full record STATE 14z-99 FREEZE. **Field pass COMPLETE (2026-08-20): #103 + #104 + #105 ALL CONFIRMED AND CLOSED (no stall any VS2 win/lose incl. Donovan-vs-Lilith; correct grab sprites under Victor AND Bulleta 6+HP throws, all tenants; AUTO portraits colored; no crash). #99 un-parked.** |
| **THE #101 KERNEL VOICE-TABLE PORT — donovan-m8 / huitzil-m17 / pyron-m11 / merged-m3 (FROZEN 14z-96, maintainer-ruled option (a) + freeze 2026-08-18). The grunt fix.** | `d038553d` / `bfd819a0` / `738bcfc2` / merged program fingerprint `ac3d06184f8c248717ba754275d5ab0147c69f07` | `build/don_m8` / `build/hui44` / `build/pyron28` / `build/m3b_merged10`; tags `freeze/{donovan-m8,huitzil-m17,pyron-m11,merged-m3}`. = the 14z-94 batch + each tenant's four `kernel_voice_e0-e3` words (the kernel per-class voice tables' variant halves — vsavj ships them as byte-copies of the base halves, so tenants fired LEGACY voices: Phobos fired Bulleta's `0x1d2` = the maintainer's video-confirmed electrocute grunt, Donovan fired VICTOR's `0x322`) + 16 authored (base,+0x300 alias) Z80 song pairs (the kernel path calls the REAL `0x4CE2`, so the facing alias applies — native's own `0x700→0xA00` twin doctrine) + batch scope `0x730,0x733`. Phobos/Pyron hurt events now port vs2's `0x2a1/0x2a2` — FREE Z80 rows both games, deliberate silence. Measured identity-only: same frames, right voice (or native silence); firing pattern untouched. Stock twin `build/m5_stock3` BIT-IDENTICAL `a054de5c` incl. whole-artifact digest. Gates at freeze: audit_hui_grunt per-build rows green, audit_merged_legacy PASS on the 764-op image, tenant_loop 289/327/262 + 764, manifest_merge (9,9,11)/25, m3a pins re-pointed. merged-m3: NO registry.tsv row per the merged convention (tag + this row). |
| **THE #91+#92 FIX BATCH — huitzil-m16 / pyron-m10 / merged-m2 (FROZEN 14z-94). The first builds on which a planted tripwire is NOT reachable in extended play.** | `da734d49` / `e29cac23` / merged program fingerprint `081e2e53c5debff6d2d5bb4d4376d2a1ef6be842` | `build/hui43` / `build/pyron27` / `build/m3b_merged9`; tags `freeze/{huitzil-m16,pyron-m10,merged-m2}`. **donovan-m7 is UNCHANGED** — his manifest never moved and his op count is unmoved at 285. = the previous batch + (A) the reconciliation row resolving vs2 `0x494de`, a 32-bit divide helper vsavj carries byte-identical at `0x47fb6` (huitzil only; 52 tripwires -> 51, and the merge op count 753 -> 752) and (B) **the four arcade-ladder stage bytes** at `+0x01/+0x1a/+0x29/+0x31` of each tenant's table-B row (`0x00BB68 + class*0x40`) retargeted `0x18` -> `0x0a`. `0x18` is **REVENGER'S ROOST**, vs2's THIRTEENTH stage; vsav ships twelve, so selecting it walked off the banner family into its own `0x00400000` terminator and died at vec3 (#92). All eight sit opposite candidate class `0x13` (Donovan) — they are the ladder entries scheduling the Donovan match. `0x0a` = ABARAYA, maintainer-ruled 2026-08-17 ("any stage except Fetus of God, least impact"). **VERIFIED AGAINST LIVE CRASHES ON THE PREDECESSORS**, 40,620-frame arcade marathon with the tenant forced: huitzil-m15 CRASH 18337, pyron-m9 CRASH 15079, merged-m1 CRASH 8887 — all three successors END 40620. Suites SUITE GREEN on both solos; exactly one replay moved per set (the tenant pick), attributed to ONE byte at `$FF1E52` in the live ladder pool. Merged gates all green (audit_merged_legacy AUDIT-EXIT 0, leg a 47/47, leg b 6/6; render-content; trap and FG parity; select-bank gates). **merged-m2 has NO registry.tsv row on purpose** — same reason as merged-m1, see that row and the registry header. **PLAYTESTED 2026-08-18 (maintainer, MAME, `build/m3b_merged9`): NO REGRESSION.** #92's fix confirmed in the field — Donovan is met on Bishamon's stage, and `v=0x0a` decodes to ABARAYA, the ratified retarget. The round-end flicker was NOT observed. **One crash-reset, GitHub #99**: 5th arcade match, Donovan vs Phobos (CPU) at fight start, reached by continuing with a character switch after losing as Phobos; HUD was up, so match setup completed. Two lesser findings: #100 (next-stage screen shows Donovan as Victor, blank portrait — cosmetic) and a doubt about Phobos' electrocuted sfx. **CORRECTED 14z-95 (maintainer): that sfx report is a WRONG sound, not a MISSING one, so the "lines up with the already-open #93/#98" reading here was mine and is RETRACTED** — both of those are absence shapes, and a wrong id at the right moment points at the id-mapping layer (per-tenant voice remaps / `voice_borrow_keep_tenant` / the ruled shock remap `audit_trap_shock` locks at class 0x06). The maintainer is investigating it and #99 themselves: **both are HANDS-OFF pending their feedback.** **The crash is NOT a regression against a prior build — it is a path no gate covers: `tests/replays` has no tenant-vs-tenant replay at all, though §4 mandates one.** |
| **merged-m1 — THE FIRST FROZEN MERGED BUILD (14z-92, maintainer-decided). All 18 characters, one image.** | program fingerprint `952fc73138b93e2024516872b95ddc615694d900` | `build/m3b_merged8`; tag `freeze/merged-m1`. **NO `registry.tsv` ROW, ON PURPOSE — see the header of `tests/expected/registry.tsv` before you add one.** The dispatch fingerprint covers PROGRAM members only, and the LEGACY-ONLY instrument `build/merged1` (tenants draw BLANKS, zero-filled overlay) is generated from the same inputs and fingerprints IDENTICALLY (952fc731…, measured) — so a registry row would register the instrument too, and the absence of that row is exactly what keeps it out of run_suite. merged-m1 is therefore frozen by TAG + this row, and validated by the merged-specific gates rather than by run_suite dispatch. = the 753-op 3-tenant program image (owner tag + sfx records + damage work-var rows + chirp/shock + the M5 VOICE BATCH + the 14z-91 walker relocation / fixture deletion / type-6 change) + the S2 gfx chain (D → H → P, group B pristine) + the authored Z80/sample members. GATES AT FREEZE: `test_merged_render_content` PASS (all three bands + the relocated strip byte-equal to the frozen solos, de-substitution held, 4-window poison control fired, 3 pick replays live), `audit_trap_parity` PASS, `audit_fg_parity` PASS, `audit_select_bank_gates` PASS, `verify_gfx_build` + `check_tenant_hud` PASS on all three tenants, and `audit_merged_legacy` **AUDIT-EXIT 0 — leg (a) 47/47 with 0 NOT-EVALUATED, leg (b) all six guard-clean** (it rebuilt its instrument from scratch and reproduced 753 ops and the same fingerprint, so the merged program build is deterministic end to end). **PLAYTEST FIELD-CONFIRMED (maintainer, 2026-08-16): "no obvious regression"** — frozen on gate evidence first and played after, by decision. The maintainer added that the game "may even feel better", explicitly flagged as feeling rather than fact: recorded as an IMPRESSION only (a plausible mechanism exists — 14z-91 removed thunk cycles from a path dispatching 279,577 times per corpus, which widens main-loop headroom and would read as less slowdown — but it is UNMEASURED, see the STATE freeze record). **FIELD-CONFIRMED ON THE MERGED IMAGE (maintainer, 2026-08-16): the BEAM visual "100% clean, as is its sound"** (the S6 carry-forward — the effect family, three root causes across 14z-70/71, is now closed end to end on the shipping artifact), **and Phobos' historically-defective moveset**: 236+P, 236+K, jump214+K, 236+2K, 214+2K "in the variants that broke or were incomplete in the past and their ES variants". That covers out-of-range entry 82 (the Plasma Trap, LOUD) in the field; entry 83 (Reflect Wall, SILENT) is guard-cancel-only and therefore rig-only — `test_hui_pairs` PASSES on merged8. Coverage boundary as stated by the maintainer: all MOVES on the three tenants, not every L/M/H strength of each; measured as unknown-unknowns rather than a named mechanism (STATE 14z-92 (4)). A freeze is reversible; m6/m14/m8 were withdrawn in 14z-88. Rebuild: `ROMDIR=... tools/build_merged.sh <dir>` (~1 min; the fingerprint moves with the generator — do not pin it). |
| ~~donovan-m6 / huitzil-m14 / pyron-m8 — THE 14z-87b BATCH (beep fix + medallion fix)~~ **WITHDRAWN 14z-88 (maintainer-decided revert): the medallion row move cost a legacy pairing (replay 38) one main-loop frame at the select→VS fade on the H/P/merged builds (never re-converges vs vanilla); the beep fix stays (sound members, no program change) — the CURRENT builds are donovan-m5 / huitzil-m13 / pyron-m7 again (row below)** | `57754602` / `66feb5e8` / `fab92eb7` | `build/don_m5` / `build/hui40` / `build/pyron25` (dirs reused); REGISTERED (sets carried-renamed; work-RAM streams unchanged by both fixes — CORRECTED 14z-88: the medallion move moved its STAGING slot to $FF42A2, so the sets moved to the V3 masked basis and the tenant-content .sha1s were re-frozen after attribution). = the voice-borrow builds + (1) QSOUND PACKING LAW #3 (the record `end` byte plays INCLUSIVE; packer copied exclusive — 3 of 57 packed records held a foreign end byte; rec#0x3C8 = the sword-plant BEEP, ear-confirmed from a byte-synthesized prediction, fixed in build_qs_songs.py + law-3 gate in test_qs_songs.sh; sound members only) and (2) THE MEDALLION FIX (Pyron wheel-medallion pal_row 0x1A->0x1D, one layout field: Donovan's P2-hover portrait draws row 0x1A by vs2-heritage attr — the collision exists only MERGED; snapshot-verified both directions, maintainer-confirmed). Stock twin BIT-IDENTICAL 6c93cfa8 through both. |
| **donovan-m5 / huitzil-m13 / pyron-m7 — THE VOICE-CLASS BORROW FIX (14z-87, maintainer-decided b+c) — CURRENT again since the 14z-88 revert (tags freeze/{donovan-m5,huitzil-m13,pyron-m7}); the dirs carry the 14z-87b beep-fixed sound members (program fingerprints unchanged by that fix)** | `3c599fb6` / `2629561c` / `94ce9a48` | `build/don_m5` / `build/hui40` / `build/pyron25`; REGISTERED (sets carried-renamed from the m4/m12/m6 sets, tenant-content .sha1s re-frozen). Each = predecessor + the shared **voice_borrow_keep_tenant** thunk (engine borrow site `PRG:0x0AEF2/0x0AEF8`: tenants keep their OWN voice class — skip-write-only; legacy path byte-preserved) + its two ported candidate/voice-number table rows (variant rows of `0x00B268`/`0x00BB68`). Fixes the sword-plant "ding" class at its root: tenant engine-voice events now play their AUTHORED voices (plant-end measured authored 0x6A; the 0x62B/0x308 pair gone). ALL only_variant_slot-gated; stock twin BIT-IDENTICAL (6c93cfa8, measured). Cost: ~60 cycles on a 0-1×/match event; tenant-content .sha1 movement = the dead-stack hook-cycle class + intended voice content (measured, replay 63 RAM diff: 3 dead-stack bytes, live state identical); legacy masked classes held, NO flicker-inventory movement. Gates at freeze: audit_voice_borrow own-class (+ lottery ground-truth pair vs don_m4), m3a all-four bit-exact, tenant_loop re-frozen 270/305/239 + 538/738, manifest_merge re-frozen (incl. accrued staleness from 14z-85f/86 — caught here), shared_writes re-frozen 71/66/55. Mechanism: engine_internals "per-node sfx dispatch, third pass". Awaiting maintainer ear-check. |
| donovan-m4 / huitzil-m12 / pyron-m6 — THE M5 VOICE BATCH (14z-86) — superseded by the 14z-87 row above (tags freeze/{donovan-m4,huitzil-m12,pyron-m6} are the way back; build/don_m4 stays on disk as audit_voice_borrow's lottery-mode ground-truth reference) | `84f49aaa` / `e1f598d6` / `4c6e3fb6` | `build/don_m4` / `build/hui39` / `build/pyron24`; REGISTERED; tags `freeze/{donovan-m4,huitzil-m12,pyron-m6}`. Each = predecessor + its VOICE BLOCK: 79 verbatim vs2 songs at authored ids 0x58-0xA6 (Z80 rows via `tools/build_qs_songs.py [voice_batch]`: the 8th note-table slot restored via the table-0 relocation; authored records; 841 KB packed into `vsw.21m` = WIDE v1.2 content member), per-tenant remaps (D36/H14/P10) + 25 farm sound_stubs + the facing-alias thunk @0x5FFF00 (voice ids skip +0x300 — measured channel-allocation-only). ALL profile-gated; stock twin bit-identical (6c93cfa8, measured). Gates at freeze: keyon batch A/B GREEN (whole-run content multisets vs native), trap parity/shock green (hui39 + merged6), FG parity green (merged6), m3a all-four bit-exact, tenant_loop re-frozen 265/300/234+531/729. Map: `docs/project/tables/qs_voice_map.md`. FIELD-CONFIRMED (maintainer, 2026-08-15): "the sounds are normal now among all 3 newcomers" — after the two maintainer-caught playback-law fixes (half-bank + byte-parity). One open audible item: the sword-plant ding — ROOT-CAUSED 14z-87 to the engine VOICE-CLASS BORROW (PRG:0x0AEF6; engine-side, the 14z-86 row-0x1C design retracted); DECIDED b+c and SHIPPED 14z-87 — see the donovan-m5 row above. |
| **huitzil-m11 — PHOBOS FROZEN (14z-86) — supersedes huitzil-m10** | fingerprint `6eed421be848c2de333bec9a82ef74de18cd88c9` | `build/hui38`; REGISTERED `-> huitzil-m11`; tag `freeze/huitzil-m11`. = m10 + **the M5 EJECTION PILOT**: trap record node 10 remapped 0x739→0xD8 onto AUTHORED Z80 song rows (WIDE v1.1 content members `vsw.z01/z02`, sentinel CRCs 0xdec0de38/39; `tools/build_qs_songs.py` injects vs2's 0x33-byte song verbatim at flat 0x3C980 + the 0x3D8 alias twin at 0x3C9C0 from `build/manifest/qs_songs.toml`). NO sample port — the content is byte-identical in vsav's own image (0x18D800 = record #0x5C = note-entry 0x28). Keyon A/B matches native (v11/v12, 0x2800 window); ring rig 87 shows 00d8 in the 0739 slot both windows. Gates at freeze: audit_trap_parity RE-FROZEN (ground-truthed failing pre-pilot), test_qs_songs + test_qs_id_table NEW, trap shock/sound green, m3a on the new EXPECT. Full decode: engine_internals "The QSound Z80 driver". EAR-CHECK CONFIRMED (maintainer, 2026-08-14): "The trap mine ejection sound is indeed there" — no other new sounds, as expected (only the ejection was ported; the voice blocks are the next batch). THE TRAP IS FULLY CLOSED, all four items field-confirmed (damage 14z-85f, chirp 14z-85g, shock 14z-85g(2), ejection 14z-86). |
| **huitzil-m4 — PHOBOS RE-FROZEN (14z-82c, maintainer-adopted 2026-08-12) — supersedes huitzil-m3** | fingerprint `e66678d087824d1639750d2b9565c0b99ad2b250` | `build/hui30`; REGISTERED `-> huitzil-m4`; rebuilds bit-exact. = huitzil-m3 + the ADOPTED **`hitclass_map_extend`** site_thunk (shared with pyron; the f7997-class fix): vsavj's projectile-pool hit sweep maps colliding objects' type bytes through a 64-entry byte map at `PRG:0x1A888` (seven callers); Phobos stamps types 68/72 into that pool, so a landed hit would over-index it exactly as pyron-m2's type-64 satellite measured. Body GENERATED (`tools/gen_hitclass_map_thunk.py`) and reconstructed by `tests/test_hitclass_map_thunk.sh`; legacy measured BIT-IDENTICAL (fire census: legacy never enters the map — **that census figure is RETRACTED 14z-92: it was 2 replays, both scoring zero; corpus-wide legacy enters 230 times at indices < 64, so it reads vanilla's own bytes. Fix unaffected, argument restated**). Expectation set `tests/expected/huitzil-m4/` (renamed from huitzil-m3, content unchanged). Validate: `MAME_ROMPATH="build/hui30/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. KNOWN-OPEN unchanged from m3 (variant_dispatch row 0x10 red; win-quote) |
| **pyron-m3 — PYRON RE-FROZEN (14z-82c, maintainer-adopted 2026-08-12) — supersedes pyron-m2** | fingerprint `6c7f7322da793c12b3681dd3ef5a76b3792ae5d0` | `build/pyron21`; REGISTERED `-> pyron-m3`; rebuilds bit-exact; BYTE-IDENTICAL to the measured 14z-82b probe build. = pyron-m2 + **`hitclass_map_extend`** — THE f7997 FIX: his type-64 satellite landing a hit over-indexed vsavj's 64-entry projectile hit-class map (map[64] = the following rts's 0x4E), a LATENT crash measured on pyron-m2 SOLO. The 11,017-frame soak that crashes pyron-m2 runs END-clean; legacy BIT-IDENTICAL over 30,284 frames (`tests/audit_hitclass_map_cost.sh`, rerunnable). Expectation set `tests/expected/pyron-m3/` (renamed from pyron-m2, content unchanged). Validate: `MAME_ROMPATH="build/pyron21/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. ALSO DISSOLVED (measured): replay 80's f4840 reset — same crash signature on pyron-m2 (vec3 f4638 PC 01AB10), END-clean on pyron-m3. OPEN unchanged from m2: win-quote |
| pyron-m1 — SUPERSEDED by pyron-m2 (14z-76); no longer producible from the tree (pyron.toml now carries the effect-palette row) | fingerprint `d8b282daab75fcb3c52e75170a05a600fd0f3ad7` | `build/pyron19`; REGISTERED `-> pyron-m1`. The THIRD full-roster tenant, at his native vs2 id 0x11. Everything the 14z-74/75 arc landed: his art at delta 0, select family + 21-cell wheel, sprite palettes, win screen, his own variant-id HUD (anchors 0xBE94/0xBE9C), physics, the air 214+P fix, THE BLINK (three aliased palette-routine tables, one word each — sweep them with `tests/test_variant_dispatch.sh`), and THE COSMO CRASH fixed in HIS OWN DATA (sub-state index 81 is out of range for vsavj's 80-entry table; retargeted 81->79 at vs2 0x0D0C7F, one byte, tenant-scoped — the 14z-74 engine-side repoint of the shared word is WITHDRAWN, it broke four legacy replays). Expectation set `tests/expected/pyron-m1/`: 42 `.sha1` + 13 `.masked` + 17 `.skip` = 72/72 replays, `run_suite.sh vsavjw` **GREEN (55 PASS / 17 SKIP / 0 FAIL)**. Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/pyron19/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. OPEN (non-blocking): the win QUOTE (shared fold), his EFFECT palette (PORTED 14z-76 on `build/pyron20` `69e8c6f0`, awaiting playtest — the "16-row table" reason this row was deferred is RETRACTED, see the pyron20 row below), and replay 80's f4840 reset — an INDEPENDENT defect present on pyron14 too. |
| **pyron-m2 — PYRON RE-FROZEN (14z-76, 2026-08-10, maintainer playtest) — supersedes pyron-m1** | fingerprint `69e8c6f08b9fc5859948e50cfb41156d62adf1ec` | `build/pyron20`; REGISTERED `-> pyron-m2`; rebuilds bit-exact. = pyron-m1 + his EFFECT palette block, delta EXACTLY two ops (`data_file 0x3faba0` from vs2 `0x3AC45C` len `0xDC0`, and `poke32 0x38c25c -> 0x003faba0` = row 0x11 of the effect-palette pointer table). **The "16-row table" premise that deferred this for two sessions is RETRACTED** — `0x38C218` is ONE 32-row id-indexed table and `0x38C258` is its second half (0 references in either ROM view; both tables alias their variant half except rows 0x12/0x18, the Oboro-class datasets), so row 0x11 is an ordinary variant alias row. Gate `tests/test_effect_palette_table.sh`. **Visibility was undecidable automatically** (0 reads of any effect block across two vanilla fighting replays + a 6000-frame soak, against a 60-read positive control on his sprite block — a rare-event palette); the maintainer playtest decided it: Pyron's shock aura RED on pyron19 / YELLOW on pyron20 = vs2, and **Demitri identical on both builds and correct**, which is the legacy check no RAM gate can make. Expectation set `tests/expected/pyron-m2/` (renamed from pyron-m1, content unchanged), `run_suite.sh vsavjw` GREEN 55 PASS / 17 SKIP / 0 FAIL. Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/pyron20/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. OPEN: the win QUOTE (14z-76 measured its real path and eliminated the arrays every prior attempt targeted) and replay 80's f4840 reset. |
| **huitzil-m3 — PHOBOS RE-FROZEN (14z-79, maintainer playtest) — supersedes huitzil-m2** | fingerprint `34c8b47de5a43a67e7292f16d0ad133d287fa7e4` | `build/hui29`; REGISTERED `-> huitzil-m3`; rebuilds bit-exact. = huitzil-m2 **+ the (b') index-window thunk** **− the withdrawn `df_palette_seq_rows` row.** **(b')** hooks the sub-state dispatcher `PRG:0x018460` (`patch = "jmp"`, 470-byte body in hole_a) and covers the out-of-range window of table `0x018468` (80 entries; vs2's twin has 84): entries 80-83 run vs2's handlers INLINE, every other index takes the vanilla path, and anything else is a defined vec3. Fixes **Plasma Trap** (entry 82, LOUD — air 214+MK, crashed on every Phobos build while every gate stayed green; maintainer-confirmed fixed) and **Reflect Wall** (entry 83, **SILENT** wrong-routine dispatch, guard-cancel-only so it is rig-verified: handler hits at f3214/f3315, `D0=0xA6`, with `test_hui_pairs.sh` passing as the positive control). Body is GENERATED by `tools/gen_index_window_thunk.py` and RECONSTRUCTED from the ROMs by `tests/test_index_window_thunk.sh`; exhaustively simulated over all 65,536 index values (80/80 legacy entries reach their vanilla handler **with vanilla D1**; 4/4 danger entries run vs2's body byte-for-byte; every other value LOUD). Two design corrections vs the STATE 14z-78 spec, both measured: the specified `lea 0x018468,a0` normal path is a DATA-space read and returns ciphertext (38 of 80 legacy targets come out ODD), so the body carries its own re-encrypted copy of the table and keeps the read pc-relative; and each trampoline restores D1, because "D1 is dead on ENTRY to all 80 handlers" is true and insufficient — they `rts` into a `bsr.w` chain that reads it (a build without the restore moved every self-frozen legacy log). **WITHDRAWN in the same commit: `df_palette_seq_rows`** — it wrote palette-seq ids 0x1E-0x21, which are **BULLETA'S Dark Force block** (236 resolver calls in one DF, measured on vanilla, `$FF802E`=1), so a LEGACY character rendered wrong on every Huitzil build from 14z-69 until now. Found by maintainer playtest; invisible to every RAM gate because the palette path never transits work RAM. Phobos' DF is purple again until he gets his OWN block (deferred — see STATE 14z-79). Legacy: **13/13 masked replays PASS with frozen flicker inventories UNCHANGED**; `.sha1` determinism baselines re-frozen (28 moved — hook cycles at a cold site, 22 dispatches per 5,520-frame replay; every divergence begins 1-2 frames after the thunk's first execution and is absent where it never runs). Expectation set `tests/expected/huitzil-m3/` (renamed from huitzil-m2). Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/hui29/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. **KNOWN-OPEN RED:** `tests/test_variant_dispatch.sh` on table `0x02a8a4` row 0x10 (`ours 0x004a`, vs2 `0x0040`) — that aliased row is what puts Phobos on Bulleta's palette routine, and it stays red until the deferred fix. It had been red since 14z-74 and was written off as benign; it was the Bulleta bug all along. |
| **huitzil-m2 — PHOBOS FROZEN (14z-74, supersedes m1)** | fingerprint `9deda0808e87601b10e2171405805d4669ba2624` | `build/hui27`; REGISTERED `-> huitzil-m2`. = m1 + decision D5 (the pcrel-scan no longer corrupts the ported OBJ bank table; delta exactly 24 bytes). Maintainer playtest clean; the m1 expectation set (renamed to huitzil-m2) is GREEN on it, and Phobos-vs-Demitri/Sasquatch/Q-Bee/Bishamon are bit-identical to m1 across 14,621 frames each. **m1's 22c016ac can no longer be produced from the tree** — that is why it was superseded rather than kept. Prior m1 text follows: The first full-roster tenant frozen. Expectation set `tests/expected/huitzil-m1/`: 38 `.sha1` (self-frozen determinism) + 13 `.masked` (vanilla-legacy under the ram.md mask: exact/window/composite/diverge — classes MATCH the donovan-m3a basis, confirming the beam hooks are legacy-inert) + 17 `.skip` — all 71 replays accounted for, `run_suite.sh vsavjw` GREEN (54 PASS / 17 SKIP). One deviation from the donovan-m3a inventory: `11_pick_donovan` is `.skip` here (it picks the Donovan cell 0x13, unbacked on this Huitzil-only build; the tenant pick is covered by `37_pick_huitzil_cell`). Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/hui26/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. = hui25 + one `[[data_port]]` `grab_hold_keyframes`. The victim's per-frame HOLD position is written by a shared capture positioner (`victim_pos = attacker_pos ± facing-flipped keyframe (Xoff,Yoff)`) that selects a per-ATTACKER keyframe block via pointer table `0xBE27A[attacker_id]`; H reaches it through his ported CLONE `0xc9eb0` (0x27282 fell inside region x026142). vsavj row 0x10 = `0x092C4A` ALIASED character 0's block, so H held the victim with char-0's offsets (dx −27 vs native +74, a ~109px teleport). Fix ports H's OWN vs2 block `0x0C56AA` (len `0x1D80`, sibling-identical to vh2 `0x0C4F3C` through `0x1E1A`) into `wide_ext` `0x40b220` and repoints row `0xBE2BA` — host block `0x092C4A` and every vanilla row untouched. The exact twin of Donovan's `throw_victim_keyframes` (`donovan.toml:711`). **Maintainer-confirmed clean on BOTH grabs (6MP/6HP + 63214) in MAME and FBNeo.** Also this session: FG "slowness" was the broken GFX, not timing — resolved by observation. Gates: full H battery GREEN (boot=legacy masked-v2 EXACT, grab, grab_victim `matches` peak Δ=0, winscreen, pairs, ex, air, walk, df_style, empty_tiles, beam_variants/walk/list6, gfx_layout3, m3a_reproducible). New gate `tests/test_hui_grab_victim.sh` + `tools/check_grab_victim.py` (phase-tolerant relative-offset A/B). OPEN: only the cosmetic win quote (does not block freeze). Retraction (STATE 14z-73): "positioner never invoked" was a false negative — I breakpointed the vanilla copy `0x2802e`, not H's clone `0xc9eb0`. |
| **hui25 — THE BEAM DRAWS CLEAN (14z-71, maintainer-confirmed, superseded by hui26)** | fingerprint `b0fb2f948e04aa53b5e6ab21e2426a47540854bc` | `build/hui25`; prior launcher default. = hui20 + the STRIP fix, i.e. the third defect under the first two. The beam's middle piece is a procedural list-type-4 strip, and (a) vsav's type-4 handler biases tile codes `+0x3800` where vs2's biases `+0x4200` — ONE byte in otherwise byte-identical routines, so ported vs2 data drew art 0x0A00 low (the freeze/reflection tiles); (b) that handler **composes its own bank word** (`ori.w #$2000` = bank 1) instead of taking the object's, so the art could never reach group C through the record path. Fix: a ported type-4 copy carrying bank 4 + vs2's bias + our 0x1000 placement shift, dispatched only to the tenant's children, plus `--strip-tiles` copying the vs2 bank-1 span `0x4EA0-0x4FBF` into group C at `+0x1000`. Maintainer playtest: all three beam variants clean incl. the ES, AND the grab lightning confirmed on both the regular grab and Circuit Scrapper — **the effect family is CLOSED** — and THREE of its four members shared one cause, the dead effect-class row 16 (maintainer A/B: hui17 no electricity, hui18 yes, and hui18 differs by exactly that repoint). Only the 214 explosion stood apart (uncopied tiles). OPEN on this build: the grab VICTIM's sprite placement glitches mid-animation (endpoints correct; per-frame victim-offset data is the suspect), the win quote, FG pacing. Gates: hui_boot (legacy masked-v2 EXACT), beam_list_type6 (now freezing BOTH games' biases for types 4/6/8), beam_anim_walk, beam_variants, audit_empty_tiles on the beam replays, audit_effect_class_rows incl. the tripwire, m3a_reproducible, gfx_layout3, hui_pairs/ex/grab/air/walk/winscreen — all PASS. Docs: `docs/game/atlas/sprite_lists.md`, `docs/game/engine_internals.md` "The sprite-list DRAWER", `docs/project/porting_sprite_lists.md` |
| **hui20 — THE BEAM DRAWS (14z-71, NOT yet frozen, awaiting playtest)** | fingerprint `40cc10b1b6ed1275cb69893393e2530ae38aef2d` | `build/hui20`. = hui17 + the two-stage beam fix, both at ZERO legacy cost. (a) **Effect-class row 16**: every secondary-object pool dispatches on the object's class byte `+0x02` through a 38-row handler table (vsavj `0x080AAC`), index-aligned 1:1 across all three sets; vsav ships rows 16/17/19/31 as STUBS where vs2/vh2 fill 16/17/19. Row 16 is the beam's — measured, our build already set class 16 on the same object at the same frames and loaded the stub (native 598 reads of `0x093460`, ours 593 of `0x080B44`). New root `0x93460:0x306:t0x9306c:f` + `[[code_ptr]]`. (b) **Drawer list-type 6 takeover**: the beam's sprite list is type 12, a composite vsav lacks; its table cannot grow (entry 0's offset IS the length) or move (`(d8,PC,Xn)`), so the port takes over vsav's UNUSED list-type 6 — 0 reads across six legacy replays vs controls of 4329/2702/2260/321 on types 2/10/0/4. **The deadness assumption is NOT load-bearing**: non-tenant lists fall through to vsav's original type-6 code and arm a `$FF010C` tripwire that fails a gate. Legacy inventory identical to baseline run-for-run; `test_hui_boot.sh` masked-v2 EXACT. Gates: beam_anim_walk (flipped to `walks`), beam_list_type6, beam_variants, audit_effect_class_rows, m3a_reproducible, gfx_layout3, hui_pairs/ex/grab/air/walk/winscreen, audit_empty_tiles — all PASS |
| **hui17 — + the 214+P GROUND EXPLOSION (PING #13, 14z-70f, MAINTAINER-CONFIRMED)** | fingerprint `699de9b7ed40e4662f1943b7baaf606082d29dcf` (program unchanged from hui15/16 — the fix is gfx-only, as the shadow fix was) | `build/hui17`. = hui14 + (a) the x088512 root grown 0x3B40 -> 0x3B98 with a RAW tail from +0x3B78, repairing three pc-rel tables that resolved into the ANIM region — a REAL latent repair that is behaviourally inert today (the code that reads them never runs); (b) `extra_tiles/0x10.json` 2 -> **569 tiles**, fixing the grenade's ground detonation, which drew a solid FUCHSIA rectangle because its codes were remapped bank 3->4 but the tiles were never copied. Reproduce ONLY with `tests/replays/hui/83d_hui_grenade_ground.rpl` — 214+**LP** with both fighters walked to their corners; every earlier rig fired MP from start distance, so the bomb hit the OPPONENT and the capture showed the on-contact explosion instead. Gates: gfx_layout3, hui_boot (legacy masked-v2 EXACT), hui_winscreen, pairs, ex, grab, air, walk, audit_empty_tiles, m3a_reproducible — all PASS |
| **hui14 — + the DARK FORCE PALETTE (14z-69p, NOT yet frozen; the palette row was WITHDRAWN in 14z-79 — it overwrote Bulleta's DF block. HISTORICAL)** | fingerprint `c25b3824a82bcf482069bbd14291078cbf8abbbd` | `build/hui14`. = hui13 + one `[[data_port]]` row: palette-seq rows 0x1E-0x21 (vsavj `0x39ACC0`) replaced with the sequence native's DF actually shows (vs2 `0x3ABEDC`, vh2 twin `0x38BEB0`). He now flashes his own warm gold instead of purple; the afterimages stay by design. Legacy-inert because vanilla never requests those ids — guarded by `tests/audit_palette_seq_ids.sh` (10,504 sampled calls, only 0x26/0x27), which is the ONLY guard since the palette path never transits work RAM. Gate `test_hui_df_style.sh` now defaults to `--expect colours-fixed` |
| **hui13 — + the CHILD SHADOW FIX (14z-69o, playtest-confirmed)** | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` (same as hui12 — the fix is gfx-only, the program is unchanged) | `build/hui13`. = hui12 + two tiles (`0x0F8B`, `0x0F8C`) added to the group-C copy inventory via the new per-tenant `build/manifest/extra_tiles/<char>.json`. The child sidekick's shadow CORE resolved to an EMPTY group-C tile and rendered as a solid rectangle; the tiles are referenced by records the `obj_records.py` pointer walk never reaches, so they were never copied. Verified: 0 empty-tile draws over replay 82 (was 2), both tiles byte-identical to vs2, and a pixel A/B at f3500 shows the rectangle become native's tapered shadow (159 px changed, bbox x139-186 y184-199). Gates: gfx_layout3, boot, m3a-reproducible, pairs, ex, grab, air, walk, winscreen, wide_render_content — all PASS |
| **hui12 — the pc-rel TABLE FIX (14z-69i, NOT yet frozen, not yet playtested)** | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` | `build/hui12`. = hui11 + region `x06cac0` forced to its declared 0xEBC (`:f0xca8`) so the row-8 machine's seven pc-rel DATA TABLES sit inside it, with the tail EMITTED RAW (CPS-2 decrypts opcode fetches only, so a data read returns the stored bytes). All seven now read byte-identical to vs2 — they previously resolved into unrelated bytes, which was the "ported machine reads garbage" park. Legacy untouched: boot masked-v2 EXACT, m3a-reproducible bit-exact, and every H gate green (pairs, ex, grab, air, walk, fx_flow, winscreen, df_style, ladder, census). **The beam still does not draw** — measured against native at its own frames (see STATE 14z-69i), so the residual is the emitter/draw path, not the tables |
| **hui11 — PING #10 (14z-68m, NOT yet frozen)** | fingerprint `5c6dbe43e017cb4ee785ef27b63e4790bc9e0622` | `build/hui11` (pinned, PING10_ARTIFACT.md); playtest default. = hui10 + **the win screen actually fixed**: (a) PALETTE — hui10 had given H *Donovan's* set; the byte table at vs2 0x6B2F2 reads through the OPCODE view (proved by Donovan's frozen `vs2_src` 0x3C365C == pool + 0x11*0xA0), so H is row 0x0B = **0x3C329C**, a bright orange/yellow ramp matching the native capture. Self-check: each palette row's last word = 5*row (H 0x37-0x3B, Donovan 0x55-0x59). (b) POSITION — the portrait sat 64px too far LEFT and 24px too low; the per-winner table 0x5F200 row 0x10 was a plain alias (0x0080,0x0098) where vs2 has (0x00C0,0x0080). Fixed with the same slot-following `code_word` rows as Donovan's 14z-45 `win_pos`. Snapshot-verified against the maintainer's native capture. STILL OPEN: the win QUOTE text (*this row's parenthetical — "the fetch's `lea -4(a0,d0.w)` bias means the consumer reads index 0x60+id-1 = 0x6F" — is RETRACTED: 14z-73 measured `d0 = 0x40 + winner id`, and 14z-76 showed the quote text has no absolute pointer to repoint at all. The mechanism is the first-level table's aliased variant half; 14z-116 measured the rest, `engine_internals.md` "The WIN-QUOTE TEXT SYSTEM" §8*), plus the beam family, child-companion shadow, DF style, FG pacing. Gates: boot masked-v2 EXACT, ex, grab, air, pairs, walk, m3a, **and Donovan's own win-pal gate** — all PASS |
| **hui10 — PING #9 (14z-68 close, NOT yet frozen)** | fingerprint `64128aa7465e15378c0082afcc953aa9730744ce` | `build/hui10` (pinned, PING9_ARTIFACT.md); playtest default of `tools/run_hui_behavior.sh`. = hui9 + **the win-screen palette fix** (source re-derived from vs2's win drawer 0x6B29C: the char id is remapped through the byte table at 0x6B2F2 — read via the DATA view — giving H row 0x59, i.e. 0x3C2BBC + 0x59*0xA0 = 0x3C635C, a GOLD ramp; the old 0x3C347C was the pink/lavender guess). Verified in-emulator: win-screen palette RAM reads the gold ramp at both sample frames. Plus three behaviourally-inert shipped fixes (spawner-region boundary, two newcomer-id mask widenings, the obj_hook_extra facility). Gates at cut: boot masked-v2 EXACT, ex, grab, air, pairs, walk, fx_flow, ladder, m3a — all PASS. STILL OPEN: win-pose garbled art blocks, the beam/effect family, the child-companion shadow, DF style, FG pacing |
| **hui9 — PING #8 (14z-67 close, NOT yet frozen)** | fingerprint `9e3105e0be8a5b5c85f5c792c5c9947f49196098` | `build/hui9` (pinned, PING8_ARTIFACT.md); = hui6 + the ping-round fixes: effect byte-map rows (236P ray spawns), c5 companion-record art in bank 5 + spawner bank flips, the throw-arc superset tables (63214 launch yv 16.0 native-exact). Playtest default of `tools/run_hui_behavior.sh`. REMAINING before freeze: the effect-flow closure (NEXT_SESSION recipe), shadow restore, win-pal, DF style, FG pacing |
| hui6 — the ping-#7 reference (superseded by hui9) | fingerprint `b99b73597b7ab09761e0da58e81527db8747c7e5` | `build/hui6`; rebuild: `TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/hui6`. Huitzil at native 0x10 with HIS REAL ART end to end: fighter band at delta 0 in group C bank 4 (native codes, no record remap), select figure/portrait/name, 21-cell wheel, VS splash, HUD mug/plate (pool 0xBE9A/0xBE92), sprite+effect+win palettes, x05c800 escape fix. Cell 0x10 hand-pickable (replay 37: D,D,D from default). Every gate green incl. behavior battery ON this build + oracle (1741). Playtest: `tools/run_hui_behavior.sh`. FREEZE after maintainer confirmation (registry row + expectation set) |
| **donovan-m3a — THE WIDE REFERENCE (FROZEN 2026-08-06, 14z-64, maintainer-ratified)** | fingerprint `4b7d0dc7319ed6cf94a02b22938cdb18946dfddd` | `build/m5_wide` (rebuilds bit-exact from the tree); REGISTERED `-> donovan-m3a`. The M3a de-substitution complete: tenant at native 0x13 via `id_by_profile` (build with `--profile cps2-wide-v1`, no id flag), Jedah fully restored, select family + wheel from group C bank 5 with real medallion art/palettes, ring reuse, variant-id HUD/win-pal, the 14z-2 mirror-victim fix. Masked basis V2 (per-set `mask` file; staging-slot windows for rows 0x16/0x19/0x1A; vanilla logs `tests/expected/vsavj/masked-v2`). Stock twin **6c93cfa8** at `build/m5_stock` (= old ae701ffb + exactly the 2-byte mirror fix). Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/m5_wide/rompath;$ROMDIR" tests/run_suite.sh vsavjw` — **FIXED 14z-78 (maintainer sign-off): this command had been RED since 14z-75** on two `NO-EXPECTATION` replays (`37_pick_huitzil_cell`, `40_pick_pyron_cell`), both added AFTER this set was frozen in 14z-64, so it had no entry for either. 0 FAIL and 0 divergence throughout — never a regression. Both are now `.skip` ("picks a cell this build does not back"), matching `11_pick_donovan`'s precedent. **`huitzil-m2` had the same gap** on `40_pick_pyron_cell` and is fixed the same way. Ruling: a replay added after a freeze may invalidate that freeze. See STATE.md "frozen sets were RED on UNACCOUNTED replays". |
| donovan-m5w — superseded by donovan-m3a | fingerprint `9bac6ee378e1a5ce0674423279c357a4d2a076ec` | `build/m5_wide`; REGISTERED `-> donovan-m5w`. Rebuilt through the fixed romset pipeline (group C zero-filled; `audit_romset_identity.py` clean) + the 14z-60 select-wheel extension. Maintainer playtest confirmed with and without Donovan. Gates: `test_wide_profile.sh`, `test_mame_wide.sh`, `test_wide_render_content.sh` (3,721/3,721 frames pixel-identical to the stock track), `test_romset_identity.sh` — all PASS. Expectation set `tests/expected/donovan-m5w/`: 33 self-frozen `.sha1` + full logs, 14 authored `.masked` (`diverge` ×3, §4 v3 `window` ×4, §4 v4 `composite` ×7), 16 `.skip` — all 63 replays accounted for and **`run_suite.sh` GREEN**. Validate any WIDE build with `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="<rompath>;$ROMDIR" tests/run_suite.sh vsavjw` |
| **m5_stock (the stock twin, re-frozen 2026-08-06)** | fingerprint `6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5` | `build/m5_stock`; rebuilds bit-exact. = the former ae701ffb + EXACTLY the 2-byte mirror-victim fix (PRG:0x0B1A16, byte-attributed). Not registered — the dual-track partner and the rendering gate's reference. Full battery GREEN at freeze |
| ~~m5w~~ **KNOWN-BAD, kept as evidence** | `ac52eeff` | the 14z-60y sprite garble: its `vsavjw.zip` carries group C as byte copies of group B, so the loader served pristine tiles for the patched group B. Do not playtest. `python3 tools/audit_romset_identity.py build/m5w/rompath` names all four shadows |
| null vsavj | `12fbb0e1a137a1420824856d3efb0af8fff57be6` | == reference members; zip repacked deterministically |
| **donovan-m2c (M2b+ASSETS FROZEN 2026-08-02)** | fingerprint `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` | `tools/build_donovan.sh 6 build/donovan6` **AS OF 2026-08-02 — that command today produces `a054de5c` (`donovan-m8-stock`), not this fingerprint; the way back to a tree that builds it is the `freeze/donovan-m2c` tag**; REGISTERED `-> donovan-m2c`; the 14z-42..49 arc on top of M2b-CORE: LS hit-freeze thunks, full ES chain + meter decode, win screen, deity seq-states, accent owner-link fallback, HC motion farm_ports, HUD mugshot/name, select medallion; masked legacy basis = THREE windows (palette staging slot $FF4182-$FF41A1 ratified round 64; audit `tests/audit_mask_window_ff4182.sh`); gates: full battery GREEN (battery_49b) + `run_suite.sh` GREEN by fingerprint auto-detection; maintainer-confirmed rounds 52-64; gfx member sha1s in registry note |
| **donovan-m2b-core (M2b-CORE FROZEN 2026-07-28)** | fingerprint `71601263474dfd7e4afd0741dae696cde22eda4e` | `tools/build_donovan.sh 6 build/donovan6`; REGISTERED `-> donovan-m2b`; sprites/palettes/effects in Jedah's gfx space; rompath carries patched vsav.zip (gfx sha1s in registry note); gates: tests/test_m2b_stage6.sh + oracle/xemu/flavor + tests/test_m2b_scroll3.sh — ALL PASS; select portrait/name/mugshot + attract palette remain (docs/game/engine_internals.md) |
| **donovan-m2 (M2a FROZEN 2026-07-28)** | fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa` | `tools/build_donovan.sh 5 build/donovan5`; all gates green (4 guarded soaks incl. ES-DP spam, round-2, input-chaos / 13-replay masked legacy / oracle / xemu / flavor); supersedes eda50a18 (214P/214K music: engine_data-masquerade farm rows + direct helper stubbed; farm-ref audit clean — 25 stubbed / 4 live); REGISTERED: `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv; validate any build with `ROMDIR=... [MAME_ROMPATH="<rompath>;$ROMDIR"] tests/run_suite.sh` (fingerprint auto-detects the expectation set; masked legacy basis applied automatically) |

## [14z-123 G6 (1)] from «M1 additions (2026-07-25, session 2)»

## M1 additions (2026-07-25, session 2)

| Piece | Where |
|---|---|
| Replay format + MAME runner | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` |
| FBNeo harness (patched frontend) | `emu/fbneo-patches/0001-…`, `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` |
| Legacy suite (10 replays, frozen) | `tests/run_suite.sh`, `tests/expected/vsavj/` |
| Watchpoint write-tracer | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`; `WATCH=addr,len[,r\|w\|rw\|b][,p\|d\|o]`, + `DUMPS` since 14z-98 so a -debug trace run carries its OWN state anchors — every -debug watch configuration is its own timeline, docs/GOTCHAS.md) |
| Pick probe (slot mapping) | `tools/pick_probe.sh` |
| Forced-id boot probe (14z-65) | `tools/force_pick_probe.sh <rompath> <id> <out>` — pokes the commit field across commit->load; verdicts id-hold/load/guard. Validated: vanilla ids load, variant 0x10 wedges on the stage-4 ladder |
| Structural diff | `tools/diff_sets.py` (`--mask-pointers`) |
| Character tables atlas | `docs/game/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) |
| RAM atlas | `docs/game/atlas/ram.md` |
| M1 acceptance review | `docs/project/M1_acceptance.md` (both clauses met; R2 quantified) |
| Write/read tracer | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) |
| Program patcher | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` |
| M2 feasibility | `docs/project/M2_feasibility.md` (3 domains; remaining work list) |
| Patch-tooling test | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) |
| M2 repoint proof | `tests/test_m2_repoint.sh` (mechanism + superset invariant) |
| Select wheel + id space (14z-60) | `tools/select_wheel.py` (decode/verify TABLE A+B, generate a full-coverage walk), `tools/check_wheel_walk.py` (measured vs predicted), `tools/audit_id_space.py` (id width at every consumer + the variant-row alias matrix), `tools/wheel_positions.py` (cell -> screen position, measured from the palette-0x1E cursor ring in OBJ RAM); atlas `docs/game/atlas/select_screen.md`, `docs/game/atlas/id_space.md` |

Run a patched build: `MAME_ROMPATH="<packed_dir>;$ROMDIR" tools/run_mame.sh vsavj ...`

## [14z-123 G6 (1)] from «M2a port pipeline — the single-tenant recipe and the stage ladder»

```sh
export ROMDIR=/path/to/reference/sets
# full chain: audit -> extract (vhunt2 oracle) -> generate -> patch -> pack
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan
# run it (guarded: exception breakpoints + register dump at fault)
MAME_ROMPATH="$PWD/build/donovan/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavj tests/replays/12_donovan_vs_cpu.rpl out.log box
```

Stages: 1 null-relocation scaffolding, 2 passive data, 3 anim + sprite
sub-tables, 4 code + support zones + engine hooks, 5 select plumbing.
Stage gates: `tests/test_m2a_stage{1,2,3}*.sh` (all PASS).

## [14z-123 G6 (1)] from «M2a C0 additions (2026-07-25, session 4)»

## M2a C0 additions (2026-07-25, session 4) — verification harness upgrade

| Piece | Where |
|---|---|
| Crash guard | `tests/lua/replay_guard.lua` + `tools/run_replay_guarded.sh` (`GUARD_DEBUG=0` for cheap/checksum-canonical mode; `-debug` mode for breakpoint crash capture — its checksums are NOT comparable to non-debug runs, docs/GOTCHAS.md) |
| Crash-guard ground truth | `tests/test_crash_guard.sh` (clean negative + vec4/vec3 positive controls) |
| Dual-emulator field comparator | `tools/compare_fields.py` + `tests/fields_m2a.tsv` (debounced anchors; stable/settled/phase field classes; `--exact` for same-emulator) |
| Comparator ground truth | `tests/test_compare_fields_selfcheck.sh` (§4 protocol exercised: MAME/FBNeo agree on `16_xemu_2p`, 1-frame skew) |
| Dump-set completeness | `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS, so a lost dump silently moves the anchor instead of failing. Asserts a per-frame dump directory is complete: `--first/--last`, `--size`, `--addr`, or `--contiguous` for a directory of unknown extent. Run by `tools/run_sim_jtcps2.sh` on every `--wram` run and by `test_mister_sim_anchor` on BOTH legs (14z-107 (7)) |
| Dual-emulator-safe replay template | `tests/replays/16_xemu_2p.rpl` (authoring rules in docs/GOTCHAS.md — vs-CPU replays have emulator-divergent content!) |
| Slot-0x0F pick replay | `tests/replays/11_pick_donovan.rpl` (Jedah on vanilla; per-build expectations via fingerprint dispatch) |
| Auto-detecting suite runner | `tests/run_suite.sh` — `MAME_ROMPATH` fronting, fingerprint → `tests/expected/<expset>/`, `.diverge` expectation kind (exact-frame divergence vs frozen full logs under `expected/<set>/logs/`) |
| Fingerprint / registry | `tools/build_fingerprint.py`, `tests/expected/registry.tsv` (rows only at freeze time, STATE.md decision) |
| Diverge checker | `tools/check_diverge.py` |
| Flicker comparator (hooked-build legacy gate v2) | `tools/compare_flicker.py` + ground truth `tests/test_compare_flicker.sh`; frozen masked vanilla logs `tests/expected/vsavj/masked/` |
| Dispatch ground truth | `tests/test_suite_dispatch.sh` (no emulator; fast) |
| FBNeo runner extensions | `tools/run_replay_fbneo.sh`: `FBNEO_DUMPS` (-hdump), `FBNEO_ROMPATH` zip overlay — **verified to load CRC-changed patched zips** |

## [14z-123 G6 (1)] from «Key findings so far»

## Key findings so far

- vsavj key/range: master `0xfa8f4e33a4b881b9`, encrypted range
  `PRG:0x000000-0x100000` (first 1MB only; the other 3MB of program ROM is
  never opcode-encrypted). Watchdog instruction: `cmpi.l #$726A4BAF, D0`.
- ROM file byte order vs 68k logical order trap: docs/GOTCHAS.md first entry.
- MAME 0.288 `-verifyroms` passes all four sets with `-rompath` pointed at
  `$ROMDIR`; `qsound_hle.zip` and the copied `vhunt2.key` resolved the audit.

## [14z-123 G6 (2)] «Individual gates (as of 14z-123)»

### Individual gates

```sh
export ROMDIR=...
tests/test_decrypt_oracle.sh          # decryption == MAME's, both byte orders sane
tests/test_null_build.sh              # null build bit-identical + deterministic
tests/test_attract_determinism.sh     # 60s attract, per-frame RAM checksums, 2 runs
tests/test_fbneo_smoke.sh             # FBNeo headless boot + 15s crash-free soak
tests/test_m2a_stage4_code.sh         # stage-4 gate: veto lock + guarded moveset
                                      # + masked legacy gate. 14z-97 (#96):
                                      # the legacy target is RESOLVED from the
                                      # build's fingerprint (registry.tsv), so
                                      # it follows each freeze — today
                                      # donovan-m9-stage4, V2 basis. It used to
                                      # pin donovan-m2c + the V1 basis + three
                                      # first-divergence constants.
tests/test_m2a_stage4_oracle.sh [rp]  # vsav2-as-oracle: anchors/neutral-exact/
                                      # HP-trajectory/comparative bound (17+18 replays)
tests/test_m2a_stage4_xemu.sh  [rp]   # dual-emulator: MAME+FBNeo field agreement
tests/test_m2a_flavor_selector.sh [rp]# Start-hold flavor latch (stage 5)
tests/test_don_sword.sh        [rp]   # sword-swing behavior gate (anim node)
tests/test_don_accent.sh       [rp]   # palette locks: accent steadiness, VICTOR
                                      # byte guard + cycle, fixture-override rows,
                                      # shock-window vanilla lock (palette ROM->RAM
                                      # is RAM-gate-blind — these are the only locks)
tests/test_don_sound.sh        [rp]   # sound-ring gate: NO vsavj music-range id may
                                      # be enqueued + frozen per-replay id inventories
                                      # (sound is invisible to every other gate)
tests/run_battery_m2.sh [outbase]     # THE deliverable battery: audit + all of the
                                      # above in order; run before ANY build commit
tests/audit_wide_phase_a.sh           # WIDE Phase A measurements (rerunnable; ground-
                                      # truths its own instrument before trusting nulls)
tests/test_wide_profile.sh            # WIDE profile gate: emulator superset invariant
                                      # + inertness + the B4 canary (needs FBNEO_REF)
tests/test_mame_parity.sh             # B5 PREREQUISITE: the pinned MAME source build
                                      # reproduces every frozen oracle log bit-for-bit
                                      # (refuses to run on a WIDE-patched binary)
tests/test_mame_wide.sh               # the MAME twin of test_wide_profile.sh
tests/test_replay_video_selfcheck.sh  # ground truth for replay.lua VIDEO_OUT (the MAME
                                      # framebuffer checksum) — both directions
tests/test_mame_determinism.sh        # RUNS=/JOBS=/PROBE= repetitions; measures the
                                      # run-to-run divergence rate the whole oracle
                                      # assumes is zero (see STATE 14z-59)
tests/test_crypt_boundary.sh          # code above the encryption window is stored RAW
                                      # (load-bearing: character code in the extension)
tests/test_dualtrack.sh               # dual-track. RE-SCOPED 14z-94, MAINTAINER-
                                      # RATIFIED 2026-08-17 (GitHub #95):
                                      # this row said "WIDE is legacy-IDENTICAL to
                                      # stock", which 14z-64's M3a de-substitution
                                      # made false — the two builds carry DIFFERENT
                                      # ROSTERS by construction (m5_stock puts
                                      # Donovan at 0x0F over Jedah; m5_wide restores
                                      # Jedah and takes native 0x13), so every
                                      # select-reaching replay must differ. Now:
                                      # bit-identical UP TO select entry with the
                                      # onset frozen per replay (890, 3190 for the
                                      # mid-attract one, none for 06_test_mode);
                                      # patched-slot content differs; and the attract
                                      # divergence is attributed at its ONSET (frame
                                      # 4267, 3 bytes in the P1 effect-channel record
                                      # pointer) with the SAME writer PC on both legs
                                      # — data, not control flow. NOT in any runner
                                      # (#30): that is how it stayed red 11 days
tests/test_phasec_image.sh            # Phase C step 2: image grows to 6MB, WIDE romset
                                      # shaped+runs, extension PROVABLY READ (negative
                                      # control), stock build untouched
tests/test_phasec_spaces.sh           # Phase C: the declarative address-space model is
                                      # byte-for-byte inert on a stock build, and the
                                      # WIDE extension is gated by construction
tests/test_fbneo_instruments.sh       # B5b: FBNeo write tap (non-perturbing + re-derives
                                      # a known MAME finding), pokes, and address-resolved
                                      # dumps cross-checked byte-for-byte against MAME
tests/test_input_integrity.sh         # ground truth for the input-integrity check:
                                      # silent on clean runs, catches a stray
                                      # un-scripted press at the right frame. MAME's
                                      # window takes focus even under -video none,
                                      # so host keys reach the emulated controls
tests/test_compare_window.sh          # ground truth for the §4 v3 "bounded
                                      # re-convergent window" class: accepts the
                                      # select-screen shape; rejects flicker, a
                                      # drifting onset, a run that never
                                      # re-converges, and a silently-identical
                                      # pair. No emulator needed
tests/test_select_wheel.sh            # the select cursor, 4 sections: tables decoded
                                      # from the ROM; a generated walk over all 128
                                      # (cell,direction) pairs measured in MAME; four
                                      # negative controls on the checker's verdicts;
                                      # and all 16 cell screen positions measured
tests/test_id_space.sh                # freezes the id space: 0 out-of-range variant
                                      # rows, the 5 sites that fold the id to 4 bits,
                                      # and vsav2's 2-fold/6-widened reference shape
tests/audit_id_writers.sh             # on-demand (22 MAME runs): every character-id
                                      # VALUE vanilla ever assigns, both player structs.
                                      # Fails if any legacy gameplay path writes an id in
                                      # 0x10-0x1F — the invariant that would make a tenant
                                      # on a variant id superset-safe by construction
tests/audit_mask_window_ff4182.sh     # on-demand: proves the masked palette-staging
                                      # window hides the designed diff and nothing else
tests/audit_mask_window_ff42a2.sh     # 14z-88: the ROW-0x1D staging window
                                      # ($FF42A2-C1, V3 basis) attributed on the
                                      # tenant-content .sha1 replays the 14z-87b
                                      # medallion move shifted: pre-move vs
                                      # post-move build IDENTICAL under the V3
                                      # mask, DIFFERENT under V2 (control), +
                                      # unmasked first-div frame. Args: pre
                                      # rompath, post rompath, replay names
tools/freeze_masked_basis.sh          # 14z-88: (re)generate a vanilla masked
                                      # basis (logs+sha1, double-run determinism)
                                      # under a given MASK_RANGES — masked bytes
                                      # are SKIPPED from the checksum, so every
                                      # window addition needs a NEW basis dir
                                      # (masked / masked-v2 / masked-v3)
tests/test_select_arrays.sh           # the select record-pointer arrays (M3a): all THREE
                                      # UI pieces (portrait 0x26742A, name 0x2675AA,
                                      # highlight 0x268A02), 32 rows per player with P2 at
                                      # +0x80, indexed by cell/id with NO 4-bit fold, rows
                                      # 0x10-0x1F variant aliases. A tenant at 0x13 costs
                                      # SIX longs. Static model + a one-byte corruption
                                      # control + the ENGINE's own row sequence for each
                                      # piece. ~13s
tests/test_tenant_id.sh               # the tenant id is a BUILD INPUT: resolution,
                                      # the variant-id-needs-profile refusal, and the
                                      # frozen-reference reproducibility guard (no
                                      # id_by_profile until M3a completes). EXTENDED
                                      # 14z-77 (M3b slice C) with ROW OWNERSHIP: the
                                      # per-FILE stamp, row_owner resolution, the
                                      # row_applies truth table, row_hex selection, and
                                      # the multi-tenant refusal in BOTH directions
                                      # (asserted by no test before this; the loop
                                      # slice deletes the refusal and flips it).
                                      # Pure functions, no ROMs, no emulator. ~1s
tests/test_shim_charid.sh    [bd id] # 14z-77 (M3b slice G): the init shim can
                                      # identify WHICH tenant it runs for —
                                      # (0x382,A6) already holds the character id
                                      # at char-init. That was an ASSUMPTION the
                                      # merged shim's per-id flavor chain rests
                                      # on. (F2 FIXED 14z-82: the merged shim
                                      # is assembled at engine_here and planted
                                      # on EVERY declaring tenant's row, each
                                      # chain block exiting into its OWNER's
                                      # handler; audit_merged_legacy section 0
                                      # asserts HENT==SHIM. The id-read finding
                                      # here is what the chain rests on.)
                                      # Measured on BOTH player structs
                                      # ($FF8782 and $FF8B82 = 0x13), 2 replays.
                                      # NEEDS THE FORCED-PICK POKES: replay 11
                                      # never forms a Donovan match and returns a
                                      # meaningless zero, so section 0 proves the
                                      # probe is armed before any verdict. Verdict
                                      # control: offset +0x000 must NOT read the
                                      # id. ~44s. Defaults build/m5_wide, id 0x13
tests/test_type_stamp_census.sh       # 14z-82: the STATIC type-stamp census
                                      # (tools/audit_type_stamps.py) reproduces
                                      # the FROZEN inventory build/manifest/
                                      # type_stamps.toml — every family stamp/
                                      # compare/reader/embedded-walker site,
                                      # source-address-keyed, positive control
                                      # on the six measured sites + negative
                                      # control on the three unported stamps.
                                      # Drift = FAIL (re-review, never absorb).
                                      # 2 verdict controls. No emulator, ~5 s
tests/audit_type_writes.sh            # 14z-82 ON-DEMAND (~8 min, 6 MAME tap
                                      # legs): the DYNAMIC half — every
                                      # family-valued type-byte write's PC must
                                      # map to a frozen stamp row (catches
                                      # register-sourced/computed stamps the
                                      # static scan cannot see). 117-stamp
                                      # rig-liveness control. Run BEFORE
                                      # trusting any renumber-path change.
                                      # Measured 14z-82: all writers in
                                      # inventory; 118/120 NOT OBSERVED
tests/test_hitclass_map_thunk.sh      # 14z-82b: the f7997 fix body (the
                                      # projectile hit-class byte map extended
                                      # to vs2's 80 entries) reconstructs from
                                      # the two ROMs; any committed manifest
                                      # row must match it byte-for-byte. Notes
                                      # "not adopted" while the maintainer
                                      # re-freeze decision is pending. 2
                                      # verdict controls. No emulator, ~2 s
tests/audit_hitclass_map_cost.sh      # 14z-82b ON-DEMAND (NO minute figure
                                      # on purpose — the "~20 min" here was
                                      # measured on the 4+2 replay version
                                      # and was still being read a session
                                      # after the corpus grew to 46. Budget
                                      # on the work formula in the script
                                      # header; poll the process): the
                                      # adoption numbers on a PROBE build —
                                      # the 11,017-frame soak that crashes
                                      # frozen pyron-m2 must END clean; legacy
                                      # A/B bit-identical (measured: 30,284
                                      # frames, zero divergence); fire census.
                                      # REWRITTEN 14z-92 (M4): corpus-wide
                                      # (46 legacy pairings, was 4 + 2), the
                                      # reference is now a NO-THUNK TWIN built
                                      # from the current manifest (the old
                                      # build/pyron20 no longer boots AND had
                                      # stopped being a control), and the crash
                                      # soak has a positive control. RESULT:
                                      # the "legacy enters the map 0 times"
                                      # claim is FALSIFIED — 230 entries over
                                      # 2 replays, all indices < 64, so legacy
                                      # gets vanilla answers; 43/46
                                      # bit-identical. Never freezes the probe.
                                      # EXTENDED 14z-93 with the OTHER HALF:
                                      # section 3 is the TENANT fire census
                                      # (what the thunk BUYS, the number M4
                                      # left open), all 37 hui+pyron rigs on
                                      # verticals built from the CURRENT
                                      # manifests, indices binned in-domain /
                                      # vs2-extension / trap. Huitzil+Pyron
                                      # only — donovan.toml does not declare
                                      # the row. Section 4 diagnoses section
                                      # 0's dead crash control with the same
                                      # probe. THE THREE VERDICTS ARE KEPT
                                      # APART BY DESIGN: "reaches the
                                      # extension", "enters but stays below
                                      # 64", and "NO RIG PRODUCES THE EVENT"
                                      # (the sweep is POOL-vs-POOL, so a
                                      # tenant projectile hitting a FIGHTER
                                      # never transits the map) mean
                                      # different things, and folding them
                                      # is what produced the retracted claim.
                                      # HITCLASS_TENANT_ONLY=1 skips 1+2.
                                      # Verdict logic ground-truthed by
                                      # tests/test_classify_hitclass_probe.sh
tests/audit_ladder_selector.sh         # 14z-95 (GitHub #99) ON-DEMAND (~12 min,
                                      # 2 marathon runs): THE ARCADE-LADDER
                                      # SELECTOR, made rerunnable. #99 is a
                                      # crash at the FIFTH arcade match and
                                      # the investigation's probe lived only
                                      # in a shell history; this is it, and
                                      # it is what #99 resumes from.
                                      # Watches $FF8100 (stage) / $FF8110
                                      # (in-use mask, btst so MOD 32, and
                                      # "sound-state-fed, the run-to-run
                                      # lottery" — why 14z-85f was flaky) /
                                      # $FF8114 (chosen index) / $FF8138
                                      # (bound=6) / $FF8121 (venue).
                                      # SECTION 1 quantifies the #99 BLOCKER:
                                      # ONE ladder advance in 40,620 frames,
                                      # i.e. the marathon exercises TWO rungs
                                      # of eight and then drops to attract.
                                      # MORE advances is reported as an
                                      # IMPROVEMENT wanting a deliberate
                                      # re-freeze; fewer is a regression.
                                      # SECTION 2 is a REGRESSION LOCK ON A
                                      # DEAD HYPOTHESIS, which is why it is
                                      # worth keeping: ram.md:89 records 0x18
                                      # at index 7 of all 36 table-A rows and
                                      # the bound is 6, so if the scan ever
                                      # overran onto index 7, class 0x18 (=24,
                                      # a character that does not exist) would
                                      # reach the opponent's $382 at character
                                      # load — a crash of exactly #99's shape.
                                      # Measured: with the mask saturated to
                                      # 0xffffffff it CLAMPS at idx 6, stage
                                      # 0x0016 (the maximum LEGAL stage), not
                                      # past it. SECTION 3 proves the mask is
                                      # LOAD-BEARING (poking it moves the
                                      # stage) — without that, 1 and 2 would
                                      # be measuring a dead input and every
                                      # reassurance would be vacuous.
                                      # LADDER_FRAMES/LADDER_BUILD override
tests/audit_tripwire_reach.sh          # 14z-93 (GitHub #91) ON-DEMAND (~15 min,
                                      # JOBS=3): DO ANY PLANTED TRIPWIRES
                                      # FIRE IN EXTENDED PLAY? Every build
                                      # carries --tripwire-open, which routes
                                      # UNRECONCILED refs to planted ILLEGALs
                                      # instead of failing (huitzil-m15 52,
                                      # pyron-m9 31, donovan-m7 36,
                                      # merged-m1 70). Nothing had measured
                                      # whether any is REACHABLE. Runs the
                                      # 40,620-frame arcade marathon
                                      # 26_don_arcade_mash with the tenant
                                      # FORCED (it picks a legacy character
                                      # on its own — that is why this was
                                      # invisible) on each frozen build.
                                      # MEASURED: hui41 CRASH 14767 and
                                      # m3b_merged8 CRASH 8887, both the
                                      # tripwire for unresolved 0x494de (a
                                      # 32-bit DIVIDE helper; vsavj has the
                                      # byte-identical routine at 0x47fb6);
                                      # pyron/donovan legs clean. Resolves
                                      # the faulting PC to its fragment line
                                      # so the report NAMES the target.
                                      # FAILS on any fire (rule 6) — never
                                      # counts them down. Honest limit in
                                      # the header: a PASS is RIG-BOUNDED
tests/audit_trap_sound.sh             # 14z-82d, RE-SCOPED 14z-85g (~10 min):
                                      # the MK Plasma Trap SPAWNS (type-69
                                      # pool write) and the sound RING is
                                      # live during the run (id 0x049A —
                                      # which 14z-85g measured as PERIODIC
                                      # AMBIENT, ~144f cadence starting
                                      # pre-trap; the 14z-82d "detonation
                                      # id" attribution is RETRACTED). Still
                                      # locks the (b') crash fix (a crashing
                                      # trap dies before ANY ring activity).
                                      # The PARITY question is CLOSED by
                                      # measurement — see audit_trap_parity
tests/audit_trap_shock.sh             # 14z-85g(2) (~4 min, 2 parallel):
                                      # the trap dome inflicts SHOCK — rig
                                      # 92 (deep-overlap, walk N=60) on
                                      # ours + native; ours must show class
                                      # 0x06 (the ruled remap) + seq7==4 +
                                      # freeze>=0x10, native its own 0x52;
                                      # ALSO asserts the accepted deviation
                                      # (Phobos' 11f attacker freeze)
                                      # PRESENT so drift is loud. Fails on
                                      # huitzil-m9- by design
tests/audit_qs_voice_wav.sh           # 14z-86 (~12 min, 2 -wavwrite runs):
                                      # THE EAR-LEVEL VOICE A/B — per-window
                                      # RMS/high-band vs native audio. Exists
                                      # because it CAUGHT the half-bank
                                      # truncation the register/content gates
                                      # were BLIND to (signed DSP pointer
                                      # compare — equal data, different
                                      # behavior). Synthetic-truncation
                                      # verdict control. Keep BOTH gates
tests/audit_qs_voice_batch.sh         # 14z-86 (~10 min, 2 parallel): THE
                                      # VOICE-BATCH KEYON A/B — every authored
                                      # voice id swept on ours vs the scoped
                                      # vs2 ids on native; WHOLE-RUN content
                                      # multisets compared (per-id window
                                      # attribution is venue-flaky, measured):
                                      # no native signature missing, nothing
                                      # ours plays foreign to vs2's library,
                                      # counts bounded. Verdict control
                                      # (corrupted packed sample -> foreign).
                                      # tools/check_qs_voice_batch.py.
                                      # Self-builds or verifies a build's zip
tests/test_qs_id_table.sh             # 14z-86: the Z80 sound-id-table census
                                      # gate — both games' censuses frozen
                                      # (bases DERIVED from the $3B00 anchors),
                                      # the pilot rows, the code-identity
                                      # licence (only the 2 envelope-base
                                      # immediates differ below 0x34F1), the
                                      # ejection content lock (vs2 0x255800 ==
                                      # vsav 0x18D800), + 2 verdict controls.
                                      # Static, ~5 s. tools/audit_qs_id_table.py
tests/test_kernel_voice_tables.sh     # 14z-96 (GitHub #101, ci_static): the
                                      # KERNEL per-class voice tables — vsavj's
                                      # variant halves are byte-copies (the
                                      # grunt's alias shape), vs2's carry the
                                      # newcomers' real rows (frozen verbatim),
                                      # the event-nibble law on all 256
                                      # entries, and 0x2a1/0x2a2 FREE in both
                                      # games' Z80 tables (the silence
                                      # premise). 2 verdict controls. Static,
                                      # ~5 s warm. Dynamic half:
                                      # audit_hui_grunt + replay 95
tests/test_capture_pose_sources.sh    # 14z-99 (GitHub #104, ci_static):
                                      # THE OPTION-(a) FIX PREMISES,
                                      # frozen — the ruling was "measure
                                      # first" and this gate IS the
                                      # measurement, rerunnable. Locks:
                                      # the positioner's id-unmasked read
                                      # (byte-exact at PRG:0x028058);
                                      # exactly 5 consumers of 0xBE27A;
                                      # the 14-offset-alias + 2-material-
                                      # ized-alias block shapes; source
                                      # twins for all 16 attackers in
                                      # BOTH vs2 and vhunt2 (tenant rows
                                      # distinct, stride-equal, vs2==vh2
                                      # cross-oracle); every BASE
                                      # sub-block byte-identical
                                      # vsavj==vs2 (the legacy-safety
                                      # premise of the wholesale port);
                                      # the signed-16-bit bound (worst
                                      # 0x3730); the 15-block/0x11BD0
                                      # port inventory. 2 verdict
                                      # controls. Static, ~5 s warm
tests/test_qs_songs.sh                # 14z-86: the authored-Z80-song machinery
                                      # (WIDE v1.1 vsw.z01/z02 content members;
                                      # tools/build_qs_songs.py). Placements ==
                                      # vs2 source bytes, id rows exact,
                                      # vanilla-span identity, the b0==0
                                      # reachability law, 3 verdict controls
                                      # (corrupt byte / live-id refusal /
                                      # non-zero-span refusal). Static, ~5 s
tests/audit_trap_parity.sh            # 14z-85g (~5 min, 2 parallel runs):
                                      # THE TRAP-SOUND PARITY GATE — replay
                                      # 87 on native vsav2 AND the build;
                                      # frozen per-attempt inventories:
                                      # native 0739(spawn)/010b/073a(timer
                                      # detonation); ours 00d8(the RESTORED
                                      # ejection, 14z-86 authored Z80 song)
                                      # + 010a + 0199 (the RESTORED chirp,
                                      # 14z-85g sound_stub — same sample
                                      # bytes both). RE-FROZEN 14z-86,
                                      # ground-truthed failing on the
                                      # pre-pilot shape. FORBIDS 0739/073a
                                      # on ours (music ids on vsavj).
                                      # Verdict control + per-leg liveness
tests/audit_type_dispatch_range.sh    # 14z-82, EXTENDED 14z-85 (~15 min, 7
                                      # guarded runs): on the MERGED build,
                                      # ZERO obj_hook dispatches in the
                                      # ORIGINAL 114-119 range during
                                      # hui/pyron replays (a census-missed
                                      # stamp would land there), renumbered
                                      # range LIVE for huitzil, originals still
                                      # serving donovan; verdict control sees
                                      # originals on the ref build. Reads
                                      # type_map.json. 14z-85 §4-6: 0x54470
                                      # family (59-75) dispatch LIVE on H+P
                                      # legs with the tag-stub tripwire
                                      # SILENT; solo verdict control
tests/audit_phase_mode_cost.sh        # 14z-77: what Phobos' phase-gated latch
                                      # costs Donovan — the maintainer's ratified
                                      # condition for adopting it in the merge.
                                      # Builds a phase-mode Donovan and A/Bs it
                                      # LIVE against donovan-m3a (no registry row
                                      # exists for it, and run_suite refuses an
                                      # unregistered fingerprint). LEGACY must be
                                      # bit-identical (4 replays, 30,284 frames —
                                      # it is); his OWN content must diverge AND
                                      # re-converge (24-135 frames in 13-16 runs
                                      # from the exact frame the shim runs, then
                                      # 6,000-9,700 identical incl. a full
                                      # round-2). An IDENTICAL result FAILS — that
                                      # means the rig stopped forming the match.
                                      # On-demand, ~15 min
tests/audit_region_movability.sh      # 14z-77, RE-FROZEN 14z-78: which regions
                                      # can live in wide_ext? ALL OF THEM NOW —
                                      # anim, aux0_4, hitbox(+proj) and x06717c
                                      # (a CODE region, so code executes from
                                      # the raw extension). anim was the ONE
                                      # crasher and M3b's binding constraint;
                                      # its vec3 (odd A0, vanilla PC 0x015098)
                                      # was NOT a layout limit but a placed
                                      # address baked into two donovan.toml
                                      # thunk bodies — fixed 14z-78 with
                                      # region_subst, and the class is now a
                                      # BUILD error (test_thunk_addr_literal).
                                      # Three tenants need 98,488 of the
                                      # 344,640-byte crypt window, was 470,200.
                                      # MEASURED ON ALL THREE (14z-123): H/P
                                      # anim run from wide_ext too, with a
                                      # LIVENESS control — the tenant's +0x60.l
                                      # equals the build's own table row and
                                      # the anim node pointer sits inside the
                                      # moved range at three in-match frames;
                                      # CASES= selects the six cases.
                                      # Expectations frozen BOTH ways: if anim
                                      # crashes again that is a REGRESSION.
                                      # On-demand, ~4.5 min
tests/test_shared_writes.sh           # 14z-79b: THE FROZEN SHARED-SURFACE WRITE
                                      # INVENTORY. test_hui_ladder.sh already
                                      # requires every op to write free space or
                                      # a VARIANT ROW — but it runs stages 1-3,
                                      # and the row that broke Bulleta was stage
                                      # 4. Every write landing on
                                      # vanilla-readable bytes is frozen per
                                      # tenant in build/manifest/
                                      # shared_writes.toml (D 67 / H 59 / P 50);
                                      # any addition, removal or change FAILS,
                                      # which is the point — it forces someone
                                      # to establish whose bytes a new write
                                      # touches. GROUND-TRUTHED: it flags
                                      # 0x39acc0 +128 on build/hui27, the real
                                      # defect. + 2 verdict controls.
                                      # HONEST LIMIT, stated in the tool: a pass
                                      # means the set is UNCHANGED SINCE
                                      # REVIEWED, not that the writes are safe;
                                      # an entry frozen without checking stays
                                      # wrong and green. tools/
                                      # audit_shared_writes.py. Static, seconds
tests/test_fsm_census.sh [bd]        # 14z-110 (#99): the STATIC object-script
                                      # node-state census gate. Every ported
                                      # node whose +0x17 state byte >= vsavj's
                                      # 80-entry FSM table is enumerated
                                      # (tools/audit_fsm_census.py, family-aware
                                      # node-record signature + vs2 classify
                                      # oracle) and locked to
                                      # build/manifest/fsm_census.toml. TWO
                                      # negative controls. Needs ROMDIR (vs2
                                      # oracle). ci_static, seconds.
tests/test_reaction_hook_d2.sh [bd]  # 14z-110 (#99 FIX): the reaction_hook
                                      # D2-WINDOW gate. RECONSTRUCTS the
                                      # 82-byte thunk from first principles,
                                      # re-derives the four d2 cases from
                                      # vsav2.zip (table 0x016DE4, entries
                                      # 0x50-0x53), asserts dispatcher 2
                                      # byte-identical to vsavj's own decrypted
                                      # dump (ruling (a)), and the census 6/6
                                      # native-0x51. THREE verdict controls.
                                      # ci_static, seconds.
tests/audit_don_vs_cpu.sh            # 14z-110 (#111): deterministic
                                      # Donovan-vs-CPU-{Phobos,Bishamon,Pyron}
                                      # via the venue byte $FF8121 (0x02/03/05),
                                      # liveness-asserted, guard-clean. Closes
                                      # the coverage gap #99 fell through.
                                      # Emulator, ~18 min/leg. NOTE #99 does not
                                      # reproduce here on MAME (P1-mash) — the
                                      # gate is COVERAGE, not a crash lock.
tests/audit_df_accumulator.sh          # 14z-123 (inferred_claims row 1): the
                                      # +0x161 accumulator is SASQUATCH'S DARK
                                      # FORCE ARMOR (dispatch_16 row 0x0A,
                                      # PRG:0x047E60 — NOT Aulbath's; the 14z-121
                                      # block attribution read the next table's
                                      # heads as boundaries). Four legs on
                                      # pristine vsavj + the merged build: armor
                                      # (LP+LK: +0x15E=0x200, cr.LP/MP/HP add
                                      # 20/30/40, no reaction, break past 60,
                                      # decay 240), hphk (never arms), nodf (the
                                      # must-fire negative), merged (field trace
                                      # byte-identical = superset). 9 frozen
                                      # lines; FREEZE=1; replay df/105. ~3 min.
tests/test_advancing_guard.sh          # 14z-123 (inferred_claims row 8): the
                                      # 0x27082/0x2797A step family is the
                                      # ADVANCING GUARD (guard push), NOT a
                                      # throw mash-escape: a grounded block
                                      # opens a 14-tick window +0x1AB, button
                                      # presses feed +0x170, the ATTACKER is
                                      # pushed 91/115/157 px (lists byte-
                                      # identical vsavj PRG:0x02871C). vs2
                                      # fires at a weighted >=10, vsavj +1/
                                      # press with an RNG roll below 8. Four
                                      # legs (vs2 + vsavj), 44 frozen lines;
                                      # FREEZE=1; rig = name_moves victim
                                      # part 4 (regeneration-checked). ~3 min.
tests/audit_front_comparator.sh        # 14z-123 (inferred_claims row 4): what
                                      # RAM:$FF8127 is — the FRONT/BACK draw-
                                      # order selector: writer PRG:0x02228E
                                      # compares byte +0x10 of each fighter's
                                      # current ANIM NODE (a per-pose depth
                                      # key, 19-value vocabulary frozen);
                                      # identity exact on every non-capture
                                      # frame of replay 37 (5,486/0). Pristine
                                      # vsavj, reference MAME, ~1 min.
tests/audit_grenade_ground_tiles.sh    # 14z-123 (inferred_claims row 9): the
                                      # 214+LP ground explosion draws native
                                      # vs2's own art tile-for-tile (441 tiles,
                                      # intersection 441, 0 ours-only, 0 blank;
                                      # per-CONTENT across every detonation
                                      # frame — phase-free). Closes the 14z-70e
                                      # 'most likely fixed' guess. Replay 83d,
                                      # merged build vs native, ~1 min.
tests/test_ladder_tenant_vs_palette.sh # 14z-123 (inferred_claims row 7):
                                      # the 0x3A3CA0 pool MEASURED ON SCREEN
                                      # for a tenant CPU opponent — it is the
                                      # 1P opponent-ROULETTE tag's mini-art
                                      # palette (PRG:0x00B094, once per ladder
                                      # match, OBJ row 0x0A), NOT an attract
                                      # path, NOT read by the VS screen (1P vs
                                      # CPU Phobos == 2P vs Phobos, 0 px). The
                                      # tag shows the BASE character's name/
                                      # art for a tenant (cosmetic backlog).
                                      # 4 -debug legs, red-poke A/B, liveness
                                      # via the P2 hitbox base; FREEZE=1.
                                      # Replay 111 = 110 cut at 3600. ~4 min.
tests/test_index_window_thunk.sh [bd] # 14z-79: the (b') index-window thunk at
                                      # engine site 0x018460. RECONSTRUCTS all
                                      # 470 body bytes from the two reference
                                      # ROMs rather than diffing with a
                                      # tolerance — old_hex proves only that we
                                      # patched the right PLACE, and one wrong
                                      # trampoline address is a SILENT
                                      # wrong-routine dispatch, the very class
                                      # the thunk removes. Also asserts the
                                      # engine around it is vanilla (the table,
                                      # the sibling dispatcher incl. 0x01850A,
                                      # the shared handler pool) and re-derives
                                      # the table at 80 entries. 3 verdict
                                      # controls (perturb a trampoline, a table
                                      # word, a danger body — each must be
                                      # CAUGHT) + a build-level negative control
                                      # (FAILS on a pre-thunk build, naming why).
                                      # Static, no emulator, ~40s. Defaults
                                      # build/hui30
tests/test_thunk_addr_literal.sh      # 14z-78: a placed address baked into a
                                      # hand-authored site_thunk body is a BUILD
                                      # error. Third guard of the family whose
                                      # first two cover the tenant ID; this one
                                      # covers the ALLOCATOR's output, the gap
                                      # that made anim look immovable for a
                                      # session. Opcode-anchored + word-aligned
                                      # (an unanchored scan reads operand pairs
                                      # as addresses); the anchor set is the
                                      # documented coverage boundary — a raw
                                      # longword in embedded data is OUT OF
                                      # SCOPE and section 3c says so rather than
                                      # letting section 1 read as total cover.
                                      # 4 sections incl. all three real
                                      # manifests staying quiet, the
                                      # addr_literal_ok escape hatch, and 2
                                      # verdict controls. Runs the GENERATOR
                                      # ALONE against an extract dir; never
                                      # edits a tracked file. No emulator, ~40s
tests/test_region_overlap.sh [bd...]  # 14z-77: can the tenants' shared source
                                      # spans be placed ONCE? M3b_plan Phase 2
                                      # item 2 assumes yes; MEASURED, four of the
                                      # 17 cannot. Freezes 17 shared / 8 name
                                      # collisions (7 generic per-tenant names +
                                      # x088512's extent) / 13 unique, and 2000
                                      # CONFLICTING bytes over x026142/x028122/
                                      # x05c800/x2b7ef4 — fields two or more
                                      # tenants write differently, so only one
                                      # can ship. Two-tenant spans report
                                      # UNDECIDABLE, never a reassuring zero.
                                      # Section 3 is the control that placement
                                      # normalisation is load-bearing: 7591 raw
                                      # -> 2000, i.e. 73% of the raw number is an
                                      # artefact of three INDEPENDENT builds'
                                      # allocators. tools/audit_region_overlap.py
                                      # (--no-normalise is the control only,
                                      # never a verdict). Static, ~1s
tests/test_manifest_merge.sh          # 14z-77 (M3b slice F): what the three
                                      # tenant manifests DO when merged. Freezes
                                      # the shared-row dedup counts (space 9->3,
                                      # obj_hook 6->2, wheel 3->1, site_thunk
                                      # 34->28, port_patch 90->87) and the exact
                                      # 12-collision inventory in TWO classes:
                                      # THREE real blockers ([init_shim] once,
                                      # [table_fix] twice — TOML singletons, so
                                      # the schema cannot express two) and SIX
                                      # that DISSOLVE on the WIDE track (all
                                      # three tenants agree on new_hex_variant,
                                      # and a merged build is a WIDE build by
                                      # construction). A span collision is
                                      # invisible to row dedup AND to
                                      # patch_prg.py's overlap assertion, hence
                                      # its own check. 4 permissiveness
                                      # controls. No ROMs, ~1s
tests/test_tenant_loop.sh             # 14z-80: THE MERGE GATE. A 3-tenant patch
                                      # composes AND applies — 590 ops, ZERO op
                                      # collisions, patch_prg writes 12 members.
                                      # Nine sections, GENERATOR ALONE against the
                                      # existing extract dirs (~17s, no emulator,
                                      # SKIPs without them). HONEST LIMIT, stated
                                      # in the header: that is the PROGRAM half
                                      # ONLY. The gfx half is single-tenant by
                                      # decision, no merged image has run in an
                                      # emulator, and no legacy gate has seen one.
                                      # "N tenants generate", "the patch applies"
                                      # and "the ROM is correct" are three
                                      # different statements; this makes the first
                                      # two. Sections: determinism; N=1 frozen per
                                      # tenant (D 243 / H 259 / P 205) with no
                                      # tenant-suffixed side file; N=2 436 and
                                      # N=3 590 of 707 declared; each tenant's
                                      # regions at DISTINCT addresses (the four
                                      # shared names are different spans);
                                      # 4 shared REGION rows reaching every
                                      # tenant's copy; 4b the obj_hook union
                                      # (17/17, entries ATTRIBUTED per tenant —
                                      # a count alone cannot tell whose copy);
                                      # 4c slot_table rows at 3 distinct slots +
                                      # the agreeing-duplicate count; 4d both
                                      # N-way chains DECODED (ids in declaration
                                      # order, each element with its own data
                                      # pointer); 5 zero collisions AND patch_prg
                                      # actually applying it. 5 VERDICT CONTROLS,
                                      # one of which caught ITSELF perturbing
                                      # nothing (`set() or {...}` is falsy)
tests/audit_merged_legacy.sh          # 14z-81: THE MERGED-LEGACY MEASUREMENT,
                                      # rerunnable (~45 min, on-demand). Builds
                                      # build/merged1 (3-tenant program image
                                      # against the zero-filled wide0 overlay,
                                      # gfx skipped — LEGACY-ONLY, never
                                      # playtest, no registry row on purpose),
                                      # proves the rig forms all three tenants'
                                      # matches (guarded char-init probes) and
                                      # merged determinism, then (a) THE
                                      # LEGACY REPLAYS vs the frozen vanilla
                                      # masked basis (V2; the mask comes from
                                      # donovan-m5/mask) — the list is a GLOB
                                      # over tests/expected/donovan-m5/*.masked,
                                      # so it grew 14 -> 47 with the 14z-89
                                      # legacy-pairing promotion and the
                                      # runtime grew with it (~45 min -> ~2 h);
                                      # a new .masked there joins this leg with
                                      # no edit here — dispatched through
                                      # donovan-m3a's
                                      # ratified class table VERBATIM, except
                                      # 04's RATIFIED merged-specific inventory
                                      # ({1525,2005,2009,2195}/889-1104,
                                      # maintainer 2026-08-12, encoded inline
                                      # in the script by design) — any other
                                      # deviation FAILS with the measured shape
                                      # + a proposed spec line, never a widened
                                      # tolerance — and (b) tenant content vs
                                      # the three frozen single-tenant builds
                                      # (guard-clean + first-divergence floor +
                                      # classified report). 14z-83 result:
                                      # FULL GREEN at leg (a) 14/14 — the
                                      # first all-green merged measurement.
                                      # CURRENT (14z-89, leg (a) grown to 45
                                      # by the legacy-pairing promotion):
                                      # 42 PASS / 3 FAIL, leg (b) all six
                                      # guard-clean. The 3 are measured and
                                      # attributed, awaiting rulings (STATE
                                      # "DECISIONS PENDING — 14z-89"): 21/26
                                      # arm the type-6 tripwire on legacy,
                                      # 12 measures the UNION of the two solo
                                      # shapes. Failing logs kept in
                                      # build/gate_failures/
tests/audit_walker_ghost.sh           # 14z-91: WHERE does each object-pool
                                      # walker's `jsr (A0)` push its return
                                      # address, and is that longword inside
                                      # the masked dead-stack window? THE
                                      # measurement that gates the walker
                                      # relocation — it is the single piece
                                      # of state the move changes. Measured
                                      # A7 = 0xff7ff6 CONSTANT at BOTH
                                      # walkers over 279,577 dispatches in
                                      # all 49 corpus replays, so the push
                                      # lands at 0xff7ff2-0xff7ff5, inside
                                      # $FF7F00-$FF7FFF. Frozen in
                                      # build/manifest/walker_ghost.toml.
                                      # FAILS rather than widening anything:
                                      # the header says widening the mask is
                                      # NOT the remedy. Cross-check: the
                                      # dispatch counts reproduce
                                      # dispatch_census.toml exactly on a
                                      # different register. ~5 min
tests/audit_walker_repoint.sh [bd]    # 14z-91: after the relocation, does
                                      # ANYTHING still reach the vanilla
                                      # walkers? Closes the residual the
                                      # static caller scan cannot (a target
                                      # computed at runtime). Vanilla entries
                                      # must be SILENT, relocated entries
                                      # must FIRE. NEGATIVE CONTROL is not
                                      # optional and is built in: the same
                                      # instrument on an un-relocated
                                      # REF_BUILD must see the vanilla
                                      # walkers, or every zero is just a dead
                                      # breakpoint. Measured identical counts
                                      # either side of the move (1243 /
                                      # 40236). ~5 min
tests/test_obj_walker_relocation.sh [bd] # 14z-91: the relocation is
                                      # STRUCTURALLY what it claims, from
                                      # patch.json alone — dispatch sites
                                      # covered by NO op, walker bytes
                                      # verbatim, table vanilla-prefixed, the
                                      # copy's own pc-relative dispatch
                                      # resolving to its own table, and every
                                      # caller a 4-byte OPERAND write at
                                      # caller+2 with 4EB9 untouched. 2
                                      # verdict controls. ROM-free, seconds
tools/audit_walker_callers.py         # 14z-91: every reference that can
                                      # reach a walker, enumerated BY FORM
                                      # (abs.l operand / data longword /
                                      # pc-relative / branch). Found 23
                                      # jsr.l and nothing else. Prints decode
                                      # noise with context rather than
                                      # filtering it silently. --toml emits
                                      # the frozen manifest rows
tests/test_freeze_basis_sandbox.sh    # 14z-91: freeze_masked_basis.sh must
                                      # never hand one run's MAME sandbox to
                                      # the next. The documented canary
                                      # command named the same replay twice,
                                      # so the freeze leg inherited the
                                      # verify leg's EEPROM and OVERWROTE the
                                      # basis it had just verified bit-for-
                                      # bit. Scratch repo + stubbed runner;
                                      # the verdict control reconstructs the
                                      # pre-fix tool and requires the defect.
                                      # ROM-free, ~1s
tests/audit_flicker_attribution.sh    # 14z-91: WHY is each gained flicker
                                      # frame in a frozen spec? The
                                      # legacy re-freeze added exactly two
                                      # (donovan-m7 41 +2313, 37 +7168) and
                                      # the rule was that a gained frame is
                                      # not written until it is attributed.
                                      # Both are the palette-fade STAGING
                                      # BUFFER ($FF3F02 + row*0x20, display-
                                      # only per engine_internals): 41 in
                                      # row 0x0C, which donovan.toml:862
                                      # documents this build patching, and
                                      # 37 in row 0x0A. Re-derives it via
                                      # tools/attribute_ramdiff.py against
                                      # NAMED windows, so a byte landing
                                      # outside one re-opens the specs
                                      # rather than widening a window. Also
                                      # fails on an IDENTICAL pair — these
                                      # frames are in the specs BECAUSE they
                                      # differ, so identity means the rig
                                      # died, not that the build improved.
                                      # ~3 min, 4 MAME runs
tests/expected/merged1/               # 14z-91: THE MERGED BUILD'S OWN
                                      # LEGACY CLASS TABLE (47 specs + its
                                      # own mask + a README). audit_merged_
                                      # legacy.sh leg (a) dispatches through
                                      # THIS, not a tenant set. Created when
                                      # eight deviations fired the question
                                      # that audit had pre-registered ("a
                                      # fourth should prompt: does the
                                      # merged build want its own class
                                      # table?"). All eight were the merged
                                      # build diverging LESS than the solo
                                      # prior — strict subsets, none gained.
                                      # NOT keyed by fingerprint: the merged
                                      # instrument is rebuilt every run and
                                      # is unregistered by design, so the
                                      # set is selected by the audit's
                                      # EXPECT constant
tests/audit_dispatch_census.sh        # 14z-89: WHICH type indices does
                                      # LEGACY ever dispatch at the two
                                      # obj_hook sites? Vanilla vsavj over
                                      # the whole legacy corpus (every
                                      # replay with a vanilla basis log),
                                      # breakpoint per site, D0/4 = the
                                      # index, SET-accumulated so a site
                                      # firing 270k times costs one line.
                                      # Measured: 0x054470 9 types observed,
                                      # 0x05E542 31. FROZEN in build/manifest/
                                      # dispatch_census.toml — a NEW index
                                      # FAILS.
                                      # THE COMPLEMENT IS NOT A FREE LIST
                                      # (corrected 14z-91). It was read as
                                      # "50 and 83 indices a tenant type can
                                      # take over"; a pool-attributed STATIC
                                      # sweep (forward from each pool's
                                      # allocator, 0x16F8E / 0x16FBA) puts
                                      # the TRUE free lists at 1 and 6. This
                                      # corpus reaches 9 of 58 real spawn
                                      # types at one site and 31 of 108 at
                                      # the other — the same coverage
                                      # artefact that falsified list-type 6,
                                      # ~40x larger. NO REPOINT SHIPPED ON
                                      # IT: the 14z-91 fix relocates the
                                      # WALKER instead (see obj_hook in
                                      # patch_index), so tenant types stay
                                      # above the vanilla entry count where
                                      # vanilla cannot reach them BY
                                      # CONSTRUCTION. ~2 min, JOBS-parallel
tools/probe_hook_removal.sh           # 14z-89: CAUSAL attribution for a
                                      # legacy-cycle regression — rebuild a
                                      # tenant with named hooks REMOVED and
                                      # re-measure a legacy replay against
                                      # the vanilla basis. The probe is not
                                      # shippable (the tenant loses a
                                      # feature) and does not need to be:
                                      # the legacy replay never touches the
                                      # tenant. Named both 14z-89 root
                                      # causes after dump diffs stalled at
                                      # "extra cycles somewhere":
                                      # 38 <- fixture_row0f_override_bank0/1
                                      # (two cmpi.b at venue fixture-load
                                      # sites LEGACY runs every venue load),
                                      # 24 <- the two [[obj_hook]] table
                                      # extensions. Control in the header:
                                      # the unmodified build must still FAIL
                                      # the same replay. ~5 min per probe
tests/audit_don_lilith_ko.sh          # 14z-97 (GitHub #103): a DONOVAN P1
                                      # DEATH in arcade stalls the lose flow
                                      # ~8,000 frames — OPPONENT-INDEPENDENT
                                      # (corrected 14z-97 (9); the Lilith in
                                      # the name is just the poke-free repro
                                      # his own ladder provides). Normal
                                      # flow: 580f, identical merged vs
                                      # pristine vanilla for a legacy P1.
                                      # Regression-locks the DEFECT
                                      # (EXPECT_STALL=1, the #98 discipline)
                                      # + a Victor control leg. ~5 min, 2
                                      # parallel MAME runs. ROOT-CAUSED
                                      # 14z-98 (see the next row); a probe
                                      # with the x026142 pcrel_escape_fix
                                      # flips this to FLOWED 560. Flip
                                      # EXPECT_STALL when the fix ships.
tests/audit_don_ko_writer.sh          # 14z-98 (GitHub #103): THE ROOT-CAUSE
                                      # LOCK — who writes Donovan's HP at
                                      # his arcade death, PC-attributed,
                                      # NON-DEBUG (read_tap, canonical
                                      # timeline). The judge kills on WHITE
                                      # HP's sign (+0x52, engine_internals
                                      # "THE ROUND JUDGE"); the x026142
                                      # pc-rel escape (vs2 0x262A4 bra.w
                                      # $25F9A) runs his child-object init
                                      # on the FIGHTER and pins hp:=1 with
                                      # white ~200 -> the next hit
                                      # underflows hp, white stays
                                      # positive, unjudgeable. Leg A locks
                                      # that shape (EXPECT_DEFECT=1); leg B
                                      # (Victor) must show the healthy kill
                                      # commit (both HP words 0xFFFF in one
                                      # frame) or nothing is trustworthy.
                                      # EXPECT_DEFECT=0 rehearsed on the
                                      # 14z-98 probe (his death then takes
                                      # the kill commit, f12730) — that
                                      # rehearsal caught the RH-19 window
                                      # trap now documented at leg A.
                                      # ~9 min, 2 parallel MAME runs.
                                      # WEAKEN_P1=1 (14z-99, both #103
                                      # audits): the fix-verification
                                      # mode — the natural-mash death is
                                      # LOTTERY-BOUND per build and the
                                      # FIXED build's mash-Donovan WINS,
                                      # so EXPECT_*=0 legs read NO-KO/
                                      # NEITHER without it. Cuts his
                                      # inputs at f6100 + one both-words
                                      # 5hp pin; the CPU's own hit kills
                                      # through the real judge. REFUSED
                                      # with the defect EXPECTs (the pin
                                      # would mask the hp:=1 shape).
tests/audit_don_grab_pose.sh          # 14z-98 (6), REBUILT 14z-99,
                                      # GitHub #104: a legacy grab holds a
                                      # TENANT victim on the wrong capture
                                      # record. MECHANISM = THE VARIANT-ROW
                                      # ALIAS class (re-measured 14z-99, NOT
                                      # the "reaction-index generation
                                      # drift" 14z-98 (9) claimed — that and
                                      # its 5-table reorder are RETRACTED in
                                      # the script header): the capture set
                                      # is selected PER VICTIM through
                                      # 32-row structures whose rows
                                      # 0x10-0x1F copy 0x00-0x0F, so a
                                      # tenant is served the base character
                                      # it folds onto. MECHANISM LOCATED
                                      # 14z-99 at PRG:0x02802E: the first
                                      # 32 words of EVERY attacker's
                                      # keyframe block are a per-victim
                                      # offset table indexed by the
                                      # victim's id UNMASKED, and vsavj
                                      # aliases its 0x10-0x1F half onto
                                      # 0x00-0x0F in ALL 16 blocks (14 by
                                      # offset, Zabel/special by
                                      # materialized copies; vs2's are
                                      # real). RULED option (a) full,
                                      # feasibility MEASURED CLEAN —
                                      # premises frozen in
                                      # test_capture_pose_sources.sh;
                                      # implementation + inventory:
                                      # STATE 14z-99.
                                      # Donovan 0x13->0x03
                                      # gets Victor's index 6 (native 11);
                                      # Phobos 0x10->0x00 gets Bulleta's 12
                                      # (native 26); PYRON 0x11->0x01 gets
                                      # Demitri's 11, which IS his correct
                                      # one — right by coincidence, and why
                                      # the field named D and P only.
                                      # SECTION 0 IS A LEGACY-VICTIM
                                      # CONTROL: both engines must install
                                      # the SAME index for a legacy victim
                                      # or the shared-convention premise is
                                      # dead and every tenant verdict here
                                      # is meaningless. The anim region is
                                      # resolved PER VICTIM (anim /
                                      # anim@huitzil / anim@pyron) — doing
                                      # that unconditionally through
                                      # "anim" is what produced the
                                      # retracted 14z-98 (7) Pyron reading
                                      # on the MERGED build. Hold detected
                                      # from hp-DROP samples (no tuned pixel
                                      # window); a non-majority modal is
                                      # NO-HOLD. EXPECT_MATCH=0 freezes the
                                      # defect; flip at the fix. VICTIMS=
                                      # overrides the set.
                                      # Rig: replays/96_don_victor_grab.rpl
                                      # (4 connects/run, no HP pokes).
                                      # ~12 min, 8 MAME runs (2 at a time).
tests/audit_win_pal_auto.sh           # 14z-99, GitHub #105: with AUTO
                                      # selected by the WINNER, the 2P
                                      # victory screen draws a TENANT
                                      # winner's portrait WHITE (the
                                      # maintainer's captured surface,
                                      # reproduced from their captures).
                                      # 3 legs: A merged+AUTO = the
                                      # frozen defect (EXPECT_WHITE=1,
                                      # flip at the fix); B merged
                                      # no-AUTO must stay COLORED; C
                                      # PRISTINE VANILLA + AUTO must
                                      # stay COLORED (the not-ours
                                      # control — vanilla renders its
                                      # AUTO winner fine, so this is
                                      # ours). Verdicts SCAN the dump
                                      # window over 0x90C2A0 — no pinned
                                      # frame constants. RECORD-LEVEL
                                      # fact for the fix: the win-pal
                                      # colors arrive AFTER the screen
                                      # (late upload, not absent).
                                      # LEG D = the 1P-vs-COM flavor
                                      # (replay 104, real-KO win,
                                      # field-confirmed "one of the
                                      # offending screens") — the
                                      # flavor the maintainer plays.
                                      # Merged+legacy+AUTO MEASURED
                                      # 14z-123 (leg E, replay 105 — P1
                                      # on the default cell, inputs ended
                                      # at the KO): COLORED, with P1 =
                                      # Demitri's base and P2 KO'd
                                      # asserted, else DEAD.
                                      # AUTO is AUTO-GUARD, not
                                      # autoplay; rigs for this screen
                                      # END INPUTS AT THE KO and sample
                                      # densely (the MAP screen comes
                                      # AFTER the win screen — the two
                                      # 14z-99 game gotchas). Rigs:
                                      # replays/103_tenant_2pwin_auto
                                      # (= 61 + three AUTO lines) +
                                      # replays/104_1p_auto_ko_win.
                                      # ~10 min, 4 MAME runs.
tests/audit_continue_ladder.sh        # 14z-98 (4), GitHub #102 (CLOSED
                                      # 2026-08-19, maintainer-ruled NOT
                                      # OURS — this is now the REGRESSION
                                      # LOCK, keep running it): THE
                                      # DISCRIMINATOR — does a loss+continue
                                      # reset the arcade ladder's in-use
                                      # mask ON PRISTINE VANILLA with a
                                      # legacy character? Measured YES:
                                      # vanilla venues 06->0E->12, loss,
                                      # continue (~960f, $8004=000E), mask
                                      # 1->0, pool restarts 04->0A->06 (a
                                      # repeat); merged same mechanism
                                      # (0x401->0). Both #102 symptoms =
                                      # the vanilla envelope; the tenant
                                      # correlation = "switching requires
                                      # continuing". Leg A red would mean
                                      # the behavior was OURS — reopen
                                      # #102. NO kill pokes by design
                                      # (audit_kill_poke_shape). Venue
                                      # VALUES are lottery draws; the
                                      # RESET SHAPE is the assertion.
                                      # ~20 min, 2 parallel marathons.
tests/audit_kill_poke_shape.sh        # 14z-98 (2): a 2-byte HP kill poke
                                      # (f:ff8450:0001) manufactures #103's
                                      # unjudgeable state on ANY character
                                      # (white stays ~288; the judge reads
                                      # WHITE's sign) — measured on a pure-
                                      # legacy Victor leg: UNRESOLVED 8760
                                      # vs FLOWED 600 for the 4-byte idiom
                                      # (00010001, hp AND white). BOTH
                                      # verdicts frozen — engine facts,
                                      # stable across builds. Exists because
                                      # "#103 instance 2" WAS this
                                      # artifact (settled by the no-poke
                                      # MAME retest, 14z-98 (5): real
                                      # tenant losses judge).
                                      # THE RULE: kill pokes write both
                                      # words. ~7 min, 2 parallel MAME runs.
tests/audit_roster_pairings.sh        # 14z-97: EVERY TENANT vs EVERY CHARACTER,
                                      # BOTH SIDES — the CLAUDE.md §4 mandate
                                      # ("vs each of the 18, both sides") that
                                      # the suite never had, and the gap #99
                                      # walked through. 111 pairings + a
                                      # no-poke verdict control, guarded, on
                                      # the merged build. MEASURED ~5 min at
                                      # JOBS=6 (not the hour it looks like).
                                      # Expectations are DERIVED from the
                                      # merged image's own table at
                                      # PRG:0x0BD97A, not harvested from a run
                                      # — tests/expected/roster_pairings/.
                                      # ONLY=<class> reproduces one tenant's
                                      # row; BASES=<file> one pairing.
                                      # NOT a replacement for
                                      # test_tenant_pairings: that stays as the
                                      # ~1 min six-ordering gate for routine
                                      # use, and shares tests/lib/pairing.sh.
tests/audit_legacy_pairings.sh        # 14z-89: WHICH REPLAYS ARE LEGACY
                                      # CONTENT — and is each one compared
                                      # against VANILLA rather than against
                                      # itself? Measures every non-skip
                                      # replay's loaded-character signature
                                      # on vanilla AND on the build and
                                      # FAILS if a legacy pairing carries
                                      # only a self-frozen `.sha1` (which
                                      # by construction cannot see a legacy
                                      # regression — that is how the 14z-88
                                      # medallion regression stayed green).
                                      # The filename does not answer it:
                                      # the *_don_*/*_victor_* families
                                      # became LEGACY when M3a restored
                                      # Jedah to cell 0x0F, and 35 of ~43
                                      # self-frozen replays per set measured
                                      # as legacy pairings. Signature is
                                      # +0x60.l (the per-character hitbox
                                      # base) NOT +0x382 (the voice class in
                                      # match, 14z-87); compares the
                                      # distinct-value SEQUENCE so a
                                      # hook-cycle load phase is tolerated.
                                      # 7 static verdict controls incl. the
                                      # dead-instrument refusal, plus a LIVE
                                      # positive control per set (the same
                                      # replay with the tenant id poked must
                                      # flip LEGACY->TENANT). NO POKES
                                      # otherwise — it measures what
                                      # run_suite dispatches. ~30 min,
                                      # JOBS-parallel; report per set in
                                      # build/legacy_pairings/*.tsv
tests/audit_merged_vec3.sh [bd]       # 14z-81: the merged Huitzil satellite
                                      # anim-base probe — the crash localized
                                      # by the measurement above, made
                                      # rerunnable (~4 min, 2 guarded runs).
                                      # Probes the vanilla walker ENTRY
                                      # (0x15084; the pushed vec3 PC 0x15098
                                      # is MID-INSTRUCTION and probes as a
                                      # clean zero — the dead-instrument trap,
                                      # gotcha filed) on hui29 and the merged
                                      # build, same object/frame/index, and
                                      # compares the base against the
                                      # placements-derived healthy value.
                                      # FAILS BY DESIGN until the fix lands;
                                      # then it is the regression gate. Rig
                                      # control: no PROBE at 2886 on hui29 =
                                      # rig dead, hard fail
tests/audit_objhook_owner_census.sh   # 14z-81b: which OWNER does each extended
                                      # obj_hook type (114-120, the multi-owner
                                      # x088512 pool family) carry at DISPATCH
                                      # TIME? The vec3-fix design measurement,
                                      # rerunnable (~6 min, hui29 by default,
                                      # REPORT-ONLY). Measured: 117 carries P1
                                      # directly, 119 the creator object
                                      # (player at depth 2), 115 reads ZERO at
                                      # dispatch while the same frame's dump
                                      # shows 0x84 — TIME-VARYING; 114/116/
                                      # 118/120 not observed (says so rather
                                      # than guessing). Probed the build's own
                                      # obj_hook thunk (D0 still type*4 there;
                                      # at site+6 it is already cleared).
                                      # STALE SINCE 14z-91: there is no
                                      # obj_hook thunk any more — the walker
                                      # is relocated and the dispatch site is
                                      # vanilla. Re-point this probe at the
                                      # RELOCATED walker's dispatch
                                      # (copy+0x18) before trusting it
tests/test_tenant_row_owner.sh [ex]   # 14z-77 (M3b slices C+D): is the row-OWNER
                                      # threading LOAD-BEARING? Every slice of the
                                      # multi-tenant refactor is INERT by design, so
                                      # a threading accidentally DISCONNECTED from
                                      # the emitted ops leaves the four fingerprints
                                      # unchanged too and reads as a success. This
                                      # gate perturbs ONE owner-derived row at a time
                                      # and requires the generator's OUTPUT to
                                      # change. 10 sites (slices C/D/E).
                                      # Compares the WHOLE OUTPUT DIR, not
                                      # patch.json: region blobs leave as side
                                      # .bin files, so a byte changed inside a
                                      # blob moves no op — the first version
                                      # had that blind spot and its own
                                      # controls caught it.
                                      # Runs the GENERATOR ALONE against an existing
                                      # extract dir (default build/m5_wide/extract,
                                      # SKIPs without one), so each control costs
                                      # seconds not a 4-min four-target rebuild.
                                      # Verdict logic ground-truthed: it perturbs an
                                      # intentionally UNUSED binding and requires the
                                      # checker to call it DEAD. Edits the generator
                                      # in place; trap restores on EXIT/INT/TERM and
                                      # a section asserts byte-identity. ~9s. Run it
                                      # WITH test_m3a_reproducible.sh on every M3b
                                      # machinery commit — opposite questions
tests/test_tenant_select_records.sh   # M3a select-records mechanism (14z-62): a
                                      # variant-id build carries the tenant's OWN six
                                      # select records (space-model allocations, six
                                      # array rows poked) and the host's select-family
                                      # program bytes are VANILLA. Static re-derivation
                                      # + verdict-logic negative controls + the engine's
                                      # own row fetch onto cell 0x13 (replay 36, WIDE
                                      # MAME). Self-builds at 0x13 unless given a build.
                                      # 14z-88: reads the mask from the current set;
                                      # the splash section matches the CPU opponent's
                                      # RNG ladder draw as VANILLA (was pinned to one
                                      # draw and went stale silently — run it in
                                      # batteries)
tests/test_wheel_bank5.sh      [ob]   # the select-wheel bank-5 move (14z-63): site +
                                      # re-derived tile inventory + group C member
                                      # identity straight from the zips + negative
                                      # controls + the engine's own bank-5 walk.
                                      # Self-builds at 0x13 unless given a build
tests/test_tenant_hud.sh       [ob]   # variant-id HUD (14z-63): the tenant's own
                                      # in-match mugshot/name via row 0x13 of the
                                      # 32-row-aliased HUD tables + free-pool art;
                                      # host cells pristine; staged codes measured
                                      # in-match. Self-builds at 0x13 unless given
tests/test_tenant_winpal.sh    [ob]   # variant-id win-screen palette (14z-63): the
                                      # sparse block + TT thunk at 0x5F1B6; BOTH
                                      # thunk paths measured on real 2P victories
                                      # (replays 61/62). Self-builds at 0x13 unless
tests/test_don_throw_mirror.sh [ob]   # the 14z-2 mirror-victim fix (applied 14z-64):
                                      # base-slot mirror throws use the Donovan-victim
                                      # block — static 2-byte assertion + a matched
                                      # runtime control pair on replay 65. SKIPs on
                                      # variant-id builds (correct by construction)
tests/test_accent_census.sh    [ob]   # accent/march census (14z-63): 4 frozen
                                      # family-base sites (0 direct T0/T1 refs),
                                      # all jsr-routed on variant builds. Static
                                      # + negative control, ~30s (self-builds)
tests/test_index_space.sh             # 14z-76: THE OUT-OF-RANGE INDEX SWEEP.
                                      # vsavj's dispatch tables are SHORTER than
                                      # vs2's, so a ported index can run past the
                                      # end (Pyron's Cosmo sub-state 81 into an
                                      # 80-entry table). Derives every
                                      # `jmp (d8,PC,Dn.w)` table's entry count in
                                      # BOTH roms from two structural bounds — a
                                      # target cannot land inside the table, and a
                                      # table cannot overlap the next dispatcher —
                                      # and reports where vs2 is longer. Frozen:
                                      # 110 tables, 81 twinned (24 by instruction
                                      # SHAPE, which survives relocation where a
                                      # byte-context match does not), 29 NOT
                                      # JUDGED, 3 risky. The unjudged count is part
                                      # of the verdict. Positive control: it must
                                      # re-derive the Cosmo table at 80 vs 84.
                                      # tools/audit_index_space.py. Static, seconds
tests/test_effect_palette_table.sh    # 14z-76: the per-character palette POINTER
                                      # tables are 32-row and id-INDEXED. 0x38C198
                                      # (sprite) and 0x38C218 (effect) each hold 32
                                      # rows; 0x38C1D8/0x38C258 are their variant
                                      # halves, never a base (0 refs in either ROM
                                      # view); both alias the base half except rows
                                      # 0x12/0x18 (Oboro Bishamon is real); and the
                                      # 5 readers take the id byte UNMASKED. This is
                                      # what licenses repointing a tenant's row —
                                      # the "only sixteen rows" reading deferred
                                      # Pyron's effect palette for two sessions.
                                      # 4 negative controls (a fold in the reader,
                                      # a reference to the second half, a de-aliased
                                      # variant row, a build clobbering a base-half
                                      # row). tools/audit_effect_palette_table.py.
                                      # Static, seconds
tests/test_frozen_rompath_guard.sh    # 14z-90 (issue #26): build_donovan.sh must
                                      # refuse to replace one track's packed
                                      # set with the other's under the same
                                      # name (`run_battery_m2.sh build/don_m5`
                                      # would repack STOCK over the registered
                                      # WIDE reference). Track-mismatch check,
                                      # NOT a frozen-reference check — the
                                      # latter would block HANDOFF's own
                                      # documented `build_donovan.sh 6
                                      # build/don_m4` recipe. Runs on a COPY.
                                      # ON-DEMAND, ~8 min (two real builds)
tests/test_attribute_ramdiff.sh       # 14z-90 (issue #21): attribute_ramdiff
                                      # must refuse when both logs resolve to
                                      # the SAME dump file (MAME dump names are
                                      # directory-scoped). A genuine zero-diff
                                      # between DISTINCT files stays a note.
                                      # No ROMs, no emulator, ~1s
tests/test_fbneo_tree_integrity.sh    # 14z-90 (issue #36): emu/fbneo must be
                                      # EXACTLY the pinned commit + the two
                                      # tracked patches. Reconstructs from
                                      # `git archive PIN` + `git apply` and
                                      # compares WHOLE FILES, because
                                      # `git apply -R --check` only validates
                                      # hunk context and accepts an edit a few
                                      # lines away. Also checks the changed-file
                                      # inventory, so drift in an untouched file
                                      # is visible. Run it AFTER regenerating
                                      # the patches, not before a build — a hard
                                      # gate ahead of an untested change is rule
                                      # 2 backwards. + _control.sh (5 cases)
                                      # No ROMs, no emulator, ~5s / ~20s
tests/test_audit_merged_dispatch.sh   # 14z-90 (issue #17): ground truth for the
                                      # expectation enumeration audit_merged_legacy.sh
                                      # runs before its leg-(a) glob. The glob
                                      # is *.masked only, so `.pending` — a
                                      # pairing with no ratified class anywhere
                                      # — was dropped silently, putting the
                                      # blind spot over the open regression.
                                      # Case 3 is live: donovan-m5 must name
                                      # exactly 2 NOT-EVALUATED. ROM-free, ~1s
tests/test_fbneo_runner_hygiene.sh    # 14z-90 (issue #12, shell half): a FAILED
                                      # FBNeo run must not leave the previous
                                      # run's log/.tap/side-channel outputs
                                      # behind, because the completion check is
                                      # an ARTIFACT check (grep ^END). Measured
                                      # pre-fix: rc=1 but $OUT still present
                                      # with its old content. ROMDIR, ~5s
tools/artifact_manifest.py            # 14z-90 (issue #8): per-member SHA-1 of
                                      # every packed zip in a rompath dir. The
                                      # program fingerprint covers 8.1% of the
                                      # shipped bytes; this covers all of it.
                                      # Refuses a ';' rompath chain (that would
                                      # fold $ROMDIR into the digest) and is
                                      # timestamp-free by construction.
                                      # Wired into test_m3a_reproducible.sh:
                                      # HARD on member inventory, ADVISORY on
                                      # member content until the legacy re-freeze
tests/test_shell_portability.sh       # 14z-90 (issue #15): every #!/bin/sh
                                      # script must be POSIX sh. Strips heredoc
                                      # bodies first (these scripts embed Python
                                      # and TOML; an unstripped census reports
                                      # ~16 false [[table]] hits). A script that
                                      # needs bash must say so in its shebang —
                                      # today exactly one does.
                                      # No ROMs, no emulator, ~1s
tests/test_m2a_flicker_gate.sh        # ground truth for the battery's masked
                                      # legacy gate. REWRITTEN 14z-97 (#96) AND
                                      # ITS PREDICATE INVERTED: it locked
                                      # "GROWTH fails, a SHRINK does not",
                                      # which rested on the battery running on
                                      # UNFROZEN dev builds. The target is a
                                      # FROZEN generation now, so drift EITHER
                                      # way fails. 5 cases: growth, shrink,
                                      # the frozen shape, a required replay
                                      # with no spec, and an unresolvable
                                      # target (must name rule 6).
                                      # No ROMs, no emulator, ~3s
tests/test_masked_compare.sh          # 14z-97 (#96): ground truth for
                                      # tests/lib/masked_compare.sh, the ONE
                                      # implementation of the §4 vocabulary
                                      # (exact/flicker/diverge/window/composite
                                      # + the #62 baseset/mask guard) now shared
                                      # by run_suite.sh and the M2 battery.
                                      # Every class in both directions; it
                                      # caught a real bug in the lift (the
                                      # diverge spec's temp-file STEM).
                                      # No ROMs, no emulator, ~2s
tests/test_gfx_menus_guard.sh         # 14z-90 (issue #6): ground truth for the
                                      # pixel gate's rompath guard. An absent
                                      # rompath and a vsavjw-only rompath must
                                      # both FAIL — the second is the one a
                                      # directory check cannot catch, where MAME
                                      # would resolve by hash out of $ROMDIR and
                                      # compare vanilla to vanilla. Plus a
                                      # positive control. ROMDIR, ~40s
tests/test_region_overlap_control.sh  # 14z-90 (issue #9): ground truth that the
                                      # region-overlap gate's CURRENT-trio
                                      # constants can fail. Points section 5 at
                                      # the superseded trio (must reject:
                                      # 2000 vs 2012) and names an absent build
                                      # (must FAIL, not SKIP), plus a positive
                                      # control. No ROMs, no emulator, ~2 min
tests/test_movability_liveness.sh     # 14z-90 (issue #5): ground truth that
                                      # tests/audit_region_movability.sh cannot
                                      # score a DEAD emulator as `runs`. Injects
                                      # stub builder/runner via BUILDER_CMD and
                                      # GUARDED_RUNNER: never-started and
                                      # empty-log rigs must FAIL and be named
                                      # `dead`; a live rig must still score
                                      # `runs`. Pre-fix the same rig exited 0
                                      # and printed the budget claim.
                                      # ROMDIR, no emulator, seconds
tests/test_suite_dispatch_selftest.sh # 14z-90 (issue #7): ground truth for the
                                      # kind->owner table in
                                      # tests/test_suite_dispatch.sh. Three
                                      # negative controls: an unlisted kind, an
                                      # owner that no longer reads its kind, and
                                      # a false battery-chain claim — each must
                                      # turn the gate RED and name the reason.
                                      # ROMDIR, no emulator, ~10s
tests/test_build_gate_status.sh       # 14z-90 (issue #1): ground truth that a
                                      # REJECTED build aborts the gate instead of
                                      # being soaked and stamped PASS. Copies the
                                      # stage-4/6 gates into a scratch repo with a
                                      # stubbed build_donovan.sh; 3 failure modes
                                      # (reject-after-pack, stale rompath, no
                                      # rompath) + a positive control + the sibling
                                      # gate. GATE_SRC=<dir> reruns it against the
                                      # pre-fix gates, where it must FAIL.
                                      # No ROMs, no emulator, ~1s
tests/test_compare_composite.sh       # ground truth for the §4 v4 composite class
                                      # (frozen flicker inventory + frozen bounded
                                      # windows, RATIFIED 2026-08-06): 7 synthetic
                                      # cases + a no-loophole check. No emulator.
                                      # donovan-m5w freezes 7 replays in this class
tests/test_describe_masked_shape.sh   # 14z-89: ground truth for
                                      # tools/describe_masked_shape.py, the
                                      # classifier that turns a measured masked
                                      # divergence into a PROPOSED expectation
                                      # line. It used to be a heredoc inside
                                      # audit_merged_legacy.sh, run only on that
                                      # audit's failure path — i.e. only when
                                      # something was already wrong — and its
                                      # output is COPIED INTO EXPECTATION FILES
                                      # by hand. 11 assertions: one per branch
                                      # (exact/flicker/window/composite/two-window)
                                      # + the replay-38 signature (never
                                      # re-converges = NOT expressible, must be
                                      # root-caused) + both threshold boundaries
                                      # (flicker<=2 frames, re-convergence>60) +
                                      # the length-mismatch report. Static, ~1 s
tests/test_tenant_pairings.sh          # 14z-95: TWO PORTED CHARACTERS IN ONE
                                      # MATCH, all six orderings. The
                                      # CLAUDE.md §4 coverage the suite did
                                      # NOT have — "vs each of the 18 (both
                                      # sides)" — and the gap GitHub #99
                                      # walked through. The arcade marathon
                                      # cannot close it: single-credit, ONE
                                      # character, and (measured 14z-95) only
                                      # two ladder rungs. Asserts per
                                      # ordering: no crash (guarded) + BOTH
                                      # characters loaded, checked on the
                                      # per-character hitbox base +0x60.l.
                                      # THE SIGNATURE CHOICE IS LOAD-BEARING:
                                      # +0x382 is the VOICE-FLAVOR class in
                                      # match, not the id (14z-87,
                                      # ram.md:85) — GitHub #16 records a
                                      # live gate that false-REFUSEs on it.
                                      # Frozen bases: donovan 0x3fa9d0,
                                      # phobos 0x4477b0, pyron 0x49ab7c,
                                      # measured identical as P1 and as P2.
                                      # Replay 94 is character-AGNOSTIC, so
                                      # adding a tenant is a row in CLASSES,
                                      # not a new replay. Verdict control: an
                                      # UNPOKED run must be REFUSED, else
                                      # every ok is vacuous. Needs the MERGED
                                      # build by construction. ~10s, 7 runs
tests/test_hui_electrocute.sh         # 14z-95: PHOBOS AS THE ELECTROCUTE
                                      # VICTIM, ours vs native vsav2 — the
                                      # consumer for replay 93. STATE said
                                      # TWICE (14z-74/76) that no replay
                                      # produced an electrocute; this is the
                                      # first. TRIGGER FROM THE MAINTAINER,
                                      # not derivable from the tree: Victor's
                                      # HELD HP, a CHARGEABLE NORMAL.
                                      # TWO PAID-FOR TRAPS ENCODED: (a) the
                                      # class is 0x07, NOT 0x06 — 0x06 is the
                                      # remapped TRAP DOME's route into the
                                      # same shake handler (14z-85g(2)), so a
                                      # gate on 0x06 reports "no electrocute"
                                      # while producing one; (b) a SHORT
                                      # press is the QUICK version — the
                                      # rig's first draft landed a hit
                                      # (288->275 both legs) and produced an
                                      # ordinary reaction, so the quick 6+HP
                                      # is kept as a standing NEGATIVE
                                      # control. Section 3 freezes the ring
                                      # inventory across the electrocute
                                      # window only, where the sole delta is
                                      # the documented 010a/010b cosmetic
                                      # pair. DELIBERATELY NOT ASSERTED: the
                                      # two extra Phobos voices (0x8e/0x91)
                                      # measured PRE-match — a +0x382 poke
                                      # confound is open on the native leg,
                                      # so freezing them would ratify a
                                      # possible rig artifact. ~2 min
tests/audit_hui_grunt.sh              # 14z-96: THE ELECTROCUTE-GRUNT A/B over
                                      # FIVE electrocutions (replay 95, the x4
                                      # rig) — the maintainer's grunt report
                                      # ROOT-CAUSED: the sound KERNEL's
                                      # per-class voice tables (events .0-.3,
                                      # PRG:0x3BCE/3C3A/3CA6/3D10 + variant
                                      # halves at +0x20) have vsavj rows
                                      # 0x10-0x1F as COPIES of 0x00-0x0F, so
                                      # Phobos' every-other-hit voice fires
                                      # row 0x00's id 0x1d2 (a LEGACY hurt
                                      # cry) where native vs2 fires his own
                                      # row's 0x2a2 — a FREE Z80 id, i.e.
                                      # DELIBERATE SILENCE (the robot does
                                      # not grunt). PER-BUILD frozen
                                      # expectations since the 14z-96 port:
                                      # merged-m2 = the defect (regression
                                      # lock), m3b_merged10 = the fix (02a2,
                                      # the deliberate-silence id),
                                      # m3b_merged11 = the 14z-99 row
                                      # (kernel rows untouched by the
                                      # window) — all green; an unknown
                                      # build REFUSES until a row is frozen;
                                      # GRUNT_OURS_A2 rehearses.
                                      # Static half: test_kernel_voice_tables
                                      # (ci_static). ~3 min, 2 MAME runs
tests/test_hui_boot.sh                # Huitzil stage-4 BOOT gate (14z-65): the
                                      # forced-pick match forms with HIS data
                                      # (base read from the build's own patch),
                                      # guard clean, legacy bit-identical
tests/test_hui_ladder.sh              # Huitzil stage 1-3 ladder gate (14z-65):
                                      # builds from huitzil.toml + THE OP
                                      # INVARIANT (every op = free space or a
                                      # variant row) + legacy replay bit-identity.
                                      # Build any tenant: TENANT_MANIFEST=...
                                      # TENANT_CHAR=0x10 tools/build_donovan.sh
tests/test_hui_oracle.sh [rp]         # THE vsav2-as-oracle battery (14z-66): the
                                      # m2a template's 4 locks on H's full moveset
                                      # (anchors/neutral-exact/HP-trajectory/
                                      # comparative bound); RNG determinized on
                                      # both legs. ~10 min, 8 MAME runs
tests/test_hui_pairs.sh        [bd]   # Reflect Wall GC + Dark Force gate (14z-66):
                                      # both native-matched signatures (GC seq 0x0E +
                                      # blowback; DF 0x0A at both activations).
                                      # Self-builds stage 4 unless given a build
tests/test_hui_grab.sh         [bd]   # Circuit Scrapper gate (14z-66): the 2P-dummy
                                      # grab connects with the NATIVE damage datum
                                      # (frame-identical A/B of record). Early-window
                                      # 2P pokes only — see the replay 80 header.
                                      # Self-builds stage 4 unless given a build
tests/test_list_type_census.sh         # 14z-74: the ONE-SOURCE-BANK re-check per
                                      # tenant. gfx_layout3 assumes a tenant's art is
                                      # one band in one source bank; a list TYPE 4
                                      # composes its OWN bank word and breaks that
                                      # (Huitzil's beam). Frozen counts: H 26 type-4
                                      # (the POSITIVE CONTROL — its first version was
                                      # blind and read 0 for him), D 1, PYRON 0 (so his
                                      # delta-0 placement needs no strip-tiles). Static
tests/test_pyron_cosmo.sh      [bd]   # 14z-74: the Cosmo Disruption crash. 3 sections —
                                      # static (the guarded word + table+0x224 IS vs2's
                                      # handler byte-for-byte), DEADNESS (0 dispatcher
                                      # reads of entry 81 vs a live 12/7 control; watches
                                      # the OPCODES space because the table is read
                                      # pc-relatively, and filters BY PC because the boot
                                      # ROM-checksum sweep touches every byte), and
                                      # runtime (no crash, the EX still FIRES, the match
                                      # survives — a watchdog reset is not a 68k
                                      # exception, so the field trace proves it, not the
                                      # guard). Defaults to build/pyron18
tests/test_variant_dispatch.sh [bd]   # 14z-75: THE VARIANT-ROW DISPATCH SWEEP.
                                      # vsav aliases rows 0x10-0x1F of 32-row
                                      # per-character JUMP TABLES onto 0x00-0x0F, so a
                                      # tenant silently inherits a base-half character's
                                      # routine — the most common defect shape in this
                                      # port. Sweeps every `jmp (d8,PC,Dn.w)` word table
                                      # with a mostly-aliased variant half (5 exist) and
                                      # requires ours[tenant row] == vs2's. Rows where
                                      # OURS RUNS A ROUTINE vs2 DOES NOT fail; rows where
                                      # vs2 runs one we do not are reported only (a
                                      # missing feature, not a spurious one). Catches all
                                      # THREE of Pyron's blink tables on pyron15. Two
                                      # controls: a reintroduced aliased row must be
                                      # caught, and NO table may be "unjudgeable" (vsav
                                      # ships two identical dispatchers, so the twin
                                      # finder matches by ORDINAL — demanding a unique
                                      # context silently skipped the first defect).
                                      # tools/audit_variant_dispatch.py. Static, seconds
tests/test_pyron_blink.sh      [bd]   # 14z-75: the sprite/HUD BLINK. Palette row 10
                                      # (0x90C140) carries Pyron's SPRITE and his
                                      # in-match HUD MUGSHOT, so both blink. Native
                                      # vsav2 vs the build on replay 76 (one rig, both
                                      # games), compared by a PHASE-INDEPENDENT property
                                      # — distinct row-10 values over 40 CONSECUTIVE
                                      # frames — because the two games are never on the
                                      # same frame and a frame-indexed diff produced a
                                      # confounded figure that stood a whole session.
                                      # native 1/0 changes, ours 2/39. Attribution is
                                      # part of the verdict: ours' two values must be
                                      # NAMED (native's constant + vsavj palette-seq row
                                      # 0x26 under the uploader's 0xF000 OR), so a
                                      # look-alike defect fails. REFUSES to judge unless
                                      # each leg's +0x60.l (the hitbox base; never
                                      # +0x382, the in-match voice-flavor byte — #16,
                                      # fixed 14z-92) is ONE non-zero value AND equals
                                      # Pyron's row of that game's own hitbox_base table
                                      # (vs2 data 0xD7B18, the build's 0x3D97A); 8
                                      # verdict controls incl. a loaded-wrong-character
                                      # refusal (14z-123; this row carried a "KNOWN
                                      # WEAKNESS … blocked" note for a fix already
                                      # shipped at 14z-92).
                                      # FIXED 14z-75 (a DEAD ROW: per-char palette-routine
                                      # table 0x2A8A4 row 0x11 aliased row 0x01's ANIMATED
                                      # handler; one word 0x2A8C6 008E->0040 = vs2's own
                                      # value). PYRON_BLINK_EXPECT=fixed (default) |
                                      # blinks (reproduces the pre-fix shape on pyron15).
                                      # Checker tools/check_pyron_blink.py. Defaults
                                      # build/pyron30 (14z-103; roll at each freeze)
tests/test_hui_grab_victim.sh  [bd]   # grab-victim placement A/B (14z-73): native
                                      # vsav2 vs the build, replay 80 through
                                      # field_trace.lua, comparing the victim offset
                                      # RELATIVE to the attacker (dx=p2x-p1x — cancels
                                      # the ~21px global camera shift, so NO corner rig
                                      # is needed). Refuses to judge unless both legs
                                      # grabbed (seq 0x0E + 0x13 dmg); 2 verdict controls.
                                      # GRAB_VICTIM_EXPECT=matches (default since
                                      # 14z-103; the 14z-73 grab_hold_keyframes fix is
                                      # what it guards, Δ=0) | =differs reproduces the
                                      # pre-fix ~109px teleport (needs a pre-14z-73
                                      # build). Checker tools/check_grab_victim.py.
                                      # Defaults hui46
tests/test_hui_air.sh          [bd]   # Huitzil air-movement gate (14z-66): the
                                      # float hovers (Y pinned) and the air dash
                                      # engages (seq 0x14, flat advance) — mode
                                      # signatures, not just no-crash.
                                      # Self-builds stage 4 unless given a build
tests/test_hui_ex.sh           [bd]   # Huitzil EX-move gate (14z-66): FOUR
                                      # sections (ES, FG-connect, FG-full-seq,
                                      # FG+aftermath chaos) — each fires with the
                                      # stock decrementing (anti-coverage-loss).
                                      # Self-builds stage 4 unless given a build
tests/test_hui_walk.sh         [bd]   # Huitzil velocity-port gate (14z-66):
                                      # param32 rows 0x10 static + measured
                                      # walk-speed deltas (16.16-exact).
                                      # Self-builds stage 4 unless given a build
tests/test_pyron_ladder.sh            # the Pyron stage 1-4 ladder (14z-67):
                                      # builds from pyron.toml, per-stage op
                                      # invariant (stage 4 exempts exactly the
                                      # four generator hook sites), forced-pick
                                      # boot probe, stage-3 UNMASKED legacy
                                      # bit-identity + stage-4 masked EXACT (V2
                                      # basis; V3 parked 14z-88)
tests/test_census_regions.sh [bd]     # ground truth for tools/census_regions.py
                                      # (14z-67): the data_in_code + pcrel-escape
                                      # censuses — H's frozen inventory (5 sites,
                                      # 89/35 + 9/6 escapes, adjacency-safe class,
                                      # 2 known false positives, the x05c800
                                      # KNOWN-OPEN latent pair) + Pyron clean.
                                      # Self-builds stage 4 unless given a build
tests/test_gfx_layout3.sh             # the 3-tenant group-C layout fact-locks
                                      # (14z-67, D4): one-source-bank premise,
                                      # frozen H/P/D tile inventories, H/P
                                      # delta-0 disjoint from D's frozen band
                                      # by interval, the flip-condition bound.
                                      # Static, ~90s. Ledger:
                                      # build/manifest/gfx_layout3.toml
tests/audit_gfx_merged_census.sh      # 14z-83 (M3b Phase 3 S0): the COMPLETE
                                      # merged group-C write-set census
                                      # (tools/audit_gfx_merged.py) — every
                                      # build_gfx pass, both banks, incl. the
                                      # side inventories test_gfx_layout3 is
                                      # blind to (strip/extra/effect_map/
                                      # bank-5 sets). Byte-compares every
                                      # colliding dst at source. Freezes: the
                                      # ONLY real collision = H's 288 strip
                                      # dsts 0x5EA0-0x5FBF inside P's band
                                      # (the S3 relocation target — flips to
                                      # ZERO when it lands); occupancy
                                      # 45,449/65,536; pools EMPTY. Two
                                      # comparator verdict controls (must-
                                      # fire both directions). Static, ~3min
tests/test_gfx_collision_gate.sh      # 14z-83 (S1): ground truth for
                                      # build_gfx place() — same-source-or-
                                      # fail on EVERY pass (was 2 of 8; the
                                      # band pass had NO check). Clean write,
                                      # benign same-source skip, different-
                                      # bytes MUST-RAISE control naming both
                                      # provenances, and the single-write-
                                      # path textual lock. Emits
                                      # gfx_written.json (the S2 chain
                                      # ledger). No ROMs, ~1s
tests/test_replay_stage_census.sh      # 14z-93 (GitHub #10): FREEZES the
                                      # input-staging split of every
                                      # replay-driving Lua instrument. The
                                      # canonical convention is replay.lua's
                                      # (parse held[fr], stage
                                      # held[frame+1]); TEN instruments net
                                      # a +1 shift, so a frame number from
                                      # one of their logs is NOT a frame
                                      # number from a compare_* first
                                      # divergence or a masked window onset.
                                      # NOT A FIX — deliberately: the
                                      # consuming gates' frame constants
                                      # were tuned UNDER the drift, so the
                                      # staging fix and the re-measurement
                                      # are ONE change (docs/project/
                                      # gotchas.md). This PINS it at 10
                                      # deviant / 11 canonical: a NEW
                                      # instrument copying the wrong flavour
                                      # FAILS, every deviant must carry its
                                      # banner, replay.lua must stay
                                      # canonical. EXPECT_DEVIANT=0 flips it
                                      # to asserting uniformity once fixed.
                                      # STRIP LUA COMMENTS when censusing —
                                      # the banners quote `held[frame + 1]`,
                                      # so a naive grep reads a drifted file
                                      # as canonical (measured: 10 -> 3).
                                      # 4 verdict controls. No ROMs, ~1s;
                                      # in ci_portable
tests/test_voice_row_range.sh          # 14z-93 (GitHub #92), TABLE-A SECTION
                                      # ADDED 14z-94: the AUTHORED
                                      # ARCADE-LADDER rows must stay inside
                                      # VANILLA's value range. Each tenant
                                      # build authors a 64-byte row in
                                      # table A (0x00B268, candidate
                                      # CLASSES) and table B (0x00BB68, the
                                      # STAGE for each) at its own class;
                                      # the selector scans ONE index across
                                      # both, so they are pairs. A table-B
                                      # value reaches $FF8100 and indexes
                                      # the stage-banner family whose
                                      # FOLLOWING row is dereferenced.
                                      # Vanilla emits only even 0x00..0x16
                                      # over all 1024 bytes; 0x16 is also
                                      # what the banner table can service.
                                      # RED BY DESIGN (rule 6): huitzil and
                                      # pyron rows carry 0x18 at four
                                      # offsets each — all eight are class
                                      # 0x13 (Donovan) at REVENGER'S ROOST,
                                      # vs2's 13th stage, which vsav lacks;
                                      # donovan's row is clean because it
                                      # never lists his own class.
                                      # DERIVES the bound from the tables
                                      # and CROSS-CHECKS it against
                                      # vanilla's range — that cross-check
                                      # caught an off-by-one in its author's
                                      # derivation that had declared the
                                      # defect legal. SECTION B (14z-94)
                                      # audits table A, which section A
                                      # explicitly did not: two derived
                                      # bounds (36 rows structurally; 32 by
                                      # the in-use mask's `btst` MOD 32) and
                                      # the two marker values asserted
                                      # (0x18 at index 7 of all 36 rows;
                                      # 0xff only as whole rows 0x0b/0x1b).
                                      # It runs BEFORE the verdict combines,
                                      # or it would never execute while
                                      # section A is red. Table A is CLEAN.
                                      # NOT in ci_portable: needs the DATA
                                      # view + build dirs, so a clean
                                      # checkout would SKIP and that job
                                      # fails on SKIP. ~2s
tests/test_decode_stage_banners.sh    # 14z-94 (GitHub #92): ground truth for
                                      # tools/decode_stage_banners.py, which
                                      # NAMES the #92 value space — the
                                      # replacement stage is a maintainer
                                      # decision and must be taken against
                                      # names, not numbers. 6 sections:
                                      # both families enumerate to their
                                      # measured sizes (vsavj 12, vs2 13),
                                      # known records decode to known text,
                                      # the 12 shared stages agree 1:1 in
                                      # order (so the port owes NO renumber),
                                      # and every out-of-range authored entry
                                      # is #92's single known shape.
                                      # 3 VERDICT CONTROLS, one of which is
                                      # the trap: decoding vs2 from its table
                                      # BASE instead of the ANCHOR read out
                                      # of its code site manufactures a "+8
                                      # renumber between the games" that does
                                      # not exist. The tool exits nonzero
                                      # naming the anchor, because an empty
                                      # family that merely omits the names
                                      # reads as "no match" and is right by
                                      # accident. Static, ~2s
tests/test_record_window.sh           # 14z-94: ground truth for
                                      # tests/lua/record_window.lua, the
                                      # in-emulator WINDOWED movie recorder.
                                      # `-aviwrite` works headless but writes
                                      # UNCOMPRESSED video for the whole run
                                      # — measured 5.7 GB in two minutes of
                                      # wall time — so the recorder starts
                                      # and stops on named frames and
                                      # defaults to MNG (2.4 MB for 120
                                      # frames). 4 assertions: EXTENT (the
                                      # movie covers exactly the window),
                                      # DETERMINISM (same window twice is
                                      # byte-identical — the whole reason to
                                      # prefer this over a screen capture),
                                      # LIVENESS (a window VIDEO_OUT says
                                      # CHANGES must not compress like a
                                      # STILL one — catches a recorder
                                      # reproducibly emitting blank frames,
                                      # which determinism cannot), and 2
                                      # controls. The busy/still windows are
                                      # CHOSEN FROM the measured checksum
                                      # stream at run time, so no frame
                                      # constant is baked in to rot. NOTE
                                      # replay.lua has NO frame cap — it runs
                                      # to the script's last line, so the
                                      # gate truncates the rig instead.
                                      # ROMDIR + a WIDE build, ~90s
tests/test_s4_thresholds.sh           # 14z-93 (GitHub #44): the ratified §4
                                      # thresholds (FLICKER_MAX, RECONVERGE)
                                      # are declared ONCE in
                                      # tools/s4_thresholds.py and every
                                      # comparator imports them. Asserts the
                                      # values, that all four consumers
                                      # import, that none re-declares a
                                      # local literal, that none hardcodes
                                      # an argparse default, + a verdict
                                      # control both ways (a re-introduced
                                      # literal caught; a COMMENT not
                                      # flagged). ROM-free, ~1s; ci_portable
tests/test_qs_window_law.sh           # 14z-93 (GitHub #82): the QSound
                                      # sample-window endpoint is INCLUSIVE
                                      # (packing law #3). The builder was
                                      # corrected at 14z-87b; both AUDIT
                                      # paths were not, and went on
                                      # justifying the exclusive slice with
                                      # the superseded belief — so the byte
                                      # that caused the sword-plant beep sat
                                      # OUTSIDE the audit surface. Law now
                                      # in tools/qs_window.py, bounds
                                      # CHECKED not clamped. 14 cases incl.
                                      # a terminal-byte corruption control
                                      # and a control REPRODUCING the old
                                      # blindness. ROM-free, ~1s; ci_portable
tests/test_replay_stage_census.sh     # 14z-93 (GitHub #10): FREEZES the
                                      # input-staging split (10 deviant / 11
                                      # canonical). NOT a fix — the
                                      # consuming gates' frame constants
                                      # were tuned UNDER the drift, so the
                                      # staging fix and the re-measurement
                                      # are ONE change. Pins it so it cannot
                                      # GROW, requires every deviant to
                                      # carry its banner, and requires
                                      # replay.lua to stay canonical.
                                      # EXPECT_DEVIANT=0 flips it to
                                      # asserting uniformity once fixed.
                                      # STRIP LUA COMMENTS when censusing —
                                      # the banners quote `held[frame + 1]`
                                      # (measured: a naive grep turned 10
                                      # deviants into 3). ROM-free, ~1s
tests/test_classify_hitclass_probe.sh # 14z-93: ground truth for the
                                      # hit-class probe's VERDICT LOGIC
                                      # (tools/classify_hitclass_probe.py),
                                      # which decides whether a census zero
                                      # means "the tenant stayed inside
                                      # vanilla's 64 entries", "no rig
                                      # produced the event" or "the rig
                                      # died". 15 cases: the three real
                                      # verdicts, the four states that are
                                      # NOT a zero (DEAD / CRASH / CAPPED /
                                      # absent log), and the ways it could
                                      # be quietly wrong — D0 is the RAW
                                      # index here (index*4 at the obj_hook
                                      # sites, so a "fix" that divides would
                                      # make 0x44 vanish), the low WORD is
                                      # the index and a stale high word must
                                      # be masked, while a LARGE low word is
                                      # a real trap and must not be. Written
                                      # first and it CAUGHT ITS AUTHOR: the
                                      # high-word fixture encoded the wrong
                                      # width. No ROMs, ~1s; in ci_portable
tests/test_classify_pool_spawns.sh    # 14z-93: ground truth for the SPAWN
                                      # DENOMINATOR (tools/classify_pool_
                                      # spawns.py) — how many type >= 64
                                      # objects entered the $FF9400
                                      # projectile pool. Without it a zero
                                      # from the map census is ambiguous
                                      # between "never stamps a dangerous
                                      # type" and "stamps them constantly,
                                      # nothing collided" — opposite
                                      # rulings. 12 cases. THE LANE is the
                                      # sharp one: the type byte is at
                                      # +0x02, an EVEN address, so it is
                                      # the HIGH lane of the logged word —
                                      # and the real captures carry the
                                      # SAME value in both lanes
                                      # (data 00004040), so a low-lane
                                      # reader is right by coincidence.
                                      # Every lane case uses UNEQUAL lanes.
                                      # Caught the tool's first version.
                                      # No ROMs, ~1s; in ci_portable
tests/test_obj_record_walk.sh         # 14z-92 (GitHub #75): ground truth
                                      # for the RELOCATION-AWARENESS of
                                      # obj_records.walk's two heuristic
                                      # passes. Both decide "is this a
                                      # record" from ADDRESSES, and
                                      # placement moves the addresses under
                                      # the same bytes — sweep asks about
                                      # the aux windows (hardened 14z-74),
                                      # the pointer pass asks about the
                                      # REGION window (hardened here, after
                                      # it invented a record on merged
                                      # huitzil and aborted every merged
                                      # build from merged6). A built-image
                                      # walk must VERIFY the source's
                                      # structure, never re-derive it.
                                      # 4 verdict controls, each of which
                                      # must actually fire: A the phantom
                                      # (ptr_allow=None MUST invent it —
                                      # the pre-fix behaviour needs no
                                      # reconstruction), B the session-14b
                                      # clobbered fmt-0 count, C an
                                      # un-relocated pointer, D two
                                      # pointers swapped onto each other's
                                      # targets — which a COUNT check
                                      # cannot see, so the gate proves the
                                      # old blindness rather than asserting
                                      # the new strictness. Synthetic
                                      # fixture, no ROMs, no build dirs,
                                      # ~1s; in tests/ci_portable.txt
tests/test_fbneo_legacy_oracle.sh     # 14z-92 (GitHub #78 PARTIAL): the
                                      # HACKED build's legacy content vs
                                      # VANILLA, on FBNeo. CLAUDE.md §4
                                      # defined this oracle and the suite
                                      # did not run it: FBNeo had the
                                      # emulator superset invariant on
                                      # PRISTINE vsavj + dual-track
                                      # inertness, and the hacked-build
                                      # legacy comparison lived on MAME —
                                      # never their product. 4 replays x 5
                                      # frames (14z-110b: 26_don_arcade_mash
                                      # DROPPED for 05_timeout_idle, frames
                                      # are measured-clean OVERRIDES — the
                                      # d2-window cycles moved FBNeo's phase;
                                      # 14z-115: 05's fifth instant 8300 ->
                                      # 9500, re-scanned on don_m15 — the
                                      # wheel's three extra OBJ entries per
                                      # select frame re-rolled the phase
                                      # again, MAME exact at the same frame;
                                      # gate header); otherwise SAMPLE FRAMES
                                      # ARE DERIVED
                                      # from each replay's frozen MAME spec
                                      # and pushed clear of every ratified
                                      # flicker/window, so a mismatch is
                                      # FBNeo-only by construction. Set
                                      # resolved from the build, never
                                      # pinned. FBNEO_REF makes leg A a
                                      # true reference binary; without it
                                      # leg A runs vanilla on the patched
                                      # binary and the claim is completed
                                      # by test_wide_profile (named in the
                                      # header, not assumed). 3 comparator
                                      # controls incl. one proving the mask
                                      # is APPLIED. FOUND ON ITS FIRST RUN,
                                      # both cross-checked against MAME at
                                      # the same frame (MAME: 0 diffs):
                                      # $FF055B-$FF055D (sound-driver work
                                      # area, ram.md:74) and $FF06D1/D4/DB
                                      # (OBJ-builder secondary stack,
                                      # ram.md:62 "execution POSITION, not
                                      # state"). Reported as `open:` —
                                      # MEASURED DEVIATIONS AWAITING A
                                      # RULING, bounded to two named
                                      # windows; anything outside FAILS.
                                      # FBNEO_ORACLE_EXPECT=exact is the
                                      # post-ruling target. ~5 min
tests/audit_pool_free_byte.sh         # REWRITTEN 14z-85 (the 14z-84 version
                                      # measured only $FFB800 and attributed
                                      # it to the 59-75 family — WRONG POOL;
                                      # the family lives in $FF9400, 0x100
                                      # stride, walker 0x54458): census +
                                      # byte-lane PC-attributed tap on BOTH
                                      # pools, 3 legs. Auto pre/post-tag mode
                                      # by tag_map.json: post asserts family
                                      # slots carry the stamper's tag and
                                      # +0x7F writers are exactly the emitted
                                      # thunks. Also caught: hole_b's WORD
                                      # write at b8+0x7E covers +0x7F — the
                                      # 14z-84 zero-writes there was a word-
                                      # offset accounting artifact. ~20 min
tests/audit_fg_damage.sh              # 14z-85e, REFRAMED 14z-85f (~5 min):
                                      # FG damage vs CPU frozen at 10 HP —
                                      # measured UNCHANGED by the fix: these
                                      # rigs' ticks were fighter-path
                                      # contacts, never the broken path. A
                                      # plain regression lock now; the
                                      # PARITY gate is audit_fg_parity.sh.
                                      # Liveness: stock decrement or the
                                      # run proves nothing (downgrade trap)
tests/audit_fg_parity.sh              # 14z-85f (~4 min, 2 parallel runs):
                                      # THE FG PARITY GATE — the native-
                                      # comparable 89_hui_ex_fg_vs2 replay
                                      # on native vsav2 AND the build; BOTH
                                      # legs must match the frozen native
                                      # staircase 23/23/23/23/52 HP with 12
                                      # ticks and 5 per-attempt stock-
                                      # decrement EX tells. Locks the
                                      # x028122 object-hit damage work-var
                                      # reconciliation (same-value class
                                      # #4: ported applier staged into
                                      # vs2's $FF3494 family, vsavj reads
                                      # $FF3442). Ground-truthed FAILING on
                                      # the pre-fix merged; 2 verdict
                                      # controls (tick removed, no stocks)
tests/audit_pyron_ring.sh             # 14z-85, RE-FROZEN 14z-85b (~10 min,
                                      # 4 runs): pyron's merged-vs-solo
                                      # ring-id diff must be EMPTY (the
                                      # per-node sfx helper class is FIXED —
                                      # pyr/hui_sfx_records curated arrays;
                                      # pre-fix the diff was music 0x729 + 4
                                      # ids). Any new id or a missing solo
                                      # id FAILS. Solo default: pyron22
tests/audit_df_gold.sh                # 14z-84: Phobos' DF uploads HIS gold
                                      # block (live palette RAM vs the
                                      # build's own placed block) and
                                      # Bulleta's DF does NOT leak it (the
                                      # 14z-69p anti-class). Compare on
                                      # 0x0FFF color bits — the uploader ORs
                                      # the alpha nibble (v1 compared raw
                                      # bytes and called a WORKING upload
                                      # dead). DF-controlled rig. ~10 min
tests/audit_select_bank_gates.sh      # 14z-84: the merged drawer bank gates
                                      # (name/splash/winquote *_bank_variant
                                      # _id) must gate EVERY declaring
                                      # tenant's id — the first-playtest
                                      # name/portrait garble class (shared
                                      # TT-placeholder rows deduped to
                                      # tenant 0's compare). Static over
                                      # patch.json + fragment + manifests,
                                      # ground-truthed FAILING on the
                                      # pre-fix build. ~1s
tests/test_merged_render_content.sh   # 14z-83 (S5): the MERGED render gate
                                      # — H/P's FIRST render gates anywhere.
                                      # Live A/B vs the three frozen solo
                                      # builds in decoded gfx memory (no
                                      # frozen hashes): D 0x4AD8F, H
                                      # 0x40AF6, P 0x45000, the relocated
                                      # strip 0x486A0, group-B pristine at
                                      # 0x2AD8F, pairwise-distinct check,
                                      # 4-window poison control, 3 pick-
                                      # replay liveness. WINDOW CHOICE IS
                                      # LOAD-BEARING (header): merged bank 4
                                      # is a UNION — a window holding
                                      # another tenant's exclusive codes
                                      # fails BY DESIGN. ~25 min
tests/test_gfx_chain.sh               # 14z-83 (S2): the group-C gfx CHAIN
                                      # (--chain: prior link's members +
                                      # ledger seed the next). 4 sections:
                                      # solo Donovan == frozen build/m5_wide
                                      # /gfx byte-for-byte; idempotent
                                      # re-chain; D->H cumulative; and the
                                      # MUST-FAIL control — P onto H dies at
                                      # the known strip collision naming
                                      # both sources. >>> S3 flips section 4
                                      # to full-chain success. ~6 min
tests/test_extract_hp.sh              # Huitzil/Pyron extraction gate (14z-65):
                                      # frozen region shapes (piecewise shifts,
                                      # dead filler, the H insertion sliver) +
                                      # unanchored-char refusal control. ~2min
tests/test_patch_overlap.sh           # ground truth for the patch_prg op-overlap
                                      # assertion (14z-65): two ops writing one word
                                      # is a NAMED build error; disjoint and
                                      # word-adjacent ops stay clean. ~2s, no emulator
tests/test_m3a_reproducible.sh        # M3b Phase 0 gate: ALL FOUR frozen references
                                      # (donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8 /
                                      # huitzil-m2 9deda080 / pyron-m2 69e8c6f0)
                                      # rebuild bit-exact from the tree (scratch
                                      # dirs). Extended from the original PAIR in
                                      # 14z-76; its value scales with the count —
                                      # three independent tenant fingerprints are
                                      # three independent oracles over one refactor.
                                      # Needs only ROMDIR, no emulator. ~4 min.
                                      # Run after EVERY M3b machinery commit
tests/test_romset_identity.sh         # ground truth for tools/audit_romset_identity.py:
                                      # no member may carry the PRISTINE bytes of a member
                                      # the build patched (both emulators resolve a ROM
                                      # entry by hash before name, so such a member
                                      # silently reverts the patch — 14z-60z). 4 synthetic
                                      # sets, no emulator, ~1s
tests/test_hui_winscreen.sh    [bd]   # the WIN-SCREEN gate (14z-68m): palette
                                      # SOURCE (the OPCODE-view remap table, proved
                                      # by Donovan's frozen row), the SELF-LABELLING
                                      # marker (last word of each palette row = 5*row
                                      # — the check that would have caught shipping
                                      # Donovan's palette), all 8 colour sets, and the
                                      # portrait POSITION row. Static, seconds.
                                      # Negative control: FAILS on build/hui10
tests/test_hui_fx_flow.sh      [bd]   # the effect-flow attribution gate (14z-68):
                                      # leg 1 fighter-side flow identity (H's ray runs
                                      # HIS per-char handlers; the REFUTED 0x56D68 entry
                                      # must stay cold); leg 2 piece-side machine
                                      # attribution, auto-detecting pre/post-port from
                                      # the build's own patch notes. Rig: replay 83b
                                      # (2P dummy, 3 spaced 236LP, FBNeo taps).
                                      # Ground-truthed on hui9 + a bad-thunk negative
                                      # control. Self-builds stage 6 unless given
tests/test_hui_df_style.sh     [bd]   # the DARK FORCE gate (14z-69): replay 85
                                      # on NATIVE vsav2 vs the build. DF COSTS A
                                      # BANKED STOCK — the replay pokes $FF8509 and
                                      # the checker (tools/check_df_style.py) REFUSES
                                      # to judge unless both legs show $FF802E=1 and
                                      # a stock spent (seq 0x0A with an empty meter is
                                      # the DOWNGRADE, not DF — it fooled three
                                      # sessions). Freezes the OPEN defect's shape
                                      # (--expect differs: purple row 0x0A vs native
                                      # gold, his art drawn ~4x over); set
                                      # DF_STYLE_EXPECT=matches when fixed. Three
                                      # verdict controls. Defaults to the CURRENT
                                      # huitzil solo (build/hui51 since 14z-117b;
                                      # re-pointed at every freeze — read the
                                      # script's BUILD default, not this line)
tests/audit_empty_tiles.sh    [bd]     # 14z-69o: does the build DRAW any sprite whose
                                      # group-C tile is BLANK? A remapped-but-uncopied
                                      # tile renders as a SOLID RECTANGLE and no other
                                      # gate can see it (records/codes/walk all correct).
                                      # Complete, not a sample. Ground-truthed: PASSES on
                                      # build/hui14, FAILS on build/hui12 naming both
                                      # shadow tiles. RUN FOR EVERY NEW TENANT
tests/audit_palette_seq_ids.sh        # 14z-69p: which palette-seq ids does LEGACY ever
                                      # (14z-118: DFRPL= picks the DF rig — replay 85
                                      # never activates Anakaris, df/97 does; a DF-on
                                      # char with 0 calls is reported as NO PALETTE-SEQ
                                      # PATH; the full-roster result is frozen in
                                      # tests/expected/df_palette_seq_census.txt)
                                      # request? (uncapped probe on 0x2AD82, 8 replays).
                                      # The DF-palette data row is legacy-inert ONLY
                                      # because the answer is {0x26, 0x27} — and the
                                      # palette path never transits work RAM, so this
                                      # audit is its ONLY guard. Use GUARD_PROBE_MAX:
                                      # the default 400-hit cap truncated it once and
                                      # hid id 0x27
tests/test_beam_variants.sh    [bd]   # 14z-70h: the beam-port premises. All THREE
                                      # variants (236+P / 236+K / 236+2P==2K) are ONE
                                      # art path — pal 0x0C from the tenant band — and
                                      # every tile they draw is ALREADY in group C, so
                                      # the port needs no copy-inventory work. Encodes
                                      # two paid-for traps: ES CONSUMES A METER STOCK
                                      # (empty meter = silent downgrade, like DF, so it
                                      # asserts the ES is richer than P), and multi-tile
                                      # sprites must be expanded w*h at base+row*0x10+col
                                      # (obj_records_dump reports the BASE code only).
                                      # Native leg only, ~1 min
tests/test_beam_anim_walk.sh   [bd]   # 14z-70: does the build ever WALK the anim
                                      # nodes that carry the beam sprite lists?
                                      # Native reads 0x24FCFA twice in its beam
                                      # window; ours reads the placed twin 0x0E2DD8
                                      # ZERO times — the defect is anim-sequence
                                      # SELECTION, not the draw path. 4 sections
                                      # (static port check 11/11 relocated pointers,
                                      # native leg, our leg, 3 verdict controls).
                                      # BEAM_WALK_EXPECT=walks (default since 14z-71) |
                                      # absent reproduces the pre-fix state.
                                      # Defaults to the current huitzil solo
                                      # (build/hui51, re-pointed each freeze). ~2 min
tests/test_beam_list_type6.sh         # 14z-71: the list-type 6 TAKEOVER gate. The
                                      # thunk body must be Capcom's composite handler
                                      # (vs2 0x01A1FC) with EXACTLY six scratch
                                      # displacements, bsr.w -> jsr 0x1AFAE and one
                                      # loop displacement changed — checked by
                                      # RECONSTRUCTING it from vs2's bytes, not by
                                      # diffing with a tolerance. Also proves the
                                      # non-tenant FALLBACK reproduces vsav's own
                                      # type-6 head and rejoins at 0x01B6B2, which is
                                      # the entire safety argument and which legacy
                                      # never exercises. Static, seconds
tests/audit_effect_class_rows.sh      # 14z-71: the THREE deadness measurements the
                                      # beam port rests on — effect-class row 16 is
                                      # never dispatched by vanilla (0 reads, against
                                      # a 1760-hit control on row 37); the composite
                                      # handler's A5 scratch $FF3578-$FF3581 IS used
                                      # (39/replay) so vs2's displacements cannot be
                                      # kept; and drawer list-type 10 is NOT a spare
                                      # slot (2702 reads) — the closed shortcut.
                                      # EVERY section carries a same-instrument
                                      # positive control: this file exists because a
                                      # blind watchpoint and a real zero look
                                      # identical, and both traps bit here (GOTCHAS)
tests/test_wide_render_content.sh     # the WIDE track must SERVE the ported content's
                                      # tiles (RE-SHAPED 14z-67 for m3a semantics —
                                      # cross-track pixel identity ended BY DESIGN):
                                      # member identity + decoded band equivalence at
                                      # the correct banks (WIDE 0x4AD8F == stock
                                      # 0x2AD8F; WIDE 0x2AD8F == PRISTINE, the
                                      # de-substitution invariant) + a true-shadow
                                      # audit control + liveness (replay 36). This is
                                      # the gate whose absence let the sprite garble
                                      # reach a playtest — AND the gate that sat
                                      # stale-red from 14z-64 to 14z-67 (GOTCHAS:
                                      # the not-in-the-battery class)
tests/test_release_roundtrip.sh [rp nm] # 14z-105 (ci_static, ~40 s): THE RELEASE
                                      # PACKAGE GATE — package, apply to the
                                      # pristine dumps, byte-identical x42 +
                                      # fingerprint + manifest; the applier
                                      # refuses corrupted patch / wrong sha1 /
                                      # wrong dump without writing; rule 7
                                      # verbatim-chunk scan with a must-fire
                                      # control. Needs xdelta3.
tests/run_suite.sh [--freeze] [set]   # SUITE_ONLY="<name> ..." (14z-105): run
                                      # only the named replays — an AUTHORING
                                      # aid (re-freeze the .sha1 replays in
                                      # minutes instead of the ~3 h full pass);
                                      # prints FILTERED and is never a verdict
tests/test_oboro_select.sh [wide stock] # 14z-105 (W1, ~4 min, 5 MAME runs): THE
                                      # OBORO SELECT HOOK — Bishamon's cell +
                                      # START held at confirm commits vanilla
                                      # vsavj's Oboro (0x18) and the match
                                      # loads base 0x0B3450. Legs: P1 hold /
                                      # no-hold control / Start on Demitri
                                      # (cell-gated) / P2 side / the STOCK
                                      # twin (profile-gated => 0x08). Every
                                      # leg asserts id AND loaded base. No
                                      # pokes — the pick is made with the
                                      # sticks. Verdict control. Defaults
                                      # build/m3b_merged13 + build/m5_stock6
tests/test_pyron_medallion_2p.sh [wide] # 14z-116 (~5 min, 2 MAME runs): THE
                                      # P2-HOVER half of medallion palette
                                      # stability. Row 0x1A is BOTH Pyron's
                                      # medallion row and the P2 figure's
                                      # sword-accent slot; the 62k thunk's
                                      # P2 branch no longer writes it.
                                      # Leg 1: P2 hovers Donovan -> 0x1A
                                      # holds Pyron's vs2 palette. Leg 2
                                      # MUST-FIRE: P1 hovers Donovan -> row
                                      # 0x17 still RECEIVES the accent, so
                                      # leg 1 cannot be "passed" by deleting
                                      # the thunk. CLOSES A COVERAGE GAP:
                                      # test_wheel_bank5 3b's two protocols
                                      # are both single-player and could
                                      # never see this. Default
                                      # build/m3b_merged19
tests/test_shadow_tenant.sh [wide]   # 14z-116 (~6 min, 2 MAME runs): SHADOW
                                      # MORPHING INTO A TENANT. The "?" cell
                                      # + FIVE START PRESSES arms $43
                                      # (PRG:0x020CB0 — presses, not a hold);
                                      # confirm sets $3BC; at the ROUND END
                                      # PRG:0x009BB2 gives the flagged winner
                                      # the LOSER's id, UNMASKED. Asserts P1
                                      # beats tenant Donovan and becomes
                                      # id 0x13 with DONOVAN'S OWN record
                                      # 0x003FA9D0 — the point is that it is
                                      # NOT Victor's 0x0009769E, the shell
                                      # 0x13 aliases (the quiet failure the
                                      # maintainer named). Must-fire control:
                                      # the same replay with FOUR presses
                                      # must not arm, not set $3BC and not
                                      # morph. Replay 113; only the FIRST
                                      # morph is deterministic (the arcade
                                      # draw is a lottery past ~8500).
tests/test_random_select_tenants.sh [wide] # 14z-117 (~12 min, 4 MAME runs): RANDOM
                                      # SELECT INCLUDES THE TENANTS. Static: both
                                      # sites are jmps, body B's table = 15 vanilla
                                      # ids + the build's tenants.json, outside the
                                      # crypt range. Runtime: P1 parks on "?" (D,D,DR),
                                      # $382 sampled 91 frames = exactly 15 + tenants;
                                      # confirm on a tenant's MIDDLE frame loads that
                                      # tenant's own record; must-fire control = the
                                      # previous merged (CONTROL=, no tenant drawn).
tests/test_version_string.sh [outbase] # 14z-105 (W2, ~2 min, 2 MAME runs): the
                                      # select-screen VERSION STRING — the
                                      # wheel record's last N entries are the
                                      # glyph codes at the declared pal row
                                      # and screen position; authored tiles
                                      # packed byte-identical, non-blank,
                                      # pen-15 background, font-exact; the
                                      # LIVE OBJ list carries exactly N glyph
                                      # sprites at OBJ (x+64, y+16); a MAME
                                      # snapshot pixel-matches the intended
                                      # bitmap with ZERO mismatches (this is
                                      # what caught the codec half-mirror).
                                      # Controls: 1px shift, corrupted tile.
                                      # Knobs read from the manifests and
                                      # asserted identical across them.
tests/test_gfx_tile_codec.sh          # 14z-105 (ci_portable, ~1s): the CPS-2
                                      # OBJ tile bit law (plane bit i = pixel
                                      # 7-i within each 8-px half, pen 15
                                      # transparent), round trips both ways,
                                      # and the PRE-FIX mirrored mapping
                                      # reconstructed inline and required to
                                      # DISAGREE on an asymmetric tile.
tests/audit_voice_borrow.sh [bd]      # 14z-87 (~6 min, 2 MAME runs): THE
                                      # VOICE-CLASS BORROW mechanism gate —
                                      # the sword-plant "ding" frozen as its
                                      # LOTTERY-PROOF invariants (the fired id
                                      # varies run-to-run with the QSound-latch
                                      # phase, so no single id is frozen):
                                      # static table facts (0x00B268/0x00BB68,
                                      # tenant rows alias 0x03, vs2's Victor
                                      # row lists 0x13), the serialized
                                      # single-run write+read on $FF8782
                                      # (writer must be PRG:0x0AEF6; the
                                      # dispatcher must read the SAME value —
                                      # tests/lua/read_tap.lua, the anti-
                                      # cross-run-correlation instrument), and
                                      # the ring-window membership over the
                                      # WHOLE candidate family. 2 verdict
                                      # controls. Default: own-class on
                                      # build/don_m10 (14z-103; the b+c fix
                                      # ships in every current build);
                                      # VOICE_BORROW_EXPECT=lottery vs
                                      # build/don_m4 = the ground-truth-
                                      # failing pre-fix pair
```

## [14z-123 G6 (2)] «The review-triage table (as of 14z-123)»

| gate | issue | what it locks |
|---|---|---|
| `test_optimize_guard.sh` | #79 | Six tools refuse `python -O`, which REMOVES asserts rather than weakening them. Its systemic section — any assert-using tool a builder invokes must carry the guard — is what found four of the six; #79 named two. |
| `test_romset_path_guard.sh` | #76 | `build_wide_romset` cannot take the reference set as its own output. The one failure in that file with **no undo** (rule 7 forbids in-tree romset copies). |
| `test_mame_mirror_guard.sh` | #80 | `rsync --delete` runs only in a directory `setup_mame.sh` owns. Guard is EXTRACTED from the shipped script between markers, never copied. |
| `test_basis_publish_atomic.sh` | #86 | A masked basis publishes whole or not at all. Drives the REAL script symlinked into a fake repo with a stubbed MAME runner. |
| `test_qs_ledger_binding.sh` | #89 | QSound audit ids come from a ledger fingerprint-bound to the artifact under test, never rebuilt from `build/wide0`. |
| `test_freeze_retires_diverge.sh` | #88 | `--freeze` retires a superseded `.diverge` instead of leaving it to shadow the new `.sha1`. |
| `test_meter_in_field_map.sh` | #83 | The dual-emulator oracle actually compares meter, bound to `ram.md`. |
| `test_qs_wav_timebase.sh` | #85 | The WAV audit converts frames at the CPS rate (59.6374 Hz), not 60. |
| `test_no_tracked_mutation.sh` | #81 | No test writes into `tools/`; controls perturb a `shadow_tools.sh` copy. |
| `test_gfx_layout_fields_live.sh` | #87 | `gfx_layout3.toml`'s profile/scatter fields are enforced, not decorative. |
| `test_harness_frame_bound.sh` | #77 | FBNeo replay frames are bounded before the arithmetic; the cap is re-derived from `tests/replays`, not trusted. |
| `test_static_runner.sh` | #30 | ground truth for `run_all_static.sh`'s PASS/SKIP/FAIL classifier. Sharpest case: SKIP in PROSE must still count PASS. |
| `test_battery_accounting.sh` | #24 | `run_battery_m2.sh` cannot print BATTERY GREEN while gates self-skip; counts branch skips by group size. |
| `test_decrypt_cache.sh` | #69 | the decrypt cache delivers full, correct images; a TRUNCATED cache is refused, not silently served. |
| `test_build_ref_rot.sh` | #94 → 14z-97 | A hardcoded `build/<name>` default must not have ROTTED (present, read as a romset, too old to carry the members the reader needs). **Extended 14z-97 twice:** the pattern matched POSITIONAL defaults only, so eleven named-env references (`BUILD="${BUILD:-build/don_m7}"`) were invisible — coverage 21 → 32; and it now REPORTS CURRENCY, which rot cannot see, because a superseded build loads perfectly (that is how #96 happened one level up). Currency reports and never fails: a superseded reference is often correct, and only the gate's author knows which. Today: 3 current, 16 superseded. |
| `test_select_port_hygiene.sh` | #46 | `select_port` is chainable, idempotent, and free of unreachable code — while KEEPING the round-22 analysis. |
| `test_build_identity_distinct.sh` | 14z-94 | the merged playtest build stays distinguishable from its legacy-only instrument, which SHARES its program fingerprint by design. |
| `test_record_walk_bounds.sh` | #51 | Both record walkers examine the last long that fits. |
| `test_pcrel_escapes.sh` | #22 | The pc-rel DATA-escape set is unchanged since reviewed. **Not portable** — needs builds + `vsav2_data.bin`. |
| `test_baseset_mask_invariant.sh` | #62 | Every `.masked` spec cites a basis frozen under its own mask. |
| `test_mask_ranges_reader.sh` | #61 | The mask reader masks exactly the spec and refuses nonsense. **Not portable** — needs ROMDIR + a WIDE build. |
| `test_patch_source_identity.sh` | #18 | A patch applies only to the source set it was verified against. **Not portable.** |
| `test_guard_integrity.sh` | #31 | The crash guard checks inputs and refuses what it cannot honour. **Not portable.** |
| `test_phasea_a3_liveness.sh` | #25 | A3 cannot decide gfx growth on a measurement it never made. |
| `test_hex_lengths.sh` | #20 | Generated hex writes are length-checked. |
| `test_minitoml_subset.sh` | #42 | The TOML subset refuses dotted headers/keys, duplicates, signed hex. |
| `test_member_classify.sh` | #19 | The PRG suffix class excludes `m` members. **Not portable.** |
| `test_builder_rom_audit.sh` | #38 | Builders audit the ROMs they read. **Not portable.** |
| `test_m2a_target_policy.sh` (was `test_m2a_mask_pin.sh`) | #70 → #96 | **The assertion was INVERTED 14z-97.** It used to lock the battery's V1 mask copy against run_suite's, because the pin to the donovan-m2c generation was deliberate and re-pointing it was an open maintainer question. That question was ruled 2026-08-19 (option (a)), so the pin and the duplicate are gone and this now fails if either returns: no literal mask in `m2a_common.sh`, no expectation-set constant, the target resolved from the fingerprint, the V1 literal defined in exactly one file, and the ruling still written down. |
| `test_fbneo_overlay_hygiene{,_control}.sh` | 14z-94 | FBNeo overlay hygiene (`_control` is its must-fire control) |
| `test_reconcile_matcher.sh` | #43(a) | ONE matcher, two callers. `reconcile_batch`'s drifted copy of `find_equiv`'s core is deleted; the three drifts survive as parameters pinned to the batch tool's MEASURED values. Section 2 proves the refactor inert against the pre-refactor copy reconstructed from git (1640/1640 probes), with a must-fire control; section 3 proves the parameters load-bearing (183/1640 change when freed), so #43(b) is a real change and section 2 is not vacuous. **Not portable.** |
| `test_merged_inputs.sh` | #27 | the merged build's four ROM-derived inputs are PRODUCED, not demanded — and a regenerated set yields the identical merged patch. Asserts the ARTIFACT is reproducible rather than that the input dirs are byte-equal, because the latter is false and cosmetic: `build/m5_wide/extract/regions.json` predates two `extract_char.py` changes. **Not portable.** |
| `test_record_window.sh` | 14z-94 | the windowed MNG recorder (2.4 MB/120 frames vs `-aviwrite`'s 5.7 GB/2 min). **Not portable.** |
| `test_decode_stage_banners.sh` | #92 | the stage-banner decoder — incl. the control requiring a base-as-ANCHOR decode to FAIL LOUDLY. **Not portable.** |

## [14z-123 G6 (2)] «The MiSTer gate table (as of 14z-123)»

| gate | tier | what it locks |
|---|---|---|
| `tests/test_jtcores_twin.sh` | ci_portable | pin, cps2w-vs-cps2 twin, the patch SERIES == `format-patch` per commit |
| `tests/test_sim_wram_contract.sh` | ci_portable | dump naming + 68k byte order + skew absorption, two must-fire controls, the rule-7 refusals, a static proof that every line the harness patch adds sits inside `#ifdef _JTFRAME_SIM_WRAMDUMP` — and since 14z-107 (7) the DUMP-INTEGRITY assertion (`tools/check_wram_dumps.py`, six checks: a hole, a truncated file, a stray frame, a wrong address, `--contiguous` and its hole) plus the lane's frame-output default (`--frame-output off` -> `-d JTFRAME_SIM_NOVIDEO=1`) with a flipped-default control and the shape of fork patch 0008 |
| `tests/test_rpl2siminputs.sh` | ci_portable | `.rpl` -> `sim_inputs.hex` bit map, frozen translation, refusals, **the per-direction lock + its must-fire control (5/5b), and the anchor-independence check + its positive control (6/6b)**. The direction map was REVERSED end for end and is FIXED (14z-108, measured on all four against `RAM:$FF8058`): the frozen vector moved `111 6ee 000 000 080` -> **`181 67e 000 000 010`**, and the `05_timeout_idle` sha1 `eb3e1d04…` **did NOT move and cannot** — that replay scripts no direction token, which is also why the sim anchor could not move |
| `tests/audit_sdram_bank_load.sh` | **manual/emulator (~65 min)** | the per-bank SDRAM traffic profile (ACTIVE counts, share, kiB/s, same-row hit rate and mean run, clash warnings) split into attract / select / in-match — the evidence for the MiSTer BANK REPACK ruling. **Since D3 it has TWO legs**: the default `--core cps2` on stock `vsavj` (the headroom bound) and `--core cps2w --wide build/m3b_merged18` on the WIDE romset, which is what answers `mister_map.md` §9 open question 1 — only a core carrying the obj promote can produce group-C traffic at all. The WIDE leg shifts every phase boundary by the longer transfer and ASSERTS the transfer length from the run's own log. It also prints a **PEAK per-bank table** derived from the run's own reporter intervals: saturation is a property of the worst interval, not of a phase average, and the peak table depends on no frozen boundary. `--log FILE` re-analyses `build/sdram_bank_load_14z107.log` offline. **THE WIDE LEG HAS NOW RUN, 14z-107 (12), ON A BOOTING IMAGE, AND THE ANSWER IS YES WITH ROOM**: bank 0 carries 40,717 accesses/frame through the select screen (**32.9%** of its 123,825 all-miss ceiling), 41,535 in-match, whole-run peak 54,363 (43.9%), data bus 16-18%, and ZERO `SDRAM reads clashed` in 3,500 frames — the redirect costs bank 0 about 1,000 accesses/frame, ~2.5%. The run's own anchor landed at **2806** = the frozen 2609 + the 197-frame transfer difference, so its phase boundaries were checked rather than assumed. **What it does NOT bound: bank 1's group-C half.** `05_timeout_idle` picks Demitri, so obj bank 4 is never fetched and ba1's 13,890 accesses/frame are PCM alone **`--rpl FILE` (14z-108) runs or re-analyses a DIFFERENT replay, and REFUSES the phase table when given one**: the four boundaries are absolute simulated frames keyed to `05_timeout_idle`'s frozen match-start anchor, so on any other replay they label phases that are not there. It reports whole-run per-bank rates (download EXCLUDED, its end parsed from the log and refused if absent) plus the `WARNING: (test.cpp) SDRAM reads clashed` count, anchored to the line so this report's own prose about clashes is not scored as evidence. That path is validated on synthetic logs whose answer is known by construction (rates of exactly 10/5/2/3 per frame; 3 warnings counted as 3, the same text as prose counted as 0), and the default path still reproduces the frozen 14z-107 table unchanged. **`test_mister_gfxc_fetch` now passes `--stats`, so a tenant-match run answers the fetch question and the bank-load question from ONE simulation** |
| `tests/audit_mister_map_fit.sh` | ci_static (~5 s) | the SDRAM PLACEMENT MAP fits the 64 MB tier **AS PLACED — by 0.125 MB, with bank 1 EXACTLY FULL (corrected 14z-107 (9) by the census; the old 0.708 MB sized the group-C obj banks by the art's footprint where the download reserves the whole 8 MB region)** — the banks are modelled from the placed offsets and lengths with an overlap check, and the four content extents are frozen: group-C obj bank 4 ceiling `0xEE73`, obj bank 5 ceiling `0xFFDB`, QSound live `0x8E57F0`, PRG live `0x5FFF1E`. Also checks the `.rom` against the 26-bit `ioctl_addr` and the 16-bit header words. Re-checks the "tile code IS its SDRAM address" scramble identity §1 rests on. THREE must-fire controls (untrimmed QSound must be rejected; +1 MB of the obj-bank-5 REGION must overflow bank 0; the identity must fail without the scramble). Design: `docs/project/mister_map.md` |
| `tests/test_mister_mra_map.sh` | ci_static (~15 s) | **SLICE D0**: the WIDE `.rom` is EXACTLY `mister_map.md` §3 — 66,265,152 B, header words 6144/6400/15552/64704, every region 1 KiB-aligned and byte-for-byte the romset's, the trimmed QSound region a PURE truncation. Also: the stock `vsavj` MRA from `cps2w` == `cps2`'s except `<rbf>`, `cps2` emits NO WIDE MRA (the `cps2w.cpp` sourcefile gate), stock `vsavj.rom` still BIT-IDENTICAL (46,407,744 B, sha1 `f9dc2987…`), and the fork's catalogue entry names the CURRENT build's CRCs. TWO must-fire controls: untrimmed -> 73,670,720 B / `qsnd_start` 71,936 KiB (and the generator SILENTLY writes the wrapped word); `length` +0x400 -> the frozen table fails |
| `tests/test_mister_wide_gate.sh` | ci_portable (~30 s with Verilator, seconds without) | **SLICE D1, the RTL trust surface.** The frozen line-by-line delta of the two OVERRIDDEN files vs the shared originals (`tests/expect/cps2w_rtl_delta.txt`); the profile byte agreeing in all three copies (TOML `offset=41 data="fe"`, RTL `PROFILE_BYTE=6'd41`, `~profile[0]`) plus the `fill=0xff` and `JOY_BYTE` facts the polarity rests on; the widths, and that `PCM_AW` is NOT widened (it cannot be — `jtframe_romrq_bcache.v:74`); MAME's three qsound.cpp lines that validate `dsp_ab[7]`; and `jtframe files` resolving cps2w to OUR nine overrides + three new modules + the new jtframe slot module, and cps2 to NONE of ours (the two lists differ in exactly 22 entries). Then Verilator: `jtcps2w_qsnd_bank` over **all 65,536 `dsp_ab` values in both profile states** (bank[7] stuck at 0 with `wide_en` low, moving 16,384 times with it high) and `jtcps2w_profile` over a real 64-byte header stream. FOUR must-fire controls: gate bypassed; profile byte moved to 40; polarity flipped; an override perturbed by one width. **EXTENDED AT D2 (section 7)**: every SDRAM placement constant re-read from `jtcps1_sdram.v` in BYTES and compared against `mister_map.md` §5 (VRAM `0x600000`, ORAM `0x640000`, WRAM `0x648000`, Z80 `0x658000`, PCM-high `0x6E0000`, group-C obj bank 5 `0x7E0000`, obj bank 4 bank-1 `0x800000`); all four `wide_en` conjunctions re-read verbatim; the CPS1 arm of the re-pack still the reference values; and `jtframe_ram1_7slots` NOT in jtframe's shared `jtframe_sdram64.yaml`. **EXTENDED AGAIN AT D3+D4 (section 8)**: a third Verilator bench, `jtcps2w_obj_bank` over **all 65,536 y-words in both profile states** (bank[2] stuck at 0 with `wide_en` low, set 32,768 times with it high) which also transcribes `tools/gfx_tiles.py`'s `bank_word` table and requires each of the six encodings to decode to its own bank with none of them setting y bit 15 — the sprite-list TERMINATOR; the sprite-list terminator test in the override asserted IDENTICAL to the reference core's AND at an earlier line than the promote; the 3-bit bank asserted at all six ports between the frame table and SDRAM; `rom0_bank[2]` now UNTIED; and D4's `wide_en & RnW` read decode, 22-bit `rom_addr`/`main_rom_addr`/`SLOT3_AW`, the `4'h6` wait-state boundary and the surviving `!RnW` on `objcfg_cs`. TWO more must-fire controls: the promote's gate bypassed, and the promote reading `y[15]` instead of `y[12]` — the profile's first draft |
| `tests/test_mister_page.sh` | ci_portable (~8 s) | **THE SYNTHESIS CANNOT GO STALE.** `tools/mk_mister_page.py --check` re-derives every figure `docs/project/mister_core.md` states (17 checks) from the same constants the other gates freeze — the roster's live bytes and address footprint, the declared-region arithmetic, the four bank extents and the 0.125 MB slack, the `.rom` size and header words, the anchor and its band — and recounts the group-C ceilings from the romset. The rendered page is NEVER committed (`.gitignore`); the generator is. Written as the living-documentation pilot (14z-107 (10)) |
| `tests/test_checkskills.sh` | ci_portable (~1 s) | **THE SKILLS ARE LOCKED TO THE DOCS (14z-114): the MiSTer pair `[MSC]`/`[MSV]`, the CPS-2 pair `cps2-hardware` `[CPH]` / `cps2-emulation` `[CPE]`, the game skill `vampire-savior-engine` `[VSE]` (anchored in `engine_internals.md`, `game/gotchas.md` and the atlas; forbids port vocabulary), and the port skill `vampire-saved-port` `[VSP]` (161 rules anchored in CLAUDE.md, HANDOFF, both gotchas, the porting/manifest/triage/hardening/registry docs and — ONLY under "STANDING PRINCIPLE" / "THE DEADNESS REGISTER", because the file rolls — STATE.md), table-driven per prefix.** `tools/checkskills.py`: every `- [PFX-N]` rule in `.claude/skills/*/SKILL.md` is anchored exactly once (`**[MSC-N]**` at the doc paragraph it distils) and every anchor has a rule; the level-1 skill names nothing game-specific (`mister_scope.md` §1); every number a skill quotes appears in a LOG (`platform/mister.md`, `mister_map.md`, `mister_fit.md`, `mister_field.md`, `release_format.md`, the gotchas, `BITSTREAM.txt`) and never only in the synthesis. Cross-references `[PFX-N]` between skills must name a defined rule. Extractors self-tested; eight must-fire controls on a perturbed copy (unanchored rule ×2, stripped anchor, a game name in level 1, a port token in the game skill, an uncited number, a dangling cross-reference, a VSP anchor in STATE outside the standing sections). **Editing an anchored paragraph: keep the marker with the fact, or move the rule** |
| `tests/test_checkdocs.sh` | ci_portable (~0.2 s) | **THE DOCS ARE LOCKED TO EACH OTHER (14z-118, the documentation audit):** `tools/checkdocs.py` reads `docs/doc_locks.tsv` — one row per load-bearing number (label, canonical value, a key regex naming the fact, the documents that must quote it, the sibling values allowed beside it) — and asserts PRESENCE (every listed doc quotes the canonical verbatim) and NO RIVAL (no other value of the same shape within 80 chars after the key unless in `also`). The atlas row is canonical; syntheses follow it. Seeded with 16 locks / 40 file-sites from `doc_audit_14z118.md` §2 (OBJ bank table, sprite-palette pointer table, AI script tables, the voice-borrow writer, the Gallon-variant idiom, the loader, the id fold, the id pair, the fade window, name entries, the ring base, match-init normalisation). Twelve extractor self-tests every run; three must-fire controls on a perturbed copy (dropped number, rival number, missing file). **Add a row whenever a number is quoted in a second document** |
| `tests/test_doc_anchor_census.sh` | ci_portable (~1 s) | **EVERY SKILL ANCHOR'S FILE AND SECTION ARE FROZEN (14z-122, the documentation rationalization pass):** `tools/doc_anchor_census.py` walks every doc `checkskills.py` reads PLUS the archives it does not (STATE_HISTORY, DECISIONS_HISTORY, NEXT_SESSION, GOTCHAS, patch_notes, every `*_history.md` twin) and freezes one row per `**[PFX-N]**` — id, file, nearest preceding header, list status — in `tests/expected/doc_anchor_census.tsv`; `--check` diffs it, and hard-fails a defined rule anchored in a history twin or on two rows. WHY: `checkskills` asserts "exactly one anchor somewhere in the list", so a paragraph moved between two files of one list, or to another section, passes it SILENTLY — control A proves that on the real tree (checkskills PASSES the move, the census fails it). A doc commit that moves an anchor reviews the diff and `--freeze`s in the same commit. Four must-fire controls (between-file move, section move, history-twin anchor, a stray token in an archive). `--list-files` prints every file this tool and checkskills read, for copies |
| `tests/test_docshape.sh` | ci_portable (~2 s) | **EVERY HAND-WRITTEN DOC'S SHAPE IS DECLARED AND ENFORCED (14z-122):** `tools/checkdocshape.py` reads `docs/doc_shape.tsv` (one row per doc: class, history twin, requirements; completeness both ways, so a new doc is classified at birth) and lints REFERENCE/REGISTER docs against SESSION-SHAPED HEADERS (a trailing provenance parenthetical — `(measured 14z-N)`, `(paid: 14z-N)` — is stripped by a wrap-tolerant scanner first; a group carrying RETRACTED/superseded words is never stripped), holds ORIENT (NEXT_SESSION) to one `# ` header with history in its twin, forbids anchors in HIST docs, requires declared banners/atlas-rows, resolves every doc link in README/HANDOFF/CLAUDE.md, and verifies every `docs/x.md 'Section'` citation in tools/tests against the file's real headers (backticks normalized, a trailing `...` = prefix). Allowances in `docs/doc_shape_allow.tsv` — a row matching no header FAILS as dead. PENDING rows are skipped until their document's commit flips them; `--no-pending` is the pass-close mode. THIS is what stops the logs re-accreting after the rationalization pass. Seven must-fire controls. First real run found: 26 session-shaped headers (venue_assets + the three gotchas buckets re-classed PENDING for their own commits), CLAUDE.md's docs/annotations.md row promising a file git never saw (retired, open to veto), and three stale section citations |
| `tests/test_gotchas_index_current.sh` | ci_portable (~1 s) | **docs/GOTCHAS.md IS GENERATED (14z-122):** `tools/gen_gotchas_index.py --check` regenerates the index from the three buckets' `## ` headers (consecutive `## ` lines are ONE wrapped header, `**[PFX-N]**` tokens stripped, `(paid:)` tags kept so a grep that hits the index hits the bucket; no per-entry slug links on purpose) and `cmp`s it — the `test_tables_current` pattern. The hand-written index it replaced (ten `### appended 14z-N` digests + a third abridged copy of the buckets) is verbatim in `docs/GOTCHAS_history.md`. After appending a gotcha, REGENERATE: `python3 tools/gen_gotchas_index.py`. Two must-fire controls |
| `tests/test_annotations_current.sh` | ci_portable (~1 s) | **docs/annotations.md IS GENERATED (14z-123, the T1 annotations check):** `tools/gen_annotations.py --check` regenerates the address -> label/comment stream CLAUDE.md §5 promised at M0 — every program-space address named by a live carrier (the atlas, `engine_internals.md`, the reference docs, `build/manifest/*.toml`, `tools/`, `tests/`) with the carrier file and the section or manifest row it sits under; no line numbers by design (they churn on unrelated edits). The tail section lists CODE-ONLY addresses — the documentation gap. WHY: `re/ghidra/` never held a project; the 14z-122 retirement note claimed the stream lived in the atlas + manifest comments, and the check measured ~2,900 addresses across five carrier kinds, ~220 named only in engine_internals prose and ~265 only in code. Four must-fire controls on a synthetic root. Regenerate after any edit that adds or removes a program address: `python3 tools/gen_annotations.py`. |
| `tests/test_tables_current.sh` | ci_static (~1 s; SKIPs without the three solo build dirs) | **THE COMMUNITY TABLES FOLLOW THE BUILD (14z-118):** `docs/project/tables/{donovan,huitzil,pyron}.md` are rendered by `tools/tables_char_md.py` from each current solo build's `extract/regions.json` + `bank_map.toml` (inputs' SHA-1s, shifts, regions with SHA-1s, dispatch targets, VS2-vs-VH2 variant sites, the per-character VALUE rows = the tunables of CLAUDE.md §2 rule 5); the gate regenerates and `cmp`s, failing on drift. One must-fire control (a perturbed `word132` must regenerate differently). Defaults `DON/HUI/PYR` = the current solos (re-point sweep). **Regenerate the three pages in every freeze commit** |
| `tests/test_charmap_current.sh` | ci_static (~20 s; SKIPs without the three solo build dirs) | **THE CHARACTER-DATA MAP (14z-118, maintainer's request):** `docs/project/tables/chars/<tenant>.json` (agent-target) + `.md` (human page) generated by `tools/charmap_gen.py` -> `tools/charmap_md.py` from each current solo build — every bank row (physics decoded 16.16), the 20 dispatch rows, every ported region's byte diff ATTRIBUTED (relocated pointers checked against placements and the reconciliation map, `[gfx_remap]` band + the build's `effect_map.json` shelf codes, region_fix/port_patch/table_fix/data_port fixes, effect-list pointers, overrides), sfx records, FSM state-node runs, sprite-list summary, and a generated "What is NOT decoded" worklist. `UNATTRIBUTED` counts are frozen by the cmp. Controls: a changed built byte -> +1 unattributed; an override row -> `override:<id>`. **Regenerate in every freeze commit** (the map names the build) |
| `tests/test_charmap_overrides.sh` | ci_portable (~1 s) | **THE OVERRIDE CHANNEL:** `build/manifest/charmap_<tenant>.toml` (hand-written: `[[override]] id/path/expect/value/stage/note`, path `region/<name>/<hexoff>` in phase 0) compiles via `tools/charmap_compile.py` into the `# BEGIN charmap … # END charmap` block of the tenant manifest as ordinary `[[region_fix]]` rows — gen_donovan_patch.py unchanged. The committed block must equal a fresh compile; wrong `expect` / length mismatch / stale block all fail |
| `tests/test_anim_node_walk.sh` | **emulator (MAME, ~2 min)** | **THE ANIM-NODE DECODER IS AN INSTRUMENT (14z-118, phase 1):** `tools/anim_nodes.py`'s chains vs Donovan on NATIVE vs2 (`17_don_oracle_vsav2`), P1 `obj+0x1C`/`+0x20` per frame — every pointer on the graph, every change an edge or a jump onto a graph node, first countdown = dur or dur−1; negative control: a stride-0x17 decode must leave most pointers off-graph. Run after any change to the decoder or the node-format claims in `engine_internals.md` |
| `tests/test_move_naming.sh` | **emulator (MAME, ~3 min, legs in parallel)** | **THE MOVE LISTS' CHAIN IDS ARE WHAT NATIVE VS2 ENTERS (14z-120, phase 1 naming step; all three tenants since 14z-120 (2)):** `tools/name_moves.py gen` regenerates the rigs (`tests/replays/naming/<tenant>_<part>.{rpl,json}` must match — Donovan 8 parts, Pyron 4, Huitzil 8), runs them on native vs2 (Pyron/Huitzil forced by the early-window poke, both fighters' X pinned before every event) with P1's `obj+0x1C` sampled per frame, maps every pointer onto `anim_nodes.py`'s graph from that tenant's extract and compares each event's entered-chain list to `tests/expected/move_naming_<tenant>.txt`; every `table:seq` in `build/manifest/moves_<tenant>.toml` must have been entered; positive controls Blizzard HP = vs2 `0x283E58` (replay 59) and Lightning ES = `0x284A64` (replay 56); negative control: a swapped line fails the compare. Run after any change to a move list's seq ids, the rig schedules, the decoder or the vs2 extracts |
| `tests/test_hitbox_encoding.sh` | **emulator (MAME, ~4 min, four legs in parallel, two of them -debug)** | **THE HITBOX ENCODING AND THE ATTACK RECORD (14z-120 (5), phase 2):** Donovan on native vs2, `name_moves.py` parts 9/10 (normals that connect, a whiff ladder, a projectile, the multi-hit Lightning Sword, Ifrit, the column) under `field_trace.lua` + the `trace_writes.lua` tap on the victim's `+0x50..+0x55`; asserts the five table pointers (`+0x8C` = attack = base[4], `+0x90` = push = base[3]), A3 = attack record of the attacker's node (`hbA>>8`) on every HP write, 8/8 hits on the first overlap frame under the mirrored-x convention with no whiff overlap (negative control: the un-mirrored convention), and victim `+0x54` = record `+0x17` on the fighter, projectile, multi-hit and column paths. Run after any change to `tools/hitbox_records.py`, the rigs or the extracts |
| `tests/test_reactions.sh` | **emulator (MAME, ~2 min, legs in parallel)** | **THE REACTION SETS (14z-120 (7), phase 3):** the tenant on P2 (P2 early-window poke) vs Victor on P1 (forced 0x03); every contact class hit and blocked; `tools/reaction_map.py` turns P2's node pointer into one line per contact (class, freeze, chain path table:seq@node, frames to the return) frozen in `tests/expected/reactions_<tenant>.txt` (`FREEZE=1` re-freezes from the run, 14z-121); both ids asserted from the trace. Run after any change to the extracts, the decoder, the victim rigs or a reaction-set remap |
| `tools/charpages_internal.sh` + `tests/lua/sprite_capture.lua` + `tools/sprite_render.py` | **manual (~15 min, 48 MAME legs)** | **THE INTERNAL CHARACTER PAGES WITH SPRITES (14z-121 (6)):** A. `field_trace` P1's node on every naming part; B. `tools/charpages_frames.py pick` (the first frame the node is an attack node of the move's chain, else the chain's first + probes to +120 f) and `choose` (a chain without an attack node renders at the first probe where an OWNED pool object — the foot, the sword, a projectile — carries a record with real power; the page draws that object's `hitbox_proj` box at the object); C. `sprite_capture.lua` at those frames (the OBJ list + the `$90C000` palette page); D. `sprite_render.py` — the tenant's entries = its records' within-bank tile set (`obj_records.walk`) in bank 3 (vs2's id-indexed OBJ bank table `0x27530`, `0x6000` for all three tenants), mid-screen (the HUD strips are bank 1 at the top and bottom), the LEFT x-cluster (the rigs pin P1 left of P2) → PNG per move from `vsav2.zip`'s tiles; E. `charmap_html.py --sprites` — the sprite and its boxes OUTLINED in one drawing (`KX=64, KY=262`, calibrated 14z-121 (7)). Output `../charpages/` — ABOVE the working tree (unaddable, uncommittable, unpushable from this repo), NOT published; step 0 of the script builds every prerequisite from the user's own dumps, so anyone owning the ROMs regenerates the pages. Not a gate: a currency check would be a re-run |
| `tests/test_killshread_es.sh` | **emulator (MAME, ~2 min)** | **KILLSHREAD (ES) (14z-121 (3)):** the maintainer's ruling measured — Donovan part 12 (plain plant → summon, ES plant → summon, LK and HK; Victor idle in the sword's path): contact lines frozen in `tests/expected/killshread_es.txt` (`FREEZE=1`), plus the structural shape: a plain summon = ONE contact wave, an ES summon = TWO (going away and coming back), the plant never connects. Run after any change to the rig or Donovan's stance/summon chains |
| `tests/test_projectile_params.sh` | **emulator (MAME, ~3 min; `NOLIVE=1` = the ROM-free half)** | **THE PROJECTILE PARAMETERS (14z-121, phase 3):** `tools/projectile_params.py` decodes every `$FF9400` type handler's inline init (walker-2 table `0x5C620[type]`; `+0x9A` → `+0x26/+0x50` and an `(xv, xacc, yv, yacc)` record; Cosmo = immediates) — rows frozen in `tests/expected/projectile_params.txt` (`FREEZE=1`); the same decoder on each build's `verify_op.bin` at the placed handler must equal vs2 (ours == vs2, three builds); the five census rigs' live spawns must match their rows (27 tabled spawns, one tick allowed; the seven tabled types each measured); a perturbed row must fail. Run after any change to the decoder, the rigs, or a projectile handler region |
| `tests/test_projectile_census.sh` | **emulator (MAME, ~2 min)** | **WHICH PROJECTILE-POOL TYPES EACH MOVE SPAWNS (14z-120 (11)):** the naming rigs' specials/meter parts with the 32 pool slots' type bytes sampled; `tools/projectile_census.py` lists per event the types that first appear after the input; frozen `tests/expected/projectile_census.txt`. Run after any change to the rigs or a tenant's projectile handlers |
| `tests/test_attract_roster.sh` | ci_static (~2 s, ROMDIR) | **THE ATTRACT-DEMO ROSTER (14z-118, the ram.md audit):** the assigner `PRG:0x005BEA` (demo counter `RAM:$FF1E2A`, `#$e` mask, x2) and its 8 x 4-byte table `PRG:0x005C08` — Jedah v Victor, Gallon v Bulleta, Q-Bee v Bishamon, Lilith v Zabel, Anakaris v Sasquatch, Demitri v Morrigan, Aulbath v Felicia, Lei-Lei v Anakaris, with venues — decoded from the opcode view and frozen; every base id once per column, none in the variant half, so a tenant never changes attract. Dynamic twin: 40,000 vanilla attract frames traced (`build/attract_roster_trace_14z118.log`), all eight in table order. One negative control (a tenant id planted in the table must fail) |
| `tests/test_mister_sdram_census.sh` | **manual/emulator (~45 min)** | **SLICE D2'S CORE EVIDENCE.** Downloads a `.rom` in the simulator, dumps all four 16 MB banks and checks every one of the 67,108,864 bytes against `mister_map.md` §5 with `tools/mister_sdram_census.py` (which replays the download mapping, CPS-2 GFX scramble included). FOUR legs: A cps2w+WIDE vs the WIDE map (THE census), B cps2+WIDE vs the STOCK map, C cps2w+stock vs the WIDE map, D cps2+stock vs the STOCK map (the calibration leg — the tool checked against a mapping nobody changed). Cross-checks independent of the tool: C vs D banks 1/2/3 BYTE-IDENTICAL and bank 0 differing; A vs B banks 2+3 DIFFERING (without the redirect group C aliases onto vanilla's art). Must-fire: leg B must FAIL the WIDE map, and A re-run with one expected constant moved 1 KiB must be rejected (twice, one per bank). `CENSUS_KEEP=<dir>` caches the bank images |
| `tests/test_mister_prg_probe.sh` | ci_portable (~3 s) | **SLICE D4/D5's ROM-FREE HALF.** Locks the 68k program-ROM read probe's contract without a ROM or a simulator: every code line the probe adds to `jtcps2_main.v` sits inside `` `ifdef JTCPS2W_PRGPROBE `` (with the hoisted-line control); its window bit IS the decode's window bit, both re-read from the RTL; its ADDRESS half carries no chip select, which is what lets it speak on the profile-CLEAR leg where `rom_cs` cannot assert at all. Then the verdict logic itself — `tools/prgprobe_verdict.py` (CLAUDE.md §4: a test's classification code is validated before its verdicts are trusted) — on synthetic logs whose answer is known by construction: **all three answers plus FOUR refusals** — a silent control, a control whose bytes do not verify, a probe whose HI records sit BELOW `$400000` (the defect the probe's first draft shipped with, frozen from the real numbers), and raw-right/latched-wrong, which the tool's first version scored as a PASS over ten fetches the CPU received as garbage. Also asserts the byte order is DERIVED from the control rather than hard-coded, and that `--prgprobe` refuses `--core cps2` |
| `tests/test_mister_prg_window.sh` | **manual/emulator (~2 x 40 min)** | **THE MEASURED PAIR, FROZEN.** Runs `11_pick_donovan` on `cps2w` with the WIDE romset twice, on `.rom` images that differ in ONE BYTE (header 41 `0xFE`/`0xFF`), and freezes the probe's own last per-frame report for each leg in `tests/expect/mister_prg_window.txt`. Structural assertions independent of the frozen numbers: `wide_en` really is 1 and 0; the must-fire count below `$400000` is in the tens of millions in BOTH legs; the CONTROL leg completes exactly ZERO reads above `$400000` (the decode is gated by construction); and both legs issue the same number of 68k bus READ cycles into the window. `--pos-log DIR --neg-log DIR` re-analyses finished runs; `--freeze` rewrites the expectation deliberately |
| `tests/test_mister_qsound_ext.sh` | **manual/emulator (~2 x 75 min)** | **THE QSOUND EXTENSION FETCHED ON THE CORE (14z-108) — the last major subsystem of the profile to get any coverage.** Stock CPS-2 cannot address banks `0x80-0x8E` at all (`qsnd_addr[22:16] <= dsp_ab[6:0]` keeps seven bank bits, so `0x8N` plays as `0x0N`); reaching them needs D1's width fix AND D2's QSound split. Counts SDRAM reads into the 1 MB QSound HIGH window while a tenant fights (`108_tenant_voice.rpl` — walk forward and mash, so attacks CONNECT), and requires the same image with the profile bit clear to issue NONE. **Measured: 210,180 reads / 76 distinct / first frame 3783, addresses `0x830AA0-0x83FFFE` = DSP bank `0x83`; control leg ZERO while still issuing 54,113,994 QSound LOW reads.** The window is DERIVED FROM THE RTL (`PCMH_OFFSET`, `SLOT5_AW`, and which `u_bankN` carries `pcmh_cs`), and the gate asserts `pcm_addr[22:20] == 0` — the condition that makes the `SLOT5_AW=20` truncation lossless (Quartus warning 10230). Proven able to FAIL on four fabricated defects: a leaking control, a zero positive, an out-of-range address, and a dead liveness probe. **Fetched is NOT heard — no audio has been rendered or compared** |
| `tests/test_mister_tenant_oracle.sh` | **manual/emulator (~65 min)** | **THE §4 DUAL-EMULATOR ORACLE ON TENANT CONTENT (14z-108) — the first evidence that a tenant FIGHTS CORRECTLY on the core, as opposed to having its art fetched.** MAME and `cps2w` run `36_pick_tenant_cell` on the same WIDE romset; the mapped fields of `fields_m2a.tsv` must agree at the round-1 match-start anchor and its follow offsets. This is the case CLAUDE.md §4 wrote the dual-emulator rule FOR — authored content, no vanilla oracle — and jtcps2w is a third implementation, so a bug would have to manifest identically in two unrelated codebases and in Jotego's RTL. **Frozen: MAME 2886 / sim 3546 / skew 660 ± 30**, and the skew is the 659-frame WIDE transfer PLUS ONE — the same +1 the legacy replay shows on a 462-frame transfer, so the boot-phase offset is a constant rather than a function of content. **Asserts P1's hitbox base is `0x003FA9D0` on BOTH legs** — the RELOCATED tenant record; a core that loaded a legacy character instead fails there, which is what 14z-107 (12) looked like. **`p2_hitbox_base` is excluded BY NAME** (the sound-fed CPU draw: MAME `0x000ABD74` vs core `0x0009769E`) and a control proves that exclusion is LIVE rather than vacuous. The must-fire control perturbs the TIMER, which is compared but is not an anchor input — a byte-swap control is weaker because it destroys the anchor and never exercises the field comparison at all |
| `tests/test_obj_records.sh` | **MAME only, ~2 min** | ground truth for `tools/oram_obj_records.py` — the byte-level OBJ-list walker reproduces `tests/lua/obj_records_dump.lua` BYTE FOR BYTE on the same ORAM bytes (1153/1153 lines at the frozen tenant anchor). Two must-fire controls: a one-bit tile-code change alters the records; an impossible page offset is REFUSED. CPS-2 ORAM is DOUBLE-BUFFERED with a runtime page select — the walker reports the terminator so live/idle pages are distinguished, never assumed. No fixture committed (ORAM is ROM-derived, rule 7) |
| `tests/test_mister_obj_oracle.sh` | **manual/emulator (~65 min; `--sim-dir/--mame-log` and `--select-sim-dir/--select-mame-log` re-analyse finished runs)** | **THE OBJ-LIST ORACLE (14z-109) — the first cross-implementation agreement on a video-determining surface.** VRAM was ruled out (implementations legitimately differ there); the OBJ list is what the 68k BUILDS. Match anchor: the PROMOTED (y-bit-12, group-C) subset — the port's own sprites — is 31 entries on BOTH legs, ORDERED AND FIELD-FOR-FIELD IDENTICAL, 19-bit addresses the same set (`0x4b0c4-0x4ecda`); the unpromoted remainder is the CPU-opponent LOTTERY and is reported, never asserted. Select screen (section 3, no opponent so no lottery): promoted subset exact on ALL 81 frames, whole list 55/81 with every shortfall in the unpromoted part, and the authored M6 mark (codes `fe40/fe41`, pal row 0x19) IDENTICAL across implementations. Must-fire: a one-bit promoted-code change turns 1c/1d red (verified end to end); 3z fails if the select list is CONSTANT |
| `tests/test_mister_gfxc_fetch.sh` | **manual/emulator (~2 x 65 min)** | **SLICE D3'S PAYOFF, and the first VIDEO-adjacent verdict in this lane.** Runs a tenant-picking replay (`11_pick_donovan`) on `cps2w` with the WIDE romset and counts the SDRAM READS the core issues into the group-C destinations, using the harness's read probe (`JTFRAME_SIM_RDPROBE`, fork commit 12). The windows are DERIVED FROM THE RTL (`GFXC4_OFFSET`/`GFXC5_OFFSET` and the bank each group-C slot sits in) because an instrument that names a physical address is invalidated by a memory-map change. The distinct-block list IS a tile-code list (a CPS-2 tile code is its own SDRAM address), and every code must be inside the roster's frozen live extent. **The control leg is the SAME `.rom` with header byte 41 changed from `0xFE` to `0xFF`** — one byte, the runtime profile bit — and must read ZERO from both group-C windows; two further probes on the VANILLA obj banks must be non-zero in BOTH legs, so a zero is evidence about the core rather than about the probe. `--pos-log DIR --neg-log DIR` re-analyses two finished run dirs. **STATE 14z-107 (12): the WHEEL half is GREEN** (obj bank 5, 105 distinct codes `0x74D6-0xFE41` inside the frozen extent `0xFFDB`, control at zero) **and the FIGHTER half — obj bank 4 — was RED for a HARNESS reason**: the tenant-picking replay's directions were REVERSED end for end, so the cursor never reached a tenant (fixed 14z-108 in `tools/rpl2siminputs.py`; the fighter half is re-run on the corrected input path). Its first real measurement also found TWO defects IN ITSELF, both fixed — the tile code computed from the ABSOLUTE SDRAM address instead of relative to the armed window's base, and a liveness control demanding vanilla obj traffic in a leg that cannot boot by construction |
| `tests/test_mister_sim_anchor.sh` | **manual/emulator (~50 min)** | THE ORACLE: MAME and the core under test (**`cps2w` since D1**, `SIM_CORE=cps2` for the reference leg) agree on every mapped §4 field at the round-1 match-start anchor of `05_timeout_idle` (MAME **2146** / sim **2609**, skew **463 ± 30** — RE-MEASURED 14z-107 (7) with host frame output OFF. It read 2502/356 and 2507/361 on runs whose input script the harness's frame writer was replaying, and 2606/460 before that, which was the BOOT offset rather than the anchor). Runs with `--frame-output off` and ASSERTS that mode from the run's own log banner; asserts BOTH dump sets are COMPLETE (`tools/check_wram_dumps.py`) and the sim window NON-CONSTANT before computing any anchor; then the byte-swap, hook-inertness and punched-hole controls |
