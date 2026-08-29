# NEXT SESSION — orientation (rewritten at the 14z-118 close, 2026-08-29)

> ## **START HERE. NOTHING IS RED. THE DOCUMENTATION AUDIT'S FIRST PASS IS
> ## DONE — eight commits, strict 114/0/0/0, NOT PUSHED (push at the
> ## maintainer's word; check `git status -sb`). Read STATE 14z-118 CLOSE,
> ## then `docs/project/doc_audit_14z118.md` §4 (one line per commit).**
> ##
> ## **WHAT NOW EXISTS:** `tools/checkdocs.py` + `docs/doc_locks.tsv` (16
> ## cross-document number locks, `test_checkdocs`, ci_portable — ADD A ROW
> ## whenever a number is quoted in a second document); `tools/tables_char_md.py`
> ## + `test_tables_current` (ci_static — the three community tables follow
> ## the build; REGENERATE THEM IN EVERY FREEZE COMMIT, the re-point sweep
> ## moves their build names). Both are in the HANDOFF gate index.
> ##
> ## **WHAT THE PASS FOUND, one breath:** nearly every "guessed" claim was
> ## settled by CITING a gate that already existed — the docs measured more
> ## than they said. The one-hop class showed up inside single files
> ## (`character_tables.md` L45 vs L128) and inside the audit's own survey
> ## (three false leads, struck; `project/gotchas.md` "THE AUDIT'S OWN
> ## INVENTORY IS ONE HOP AWAY TOO").
> ##
> ## **WHAT IS LEFT, in order (STATE 14z-118 CLOSE "NOT done"):** ~~(a)~~
> ## DONE the same day (AUDIT (9)): Anakaris's DF measured — `0xAA` has NO
> ## Dark Force requester in the whole roster, the "very probably his" claim
> ## retracted, census frozen (`tests/expected/df_palette_seq_census.txt`;
> ## rerun with `DFRPL=tests/replays/df/97_df_mech.rpl CHARS="00 .. 0f"`).
> ## Still open from (a): whether a NON-DF path requests `0xAA` — a whole-
> ## corpus phase-A census before anyone calls the block free. ~~(b)~~ DONE
> ## (AUDIT (10)): the fourteen gotchas re-filed with their anchors;
> ## ~~(c)~~ DONE (AUDIT (11)): the attract roster decoded, traced and gated
> ## (`test_attract_roster`); `$FF8127`'s 14z-104 reading was WRONG — it marks a
> ## P2-won down, not a P1-won one, and flips at the refill (semantics OPEN);
> ## the real side codes are `$FF8105`/`$FF810C`; ~~(d)~~ DONE (AUDIT (12)); ~~(e)~~
> ## RULED 2026-08-29 (AUDIT (13)): STOCK CONTROL kept, run once per NEW `.rbf`.
> ## **THE 14z-118 LIST IS CLOSED**, and the `0xAA` question with it (AUDIT (14)):
> ## the whole-corpus census ran (73 legs) and `0xAA-0xAD` is SASQUATCH's —
> ## palette-seq blocks are 8 ids, `BASE + ($381<<2) + phase`, and a free one
> ## is found by reading `0x02A8A4`'s routines, never by a census. Still open:
> ## `$FF8127`'s meaning and `+0x381`'s (costume index is the natural reading,
> ## not established) — only if they ever matter.
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`; bundle 14z117b
> ## FIELD-VERIFIED GREEN (M11, 2026-08-29). Fork `f997cfe1` (27 commits).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.

# HISTORY BELOW — the 14z-118 verdict, 14z-117 final-close, 14z-117 second-close, 14z-117 first-close, 14z-116, 14z-114, mid-14z-114 and 14z-113 orientations and older;
# kept for the census anchors, eliminations and traps, superseded as the opener.

## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-118 VERDICT, 2026-08-29 — superseded by the 14z-118 close above)

> ## **START HERE. NOTHING IS RED. THE M11 BOARD VERDICT IS GREEN
> ## ("behavior identical to emulation", maintainer, MiSTer, 2026-08-29 —
> ## STATE 14z-118). Nothing is pending on hardware. THE WORK IS THE
> ## DOCUMENTATION AUDIT, ruled by the maintainer: every claim MEASURED not
> ## guessed, everything consistent, nothing stale. The Sailor Moon S
> ## discipline.**
> ##
> ## **THE AUDIT ALREADY HAS ITS FIRST SPECIMEN, from recording the verdict:**
> ## the M9 and M10 verdicts had each been written into ONE row while nine
> ## "not field-tested / pending" lines stayed alive in headers, registry
> ## rows and `mister_field.md` — the file whose job is the verdict log.
> ## Retired 14z-118 (`project/gotchas.md` "A FIELD VERDICT LANDS IN ONE
> ## ROW"). Expect the same shape everywhere: a claim right at its source
> ## and wrong one hop away.
> ##
> ## **HOW TO SHAPE THE AUDIT** (the 14z-113/114 staleness passes are the
> ## template — S1-S20 for MiSTer, S-C1..S-C12 for the game docs, S-D for
> ## the port docs; one commit per document): INVENTORY FIRST —
> ## `docs/project/doc_audit_14z118.md`, one row per document in
> ## `docs/game/`, `docs/platform/`, `docs/project/`, HANDOFF and the six
> ## skills (~29,000 lines), each claim marked MEASURED (name the log, gate
> ## or dump) / DERIVED (from a measured fact by a stated rule) / GUESSED
> ## (nothing behind it). Re-measure or RETRACT the third class; grep every
> ## retraction across the repo ([VSP-13]: headers and summary lines first).
> ## Lock cross-document numbers (addresses, counts, fingerprints, pins)
> ## with a script where one is cheap — `checkskills.py` already locks the
> ## skills to the docs; extend that idea to the atlas↔engine_internals
> ## pairs. Start with the specimen family: `character_tables.md` ↔
> ## `id_space.md` ↔ `engine_internals.md`'s character-bank section ↔ the
> ## data-architecture artifact
> ## (https://claude.ai/code/artifact/98d586db-1a69-49eb-b421-5085db07b707).
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle
> ## `../mister_fieldtest_14z117b/` — FIELD-VERIFIED. Everything pushed
> ## — check `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 FINAL close, 2026-08-29 — superseded by the 14z-118 opener above)

> ## **START HERE. NOTHING IS RED. TWO FREEZES SHIPPED AND PUSHED TODAY
> ## (merged-m12 M10, merged-m13 M11). THE NEXT SESSION IS RULED BY THE
> ## MAINTAINER: their board results on bundle 14z117b, then — the real
> ## work — A FULL DOCUMENTATION AUDIT: every claim MEASURED not guessed,
> ## everything consistent, nothing stale. The Sailor Moon S discipline.**
> ##
> ## **HOW TO SHAPE THE AUDIT** (the 14z-113/114 staleness passes are the
> ## template — S1-S20 for MiSTer, S-C1..S-C12 for the game docs, S-D for
> ## the port docs; one commit per document): for each document in
> ## `docs/game/`, `docs/platform/`, `docs/project/`, HANDOFF and the six
> ## skills, inventory its claims and mark each MEASURED (name the log,
> ## gate or dump that measured it) / DERIVED (from a measured fact by a
> ## stated rule) / GUESSED (nothing behind it). Re-measure or RETRACT the
> ## third class; grep every retraction across the repo ([VSP-13]: headers
> ## and summary lines first). Check cross-document consistency on the
> ## load-bearing numbers (addresses, counts, fingerprints, pins) with a
> ## script where one is cheap — `checkskills.py` already locks the skills
> ## to the docs; extend that idea to the atlas↔engine_internals pairs.
> ## **Today's specimen of the failure class:** the data-architecture page
> ## drew the character bank wrong (0x12 as real data, vsav2's vacated
> ## wheel cells as missing rows) while the atlas beneath it was right —
> ## a claim can be correct at the source and wrong one hop away.
> ##
> ## **WHAT 14z-117 DID, one breath:** the medallion-fix freeze (M10, cheap
> ## as predicted); the random-select feature (two thunks, one table,
> ## `roster_subst`; the walker's non-tick path re-reads the table — a
> ## bound-only thunk crashed, fixed; the Shadow rig re-timed) and its
> ## freeze (M11); the VS/VS2 data-architecture artifact, corrected after
> ## the maintainer's read: https://claude.ai/code/artifact/98d586db-1a69-49eb-b421-5085db07b707
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle
> ## `../mister_fieldtest_14z117b/` (`.rbf` unchanged). Everything pushed
> ## except the final close commit — check `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 SECOND close, 2026-08-29 — superseded by the final close above)

> ## **START HERE. NOTHING IS RED. TWO FREEZES SHIPPED TODAY — merged-m12
> ## (M10, the Pyron-medallion fix) and then merged-m13 (M11, RANDOM SELECT
> ## INCLUDES THE TENANTS) — and the next event is the BOARD VERDICT on
> ## `../mister_fieldtest_14z117b/` (the tell is "M11"; park on "?" and
> ## the draw cycles all 18).**
> ##
> ## **WHAT 14z-117 DID, one breath:** the freeze battery for the medallion
> ## fix (cheap as predicted: three ops changed content, no address moved),
> ## pushed at the maintainer's word; then, at their word, the random-select
> ## item: TWO profile-gated site_thunks at `0x020C74` (the bound) and
> ## `0x020C80` (the table read + rts + an 18-entry table), one table filled
> ## per build by the new generator feature `roster_subst`. **The trap paid
> ## for:** the walker re-reads the table on its NON-tick frames — a
> ## bound-only thunk crashed the figure refresh with a code byte as id
> ## (`game/gotchas.md`, `select_screen.md` "THE WALKER HAS TWO PATHS").
> ## Confirm semantics are vanilla's (what shows is what you get), the
> ## harness stages inputs one frame ahead, nine legacy select replays are
> ## bit-identical (none hovers "?"), stock twin unchanged both times.
> ## The Shadow rig (`113`) was RE-TIMED (confirm 1450 -> 1521-1522) because
> ## the wider draw made it a mirror match on the solos.
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle 14z117b (`.rbf`
> ## unchanged). Gates: `test_random_select_tenants.sh` (emulator tier,
> ## CONTROL = the previous merged; when `m3b_merged19` rolls off, re-point
> ## or accept its SKIP). Full numbers: STATE 14z-117 (2) and its CLOSE.
> ## **Everything PUSHED at the maintainer's word (fork, main, tags) — check
> ## `git status -sb`, not this line.**
> ##
> ## **OPEN, unchanged:** the maintainer's 1:1 wheel mockup; #112/#113
> ## parked; the FBNeo two-run-family question; the tenant CPU AI
> ## "lackluster" note; the win quotes (forgone, clean-way-only).
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 FIRST close, 2026-08-29 — superseded by the second close above)

> ## **START HERE. NOTHING IS RED. THE PYRON-MEDALLION FREEZE IS DONE —
> ## merged-m12 (M10) is frozen, tagged, released and bundled; the next
> ## event is the BOARD VERDICT on `../mister_fieldtest_14z117/` (the tell
> ## is "M10" bottom-right, three glyphs).**
> ##
> ## **WHAT 14z-117 DID, one breath:** rebuilt the four tracks with the mark
> ## M9 -> M10 (`version_x` 340 -> 324 — a third glyph at 340 clips at pixel
> ## 384), ran the whole 14z-115 battery, and froze donovan-m16 `7950c844` /
> ## huitzil-m23 `7ade3180` / pyron-m17 `01b39c39` / merged-m12 `cde712e1`
> ## (`build/m3b_merged19`, 819 ops), stock twin `m5_stock11` = `d29fd062`
> ## UNCHANGED. **The battery WAS cheap, as predicted:** on every build only
> ## three ops changed content and NO address moved; every masked legacy
> ## class passed on all three suites; the moved `.sha1`s were exactly the
> ## 14z-115 tenant/select-rig inventory (+ `113_shadow_vs_tenant`, frozen
> ## for the first time), attributed on 103 and 92 by DUMPS diff — execution
> ## position + dead stack, zero bytes past the victory screen. Pointer-flow
> ## WEAK +1 per build (the new coord pair); MiSTer bank-5 census 6,272 /
> ## extent `0xFE42` (the third glyph). merged_legacy 47/47, guard corpus
> ## 344/344, roster pairings 111/111, legacy pairings and strict — STATE
> ## 14z-117 CLOSE has the final numbers.
> ##
> ## **THE MiSTer TAIL WAS NOT EMPTY** (the program moved): fork `80e08111`
> ## (catalogue: six CRCs), patch 0026, pin bumped, `release/merged-m12/`,
> ## bundle `../mister_fieldtest_14z117/` (STOCK CONTROL MRA byte-identical
> ## to 14z-115's, `.rbf` unchanged — flash nothing). **Fork, main and the
> ## four tags PUSHED** at the maintainer's word (they took the bundle to
> ## the board); check `git status -sb`, not this line.
> ##
> ## **ONE TRAP PAID FOR, in `project/gotchas.md`:** the re-point sweep
> ## stamped four lines ending in `\` — `test_pointer_flow` PASSED with a
> ## truncated `for` list. Read a re-pointed gate's PASS by its per-item
> ## lines, and grep `'\\ *# re-pointed'` after every sweep.
> ##
> ## **OPEN, unchanged:** the maintainer's 1:1 wheel mockup (replaces the
> ## outline tiles through the same knobs); random select "include the
> ## tenants" (shape in STATE 14z-116, not built); #112/#113 parked; the
> ## FBNeo two-run-family question; the tenant CPU AI "lackluster" note.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged19
> ## fbneo`. Current + one back: `don_m15/m16`, `hui49/50`, `pyron33/34`,
> ## `m3b_merged18/19`, `m5_stock10/11`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-116 close, 2026-08-29 — superseded by the 14z-117 opener above)

> ## **START HERE. THE WORK IS THE FREEZE BATTERY, and it is the whole
> ## session — start it fresh, on a full context budget. 14z-110b closed at
> ## the context ceiling with three validations in flight and cost 14z-111
> ## an opening audit; do not repeat that.**
> ##
> ## **WHAT IS WAITING TO BE FROZEN:** `build/m3b_merged19`
> ## (fingerprint `af21bc88`) — merged18 PLUS one fix: **Pyron's medallion
> ## white-out**. `PRG:0x05F9D0`'s P2 branch no longer writes palette row
> ## `0x1A` (`tst.b $381(a4)` -> `bne` to the pop/rts, two NOPs where
> ## `adda.w #$60,a1` was; SAME byte count, so no allocation ripple and
> ## **no re-point sweep for the thunk itself**). FIELD-VALIDATED on the
> ## board: medallion correct, the P2 select sword now orange, select
> ## screen only, "a good tradeoff". Detail: `donovan.toml`'s
> ## `select_sword_pal_variant_id` comment; gate
> ## `tests/test_pyron_medallion_2p.sh`.
> ##
> ## **WHY THE BATTERY SHOULD BE CHEAP THIS TIME, and where to check that
> ## assumption first:** the change is TEN BYTES inside one already-existing
> ## thunk body, on a path that runs only on a P2 TENANT HOVER. Measured at
> ## 14z-116: `38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select`
> ## are **BIT-IDENTICAL** between merged18 and merged19. Replay 38 is the
> ## one whose one-main-loop slip forced the 14z-88 revert, so that is the
> ## meaningful control. **EXPECT the solos to move** (they rebuild) and
> ## expect the tenant select rigs' self-frozen `.sha1`s to move on the
> ## P2-hover ones; attribute them by DUMPS diff as always.
> ##
> ## **THE BATTERY, in the 14z-115 order** (STATE 14z-115 has the full
> ## list): rebuild solos + merged + the stock twin (expect the stock twin
> ## UNCHANGED — the thunk is `only_variant_slot`) -> `run_suite` verify on
> ## the three sets -> `audit_merged_legacy` 47/47 -> `audit_guard_corpus`
> ## -> `audit_roster_pairings` 111/111 (**re-derive `bases.tsv` first** —
> ## it has rotted twice) -> `audit_legacy_pairings` -> `test_dualtrack`,
> ## `test_m3a_reproducible`, `test_fbneo_legacy_oracle`, `test_pointer_flow`
> ## (re-freeze WITH attribution), `pcrel`/`escape_triage`, `inp corpus`,
> ## the wheel/MiSTer/release gates -> `run_all_static --strict` -> tags,
> ## registry row, re-point sweep, N-2 build-dir sweep -> **the MiSTer tail
> ## (group C does NOT move, but the PROGRAM does: `gen_vsavjw_xml.py
> ## --check` will go red, so a new fork catalogue commit + patch + pin bump
> ## + bundle + `release/merged-m12/` are all needed)** -> docs.
> ## **NEW GATES TO INCLUDE, none in ci_static:**
> ## `tests/test_pyron_medallion_2p.sh`, `tests/test_shadow_tenant.sh`
> ## (both emulator tier, HANDOFF-indexed), and `test_win_quote_decode`
> ## (ci_static, already registered).
> ##
> ## **MARK: M9 -> M10** (`version_text` in all three manifests).
> ##
> ## **WHAT 14z-116 SETTLED, so none of it is re-derived:**
> ## **WIN QUOTES — FORGONE** by ruling, parked CLEAN-WAY-ONLY (the 14z-76
> ## whole-bank relocation is ruled OUT: it moves `RAM:$FFF230` on legacy
> ## win screens). A data-only fix is impossible (zero free bytes at BOTH
> ## hops); the real cost is ~330 GLYPH TILES. Tools + gate in the tree.
> ## **RANDOM SELECT** cannot pick a tenant — fixed 15-entry table at
> ## `PRG:0x020C88`, hard bounds; **the maintainer ADDED "include the
> ## tenants" to the list** (fix shape recorded in STATE, not built).
> ## **SHADOW** is armed by FIVE START PRESSES on the "?" cell and takes the
> ## character he JUST BEAT (`PRG:0x009BB2`, round end, unmasked) — he takes
> ## the TENANT, not the shell, confirmed on emulator and on the board in
> ## 2P vs. **MARIONETTE is a vs2 character**, parked. **No legacy character
> ## meets a tenant in 1P arcade** — ruled NOT A PROBLEM.
> ##
> ## **TWO TRAPS THIS SESSION PAID FOR, both in gate headers now:** the
> ## wheel route to the "?" cell is **Down, Down, Down-RIGHT** on a WIDE
> ## build (our port re-pointed cell `0x08`'s Down edge to Phobos, so
> ## vanilla's D,D,D is wrong); and Shadow's five STARTs are PRESSES, with
> ## the 6th DISARMING.
> ##
> ## **OPEN:** the maintainer's 1:1 wheel mockup (replaces the outline tiles
> ## through the same knobs, nothing to undo); #113 parked; #112 and the
> ## tenant CPU AI "lackluster" observation recorded, unscheduled. The
> ## FBNeo instrument question is NARROWED (the "unidentified writer" is
> ## retired — the binary's mtime is 2026-08-17, eleven days before the
> ## session that flagged it) but the two run families are still unexplained.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged19
> ## fbneo`. merged18 is the last FROZEN set (merged-m11, M9); merged19 is
> ## the candidate. Everything is PUSHED (`origin/main` = `8055a27`).


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-114 close, 2026-08-28 — superseded by the 14z-115 opener above)

