# STATE — living progress log

## Session 14z-115 CLOSE — ritual complete. **THE SELECT-WHEEL SEPARATION FROZEN
## (donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged),
## tagged at `b30611a`, strict 111/0/0/0 on that tree, guard corpus 340/340 — NOT
## field-tested, NOT pushed; the maintainer's own mockup is the next cut.**

| | |
|---|---|
| opened with | the 14z-114 close pushed (`864cf79`); #113 parked by the maintainer; "time to tackle some cosmetics" |
| delivered | the E2 wheel (positions by the maintainer's pixel offsets, rings tuned by eye over four probe builds, one authored outline sprite per cell, no palette change) -> approved on MAME snapshots -> THE FREEZE (`7384f19` + `b30611a`), release `release/merged-m11/`, MiSTer tail (fork `202fc3e6`, patch 0025, pin, bundle `../mister_fieldtest_14z115/`), the re-point sweep, the N-2 build-dir sweep, four documents' ground truth moved |
| green at close | `run_all_static --strict` **PASS 111 / SKIP 0 / FAIL 0 / MISSING 0** on the tagged tree `b30611a`; suites: donovan-m15 / huitzil-m22 / pyron-m16 full verify — every replay PASS except the two `112_*` that had NO expectation since 14z-112 (now `.skip` / frozen `.sha1`); `audit_merged_legacy` 47/47 (both legs on the new solos); `audit_guard_corpus` 340/340; `audit_roster_pairings` 111/111; `audit_legacy_pairings` PASS; `test_fbneo_legacy_oracle` PASS ×2 after the ruled refit; dualtrack, m3a, inp corpus, every wheel/MiSTer/release gate — the two rows above |
| push | **NOT PUSHED** — main is ahead of origin by the freeze commits and this close; the fork `202fc3e6` is local; tags `freeze/{donovan-m15,huitzil-m22,pyron-m16,merged-m11}` local. Push at the maintainer's word |
| not done, by ruling or by absence | field test of M9 (the next board session); the maintainer's 1:1 mockup (replaces the outline tiles through the same knobs); **the OPEN INSTRUMENT QUESTION** (two FBNeo run families diverging from frame 72 — see the session entry); #113 parked; `m3b_merged15` defect-mode reference and the other 14z-113 housekeeping unchanged |
| **EMULATION VERDICT (maintainer, 2026-08-28, after the push)** | "everything works as intended on emulation, both MAME and FBNeo, no regression to report and the new wheel is a big visual update already" — MiSTer test next. |
| next | whatever the maintainer brings: the mockup, the board verdict on M9, or a veto. Load `vampire-saved-port` first; the wheel's knobs and the freeze's attribution are in patch_notes 14z-115 |

**Ledger rollover:** the 14z-112 group (two records) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-113 / 14z-114 / 14z-115.


## Session 14z-115 (2026-08-28) — **THE SELECT-WHEEL SEPARATION ("E2"), maintainer-directed
## and approved on MAME snapshots: the three tenant medallions repositioned, their hover rings
## re-tuned by eye, a 1 px black ring authored around each — FROZEN as donovan-m15 /
## huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged. NOT yet field-tested.**

| | |
|---|---|
| opened with | the 14z-114 close pushed (`864cf79`); the maintainer: #113 stays parked; "time to tackle some cosmetics" — the Vampire Collection wheel as the reference (`../images/P1-Phobos_P2-donovan.JPG`): ≥1 px black between each new medallion and anything else, the purple border, the blue field. "Only touch the visuals; show me results early." |
| what the captures showed | Our snapshot vs vanilla vs the reference (real tiles rendered from the ROM, not screenshot cut-outs): the blue field, purple border and black gaps are the venue TILEMAP; the medallions are sprites with transparent corners. Our three cells were bare vs2 3x2 sprites over the throne art on the SAME ROW as the vanilla "?" cell 0x0B, overlapping it and each other (live OBJ list: "?" 175-207 x 134-166 screen, tenants centred (150,152)/(180,160)/(208,152); OBJ = screen + (64,16)). The "?" cannot move — its ring base is legacy-visible. |
| the proposals, and the maintainer's own answer | B (per-cell blue discs + purple ring + black ring) and C (one continuous field, the Collection look) both "look much worse than current". The maintainer's direction instead: move all three 4 px down, Phobos 1 px left, Donovan 1 px right — then E2: Phobos/Donovan 1 px up, Pyron 3 px down, plus a 1 px black outline. **Positions locked: sprite corners Phobos (137,148), Pyron (168,160), Donovan (197,148) screen.** "The medallions' positions are great." |
| the rings, measured not mocked | Built a probe merged image and snapshotted the cursor on each cell (replays 37/40/36 at f1500). First build: the rings moved UP — **the ring-base table's Y runs opposite to the cell position** (a +3 base y = 3 px up; measured on the live OBJ list). Fixed; then the maintainer tuned by eye over four builds: Phobos ring +4, +3, +1 = **+8 x**; Pyron +2, +1 = **+3 x**; Donovan as it was. Bases: (165,77) / (191,65) / (217,77). The "1" P1 marker clips slightly at Phobos — ruled fine (ring and marker cycle yellow/red anyway). |
| the outline mechanism | One authored 4x3-tile ring sprite per cell: the medallion's own alpha placed at (8,8) in a 64x48 canvas, dilated 1 px, minus the art → pen 0; rendered by `build_gfx_donovan.py` from the same vs2 tiles the medallions come from (`wheel_bank5.json` `"outline"`), placed at group C **`0x1F800 + 4k`** (the first guess `0x1FE50` collided with effect art at `0x1FE61` and the build REFUSED it — same-source-or-fail doing its job; the free block was read off the merged-m10 `gfx_written.json` ledgers). Palette: **row 0x19 pen 0 = (1,1,1), no palette content change** — deliberate: no vanilla row carries blue+purple+black together (row 0x09 came closest: exact field blue, near-black, mauve border), and the 14z-88 lesson makes any row edit a measured cycle risk. Record: entries `[outline, medallion]` per cell, in cell order, after the 18 vanilla entries and before the 2 glyphs — **later entries draw on top** (measured: Donovan over Pyron over Phobos over "?"), so a front cell's ring covers the cell behind it and hides under its own art. Generator knobs `cell_outline` / `outline_base` / `outline_pal` on `[[select_wheel]]` in all three manifests; `tools/check_wheel_bank5.py` taught the interleave (it failed honestly on the first run: "cell 0x11 pal 0x19 != 0x1a" was the ring entry). |
| approved | the maintainer, on `images/wheel_mockups/e2_outlines_x4.png` (real MAME snapshots of the probe): "approved!" |
| THE FREEZE | `version_text` M8 → M9. Builds: donovan-m15 `38a4becb` (`build/don_m15`, 332 ops), huitzil-m22 `7bb36d0c` (`build/hui49`, 366), pyron-m16 `7177229a` (`build/pyron33`, 303), merged-m11 `dea2c918` (`build/m3b_merged18`, 819 ops — count unchanged, the data ops grew), stock twin `build/m5_stock10` = `d29fd062` **UNCHANGED** (profile-gated, measured by rebuild). Registry rows +3; expectation sets carried-renamed m14→m15 / m21→m22 / m15→m16. Members moved: PROGRAM `vm3j.03d/04d/07b/10b`, `vsw.41/42`; GROUP C `vsw.31m/33m/35m/37m`; QSound/Z80 untouched. |
| gates at freeze (all PASS unless noted) | wheel_bank5 · select_wheel · tenant_select_records (host-pick window 889-2415 held) · version_string (M9 pixel-exact) · oboro_select · jtcores_twin · mister_mra_map (on merged18) · mra_parts · release_roundtrip (merged-m11) · pointer_flow (re-frozen WITH attribution: the two STRONG win_pal bases +0x20 with the grown record, WEAK data:long −1..−2 per build) · pcrel_escapes + escape_triage (inventories IDENTICAL, re-pointed) · tenant_loop · m3a (EXPECT_WIDE/HUI/PYR/MERGED + MANI_WIDE/HUI/PYR/MERGED re-pinned, attributed per member; stock manifest UNCHANGED) · inp corpus 6/6 on merged18 · audit_merged_legacy **47/47** (leg b on the new solos re-run at close — see below) |
| more gates, run after the row above was written | `test_dualtrack` PASS (onsets frozen, held) · `audit_merged_legacy` re-run with leg (b) on the NEW solos: PASS 47/47 · `test_m3a_reproducible` PASS after re-pin · `test_fbneo_replay_determinism` PASS · **`test_fbneo_legacy_oracle` RED then REFIT (the 14z-110b class):** `05_timeout_idle` f8300 read the P1 anim-node timer `+0x8420` (0x07 vs 0x00) FBNeo-only, MAME's masked class EXACT at the same frame; don_m14 PASSES the same instant, so it is ours — three more OBJ entries per select frame re-roll FBNeo's phase again. Ruled response applied: a ~25-instant scan on don_m15 (both legs, masked diff classified) found 600/2250/2800/3900 still clean and 8300 dirty → the fifth instant moves to **9500**; inventory unchanged; PASS ×2. · `audit_roster_pairings` PASS 111/111 on merged18 — after **`bases.tsv` was found ROTTED**: last re-derived at 14z-110, never at 14z-111 when the AI-script roots shifted the tenants' ext regions (+0x10D0 H / +0x1ED0 P); this freeze adds +0x20; re-derived from merged18's own table `PRG:0x0BD97A` (Phobos `0x45a6b0`, Pyron `0x4ae85c`, Donovan unchanged) · `audit_legacy_pairings`: `112_don_pod_vsav2` (the #112 rig's vsav2 half) had NO expectation on any set — `.skip` on the three current sets (targets vsav2, like `17_don_oracle_vsav2`); `112_don_pod_merged` (TENANT) frozen `.sha1` · `test_mister_page` / `audit_mister_map_fit`: bank-5 non-blank count 6,245 → **6,271** (+26 live outline-tile codes in bucket 62; extent `0xFE41` unchanged) re-frozen in the tool, the fit gate, `mister_core.md` and `mister_map.md`, old figures kept in the log; the three-sizes ASCII figure re-pasted · `test_jtcores_twin` / `test_mister_mra_map` / `test_mra_parts` / `test_release_roundtrip` (merged-m11) PASS · build-dir policy applied (`build_dir_triage.md`, 14z-115 sweep) |
| **OPEN INSTRUMENT QUESTION, for the maintainer** | During the FBNeo clean-frame scan, runs of the SAME vanilla leg (same binary, same args, fresh sandboxes) fell into TWO bit-identical families that diverge from **frame 72** (the EEPROM/boot instant of the 14z-91 gotcha): every run in a 12-minute window (16:00-16:12) vs every run after 16:13 (six runs over 40 min, incl. the gate's own two, all identical). Emulator load logs identical, `audit_roms` clean, ROMs' mtimes untouched, `test_fbneo_replay_determinism` PASS (on `02`), `emu/fbneo/fbneo` mtime 16:35:59 by an unidentified writer (no gate I ran rebuilds it; the oracle gate only asserts it exists). The refit was measured against the later, stable behaviour (which the gate reproduces). Not root-caused; recorded so it is not re-discovered as "FBNeo is flaky". A cheap first check next session: `shasum emu/fbneo/fbneo` vs a fresh `tools/setup_fbneo.sh` build. |
| after the freeze commit (`7384f19`) | strict: 109 PASS / 2 FAIL — `test_tenant_row_owner` (reads the then-uncommitted generator diff as an escaped perturbation; PASS on the committed tree) and `test_escape_triage` (`tools/triage_pcrel_escapes.py` keys its solos by BARE name — `"hui48"`, no `build/` — so the path sweep missed it and the gate read merged18's placements against the OLD extracts; re-pointed, then the verdict set re-frozen: all 25 verdicts IDENTICAL modulo merged landing addresses, huitzil/pyron +0x20, donovan 0 — the 14z-111 class). `audit_guard_corpus` **PASS 340/340** on merged18. Tags cut at the fix commit. |
| paid for on the way | zsh word-split (`for f in $frames` iterates once) built a malformed `-hdump` spec and the FBNeo harness wrote NO dumps with rc 0 — twice; recorded in `project/gotchas.md` beside the `=cmd` sibling. `mk_mister_page.py --help` wrote a 63 KB file named `--help` into the repo root (the tool takes a positional out path; removed). |
| suites — the moved `.sha1`s, ATTRIBUTED | donovan-m15: 12 self-frozen `.sha1` moved (103/108/109/110, 36/37/44/58/61/62/64/92 — tenant matches and select rigs), huitzil-m22 13, pyron-m16 14; every masked legacy class PASSED. Attribution by DUMPS diff (don_m14 vs don_m15): replay 103 at 890 → `$FF06CD` + `$FF06D1` (OBJ-builder execution position, the ratified class); 1200 → `$FF06D1` + dead stack `$FF7Fxx`; 2412 → those + `$FF06B7/B9` (the builder's record cursor, one entry further because of the interleave) + **`$FFBA11/15` = the P1 ring object's position — the change itself**; round-2 start 5800 → `$FF06CC/CD` only. Replay 109 at 890 adds the QSound latch phase `$FF043C`; at 2412 both rings (`$FFBA`/`$FFBC` +0x11/+0x15); at 3200 ZERO. No gameplay field moved. Re-frozen per set with `SUITE_ONLY` + `--freeze`; full verify runs recorded at close. |
| release / MiSTer tail | `release/merged-m11/{fbneo,mame,mister}/` (M9; round-trip PASS; bitstream 18269 hash-verified in). The tail is NOT empty this time (group C moved): fork commit **`202fc3e6`** (catalogue), patch **0025**, pin bumped, `test_jtcores_twin` PASS; board bundle **`../mister_fieldtest_14z115/`** (`_Arcade/` WIDE + `[STOCK CONTROL]` MRAs, `games/mame/` zips, `.rbf` unchanged) — **THE TELL IS M9.** Fork NOT pushed (the maintainer's word). |
| re-point sweep | 86 files (gate defaults + manifests) `m3b_merged17`→`m3b_merged18`, `don_m14`→`don_m15`, `hui48`→`hui49`, `pyron32`→`pyron33`, `m5_stock9`→`m5_stock10`, each line stamped `re-pointed 14z-115 <- <old>`; running scripts were excluded from the sed and re-pointed after they finished (VSP-110). |
| docs | patch_notes 14z-115 (byte detail), patch_index (rows + 14z-115 additions + patch 0025), `select_screen.md` "The appended cells' PLACEMENT and OUTLINES", HANDOFF (playtest block, current-builds header, registry row), `mister_core.md` / `mister_map.md` / `platform/mister.md` / `mister_scope.md` ground truth (pin, 25 commits, merged-m11), `hardening_register.md` guard currency. The maintainer's mockups + our snapshots live in `../images/wheel_mockups/` (outside the repo). |
| open | **the maintainer is drawing a "perfect" mockup** at 1:1 over the E2 frames (`e2_outlines_build_1x.png` etc.); it replaces the outline tiles through the same knobs. #113 stays parked. Field test of M9 pending. |


## Session 14z-114 CLOSE — ritual complete. **ALL SIX SKILLS DISTILLED AND
## LOCKED TO THE DOCS in one session: the MiSTer pair, the CPS-2 pair, the game
## skill and the port skill — 425 rules, every one anchored in the paragraph it
## distils, every number in a log; four staleness passes run first, each its
## own commit.**

| | |
|---|---|
| opened with | the 14z-113 orientation; nothing red; main == origin/main at `09e4961` |
| delivered | the retraction (merged-m10 registry row) -> the MiSTer pair + checker (`bb8ecde`, PUSHED at the maintainer's word) -> the plan `skills_scope.md` -> A+B staleness (`6acfeb6`) -> `cps2-hardware` + `cps2-emulation` -> C staleness (`0291fbf`) -> `vampire-savior-engine` -> D staleness (`7c688cf`) -> `vampire-saved-port` (`4cc4af7`). Six skills: `[MSC-1..73]`, `[MSV-1..36]`, `[CPH-1..30]`, `[CPE-1..42]`, `[VSE-1..83]`, `[VSP-1..161]` |
| green at close | `tests/test_checkskills.sh` PASS (425 rules, eight controls fire); `run_all_static --tier portable` **54/0/0/0**; `ROMDIR=... run_all_static --strict` **PASS 111 / SKIP 0 / FAIL 0 / MISSING 0** on the tree as committed at `4cc4af7` (the run's tree-dirtiness note names this close's own uncommitted rollover edit to STATE_HISTORY, nothing else) |
| push | **NOT PUSHED past `bb8ecde`** — six commits local (`6c7ccb6` plan, `6acfeb6`, `276c010`, `0291fbf`, `7c688cf`, `4cc4af7`) plus this close; push at the maintainer's word (standing rule) |
| not done, by ruling or by absence | **#113 stays OPEN** (camera evidence in progress — nothing re-derived, nothing closed). Two D staleness items left flagged UNVERIFIED rather than edited (skills_scope §4 row D). The five skill decisions remain OPEN TO VETO. The re-filing candidates (fourteen emulator-fact entries in `project/gotchas.md`, the 14z-90 onset entry in `game/gotchas.md`) are the maintainer's call. Housekeeping still deferred from 14z-113 (`build/m3b_merged15` defect-mode reference; STOCK CONTROL once-per-`.rbf`; the cosmetic backlog) |
| next | nothing scheduled by this session. The opener is whatever the maintainer brings: #113's camera verdict, a veto on a skill decision, or the deferred housekeeping. **Every future session loads the relevant skill before the work** — that is what they are for |

**Ledger rollover:** the 14z-111 group (two records) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-112 / 14z-113 / 14z-114.


## Session 14z-114 (2026-08-28) — **THE MiSTer SKILLS DISTILLED, WITH THEIR
## CHECKER: two skill packages (level 1 `[MSC-1..73]`, level 2 `[MSV-1..36]`),
## every rule ID-anchored in the doc paragraph it distils; the log gained the
## 14z-108/109 measurements it never had; the field test got an in-tree carrier.**

| | |
|---|---|
| opened with | the 14z-113 orientation; nothing red; main == origin/main at `09e4961` |
| first | a retraction: the merged-m10 HANDOFF registry row still said the `.rbf` was "on the synthesis box" and the release format "the open item" — both retired by `09e4961` the same day. Fixed in place (14z-114 named), STATE freeze row + NEXT_SESSION history block marked as-written-then-superseded, re-grep empty (`3dcd5cd`) |
| the design question, decided first | **the checker's shape.** Not the SMS two-renditions pattern (a second hand-written human doc per skill would be more prose to drift): **the docs ARE the human rendition.** Each rule is anchored `**[MSC-N]**` at the paragraph it distils; `tools/checkskills.py` asserts (1) the ID-lock BOTH ways — a deleted paragraph or an unanchored rule fails, one anchor per rule; (2) the `mister_scope.md` §1 liftability test on level 1 (no `vsav`, tenant, ceiling, fingerprint, build dir — fixed token list); (3) **every number a skill quotes appears in a LOG** (`platform/mister.md`, `mister_map.md`, `mister_fit.md`, `mister_field.md`, `release_format.md`, the gotchas, `BITSTREAM.txt`) and never only in the synthesis — the synthesis's own staleness rule, mechanised. Extractors self-tested on synthetic content every run; gate `tests/test_checkskills.sh` (ci_portable) adds four must-fire controls on a perturbed copy of the tree |
| the skills | `.claude/skills/mister-cps2-wide-core/SKILL.md` — level 1, 73 rules, sections 1.1-1.7 per the scope rows + 1.8 "what is NOT known" (pixels/audio never measured, the decryption window inferred, the 128 MB CS polarity inferred, timing a seed lottery); `.claude/skills/mister-vampire-saved/SKILL.md` — level 2, 36 rules, 2.1-2.5. TWO packages rather than twelve: one SKILL.md per level with one section per scope row (a skill loads whole; the split the maintainer confirmed is the ROWS, not the file count). Both load in this session already. Cross-references to `[RH-NN]` rather than restating the general discipline |
| what the checker found on its first real run (the point of building it first) | **every 14z-108/109 hardware-adjacent figure was missing from the LOG** — the tenant anchor 2886/3546/660, bank-1 load (15,496 / 12.5%), the QSound extension fetch (210,180 / bank `0x83`), the OBJ-list oracle (`0x4b0c4-0x4ecda`, 81 frames), the synthesis fit (+206 ALMs / 41,910) — they lived only in `mister_core.md` §12, HANDOFF and STATE. `platform/mister.md` now carries them ("THE 14z-108/109 MEASUREMENTS, RECORDED IN THE LOG"), each naming its gate |
| the doc hole the scope document had flagged (§4, §5.4) | skill 2.5 (field test + triage) had NO live carrier — narrated only in NEXT_SESSION history, STATE_HISTORY 14z-109 and the out-of-tree `FIELD_TRIAGE.txt`. **`docs/project/mister_field.md`** written: what hardware answers, the bundle and its STOCK CONTROL, the stopwatch figures (26.5 s loop at 59.6374 Hz), the symptom table, field-reports-are-recordings, where the verdicts are |
| anchors | 109 markers inserted across `platform/mister.md`, `mister_core.md`, `mister_map.md`, `mister_fit.md`, `mister_field.md`, `cps2_wide.md`, `release_format.md`, both gotchas, HANDOFF — each needle asserted UNIQUE before any edit (109/109 first pass). `mk_mister_page --check` still re-derives all 17 figures through them |
| routing | `docs/README.md` (routing row + `mister_field.md` entry + scope row status), HANDOFF (MiSTer section lead + gate row), CLAUDE.md §5 taxonomy (skills bullet + the anchored-paragraph rule), `mister_scope.md` STATUS header, `tests/ci_portable.txt` |
| green | `tests/test_checkskills.sh` PASS (109 rules, four controls fire); `run_all_static --tier portable` **PASS 54 / SKIP 0 / FAIL 0 / MISSING 0**; `ROMDIR=... run_all_static --strict` **PASS 111 / SKIP 0 / FAIL 0 / MISSING 0** (110 + `test_checkskills`) on the tree as committed |
| **then, the same session: THE PLAN AND PAIR A+B** | `docs/project/skills_scope.md` (four remaining skills, the checker extension, the staleness pass each needs, sequencing A+B -> C -> D, five decisions under stated assumptions) -> **the A+B staleness pass** (six status claims in `cps2_wide.md`/HANDOFF/the `-video none` gotcha fixed in place, 14 re-filing candidates listed) -> **`cps2-hardware` `[CPH-1..30]` and `cps2-emulation` `[CPE-1..42]`** distilled from every non-MiSTer platform source (platform gotchas 9-1027 + 1834-1892, all of `cps2_wide.md`, HANDOFF B5/migration/troubleshooting, the emulator-fact project gotchas), 72 anchors (72/72 needles unique first pass); the checker made TABLE-DRIVEN per prefix (path, anchor docs, log set, forbidden tokens) with **cross-reference resolution** (a `[PFX-N]` naming an undefined rule fails); gate: six controls. `checkskills` **ALL PASS 181 rules / 4 skills**; portable tier PASS 54/0/0/0 after the pair |
| **then C, THE GAME SKILL** | every game source read in full (`engine_internals.md` 3,733 lines, `game/gotchas.md`, all seven atlas files) -> **the C staleness pass, S-C1..S-C12** (the "NOT YET SYNTHESISED" header above its own CLEARED note; the M2b slot-0x0F placement and its "remaining" lists; the select-screen "next session" plan; the 214P music bug "must be re-diagnosed" (root-caused 14z-52) and "maintainer decision material" (WIDE QSound + M5); the Dark Force header/status "palette OPEN" (fixed 14z-84 `df_gold_variant_id` — verified in `huitzil.toml`); capture-pose "MEASURED FEASIBLE" and win-screen "KNOWN-OPEN #105" (both shipped 14z-99, verified in patch_notes); 14z-70e "explosion believed CORRECT" (retracted by 70f); the atlas README's phantom per-romset files; `ram.md`'s three-freezes-old set names; the PS1 "do not build from these yet"; and `game/gotchas.md`'s TITLE LINE with a whole entry spliced into it) -> **`vampire-savior-engine` `[VSE-1..83]`** (C.1 the three-sibling method, C.2 the bank and id space, C.3 pools/dispatch, C.4 anim/drawer/gfx, C.5 combat, C.6 select/venue, C.7 sound, C.8 modes/exceptions, C.9 the rigs the game sabotages), **no ROM addresses** (decision 2), 83 anchors (83/83 unique after one needle repoint), checker row + a seventh control (a port token in the game skill). `checkskills` **ALL PASS 264 rules / 5 skills**; portable tier PASS 54/0/0/0. Two items left flagged UNVERIFIED rather than edited (the M2b sprite-palette writer note; the attract-demo roster TODO) |
| **then D, THE PORT SKILL** | **the D staleness pass first, its own commit `7c688cf` (S-D1..S-D6):** HANDOFF's playtest block and "Current WIDE builds" header had stopped at the 14z-105 batch (merged-m6, "M6", don_m11/hui47/pyron31) while four freezes sat in the registry -> merged-m10 / M8 / don_m14-hui48-pyron32; `patch_index.md`'s four romset rows CURRENT at the 14z-102 generation (re-registered: stock twin `d29fd062`, donovan-m14 `772d8052`, huitzil-m21 `cd362ca4`, pyron-m15 `c403a283`; the hui9 gfx-rung row asserting a pinned `hui6` deleted two sweeps ago -> HISTORY) and the FBNeo 0002 row's "ONE widened condition" (two gated blocks); `hardening_register.md` #107/#109 both still "-> the next window" (SHIPPED 14z-102) and guard currency at hui45/pyron29/don_m9; `build_dir_triage.md` "must join the re-point sweep" (done every freeze since); `project/gotchas.md` "the GENERATOR side is still open" (post-increment reader relocated since 14z-69); `tenant_manifest.md` "refused until M3 Phase 3" (Phase 3 is `build_merged.sh`). Two left flagged UNVERIFIED (skills_scope §4 row D). **Then the skill**: `.claude/skills/vampire-saved-port/SKILL.md`, 161 rules, D.1 the law BY CITATION (CLAUDE.md §1-§5 + the two standing STATE sections, 33+3 anchors — decision 3 held: nothing restated), D.2 oracles and frozen classes, D.3 extraction/reconciliation/generation, D.3b sprite lists, D.4 freezes/registry/build dirs/releases/suite, D.5 rigs and probes, D.6 attribution. 161 needles asserted unique before insertion (161/161 first pass). **Checker**: VSP row with the §3 STATE-section restriction (a `**[VSP-N]**` anywhere in STATE.md outside "STANDING PRINCIPLE" / "THE DEADNESS REGISTER" fails, named); gate gains the eighth control and nine files. **Found on the way and fixed:** the `**[CPE-3]**` and `**[CPE-19]**` anchors had been inserted BEFORE their `## ` headers in `project/gotchas.md`, breaking both headings — moved inside. Routing: README row + plan entry, CLAUDE.md skills bullet, HANDOFF gate row, plan STATUS. `checkskills` **ALL PASS 425 rules / 6 skills**; gate PASS eight controls; portable **54/0/0/0**. |
| push | committed to main; pushed at the maintainer's word (standing rule) |

## Session 14z-113 CLOSE — ritual complete. **THE MiSTer SCOPE DOCUMENT
## WRITTEN AND ITS THREE DECISIONS RULED; THE S1-S20 STALENESS PASS RUN;
## BUNDLE 14z112 FIELD-VERIFIED; merged-m10 FROZEN; THE RELEASE FORMAT RULED
## AND SHIPPED (one self-sufficient directory per platform).**

| | |
|---|---|
| opened with | the 14z-112 orientation; nothing red; main == origin/main at `1a0d7bb` |
| delivered | `docs/project/mister_scope.md` (split, boundaries, doc map, S1-S20) -> rulings (split confirmed; pass mandatory, after the board; `.rbf` + MRAs in-tree) -> board results ("excellent, no regression", stock coexists, STOCK CONTROL boots) -> the S1-S20 pass (one commit, re-grep empty, 110/0/0) -> **freeze merged-m10** (`build/m3b_merged17`, M8 + fingerprint `32007911` unchanged, tag pushed, 54 defaults re-pointed, MiSTer tail empty by construction) -> **the release format ruled** (self-sufficient per platform; patch set copied into each; driver patch + recipe, no binaries; every version releases every platform) and **shipped as `release/merged-m10/{fbneo,mame,mister}/`** with `tools/package_release_platforms.py`, `docs/project/release_format.md` and `test_release_roundtrip.sh` §4 (layout + no cross-platform leakage + must-fire) |
| green at close | `run_all_static --strict` **PASS 110 / SKIP 0 / FAIL 0 / MISSING 0** (run four times this session, last on the tree as committed); inp corpus 6/6, version string, render-content on merged17; ROM audit 76/76 |
| push | main == origin/main; `freeze/merged-m10` on origin; no local-only tags; fork current at `63496069` (`git ls-remote`, all three) |
| not done, by ruling or by absence | **#113 OPEN** — the maintainer is producing CAMERA evidence that hardware may disagree with the emulator finding; nothing re-derived, nothing closed. **The `.rbf` is not in the tree** — it was never on this machine; its home is `release/merged-m10/mister/jtcps2w.rbf` (hash in `BITSTREAM.txt`), the maintainer will drop it in. `build/m3b_merged15` NOT deleted (referenced by `test_inp_crash_merged_m8_01` defect mode). STOCK CONTROL: kept, re-scoped to once-per-new-`.rbf` (recommendation; the maintainer asked, did not rule) |
| next | **THE MiSTer SKILLS** — distilled in a FRESH session from the corrected docs per `mister_scope.md` (six core + one shared + five VS-specific), each shipping with its checker (the SMS `checkskills.py` pattern) |

**Post-close addendum (same day, 2026-08-28) — THE BITSTREAM IS IN THE TREE,
AS A BUILD RESOURCE.** The maintainer dropped `jtcps2w.rbf` in; sha256
verified `46fc74af…f66f` (3,111,944 B) against the record. Then the
maintainer's design point, adopted: the bitstream is a COMMON BUILD RESOURCE
(rebuildable with the right environment) that every release includes, never
copied from a previous release. So it lives once at
**`release/bitstreams/18269/{jtcps2w.rbf, BITSTREAM.txt}`** with
`release/bitstreams/CURRENT` = `18269`; `tools/package_release_platforms.py`
resolves CURRENT (or `--bitstream DIR`), verifies the file against the
record's sha256 and REFUSES on mismatch (exercised: a tampered record is
refused), then copies both into `mister/`. `release/merged-m10/mister/` was
regenerated from it (28 files; gate §4 now also checks the `.rbf` is present,
its hash equals the record, and the record is byte-identical to the
canonical one). `docs/project/release_format.md` carries the resource.

**Ledger rollover:** the 14z-110b group (three records) moved verbatim to
STATE_HISTORY.md; STATE holds 14z-111 / 14z-112 / 14z-113.


## Session 14z-113 (2026-08-28) — **THE MiSTer SCOPE DOCUMENT IS WRITTEN
## (`docs/project/mister_scope.md`) — scope only, not the skills, as agreed.**

| | |
|---|---|
| opened with | the 14z-112 orientation: nothing red, two hardware answers pending (#113 hand check, bundle 14z112), the scope document queued. main == origin/main at `1a0d7bb` (`git ls-remote`) |
| the deliverable | `docs/project/mister_scope.md` — the two-level split (**level 1 CPS-II/WIDE core**: separate-core mechanism, the runtime profile bit, SDRAM tiers/slots/placement RULES, the five format caps + the nine gated sites, the simulation lane + instruments, synthesis/release, MRA mechanics; **level 2 VS-specific**: the roster's demand, the placement NUMBERS, catalogue/MRA/bundle generation incl. the freeze's MiSTer tail, the WIDE oracles, field test + triage), each with boundary / sources by section / gates; the doc dependency map; five places the boundary is not clean; the **known-stale inventory S1-S20** with file:line and the session that moved each |
| method | all ~5,000 lines of the MiSTer sources READ (`platform/mister.md`, `mister_map.md`, `mister_core.md`, `cps2_wide.md`, `mister_fit.md`, the HANDOFF section, the tool headers, the 14z112 bundle README) — none summarised from memory; every "true now" checked against git/tree, not prose |
| the staleness that matters | (S1/S3/S12) `mister_core.md` still says pin `dd242a65` + fifteen commits, romset merged13, and "HARDWARE: never"; `mister_map.md`'s header still says no tenant ever fought and nothing ran on hardware; (S15) `patch_index.md` registers 7 of 24 jtcores patches, one marked "LOCAL-ONLY (not pushed)"; (S8) a 14z-112 correction was spliced mid-sentence in `mister.md:1593`; (S18) `release/mister/jtcps2w.rbf` is cited by three docs and tracked by none; (S20) every HANDOFF MiSTer example names `build/m3b_merged13`, which the 14z-112 sweep DELETED. The `mister_mra.sh` HEADER correction NEXT_SESSION asked to verify IS in place (S16 is its usage text only). **All numbers agree across synthesis and logs; every disagreement is STATUS** |
| verified clean | the nine gated sites (three copies agree), the placement offsets (three copies), the anchors, the `.rom` arithmetic, the release policy; `audit_mister_map_fit.sh` re-derives the extents from `m3b_merged16` every run, so `mister_fit.md`'s ceilings hold on the current freeze (only its `0x4D10F3` high-water mark is un-frozen and merged-m6's) |
| ~~not done, by design~~ **THE S1-S20 PASS RAN (same session, after the board results, per ruling (2))** | Fixed in place with the correcting session named at each site: `mister_core.md` ground truth (pin `63496069`, 24 commits, merged-m9), file counts, §12 HARDWARE / HEARD / DRAWN rows, the `.rbf` path; `mister.md` distribution status, the fork-commit row extended to 24, the spliced 14z-112 sentence re-flowed, D2-era counts qualified, the input-coverage bullet's lead rewritten, the Recipe re-pointed to `m3b_merged16`; `mister_map.md` pin note + a current STATUS paragraph above the 14z-107 header; `mister_fit.md` provenance note (`0x4D10F3` is merged-m6's, the gate-frozen ceilings are not); `cps2_wide.md` header DRAFT -> RATIFIED; `docs/README.md` map row D0-D5; `patch_index.md` rows 0008-0024 added, 0007's "LOCAL-ONLY" retired; `mister_mra.sh` usage text; HANDOFF's four operational `merged13` commands -> `merged16`. Measurement RECORDS naming `merged13` left as written (logs of runs on that image). Re-grep of every retracted wording: empty outside this row. Scope doc §6 header carries the status |
| decisions pending | see "Decisions pending": (1) confirm the split, (2) run the staleness pass BEFORE the skills (recommended), (3) the `.rbf`'s home |
| green | `run_all_static --strict` after the docs change: **PASS 110 / SKIP 0 / FAIL 0 / MISSING 0**; ROM audit 76/76 |
| **THE FREEZE — merged-m10 (maintainer, 2026-08-28: "you can do the freeze, all the more so since the pass was green")** | `build/m3b_merged17` frozen as **merged-m10**: the one-zip repackaging of merged-m9, **M8 mark unchanged, program fingerprint `32007911` unchanged, every member CRC unchanged** — the zip sha1 moved (`eee7e4b1` -> `5aeefbec`) because `vsavjw.zip` gained the four patched group-A members and the parent is now the pristine dump. Tag `freeze/merged-m10`; HANDOFF registry row; `release/merged-m10/{fbneo,mame,mister}/` — **the first release in the per-platform format ruled the same day** (round-trip PASS, 20 patched + 5 pristine, manifests identical across the three) — `mister/` holding (the WIDE + `[STOCK CONTROL]` MRAs, 31/31 and 22/22 parts resolving, and `BITSTREAM.txt` — seed/slack/sha256; the `.rbf` file itself is still on the synthesis box, its home is the open RELEASE FORMAT item — *as written at freeze time; superseded the same day, see the post-close addendum above: in-tree at `release/bitstreams/18269/`*). Re-point sweep: 54 gate defaults `m3b_merged16` -> `m3b_merged17`, `test_pointer_flow` pair -> `merged-m10` (expectation copied from `merged-m9.txt`, identical program), `audit_hui_grunt` gains the merged17 key, `mk_mister_page.py` reads merged17. **The MiSTer tail of this freeze is EMPTY by construction** (`gen_vsavjw_xml.py --check` ok on merged17; catalogue keyed by name+CRC; `.rbf` unchanged) — the field bundle 14z112 IS this set. No tenant/stock build dir moved; build-dir policy: merged16 stays as "one back", merged15 is still referenced by `test_inp_crash_merged_m8_01` defect mode and is NOT deleted. **Gates at freeze, on merged17:** `test_inp_corpus` 6/6 no exception · `test_version_string` PASS · `test_merged_render_content` PASS · `test_release_roundtrip` PASS incl. the new §4 layout check · `gen_vsavjw_xml.py --check` ok · `check_mra_parts` WIDE 31/31, STOCK 22/22 · `run_all_static --strict` **PASS 110 / SKIP 0 / FAIL 0 / MISSING 0** on the tree as committed (gate §4 + the sweep included) |
| **BUNDLE 14z112 FIELD-VERIFIED (maintainer, 2026-08-28)** | "excellent: no regression" — **stock Vampire Savior renders correctly on Jotego's own JT core from the shared pristine `vsav.zip`, WIDE runs on our core, and the STOCK CONTROL MRA boots on our `.rbf` too.** So the one-zip packaging is CONFIRMED on hardware: one SD card carries this profile AND stock, which is what 14z-112's fix set out to do. The repackaged set `build/m3b_merged17` is therefore field-proven — registering/freezing it is now UNBLOCKED (still the maintainer's call; content unchanged, fingerprint `32007911`, only the zip layout moved). The maintainer asks whether the STOCK CONTROL still has a use — answered under "Decisions pending" (recommendation: keep it, as the per-BITSTREAM superset leg, run once per new `.rbf`, not per romset release). #113's hand check was not mentioned in this report and is NOT assumed closed |

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
  2026-08-28, after it booted fine on bundle 14z112.) RECOMMENDATION: KEEP
  IT, RE-SCOPED.** It was built (14z-109) to separate a fault in our
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
| ~~**PYRON'S MEDALLION WHITENS on the select screen**~~ **FIXED 14z-116** | **FIXED** on `build/m3b_merged19` (fingerprint `af21bc88`), not yet frozen | **The long-parked residual is closed, and it was never the accent march.** WRITE-TAP ATTRIBUTION (16 word writes, PCs `0x3FFC60-0x3FFCA6`) named **our own 14z-62k sword thunk** at `PRG:0x05F9D0`: its P2 branch wrote `0x90C340` = row `0x1A`, which is also Pyron's medallion row. Not Donovan's portrait (the 14z-87b supposition), and not the marcher — the marcher was already neutralised for `0x16/0x19/0x1A` in 14z-64. **Maintainer chose the fix from three options (2026-08-28): drop the P2 write.** `tst.b $381(a4)` now `bne`s to the pop/rts, two NOPs replace `adda.w #$60,a1` — same byte count, no allocation ripple. **Accepted trade: P2's select-figure sword shows the vanilla grey ramp while P2 hovers a tenant.** MEASURED: row `0x1A` holds Pyron's vs2 palette across the whole select with P2 on Donovan; P1's accent on row `0x17` byte-for-byte unchanged; **`38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select` BIT-IDENTICAL to merged18** (the changed path runs only on a P2 tenant hover, which no legacy replay does) — note `38` is the exact replay whose one-main-loop slip forced the 14z-88 revert of the previous attempt. Gate: **`tests/test_pyron_medallion_2p.sh`**, two legs, verified to FAIL on merged18 and PASS on merged19. **It closes a real coverage gap:** `test_wheel_bank5` 3b's two protocols are both SINGLE-PLAYER, so it could never see this and stayed green through every freeze. **NOT FROZEN — a freeze is a separate decision** |
| **#112 Press of Death black foot** (Donovan's EX foot super) | DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA; why a tenant runs that vanilla sequence is unknown. Entry point when resumed: DISASSEMBLE the effect spawn, never scan |
| **RANDOM SELECT should include the three tenants** — ADDED TO THE LIST by the maintainer 2026-08-28 | measured 14z-116, not built | the "?" cell walks a FIXED 15-entry table at `PRG:0x020C88` (`04 07 02 0C 05 0F 0A 00 0E 03 08 01 0D 09 06` = the base-half roster minus `0x0B`), 3-frame cursor, wrap `cmpi.b #$f`. Both bounds hard -> a tenant can never come up. **The siblings are the precedent**: vsav2's twin table (`PRG:0x01F8B4`) lists `10 11 13`, vhunt2's too — including the newcomers is what the source games do. FIX SHAPE: 18-entry relocated table + bound `#$f` -> `#$12`; it cannot grow in place (15 bytes + 1 pad, then code at `0x020C98`) and the table is read PC-relative, so it is a `site_thunk` on `PRG:0x020C80` + a `code` op, not a data poke. COST TO WATCH: the added cycles land on the select screen, whose legacy replays are already the bounded-window class — measure the onset before and after |
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
