# STATE — living progress log

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

## Session 14z-112 CLOSE — ritual complete. **#99 CLOSED ON A GREEN FIELD
## VERDICT; #112 REPRODUCED, RULED COSMETIC AND PARKED; #113 MEASURED VANILLA;
## AND THE WIDE PROFILE STOPPED BREAKING STOCK VAMPIRE SAVIOR.**

| | |
|---|---|
| opened with | the 14z-111 orientation: field verdict pending, one unreplayed maintainer recording |
| #99 | **CLOSED (maintainer).** Board GREEN on bundle 14z111 (M8) over the Bishamon > Phobos route that was 100% on M6/M7, plus four hand-played MAME recordings replayed guard-clean (`play-merged-m9-01`, `run-merged-m9-02..04`) covering both crash routes, a full arcade run to the ending, and a lost-then-continued Phobos fight. All tracked under `tests/inp/` |
| #113 | **MEASURED VANILLA and awaiting only the maintainer's MiSTer check.** The "flash" is ONE all-white frame at every down — identical hash, identical event inventory, on stock `vsavj` AND on `vsav2`. Gate `tests/test_down_flash_vanilla.sh`; mechanism section in engine_internals |
| #112 | **REPRODUCED deterministically** (`run-merged-m9-05`: Victor white f5685-5693 vs Q-Bee black f7357-7370) and **RULED COSMETIC (option c), option (a) PARKED** to a later cosmetic pass, option (b) refused (the sequence is vanilla data — editing it breaks the superset invariant). Whole draw path measured VANILLA down to the writer instruction; WHY a tenant runs that sequence is still unknown |
| **TWO RETRACTIONS, both mine, both same-session** | (1) "the effect shelf-pack breaks multi-tile rectangles" — falsified by the audit it motivated: the tile window is byte-identical to stock, so the rectangle test was measuring vsavj-vs-vsav2 layout, not a defect. (2) "the port borrows vanilla sequence 0x28394E" — the four "pointers" were a displacement word followed by the next opcode. **Both were byte SCANS. The standing lesson recorded for the cosmetic pass: DISASSEMBLE, never scan** |
| the MiSTer fix | **WIDE builds no longer pack a patched `vsav.zip`** — the four patched group-A members moved INSIDE `vsavjw.zip`, so one SD card can carry this profile AND stock Vampire Savior. The core was never at fault (already gated on MRA header byte 41). Rebuilt as `build/m3b_merged17`, SAME fingerprint `32007911` — packaging, not content. Bundle `../mister_fieldtest_14z112/`, .rbf unchanged. Awaiting the board |
| recordings became infrastructure | `.inp` playback now stops at the END OF HUMAN INPUT (`-exit_after_playback` + a `PLAYBACK <n>` line). The old runs scored ATTRACT DEMO as play: frame figures corrected in every NOTE (real play is 5181 / ~10000 / ~43600 / ~21500 / ~16200 / 7490, not "200000") |
| new instruments | `tools/run_inp_probe.sh` + `tests/lua/inp_probe.lua` (per-frame video hash, HP/death flags, OBJ counts, snapshots, OBJ dumps, `GFXRANGE` tile hashes, `RECT_AUDIT`, `WRITETAP`, `FINDBYTES`, POKES, char-ids), `tools/audit_effect_rects.py` (INSTRUMENT, not a gate), `tests/test_down_flash_vanilla.sh` |
| gotchas paid for | MAME **read** taps never fire (write taps do) — a dead knob, removed not documented; a tap installed once at autoboot is silently dropped unless re-installed on the map-change notifier; tap dedup on `(pc,addr)` hides the write that decides the frame; build-dir deletion must grep FOUR places incl. `build/manifest/`; "tracked" build dirs are only partly tracked |
| build-dir sweep | 26 generations deleted, **4.9 GB -> 2.9 GB**, keeping current + one back. It broke `test_shared_writes` (its fixture `don_m7` had 23 UNTRACKED outputs); recovered by rebuilding at the freezing commit — fingerprint `c90b60c3` reproduced exactly. The cheap alternative (re-point + re-freeze) was MEASURED and REFUSED: it would have laundered 103 unreviewed shared-surface writes |
| green at close | `run_all_static --strict` **PASS 110 / SKIP 0 / FAIL 0** (the 14z-111 baseline) · inp corpus 6/6 on merged17 · MiSTer MRA map · romset identity · WIDE render-content · m3a reproducible (four WIDE manifests re-frozen for one-zip packaging, 42 -> 25; **MANI_STOCK unchanged** = the control that the stock track is untouched) |
| queued | the MiSTer **scope document** (the agreed first step of the documentation/skill-distillation effort — scope only, not the skills); THE COSMETIC BACKLOG (win-quote text for all three tenants, ladder map names/pictures, select-wheel polish, #112) |
| not done | the maintainer's MiSTer check on #113; ~~the board test of bundle 14z112~~ **DONE 14z-113: field-verified, no regression, stock coexists** (see the 14z-113 group); `merged17` is NOT registered or frozen — that stays a separate decision, now unblocked |
| push | main == origin/main at close (`git ls-remote`); no tags cut (no freeze) |

**Ledger rollover:** the 14z-110 and 14z-109 groups moved verbatim to
STATE_HISTORY.md; STATE holds 14z-110b / 14z-111 / 14z-112.



## Session 14z-112 (2026-08-27) — **FIELD VERDICT GREEN on merged-m9 (M8):
## #99 CLOSED by the maintainer. Four maintainer recordings tracked, all
## guard-clean. #113 re-read as a sprite-dropout frame.**

| | |
|---|---|
| board | the maintainer's MiSTer on bundle `../mister_fieldtest_14z111/` (wheel = M8) does NOT crash on the Bishamon > Phobos route that crashed 100% on M6 and M7, "despite all my efforts" |
| MAME recordings (all replayed with `tools/run_inp_guarded.sh` on merged16, `crashes=0`, tracked under `tests/inp/`) | `play-merged-m9-01` (14z-111: first match vs CPU Phobos dragged near time-over) · `run-merged-m9-02` (full arcade run as Donovan to the ENDING — the shell character's, as expected; first evidence a tenant run completes) · `run-merged-m9-03` (Anakaris > Victor > Phobos, the reliable M6/M7 route; Phobos dragged through most of the moveset, lost, retried on continue — no poisoned second fight) · `run-merged-m9-04` (Bishamon > Phobos, long fight) |
| #112 evidence grew | Press of Death palette flips with ANY kick AND MID-ANIMATION (white/blue foot turns black/blue partway) — rules out a per-strength palette row; it is a time-varying palette write (fade/flash family or a row collision). Issue comment posted |
| #113 re-read (CRT) | not a palette flash: on the CRT the BACKGROUND STAYS while the sprites (Phobos especially) are not drawn or sit on an invisible plane for at least one frame — an OBJ-list / draw issue. Cosmetic, still the photosensitivity item; investigate via per-frame OBJ dumps vanilla-vs-merged at the first down, not the palette. Issue comment posted |
| #112 REPRODUCED (14z-112) | The maintainer's `tests/inp/run-merged-m9-05` carries a clean A/B on ONE build: match 1 vs Victor = white Press of Death (f5685-5693); match 2 vs **Q-Bee** (opponent 0x0c from f6215) = the LAST instance, **f7357-7370, descends white and lifts BLACK** (sole/toes/stripes black, outline cyan). Real playback = **7490 frames** (MAME's own count) — later "instances" are the attract demo, a trap that cost one 200000-frame pass. RULED OUT by measurement: palette-row overwrite (row 05 byte-identical white vs black), the WIDE 19-bit promote (`a18 == a19` on every foot record), a tile-inventory hole (all 27 codes resolve through delta 0x2750 into placed sources), and any dark row being in use. **LIVE LEAD:** vsav2 draws native Donovan on palette row **0x10**; our port draws the foot on row **05** — the port remaps rows, so a phase whose records carry a row inconsistent with the remap renders correct art in wrong colours. **14z-112 continued — four more eliminations, all measured on the capture:** (a) the foot's tiles are NOT blank — every white AND black tile reads 128/128 non-zero bytes in MAME's decoded `:gfx` (probe env `GFXTILES`); (b) no placement collision — the black dsts appear in NO select/overlay/wheel/exception dst list; (c) the foot is EFFECT art, not band art — ALL 27 foot sources are in `tile_exceptions.json:skip_band_src`, i.e. skipped by the band sweep and delivered by `effect_map` pairs (`build_gfx_donovan.py:392-413`), and this is true of the WHITE tiles too, so it does not discriminate; (d) **DISCARDED as invalid:** a cross-game hash of our dst tiles vs vsav2's source tiles (`0x10000+src`) matched NOTHING — including the WHITE tiles that demonstrably render correctly — so the two `:gfx` regions are not comparable by linear tile index and nothing may be concluded from it (RH-18). **THE SOLID RESULT (measured, assumption-free):** within the SAME move, the foot's records switch tile sets mid-animation — descent `0xe706-0xe740`, lift `0xe768-0xe796` — while the palette row is `05` for BOTH and its contents never change. The Victor (white) instance's foot uses a THIRD set, `0xe7d7-0xe7f8`, also on row 05. So the black is neither a palette rewrite nor a row swap: **the lift-phase tiles simply carry dark art in this build.** That also explains "about half the time": the move only reaches the lift phase on some outcomes.
**THREE MEASUREMENTS DISCARDED AS INVALID this session — do not resurrect them:** (i) cross-game tile hashing (our dst vs vsav2 `0x10000+src`) — mismatched even for the KNOWN-GOOD white tiles, so the two `:gfx` regions are not comparable by linear index; (ii) nibble histograms of tile bytes as "pixel indices" — CPS-2 tiles are PLANAR, nibbles are not indices; (iii) every conclusion drawn from inverting the band delta (`src = dst - 0x2750`), because under it BOTH the black AND the white codes "mismatch" their `effect_map` placement — which falsifies the inversion, not the tiles. **The delta inversion is UNPROVEN and must be established before any placement argument is made again** (the foot's sources are all in `skip_band_src`, so they arrive via `effect_map` at dsts `0xeaa7-0xee71`, nowhere near the observed `0xe7xx` — meaning the observed codes are reached by a path not yet identified).
### #112 (14z-112) — ~~ROOT-CAUSED: THE EFFECT SHELF-PACK BREAKS MULTI-TILE RECTANGLES~~ **RETRACTED THE SAME SESSION, by the audit the claim asked for.** CORRECTED: THE LIFT-PHASE RECORDS DRAW *UNTOUCHED EFFECT CODES* — THE PORT'S OWN DOCUMENTED "render garbled" DEFERRAL

**RETRACTION (same session, 14z-112).** The shelf-pack claim below was
falsified by the very audit it motivated: the audit's first real run reported
1623 of 2777 blocks "corrupt" — implausible — and the check that explains it
is decisive: **every tile in the window `0xa000-0xffff` of the merged build is
BYTE-IDENTICAL to stock vsavj (24576/24576), including all four foot tiles.**
Our build does not place ANY art there, so no shelf-pack error can live there,
and the rectangle-vs-donor test was measuring the LAYOUT DIFFERENCE BETWEEN
vsavj AND vsav2 (shared engine art, laid out differently in each game), not a
defect. The three "corrupt" blocks and the 28/28 "correct" one are the same
phenomenon seen from two sides. **The verdict LOGIC is sound** — ground-truthed
5/5 against the hand measurements — **its PREMISE was wrong for stock-art
blocks.**

**WHAT SURVIVES, and the corrected reading.** Records AND art on this path are
both vanilla: the record at `PRG:0x287D80` is byte-identical to stock
(`vm3j.08a`: 0 of 524288 bytes differ) and so are the tiles it references. So
our build renders those records exactly as stock vsavj would — the divergence
is not in any byte we wrote, it is in **which records the ported animation
selects**. And the port DOCUMENTS this failure mode in the builder itself
(`gen_donovan_patch.py:2951`): *"Effect/low codes stay untouched (per-record
effect map is a later step; **they render garbled**, never crash — tile codes
cannot fault)"*. The lift phase draws such untouched effect codes; the descent
phase happens to draw codes whose stock content is the right art (vsav and
vsav2 share much effect art). That is the live hypothesis, and it is NOT yet
proven — proving it means showing the lift record is reached by tenant
animation data that the effect-map step never covered.

**~~IT IS A BORROWED VANILLA EFFECT SEQUENCE~~ RETRACTED WITHIN THE HOUR — THE
"POINTERS" WERE AN INSTRUCTION-BOUNDARY FALSE POSITIVE (14z-112).** The four
"tenant pointers to `0x28394E`" (`0x42D024`, `0x42D062` in `x088512@huitzil`;
`0x4855C4`, `0x485602` in `@pyron`) are NOT pointers. Disassembled, every one
reads `move.l #$02208000,($0028,A4)` (or `#$80008000`) followed by `394E` =
`move.w A6,($0030,A4)`: the long-scan matched the DISPLACEMENT word `0028` of
one instruction against the OPCODE `394E` of the next. **`0x0028394E` is never
stored anywhere.** RH-35 exactly — scanning a whole binary for a value that is
also a common encoding returns noise — and I had already paid for this once
this session with the `e768 7105` hit in base territory. **So there is NO
evidence the port points any tenant at that sequence, and no precedent of
"giving Huitzil/Pyron their own effect" either: those sites are ordinary
authored spawn code (`jsr $16FD0` = the vsavj pool-3 allocator, `$FFC8xx`,
reconciliation-mapped) and say nothing about which animation is installed.**
What remains true and measured: the whole draw path is vanilla (writer
`PC 0x01B2BE` byte-identical to stock, vanilla record, vanilla sequence,
vanilla art), and **why a tenant object runs that vanilla sequence is
UNKNOWN.** Any pointer archaeology here must disassemble, not scan.

**(SUPERSEDED) IT IS A BORROWED VANILLA EFFECT SEQUENCE (14z-112, the answer to "why").**
The vanilla animation sequence at **`PRG:0x28394E`** contains BOTH records as
consecutive frames — descent `0x287D0C` (renders correctly) then lift
`0x287D7C` (renders as foreign art) — and `0x28394E` is **exactly the address
the port's own tenant data points at**: two pointers from `x088512@huitzil`
(`0x42D024`, `0x42D062`) and two from `x088512@pyron` (`0x4855C4`,
`0x485602`). So the port deliberately BORROWS this vanilla effect sequence for
tenants. Every byte drawn is Capcom's, but **the decision to point a tenant at
this sequence is ours** — and its later frames draw art that is not the
tenant's, which is the #112 black. Donovan's own regions contain no such
pointer (searched `0x283940-0x2839A0` across every member), so he reaches the
sequence through vanilla dispatch rather than a stored pointer — the one link
still unproven.
**A DEAD END, recorded so it is not retried blind:** decoding the tiles to LOOK
at them failed — the MAME `cps_layout16x16` plane/offset layout I applied
produced stripes for the KNOWN-GOOD foot tile (`0xe715`), so the decode is
wrong and nothing was concluded from the rendered images. Getting a real
picture needs the layout established against a positive control first.

**THE FULL CAUSAL CHAIN IS VANILLA — WRITER INCLUDED (14z-112).** A write tap
(with the re-install-on-map-change notifier `inp_guard` uses — without it a tap
is silently dropped and reports zero forever, measured here) caught the two
corrupt blocks being emitted on frame 7360 by a SINGLE instruction, **`PC
0x01B2BE`**, which is **byte-identical to stock** (`vm3j.03d` carries 148
modified runs elsewhere, none covering it). So the chain is, end to end:
vanilla OBJ-builder instruction -> vanilla record `0x287D7C` -> vanilla
animation sequence -> vanilla art tiles `0xe7xx`. **Not one byte this port
wrote participates in drawing the black frame.** The port's only influence is
upstream: what makes the tenant's object select this animation. (Tap-dedup
gotcha, also paid for: keying on `(pc, addr)` hides every later write to the
same slot — the one that decides what is drawn; key on `(pc, addr, data)`.)
**THE DECISIVE EXPERIMENT NOT YET RUN:** play this same animation on STOCK
`vsavj` and look. Identical code + identical data + identical art must give
identical pixels, so if stock renders it black too, the black is VANILLA
rendering of a borrowed effect and the port question becomes "should a tenant
borrow this effect at all" (a gameplay/asset decision, maintainer's call) — not
a byte to fix.

**THE PATH IS 100% VANILLA — measured this session, and it bounds the search.**
Beyond the tiles and the record: the descent record `0x287D0C` and the lift
record `0x287D7C` are **consecutive frames of ONE vanilla vsavj animation
sequence** (8-byte entries = record pointer + duration, at `0x283968+` and
`0x2859CC+`), and the only pointers to the lift record (`0x283980`,
`0x2859E4`) are themselves in untouched base territory. `vm3j.08a` — which
holds the records, the sequence AND the pointers — differs from stock in 0 of
524288 bytes. So every byte on this draw path is Capcom's; **nothing we wrote
is being rendered**, and the question is only what makes Donovan's object run
this vanilla sequence. One lead, unresolved: the ONLY ported pointers into
that sequence area come from `x088512@huitzil` and `x088512@pyron` (both
`-> 0x28394E`) — **none from Donovan's regions**.
**A dead instrument, recorded so it is not rebuilt:** a Lua READ tap on the
record found nothing, and its positive control (a tap on `RAM:$FF8400`, read
every frame) ALSO found nothing — **MAME read taps do not fire for
direct-mapped memory on this driver, though WRITE taps do** (which is why
`inp_guard` works). Zero reads is therefore not evidence. The knob was removed
rather than left documented-and-dead (RH-54); gotcha filed in
`docs/platform/gotchas.md`. Next: the debugger trace (`INP_DEBUG=1
TRACE_FROM=`) around the lift frames, which is the one instrument that can
answer "who fetched this".

**(SUPERSEDED) The mechanism, measured end to end on `tests/inp/run-merged-m9-05`.** The
records driving Donovan's Press of Death are **STOCK vsavj data, byte-identical
to the reference** (`vm3j.08a` differs from stock in 0 of 524288 bytes; the
record sits at `PRG:0x287D80`, entries are 4-byte `(tile, attr)` pairs). The
port does not rewrite them — it places Donovan's art AT the tile codes those
host records already reference (the freed Jedah band). A CPS-2 block of `w x h`
draws `code + r*0x10 + c`, so a multi-tile block needs the donor's rectangle
laid into the destination rectangle. **Measured, block by block, against the
donor's own rectangle (content-addressed via `GFXRANGE` hashes, not
arithmetic):**