> ## **START HERE. NOTHING IS RED. SIX SKILLS EXIST AND ARE LOCKED TO THE
> ## DOCS — load the relevant one BEFORE the work, every session.**
> ##
> ## **WHAT EXISTS NOW (`.claude/skills/<name>/SKILL.md`):**
> ## `mister-cps2-wide-core` (`[MSC-1..73]`, level 1) and `mister-vampire-saved`
> ## (`[MSV-1..36]`) for the FPGA lane; `cps2-hardware` (`[CPH-1..30]`) and
> ## `cps2-emulation` (`[CPE-1..42]`) for the board and the two emulators as
> ## instruments; `vampire-savior-engine` (`[VSE-1..83]`, the game's laws, NO
> ## ROM addresses); `vampire-saved-port` (`[VSP-1..161]`, THIS port's
> ## discipline — CLAUDE.md by citation, the oracle classes, the pipeline law,
> ## freezes/releases/the suite, every rig and how it lied). 425 rules. Each
> ## rule is anchored `**[PFX-N]**` at the doc paragraph it distils and
> ## `tools/checkskills.py` (`tests/test_checkskills.sh`, ci_portable, eight
> ## must-fire controls) locks both directions, lints level 1 for game words,
> ## refuses any number not in a LOG, resolves cross-references, and refuses
> ## a VSP anchor anywhere in STATE.md outside "STANDING PRINCIPLE" / "THE
> ## DEADNESS REGISTER" (the file rolls). Plan and boundaries — now the
> ## record — `docs/project/skills_scope.md`; five decisions OPEN TO VETO in
> ## STATE "Decisions pending".
> ##
> ## **THE ONE RULE THIS ADDS TO EDITING DOCS:** an anchored paragraph carries
> ## its marker — rewrite the fact and keep the marker with it, or move the
> ## rule; delete the paragraph and the gate goes red, on purpose. Four
> ## staleness passes (MiSTer S1-S20 in 14z-113; A+B, C, D in 14z-114) ran
> ## BEFORE distilling, each its own commit; the docs the skills cite are the
> ## corrected ones.
> ##
> ## **NOT PUSHED:** everything after `bb8ecde` (the MiSTer skills) is local —
> ## six commits + the close. Push only at the maintainer's word; check
> ## `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** #113 stays OPEN (camera evidence in progress — do
> ## not close, do not re-derive); two D staleness items flagged UNVERIFIED
> ## (skills_scope §4 row D); re-filing candidates for the maintainer
> ## (fourteen emulator-fact entries in `project/gotchas.md`, the 14z-90
> ## onset entry in `game/gotchas.md`); housekeeping deferred
> ## (`build/m3b_merged15` referenced by `test_inp_crash_merged_m8_01` defect
> ## mode; STOCK CONTROL once-per-`.rbf`, unruled; the cosmetic backlog —
> ## DISASSEMBLE, NEVER SCAN).
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17` (M8 mark;
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`); solos `don_m14` /
> ## `hui48` / `pyron32`, stock twin `m5_stock9`; bitstream seed 18269 at
> ## `release/bitstreams/CURRENT`. Strict static at close: 111/0/0/0.


## (HISTORY) NEXT SESSION orientation (written mid-14z-114 after C, 2026-08-28 — superseded by the close opener above)

