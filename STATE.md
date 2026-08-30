# STATE — living progress log

## Session 14z-123 (2026-08-30) — **THE DOCUMENTATION RATIONALIZATION PASS CONTINUES. T1 (the annotations check,
## maintainer-ruled check-first) MEASURED — outcome B, a REAL GAP: `re/ghidra/` never held a project, and the 14z-122
## retirement note ("the stream lives in the atlas + manifest comments") was FALSE — 2,921 program-space addresses across
## five carrier kinds, ~220 named only in engine_internals prose, 265 only in code. `docs/annotations.md` CREATED as a
## GENERATED index (`tools/gen_annotations.py`, gate `test_annotations_current`); the CLAUDE.md row RETURNED. No build changed.**

| | |
|---|---|
| opened with | the 14z-122 close (2); NEXT_SESSION's order: T1 → G2 → G3 → T2s → G4 → G6 → CLAUDE.md condensing → G7 |
| **T1, measured** | `re/ghidra/`: a `.keep` + the M0 README ("exported annotations" would live here — none ever were; `git log --all` shows one commit, M0). The carriers, counted by distinct program-space address (`0x001000-0x3FFFFF`; HIST/EXEMPT/GENERATED docs and `probe_*.toml` excluded): atlas **438**, engine_internals **602** (~220 in NO other document), other reference docs **940**, manifests **1,756**, code (`tools/`, `tests/`) **818** — union **2,921**, of which **265 are CODE-ONLY** (named by a gate or tool and by no document or manifest). So the stream exists, scattered across five kinds of carrier, and no single place answers "what is `PRG:0x027038`?" — the maintainer's CREATE branch |
| the shape chosen | GENERATED, not hand-written (a sixth copy would drift — the project's own doctrine; the GOTCHAS-index pattern): `tools/gen_annotations.py` renders one row per address with the carrier FILE and SECTION (or manifest `name =` row) in tier order; **no line numbers by design** (they churn on every unrelated edit and would make the currency gate a tax on every commit); a `vs2`/`vh2` hint when the line named the sibling set; RAM excluded (`ram.md` IS the RAM stream); the tail section = the code-only list, kept visible as the documentation gap. `tests/test_annotations_current.sh` (ci_portable): `--check` + four must-fire controls on a synthetic root (fresh passes; a new address fails until regenerated and lands under its section; a hand-edit fails; a code-only address lands in the gap section). The tool and the gate exclude THEMSELVES as carriers (their synthetic control addresses had leaked into the gap list — caught on the first run: 2,921 → 2,925 → 2,921) |
| the row | CLAUDE.md §5's struck row is LIVE again, describing the generated document and carrying the measurement; `docs/README.md` entry; HANDOFF gate row; `doc_shape.tsv` GENERATED row; `inferred_claims.md` row 17 closed + pass log |
| green | `test_annotations_current` PASS; checkdocshape (6 PENDING unchanged); checkdocs 19 locks; checkskills 425; census 427 `--check`; portable tier **60 PASS / 0 FAIL** (+1). [VSP-13] grep for the false note (`"lives in .docs/game/atlas/. and the manifests"`) → only the pass-log line quoting the grep |
| **row 16** | `hardening_register.md`: the `0x0448a6` headline read SUSPECT above its own shipped status — RESOLVED (14z-102, #107) in place; the analysis kept |
| **G3 (b) — `engine_internals.md` :1689-2947** (drawer, AI scripts, class-02/jump/air, palette dispatch, effects, WIN SCREEN, type dispatch + hit-class map, allocators, seeding, queue, capture-pose, throw arcs, damage, white frame, judge) | the history twin `docs/game/engine_internals_history.md` OPENED (HIST; joins checkskills' VSE LOG list as `_GAME_LOGS`); **10 narrative blocks (99 lines) moved VERBATIM** — the win-screen opener and its two 14z-73 retractions, the quote system's INDEX-SPACE misdiagnosis, the hit-class map's "ADOPTED, not pending" + the falsified two-replay deadness narrative + its RETRACTED blockquote, the capture installer's superseded reading + "MEASURED FEASIBLE" framing, the +0x1D→+0x17 correction note — each replaced by the FACT with an `[M: gate, session]` tag and a pointer to the history; the quote subsection gains its STATUS (forgone, clean route only); `:770`'s `+0x1C` line cites the readers table; **every `##` in the range now carries Atlas rows + Gates** (every cited gate asserted to exist); one em-dash header made parenthetical. The REFERENCE-class preview lint: 23 session-shaped headers remain, ALL in (a)/(c) ranges. `project/gotchas.md`'s `+0x1C` carrier re-grepped — already clean since the G1 retitle |
| **G2 #2 — the attract-palette / VS-screen claim (row 7): RETRACTED on both counts, REFINED to the roulette tag** | a fork built `tests/test_ladder_tenant_vs_palette.sh` (+ `tests/expected/ladder_tenant_vs_palette.txt`, replay `111_don_arcade_vs_screen` = 110 cut at 3600; evidence `build/vs_pal_14z123/`): `PRG:0x00B094-0x00B0B4` is the 1P OPPONENT-ROULETTE screen's palette load — once per ladder match (`$FF8008 == 0x0008`, frame 2416), pool row `0x3A3CA0 + id*32` → OBJ palette row `0x0A`; a red-poke A/B shows row `0x0A` colours ONLY the tag's mini character art (bbox (123,56)-(171,72)), 0 px on the VS screen; the 2P path never runs it; the 1P-vs-CPU-Phobos VS screen is PIXEL-IDENTICAL to the 2P Donovan-vs-Phobos one in both portrait regions. The pool ships byte-identical to vsavj; row `0x13` is the grey ramp, `0x10`/`0x11` are real palettes of the same bank (indexed from `0x3A3C00`). WHAT IS WRONG: the roulette tag reads "BULLETA" with Bulleta's mini-art in row `0x10`'s brown ramp for CPU Phobos (a 4-bit-folded consumer, PC unattributed) — single-player, tenant-plays-1P only, cosmetic → the COSMETIC BACKLOG row below. Carriers corrected in place: engine_internals (the M2b paragraph + the 14z-114 UNVERIFIED note), id_space ×2. Not reached: Pyron/Donovan as CPU opponents on screen |
| **G2 #1 — the "Aulbath-victim" DF accumulator (row 1): the MECHANISM CONFIRMED live, the CHARACTER RETRACTED — it is SASQUATCH'S DARK FORCE ARMOR** | a fork built `tests/audit_df_accumulator.sh` (+ `tools/df_accumulator_check.py`, replay `df/105_df_sas_armor` = 97's prologue with P1 Sasquatch / P2 Victor poked in the early window, `tests/expected/df_accumulator.txt` 9 frozen lines; four MAME legs, ~3 min; evidence `build/df_accum_14z123/`): the 0x200-arming state vsavj `PRG:0x047E60` is row 0x0A of `dispatch_16` (`PRG:0x0BF31A`, the seq-0x16 DF activation dispatch) — the 14z-121 "Aulbath's block" read the NEXT table's (`0xD9538`) head addresses as code boundaries. LP+LK / MP+MK activation → sub-state 2 → at the chain's end `+0x15E` = 0x200, `+0x18F` clear (`PRG:0x047EDA`); HP+HK (`+0x122` = 0x4400) → sub-state 4, never arms. Armed: cr.LP +20 / cr.MP +30 / cr.HP +40 into `+0x161`, decay 240, NO reaction, damage 5/12 (vs 4/10 unarmored); the contact carrying the sum past 60 reacts normally and clears; DF end clears all. Aulbath's DF arms the OTHER family (`PRG:0x045FAA`: 0x7FFF with `+0x18F` = 1, full armor, no accumulator); "four 0x7FFF sites" undercounted (engine 4 + character blocks 5). Merged build byte-identical to pristine (superset control). vs2 has no Sasquatch — no native leg. Carriers corrected: the readers-table cell, `ram.md` `+0x15E`/`+0x161` rows, the 14z-121 (3) STATE row marked in place; two gotchas filed. Not reached: the CPU-side choice, the node-+0xB armor exception |
| **G2 #3 — the "throw mash-escape" step family (row 8): RETRACTED — it is the ADVANCING GUARD (guard push)** | a fork built `tests/test_advancing_guard.sh` (+ `tools/advancing_guard.py`, `tests/expected/advancing_guard.txt` 44 frozen lines over 4 legs × 8 events; the rig = `name_moves.py` `DONOVAN_VICTIM` part 4 with new `block()`/`mash()` recipes, replay `naming/donovan_victim_4`; `test_reactions.sh` now filters `PHASE2_PARTS`; evidence `build/advancing_guard_14z123/`): a grounded BLOCK (class `0xFF`, handler `0x2246E`, state `0x0202`, `+0x140` = 2) opens a 14-tick window `+0x1AB`; each NEW button press (`+0x126 & 0x77`, directions never) feeds `+0x170`; at the threshold the check (`0x267B8`, vsavj `0x275CE`) arms the ATTACKER (`+0x185` = 1, `+0x1B0` = 0, `+0x5D` = flip_x ^ 1, `+0x59` = the press's strength class) and `0x27082` pushes it AWAY 91/115/157 px (lists byte-identical: vsavj `PRG:0x027E2E` / `PRG:0x02871C`; 9/9 fired events MATCH the data-view bytes per frame on both games). The games differ in the threshold: vs2 weights 1/2/3 per press, fires at >= 10 (light-only mash cannot); vsavj +1 per press, below 8 an RNG roll against `PRG:0x028D50` (3: 8/32 … 6+: always). Anakaris skipped by both. NO throw opens the window (Victor's 6MP hold, Sharirum Luna: `+0x1AB` = 0 throughout). Carriers corrected: engine_internals (the sentence → the mechanism), `ram.md` (`+0x1B0` + five new rows), STATE 14z-121 (4) marked in place; four rig gotchas filed (near-pinned first event lands in the intro; two engine ticks per video frame; a cornered blocker transfers pushback; mash recipes must release). Not traced: `+0x171`'s consumer, `+0x3B5` = 4 |
| next | the two T2 forks (rows 13/14/15; rows 4/9) still running; G3 (a) NOW (all three G2 measurements in) |

## Session 14z-122 CLOSE (2) — ritual complete for the CONTINUED session. **Two new rulings recorded: the
## annotations row is now CHECK-FIRST (stored elsewhere / unnecessary / else CREATE the document), and THE
## CLAUDE.md CONDENSING PASS is a named item ("more concise and to the point ... without losing precious
## information, especially on the work style and discipline") — both in "Decisions pending". G1 done (the
## post-close entry below); NEXT_SESSION rotated through its rollover. 10 commits LOCAL past `f7d4781`.**

## Session 14z-122 (post-close, same day) — **G1 EXECUTED after the specimen's ratification ("it's good"): eight
## document commits — patch_index folded, patch_notes reordered move-only, build_dir_triage / tenant_manifest /
## cps2_wide split to history twins, sfx_records + tables/README flipped, the atlas retagged (the Shadow-vs-tenant
## contradiction CORRECTED; rec8 graduated), the three gotchas buckets retitled REGISTER. 6 docs remain PENDING —
## all G2-gated or big-session items. PUSHED through the ratification commit; the post-close commits are LOCAL.**

| | |
|---|---|
| unblocked by | the maintainer's three answers (2026-08-30): the SPECIMEN ratified ("it's good"); the annotations-row question answered (awaiting the ruling); PUSH executed at `f7d4781` |
| the commits (4-11) | patch_index: eleven out-of-order `## 14z-N additions` sections -> ONE named-patches registry (row accounting exact; the first fold attempt crashed BEFORE writing while its TSV flip applied — the INDEX class masked the unfolded file until a grep caught it, the [VSP-40] shape); patch_notes: 61 whole blocks to newest-session-first + a topic index, body sorted-sha BYTE-IDENTICAL (move-only, asserted); build_dir_triage 444->114 (policy + latest sweep live; the 14z-101 package + A1-C inventory + old sweeps -> `_history`); tenant_manifest (single-tenant-era narrative -> twin; rule 5 names only `byte2d`+`auto` — rec8 GRADUATED 14z-121); sfx_records needed NO text change (the lint proved it); tables/README's build names re-pointed (the 14z-119 sweep had missed the prose); the ATLAS: ram/venue retitles, select_screen:401 "never been run" CORRECTED against the green `test_shadow_tenant` (six sessions of contradiction), character_tables' "?"-cell guess RETIRED, id_space's rec8 rows reworded; the GOTCHAS buckets: 16 session-batch titles -> topical `(paid: 14z-N)` form, wrapped headers taught to the lint, RE-FILED tombstones allowed by name, index regenerated; cps2_wide: the B4 attempt-1 + diagnostic-path narratives -> twin (anchors asserted absent from the moved spans), the spec whole |
| the lint's own harvest | commit 8 briefly landed on a RED lint (a `\| tail -1` ate the status — [VSP-112]'s pipeline trap, in the very pass built to catch staleness); fixed forward, and every later commit captures tool exit statuses directly. The gotchas retitle's FIRST pass mangled five wrapped headers — caught by the printed before/after review, reverted, redone wrap-aware |
| inferred_claims | rows 2/3/5/6 CLOSED (T0/T1); the pass log accretes in the file; OPEN: the three T3 rigs (Aulbath-victim DF accumulator, attract-palette surface, throw mash-escape), the T2s (object byte +0x10, region-movability H/P legs, win_pal merged+legacy+AUTO, grenade A/B, pyron_blink guard switch), HANDOFF rows 12-15 (ride G6) |
| green | portable tier at close of the block (see below); census 427 (re-frozen thrice for reviewed section renames); checkdocs 19 locks; checkskills 425; docshape 6 PENDING (README, HANDOFF, engine_internals, platform/mister, mister_core, mister_map) |
| next | G2 FIRST (the three T3 measurements gate engine_internals); then G3 (engine_internals, three commits); G4 (mister pair); G6 (HANDOFF); G7 close (`--no-pending`, the ci floor). The worklist: `docs/project/inferred_claims.md` + the NEXT_SESSION opener |

## Session 14z-122 CLOSE — ritual complete. **THE DOCUMENTATION RATIONALIZATION PASS OPENED (the maintainer's
## first future item): the five enforcement tools (T1-T5) SHIPPED and green; the SPECIMEN restructure
## (tables/reconciliation.md) done for the maintainer's review; NEXT_SESSION split (56 live lines); the
## inferred-claim inventory (16 rows); the SECOND future item (Zabel j.LK proximity guard) RECORDED, not
## started. No build changed. NOT pushed.**

| | |
|---|---|
| opened with | the 14z-121 close (`abad01d`, pushed); the maintainer's two future items: (1) the documentation rationalization pass — "documentation should be rationalized and to the point"; logs kept but not as reference; some files carry duplication and INFERRED claims; (2) Zabel j.LK proximity guard, a surgical vanilla+WIDE patch, its OWN session |
| rulings taken (maintainer, this session) | scope = ALL hand-written docs, one commit per document; chronology moves VERBATIM to `<name>_history.md` twins; `patch_notes.md` stays a log (index + whole-block reorder only); **every INFERRED claim is RE-MEASURED** before its document's commit (board/playtest/testimony rows retract into "What is NOT known" — the ruled fallback); gate WHY narratives go into the gate scripts' own headers; all five enforcement additions in scope |
| **T1-T5, the enforcement (each its own commit, each with must-fire controls)** | `test_doc_anchor_census` (every `**[PFX-N]**` anchor's FILE+SECTION frozen — checkskills accepts a between-file move SILENTLY, proved on the real tree); checkdocs KEY LIVENESS (a reflow can no longer disarm NO-RIVAL silently; 3 new locks: byte-41 `0xFE`, `66,265,152`, wheel record `PRG:0x272A68` — the plan's guess 0x272A92 was wrong, the tree decides); checkskills HISTORY rule (no anchors in `_history.md` LOG twins) + the gate's FILES list DERIVED; `test_docshape` (`docs/doc_shape.tsv` classes every doc REFERENCE/REGISTER/LOG/HIST/ORIENT/INDEX/GENERATED/EXEMPT/PENDING; session-shaped headers barred from REFERENCE docs; links + quoted-section citations verified); `test_gotchas_index_current` (`docs/GOTCHAS.md` GENERATED from the buckets' `##` headers — 353 entries; the hand-written index + its ten session digests verbatim in `GOTCHAS_history.md`) |
| **what the new gates caught on day one** | 26 session-shaped headers (venue_assets + the THREE gotchas buckets carry session-batch titles — re-classed PENDING, their retitling is now a pass item); **CLAUDE.md §5 promised `docs/annotations.md`, a file `git log --all` has NEVER seen** — row struck with a dated retirement note, **OPEN TO VETO** (recreate it and the row returns); three stale quoted-section citations; hardening_register:58 retitled; the [VSP-13] echo of the annotations mention in my own T4 row |
| **G0** | the SPECIMEN: `tables/reconciliation.md` 658→182 lines (STATUS banner, methods kept, THE MAP AT A GLANCE measured from the toml — 272 rows: 220 verified / 12 plausible / 40 open, the damage-pipeline twin table, sound rows' three classes with "RESTORE AT M5" corrected as SUPERSEDED by 14z-86, twin-choice case law, What is NOT known); chronology :71-658 BYTE-VERBATIM in `reconciliation_history.md`. NEXT_SESSION → 56 live lines + `NEXT_SESSION_HISTORY.md` (18 openers; the rollover is now part of this ritual). `docs/project/inferred_claims.md` — 16 rows + 5 labelled unknowns (T0×6 T1×1 T2×5 T3×3 T4×2; the fork's draft spot-checked 8/8); two live contradictions found: select_screen:401 "never been run" vs the green `test_shadow_tenant` since 14z-116, and hardening_register:73's stale SUSPECT headline (#107 shipped the flip at 14z-102) |
| green at close | portable tier **59 PASS / 0 FAIL** (+4 gates); census 427 anchors; checkdocs 19 locks / 50 sites; checkskills 425; the full static tier (ROMDIR) `--strict` **PASS 120 / SKIP 0 / FAIL 0 / MISSING 0** (run concurrently with the close edits — its dirty-tree note is those edits, and the four doc gates were re-run green after them) |
| not done, by design | the remaining document commits (G1: patch_index, patch_notes index, build_dir_triage, tenant_manifest, sfx_records+tables/README, the atlas retags, cps2_wide; the gotchas retitling; G2 measurements before engine_internals; G4 mister; G6 HANDOFF; G7 close) — the maintainer should READ THE SPECIMEN first; the plan's per-file table is in the session plan file, the live worklist in `inferred_claims.md` |
| open to veto | ~~the CLAUDE.md annotations-row retirement~~ **RULED (maintainer, 2026-08-30): CHECK FIRST — "we need to check if the information is either stored elsewhere or unnecessary. If it is necessary and not easily available then we should absolutely create the document." The check (T1, next session's opener): what an address→label/comment STREAM would hold vs what exists — the atlas (per-address rows with labels+evidence), the manifests' inline comments, and `re/ghidra/` (CLAUDE.md §3 names a Ghidra project — does it hold a label export?). Outcome A: covered → the retirement stands, reworded to say WHERE; outcome B: a gap → create `docs/annotations.md` for real and the row returns.** ~~the specimen's shape~~ **DECIDED (maintainer, 2026-08-30): "it's good" — ratified; anchored documents moved (the post-close block)** |
| push | NOT pushed — push at the maintainer's word |

## Session 14z-122 (2026-08-30) — **THE TWO FUTURE ITEMS RULED: the documentation rationalization pass (opened,
## tooling-first) and the Zabel j.LK proximity-guard patch (recorded in "Decisions pending", its own session).**

| | |
|---|---|
| the brief, in substance | docs are largely/entirely logs in places; logs are fine (STATE/DECISIONS history keep them) but browsing logs for one fact is orders of magnitude slower for humans and agents; a previous effort built the current hierarchy; since then files were appended with discovery logs, duplication exists, and some claims were INFERRED not measured |
| the survey (three read-only agents) | ~36.5k non-generated lines; five files = 49%; the log-shape/duplication/lock maps that shaped the plan (byte-41 paragraph ×3, `66,265,152` in 7 files, `+0x1C` in three states at once, the D2 window with NO engine_internals section) |
| sequence | Zabel item recorded FIRST (this file + the NEXT_SESSION opener) so it survives any close; then T1..T5, the specimen, the split, the inventory — the CLOSE row above |

**Ledger rollover:** the 14z-119 group (two records) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-120 / 14z-121 / 14z-122.


## Session 14z-121 CLOSE — ritual complete. **ONE DAY, FROM THE M12 VERDICT TO THE CHARACTER PAGES: the board
## verdict GREEN; the Killshread ruling; the phase-3 remainder (the record decoded from its readers, the decoder
## bound bug behind the "unindexed nodes", every projectile's parameters, the gap rows); the open list worked down
## (the pushback = a STEP TABLE on record +0xC; Killshread (ES) measured; the air-attack height table; +0x1A);
## the map's residue; the map's carriers; the three CHARACTER PAGES as artifacts and the INTERNAL pages with
## sprites, outlined boxes and detached hits, regenerable from a user's own dumps. No build changed. PUSHED.**

| | |
|---|---|
| opened with | the 14z-120 close (`127a621`); the maintainer's M12 verdict and the Killshread ruling |
| delivered, in order | (1) verdict + ruling; (2) phase-3 remainder; (3) the open list; (4) the residue; (5) the map's carriers + the public character pages (artifacts Donovan `85d7fd52…` / Huitzil `f0dddc83…` / Pyron `ad618f12…`); (6) the internal pages with sprites; (7) boxes outlined over the sprite, projectiles named by move, the user-regeneration script, output above the tree; (7b) the detached-hit class (Press of Death's foot) |
| retractions this session ([VSP-13], each grepped) | "+0x1C scales the pushback"; "each tenant's reaction set is its OWN table"; "the slide is the pushbox separation, not a velocity"; the "unindexed lying/wake nodes / computed address"; "+0x392 meter candidate" |
| green at close | portable tier GREEN after every commit; `test_move_naming` x3, `test_reactions` x3, `test_anim_node_walk`, `test_hitbox_encoding`, `test_projectile_params`, `test_killshread_es`, `test_charmap_current`, `test_tables_current` — all PASS on the committed tree. The strict static tier was not re-run at the close (no build or manifest row of the build changed; `bank_map.toml` gained only `note` keys, `test_tables_current` PASS) |
| not gated | the internal pages (a re-run of `tools/charpages_internal.sh` is the check); the sprite renders are checked by eye on seven frames, never against a MAME snapshot |
| open | the a2 mid-chain ENTRY index picker; the throw mash-escape step family (`0x27082`); the `x2b7ef4` effect-tail residue; the Aulbath accumulator's threshold fork; the cosmetic backlog unchanged |
| rollover | the 14z-118 group (five records) moved verbatim to STATE_HISTORY + one ledger line; STATE holds 14z-119 / 14z-120 / 14z-121 |
| push | PUSHED at the maintainer's word through `abb1476`; this close pushed with it |

## Session 14z-121 (7) — **THE MAINTAINER'S THREE + ONE ON THE INTERNAL PAGES: the boxes OUTLINED over the sprite in
## one drawing (world→screen calibrated: `KX=64, KY=262`); projectiles named by their MOVE with the type and handler
## kept; `tools/charpages_internal.sh` regenerates the pages from a user's OWN dumps (audits, builds, captures, renders);
## the pages now live ABOVE the working tree (`../charpages/`). No build changed.**

| | |
|---|---|
| the overlay | `sprite_capture.lua` now writes a `C<frame>` line (both fighters' world x/y, the camera `$FF8290`, P1's facing); `sprite_render.py` writes a sidecar JSON per PNG (crop origin + those values); `charmap_html.py --sprites` composes ONE SVG per chain — the sprite `<image>` at its crop origin and the hurt/push/hit boxes as OUTLINED rects in the same OBJ-screen space: box centre = (`KX + (p1x − cam) − bx`, `KY − (p1y + by)`) (authored facing left, P1 faces right). Calibrated by eye on Donovan's walk/5LP/5HP/2LK captures with PIL overlays (`build/p3_sprites_14z121/cal/ov*.png`): `KX=48` sat 16 px left; `KX=64` (the CPS OBJ x offset) fits, `KY=262` puts the feet on the ground. The plain box diagram stays beside it |
| projectiles by move | `charmap_gen` joins the census (`tests/expected/projectile_census.txt`) into `structures.projectile[type].moves`; the map page and both HTML pages show "Sol Smasher (`0x40`) · `0x672d0`" — the move, the type and the address |
| the user's own dumps | `tools/charpages_internal.sh` step 0: `audit_roms` against `docs/checksums.txt` (stop on mismatch), `setup_mame.sh` when the pinned binary is absent, `build_wide_romset.py` when `build/wide0` is absent, the three solo builds by the HANDOFF four-track recipe when their extracts are absent; then A-E as before. Output `${CHARPAGES_OUT:-../charpages}` |
| above the tree | `../charpages/` (sibling of the repo, like the field bundles) — nothing under it can be added, committed or pushed from this repository; `build/charpages/` removed |
| verified | the three pages built (composites: Donovan 63 / Huitzil 53 / Pyron 49); the overlays checked on four Donovan frames. The full script not re-run end to end after the prerequisites block was added (`sh -n` clean; every step ran individually this session) |
| **(7b) the DETACHED hit (maintainer: Press of Death's box is on the foot, not the fighter)** | a class, not a one-off: the foot, the flying Killshread, every projectile, Huitzil's mine and launcher hit through an object P1 OWNS. `sprite_capture.lua` now lists P1's owned pool objects per frame (`$FFB800` x 0x80 and `$FF9400` x 0x100, `+0x30` owner = `$8400`; type, position, node, `hb8/hbA`); `tools/charpages_frames.py` (`pick` / `choose`) replaces the inline picker: a chain with no attack node gets PROBE frames to +120 f and the frame chosen is the first where an owned object carries a record with REAL power (the foot's first record is a dormant power-0 placeholder for its whole flight — `(-3,-173,44,6)` = the landing spot, class 0); the renderer keeps entries near any owned object (and never the other fighter's); the page draws each owned object's `hitbox_proj` record at the object. Checked by eye: Press of Death (the descending foot, record 6 `(-1,-48,38,54)`, class 0x50), Blizzard Sword (the snowflake, record 1), Plasma Trap (the mine dome, record 5, class 0x52). 33 moves render at an object frame |

## Session 14z-121 (6) — **THE INTERNAL CHARACTER PAGES WITH SPRITES (maintainer: "for our internal, unpublished
## documentation, adding the sprites would be nice"): every move's sprite at its first active frame, captured from the
## native game's OWN OBJ list and palette page on the naming rigs and drawn from vsav2's tiles — 165 sprites, three
## pages under `build/charpages/` (untracked, unpublished). Pipeline `tools/charpages_internal.sh`. No build changed.**

| | |
|---|---|
| the route chosen | not a ROM-side renderer (the attr→palette-row mapping and the block row order were unread) but the emulator's truth: at the frame the naming rig reaches a move's first attack node, dump the OBJ list and the `$90C000` palette page (`tests/lua/sprite_capture.lua`, `obj_records_dump.lua` + the page), draw the character's entries from the zip's tiles (`tools/sprite_render.py`: `gfx_tiles` decode, attr flips/blocks, CPS-2 colour words, pen 15 transparent, entry 0 on top) |
| what separates the tenant's entries (the trap, `project/gotchas.md`) | the rigs are NATIVE vs2, so "group C" is not where the art is; the records' tile set (`obj_records.walk`, 15k within-bank codes) admitted the HUD and the downed opponent — settled by the OBJ bank table (`0x27530[id]` = `0x6000` = bank 3 for all three; the mid-screen entries agree), the y window (the HUD strips are bank 1 at the top/bottom), and the LEFT x-cluster (P1 pinned left of P2, facing right) |
| the frames | the picker over `field_trace` traces of all 24 naming parts: 328 (move, seq) frames, 177 at an attack node, 151 at a chain's first node; 165 distinct sprites after dedupe (Donovan 63 / Huitzil 53 / Pyron 49 embedded) |
| verified by eye | Donovan 5HP and Blizzard Sword (with Anita), Pyron Sol Smasher, Zodiac Fire, Huitzil 2HK — the character alone, the game's palette. Not measured against a MAME snapshot (an OBJ-to-pixel oracle would be the gate; deferred) |
| record | `tools/charpages_internal.sh` regenerates everything (~15 min); README row; HANDOFF row; `charmap_html.py --sprites`. Rendered art stays untracked and unpublished |

## Session 14z-121 (5) — **THE MAP'S CARRIERS: the projectile parameters are IN the map (`structures.projectile`, page
## section) and the hitbox summary's stale "+0x1C pushback scale" is gone; and THE CHARACTER PAGES — `tools/charmap_html.py`
## renders each tenant's map as a wiki-style HTML page (physics, every move with frame data / damage / boxes / notes,
## projectiles, reactions), committed as `chars/<tenant>.html` and published as artifacts. No build changed. Not pushed.**

| | |
|---|---|
| the map | `charmap_gen.py` gains `structures.projectile` (each census type's handler on vs2 and on the build, the decoded rows, `ours_source`); `charmap_md.py` renders "Projectile parameters (phase 3)" and the reactions blurb names the step-list release and the labelling rule; the hitbox `_encoding` sentence lists the fields by their readers. `test_charmap_current` PASS |
| the pages | `tools/charmap_html.py <tenant> <build> <out.html>` — reads only the map JSON, the move list, the extract's hitbox set and the frozen reaction lines; per move: name, input, kind, chain, startup/active/recovery/total (the map's derivation), damage/white, meter, class, pushback idx, freeze, the first active frame's hit/hurt/push boxes as an SVG (authored facing left, drawn facing right), the maintainer's notes; ES rows nest under their special. Design: night ground (dark-first, a moonlit-paper light theme), Marcellus / IBM Plex, the hitbox colours players know. Artifacts: Donovan `85d7fd52…`, Huitzil `f0dddc83…`, Pyron `ad618f12…` (URLs in `tables/README.md`) |
| not gated | the HTML is regenerated with the map by hand (README row); a currency gate would be `test_charmap_current`'s pattern — deferred until the page's shape settles with the maintainer |

## Session 14z-121 (4) — **THE CHARACTER-DATA MAP'S RESIDUE: Plasma Trap's chain is the JUMP PHASE (rising `0x2a` /
## apex `0x2b`, every strength — measured, part 9); Donovan's `0x3d` is `0x3c`'s loop body; the unentered a2 ids are
## entered by NO normal/6+button/3+button input (part 13, the negative frozen); `+0x392` is not an engine meter; the second
## step family reads as the throw mash-escape. Two naming parts added to the gate. No build changed. Not pushed.**

| | |
|---|---|
| **Plasma Trap** | Huitzil part 9 (`tests/replays/naming/huitzil_9.*`): early (right after take-off) `a2:0x2a`, late (apex) `a2:0x2b` for LK, MK and HK alike — the chain is the jump phase; the strength only sets the mine's distance (`projectile_params`: xv 1/2/3). TOML row note resolved; six lines appended to `move_naming_huitzil.txt` |
| **Donovan `0x3d`** | not an input: `a2:0x3c`'s last node LOOPS onto `0x3d`'s first node (`0x28521c`), so the transformation loop runs under `0x3c`'s label (deterministic labelling keeps continuity). TOML note resolved |
| **the unentered a2 ids** | Donovan part 13 (`donovan_13.*`): point-blank 5LP..5HK, 6LP/6MP/6HP/6LK/6MK, 3LP/3HP/3LK/3MK/3HK, 1HK — every one enters the plain chain (`a2:0x00..0x0a`, `0x0c/0x0e/0x0f/0x10/0x11`); `0x18-0x1d`, `0x24` and the odd standing ids stay unreached by any input tried (17 lines appended to `move_naming_donovan.txt` as the frozen negative) |
| **`+0x392`** | not an engine meter: its only writer in vs2's engine range is `0x4D0C0`, inside one character's code block (vs2 id 0x0C's), no engine reader — the ram.md "meter candidate" row retired; worklist row DONE |
| **the second step family** | **CORRECTED 14z-123 (`tests/test_advancing_guard.sh`): it is the ADVANCING GUARD — a grounded block opens the window, button presses feed `+0x170`, the ATTACKER is pushed 91/115/157 px; no throw opens it.** `0x27082` (three lists `0x2797A`: 91/115/157 px) runs while `+0x185` is set; `+0x185` is set on the OTHER fighter by `0x2681E` when the mash counter `+0x170` reaches 10 (with a facing flip) — the shape of a throw mash-escape; read, not measured. The block-contact tap saw only the walk movers (P2 holds R), so it stays unmeasured |
| gates | `test_move_naming` donovan + huitzil (parts 13 / 9 added); `test_charmap_current` (worklist rows: meter DONE, the a2 entry rule's select/advance named); portable tier |
| still open (small) | which code picks a mid-chain ENTRY index for a2; the throw-escape family's measurement; the `x2b7ef4` effect-tail residue (a build-attribution job) |

## Session 14z-121 (3) — **THE OPEN LIST WORKED DOWN: the pushback's real carrier is the record's `+0xC` (a PER-FRAME
## STEP TABLE, `0x2783C`, whose end releases the hold — 14z-120 (12)'s "pushbox separation, not a velocity" RETRACTED);
## Killshread (ES) MEASURED and gated (one wave after a plain plant, TWO after the ES); the `0x0BE23A` table = the minimum
## air-attack height (36 for Zabel/Lilith/Jedah, 0 for all others); `+0x1A`'s arithmetic read; the accumulator is an
## AULBATH-victim mechanic. No build changed. Not pushed.**

| | |
|---|---|
| **the pushback** | write tap on the victim's x through 5LP/5MP/5HP: light/medium are written by **`0x27038`** (5LP: `0x17D5C` = the separation routine for +0..+8 while the fighters overlapped, THEN `0x27038` from +26; 5MP: `0x27038` x16 from +9), heavy by `0x265DC` (the velocity integrator, `+0x40` = 2.9 px/f − 1/32 per frame). `0x27038`: `d0 = +0x59` → word list `0x2783C` (DATA view) → byte STEP list indexed by `+0x164`; `x += step` per frame (facing `+0x5D`); a negative byte ends it and returns 1 = **the hold release**. `+0x59` = the record's `+0xC` (hit) / `+0xD` (block) copied at `0x172DA`. Lists: idx 0 = 30 px/11 f (= 5LP measured), idx 1 = 51/16 (= 5MP), idx 2 = 80/20, idx 3 = 159/24, idx 7 = 140/20 … The 14z-120 (12) tap had watched only a light hit's overlap frames — corrected in place (engine_internals, STATE 14z-120 (12), the worklist; gotcha filed). `hitbox_records.py` now decodes `pb_hit/pb_blk/facing/freeze/scale/recov`; the maps' record tables carry the columns |
| **Killshread (ES)** | rig `name_moves.py` donovan part 12 (`tests/replays/naming/donovan_12.*`, P2 Victor idle at 176 px): plain plant → summon = ONE wave (LK +36/+38/+40, HK +129/+131/+134, class 1); ES plant (one stock) → summon = TWO waves (+31..+38 and +84/+86, the second ending in class 0x16 knockdown) — the maintainer's description, measured. Gate **`tests/test_killshread_es.sh`** (18 frozen lines + the wave-count shape); the naming gate skips part 12 |
| **`0x0BE23A`** | vsavj `0x027B80` (five state-code callers): a button press is refused while airborne below `+0x14 − +0x3A` < word[id] → the MINIMUM AIR-ATTACK HEIGHT: 36 for `0x04/0x0D/0x0F` (Zabel, Lilith, Jedah) and their variant mirrors, 0 for everyone else including the tenants. `bank_map.toml` note updated |
| **`+0x1A`** | the damage routine `0x175AE-0x176E0` read: scale index = victim-state term `0xD2ABE[id*0x20 + +0x3B3]` (+ `0xD32BE[id]` under `+0x1C3`) + the combo row (`+0x1A` ? `0x1841A/0x1801A[+0x1A]` : the attacker's own `0x18C1A/0x1881A[id]`; column = `+0x144` combo count, cap 0x1F) + a random term when the attacker leads on white HP; damage = LUT `0xD32DE[min(idx,0x20)*128 + power]` (negative idx → `0xD435E`), cap 0x7F |
| **the accumulator's owner** | **CORRECTED 14z-123 (`tests/audit_df_accumulator.sh`): it is SASQUATCH's Dark Force — `dispatch_16` row 0x0A — not Aulbath's; the block attribution below read the next table's heads as code boundaries.** every `+0x15E` arming site also sets `+0x18F`, which the accumulate path needs CLEAR; the only clear that keeps `+0x15E` armed is `0x4900A`, inside Aulbath's code block (vs2 blocks in id order per the DF table `0xD9538`: `0x471E8`..`0x49486`). A legacy-victim mechanic; the tenants' `+0x1C` bytes ride verbatim. The threshold fork stays OPEN, out of scope |
| green | `test_killshread_es` (frozen 18 lines) · `test_hitbox_encoding` · `test_charmap_current` · `test_move_naming` (donovan; part 12 skipped) · portable tier |
| still open | the second step family (`0x27082`/`0x2797A`, counter `+0x1B0`); the threshold fork; Plasma Trap's HK chain; Donovan's `0x3d` |

## Session 14z-121 (2) — **THE PHASE-3 REMAINDER, in one sitting: the attack record decoded from its READERS (`+0x1C` is
## NOT a pushback scale — RETRACTED — but a DARK-FORCE-armed accumulator against the bank row `byte15b` = 60); the
## "unindexed lying/wake nodes" were a DECODER BOUND BUG (table b cut at 18 of 139 entries — fixed, Huitzil re-frozen);
## every `$FF9400` projectile type's parameters DECODED and MEASURED (`test_projectile_params`, 29/29 live, ours == vs2 on
## three builds); the 17 `gap_*` bank rows RESOLVED by a reference scan (13 slices, the capture-keyframe pointer table,
## one real word table). No build changed. Not pushed.**

| | |
|---|---|
| **`+0x1C`** | its ONLY reader is vs2 `0x16B70`: `add.b $1c(a3),$161(a1)` with `+0x162 := 0xF0` (240 f decay, cleared by the tick `0x20E6A`), compared to `+0x15B` — loaded at init from the bank row **`byte15b` (`0x0BE87A`), 60 for every character in BOTH games** — gated on the victim's `+0x15E` armed, `+0x38` = 0, `+0x11F`/`+0x18F` clear. MEASURED: the accumulate PC never fired on any contact of the victim rig (only the clear at `0x16B9C`), `+0x15E` = 0 on every frame of every naming part and the victim parts, its writers (`0x2203A/0x22078/0x22282/0x3E928`, each with `+0x18F/+0x190/+0x143`) sit inside the per-character DARK FORCE handlers (`0x22008: jmp 0xD9538[id]` from the activation flow `0x26166`). The 14z-120 (6) "scales the pushback" correlation is RETRACTED ([VSP-13] grep: STATE rows, engine_internals header, charmap worklist); its real carrier is unread. OPEN: which characters' DF arm it and what the threshold fork (`0x170DE` / `0x16B94`) changes |
| **the record, by its readers** (static, vs2 `0x16930-0x175F6`) | `+0x13` = the HIT-FREEZE class (pairs table `0x17FA4`/`0x17FA6` hit/block → attacker `+0x5C`, victim `+0x5C`; the measured 11); `+0x1B` = the WHITE-DAMAGE RECOVERY-RATE class (`0x18018` → `+0x13A/+0x13B`, the refill at `0x20DF2`); `+0xE` = the victim's facing rule (→ `+0x5D`); `+0x1A` = a combo-scaling table selector (0 = the attacker's per-character table); `+0x14` meter confirmed (halved on block; the victim's 8 while `+0x144` < 12); `+0xC/+0xD` → `+0x59`, `+0xF` → `+0x5A`, `+0x19` → `+0x56`, `+0x1E` → `+0x1A4`, `+0x16` class 4→5, `+0x1D` node-byte-3 test; **`+0x11/+0x12/+0x15/+0x18/+0x1F` have NO reader in the hit code**. `engine_internals` "The attack record's fields, by their readers"; `ram.md` rows |
| **lying/wake nodes = a decoder bug** | the `+0x1C` (node pointer) write tap on the victim rigs: writers `0x2713C` (select) and `0x27222` (advance) only; the first `OFF:` node (`0x2484FE`) was entered by the SELECT with offset `0x622` into Huitzil's **table b** (`0x247EDC`, indices 42/45 = `b:0x2a/0x2d`). `anim_nodes.py` appended a word before testing the bound, so node word `0x0025` at index 129 collapsed the table to 18 entries (raw bound 139; Donovan's b 69 → 123 likewise). Fixed (odd / backward word ends the table); `test_anim_node_walk` PASS unchanged (3638/3638); maps regenerated (b/c 139 entries); `reactions_huitzil.txt` re-frozen — exactly the two `OFF:` lines (now `b:0x2d … b:0x56`, `b:0x3c/0x3e/0x40 … b:0x48`); Donovan/Pyron lines unchanged. `test_reactions.sh` gained `FREEZE=1`. Gotcha filed |
| **projectile parameters** | the `$FF9400` pool's walker is the SECOND table (vs2 `0x5C620`; `0x6A51C`'s Huitzil entries all point at a generic `jmp 0x157C2`): `0x3E→0x66EC4` (the known Blizzard region — positive control), `0x40/41/42 → 0x672D0/0x67550/0x67846`, `0x44..0x47 → 0x6800C/0x68458/0x68768/0x689CC`. `tools/projectile_params.py` decodes the one init shape (`+0x9A` 0/2/4/6 = LP/MP/HP/ES → `+0x26`, `+0x50`, an `(xv, xacc, yv, yacc)` record; Blizzard by `+0x0A*8`; Cosmo = state immediates). **`tests/test_projectile_params.sh`** PASS: rows frozen (`tests/expected/projectile_params.txt`), ours == vs2 on don_m18/pyron36/hui52 at the PLACED handlers (`verify_op.bin`; Pyron and Huitzil carry ALL of vs2's handler regions `x0672d0..x0689cc`), 29/29 live spawns match (five census rigs; one tick allowed; `+0x26` is a BYTE for five types and a WORD for Plasma Trap / Erasing Sphere — the live byte is its high byte), every tabled type measured, perturbed-row control fires |
| **the `gap_*` rows** | every absolute reference into `0x0BD800-0x0BEC60` in vsavj's code (25 sites; controls: `param32_a` at `0x0228E2/0x0271A8`, `jump_params` `0x027A76` read `id*0x30`, `param32_b` `0x026484`): 13 gap rows are SLICES of `param32_a`/`jump_params`/`param32_b`/`rec8_b` (`rec8_a` = `jump_params` rows 0-5); `gap_be27a+be2ba` = the 32-LONG capture-keyframe pointer table `0x0BE27A` ([VSE-44]'s installer); `gap_be23a` = a REAL per-char word table (airborne height threshold at `0x027B94`); `rec8_b` = the PURSUIT physics record pair (`0x0BE3FA + id*0x20`, `0x026646`, chain `a2:0x4C`). Recorded as `note` keys on the `bank_map.toml` rows (parsers tolerate them; the build reads no `note`), carried into the maps' bank tables by `charmap_gen`/`charmap_md`; worklist rows rewritten. `test_charmap_current` + `test_tables_current` PASS |
| **the reaction sets are SHARED, not per-tenant** | the re-freeze under deterministic labels (a node is on many chains; label = the previous node's chain, else the entering chain with the smallest seq) shows the three tenants' paths carry the SAME canonical seqs — light `b:0x03`, heavy `b:0x03 -> b:0x23`, sweep `b:0x09 -> 0x0a -> 0x0b -> b:0x44`, air `… b:0x2a -> b:0x14 -> … -> b:0x44`, stand `a:0x00`, block stance `a:0x13/0x14`; 14z-120 (7)'s "own table (c / b)" was the last-enumerated chain's label and is RETRACTED in place (engine_internals, STATE 14z-120 (7), NEXT_SESSION, the worklist). Pyron's `OFF:` block-stance nodes also resolve (`a:0x13`) |
| rigs that did NOT fire, deleted | a knocked-down-victim part (sweep + pursuits + OTG normals) twice: far pin — sweeps to the wall, every pursuit whiffed; mid pin — 3/6 sweeps, no pursuit. Removed from `name_moves.py` ([VSP-137]); gotcha filed. Evidence `build/p3_*_14z121/` |
| green | `test_projectile_params` PASS · `test_reactions` ×3 PASS (Huitzil re-frozen) · `test_anim_node_walk` PASS · `test_charmap_current` PASS · `test_tables_current` PASS · portable tier (below) |
| open | the DF-armed accumulator (which DFs, the threshold fork); the pushback correlation's real carrier; `+0x1A`'s arithmetic; the `0x0BE23A` height check; the Killshread (ES) two-way attack; Plasma Trap's HK chain; Donovan's `0x3d` |

## Session 14z-121 (2026-08-30) — **THE M12 BOARD VERDICT: GREEN ("all green", maintainer, MiSTer).
## Donovan's VS2 physics port behaves on silicon as on both emulators. And one move-list correction from
## the maintainer: Killshread Summon has NO ES (row dropped); the stance pair's ES is Killshread (ES),
## whose effect plays during the summon — the sword attacks both ways. No build changed.**

| | |
|---|---|
| opened with | the 14z-120 close (`127a621`, pushed); the maintainer: "M12 verdict: all green" + the Killshread ruling |
| the verdict | **FIELD VERDICT GREEN (maintainer, MiSTer, 2026-08-30, 14z-121): "all green"** on bundle `../mister_fieldtest_14z119/` (merged-m14 `6649523a`, tell "M12"). STOCK CONTROL not re-run (`.rbf` 18269 unchanged — once-per-`.rbf`). Validates on silicon the three physics value ops (`PRG:0x0BD912/0x0BDF0A/0x0BE392`) the emulators measured at the first-movement frame (STATE 14z-119). Still a person at a CRT ([MSV-31]) |
| the sweep ([VSP-13], the 14z-118 gotcha) | the "NOT YET FIELD-TESTED" twins marked in place: `mister_field.md` (§ bundles, the two verdict-table rows, §6), HANDOFF (playtest block + the 14z-119 registry row), `patch_index.md` (the physics row), `platform/mister.md`, `mister_core.md` §12, STATE 14z-119 header + three "open/not done" rows, NEXT_SESSION rewritten |
| **Killshread, ruled** | (1) `Killshread Summon (ES)` — NO ES, confirmed; the row is DROPPED from `moves_donovan.toml` (54 -> 53 rows). The rig keeps the 214KK-in-stance probe as the measured negative control (enters `0x47`, no stock), so `tests/expected/move_naming_donovan.txt` is unchanged. (2) **Killshread (ES)** (`a2:0x46`, the stance change with two kicks) IS the pair's ES, and its effect takes place DURING THE SUMMON: the returning Killshread attacks both going away AND coming back to Donovan, where the plain summon attacks one way only. Stated by the maintainer, not measured — recorded as such in the TOML row and `engine_internals` "Donovan's anim-chain map"; measuring it (the summon's attack records under the ES flag) is a phase-3 item if wanted |
| green | `test_move_naming` (donovan) on the 53-row TOML; `test_charmap_current` on the regenerated `donovan_anim.md`; portable tier (`checkdocs`, `checkskills`) |
| open | the phase-3 remainder and the other small naming opens (Donovan's `0x3d`, Plasma Trap's HK chain) — NEXT_SESSION |

## Session 14z-120 CLOSE — ritual complete. **ONE DAY, THE CHARACTER-DATA MAP FROM THE MOVE LISTS TO
## PHASE 3: the three move lists in the tree; every chain of the three tenants NAMED on native vs2
## (`test_move_naming`, 412 frozen lines, own-name and id checks); the hitbox encoding, the attack
## record and the reaction sets MEASURED (`test_hitbox_encoding`, `test_reactions`,
## `test_projectile_census`); the maps carry hitboxes, frame data and reactions. No build changed;
## strict 117/0/0/0; the M12 board test still running on the maintainer's side. PUSHED at close.**

| | |
|---|---|
| opened with | the 14z-119 close (`71192cc`, unpushed); the maintainer asked for the move-list format |
| delivered, in order | the move lists (Donovan / Pyron / Huitzil, 54 / 42 / 50 rows — Donovan 53 since 14z-121); the naming rig `tools/name_moves.py` and Donovan's 53 ids; the DF-cost ruling recorded (VS cost, DECIDED); Pyron's and Huitzil's naming (the mirrored-rig pass caught by the maintainer's Planet Burning challenge — position pins, facing byte, own-name row check + id check, swapped-seq control); phase 2 — the hitbox encoding, `+0x8C`/`+0x90`, the record's `+0x17` class (the "+0x1D" resolved), `+0x14` meter, `+0x1C` pushback; phase 3 — the reaction sets, the stun mechanism (freeze → chain → HOLD released by the pushbox separation settling), projectile parameters inline per type handler, the projectile-type census |
| green at close | `run_all_static --strict` **117/0/0/0**; emulator gates `test_move_naming` x3, `test_hitbox_encoding`, `test_reactions` x3, `test_projectile_census`, `test_charmap_current` — all PASS on the committed tree |
| corrections this session ([VSP-13], each grepped) | "no ES Planet Burning / 63214PP = Cosmo" (the rig facing left); "pairs trigger other ES trackers" (same); the class byte "+0x1D" (`engine_internals` 2538, `patch_notes` annotated); "+0x8C push / +0x90 attack" (`ram.md`); Genocide Vulcan 421+K → 421+P (maintainer-confirmed) |
| maintainer rulings | Dark Force at VS cost, on purpose (DECIDED); Genocide Vulcan = 421+P; Planet Burning ES confirmed as described and measured |
| not done, by absence | ~~the M12 board verdict (maintainer, in progress)~~ **GREEN 14z-121**; the phase-3 remainder (NEXT_SESSION); the small naming opens |
| next | NEXT_SESSION — the board verdict first; then the phase-3 remainder or whatever the map's findings suggest. Load `vampire-saved-port` first |

**Ledger rollover:** the 14z-117 group moved verbatim to STATE_HISTORY.md; STATE holds 14z-118 / 14z-119 / 14z-120.


## Session 14z-120 (7) — **PHASE 3 (reactions) — the tenants' REACTION SETS measured as the VICTIM: which
## of their own chains each class enters, the shared blockstun chain, the stun lengths as the engine ran
## them. `tools/reaction_map.py`, `tests/test_reactions.sh`, the maps' "Reactions as the victim". Not pushed.**

| | |
|---|---|
| the rig | `name_moves.py` tenants `<tenant>_victim`: P1 = Victor (forced 0x03), P2 = the tenant (the P2 early-window poke `ff8b82`); part 1 hits (5LP/5MP/5HP, 2LK/2MK/2HK, j.HP, the throw, a DP, a fireball), part 2 the same BLOCKED (P2 holds AWAY = R since it faces left), part 3 (Donovan) anti-air. `field_trace` on P2's node/class/freeze/HP; both ids asserted from the trace (id=3, p2id=0x13/0x10/0x11) |
| ~~**the reaction sets are per character, in the character's own table**~~ **RETRACTED 14z-121 (2): a last-writer-wins labelling artefact — deterministically labelled, all three tenants carry the SAME canonical `b:` seqs** | ~~Donovan and Huitzil: table `c`; Pyron: table `b`.~~ Donovan: class 1/2 (light, medium, low) `c:0x08 -> c:0x09`; class 4 (heavy) `c:0x08 -> 0x1f -> 0x20`; class 3 (sweep) `c:0x1c -> 0x1d -> 0x1e -> 0x19 -> 0x1a -> 0x1b -> b:0x44`; class 0x37 (air hit) `c:0x08 -> 0x11 -> 0x16 -> 0x17 -> 0x18 -> b:0x43`; throw `c:0x01`. Huitzil: `c:0x19 -> c:0x1c`, heavy `-> c:0x00..0x04`, sweep via `b:0x09 -> c:0x09/0x0a` then FOUR UNINDEXED nodes (`OFF:0x248AE2..`, linked lying/wake nodes no index table reaches). Pyron: `b:0x04`, heavy `b:0x78 -> b:0x23`, air `b:0x78 -> 0x41 -> 0x42 -> 0x56 -> 0x48`, sweep `b:0x40 -> 0x1a -> 0x56 -> 0x48`; his block stance is an unindexed node |
| **block and stun** | a block is class `0xFF` everywhere: the stance (`a:0x14` Donovan, `a:0x15` Huitzil) then the SHARED blockstun chain `b:0x0c` (one node, held). The reaction chains are HOLD chains ended by an engine counter, so the stun is NOT chain data — measured returns to a stand chain, IDENTICAL on the three tenants: light 19, medium 23, heavy 35, blocked 22/26 (light/heavy), blocked DP 18, blocked jump-in 19, low 24; the sweep knockdown 67-76, the air hit 61-69; freeze `+0x5C` = 11 on every contact |
| deliverables | `tools/reaction_map.py` (one line per contact: class, freeze, chain path `table:seq@node`, frames to return); `tests/expected/reactions_{donovan,huitzil,pyron}.txt` (20/19/19 contacts); `tests/test_reactions.sh` (rigs = regeneration, legs, ids, lines identical); the rigs under `tests/replays/naming/<tenant>_victim_<p>`; `charmap_md` "Reactions as the victim" (rendered from the frozen lines); `engine_internals` "Reactions as the victim"; the worklist row; HANDOFF gate row |
| **(8) how the stun runs** (same day, frame by frame on Donovan taking 5LP/5MP) | freeze first (`+0x5C` 11 -> 0 with the node timer HELD at 3), then ONE node of `c:0x08` (the walker leaves by a game-logic jump), `c:0x09`'s three nodes, and a HOLD on its last node (flag 0x40; `+0x21` 0x40 -> 0xFF); a light hit exits the hold at once (19 f), a medium ~5 frames later with the timer wrapping. The release counter is NOT in either fighter block nor `$FF3400-$FF35FF` (every byte/word sampled per frame — no monotone counter; only `+0x54`, `+0x05` = 2 and `+0x144` are set at the hit and cleared at the return) — OPEN. `engine_internals` "Reactions as the victim" |
| **(9) the hold's release = the pushback slide ending** | the victim's x moves from freeze-end to the return frame (light 30 px over +9..+17, medium 51 px over +10..+22, heavy still sliding at +35 with `+0x40` decaying) and the hold exits the frame the slide stops — hitstun beyond the chain = the pushback's duration = the record's `+0x1C`. The `+0x21` tap: HOLD set at vs2 `0x271E0` (`st.b`), released by a node SELECT at `0x2713C` (the game-logic jump); the slide's own counter is the open detail |
| **(10) projectile parameters** | Blizzard Sword: slot 3 of `$FF9400`, type 0x3E; spawn at vs2 `0x59E10` (`+0x9A` = attacker `+0x102` strength, placed at `(x+0x40, y+0x80)`), the TYPE HANDLER's init `0x6706A..0x670AE` reads `xv/yv = 0x670C0/0x670C4[strength*8]` — LP 6.0/−4.0, MP 7.0/−4.5, HP 8.0/−5.0 — fixed accelerations −0.0625 / +0.125; the tables are INLINE in the handler inside Donovan's ported region `x066ec4`. "Projectile records" = per-type handler data; a per-type decode remains. `engine_internals`; the worklist row |
| **(11) projectile-type census** | the 32 pool slots' type bytes sampled across the naming rigs: Donovan Blizzard `0x3E` only; Pyron Sol Smasher `0x40`/`0x41` (air), Cosmo `0x42`; Huitzil Launcher `0x44`, Plasma Trap `0x45`, Final Guardian `0x46`, Erasing Sphere `0x47` (421KK = `0x47` under either name); everything else spawns no pool object. `engine_internals` "Which moves spawn PROJECTILE-POOL objects" |
| ~~**(12) the slide is the PUSHBOX SEPARATION routine**~~ **RETRACTED 14z-121 (3): the tap saw only the overlap frames; the slide is the STEP TABLE `0x2783C[record +0xC]` stepped by `0x27038`** | ~~the only writer of the victim's x through a light hit is vs2 `0x17D30-0x17D7A`~~ (splits an overlap between the two fighters, or gives it to the one not cornered `+0x38`), driven by the reaction nodes' push boxes; `+0x40` stays 0 — no pushback velocity on light/medium. Reference push boxes at `0xA776C` read in the DATA view (the opcode view of a table is crypt noise — dumpops must use the program space for data) |
| open (phase 3) | ~~how `+0x1C` couples to the separation (unread)~~ **RESOLVED 14z-121 (2): it does not — its only reader is a DF-armed accumulator; the pushback reading is retracted**; ~~the unindexed lying/wake nodes~~ **14z-121 (2): table-b entries the decoder's bound had cut** (entered by game-logic jumps — the per-victim pose tables of [VSE-44] are the candidate source); projectile parameter records; the `gap_*` auto tables |


## Session 14z-120 (5) — **PHASE 2 OF THE CHARACTER-DATA MAP (maintainer: "push then do phase 2"):
## the hitbox encoding and the attack record MEASURED on native vs2 — boxes are (x, y, hw, hh) authored for
## the LEFT-facing sprite; +0x8C = attack / +0x90 = push (the community row had them crossed); the class
## byte is record +0x17 on every path (the "+0x1D" was the same byte counted from the region start).
## `tools/hitbox_records.py`, `tests/test_hitbox_encoding.sh`, the map's "Hitboxes and attack records"
## section and per-chain frame data. No build changed. Pushed up to `af729df`; the rest NOT pushed.**

| | |
|---|---|
| the instruments | `name_moves.py` parts 9 (walk to contact, 5LP/5MP/5HP/2MK/2HK, j.HP, a Blizzard at range, a 5MP ladder) and 10 (three Blizzards at range, Lightning Sword, Ifrit, Killshread + the column), both POKE-FREE so the `-debug` tap can replay them; `field_trace.lua` (positions, facing, node, box ids `+0x94`, the five table pointers, victim HP/class/freeze) and `trace_writes.lua` on the victim's `+0x50..+0x55` (PC + A3 at every HP/class write); opcode dumps around the writers disassembled with capstone |
| **tables** | `+0x60` = base = a table of word offsets from itself; `+0x80/84/88 = base+base[0..2]` (VULN 0/1/2), **`+0x8C = base+base[4]` = ATTACK records, `+0x90 = base+base[3]` = PUSH** (live pointers: `ff848c` = `0xC986A`); `+0x64` = the FAMILY table (`hitbox_comp`, 4 bytes {vuln0, vuln1, vuln2, push} per entry), indexed by the node's hb8 — `+0x94.l` equalled the entry on every frame. Sizes: Donovan 144 families / 200 records, Huitzil 72 / 364, Pyron 63 / 143 |
| **the box** | `(x, y, hw, hh)` signed words, centre at fighter `(x + x', y + y)`, **`x' = -x` when flip_x (+0x0B) = 1** — authored for the unflipped LEFT-facing sprite (a forward attack box has a negative x), half-extents, y up (ground 40). PROOF: 8/8 fighter hits (HP write frames from the tap) begin on the first frame the attack box overlaps a victim vuln box; zero whiff windows overlap (one extra overlap = 5MP's second record while the victim was in hitstun — the hit-id dedup); the un-mirrored convention matched 0/8 (the gate's negative control) |
| **the attack record** | selected by the node's `hbA >> 8` (0 = not attacking → a chain's ACTIVE nodes are those with hbA != 0; startup/recovery derived); 0x20 bytes: `+0` box, `+8` real power, `+9` white power, `+0x10` hit id, **`+0x17` reaction class**, `+0x1C` unexplained (0x14/0x1E/0x28 normals, 0x46 specials), `+0x1D` zero everywhere. Writers: the vs2 stager `0x16F5E` (a counter test forces class 1, else `move.b $17(a3),$54(a1)` at `0x16F70`; the special classes dispatch to immediates — `0x16FE4 #$4e` electric, `0x16FEC #$52` column, `0x16FF4 #$0a`); HP at `0x17444/0x17448` (`sub.w d4,$50/$52(a1)`); the object-hit applier `0x28A6A` takes `A3 = ($8C,a6) + id*0x20` from the owner's `hitbox_proj` records (table at `proj_base + proj_base[4]`) — Blizzard's record 1 (`+0x17` = 0x14) put 0x14 on the victim; Lightning Sword 0x4E, Ifrit 0x0A, the column 0x52, all = their record's +0x17 |
| **the "+0x1D" resolved** | the worklist's "class byte +0x17 vs +0x1D — the docs disagree": the shipped Huitzil rows `hitbox_proj +0x17D/+0x19D` (14z-85g) are byte +0x17 of projectile records 5 and 6 — the records start at region+0xC6, not the region start. The bytes patched were right; the wording was an offset from the wrong base. `engine_internals` 2538 corrected, `patch_notes` annotated, `project/gotchas.md` |
| deliverables | `tools/hitbox_records.py` (decoder: tables, family, boxes, attack + projectile records, `node_boxes(hb8, hbA)`, `placed()`/`overlap()`); `charmap_gen.py` "hitbox" structure (vs2 vs ours per record with region-label attribution — Donovan 20/200 records differ, 0 unattributed; the class remaps) + `charmap_md.py` "Hitboxes and attack records" table and, in `<tenant>_anim.md`, an `atk rec` column and a derived **startup · active · recovery** line per chain; the worklist rows 68/69/71 marked DONE (open: record `+0x1C` and `+0x11..+0x16`); `engine_internals` "Hitboxes and attack records"; `ram.md` rows `+0x0A/+0x60/+0x64/+0x80..+0x94` upgraded to [D] with the corrected mapping; HANDOFF gate row |
| gates | `test_hitbox_encoding.sh` (emulator, ~4 min): rigs, the four legs, the six assertions above + the negative control; `test_charmap_current` PASS on the regenerated maps |
| **(6) the open fields, by correlation** (same day; part 11 = the contacts BLOCKED, P2 holding away; fields: both bars, victim velocity/combo/freeze) | **`+0x14` = the attacker's meter gain on hit** (13 contacts across 7 records: 6/12/18 L/M/H normals, 3 per LS tick, 9 Ifrit, 2 column; a fraction on block; the victim gains 8 per hit, 0 on block); ~~**`+0x1C` scales the pushback** (27/41/59 px at 15 f for 0x14/0x1E/0x28)~~ **RETRACTED 14z-121 (2): `+0x1C`'s only reader never fired on these contacts; the correlation's carrier is unread**; observed only: `+0x12` = strength index, `+0x16` = 1 on specials/projectiles; `+0x11/+0x13/+0x15` open; a blocked contact writes class `0xFF`. In the tool, the map tables (`str`/`meter`/`spc`/`push` columns) and `engine_internals`. Rig lesson: P2 "holds back" = R when it faces left — the first block run had Victor walking INTO the attacks |


## Session 14z-120 (2) — **THE NAMING STEP FOR PYRON AND HUITZIL (maintainer: "do the Phobos and
## Pyron naming rigs"): 41 + 49 chain ids measured on native vs2, both TOMLs filled, the gate now
## covers the three tenants. Two findings for the maintainer: Genocide Vulcan answers to 421+P (the
## list's 421+K never fired); the guard cancel spent no banked stock natively. No build changed. NOT pushed.**

| | |
|---|---|
| the rigs | `tools/name_moves.py` gained tenant support (the forced-id poke `1400/1450/1500:ff8782:10|11`, the tenant's own extract for the chains, P2-side recipe tokens for the air throws and the guard-cancel setup) and PER-EVENT POSITION PINS: 40 frames before an event both fighters' X are poked (`far` 552/728, `near` 880/925) so P1 always faces right and no walk-in is needed. Pyron 4 parts, Huitzil 8 (parts 5-8 = the input search for Vulcan / the guard cancel / the grapple, kept as measured); all under `tests/replays/naming/` |
| **why the pins exist (the first pass, `project/gotchas.md`)** | after the first throw P2 stood behind P1 and every later motion measured its MIRROR — 623LP and 421LP entered the same chain, "Zodiac Fire" teleported, Cosmo Disruption read as a 63214 — visible only through the x delta and the by-strength pattern. Plus: a walk-in's trailing R + a motion's R = a dash tap. THEN THE PINS THEMSELVES BIT (the maintainer challenged the Planet Burning result — rightly): a poked near pair overlapped the pushboxes and the engine CROSSED the fighters five frames later, so every near event of the second pass faced left too; a near event is now the far pin + a walk-in + a pause (min gap 420), the facing byte `+0x0B` (1 = right) is sampled and `expect` marks left-facing events. RETRACTED with it: "a pair press is read by every ES tracker the half circle contains" and "no ES Planet Burning" — facing right, every pair enters the ES grapple |
| **Pyron, measured** | normals in Donovan's layout (`0x01` = Rushing Punch, the dash attack; Diving Punch `0x18-0x1a`); Sol Smasher ONE chain `0x26` (air `0x2a`) for every strength, its ES the same chains with class byte 16; Zodiac Fire `0x2e-0x30` + ES `0x31`, tail `0x35` (a ~180 px rush with attack boxes); Orbital Blaze `0x36-0x38` + ES `0x39`; Galaxy Trip ONE chain `0x3a -> 0x3b` for all twelve inputs (P = air, K = ground, L/M/H = distance: LP x−40 air, HP x+220 air, LK x−35, HK x+230); Cosmo Disruption `0x3c` (PP/KK, held/tapped); Piled Hell `0x45 -> 0x46 -> 0x47` ground and air; Corona Whip `0x1e -> 0x20`; Planet Burning `0x1e -> 0x21 -> 0x22`, its ES the same chains with class byte 16 (any two punches, up close, facing right); 63214+PP at range = nothing, so Cosmo's tracker discriminates the half circles; Galactic Throw `0x23`; pursuit `0x3f -> 0x40 -> 0x3d`, ES `-> 0x3e`; dash `0x24` both ways; Shining Gemini chain-less (2 stocks natively) |
| **Huitzil, measured** | the six 6+button alternates = the ODD standing ids `0x01,03,05,07,09,0b` (so Donovan's odd ids are his unused alternates); Plasma Beam P `0x44-0x46` / K `0x41-0x43` / ES `0x47-0x4a` after the wind-up `a:0x28`; Mighty Launcher `0x23` (air `0x24`), ES `0x51/0x52`; **Genocide Vulcan = 421+P** `0x25 -> 0x26|0x27 -> 0x28`, ES 421PP; 421KK = Erasing Sphere `0x40`; Plasma Trap `0x2a/0x2b` (by situation), ES `0x2c`; **Reflect Wall = the guard cancel `0x4c`** from `a:0x13` (block) `-> b:0x0c` (blockstun) for any punch, nothing in neutral, nothing with a kick, `+0x109` unchanged; Circuit Scrapper `0x1e -> 0x2d -> 0x2e -> 0x30 -> 0x31`, ES via `0x2f` (any pair); Magnet Slam `0x1e -> 0x1f` (MP) / `0x20` (HP); Sky Capture `0x4e`; Final Guardian Beta `0x33 -> 0x21 -> 0x34 -> 0x35 -> 0x39 -> 0x36`; pursuit `0x3a -> 0x3c`, ES `-> 0x3f`; Air Dash = the airborne chain `a:0x10` re-entered with class 20 (~260 px), Float = `a:0x12` re-entered and hanging; dashes `0x21/0x22`; Ray of Doom chain-less (2 stocks) |
| gates | `test_move_naming.sh` loops the three tenants (PARTS from the tool's schedule, per-tenant extract and expectation); expectations frozen `tests/expected/move_naming_{pyron,huitzil}.txt`; Donovan's rigs and expectation byte-identical after the tool changes (checked); `test_charmap_current` PASS with the labelled appendices (a2 named: Donovan 59/101, Huitzil 46/85, Pyron 41/75) |
| docs | engine_internals "Donovan's anim-chain map" extended with the two tenants; `project/gotchas.md` (the facing pin); HANDOFF gate row; both TOML headers carry the findings |
| **the cross-character check (maintainer-requested after the Planet Burning catch)** | Genocide Vulcan CONFIRMED 421+P by the maintainer. The gate now proves the data is not mixed between tenants: (1) `expect` asserts the sampled `$FF8782` at every event equals the tenant's id (0x13/0x11/0x10) and marks `WRONG-ID` otherwise — 0 of 412 lines; (2) step 5 requires every `table:seq` of a TOML row to be entered by an event NAMED FOR THAT ROW (longest-prefix match; the probes were renamed to their moves' real names), with a must-fire control (two rows with swapped seqs FAIL); each tenant's chains come from its own extract and its own expectation file. Donovan / Pyron / Huitzil: PASS |
| closed by the maintainer (2026-08-30) | the guard cancel's meter cost need not be measured. Context from the maintainer: vs2 has TWO Dark Forces — the common stat-improving one at 1 stock and the character-specific one at 2 — which is the "two stocks natively" the rigs saw; we run the character-specific DF at VS's cost on purpose (Decisions pending, DECIDED). Still open: Plasma Trap's HK chain (situation-dependent in the rig) |


## Session 14z-120 (2026-08-30) — **THE MOVE LISTS AND THE NAMING STEP (phase 1 of the character-data
## map): the maintainer's three lists transcribed to `build/manifest/moves_{donovan,pyron,huitzil}.toml`;
## Donovan's 53 chain ids MEASURED on native vs2 by a new rig (`tools/name_moves.py`, eight legs) and
## frozen by `tests/test_move_naming.sh`; the SWORDLESS normal set found. No build changed. NOT pushed.**

| | |
|---|---|
| opened with | the 14z-119 close (`71192cc`, unpushed); the maintainer asked for the move-list format, then gave the three lists |
| the lists | `moves_donovan.toml` (54 rows; 53 since 14z-121, the Summon (ES) row dropped), `moves_pyron.toml` (42), `moves_huitzil.toml` (50; display name Phobos). Conventions ruled by the maintainer and recorded in the Donovan header: ES = the special with two punches / two kicks, ANY pair; Dark Force = P+K same strength for everyone (listed for the name); guard cancel = 623P/K in blockstun for 1 stock (Ifrit / Zodiac Fire / Reflect Wall — the last GUARD-CANCEL-ONLY and, maintainer-corrected, WITHOUT an ES); Galaxy Trip six destinations, no ES; Phobos's six 6+button alternate attacks = six command normals; Air Dash / Float filed as movement. ES rows are SEPARATE rows because ES is separate content (STATE_HISTORY 14z-44: its own chain + its own attack records), re-confirmed below for every Donovan special |
| **the naming rig** | `tools/name_moves.py gen` lays a per-tenant schedule of input recipes (the cadences of rigs that already fired each move natively: 59 for 41236, 60 for 63214, 19 for 623, 48/56 for 421, 50 for 214, 27 for the throw) on replay 17's native-vs2 prologue; `tests/lua/field_trace.lua` samples P1's `obj+0x1C` per frame; `analyse`/`expect` map each pointer onto `tools/anim_nodes.py`'s graph and list the chains ENTERED per event ([VSE-47]: the chain is the measurement, never the input's name). Eight parts, ~30 s each headless, in parallel. Rigs committed under `tests/replays/naming/donovan_[1-8].{rpl,json}` |
| **measured (all in `donovan_anim.md`, labelled)** | table `a2` is the move table in input order: standing `0x00,02,04,06,08,0a`, crouching `0x0c-0x11`, jumping `0x12-0x17`; **SWORDLESS standing normals `0x1e-0x23` + crouching MP/HP `0x25/0x26`** (entered only with the sword planted; the other crouching + every jumping normal keep their chain; the sword specials and dive kicks are ABSENT swordless — the plain normal comes out); 6HK `0x27` (+ landing `0x63`); j.2LK/MK/HK `0x28/0x29/0x2a`; throw `0x2c` (4/6, MP/HP one chain); Ifrit `0x2d-0x2f` + ES `0x30`; Blizzard `0x31-0x33` + ES `0x34`; Lightning `0x35-0x37` + ES `0x38`, tail `0x39`; Press of Death `0x3a` (one chain, distance is a parameter); Change Immortal `0x3b -> 0x3c -> 0x3e -> 0x3f` (`0x3d` unreached); grapple `0x41`; Killshread LK `0x44` / MK,HK `0x43` / ES `0x46`; summon ground `0x47`, air `0x48`, NO ES (no stock spent); Lightning-in-stance `0x54-0x56` + ES `0x57`, tail `0x58`; dashes `0x49/0x4a` + end `0x4b`; pursuit `0x4c` (P = K), ES `0x4e`. Table `a`: idle `0x00`, walk `0x02/0x04`, crouch `0x09->0x01->0x06`, jump `0x0e->0x10->0x0f`. **Slay Shred has NO fighter chain**: idle re-entered, `$FF802E` up 25 f later, TWO stocks spent natively, 332 f long; normals inside DF unchanged |
| **positive controls** | Blizzard Sword HP entered vs2 `0x283E58` = the chain replay 59 recorded (14z-48); Lightning Sword ES entered `0x284A64` = replay 56's ES chain (14z-44); every ES/EX spent exactly one stock at its entry frame (`+0x109` sampled) |
| **paid for (project/gotchas.md)** | (1) `$FF8109` is a BINARY timer (99, one tick per ~82 f): a `0x99` "keep-alive" poke = 153 ENDED the round and every later event read UNFIRED; no poke needed, the generator asserts part length. (2) `63214` contains `214`: with the sword planted the grapple input is Killshread Lightning (`0x55/0x56`); the stance persisted a whole part (an air summon returned the sword, the next "summon back" re-planted it). (3) a facing flip inverts a button sequence's "4". Two refuted readings of `0x1e/0x21` on the way (close-range normals; DF-form normals), both by measurement |
| the gate | `tests/test_move_naming.sh` (emulator tier, ~2 min): rigs = regeneration; the eight legs; every event's entered-chain list == `tests/expected/move_naming_donovan.txt` (179 lines, identical on two independent runs); every `table:seq` in the TOML entered; negative control (a swapped line fails). Indexed in HANDOFF |
| docs | `engine_internals.md` "Donovan's anim-chain map" (under the walker section); `project/gotchas.md`; `charmap_md.py --anim` labels every named chain from the TOML ("Named chains: 59 of 101" on `a2`); `charmap_gen.py`'s "not decoded" row updated (the three maps regenerated, `test_charmap_current` green); HANDOFF gate row |
| open | Huitzil's and Pyron's naming rigs (the schedules are data in `name_moves.py`; recipes for Galaxy Trip's six destinations, the air throws, Float, the held EX inputs are new); Change Immortal's `0x3d` (the 2/8 control); the odd standing ids `0x01,03,05,07,09,0b` and `0x18-0x1d`, `0x24` (unentered — the maintainer may recognise them); ~~whether to drop the `Killshread Summon (ES)` row (measured: no ES)~~ **DROPPED 14z-121 (maintainer-confirmed; the ES effect is Killshread (ES)'s)** |



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

- Session 14z-119 CLOSE — THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (mark M12), the stock twin MOVED by design; strict 117/0/0/0; FIELD VERDICT GREEN 14z-121  [+1 more entries]  [rolled 14z-122 close]
- Session 14z-118 CLOSE (3) — the session's close. One day, four arcs: the M11 board verdict  [+4 more entries]  [rolled 14z-121 close]
- Session 14z-117 CLOSE (3) — the session's last act. The VS/VS2 data-architecture page CORRECTED from a row-by-row measurement after the maintainer read it; the next session is RULED: a full documentation audit — measured, consis… [+4 more entries]
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

- **THE CLAUDE.md CONDENSING PASS (maintainer-directed 2026-08-30, 14z-122
  close). RULED as a named item of the documentation pass; NOT started —
  "for a next session".** The maintainer's words, in substance: CLAUDE.md
  "has become very big and looks to have been extended like a log. This is
  not bad but wastes resources: we should plan a pass on it to remove
  duplicates if any and rewrite the contents in a more concise and to the
  point manner, without losing precious information, especially on the work
  style and discipline." Constraints the pass's tooling already enforces:
  CLAUDE.md carries **30 `**[VSP-N]**` anchors** (checkskills + the census
  freeze every one by section) and is a LOG for VSP skill numbers — every
  rewrite keeps each marker with its fact or moves the rule ([VSP-13]-grade
  discipline; the census diff is the review artifact). Shape suggestion to
  ratify at the pass: the LAW (rules 1-8, §4's classes, §5's standing
  orders) stays verbatim-precise; the CORRECTION NARRATIVES appended inside
  rules (the 14z-91/94/110b/114 stories) condense to the rule + a dated
  citation, with the narrative in the docs that already carry it. Slot:
  before G7 (the close bumps floors; the law should settle first).
- **ZABEL j.LK PROXIMITY GUARD — A LEGACY-CONTENT PATCH, ITS OWN SESSION
  (maintainer, 2026-08-30, 14z-122). RULED as the SECOND of two future items;
  not started.** The maintainer's report, in substance: Zabel's j.LK does not
  trigger proximity guard properly — "afaik it does, but not all the time it
  should, and definitely unlike any normal of any character". The ask: a
  SURGICAL patch for BOTH vanilla vsav and the WIDE build that corrects this
  and nothing else — no side effects. What that implies for the session that
  takes it: (1) it is a deliberate change to LEGACY behaviour, so by
  definition outside the superset invariant's "untouched" set — it needs its
  own ratified expectation class and its own build flag (CLAUDE.md §1/§4; a
  stock `vsav` patch is a NEW track, not the stock twin); (2) [VSP-20]
  first — a hand-played MAME recording of the whiff BEFORE any theory;
  (3) [VSP-14] — archaeology on "proximity guard" across STATE_HISTORY and
  the engine docs before measuring; (4) measure vanilla's proximity-guard
  test against every other normal (the maintainer's own comparison class)
  so the fix is bounded by a measured difference, not an impression.
  Recommendation: a data-side fix on Zabel's j.LK record (the guard-range or
  a record flag) if the difference is in his data; a code-side change only if
  the engine special-cases the move. Nothing decided beyond "its own session".
- **DARK FORCE STOCK COST FOR THE TENANTS (14z-120, found by the naming rig). DECIDED (maintainer, 2026-08-30): option (a) — the character-specific DF at VS (vanilla) cost is ON PURPOSE; "vanilla stays untouched and guides how the game should be played"; adjustments, if any, will be per character, never to the general mechanic.** On native vs2 Donovan's Slay Shred spends TWO stocks (`+0x109` 9 -> 7 at activation; Huitzil measured the same 14z-69); on our vsav engine every Dark Force, tenants included, spends ONE (the two engines run different DF systems, [VSE-69]). So a tenant's DF is cheaper here than at home. Options: (a) keep vsav's 1 stock — every character in this cabinet pays the same, "vanilla wins ties" [VSP-21]; (b) charge the tenants VS2's 2 stocks (a per-character cost hook the vsav engine does not have — new code on the DF path). **Recommendation: (a).** Note also (maintainer, 14z-120): Phobos's and Pyron's physics rows were CHECKED — `port_param32 = true` in both manifests and every value field of the 32-row bank equals VS2 for all three tenants (the map, `docs/project/tables/chars/*.json`; only relocated pointers differ). What the bank does NOT cover — throw-arc rows, hit-freeze tuning, the generation-drift class [VSE-6] — is phase 2's measurement.
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
| **Arcade ladder OPPONENT-ROULETTE TAG for a tenant opponent** (1P, tenant-plays-1P only — the CPU draws a tenant only on a tenant's ladder row) | measured 14z-123, not fixed | the tag shows the BASE character's name and mini-art (Phobos `0x10` → "BULLETA", a 4-bit-folded consumer, PC not attributed) drawn in pool row `PRG:0x3A3CA0 + id*32`'s own colours (a brown ramp for `0x10`; `0x13` is a grey ramp). The VS screen itself is correct (pixel-identical to the 2P path). Fix shape if ever wanted: author three pool rows (`0x3A3EA0/0x3A3EC0/0x3A3F00`, 32 bytes each, in a table vanilla never indexes past `0x0F` — legacy-invisible by construction) plus un-fold the tag's name/art consumer (its own measurement). Gate `tests/test_ladder_tenant_vs_palette.sh` |
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