| block | size | tiles correct |
|---|---|---|
| `0xe715` (descent, renders CORRECTLY) | 7x4 | **28/28** |
| `0xe775` | 3x2 | 6/6 |
| eight 1x1 / 1x2 / 2x1 / 1x3 blocks | small | all exact |
| **`0xe76e`** | 1x6 | **5/6** |
| **`0xe768`** | 2x8 | **1/16** — only the base tile is right |
| **`0xe78a`** | 4x3 | **2/12** |

So 11 of 14 blocks are placed perfectly and **3 are mis-packed**; every corrupt
slot holds a real but WRONG donor tile (e.g. `0xe769` should hold donor
`0x30266`, holds `0x3023e`), which is why the foot draws as recognisable
shapes filled with foreign art — the "blue/BLACK" the maintainer sees. The
descent phase uses the intact blocks, the lift phase uses the corrupt ones:
**"comes down white, goes back up black", exactly as reported**, and it only
appears when the move reaches the lift phase — the "about half the time".

**(SUPERSEDED — see the retraction above) Where the defect lives:** the effect shelf-pack that assigns rectangle
targets for non-band (shared-effect) codes — `gen_donovan_patch.py` (the
`gfx_remap` pass emitting `effect_map.json`) + `build_gfx_donovan.py`'s
`effects` placement. It lays small rectangles correctly and breaks on larger
ones. **NOT yet determined: the exact packing rule that fails** (1x6 and 4x3
break while 3x2 and 1x3 are intact, so it is not area alone), and **how many
OTHER records are affected** — a whole-inventory audit of every multi-tile
block against its donor rectangle is the obvious gate and is NOT yet written.
Palette, tile content, records and the WIDE promote are all exonerated by
measurement (see the eliminations below).