> ## **START HERE. NOTHING IS RED. THE MiSTer SKILLS EXIST AND ARE LOCKED
> ## TO THE DOCS — load them before any MiSTer work.**
> ##
> ## **WHAT 14z-114 DID, one breath:** a retraction first (the merged-m10
> ## registry row still called the `.rbf` "on the synthesis box"); then the
> ## distillation. **Two skills**: `mister-cps2-wide-core` (level 1,
> ## game-independent, `[MSC-1..73]`, sections 1.1-1.7 + 1.8 "what is NOT
> ## known") and `mister-vampire-saved` (level 2, `[MSV-1..36]`, 2.1-2.5),
> ## one section per `mister_scope.md` row. **The checker shape, decided
> ## before a rule was written: the docs ARE the human rendition.** Each rule
> ## is anchored `**[MSC-N]**` at the paragraph it distils and
> ## `tools/checkskills.py` (`tests/test_checkskills.sh`, ci_portable) locks
> ## it both ways, lints level 1 for game names/ceilings/build dirs, and
> ## refuses any number not present in a LOG. **Its first real run found
> ## that every 14z-108/109 measurement was missing from `platform/mister.md`**
> ## — entered there now — and that skill 2.5 had no live carrier:
> ## `docs/project/mister_field.md` (field test + triage) is new.
> ##
> ## **THE ONE RULE THIS ADDS TO EDITING DOCS:** an anchored paragraph carries
> ## its marker — rewrite the fact and keep the marker with it, or move the
> ## rule; delete the paragraph and the gate goes red, on purpose.
> ##
> ## **SAME SESSION, LATER — THE PLAN FOR THE REST AND PAIR A+B SHIPPED:**
> ## `docs/project/skills_scope.md` plans four more skills (five decisions
> ## under stated assumptions, OPEN TO VETO in STATE); `cps2-hardware`
> ## (`[CPH-1..30]`) and `cps2-emulation` (`[CPE-1..42]`) are distilled and
> ## locked; **then C shipped too**: `vampire-savior-engine` (`[VSE-1..83]`,
> ## no ROM addresses) after the game staleness pass S-C1..S-C12 (the DF
> ## "palette OPEN", the capture-pose "feasible" and win-screen "#105 open"
> ## headers were all years-of-sessions stale; the game gotchas' title line
> ## had an entry spliced into it). **264 rules / 5 skills, `checkskills`
> ## ALL PASS, seven controls. NEXT: D, the port skill `vampire-saved-port`**
> ## — its staleness pass first (`project/gotchas.md` 179 entries with
> ## RESOLVED cross-refs, `hardening_register.md` and `build_dir_triage.md`
> ## dated to the 14z-102/103 sweeps, HANDOFF playtest defaults), then rules
> ## that ANCHOR INTO CLAUDE.md and never restate it (decision 3).
> ##
> ## **OPEN, unchanged:** #113 stays OPEN (camera evidence in progress — do
> ## not close, do not re-derive); housekeeping deferred (`build/m3b_merged15`
> ## referenced by `test_inp_crash_merged_m8_01` defect mode; STOCK CONTROL
> ## re-scoped to once-per-`.rbf`, recommendation unruled; the cosmetic
> ## backlog — DISASSEMBLE, NEVER SCAN). **FUTURE, unscheduled:** the other
> ## skills the maintainer sketched (CPS-II emulation, VS/VS2/VH2) — reuse
> ## this checker pattern; the living-documentation effort.
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17`
> ## (`tools/run_wide.sh build/m3b_merged17 fbneo`); bitstream seed 18269 at
> ## `release/bitstreams/CURRENT`; everything pushed once this session's
> ## commit lands (check `git ls-remote`, not this line).


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-113 close, 2026-08-28)

> ## **START HERE. NOTHING IS RED. EVERYTHING IS PUSHED. THE OPENER IS THE
> ## MiSTer SKILLS — and the reason this is a fresh session is the method:
> ## the skills are distilled from the docs AS THEY NOW READ, not from any
> ## session's memory of them.**
> ##
> ## **WHAT 14z-113 SETTLED, one breath:** the scope document
> ## (`docs/project/mister_scope.md`) and its three rulings; the S1-S20
> ## staleness pass (every MiSTer doc's STATUS line is current — pin
> ## `63496069`, 24 fork patches registered, "hardware: never" retired,
> ## `cps2_wide.md` says RATIFIED); bundle 14z112 field-verified ("no
> ## regression", stock coexists, STOCK CONTROL boots); **merged-m10
> ## FROZEN** (`build/m3b_merged17`, M8 + fingerprint `32007911` unchanged,
> ## packaging only, tag pushed, MiSTer tail empty); **the RELEASE FORMAT
> ## ruled and shipped** — `release/merged-m10/{fbneo,mame,mister}/`, each
> ## self-sufficient, every version releases every platform
> ## (`docs/project/release_format.md`, `tools/package_release_platforms.py`,
> ## `test_release_roundtrip.sh` §4).
> ##
> ## **THE WORK: THE MiSTer SKILLS, per `mister_scope.md` §2-§3** — level 1
> ## CPS-II/WIDE core (1.1 separate-core mechanism, 1.2 the runtime profile
> ## bit, 1.3 SDRAM tiers/slots/placement RULES, 1.4 the format caps + the
> ## nine gated sites, 1.5 the simulation lane + instruments, 1.6
> ## synthesis/release, 1.7 MRA/`.rom` mechanics) and level 2 VS-specific
> ## (2.1 the roster's demand, 2.2 the placement NUMBERS, 2.3 catalogue/
> ## MRA/bundle generation — now `release_format.md`, 2.4 the WIDE oracles,
> ## 2.5 field test + triage). Each row names its sources BY SECTION and its
> ## gates: **read those sections, not this file.** The liftability test
> ## decides every placement: if it names `vsav`, a tenant, `0xEE73`/
> ## `0xFFDB`, a fingerprint or a build dir, it is level 2.
> ## **A SKILL SHIPS WITH ITS CHECKER** (STATE "Decisions pending", the SMS
> ## `checkskills.py` pattern): ID-lock each skill to the doc sections it
> ## distils so the two cannot drift; a skill that quotes a number cites the
> ## LOG (`mister.md` / `mister_map.md` / `mister_fit.md`), never the
> ## synthesis — that is `mister_core.md`'s own staleness rule. Decide the
> ## checker's shape FIRST; it is the design question of the session.
> ## `mister_scope.md` §7 lists the holes a skill must state rather than
> ## hide (pixels and audio never MEASURED, timing a seed lottery, bank 1
> ## on one replay, silicon's decryption window inferred).
> ##
> ## **THE `.rbf` IS IN THE TREE (post-close, same day):** canonical at
> ## `release/bitstreams/18269/` (+ `CURRENT`), hash-verified into every
> ## release's `mister/` by the packager, never copied release-to-release;
> ## `merged-m10/mister/` regenerated from it. A NEW bitstream = a new seed
> ## dir + a `CURRENT` bump, never an overwrite.
> ## **ONE SMALL THING MAY LAND FIRST: #113** — OPEN by the maintainer's
> ## instruction: camera evidence in progress that hardware may DISAGREE
> ## with the emulator finding. Do not close it, do not re-derive the
> ## emulator measurement; if the board shows something the emulators do
> ## not, that is a rendering finding (palette / CPS-B layer register at the
> ## white frame — never measured), not a game-data one.
> ##
> ## **HOUSEKEEPING, deferred:** `build/m3b_merged15` (N-2) still referenced
> ## by `test_inp_crash_merged_m8_01` defect mode — re-point or keep, the
> ## maintainer's call; the STOCK CONTROL MRA kept, re-scoped to
> ## once-per-new-`.rbf` (recommendation, unruled); the cosmetic backlog
> ## (win-quote text for the three tenants, ladder names/pictures, wheel
> ## polish, #112 — DISASSEMBLE, NEVER SCAN) parked as one later pass.
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17` (play:
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`); the field bundle
> ## `../mister_fieldtest_14z112/` IS this set. `run_all_static --strict`
> ## PASS 110/0/0/0 at close.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-112 close, 2026-08-27; updated during 14z-113)

> ## **START HERE. NOTHING IS RED. #99 IS CLOSED. The tree is green
> ## (`run_all_static --strict` PASS 110/0/0) and everything is pushed.**
> ##
> ## **TWO THINGS ARE WAITING ON THE MAINTAINER'S HARDWARE — do not
> ## re-derive them, just read the answer when it comes:**
> ## **(1) #113** — the one-frame white-out at a down is MEASURED VANILLA
> ## (identical on stock `vsavj` AND `vsav2`; gate
> ## `tests/test_down_flash_vanilla.sh`). His MiSTer double-check closes it.
> ## **(2) BUNDLE `../mister_fieldtest_14z112/` — ANSWERED 14z-113
> ## (maintainer, 2026-08-28): NO REGRESSION.** Stock renders correctly on
> ## Jotego's own core from the shared pristine `vsav.zip`, WIDE runs on
> ## ours, the STOCK CONTROL boots too. One-zip packaging is field-proven
> ## and **FROZEN as merged-m10 (14z-113): `build/m3b_merged17`, M8 mark
> ## and fingerprint `32007911` UNCHANGED, tag `freeze/merged-m10`,
> ## `release/merged-m10/` with the first in-tree `mister/` layer (MRAs +
> ## BITSTREAM.txt; the `.rbf` itself is not in the tree yet — the RELEASE
> ## FORMAT is the open item *[HISTORY — both done post-close 14z-113, see the
> ## live opener above]*). Play with
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`.**
> ## **#113 stays OPEN: the maintainer is gathering camera evidence that
> ## original hardware/MiSTer may DISAGREE with the emulation finding —
> ## do not close it, do not re-derive the emulator measurement.**
> ## The STOCK CONTROL's remaining use is the superset invariant ON SILICON
> ## — run it once per new `.rbf`, not per release (STATE "Decisions
> ## pending"). **Next by the maintainer's own sequencing: the S1-S20
> ## staleness pass, then the MiSTer release format, then the skills.**
> ##
> ## **THE MiSTer SCOPE DOCUMENT IS DONE (14z-113):
> ## `docs/project/mister_scope.md`** — the two-level split with each
> ## skill's boundary/sources/gates, the doc dependency map, and the
> ## **known-stale inventory S1-S20** (file:line). All ~5,000 lines were
> ## read; NOTHING was corrected (scope only). **THREE DECISIONS SIT IN
> ## STATE "Decisions pending"**: confirm the split; run the staleness pass
> ## BEFORE the skills (recommended — `mister_core.md` still says "hardware:
> ## never" and `patch_index.md` registers 7 of 24 fork patches); and where
> ## the `.rbf` lives (cited by three docs, tracked by none). The
> ## `mister_mra.sh` HEADER correction 14z-112 asked about IS in place.
> ## **If the pass is approved, it is the next session's work: one commit,
> ## retraction discipline, headers and summary lines first.** Note S20:
> ## every HANDOFF MiSTer example still names `build/m3b_merged13`, which
> ## the 14z-112 sweep DELETED — those commands are non-runnable as written.
> ##
> ## **THE COSMETIC BACKLOG (STATE, parked as ONE later pass):** win-quote
> ## TEXT for ALL THREE tenants (each still shows its SHELL's quote; art is
> ## already native), arcade ladder MAP NAMES + PICTURES, SELECT WHEEL
> ## polish, and **#112** (Press of Death black foot — DECIDED cosmetic).
> ## None is competitive-2P surface.
> ##
> ## **IF YOU TOUCH #112 AGAIN, THE METHOD IS THE FINDING: DISASSEMBLE,
> ## NEVER SCAN.** 14z-112 produced TWO retractions, both from byte scans
> ## matching across instruction boundaries (`e768 7105` in base territory;
> ## `0028394E` = a displacement word plus the next opcode). What IS
> ## measured: the entire draw path is VANILLA down to the writer
> ## instruction `PC 0x01B2BE` (byte-identical to stock), and WHY a tenant
> ## runs that vanilla sequence is UNKNOWN. Do not re-derive the
> ## eliminations — they are listed in STATE 14z-112.
> ##
> ## **STATE OF THE BUILDS:** `build/m3b_merged17` is the repackaged set —
> ## NOT registered, NOT frozen; freezing is a separate decision once the
> ## board confirms. `build/` was swept to 2.9 GB (current + one back per
> ## track). **Before deleting any build dir, grep FOUR places** — `tests/`,
> ## `tools/`, **`build/manifest/`** and `docs/` — excluding comment lines,
> ## and run `--strict` BEFORE committing: a fixture loss shows up as a
> ## gate degrading to SKIP, not as a failure
> ## (`docs/project/build_dir_triage.md`).
> ##
> ## **RECORDINGS ARE INFRASTRUCTURE NOW:** playback stops at the end of
> ## HUMAN input (`-exit_after_playback`, `PLAYBACK <n>` in every log), so
> ## the attract demo can no longer be scored as play. Instruments:
> ## `tools/run_inp_probe.sh` (video hash, HP/death, OBJ counts, snapshots,
> ## OBJ dumps, `GFXRANGE`, `RECT_AUDIT`, `WRITETAP`, `FINDBYTES`),
> ## `tools/run_inp_guarded.sh` (crash capture), `tools/audit_effect_rects.py`
> ## (an INSTRUMENT, not a gate — read its header).



## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-109 CLOSE, 2026-08-26)

> ## **START HERE. THE OPENER IS THE #99 FIX WINDOW — census, remap rule,
> ## the #111 coverage repairs, then the re-freeze. Everything is ruled;
> ## nothing is open except the work.**
> ##
> ## **WHAT HAPPENED IN 14z-109, one breath:** the FIELD TEST PASSED — the
> ## core boots on a real DE10-Nano, tenants selectable and playable,
> ## TENANT VOICES PLAY ("fetched is not heard" is retired), select screen
> ## emulator-identical, feel better than emulator — with ONE
> ## 100%-reproducible crash, which was ROOT-CAUSED the same day: **#99 =
> ## vs2 type byte `0x51` at node `ROM 0x3FB899` inside DONOVAN'S ported
> ## block**, walked by Donovan's OPPONENT (any — Phobos AND Bishamon both
> ## crashed it in the field), indexing past vsavj's 80-entry FSM jump
> ## table at `PRG:0x018510` -> word `0x0001` -> odd jump -> vec3 -> the
> ## game's own exception handler soft-boots to the NAME SCREEN. Every
> ## field observation is downstream of this. Full trail: STATE 14z-109
> ## (3)-(8); mechanism docs: engine_internals "CPU exceptions" + "The
> ## object-script state dispatcher"; GitHub #99 is current.
> ##
> ## **THE RULING IS TAKEN (maintainer, 2026-08-26) — (a)+(b)+(c):**
> ## (a) fix shape A: DATA-SIDE EXTRACTION REMAP — the dispatcher (vanilla
> ## code on the legacy path) is NEVER patched. (b) `0x51 -> 0x19`:
> ## vs2's `0x51` aliases vs2's DEFAULT handler (`move.b (0x17,a3),
> ## (0x54,a1); rts`) and vsavj's default at table offset `0x17C` (handler
> ## `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
> ## BYTE-IDENTICAL — the remap is instruction-level exact, zero gameplay
> ## surface. (c) THE CENSUS with the ESCALATION CLAUSE: scan ALL THREE
> ## tenants' node streams (0x18-byte nodes, next-state byte at +0x17) for
> ## values `>= 0x28`; default-alias hits auto-remap by the same
> ## handler-equivalence proof; **anything else returns to the maintainer
> ## as its own decision.**
> ## **THE STANDING CAVEAT ON ESCALATED HITS (maintainer's own
> ## instruction, also a persistent memory):** "port the handler" LOOKS
> ## best but is NOT FREE — memory, cycles, side-effects. Order: measure
> ## what the state DOES and how often content reaches it -> consider
> ## neutralize-to-default -> port ONLY if feel demonstrably needs it.
> ## **Raise this point if the maintainer seems too eager to approve a
> ## port.**
> ##
> ## **HOW THE FIX LANDS (the mechanism already exists):** the extraction's
> ## `data_port` rows carry a `fixes = "off:old:new"` field — the #92 stage
> ## bytes shipped exactly this way (`voice_borrow_voicenums_b`,
> ## patch_notes 14z-94). The census names the offsets; the remap becomes
> ## `fixes` entries (or a dedicated family-aware rule if the hits are
> ## many) on the ops that port each tenant's block. **The census must be
> ## FAMILY-AWARE — walk the node streams the way the FSM does; a blanket
> ## byte replace would corrupt nodes whose +0x17 is not a state.** Anchor
> ## facts for the walker: our node `0x3FB882` = vs2 `0x0C9CAA` (verbatim,
> ## unique content hit); Donovan base `0x3FA9D0`; the vs2 FSM table is
> ## `0x016D34` (0x54=84 entries), ours `0x018510` (80 entries; valid
> ## 0x00-0x4F — vs2's 84 make 0x50-0x53 the renumber gap). CORRECTED
> ## 14z-110: was "~0x28".
> ##
> ## **#111 LANDS IN THE SAME WINDOW:** re-point `26_don_arcade_mash`'s
> ## navigation (U,U,R lands on JEDAH on the 21-cell wheel; L,L,D,D
> ## reaches Donovan — measured), re-measure `audit_continue_switch.sh`'s
> ## trajectory per its own header, and ADD the missing gate: Donovan vs
> ## CPU-Phobos (and ideally each tenant vs each tenant CPU). **The venue
> ## byte `$FF8121` makes that DETERMINISTIC: the draw pool is
> ## `row[venue..venue+7]` (measured 12/12) — venue `0x02` = Phobos first
> ## on his paired stage, venue `0x10` = Bishamon-then-Phobos, the two
> ## field contexts.** A 2P replay exists too: `109_2p_don_vs_phobos.rpl`
> ## (P2 scripting landed this session — fork `4dfc3734`, bits 12+,
> ## frozen sha1s provably unmoved).
> ##
> ## **THEN THE RE-FREEZE (donovan-m12 / huitzil-m21 / pyron-m15 /
> ## merged-m7), and its MiSTer TAIL:** a romset rebuild moves CRCs ->
> ## `tools/gen_vsavjw_xml.py --check` goes red -> the fork's catalogue
> ## entry needs a NEW COMMIT and the MRA/bundle for the board must be
> ## REGENERATED (`../mister_fieldtest_14z108/` becomes stale the moment
> ## the freeze lands). Budget it; the field crash is the whole reason for
> ## the window, so the maintainer will want the new bundle on the SD card.
> ##
> ## **CRASH-TRIAGE KIT, if anything else ever "flaky-resets":**
> ## name-screen reboot = CPU exception (code at `$FF0000`, regs at
> ## `$FF0018-53` — but ONLY if the handler runs; under the guard read
> ## regs via `GUARD_PROBE`, the RAM block stays stale); gold full test =
> ## cold/watchdog. Method: deterministic lab rat -> vector+ADDR ->
> ## `GUARD_PROBE_HIST` -> conditional register probe (PROBE prints
> ## A1/A3 since 14z-109). Three guarded runs took #99 from "flaky" to a
> ## named byte.
> ##
> ## **ALSO NEW THIS SESSION, so it is not re-derived:** the OBJ-LIST
> ## ORACLE — first cross-implementation video-determining agreement
> ## (promoted subset field-identical at match anchor AND select screen;
> ## M6 mark identical; `test_mister_obj_oracle.sh` + `test_obj_records.sh`,
> ## HANDOFF rows); the DECISIONS CLEANUP — resolved rulings live in
> ## `DECISIONS_HISTORY.md` (topic-greppable, retraction grep covers it),
> ## STATE keeps only live items; the repo-root dump litter moved to
> ## `../dumps/` (README inside; all regenerable).
> ##
> ## **PUSH STATE: everything is pushed** — `origin/main` current at the
> ## close commit, fork at `4dfc3734` (20 commits, public). Check
> ## `git ls-remote`, not prose. **Scratch:** the jtsim clone
> ## `/tmp/vampire-saved-jtsim-14z108` was SWEPT at this close (field test
> ## reported; rebuild is one `setup` command); `../mister_fieldtest_14z108/`
> ## is DURABLE but goes STALE at the re-freeze; `../dumps/` is the
> ## maintainer's, safe to delete wholesale per its README.



## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-108 CLOSE, 2026-08-25)

> ## **THE OPENER IS THE FIELD TEST, AND IT IS THE MAINTAINER'S.**
> ## Simulation is EXHAUSTED for this arc. A tenant fights on the core and
> ## fights CORRECTLY against MAME; the QSound extension is fetched; bank 1
> ## under load is GO; scroll is structurally cleared; the core fits a
> ## Cyclone V. **Nothing further in Verilator moves the arc** — the three
> ## things still never done all need hardware or a different surface:
> ## PIXELS compared, a tenant's voice HEARD, and anything at all on real
> ## silicon.
> ## **THE BUNDLE IS BUILT AND VERIFIED**: `../mister_fieldtest_14z108/`
> ## (outside the repo, rule 7) — the WIDE MRA, `vsavjw.zip`, the PATCHED
> ## `vsav.zip`, `qsound.zip`, and a README. All 31 CRC-identified parts
> ## were checked to resolve, because an unresolved part is filled with
> ## `0xFF` rather than refused.
> ## **THE `.rbf` IS NOT IN IT** — it comes from the Windows box, and its
> ## sha256 must be checked first (`46fc74af…`, seed 18269): **a
> ## timing-FAILING seed emits a bitstream indistinguishable from a good
> ## one**, and 4 of 12 seeds fail.
> ## **AND THE BUNDLED `vsav.zip` IS PATCHED** — four members carry the
> ## ported art, everything resolves by CRC, so a stock CPS-2 MRA pointed
> ## at it gets wrong art SILENTLY. Back up the pristine copy first.
> ##
> ## **WHAT THE FIELD TEST ANSWERS THAT NOTHING HERE CAN:** whether a
> ## tenant's VOICE PLAYS (we have proved those samples are FETCHED out of
> ## DSP bank `0x83`; "heard" is not reachable from simulation), whether
> ## the picture is right (no frame has ever been compared and VRAM turned
> ## out to be a dead end for that — see below), and whether any of it
> ## survives real SDRAM, real timing and the analog chain.
> ## **IF IT DOES NOT BOOT, report the failure MODE** — black screen vs
> ## RAM-test pattern vs a boot loop and its period. A ~1,580-frame loop is
> ## what the pre-D5 decryption bug looked like (**= about 26.5 s at the
> ## real 59.6374 Hz — a stopwatch is a valid instrument for this**).
> ##
> ## **UPDATED 14z-109: THE BUNDLE NOW CARRIES A NEGATIVE CONTROL AND A
> ## TRIAGE CARD.** The field test was about to be run WITHOUT a control,
> ## which by this project's own standard is not a measurement.
> ## `_Arcade/Vampire Savior (Japan 970519) [STOCK CONTROL].mra` runs stock
> ## `vsavj` on the SAME `.rbf` with the profile bit left at the `0xFF`
> ## fill, so **"does STOCK boot?"** separates a fault in our profile from
> ## one in the bitstream, the card, the SDRAM module or the video chain.
> ## `games/mame/vsavj.zip` added (1.5 MB); the control ALSO needs the
> ## maintainer's PRISTINE `vsav.zip` in place of the bundled patched one.
> ## **MEASURED, not assumed: against the bundle as shipped that MRA loses
> ## 8 of its 22 parts** — the four patched art members AND four program
> ## members — and unresolved parts are `0xFF`-filled rather than refused,
> ## so it would "run" and show nonsense. Both configurations were then
> ## checked part-by-part: **WIDE 31/31 resolve, STOCK 22/22 after the
> ## swap.** New `tools/check_mra_parts.py` + gate `tests/test_mra_parts.sh`
> ## (ci_portable, verdict logic ground-truthed with three refusals).
> ## `FIELD_TRIAGE.txt` is the symptom -> meaning -> next-action card.
> ## **AND THE BUNDLE README'S ITEM 5 WAS STALE AND IS FIXED** — it still
> ## called the identical 128 KB "scroll tilemap", still said the
> ## layer-enable registers were undocumented, and still invited the
> ## maintainer to treat a wrong-looking background as "the first hard
> ## evidence either way". All three were corrected LATER in 14z-108 than
> ## the README was written. **The bundle lives OUTSIDE the repo, so the
> ## retraction-discipline grep over `docs tests` could never have found
> ## it** — when a claim is corrected, the sweep has to cover artifacts
> ## that have already left the tree.
> ##

> ## **14z-109 (2): THE SELECT SCREEN CONFIRMS THE PROMOTE-BIT SPLIT IS
> ## THE RIGHT CUT, NOT A CONVENIENCE.** At select NO CPU OPPONENT HAS BEEN
> ## DRAWN, so the lottery that limits the match-anchor comparison is
> ## ABSENT — which makes it an independent test of the split itself.
> ## **Measured over 81 core frames vs 111 MAME frames, both NON-CONSTANT
> ## (21 and 31 distinct lists, so agreement is not cheap):**
> ## **the PROMOTED subset has an exact MAME twin on ALL 81 frames (100%),
> ## with 67-72 promoted entries — more than twice the match anchor's 31.**
> ## The WHOLE list matches on 55 of 81 (68%), **and every shortfall is in
> ## the UNPROMOTED (vanilla) part** — so our content agrees everywhere and
> ## the vanilla remainder carries some phase noise. **THAT REMAINDER IS AN
> ## OPEN QUESTION, NOT A DEFECT CLAIM: it is not the lottery (no opponent
> ## exists here), most likely a sub-frame sampling phase, and it has not
> ## been root-caused.** It is REPORTED, never asserted.
> ## **AND THE AUTHORED "M6" VERSION MARK IS IDENTICAL ACROSS
> ## IMPLEMENTATIONS** — codes `fe40`/`fe41` (the authored glyph tiles),
> ## palette row 0x19, same coordinates on both. The naked-eye A/B tell is
> ## now a MEASURED agreement rather than a picture.
> ## Gate: `tests/test_mister_obj_oracle.sh` section 3
> ## (`--select-sim-dir/--select-mame-log`), helper
> ## `tools/obj_select_compare.py`. Its 3z check FAILS if the select list
> ## is constant — a static screen would make agreement meaningless.
> ##

> ## **14z-109: A VIDEO-DETERMINING SURFACE FINALLY AGREES ACROSS
> ## IMPLEMENTATIONS — THE OBJ LIST.** 14z-108 ruled VRAM out as an oracle
> ## (two implementations legitimately differ there, the palette by HALF,
> ## and the legacy control reproduced it on stock `vsavj`) and named three
> ## candidate successors. The OBJ list is one of them; it was tried and it
> ## WORKS, because it is what the 68k BUILDS rather than something each
> ## implementation stages its own way.
> ## **THE RESULT, at the frozen tenant anchor (MAME 2886 / sim 3546):
> ## the PROMOTED subset is 31 entries on BOTH legs, ORDERED AND
> ## FIELD-FOR-FIELD IDENTICAL, and the 19-bit tile addresses slice D3
> ## computes are the SAME SET, `0x4b0c4-0x4ecda`.** The promote, the
> ## group-C redirect and the 3-bit bank are now confirmed against an
> ## unrelated codebase at the sprite-list level. **STILL NOT PIXELS** —
> ## this is the LIST, not the rendered frame.
> ## **THE TRAP THAT NEARLY PRODUCED A FALSE FINDING, and it is worth more
> ## than the result:** the raw lists do NOT match — 40 entries vs 129 —
> ## and the first reading of that was "the core draws a third of the
> ## sprites". **WRONG. A 1P replay's CPU opponent is the SOUND-STATE-FED
> ## LOTTERY** (`atlas/ram.md:99`; `test_mister_tenant_oracle` already
> ## excludes the P2 fields BY NAME for this reason), so the two legs fight
> ## DIFFERENT opponents and most of the list is their sprites. **An OBJ
> ## list cannot be filtered "by P2" the way a field table can — sprites
> ## carry no owner.** What rescues it is that OUR content IS labelled:
> ## y bit 12, the CPS-2 Turbo promote, is set on exactly the group-C
> ## sprites this port adds and on nothing vanilla can emit. Compare that
> ## subset and it is exact; the remainder is REPORTED, never asserted.
> ## **A LEGACY CONTROL WAS RUN AND IS ALSO CONFOUNDED** — `05_timeout_idle`
> ## is a 1P arcade replay, so it draws different opponents too (counts
> ## agree 52/57 vs 61, codes barely overlap). **Do not read that run as
> ## evidence either way; the lottery is in both.** A clean whole-list
> ## comparison needs a PINNED OPPONENT, which needs P2 scripting in
> ## `SimInputs` — still the deferred COVERAGE item.
> ## **Instruments: `tools/oram_obj_records.py` (calibrated byte-for-byte,
> ## 1153/1153 lines, against `tests/lua/obj_records_dump.lua` BEFORE any
> ## core data was read), gates `tests/test_obj_records.sh` (~2 min, MAME
> ## only) and `tests/test_mister_obj_oracle.sh` (~65 min, `--sim-dir/
> ## --mame-log` re-analyses finished runs).**
> ##

> ## **START HERE. THE ARC IS MiSTer. A TENANT HAS FOUGHT ON THE CORE,
> ## AND THE CORE FITS A CYCLONE V — BUT DOES NOT RELIABLY CLOSE TIMING.**
> ## Download -> boot -> select -> the extended wheel -> a tenant picked ->
> ## a tenant FIGHTING, with its fighter art coming out of SDRAM. Six RTL
> ## slices (D0-D5), the stock legs green, every control firing — and as of
> ## 14z-108 it SYNTHESISES and FITS, at +206 ALMs — but TWO SEEDS IN FOUR
> ## MISS TIMING, and the flow's own retry-until-pass hid that.
> ## **WHAT HAS NEVER HAPPENED IS HARDWARE.** No `.rbf` has been loaded
> ## onto a DE10-Nano, no MRA has run on real silicon, no analog output
> ## has been seen. Read those two halves together: the design is proven
> ## CORRECT in simulation and BUILDABLE on the toolchain, and it has
> ## never been switched on.
> ##
> ## **QUARTUS IS DONE — 14z-108. FIT: YES. TIMING: NOT RELIABLY.**
> ## Cyclone V 5CSEBA6U23I7, Quartus 20.1.1 Lite via `jotego/jtcore20x`,
> ## pin `7b9a0d2d`, **`cps2` built FIRST as the reference leg**.
> ## **FIT IS UNAMBIGUOUS AND GOOD:** +206 ALMs (+1.1%, 44% of 41,910),
> ## +2,048 memory bits, RAM blocks / DSPs / PLLs UNCHANGED, nothing near
> ## overflow. That half is settled.
> ## **TIMING IS A SEED LOTTERY, MEASURED AT n=12.**
> ##   `cps2w` (12): -0.545 -0.313 -0.110 -0.039 | 0.008 0.009 0.066
> ##                 0.067 0.147 0.167 0.202 0.396   -> 4 FAIL, med +0.038
> ##   `cps2`  ( 5):                 0.144 0.287 0.431 0.511 0.665
> ##                                                  -> 0 FAIL, med +0.431
> ## **The BEST of twelve `cps2w` seeds is worse than the MEDIAN of five
> ## `cps2` seeds; `cps2`'s WORST beats EIGHT of twelve.** Two `cps2w`
> ## passes are +0.008 and +0.009 — a quarter of the passing placements
> ## clear by under 10 PICOSECONDS. Failure rate 4/12, 95% CI ~14-61%:
> ## say "commonly", not "a third". FAILs are jtframe's OWN gate on runs
> ## Quartus called "successful, 0 errors".
> ## **`xjtcore.sh` CALLS `jtseed 4`, WHICH RETRIES AND BREAKS ON FIRST
> ## SUCCESS — AND BE PRECISE ABOUT WHAT THAT HIDES.** It does NOT ship
> ## failing bitstreams (~99% of invocations produce a passing `.rbf`).
> ## **It hides FRAGILITY: the artifact is a CHERRY-PICKED PLACEMENT.** A
> ## green run certifies "one placement was found that closes", never
> ## "this design closes with margin" — and only the second is a basis
> ## for building on.
> ## **WHERE IT IS MARGINAL:** every failing path is inside
> ## `jtframe_sdram64`, terminating at an SDRAM address pin, and the
> ## worst path RESHUFFLES between seeds (different source register AND
> ## destination pin each time). So it is not one slow path but the SDRAM
> ## controller's ADDRESS-GENERATION CONE AS A WHOLE — shared jtframe
> ## infrastructure the fork does not touch. **NOT WIDE's own logic**;
> ## WIDE loads that cone enough to lose the lottery, the control keeps
> ## enough margin to absorb the same variance.
> ## **WHAT IT DOES AND DOES NOT BLOCK.** It does NOT block shipping by
> ## itself — we distribute a PREBUILT `.rbf` and the baseline is a
> ## passing draw. It DOES mean +0.066 is not real headroom: a future
> ## slice cannot assume it, any rebuild is a lottery, and a jtframe
> ## uprev or Quartus version change could move it to mostly-failing.
> ## **Spending margin back (pipelining the SDRAM address path, reducing
> ## WIDE's load on that cone) is a DESIGN decision under Rule 1 v2 and
> ## is the MAINTAINER'S — not something to fix by seed-hunting.**
> ## **A FAILING SEED STILL EMITS AN `.rbf`**, indistinguishable from a
> ## good one by inspection — same size class, same filename, same
> ## published path. A sweep overwrote `release/mister/jtcps2w.rbf` with
> ## the WORST failing seed before it was restored. **VERIFY BEFORE
> ## FLASHING.** The shipping baseline is sha256 `46fc74af…`, **SEED
> ## 18269**, slack +0.066, gate PASS — jtseed's own random draw and the
> ## +0.066 row of the n=12 table, i.e. a passing draw from the
> ## distribution in which a third fail, NOT a privileged build.
> ## Rebuild it with `jtcore cps2w -mister --nodbg --seed 18269`, NOT
> ## with `xjtcore.sh` (which re-draws at random).
> ## **AND THE HASH WILL NOT MATCH ON A DIFFERENT DAY:** `build_id.tcl`
> ## compiles a `%y%m%d` datestamp in (`260825` here), so the same seed
> ## reproduces the PLACEMENT and TIMING exactly and a different
> ## bitstream. **The hash identifies the ARTIFACT, the seed identifies
> ## the RESULT** — never read a hash mismatch as a failed reproduction.
> ##
> ## **THE OPENER IS NOW HARDWARE — AND IT IS THE MAINTAINER'S, NOT
> ## MINE.** Synthesis settles BUILDABILITY and nothing else: no `.rbf`
> ## has been loaded onto a DE10-Nano, no MRA has run on real silicon, no
> ## analog output has been seen. That is a field test (`mister_core.md`
> ## §1: MiSTer + 128 MB module + Jammix -> CRT at native timing) and it
> ## needs the maintainer at the board. **Before it: MiSTer PACKAGING is
> ## still unanswered** — which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours (STATE "Decisions
> ## pending"). Both must be settled before anything ships.
> ##
> ## **THE §4 TENANT ORACLE IS DONE — 14z-108, AND IT AGREES.** A tenant
> ## does not merely fetch art on the core, it FIGHTS CORRECTLY: MAME
> ## anchor 2886, sim 3546, skew 660 (= the 659-frame transfer PLUS ONE,
> ## the same +1 the legacy replay shows on a 462-frame transfer, so the
> ## boot offset is a CONSTANT). **`p1_hitbox_base` is `0x003FA9D0` on
> ## BOTH legs** — the core loaded the tenant's RELOCATED character record
> ## from above `CPU:$400000`. HP, white HP, timer, position, meter,
> ## `ptr64` and `word132` all agree; the only disagreement is
> ## `p2_hitbox_base`, the sound-fed CPU draw, excluded by name for a
> ## measured reason and proven LIVE by a control. Gate:
> ## `tests/test_mister_tenant_oracle.sh` (emulator, ~65 min).
> ##
> ## **THE QSOUND EXTENSION IS FETCHED — 14z-108.** 210,180 reads over 76
> ## distinct blocks in the 1 MB HIGH window, DSP bank `0x83`, first at
> ## frame 3783 (inside the match, during the mash); control leg ZERO
> ## while still issuing 54 M QSound LOW reads. Confirms D1's width fix
> ## and D2's split end to end, and that the `SLOT5_AW=20` mask is
> ## lossless in practice. Gate: `tests/test_mister_qsound_ext.sh`.
> ## **FETCHED IS NOT HEARD** — no audio has been rendered or compared,
> ## and nothing in this lane ever has.
> ##
> ## **BOTH REMAINING SIMULATION ITEMS WERE ADVANCED 14z-108.**
> ## **SCROLL — structurally cleared.** Every scroll-path line in
> ## `cps2w`'s `jtcps1_sdram.v` override (`SCR_OFFSET = 0`, `rom1_cs`,
> ## `rom1_addr[19:0]`, `gfx1_addr`, the `slot1_*` bindings) is
> ## byte-identical to the shared `cores/cps1` original, and the scroll
> ## slot still sits in `u_bank2`/`u_bank3` in BOTH. The only slot1 the
> ## fork adds anywhere is `gfxc4_cs` on `u_bank1` — a different bank.
> ## **D2 cannot have moved scroll, by construction.** Rendering is still
> ## untested.
> ## **VIDEO — the first cross-implementation comparison of a
> ## video-determining surface, and it ended as a DEAD END worth
> ## knowing about.** Pixels need infrastructure neither side has, but
> ## VRAM `$900000-$93FFFF` is dumpable on both — by address on MAME, and
> ## on the core because D2 maps it to bank 0 byte `0x600000`. Compared
> ## at the frozen anchors, then RE-CUT along the real layer map once the
> ## video registers were documented. **(An intermediate reading called
> ## the identical `$910000-$92FFFF` "scroll tilemap" — that was WRONG:
> ## no layer base points there, it is UNCLAIMED VRAM.)**
> ##
> ## **THE VIDEO REGISTERS ARE NOW DOCUMENTED** (`atlas/ram.md`, "CPS-2
> ## VIDEO REGISTERS"): CPS-A at `$804100` is **WRITE-ONLY** so it needs
> ## the emulator's `cps_a_regs` SHARE, not a bus dump; CPS-B layer
> ## control is `+26`; every CPS-2 game shares one config. At the match
> ## anchor: scroll1 `$900000`, scroll3 `$904000`, scroll2 `$908000`,
> ## palette `$90C000`, **layer_control `0x2d0e` = ALL THREE SCROLL
> ## LAYERS ENABLED.**
> ## **RE-CUT ALONG THAT MAP, the diff reads: scroll1 22.3%, scroll3
> ## 2.9%, scroll2 17.7%, PALETTE 52.7% — and row-scroll plus every
> ## UNCLAIMED region (204,800 bytes, not zero) BYTE-IDENTICAL.** An
> ## earlier reading calling the identical 128 KB "scroll tilemap" was
> ## WRONG: no layer base points there.
> ##
> ## **THE LEGACY CONTROL WAS RUN AND IT SETTLES IT: THE DIFFERENCE IS
> ## NOT OURS.** Same core, same region, but STOCK `vsavj` and the legacy
> ## replay `05_timeout_idle` — scroll1 35.4%, scroll3 3.8%, scroll2
> ## 15.1%, palette 51.2%, row-scroll and unclaimed 0%. **Same pattern,
> ## same magnitudes, on vanilla content with the roster nowhere in
> ## sight.** A general MAME-vs-jtcps2 implementation difference; it says
> ## nothing about the profile, the roster or any slice.
> ## **THE USEFUL NEGATIVE RESULT — DO NOT REPEAT THIS APPROACH: VRAM IS
> ## NOT A VIABLE CROSS-IMPLEMENTATION VIDEO ORACLE.** Two unrelated
> ## implementations legitimately hold different bytes in the palette and
> ## all three scroll tilemaps (the palette by HALF), so that surface can
> ## never separate "our port broke something" from "these are different
> ## implementations". **A future video oracle needs a DIFFERENT surface:
> ## rendered frames, the OBJ list, or the palette AFTER the hardware's
> ## own conversion.** Row-scroll and every unclaimed region are
> ## byte-identical in BOTH runs (204,800 non-zero bytes, two romsets, two
> ## replays), so the transfer and dump paths are sound.
> ## **PIXELS remain never compared — and the cheapest route to that is
> ## now the FIELD TEST, where you simply look at the screen.**
> ##
> ## **THE SEED SWEEP IS DONE and is what produced the finding above.**
> ## It was commissioned because the attribution showed a five-path
> ## cluster at the limit on a term that is ROUTING. That reasoning was
> ## right and a single build would never have shown it. **More seeds are
> ## cheap (~12 min each) if the failing fraction is ever worth pinning
> ## down properly; with n=4 no pass RATE is quoted.**
> ##
> ## **QUEUED, ONE FORK COMMIT: `cores/cps2w/README.md` IS STALE.** It
> ## still says "Status: slice D1" and calls D2-D4 "not here yet", with a
> ## file table of FIVE `hdl/` files against the tree's THIRTEEN — written
> ## at `4840df8a` and never updated after `0df6f000`. Found by the
> ## Quartus session, which stopped and asked before building. Not fixed
> ## during 14z-108 because a README commit moves the pin out from under
> ## a build in flight; do it once the synthesis numbers land.
> ##
> ## **WHAT 14z-108 MEASURED, so it is not re-measured.**
> ## **(1) THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END**,
> ## not transposed in two. Measured on ALL FOUR against the game's own P1
> ## mirror `RAM:$FF8058.w` (`tests/replays/107_four_directions.rpl`,
> ## attract-only on STOCK `vsavj`, MAME vs `cps2w`, both dump sets
> ## integrity-checked): Up arrived as Right, Down as Left, Left as Down,
> ## Right as Up. 14z-107 (12) had two data points and inferred a two-bit
> ## SWAP leaving Up and Right untouched — **that was wrong, and a two-bit
> ## fix would have left half the defect in the tree.** Mechanism:
> ## `test.cpp:380` copies file bits 4-7 straight onto `joystick1[3:0]`
> ## and jtframe's port is MSB-FIRST (`jtframe_keyboard.v:107-110`), so
> ## the file map is `bit4=Right bit5=Left bit6=Down bit7=Up`. Fault is
> ## OURS, not jtframe's — one dict in `tools/rpl2siminputs.py`, no fork
> ## commit, no RTL. **The fork pin is unchanged at `7b9a0d2d`.**
> ## **(2) A TENANT FIGHTING.** `test_mister_gfxc_fetch --rpl
> ## 36_pick_tenant_cell --frames 4400` PASSES in full: obj bank 4
> ## **9,388,928 reads / 1,735 distinct codes `0xAD8F-0xEE42`**, 843
> ## traffic frames after match start; obj bank 5 206 codes; both inside
> ## their frozen extents; the control leg (header byte 41 `0xFE`->`0xFF`)
> ## at ZERO on both windows while still reading 105 M in bank 3.
> ## **(3) BANK 1 UNDER LOAD: GO.** Same run, `--stats`: ba1 peaks at
> ## 15,496 acc/frame (**12.5%** of ceiling) with the fighter art sharing
> ## the bank with QSound, and **ZERO `SDRAM reads clashed` in 3,738
> ## frames**. ba0 peaks 54,363 (43.9%), unchanged from stock.
> ##
> ## **THE ANCHOR DID NOT MOVE, AND THAT WAS PROVEN RATHER THAN ASSUMED.**
> ## `test_rpl2siminputs` freezes two values and the record said a bit-map
> ## fix moved BOTH. **It moved one.** `05_timeout_idle` scripts NO
> ## direction token, so its sha1 `eb3e1d04…` cannot change — and since
> ## that is `test_mister_sim_anchor`'s replay, its `sim_inputs.hex` is
> ## byte-identical across the fix and the frozen anchor (MAME 2146 / sim
> ## 2609 / skew 463) **could not move**. The 45-minute gate was NOT
> ## re-run, and the gate header states that as the reason. Corrected in
> ## five documents.
> ##
> ## **STANDING WARNINGS. ALL PAID FOR AGAIN THIS SESSION.**
> ## **(1) SUSPECT THE INSTRUMENT BEFORE THE RTL** — the count is now
> ## EIGHT, and 14z-108 added four more caught BEFORE use, all in one new
> ## analysis block: cumulative counters read as per-interval; a
> ## picosecond timestamp read as an index; a clash counter matching this
> ## report's OWN PROSE about clashes; and a "peak" that was the ROM
> ## DOWNLOAD on all four banks at once. A fifth — a `05`-independence
> ## check that PASSED because gawk's `and()`/`strtonum()` do not exist on
> ## BWK awk, so awk exited 2 and the `else` arm read as success — was
> ## caught only by writing its positive control first. **THE INSTRUMENT
> ## PROTOCOL (`docs/project/gotchas.md`) IS THE MOST LOAD-BEARING
> ## DOCUMENT IN THIS LANE.**
> ## **(2) NEVER EDIT A SCRIPT WHILE A RUN IS IN FLIGHT** — `sh` reads by
> ## byte offset. `tests/` and `tools/` were frozen for the whole 2.5-hour
> ## tenant run and all edits were made before it launched.
> ## **(3) CONFIRM THE RIG ON MAME BEFORE PAYING FOR THE SIM.**
> ## `36_pick_tenant_cell` was verified to reach P1 `+0x382 = 0x13` under
> ## MAME (a ~2-minute run) BEFORE the 2.5-hour simulation, so a zero from
> ## the sim would have been a finding about the CORE rather than about
> ## the replay.
> ##
> ## **AFTER QUARTUS, IN ORDER.** The QSound extension has never been
> ## heard; the scroll path with a wide GFX map is untouched; no frame has
> ## ever been compared programmatically against MAME's (the two committed
> ## select-screen images are a naked-eye pair, not a verdict);
> ## `mister_core.md` §12 is the honest ledger of all of it. **And the
> ## placement's margins remain thin: 0.125 MB of slack in 64 MB, SDRAM
> ## bank 1 EXACTLY FULL, and the group-C ROMSET REGION cannot grow at
> ## all** — tenant art may grow freely inside the existing 16 MB, but a
> ## fifth group-C member has nowhere to go.
> ##
> ## **STILL OPEN FOR THE MAINTAINER: MiSTer PACKAGING** — which MRA is
> ## the core's MAIN one, and how a release carries both `vsav.zip`
> ## flavours (STATE "Decisions pending"). Both must be answered before a
> ## release; nothing above blocks on them. **FUTURE, UNSCHEDULED:** the
> ## LIVING-DOCUMENTATION effort and DISTILLING AI SKILLS from the
> ## project's learnings. Both follow MiSTer.
> ##
> ## **THE GAME SIDE IS PARKED AND GREEN.** 14z-105 frozen as donovan-m11
> ## / huitzil-m20 / pyron-m14 / merged-m6, field-confirmed and pushed
> ## 2026-08-22; play with `tools/run_wide.sh build/m3b_merged13 fbneo`.
> ## Release packaging is done (`release/merged-m6/`).
> ##
> ## **THE LANE, IN TWO COMMANDS** (`HANDOFF.md` "MiSTer" has the rest;
> ## `export JTSIM_SCRATCH=/tmp/vampire-saved-jtsim`, NEVER inside the
> ## repo; ~1 s per simulated frame; the WIDE transfer is **659** frames
> ## and the stock one 462, so every absolute frame moves by 197; and
> ## `--wram` dumps an SDRAM address — `RAM:$FF0000` is bank 0 byte
> ## `0x600000` on `cps2`, **`0x648000` on `cps2w`**):
> ## `tools/run_sim_jtcps2.sh <rpl> <outdir> --frames N --wram A B` and
> ## `tools/mister_mra.sh --core cps2w --wide build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THE FORK: `DefinitelyFrenchName/jtcores@vampire-saved`, remote at
> ## `c97e3d14`, NINETEEN commits, PUBLIC AND CURRENT** — the 14z-109
> ## README update is pushed (maintainer-authorised 2026-08-26, with the
> ## note that the README and the rest of this test build can be
> ## removed or updated later if needed). Fork pushes are
> ## standing-authorised.
> ## **THE MAIN REPO: `origin/main` holds `10cf9ce` and NOTHING IS LOCAL**
> ## — re-checked with `git ls-remote` at the 14z-109 push, not read off a
> ## tracking ref. **The "one commit held back / push the fork first"
> ## situation earlier in 14z-109 is RESOLVED and no longer applies**: the
> ## fork went up first, then the pin bump, in that order, and the
> ## stranded state is gone.
> ## The 14z-107 close recorded "the main repo is NEVER pushed", which was
> ## true WHEN WRITTEN and has since been false three times. Do not repeat
> ## a push figure from prose — **CHECK `git ls-remote`**: a tracking ref
> ## is a claim about the last fetch, and prose is a claim about the day it
> ## was written. This paragraph is prose too.


> ## **SLICE LOG — 14z-107 (11)+(12): THE BOOT FAILURE ROOT-CAUSED AND
> ## FIXED (D5), THE FIRST TENANT TILE EVER FETCHED, BANK 0 ANSWERED, AND
> ## THE FIGHTER HALF BLOCKED BY THE HARNESS.**
> ## **D3 — the CPS-2 Turbo object promote** (fork `b9899fa8`),
> ## `cores/cps2w/hdl/jtcps2w_obj_bank.v`:
> ## `assign bank = { wide_en & table_y[12], table_y[14:13] };` read in the
> ## ELSE arm of the sprite-list terminator test, which is the reference
> ## core's VERBATIM (the ORDER is the rule: `table_y[15]` IS the
> ## terminator). `rom0_bank[2]` UNTIED, the bank three bits wide at every
> ## port from the frame table to SDRAM — which cost FOUR override files,
> ## three of them nothing but a width. **Swept over its whole input
> ## space:** 131,072 vectors, bank[2] set 32,768 times wide / **0** stock,
> ## the six `gfx_tiles.py` encodings each decoding to their own bank, none
> ## of them setting y bit 15. Two must-fire controls fire.
> ## **D4 — the 6 MB program window** (fork `dd242a65`):
> ## `wide_en & RnW & (A[23:21]==3'b010)`,
> ## `rom_addr`/`main_rom_addr`/`SLOT3_AW` 21->22, and the `one_wait`
> ## boundary `wide_en ? 4'h6 : 4'h5`. **It shipped WITH D3 because D3
> ## cannot be demonstrated without it:** the select screen's roster record
> ## is allocated in `wide_ext` above `CPU:$400000`, so a 4 MB decode
> ## cannot read the table that names the tenant cells and the promote has
> ## nothing to promote.
> ## **D5 — THE DECRYPTION RANGE, and it is the finding of the arc** (fork
> ## `c00d7ce7`; the retraction of D4's old claim is `7b9a0d2d`). See the
> ## banner above. The measurement that produced it is the 68k
> ## program-ROM read probe (`JTCPS2W_PRGPROBE`, fork `72738d51`,
> ## sim-only): ten completed reads above `$400000`, all at
> ## `CPU:$4BE7C0-$4BE7C8`, all `fc = 2` (USER PROGRAM — opcode fetches),
> ## every RAW word the `.rom`'s byte for byte and **every latched word
> ## different**; 54,961,148 reads below `$400000` as the must-fire
> ## control; a `wide_en`-clear leg completing zero. With D5 in, the same
> ## fetches arrive as memory holds them, completed reads above `$400000`
> ## go to **1,189,750** spanning `CPU:$412BA0-$4D100E` (= `wide_ext` to
> ## the byte) with 20,000/20,000 sampled records matching the `.rom`, and
> ## the boot reaches the select screen.
> ## **THE PAYOFF: 9,038,400 reads over 105 DISTINCT TILE CODES
> ## `0x74D6-0xFE41` in group-C obj bank 5** — the select-wheel tenant art
> ## — first at simulated frame 1556, every code inside the roster's frozen
> ## live extent `0xFFDB`, control leg at zero.
> ## `tests/test_mister_gfxc_fetch.sh`'s WHEEL half is GREEN.
> ## **BOTH STOCK LEGS GREEN WITH D5 IN** (the FPGA superset invariant on
> ## the one change that could have moved it): `test_mister_wide_inert`
> ## bit-identical work RAM 101/101 with its control firing, and
> ## `test_mister_sim_anchor` at 2609 / 2146 / 463. True by construction as
> ## well as by measurement — `rng_eff` IS `addr_rng` with `wide_en` clear.
> ## **BANK 0 UNDER THE REDIRECT: ANSWERED, GO** (14z-107 (12),
> ## `mister_map.md` §9 open question 1). 40,717 accesses/frame through the
> ## select screen = **32.9%** of its 123,825 all-miss ceiling, 41,535
> ## in-match, whole-run peak 54,363 (**43.9%**), data bus 16-18%, **ZERO
> ## `SDRAM reads clashed` in 3,500 frames**; the redirect costs ~1,000
> ## accesses/frame (~2.5%) against stock. The instrument verified its own
> ## phase boundaries — the run's anchor at **2806** = the frozen 2609 +
> ## the 197-frame WIDE/stock transfer difference.
> ## **OBJ BANK 4 IS STILL UNPROVEN AND THE REASON IS THE HARNESS** — see
> ## the opener. A tenant has still never fought on the core.
> ## **FOUR NEW GATES / INSTRUMENTS:**
> ## `tests/test_mister_prg_probe.sh` (ci_portable, ~3 s) — the probe's
> ## contract and `tools/prgprobe_verdict.py`'s VERDICT LOGIC, on synthetic
> ## logs whose answer is known by construction: three answers plus FOUR
> ## refusals, two of them frozen from the real defects.
> ## `tests/test_mister_prg_window.sh` (emulator, ~2 x 40 min) — the
> ## measured pair, frozen, two `.rom` images differing in ONE BYTE.
> ## `tests/test_mister_gfxc_fetch.sh` (emulator, ~2 x 65 min) — the
> ## demonstration; its first real measurement found TWO defects IN ITSELF
> ## (the tile code computed from the ABSOLUTE SDRAM address rather than
> ## relative to the armed window's base; a liveness control demanding
> ## vanilla obj traffic in a leg that cannot boot by construction).
> ## `tests/audit_sdram_bank_load.sh` gained the WIDE leg's real run.
> ## **AND TWO HARNESS INSTRUMENTS FROM (10), still the workhorses:**
> ## `JTFRAME_SIM_RDPROBE` (fork `17a5dc2b`) — FOUR SDRAM read counters,
> ## each a bank plus a half-open byte window, reporting reads / DISTINCT
> ## 128-byte blocks (which on CPS-2 graphics IS a tile-code list) / first
> ## frame / address range. Four slots and not two ON PURPOSE: two arm the
> ## windows under test and two arm windows that MUST see traffic, so a
> ## zero is evidence about the CORE and not about the probe. Units are
> ## burst BEATS, not ACTIVATEs. `JTFRAME_SIM_VIDEO_FIRST/_LAST/_STRIDE`
> ## (fork `fd454393`) bounds the frame writer, so a 4,000-frame run
> ## writes a filmstrip instead of ~3,000 jpgs.

> ## **SLICE LOG (history) — 14z-107 (9): MiSTer SLICE D2 IS DONE. THE WIDE ROMSET
> ## HAS A PLACE IN SDRAM AND EVERY BYTE OF IT WAS COUNTED.** Fork commit
> ## `0df6f000`, **PUSHED** (fork pushes are standing-authorised now; the
> ## MAIN repo is still never pushed *[CORRECTED 14z-108: not true any
> ## more — see the banner]*). `cores/cps1`/`cps2`/`cps15`
> ## BYTE-UNTOUCHED.
> ## **WHAT SHIPPED:** the bank-0 re-pack (VRAM `0x600000`, ORAM `0x640000`,
> ## WRAM `0x648000`, Z80 `0x658000`, making room for a 6 MB PRG), the
> ## group-C GFX redirect (obj bank 4 → SDRAM bank 1, obj bank 5 → bank 0),
> ## the QSound split across two banks on `pcm_addr[23]`, the PCM-high slot
> ## and the two GFX slots, and **ONE new jtframe file**
> ## `hdl/sdram/jtframe_ram1_7slots.v` — a mechanical sibling of
> ## `ram1_5slots.v`, pulled by `cores/cps2w`'s own `game.yaml` and NOT added
> ## to jtframe's shared `jtframe_sdram64.yaml` (that list is included by
> ## every core). `cores/cps2w/hdl` goes from four files to six.
> ## **EVERYTHING BEHAVIOURAL IS GATED — five `wide_en` sites now.** The one
> ## exception is declared, not hidden: the bank-0 re-pack is unconditional
> ## because `SLOTn_OFFSET` are elaboration-time parameters. It is a
> ## RELOCATION with no behavioural surface, and `test_mister_wide_inert`
> ## measures that (`cps2w` == `cps2`, bit-identical work RAM 540-640).
> ## **THE EVIDENCE IS AN SDRAM IMAGE CENSUS, NOT A REPLAY** — and it has to
> ## be: `rom0_bank[2]` is TIED LOW until D3, so D2 changes no fetch at all.
> ## `tools/mister_sdram_census.py` replays the download mapping (regions,
> ## the QSound split, the group-C redirect, the CPS-2 GFX scramble) and
> ## compares **all 67,108,864 bytes of all four banks**. PASS on every bank
> ## on the WIDE image (66,265,152 B, transfer complete at simulated frame
> ## 659). Controls: a 1 KiB shift of any constant is rejected; banks 1/2/3
> ## byte-identical between the two cores on a stock image with bank 0
> ## differing; banks 2+3 DIFFERING between them on the WIDE image, because
> ## without the redirect group C aliases onto vanilla's art.
> ## **AND THE CENSUS CONTRADICTED THE MAP. THE CENSUS WON.** The fit's slack
> ## is **0.125 MB, not 0.708**, and **SDRAM bank 1 is EXACTLY FULL**. The map
> ## sized the group-C obj banks by the art's live FOOTPRINT; the MRA
> ## downloads the whole declared region, so each reserves its full 8 MB.
> ## Both consequences point opposite ways: tenant art may now grow freely
> ## inside the existing 16 MB (one more tile overflows nothing), and the
> ## group-C ROMSET REGION cannot grow at all. Corrected in place in
> ## `mister_map.md` and in `tests/audit_mister_map_fit.sh`.
> ## **STOCK LEG GREEN:** `test_mister_sim_anchor` 2146 / 2609 / 463 on
> ## `cps2w`; `test_mister_wide_inert` bit-identical.
> ## **NEXT: slice D3** — the obj promote (`jtcps2_obj_scan.v:152`
> ## `st3_bank <= {table_y[12], table_y[14:13]}`, the CPS-2 Turbo rule) and
> ## the `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` chain widened to 3 bits.
> ## D2 built the destination and the plumbing; D3 drives `rom0_bank[2]`.



> ## **SLICE LOG (history) — 14z-107 (8): THE SIMULATED CONTROLLER WAS PRESSING
> ## FOUR BUTTONS NOBODY SCRIPTED.** jtframe v1.7.3's `SimInputs` held
> ## **P1's AND P2's buttons 5 and 6 DOWN** on every 6-button core — two
> ## 8-bit constants on a `[9:0]` **ACTIVE-LOW** port: `parse_inputs()`
> ## masks with `&0xf0` (throwing away the bits the line above released) and
> ## the constructor seeds `joystick1..4 = 0xff`, which `parse_inputs()`
> ## never corrects for players 2-4. So the MAME leg and the sim leg of the
> ## §4 oracle had never been running the same inputs — a FIDELITY defect in
> ## the instrument, recorded in 14z-107 (7) and FIXED here.
> ## **VERIFIED BEFORE IT WAS FIXED, AGAINST A SECOND IMPLEMENTATION, NOT
> ## AGAINST THE SOURCE.** A MAME hold-vs-not differential located the
> ## game's own input mirror — `RAM:$FF8058`/`$FF805A` (P1 held / new-press)
> ## and `$FF805C`/`$FF805E` (P2), 0x40 = button 6, 0x20 = button 5, live
> ## from MAME frame ~92. The **pre-fix sim's `$FF8040-$FF8070` block is
> ## byte-identical to MAME running the same ROM with P1 AND P2 buttons 5+6
> ## physically held**; after the fix it is byte-identical to MAME's
> ## no-input leg. The fix's whole boot footprint is **8 bytes of 65,536**
> ## (`$FF8058/5A/5C/5E` 0x60→0x00, `$FF8060-63` 0x40→0x00).
> ## **FIX: fork commit `519aff8b` — `& ~0xf` and `0x3ff`, one file, no RTL,
> ## no macro, LOCAL ONLY** (push authorisation still held). It is a plain
> ## upstream bug and the commit reads as a clean upstream report; nothing
> ## was filed. Gate: `test_sim_wram_contract` check 12 (+ its control).
> ## **THE RE-FREEZE: NOTHING MOVED, AND THAT IS THE RESULT.** MAME 2146 /
> ## sim **2609** / skew **463**, re-measured on the REFERENCE core over
> ## 2100-3000 so the window could not box the answer in; band untouched at
> ## ±30. Mechanism: a button held from before boot produces no PRESS EDGE,
> ## and this replay's only inputs are a coin, a start and one button-1 tap.
> ## Every §4 field still agrees, and the sound-state-fed arcade draw is the
> ## same pair as before (MAME `$0AE9D4` / sim `$0A9518`).
> ## **`audit_sdram_bank_load`'s phase boundaries are keyed to the anchor
> ## and therefore did NOT move** (2608 / 2614); re-deriving the table from
> ## `build/sdram_bank_load_14z107.log` reproduces it exactly.
> ## **~~STILL DEFERRED (maintainer): the COVERAGE half~~ [P2 DONE 14z-109;
> ## buttons 4/5/6 still refused]** — making buttons 5/6
> ## and P2 SCRIPTABLE. `tools/rpl2siminputs.py` still refuses them loudly.
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots).


