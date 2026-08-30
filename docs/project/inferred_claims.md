# inferred_claims — the LIVE worklist of the documentation rationalization pass (14z-122)

> **STATUS (14z-122):** LIVE. Every claim found INFERRED rather than measured
> in the hand-written docs, with the measurement that answers it and its
> cost. Maintainer ruling: every row is RE-MEASURED before its document's
> commit lands; a row needing the board / a playtest / testimony is
> retracted into that file's "What is NOT known" instead (ruled fallback).
> Supersedes `doc_audit_14z118.md` as the live worklist (that file is the
> 14z-118 pass's LOG and does not change). HIST-classed docs were not
> swept — a superseded record's claims are not live carriers. The pass log
> (one line per commit, with its retraction grep) accretes at the bottom.
>
> Classes: GUESSED · DERIVED-UNMEASURED (static decode, path never observed
> live) · STALE-CARRIER (measured elsewhere; this copy stale — a [VSP-13]
> fix) · TESTIMONY (human observation; labelled, not re-measured) ·
> ESTIMATE. Costs: T0 citation-only · T1 static/log re-read · T2 re-run an
> existing rig with a new assertion · T3 new rig + frozen expectation ·
> T4 board/maintainer (→ "What is NOT known", per the ruling).
> Line numbers @ commit `55eb42b`.

## Rows, grouped by the document commit that consumes them

### G1 (9) — the atlas commits

| # | claim (quoted) | file:line | class | measurement that answers it | existing rig/gate | cost | status |
|---|---|---|---|---|---|---|---|
| 1 | "+0x161 accumulator … Live only for an Aulba[th victim]" — the whole +0x15B/+0x15E/+0x161/+0x162 family: static decode, arming path never observed live ("+0x15E = 0 on every frame of every naming and victim rig") | `docs/game/atlas/ram.md:146-148`; `docs/game/engine_internals.md:898` | DERIVED-UNMEASURED | an Aulbath-VICTIM rig with Dark Force ACTIVE (poke `$FF8509`, assert `$FF802E`=1 per [VSP-123]); write-tap `+0x15E/+0x161/+0x162` on the victim through contacts; freeze the accumulate/threshold shape | `tests/replays/df/97_df_mech.rpl` family + `audit_df_framework.sh` DF-entry mechanics; `trace_writes.lua` | T3 | OPEN |
| 2 | "`rec8`/`byte2d` rows whose per-id entry LAYOUT is unverified" | `docs/game/atlas/id_space.md:62,393`; `docs/project/tenant_manifest.md:140` | STALE-CARRIER (partial) | rec8_b HAS a decoded consumer since 14z-121 (2): the PURSUIT physics record pair `0x0BE3FA + id*0x20`, reader `0x026646` (`bank_map.toml:384` note); rec8_a is a SLICE of jump_params (`bank_map.toml:245`). Cite; `byte2d`/`auto` gaps stay genuinely unverified — reword to name only those | `bank_map.toml` notes; `test_charmap_current` | T0 | **MEASURED — closed 14z-122 (7/9): rule 5 and both id_space carriers reworded; rec8's consumers cited** |
| 3 | `PRG:0x04FAC4` — "recorded as a corrected error — which reading is current?" (audit §2 item 7, never closed) | `docs/game/atlas/id_space.md:174` vs `docs/game/gotchas.md:501` | STALE-CARRIER? | re-read both carriers against the DATA view once: id_space says the fold is real but "nothing structural" (32-row table); gotchas records the retracted "16-row" misread. Confirm they agree and add the doc-lock's `also` row already covers it — then close audit item 7 in writing | `checkdocs` row `id_fold_site`; `build/out/vsavj_data.bin` | T1 | **MEASURED 14z-122 (T1): both carriers re-read — they AGREE (32-row table, fold real, DATA view; the doc-lock `id_fold_site` + `also` covers the pair). Audit §2 item 7 closed** |
| 4 | "$FF8127 … a per-frame COMPARATOR of the two fighters' object byte +0x10 … Open: what object byte +0x10 is" (14z-118 (16) leftover) | `docs/game/atlas/ram.md:102` | DERIVED-UNMEASURED | write-tap object `+0x10` on both fighters across one match (spawn → contact → down) and name the byte from its writers | `trace_writes.lua` / `read_tap.lua` on any 2P replay | T2 | OPEN |
| 5 | slot 0x0B "(Shadow/Marionette machinery?)" guess marked UNCONFIRMED in the table row while the 14z-116 decode sits directly below it | `docs/game/atlas/character_tables.md:284` (vs :295-300) | STALE-CARRIER | none — the same file already carries the measured answer ("the ? RANDOM cell", every mechanism decoded); the row cell cites it | — | T0 | **FIXED 14z-122 (9): the cell cites the 14z-116 decode** |
| 6 | "copying a TENANT is structurally expected to work — and it has never been run" | `docs/game/atlas/select_screen.md:401` | STALE-CARRIER | none — it WAS run 14z-116: `tests/test_shadow_tenant.sh` (Shadow beats tenant Donovan, becomes id 0x13 with Donovan's OWN record `0x003FA9D0`, guard-clean END 21120), CRT-confirmed 2026-08-28. The sentence contradicts a green gate | `test_shadow_tenant.sh` | T0 | **FIXED 14z-122 (9): corrected in place with the gate citation** |

### G2/G3 — measurements feeding engine_internals

| # | claim | file:line | class | measurement | rig/gate | cost | status |
|---|---|---|---|---|---|---|---|
| 7 | attract-palette writers "(vsavj 0xB0AC attract path, table 0x3A3CA0 …) not yet repointed — if the attract demo shows wrong Donovan colors, that is the mechanism" + "UNVERIFIED … nobody has re-measured it since M2b"; bounded DERIVED 14z-118 (9) ("a tenant-vs-tenant VS screen in 1P would show the placeholder ramp … Not measured on screen") | `docs/game/engine_internals.md:262-276,303` | DERIVED-UNMEASURED | reach the one reachable surface: 1P arcade AS a tenant until the CPU draws a tenant (ladder rows 16/17/19), snapshot the VS screen, compare the ramp at `0x3A3CA0 + id*32` vs what renders | `snapshot_frames.lua` + the venue byte `$FF8121` steer (`audit_don_vs_cpu.sh` mechanics) | T3 | OPEN |
| 8 | the throw MASH-ESCAPE step family `0x27082`/`0x2797A` — "the shape of a THROW MASH-ESCAPE pushing the thrower away (read, not measured — 14z-121 (4))" | `docs/game/engine_internals.md:870` | DERIVED-UNMEASURED | a throw rig where the VICTIM mashes: tap `+0x170` (mash counter), `+0x185`, the x steps against the `0x2797A` lists; freeze the escape shape | `name_moves.py` victim-rig pattern + `trace_writes.lua`; already a named NEXT_SESSION open | T3 | OPEN |
| 9 | "The original maintainer report (ping #7, the fuchsia class) … was most likely fixed there" | `docs/game/engine_internals.md:3909` | GUESSED | run the grenade-ground rig on the CURRENT build vs native at matched pose; `audit_empty_tiles` on that replay; a clean A/B closes the guess with a citation | `tests/replays/hui/83d_hui_grenade_ground.rpl`; `audit_empty_tiles.sh` | T2 | OPEN |
| 10 | the DF section's superseded 14z-79 blockquote ("the DF palette is OPEN … mechanics are still unproven") kept under a header already corrected 14z-114 | `docs/game/engine_internals.md:3151-3173` | STALE-CARRIER | none — mechanics were measured 14z-101/104 (`audit_df_framework.sh`, frozen durations/cost); the blockquote is history material for `engine_internals_history.md`; the live sentence cites the gate | `audit_df_framework.sh` | T0 | OPEN |
| 11 | white-frame mechanism "(palette RAM blanked vs a CPS-B layer/priority register) is NOT measured; only the framebuffer is" | `docs/game/engine_internals.md:2887` | TESTIMONY/PARKED | NONE THIS PASS — #113 is maintainer-parked pending their camera evidence ("do not re-derive"); the sentence is an honest boundary and stays as "What is NOT known" | `test_down_flash_vanilla.sh` (the framebuffer half) | T4 | RULED-PARKED (maintainer, 2026-08-28) |

### G6 — HANDOFF

| # | claim | file:line | class | measurement | rig/gate | cost | status |
|---|---|---|---|---|---|---|---|
| 12 | "probably `0xAA-0xAD` Anakaris — the one character the rig could not put into DF" | `HANDOFF.md:997` | STALE-CARRIER | none — RETRACTED 14z-118 (9)/(14): DF on, zero palette-seq calls for Anakaris; the corpus census froze `0xAA-0xAD` as SASQUATCH's (`tests/expected/df_palette_seq_census.txt`) | `audit_palette_seq_ids.sh` + the frozen census | T0 | OPEN |
| 13 | "H/P anim movability is inferred from the manifests, not measured — a 'runs' verdict for them needs a liveness control first" | `HANDOFF.md:1595-1598` (= `audit_region_movability.sh` header) | DERIVED-UNMEASURED | run the audit's H/P legs with the liveness control its own header specifies (prove the moved region EXECUTES on the leg, then the runs/crash verdict) | `tests/audit_region_movability.sh` | T2 | OPEN |
| 14 | "Merged+legacy+AUTO is UNMEASURED (its one attempt mashed past the KO — void)" | `HANDOFF.md:2078-2082` (= `audit_win_pal_auto.sh` header) | DERIVED-UNMEASURED | re-run the audit with a merged+LEGACY+AUTO leg whose inputs END AT THE KO (the documented rig rule); freeze COLORED | `tests/audit_win_pal_auto.sh` + replay 103/104 pattern | T2 | OPEN |
| 15 | `test_pyron_blink` native-leg guard reads `+0x382` in match — "a borrow there yields a false REFUSE … Fix = gate on `+0x60.l`, blocked on freezing our tenant hitbox bases" — the blocker is STALE: the bases ARE frozen (`tests/expected/.../bases.tsv`, re-derived every freeze since 14z-100) | `HANDOFF.md:2615-2622`; GitHub #16 | STALE-CARRIER (blocker) + T2 fix | switch the guard to the `+0x60.l` hitbox-base signature (the `audit_legacy_pairings` signature) and re-run the gate once | `tests/test_pyron_blink.sh`; `bases.tsv` | T2 | OPEN |

### Small fixes elsewhere

| # | claim | file:line | class | measurement | cost | status |
|---|---|---|---|---|---|---|
| 16 | "`0x0448a6→0x02563e` (0.94): SUSPECT — likely WRONG SIBLING" — written as live while the entry's own tail derives "Right answer: `0x04367A`" and #107 SHIPPED that flip at 14z-102 (`patch_index.md:210` "verified") | `docs/project/hardening_register.md:73` | STALE-CARRIER | none — mark the entry RESOLVED-AND-SHIPPED with the 14z-102 citation (status header tracks reality) | T0 | OPEN |

### What is NOT known — labelled unknowns that stay labelled (no measurement this pass)

- **MSC-71** "That real CPS-2 silicon decrypts only the first 1 MB — INFERRED, never measured" (`mister_core.md:881`) — T4 hardware; already lives in the §12 holes ledger, which IS the "What is NOT known" form. No change.
- **MSC-72** the 128 MB module's chip-select polarity — INFERRED from jtframe RTL (`mister_core.md:882`, `platform/mister.md:532`) — T4; already flagged. No change.
- **`0xD153E` consumer family** "likely in-match intro/win" (`engine_internals.md:447`) — kept as a labelled unknown by 14z-118 (row 9); stays.
- **`$130(a5)` trigger** "plausibly ending/gallery content" (`venue_assets.md:159`) — bounded by static zero-refs + twelve playtest rounds; stays labelled.
- **~56K vsav2-only tiles** "attribution to characters pending the OBJ tile-code inventory" (`engine_internals.md:125`) — a census nobody needs yet; stays labelled.

### Not rows (triage notes)

- The three gotchas buckets' hedge hits are recorded PAST errors (the entries' purpose) — no rows.
- `reconciliation.md:140/:307/:529` hedges live in the session chronology that the G0 specimen moves verbatim to `reconciliation_history.md` — history is not re-measured.
- HIST-classed docs (M3b_plan, mister_scope, skills_scope, beam_port_scope, audit_2026-08-15_dispositions, M1/M2, playtest_m3a_interims, quartus_brief) not swept: superseded records.
- `platform/mister.md:1271` (EEPROM first-boot phase hypothesis) is a triage-card hypothesis, labelled as such in a symptom table — not a claim a reader acts on.
- ESTIMATE class: the 14z-118 pass already dropped the runtime-extrapolation lines it could find (its row 8); the `~N min` figures that remain sit in gate-header runtime hints, which are operational hints, not claims — sampled, no rows.

## The pass log (one line per commit, with its retraction grep)

*(accretes as document commits land; empty at open)*
- 14z-122 (9): atlas retags + rows 2/3/5/6 closed. Grep for the retired
  claims: `grep -rn "and it has never been run" docs` -> only the struck
  original inside its own correction; `grep -rn "(Shadow/Marionette machinery?)" docs`
  -> the retired-guess cell + the decoded block it cites.
- 14z-122 (post-close 4-11): the G1 document commits — see STATE 14z-122
  (post-close). Retraction greps per commit are in the commit bodies; the
  headline: `grep -rn "and it has never been run" docs` -> only the struck
  original inside its own correction (select_screen.md).
