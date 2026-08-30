# STATE — living progress log

## Session 14z-120 (2026-08-30) — **THE MOVE LISTS AND THE NAMING STEP (phase 1 of the character-data
## map): the maintainer's three lists transcribed to `build/manifest/moves_{donovan,pyron,huitzil}.toml`;
## Donovan's 53 chain ids MEASURED on native vs2 by a new rig (`tools/name_moves.py`, eight legs) and
## frozen by `tests/test_move_naming.sh`; the SWORDLESS normal set found. No build changed. NOT pushed.**

| | |
|---|---|
| opened with | the 14z-119 close (`71192cc`, unpushed); the maintainer asked for the move-list format, then gave the three lists |
| the lists | `moves_donovan.toml` (54 rows), `moves_pyron.toml` (42), `moves_huitzil.toml` (50; display name Phobos). Conventions ruled by the maintainer and recorded in the Donovan header: ES = the special with two punches / two kicks, ANY pair; Dark Force = P+K same strength for everyone (listed for the name); guard cancel = 623P/K in blockstun for 1 stock (Ifrit / Zodiac Fire / Reflect Wall — the last GUARD-CANCEL-ONLY and, maintainer-corrected, WITHOUT an ES); Galaxy Trip six destinations, no ES; Phobos's six 6+button alternate attacks = six command normals; Air Dash / Float filed as movement. ES rows are SEPARATE rows because ES is separate content (STATE_HISTORY 14z-44: its own chain + its own attack records), re-confirmed below for every Donovan special |
| **the naming rig** | `tools/name_moves.py gen` lays a per-tenant schedule of input recipes (the cadences of rigs that already fired each move natively: 59 for 41236, 60 for 63214, 19 for 623, 48/56 for 421, 50 for 214, 27 for the throw) on replay 17's native-vs2 prologue; `tests/lua/field_trace.lua` samples P1's `obj+0x1C` per frame; `analyse`/`expect` map each pointer onto `tools/anim_nodes.py`'s graph and list the chains ENTERED per event ([VSE-47]: the chain is the measurement, never the input's name). Eight parts, ~30 s each headless, in parallel. Rigs committed under `tests/replays/naming/donovan_[1-8].{rpl,json}` |
| **measured (all in `donovan_anim.md`, labelled)** | table `a2` is the move table in input order: standing `0x00,02,04,06,08,0a`, crouching `0x0c-0x11`, jumping `0x12-0x17`; **SWORDLESS standing normals `0x1e-0x23` + crouching MP/HP `0x25/0x26`** (entered only with the sword planted; the other crouching + every jumping normal keep their chain; the sword specials and dive kicks are ABSENT swordless — the plain normal comes out); 6HK `0x27` (+ landing `0x63`); j.2LK/MK/HK `0x28/0x29/0x2a`; throw `0x2c` (4/6, MP/HP one chain); Ifrit `0x2d-0x2f` + ES `0x30`; Blizzard `0x31-0x33` + ES `0x34`; Lightning `0x35-0x37` + ES `0x38`, tail `0x39`; Press of Death `0x3a` (one chain, distance is a parameter); Change Immortal `0x3b -> 0x3c -> 0x3e -> 0x3f` (`0x3d` unreached); grapple `0x41`; Killshread LK `0x44` / MK,HK `0x43` / ES `0x46`; summon ground `0x47`, air `0x48`, NO ES (no stock spent); Lightning-in-stance `0x54-0x56` + ES `0x57`, tail `0x58`; dashes `0x49/0x4a` + end `0x4b`; pursuit `0x4c` (P = K), ES `0x4e`. Table `a`: idle `0x00`, walk `0x02/0x04`, crouch `0x09->0x01->0x06`, jump `0x0e->0x10->0x0f`. **Slay Shred has NO fighter chain**: idle re-entered, `$FF802E` up 25 f later, TWO stocks spent natively, 332 f long; normals inside DF unchanged |
| **positive controls** | Blizzard Sword HP entered vs2 `0x283E58` = the chain replay 59 recorded (14z-48); Lightning Sword ES entered `0x284A64` = replay 56's ES chain (14z-44); every ES/EX spent exactly one stock at its entry frame (`+0x109` sampled) |
| **paid for (project/gotchas.md)** | (1) `$FF8109` is a BINARY timer (99, one tick per ~82 f): a `0x99` "keep-alive" poke = 153 ENDED the round and every later event read UNFIRED; no poke needed, the generator asserts part length. (2) `63214` contains `214`: with the sword planted the grapple input is Killshread Lightning (`0x55/0x56`); the stance persisted a whole part (an air summon returned the sword, the next "summon back" re-planted it). (3) a facing flip inverts a button sequence's "4". Two refuted readings of `0x1e/0x21` on the way (close-range normals; DF-form normals), both by measurement |
| the gate | `tests/test_move_naming.sh` (emulator tier, ~2 min): rigs = regeneration; the eight legs; every event's entered-chain list == `tests/expected/move_naming_donovan.txt` (179 lines, identical on two independent runs); every `table:seq` in the TOML entered; negative control (a swapped line fails). Indexed in HANDOFF |
| docs | `engine_internals.md` "Donovan's anim-chain map" (under the walker section); `project/gotchas.md`; `charmap_md.py --anim` labels every named chain from the TOML ("Named chains: 59 of 101" on `a2`); `charmap_gen.py`'s "not decoded" row updated (the three maps regenerated, `test_charmap_current` green); HANDOFF gate row |
| open | Huitzil's and Pyron's naming rigs (the schedules are data in `name_moves.py`; recipes for Galaxy Trip's six destinations, the air throws, Float, the held EX inputs are new); Change Immortal's `0x3d` (the 2/8 control); the odd standing ids `0x01,03,05,07,09,0b` and `0x18-0x1d`, `0x24` (unentered — the maintainer may recognise them); whether to drop the `Killshread Summon (ES)` row (measured: no ES) |


## Session 14z-119 CLOSE — ritual complete. **THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 /
## pyron-m19 / merged-m14, mark M12, stock twin MOVED by design — strict 117/0/0/0 on the committed
## tree, guard corpus 344/344, roster 111/111, every masked legacy class green on three suites.
## Tagged at `5672291`. NOT field-tested, NOT pushed.**

| | |
|---|---|
| opened with | the 14z-118 close (`0c2f993`, pushed); "proceed with (A)" |
| delivered | the M12 battery end to end (the session entry above has every number), release `release/merged-m14/`, the MiSTer tail (fork `2bf41090`, patch 0028, pin, bundle `../mister_fieldtest_14z119/`), the re-point + N-2 sweeps, the docs |
| green at close | `run_all_static --strict` **PASS 117 / SKIP 0 / FAIL 0 / MISSING 0** on the committed tree `5672291` (the first run was 116/0/1: `test_phasec_spaces`' stock pin — the fourth carrier of the moved stock twin — re-pinned); suites donovan-m18 61/21, huitzil-m25 67/21, pyron-m19 68/19 with every masked legacy class PASS; `audit_merged_legacy` 47/47; `audit_guard_corpus` 344/344; `audit_roster_pairings` 111/111; `audit_legacy_pairings` PASS; the gate list in the session entry — all PASS |
| push | **NOT PUSHED** — main is ahead of origin by the freeze commit + this close; the fork `2bf41090` is local; tags `freeze/{donovan-m18,huitzil-m25,pyron-m19,merged-m14}` local. Push at the maintainer's word |
| not done, by absence | the board verdict on M12 (the bundle is on disk, the tell is "M12"; pick Donovan, walk, jump); phase 2 of the map; the move lists |
| next | the maintainer's pick — the board test, then (B) phase 2 or (C) the move lists (NEXT_SESSION). Load `vampire-saved-port` first |

**Ledger rollover:** the 14z-116 group (one record) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-117 / 14z-118 / 14z-119.


## Session 14z-119 (2026-08-29/30) — **THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 /
## pyron-m19 / merged-m14, mark M12 — the M12 battery NEXT_SESSION option (A), run end to end in one
## session. Donovan walks and jumps with VS2's values on every shipping track; the STOCK TWIN MOVED
## (by design, first time since 14z-110b); every masked legacy class PASS on three suites; the two
## RED-BY-DESIGN gates re-pinned. NOT yet field-tested (bundle 14z119). NOT pushed.**

| | |
|---|---|
| opened with | the 14z-118 close (`0c2f993`, pushed); the maintainer: "proceed with (A)" — the M12 battery |
| the builds | `version_text` M11 -> M12 in all three manifests (no other manifest change: `port_param32 = true` was already in). don_m18 **`7109f835`** (339 ops — PROGRAM IDENTICAL to the validated probe `build/don_phys_probe`; the mark is gfx-only), hui52 **`ae953657`** (370 — fingerprint UNCHANGED from huitzil-m24), pyron36 **`1222df18`** (307 — unchanged from pyron-m18), `build/m3b_merged21` **`6649523a`** (826 ops = 823 + exactly the three Donovan value ops at `0x0BD912/0x0BDF0A/0x0BE392`; NO address moved), `build/m5_stock13` **`38e9cb2c`** — **THE STOCK TWIN MOVED** (was `d29fd062` since 14z-110b). Members moved: PROGRAM `vm3j.04d` (solos/merged: the three rows; stock: six), GROUP C `vsw.33m/37m` (the M12 glyph); QSound/Z80 untouched |
| **why the stock twin moved, attributed** | `port_param32` is a per-row `data_port`, not profile-gated (the #103 class): on the substituted track Donovan IS slot `0x0F`, so gen writes his VS2 rows there too — six data ops, `param32_a[0xf]` value `0x0BD8F2` + `[0x1f]` mirror `0x0BD972`, `jump_params[0xf]` `0x0BDE4A` + mirror `0x0BE14A`, `param32_b[0xf]` `0x0BE372` + mirror `0x0BE3F2` (per-op diff stock12 vs stock13: ADDED these six, nothing changed or removed; member `vm3j.04d` only). No legacy row is written — per-char stride tables. The 14z-118 record said "legacy x3 bit-identical" about WIDE and did not predict this; `test_m3a_reproducible` never showed it because the gate exits at its FIRST mismatch (WIDE). Registry: `donovan-m18-stock`; the stage-4 image moves the same way (`donovan-m18-stage4` `108f7523`, a record row — no gate dispatches on it) |
| **the registry blind spot, handled** | huitzil/pyron programs did not change, so their dispatch fingerprints equal m24/m18's (the fingerprint covers program members only — `build_fingerprint.py` KNOWN BLIND SPOT; the glyph tiles are group C). `build_fingerprint.py` resolves FIRST match, so the m24 / pyron-m18 rows are COMMENTED OUT (kept as history) and huitzil-m25 / pyron-m19 rows added with the same sha; expectation sets carried m17->m18 / m24->m25 / m18->m19 / m13-stock->m18-stock |
| the merged build refused first | `build_merged.sh` reads `test_tenant_loop`'s frozen 3-tenant count (823) and refused 826 — the red-by-design gate doing its job. `test_tenant_loop` re-frozen FROM ITS OWN PRINT: donovan 336 -> **339**, 2-tenant 612 -> **615** (sum 668 -> 671), 3-tenant 823 -> **826** (sum 932 -> 935); huitzil 370 / pyron 307 unchanged; PASS, then the merged build |
| suites | three full verifies in parallel (~5 h under load): **every masked legacy class PASS** on all three (don 61 pass / 21 skip, hui 67 / 21, pyron 68 / 19). **huitzil-m25 and pyron-m19: ZERO moved `.sha1`s** — bit-identical to m24 / m18 (the control that the mark is inert and nothing else changed). **donovan-m18: six self-frozen tenant rigs moved** — `61_tenant_2pwin`, `103_tenant_2pwin_auto`, `108_tenant_voice`, `110_don_arcade_mash`, `112_don_pod_merged`, `113_shadow_vs_tenant` — every one a Donovan match; re-frozen with `SUITE_ONLY --freeze` and re-verified PASS |
| **the moved rigs ATTRIBUTED (the method: onset frame, not a sampled frame)** | don_m17 vs don_m18 on 103 and 108. Sampled frames first: 2500 IDENTICAL on both; 4000 = 8 bytes (103) / 793 bytes (108); 5600 = 11 — a DIFFERENT FIGHT, not a phase artifact. Then the checksum logs: 103 diverges at **f2980** and 108 at **f3068** (match live from ~2900 — the first movement) and never re-converge. DUMPS at onset−1 / onset on both builds: onset−1 IDENTICAL; at the onset **exactly 2 bytes differ, `$FF8441/$FF8442` = P1 `+0x40.l`, the X-VELOCITY word: `0x0280 -> 0x0300` = 2.5 -> 3.0** — the ported walk speed, byte-exact, on both replays. Nothing outside P1's fighter block. Evidence: `build/attr_14z119/onset_summary.txt`, `summary.txt` |
| audits | `audit_merged_legacy` **47/47** (leg (b) on the NEW solos, explicit `LEGB_*`) · `audit_guard_corpus` **344/344** clean on merged21 · `audit_roster_pairings` **111/111** (`bases.tsv` UNMOVED — no allocation shifted) · `audit_legacy_pairings` PASS on the three new sets |
| gates | dualtrack PASS (onsets held) · fbneo_legacy_oracle PASS with **NO refit** · fbneo_replay_determinism · inp corpus 6/6 · random_select_tenants (CONTROL merged19, kept) · version_string (M12 pixel-exact) · pyron_medallion_2p · shadow_tenant · oboro_select · wheel_bank5 / select_wheel / tenant_select_records · tenant_loop (re-frozen) · manifest_merge · tenant_row_owner · thunk_addr_literal · pcrel_escapes (inventories IDENTICAL) · escape_triage (25 verdicts identical, no landing moved) · **pointer_flow: all four baselines IDENTICAL to their predecessors** (renamed merged-m14 / donovan-m18 / huitzil-m25 / pyron-m19) · m3a (EXPECT_WIDE/STOCK/MERGED + five MANI_* re-pinned from a `REFREEZE=1` run; HUI/PYR unchanged) · tables_current + charmap_current + charmap_overrides (the three tables and six map pages regenerated — `donovan.json/md` now read the rows `byte`) · anim_node_walk re-pointed · checkdocs 16 locks · checkskills 425 · build_ref_rot 66 live / 0 rotted · jtcores_twin · mister_mra_map · mra_parts · release_roundtrip · portable 56/0/0/0. **Strict: see the CLOSE row** |
| release / MiSTer tail | `release/merged-m14/{fbneo,mame,mister}/` (M12; bitstream 18269 hash-verified, unchanged). Fork **`2bf41090`** (catalogue: THREE CRCs — `vm3j.04d`, `vsw.33m/37m`; `--check` clean), patch **0028**, `PINNED` + `PATCH_NAMES` bumped, twin PASS; the WIDE MRA differs from merged-m13's in exactly those three `<part>` lines (+ `asm_md5`); bundle **`../mister_fieldtest_14z119/`** (`vsavjw.zip` sha1 `3b34d35f…`; STOCK CONTROL MRA byte-identical to 14z-115/117/117b's; `.rbf` unchanged; README says what to try: pick Donovan, walk, jump). **THE TELL IS M12** |
| re-point sweep | 93 files / 141 lines (+ the five audits after they finished — `audit_merged_legacy`'s `LEGB_*` defaults had been MISSED by the 14z-117b sweep and still named the one-back solos); syntax-swept; `test_random_select_tenants` re-pointed BUILD only (CONTROL stays `m3b_merged19`, which therefore STAYS on disk). N-2 sweep: `don_m16`, `hui50`, `pyron34`, `m5_stock11` deleted (grep-four-places clean) |
| **paid for (two cuts of one trap, `project/gotchas.md`)** | the sweep stamp on TOML SECTION HEADER / KEY lines broke `test_pcrel_escapes`' hand-rolled parser (`KeyError: 'build'` after "inventory unchanged" x3); and the blind name replace REWROTE HISTORY in three comments ("RE-POINTED 14z-117b: … -> hui52…", "Re-scanned on don_m18", "m3b_merged18, 14z-115") — restored. Rules filed |
| docs | patch_notes 14z-119; patch_index (track rows, stock row, 14z-119 additions, patch 0028); HANDOFF (playtest block, current-builds header, four-track recipe, MiSTer examples, registry row); `mister_core` / `platform/mister` / `mister_scope` / `mister_field` / `hardening_register` / `build_dir_triage` ground truth; the three community tables + six map pages regenerated |
| **strict at close** | `run_all_static --strict` first run: **116 PASS / 0 SKIP / 1 FAIL** — `test_phasec_spaces`, whose stock-twin pin still said `d29fd062` (the FOURTH carrier of the moved stock twin, after m3a EXPECT_STOCK, the registry and the stock-track index row); re-pinned to `38e9cb2c` with the attribution, PASS standalone; a full strict re-run after the commit is recorded in the CLOSE row |
| open | the board verdict on M12 (bundle 14z119); phase 2 of the character-data map (hitbox rectangles + attack records by measurement); the move lists (phase 1 naming); the cosmetic backlog unchanged |

## Session 14z-118 CLOSE (3) — the session's close. **One day, four arcs: the M11 board verdict
## recorded; the documentation audit (16 commits) closed; the character-data map's phases 0 and 1
## shipped; Donovan's physics rows ported (UNFROZEN). Strict tier RED BY DESIGN on two gates until
## the M12 battery. Everything PUSHED at the maintainer's word, this close included.**

| | |
|---|---|
| the day, one breath | verdict `020a555` -> audit `2a6ebc3`..`a20d60b` (13) + `d383aaf`/`5a87ea2`/`b242a95` (3 more) -> charmap `45163bb` (phase 0), `5a6637b` (physics port), `2d9e845` + `9c103d5` (phase 1) -> this close |
| green at close | portable tier GREEN after every commit; `checkskills` 425 / `checkdocs` 16 locks; `test_charmap_current` + `test_charmap_overrides` + `test_anim_node_walk` PASS; **strict tier: 117 PASS, 2 RED BY DESIGN** — `test_m3a_reproducible` (tree reproduces the physics probe `7109f835`, not the frozen `90a225ce`) and `test_tenant_loop` (339/615/826 ops) until the M12 freeze re-pins them |
| unfrozen | Donovan's `port_param32 = true` (probe `build/don_phys_probe`, keep until the freeze; evidence logs `build/phys_probe_*.log`, `build/timeout_*`, `build/c*_tap_*.log`, `build/*census*.log`) |
| open for the maintainer | the move lists (phase 1 naming); which comes first next session — the M12 battery (~5 h; clears the red gates, ships the physics port, regenerates the three maps + tables) or phase 2 (hitbox rectangles + attack records by measurement); the cosmetic backlog unchanged |
| rollover | the 14z-115 group (two records) moved verbatim to STATE_HISTORY + two ledger lines; STATE holds 14z-116 / 14z-117 / 14z-118 |
| push | PUSHED (maintainer, 2026-08-29: "push, then close the session") |

## Session 14z-118 (charmap) — **THE CHARACTER-DATA MAP, PHASE 0 (maintainer's request the same
## day): every decoded per-tenant structure laid out ours-vs-VS2 with every difference attributed,
## the override channel the build consumes, two gates — and the first finding: DONOVAN'S PHYSICS
## ROWS ARE NOT PORTED (he walks and jumps with Victor's values).**

| | |
|---|---|
| the request | map all three tenants' character data, readable by agents and humans, ours vs VS2 with differences flagged, Vampire Hunter (VH, the earlier game — not vhunt2) as a designed-in hook, and "edit the machine file; the build consumes it" (ruled). Rule-7 posture ruled: decoded values are derived data, tracked under `docs/`. Move names: the maintainer supplies lists at the naming step |
| the record straightened first | the "Donovan 214+P" precedent the maintainer recalled is his **421+P Change Immortal** (14z-26/27/28/36: attack-record class bytes retyped by `[[region_fix]]` rows in the hitbox region) — exactly the layer the map's override channel compiles to |
| delivered | `tools/charmap_gen.py` (the map: bank rows with physics decoded 16.16, 20 dispatch rows, every region's byte diff ATTRIBUTED — placements, reconciliation twins for engine refs, 24-bit frame pointers, `[gfx_remap]` band + the build's `effect_map.json` shelf codes, region_fix/port_patch/table_fix/data_port fixes, effect-list pointers, overrides — sfx records, FSM state-node runs, sprite-list summary, a generated NOT-DECODED worklist); `tools/charmap_md.py` (the page); `tools/charmap_compile.py` (overrides -> `[[region_fix]]` rows inside a marked block of the tenant manifest; gen_donovan_patch.py untouched); `build/manifest/charmap_{donovan,huitzil,pyron}.toml` (empty, documented); `docs/project/tables/chars/<tenant>.{json,md}`; gates `test_charmap_current` (ci_static, 2 controls) and `test_charmap_overrides` (ci_portable, 3 controls) |
| attribution at close | bank fields UNATTRIBUTED 0/0/0; dispatch 0/0/0; data-region bytes unattributed 692 / 342 / 342 (all in `x2b7ef4`, the companion-effect tail — 24-bit frame pointers and tile words the effect pass rewrites; named in the worklist, frozen by the gate); code regions out of scope by design (relocated code is the reconciliation/pointer_flow gates' business) |
| **THE FINDING** | **Donovan's `param32_a/b` and `jump_params` rows are NOT ported** — gen's `VALUE_SKIP` applies unless `[[tenant]] port_param32 = true`, which Huitzil (14z-66) and Pyron carry and Donovan does not (the 14w-b crash guard, written when he sat on slot 0x0F: "Jedah speeds retained"). At id 0x13 the row aliases `0x03`, so **he walks at Victor's 2.5/−2.25 instead of VS2's 3.0/−2.625 and jumps with Victor's parameters (back xv −3.625 vs −4.25, yv 8.0 vs 7.875 …)**. A gameplay-feel decision — "Decisions pending" below |
| **THE PHYSICS PORT, same day (maintainer: "use VS2 parameters and not the shell character's")** | `port_param32 = true` for Donovan; probe `build/don_phys_probe` `7109f835`: exactly 17 bytes differ from don_m17, all in his three rows; the map reads them `byte`; legacy A/B ×3 bit-identical (run apart from the build); `audit_don_vs_cpu` / `audit_don_ko_writer` / `audit_don_lilith_ko` PASS, `audit_don_grab_pose` Donovan half PASS. **UNFROZEN — the next battery.** Instrument trap paid: `test_don_reactions` / `test_m2a_stage4_oracle` / `test_don_column` are STOCK gates (default `build/donovan6`); on a WIDE rompath they run pristine vsavj and fail identically on don_m17 — the control that exposed it |
| **STRICT TIER RED BY DESIGN until the M12 freeze** | after the physics port the tree reproduces the probe, not the frozen set: `test_m3a_reproducible` (WIDE fingerprint `7109f835` != donovan-m17 `90a225ce`) and `test_tenant_loop` (donovan 336 -> **339** ops, 2-tenant 612 -> 615, 3-tenant 823 -> 826 = exactly the three value-row ops) — the named state of STATE_HISTORY 14z-8x ("THE ONE RED, red BY DESIGN"); everything else in the strict tier green (117 gates). The battery re-pins both |
| **PHASE 1 SHIPPED THE SAME DAY: the anim node chains** | `tools/anim_nodes.py` walks the five index tables by the rules read off vs2's walker (`0x2713C`/`0x271C4`: table-relative offsets, +0x18 sequential, bit7 link, bit6 hold); **verified as an instrument** by `tests/test_anim_node_walk.sh` — Donovan on NATIVE vs2, 3,638/3,638 sampled node pointers on the decoded graph, 1,225 edge transitions + 32 jumps onto graph nodes, first countdown = dur (1,121) or dur−1 (137, set-and-decremented same frame), stride-0x17 control leaves 3,417 off-graph. The map gained `anim` (per-node vs2/ours diff, sprite/link pointers checked as relocations) and an appendix page `<tenant>_anim.md`; `engine_internals.md` carries the rules. Observation kept open: table a2's chains are entered MID-chain by node index |
| not done (the phases) | phase 1 REMAINDER: move naming (the maintainer's lists -> `moves_<tenant>.toml`) and derived frame data (needs phase 2's attack-word semantics); phase 2 hitbox rectangles + attack records (a measurement; settles the +0x17/+0x1D class-byte disagreement); phase 3 stun/projectile/auto tables. VH: nothing until a dump exists |
| push | phase 0 pushed (`45163bb`); the physics port commit local |

## Session 14z-118 CLOSE (2) — **the audit's second half, same day: eight more commits (9)-(16).
## The (a)-(e) list closed; the `0xAA` question closed (Sasquatch's — blocks are 4 ids per
## PLAYER SIDE); `+0x381` and `$FF8127` settled by their WRITERS. Sixteen audit commits in all.**

| | |
|---|---|
| (9) | `engine_internals` measurement pass: Anakaris's DF makes zero palette-seq calls; the `0xAA` inference retracted; full-roster DF census frozen |
| (10) | fourteen gotchas re-filed by their fact (13 project -> platform, the onset entry game -> project), anchors intact |
| (11) | `ram.md`: the attract roster decoded + traced + gated (`test_attract_roster`); `$FF8127`'s 14z-104 row wrong; side codes `$FF8105`/`$FF810C` found and frozen in `audit_tenant_timeout.sh` |
| (12) | `id_space.md` refreshed; the Oboro "entry path unlocated" hole closed in place |
| (13) | STOCK CONTROL cadence RULED (maintainer): keep, once per new `.rbf` |
| (14) | **the whole-corpus non-DF census (73 legs): `0xAA-0xAD` requested nowhere AND NOT FREE — Sasquatch's, by the routine table; THE FAMILY RULE `BASE + (side<<2) + phase`; `REPLAYS=all` mode + frozen corpus union; the (9) "candidate free" reasoning retracted (the census fallacy)** |
| (15) | `+0x381` = the PLAYER-SIDE index, set at init (`0x0058A4`/`0x0058AA`) — write-tapped |
| (16) | `$FF8127` = a per-frame comparator of the two fighters' object byte `+0x10` (writer `0x02228E`), not match state; the coincidence-freezing assertion I had added in (11) removed |
| the lesson of the second half | three of my own same-day readings were wrong and corrected by a later measurement in the same session ((9)'s "candidate free", (11)'s "P2-won polarity", (14)'s "costume index" before it became a claim) — a RAM byte is settled by its WRITER, a palette block by its ROUTINE ROW, never by an edge or an absence |
| green | `checkskills` 425 / `checkdocs` 16 locks / portable tier after every commit; `REPLAYS=all` audit PASS end to end; `audit_tenant_timeout` PASS on merged20 |
| open | what fighter-object byte `+0x10` is (only if it matters); the cosmetic backlog (maintainer's list, unscheduled) |
| push | (15) `d383aaf` and (16) `5a87ea2` local; everything before pushed |

## Session 14z-118 CLOSE — **THE DOCUMENTATION AUDIT, FIRST PASS: the docs locked to each
## other (`checkdocs`, 16 locks), the community tables GENERATED and GATED, the specimen family
## and `engine_internals`' citable sites corrected, seven HIST banners, HANDOFF re-pointed —
## eight audit commits, strict 114/0/0/0. NOT pushed (the verdict commit was).**

| | |
|---|---|
| opened with | the M11 board verdict recorded and pushed (`020a555`); the maintainer: proceed with the audit order, option (a) for `tables/` |
| delivered | inventory `docs/project/doc_audit_14z118.md` (43 docs + 6 skills, MEASURED/DERIVED/GUESSED per file) -> `tools/checkdocs.py` + `docs/doc_locks.tsv` + `tests/test_checkdocs.sh` (ci_portable; PRESENCE + NO-RIVAL per lock; 12 self-tests, 3 must-fire controls) -> `character_tables`/`id_space`/`select_screen` (Dark Gallon decoded+board-confirmed, `0x12` OWNS its palette rows — the gate existed, the claim never cited it) -> `engine_internals` (DF header cites `audit_df_framework.sh`; the M2b safety gate struck; the Anakaris inference names its measurement) -> `sprite_lists` dated, `ram.md` open measurements + `$FF8440`, README SHA-1s re-derived, `venue_assets` currency -> **`tools/tables_char_md.py` + `tests/test_tables_current.sh` (ci_static): `donovan.md` regenerated (its `param32_a` was stale), `huitzil.md`/`pyron.md` created, README rewritten** -> HANDOFF: three MiSTer commands, two gate comments and the four-track rebuild recipe re-pointed -> five HIST banners + two two-layer notes -> the light rows (`mister_core`, `mister_fit`, `quartus_brief`, `visual_smoke_tests`, `coverage_matrix` Shadow cell, `porting_code_regions`) |
| what the pass found, in one line | almost every GUESSED claim was settled by a CITATION to a gate that already existed and was never named at the claim — the docs measured more than they said; the real GUESSED residue is small and named (below) |
| the audit's own errors | three survey leads were misreadings of true claims (`select_screen` 128 vs 100/128; `patch_index` L237; the `mister.md` runtime estimates) — struck in the inventory, gotcha filed ("THE AUDIT'S OWN INVENTORY IS ONE HOP AWAY TOO"); `coverage_matrix`'s Shadow cell was a DOC misreading, corrected |
| green at close | `run_all_static --strict` **PASS 114 / 0 / 0 / 0** (113 + `test_tables_current`; `test_checkdocs` in the portable 55); `checkskills` ALL PASS (425 rules) after every commit; `checkdocs` PASS 16 locks / 40 sites |
| commits | `2a6ebc3` inventory · `9f8edef` (1) checkdocs · `87c6c66` (2) specimen family · `a58635c` (3) engine_internals · `55fdf8b` (4) atlas pages · `56a65d0` (5) tables + HANDOFF re-points · `a1f3d02` (7) HIST banners · `bdf3e16` (8) light rows · this close |
| NOT done, named | (a) ~~`engine_internals.md`'s measurement sites~~ **DONE later the same session (AUDIT (9)): Anakaris's `0xAA` inference MEASURED FALSE — DF on, zero palette-seq calls; full-roster census frozen; `0xAA` has no DF requester; the four "likely"s settled, the attract-palette note derived and bounded**; (b) ~~the 14 emulator-fact gotchas to re-file~~ **DONE (AUDIT (10)): 13 moved project -> platform with their anchors, the onset entry game -> project;** (c) ~~`ram.md`'s two open measurements~~ **DONE (AUDIT (11)): attract roster decoded + traced + gated; `$FF8127` was NOT P1-downs-won (polarity inverted, semantics open), the real side codes `$FF8105`/`$FF810C` found and frozen;** (d) ~~`id_space.md`'s tag refresh~~ **DONE (AUDIT (12));** (e) ~~the STOCK CONTROL once-per-`.rbf` recommendation~~ **RULED 2026-08-29: keep, once per new `.rbf` (AUDIT (13))** |
| push | NOT pushed — eight audit commits + this close local; push at the maintainer's word |
| next | the maintainer's read of the inventory and this pass; then (a)-(d) above in that order — (a) needs the emulator, budget it as a session |

## Session 14z-118 (2026-08-29) — **THE M11 BOARD VERDICT: GREEN. The random-select freeze
## (merged-m13, bundle 14z117b) behaves on silicon as on both emulators. Ruled item (1) of
## 14z-117 closed; item (2), the documentation audit, is the session's work — and this
## record is its first specimen.**

| | |
|---|---|
| opened with | the 14z-117 close (`ca132f3`, local); the maintainer: "My test results on MiSTer are all green: behavior identical to emulation." Scope confirmed on request: random select cycles all 18 + a tenant confirm loads; the M11 tell; general play no regression; the M10 medallion/sword trade re-observed. STOCK CONTROL not re-run (`.rbf` unchanged) |
| the verdict | **FIELD VERDICT GREEN (maintainer, MiSTer, 2026-08-29, 14z-118): "all green: behavior identical to emulation"** — random select cycles all 18 on "?" and confirming a tenant loads it; the M11 tell visible; no regression in play; the M10 sword/medallion trade re-observed (select screen only). STOCK CONTROL not re-run (`.rbf` 18269 unchanged — once-per-`.rbf`). |
| what it validates on silicon | both profile-gated site_thunks (`random_select_bound` `0x020C74`, `random_select_roster` `0x020C80`), the per-build `roster_subst` table, and the walker's two-path re-read — the same surface `tests/test_random_select_tenants.sh` measures on MAME; the jtcps2w core executing hole-b code the emulators had only ever run. Still a person at a CRT ([MSV-31]): no frame captured |
| **what the sweep found — the audit's first specimen** | recording the verdict under [VSP-13] (grep the claim, not the files) found the M9 and M10 verdicts had each been written into ONE row while their "pending" twins stayed alive: `HANDOFF` M10 registry row ended "Field test on the board pending" under its own "FIELD-VALIDATED" header; the M9 row said "NOT YET FIELD-TESTED" a day after the CRT verdict; four STATE headers/rows (14z-115 close, 14z-115, 14z-117 first close) still said not-tested/pending; `mister_field.md` §6's verdict list, §1's board column, `mister_core.md` §12 and `platform/mister.md` all stopped at 14z-113; `mister_scope.md` still "awaiting the board's answer" on bundle 14z112. All marked in place this session (before-grep `build/verdict_grep_before_14z118.txt`, 9 live hits; after: 0 outside HISTORY blocks). Gotcha filed: `project/gotchas.md` "A FIELD VERDICT LANDS IN ONE ROW" |
| push | `main` pushed at the maintainer's word (this commit + `ca132f3`); fork untouched, no tags |
| next | the documentation audit — inventory first (`docs/project/doc_audit_14z118.md`), one commit per document |

## Session 14z-117 CLOSE (3) — the session's last act. **The VS/VS2 data-architecture page
## CORRECTED from a row-by-row measurement after the maintainer read it; the next session is
## RULED: a full documentation audit — measured, consistent, nothing stale.**

| | |
|---|---|
| the correction | the maintainer read the character-bank grid and asked why Gallon/Aulbath/Sasquatch looked un-doubled. The grid was WRONG in two places and its legend conflated two things. Measured on both data images (hitbox base, dispatch, anim index, and the two palette pointer tables): vsavj — every variant row 0x10-0x1F is a byte-identical COPY of row−16 except `0x18` (Oboro); `0x12` (the Dark Talbain id) copies Gallon's rows and has its own row ONLY in the two palette tables (`0x38C198` / `0x38C218`). vsav2 — all 16 base rows keep their own data (Gallon, Aulbath, Sasquatch leave the WHEEL, not the bank), variant `0x10/0x11/0x13/0x18` own, `0x19` own in the hitbox table only. The atlas had all of this right (`character_tables.md`, `id_space.md`); the translation to the grid was the error. Republished; legend now says COPY, not alias; linked from `docs/README.md` |
| commits | `d2b2484` (push record) + this close; artifact v2 "bank grid corrected" |
| **NEXT SESSION, RULED BY THE MAINTAINER** | (1) ~~their board results on bundle 14z117b (M11)~~ DONE — GREEN, STATE 14z-118; (2) **a full pass on the documentation: every claim derived from a MEASUREMENT, not a guess; everything consistent; nothing stale** — the Sailor Moon S discipline. Shape it as the 14z-113/114 staleness passes were shaped (S1-S20, S-C1..): inventory the claims per document, mark each MEASURED (with the log/gate that measured it) / DERIVED / GUESSED, re-measure or retract the last class, grep every retraction across the repo ([VSP-13]), and commit per document. Today's grid error is the specimen: a claim that was right in the atlas and wrong one hop away |
| push | this close commit NOT pushed — push at the maintainer's word |

## Session 14z-117 CLOSE (2) — ritual complete. **THE RANDOM-SELECT FREEZE: donovan-m17 /
## huitzil-m24 / pyron-m18 / merged-m13, mark M11 — strict 112/0/0/0, guard corpus 344/344,
## roster 111/111, legacy pairings PASS, every masked legacy class green on three suites.
## FIELD-TESTED GREEN on the board 2026-08-29 (bundle `../mister_fieldtest_14z117b/`, STATE 14z-118), PUSHED.**

| | |
|---|---|
| opened with | merged-m12 (M10) pushed and on the board; "do the random-select includes the tenants then" |
| delivered | the feature (two thunks, `roster_subst`), its gate, the crash-and-fix on the way (STATE 14z-117 (2)), the Shadow rig re-timed, the whole battery again, release + MiSTer tail, docs; **plus the VS/VS2 data-architecture page** at the maintainer's request: `https://claude.ai/code/artifact/98d586db-1a69-49eb-b421-5085db07b707` (eleven figures from the atlas; no ROM bytes — the palette is authored) |
| green at close | `run_all_static --strict` **PASS 112 / SKIP 0 / FAIL 0 / MISSING 0**; suites donovan-m17 / huitzil-m24 / pyron-m18: 66 pass / 19 (18) skip, moved `.sha1`s = `113` ×3 (the re-timed rig, attributed) + `40_pick_pyron_cell` on pyron only (ONE byte, `$FF8440` = the "?" walker's cursor, zero bytes at match), re-frozen and re-verified; `audit_merged_legacy` 47/47; `audit_guard_corpus` 344/344; `audit_roster_pairings` 111/111 (`bases.tsv` re-derived: Phobos +0xC0, Pyron +0x30); `audit_legacy_pairings` PASS (50/10/7 · 52/8/7 · 52/9/7); m3a, dualtrack, fbneo_legacy_oracle (no refit), inp corpus 6/6, random_select_tenants, version_string (M11), medallion, shadow, oboro, wheel gates, pointer_flow, pcrel, escape_triage, tenant_loop, manifest_merge, MiSTer twin/mra_map/parts/page/fit, release_roundtrip — all PASS |
| push | **PUSHED** at the maintainer's word (2026-08-29, "push"): fork `f997cfe1` FIRST, then main `085db97` + tags `freeze/{donovan-m17,huitzil-m24,pyron-m18,merged-m13}` |
| not done, by absence | ~~the board verdict on M11~~ (GREEN 14z-118); the 1:1 wheel mockup; #112/#113 parked |
| next | ~~the board test of bundle 14z117b (tell: "M11"; park on "?" — all 18 cycle; confirm one)~~ DONE, GREEN (14z-118). Load `vampire-saved-port` first |

**Ledger rollover:** none this close — STATE holds 14z-115 / 14z-116 / 14z-117 (both freezes).


## Session 14z-117 (2) — **RANDOM SELECT INCLUDES THE TENANTS, maintainer-directed
## ("do the random-select includes the tenants then") and FROZEN the same day as
## donovan-m17 / huitzil-m24 / pyron-m18 / merged-m13, mark M11 — two sites, one table,
## after a bound-only first cut crashed the figure refresh.**

| | |
|---|---|
| opened with | merged-m12 (M10) pushed; the maintainer on the board with bundle 14z117; "do the random-select includes the tenants then" |
| the mechanism, re-read | the 14z-116 record was right about the draw (fixed 15-entry table at `PRG:0x020C88`, bound `cmpi.b #$f`, cursor `$40(a6)`) and WRONG BY OMISSION about the walker: the 3-frame timer's NON-tick frames branch to `020C7C` and re-read the table with the unchanged cursor, so `$382` is rewritten every frame from two paths. `select_screen.md` "THE WALKER HAS TWO PATHS", `game/gotchas.md` |
| the fix | `[[site_thunk]]` x2 in all three manifests, profile-gated, ENGINE-SITE emitted once: `random_select_bound` at `0x020C74` (`cmpi.b #NN,d0 / bcs / moveq #0 / jmp 020C7C`, `jmp_ok`) and `random_select_roster` at `0x020C80` (`move.b tbl(pc,d0.w),$382(a6) / rts` + the 18-entry table, hole b, `rts_ok`). NEW generator feature **`roster_subst = "ids_ph:count_ph:base"`** fills the table tail with the BUILD'S OWN variant-half tenant ids (ascending) and the bound with base+count — a literal list is wrong on two of the three builds (the TT trap at roster level). Byte detail: patch_notes 14z-117 (2) |
| the first cut, and what it cost | one site (the bound) with a body that finished the routine. Solo PASS; MERGED: address error `vec3` at `PC 0x01C3B0`, `A0 0x02220FF5`, two frames after the first tenant showed. Attribution took a probe on the copy helper (no hit — wrong entry), an instruction trace (`GUARD_TRACE`, entry `05F9E4 jmp 1c3a4` from the figure refresh at `0x05FFF6`), then a `GUARD_PROBE` at `05F9C8` printing a0 per refresh: `0x46db00` (0x10) / `0x38c2a0` (0x00!) / `0x4bfbe0` (0x11) / `0x02220FF5` — and consecutive-frame DUMPS of `$382`: `06 → 10 → 00 → 11 → 4A…`. The `00` and `4A` are vanilla's pad byte and a CODE byte read by the non-tick path with cursor 15/16. Not a consumer problem: the 32-row accent table `0x38C198` already carries the tenants' rows |
| measured | draw cadence exactly 3 frames per id in table order (`… 09 06 10 11 13 04 …`); **confirm semantics are vanilla's** — what is showing is what you get (merged19: `0x04` showing -> P1 `0x04`; the thunked build: `0x10` -> P1 `0x10`, record base Phobos' own `0x45a770`); the replay harness stages inputs one frame ahead, so a press on a plateau's FIRST frame registers on the previous id (the gate presses mid-plateau). Legacy cost: nine select replays (04/63/03/09/11/38/05/08/36) **BIT-IDENTICAL** don_m16 vs the probe, twice (both cuts) — no legacy replay hovers "?". Stock twin `d29fd062`, whole-artifact manifest identical |
| gate | `tests/test_random_select_tenants.sh` (HANDOFF-indexed, emulator tier): static shape of both bodies; P1 parks on "?" (D,D,DR) and `$382` is sampled 91 frames = exactly 15 + this build's tenants; confirm on a tenant's middle frame loads that tenant's own record at frame 4300; must-fire control = the previous merged (`CONTROL=build/m3b_merged19`, no tenant drawn). PASS on the solo probe, the merged probe, and merged20 |
| THE FREEZE | `version_text` M10 -> M11. don_m17 `90a225ce` (336 ops), hui51 `ae953657` (370), pyron35 `1222df18` (307), `build/m3b_merged20` `a1b7cb82` (823 ops), `build/m5_stock12` = `d29fd062` UNCHANGED. Members moved: solos `vm3j.03d` (sites) + `vm3j.10b` (bodies) + `vsw.33m/37m` (M11 glyphs), don also `vsw.41`; merged additionally `vm3j.04d/07b` + `vsw.41/42` — the two hole-b bodies are allocated per tenant iteration ahead of the ext placements: **Phobos +0xC0, Pyron +0x30** (`bases.tsv` re-derived; escape-triage's three merged landings shifted, verdicts identical; pointer_flow merged's two STRONG win_pal bases +0x30, solos identical). Registry +3, expectation sets carried m16->m17 / m23->m24 / m17->m18. `test_tenant_loop` re-frozen 336/370/307, 612/668, 823/932; `test_manifest_merge` (22,17,9)/33/8 |
| gates at freeze | random_select_tenants · version_string (M11) · pyron_medallion_2p · shadow_tenant · oboro · wheel_bank5 / select_wheel / tenant_select_records · dualtrack · fbneo_legacy_oracle (no refit) · inp corpus 6/6 · pointer_flow · pcrel · escape_triage · tenant_loop · manifest_merge · jtcores_twin · mister_mra_map · mra_parts · mister_page + map_fit (census unchanged: still three glyph tiles) · release_roundtrip (merged-m13) — all PASS; portable 54/0/0/0. **The long legs — three suites, merged_legacy, guard corpus, m3a, roster + legacy pairings, strict — are in the CLOSE row** |
| release / MiSTer tail | `release/merged-m13/{fbneo,mame,mister}/` (M11; bitstream 18269 unchanged). Fork **`f997cfe1`** (catalogue: eight CRCs; the first splice dropped the newline after `</machine>` and was amended in place), patch **0027**, pin bumped, twin PASS; bundle **`../mister_fieldtest_14z117b/`** (STOCK CONTROL MRA byte-identical to 14z-115's, `.rbf` unchanged). **THE TELL IS M11** |
| the Shadow rig re-timed | `113_shadow_vs_tenant` moved on all three sets; DUMPS attribution (don_m16 vs don_m17): at 3000 P1 was `0x00`/Bulleta vs **`0x13`/Donovan** — the old confirm (1450) now lands on the solo's own tenant (a MIRROR match) and the "Shadow took the tenant" verdict at 7800 went vacuous (P1 already the tenant). Measured the drawn-id stream on all four builds: the solo cycle (period 48) and merged's (54) coincide at `1499+3k`; frames 1520-1522 show Bulleta on all four, so the confirm moved to 1521-1522 (registers one frame early). Verified: P1 `0x00` at 3000, morph to `0x13`/Donovan's record at 7800 on don_m17 AND merged20, fight lines unshifted; `test_shadow_tenant` PASS on merged20 with the re-timed replay; the three sets' `113` `.sha1` re-frozen. The N-1 sets (m16/m23/m17) keep their old `113.sha1`, now stale by construction — they are history, not run |
| re-point sweep | 90 files, continuation-safe this time (the 14z-117 gotcha applied: no stamp after a trailing `\`); `pcrel_escapes.toml` sections; `test_random_select_tenants.sh` EXCLUDED on purpose (its CONTROL must stay the previous merged) |
| open | ~~the board verdict on M11 (bundle 14z117b)~~ GREEN 14z-118; the maintainer's 1:1 wheel mockup; #112/#113 parked; the FBNeo two-run-family question |

## Session 14z-117 CLOSE — ritual complete. **THE PYRON-MEDALLION FREEZE: donovan-m16 /
## huitzil-m23 / pyron-m17 / merged-m12, mark M10, stock twin unchanged — strict 112/0/0/0,
## guard corpus 344/344, roster 111/111, every masked legacy class green on three suites.
## Field-tested GREEN on the board 2026-08-29 (bundle `../mister_fieldtest_14z117/`; the sword trade validated — Open bugs row; header marked 14z-118), PUSHED.**

| | |
|---|---|
| opened with | the 14z-116 close (`d9bed17`, pushed); NEXT_SESSION: the freeze battery, whole session, fresh |
| delivered | the battery end to end in the 14z-115 order — see the session entry below for every number; the release `release/merged-m12/`; the MiSTer tail (fork `80e08111`, patch 0026, pin, bundle); the re-point + N-2 sweeps; the docs |
| green at close | `run_all_static --strict` **PASS 112 / SKIP 0 / FAIL 0 / MISSING 0** (111 + `test_win_quote_decode`); suites donovan-m16 / huitzil-m23 / pyron-m17 full verify: every masked legacy replay PASS, the self-frozen tenant/select rigs re-frozen after attribution and re-verified; `audit_merged_legacy` 47/47; `audit_guard_corpus` 344/344; `audit_roster_pairings` 111/111; `audit_legacy_pairings` PASS; dualtrack, m3a, fbneo_legacy_oracle (no refit), inp corpus 6/6, pointer_flow, pcrel, escape_triage, version_string, pyron_medallion_2p, shadow_tenant, oboro, wheel gates, jtcores_twin, mister_mra_map, mra_parts, mister_page, mister_map_fit, release_roundtrip — all PASS |
| push | **PUSHED** at the maintainer's word (2026-08-29, "I'll do the MiSTer testing, you can already push"): fork `80e08111` pushed FIRST (`origin/vampire-saved`), then main `d27d45a` + tags `freeze/{donovan-m16,huitzil-m23,pyron-m17,merged-m12}` |
| not done, by absence | ~~the board verdict on M10~~ (GREEN 2026-08-29, marked 14z-118); the maintainer's 1:1 wheel mockup; random select "include the tenants" (shape recorded 14z-116, unscheduled) |
| next | the board test of `../mister_fieldtest_14z117/` (tell: "M10"); then whatever the maintainer brings. Load `vampire-saved-port` first |

**Ledger rollover:** the 14z-114 group (two records) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-115 / 14z-116 / 14z-117.


## Session 14z-117 (2026-08-29) — **THE PYRON-MEDALLION FREEZE: donovan-m16 / huitzil-m23 /
## pyron-m17 / merged-m12, mark M10, stock twin unchanged — the whole battery in one session,
## as NEXT_SESSION asked; the change was ten in-place bytes + one glyph and NO ADDRESS MOVED.**

| | |
|---|---|
| opened with | the 14z-116 close (`d9bed17`, pushed); NEXT_SESSION: "the work is the freeze battery, the whole session, fresh"; `build/m3b_merged19` (`af21bc88`, M9) field-validated and unfrozen |
| the builds | `version_text` M9 -> M10 in all three manifests; **`version_x` 340 -> 324** — a third glyph at x=340 puts the "0"'s last ink column at pixel 384, off the 384-wide screen (glyph ink box = 10 px centred in the 16 px cell). don_m16 `7950c844` (332 ops), hui50 `7ade3180` (366), pyron34 `01b39c39` (303), `build/m3b_merged19` rebuilt with the mark = `cde712e1` (819 ops), `build/m5_stock11` = `d29fd062` **UNCHANGED** (whole-artifact manifest identical, 30 members). Per-op diff vs the 14z-115 builds: exactly THREE ops changed CONTENT (coord list +1 pair at `0x413c70`, record count `0x19 -> 0x1A` at `0x413ce0`, the thunk body at `0x41a120`) and **no op moved** — the +4 coord bytes sat in alignment slack |
| members moved | solos `vsw.31m/33m/35m/37m` (the third glyph tile, `GFX:tile 0x1FE42`) + `vsw.41`; merged also `vm3j.10b` (its thunk copy lives in hole b, the 14z-116 write-tap PCs `0x3FFC60`-); QSound/Z80 untouched. m3a re-pinned per member; the six CRCs are the whole MiSTer catalogue delta |
| suites | three full verifies (~3 h each, parallel): **every masked legacy class PASS** (53/52/52 pass, 19/19/18 skip). Moved `.sha1`s = the 14z-115 inventory exactly (103/108/109/110/112, 36/37/44/58/61/62/64/92 + each set's pick-cell replay) plus `113_shadow_vs_tenant`, which had NO expectation since 14z-116 — self-frozen now. Attribution by DUMPS diff (don_m15 vs don_m16): replay 103 at 890 `$FF06CD/D0/D1` (OBJ-builder execution position — one more list entry per select frame), 1200/2412 `$FF06D1` + dead stack, **5800 ZERO bytes**; replay 92 (P2 hover walk, the path the fix changes) `$FF06D1` + dead stack only at 1100/1400/1700/2100 — the fix's own effect is palette RAM (`$90C340`), which `test_pyron_medallion_2p` checks, not work RAM. Re-frozen with `SUITE_ONLY --freeze`, then a filtered verify of the frozen names: all PASS |
| audits | `audit_merged_legacy` **47/47** leg (a), leg (b) on the new solos; `audit_guard_corpus` **344/344** clean; `audit_roster_pairings` **111/111** after `bases.tsv` re-derived from merged19's `PRG:0x0BD97A` (no row moved — recorded in the file); `audit_legacy_pairings` PASS; `test_dualtrack` PASS (onsets held); `test_fbneo_legacy_oracle` PASS with NO refit (the 14z-115 instants stayed clean); inp corpus 6/6; m3a PASS end to end |
| frozen expectations that moved, attributed | `test_pointer_flow`: WEAK `data:long` **+1** on every build (the one new 4-byte coord pair reads as one more WIDE-hole window), STRONG unchanged — new baselines merged-m12 / donovan-m16 / huitzil-m23 / pyron-m17. `audit_mister_map_fit` + `mk_mister_page`: bank-5 non-blank 6,271 -> **6,272**, extent `0xFE41 -> 0xFE42`, bucket 63 2 -> 3 (the third glyph); the ASCII figure unchanged (128 B is invisible at that scale). Escape triage: 25 verdicts IDENTICAL; pcrel inventories IDENTICAL |
| release / MiSTer tail | `release/merged-m12/{fbneo,mame,mister}/` (M10; round-trip PASS; bitstream 18269 hash-verified, unchanged). Fork commit **`80e08111`** (catalogue: `vm3j.10b`, `vsw.41`, `vsw.31m/33m/35m/37m`), patch **0026**, pin bumped, `test_jtcores_twin` PASS, `test_mister_mra_map` PASS; bundle **`../mister_fieldtest_14z117/`** (`_Arcade/` WIDE MRA regenerated + STOCK CONTROL MRA byte-identical to 14z-115's, `games/mame/` zips, README). **THE TELL IS M10.** Fork NOT pushed |
| re-point sweep | 85 files + `pcrel_escapes.toml` sections + `audit_merged_legacy.sh` after it finished; `bases.tsv` re-derived; three stale LABEL strings the 14z-115 sweep left (`don_m14`-style `chk` labels) re-labelled. N-2 sweep under the policy: `don_m14`, `hui48`, `pyron32`, `m3b_merged17`, `m5_stock9` deleted (no live reference, grep-four-places) |
| paid for | the sweep appended its stamp to four lines ending in `\` (shell continuations): `test_escape_triage` died loudly, **`test_pointer_flow` PASSED with a truncated `for` list** — fixed, syntax-swept every re-pointed script, filed in `project/gotchas.md` |
| docs | patch_notes 14z-117, patch_index (track rows, twin, 14z-116 row -> FROZEN, patch 0026), HANDOFF (playtest block, header, registry row), hardening_register, build_dir_triage, mister_core / mister_map / mister_scope / platform/mister / mister_field ground truth, engine_internals (version string position), STATE rollover (14z-114 group -> STATE_HISTORY + ledger) |
| open | field test of M10 on the board (the bundle); the maintainer's 1:1 wheel mockup; #112/#113 parked; the FBNeo two-run-family question unchanged |

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
  A reference to `STATE "Decisions pending"` for an entry no longer here
  resolves in `DECISIONS_HISTORY.md` (entries move there verbatim once
  ruled and no longer shaping work — 14z-109 cleanup).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to STATE_HISTORY; entries within them are marked DECIDED/FIXED
  in place, as always. **DECISIONS have their own archive since 14z-109:
  once a ruled decision stops shaping active work, its entry moves
  VERBATIM to `DECISIONS_HISTORY.md`** (grep there by topic; the §5
  retraction grep covers it).

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

- Session 14z-116 CLOSE — THE COSMETIC/EXTRAS ARC: win quotes MEASURED THEN FORGONE, the hidden characters DECODED (Shadow takes the tenant — confirmed on the board), and PYRON'S MEDALLION WHITE-OUT FIXED after two years parked; 13 commits pushed; nothing frozen (the freeze battery = 14z-117). The close ritual audited: patch_notes/patch_index/HANDOFF/gotchas had been skipped on the first pass and were written.
- Session 14z-115 CLOSE — THE SELECT-WHEEL SEPARATION FROZEN (donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged), tagged at `b30611a`, strict 111/0/0/0, guard corpus 340/340; emulation verdict "no regression", the maintainer's own mockup the next cut (moved to STATE_HISTORY 14z-118)
- Session 14z-115 — THE SELECT-WHEEL SEPARATION ("E2"): the three tenant medallions repositioned by the maintainer's pixel offsets, hover rings tuned by eye, a 1 px black outline authored per cell; the OPEN FBNeo two-run-family instrument question first recorded (moved to STATE_HISTORY 14z-118)
- Session 14z-114 CLOSE — ALL SIX SKILLS DISTILLED AND LOCKED TO THE DOCS in one session (the MiSTer pair, the CPS-2 pair, the game skill and the port skill — 425 rules, every one anchored in the paragraph it distils, every number in a log; four staleness passes run first, each its own commit) (moved to STATE_HISTORY 14z-117)
- Session 14z-114 — the MiSTer SKILLS distilled with their checker: two skill packages (level 1 `[MSC-1..73]`, level 2 `[MSV-1..36]`), every rule ID-anchored in the doc paragraph it distils; the log gained the 14z-108/109 measurements it never had; the field test got an in-tree carrier (moved to STATE_HISTORY 14z-117)
- Session 14z-113 CLOSE — the MiSTer SCOPE DOCUMENT written and its three decisions ruled; the S1-S20 staleness pass run; bundle 14z112 field-verified; merged-m10 FROZEN; the RELEASE FORMAT ruled and shipped (one self-sufficient directory per platform) (moved to STATE_HISTORY 14z-116)
- Session 14z-113 — `docs/project/mister_scope.md` written (scope only, not the skills): the two-level split, the doc dependency map, and the known-stale inventory S1-S20 (moved to STATE_HISTORY 14z-116)
- Session 14z-112 CLOSE — #99 CLOSED on a green field verdict (the board on bundle 14z111 / merged-m9 M8 does not crash on Bishamon > Phobos; MAME agrees on four hand-played recordings, all guard-clean, tracked as `play-merged-m9-01`, `run-merged-m9-02..05`); #112 (Press-of-Death palette) reproduced, ruled COSMETIC and parked; #113 measured VANILLA on emulator (the one-frame white-out at a down); the WIDE profile stopped breaking stock Vampire Savior — a WIDE set is ONE zip, the four patched group-A members inside `vsavjw.zip`, the parent pristine (`build/m3b_merged17`; frozen as merged-m10 at 14z-113) (moved to STATE_HISTORY 14z-115)
- Session 14z-112 — FIELD VERDICT GREEN on merged-m9 (M8): #99 CLOSED by the maintainer; the four recordings tracked; #113 re-read as a sprite-dropout frame; playback length now MEASURED (a recording ends where the human stopped; `test_inp_corpus` plays to MAX_FRAMES=6000 by default) (moved to STATE_HISTORY 14z-115)
- Session 14z-111 CLOSE — #99 ROOT-CAUSED (CPU-Phobos ran DEMITRI's AI: the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + the same 16 repeated, so tenant classes read the aliased row) AND FIXED by option A (the tenants' own vs2 AI script blocks as data roots, zero code); frozen donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9, mark M8; board bundle 14z111 ready; FIELD REPORTS ARE RECORDINGS promoted to CLAUDE.md §4 law with `tests/test_inp_corpus.sh` (moved to STATE_HISTORY 14z-114)
- Session 14z-111 — OPENED WITH A CLOSE-RITUAL AUDIT of 14z-110b (clean but unchecked): the three in-flight validations re-run and accepted; then the field verdict RED on merged-m8 (the board STILL crashes on Bishamon > Phobos, MAME by hand too) -> the maintainer's hand-played `.inp` captured under the new `tools/run_inp_guarded.sh` found the real mechanism the two poke-derived fixes never touched (moved to STATE_HISTORY 14z-114)
- Session 14z-110b CLOSE — the 0x51->0x44 remap BUILT, FROZEN (donovan-m13 / merged-m8, M7 mark carried) and MAME-VALIDATED; the board bundle carries merged-m8; the FBNeo partial oracle's reduced refit RULED and in progress; closed at the maintainer's call (context ceiling) with three validations in flight — re-run and accepted at the 14z-111 opening audit
- Session 14z-110b addendum — THE FBNEO ORACLE RED ROOT-CAUSED TO THE RULED d2-WINDOW CYCLES (110), NOT THE REMAP (110b): m12 == m13 RAM at the failing frame; the hunt cost a paid-for instrument trap; resolution = per-replay measured-clean frame overrides, 26_don_arcade_mash dropped for 05_timeout_idle (maintainer-ruled)
- Session 14z-110b — THE RESIDUAL #99 ROOT-CAUSED AND THE REMAP RULED-BY-CONDITION: the STORED state 0x51 over-runs a SECOND 80-vs-84 dispatcher (PRG:0x2384E) the 14z-43 audit also missed; fix = 0x51 -> 0x44 on the six deity nodes + one ported immediate, measured equivalent at every consumer both engines have. (Field: STILL CRASHED — the real #99 was the AI script-table alias, found 14z-111 from the maintainer's recording.)
- Session 14z-110 (4) — CLOSE. THE RULED ORDER IS COMPLETE: FIX -> AUDIT -> RE-FREEZE. The #99 d2-window fix built, audited and frozen (donovan-m12 / merged-m7, mark M7), with the MiSTer CRC tail and a field bundle. Its verdict came later and was RED: the crash survived, and 14z-111 root-caused the real mechanism.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-109 (4) — THE #99 CRASH INVESTIGATED ON EMULATOR after the FIELD TEST PASSED on a real DE10-Nano (tenants selectable, playable, voices heard, feel better than emulator) with one 100%-reproducible crash. Root-caused the same day to vs2 type byte 0x51 in Donovan's ported block — a conclusion 14z-111 later RETRACTED as poke-contaminated. Also: the OBJ-list oracle, the DECISIONS_HISTORY split.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-108 CLOSE — ritual complete. THE FUNCTIONAL CHAIN IS COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT RELIABLY CLOSE TIMING. A tenant FIGHTS on the core and fights CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under load is GO; scroll is structurally cleared; the CPS-2 video registers are documented for the first time. AND THE SESSION'S OWN HEADLINE IS THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER THE SAME DAY — three of them mine. 22 commits, ALL LOCAL.  [rolled 14z-111 close]
- Session 14z-108 — THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END, NOT TRANSPOSED IN TWO — measured on all four before one bit was changed, and the half nobody had exercised is where the previous reading was wrong. `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no RTL), verified against the game's own input mirror on both implementations, and the gate rebuilt with a per-direction lock and a must-fire control. One of the two frozen expectations the record said would move DID NOT MOVE AND COULD NOT — which also means the frozen sim anchor could not move. AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4 — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS FOUGHT ON THE CORE. Bank 1 under load answered from the same run and it is GO. Still never: HARDWARE — and no Quartus synthesis has ever been run, so resource fit and timing closure are unknown. That is now the largest gap in the arc.  [rolled 14z-111 close]
- Session 14z-107 CLOSE (final) — THE WIDE ROMSET BOOTS ON THE CORE, draws our select screen and fetches our wheel art: six RTL slices D0-D5 (the MRA, the runtime profile gate + QSound width, the SDRAM placement, the CPS-2 Turbo object promote, the 6 MB program window, and D5 THE DECRYPTION RANGE — the CPS-2 key's encrypted-opcode range word is stored COMPLEMENTED and jtcps2_dec_ctrl reads it straight, which no stock CPS-2 game could ever expose); 105 distinct tenant tile codes out of obj bank 5 with the control leg at zero; bank 0's traffic under the redirect ANSWERED and GO; both stock legs green. **The arc's headline was methodological: SEVEN instrument and harness defects found in this lane, every one of which would have read as an RTL fault, with D5 the counter-example where the RTL genuinely was at fault.**  [+3 more entries]  [rolled 14z-108 close]
- Session 14z-106 CLOSE — ritual complete: HOUSEKEEPING executed (the 14z-105 evidence logs + the guard-corpus TSV committed, the rehearsal probes attic'd, `../build_attic_14z102` 8.1 GB deleted under the standing policy, `emu/fbneo`'s modified content verified as patches 0001+0002) and THE MiSTer ARC OPENED with no RTL touched — the framing RULED (an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA re-implementation of MAME) and all five alignment questions answered the same day (separate core, GPL-3.0 fork, measure-then-choose profile, sim = gate / hardware = field test, MRA+RBF with a stock-vsavj reference leg); LICENSE = GPL-3.0; slice A landed the public fork `DefinitelyFrenchName/jtcores@vampire-saved` with the separate core `cores/cps2w` -> `jtcps2w.rbf`, pinned as submodule `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`, and the twin proof MEASURED (the vsavj MRA byte-identical to stock cps2's except `<rbf>`); slice B measured the fit (`mister_fit.md`: PRG 4.82 MB, QSound banks 0x80-0x8E all aliasing, GFX 52,347 roster codes / 6.39 MB against 4,028 blank tiles / 0.49 MB in ALL of vanilla's 32 MB — a wider GFX tier REQUIRED) and slice C proved THE VERILATOR SIMULATION LANE ON macOS (stock jtcps2 running vsavj, ~1.4 s/frame, the full recipe in `docs/platform/mister.md`, the `.rpl` -> `sim_inputs.hex` translator gated)  [+3 more entries]  [rolled 14z-107 close (final)]
- Session 14z-105 CLOSE (final) — THE MAINTAINER-DIRECTED WINDOW EXECUTED END TO END and field-confirmed: W1 the OBORO SELECT HOOK (cursor on Bishamon + hold START -> vanilla vsavj's Oboro, id 0x18, P1 and P2, vanilla's own Gallon-variant idiom one cell over) and W2 the VERSION STRING ("M6" at the select screen, the naked-eye A/B tell CLAUDE.md §5 had wanted since 14z-92, authored glyphs pixel-exact) — frozen as donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 with the stock twin m5_stock6 = `883e7d17` BIT-IDENTICAL, every gate and both soaks green, pushed 2026-08-22; the GFX TILE CODEC was found MIRRORED on the way (plane bit i draws at pixel 7-i; 14 sessions old, nothing had ever read pixel ORDER until the first authored tile) and the 14z-104 prediction that more sprites would move the select-window specs DIED by measurement over all 148 specs; RELEASE PACKAGING landed (`release/merged-m6/`, xdelta3 against the reference dumps, no ROM byte in the package) and was ruled IN-TREE until MiSTer  [+3 more entries]  [rolled 14z-107 close]
- Session 14z-104 CLOSE — THE §4 COVERAGE DEBT TACKLED end to end (maintainer-directed): the mandate measured cell by cell, six new audits built and green on merged-m5 and the matrix documented as a maintained artifact; THE PURSUIT answered and instrumented (audit_pursuit_leap); coverage gap 1 (tech roll + throw tech, both directions) and gap 2 closed; THE OBORO QUESTION answered with a live demonstration; the 14z-105 window (Oboro hook + version string) prepped in NEXT_SESSION  [+4 more entries]  [rolled 14z-107 close]
- Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale reference re-pointed, run green, or ruled a deliberate pin) plus the three findings it surfaced (the gate_failures litter class, GitHub #110, four LEGACY replays promoted off self-frozen .sha1); #110 FIXED AND CLOSED — the mechanism was the ARCADE DRAW, not cycle drift, both audits re-derived on pinned-opponent rigs and green on merged-m5; the Circuit Scrapper report measured and not reproduced  [+1 more entry]  [rolled 14z-107 close]
- Session 14z-102 CLOSE — THE #107+#109 WINDOW frozen as donovan-m10/huitzil-m19/pyron-m13/merged-m5 (#109 re-derived from scratch to effect-class ROW 31, the DF clone-mode beam emitter vsavj stubbed; #107 row flip; gold tint kept; build-dir triage 8.1 GB atticked; N-2 deletion policy adopted)  [+6 more entries]  [rolled 14z-105 close]
- Session 14z-101 CLOSE — the agreed #108->#107->#106 sequence executed windowless (#108 INVERTED to not-a-defect: the satellite word is our own bank row, native satellites equally sweep-inert; #107 twin-anchored statically + tie-refusal landed; #106 closed via verify_pcrel_data --extract); guard-corpus built 316/316; DF mechanics measured ours-vs-native (frameworks differ BY DESIGN; ours == pristine vsavj on the legacy control); #109 found, root-caused through two in-place retractions, and fully prepped  [+9 more entries]  [rolled 14z-104 close]
- Session 14z-100 CLOSE — THE HARDENING PROGRAM opened and executed same-session (pointer/flow comb H1, escape triage H2, the #99 continue-switch lock H3, the contact rig H4 with the -debug/non-debug instrument paradox left to 14z-101); #99 CLOSED (maintainer); #106/#107/#108 filed; the build-dir decision package delivered  [+3 more entries]  [rolled 14z-104 close]
- Session 14z-99 FREEZE + field-confirmation — THE WINDOW EXECUTED END TO END (donovan-m9/huitzil-m18/pyron-m12/merged-m4; #43(b)+#103+#104+#105; merged BIT-FOR-BIT the rehearsal; stock twin moved by design); field pass CLOSED all three tickets same day (incl. transformation throws) and un-parked #99; the skipped close ritual caught up post-freeze  [+7 more entries]  [rolled 14z-102 close]
- Session 14z-98 CLOSE — #103 root-caused+staged (window = uncomment+battery), #102 answered (vanilla's own continue), #104 found/reproduced/mechanism-closed-then-14z-99-corrected, #105 filed + AUTO selection solved, "instance 2" retracted (the 2-byte-poke class); NO SHIPPED BYTE MOVED  [+9 more entries]  [rolled 14z-101 close]
- Session 14z-97 CLOSE — #96 CLOSED (the battery's target FOLLOWS THE BUILD via registry.tsv); the §4 masked-compare vocabulary unified to ONE implementation (tests/lib/masked_compare.sh, proven 3 ways); the #99 continue rig BUILT and blocked one screen short by #103 (instance 2); #102 filed (arcade chaining quirks); 08_challenger_join's 3807 attributed to $FF06E1 (ram.md:62); two measured-wrong-thing defects fixed (propose_masked_specs absolute-builddir trap; the lifted diverge branch)  [+9 more entries]  [rolled 14z-100 close]
- Session 14z-96 CLOSE — ritual complete  [+7 more entries]
- Session 14z-95 — FOUR MAINTAINER RULINGS TAKEN, #52 LANDED, and the Phobos sfx report corrected from "a sound missing" to "a WRONG sound"
- Session 14z-94 (11) — THE MERGED-M2 PLAYTEST RESULT (maintainer, 2026-08-18, build/m3b_merged9 on MAME). NO REGRESSION — and one CRASH.  [+11 more entries]
- Session 14z-93 CLOSE — ritual complete  [+3 more entries]
- Session 14z-92 CLOSE — ritual complete  [+6 more entries, incl. GitHub #75 closed — the merged gfx-verify abort was a verifier artifact]
- Session 14z-91 CLOSE — THE LEGACY REGRESSION FIXED (obj_hook de-thunked: walker relocated, callers repointed; fixture-override deletion; type-6 change), m5/m13/m7 -> m7/m15/m9 re-freeze, EIGHT maintainer rulings applied (Rule 1 v2 retitle #35, PNG goldens ruled outside rule 7 #73, CI drafted #41...). THIS GROUP ALSO HOLDS, as ### sub-entries: 14z-90 (the 2026-08-15 adversarial audit re-judged, tier 1 complete), 14z-83..89 (Phobos DF gold block huitzil-m6, M5 voice samples design + Z80 driver RE, the 14z-85 owner-tag family, 14z-86 M5 voice batch, 14z-87 voice-class borrow + 87b beep/medallion, 14z-88 medallion revert, 14z-89 QSound ledger binding)
- Session 14z-82d — the playtest reports, measured  [+3 more entries]
- Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not
- Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three traps that were not in the spec
- Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN FOR TEN SESSIONS
- Session 14z-71 — THE BEAM: row 16 of the effect-class table is a STUB in vsav, and underneath it vsav has no list-type 12
- Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted
- Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal
- Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family asks it instead of the build scalar
- Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)  [+1 more entries]
- Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a GENERATOR BUG found under it  [+1 more entries]
- Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table row for H aliased character 0's block; ported H's own block. Also: the FG "slowness" was the broken GFX, not timing — resolved by observation.  [+1 more entries]
- Session 14z-71 CLOSE — ritual complete  [+6 more entries]
- RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6 (maintainer-approved; build/hui20, fingerprint 40cc10b1)
- Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build never walks the beam anim nodes (measured, both legs, one emulator)  [+3 more entries]
- Session 14z-69 CLOSE — ritual complete  [+8 more entries]
- Session 14z-68 (the effect-flow closure — root cause found)
- Session 14z-67 (D4: the Phobos gfx vertical)
- Session 14z-66 (playtest round-1 worklist)
- Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)
- Session 14z-64 SESSION CLOSE (2026-08-07)  [+3 more entries]
- Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL MEDALLION ART, vanilla cells pixel-identical by construction)
- Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and PLAYTEST-VALIDATED: the select family serves from group C bank 5; Jedah confirmed indistinguishable from vanilla by human playtest)  [+1 more entries]
- Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the emulator; and the rendering gate that should have caught it)
- Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)
- Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)  [+1: 14z-59j dual-track invariant established — later SUPERSEDED 14z-94 (#95), see the archive's marked banner]
- Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)  [+5 more entries]
- Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)
- Session 14z-58e (handoff hygiene: reproducibility PROVEN)  [+1 more entries]
- Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)
- Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)
- Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)
- Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)
- Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)
- Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)
- Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)
- Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)
- Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)  [+2 more entries]
- Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)  [+1 more entries]
- Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)
- Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)
- Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)  [+1 more entries]
- Session 14z-44c (round 55: WIN-screen item corrected + sharpened)  [+2 more entries]
- Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)  [+1 more entries]
- Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)  [+2 more entries]
- Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)  [+1 more entries]
- Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)
- Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)
- Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)
- Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)
- Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)
- Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)
- Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)
- Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)
- Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)
- Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)
- Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)
- Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)
- Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)
- Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)
- Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)
- Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)
- Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)
- Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)
- Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)
- Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)
- Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)  [+1 more entries]
- Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)
- Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)  [+1 more entries]
- Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19
- Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)
- Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)
- Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)
- Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)
- Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)
- Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)
- Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)
- Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)
- Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)  [+2 more entries]
- Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)
- Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)
- Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)
- Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)
- Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean
- Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)
- Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)
- Maintainer priority statement (round 24, 2026-07-30)
- Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)
- Session 14z (round 22: winpal copies convicted and fully reverted)
- Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)
- Session 14w-c resolution (ALL GREEN at d6a751cb)  [+4 more entries]
- Session 14v (grab-pointer work vars fixed — the Felicia float)
- Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)
- Session 14t (win-quote palette: decoded, port REVERTED by the gate)
- Session 14s (playtest round 16: overlay REVERTED; pixel gate born)
- Session 14r (overlay port COMPLETED to a 22-site shipping config)
- Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)
- Session 14p (feet fixed; blink mechanism = Jedah's overlay records)
- Session 14 highlights (M2a FROZEN)
- Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)
- Session 14n (round 12: revert validated; two new items scoped)
- Session 14m (f8eda2ca REVERTED — regression + board reset)
- (reverted) Session 14l (bank-attribution fix)
- Session 14k-b (blink TRULY root-caused: per-record bank attribution)
- (superseded analysis) Session 14k (OBJ budget saturation theory)
- Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)
- (earlier) Session 14i-b (round-9 mechanisms pinned)
- (earlier same session) Playtest round 9 diagnosis
- Session 14h highlights (win-quote portrait ported; HUD name found)
- Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)
- Session 14f highlights (select palettes fixed; splash/win specified)
- Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)  [+1 more entries]
- Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)
- Session 14c highlights (select-screen pipeline mapped)
- Session 14b highlights (M2b static phase — R2 cracked)
- Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)
- Sessions 5-6 highlights (M2a stage 4 — the port runs)
- Session 4 highlights (M2a — the real Donovan port)
- Session 3 highlights
- Early standing sections (Current milestone / Next actions / Open items / Decisions made) — 2026-07-era snapshots, STALE, kept verbatim in the archive; the closed early decisions (base revision vsavj, per-member checksums, byte-order convention) are all recorded in CLAUDE.md/HANDOFF too
- OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES — FIXED 14z-61 (the shadowed-ROM-member hash-resolution trap); header kept as written