> ## **SLICE LOG (history) — 14z-107 (7): THE "VIDEO-SENSITIVE ANCHOR" IS
> ## ROOT-CAUSED, AND IT INVERTED A VERDICT.** The picture never touched
> ## the CPU. jtframe's Verilator harness forks an ImageMagick child per
> ## CHANGED frame — ALWAYS, `-video` is not what enables it — and that
> ## child ended with **`exit(0)`**, which runs the C stdio cleanup.
> ## **libc++'s `basic_filebuf` is a `FILE*`**, so the child `fclose()`d the
> ## copy it inherited of the parent's `sim_inputs.hex` stream, and POSIX
> ## makes `fclose()` on a read stream REWIND THE SHARED FILE OFFSET. The
> ## parent then re-read input lines it had already consumed: **the
> ## simulated CONTROLLER was being replayed, once per fork** — and the
> ## number of forks follows the PICTURE.
> ## **THE 2x2 (681 dumps per leg, all four sets asserted complete):** frame
> ## output OFF, LUT present vs absent → **bit-identical 681/681**; same
> ## core, frame output OFF vs FORK → **483 of 681 differ**, first at frame
> ## **2051**, ONE byte, `RAM:$FF8060`, the **START bitmask**; black-screen
> ## core OFF vs FORK → bit-identical (it forks once, not 1,348 times); fork
> ## mode run twice → bit-identical, so the corruption is DETERMINISTIC.
> ## **THE FROZEN ANCHOR WAS THE ARTIFACT: re-measured MAME 2146 / sim
> ## 2609 / skew 463**, and every leg that does not fork agrees on 2609.
> ## D1's RED 2609/463 was right; the green 2502/356 was the corrupted run.
> ## Band unchanged at +/- 30 — the centre moved onto a named mechanism.
> ## **FIXES (fork, LOCAL ONLY):** `7cf1eedb` the child now `_exit(0)`s (the
> ## real repair, one word); `692ba4d6` adds `JTFRAME_SIM_NOVIDEO` + reaps
> ## the children, and `tools/run_sim_jtcps2.sh --frame-output off` is the
> ## lane's DEFAULT so a state oracle does nothing with the pixels at all.
> ## **INTEGRITY:** `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS,
> ## so a lost dump used to just move the anchor. Every `--wram` run now
> ## asserts its set is complete, and the anchor gate checks BOTH legs and
> ## asserts the frame-output mode from the run's own log banner.
> ## **THE DUMPS WERE NEVER CORRUPTED** — they are written by the PARENT
> ## from an `ofstream` opened and closed inside one call, with no
> ## descriptor open across the fork. The INPUTS were.
> ## **AND ONE NEW FINDING, RECORDED NOT FIXED: v1.7.3's `SimInputs` HOLDS
> ## P1 BUTTONS 5 AND 6 DOWN** (`test.cpp:201`'s `& 0xf0` drops bits 9:8;
> ## active low; `jtcps2_main.v:266` wires them in). The MAME and sim legs
> ## are therefore not running identical inputs. The one-line fix moves the
> ## anchor again, so it belongs with the queued P2/6-button fork commit —
> ## that pending item is upgraded from COVERAGE to FIDELITY.
> ## **[FIXED 14z-107 (8), fork commit `519aff8b` — and P2's buttons 5/6
> ## were held too. The anchor did NOT move. See the newest block above.]**
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots) — and it can now change video output without the anchor going
> ## ambiguous, which was the whole point of this session.

