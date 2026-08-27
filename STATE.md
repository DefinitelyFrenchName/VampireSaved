# STATE — living progress log

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



## Session 14z-110b CLOSE — **the 0x51->0x44 remap is BUILT, FROZEN and
## MAME-VALIDATED; the board bundle carries merged-m8; the FBNeo partial
## oracle's reduced refit is RULED and IN PROGRESS (continuation recipe
## below).** Closed at the maintainer's call (context ceiling) — three
## background validations were in flight at close and MUST RE-RUN.

### GREEN AT CLOSE (measured this session)

| | |
|---|---|
| the remap | six bytes (vm3j.10b alone, all three tracks), five-consumer equivalence, poison-rig A/B: stored 0x44 PERSISTS (vs pre-remap flail) |
| builds | don_m13 `ec86330f` / stock8 `d29fd062` / merged15 `73690f21` (program fingerprints; whole-artifact digests re-frozen + attributed) |
| registry/pins | donovan-m13 + -stock rows; m3a SIX pins green ("merged image: CHECKED"); phasec re-pinned; ~51 defaults re-pointed |
| suite | don_m13 .sha1s: 12 of 13 IDENTICAL, only 110_don_arcade_mash moved (the remap's footprint) — SUITE GREEN (filtered) |
| MAME cross-view | **merged_legacy on merged15: PASS, zero fails (47 replays on ratified classes)**; stage-4 gate PASS (stage-4 image legitimately unchanged — the rows are stage 6) |
| audits | continue_switch PASS (all 5, incl. the deterministic literal pairing); don_vs_cpu PASS (both field contexts); dualtrack PASS; census EMPTY + gates PASS ×3 builds |
| MiSTer | fork `f5a3391a` (catalogue #3, pushed), pin bumped, patch 0023, twin+mra gates PASS; **bundle `../mister_fieldtest_14z110/` refreshed to merged-m8** (WIDE 31/31; README updated; .rbf unchanged) |
| release | release/merged-m8 packaged, round-trip PASS |

### LOST AT CLOSE — RE-RUN FIRST NEXT SESSION (rule 2: these are the freeze's
### formal acceptance, interrupted not failed)

1. **The full-suite acceptance verify on don_m13** (`MAME_BIN=~/.cache/...
   MAME_ROMPATH="build/don_m13/rompath;$ROMDIR" tests/run_suite.sh vsavjw`).
2. **audit_guard_corpus on merged15** (BUILD=build/m3b_merged15, JOBS=2).
3. `tests/run_all_static.sh --strict` once the oracle refit lands (see below).
NO TAGS were cut for 110b (donovan-m13/merged-m8) — tag AFTER 1+2 are green.

### THE FBNEO ORACLE — reduced refit RULED (maintainer, this session),
### continuation recipe

Root cause (measured, trail in the 110b addendum): the RULED d2-window
cycles shift FBNeo's execution phase corpus-wide — oracle PASS on m11,
byte-identical FAIL on m12/m13; the remap is exonerated (m12==m13 RAM at the
failing frame, full-image diff = exactly six bytes). MAME holds everywhere.
The plan: per-replay FRAME OVERRIDES (chosen from measurement) + re-frozen
in-window inventory; **drop 26_don_arcade_mash alone** (cycle-saturated,
cascading, MAME-covered — document in the gate header). A clean-frame SCAN
for 01/06/21 + 05 (the 26-substitute) was running at close:
`$SCRATCH/refit/plan.sh` shape — dumps at ~22 frames/replay, both legs,
masked diff classified clean/inwin/dirty. Re-run it (script is 20 lines,
regenerate from the 110b addendum's description), pick 5 clean frames per
replay, add a FRAME_OVERRIDE case block + extend FROZEN with the audited
in-window offsets, verify x2 for determinism, THEN run static strict.
**THE SCAN COMPLETED AT CLOSE — the refit is now mechanical.** Measured
clean (`exact`, masked-zero-diff) frames on don_m13, both legs:
- 01_attract_long (15/17 usable): 600, 1000, 1400, 2600, 3400 all exact
- 06_test_mode (7/7): unchanged — keep the derivation
- 21_don_mash (13/21): 600, 2523, 3164, 4446, 5087 exact
- 05_timeout_idle (15/21, the 26 substitute): 600, 2250, 2800, 3900, 8300 exact
Every in-window offset at USABLE frames is already in FROZEN (55B/C/D,
6D1, 6D4, 6D5) — choosing exact-only overrides needs NO inventory change.
Implementation: a FRAME_OVERRIDE case block in the gate (replay -> 5
frames), REPLAYS default swaps 26 -> 05 with the documented exclusion
note, verify x2 for determinism, then static strict. Dirty frames measured
and avoided: 01 f6734(+0xf226); 05 f1150/1700/4450/5550/6100; 20/07/22
lists in the 110b addendum; 21 f1241/1882/5728/6369/8292.

### THE FIELD QUESTION AT CLOSE (the maintainer's, on the board)

merged-m8 on the SD card: Donovan 1P -> Bishamon -> the next tenant match
plays through with NO name-screen reset, and the Victor KO plays its REEL
(the neutral-pose bug was the same poison's mild surface). The wheel still
says M7 (the mark did not bump for 110b — gfx unchanged).


## Session 14z-110b addendum — **THE FBNEO ORACLE RED IS ROOT-CAUSED TO THE
## RULED d2-WINDOW CYCLES (110), NOT THE REMAP (110b) — and the hunt cost a
## paid-for instrument trap.** Resolution pending maintainer (the FBNeo
## analogue of the ratified MAME 24-tip).

**The measured chain:** oracle PASS on don_m11 (0 fails) -> FAIL on don_m12
and don_m13 with BYTE-IDENTICAL rows (5 fails: 01_attract f6734 4 bytes —
3 at sound-area-class-adjacent offsets + 1 at +0xf226; 26_don_arcade_mash
wholesale at 4 of 5 sampled frames, 1230-2574 masked bytes). m12 vs m13
work RAM at the failing frame: ZERO bytes (the six remap bytes are unread
in this replay — full-image diff = exactly six bytes, RH-46). Pairings,
ladder, and in-use mask IDENTICAL van/m12/m13 through f15000 (probe) —
the divergence is a cycle-slip WITHIN the same fights (the 14z-89 class),
FBNeo-side, cascading through the mash. ROMDIR audited pristine en route.

**The instrument trap that manufactured the earlier contradiction:** the
oracle takes its build POSITIONALLY; `BUILD=env` is silently overwritten —
the "m12 PASS" measured don_m11 (the then-default) and both later "m12/m13"
runs measured don_m13 (the re-pointed default). Filed in project/gotchas
("identical results across different builds = check you varied the
variable").

**Resolution PENDING (maintainer):** the oracle's own rule — FBNeo-only
deviation beyond the two ratified phase classes = GROWTH, sign-off
required. The mechanism is the ruled cost (accepted with "if it moves,
stop and escalate"); zero-cycle hooking is impossible at the site
(documented law). Options to be asked once MAME's cross-view lands
(acceptance verify + merged_legacy in flight): swap the two cycle-saturated
replays out of the oracle's sample set (keeps it strict; MAME retains full
coverage of both) vs a third FBNeo phase class (the never-reconverging
licence the maintainer refused in 14z-89) vs engineering a leaner arm
(relocates the tipping point, their own words).

## Session 14z-110b — **THE RESIDUAL #99 ROOT-CAUSED AND THE REMAP RULED-BY-
## CONDITION: the STORED state 0x51 over-runs a SECOND 80-vs-84 dispatcher
## (PRG:0x2384E) the 14z-43 audit also missed; the fix is 0x51 -> 0x44 on the
## six deity nodes + ONE ported immediate — measured equivalent at every
## consumer both engines have.** Maintainer GO: "if the semantics are the
## same, let's go with (1) without doubt" — the condition was then met.

**The field falsified the first fix's completeness** (M7 wheel confirmed =
the d2 window WAS loaded): the crash persisted (Phobos as 3rd fight — venue
variance, the trigger follows whoever walks Donovan's node), plus a NEW
surface: Victor KO'd -> NEUTRAL POSE, no reel, no sound, resolution proceeds.
Both are ONE mechanism: the d2 window's copy handler now STORES 0x51 into
(0x54,a1) — in vs2 a real state; on vsavj out of range for the stored-state
consumers. The poison predates the fix (d1 case_a2 and the 14z-43 thunk
always stored it); pre-fix the node walk crashed first.

### THE MEASUREMENTS (in ask-order, each requested by the maintainer's doubt)

1. **The (0x54,aN) consumer map, both engines** (97 vs 98 sites, structurally
   parallel): ONE index consumer — `0x2384E` (vs2 `0x2237A`): `move.b
   (0x54,a6),d0; add; move.w (6,pc,d0),d1; jmp` — vsavj table `0x2385C` = 80
   entries, vs2 `0x22388` = 84. vsavj [0x51] = misaligned `jmp 0x2399C` (the
   crash/neutral-pose site); vs2 [0x51] handler = byte-identical to vsavj's
   OWN [0x0A]==[0x44]==[0x4C] handler.
2. **Full handler bodies** (not prefixes): identical instruction streams
   except vs2's extra `cmpi #$51 beq` — which GROUPS 0x51 with {0x4C,0x44}
   into the same branch. vs2's own code declares the family.
3. **The per-state lookup inside the handler** is the property table read
   An-indexed = DATA view (the 14z-79 access-mode rule; an opcode-view read
   en route was discarded as the wrong view): vsavj[0x44]=0x19 ==
   vs2[0x51]=0x19. The ES-freeze family preserved. (0x19/0x4E remaps fail
   this or the d3 dispatcher — why 14z-35/the first ruling were wrong.)
4. **Ported-code literal knowledge of 0x51** (the maintainer's PoC worry,
   measured): the widened scan closed at FIVE sites — two in `x022400`
   (one = the ported handler's dead-after-remap grouping test; one REAL
   divergence at +0x15E8: `cmpi #$51,(0x54,a6); bne; move.b #1,(0x117,a6)` —
   a vs2 state-0x51-ONLY action), plus our own thunks (es_type51, index
   window, and a variant-id chain whose #$51 is PYRON'S VARIANT SLOT id —
   character id, unrelated). First scan was CONTAMINATED (backticks in an
   unquoted heredoc — the documented class) and re-run clean.
5. **Store-constant inventory**: NEITHER engine ever stores #$44/#$4C to
   (0x54,An); no Donovan node natively carries 0x44/0x4C/0x0A -> the site-2
   companion edit (#$51 -> #$44) is collision-free, and post-remap state 0x44
   arises exactly and only where vs2 had 0x51.

### THE FIX AS LANDED (manifest e6b130e)

SIX `region_fix` bytes: the deity node bytes (`hitbox` +0x10E9..0x1189,
`51 -> 44` — the 14z-35 offsets, correct value this time). **The seventh (a
companion edit at ported `x022400`+0x15EB) was landed and RETRACTED within
the session:** the region is HUITZIL's (a donovan-row silently never fires —
measured on the built image) and its invoking thunks are PARKED, so the
ported copy is dead code; vanilla has NO twin of vs2's conditional
`0x117` store there. The 0x117 flag is LIVE engine-wide (22 tst / 11 clr /
27 stores) — the residual timing delta for deity states is recorded in the
manifest comment; arbiters are the deity-family gates and the field. The d2 window STAYS as the guard;
`es_type51_dispatch` and reaction_hook `case_a2` go DEAD-BUT-EQUIVALENT
(vanilla [0x44] is the same copy handler) — deprecation candidates, noted in
the manifest. Census gates rewritten for the EMPTY inventory (synthetic
MISSING control). Builds/freeze round 2 in progress at the time of writing.


## Session 14z-110 (4) — CLOSE. **THE RULED ORDER IS COMPLETE: FIX -> AUDIT ->
## RE-FREEZE, all green.** donovan-m12 / merged-m7 frozen and tagged; the
## acceptance full suite is GREEN (65 PASS / 18 SKIP / 0 FAIL, zero
## nondeterministic) and the static tier is GREEN (PASS 110 / 0 / 0). The #99
## fix ships in every track; the FIELD pass on the new bundle is the final
## verification (MAME cannot reproduce the crash).

### THE FREEZE, as ratified

| | value |
|---|---|
| donovan-m12 | `60b55a12`, 327 ops; set carried from m11, .sha1s MEASURED IDENTICAL; +16870 flicker ratified (below) |
| merged-m7 | program `761fd35a`, 808 ops; `build/m3b_merged14`; release/merged-m7 packaged (round-trip PASS) |
| stock twin | `cf455760` (`build/m5_stock7`) — MOVED this window (the fix is not profile-gated) |
| huitzil-m20 / pyron-m14 | CARRIED — program bit-exact, whole-artifact delta = the two M7 glyph members only |
| m3a pins | all SIX re-frozen with per-member attribution (incl. MANI_MERGED `75a253ea`, measured twice) |
| MiSTer | fork `fc04a8ec` (2 catalogue commits, PUSHED), pin bumped, patches 0021+0022, twin+mra gates PASS |
| version mark | M7 (gfx-only; program fingerprints held; test_version_string pixel-exact) |

### TWO MAINTAINER RATIFICATIONS THIS CLOSE

1. **24_don_winmash flicker inventory +16870** (solo set only): the ruled d2
   compares' ~18 cycles tip the documented win-screen-fade VBL-edge frame
   (the 14z-89/91 site, this exact replay). Measured before the ask:
   deterministic; NINE bytes, all the OBJ-builder secondary stack
   `$FF06D7-E1` (the ratified execution-position class, ram.md:62); adjacent
   frames zero-diff; 1650 identical after; the SAME fix on the merged image
   HOLDS its inventory — per-image cycle budget, the maintainer's own 14z-89
   framing. Checker still demands exact inventory match.
2. **The M7 mark** (convention: the shipped build's naked-eye tell) — gfx-only
   by measurement.

### THE NO-EXPECTATION DEBT, surfaced and paid for donovan-m12

The first full verify since 14z-108 surfaced four arc-added replays with no
expectations (107/108/109/110) — run_suite counts NO-EXPECTATION as RED by
design. Frozen after review (tenant-determinism .sha1 class). **STILL OPEN,
flagged not fixed: huitzil-m20 / pyron-m14 / merged sets carry the same four
gaps** — their full verifies were not rerun this window (their images did
not move); the gaps predate this window. Freeze them at the next window that
touches those sets.

### INSTRUMENT NOTES (beyond the (2) entry's)

- run_suite reads specs per-replay at comparison time — a spec landed
  mid-run applies to replays not yet reached (measured: the ratified 24 line
  turned a mid-flight run's 24 row green).
- My dump legs collided writing `dump_*` next to a shared log dir —
  contaminated per RH-4, discarded, re-run into separate dirs. Two parallel
  legs of the same replay need separate output dirs.

### POST-CLOSE ADDENDA (same session, during the maintainer's field pass)

- **The dynamic FSM census is now CORPUS-WIDE:** all 83 replays on merged-m7
  (unpoked legs, fsm_census.lua, all three dispatchers) — **ZERO indices
  >= 0x50 dispatched anywhere.** The bound the static census stated is now
  measured across the whole corpus on the shipped image.
- **donovan-m12-stock registry row + carried stock/stage4 expectation sets**
  (the battery's targets — missed in the main batch; the -stock row
  convention was donovan-m8/m9/m10's). Stage-4 fingerprint CORRECTED same
  session: the gate builds stage 4 with ITS OWN recipe (99e92afc), and my
  scratch build's 653e315c used the WIDE-profile flags — a build includes
  its defaults (RH-49).
- **#111 U,U,R triage posted** (33 replays: keep all as frozen legacy
  coverage — the Donovan intent died at 14z-64 and their expectations were
  re-frozen since against the actual content; headers NOT edited in-file,
  replay file sha1s are frozen in sim gates).

- **The deferred-to-freeze validations are done:** stage-4 gate PASS on the
  corrected target (all replays masked-exact — no cycle question on that
  track); M2 battery on stock7 23/23 passed with its one skip (the
  wide-render gate) covered by a direct run — PASS (member identity + band
  equivalence + de-substitution invariant + control + liveness). The last
  re-point miss (the gate's m5_stock6 default) fixed on the way.

### WHAT REMAINS (the next session's opener)

The FIELD TEST of merged-m7: fresh board bundle at `../mister_fieldtest_14z110/`
(regenerated this close; carries the 14z-109 durable extras), the .rbf
unchanged (seed 18269, sha256 `46fc74af…` — the romset moved, the BITSTREAM
did not). The field pass verifies #99 dead on the CRT; #111's remaining
items (33 U,U,R replays triage; H/P/merged NO-EXPECTATION gaps) follow.


## Session 14z-110 (3) — **THE AUDIT PHASE: green across the board; the two
## static reds are the frozen generation itself, resolved by the freeze.**
## (Guard corpus + H/P reproduction checks in flight at the time of writing.)

**Audits on the fix builds (don_m12 `60b55a12` / m3b_merged14 `761fd35a` /
m5_stock7 `cf455760`):**

| audit | verdict |
|---|---|
| FBNeo legacy oracle (don_m12) | **PASS** — frozen phase-class offset inventories held |
| test_dualtrack (stock7 vs don_m12) | **PASS** — onsets 890/4267 held; divergence DATA-only, same writer sets |
| audit_merged_legacy (merged14) | **PASS** — leg a on the ratified legacy classes: **the frozen flicker/window inventories HELD with the d2 compares on the hit-stun path** (the ruling's stop-and-escalate cost gate: it did not move); leg b guard-clean, its vs-old-solo rows REPORT-classified as designed |
| audit_don_vs_cpu (merged14) | **PASS** — Phobos (venue 0x02) + Bishamon (0x10) legs, liveness + guard-clean |
| audit_continue_switch (merged14) | **PASS x2, frame-identical** — re-measured schedule (loss at match 4 ~f31620, re-select f31940-32500, blanket pokes f31960-32520); **assertion 5 now DETERMINISTIC via the venue steer** (post-continue first draw = Phobos); bonus: match 3 is naturally Phobos-vs-CPU-Donovan |
| test_fsm_census / test_reaction_hook_d2 | **PASS** on all three new builds |
| run_battery_m2 (stock7) | **DEFERRED TO THE FREEZE by design** — m2a_common targets the CURRENT FROZEN GENERATION (#96 ruling); an unregistered fingerprint stops it. Pre-registry gates green. Re-run post-registration |
| run_all_static --strict | PASS 108 / SKIP 0 / **FAIL 2** — `test_phasec_spaces` (stock rebuild = `cf455760` = stock7, expected the frozen `883e7d17`) and `test_m3a_reproducible` (WIDE rebuild = `60b55a12` = don_m12, expected the frozen `1de9a027`). **Both are the fix itself: the tree now produces the NEXT generation.** The sanctioned resolution is step 3 of the ruled order — the freeze updates these expectations deliberately. No other gate moved |

**The re-select poke lesson (measured twice):** pokes at f32040-32220 alone
did NOT land the switch (the re-select's class read sits elsewhere in the
window than the initial select's commit era); blanketing the whole measured
window (f31960-32520, every 40) lands it deterministically. The audit's
schedule comment carries this.

**Freeze-naming note (pending the reproduction check):** hui47/pyron31's
manifests are untouched by the fix; if they rebuild bit-exact, their
registrations (huitzil-m20 / pyron-m14) STAY and the batch is
donovan-m12 + merged-m7 + the stock update only — bit-identity needs no new
set names, against NEXT_SESSION's pre-named huitzil-m21/pyron-m15.


## Session 14z-110 (2) — **THE #99 FIX IS BUILT AND MECHANISM-PROVEN
## (A/B, register-forced): old build vec3s at the exact field signature,
## new build runs vs2's copy handler.** Builds: don_m12 + m3b_merged14
## (UNREGISTERED — the freeze is step 3). Audit phase begins.

**The fix, as ruled** (patch_index "14z-110 additions"): `[reaction_hook]`
gains `d2_case_a0/a2/a4/a6` (vs2 dispatcher-2 twin `0x016DE4` handlers,
verbatim — d2 differs from d1 at 0x52/0x53); the emitter
(`gen_donovan_patch.py`) emits an 82-byte thunk whose bne-arm carries the
same `0x50-0x53` window as the d1 arm via a SECOND ext table, falling
through to `jmp 0x018508` for every other index. Without d2 keys the
50-byte thunk is emitted byte-identical (probe manifests unchanged).
Vanilla dispatcher byte-untouched — asserted against vsavj's OWN decrypted
dump, not a build artifact.

**THE RH-43 A/B (GUARD_FORCE rig, `tests/replays/21_don_mash` + Donovan
picked, scratch node in the dead-stack window `$FF7F00/$FF7F80`,
`(0x17,A3)=0x51`, D0/A1/A3 forced at the site 0x018458):**
- don_m11 (old): `FORCE 3462` -> `CRASH 3463 vec3 PC 01850E ADDR 00018511`
  — the EXACT #99 signature, on demand, first time on MAME.
- don_m12 (new): `FORCE 3223` -> END 14120 clean, scratch `+0x54 = 0x51`
  (the copy handler ran — vs2's semantics exactly). **0 INPUT-VIOLATIONS**
  after the instrument fix below.

**INSTRUMENT: `GUARD_FORCE` added to `replay_guard.lua`**
(`hexaddr:minframe:REG=hex,...`, one-shot register forcing) — first version
armed its breakpoint eagerly and every pre-window debugger stop skewed the
frame_done input application by a beat: BOTH parallel legs flagged the SAME
frame 2874 as INPUT-VIOLATION (deterministic bp-stop skew, not host input).
Now lazy-arms at minframe-1 and bpclears after firing; the clean leg shows
zero violations. Filed under "suspect the instrument" — count now NINE.

**Gate: `tests/test_reaction_hook_d2.sh`** (ci_static) — manifest hex
re-derived from vsav2.zip, thunk reconstructed from first principles, the
vanilla dispatcher compared against vsavj's decrypted dump, census 6/6,
three verdict controls; PASS on don_m12 AND m3b_merged14. Its own first
version had wrong ext-table offsets and FAILED the good build — fixed and
the controls now prove it can fail for the right reasons.

**Op-count pins re-frozen with attribution** (`test_tenant_loop`: don
325->327, N=2 600/652->602/654, N=3 806/907->808/909 — +2 = the d2 cases
blob + its ext table, Donovan-declared, nothing dedupes; the thunk grows
50->82 bytes of hex, not an op). Placements: the 82-byte thunk moved to
`0x3FFD50` and six downstream 0x3FFDxx allocs shifted +0x60 (site-operand
carried; pcrel/pointer_flow re-derive at the freeze, the 14z-105 class).

**NOTE FOR THE FREEZE: the STOCK TWIN MOVES THIS TIME.** The reaction_hook
is not profile-gated (the substituted track carries the same six 0x51
nodes and needs the same fix), so m5_stock7 will fingerprint differently —
unlike 14z-105's profile-gated window. Budget the stock re-freeze.

**AUDIT (step 2 of the ruled order) — in flight:** fbneo legacy oracle,
audit_don_vs_cpu + guard corpus on merged14, audit_merged_legacy (the
flicker-inventory gate); results land below before any freeze.


## Session 14z-110 — **THE #99 FIX WINDOW, RE-SCOPED TO MEASURE-FIRST: the
## ruled data-remap is UNSAFE, the census is CLEAN, the #111 coverage gap is
## CLOSED with a deterministic gate.** No shipped byte moved; the fix shape is
## back with the maintainer (see "Decisions pending — #99").

**The session in one line:** planning to implement the ruled `0x51 -> 0x19`
remap found it re-breaks the 14z-43 ES port, so the maintainer said HOLD —
measure first; the measurement produced a consumer-complete census (exactly
the six known 0x51 nodes, no others), a deterministic Donovan-vs-CPU gate, and
a re-ask with a code-side recommendation.

### THE DECISIVE FINDINGS (all measured this session)

| | result |
|---|---|
| the FSM tables | **80 entries** (valid 0x00-0x4F), NOT "~0x28" — corrected in engine_internals/NEXT_SESSION/STATE. vs2 twins 84 -> gap **0x50-0x53** |
| the node byte feeds | **THREE** dispatchers (0x018460/0x018508/0x0185D2). The 14z-43 audit named 1+3, missed **2 (0x018508)** — where #99 crashes |
| data remap 0x51->0x19 | **UNSAFE**: diverges on dispatcher 3 (0x19->0x18694, not copy) AND fails the es_type51 thunk's `cmpi #0x51` |
| any copy-aliased remap (0x4E/0x4F) | dispatcher-exact on all three BUT changes `property[class]` (0x51->0x19 vs 0x4E->0x0F, the ES-freeze family). No safe data value exists |
| the census (static, family-aware) | **exactly SIX out-of-range nodes across all three tenants — the known 0x51 cluster in Donovan's hitbox. Huitzil/Pyron: ZERO.** No escalation members |
| the census (dynamic, 8 combat replays) | **zero idx>=0x50 dispatched anywhere.** Tenant nodes A3 0x3fb462-0x3fbd62 ARE walked (bracketing the #99 cluster 0x3fb862-902) but the six crash nodes are NOT — the honest gap, precisely |
| the #99 crash on MAME | does NOT reproduce from a P1-mash (full venue-0x02 Donovan-vs-Phobos marathon clean to END 40620) — needs the CORE's cross-fighter walk |

### THE RECOMMENDED FIX (maintainer's to ratify — Decisions pending #99)

Code-side on dispatcher 2's arm, INSIDE the `reaction_hook` that already owns
the only entry to it (`bne 0x018508` lives in the site prefix 0x018458): give
its bne-arm the same 0x50-0x53 window the reaction_hook already runs for
dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim. Data
stays native 0x51 (dispatcher 3 + property untouched). Cost: ~2 compares on a
legacy path — **must be measured against the frozen flicker inventory before
it ships.** Not a "port the handler" import; it reuses handlers already
present. The fix waits on the ruling (the maintainer said measure first).

### ARTIFACTS (committed, the persistent-suite doctrine)

- **`tools/audit_fsm_census.py`** — static family-aware census (node-record
  signature, vs2 classification oracle). **`build/manifest/fsm_census.toml`**
  frozen inventory (6 nodes). **`tests/test_fsm_census.sh`** — gate + TWO
  negative controls (perturbed +0x17 -> ADDED; cleared -> MISSING), green;
  registered in `ci_static.txt`. The build-time guard #99 asked for.
- **`tests/lua/fsm_census.lua`** — dynamic census instrument (per-site divisor,
  OOR + tenant-node A3 capture, POKES for venue steering).
- **`tests/replays/110_don_arcade_mash.rpl`** — 26's mash body verbatim, WIDE
  L,L,D,D prologue to Donovan 0x13 (26's U,U,R lands on Jedah). 26 untouched.
- **`tests/audit_don_vs_cpu.sh`** — deterministic Donovan-vs-CPU-{Phobos,
  Bishamon,Pyron} via the venue-byte steer ($FF8121: 0x02/0x03/0x05), liveness
  asserted, guard-clean. Closes #111's core gap. Phobos leg smoke-tested green.

### DOCS / RETRACTION (CLAUDE.md §5)

- "~0x28 states" -> "80 entries" in engine_internals (authoritative),
  NEXT_SESSION (live), STATE 14z-109 (marked in place). engine_internals
  dispatcher section rewritten (three dispatchers, 84-vs-80 gap).
- `docs/project/gotchas.md`: the renumbered-family rule sharpened — "enumerate
  EVERY dispatcher a byte reaches" + the property-dependency caveat.
- `docs/project/patch_index.md`: the missing `region_fix` mechanism row added.

### #111 (coverage rot) — PARTIAL, tracked

`audit_don_vs_cpu` + replay 110 close the "no Donovan-vs-CPU-Phobos gate" gap.
STILL OPEN (filed on #111): 33 replays share 26's U,U,R stock-track prologue
(triage list); `audit_continue_switch` still frozen to merged11's trajectory
(re-measure per its header deferred with the re-freeze).

### NOT DONE THIS WINDOW (waits on the ruling / is the next window)

The fix itself; the flicker-inventory cost measurement; the re-freeze
(donovan-m12/huitzil-m21/pyron-m15/merged-m7) + its MiSTer CRC tail.


## Session 14z-109 (4) — **THE #99 CRASH INVESTIGATED ON EMULATOR: a
## confirmed mechanism CLASS, real eliminations, and an HONEST GAP — no
## clean natural repro of the exact field crash yet.** Also surfaced: the
## standing crash-soak coverage has rotted, which is why nothing caught it.

**Maintainer's refined field data (2026-08-26):** 1P-vs-COM ARCADE ONLY,
Donovan P1 vs Phobos, crashes at SOME point in the match (not necessarily a
hit, not necessarily the start); **2P versus Donovan-vs-Phobos does NOT
crash**; first-fight Phobos crashed ~1/2, the ladder second-fight (after
beating Bishamon) is the 100% path.

### CONFIRMED BY DISASSEMBLY — the per-class sfx dispatcher is UNBOUNDED

`PRG:0x27F16`: `move.b (0x382,a6),d1` -> `lsl.w #2,d1` -> `lea 0x0BF41A,a0`
-> `movea.l (0,a0,d1.l),a0` -> jumps through `a0`. **No bounds check.** The
table has valid handler pointers for classes `0x00-0x27` (legacy + arcade +
the three tenants at `0x10`/`0x11`/`0x13` -> WIDE ext); beyond that it reads
non-pointer bytes. **Forcing an out-of-range class into `+0x382` crashes
exactly there** — probe J: class `0x20`/`0x30`/`0x40` -> `vec3` address
error at `~0x02adXX`; `0x12`/`0x14`/`0x18`/`0x28` safe.

### THE FIELD PATTERN FITS THIS, AND 2P-CLEAN IS THE KEY

The voice-class borrow (`PRG:0x0AEF2`, thunked to our `0x3FFC60`) runs in the
ARCADE path and writes `+0x382` from the opponent-candidate list; its value
is sound-fed (`$FF8110`), hence STOCHASTIC. 2P has no borrow, so `+0x382`
stays the char id (`0x13`/`0x10`, both valid) -> never crashes. A bad class
armed at match start FIRES on the next sfx event, which can be any time ->
"crashes at some point, not necessarily a hit". Every field observation is
consistent with a bad `+0x382` reaching the unbounded dispatcher.

### ELIMINATED: the #92 stage-`0x18` mechanism

The 14z-94 #92 crash was table-B stage `0x18` (vs2's 13th stage) indexing the
banner family past its end. **Measured: tenant table-B rows `0x10`/`0x11`/
`0x13` contain NO `0x18`** — the fix covered Donovan too. This is a DIFFERENT
bug in the same subsystem, NOT a #92 regression.

### THE HONEST GAP — no clean natural emulator repro

- probe J crashes but on a FORCED class (artificial).
- probe H crashed (`0x01850e`, a different PC — a state jump-table, not the
  sfx dispatcher) but had in-match class pokes; not trustworthy.
- first-fight-Phobos: 8 sound-state seeds, active Donovan, ZERO crashes.
- the committed `audit_continue_switch.sh` DRIFTED on merged13 — it ran clean
  but never reached the Donovan-vs-Phobos pairing (its trajectory is frozen
  to merged11), so its "clean" is vacuous here. **This also weakens the
  original #99 closure, which the 14z-100 note already flagged as "weak
  evidence".**
- **POSSIBILITY TO HOLD: the crash may be more readily reproducible on the
  CORE than on MAME** (user 100% vs my ~0% natural). Either a stochastic
  state my rigs missed, or a core-specific amplifier. 2P-clean on the core
  argues against a pure asset-streaming collision.

### WHY NOTHING CAUGHT IT — coverage rot (the recurring class)

- `26_don_arcade_mash` (the "Donovan arcade mash" soak) navigates U,U,R,
  which on the EXTENDED wheel lands on **Jedah `0x0F`**, not Donovan — the
  soak lost its nominal subject.
- `audit_continue_switch.sh`'s frozen trajectory no longer reaches the
  pairing. **No current gate exercises Donovan-vs-CPU-Phobos.** Same
  "check that stopped checking" class as 14z-94/95.

### ARTIFACT

`tests/replays/109_2p_don_vs_phobos.rpl` — the first 2P versus replay in the
tree (CLAUDE.md §4 has wanted "vs each of the 18, both sides"), P1 Donovan vs
P2 Phobos via the extended wheel, made possible by tonight's P2 scripting.
Verified P1=Donovan `0x3FA9D0` / P2=Phobos `0x4595B0` load on MAME.

### FIELD CONFIRMATION x2: Donovan-vs-BISHAMON crash + the video

**(1) The maintainer reproduced the crash in Donovan vs BISHAMON.** This is
the root cause's own prediction landing: the bad node is in DONOVAN'S data
block and is walked by his OPPONENT — whoever that is. Phobos was never
special; the ladder just funnels there. Kills every remaining Phobos-specific
theory (and further de-weights the sidekick reading).

**(2) The crash video (`../videos/donovan_phobos-2nd_fight_crash.mp4`, 21 s,
CRT @ 60fps) — read frame by frame:**
- Sequence: Bishamon win quote -> Donovan victory art -> VS screen **Donovan
  vs Phobos, CONCRETE CAVE** (the decoded table pairing, on screen) -> intro
  with the shell + kids -> fight.
- ~1 s before the cut: an effect-heavy CONNECTING exchange — Phobos lands an
  arm-thrust (consistent with the earlier 5+MP/6+MP suspicion).
- **The last gameplay frame is NEUTRAL** — both fighters standing apart. The
  crash follows the exchange by ~0.5-1 s, matching "not necessarily during a
  hit": the bad node is walked in the post-exchange anim chain, not in the
  hit event itself.
- The reset shows a BRIEF white-on-black check list ("WORK RAM OK / CPS0..2
  RAM OK / OBJECT RAM OK / Q SOUND RAM OK") drawing progressively, then the
  name screen — the soft-reset path's abbreviated check, exactly what the
  decoded exception handler predicts (and distinct from the gold full test).

Every observable in the video is downstream of the captured mechanism. The
remaining work is unchanged: identify the record family of `0x3FB882` in the
extraction and the vsavj renumbering of vs2's `0x51` — maintainer-facing,
fix as a remap rule per the 14z-33/35 shape.

### ROOT CAUSE CAPTURED — a vs2-numbered type byte in DONOVAN'S ported data

The extended guard probe (`GUARD_PROBE=1850c`, cond `(d1&1)==1`, PROBE line now
carrying A1/A3) caught the fatal iteration live:

```
PROBE 13918 D0=000000a2 D1=00000001 A0=ffff8400 A1=00ff8800 A3=003fb882
      A6=00ff8400 RET 00ff02dc MEM[A3+17=3fb899]=51
```

- **A1 = `$FF8800`: the P2 PLAYER object — Phobos himself**, not a sidekick
  sub-object. (The sidekick lead was the right NEIGHBORHOOD — a Phobos-side
  1P-only event — but the wrong object.)
- **A3 = `0x3FB882`: a node INSIDE DONOVAN'S relocated data block**
  (base `0x3FA9D0`, node at +0xEB2). Phobos's object walks DONOVAN'S ported
  node — the cross-fighter interaction shape (cf. 14z-73 grab-victim).
- **`(0x17,A3)` = `0x51`** — the fatal index. `D0 = 0x51*2 = 0xA2` runs past
  the state jump table at `0x018510` (80 entries, valid `0x00-0x4F` —
  **CORRECTED 14z-110: was "valid states end ~0x25"; the table is 80-entry,
  vs2's twin 84, gap 0x50-0x53**), fetches the
  word `0x0001`, and `jmp (2,pc,d1.w)` lands on odd `0x18511` -> vec3 ->
  the soft-restart handler -> name screen. Every field observation is downstream
  of this.
- **`0x51` IS THE KNOWN FAMILY:** 14z-35 "type-0x51 cluster — the engines
  RENUMBERED the copy-class record family"; 14z-33 "record-type dispatch
  aliases". A vs2-numbered type byte in ported data, indexing a vsav dispatch
  that numbers the family differently. The 14z-33/35 fixes covered the members
  then known; **this node (`ROM 0x3FB899`, in Donovan's block) is a missed
  member.**

**REMAINING to fix it (build-pipeline, maintainer-facing):** identify WHICH
record family `0x3FB882` belongs to in the extraction (the manifests map
Donovan's block), what vs2's `0x51` MEANS there, and its correct vsavj
renumbering — then the fix is the same shape as 14z-33/35 (a remap rule in the
extraction, not a hand-poke). Also: verify the FIELD path (natural 1P arcade)
funnels through this same node — probe H's trajectory is poke-contaminated,
so the node identification transfers but the path should be confirmed on a
clean repro or on the maintainer's video.

**INSTRUMENT CHANGE, recorded:** `tests/lua/replay_guard.lua`'s PROBE line now
prints A1 and A3 (additive; existing fields unchanged). This is what made the
capture possible.

### THE PROBE-H AUTOPSY REFINES IT: an ODD dispatch index, not merely out-of-range

Probe H's crash is DETERMINISTIC (f13918 every run, vec3, PC 0x01850e, fault
ADDR 0x18511) — a reusable lab rat even though its trajectory is
poke-contaminated. Dense-dump autopsy findings:

- **Fault ADDR 0x18511 => D0 = 1, an ODD index.** The normal state path
  doubles the state (word table), which can only make EVEN indexes. So this is
  NOT a plain too-big state: either the dispatcher was ENTERED from a path
  that did not double the index, or D0 was loaded from the wrong field. An
  odd D0 faults on the table read itself — instantly, cleanly, no corruption
  first — which matches the field signature perfectly.
- **Player-slot `+0x54` states all benign** ($FF8400..$FF9800 at 0x400 stride,
  values 0-5) up to f13910 — the corrupt write either targets an object
  outside that window or lands in the last 8 frames.

**NEXT (deterministic, cheap):** re-run probe H dumping EVERY frame
13910-13918 over a wider window, and capture the guard's stack for the
caller; then PC-attribute the write/entry that produces D0=1. Separately,
the ACCUMULATOR hypothesis stands (first-fight crashes "if long enough";
second-fight crashes at the intro 100% => something counts up across the RUN,
plausibly sidekick voice events — which also explains 2P immunity if the
sidekick path is silent there, as the maintainer heard).

**HARDWARE PROTOCOL AGREED:** the maintainer records 1P crashes on video (CRT,
60fps — the value is the LAST ~10 SECONDS before death: what Phobos and the
sidekick were doing), plus passive observation of sidekick activity before
each crash. No RAM peeking needed on the DE10 — the emulator side owns
instrumentation. Playing Phobos as P2 is LOW-VALUE by our own model (2P
suppresses the sidekick behaviour), noted so it is not over-invested in.

### SYNTHESIS: A PHOBOS OBJECT (LIKELY THE SIDEKICK) DRIVEN TO AN OUT-OF-RANGE STATE

**Maintainer's strongest clue yet:** 1P vs COM crashes reliably "if the fight
is LONG ENOUGH"; 2P versus NEVER crashes despite everything; and in 2P **the
Phobos SIDEKICK had NO voice/SFX** (incl. the "get up, don't give up" lose
animation, which normally speaks) — while in 1P that sidekick voice DOES play.

**Traced the reproduced crash site `0x01850e`:** it is a VANILLA object
state-machine dispatch — `move.w (6,pc,D0.w),d1; jmp (2,pc,D1.w)` — where D0 is
the object's STATE field `(0x54,a1)`. Handlers (0x018694-0x01877c) set next
states including `0x25`(37); a state value beyond the offset table reads a
garbage offset and jumps to an odd address -> `vec3` address error -> the
soft-restart handler -> name screen. So the crash is: **an object's `+0x54`
state got set OUT OF RANGE**, and vanilla's dispatcher faulted on it.

**THE COHERENT PICTURE, every field observation accounted for:**
- Phobos's SIDEKICK is an assist object with its own state machine + voice.
- It acts PERIODICALLY through a match -> "crashes if the fight is long enough"
  (more sidekick events = more chances to hit the bad state).
- Its full behaviour incl. VOICE runs in the 1P/arcade path and is absent in
  2P (maintainer heard exactly this) -> crash is 1P-only, and "2P clean" is
  NOT a coincidence: the triggering event doesn't fire in 2P at all.
- The hits observed near crashes were Phobos's, never Donovan's — **a strong
  hint, NOT a certainty (maintainer-corrected 2026-08-26): the trigger may not
  be an attack at all.** Consistent either way with it being Phobos's OBJECT —
  a periodic sidekick event needs no attack to fire.
- Immediate reboot, no corruption -> a control-flow fault, which this is.

**LEAD (for measurement, not arbitrage): what writes `+0x54` out of range on
a Phobos object in 1P.** Candidates: a ported Phobos sidekick anim node whose
state byte is wrong; the mid-match `+0x382` voice reassignment feeding a
sidekick voice/state path; or a lost/mis-ported sidekick spawner (cf. the
14z-41 lost-spawner and the effect-flow work). The `$FF0000` exception code
and the `+0x54` state value at fault are the two things to capture in a
poke-free 1P Phobos repro.

**DISCRIMINATING, on hardware:** does making Phobos's SIDEKICK active (his
assist/summon moves) bring the crash on FASTER? Does the sidekick look/behave
normally in the frames before a crash? A "yes, faster with sidekick activity"
nails the sidekick object.

### THE CRASH SIGNATURE IS DECODED — it is a CPU EXCEPTION, and my vec3 repros are the SAME EVENT

**Maintainer refined the signature: the reset goes STRAIGHT TO THE GAME NAME
SCREEN (plain white name on black), NOT through the gold-text RAM test.** That
is decisive. A cold/watchdog reset always re-runs the RAM test (it is exactly
what the pre-D5 boot loop did). Skipping it means a SOFTWARE restart from a
point after the RAM test.

**Decoded the 68k exception vectors + handlers (verify_op/verify_data):** every
exception (bus `vec2`, address `vec3`, illegal `vec4`, …) runs a handler that
does `move.w #code,($FF0000)` — storing the exception TYPE (0 bus / 1 addr / 2
illegal / …) — then `movem` all regs, resets SP (`lea ($FF0054),sp`) and
branches to a common restart routine (`0x608`), which reboots to the name
screen. **So "name screen, no RAM test" IS the game's designed response to any
CPU exception.**

**CONSEQUENCE — this softens the "no clean repro" pessimism.** A CPU exception
is exactly what the crash guard trips on, and I HAVE reproduced vec3/vec4
exceptions in-context: probe H `vec3 PC 0x01850e` (a `jmp (2,pc,d1.w)` jump
table, i.e. a bad-pointer jump), probe J `vec3/vec4` on forced classes. **These
are the SAME EVENT CLASS the maintainer sees on hardware** — the guard reports
the vector, hardware runs the handler to the name screen. So the field crash is
confirmed to be a bad-pointer jump / bad access / illegal instruction, NOT data
corruption (which the no-prior-corruption observation already argued).

**NEW INSTRUMENT: `$FF0000` holds the exception code.** Any repro can read it to
know bus vs address vs illegal without guessing from a PC. probe H's is an
ADDRESS error (odd-address jump-table target).

**REMAINING: pin which natural path triggers it.** probe H is the closest
(Donovan arcade context, real vec3) but has select-time pokes; the next step is
a poke-free trajectory that reaches the same `0x01850e` fault, then trace what
value indexes that jump table out of range. The `0x01850e` jump table —
`move.w (6,pc,d0.w),d1; jmp (2,pc,d1.w)` indexed by d0 — is a TYPE/STATE
dispatch, which fits "a specific Phobos move drives a state value out of range".

### CORRECTION + SHARPENED LEAD (same session, after the candidate-row check)

**THE ARCADE-BORROW THEORY IS WEAKENED — stated plainly because it was the
banner above.** I checked Donovan/Phobos/Pyron candidate rows (table A) against
the dispatcher's handler table read from the RIGHT source (member 04d, not the
mis-byte-ordered data view): **every candidate value is `0x00-0x18`, and every
one of those has a valid dispatcher handler.** So the borrow cannot write a
crash-inducing class into `+0x382`. Probe J proved the dispatcher is UNBOUNDED,
but with inputs (`0x20`/`0x30`/`0x40`) the borrow can never actually produce.
Probe J is therefore the right MECHANISM with the wrong INPUT SOURCE.

**THE SHARPENED LEAD, and it fits the field data better: a specific PHOBOS
MOVE.** The maintainer's own refinement — hits near crashes were Phobos's
(possibly 5+MP/6+MP), never Donovan's, "at some point" — **[LATER
maintainer-corrected: a strong hint, NOT a certainty; the trigger may not be an
attack]** — plus the crash signature (immediate
black screen -> the GAME reboots to its RAM test, NO prior graphical/sound
corruption = a clean jump through a bad pointer, not data rot) points at a
Phobos move whose execution dereferences a bad pointer. The CPU AI uses
Phobos's full moveset; a human in 2P may simply never have thrown the exact
move — which makes "2P clean" most likely a COINCIDENCE, exactly as the
maintainer cautioned, not a property of the 1P path.

**This is the 14z-73 grab-victim SHAPE** (a move indexing a per-victim
keyframe/effect table that, for one victim, reads a bad row), possibly UNIFIED
with the unbounded per-node sfx dispatcher (an anim node carrying an
out-of-range sfx class in its `+0x16` trigger -> `0x27F16` jumps through
`table[badclass]`). Both are "a specific move -> a bad pointer jump" and both
fit every observation.

**THE DISCRIMINATING TEST (maintainer, on hardware): 2P, HUMAN Phobos vs human
Donovan, deliberately spam Phobos's suspected move (5MP/6MP).** If it crashes,
the arcade path is IRRELEVANT and the bug is in Phobos's moveset vs a tenant
victim — chase Phobos's move/effect/keyframe data. If Phobos genuinely cannot
crash it in 2P no matter the move, the 1P-arcade path really is special and the
borrow/AI path comes back. Either answer halves the search.

### NEXT (measurement, not arbitrage — per the maintainer's standing ask)

Reach the pairing NATURALLY and TRACE the borrow's actual write to `+0x382`
for a Phobos opponent: re-measure the continue-switch trajectory for
merged13 (its header documents how) OR a fresh venue-steered marathon, then
tap `$FF8782`/`$FF8B82` through the Donovan-vs-Phobos match. If a class
whose `table[class]` is a bad pointer appears, that is the root cause and
the fix is either bounding the dispatcher or fixing what the borrow writes
for a tenant opponent. The 2P sim (core) is a cross-check, not the hunt.

## Session 14z-109 CLOSE — ritual complete. **THE ARC'S QUESTION IS
## ANSWERED AND THE ONE DEFECT IT SURFACED IS ROOT-CAUSED AND RULED.** The
## core WORKS ON HARDWARE — tenants fight, TENANT VOICES PLAY, select
## emulator-identical. The one crash is #99 = vs2 type byte `0x51` in
## Donovan's ported node stream, remap ruled `0x51 -> 0x19` with the census
## + escalation clause. **The next session is the FIX WINDOW.**

**The session in one line:** it opened waiting for a field test, and by
close the field test had passed, its single crash had gone from "flaky
reset on a CRT" to a named byte at a named ROM address with an
instruction-level-exact fix ruled — with the maintainer's live observations
(2P-clean, the sidekick's silence, "long enough", the reset style, the
Bishamon crash) cutting the search space at every step.

### WHAT THE SESSION ESTABLISHED

| | result |
|---|---|
| the FIELD TEST | boots, plays, tenants fight on real silicon; VOICES PLAY; select emulator-identical |
| #99 root cause | node `0x3FB899` (Donovan block) carries vs2 state `0x51`; vsavj table ends ~`0x28`; unbounded dispatch at `0x018508` -> vec3 -> soft reboot |
| the ruling | (a) data-side remap only (b) `0x51 -> 0x19` (byte-identical default handlers) (c) census + escalate non-equivalents; port-the-handler caveat STANDING |
| the OBJ-list oracle | promoted subset field-identical across implementations at match anchor AND select; M6 mark identical |
| P2 scripting | fork `4dfc3734`, file bits 12+, frozen sha1s provably unmoved; first 2P replay in the tree |
| the exception decoder | name-screen reboot = CPU exception, code at `$FF0000`, regs at `$FF0018-53`; gold test = cold/watchdog |
| venue steering | draw pool = `row[venue..venue+7]`, 12/12 measured — deterministic opponent pinning exists now |
| decisions hygiene | `DECISIONS_HISTORY.md` born; STATE pending section: 5 live entries |

### THE CORRECTIONS, because they transfer

Four intermediate theories died by my own measurement and are marked in
place: the arcade voice-class borrow (candidate rows only carry valid
classes); the sidekick OBJECT (right neighborhood — a Phobos-side 1P event —
wrong object: A1 was P2's player block); "Phobos-specific" (Bishamon
crashed it too — the node is DONOVAN'S); and my mis-ID of probes C/D's
opponents from an assumed id map (0x0f = Jedah, not Bishamon — the
authoritative slot map is character_tables.md, assume nothing).

### RITUAL

- **STATE**: this entry; the (3)-(8) sub-entries stand; no rollover needed
  (two session groups live, file ~120 KB).
- **`docs/NEXT_SESSION.md`**: rewritten — the opener is the #99 FIX WINDOW
  (census -> remap `fixes` rows -> #111 coverage -> re-freeze -> the MiSTer
  CRC tail: catalogue fork commit + fresh board bundle).
- **`HANDOFF.md`**: `test_obj_records` + `test_mister_obj_oracle` rows
  registered.
- **Retraction sweep**: "P2 is not expressible" corrected in
  `rpl2siminputs.py`, `docs/platform/mister.md` (x2), NEXT_SESSION history
  marker; the DF-style stale reference in engine_internals fixed in
  passing during the decisions cleanup.
- **GOTCHAS**: three filed and indexed (name-screen exception discriminator;
  the renumbered-family porting rule; the deterministic-lab-rat triage
  method).
- **Memories**: `port-the-handler-is-not-free` (maintainer's standing
  instruction); `decided-items-leave-pending` extended with the
  DECISIONS_HISTORY lifecycle.
- **GitHub**: #99 reopened + root cause + ruling (current); #111 filed
  (coverage rot). Both self-contained.
- **SCRATCH**: `/tmp/vampire-saved-jtsim-14z108` (1.3 GB) SWEPT — the
  14z-108 close kept it for the field test, the field test has reported;
  rebuild is one `tools/setup_jtcores.sh` + `run_sim` away.
  `../mister_fieldtest_14z108/` DURABLE but STALE AT THE RE-FREEZE (CRCs
  move). `../dumps/` is the maintainer's dump folder (root litter swept
  there, README inside, all regenerable). Session scratchpad ephemeral;
  every conclusion is in STATE/docs/#99.
- **PUSH**: everything pushed through the close commit; fork public at
  `4dfc3734`. Verified `git ls-remote`, not prose.

## Session 14z-109 (3) — **THE FIELD TEST RAN, AND THE ARC'S QUESTION IS
## ANSWERED: THE CORE WORKS ON HARDWARE.** Tenants selectable and playable,
## TENANT VOICES PLAY (the one thing simulation could never answer), select
## screen emulator-identical. **AND ONE 100%-REPRODUCIBLE CRASH — which is
## #99 BACK FROM THE DEAD, now with a deterministic repro path it never had.**

**The maintainer's field report (MiSTer, DE10-Nano, 2026-08-26), verbatim in
substance — the primary artifact:**

- Boots; 1P vs COM plays well, general feel BETTER than emulator (likely
  input-lag/handling, the maintainer suggests).
- **Sound plays, INCLUDING THE NEW TENANTS' — all seems good.** ["Fetched is
  not heard" is retired: the QSound extension is now HEARD on hardware.]
- Select screen emulator-identical, usage-wise perfect (parked cosmetics
  aside, out of scope).
- All 3 tenants selectable, playable, no graphical or other issues before,
  during or after matches — with ONE exception:
- **A 100%-reproducible crash-reset: pick DONOVAN 1P in normal mode, first
  fight BISHAMON, WIN it -> second fight is ALWAYS PHOBOS (stage may vary,
  opponent never) -> crash-reset at the end of the character intro or just
  as the fight begins, regardless of input.** Not tried on emulator yet.
  Does NOT happen picking Phobos or Pyron as P1.
- 2P versus not yet tried; confidence high.

### THE CRASH IS #99, AND ITS CLOSURE DID NOT HOLD

Archaeology (CLAUDE.md §5, done BEFORE touching anything):
- **14z-94 (#99):** the SAME signature — Donovan vs CPU-Phobos, "crashed
  right after the character's intro at fight start" — on **MAME**, build
  merged9, reached via continue+switch to match 5. So the crash class is
  NOT MiSTer-specific.
- **14z-100:** `tests/audit_continue_switch.sh` reached the literal
  Donovan-vs-CPU-Phobos pairing at **match 4** on merged11 and ran clean —
  the basis for closing #99, with the caveat recorded at the time: "the
  clean pass is weak evidence" that #103's fix removed the trigger.
- **The field path is DIFFERENT and NEVER TESTED: match 2, reached by
  WINNING match 1 (vs Bishamon), no continue.** The 14z-100 rig cannot have
  exercised it.
- Also on the books: the 14z-94 LEAD, explicitly unmeasured then — the
  voice-class borrow (`ram.md:87`) writes a class from the OPPONENT'S
  candidate row into `+0x382` at match start; a tenant opponent makes that
  a tenant class; and the crash timing (right after the intro) is when the
  dispatcher first fires.

**In flight: an emulator repro attempt** on merged13/MAME under the crash
guard — if it reproduces, the full instrument set (write taps with PC
attribution, per-frame dumps) applies; if it does not, the difference
between implementations is itself the lead.

## Session 14z-109 (2026-08-25/26) — **THE FIELD TEST GAINED A NEGATIVE
## CONTROL IT DID NOT HAVE, AND THE OBJ LIST BECAME THE FIRST WORKING
## CROSS-IMPLEMENTATION VIDEO ORACLE.** Opened while the maintainer's
## hardware test was pending, so everything here is work that does not need
## the board. **IN FLIGHT AT THE TIME OF WRITING: the field test itself.**

**The session in one line:** it started as housekeeping during a wait, found
that the field test was about to be run WITHOUT a control, and ended by
making a video-determining surface agree across two unrelated codebases for
the first time.

### WHAT WAS ESTABLISHED

| | result |
|---|---|
| the field-test bundle | had **ONE MRA and no control**; now carries a STOCK CONTROL leg |
| MRA part resolution | **WIDE 31/31 resolve, STOCK 22/22** after the pristine swap — measured, not assumed |
| the bundle README | item 5 was **STALE**, corrected later in 14z-108 than the README was written |
| the fork README | brought to D0-D5 (was "slice D1", 5 files against the tree's 13) |
| the OBJ list as an oracle | **WORKS** — promoted subset 31 vs 31, field-for-field IDENTICAL |
| the walker | calibrated **1153/1153 lines** against the live-machine one BEFORE use |

### THE RESULT THAT MATTERS

At the frozen tenant anchor (`36_pick_tenant_cell`, MAME 2886 / sim 3546) the
**PROMOTED** subset of the OBJ list is **31 entries on BOTH legs, ORDERED AND
FIELD-FOR-FIELD IDENTICAL**, and the 19-bit tile addresses slice D3 computes
are the same set, **`0x4b0c4-0x4ecda`**. The promote, the group-C redirect and
the 3-bit bank are confirmed against an unrelated codebase at the sprite-list
level. **First cross-implementation agreement this project has on a
video-determining surface, and it is on the content the port exists to add.**
**STILL NOT PIXELS** — this is the LIST, not the rendered frame.

### THE CORRECTION, WHICH IS WORTH MORE THAN THE RESULT

The raw lists do NOT match: **40 entries vs 129**. I reported that mid-run as
"a real difference — the core genuinely holds a shorter list". **THAT WAS
WRONG.** A 1P replay's CPU opponent is the SOUND-STATE-FED LOTTERY
(`atlas/ram.md:99`) and genuinely differs between the legs —
`test_mister_tenant_oracle` **already excludes the P2 fields BY NAME for this
exact reason**, and I had that fact in front of me before I ran anything.
Most of the list is the opponent's sprites.

What rescues the surface: an OBJ list cannot be filtered "by P2" the way a
field table can — **sprites carry no owner** — but OUR content IS labelled.
**y bit 12, the CPS-2 Turbo promote, is set on exactly the group-C sprites
this port adds and on nothing vanilla can emit.** So the promoted subset is
ours, is lottery-free, and must agree exactly; the remainder is REPORTED,
never asserted.

**THE LEGACY CONTROL WAS RUN AND IS ALSO CONFOUNDED — recorded so it is never
read as evidence.** `05_timeout_idle` is 1P arcade too, so it draws different
opponents as well (counts agree 52/57 vs 61, codes barely overlap). **A clean
WHOLE-list comparison needs a PINNED OPPONENT, which needs P2 scripting in
`SimInputs` — still the deferred COVERAGE item, and now with a concrete
reason to want it.**

### THE FIELD TEST HAD NO CONTROL

The bundle shipped one MRA, so any failure — black screen, boot loop, wrong
art — would have been indistinguishable between "our profile is wrong" and
"the bitstream, the card, the SDRAM module or the video chain is wrong".
By this project's own standard that is not a measurement. Added (outside the
repo, rule 7): the **STOCK CONTROL MRA** (vanilla `vsavj` on the SAME `.rbf`
with the profile bit at the `0xFF` fill — verified, the file names
`<rbf>jtcps2w` and contains no `0xFE`), `games/mame/vsavj.zip`, and
`FIELD_TRIAGE.txt` (nine symptoms, each with meaning and next action).
**Measured on the way: pointed at the bundle as shipped the control MRA loses
8 of its 22 parts** — four patched art members AND four program members — and
jtframe `0xFF`-FILLS an unresolved part rather than refusing, so it would have
"run" and shown nonsense.
**The pre-D5 boot loop converted to something usable at a board: ~26.5 s** at
the real 59.6374 Hz (`8 MHz / (512*262)`, MAME `cps1.h:39-45`).

### RETRACTION DISCIPLINE — THE SWEEP HAS TO LEAVE THE TREE

The bundle README's item 5 called the identical 128 KB "scroll tilemap", said
the layer-enable registers were undocumented, and invited treating a
wrong-looking background as "the first hard evidence either way". All three
were corrected LATER in 14z-108 than the README was written. **The bundle
lives OUTSIDE the repo, so the CLAUDE.md §5 grep over `docs tests` could never
have found it.** When a claim is corrected, the sweep must reach artifacts
that have already left the tree.

### NEW INSTRUMENTS, all with must-fire controls

- `tools/check_mra_parts.py` + `tests/test_mra_parts.sh` (ci_portable, ROM-free)
- `tools/oram_obj_records.py` + `tests/test_obj_records.sh` (~2 min, MAME only)
- `tests/test_mister_obj_oracle.sh` (~65 min; `--sim-dir/--mame-log` re-analyse
  finished runs). **Its page selection does NOT hard-code a buffer:** CPS-2
  ORAM is double-buffered with a runtime page select
  (`main_addr_x[13] = main_ram_addr[15] ^ obank`), so it walks both and lets
  the comparison choose. Hard-coding a page is how a phase difference gets
  reported as a content difference.

### PUSH STATE

`origin/main` holds **`613db08`** (verified with `git ls-remote`, not a
tracking ref). The fork README commit `c97e3d14` was **deliberately NOT
pushed** at the maintainer's instruction, and the main-repo commit that bumps
the `emu/jtcores` pin to it is therefore held back too — publishing it would
point public `origin/main` at a fork commit the fork remote does not carry.
**Push the FORK first, then that commit — never that commit alone.**
**[RESOLVED 2026-08-26: the maintainer authorised the fork push. Done in
that order — fork `c97e3d14` first, then the pin bump. `origin/main` now
holds `10cf9ce` and NOTHING is local. The ordering rule above is kept
because it is the general lesson, not because anything is still stranded.]**
The two
commits were reordered (disjoint by file) so everything else could ship; the
resulting tree hash was verified byte-identical before each push.

### VERIFICATION

`tests/run_all_static.sh --strict` GREEN at the session open (PASS 107) and
after the changes (**PASS 108**, SKIP 0, FAIL 0, MISSING 0), with the tree
clean under the run — the 14z-108 discipline (commit first, then run, then do
not type) followed this time.

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

- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** Recorded as FUTURE, UNPLANNED work — nothing scheduled.
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
- **OPEN (cosmetic):** Huitzil's win QUOTE text — root-caused, not built.
  The consumer's `lea -4(a0,d0.w)` bias means it reads index 0x60+id-1.
- **OPEN:** FG pacing — untouched.

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