---

# STANDING SECTIONS (current state — never archived)
## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

**[VSP-21]** "vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decisions pending (human)

*(Cleaned 14z-109, maintainer-directed: resolved and no-longer-shaping
entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*

- **DONOVAN'S PHYSICS ROWS (14z-118, found by the character-data map). DECIDED (maintainer, 2026-08-29): "use VS2 parameters and not the shell character's" — option (a); `port_param32 = true` set, probe + soak below, freeze at the next battery. **FROZEN 14z-119 as donovan-m18 / merged-m14 (M12); the stock twin moved with it, by design — STATE 14z-119.**
  `param32_a` (walk fwd/back), `param32_b` and `jump_params` (three jumps x
  xv/xaccel/yv/gravity) are NOT ported for Donovan: `build/manifest/donovan.toml`
  carries no `port_param32 = true`, so gen's `VALUE_SKIP` leaves his bank
  rows at the vsavj alias — **Victor's** values (row `0x03`). Measured on
  `build/don_m17`: walk 2.5 / −2.25 vs VS2's 3.0 / −2.625; back-jump xv
  −3.625 vs −4.25, neutral yv 8.0 vs 7.75, forward yv 8.0 vs 7.875, gravity
  −0.352 vs −0.375 (16.16). Huitzil (14z-66, after his own soak) and Pyron
  port theirs. The skip was the 14w-b crash guard written for the slot-0x0F
  port ("Jedah speeds retained"); whether the hazard survives the move to a
  variant id was never re-examined for Donovan. **Options:** (a) set
  `port_param32 = true` for Donovan and run the same soak battery Huitzil
  ran (RECOMMENDED — VS2-faithful movement is the project's default; the
  cost is one freeze); (b) keep Victor's physics deliberately (record it as
  a tuning decision in `charmap_donovan.toml`'s header so the map stops
  flagging it). Gameplay feel: the maintainer's call.