> ## **SLICE LOG (history) — 14z-107 (6): MiSTer SLICE D1 IS DONE, and it is the
> ## slice where `cores/cps2w` STOPS BEING cfg-ONLY.** The QSound
> ## sample-bank width fix ships behind a **RUNTIME** profile gate: **MRA
> ## header byte 41, bit 0, ACTIVE LOW** (`0xFF` fill = profile OFF, the
> ## WIDE MRA writes `0xFE`). So stock `vsavj` on `jtcps2w.rbf` is a STOCK
> ## MACHINE by construction, which is what makes rule 1 v2's
> ## "profile-gated" a fact on FPGA rather than an inertness argument.
> ## Fork commit `4840df8a` — **LOCAL ONLY, NOT PUSHED** (the maintainer has
> ## not re-confirmed push authorisation; every other fork commit is
> ## public).
> ## **`cores/cps2w/hdl` now holds FOUR files** — two new
> ## (`jtcps2w_profile.v`, `jtcps2w_qsnd_bank.v`) and two OVERRIDES of
> ## SHARED files (`jtcps15_sound.v` from cps15, `jtcps2_game.v` from
> ## cps2). `cores/cps1`, `cores/cps2` and `cores/cps15` are BYTE-UNTOUCHED
> ## and that is now a `git diff` assertion (`test_jtcores_twin` 2e).
> ## **THREE THINGS THAT CHANGE HOW TO WORK HERE:**
> ## **(1) `PCM_AW` 23 → 24 DOES NOT COMPILE** and three documents said it
> ## did. `jtframe_romrq_bcache.v:74` replicates `SDRAMW-AW` zeroes, which
> ## goes NEGATIVE past `AW = SDRAMW = 23` — Verilator refuses to elaborate.
> ## An 8-bit jtframe slot reaches **8 MB of a 16 MB bank**, which is why
> ## the map splits QSound across two banks. Struck in place everywhere.
> ## **(2) `jtframe files` DEDUPS BY FULL PATH**, so overriding a shared
> ## file means DELETING it from the original core's list — and a `.yaml`
> ## pulled with `get:` drags the shared file with it, so cps2w had to
> ## INLINE cps15's `qsound.yaml` instead of pulling it.
> ## **(3) The bank bit IS `dsp_ab[7]`, validated against MAME's LLE
> ## qsound device** (`map(0x0000,0x7fff).mirror(0x8000)` +
> ## `m_rom_bank = (m_rom_bank & 0x8000U) | offset`), not against the
> ## commented-out permutation jtcps15 carries.
> ## **NEXT: slice D2** — the placement: bank-0 repack, the group-C GFX
> ## redirect in `jtcps1_prom_we`, the QSound bank split on
> ## `qsnd_addr[23]` (already produced and gated, just unrouted),
> ## `jtframe_ram1_7slots.v` (maintainer-ruled option A) and the two new
> ## GFX slots.
> ## **(4) A NEW CORE WITHOUT `hdl/pal_lut.hex` RENDERS A BLACK SCREEN**,
> ## `*.hex` is gitignored in jtcores so `git add` refuses it silently, and
> ## — through the Verilator harness's per-changed-frame `fork()` — that
> ## VIDEO defect MOVED the simulated match-start anchor by 107 frames and
> ## turned `test_mister_sim_anchor` RED. Four 50-minute runs to find. A
> ## 2x2 factorial put the whole effect on the `.hex` and none on the RTL.
> ## **So: never blame a red anchor on RTL until a core-vs-core RAM
> ## comparison says so** — that is what `test_mister_wide_inert` is for.
> ## **Gates:** `test_mister_wide_gate` (ci_portable, 22 s) is the RTL
> ## trust surface — a frozen line-by-line override delta, the missing-asset
> ## check that would have caught pal_lut, and two Verilator benches with
> ## four must-fire controls; `test_mister_wide_inert` (emulator, ~22 min) is
> ## the INERTNESS instrument (cps2 vs cps2w, bit-identical work RAM);
> ## `test_mister_sim_anchor` runs on **cps2w** by default
> ## (`SIM_CORE=cps2` for the reference leg) and is a cross-IMPLEMENTATION
> ## oracle, not an inertness test.

> ## **SLICE LOG (history) — 14z-107 (5): MiSTer SLICE D0 IS DONE.** The MRA that
> ## makes the WIDE image downloadable at all is written, pushed to the fork
> ## (`38acc638`) and gated. `rom/vsavjw.rom` = **66,265,152 B**, header
> ## words **6144 / 6400 / 15552 / 64704** — `docs/project/mister_map.md`
> ## §3 to the byte, verified region by region against the romset. The
> ## stock leg is untouched and now GATED: the `vsavj` MRA from `cps2w` is
> ## byte-identical to `cps2`'s except `<rbf>`, `cps2` emits NO WIDE MRA,
> ## and stock `vsavj.rom` is still 46,407,744 B.
> ## **Build it:** `ROMDIR=... tools/mister_mra.sh --core cps2w --wide
> ## build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THREE THINGS D0 FOUND, all of which change how to work here:**
> ## **(1) The map's own proposed TOML row was WRONG and wrong SILENTLY** —
> ## `parts=` collapses a whole region into ONE `<interleave>`, so three
> ## QSound members all mapping "12" become the first one truncated. The
> ## fix is a SEPARATE `qsoundw` region (with a generic `skip=true` row, or
> ## the stock MRAs gain a comment line and the twin breaks). Corrected in
> ## place in §3, wrong row kept and labelled.
> ## **(2) jtframe finds zip members by CRC32 ALONE** (`mra2rom.go:163-172`)
> ## — FBNeo and MAME resolve by NAME and only warn, which is why our WIDE
> ## members carry SENTINEL CRCs there. **So the MiSTer MRA is pinned to one
> ## romset BUILD**: `tools/gen_vsavjw_xml.py` generates the fork's
> ## catalogue entry from the zip, and a romset rebuild that moves a CRC
> ## needs a new fork commit. `tests/test_mister_mra_map.sh` says so loudly.
> ## **(3) The WIDE set's PARENT is the BUILD's `vsav.zip`,** not the
> ## pristine dump (the merged build patches `vm3.13m/15m/17m/19m`), and
> ## `jtframe mra` reads a hard-coded `$HOME/.mame/roms/` — hence the
> ## private-`$HOME` staging in `tools/mister_mra.sh`.
> ## ~~**NEXT: slice D1** (the QSound width fix, `jtcps15_sound.v:47,416` +
> ## `PCM_AW` 24)~~ — **DONE, see the 14z-107 (6) block above; and `PCM_AW`
> ## 24 was wrong.**
> ## Two SHIPPING questions D0 surfaced, for the maintainer, in STATE
> ## "Decisions pending": which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours.


> ## **14z-107 (4): THE MiSTer SDRAM PLACEMENT MAP EXISTS
> ## AND IT FITS, by 0.125 MB of 64 (0.708 MB RETRACTED 14z-107 (9) —
> ## see below).** Read `docs/project/mister_map.md`
> ## before any MiSTer RTL. Three things in it change what earlier
> ## entries below say:
> ## **(1) "6.39 MB of tenant art into bank 1's 7.1 MB spare" IS WRONG.**
> ## 6.39 MB is a LIVE-BYTE count; a CPS-2 tile code IS its SDRAM address
> ## (the download scramble at `jtcps1_prom_we.v:105` undoes the .rom's
> ## 4-way interleave), and the roster runs to code `0xEE73` in group-C
> ## obj bank 4 and `0xFFDB` in bank 5 -> **an ADDRESS FOOTPRINT of
> ## 15.45 MB**, needing the spare of BOTH banks 0 and 1.
> ## **(2) THE WIDE `.rom` DOES NOT DOWNLOAD AS DECLARED** — 70.26 MB
> ## overflows the 26-bit `ioctl_addr` GAME port
> ## (`jtframe_mem_ports.inc:1`) AND the 16-bit header start word. The
> ## MRA must trim QSound to 8.9375 MB; `mra2rom.go:177-196` +
> ## `parts=[...]` do that from the MRA alone, so the ONE-ROMSET ruling
> ## holds. **DONE in D0 — but NOT with the row §3 proposed; see the
> ## 14z-107 (5) block above.** QSound is then SPLIT across SDRAM banks 0 and 1 on
> ## `pcm_addr[23]` — without that split the map overflows bank 1 by
> ## 0.39 MB and nothing else closes it.
> ## **(3) THE PRG WINDOW IS RESOLVED:** `objcfg_cs` is WRITE-ONLY
> ## (`jtcps2_main.v:190 && !RnW`), so a 6 MB `rom_cs` gated on `RnW`
> ## has NO read collision; the 16-byte `$400000-$40000F` reservation is
> ## enough. Bonus defect found: `:167` would leave `$500000-$5FFFFF`
> ## ZERO-wait while all other ROM is one-wait.
> ## **Slice plan D0-D4 with a gate + must-fire control each is in §10.**
> ## New gate `tests/audit_mister_map_fit.sh` (ci_static, ~5 s) freezes
> ## the four extents the fit rests on; **one new tenant tile above
> ## `0xEE73`/`0xFFDB` breaks the map**, and this is what catches it.
> ## **Open for the maintainer: the bank-0 slot count** (add
> ## `jtframe_ram1_7slots` vs move the Z80 to bank 1) — Decisions
> ## pending.