**THE NARROWING (14z-112, content-addressed — the arithmetic route was abandoned):** matched our foot tiles to vsav2's BY CONTENT via a new `GFXRANGE` scan of MAME's decoded `:gfx` (positive control first: our `0x0e715` == vs2 `0x301e6`, byte-identical, both 7x4 pal=05). Result: **ALL six sampled foot tiles — descent AND lift — are byte-identical to vsav2's** (`0e706`=`301d8`, `0e715`=`301e6`, `0e740`=`3021f`, `0e768`=`30265`, `0e78a`=`3024a`, `0e796`=`30273`), **vsav2 DRAWS the lift tiles too, and with the SAME palette row 05 — whose 16 words are byte-identical between the games.** Art and palette are therefore BOTH exonerated on both sides; the divergence is in the OBJ RECORDS. And the records agree where they correspond (`attr=3605` 7x4, `0005` 1x1, `1005` 1x2 — identical words in both games). **THE ANOMALY: block HEIGHT.** Over its whole Press of Death vsav2 emits pal-05 blocks of height 1/2/3/4/5 only (max 5); our lift window `f7357-7371` additionally emits **height 6 (`0e76e`, 1x6) and height 8 (`0e768`, 2x8, attr `0x7105`)** — shapes the donor never produces. A tall block sweeps a RUN of consecutive tiles, so those strips pull in neighbours that are not part of the sprite and render dark through row 05. **CAVEAT, stated: the vsav2 capture is ONE instance of the move; the height histogram is strong evidence, not proof that the donor never emits h>=6 here.** NEXT: (a) confirm the donor's height ceiling over more vs2 instances/phases; (b) find where the two tall records come from in the ported per-phase record data and what their vs2 twins are — that is the fix site. **NOTE the earlier arithmetic path is abandoned:** the band-delta inversion was falsified, and the effect shelf packs non-contiguously (our `0e715`->vs2 `301e6` is +0x21AD1 while `0e740`->`3021f` is +0x21ADF), so ONLY content matching is admissible here.
**(superseded plan) NEXT, in order:** (0) ESTABLISH the record->gfx-address path for ONE known-good white tile (e.g. `0xe715`) — content-match its bytes against candidate sources with the project's canonical decoder rather than by arithmetic; only then is any placement claim admissible. (1) DECODE and RENDER the 128 bytes of a black tile and a white tile (4bpp, row 05) and LOOK — right art through wrong colours, or wrong art?; (2) diff the OBJ record stream of the white instance (f5685-5693, Victor) against the black one (f7357-7370, Q-Bee) step by step — if the two ask for different codes at the same animation step, the divergence is upstream in the record/anim data, and the opponent-dependence is the clue. Instrument: `inp_probe.lua` (foot detection, foot-gated palette rows, `GFXTILES`, `CPSREGS` — the last is DEAD, CPS-A regs read back 0) |
| (superseded) #112 EARLIER PROGRESS — move identified, black not yet reproduced | Press of Death = Donovan's **EX 41236+K** (meter-gated — that is why meterless kicks whiff; banked via `POKES ff8509`, replay 56's ES trick). Rigs `tests/replays/112_don_pod_{merged,vsav2}.rpl` reproduce the giant white/blue foot on merged (Donovan L,L,D,D; c1=0x13 asserted) AND vsav2 (native, R,R). `inp_probe.lua` gained char-id (`c1/c2` = `$FF8782/8B82`), raw input ports (`in=`), and POKES. **Foot is WHITE/blue (correct) in ~16 instances** across two opponents (Victor + Phobos on his own stage, c2=0x10), all three strengths, varied RNG — the blue/BLACK the maintainer sees "about half the time" did NOT reproduce, so it is NOT per-invocation RNG. Hypothesis (unproven): the foot's palette row is shared/unreserved and gets overwritten mid-animation under palette-allocator pressure (busier scene / Dark Force / deeper match) — matches the maintainer's "turned black MID-move" note. Maintainer clue: white DOWN, BLACK on the way back UP (mid-move), no Dark Force, no being-hit, "might not have hit". Tested BOTH branches — CONNECT (2-hit, vs Victor) and WHIFF (fired at range, empty ground): foot stays WHITE through descent AND lift in both. ~20 instances total, all white. So it is a state condition the scripted round-1 rig misses; it IS on MAME (#112 body) so an .inp will carry it. **Maintainer offered an .inp of the black run + video/timestamp — accepted (field-reports-are-recordings); replay under inp_probe, freeze white-vs-black frames, diff the foot's OBJ record + palette-RAM row, then vs vsav2 for the donor question.** Foot pal index not yet pinned (candidates 05/0b from OBJ dump) |
| #113 MEASURED — VANILLA | `tests/lua/inp_probe.lua` + `tools/run_inp_probe.sh` (per-frame framebuffer hash + HP/death flags/OBJ counts on an `.inp` OR a replay) located the first down in play-merged-m9-01 at f6074 (Phobos `+0x11F`=01, t=0x2B) and the "flash" at **f6153: one ALL-WHITE frame** (mean 255; the OBJ list never collapses — the sprite-dropout reading was the CRT's rendering of a white frame). Stock vsavj on the reference MAME shows the SAME hash at the same events (`104`: down 6550 -> white 6646; intro pair 1909/1911; start 2148 = HP-set+183, merged +183 too) and nowhere else. Gate `tests/test_down_flash_vanilla.sh` PASS (inventory == attributable events, negative control on strays). Decision pending: close as vanilla (recommended) vs opt-in softening |
| **WIDE NO LONGER BREAKS STOCK VAMPIRE SAVIOR (14z-112)** | The build packed a PATCHED `vsav.zip` (4 group-A members `vm3.13m/15m/17m/19m`) and the field bundle shipped it as `games/mame/vsav.zip` — one file, so a card could hold this profile OR stock, never both, and a stock MRA got wrong art SILENTLY. **The core was never at fault: the profile is already runtime-gated on MRA header byte 41.** FIX: the patched members go INSIDE `vsavjw.zip` and no `vsav.zip` is packed — jtframe matches by CRC32 alone and FBNeo/MAME search the set's own zip first, so both legs share the pristine dump. Rebuilt as `build/m3b_merged17`, **same program fingerprint `32007911`** — packaging, not content. Evidence: MAME takes the patched member from `vsavjw.zip` (verifyroms FOUND = patched CRC) · identity audit PASS · a full replay of `run-merged-m9-05` IDENTICAL 7490/7490 · corpus 6/6 · `test_mister_mra_map` PASS (the fork catalogue needed NO regeneration — members are keyed by name+CRC, not container) · romset-identity + WIDE render-content PASS · every MRA part resolves by CRC (WIDE 31/31, stock 22/22 against PRISTINE dumps alone). Bundle `../mister_fieldtest_14z112/` (.rbf UNCHANGED, wheel still M8). Also fixed for the new packaging: `build_donovan.sh` WIDE path, `mister_mra.sh` (its header had asserted the two legs NEED different `vsav.zip` files — corrected in place), `gen_vsavjw_xml.py` (pristine-parent fallback), `test_mister_mra_map.sh` (covers both packagings) |
| PLAYBACK LENGTH IS NOW MEASURED (14z-112) | A recording ENDS where the human stopped playing; MAME then runs the ATTRACT DEMO, and the guard was scoring that as play. **Esc is a UI key and is NOT in the `.inp`** (header checked: magic + basetime + sysname, no frame count), so no end-of-input signal is needed from the maintainer — MAME's own `-exit_after_playback` stops at the last recorded frame. Both `tools/run_inp_{guarded,probe}.sh` now pass it and append `PLAYBACK <n>` (MAME's authoritative count) + `END <n>`; the terminator is written ONLY when MAME reports a playback, so `test_inp_corpus.sh`'s dead-run check can still fail (RH-25) — negative-controlled this session. **Frame figures CORRECTED in the NOTEs: real play is 5181 (crash-m8-01), ~10000 (play-01), ~43600 (run-02), ~21500 (run-03), ~16200 (run-04), 7490 (run-05) — the old "200000 frames guard-clean" counted demo.** The verdicts stand (the play was covered); the numbers did not. Gates after the change: corpus PASS 6/6, `test_inp_crash_merged_m8_01` PASS |
| gate note | `tests/test_inp_corpus.sh` plays each recording only to `MAX_FRAMES=6000` (100 s) by default; the `.inp` files are complete and `MAX_FRAMES=200000` covers them fully (~1 h for run-02). The instrument is capped, not the recordings |
| push | main pushed at each tracking commit; no tags cut (no freeze) |