- **THE `docs/project/tables/` PROMISE (14z-118, from the documentation
  audit's inventory `docs/project/doc_audit_14z118.md` §3). DECIDED
  (maintainer, 2026-08-29): option (a) — generate the two missing
  manifests and refresh all three.** The
  directory's README says "per-character data manifests for Donovan /
  Huitzil / Pyron" and still opens with "Empty until a ported character
  exists"; it holds `donovan.md` (2026-08-09, never refreshed) and no
  Huitzil or Pyron file. CLAUDE.md §2 rule 5 ([VSP-6]) makes these the
  community-facing tunables. Options: **(a) generate `huitzil.md` /
  `pyron.md` with the extractor that produced `donovan.md` and refresh all
  three from the current manifests — RECOMMENDED, it is what the rule
  says;** (b) retract the promise and name `build/manifest/*.toml` as the
  table of record. Blocks audit step 5 only; steps 1-4 proceed.

- **THE TENANTS' WIN QUOTES — FORGONE FOR NOW (maintainer, 2026-08-28,
  14z-116). DECIDED.** The ruling, verbatim in substance: *"Let's forgo for
  now but document everything so that, should we want to do it in the
  future. And should we ever do it, we'd do it the clean way, not touching
  vanilla."* So this is PARKED, not closed, and it is parked WITH A
  CONSTRAINT ON ANY FUTURE ATTEMPT: **the clean way only — the vanilla bank,
  the four-entry region root, tables A/B and `RAM:$FFF230`'s vanilla value
  all stay byte-identical. The 14z-76 whole-bank relocation is RULED OUT by
  this decision, not merely un-preferred.** The buildable shape is the one
  measured below (group C bank 5's blank font window + the shipping
  `winquote_bank_variant_id` gate + one tenant-only selector thunk), and the
  single open measurement before it could be scoped is named there. Nothing
  in the tree needs undoing: Phase 0 shipped only tools, a gate and
  corrections. Everything below is the measurement record.

  PHASE 0 AS MEASURED (14z-116): The maintainer's framing for this task: cosmetic, no 2P surface,
  so equip the suite against a silent state poison — and **forgo it outright
  if the implementation carries structural risk or costs compatibility**.
  Phase 0 was run before any shipped byte. What it found:
  - **A data-only fix is IMPOSSIBLE, confirmed.** `tools/scan_quote_window.py`
    re-derived the 14z-76 prose claim as a script: **zero** runs of `0x20`+
    free bytes within `±0x8000` of the bank base, and zero around any of the
    16 winner blocks (the second hop). A control at `0x8` finds exactly one
    9-byte run, so the scanner is not blind.
  - **The 14z-76 relocation plan is wrong in three places** (all corrected in
    place, `engine_internals.md` §8 + the `patch_index.md` header): the root
    is a FOUR-ENTRY REGION array whose other three banks are the ENGLISH
    text, not one long; the bank is `0x4104` bytes, not `0x40DC`; and lines
    can be 17 codes — the real bound is the renderer's own 66-word buffer,
    which is exactly what a bad offset overruns.
  - **The relocation is NOT legacy-invisible.** `move.l a1,$30(a4)` installs
    an absolute bank pointer at `RAM:$FFF230`, measured live during the
    VANILLA win screen (replay 23 `0x00331136`, replay 28 `0x0033101E`). So
    the deferral's "change one long" would move legacy work RAM on every
    win-reaching replay and buy a permanent superset-invariant tax, with a
    new ratified class per replay, for a cosmetic.
  - **THE REAL COST IS GLYPHS, and nobody had measured it.** The three vs2
    tenant blocks use 331 distinct codes; at the shared font base **326 of
    327 non-pad codes draw a DIFFERENT character in vsavj**. Every glyph
    DOES exist in vsavj — but at tiles `0x22000-0x2FFFF`, gfx **bank 1**,
    unreachable from a 12-bit code in the quote object's bank — and vsavj's
    bank-0 font window is **4096/4096 non-blank**, so there is no free slot
    to remap into. A code remap cannot fix this: ~330 glyph tiles must
    travel, which no version of the 14z-76 plan budgeted.
  - **AND THERE IS A CLEAN ROUTE, if you want it.** Group C **bank 5's**
    font window (in-group `0x13800-0x147FF`) is **4096/4096 blank** on
    `build/m3b_merged18`, and the shipping `winquote_bank_variant_id` gate
    (14z-62j, `site 0x05F328`, `only_variant_slot`) already flips the
    win-quote drawer to bank 5 on a TENANT WIN ONLY. So the glyphs can be
    authored into space we own, by the same mechanism the 14z-115 outline
    sprites used, with **no vanilla tile touched**; the text would ride one
    `site_thunk` on the selector for winner `>= 0x10`, leaving the vanilla
    bank, the root array and `$FFF230`'s vanilla value byte-identical.
    **NOT YET MEASURED, and it is the one thing left before a build could be
    scoped:** whether the TEXT object (set up at `PRG:0x00C840-0x00C862`,
    fed by `$30(a4)`) takes its bank from the same field that gate writes —
    the gate patches the drawer object at `0x5F328`, which is a different
    chain. If it does not, the thunk writes the bank itself.
  **THE PRICE THAT DECIDED IT:** ~330 authored glyph tiles + a thunk on a
  legacy-reachable site + a new win-quote RENDER gate (pixels — no RAM gate
  can ever see text), for a single-player cosmetic surface the standing
  "cosmetic is optional" scope calls nice-to-have. **RESUMING IT LATER
  COSTS NOTHING EXTRA**: the decoder, the font audit, the reach scan and the
  structure gate are all in the tree and green, so a future session starts
  at Phase 1 with the one open measurement, not at archaeology.