> ## **THE STATE IN ONE BREATH: the 14z-105 window is FROZEN as
> ## donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 (stock twin
> ## m5_stock6 = `883e7d17`, UNCHANGED). PLAY:
> ## `tools/run_wide.sh build/m3b_merged13 fbneo`. FIELD-CONFIRMED and
> ## PUSHED 2026-08-22 (Oboro + the M6 mark both confirmed; Oboro's long
> ## intro is vanilla's own boss intro — accepted, not tournament-legal).**
>
> ## **WHAT THE WINDOW SHIPPED (both profile-gated, both inside the
> ## ratified select-window class):**
> ## **W1 — THE OBORO SELECT HOOK:** cursor on BISHAMON, hold START,
> ## confirm with any button -> vanilla vsavj's Oboro (id 0x18, base
> ## 0x0B3450; the pale colorway; HUD name stays "Bishamon" — aliased
> ## rows). P1 and P2. Without Start: plain Bishamon. The mechanism is
> ## vanilla's own Gallon-variant idiom at PRG:0x020B9C one cell over
> ## (`btst #7,$394(a6)` IS the Start test — measured before authoring).
> ## Gate `tests/test_oboro_select.sh` (5 legs incl. P2 and the stock
> ## twin). Atlas: select_screen.md "The Oboro select hook".
> ## **W2 — THE VERSION STRING:** "M6" at the select screen's bottom-
> ## right — THE NAKED-EYE A/B TELL (CLAUDE.md §5, open since 14z-92,
> ## now implemented). Two authored glyph sprites on the roster21 wheel
> ## record, tiles in group C 0x1FE40/41, pal row 0x19. Knobs on
> ## `[[select_wheel]] roster21` in all three manifests — **BUMP
> ## `version_text` AT EVERY FREEZE** (it names the generation). Gate
> ## `tests/test_version_string.sh` (pixel-exact snapshot). Font:
> ## `build/manifest/version_font.json` (0-9 A-Z - . space; add glyphs
> ## there if the text needs more).
>
> ## **THE FINDING ON THE WAY — the tile codec was mirrored.**
> ## `gfx_tiles.decode` had mapped plane bit i to pixel i since it was
> ## written; the hardware draws bit i at pixel 7-i of each 8-px half,
> ## and the transparent pen is 15. Nothing had ever consumed pixel
> ## ORDER until the first authored tile. Fixed both ways, gate
> ## `tests/test_gfx_tile_codec.sh`, platform gotcha. RULE: a
> ## synthesized tile is verified at the RENDER layer, never by a byte
> ## round-trip alone.
>
> ## **A PREDICTION THAT DIED:** the 14z-104 close said the select-window
> ## specs would MOVE with two more sprites. Measured over all 148
> ## window/composite specs: UNCHANGED. The window end is the VS-phase
> ## re-init, not the sprite count.
>
> ## **THE NEXT SESSION starts clean — the field test passed and the
> ## push is done.** Nothing is queued — every verification
> ## the 14z-102 freeze had is green on 14z-105 (incl. audit_merged_
> ## legacy 47/47 + leg b, and the guard-corpus soak 316/316, run while
> ## the maintainer tested; the Oboro pick also agrees on FBNeo, leg F).
> ## **RELEASE PACKAGING IS DONE (14z-105 (2)):** `release/merged-m6/`
> ## — xdelta3 patches against the four reference dumps, manifest,
> ## applier, README; gate `test_release_roundtrip.sh` (round trip
> ## byte-identical, applier refusals, rule-7 scan). Re-package at every
> ## freeze with `tools/package_release.py build/<merged>/rompath release
> ## --romdir $ROMDIR --name merged-mN --version <mark>`. RULED
> ## (maintainer, 2026-08-22): stays IN-TREE until MiSTer; a tagged GitHub
> ## release is cut then, covering both. MiSTer core surgery is next.
> ## **14z-106 (2026-08-22): housekeeping DONE** (w6 evidence logs +
> ## guard-corpus TSV committed; probes attic'd to `../build_attic_14z105`;
> ## `../build_attic_14z102` DELETED per policy; fbneo submodule content
> ## verified = patches 0001+0002). **MiSTer FRAMING RECORDED (maintainer):
> ## the deliverable is an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA
> ## re-implementation of the MAME emulation.** Before any RTL: the
> ## alignment questions in STATE "Decisions pending — MiSTer alignment"
> ## — ALL FIVE RULED 2026-08-22: separate core (GPL-3.0 fork of jtcores,
> ## own RBF), measure-then-choose profile, sim = gate / hardware = field
> ## test, MiSTer + Jammix available (SDRAM SIZE TO CONFIRM), MRA+RBF with
> ## a stock-vsavj reference-leg MRA. LICENSE: GPL-3.0 (done).
> ## **14z-106 (3): MiSTer SLICE A DONE** — fork `DefinitelyFrenchName/
> ## jtcores@vampire-saved` (core `cores/cps2w` → `jtcps2w.rbf`), submodule
> ## `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`;
> ## the vsavj reference-leg MRA measured byte-identical to stock except
> ## `<rbf>`. ("NO XL SDRAM tier exists" — TRUE OF OUR PIN ONLY; see
> ## the 14z-107 (2) block below.)
> ## **SLICE B MEASURED (`docs/project/mister_fit.md`): the roster's art
> ## is 6.39 MB vs 0.49 MB blank in vanilla's 32 MB — a wider GFX tier is
> ## REQUIRED; PRG needs 4.82 MB (+ a 30-B pin at 0x5FFF00); QSound ext =
> ## banks 0x80-0x8E (all aliasing → width fix required). ~~PENDING RULING:
> ## WIDE v1 VERBATIM on a 128 MB tier (recommended) vs a tighter MiSTer
> ## profile.~~ **RULED 2026-08-23: WIDE v1 VERBATIM. The "128 MB tier"
> ## half is superseded — see 14z-107 (2) below.** **SLICE C: THE SIM LANE WORKS** (stock jtcps2 + vsavj under
> ## Verilator on this Mac, ~1 s/frame, recipe in mister.md; `.rpl` →
> ## `sim_inputs.hex` translator gated).**
> ## **14z-107 (2026-08-23): THE MiSTer ORACLE IS REAL — the §4
> ## dual-emulator protocol now runs on a THIRD implementation and
> ## AGREES.** Fork commit 2 `553dd56` = `JTFRAME_SIM_WRAMDUMP`, 64
> ## macro-gated lines in the Verilator TESTBENCH `test.cpp` (no RTL);
> ## `emu/jtcores` pin bumped and the patch mirror is now a SERIES.
> ## `tools/run_sim_jtcps2.sh` is the whole lane in one command; gates
> ## `test_sim_wram_contract` (ci_portable) + `test_mister_sim_anchor`
> ## (emulator tier, ~55 min). MEASURED: work RAM = SDRAM bank 0 byte
> ## `0x600000`, 64 KB, 68k byte order; `05_timeout_idle` round-1
> ## match-start anchor MAME **2146** / sim **2502**, skew **+356** [RETRACTED 14z-107 (7): 2609 / +463]
> ## (NOT the +460 boot offset — the attract/select/VS path costs ~99
> ## fewer frames on the core, which is why §4 anchors exist). Every
> ## compared field agrees, P1 = Demitri `$093B6A` on both.
> ## **THE ONE DISAGREEMENT IS THE GAME'S OWN LOTTERY:** the 1P arcade
> ## draw is sound-state-fed (`ram.md:99`, the #110 mechanism), so the
> ## CPU opponent differs (`$0AE9D4` MAME vs `$0A9518` core) and the
> ## P2-identity fields are excluded BY NAME. Pinning it needs a 2P
> ## replay -> P2 SCRIPTING in `SimInputs` -> a queued fork commit
> ## [still queued at 14z-107 (8): commit 10 RELEASED P2's buttons, it did
> ## not make P2 scriptable; the draw is the same pair after the fix].
> ## **TWO RETRACTIONS:** `JTFRAME_SIM_IODUMP` dumps the EEPROM on CPS-2
> ## and `JTFRAME_SAVESDRAM` is Verilog-model-only — work RAM was never
> ## "reachable"; and **`-load` is MANDATORY** (the download latches the
> ## decryption key into core registers, so a preloaded run boots into
> ## ciphertext — 1,841 frames of ALL-ZERO RAM that still "agreed" with
> ## MAME on 99.2% of sampled bytes. Check NON-CONSTANCY first.)
> ## **14z-107 (2) — THE MEMORY-MAP TRUTH (docs + STATE only; no code, no
> ## RTL). The profile ruling STANDS (WIDE v1 verbatim, one romset); the
> ## implementation assumption attached to it is RETRACTED: "MiSTer work =
> ## width plumbing only" is FALSE and the 128 MB tier is NOT a flag away.**
> ## At our pin `v1.7.3` **64 MB is PHYSICAL** — jtframe's table stops at
> ## `AW 23`, the bank geometry has no AW=24 arm (`addr[9]` would never be
> ## driven, aliasing with `addr ^ 0x200`), and only 13 A / 2 BA / 1 nCS
> ## pins are assigned. **`JTFRAME_SDRAM_XL` (128 MB) IS real — UPSTREAM,
> ## 3057 commits away, untagged** — as TWO CHIPS on one module with chip
> ## select on **nCS POLARITY**, and reachable ONLY inside the
> ## `JTFRAME_SDRAM_CACHE` branch: setting it on `cps2w` today would
> ## compile, validate and silently alias (platform gotcha). That
> ## **partially UN-RETRACTS** 14z-106's "no XL tier" — true of the pin,
> ## false of jtframe; `cps2_wide.md` now carries the version qualifier.
> ## **The CPS-2 CORE caps GFX at 32 MB in the OBJECT FORMAT** (16-bit code
> ## + 2-bit bank — the SAME 19-bit promote WIDE v1 already makes on FBNeo),
> ## the 68k at a flat 4 MB `rom_cs` (with a real collision against the
> ## objcfg window at `0x400000`), scroll at 8 MB, QSound at a 7-bit latch.
> ## No SDRAM tier lifts any of them.
> ## **AND THE ROSTER FITS 64 MB BY TOTAL — ~56.1 MB** (`mister_fit.md` §6):
> ## PRG 6 MB fits bank 0 TODAY, QSound 16 MB fits bank 1 TODAY (PCM is
> ## alone in a 16 MB bank), and ONLY GFX overflows, by ~6.4 MB — into
> ## bank 1's ~7.1 MB of spare. ~~**NEW PENDING DECISION: THE MiSTer
> ## MEMORY-MAP ROUTE** — (1) uprev to untagged master + XL + `mem.yaml`
> ## cache lanes, or (2) stay at the pin and BANK-REPACK inside 64 MB.
> ## **Recommendation (2)**~~ **DECIDED (maintainer, 2026-08-23): (2), the
> ## BANK REPACK, measuring first; XL is the FALLBACK. Measured GO the same
> ## day and SHIPPED in D2.** And the "~6.4 MB into bank 1's ~7.1 MB spare"
> ## framing is RETRACTED twice over: 6.39 MB is LIVE BYTES, the address
> ## footprint is 15.45 MB, and the DECLARED REGION the download reserves is
> ## 16 MB — see the top banner.
> ## **THE SIM LANE'S SDRAM MODEL IS FIXED (14z-107 (3), fork commit 3).**
> ## It dropped `addr[22]` — which rides on `sdram_a[9]` as the tenth COLUMN
> ## bit, NOT `addr[9]` — so GFX banks 2/3 were half-aliased. The "~3
> ## constants / widen the column to 0x3ff" fix named earlier was WRONG.
> ## The anchor oracle never moved (bank 0 is entirely below WORD 0x400000)
> ## and still passes; the anchor moved 2507 -> 2502 (skew 361 -> 356) [both absolutes RETRACTED 14z-107 (7): the clean anchor is 2609]
> ## because `jtcps1_obj_draw.v:137` skips blank tiles, so OBJECT TIMING
> ## DEPENDS ON GFX CONTENT. Two more harness bugs had to be
> ## fixed before `-stats` produced anything (commits 4 and 5).
> ## NEXT OPENER: ~~**the MEMORY-MAP ROUTE ruling**~~ [TAKEN 2026-08-23 —
> ## bank repack], then the core-side format
> ## work; phase B (the round-transition anchor on the full 12,120-frame
> ## replay, ~3.5 h), the Verilator 8 MB-per-bank fix and P2/6-button
> ## `SimInputs` are the queued follow-ups. [8 MB-per-bank done 14z-107 (3);
> ## `SimInputs` FIDELITY done 14z-107 (8), COVERAGE still queued.]
> ## The N-2 build-dir
> ## deletion policy applies at the NEXT freeze (m10/m19/m13/merged-m5
> ## dirs are now one-back; m9/m18/m12/merged-m4 + m5_stock4 are N-2 and
> ## fall).

## What 14z-105 did (the whole arc, one screen)

**Measure first:** Start held on the vanilla select screen -> struct
`+0x394` = `$8000`, `$FF8060` = 1 (both live at select; the template
bit is Start). **W1** authored as a 30-byte profile-gated site_thunk
(every manifest, deduped; +2 ops), rehearsed on a merged probe, gated
five ways. Stock twin rebuilt = `883e7d17` bit-identical (the profile
gate measured, not argued). **W2** authored as `version_*` knobs + a
5x7 font + `gfx_tiles.encode` + an `"authored"` list in
`wheel_bank5.json`; the first probe rendered mirrored glyphs in a black
box -> the OBJ list proved the sprites right and the TILE BYTES wrong ->
codec fixed both ways -> re-probe pixel-exact (0 mismatches). **The
freeze:** tenant_loop op counts re-frozen (325/365/298; 600/652;
806/907), five artifacts built from the tree (merged13 bit-for-bit the
probe), sets carried-renamed + registry rows, m3a pins + whole-artifact
manifests moved with member attribution (program + the four GROUP C
members = the glyph tiles; no QSound), the standing re-point sweep
executed (~70 defaults), placements +0x10 (hui) / +0x30 (pyron) ->
bases.tsv, pcrel [merged_*], pointer_flow baselines re-derived;
region_overlap section 5 still 2033. Every gate run at the freeze:
STATE 14z-105 CLOSE.

## What 14z-103/104 did — see STATE; the coverage matrix is fully green
(docs/project/coverage_matrix.md), #110 fixed, the A4 pin-cleanup done.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-104 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-103 did (the whole arc, one screen)

**The A4 pin-cleanup pass executed end to end** — every stale build-dir
reference re-pointed and run green, ruled a deliberate pin (don_m5 =
walker_repoint's un-relocated negative control; pyron26 + hui41 =
decode_stage_banners' frozen #92 carriers), or reclassed operational;
disposition table in `docs/project/build_dir_triage.md`. Findings: the
gate_failures litter class (the flicker-gate fixture wrote deliberate-
FAIL stubs into the evidence dir on every static run — fixed at the
root with M2A_KEEP_DIR, 141 files purged by content signature);
**GitHub #110** — audit_fg_damage + audit_pool_free_byte red since
14z-87 because that batch RE-ROLLED THE ARCADE DRAW (m6: char 0x0C /
stage 0x12; m7+: char 0x00 / 0x0E) — fixed by pinning the opponent
(2P-dummy rigs hui/74+75, EXPECT 69/69 bit-identical across
generations; pcosmo -> 106_pyron_cosmo_clash) and CLOSED; the 14z-88
self-frozen-sha1 hole live again on replays 94/103/105/106 — promoted
to `window vsavj/masked-v2 889 2091` (103 per-leg: tenant on don,
.legacy-exempt on hui/pyron); grab_victim's default was the pre-14z-73
expectation since birth (now `matches`, Δ=0); flicker_attribution had
been SKIPping on a removed set dir (now fingerprint-resolved). The
Circuit Scrapper report was measured NOT REPRODUCED (six-run A/B, MP/
HP/mash) and the maintainer confirmed it fine. Everything pushed
(bb79e18); suites GREEN x3, statics 97/0/0 strict.

## What 14z-102 did (the whole arc, one screen)

**The #107+#109 window frozen end to end** as donovan-m10 / huitzil-m19
/ pyron-m13 / merged-m5 (maintainer "go"; beams field-confirmed on the
rehearsal probe first; gold tint KEPT). #107 = the verified
reconciliation row 0x0448a6 -> 0x04367a (shared map — stock moved too).
#109 = the clone-beam fix: vsavj ships effect-class ROW 31 as a stub
(the DF clone-mode beam emitter); ported root 0x926e4:0x11e:t0x922f0 +
code_ptr at PRG:0x080B28; the root changed extraction (hui placements
shifted, op counts re-frozen 363/804, tenant bases re-derived). Every
verification green: run_suite x6, battery effectively 24/24,
guard-corpus soak 316/316 zero vectors, statics 97/0/0 strict.
PUSHED with #107/#109/#50 closed. Post-freeze rulings: DF durations
kept categorically (vsavj per-character, 1 stock); tint confirmed good;
#50 closed as standing policy; build-dir triage EXECUTED (85 dirs /
8.1 GB -> ../build_attic_14z102, reversible; N-2 generation-roll now
standing policy at every freeze).

## What 14z-101 did (the whole arc, one screen)

**The agreed #108→#107→#106 sequence, all executed windowless:** #108
INVERTED by the writer hunt (not-a-defect; the -debug "paradox" was a
pristine-table misread; audit re-framed to NATIVE PARITY + anchor leg);
#107 twin-anchored statically (both games' own farms bind slot-for-slot;
0x45FCC eliminated — next slot's routine; tie-refusal policy landed in
reconcile_batch + gate §6, live control: fresh 0x448a6 refuses as
TIE-4x0.94-w0x20; m3a bit-exact); #106 closed (verify_pcrel_data
--extract/--placement-suffix; merged inventories IDENTICAL to solos,
frozen by reference with a must-fire control; also fixed the tool's
listdir-accident zip pick).

**New standing instruments:** `audit_guard_corpus.sh` (79 replays × 4
legs under guard, 316/316 green, hui41-crash must-fire control);
`tools/enum_biased_lists.py`; rigs `df/97-102` (DF framework mechanics,
clone-attack discriminators, the NATIVE clone-mode reference).

**DF mechanics measured** (the field pass's named unknown): the GAMES'
DF frameworks differ by design — vs2 = 2-stock universal buff, uniform
332f (maintainer-confirmed); vsavj = 1-stock per-character modes
(legacy sweep spans 269-540f); ours == pristine vsavj EXACTLY on the
legacy control. Phobos' 0x18 clone-train mode is a legitimate vsavj DF
class (legacy 0x0C/0x0F use it at the same 377).

**#109 found and fully root-caused through the confirmation loop** (two
intermediate readings retracted in place — the layered-correction arc is
itself instructive: identify moves by measured EFFECTS, never the
script's input name — vs2's buffer folds 6236 to 236; gotcha paid).
The clone-mode EX = 263+2P (1 stock); the ES = 236+2P.

**The FOREIGN-DRAW class named** (register §5): audit_empty_tiles
measured PASSING on the #109 event — it audits group-C blanks, this
class draws from the WRONG SPACE; exposure census-bounded 26/1/0, the
paired-draw census queued as the instrument. [The #109 instance of the
class dissolved with the 14z-102 re-derivation (the beam draws
correctly); the CLASS and the census stay valid for the B-sweep
carries.]

**Also:** the ~200-build-dirs decision package delivered
(`docs/project/build_dir_triage.md`); the stale "#10 ripe" banner claim
retired; strengths/timeout-wins field items closed.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-98 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-98 did

**#103 root-caused and causally confirmed; no shipped byte moved.** The
banner's consumer trace ran and ELIMINATED its own suspect (both spaces,
live controls), which moved the hunt one level up: the KO-recognition
step (phase 6->8) never fires for a Donovan death because the judge
tests WHITE HP's sign and his white never goes negative — a ported
pc-rel escape pins his hp to 1 mid-match. Chain, instruments, fix design
and rehearsals: STATE 14z-98; the issue carries the full write-up.

**New instruments:** `tests/audit_don_ko_writer.sh` (the root-cause
lock, both modes rehearsed); `trace_writes.lua` DUMPS (self-documenting
-debug runs). **New gotchas (project bucket):** every -debug watch
configuration is its own TIMELINE; GUARD_PROBE's RET (SP) lies for
jmp-reached code. **Atlas:** +0x52 judge note, +0x54, +0x11F rows;
engine_internals "THE ROUND JUDGE" section. **Retractions executed:**
the "author the four per-char rows" fix shape (issue, STATE (9) marker,
bank_map.toml trace note).

---

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-97 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-97 did

**Closed: #96** (maintainer-ruled option (a), executed). One arc, no build
bytes touched.

**The battery's legacy target now FOLLOWS THE BUILD.** It resolves the
expectation set from the build's own program fingerprint through
`tests/expected/registry.tsv` — the same auto-detecting mechanism
`run_suite.sh` has always used — so nothing in the gate names a generation,
and at the next freeze the registry row moves and the gate follows with no
edit. An unregistered fingerprint is now the rule-6 signal by construction,
and it stops the gate BEFORE any replay runs.

**First measurement, and it settles the ticket: the pipeline DOES reproduce
the freeze.** Rebuilt clean, stage 6 -> `a054de5c` (the stock twin named in
the donovan-m8 freeze record), stage 4 -> `22c804c8`. Every #96 symptom was
the dated `donovan-m2c` pin, exactly as the ruling said.

**The one open item, `08_challenger_join`'s 3807, is ATTRIBUTED:** full-RAM
dump diff at 3507 AND 3807 shows one differing live byte, **`$FF06E1`** —
the byte `docs/game/atlas/ram.md:62` names verbatim (OBJ-builder secondary
stack, "execution POSITION, not state"). Corroborated twice: `donovan-m2b`
measured the same pair one generation EARLIER than the pin, and on the WIDE
track that frame is a select-window onset (the challenger join re-enters
select). Not growth of an unknown kind.