## Session 14z-111 CLOSE — ritual complete. **#99 ROOT-CAUSED (CPU-Phobos ran
## DEMITRI's AI — the aliased upper half of the AI script tables) AND FIXED
## (option A: the tenants' own vs2 AI, zero code); frozen donovan-m14 /
## huitzil-m21 / pyron-m15 / merged-m9, mark M8; board bundle 14z111 ready.**

| | |
|---|---|
| opened with | the 14z-110b close-ritual audit: 3 stale items fixed (uncommitted H/P M7 bumps behind committed pins; no 110b HANDOFF row; patch_index "NOT YET BUILT"), 110b acceptance re-runs GREEN, FBNeo oracle refit landed, tags cut, the re-point sweep + build-dir policy applied |
| the turn | the maintainer's board AND hand-played MAME both still crashed on merged-m8 -> the maintainer recorded it (`tests/inp/crash-merged-m8-01`) -> `tools/run_inp_guarded.sh` (write tap on the game's own `$FF0000` exception store) captured vec11 at `PRG:0x422BAC` on the natural path -> trace + write taps -> the four CPU AI script tables, 16 classes + the same 16 repeated |
| the fix | bank_map `ai_script_0..3` (data_ptr, `region = "auto"`, `optional = true`) + one DATA root per tenant + `region_space x101aca=wide_ext` + 4 `reconciliation_huitzil` rows (Phobos's own AI reached tripwires) + M8 mark; WIDE-only (stock twin unchanged). The pinned merged extract inputs (`build/{m5_wide,hui32,pyron21}/extract`) REGENERATED deliberately (old kept as `extract.pre-14z111`, untracked); `build/merged1` (the legacy-only instrument) rebuilt by audit_merged_legacy — both committed |
| green at close | test_inp_crash_merged_m8_01 MODE=clean (default) PASS · don_vs_cpu · merged_legacy 47/47 · guard corpus 332/332 on merged16 · stage-4 · m3a (all pins + whole-artifact re-attributed) · tenant_loop · pointer_flow / pcrel / escape_triage / region_overlap(+control) / id_space / biased-list re-frozen with attribution · suites GREEN x3 under --freeze AND x3 verify (tenant .sha1s moved only by `$FF06CC/CD`, state identical; H/P gained the 107-110 expectations they never had) · MiSTer twin + mra-map · bundle WIDE 31/31 · `run_all_static --strict` FINAL: **PASS 110 / SKIP 0 / FAIL 0 / MISSING 0** (after the biased-list hui46 pin and a hollowed jtsim scratch clone — platform gotcha) |
| naming/cleanup | recordings are `<what>-<freeze set>-NN` (`crash_m10` -> `crash-merged-m8-01`, gate `test_inp_crash_merged_m8_01`); unreferenced cache recordings deleted (crash_m8 plain-play, crash_m9 abort, smoketest) — rule in CLAUDE.md §4 + build_dir_triage.md |
| the law | **FIELD REPORTS ARE RECORDINGS** (maintainer-ruled at close): CLAUDE.md §4 clause + `tests/test_inp_corpus.sh` (every tracked `.inp` replayed at every freeze, PASS 1/1 on merged16) + HANDOFF/gotcha — the tooling had existed since 14z-9x; its use was not systematic, and 14z-109..111 paid for that with two shipped non-fixes |
| first MAME verdict | **1P Donovan vs CPU Phobos, dragged near time-over with button spam: NO CRASH** (maintainer, 2026-08-27; `tests/inp/play-merged-m9-01`, 20000 frames guard-clean) — not a proof, but the #99 protocol no longer reproduces. TWO COSMETICS observed and filed with the recording as evidence, neither investigated: Press of Death (41236+K) blue/BLACK palette ~half the time (GitHub #112) and the whole-screen flash at the first down — photosensitivity (GitHub #113) |
| not done | the field verdict (the maintainer's board, bundle 14z111, tell = M8); the maintainer's other-crash provocations (replay any new `.inp` on both builds); the probe capture dir `build/inp_guard/` kept untracked as evidence |
| push | main + fork pushed (`git ls-remote`, not prose); tags `freeze/{donovan-m14,huitzil-m21,pyron-m15,merged-m9}` cut and pushed at close |

**Ledger rollover:** the 14z-108 group moved verbatim to STATE_HISTORY.md;
STATE holds 14z-109 / 14z-110(+b) / 14z-111. (Commit a3ca058's message
claimed this a commit early — its script had aborted before writing.)



## Session 14z-111 (2026-08-26) — **OPENED WITH A CLOSE-RITUAL AUDIT of
## 14z-110b (the maintainer's call: the close was clean but unchecked).**
## Findings, then the mechanical fixes applied; the judgment calls left
## for the maintainer below.

**Measured against the tree (git, not prose):** main == origin/main (pushed);
no stash; no leftover emulator/suite processes; `emu/fbneo` dirty = exactly
the two applied patches (8 files = 3 + 5, expected); the refit scan dumps
survive in the session scratchpad (`refit/`, ~22 frames × 4 replays).

**STALE AND FIXED THIS SESSION:**
1. **`huitzil.toml` / `pyron.toml` `version_text` M6 -> M7 were UNCOMMITTED
   since 14z-110** — while `test_m3a_reproducible.sh`'s MANI_HUI/MANI_PYR
   pins (committed 49e00ed) were re-frozen on the M7 glyph members. A clean
   checkout would have rebuilt H/P with "M6" and failed the pins: a rule-3
   reproducibility gap. Committed now.
2. **HANDOFF had NO registry row for 14z-110b** (donovan-m13 / merged-m8 /
   stock8) and the playtest default still named merged14. Row added,
   default -> merged15.
3. **patch_index still said "NOT YET BUILT" for the 14z-110 d2 window**
   (shipped two freezes ago) and had no 14z-110b remap entry. Both fixed.

**STALE, LEFT FOR THE MAINTAINER (not mine to decide):**
- **Build-dir policy skipped at BOTH 14z-110 and 14z-110b:** `don_m12/13`,
  `m3b_merged14/15`, `m5_stock7/8` and `guard_corpus/m3b_merged14.*.tsv`
  are UNTRACKED (14z-105 tracked its generation), and the N-2 deletion
  (`build_dir_triage.md`: keep current + one back) never fired — `don_m11`,
  `m3b_merged13`, `m5_stock6` (305 MB tracked) and the m12/merged14/stock7
  generation (305 MB) are both still present. Suggest: track m13/merged15/
  stock8 + the TSV, delete m11/merged13/stock6 AND m12/merged14/stock7 at
  the next freeze (or now).
- **12 local freeze tags are unpushed** (donovan-m8/m9, huitzil-m16..18,
  pyron-m10..12, merged-m1..m4) — long predating 110b. Push is the
  maintainer's call by standing rule.
- STATE.md holds four groups (108 / 109 / 110 / 110b); the ledger ends at
  14z-107. 14z-108 is due to roll to STATE_HISTORY at this close.

### THE 14z-111 FREEZE — donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9 (M8), stock twin UNCHANGED

| | |
|---|---|
| builds | don_m14 `772d8052` / hui48 `cd362ca4` / pyron32 `c403a283` / merged16 `32007911` / stock9 = `d29fd062` (donovan-m13-stock, program identical: WIDE-only port, gfx-only mark) |
| layout | Donovan's `x101aca` at the wide_ext HEAD (`region_space`, after a hole_a placement cascaded 56 regions — measured); every ext region behind it +0x10D0 (hui) / +0x1ED0 (pyr) / +0x2B60 (pools) — uniform, verdicts unchanged |
| acceptance | `test_inp_crash_merged_m8_01` MODE=clean PASS on merged16 (default flipped); defect mode still reproduces on merged15 |
| validations on merged16 | don_vs_cpu PASS (3 CPU legs, own AI) · merged_legacy PASS 47/47 · guard corpus 332/332 · stage-4 PASS (target unchanged) · m3a PASS (all pins + whole-artifact manifests, per-member attributed; 07b = 16 bytes of existing repoints whose targets shifted) · tenant_loop 332/366/303, 608/660, 819/920 · pointer_flow / pcrel / escape_triage re-frozen with attribution · MiSTer twin + mra-map PASS |
| suites | donovan-m14 GREEN (12 tenant .sha1s moved: ONLY `$FF06CC/CD`, an execution-position return-address word one slot below the ratified secondary-stack window, at select entry f890 and match-start windows; state byte-identical — measured at 9 frames) · huitzil-m21 GREEN · pyron-m15 (in flight at the time of writing) · verify passes in flight |
| release / MiSTer | `release/merged-m9` (M8) · fork `63496069` pushed, pin bumped, patch 0024 · bundle `../mister_fieldtest_14z111/` = merged-m9, WIDE 31/31, .rbf unchanged, **tell = M8** |
| open | field verdict on the board; the maintainer's other-crash provocations (any `.inp` under a new name replays on both builds) |

**Why the tenant .sha1s moved without any state change (recorded, mechanism attributed not proven):** the AI channel starters read the tenant's rows at select entry and match-start phases; the data they now read (his own block in the ext) differs from Demitri's, so the interpreter's per-frame work costs different cycles at the sample instant — the OBJ-builder bsr chain sits one word apart. Nothing else in 64 KiB moves. `$FF06CC` is 4 bytes below the ram.md `$FF06D0-$FF06EF` row: the class's window is one slot deeper on this content (note added to ram.md).

### #99 FIX — OPTION A AUTHORED AND PROBE-VALIDATED (maintainer chose A; 14z-111, 2026-08-27)

**Landed (8596b9d, NOT frozen):** bank_map `ai_script_0..3` (data_ptr, the
new `region = "auto"`), one DATA extra root per tenant for his vs2 AI block,
four `reconciliation_huitzil` rows for the tripwires Phobos's own AI reaches
(`0x2cbde/0x2ce0a/0x2ce3e/0x364a` — the R1 loop's first fire, twins
measured), `test_tenant_loop` re-frozen (+5/tenant, -4 hui tripwires).
**ACCEPTANCE: `test_inp_crash_merged_m8_01 MODE=clean` PASS on the merged probe
`0df398ff`** — the maintainer's recording plays through with zero
exceptions (defect mode on merged15 still PASSes = the capture is stable).
Interpreter equivalence measured (patch_notes 14z-111). Docs landed:
patch_notes / patch_index / engine_internals "CPU AI action-script system" /
gotchas. **In flight (niced chain, scratchpad `val_*.log`):**
`audit_don_vs_cpu` (three CPU legs on the tenants' OWN AI) ->
`audit_merged_legacy` (the superset proof for the alias-half rows) ->
`audit_guard_corpus` (332). Then the freeze ritual (donovan-m14 / huitzil-m21
/ pyron-m15 / merged-m9, **M8 mark**, stock twin moves — the rows are data),
flip the gate to MODE=clean default with BUILD re-pointed, MiSTer CRC tail.
The maintainer is meanwhile provoking OTHER crashes on MAME with recording
armed (a Donovan-vs-CPU-Bishamon crash would be a different mechanism).

### #99 ROOT CAUSE — CAPTURED ON THE NATURAL PATH (maintainer's .inp `crash-merged-m8-01`, 14z-111)

**The crash:** frame 4806, **vec11 (line-F)** at `PRG:0x422BAC` = inside
`x05c800@huitzil` DATA (a per-class (dx,dy) table right after an `rts`),
reached by `jmp (2,pc,d1.w)` at `0x41C1A8` in Phobos's PORTED jump handler
(vs2 `0x2592A`, region `x02592a@huitzil`) indexing its sub-state table by
Phobos's `+0x07 = 0x0E`. **vs2's table has 5 entries (`+0x07` 0x00-0x08);
vsavj's own jump handler (`0x22A24`) has 10 (0x00-0x12).** Sub-state 7 is a
vsavj-only phase. Same PC/frame on merged14 — the 110/110b fixes never
touched this path.

**Who writes 0x0E:** vanilla `PRG:0x2BD72` (`move.l #$0200060E,(4,a6)`) — the
JUMP COMMAND of the CPU AI SCRIPT INTERPRETER (`0x2BD54` family), executing
a script whose channel pointers were `0x100036/0x10036A/0x100BA0`: VANILLA
scripts. **The four per-class AI action-script tables `PRG:0xBF01A/09A/11A/
19A` (consumers `0x2CCB6` family, `bank_map.toml` "still parked") are 32
entries = 16 classes + THE SAME 16 REPEATED (Capcom's aliasing guard). Class
0x10 (Phobos) -> entry 16 = DEMITRI's AI scripts; 0x11 -> class 1's; 0x13 ->
class 3's.** CPU-Phobos plays Demitri's AI; Demitri's jump command asks for
sub-state 7; Phobos's private vs2 jump handler dies on it.

Why every field fact fits: **only Phobos** has a private jump handler (vs2
`0x213F2` adds `cmpi #$10 -> 0x2592A`; Donovan/Pyron fall through to
vanilla's 10-entry handler and digest the borrowed scripts); **CPU only**
(the tables are CPU-side, 14z-98 trace — 2P never touches them); **takes
time** (the AI must randomly pick the script carrying that command; the
maintainer's keep-away rig gives it time); **every platform** (same code).

**vs2's twins:** tables `0xD91B8/0xD92B8/0xD9338` (3 starters, `0x2C492/51C/578`)
carry real rows for 0x10/0x11/0x13 -> vs2 `0x100000-0x102Bxx`; per-tenant
script volume ~0xE3C (H) / ~0xC8E (P) / ~0x10B8 (D) bytes. The two
interpreters are STRUCTURALLY IDENTICAL (15 command tables, same sizes) —
the bytecode numbering carries; command BODIES can differ (the jump body
does: vsavj writes sub 0x0E, vs2's twin does not — measured below).
Fix shapes — **DECISION PENDING (maintainer; gameplay-bearing: CPU-tenant
behaviour is 1P content):**
- **(A) UNPARK the four AI tables** — add `bank_map.toml` `data_ptr` rows for
  `0xBF01A/09A/11A/19A` (twins `0xD91B8/238/2B8/338`, origin arithmetic
  verified) so the extractor seeds vs2's tenant AI scripts (one contiguous
  vs2 block `0x100000-0x102Bxx`, ~11 KB, word-offset streams) as regions,
  relocates them into WIDE ext and repoints rows 0x10/0x11/0x13 (the alias
  half — reachable by no legacy class, `id_space.md`; 0x18 Oboro untouched).
  ZERO code. CPU Phobos/Pyron/Donovan then play THEIR OWN vs2 AI — correct
  by construction (vs2's Phobos scripts were written against his 5-sub-
  state handler). Pre-ship measurement owed: the two interpreters are
  structurally identical (15 command tables, same sizes, jump body byte-
  identical) but bodies drift by bytes — verify per command like 110b's
  consumer proof; script-internal absolute pointers via the extractor
  oracle. RECOMMENDED.
- **(B) band-aid** — guard Phobos's private jump handler (`x02592a`) for
  sub-states beyond its table (route to vanilla's generic handler). Code in
  a ported region, no crash, but CPU tenants keep playing BORROWED vanilla
  AI (Phobos attempting Demitri's script) — nonsense behaviour, no crash.
- **(C) both** — (A) for behaviour, (B) as the guard against any other
  vsavj-side writer of a foreign sub-state (8 static `move.b #$0e,(7,a6)`
  sites exist in vanilla; whether any can reach a seq-6 Phobos is
  unmeasured — the 2P field runs say not in practice).
Also: bump the version mark to **M8** at the fix freeze — the 110b freeze
shipped the same "M7" as its predecessor, so the field could not tell the
builds apart by eye (paid for tonight).

**Gate:** `tests/test_inp_crash_merged_m8_01.sh` (MODE=defect PASS on merged15 —
CRASH 4806 vec11 PC 422bac frozen; flip to MODE=clean with the fix). The
recording is tracked at `tests/inp/crash-merged-m8-01/` (40 KB + nvram).

**Instrument that got it:** `tools/run_inp_guarded.sh` + `tests/lua/inp_guard.lua`
(cheap-mode write tap on the game's exception-code store; `INP_DEBUG=1
TRACE_FROM=` for the instruction trace, `WATCH=` write ring). The .inp is
`~/.cache/vampire-saved/inp/crash-merged-m8-01/` (hand it into tests/ — persistent
suite doctrine — before close). NOTE the soft-reset RAM test writes 0..9 to
`$FF0000` too (CRASH lines with SP=0 after the real one): filter pending.

### THE #99 CRASH IS NOT FIXED — and it reproduces on MAME by hand (2026-08-26, maintainer)

**Two emulator-derived fixes, both falsified by the board and now by MAME
itself.** The 14z-109 "root cause captured" (`0x3FB899 = 0x51` walked by
Phobos's object) came from probe H, which the record marks POKE-CONTAMINATED,
with "verify the field path funnels through this same node" listed as
remaining work — NEVER DONE. 14z-110 (d2 window) and 14z-110b (remap) were
validated against THAT mechanism on rigs; every natural-path rig
(`audit_don_vs_cpu`, both contexts) ran clean before AND after — the rigs
never reproduced the field crash, and the maintainer's hands do, on merged15,
first try. **So the mechanism the board and MAME hit is a DIFFERENT one, or
the captured node is walked by a path the rigs never take.** Retracted in
place: HANDOFF's 110b row "field surfaces closed" and patch_index's 110b
"Field surfaces closed" (this session's own overclaims).

**Next (in flight):** the maintainer records the crash as a MAME `.inp`
(`WIDE_RECORD=crash_m8 tools/run_wide.sh build/m3b_merged15 mame`, the
HANDOFF:487 protocol); `tools/run_inp_guarded.sh` + `tests/lua/inp_guard.lua`
(new this session) play it back in CHEAP mode (no -debug, so the playback
stays faithful) and read the game's OWN exception record — `$FF0000.w` code,
`$FF0018-$FF0053` D0-A6, `$FF0054.l` saved SP, the 68k frame at that SP (PC,
fault address) — the moment it appears, plus a work-RAM dump. First natural-
path capture of the crash, ever. Everything else (the M8 mark bump, another
fix) waits on what it says.

### BUILD-DIR POLICY APPLIED (maintainer-conditioned: "IF AND ONLY IF we know we can rebuild")

Rebuildability PROVEN first: `test_m3a_reproducible` PASS (donovan/H/P/stock
program images + whole-artifact manifests), and `tools/build_merged.sh` into
scratch reproduced merged15's fingerprint `73690f21` with both zips
member-content-identical (only zip timestamps differ). Then: m13 generation
(`don_m13`, `m3b_merged15`, `m5_stock8`) TRACKED; m11 generation (`don_m11`,
`m3b_merged13`, `m5_stock6`) DELETED (git sees 77 renames — the generations
are mostly byte-identical); m12 generation stays on disk untracked as the one
back. `run_all_static --strict` on the resulting tree: PASS 110/0/0.

### THE 110b CLOSE ORDER, EXECUTED (this session, "go ahead")

| step | result |
|---|---|
| (2) full-suite acceptance verify on don_m13 (MAME) | **SUITE GREEN** — 65 PASS, 0 FAIL; SKIPs = the vsav2-target ground-truth halves only; no tracked file changed |
| (2) audit_guard_corpus on merged15 (JOBS=2) | **PASS 332/332 guarded runs, zero vectors** (`build/guard_corpus/m3b_merged15.1787771888.tsv`, tracked) |
| (3) FBNeo oracle reduced refit | **LANDED (86f9cb2)**: FRAME_OVERRIDE 01/21/05 from the measured scan, 06 derived, 26 dropped for 05 (documented in the gate header + CLAUDE.md §4 + HANDOFF); overrides checked against the ratified MAME regions (unsafe = FAIL); FROZEN inventory unchanged. **PASS x2, every frame masked-EXACT** (no phase line at all — the chosen instants are cleaner than the old derived ones ever were) |
| (4) `run_all_static.sh --strict` | **PASS 110 / SKIP 0 / FAIL 0 / MISSING 0**, no tracked file changed during the run |
| (4) tags freeze/donovan-m13 + freeze/merged-m8 | **CUT (local, annotated, at the post-refit tree) — NOT pushed; push is the maintainer's call, along with the 12 older unpushed tags** |
| (1) field verdict on merged-m8 | **RED (maintainer, 2026-08-26 evening): the 20:17 bundle (all three files, CRC chain zip->MRA->merged15 VERIFIED `156fd6a8`) STILL CRASHES on the board — same protocol (Donovan 1P, win vs Bishamon, then Phobos), every time, within the match (not necessarily at fight start). AND THE SAME PROTOCOL CRASHES ON MAME ON merged15 BY HAND.** The remap (110b) and the d2 window (110) did not touch the crash. Wheel still M7 (the mark was not bumped for 110b — the tell was useless; bump it next freeze). See "THE #99 CRASH IS NOT FIXED" below. |



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

"vsav vanilla is always better when we can." **When a console port and
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

- **THE REMAINING SKILLS — PLANNED 14z-114 (`docs/project/skills_scope.md`),
  five decisions taken under stated assumptions, OPEN TO VETO:** (1) FOUR
  skills — `cps2-hardware`, `cps2-emulation` (split per "MiSTer separate
  from emulation"), `vampire-savior-engine`, `vampire-saved-port`; (2) the
  game skill quotes NO ROM addresses (laws + the atlas row it names); (3)
  the port skill anchors into CLAUDE.md and points, never restates it; (4)
  each skill's staleness pass runs in the same session as its distillation
  as its own commit (the MiSTer ruling generalised); (5)
  `engine_internals.md` counts as a LOG for the game skill's number-citation
  check. Sequencing A+B (platform) -> C (game) -> D (port). Distillation of
  A+B began the same session.
- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** ~~Recorded as FUTURE, UNPLANNED work — nothing scheduled.~~
  **THE MiSTer PAIR IS DONE 14z-114** (`mister-cps2-wide-core`,
  `mister-vampire-saved`, checker `tools/checkskills.py`; STATE 14z-114). The
  CPS-II-emulation and VS/VS2/VH2 skills remain future, unscheduled; the
  checker shape (docs as the human rendition, anchored IDs, numbers cite the
  log) is the pattern they should reuse.
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

Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
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
  consumer's `lea -4(a0,d0.w)` bias means it reads index `0x60+id-1`. NOTE the
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
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | root-caused, not built | consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`. Art side already native (14z-62e/62j) |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| **#112 Press of Death black foot** | DECIDED cosmetic, parked | whole draw path measured VANILLA; why a tenant runs that vanilla sequence is unknown. Entry point when resumed: DISASSEMBLE the effect spawn, never scan |
| (#113 first-down white-out) | **not ours** — vanilla in vsavj AND vsav2 | pending only the maintainer's MiSTer double-check, then it closes |


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
