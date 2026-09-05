# SKILLS SCOPE — the remaining distillations (CPS-2, emulation, the game, the port)

> **STATUS (14z-118 audit): EXECUTED 14z-114 — all four skills exist and are
> locked (`tests/test_checkskills.sh`).** §4 (the staleness pass each skill
> needs) stays the live template the 14z-118 documentation audit follows;
> the rest is the record of boundaries and decisions.

Written 14z-114 (2026-08-28), **the plan before the work**, as the sibling of
`mister_scope.md` (whose two skills shipped the same day with their checker).
It answers: which skills remain, where each boundary falls, which docs feed
which, how the checker extends, what must be read and made current before
each is written, and in what order. The maintainer's sketch (2026-08-24,
STATE "Decisions pending"): *at least a CPS-II skill separate from a
VS/VS2/VH2 skill, and MiSTer separate from emulation; exact scopes to be
agreed.* MiSTer is done; this document fixes the rest.

**Ground truth at the time of writing:** main == origin/main at `bb8ecde`;
the doc set is 26,459 lines (`wc -l docs/**/*.md`); MiSTer's ~5,300 are
distilled; the remainder splits as game 6,470 (engine_internals 3,733 +
atlas 2,344 + gotchas 653 — minus headers), platform-non-MiSTer ~1,700
(platform/gotchas.md lines 9-1027 and 1834-1892 + cps2_wide.md 642),
project ~9,000 (project/gotchas.md 3,133, patch_notes 3,745, porting_* 305,
build_dir_triage 380, hardening_register 247, tenant_manifest 192,
patch_index 286, plus CLAUDE.md and the non-MiSTer HANDOFF). GOTCHAS index
count at 14z-107: 46 game / 79 platform / 179 project entries.

---

## 1. The rule, restated for three more buckets

Same test as `mister_scope.md` §1 and `docs/README.md`: *would this still be
true if we abandoned the roster hack tomorrow?* — applied at one remove:

| skill is… | if a stranger could use it unchanged while… | forbidden in its text |
|---|---|---|
| **CPS-2 hardware** | hacking ANY CPS-2 game on ANY emulator | game names, characters, tenants, build dirs, manifests, MAME/FBNeo build recipes |
| **CPS-2 emulation** | driving MAME/FBNeo on ANY CPS-2 game | game names, characters, tenants, build dirs, manifests |
| **the game** (VS/VS2/VH2) | working on Vampire Savior's engine with no port in mind | tenant, `build/`, `merged`, `m3b_`, `wide_ext`, manifest/generator names, fingerprints |
| **the port** | — dies with the project | nothing |

Two consequences that decide placements, both already paid for:

* **"Vanilla art through the wrong palette row", "the per-char OBJ bank word
  carries game logic", "y bit 15 is the terminator"** — game facts in the
  first two cases, a CPS-2 fact in the third. The OBJ *format* is hardware;
  *how vsav fills it* is the game; *what the port does with bank bits* is
  the port. Three rules, three skills, and each cites the others by ID.
* **The harness is split down the middle.** MAME's `-debug` perturbing
  multi-CPU timing, Lua write taps dropping on re-install, FBNeo resolving
  members by CRC: emulation facts. `GUARD_PROBE` grammar, forced-pick pokes,
  the replay `.rpl` format, `run_wide.sh`: project instruments. The
  emulation skill says *what the emulator does to a probe*; the port skill
  says *which probe to reach for*.

---

## 2. The four remaining skills

Four rather than the sketch's "at least two", because "MiSTer separate from
emulation" implies an emulation skill of its own and the platform gotchas
split cleanly at the hardware/emulator line (§1). Same package shape as the
MiSTer pair: one `SKILL.md` per skill, one section per row below, rules
`- [PFX-N]` anchored `**[PFX-N]**` in the doc paragraph they distil.