- **THE MiSTer SCOPE DOCUMENT — three decisions, ALL DECIDED (maintainer,
  2026-08-28, 14z-113; `docs/project/mister_scope.md` §8).**
  (1) **The split stands as written** ("in line with what I would do";
  the maintainer defers on the CPS-II-vs-VS specifics and follows the
  recommendation, MRA mechanics at level 1 included).
  (2) **The staleness pass (S1-S20) is MANDATORY before any distillation
  — but WAITS for the board results the maintainer is producing in
  parallel right now** (the #113 hand check and bundle 14z112's stock
  coexistence), so the pass lands on a settled state and does not have to
  be re-done. **Sequencing: board results -> record them -> the S1-S20
  pass (one commit) -> only then the skills.**
  (3) **The `.rbf` AND the MRAs are TRACKED IN-TREE** — the maintainer's
  ruling: they belong with any BPS/xdelta used to patch vanilla ROMs, i.e.
  under `release/`. **This opens a NEW item, the MiSTer RELEASE FORMAT**
  (below): what a `release/<name>/` carries for MiSTer, how and where it is
  generated, and its provenance record.

- **DOES THE STOCK CONTROL MRA STILL HAVE A USE? (maintainer's question,
  2026-08-28, after it booted fine on bundle 14z112.) DECIDED (maintainer,
  2026-08-29, 14z-118): KEEP IT, RE-SCOPED — run once per NEW `.rbf`
  (seed / slice / pin), off the per-release checklist; stays in every
  release's `mister/`. The recommendation as it was put:** It was built (14z-109) to separate a fault in our
  PROFILE from one in the bitstream/card/module/video chain, at a time when
  the bundle's `vsav.zip` was patched and no stock MRA could serve as a
  control. Two of its three jobs are now done by something else: a stock
  MRA on Jotego's own core covers "the board/card/module is fine" (and it
  just did), and the shared pristine `vsav.zip` means no bundle can poison
  stock art any more. **The job nothing else does: it is the EMULATOR
  SUPERSET INVARIANT ON SILICON** — stock `vsavj` running on OUR `.rbf`
  with the profile bit at the `0xFF` fill, i.e. CLAUDE.md rule 1 v2's
  "the patched binary running stock is untouched by construction",
  measured on hardware rather than in Verilator (`test_mister_wide_inert`
  is the simulated form). That claim is about the BITSTREAM, so the control
  needs running **once per new `.rbf` (new seed / new slice / new pin),
  NOT per romset release** — the `.rbf` has not changed since 14z-108, so
  today's pass covers it until the next synthesis. Cost of keeping: one
  XML file in the bundle and one line in the README. Recommendation: keep
  it in the release format (the MRAs are tracked in-tree now), label it
  "run when the bitstream changes", and drop it from the per-release
  checklist. Dropping it outright is also defensible — the maintainer's
  call; no gameplay surface.