**Constants that disappeared AS constants:** the V1 mask string (#70's other
half), the V1 basis path, `M2A_FLICKER_SPECS=donovan-m2c`, the two
generation-dependent class lists, and 700 / 4278 / 1080 (from the MASKED
gate — 4278 rightly stays in the unmasked stages-1-3 one, where it is a fact
about vanilla's attract demo). Those three are `.masked` `diverge` specs now,
which is STRICTER — `check_diverge.py` also asserts line-identity before the
frame.

**A PREDICATE WAS INVERTED, deliberately.** 14z-90 (#2) made the flicker
check fail on growth and merely ADVISE on shrink, because the battery ran on
UNFROZEN dev builds. That premise is gone: the target is a frozen
generation, so a shrink means the fresh build is not the frozen one, and
drift either way now fails. If you find yourself "fixing" that back, read
`tests/test_m2a_flicker_gate.sh`'s header first.

**The §4 vocabulary has ONE implementation:** `tests/lib/masked_compare.sh`
(exact/flicker/diverge/window/composite + the #62 baseset-mask guard),
shared by `run_suite.sh` and the battery. Proven three ways — textual
identity of every checker call and verdict string with the pre-lift block, a
synthetic ground truth over all five classes in both directions, and a
real-data re-check of `window`+`composite` on the shipping WIDE build.

**Two real defects found on the way, both of the "measured the wrong thing
quietly" class:** `tools/propose_masked_specs.sh` measured PRISTINE VANILLA
when given an absolute builddir (it existence-checked one path and handed
MAME another), and the lifted `diverge` branch would have reported
NO-BASE-LOG on every diverge spec (`check_diverge.py` derives the base log
from the spec FILE's stem). Both fixed, both gated. Also: a verdict control
in `test_baseset_mask_invariant.sh` was briefly passing because it CRASHED.

**Where the tenants stand:** unchanged. No build moved; the 14z-96 freeze
stands.

## What 14z-95 did

**Closed: #24, #27, #43(a), #52, #97, #98, #100.** Advanced: #96 (symptom
fixed, three items separated, root-caused to one constant), #99 (parked with a
cold-resume record), #100 (mechanism localised, then closed WON'T FIX under
the standing cosmetic ruling and re-scoped beyond MiSTer).

**Five new gates**, all with must-fire controls:

| gate | what it locks |
|---|---|
| `test_tenant_pairings.sh` | tenant-vs-tenant, all SIX orderings — the CLAUDE.md §4 coverage the suite never had, and the gap #99 walked through |
| `test_hui_electrocute.sh` | the FIRST electrocute rig in the project's history (STATE said twice no replay produced one) |
| `test_merged_inputs.sh` | the merged build's inputs are PRODUCED, not demanded — rule 3 is one command |
| `test_reconcile_matcher.sh` | one matcher, pinned inert (1640/1640 probes), parameters proven load-bearing |
| `audit_ladder_selector.sh` | the #99 ladder probe, and a regression lock on a hypothesis that DIED |

**THE SESSION'S REAL LESSON, worth more than any single fix: FOUR separate
defects were checks that had STOPPED CHECKING**, and each read as green or
quiet rather than red —

| what | how it hid |
|---|---|
| `test_dualtrack` | red for 11 days; no runner executed it |
| `audit_pyron_ring` | compared two builds that stop being comparable at f4741 |
| `test_m2a_stage4_code` | asserted a constant a ratified change had invalidated |
| `test_reconcile_matcher` | **mine** — disarmed itself the moment I committed the change it polices |

The last was caught ONLY because `run_all_static` counts SKIP as a third
outcome (#29/#30). That is an argument for spending time on gate
VERIFICATION, not only on gate COVERAGE.

**Generalise from the fourth:** any gate that reconstructs a "before" state
from git is dated by its own commit. `git log -S` answers "where did this
change", NOT "the last version that HAD this".

## Where the tenants stand

Unchanged this session — no build byte moved. `build/m3b_merged9` =
**merged-m2** (`081e2e53`, 752 ops), solos `hui43` = huitzil-m16
(`da734d49`) and `pyron27` = pyron-m10 (`e29cac23`), `build/don_m7` =
donovan-m7 (`c90b60c3`, unchanged since 14z-91). Maintainer playtest of
merged-m2: **no regression**, one crash (#99), one cosmetic (#100, now
won't-fix).

---

(Deeper history, 14z-92/93/94, follows — same caveat as above.)

## What changed in the triage, in one screen

Almost none of these were wrong logic. They were **checks that stopped
existing** under an ordinary condition — an env var, a wrong argument, a
phantom CLI option, a stale marker file, a literal constant — and in each case
the thing that should have caught it was disabled by the same stroke.

| # | the switch | what it turned off |
|---|---|---|
| 79 | `python -O` | `assert` is REMOVED, not weakened. Six tools, incl. the cipher round-trip self-check. |
| 76 | a wrong 2nd argument | `outdir == romdir` deletes the reference set. No undo (rule 7). |
| 80 | `MAME_BUILD_ROOT` | `rsync --delete` into any caller-supplied path. |
| 86 | a late replay failure | the oracle trust root left half old, half new. |
| 89 | `--dry-run`, which never existed | voice ids rebuilt from `wide0`, reported as a verdict on another build. |
| 88 | a leftover `.diverge` | the freeze you just took, silently ungoverned. |
| 85 | the literal `60` | 2.03 s drift by voice 79, against a 3.35 s window. |
| 83 | an absent TSV row | meter, which CLAUDE.md §4 names explicitly. |
| 81 | SIGKILL / a second terminal | tracked `gen_donovan_patch.py`, left perturbed. |
| 87 | nothing reading the field | `gfx_layout3.toml`'s bank words, collision rule and scatter bounds. |
| 77 | one mistyped `.rpl` frame | `nScriptFrames + 2` wraps -> `calloc(1,4)` with a ~4 GB write past it. |

**Three were hiding a second defect** — #87's scatter bound had already
drifted (huitzil: 246 codes outside it, re-measured to `0x0AF5`), #85's
control was aimed at the one window where the drift is smallest, #81's
self-check compared against a snapshot it took itself. **Two were latent**
(#89, #51): real defects that currently produce right answers, which is
exactly why they needed gates and not rebuilds.

**THE SUITE IS GREEN.** `test_dualtrack` — the one red thing — is fixed and
is now a STRONGER gate (**#95**, closed). It was never a regression: it
asserted two things the project had *deliberately* made false, and **no
runner ran it**, so nobody saw it go red 11 days ago.

| its claim | what invalidated it |
|---|---|
| 11 legacy replays bit-identical stock↔WIDE | **14z-64 M3a de-substitution** — the two builds carry DIFFERENT ROSTERS by construction (`m5_stock` id 0x0F over Jedah; `m5_wide` id 0x13, Jedah restored), so every select-reaching replay must differ |
| attract diff = 57 bytes, 0 gameplay, at frame 4400 | **14z-86 M5 voice block** — the WIDE sound delta grew and now propagates |

Re-derived: section 1 asserts **bit-identical up to select entry** with the
onset frozen per replay (890 ×9, 3190 for the mid-attract one, none for
`06_test_mode`) — the same constants §4 v3 ratifies, which corroborates that
it is select entry. Section 3 attributes the **onset**, not a late frame:
3 bytes at 4267, all in the P1 effect-channel record pointer. New section 4
is the load-bearing one — **the same writer PC on both legs**, so it is DATA,
not control flow; a different writer set is what would mean the profile
leaked into engine flow.

**DECIDED 2026-08-17 (maintainer):** the re-scoped section 1 is ratified —
*"agreed this is why wide exists and now that it exists we must take it into
account."* Nothing about it is open. `CLAUDE.md`'s FBNeo clause was updated
the same day, since it names this gate as one of FBNeo's three guarantees
and said "dual-track inertness" with no scope.

**AND THE REAL LESSON, worth more than the fix:** `grep -rn test_dualtrack`
finds no runner — only docs and **CLAUDE.md:112, which names it as one of
FBNeo's three guarantees.** A rule was resting on a gate nobody executed.
That is GitHub #30, and it is now the highest-value open issue.

**Three new tickets, deliberately NOT folded in:** **#93**
`audit_qs_voice_batch`'s keyon failure (proven pre-existing — identical under
both input stagings), **#94** `audit_pyron_ring`'s dead `build/pyron22` (the
FOURTH reference-rot instance, so it asks for a standing check rather than a
fourth one-line repair), and **#95**, now CLOSED. #94 remains: audits pinned to
untracked build dirs with nothing to notice.

**#30 IS DONE.** There is now ONE pre-commit command:

    ROMDIR=... tests/run_all_static.sh        # PASS 88 / SKIP 0 / FAIL 0
                                              # (measured 2026-08-18; the count
                                              #  moves — read the runner, not this)

It counts PASS/SKIP/FAIL separately (#29 — a SKIP is not a pass) and names any
emulator-free gate that is in neither registry, so the orphan problem cannot
regrow. On its FIRST full run it found three gates stale for weeks
(`test_census_regions`, `test_voice_row_range`, `test_phasec_spaces` — all
fixed, all detailed in STATE 14z-94 (9)) and a fourth now filed as **#96**.

**(history) Start here next time: #96** — [14z-95: the named symptom is FIXED; two items remain, see the top] — `test_m2a_stage4_code`'s `06_test_mode`
divergence disappeared (expected 700, got none). Either a stale constant or
something live gone inert; name the mechanism before touching the number.
**RULED 2026-08-18 (maintainer), so this list has moved:** **#24 CLOSED**;
**#52 fixed and landed** (14z-95); **#27 ruled — ONE COMMAND**, a documented
procedure only if a single command cannot work; **#43 ruled — SPLIT**, land
the inert refactor now and ship the row movement at the next re-freeze.
Remaining maintainer-owned: **#57**. Architecture backlog:
#47/#48/#49/#50, #69, #71, #46, #93, #94. None blocks the re-freeze.
**#99 is PARKED (see the banner). The Phobos sfx thread is measured but
NOT closed** — the extra voices found are at the PRE-MATCH phase, not at the
end of the electrocute where the report puts them, and a `+0x382` poke
confound is open. Both are on the issue and in STATE 14z-95.

## (HISTORY, 14z-94) Where it stood then

| leg (40,620-frame arcade marathon, forced pick, sparse probe at `0x05ffb6`) | verdict |
|---|---|
| `pyron26` pre-fix (FROZEN) | **CRASH 15079** `vec3 PC 01afb6` — #92 |
| `pyron27` post-fix | **END 40620** |
| `hui41` pre-fix (FROZEN) | **CRASH 18337** `vec4 PC 0fb6e0` — #91 |
| `hui43` post-fix | **END 40620** |
| `m3b_merged8` + Huitzil (FROZEN) | **CRASH 8887** `vec4 PC 456930` — #91 |
| `m3b_merged9`, all three tenants | **END 40620** |

**MERGED GATE SET, all green on `m3b_merged9` (752 ops, `081e2e53`):**
`audit_merged_legacy` AUDIT-EXIT 0 (leg a 47/47 with 0 NOT-EVALUATED, leg b
6/6 guard-clean), `test_merged_render_content` PASS,
`audit_trap_parity` PASS, `audit_fg_parity` PASS,
`audit_select_bank_gates` PASS, `verify_gfx_build` + `check_tenant_hud` PASS
on all three tenants.

The probe fired on every leg, so it is armed rather than dead: 3 hits on the
three legs that ran to 40,620, and 2 on `hui41` — which crashed at 18337,
before the third firing. New builds `hui43` `da734d49` / `pyron27`
`e29cac23`, both UNREGISTERED and UNFROZEN; `hui41`/`pyron26` are untouched.

`tests/test_voice_row_range.sh` is now GREEN on the new builds (it stays RED
on the frozen ones, correctly). The historical shape it caught:

```
hui41/hui42 row 0x10: 0x18 at +0x01, +0x1a, +0x29, +0x31
pyron26     row 0x11: 0x18 at +0x01, +0x1a, +0x29, +0x31
don_m7      row 0x13: clean  (his row never lists his own class 0x13)
```

All eight are ONE shape: the paired table-A byte is class `0x13` (Donovan)
every time, 4/4 on both tenants and 0/12 elsewhere. Across vs2's 32 rows,
`0x18` appears 50 times and **all 50** sit opposite class `0x13`.

Vanilla never emits above **`0x16`** across all 1024 bytes of table B, and
`0x16` is exactly what the downstream table can service (derived
independently; the gate cross-checks the two and fails if they disagree).

**DECIDED 2026-08-17 (maintainer): ABARAYA (`0x0a`)** — "any stage except
Fetus of God, take the one that implies the least impact". Applied.
`tools/decode_stage_banners.py` names the twelve vsav stages, and poking the
word changes the venue on screen (measured: same match, same frame, different
stage). Chosen on three measured grounds — ABARAYA is one of only four values
already reachable in every affected group (so no rung gains a stage it could
not already produce), it is not another character's venue in these ladders
(`0x14` is Pyron's, `0x16` Jedah's), and it is the shortest banner record in
the family at 7 glyph sprites. **DONE:** `huitzil.toml` + `pyron.toml` patched
via the data_port `fixes` key, gate green, crash gone on the marathon with a
live control; the merged op-count constant re-frozen (-1, attributed) and
every merged gate green. **REMAINING:** only the re-freeze itself — registry
rows for huitzil + pyron + merged, which is a STATE decision.

**CORRECTED 14z-94 — the 14z-93 close called this "a voice, so it is
audible" and predicted the round-end flashing would correlate with voice
events.** It is not a voice. `$FF8100` is the ladder's STAGE index: it drives
the stage-name banner on the arcade map screen AND the venue you then fight
in. The flashing prediction rested on the voice reading and does not follow
from the corrected one — treat it as open, not as supported.

## The chain, if you need to re-derive it

```
authored table-B row (0x18) -> stage list $FF1E50
  -> selector loop (0x00aee2) picks index 2 -> $FF8100 = 24
  -> 0x05ffa6: A0 = 0x26775A + 2*24 - 4 = banner-table row 0x1A, STORED to $1c(a6)
  -> consumer derefs the FOLLOWING row = 0x00400000, that table's TERMINATOR
  -> [0x400000] reads 0x7080 -> jmp (4,PC,D0.w) -> vec3
```

vsav's banner family is rows `0x0F..0x1A` (12 stages, values `0x00..0x16`);
vs2's is rows `0x13..0x1F` (13, values `0x00..0x18`). **Both games number
`v=0x00` at their own first row, so the twelve shared stages are identical at
identical values and the port owes NO renumber** — which is why the defect is
four bytes and not a whole table. Every ENGINE site is vanilla and unpatched;
only the authored ROW is ours.

**THE ANCHOR IS THE TRAP.** Each game's site anchors at the address of its
family's FIRST ROW, not the pointer table base (vsavj `0x26775a` = table+0x3C;
vs2 `0x2a0a96` = table+0x4C). Decoding vs2 from its base invents a tidy "+8
renumber between the games" that does not exist — believed for part of 14z-94
until both code sites were read. `tests/test_decode_stage_banners.sh` section
3 reproduces that mistake and requires it to fail loudly.

## Do not repeat these — five of my conclusions died by measurement

| published | killed by |
|---|---|
| "element-table base is 4 bytes low" | a probe at that writer got ZERO hits while the crash reproduced |
| "0x400000 is a stock sentinel WIDE makes live" | stock and WIDE both read `0x7080` |
| "the crash is HUITZIL-ONLY" | **Pyron crashes identically** under a sparse probe — it is a RACE |
| "the selector loop exhausts" | selector 2 < bound 6; it found a real candidate |
| "the value is tenant-specific" | Pyron computes the same pointer; the SLOT differs |

**Method traps that produced those, all now in GOTCHAS:** probes must stay
SPARSE (one firing 17,616 times made the crash vanish); `l@()` memory
conditions silently do not work in `GUARD_PROBE_COND`; never cross-correlate
frames between `-debug` and non-debug runs; do not use `bp_regs.lua` on a
timing question (it is a #10 +1 staging deviant); An-relative reads inside the
crypt window need the DATA view.

**"Huitzil-only" was also my argument for retracting the 14z-85f Sasquatch
link. Since Pyron IS in that recipe, that link is OPEN again.**

## Also settled in 14z-93

- **hitclass thunk: KEEP** (maintainer). Tenant census: **0 map entries over
  37 rigs against 121 pooled type >= 64 objects** — the gap is CONTACT.
- **#78 ratified**, **#90 fixed**, **#44 fixed**, **#41 CI added**, **#82
  fixed**, **#84 closed**, **H-vs-P stuck direction closed**.
- **#10** re-verified: NOT fixed, deliberately, now `deferred-with-reason`
  and gated. Its precondition (the legacy re-freeze) HAS been met, so it is
  ripe. Budget the RE-MEASUREMENT of five gates' frame constants, not the
  one-line edits. **Re-freeze nothing** — replay.lua is untouched.

## What 14z-92 was, in one line

**Five instruments had quietly stopped measuring**, and four of them were
GREEN or unrun rather than red. A decayed gate does not fail — it stops
disagreeing.

| instrument | broken since | presented as |
|---|---|---|
| `obj_records.walk` pointer pass | fired 14z-86 | a build defect (#75) |
| `test_merged_render_content` H legs | 14z-86 | a CONTENT REGRESSION |
| `audit_hitclass_map_cost` reference | 14z-86 / 14z-82c | would have blamed the thunk |
| `test_pyron_ladder` tenant selection | always | **built Donovan**, green (#84) |
| `test_pyron_blink` guard | 14z-87 | could false-REFUSE |

If you read one thing before touching a gate: **`docs/project/gotchas.md`,
"A frozen build stops being a usable REFERENCE when the profile bumps"** —
three references rotted this session (`hui31`, `pyron20`, `pyron17`).

## Two beliefs that changed

1. **Legacy DOES enter the hit-class map — 230 times, not zero.** The old
   census was two replays, both of which score zero. The fix is still sound
   (all indices far below 64, so legacy reads vanilla's own bytes); the
   ARGUMENT was wrong and is corrected everywhere it appeared.
2. **The tree contradicted itself on the QSound terminal byte** (#82):
   `build_qs_songs.py` says INCLUSIVE (packing law #3 — the sword-plant
   beep), `audit_qs_voice_batch.py` still justifies EXCLUSIVE with the
   pre-14z-87b belief.

## Do not repeat these

- #75's blocker **had already dissolved** before the fix — merged8 verifies
  green with the pre-fix tool. The fix removed a dice roll, not a blocker.
- "It may feel better" was **emulator-sided**. The project has NO measured
  performance-positive result. Do not cite the obj_hook cycles for it.

## (HISTORY, 14z-94) The open list as it stood then — SEE THE TOP FOR THE CURRENT ONE

### THE REQUALIFIED AUDIT BACKLOG (maintainer cleared `contested`, 2026-08-16)

Eleven findings from the 2026-08-15 adversarial review are now ACCEPTED.
Ordered by severity, and split by whether they can be started without a
ruling. The 21 still carrying `contested` are NOT in this list.

**~~NEEDS A RULING FIRST — 3 items~~ ALL THREE RULED 2026-08-18 (maintainer).
The rulings are inline below; nothing in this block is open.**

- ~~**#30 + #24 + #29 ARE ONE CLUSTER, not three tickets.**~~ **ALL THREE
  CLOSED** — #30 and #29 in 14z-94, **#24 closed 2026-08-17 (maintainer)**.
  `tests/run_all_static.sh` is the runner the cluster needed, and
  `run_battery_m2.sh` now tallies PASS/SKIP and refuses GREEN at any skip.
  The original analysis, kept because the eliminations stay valid: #29 (~28 gates
  `exit 0` when their build inputs are absent) and #24 (the battery prints
  `BATTERY GREEN` anyway) are the same defect seen from both ends, which is
  why #24 carries `duplicate`; and BOTH fixes need the thing #30 says does
  not exist — a runner. Both handoffs propose the same mechanism: give SKIP
  a distinct exit (77, the automake convention) and have a runner tally
  PASS/SKIP/FAIL and refuse GREEN when anything skipped.
  **The ruling needed is #30's:** what runs the suite? The 14z-93 CI covers
  the 18 ROM-free gates and already fails on SKIP, so the pattern exists —
  the open question is the ~90 gates that need `$ROMDIR`, which CI cannot
  run. Note the blast radius both handoffs flag: flipping `exit 0` -> 77
  changes the contract for every existing caller, including HANDOFF's own
  documented command lines.
- **#27 — RULED 2026-08-18 (maintainer): ONE COMMAND.** *"It should be one
  command; the procedure should be considered only if a single command cannot
  work."* So rule 3's "reproduce from pristine inputs" is NOT satisfied by a
  documented procedure a human follows. `build_merged.sh` regenerates its own
  missing inputs — the three `build/*/extract` dirs and `build/wide0` — and
  keeps using existing ones when present so the common path stays fast. No
  ROM-derived byte gets tracked, so rule 7 is untouched.
  **The constraint to respect while implementing:** this direction unfreezes
  the same pinned dirs #26's track-mismatch guard protects, so regeneration
  must be CREATE-IF-ABSENT and never rebuild-over, and the regenerated extract
  must be proven byte-identical to the pinned one — otherwise the merged
  fingerprint moves and that is rule 6, not a build convenience.
- **#43 — RULED 2026-08-18 (maintainer): SPLIT IT, land the inert half now.**
  The ticket bundles two things with different risk, and only one of them is
  rule-6 territory:
  **(a) the refactor** — move the matcher into `find_equiv.py` with
  `hit_cap`/`allow_fallback`, delete `reconcile_batch.masked_search`, import
  it. With `allow_fallback=False` it must reproduce all 271 rows exactly, so
  ZERO built bytes move. Rule 6 does not reach a change that provably moves
  nothing, which is why a clean freeze is not a precondition for it.
  **(b) flipping the fallback on** — moves 3 rows (`0x028122`, `0x1e744e`,
  `0x0448a6`) and therefore built bytes. Rides the next re-freeze.
  Why (a) goes first rather than after: #91 was a missing reconciliation row
  that crashed the shipping build in extended play, every build ships planted
  tripwires standing in for unresolved rows (merged-m2 ~69), and #99 is a
  crash on a path no rig has executed — so if #99 is a tripwire fire, the
  canonical matcher is what names the row. Waiting is also circular: the
  freeze waits on the crash, and the tool that may diagnose the crash would
  wait on the freeze.
  **Honest condition on (a):** it is inert *if* the 271-row control holds. If
  reproducing them exactly turns out to need drifted behaviour not yet
  enumerated, that is a finding — stop and report, do not nudge rows to make
  the control green.
  **Lands regardless of timing:** `reconcile_batch.py:14` says
  `--allow-plausible` is "for experiment builds only" while
  `tools/build_merged.sh:41` hardcodes it, so plausible rows ship in the
  artifact that gets played.

**MEDIUM — no ruling needed**

- **#28** — `build_merged.sh` reads `$ROMDIR` without the mandatory
  `audit_roms.py` checksum gate. CLAUDE.md §3 is explicit; a builder that
  skips it can produce an artifact from an unaudited dump, unattributable
  under rule 4. Small, self-contained.
- **#38** — `run_replay_fbneo.sh` leaves a stale overlay `roms/` dir on the
  non-overlay branch. Same class as the 14z-90 runner-hygiene fix.
- **#42** — `_minitoml.loads()` silently switches parser by host Python and
  the guard exists in 1 of 11 manifest consumers. Rule 3 again: a
  host-dependent manifest parser makes "the build" a function of the
  developer's interpreter. Hit live this session — `tomllib` is absent on
  this box's python3. Fix without a ruling: a gate asserting both parsers
  agree on every tracked manifest.

**LOW — no ruling needed**

- **#18** — `patch_prg.py` applies every op with no expected-old-bytes and
  no source-set identity check. The old-byte verification lives in the
  GENERATOR against cached decrypted views; nothing joins that image to the
  one actually patched. Adding the check is inert if the tree is sound —
  and a finding if it is not.
- **#20** — `port_patch`/`data_port` do not assert `len(new) == len(old)`,
  so a hex-count typo silently resizes the emitted blob. Same shape: cheap
  assertion, possible finding.
- **#19** — `_PRG_RE` matches gfx members `vsw.41m`/`vsw.43m`, which the
  documented `--gfx 8` growth path creates. Inert today, wrong at the next
  member count the project has already written down.
- **#25** — `audit_wide_phase_a` A3 lets a dead measurement stand as a
  `note` and then publishes the permissive decision — against the rule the
  file's own A1 comment states.
- **#31** — `replay_guard.lua` ignores `MASK_RANGES` and has no
  input-integrity check while its header claims it "can substitute for
  replay.lua in any gate". Cheapest correct fix per the handoff is to make
  the claim TRUE (abort loudly when `MASK_RANGES`/`NO_INPUT_CHECK` is set)
  rather than porting the mask reader. Named blast radius:
  `test_crash_guard.sh` compares a guarded log to an UNMASKED expectation,
  so masking must stay opt-in or that gate goes red.

**DEFERRED WITH A REASON, AND NOW RIPE — #10 (severity HIGH)**
*"10 of 21 replay instruments feed inputs a frame later than replay.lua."*
Re-verified at HEAD 14z-93 and CONFIRMED maintainer-deliberate: the finding
is correct, it is mitigated, and the fix is deferred for a real reason.
Label `deferred-with-reason`; it stays open and stays `contested` by
decision, not by neglect.

- **State:** 21 replay-driving instruments, **10 deviant / 11 canonical** —
  the same 10 files, same two flavours the issue lists. Nothing fixed.
- **Why deferred:** the frame constants of the consuming gates
  (`test_beam_variants` DUMP_FRAMES, `test_tenant_hud` 3100/3110,
  `test_hui_df_style` OBJFR/PALFR, `audit_trap_parity` WINDOWS,
  `audit_voice_borrow` WINDOW=3985,4005) were tuned UNDER the drifted
  timing. Correcting the staging alone does not make them right, it
  silently RE-DATES them. The staging fix and the re-measurement are ONE
  change — which is also this issue's own handoff.
- **THE PRECONDITION IS NOW MET.** The gotcha scheduled it "after the
  legacy re-freeze"; that completed in 14z-91. It is ripe, not blocked —
  waiting on scheduling and on #91/#92 clearing under rule 6. **When it is
  scheduled, budget the re-measurement, not the one-line edits:** the code
  fix is one line per file in two flavours (group (i) stage
  `held[frame + 1]`; group (ii) parse `held[fr]`), and all the cost is in
  re-deriving those five gates' constants.
- **Mitigation is now real** (it was not): the gotcha promised every
  drifted instrument carried a banner and THREE did not — `bp_regs.lua`
  (none, and its header asserted the opposite), `ring_tap.lua` (none, and
  its output is frame-addressed), `read_tap.lua` (backwards direction).
  Fixed 14z-93.
- **Gated:** `tests/test_replay_stage_census.sh` pins the split at 10/11, a
  NEW instrument copying the wrong flavour FAILS, every deviant must carry
  the banner, and `replay.lua` must stay canonical. Set `EXPECT_DEVIANT=0`
  when the fix lands and it flips to asserting uniformity. **Strip Lua
  comments before censusing** — the banners quote `held[frame + 1]`, so a
  naive grep reads a drifted file as canonical (measured: it turned 10
  deviants into 3).
- **Do NOT re-freeze anything from this fix.** `replay.lua` and
  `replay_guard.lua` are both canonical and untouched, so no frozen log
  moves.

**STILL CONTESTED — 20 further items, deliberately not scheduled.** #22
(medium, `verify_pcrel_data.py` run by nothing), #77, and 18 low items.


- **#91 — A PLANTED ILLEGAL IS REACHABLE ON `merged-m1`. RULE 6: this is
  the only forward task until it is green.** Deterministic and reproduced:
  `hui41` CRASH 14767 and `m3b_merged8` CRASH 8887, both the tripwire for
  **unresolved vs2 `0x494de`**. **NOT Huitzil-only** — that was retracted
  14z-93: Pyron and Donovan's clean `END 40620` legs are a TIMING accident,
  and under a sparse probe Pyron crashes identically (#92). It is a RACE. Rig: `26_don_arcade_mash` (40,620-frame
  arcade marathon) with the forced pick — the suite's tenant rigs are too
  short to reach it and that replay picks a legacy character on its own,
  which is why this was invisible.
  **`0x494de` is a 32-bit software DIVIDE helper** (11 callers in vs2) and
  **vsavj has the byte-identical routine at `0x47fb6`** — a missing
  reconciliation row, not a missing feature. Choose the LIVE twin by
  tracing (it appears twice; content-twin trap). Do NOT remove or widen the
  tripwire — it is the detector, and 51 other deferred targets sit behind it.
  Costs a huitzil + merged re-freeze, so the row is a maintainer decision.
  Instrument: `tests/audit_tripwire_reach.sh`. **NOT the 14z-85f flaky crash
  reset** for the TRIPWIRE half (#91): Phobos was not in that recipe and the
  tripwire is Huitzil-only. **But #92 (the `0x1afb6` vec3) reproduces on
  PYRON, who IS in that recipe — so a 14z-85f/#92 link is OPEN.**

- ~~**GitHub #75 — `build_merged.sh` ABORTS on huitzil.**~~ **CLOSED 14z-92.**
  It was a VERIFIER artifact, not a build defect: `obj_records.walk`'s pointer
  pass re-derived record structure from the relocated image, so a straddled
  datum inside a real record became a valid record head under the merged
  placement window (+1 record, +67 entries, 34 out-of-band tiles). Fixed with
  the same `ptr_allow` treatment 14z-74 gave the sweep pass; gated by
  `tests/test_obj_record_walk.sh` (4 verdict controls, ROM-free, in
  ci_portable).
  **Read this part too:** the abort had ALREADY stopped happening. 14z-91
  moved `anim@huitzil` 0x41a7e0 -> 0x41a6e0 and the coincidence dissolved —
  merged8 verifies green with the pre-fix tool too (measured). Nobody knew
  because nobody re-ran `build_merged.sh` after 14z-91. **`build/m3b_merged8`
  (`952fc731`, 753 ops) now exists** and is the first merged build carrying
  the 14z-91 legacy fix — UNREGISTERED, and no merged CONTENT gate has run on
  it. That is the S6 list below.
- ~~THE BEAM VISUAL ON A MERGED IMAGE~~ **CLOSED** (maintainer,
  2026-08-16): *"beam visual is 100% clean, as is its sound."* The S6
  carry-forward is done, and the effect family — three defects, three
  root causes across 14z-70/71 — is closed end to end on the shipping
  artifact.
- **PHOBOS' HISTORICALLY-DEFECTIVE MOVESET IS FIELD-CONFIRMED ON THE
  MERGED BUILD** (maintainer, 2026-08-16): 236+P, 236+K, jump214+K,
  236+2K, 214+2K "in the variants that broke or were incomplete in the
  past and their ES variants". That is the beam family (14z-70/71, three
  root causes) and the Plasma Trap (out-of-range entry 82, the LOUD one),
  ES included — and an ES that fires is a stronger statement than it
  looks, because an empty meter silently downgrades.
  Combined with the rigs, the whole danger set for table 0x018468 is
  covered by whichever instrument can reach it: entry 82 by the
  maintainer AND `audit_trap_parity`; entry 83 (Reflect Wall, SILENT) by
  `test_hui_pairs` only — it is guard-cancel-only, so a rig is the ONLY
  way it can ever be confirmed. `test_index_space` /
  `test_variant_dispatch` / `test_index_window_thunk` all PASS on
  merged8 besides. **Remaining L/M/H strengths are unknown-unknowns, not
  a named mechanism — a nice-to-have, not a risk item.**
- ~~"IT MAY FEEL BETTER"~~ **CLOSED (maintainer, 2026-08-16): it was
  EMULATOR-SIDED**, not the ROM. No headroom/overrun A/B is needed and the
  obj_hook-cycle mechanism is NOT the explanation. Recorded so nobody
  re-opens it as a performance claim: the project has no measured
  performance-positive result, and this was not one.
- **`build/m3b_merged8` IS FROZEN as `merged-m1` (14z-92):**
  render-content, trap parity, FG parity, select-bank-gates and
  `audit_merged_legacy` (AUDIT-EXIT 0, leg a 47/47, leg b 6/6) all PASS.
  Frozen by TAG + HANDOFF row with **no `registry.tsv` row on purpose** —
  the legacy-only instrument `build/merged1` shares its program
  fingerprint, so a row would register the blanks build too. Read the
  `tests/expected/registry.tsv` header before touching that.
  Repaired in the process: `test_merged_render_content` named `build/hui31`
  as its huitzil reference — a pre-WIDE-v1.1 build MAME refuses — so H/P's
  only render gate had produced **no huitzil measurement since 14z-86**, and
  printed the dead leg as a content mismatch. Now points at `hui41` and
  reports an empty operand as a DEAD LEG. **D and P still name `m5_wide` /
  `pyron21`; re-point a row whenever that tenant is re-frozen.**
- ~~OPTIONAL, ~2 h: `tests/audit_merged_legacy.sh`~~ **RUN at the freeze,
  AUDIT-EXIT 0** (leg a 47/47 with 0 NOT-EVALUATED, leg b 6/6 guard-clean
  vs don_m7 / hui41 / pyron26). It was a re-run on this tree by
  construction; what it bought is the determinism confirmation — it
  rebuilt its instrument from scratch and reproduced 753 ops and the same
  fingerprint.
- The merged build now has its own class table, `tests/expected/merged1/` —
  read its README before touching a spec there, and do not copy a tenant
  set's line into it: the two tables are measurably not interchangeable,
  which is why it exists.
- ~~M4: `audit_hitclass_map_cost.sh` over the FULL corpus~~ **RUN 14z-92 —
  AND IT FALSIFIED THE CLAIM IT WAS FILED TO CHECK.** `hitclass_map_extend`'s
  adoption rested on "legacy never enters the map", measured over TWO
  replays — both of which happen to score zero. Corpus-wide (46) legacy
  enters **230 times** (`26_don_arcade_mash` 228, `24_don_winmash` 2). The
  fix is still sound: every legacy index is 0x02/0x04/0x09/0x0b, far below
  64, so legacy reads VANILLA's own bytes out of the thunk. The argument is
  now "legacy enters and gets vanilla answers". Section 1: 43/46
  bit-identical, 3 transient re-convergent, 0 dead. Claim retracted in
  engine_internals, HANDOFF, and both manifests.
- ~~**OPEN from #78 — two FBNeo-only phase classes.**~~ **RATIFIED
  2026-08-16 (maintainer) and implemented 14z-93.** Both are now a named §4
  class bounded by a FROZEN offset inventory (`$FF055B-D`; `$FF06D1`,
  `$FF06D4-D5`, `$FF06D9`, `$FF06DB-DD`), measured rather than transcribed —
  the 14z-92 note had recorded only the first byte of each run. Gate green.
  `ram.md:62` extended: the class is NOT tenant-content-only. Original entry: The new
  `tests/test_fbneo_legacy_oracle.sh` (the agreed partial) found, on its
  first run, differences that MAME does NOT show at the same frames:
  `$FF055B-$FF055D` (sound-driver work area, ram.md:74) and
  `$FF06D1/D4/DB` (OBJ-builder secondary stack, ram.md:62 "execution
  POSITION, not state"). Both are attributed and bounded to two named
  windows; neither is gameplay state. They are reported as `open:` lines,
  NOT as tolerances. **The ruling needed:** ram.md:62 records that class as
  appearing only on tenant-content replays where no vanilla oracle applies —
  it appears here on LEGACY content under FBNeo, which extends it. Per §4 a
  new tolerance needs sign-off. `FBNEO_ORACLE_EXPECT=exact` is the
  post-ruling target.
- ~~**OPEN from M4 — is the thunk still load-bearing?**~~ **DECIDED
  2026-08-16 (maintainer): KEEP `hitclass_map_extend`, at least for now** —
  *"we have more to lose by dropping it than keeping it."* Nothing to do; the
  row stays in `huitzil.toml` + `pyron.toml` and no build moves. The measured
  basis follows, and the ONE thing that would reopen it is named at the end.
  The tenant enters the map **0 times** over all 37
  hui+pyron rigs — while putting **121 objects of type >= 64 into the
  projectile pool** (9 distinct types, 64-72, in 22 of the 37 rigs). The gap
  is CONTACT, not absence: the sweep is POOL-vs-POOL, so a tenant projectile
  hitting a FIGHTER never transits the map. Each of those 121 is one
  collision away from indexing past vanilla's 64 entries.
  **The dead crash control is diagnosed, not mysterious** (section 4): the
  soak rig reaches the map 0 times, so the no-thunk twin has nothing to crash
  on — yet that same rig still spawns 13 type-64/67 objects. A RIG failure.
  Do NOT drop the row on it, and do not re-point it at a new crash address.
  **Count the rows carefully:** 93 stamp rows carry `type >= 64`, but only
  **36** are in the 64-75 projectile-pool band that can over-index this map;
  the other 57 are the 114-120 obj_hook family (owner-tag served, never
  reaches the sweep). 93 overstates the exposure 2.6x.
  **WHAT WOULD REOPEN IT (the "for now" clause):** a pool-vs-pool contact rig
  that section 3 then measures at 0 extension entries. Nothing else — and
  specifically not the dead crash control, which is a rig artefact.
- **OPTIONAL, and no longer blocking anything: author a pool-vs-pool contact
  rig.** No rig in the corpus produces one, which is why the census reads 0.
  `tests/replays/hui/88_hui_plasma_trap_contact.rpl`'s header names what is
  needed — "an opposing PROJECTILE to clash with, e.g. P2 Victor doing a
  pool-object move into the mine — not a walking fighter". Pyron's cosmo rigs
  are the richest source (17-28 type-66 spawns each), so a Pyron-vs-
  projectile-character pairing is the likeliest route. It would buy two
  things: the tenant census gets a real denominator, and section 0's crash
  control becomes revivable. With KEEP decided, this is coverage work rather
  than a decision blocker.
- The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- ~~Round-end flicker~~ **CLOSED 2026-08-18 (maintainer).** It was carried
  as "parked, needs the maintainer's recording"; the merged-m2 playtest
  did NOT observe it and the maintainer ruled it closed. Not carried
  forward. If it ever resurfaces the first question is which build and
  which emulator — the 14z-93 prediction that it would correlate with
  voice events rested on the `$FF8100`-is-a-voice reading, which 14z-94
  corrected to the ladder STAGE index, so that link does not follow.
- OPTIONAL / cosmetic (maintainer 2026-08-15): the merged-only
  P2-ring-on-Donovan medallion whitening; win-screen QUOTE (both tenants);
  region_space re-freeze; op-tagging for test_shared_writes. **Donovan's
  venue palette row 0x0F** joins this list — change A traded vs2's red
  statue ramp for vsavj's, which the scope ruling makes optional; the
  cost-neutral route back (init shim → the engine's own copy helper
  `0x1C3A4` → staging row 0x0F, i.e. the fade's SOURCE) is written up in
  `build/manifest/donovan.toml` above the retired rows.
- ~~H-vs-P stuck-direction (~1/30)~~ **CLOSED 2026-08-16 (maintainer):
  never reproduced on FBNeo at all, and not reproduced on any recent build.**
  Surmised to be either an emulator-side artefact or a symptom of the period
  when Pyron and Phobos SHARED code — which they no longer do (the 14z-85
  spawn-time owner tag gave the 0x54470 family per-tenant resolution, and the
  type_renumber path did the same for 114-119). Not carried forward. If it
  ever resurfaces, the first question is which emulator, and the second is
  whether any shared-resolver path has been reintroduced.
- Then MiSTer core surgery (stretch, DECIDED) — after the roster.
- **BEYOND MiSTer (scope extension, maintainer 2026-08-18):** **GitHub
  #100**, the next-stage screen showing Donovan with a Victor name and a
  blank portrait. Closed WON'T FIX for now under the standing cosmetic
  ruling (cosmetic + single-player-only surfaces are nice-to-have) and
  re-scoped to after MiSTer. **The mechanism is already measured, so
  whoever picks it up starts from the fix, not the hunt:** one writer
  (`PRG:0x00A446`, `andi.w #$000F` at `0x00A442`) feeding `RAM:$FF8130`,
  and FOURTEEN readers — eight of which RE-FOLD, so widening the writer
  alone changes nothing. Full detail on the issue and in STATE 14z-95.

## Build / validate

(paths refreshed to the 14z-99 freeze generation at the post-freeze close —
the commands are operational, not historical, even though they sit below the
history marker)

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2

# the canary — safe as written since 14z-91
VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
  tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m9/mask)" 16_xemu_2p

MAME_ROMPATH="$PWD/build/don_m9/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_m3a_reproducible.sh                 # ~6 min, all five, hard on content
tests/audit_walker_ghost.sh                    # ~5 min — the mask assumption
tests/audit_walker_repoint.sh build/don_m9     # ~5 min — caller completeness
tests/test_obj_walker_relocation.sh build/don_m9   # seconds, ROM-free
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
tests/test_obj_record_walk.sh                  # seconds, ROM-free — the #75 gate
tools/build_merged.sh build/m3b_merged11       # ~1 min
```

## Rebuild recipes

```sh
KEY_SET=vsavj WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
  GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
  tools/build_donovan.sh 6 build/don_m9
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 ... build/hui45
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 ... build/pyron29
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock4
```