| # | skill | prefix | covers | does NOT cover | primary sources (read in full) | gates / tools it names |
|---|---|---|---|---|---|---|
| A | **`cps2-hardware`** | `CPH` | ROM file byte order vs 68k logical order; the encryption: range INCLUSIVE of its upper word, opcode vs data views (PC-relative reads are DECRYPTED, `(An)` reads are DATA-space), code above the window stored RAW, static reads of encrypted code are noise; gfx: simms not tile-contiguous, tile-band bank bits, `gfx_tiles.decode`'s mirrored halves, hash-shadowing by CRC in BOTH emulators; the OBJ format: y-word bit 15 the terminator, both ORAM pages, the CPS-2 Turbo promote; QSound: sample windows in ONE half of a 64K bank (signed pointer compare), byte-parity packing law, the inclusive `end`, the tight-loop "beep", the 7-bit bank latch; the WIDE profile as a platform artifact (sizes, the group-of-4 loader rule, power-of-two QSound as FBNeo's rule not MAME's/jtcps2's, the reserved `$400000-$40000F`, Correction A2) | anything MiSTer (`[MSC-*]`); how the game uses these; the emulators' own behaviour (B) | `platform/gotchas.md` entries 9-128, 172, 203-238, 399-430, 458-543, 749-901, 1004; `cps2_wide.md` "The profile", "Phase A", "Correction A2", "Group C 3-tenant layout" (the LAYOUT is level 2 — cite only the rule), "Known limits"; `HANDOFF` "What exists" rows (decrypt oracle) | `test_decrypt_oracle.sh`, `tools/cps2_decrypt.py`, `tools/gfx_tiles.py`, `audit_romset_identity.py`, `test_wide_profile.sh` (as the profile's own gate), `test_qs_songs.sh` |
| B | **`cps2-emulation`** | `CPE` | MAME: `-log` not `-verbose`, `-debug` perturbs timing (never compare its checksums; every watch config is its own timeline), breakpoints are samplers, debugger stops desync replay counting, `wpset` blind to pc-relative reads, watchpoint length parsed as hex, watchpoints log REGISTERS not values, `-video none` still steals focus, `-aviwrite`, palette RAM pokes read back but don't render, Lua: write taps fire / read taps don't, taps dropped on re-install, guard the notifier, `move.l` = two word writes, word-aligned taps, `device_rom_interface` reads invisible; the source build (space-free mirror, SOURCES filter omits drivers silently, SDL3 via pkg-config, `mame.lst` no comments, parity BEFORE patch, `WIDE=0` did not revert); FBNeo: `SKIPDEPEND=1` and what it hides, shared EEPROM breaks determinism, CRC-match → `0xFF` fill with `(OK)`, no `-rompath` in the SDL frontend, no video = no sprite path, the harness knobs (`-hinput/-hout`, `FBNEO_HVIDEO/HGFX/HTAP/HPOKE`); the two-implementation protocol (frame indices and slots do not transfer, cross-driver `VIDEO_OUT` not comparable, chained rompath lies about identity, `git apply` inside another repo's tree exits 0 doing nothing, submodule add stages the default branch) | the project's rigs and their grammar (D); MiSTer (`[MSC-*]`) | `platform/gotchas.md` entries 29-89, 144-193, 240-399, 429-457, 543-748, 813-870, 932-1004, 1834-1892; `cps2_wide.md` "Emulator change budget", "Governance", "B5"; `HANDOFF` "What exists", "MAME from source (B5)", "Platform / migration notes", "If it still will not start"; `project/gotchas.md` entries that are emulator FACTS filed in the project bucket (e.g. "Cross-emulator replays: same inputs ≠ same content", "`git apply` SILENTLY SKIPS", "The FBNeo gate never rendered a pixel") — cite, and flag for re-filing in the staleness pass. **RE-FILED 14z-118 (maintainer-ruled): thirteen entries moved to `platform/gotchas.md` verbatim with their anchors; the 14z-90 onset entry moved game -> project** | `test_mame_parity.sh`, `tools/setup_mame.sh`, `tools/setup_fbneo.sh`, `tools/run_mame.sh`, `tools/run_replay_{mame,fbneo}.sh`, `test_attract_determinism.sh`, `test_harness_frame_bound.sh` |
| C | **`vampire-savior-engine`** | `VSE` | the three-sibling method (three official builds of one engine: diff first, the DEAD-ROW class, content twins — hook the LIVE copy found by tracing, per-handler CODE BIAS between games, families RENUMBERED between games); the subsystems as laws not addresses: OBJ pipeline and the sprite-list DRAWER, the per-char bank word carries logic, anim numbers (+0x300 facing; set-anim QUEUES), the object TYPE dispatch and pool walker, allocator wrappers/seeding/the watchdog class, the sub-state dispatcher family, the class-02 sequence system, the damage pipeline (two appliers, one scaler), the round judge (death is the SIGN of white HP), the capture-pose installer, the arcade ladder (venue byte, the sound-fed draw), the select screen (cell index IS character id, unmasked ≥0x10, the record pointer cached at init), venue assets (no free palette row, rows 0x10+ are P2's), the QSound command path, the CPU AI action-script tables (16 + the same 16), CPU exceptions and the soft-reset path, the down-transition white frame; the id space (folding sites, reserved ids, the variant half); the atlas as the bible and "a subsystem section names its atlas rows" | how any of it is MOVED (D); which bytes the port wrote | `game/engine_internals.md` (all 3,733 lines, incl. the "NOT YET SYNTHESISED" backlog and every RETRACTED block — eliminations stay), `game/gotchas.md` (46 entries), `game/atlas/{ram,character_tables,id_space,select_screen,sprite_lists,venue_assets}.md` | `test_select_wheel.sh`, `test_select_arrays.sh`, `test_beam_list_type6.sh`, `test_down_flash_vanilla.sh`, `audit_effect_class_rows.sh`, `audit_palette_seq_ids.sh`, `tests/lua/*` (as the instruments the atlas rows were measured with) |
| D | **`vampire-saved-port`** | `VSP` | THE SUPERSET INVARIANT as method (vanilla wins ties; the masked basis; the §4 classes — exact / flicker / frozen first-divergence / bounded window / composite / the FBNeo phase classes — as frozen expectations, never tolerances; the standing watch); the build law (rule 3 no hand edits, rule 5 tables, builders chain and diff once, sentinel CRCs, the canary romset vs the shippable one, region_space/hole placement, pc-relative escapes, reconciliation rows, `fixes = "off:old:new"`, data_ptr/bank_map, the op-count and pin freezes, `--check`-gated generators); porting code regions (the four checks, crypt placement) and sprite lists (the four questions); the freeze ritual (tags, registry row, re-point sweep, build-dir policy — grep FOUR places, the MiSTer tail `[MSV-16]`, the stock twin); the verification discipline that is OURS (rigs: forced-pick pokes end by ~1500, kill pokes, `GUARD_PROBE(_HIST)`, lazy breakpoints, dump dirs never shared, identify moves by EFFECTS, 1P rigs pinned to the arcade draw, per-character timing, recordings `<what>-<freeze>-NN`, `run_inp_guarded/probe`); the deadness register and the hardening register; the session ritual by CITATION (CLAUDE.md §5 retraction discipline, bug archaeology, anti-hyperfocus, STATE/HANDOFF/NEXT_SESSION, the rollover) | the game's laws (C), the emulators' (B), hardware (A), MiSTer (MSC/MSV) — cited by ID | `CLAUDE.md` (cited by section, never restated — it is the law, the skill is the reminder), `HANDOFF.md` "Running a CPS-2 WIDE build", "THE HARDENING PROGRAM", "THE §4 COVERAGE PROGRAM", "How to build/test", "THE REVIEW-TRIAGE GATES", "THE OUT-OF-RANGE INDEX TOOLKIT", "Build registry" (the shape, not the rows), "Key findings"; `project/gotchas.md` (179 entries — distil by CLASS, not by instance; the 14z-9x "N traps" digests are already classes); `porting_code_regions.md`, `porting_sprite_lists.md`, `tenant_manifest.md`, `build_dir_triage.md`, `hardening_register.md`, `patch_index.md` (the registry SHAPE), `patch_notes.md` (SKIM — byte detail is the log the skill's numbers cite, not a source of rules), `cps2_wide.md` "Governance", STATE "STANDING PRINCIPLE", "THE DEADNESS REGISTER" | `run_all_static.sh` and the two registries, `test_release_roundtrip.sh`, `test_m3a_reproducible.sh`, `test_inp_corpus.sh`, `test_compare_{window,composite}.sh`, `audit_merged_legacy.sh`, `test_dualtrack.sh`, `test_fbneo_legacy_oracle.sh`, `test_wide_profile.sh`, `tools/build_donovan.sh`, `pack_build.sh`, `package_release*.py` |

**Where the boundaries are NOT clean, named now so the skills do not paper
over them:**

1. **`cps2_wide.md` is three documents** (mister_scope §5.1): the profile
   (A), the B-series diagnostic narrative (B: the canary/CRC lesson is an
   emulator fact; the ROMSET-side "canary is not the shippable romset" is D),
   and the MiSTer edition (done).
2. **`project/gotchas.md` holds emulator facts filed by task** — the very
   trap `docs/README.md` rule 1 warns of. The B staleness pass lists them
   (file:line) and the maintainer rules whether to re-file; the skill cites
   them where they are meanwhile.
3. **The atlas is measured on `vsavj` and quotes vs2/vh2 twins** — those
   twins are GAME facts (C) even though only the port ever reads them.
   `character_tables.md` "THE PORTED THREE — located" is C; "M2a extraction
   findings" is D.
4. **The verification classes are half law, half method.** The DEFINITIONS
   live in CLAUDE.md §4 (cite); the MEASUREMENT lessons (onset moving
   earlier is the failure; the ≥60 rule is intra-mechanism; a hook flips
   parity permanently) are D's rules, anchored in `project/gotchas.md` and
   `game/gotchas.md` ("Moving a frozen ONSET frame…").
5. **`docs/project/mister_*` cross-links**: the freeze ritual's MiSTer tail is
   `[MSV-16]`; D cites it and does not restate it.

---

## 3. The checker, extended (decided; no maintainer surface)

`tools/checkskills.py` becomes table-driven per prefix — the MiSTer pair
already is, in the two module tables; the change is data, not shape:

| prefix | skill path | anchor docs | LOG set (numbers must appear here) | liftability tokens |
|---|---|---|---|---|
| `CPH` | `.claude/skills/cps2-hardware/SKILL.md` | `platform/gotchas.md`, `cps2_wide.md`, `HANDOFF.md`, `game/atlas/ram.md` (the CPS-2 video registers) | `platform/gotchas.md`, `cps2_wide.md`, `HANDOFF.md`, `docs/checksums.txt` | game/character/tenant names, `build/`, `merged`, `m3b_`, `manifest`, `setup_mame`, `setup_fbneo` |
| `CPE` | `.claude/skills/cps2-emulation/SKILL.md` | `platform/gotchas.md`, `project/gotchas.md`, `cps2_wide.md`, `HANDOFF.md` | same as CPH + `project/gotchas.md` | game/character/tenant names, `build/`, `merged`, `m3b_`, `manifest` |
| `VSE` | `.claude/skills/vampire-savior-engine/SKILL.md` | `game/engine_internals.md`, `game/gotchas.md`, `game/atlas/*.md` | `game/atlas/*.md`, `game/gotchas.md`, `game/engine_internals.md` (its measurements are inline and name their instrument — it is a log AND a synthesis; ruled acceptable because the atlas rows it names are the provenance) | `tenant`, `build/`, `merged`, `m3b_`, `wide_ext`, `gen_donovan`, `gen_huitzil`, `gen_pyron`, `.toml`, `x101aca`, `x088512`, `32007911` |
| `VSP` | `.claude/skills/vampire-saved-port/SKILL.md` | `CLAUDE.md`, `HANDOFF.md`, `project/gotchas.md`, `game/gotchas.md`, `porting_*.md`, `tenant_manifest.md`, `build_dir_triage.md`, `hardening_register.md`, `patch_index.md`, `cps2_wide.md`, `STATE.md` (the two standing sections only) | `project/gotchas.md`, `patch_notes.md`, `patch_index.md`, `HANDOFF.md`, `CLAUDE.md`, `STATE.md`, `STATE_HISTORY.md` | none |

Two refinements the MiSTer run showed are needed:

* **Anchoring in STATE.md's standing sections is fragile** (the file rolls
  over). Rule: a `**[VSP-N]**` marker may sit only under "STANDING
  PRINCIPLE" or "THE DEADNESS REGISTER", which never roll; the checker
  refuses a VSP anchor anywhere else in STATE.md.
* **Cross-skill references** `[MSC-N]`, `[RH-N]` inside a skill are plain
  (not bold, not opening a bullet) and ignored — as today. Add one check:
  every cross-reference to an `MSC`/`MSV`/`CPH`/`CPE`/`VSE`/`VSP` ID must
  resolve to a DEFINED rule in the named skill (a dangling cross-ref is a
  stale skill). `[RH-N]` is not checked (the RH skill lives outside the
  repo; the SMS checker takes `--user-dir` for that and we do the same).

Gate: `tests/test_checkskills.sh` gains one perturbed copy per new skill
(unanchored rule) and one cross-reference control. Still ci_portable.

---

## 4. The staleness pass each skill needs — MANDATORY before distilling (the MiSTer ruling, applied)

`mister_scope.md` §6 found twenty stale status claims in ~5,000 lines and the
maintainer ruled the pass must run before any distillation. The same ruling
applies here by construction. **Each pass is: read the sources IN FULL, list
every status claim that git/tree contradicts as `Sn file:line says / true
now / moved at`, fix in place with retraction discipline (headers and summary
lines first, history kept and marked, re-grep empty), one commit, then
distil.** What is already known to need it:

| pass | known-stale or unsynthesised, before reading | size |
|---|---|---|
| A + B (platform) — **RAN 14z-114**: S-A1 `cps2_wide.md` B5b "pending" (done 14z-59e); S-A2/S-A4 "one widened condition" / "one gated core line" in `cps2_wide.md` "Where the profile stands" and HANDOFF (two gated blocks since 14z-90); S-A3 "Remaining before content work: B5/B5b" (both done); S-A5 the `-video none` gotcha predating `SDL_VIDEODRIVER=dummy` (14z-59d); S-A6 "MAME … a pinned source build is a prerequisite" (done, B5). All fixed in place, re-grep empty. **RE-FILING CANDIDATES (emulator facts filed in `project/gotchas.md`, anchored where they are, the maintainer's call whether to move them): "Pre-seeded from the ROM-audit round" (MAME audits the whole board), "Cross-emulator replays: same inputs ≠ same content", "Sound is invisible to every RAM and pixel gate", "Censusing a structure without knowing its terminator", "The FBNeo gate never rendered a pixel", "An A/B reference binary must differ by exactly one thing", "A canary must change exactly ONE thing", "A relocation test with no negative control", "The MAME replay harness was blind to the video path", "`git apply` SILENTLY SKIPS", "`git submodule add` stages the DEFAULT BRANCH", "`WIDE=0 setup_fbneo.sh` did not produce a clean reference", "MAME palette RAM takes Lua pokes for READBACK but not for RENDERING", "Every -debug watch configuration is its own TIMELINE" (14z-98).** | `platform/gotchas.md` is append-only and its pre-14z-59 entries name paths/flags since changed (`FBNEO_ROMPATH` absolutised 14z-110; the FBNeo harness has rendered pixels since B2; `SKIPDEPEND` entry predates the two-patch layout); `cps2_wide.md`'s B-series "pending" rows (B5b) | ~1,700 lines, one session's half |
| C (game) — **RAN 14z-114**: S-C1 `engine_internals.md` header "NOT YET SYNTHESISED (audited 14z-68m)" above its own CLEARED note; S-C2 the M2b slot-0x0F band placement and its "remaining before an M2b freeze" list; S-C3 the select-screen "next session" plan and "remaining select cosmetics"; S-C4 the sound section's "must be re-diagnosed" (root-caused 14z-52) and "maintainer decision material" (decided: WIDE QSound + M5); S-C5 the Dark Force header/status "palette OPEN" (fixed 14z-84 `df_gold_variant_id`); S-C6 capture-pose "MEASURED FEASIBLE" (shipped 14z-99, #104); S-C7 win screen "KNOWN-OPEN #105" (fixed 14z-99); S-C8 14z-70e "explosion believed CORRECT" (retracted by 70f); S-C9 atlas README's phantom per-romset files and "Known so far (M0)"; S-C10 `ram.md` masked-basis set names; S-C11 `select_screen.md` PS1 "do not build from these yet". All fixed in place, history kept. S-C12 `game/gotchas.md`'s TITLE LINE had the 14z-90 onset-frame entry spliced into it (restored; the entry is a verification-class fact — re-filing candidate for the project bucket). **UNVERIFIED, left as written and flagged:** the M2b sprite-palette note "other 0x90C140 writers not yet repointed" (nobody re-measured it), the attract-demo roster TODO in `ram.md`. | `engine_internals.md` opens with a "NOT YET SYNTHESISED — the standing backlog (audited 14z-68m)" that has not been re-audited in 45 sessions; the Dark Force section carries "mechanics UNPROVEN"; the grenade section's header was the 14z-71 retraction example; the atlas README says "Known so far (M0)"; `id_space.md` "Re-measuring" predates the extended wheel; `select_screen.md` predates the 21-cell layout in places (§ "The measured extension") | ~6,500 lines, a full session |
| D (project) — **RAN 14z-114**: S-D1 HANDOFF's playtest block ("merged-m6, FROZEN 14z-105", the "M6" tell, solos don_m11/hui47/pyron31, the "Current WIDE builds" header stopped at 14z-105 while four freezes sat in the registry) -> merged-m10 / M8 / don_m14-hui48-pyron32 with a new current-builds header; S-D2 `patch_index.md`'s four romset rows (CURRENT = the 14z-102 generation; the hui9 gfx-rung row asserting a pinned `hui6` deleted two sweeps ago) and the FBNeo 0002 row's "ONE widened condition" (two gated blocks, rule 1 v2); S-D3 `hardening_register.md` #107 and #109 "-> the next window" / "fix waits on the tint ruling" (both SHIPPED 14z-102) and guard currency at hui45/pyron29/don_m9; S-D4 `build_dir_triage.md`'s "must join the re-point sweep" (done every freeze since); S-D5 `project/gotchas.md` "the GENERATOR side is still open" for the post-increment reader (relocated since 14z-69); S-D6 `tenant_manifest.md` "multi-tenant manifests refused until M3 Phase 3" (Phase 3 is `build_merged.sh`). All fixed in place, history kept, re-grep empty. **Left as written, UNVERIFIED:** the 14z-43b "note here when the scripted-accept divergence is root-caused" (never revisited; the 14z-99 "#43(b)" is GitHub #43, a different item) and `audit_id_space`'s "still open here" copy-narrowing case. | `project/gotchas.md` is 179 entries with several "RESOLVED" cross-references (14z-100/101); `hardening_register.md`'s H3 queue and `build_dir_triage.md`'s A1-C classes are dated to the 14z-102/103 sweeps and the 14z-112 sweep moved 26 generations; `patch_index.md` was re-registered at 14z-113 for jtcores only; HANDOFF's playtest defaults (checked 14z-113 for `merged13` only) | ~9,000 lines (patch_notes skimmed), a full session |

**What the MiSTer run taught, to budget for:** the checker's first real run
will find numbers the skills need that no LOG carries (five figures at
14z-108/109 lived only in the synthesis). Expect the same for C (numbers in
`engine_internals.md` whose atlas row was never written) and D (numbers only
in STATE_HISTORY). The fix is to enter them in the log, not to drop the
rule.

---

## 5. Sequencing, and what one session can carry

> **STATUS 14z-114: A + B SHIPPED** — `cps2-hardware` (`[CPH-1..30]`, sections
> A.1-A.5) and `cps2-emulation` (`[CPE-1..42]`, B.1-B.4), 72 anchors in
> `platform/gotchas.md`, `project/gotchas.md`, `cps2_wide.md` and HANDOFF;
> `tools/checkskills.py` now table-driven per prefix with cross-reference
> resolution; the gate carries six controls. Yield 72 rules from ~1,700
> lines against the §5 estimate of 80.
> **C SHIPPED the same session** — `vampire-savior-engine` (`[VSE-1..83]`,
> sections C.1-C.9, NO ROM addresses per decision 2), 83 anchors across
> `engine_internals.md`, `game/gotchas.md` and six atlas files, after the
> C staleness pass (S-C1..S-C12); seven gate controls. Yield 83 from ~6,500
> lines against the estimate of 70.
> **D SHIPPED the same session** — `vampire-saved-port` (`[VSP-1..161]`,
> sections D.1-D.6 + D.3b: the law by citation, oracles and frozen classes,
> extraction/reconciliation/generation, sprite lists, freezes/registry/build
> dirs/releases/suite, rigs and probes, attribution), after the D staleness
> pass (S-D1..S-D6, its own commit); 161 anchors across CLAUDE.md (33),
> STATE's two standing sections (3), HANDOFF, both gotchas, the two porting
> docs, `tenant_manifest`, `build_dir_triage`, `hardening_register`,
> `patch_index`; the checker gained the STATE-section restriction of §3 and
> the gate its eighth control. Yield 161 from ~9,000 lines against the
> estimate of 90 — the gotchas distilled one rule per CLASS entry as
> planned, and the 14z-9x digests were already classes. **NOTHING REMAINS
> of this plan; it is now the record.**

1. **A + B first** — smallest, lowest staleness risk, and they are what the
   other two cite (`[CPH-*]` for the OBJ format, `[CPE-*]` for every probe
   caveat). One session: pass + both skills + checker extension + gate.
2. **C second** — the largest READ (engine_internals is the document a
   stranger reads; every rule must be a LAW, not an address — RH-58 applies
   in reverse: a skill quoting an address is a claim the checker forces into
   the atlas). One session, possibly two if the backlog audit is heavy.
3. **D last** — it cites all of the above, and it is where the risk of
   restating CLAUDE.md is highest. Rule for D: if a sentence is already in
   CLAUDE.md, the skill carries the ID and a pointer, not the sentence. One
   session.

Estimated rule counts, from the source sizes and the MiSTer yield (109 rules
from ~5,300 lines with heavy retraction history): A ~35, B ~45, C ~70, D ~80.

---

## 6. Decisions — taken under stated assumptions, open to veto (recorded in STATE "Decisions pending")

1. **Four skills, not three** (emulation split from hardware, per "MiSTer
   separate from emulation"). Veto → merge A and B under one prefix; the
   checker table shrinks by a row and nothing else moves.
2. **The game skill quotes NO ROM addresses** — it states laws and names the
   atlas row (`atlas/ram.md` "Player blocks", not `$FF8400`). The MiSTer
   pair quotes placement constants because they ARE the rule there; for the
   game, the address is the doc's, the law is the skill's. Veto → allow
   addresses, the citation check already forces them into the atlas.
3. **The port skill does not restate CLAUDE.md** — it anchors into it and
   points. A skill that copies the law is a second law that drifts.
4. **Each skill's staleness pass runs in the same session as its
   distillation, as its own commit** (§4) — the MiSTer ruling generalised;
   not re-asked.
5. **`engine_internals.md` counts as a LOG for the game skill** (§3) —
   its measurements are inline and instrument-named; the alternative
   (atlas-only) would refuse most of the subsystem laws. Veto → the pass
   moves each quoted figure into an atlas row first.

---

## 7. THE LEVEL-0 CUT (14z-134, 2026-09-05) — the maintainer's backlog item, executed

The maintainer's direction (2026-09-05, STATE "Decisions pending"): *"look if
there an additional split for both emulation and MiSTer at the highest level.
Namely: are there skills transferable for MiSTer or MAME/FBNeo projects that
are not necessarily CPS-II based."* The question of §1 asked one level up —
**would this still be true if the board were not CPS-2?** — put to every rule
of the three CPS-2 skills (`[CPE-1..42]`, `[CPH-1..30]`, `[MSC-1..73]`, 145
rules). The walk was done with the release run in flight, in a worktree, and
touched no gate the run executes.

### 7.1 The result

| skill | rules | LIFTED to level 0 | STAY at level 1 |
|---|---|---|---|
| `cps2-emulation` `[CPE]` | 42 | **42** → `mame-fbneo-instruments` `[MFI-1..42]` | 0 |
| `cps2-hardware` `[CPH]` | 30 | 4 → `[MFI-43..46]` (`CPH-1`, `-12`, `-13`, `-18`) | 26 |
| `mister-cps2-wide-core` `[MSC]` | 73 | **63** → `mister-jtframe-core` `[MJC-N]` | 10 |

**The finding that matters: `cps2-emulation` had no CPS-2 content.** Every
rule in it — `-debug` timing, watchpoint spaces, tap alignment, focus theft,
hash-before-name resolution, the pinned source builds, the shared EEPROM,
the two-implementation protocol — is a fact about MAME or FBNeo on any board.
The CPS-2-SPECIFIC emulator facts were filed elsewhere all along: the
loaders' shape rules (`[CPH-23]`), the reserved window's per-implementation
reads (`[CPH-25]`), the complemented key-range word (`[MSC-32]`). The skill
is kept as a REDIRECT TABLE rather than deleted, for the reason below.

### 7.2 Three decisions, taken under stated assumptions, open to veto

1. **A lifted rule KEEPS ITS NUMBER: `MFI-N` lifts `CPE-N`, `MJC-N` lifts
   `MSC-N` (gaps where a rule stays); the four CPH rules take `MFI-43..46`.**
   A reader maps the two without a table. Veto → renumber densely; the
   redirect stubs make it mechanical.
2. **Every old ID stays DEFINED in its CPS-2 skill as a one-line redirect,
   and the doc paragraph carries BOTH anchors (`**[CPE-N]** **[MFI-N]**`).**
   Measured before choosing: 352 plain citations of the 145 IDs live outside
   the skill files (gate headers, `ci_emulator.tsv`, docs, both archives).
   Renaming or deleting an ID would break every one — the same reason a
   `14z-N` tag is never renamed ([VSP-162]). A new control in
   `test_checkskills.sh` deletes a redirect and requires the checker to fail
   on the orphaned anchor. Veto → move the anchors and accept the rot.
3. **Level 0 anchors into THIS repository's docs**, like every skill so far;
   the checker's liftability list gains the BOARD tokens (`cps`, `qsound`,
   `jtcps`, `vsavjw`, `wide_en`). A level-0 skill copied to another project
   travels without its checker, exactly as the SMS `romhacking-methodology`
   does. ~~Giving each a self-contained `GUIDE.md` (the SMS shape) is the
   natural next step if one is ever reused and is NOT done here.~~
   **RULED (maintainer, 2026-09-05): all three accepted — *"I am fine with
   them"* — AND a self-contained guide per level-0 skill is REQUIRED, plus a
   self-contained version of the skill itself for use on other projects.
   DONE the same sitting:** `GUIDE.md` beside each level-0 `SKILL.md` is
   GENERATED by `tools/gen_skill_guide.py` — the rule, then the INCIDENT
   that taught it, which is exactly the documentation paragraph the rule is
   anchored to (the anchoring pays for itself: the SMS project hand-wrote its
   guide, here it is a projection of the docs), quoted as its own paragraph,
   list item or table row, windowed to ~1,800 characters around the anchor
   where the paragraph is a run-on. Gate `tests/test_skill_guides.sh`
   (ci_portable, three must-fire controls) keeps it current. The SKILL.md
   intros were made portable (no repo paths as prerequisites; "the
   originating project" instead of names the liftability lint would refuse),
   so **the skill DIRECTORY — `SKILL.md` + `GUIDE.md` — is the self-contained
   unit: copy it into `~/.claude/skills/<name>/` on another machine.** The
   incidents name this project's game, builds and sessions, as the SMS guide
   names Sailor Moon; the rules do not.

**Decisions 1 and 2 were RULED accepted the same day (maintainer,
2026-09-05).**

Wording changed only where a rule named the board, a game figure or a
project measurement: `pal_lut.hex` → "a `$readmemh` file the reference core
carries", the `wide_en` wire → "one wire", `462 → 659` → "a bigger image has
a LONGER transfer", the seed spread → "state the SPREAD and MEDIAN", QSound
→ "a sample player that round-robins channels". Two lifted rules carry the
14z-133b corrections their MSC originals had not caught up with (`[MJC-4]`
the patch series is compared without the git signature; `[MJC-37]` the
scratch clone HEALS rather than `rm -rf`).

### 7.3 The classification, rule by rule

| rule | verdict | where it lives now | why it stays (CPS-2-specific fact) |
|---|---|---|---|
| `[CPE-1]` | LIFTED | `[MFI-1]` | — |
| `[CPE-2]` | LIFTED | `[MFI-2]` | — |
| `[CPE-3]` | LIFTED | `[MFI-3]` | — |
| `[CPE-4]` | LIFTED | `[MFI-4]` | — |
| `[CPE-5]` | LIFTED | `[MFI-5]` | — |
| `[CPE-6]` | LIFTED | `[MFI-6]` | — |
| `[CPE-7]` | LIFTED | `[MFI-7]` | — |
| `[CPE-8]` | LIFTED | `[MFI-8]` | — |
| `[CPE-9]` | LIFTED | `[MFI-9]` | — |
| `[CPE-10]` | LIFTED | `[MFI-10]` | — |
| `[CPE-11]` | LIFTED | `[MFI-11]` | — |
| `[CPE-12]` | LIFTED | `[MFI-12]` | — |
| `[CPE-13]` | LIFTED | `[MFI-13]` | — |
| `[CPE-14]` | LIFTED | `[MFI-14]` | — |
| `[CPE-15]` | LIFTED | `[MFI-15]` | — |
| `[CPE-16]` | LIFTED | `[MFI-16]` | — |
| `[CPE-17]` | LIFTED | `[MFI-17]` | — |
| `[CPE-18]` | LIFTED | `[MFI-18]` | — |
| `[CPE-19]` | LIFTED | `[MFI-19]` | — |
| `[CPE-20]` | LIFTED | `[MFI-20]` | — |
| `[CPE-21]` | LIFTED | `[MFI-21]` | — |
| `[CPE-22]` | LIFTED | `[MFI-22]` | — |
| `[CPE-23]` | LIFTED | `[MFI-23]` | — |
| `[CPE-24]` | LIFTED | `[MFI-24]` | — |
| `[CPE-25]` | LIFTED | `[MFI-25]` | — |
| `[CPE-26]` | LIFTED | `[MFI-26]` | — |
| `[CPE-27]` | LIFTED | `[MFI-27]` | — |
| `[CPE-28]` | LIFTED | `[MFI-28]` | — |
| `[CPE-29]` | LIFTED | `[MFI-29]` | — |
| `[CPE-30]` | LIFTED | `[MFI-30]` | — |
| `[CPE-31]` | LIFTED | `[MFI-31]` | — |
| `[CPE-32]` | LIFTED | `[MFI-32]` | — |
| `[CPE-33]` | LIFTED | `[MFI-33]` | — |
| `[CPE-34]` | LIFTED | `[MFI-34]` | — |
| `[CPE-35]` | LIFTED | `[MFI-35]` | — |
| `[CPE-36]` | LIFTED | `[MFI-36]` | — |
| `[CPE-37]` | LIFTED | `[MFI-37]` | — |
| `[CPE-38]` | LIFTED | `[MFI-38]` | — |
| `[CPE-39]` | LIFTED | `[MFI-39]` | — |
| `[CPE-40]` | LIFTED | `[MFI-40]` | — |
| `[CPE-41]` | LIFTED | `[MFI-41]` | — |
| `[CPE-42]` | LIFTED | `[MFI-42]` | — |
| `[CPH-1]` | LIFTED | `[MFI-43]` | — |
| `[CPH-2]` | STAYS | `[CPH-2]` | the CPS-2 cipher: code encrypted, data reads bypass |
| `[CPH-3]` | STAYS | `[CPH-3]` | CPS-2 cipher: pc-relative vs (An) views |
| `[CPH-4]` | STAYS | `[CPH-4]` | CPS-2 cipher is address-aware |
| `[CPH-5]` | STAYS | `[CPH-5]` | CPS-2 cipher: decode both views |
| `[CPH-6]` | STAYS | `[CPH-6]` | CPS-2 cipher: relocating a pc-rel dispatcher |
| `[CPH-7]` | STAYS | `[CPH-7]` | CPS-2 cipher range inclusive |
| `[CPH-8]` | STAYS | `[CPH-8]` | CPS-2 cipher: raw above the window |
| `[CPH-9]` | STAYS | `[CPH-9]` | CPS-2 gfx simm interleave |
| `[CPH-10]` | STAYS | `[CPH-10]` | CPS-2 tile address composition |
| `[CPH-11]` | STAYS | `[CPH-11]` | CPS-2 OBJ tile codec and screen offset |
| `[CPH-12]` | LIFTED | `[MFI-44]` | — |
| `[CPH-13]` | LIFTED | `[MFI-45]` | — |
| `[CPH-14]` | STAYS | `[CPH-14]` | CPS-2 OBJ terminator bit |
| `[CPH-15]` | STAYS | `[CPH-15]` | CPS-2 Turbo promote |
| `[CPH-16]` | STAYS | `[CPH-16]` | CPS-2 OBJ RAM double buffering |
| `[CPH-17]` | STAYS | `[CPH-17]` | CPS-2 OBJ/tilemap walkers (method worded on CPS-2 structures) |
| `[CPH-18]` | LIFTED | `[MFI-46]` | — |
| `[CPH-19]` | STAYS | `[CPH-19]` | QSound sample window half-bank |
| `[CPH-20]` | STAYS | `[CPH-20]` | QSound byte parity |
| `[CPH-21]` | STAYS | `[CPH-21]` | QSound inclusive end |
| `[CPH-22]` | STAYS | `[CPH-22]` | QSound tight-loop beep |
| `[CPH-23]` | STAYS | `[CPH-23]` | CPS-2 loader shape rules (groups of four, QSound power of two) |
| `[CPH-24]` | STAYS | `[CPH-24]` | the CPS-2 WIDE profile |
| `[CPH-25]` | STAYS | `[CPH-25]` | CPS-2 WIDE reserved window |
| `[CPH-26]` | STAYS | `[CPH-26]` | CPS-2 WIDE extension byte order |
| `[CPH-27]` | STAYS | `[CPH-27]` | CPS-2 WIDE: measure before widening |
| `[CPH-28]` | STAYS | `[CPH-28]` | CPS-2 WIDE: inertness vs functionality |
| `[CPH-29]` | STAYS | `[CPH-29]` | CPS-2 WIDE governance (Rule 1 v2) |
| `[CPH-30]` | STAYS | `[CPH-30]` | CPS-2 WIDE change budget |
| `[MSC-1]` | LIFTED | `[MJC-1]` | — |
| `[MSC-2]` | LIFTED | `[MJC-2]` | — |
| `[MSC-3]` | LIFTED | `[MJC-3]` | — |
| `[MSC-4]` | LIFTED | `[MJC-4]` | — |
| `[MSC-5]` | LIFTED | `[MJC-5]` | — |
| `[MSC-6]` | LIFTED | `[MJC-6]` | — |
| `[MSC-7]` | LIFTED | `[MJC-7]` | — |
| `[MSC-8]` | LIFTED | `[MJC-8]` | — |
| `[MSC-9]` | LIFTED | `[MJC-9]` | — |
| `[MSC-10]` | LIFTED | `[MJC-10]` | — |
| `[MSC-11]` | LIFTED | `[MJC-11]` | — |
| `[MSC-12]` | LIFTED | `[MJC-12]` | — |
| `[MSC-13]` | LIFTED | `[MJC-13]` | — |
| `[MSC-14]` | LIFTED | `[MJC-14]` | — |
| `[MSC-15]` | LIFTED | `[MJC-15]` | — |
| `[MSC-16]` | LIFTED | `[MJC-16]` | — |
| `[MSC-17]` | LIFTED | `[MJC-17]` | — |
| `[MSC-18]` | LIFTED | `[MJC-18]` | — |
| `[MSC-19]` | LIFTED | `[MJC-19]` | — |
| `[MSC-20]` | LIFTED | `[MJC-20]` | — |
| `[MSC-21]` | STAYS | `[MSC-21]` | a CPS-2 tile code IS its SDRAM address (the CPS-2 download scramble) |
| `[MSC-22]` | LIFTED | `[MJC-22]` | — |
| `[MSC-23]` | LIFTED | `[MJC-23]` | — |
| `[MSC-24]` | LIFTED | `[MJC-24]` | — |
| `[MSC-25]` | STAYS | `[MSC-25]` | the CPS object pipeline skips on all-ones fetches |
| `[MSC-26]` | LIFTED | `[MJC-26]` | — |
| `[MSC-27]` | STAYS | `[MSC-27]` | the CPS-2 core's format caps |
| `[MSC-28]` | STAYS | `[MSC-28]` | the CPS-2 Turbo promote after the terminator test |
| `[MSC-29]` | LIFTED | `[MJC-29]` | — |
| `[MSC-30]` | LIFTED | `[MJC-30]` | — |
| `[MSC-31]` | LIFTED | `[MJC-31]` | — |
| `[MSC-32]` | STAYS | `[MSC-32]` | the CPS-2 key's complemented range word |
| `[MSC-33]` | LIFTED | `[MJC-33]` | — |
| `[MSC-34]` | STAYS | `[MSC-34]` | data-vs-code above the CPS-2 decryption window |
| `[MSC-35]` | STAYS | `[MSC-35]` | Rule 1 v2's MiSTer form (the CPS-2 WIDE governance) |
| `[MSC-36]` | LIFTED | `[MJC-36]` | — |
| `[MSC-37]` | LIFTED | `[MJC-37]` | — |
| `[MSC-38]` | STAYS | `[MSC-38]` | CPS-2 latches its key from the download (-load every run) |
| `[MSC-39]` | LIFTED | `[MJC-39]` | — |
| `[MSC-40]` | LIFTED | `[MJC-40]` | — |
| `[MSC-41]` | LIFTED | `[MJC-41]` | — |
| `[MSC-42]` | LIFTED | `[MJC-42]` | — |
| `[MSC-43]` | LIFTED | `[MJC-43]` | — |
| `[MSC-44]` | LIFTED | `[MJC-44]` | — |
| `[MSC-45]` | LIFTED | `[MJC-45]` | — |
| `[MSC-46]` | LIFTED | `[MJC-46]` | — |
| `[MSC-47]` | LIFTED | `[MJC-47]` | — |
| `[MSC-48]` | LIFTED | `[MJC-48]` | — |
| `[MSC-49]` | LIFTED | `[MJC-49]` | — |
| `[MSC-50]` | LIFTED | `[MJC-50]` | — |
| `[MSC-51]` | LIFTED | `[MJC-51]` | — |
| `[MSC-52]` | LIFTED | `[MJC-52]` | — |
| `[MSC-53]` | LIFTED | `[MJC-53]` | — |
| `[MSC-54]` | LIFTED | `[MJC-54]` | — |
| `[MSC-55]` | LIFTED | `[MJC-55]` | — |
| `[MSC-56]` | LIFTED | `[MJC-56]` | — |
| `[MSC-57]` | LIFTED | `[MJC-57]` | — |
| `[MSC-58]` | LIFTED | `[MJC-58]` | — |
| `[MSC-59]` | LIFTED | `[MJC-59]` | — |
| `[MSC-60]` | LIFTED | `[MJC-60]` | — |
| `[MSC-61]` | LIFTED | `[MJC-61]` | — |
| `[MSC-62]` | LIFTED | `[MJC-62]` | — |
| `[MSC-63]` | LIFTED | `[MJC-63]` | — |
| `[MSC-64]` | LIFTED | `[MJC-64]` | — |
| `[MSC-65]` | LIFTED | `[MJC-65]` | — |
| `[MSC-66]` | LIFTED | `[MJC-66]` | — |
| `[MSC-67]` | LIFTED | `[MJC-67]` | — |
| `[MSC-68]` | LIFTED | `[MJC-68]` | — |
| `[MSC-69]` | LIFTED | `[MJC-69]` | — |
| `[MSC-70]` | STAYS | `[MSC-70]` | this core's unmeasured pixels/audio (project state) |
| `[MSC-71]` | STAYS | `[MSC-71]` | real CPS-2 silicon's decryption window is inferred |
| `[MSC-72]` | LIFTED | `[MJC-72]` | — |
| `[MSC-73]` | LIFTED | `[MJC-73]` | — |