- **THE RELEASE FORMAT — DECIDED (maintainer, 2026-08-28, 14z-113) AND
  IMPLEMENTED FOR merged-m10.** The ruling, verbatim in substance: the
  `release/<name>/` recommendation below is accepted WITH the caveat that
  **each platform is self-sufficient per format — not every file at the
  same level; each platform directory holds everything that platform needs
  and only that** (FBNeo needs nothing MiSTer and vice-versa; platform
  drivers packaged with their platform), and **every version releases all
  platforms even when the change touched one.** Two details I asked and the
  maintainer chose: the patch set is COPIED into each platform dir (not one
  shared dir + per-platform zips); FBNeo/MAME carry the driver PATCH + build
  recipe, not binaries. Spec `docs/project/release_format.md`; producer
  `tools/package_release_platforms.py`; gate `test_release_roundtrip.sh`
  §4; first instance `release/merged-m10/{fbneo,mame,mister}/` (manifests
  byte-identical). **Refined the same day (maintainer): the bitstream is a
  BUILD RESOURCE, canonical at `release/bitstreams/<seed>/` with `CURRENT`,
  hash-verified into every release, never copied from another release** —
  the `.rbf` (seed 18269, sha256 `46fc74af…`) is in the tree there and in
  `merged-m10/mister/`. The recommendation as it was put:
  *What ships.* `jtcps2w.rbf` (3.1 MB; GPL-3.0 output of a public fork, not
  ROM content — rule 7 is not engaged), the two MRAs (WIDE + the
  `[STOCK CONTROL]` reference leg — XML metadata: names, CRCs, offsets), and
  a provenance record: fork pin, **seed, reported slack, sha256, build
  datestamp** (the hash identifies the artefact, the seed the result —
  `mister.md` "REPRODUCING THE SHIPPING BITSTREAM"). NOT the `.rom`
  (ROM-derived, rule 7) and NOT any zip.
  *Where.* Recommendation: **inside the same `release/<name>/` as the
  xdelta package**, e.g. `release/merged-m9/mister/{jtcps2w.rbf, *.mra,
  BITSTREAM.txt}` — one release = one directory for all three
  implementations, which is what `package_release.py` already promised
  ("MiSTer later adds a DISTRIBUTION layer over the SAME members", HANDOFF).
  Alternative: a separate `release/mister/` keyed by bitstream, since the
  `.rbf` changes on a DIFFERENT cadence from the romset (it did not move
  from 14z-108 to 14z-112 while the romset moved three times). The two can
  coexist: the bitstream lives once under `release/mister/<seed>/` and each
  romset release's `mister/` holds the MRAs plus a pointer to the bitstream
  it was verified with.
  *How generated.* The MRAs already come from `tools/mister_mra.sh --no-rom`
  (ROM-free, deterministic); the bundle assembly is by hand today
  (`../mister_fieldtest_14z11x/` + README + FIELD_TRIAGE). The natural home
  is a `--mister` mode of `tools/package_release.py` (or a sibling
  `package_mister.py`) that copies the MRAs, verifies the `.rbf` against the
  recorded sha256 and refuses on mismatch, writes the provenance record,
  and runs `check_mra_parts.py` against the release's own members. Gate:
  `test_release_roundtrip.sh` gains a MiSTer leg (MRA parts resolve, hash
  matches record).
  *What it retires.* The out-of-tree field bundles as the only carrier, and
  S18 of the scope document (the untracked `.rbf` path).
  **Not started; waits behind the board results and the staleness pass by
  the maintainer's own sequencing.** No gameplay surface.

