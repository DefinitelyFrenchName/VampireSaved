# The documentation audit (opened 14z-118, maintainer-ruled 2026-08-29) — INVENTORY

**The ruling** (14z-117 close, in the maintainer's words): *a full pass on the
documentation — every claim derived from a MEASUREMENT, not a guess;
everything consistent; nothing stale.* The Sailor Moon S discipline.

**The shape** (the 14z-113/114 staleness passes, `mister_scope.md` §6 and
`skills_scope.md` §4, are the template): one row per document; for each, its
claims sorted into three classes —

| class | meaning | what the audit does with it |
|---|---|---|
| **MEASURED** | names the log, gate, dump, replay frame or command that produced it | check the citation still resolves (file exists, number matches) |
| **DERIVED** | follows from a measured fact by a stated rule | check the rule is stated and the source fact is still measured |
| **GUESSED** | asserted with nothing behind it (incl. status claims no gate tracks) | RE-MEASURE, or RETRACT in place under [VSP-13] |

— then cross-document CONSISTENCY on the load-bearing numbers (addresses,
counts, fingerprints, pins), locked by a script where a script is cheap
(`tools/checkskills.py` already locks the skills to the docs; the same idea
extended to atlas↔engine_internals pairs). **One commit per document; every
commit shows its retraction grep.** Archived records (STATE_HISTORY,
DECISIONS_HISTORY, NEXT_SESSION HISTORY blocks) are located, never rewritten.

**The specimens, so the failure class is concrete:**
1. 14z-117: the VS/VS2 data-architecture page drew the character bank wrong
   (0x12 as real data; vsav2's vacated wheel cells as missing rows) while
   the atlas beneath it was right — a claim correct at its source and wrong
   one hop away.
2. 14z-118: the M9 and M10 board verdicts were each recorded in ONE row while
   nine "NOT field-tested / pending" lines stayed alive, including in
   `mister_field.md` §6 — the file whose job is the verdict log — and in a
   HANDOFF registry row directly under its own "FIELD-VALIDATED" header
   (`project/gotchas.md` "A FIELD VERDICT LANDS IN ONE ROW").
3. 14z-118: `docs/GOTCHAS.md` (the index) lacked the 14z-117 sweep entry —
   the entry existed, the index did not.

## 1. Inventory

(rows filled from the 14z-118 surveys — see §1.1-§1.3)

### 1.1 `docs/game/` — the game itself (surveyed 14z-118)

| document | lines | status / last tag | staleness hits (grep) | read | audit action |
|---|---|---|---|---|---|
| `engine_internals.md` | 3841 | "THE SYNTHESIS BACKLOG — CLEARED 14z-68n, re-swept 14z-71"; tags to 14z-117 | **36** (55 case-insensitive): L11 "NOT YET SYNTHESISED — the standing backlog", L125 "pending the OBJ", L232 "likely THE main-sprite garble mechanism", L261 "not yet repointed", L290 "attract-palette writer note UNVERIFIED", L434/450 "likely", L500 "OPEN SAFETY GATE", L501 "believed to be Jedah's VS-splash bust art", L937 "not yet decoded", L1617 "this line read KNOWN-OPEN", L2578 "likely the same root", L2619 "very probably his", L2686 "Dark Force mechanics UNPROVEN" | MEASURED dominant (272 evidence refs); DERIVED: 32-row aliasing consequences; **GUESSED: L290, L501, L2619, and every "likely" above** | **HEAVY — the audit's main body.** Each "likely/believed/UNVERIFIED/UNPROVEN" is re-measured or retracted; the L11 backlog header re-audited against 14z-114's S-C1 fix; L2686 DF "UNPROVEN" vs the 14z-101 DF measurement (STATE ledger) — a header/subsection conflict candidate |
| `gotchas.md` | 677 | dated entries, last 14z-117 | 6, all recorded PAST errors | MEASURED-retrospective (47 refs) | light: confirm no entry is a live claim; the 14z-90 onset entry flagged for re-filing to the project bucket (skills_scope §4 C) |
| `atlas/README.md` | 32 | "corrected 14z-114" | 0 | index; the three opcode-view SHA-1s (`22bb4684…`) appear NOWHERE else in docs | the three SHA-1s cannot be doc-locked (no second home; `checksums.txt` holds zip-member SHA-1s) — re-derive them with `tools/cps2_decrypt.py` in step 4 and say in the README how they are re-derived |
| `atlas/character_tables.md` | 447 | write-trace 2026-07-25; last tag 14z-116 | 2: L42 "RESOLVED 14z-60k (likely)", L47 "not yet confirmed by playing" | 19 refs; loader `PRG:0x028DD8` disassembled | medium: L42/L47 re-measured (the 14z-116/117 Dark Gallon work — board-confirmed — likely settles both); the specimen family |
| `atlas/id_space.md` | 372 | measured 14z-60, gate `test_id_space.sh`; last tag 14z-105 | 2: L136 "likely place for further masks", L312 "very likely its resolution" | strongest hygiene in the atlas | light: the two "likely"s; refresh the tag against the 21-cell wheel and `roster_subst` |
| `atlas/ram.md` | 329 | evidence-class legend [C]/[D]/[T]/[V]; last tag 14z-114 | 2: L17 "attract roster: TODO", L86 "P2 twin not yet located" | best-tagged file (59 refs) | light: close or keep the two TODOs explicitly; add the 14z-117 `$FF8440` ("?" walker cursor) row if absent |
| `atlas/select_screen.md` | 1007 | measured 14z-60; last tag 14z-118 | 4 | 69 refs; ~~INTERNAL CONFLICT: header "all 128 measured" vs L175 "at best 100 of 128"~~ **NOT a conflict (read 14z-118): the gate measures the shipped table 128/128 (§3); L175's 100/128 is a geometric FIT's score — the survey misread it; one clarifying sentence added so the next reader does not** | **light after all:** L175 clarified; L933 "pending re-freeze" named |
| `atlas/sprite_lists.md` | 199 | **NO session tag, NO date anywhere** | 0 | 8 refs; MEASURED but sparsely cited | medium: date it, cite `test_beam_list_type6.sh` / `obj_records_dump.lua` per claim; the bucket's biggest provenance gap |
| `atlas/venue_assets.md` | 164 | measured 14z-60v; last tag **14z-64 — oldest in the bucket** | 0 (+ an explicit "ending flow unmeasured" residual) | clean negative control (`0x00A43E` fold never fires) | light: re-date against the 14z-99 win-screen and 14z-116 quote measurements; "twelve playtest rounds" is testimony — say so |

### 1.2 `docs/platform/` and the six skills (surveyed 14z-118)

| document | lines | status / last tag | staleness hits (grep) | read | audit action |
|---|---|---|---|---|---|
| `platform/mister.md` | 2145 | "THIS FILE IS A LOG", wins over `mister_core.md`; tags to 14z-118 | 14, nearly all anti-assumption prose; two "pending" struck out | MEASURED (every figure names its gate: `test_mister_tenant_oracle` 2886/3546/skew 660, `test_mister_gfxc_fetch` 9,388,928 reads / 1,735 codes, `test_mister_qsound_ext` 210,180 / frame 3783); DERIVED: skew 660 = 659+1; GUESSED: the "~1.0-1.2 s/frame -> ~45 min / ~3.5-4 h" runtime extrapolations (no log line), L1391 "a gate that has never fired should be expected" | light: cite or drop the runtime estimates; re-flow S8's spliced sentence if it survived; confirm the 12 anti-assumption lines are not open items |
| `platform/gotchas.md` | 1899 | no status line; dated entries, last 14z-112; a "STATUS 14z-114" at L395 | 12, narrative or API names | MEASURED (`-aviwrite` 5.7 GB / ~2 min; seed lottery n=12; CPH-1 via `test_decrypt_oracle`); DERIVED: the GFX-content -> SDRAM-contention -> drift chain; GUESSED: L1219's forward prediction (flagged as such) | light: the 14 emulator-fact entries flagged for RE-FILING from `project/gotchas.md` (skills_scope §4 row B) — do the re-filing here |
| `mister-cps2-wide-core` | 118 | level 1, `[MSC-1..73]`; **no session tag in-file** | 3 (MSC-71 "INFERRED, never measured" is honest) | one numeric literal; near-numberless by design | none beyond the checker; freshness is the anchor lock |
| `mister-vampire-saved` | 67 | level 2, `[MSV-1..36]`; last tag 14z-112 | 1 (false hit) | every figure names a gate; MSV-5 marks a RETRACTED figure | check MSV citations against the 14z-115..118 moves (bank-5 count 6,272, extent `0xFE42`) |
| `cps2-hardware` | 61 | level 1, `[CPH-1..30]`; last tag 14z-114 | 0 | cleanest file in the bucket | none |
| `cps2-emulation` | 69 | level 1, `[CPE-1..42]`; **no session tag** | 2, narrative | zero numeric literals — the number rule cannot bite | none; note the number-rule blind spot |
| `vampire-savior-engine` | 127 | level 1 for the game, no ROM addresses; **no session tag** | 1 ("~frame 4278") | recipes name instruments and controls | none |
| `vampire-saved-port` | 198 | level 2, `[VSP-1..161]`; last tag 14z-111 | 3, all rules AGAINST staleness | cites by section | check the rigs section against 14z-115..118 (Shadow rig re-timed, random-select gate, medallion gate) |

`checkskills.py` lock, as read: (1) ID-lock both ways; (2) liftability token grep on level 1; (3) every numeric literal in a skill must appear verbatim in a LOG — LOG sets per prefix: MSC/MSV = `platform/mister.md`, `mister_map.md`, `mister_fit.md`, `mister_field.md`, `release_format.md`, both gotchas, `BITSTREAM.txt` (**`mister_core.md` excluded as synthesis**); CPH/CPE = both gotchas, `cps2_wide.md`, HANDOFF, `checksums.txt`; VSE = docs == logs; VSP = `project/gotchas.md`, `patch_notes.md`, `patch_index.md`, HANDOFF, CLAUDE.md, STATE(+HISTORY). **The number rule only checks PRESENCE in a log, not that the log's figure is current** — that is the gap §3's script fills.

### 1.3 `docs/project/` and HANDOFF (surveyed 14z-118)

LIVE = still governs work; HIST = a plan or record that executed, kept for its
eliminations. A HIST document is not audited claim-by-claim; it is checked for
ONE thing — that its banner says it is history and names what superseded it.

| document | lines | status / last tag | live? | staleness hits | read | audit action |
|---|---|---|---|---|---|---|
| `HANDOFF.md` | 3550 | same-commit currency; tag 14z-118 | LIVE | 19 (most inside dated registry rows) | MEASURED-dominant (515 instrument lines; every registry row a fingerprint + gates) | **HEAVY, mechanical:** 62 build-dir names no longer on disk. Archival registry rows are fine AS HISTORY; the OPERATIONAL ones are not — `build/m5_stock` ×23, `build/m3b_merged18` ×6, `build/hui46` ×4, `build/don_m4` ×5. Classify each line archival/operational; re-point or mark the operational ones. Gate index: one true dangle (`test_m2a_mask_pin.sh`, self-documented as renamed) |
| `docs/README.md` | 144 | split 14z-69; tag 14z-117 | LIVE | 0 | routing table | light: confirm every row's "current" claim (S17 class) |
| `patch_notes.md` | 3989 | newest-first log; top 14z-117 (2) | LIVE (append-only) | 19, all inside dated entries | MEASURED (byte detail) | none beyond §A5 of the freeze ritual: a log is not rewritten |
| `gotchas.md` | 3226 | newest 14z-118 | LIVE | 13 | MEASURED per entry | light: the 14 emulator-fact entries flagged for re-filing to `platform/gotchas.md` (skills_scope §4 B); `#103 instance 2 UNVERIFIED` (L2650) — settled 14z-98 ("instance 2 retracted"), mark |
| `mister_map.md` | 1081 | the LOG; `mk_mister_page.py --check` re-derives §5 every run | LIVE | 0 | MEASURED, script-locked | none |
| `mister_core.md` | 892 | synthesis; tag 14z-118 | LIVE | 4 (L94 "format is the open item" — RULED 14z-113) | labelled DERIVED/INFERRED boundary (MSC-71) | light: L94 |
| `cps2_wide.md` | 649 | RATIFIED (updated 14z-113); tag 14z-114 | LIVE | 4, resolved-in-place | MEASURED gate table | light: L631 "pending decision" — check which |
| `build_dir_triage.md` | 422 | "RULED AND EXECUTED 14z-102"; tag 14z-117 | UNCLEAR | 1 | MEASURED | medium: split — the ruling is HIST, the policy ("what must stay", N-2, grep-four-places) is LIVE and should carry the 14z-112 one-zip sweep it does not describe |
| `patch_index.md` | 340 | [VSP-99] same-commit; tag 14z-118 | LIVE | 6 | fingerprints per generation | ~~L237 "believed unused" is GUESSED~~ **survey misread (14z-118): the row already says "believed unused, MEASURED 14z-89 to be REACHED BY LEGACY TOO" in the same cell** — no edit; the audit's own claim retracted here |
| `M3b_plan.md` | 320 | "the working plan", written 14z-65; tag 14z-90 | HIST — but its banner does NOT say so | 3 | plan | banner: HISTORICAL, superseded by `tenant_manifest.md` §14z-114 + the merged registry |
| `mister_fit.md` | 272 | measured 14z-106 on `build/m3b_merged13` (deleted 14z-112); ceilings re-derived by `audit_mister_map_fit.sh` | LIVE, stale basis | 2 | MEASURED | medium: the provenance line names a dead build dir and "the current freeze" = merged-m9; re-state (the gate re-derives — say which build it reads now) |
| `WSL2_SETUP.md` | 272 | evergreen how-to | LIVE | 0 | commands | none |
| `hardening_register.md` | 271 | living register; tag 14z-117 | LIVE | 0 | MEASURED | none |
| `mister_scope.md` | 252 | STATUS 14z-114 distilled | HIST (plan executed) | 6, struck/resolved | MEASURED S-table | none beyond the 14z-118 fix already made |
| `beam_port_scope.md` | 223 | SUPERSEDED, premise wrong — says so | HIST | 1 | self-labelled | none — the model case |
| `skills_scope.md` | 208 | written 14z-114 | HIST (all skills exist) | 6 | plan | banner: EXECUTED 14z-114; keep §4 (the pass template) as the live citation |
| `tenant_manifest.md` | 195 | RATIFIED 2026-08-05 + STATUS 14z-114 | UNCLEAR, layered | 4 | mixed; `[tenant.folds]` rows self-labelled speculative | medium: separate the ratified schema (LIVE) from the single-tenant narrative (HIST) and the PROPOSAL sub-tables (never built — say whether they ever will be) |
| `porting_sprite_lists.md` | 170 | method; tag 14z-83 | LIVE | 0 | DERIVED, 3 instrument lines | light: cite the atlas rows it leans on by name |
| `audit_2026-08-15_dispositions.md` | 153 | closed audit record; tag 14z-95 | HIST | 4 | MEASURED per issue | banner only |
| `mister_field.md` | 138 | the LOG; tag 14z-118 | LIVE | 1 (L91 "Decisions pending" — STOCK CONTROL once-per-`.rbf`, still unruled) | MEASURED | none beyond 14z-118 |
| `porting_code_regions.md` | 135 | checklist; tag 14z-71 | LIVE | 0 | DERIVED, 3 instrument lines | light: cite the #99 / 14z-111 data-root case as its newest instance |
| `M2_feasibility.md` | 106 | analysis 2026-07-25 | HIST | 0 | pre-implementation | banner only |
| `quartus_brief.md` | 90 | EXECUTED 14z-108, HISTORICAL — says so | HIST | 0 | numbers cite STATE, not a log | light: point the result banner at `platform/mister.md` "SYNTHESISING" (the log) |
| `release_format.md` | 88 | ruled 14z-113 | LIVE | 0 | normative | none |
| `visual_smoke_tests.md` | 86 | corrected 14z-61 — oldest live tag | LIVE | 0 | MEASURED instance | light: re-date; name the gates that now embody it (`test_wide_render_content`, `test_version_string`) |
| `playtest_m3a_interims.md` | 72 | HISTORICAL, says so | HIST | 0 | closed defect list | none |
| `M1_acceptance.md` | 62 | assessed 2026-07-25 | HIST | 1 | scoping | banner only |
| `coverage_matrix.md` | 59 | measured 14z-104, same-commit rule | LIVE | 0 | evidence named per cell | light: add the 14z-116 Shadow-vs-tenant cell (morph INTO a tenant — now a run) and random-select |
| `tables/README.md` + `tables/*` | — | README: "Empty until a ported character exists" | LIVE, **stale by its own words** | — | — | DONE 14z-118 (ruled option a): generated + gated, see §4 row 5 |

## 2. Cross-document numbers to lock (candidates for the script)

Game/atlas ↔ engine_internals (from §1.1's survey; `file:line` as of 14z-118):
1. `PRG:0x282D4` (+ vsav2 `0x27530`) per-char OBJ bank table — `character_tables.md:199`, `engine_internals.md:153/1410/1414`, `game/gotchas.md:289`
2. `PRG:0x38C198` sprite-palette pointer table, 32 rows, block `0x500` — `character_tables.md:117`, `venue_assets.md:28`, `engine_internals.md:250/252`
3. `PRG:0xBF01A/09A/11A/19A` AI script tables — `character_tables.md:423`, `engine_internals.md:1441`, `ram.md:105`
4. `PRG:0x0AEF6` writer of `(0x382,A1)` — `engine_internals.md:1143/1172`, `game/gotchas.md:582`, `ram.md:102`
5. `PRG:0x020B9C` Gallon-variant idiom — `select_screen.md:495/518`, `id_space.md:231`, `engine_internals.md:841`
6. `PRG:0x028DD8` loader (≡ `0x0280B8` / `0x0280E6`) — `character_tables.md:11/78`, `select_screen.md:329`
7. `PRG:0x04FAC4` -> `(id & 0x0F) * 24` into `PRG:0x04FFA8` — `id_space.md:161`, `game/gotchas.md:523` (recorded as a corrected error — which reading is current?)
8. `RAM:$FF8782` / `$FF8B82` — `select_screen.md:108`, `id_space.md:183`, `ram.md:102`
9. `RAM:$FF4182-$FF41A1` fade staging — `engine_internals.md:714`, `ram.md:68`
10. `PRG:0x898C4` name entries (8 B) — `engine_internals.md:659`, `venue_assets.md:119`; `PRG:0x268A02` ring base — `select_screen.md:759/960/996`
11. `PRG:0x01F5A0` match-init normalisation — `character_tables.md:329`, `id_space.md:318`; `PRG:0x06C0E0` — `engine_internals.md:485`, `select_screen.md:770`
12. the 32-row / `0x10-0x1F` alias invariant — stated in 7 of 9 game files
13. `atlas/README.md`'s three opcode-view SHA-1s — nowhere else; **cannot be doc-locked** (`docs/checksums.txt` holds the zip members' SHA-1s, not the decrypted opcode view) — verify by re-running `tools/cps2_decrypt.py` in step 4 instead

Platform/MiSTer (already log-locked by `checkskills.py` for PRESENCE; the
audit checks CURRENCY): `0x4D10F3`, `210,180` / frame `3783`, `0x7E0000` /
`0x6E0000` / `0x658000`, `2886` / skew `660`, `2609` / skew `463`, `+206
ALMs` / `41,910`, pin `7b9a0d2d`, `5CSEBA6U23I7`, `59.6374 Hz`, ceilings
`0xEE73` / `0xFFDB` / `0x8E57F0` / `0x5FFF1E`, bank-5 count `6,272` / extent
`0xFE42` (moved 14z-115 and 14z-117 — the first currency test).

## 3. Proposed order and the script

**The script first, because it makes the rest cheaper:** `tools/checkdocs.py`
(ci_portable, `tests/test_checkdocs.sh` with must-fire controls per
[VSP-19]) reading a small table `docs/doc_locks.tsv` of (label, canonical
value, canonical file, every file that must quote it). It asserts every
listed file contains the canonical value verbatim and, for hex addresses,
that no DIFFERENT value sits next to the same label. Seeded from §2. This is
the atlas↔engine_internals extension of `checkskills.py`'s number rule and
it turns "consistent" from a reading into a gate. Budget: one session step.

**Then the documents, one commit each, in this order** (specimen family
first, then by weight of GUESSED claims, then the mechanical HANDOFF pass):
1. `atlas/character_tables.md` + `atlas/id_space.md` (the specimen family; L42/L47 and the two "likely"s; re-verify the artifact page against them once more)
2. `atlas/select_screen.md` — the 128-vs-100/128 conflict; L933
3. `engine_internals.md` — the 36 markers; the DF "UNPROVEN" header; the L11 backlog header (the largest single commit; may split by section)
4. `atlas/sprite_lists.md` (date + cite), `atlas/venue_assets.md`, `atlas/ram.md`, `atlas/README.md` (SHA-1 lock)
5. `patch_index.md` L237 retraction; `tables/` (README + the two missing manifests — **decision for the maintainer**: generate or retract)
6. HANDOFF build-dir classification (archival vs operational; re-point the operational)
7. the HIST banners in one commit: `M3b_plan`, `skills_scope`, `M2_feasibility`, `M1_acceptance`, `audit_2026-08-15`; `build_dir_triage` / `tenant_manifest` split LIVE from HIST
8. the light rows: `mister_fit` basis line, `mister_core` L94, `cps2_wide` L631, `quartus_brief` log pointer, `visual_smoke_tests` re-date, `coverage_matrix` new cells, `porting_*` citations, `platform/mister.md` runtime estimates, the gotchas re-filing
9. the skills last — re-run `checkskills` after every doc commit; a red there is the lock doing its job

**Not audited claim-by-claim:** STATE_HISTORY, DECISIONS_HISTORY, NEXT_SESSION
HISTORY blocks, `patch_notes.md` (logs — never rewritten; corrections are
marked at the live carrier).

**One ruling wanted before step 5:** `docs/project/tables/` promises
per-character manifests for all three tenants and holds only Donovan's
(2026-08-09). [VSP-6] makes these the community-facing tunables. Options:
(a) generate `huitzil.md` / `pyron.md` from the same extractor that produced
`donovan.md` and refresh all three from the current manifests
(recommended — it is what the rule says); (b) retract the promise and point
at `build/manifest/*.toml` as the table of record.

## 4. Log of the pass (one line per commit)

| # | document | commit | claims re-measured / retracted | grep after |
|---|---|---|---|---|
| 0 | field-verdict carriers (the specimen) | `020a555` | 9 stale "pending" lines retired, 3 verdicts entered in `mister_field.md` §6 | empty outside HISTORY |
| 1 | the script: `tools/checkdocs.py` + `docs/doc_locks.tsv` + `tests/test_checkdocs.sh` (ci_portable) | (this commit) | 16 locks / 40 file-sites seeded from §2; all agree today. NOT lockable: `atlas/README.md`'s three opcode-view SHA-1s — no second home in the tree (they come from `tools/cps2_decrypt.py`, not from a doc); left as a README-only fact, flagged in §1.1 | n/a |
| 2 | `atlas/character_tables.md` + `atlas/id_space.md` (+ the two `select_screen.md` sentences that repeat them) — the specimen family | (this commit) | 3 GUESSED claims retired by citation: "RESOLVED (likely) … not yet confirmed by playing" -> decoded 14z-116 + board 2026-08-28; "byte-identical aliases" -> aliases in the four id-space tables, OWN rows in the two palette tables (`test_effect_palette_table.sh` §2 — a gate that already existed and was never cited at the claim); "which characters occupy them: open item" -> the `test_id_space.sh` freeze. One hedge tightened (id_space L136); `select_screen.md` L175 clarified (the 100/128 is a geometry FIT's score, the table is measured 128/128) and L933's "pending re-freeze" named (donovan-m3a, 14z-64). No new measurement was needed — every fix was a citation to an existing gate | empty (only the correction notes quote the old wording) |
| 3 | `engine_internals.md` — first pass, the three sites the survey ranked GUESSED that a citation could settle | (this commit) | DF header: "mechanics UNPROVEN (14z-66/67)" -> MEASURED 14z-101, ruled 2026-08-21, frozen by `audit_df_framework.sh` (14z-104) — the section had never cited its own gate; the M2b "OPEN SAFETY GATE" (Jedah bust-art borrowing) struck as SUPERSEDED 14z-63 (bank 5, `test_wheel_bank5.sh`); the Anakaris `0xAA` DF-base inference kept as labelled inference with the settling measurement named (`df/97` rig, not run). Remaining flagged sites (L290 attract-palette writer UNVERIFIED since M2b; the "likely" family) are honest labels that need a MEASUREMENT, not a citation — listed for a later step, not silently accepted | empty |
| 4 | `atlas/sprite_lists.md`, `atlas/ram.md`, `atlas/README.md`, `atlas/venue_assets.md` | (this commit) | sprite_lists DATED (14z-71 by git, swept 14z-114) and its three re-deriving gates named; ram.md's two TODOs restated as OPEN MEASUREMENTS (not run) and the 14z-117 `$FF8440` walker-cursor row added [D]; README's three opcode-view SHA-1s RE-DERIVED (`shasum build/out/*_opcodes.bin`: all three unchanged) and the derivation written beside them; venue_assets given a currency note (what was measured since, where) and its "twelve playtest rounds" labelled testimony | empty |
| 5 | `docs/project/tables/` (maintainer-ruled option a, 2026-08-29) | (this commit) | `tools/tables_char_md.py` renders each tenant's page from the build's `extract/regions.json` + `bank_map.toml`; `donovan.md` REGENERATED (the hand page's `param32_a = FFFD0000` was stale — shipped is rec8 `00030000 FFFD6000`), `huitzil.md` / `pyron.md` CREATED; README rewritten (it said "Empty until a ported character exists"); gate `tests/test_tables_current.sh` (ci_static) diffs a regeneration against the committed pages, one must-fire control. The hand page's prose is in git history (`2a6ebc3`) | empty |
| 6 | HANDOFF build-dir references | (this commit) | the survey's 62 dangling names classified: registry rows and "previous batch" paragraphs are ARCHIVAL (kept — they name what a freeze was built as); OPERATIONAL lines re-pointed: three MiSTer example commands (`m3b_merged18` -> `m3b_merged20`), two gate-index comments ("defaults to build/hui46" — the gates were re-pointed at 14z-117b, the comments were not; now say "the current solo, read the script"), and the 14z-8x `m5_stock`/`don_m4` rebuild recipe replaced by the four-track recipe `test_m3a_reproducible.sh` runs. `build/m5_stock` ×23 in the survey was a substring count (bare `m5_stock` appears twice, both registry rows). `don_m4` at L2289/L3279 names a ground-truth pre-fix pair — archival, kept | `grep -n 'build/m3b_merged18\|build/hui46' HANDOFF.md` = archival rows only |
| 7 | the HIST banners: `M3b_plan`, `skills_scope`, `M2_feasibility`, `M1_acceptance`, `audit_2026-08-15_dispositions`; the two-layer notes on `build_dir_triage` and `tenant_manifest` | (this commit) | each now opens with a STATUS line saying it is history and naming what superseded it (registry rows, `tenant_manifest` STATUS 14z-114, `id_space.md`, STATE/hardening_register); the two layered docs say which parts are LIVE / HISTORICAL / PROPOSAL-never-built so a reader stops treating dir counts and slot-0x0F prose as current | n/a (no claim retracted — status made explicit) |
| 8 | the light rows: `mister_core` L94, `mister_fit` provenance, `quartus_brief` log pointer, `visual_smoke_tests` currency, `coverage_matrix` Shadow cells, `porting_code_regions` newest instance | (this commit) | `mister_core`: "the release format is the open item" -> ruled 14z-113 (`release_format.md`); `mister_fit`: gate default `m3b_merged16` -> the current merged (the gate was re-pointed, the prose not); `quartus_brief`: numbers now point at the LOG (`platform/mister.md` SYNTHESISING) since STATE 14z-108 rolled; `coverage_matrix`: Shadow "N/A-until-enabled" was a MISREADING (Shadow is vanilla's own code, never disabled) -> MEASURED 14z-116 + board; Marionette is vsav2's; the remaining Shadow gaps named; `visual_smoke_tests`: the gates that embody it named; `porting_code_regions`: #99 added as the newest instance. `cps2_wide` L631 was already struck/DECIDED — no edit. NOT done here, deferred to a later step: the 14 emulator-fact gotchas to re-file `project/gotchas.md` -> `platform/gotchas.md` (a re-filing pass of its own); `platform/mister.md`'s "~45 min / ~3.5-4 h" runtime estimates — grep finds no such line, the survey's claim is UNVERIFIED and dropped | `grep -n 'open item in STATE' docs/project/mister_core.md` empty |
| 9 | `engine_internals.md` second pass — the sites that needed a MEASUREMENT | (this commit) | **Anakaris `0xAA` DF base: MEASURED and the inference RETRACTED** — on rig `df/97` his DF activates and makes zero palette-seq calls (Demitri control 577); a full-roster re-census (16 legs, every DF observed) reproduces the 14z-79b owners, adds `0x0B` -> Zabel's block, and leaves `0xAA` with NO DF requester (frozen `tests/expected/df_palette_seq_census.txt`; `audit_palette_seq_ids.sh` gained `DFRPL=` and the no-path verdict). Three "likely"s settled by citation (garble mechanism -> confirmed by its fix; the 150-entry wheel reading -> superseded by the measured record; the bank-word-0 pieces -> the 14z-69o shadow fix); one kept as labelled unknown (`0xD153E` consumer family); the attract-palette writer note DERIVED and bounded (unreachable by attract at a variant id — `audit_id_writers.sh`; the 1P tenant-vs-tenant VS screen is the only surface, cosmetic, not observed) | `grep -n 'very probably his' docs` = the struck paragraph only |
| 10 | the gotchas re-filing (skills_scope §4 row B, maintainer-ruled 2026-08-29) | (this commit) | 13 emulator/toolchain entries `project/gotchas.md` -> `platform/gotchas.md` verbatim under a provenance banner (pre-seeded ROM-audit facts `[CPE-20]`, cross-emulator content `[CPE-33]`, the video-blind FBNeo gate `[CPE-35]`, canary/relocation-control lessons `[CPE-38]`/`[CPE-39]`, the MAME harness blind until B5, `git apply` `[CPE-25]` / `git submodule add` `[CPE-21]`, the `:IN2` EEPROM line, `WIDE=0` `[CPE-31]`, probe PC off an instruction boundary, palette-RAM pokes `[CPE-19]`, and the `-debug` half of the 14z-98 entry `[CPE-3]` — split so `[VSP-125]`'s kill-poke half stays in the port bucket); the 14z-90 onset entry (`[VSP-38]`) game -> project. Pointer notes at both removal sites; 12 index lines redirected; `checkskills` ALL PASS with every anchor in its new file | n/a (moves, not retractions) |
| 11 | `atlas/ram.md`'s two open measurements (c) | (this commit) | **Attract roster: MEASURED** — static decode of the assigner + table (`PRG:0x005BEA` / `0x005C08`, eight matchups with venues) confirmed by a 40,000-frame vanilla trace; gate `test_attract_roster.sh` (ci_static, negative control). **P2 downs twin: the 14z-104 row was WRONG, not incomplete** — `$FF8127` goes 0->1 after a P2-won down, not a P1-won one, and flips at the next match's refill (semantics OPEN); the engine's real per-side record at the down is `$FF8105`/`$FF810C` (1 = P1, 2 = P2), new rows; `$FF810E` is a round-PHASE byte (0/1/0/FF), not a monotonic counter — both single-probe [D: 14z-104] rows superseded by two per-frame vanilla legs, frozen in `audit_tenant_timeout.sh` (side codes + the `$FF8127` polarity). Evidence `build/timeout_{ctl2,inv2}_trace_14z118.log` | `grep -n 'P1 downs-won' docs/game/atlas/ram.md` = the struck text only |
| 12 | `atlas/id_space.md` tag refresh (d) | (this commit) | gate re-run PASS (44 tables / 25 distinct / 7 folds); a currency header naming what shipped from each prediction; the writers table extended with the attract writer's full range; "vanilla's entry path to `0x18` still unlocated" RETRACTED (14z-116 measured none exists); the free-id set marked taken and locked; manifest items 2 and 5 given their shipped status (wheel cell == id; ladder rows 14z-111; the VS palette block still unsupplied); re-measuring commands extended with the three gates that now cover this page | `grep -n 'still unlocated' docs` = the struck text only |