- **#112 — PRESS OF DEATH BLACK FOOT: ACCEPTED AS COSMETIC. DECIDED
  (maintainer, 2026-08-27): option (c) — accept for now; option (a) (give
  tenants their own effect animation) is PARKED for a later pass over the
  port's remaining purely-cosmetic items.** Option (b) (trim the borrowed
  sequence) is refused outright: the sequence is vanilla vsavj data, so
  editing it breaks the superset invariant regardless of what it does to the
  move. Rationale for (c): the defect is purely visual on a single-player
  surface, the project already carries small cosmetic imprecisions, and the
  mechanism is not understood well enough to patch safely — the whole draw
  path measured VANILLA (writer `PC 0x01B2BE` byte-identical to stock,
  vanilla record `0x287D7C`, vanilla sequence, vanilla art, tile window
  byte-identical to stock), and WHY a tenant runs that sequence is still
  unknown. GitHub #112 stays OPEN as the parked record; do not re-derive the
  eliminations, they are listed in the 14z-112 group above. **When the
  cosmetic pass happens, the entry point is a DISASSEMBLY-based trace of the
  effect spawn — not a byte scan** (two instruction-boundary false positives
  were paid for here: `e768 7105` and `0028394E`).

- **#113 — THE ONE-FRAME WHITE-OUT AT A DOWN IS VANILLA (measured 14z-112,
  `tests/test_down_flash_vanilla.sh` PASS on stock vsavj / reference MAME).**
  Stock Vampire Savior draws ONE all-white frame (fnv `eab1fb569cb99b25`,
  whole framebuffer) 57..96 frames after every down, plus the intro pair and
  the match-start frame — merged-m9 reproduces exactly that inventory and
  nothing more. So it is not a port defect, and the photosensitivity concern
  is with Capcom's design. **The decision:** (a) CLOSE as vanilla behaviour
  (RECOMMENDED — the superset invariant forbids changing legacy frames, and
  the flash fires on every legacy down); (b) an OPT-IN accessibility
  softening (dip/config-gated, WIDE-only, default OFF, so default legacy
  output stays bit-identical) — a deliberate legacy-content change that
  needs its own ruling, a measured mechanism (palette-RAM vs CPS-B layer
  register at the white frame — not yet measured) and a gate; not free.
  The CRT "background stays, sprites vanish" is consistent with one white
  frame on phosphor (interpretation, not measured).
  **Maintainer's rule (2026-08-27): vanilla in VS with VS characters =>
  close regardless of vs2; measured BOTH — vsavj (104: +96) AND vsav2
  (37_victor_ko_vsav2, native Donovan: +88) show it. Awaiting the
  maintainer's own hand check on stock vsavj, then CLOSE.**
  **UPDATE 2026-08-28 (maintainer): NOT closed, and not to be closed yet.
  The maintainer is gathering CAMERA evidence because original
  hardware/MiSTer may DISAGREE with the emulation finding, and wants
  bulletproof evidence before the topic is reopened. Until that arrives:
  the emulator measurement stands as measured, nothing is re-derived, and
  #113 stays OPEN. If the board does show something the emulators do not,
  that is a cross-implementation finding about the white frame's
  rendering (palette/CPS-B layer register at that frame — never measured,
  see (b) above), not about the game data.**
- **~~#99 — THE TYPE-0x51 REMAP~~ RE-RULED (maintainer, 2026-08-26, 14z-110):
  THE REACTION_HOOK D2-WINDOW SHAPE IS APPROVED, in the explicit order
  FIX -> AUDIT -> RE-FREEZE.** "Very well, I agree with all the proposal."
  What is approved, precisely:
  * **Shape: the reaction_hook THUNK BODY is extended — never the vanilla
    dispatcher.** The engine's patched footprint does not grow (still the one
    6-byte `jmp` at `0x018458`); the thunk's bne-arm (the only entry into
    dispatcher 2 at `0x018508`) gains the same `0x50-0x53` window test it
    already runs for dispatcher 1, dispatching via a SECOND ext table to vs2's
    dispatcher-2 twin (`0x016DE4`) handlers VERBATIM; every other index takes
    `jmp 0x018508` exactly as today. Data stays native `0x51` — dispatcher 3,
    the `es_type51_dispatch` thunk and the `property[0x51]=0x19` lookup are
    untouched.
  * **Scope: DATA-TRIGGERED, deliberately NOT tenant-id-gated.** The branch
    keys on the node byte's VALUE (`0x50-0x53`), which only vs2-numbered
    ported data can carry — vanilla data reaching dispatcher 2 with such a
    byte crashes today, so no legacy behavior can depend on the added branch
    (legacy-safe by IMPOSSIBILITY, the index_window_018468 precedent). An
    id-gate would be WRONG: the field proved the walking object can be a
    LEGACY character's (Bishamon) — the trigger is whose DATA the node lives
    in, not whose object walks it.
  * **Ownership: `donovan.toml`'s `[reaction_hook]` singleton** (merged
    inherits; solo Huitzil/Pyron don't declare it and the census measured
    them at ZERO out-of-range nodes, so they don't need it).
  * **The one global cost is CYCLES** — every object on the hit-stun path
    (`+0x38` set) executes the ~2 added compares, all characters. The
    flicker-inventory measurement (step 2 of the order) is the gate: if the
    frozen inventory moves, STOP and return to the maintainer — never widen.
  * **Order is binding: FIX (manifest + emitter) -> AUDIT on the fix build
    (flicker inventory, test_fsm_census still 6/6 native, audit_don_vs_cpu,
    guard soaks, audit_continue_switch re-measure) -> RE-FREEZE
    (donovan-m12/huitzil-m21/pyron-m15/merged-m7) + the MiSTer CRC tail.**
    Field pass on the new bundle is the actual #99 verification (MAME cannot
    reproduce the crash).
  This supersedes the 2026-08-26 (a)+(b)+(c) ruling's part (b); (a) — vanilla
  dispatcher never patched — is honored by construction, and (c)'s census came
  back EMPTY of further members. The measured basis below stands as the trail.
  **Original re-ask (14z-110), kept for the trail:** The census is
  DONE and the fix shape needed a fresh decision; (b) was not implemented.
  **WHAT THE CENSUS FOUND (measured 14z-110, `tools/audit_fsm_census.py` with
  the vs2 oracle + `tests/lua/fsm_census.lua` corpus):**
  1. **There is only ONE out-of-range family, and it is the KNOWN one.** The
     static family-aware census (node-record signature: 0x20-stride, monotonic
     +0x10 counter, +0x17 a valid state) finds exactly SIX out-of-vsavj-range
     node-state bytes across ALL THREE tenants — the six `0x51` records in
     Donovan's hitbox (`0x3FB862`-`0x3FB902`, +0x17 at blob offsets
     `0x10E9..0x1189`), which ARE the 14z-35 cluster. **Huitzil and Pyron have
     ZERO.** No `0x50/0x52/0x53` node clusters exist. **So the escalation
     clause resolves cleanly: there are no OTHER members to classify.** (Bound:
     signature-based; the dynamic corpus census found no idx >= 0x50 dispatched
     on any leg, mapping the reachable tenant node regions — a coverage bound,
     stated, not a universal proof.)
  2. **The node byte feeds THREE dispatchers, not one, and they are 80-entry
     not "~0x28".** `0x018460`/`0x018508`/`0x0185D2` (vs2 twins `0x016D34`/
     `0x016DE4`/`0x016EB6`, 84 entries -> gap `0x50-0x53`). The 14z-43
     `es_type51_dispatch` thunk's consumer audit named dispatchers 1+3 and
     MISSED dispatcher 2 (`0x018508`) — that is where #99 crashes. The records
     were left native `0x51` on purpose (dispatcher 3 + the property lookup
     need it).
  3. **A DATA remap breaks things:** `0x51 -> 0x19` diverges on dispatcher 3
     (there `0x19` -> handler `0x18694`, NOT the copy handler) AND fails the
     `es_type51_dispatch` thunk's `cmpi #0x51`. `0x51 -> 0x4E/0x4F` is
     copy-aliased on all three dispatchers, BUT the copy handler STORES the
     class and a downstream property lookup keys on it
     (`property[0x51]=0x19` vs `property[0x4E]=0x0F`, the 14z-44 ES-freeze
     family) — so it changes gameplay. **No data value is both
     dispatcher-exact on all three AND property-preserving.** Ruling (b) as
     written ("`0x51 -> 0x19`, zero gameplay surface") is therefore wrong on
     both counts.
  **RECOMMENDATION (measure-first order, port-the-handler caveat honored):**
  the clean fix is **CODE-SIDE on dispatcher 2's arm, inside a hook that
  already owns the only entry to it** — the `reaction_hook` site prefix
  (`0x018458`) already re-creates `tst.b (0x38,a1); bne 0x018508`, so its
  bne-arm gains the same `0x50-0x53` window the reaction_hook already runs for
  dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim.
  Data stays native `0x51` (dispatcher 3 + property untouched). Cost: ~2
  compares on a path legacy executes when `+0x38` is set — **must be measured
  against the frozen flicker inventory before it ships** (that is the only open
  cost; if it moves the inventory, stop and root-cause). This is NOT a "port
  the handler" import — it reuses handlers already present; it adds a window
  test, not a foreign routine. **Delivered this window regardless of the
  ruling:** the census tool + gate (`test_fsm_census`, negative controls
  green), the deterministic Donovan-vs-CPU-Phobos coverage gate
  (`audit_don_vs_cpu`, closes #111's core gap), replay 110. The fix itself
  waits on this ruling.
  **HONEST GAP unchanged:** #99 does NOT reproduce on MAME from a P1-mash
  (full venue-0x02 Donovan-vs-Phobos marathon ran clean to END 40620) — the
  bad node needs the specific cross-fighter walk the maintainer sees 100% on
  the CORE. So no MAME regression lock is possible; the fix is verified by the
  census (node no longer >= table size on dispatcher 2's reachable path) + a
  field pass.
  **~~ORIGINAL RULING (maintainer, 2026-08-26), SUPERSEDED BY THE ABOVE~~:**
  (a)+(b)+(c) — (a) data-side extraction remap, never the dispatcher; (b)
  `0x51 -> 0x19`; (c) census + escalation. (a) and (c) stand in spirit; (b) is
  the part the measurement overturns. Kept for the trail.**
  **THE MAINTAINER'S STANDING CAVEAT ON (c), recorded verbatim in spirit:**
  for escalated hits, "port the handler" LOOKS like the best default (no
  error states + vs2-consistent tenant behavior) — **but it is NOT free: not
  in memory, not in cycles, and not in side-effects. Measure first. And if
  the maintainer seems too eager to say yes to a port, RAISE THIS POINT** —
  their own instruction. The project's evidence agrees: a ported handler
  imports code that may touch fields vsav lays out differently, may call vs2
  helpers at vs2 addresses (thunk/relocation work), costs bytes and
  per-frame cycles, needs its own gates — and "consistent with vs2" can
  still be WRONG under vsav's engine (the DF-frameworks-differ-BY-DESIGN
  lesson, 14z-101; the effect-class root that pulled cascading dependencies,
  14z-102). Default order for an escalated hit: measure what the state DOES
  and how often our content reaches it -> consider neutralize-to-default ->
  port ONLY when the behavior demonstrably matters to feel.
  **Original measured entry:** Step 1 done (14z-109 (7)), all three answers:
  1. **Family**: the object-script FSM node stream — 0x18-byte nodes whose
     `+0x17` byte is the NEXT-STATE index — inside Donovan's ported
     character block. Our node `0x3FB882` = vs2 `0x0C9CAA`, ported
     byte-verbatim (single content-search hit, 0x28-byte window).
  2. **What vs2's `0x51` means**: vs2's FSM table (dispatcher `0x016D2C`,
     table `0x016D34`) has **0x54 states**; entry `0x51` (offset `0x023C`)
     is vs2's MOST-ALIASED **DEFAULT handler** — `move.b (0x17,a3),(0x54,a1);
     rts`, the plain "advance to the node's next state". ~20 vs2 states
     alias it.
  3. **The vsavj equivalent**: vsavj's default at table offset `0x017C`
     (handler `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
     **BYTE-IDENTICAL** to vs2's `0x51` handler.
  **PROPOSED RULING: remap node-state `0x51 -> 0x19`** (the lowest vsavj
  default-alias) — semantically exact, both engines run identical
  instructions, zero gameplay surface. **Plus the census before the fix
  window**: scan ALL THREE tenants' ported node streams for `+0x17` values
  `>= 0x28` (vsavj's table size) and remap each by the same
  handler-equivalence method — one missed member is how THIS one shipped.
  Fix = extraction remap rule (14z-33/35 shape), landing with #111's
  coverage work in one window. Original entry:** Root cause is on the issue: node `ROM 0x3FB899` in Donovan's
  relocated block carries vs2 type byte `0x51`; vsavj's dispatcher at
  `PRG:0x018508` has no row for it and no bounds check. The fix wants THREE
  answers before any byte moves: (1) which record family `0x3FB882` belongs
  to in the extraction; (2) what vs2's `0x51` MEANS there (its handler in
  vs2's own table); (3) the correct vsavj renumbering — then a REMAP RULE in
  the extraction per the 14z-33/35 shape, never a hand-poke. Gameplay
  surface possible (the node does something in vs2 that vsavj may express
  differently), hence maintainer-ruled. **#111 (coverage rot) should land in
  the same window**: re-point or replace `26_don_arcade_mash`, re-measure
  `audit_continue_switch`, and add the missing Donovan-vs-CPU-Phobos gate
  (the venue-byte steer makes a deterministic one possible). The build-time
  guard — validate every ported type/selector byte against the consuming
  dispatch's bounds — is what keeps the NEXT missed family member off a CRT.

- **~~THE TIMING-MARGIN RESPONSE~~ DECIDED (maintainer, 2026-08-25).**
  `cps2w` fails 4 of 12 fitter seeds (14z-108). Options were laid out A-E.
  **RULED: A + B, with C IN RESERVE. D is ACCEPTABLE. E is OPPOSED unless
  there is no better choice.**
  * **A — do nothing to the RTL.** We distribute a PREBUILT `.rbf`, so the
    fragility is ours and not the users'.
  * **B — PIN THE SEED AT RELEASE.** Every shipped bitstream is built from a
    NAMED seed with its slack and sha256 recorded and verified, never from
    an `xjtcore.sh` random draw. The current baseline is **seed 18269,
    +0.066 ns, sha256 `46fc74af…`**. Costs nothing and converts "we got a
    lucky draw" into "we know which draw, and we check it".
  * **C — shed load on the SDRAM address cone** (bank 0 carries SEVEN slots
    since D2; the rejected 14z-107 alternative was moving the Z80 out).
    HELD IN RESERVE: it is the only fix that stays inside Rule 1 v2 and
    touches no shared infrastructure, but it would invalidate the bank-1
    bandwidth measurement, so it is not to be spent on headroom we do not
    currently need. **Revisit BEFORE the next RTL slice, not after.**
  * **D — pipeline the SDRAM address path.** ACCEPTABLE if C is not enough.
    Note it means overriding jtframe's shared controller in `cores/cps2w`.
  * **E — lower the SDRAM clock.** OPPOSED unless nothing else works: bank 0
    already peaks at 43.9% of its 96 MHz ceiling, so the clock is buying
    headroom we are using.

- **~~MiSTer PACKAGING: which MRA is MAIN, and how a release carries both
  `vsav.zip` flavours~~ DECIDED (maintainer, 2026-08-25): OPTION A, a
  WIDE-ONLY RELEASE, with option B as the eventual target.**
  **The collision, named exactly (14z-108):** the four ported-art members
  are `vm3.13m/.15m/.17m/.19m`, and they live in **`vsav.zip`, not
  `vsavjw.zip`**. So the WIDE MRA needs a PATCHED `vsav.zip` while every
  stock MRA needs the PRISTINE one — same filename, one `games/mame/`
  folder — and jtframe resolves members **by CRC32 alone**, so the wrong one
  is silently filled rather than refused.
  **Ruled: ship the WIDE MRA only.** The maintainer's reasoning, recorded
  because it settles the "which MRA is main" half too: **Jotego's own
  `jtcps2` core already runs vanilla**, so our core does not need to, and
  the stock regional MRAs are a development reference leg rather than a user
  feature. The generator currently makes the **Euro** set the main MRA and
  buries the WIDE entry in `_alternatives/`, which is backwards for a core
  whose purpose is the roster.
  **Option B stays the target shape "in time"**: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **THE REMAINING SKILLS — PLANNED AND ALL FOUR SHIPPED 14z-114 (`docs/project/skills_scope.md`,
  now the record); the five decisions were taken under stated assumptions and remain OPEN TO VETO — a veto means re-cutting a shipped skill, which the checker makes mechanical:** (1) FOUR
  skills — `cps2-hardware`, `cps2-emulation` (split per "MiSTer separate
  from emulation"), `vampire-savior-engine`, `vampire-saved-port`; (2) the
  game skill quotes NO ROM addresses (laws + the atlas row it names); (3)
  the port skill anchors into CLAUDE.md and points, never restates it; (4)
  each skill's staleness pass runs in the same session as its distillation
  as its own commit (the MiSTer ruling generalised); (5)
  `engine_internals.md` counts as a LOG for the game skill's number-citation
  check. Sequencing A+B (platform) -> C (game) -> D (port). Distillation of
  A+B began the same session — and all four landed in it: `[CPH-1..30]`, `[CPE-1..42]`, `[VSE-1..83]`, `[VSP-1..161]`; 425 rules across six skills, `checkskills` ALL PASS.
- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** ~~Recorded as FUTURE, UNPLANNED work — nothing scheduled.~~
  **ALL SIX SKILLS ARE DONE 14z-114** (`mister-cps2-wide-core`,
  `mister-vampire-saved`, `cps2-hardware`, `cps2-emulation`,
  `vampire-savior-engine`, `vampire-saved-port`; checker `tools/checkskills.py`;
  STATE 14z-114). The maintainer's sketch — a CPS-II skill separate from a
  VS/VS2/VH2 skill — is met by the `cps2-*` pair and `vampire-savior-engine`;
  the checker shape (docs as the human rendition, anchored IDs, numbers cite
  the log) is the pattern any future skill reuses.
  As was done for Sailor Moon S, distil the project's learnings into agent
  SKILLS, **scoped by subject rather than by task**. The maintainer's sketch:
  at least a **CPS-II** skill separate from a **VS / VS2 / VH2** skill, and
  **MiSTer** separate from **emulation**; exact scopes to be agreed. Stated
  rationale: they make further work markedly easier.
  **The precedent is concrete and observable from inside a session** — the
  SMS project produced `romhacking-methodology` (general RE/patch discipline)
  and `snes-romhacking` (platform-specific hard rules), and both load into
  Claude Code sessions on this machine today.
  **Three observations to carry into the scoping conversation:**
  1. **The split the maintainer proposes is the one `docs/README.md` already
     uses.** "Would this still be true if we abandoned the roster hack
     tomorrow?" separates `platform/` (CPS-2, MAME, FBNeo, MiSTer) from
     `game/` (Vampire Savior itself) from `project/` (this port) — and it is
     the same question that separates a CPS-II skill from a VS/VS2/VH2 skill
     from a port skill. A skill that mixes those scopes fails the same way a
     doc filed by task instead of by fact does.
  2. **A skill is loaded BEFORE the work, so it must carry what you need to
     know before you know you need it** — laws, traps and negative controls,
     not reference data. SMS made this split explicitly:
     `sms_hacking_playbook.md` quotes ZERO addresses on purpose and points at
     the checked docs instead. Skill = the discipline; docs = the facts.
     Candidate content from this project, all paid for: measure-don't-infer,
     probe sparsity, the negative-control rule, "identify moves by measured
     EFFECTS not the script's input name", "a gate that stops checking reads
     GREEN not RED", "suspect the instrument before the thing under test",
     and the §4 vocabulary of frozen non-exact classes.
  3. **Skills go stale exactly like docs, and need the same enforcement.**
     SMS ships `tools/checkskills.py`, which ID-locks the human playbook to
     the agent skill so the two cannot drift. Whatever is distilled here
     should ship with its checker in the same commit.
  Sequencing: this naturally follows the living-documentation effort above
  (a skill is a distillation, so it wants the synthesis to exist first), and
  both follow MiSTer.

- **MiSTer DOCUMENTATION + SKILL DISTILLATION, AT TWO LEVELS (maintainer
  direction, 2026-08-27). DONE 14z-114 — both levels distilled, see the
  14z-114 entry; `mister_scope.md` carries the status.** FIRST STEP AGREED 2026-08-27: produce the SCOPE
  DOCUMENT ONLY — ~~queued in `docs/NEXT_SESSION.md`~~ DONE 14z-113:
  `docs/project/mister_scope.md`; its three follow-on decisions are the
  entry "THE MiSTer SCOPE DOCUMENT — three decisions" above.** The scope document
  names what skills should exist, where each boundary falls, which existing
  docs feed which, and what is known-stale; the skills themselves wait on it.
  Rationale for splitting it out: the sources run ~4,000 lines and must be
  READ, and the state is not settled (merged17 unfrozen, two field checks
  outstanding), so writing reference material now would bake in claims that
  are still moving. Recorded as FUTURE work alongside the existing
  skill-distillation and living-documentation items, not scheduled. The
  maintainer's scoping: document (and possibly distil into skills) the MiSTer
  implementation **at each level** — (1) the **WIDE CPS-II core** level (the
  profile, the runtime profile bit, the SDRAM map, the simulation lane: all
  game-independent), and (2) the **VS-specific** level (this romset's
  placement, catalogue/MRA generation, the field-test bundle). The split
  mirrors `docs/README.md`'s own test ("would this still be true if we
  abandoned the roster hack tomorrow?") and the CPS-II-vs-VS/VS2/VH2 split
  already sketched for the skills. Raw material exists and is large:
  `docs/platform/mister.md` (core, lane, profile gate, SDRAM ceilings) and
  `docs/project/mister_fit.md` (what this port needs vs what jtcps2 offers).

- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24).** Recorded as DIRECTION, not as a task — nothing is
  scheduled and MiSTer stays the current arc. In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- ~~Minor win-screen palette issues~~ **FIXED 14z-68m** (build/hui11):
  the palette source is the OPCODE-view remap table, and the portrait
  position row needed vs2's own values. Gate: `tests/test_hui_winscreen.sh`.
- **OPEN (cosmetic):** win QUOTE TEXT — **all THREE tenants still show their
  SHELL's quote** (corrected 2026-08-27 by the maintainer; this entry used to
  say "Huitzil's", which understated the scope). Root-caused, not built: the
  first-level table at the quote bank base ALIASES its variant half
  (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — *corrected 14z-116: this entry
  said "consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`", which is
  the 14z-73 reading of the PORTRAIT fetch and was retracted in
  `engine_internals.md` the same session; it is not the quote mechanism.*
  MEASURED 14z-116 (see the session entry and "Decisions pending"): a
  data-only fix is impossible, the relocation perturbs legacy work RAM, and
  ~330 glyph TILES have to travel. NOTE the
  win-quote ART is already native and complete (14z-62e/62j, group C bank 5) —
  what remains is the TEXT. See the cosmetic backlog below.
- **OPEN:** FG pacing — untouched.

### THE COSMETIC BACKLOG (parked, 2026-08-27 — the maintainer's own list)

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:

| item | status | what is known |
|---|---|---|
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | **FORGONE FOR NOW (maintainer 14z-116); parked WITH A CONSTRAINT — if ever done, the CLEAN way only, vanilla untouched** | the first-level table aliases the variant half; a data-only fix is IMPOSSIBLE (zero free bytes at either hop, re-derived by `tools/scan_quote_window.py`), the bank relocation perturbs `RAM:$FFF230` on legacy win screens, and ~330 glyph tiles must travel. Art side already native (14z-62e/62j) |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| ~~**PYRON'S MEDALLION WHITENS on the select screen**~~ **FIXED 14z-116** | **FIXED and FROZEN 14z-117** as merged-m12 (`build/m3b_merged19` rebuilt with the M10 mark, `cde712e1`; the 14z-116 candidate was `af21bc88` under M9 — same bytes) | **The long-parked residual is closed, and it was never the accent march.** WRITE-TAP ATTRIBUTION (16 word writes, PCs `0x3FFC60-0x3FFCA6`) named **our own 14z-62k sword thunk** at `PRG:0x05F9D0`: its P2 branch wrote `0x90C340` = row `0x1A`, which is also Pyron's medallion row. Not Donovan's portrait (the 14z-87b supposition), and not the marcher — the marcher was already neutralised for `0x16/0x19/0x1A` in 14z-64. **Maintainer chose the fix from three options (2026-08-28): drop the P2 write.** `tst.b $381(a4)` now `bne`s to the pop/rts, two NOPs replace `adda.w #$60,a1` — same byte count, no allocation ripple. **ACCEPTED TRADE, field-observed 2026-08-29 (and NOT what I predicted):** the P2 sword does not revert to grey — it draws with whatever row `0x1A` holds, which is now Pyron's medallion palette, so its pixels go from steel blue-white `(153,170,221)` to orange-gold `(255,136,34)` and, on Donovan's own gold-and-red costume, read as the sword being ABSENT. The grey ramp was the PRE-62k state, before a medallion lived in that row. **A partial fix is IMPOSSIBLE (measured): sword and medallion draw from THE SAME entries of row `0x1A` — 23 shared colours — so the row cannot be split by pen.** **VALIDATED ON THE BOARD (maintainer, 2026-08-29): "Confirmed, the sword is
actually orange, and only on the select wheel screen, this is a good
tradeoff. The fix is validated."** The scope confirmation matters as much as
the verdict: the trade is CONFINED TO THE SELECT SCREEN — no in-match
surface — which is what the thunk's site (`PRG:0x05F9D0`, the select figure
uploader) predicts and the board now measures. MEASURED: row `0x1A` holds Pyron's vs2 palette across the whole select with P2 on Donovan; P1's accent on row `0x17` byte-for-byte unchanged; **`38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select` BIT-IDENTICAL to merged18** (the changed path runs only on a P2 tenant hover, which no legacy replay does) — note `38` is the exact replay whose one-main-loop slip forced the 14z-88 revert of the previous attempt. Gate: **`tests/test_pyron_medallion_2p.sh`**, two legs, verified to FAIL on merged18 and PASS on merged19. **It closes a real coverage gap:** `test_wheel_bank5` 3b's two protocols are both SINGLE-PLAYER, so it could never see this and stayed green through every freeze. **NOT FROZEN — a freeze is a separate decision** |
| **#112 Press of Death black foot** (Donovan's EX foot super) | DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA; why a tenant runs that vanilla sequence is unknown. Entry point when resumed: DISASSEMBLE the effect spawn, never scan |
| ~~**RANDOM SELECT should include the three tenants**~~ — ADDED TO THE LIST by the maintainer 2026-08-28; **BUILT 14z-117 at the maintainer's word ("do the random-select includes the tenants then"), gated (`test_random_select_tenants.sh`: draw = 15 vanilla + this build's tenants; confirm on a tenant frame loads the tenant's own record; must-fire control), frozen as merged-m13 (M11); FIELD VERDICT GREEN on the board (maintainer, MiSTer, 2026-08-29, STATE 14z-118)** | DONE 14z-117 — TWO sites, not one: the walker re-reads the table on its non-tick frames (`select_screen.md` "THE WALKER HAS TWO PATHS"); a bound-only thunk crashed the figure refresh with a code byte as id | the "?" cell walks a FIXED 15-entry table at `PRG:0x020C88` (`04 07 02 0C 05 0F 0A 00 0E 03 08 01 0D 09 06` = the base-half roster minus `0x0B`), 3-frame cursor, wrap `cmpi.b #$f`. Both bounds hard -> a tenant can never come up. **The siblings are the precedent**: vsav2's twin table (`PRG:0x01F8B4`) lists `10 11 13`, vhunt2's too — including the newcomers is what the source games do. FIX SHAPE: 18-entry relocated table + bound `#$f` -> `#$12`; it cannot grow in place (15 bytes + 1 pad, then code at `0x020C98`) and the table is read PC-relative, so it is a `site_thunk` on `PRG:0x020C80` + a `code` op, not a data poke. COST TO WATCH: the added cycles land on the select screen, whose legacy replays are already the bounded-window class — measure the onset before and after |
| **MARIONETTE — a vs2 character, PARKED UNTIL FURTHER NOTICE (maintainer, 2026-08-28)** | not ported, not planned | **Assets live in VS2, not in VS.** She is not in Vampire Savior at all, so nothing in our romset is missing or broken by her absence. The maintainer's framing, and it is the right one: **Marionette and Shadow are both just MIRROR-MATCH MECHANISMS** — the shared machinery at `PRG:0x009BB2` copies the opponent's id and palette, so "playing as" either is playing the opponent's character. That makes porting her a low-value item: it adds a second route to a mirror match, not a character. **Not before everything else.** If it is ever revisited, note that vs2's arming counter is the SAME single `#$5` check as vsavj's (`PRG:0x01F8D6`), so whatever arms her in vs2 is a different mechanism and has not been located |
| **Oboro's intro eats into the round** | **DECLINED by the maintainer 2026-08-28 — do NOT delay round start or cut the intro** | recorded so it is not revived: it would be a match-state TIMING change on a shared path for a cosmetic reason, which is the trade the superset invariant exists to refuse. The maintainer will instead check whether vsavj's Oboro has an alternate SHORT intro |
| (#113 first-down white-out) | **not ours** — vanilla in vsavj AND vsav2 | pending only the maintainer's MiSTer double-check, then it closes |

**THE ARCADE HIDDEN-CHARACTER ROSTER — CONFIRMED BY THE MAINTAINER
2026-08-28.** Exactly THREE exist in the arcade game: **Oboro Bishamon,
Dark Gallon and Shadow.** *(First stated as four including Marionette, then
corrected by the maintainer within the hour: **Marionette is a Vampire
Savior 2 character, not a Vampire Savior one**, and the "7 START presses"
code belongs to vs2. Recorded because the ROM agreed with the correction
before it arrived — see the Shadow row.)* *The alternate Lilith, Aulbath and
Victor are CONSOLE-PORT ONLY* — which independently confirms the 14z-116
table measurement (the only variant datasets in any of the three ROMs are
our three tenants plus two Oboros; there is no Lilith/Victor/Aulbath
alternate anywhere). Status of each on our build, all measured 14z-116:
- **Oboro `0x18`** — shipping, ours, gated (`test_oboro_select.sh`), field-confirmed 14z-105. **CAUTION for the maintainer's floated idea of removing the hold-START hook "since Oboro and Dark Gallon were already in VS" (2026-08-28): that is true of DARK GALLON and NOT of OBORO.** Measured 14z-116: the only immediate writes of a character id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — **no vanilla path anywhere writes `0x18` to `$382`.** vsavj ships Oboro's DATA complete (record `0x0B3450`, own palette block, 20 distinct bank rows) but no player-facing select path, which is precisely why 14z-105 added one. Removing the hook would make Oboro UNREACHABLE again; Dark Gallon would survive untouched, since that path is vanilla's own.
- **Dark Gallon `0x12`** — vanilla's own path (Gallon + START + 2-3 punches *or* 2-3 kicks, `PRG:0x020B9C`); our Oboro hook displaces that block's first instruction and re-executes it, so it is preserved BY CONSTRUCTION. Statically certain, **never played** — the maintainer is field-testing it.
- **FIELD VERDICT ON M9 (maintainer, MiSTer, 2026-08-28): "everything seems
  right... the new character wheel already looks almost perfect on CRT,
  Shadow works as intended, Dark Gallon is properly selectable with hold
  start + 3 punches at the same time. All seems perfectly fine."** So the
  E2 wheel is CRT-confirmed, Shadow is confirmed working on silicon, and
  **DARK GALLON IS CONFIRMED PLAYABLE** — which also validates the 14z-116
  static decode of `PRG:0x020C18` (the trigger accepts `0x300`/`0x500`/
  `0x600`/`0x700`, i.e. two OR three punches; the board used three).
  **TWO THINGS HE COULD NOT TEST IN ~2 HOURS OF TRYING, AND BOTH ARE
  STRUCTURALLY IMPOSSIBLE — the time was spent on things that cannot
  happen. Measured, so nobody spends another two hours:**
  1. **A tenant from RANDOM SELECT.** Already measured this session: the
     "?" draw is a fixed 15-entry table (`PRG:0x020C88`) holding no
     variant-half id, bound `cmpi.b #$f`. It is not luck, it cannot occur.
  2. **SHADOW vs a tenant, in 1P arcade.** NEW measurement: scanning ladder
     table A (`PRG:0x00B268`, 36 rows x 8 groups, reachable indices 0-5 —
     the scan bound `$FF8138` is 6) for a tenant candidate returns **rows
     16, 17 and 19 ONLY — i.e. classes `0x10`/`0x11`/`0x13`, the tenants'
     own rows.** A tenant appears as a CPU opponent *only when the player is
     a tenant* (which is exactly the shape of the #99 field crash: Donovan
     1P -> CPU Phobos). **Shadow's own pool is rows 32-34** (`0x800 +
     $3BD*8`) **and contains no tenant in any group.** So Shadow can never
     draw one from the ladder, however long you play.
  **HOW TO TEST IT ON THE BOARD:** 2P VERSUS — P2 picks the tenant with the
  sticks, P1 does the Shadow code. That is exactly what the emulator rig
  does (`tests/replays/113_shadow_vs_tenant.rpl`), and it is the only route
  either implementation has to that matchup.
  **-> DONE, AND GREEN (maintainer, MiSTer, 2026-08-28): "Shadow works
  perfectly even with the VS2 tenants in 2P vs, so that's a win."** The
  board agrees with the emulator leg on the one case that mattered, so the
  Shadow-vs-tenant question is CLOSED on both implementations.
- **NO LEGACY CHARACTER EVER MEETS A TENANT IN 1P ARCADE — RULED NOT A
  PROBLEM (maintainer, 2026-08-28): "not a problem since we're way focused
  on 2p vs". CLOSED, no work planned.** Kept as a measured fact because it
  explains field observations rather than because it needs fixing.** Rows `0x00-0x0F`
  contain no reachable tenant candidate at all, so a 1P run as Morrigan (or
  anyone vanilla) can never be scheduled against Donovan, Phobos or Pyron.
  The port authored the tenants' OWN rows (what they fight) and never added
  them to anyone else's. This is the same family as the random-select item
  and arguably more noticeable in play — a player's whole arcade experience
  never shows the new characters unless they pick one. **Not built, not
  scoped, no recommendation without a ruling**, and it is a GAMEPLAY-FEEL
  change (who you fight, and the ladder is already a lottery), so it is the
  maintainer's call per CLAUDE.md 5.
- **TENANT CPU AI LOOKS "LACKLUSTER" — maintainer observation (2026-08-28),
  UNPROVEN, DEPRIORITISED.** Verbatim: *"when I do fight against any of the
  VS2 tenants it seems their AI is lackluster to say the least and I'm
  pretty sure that's a side effect of the port although I can't prove it...
  but once again, we're 2P vs focused."* Recorded rather than investigated,
  with the archaeology a future session would start from so it is not
  re-derived: the four per-class AI action-script tables
  (`PRG:0x0BF01A/09A/11A/19A`) are **16 classes THEN THE SAME 16 REPEATED**
  (Capcom's aliasing guard), which is what made CPU-Phobos play DEMITRI's
  AI and was the root cause of #99; 14z-111 fixed it by making each
  tenant's OWN vs2 AI script block a data root (option A, zero code). So
  the tenants do have their own scripts now — but whether those scripts are
  as *deep* as a legacy character's on this engine has never been measured,
  and "feels weaker" is not a measurement. **If it is ever picked up, the
  first question is whether the ported script blocks are COMPLETE** (a
  truncated block would present exactly like this), not whether the tables
  are aliased. CPU-side only — 2P versus never reads them ([VSE-75]).
- **SHADOW vs A TENANT — MEASURED AND GREEN (14z-116).** The maintainer's
  question ("the big problem is not selecting him, it's knowing whether the
  game breaks", INCLUDING "does Shadow take the SHELL character instead of
  the tenant") was answered by a RUN, not by disassembly. Rig:
  `tests/replays/113_shadow_vs_tenant.rpl`, gate `tests/test_shadow_tenant.sh`
  (emulator tier, ~6 min, two runs, must-fire control). **RESULT: Shadow
  takes the TENANT.** P1 armed the code (5 START presses on "?"), beat P2
  Donovan, and at the round end flipped `0x00 -> 0x13` with the loader
  installing **Donovan's own record `0x003FA9D0`** — not Victor's
  `0x0009769E`, the shell `0x13` aliases, which is exactly the quiet failure
  the gate is written to catch. HUD reads "Donovan", art is his, and the run
  is **guard-clean END 21120** across several further morphs.
  **TWO CORRECTIONS TO MY OWN EARLIER STATIC PASS, both from this run:**
  (1) `PRG:0x009BB2` is NOT match init — it is the ROUND/MATCH-END path
  (`$13A`/`$13C` are the winner/loser pointers), so **Shadow does not keep a
  pick, he takes the character he just beat, round by round**; (2) arming
  alone leaves you playing the roulette's pick rendering NORMALLY (measured:
  Bulleta, no silhouette), so what produces the black-silhouette
  presentation on this Japan set is still unestablished — it blocks nothing.
- **Shadow** — present and vanilla: exactly 5 START presses on the "?" cell then any attack button (`select_screen.md`), which matches the community code instruction for instruction. The mechanism copies the OPPONENT's id and palette **UNMASKED** at `PRG:0x009BB2`, and every table the copied id then indexes is 32 rows with our tenant rows populated, **so Shadow-copying a TENANT is structurally expected to work**. Never run — this is the `coverage_matrix` "morphing INTO a tenant" cell, and it now has a mechanism attached rather than an unknown.


## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
