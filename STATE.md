# STATE — living progress log

## Session 14z-106 CLOSE — ritual complete

The session, in one line: housekeeping executed (evidence committed,
probes attic'd, the 14z-102 attic deleted); the MiSTer framing and all
five alignment questions ruled and recorded; the arc OPENED with no RTL
touched — GPL-3.0 licence, the public jtcores fork with the separate
`jtcps2w` core pinned and gated (twin proof: the vsavj MRA identical to
stock except `<rbf>`), the fit numbers measured (a wider GFX tier is
unavoidable: 6.39 MB of roster art vs 0.49 MB blank in vanilla; no XL
tier exists — retracted), and the Verilator lane proven on macOS at
~1.4 s/frame with the `.rpl` translator gated.

Ritual: STATE (this + entries (2)-(4)); NEXT_SESSION rewritten (banner
carries the whole arc state + the opener); HANDOFF MiSTer block + docs
index; GOTCHAS: none paid beyond what mister.md's recipe records
(four failed sim attempts, each a missing GNU tool or module — recorded
there rather than as a gotcha because the recipe IS the fix); suite
`run_all_static --strict` PASS 100/0/0 at the slice-A commit (the
translator gate registered after that run; it passes alone — counts
next run, 101). Four commits LOCAL (b4a7d15, 1622522, 0d16a0b, ad25cdc);
PUSH pending the maintainer's word.

**Decisions pending for the maintainer:** THE MiSTer PROFILE SHAPE
(recommendation: WIDE v1 verbatim on a 128 MB tier). Next opener: the
RAM comparison at a §4 anchor on the STOCK core (mister.md recipe; the
`-setname`/sdram-reuse question first). Model note (maintainer asked):
the opener is mechanical — any current model; the RTL width surgery
waits on the ruling anyway.

## Session 14z-106 (4) — SLICE C: THE SIMULATION LANE WORKS ON macOS
## (stock jtcps2 running vsavj under Verilator, frames rendered, ~1.4 s
## per frame); the translator + its gate landed; the oracle COMPARISON
## itself is the next session's opener

- **Recipe proven** (`docs/platform/mister.md` "Recipe"): brew go coreutils
  gnu-sed xmlstarlet verilator imagemagick; modules fx68k/jt12/jt51/
  jteeprom/jtdsp16 (setup_jtcores.sh now inits all five); `~/.mame/roms`
  symlinks to `$ROMDIR` (outside the tree); `jtframe mra cps2w` builds
  `rom/vsavj.rom` (scratch only); `jtsim -verilator -sysname cps2 -setname
  vsavj -load -video N` from `cores/cps2/ver/game` IN A SCRATCH CLONE
  (never inside `emu/jtcores` — jtsim litters the core dir). Four
  attempts to get there, each a missing GNU tool or module, all recorded.
- **Measured:** Verilator builds the core; the ROM download takes 462
  simulated frames (10'43" wall, once — dumps `sdram_bank0-3.bin`); a
  492-frame run = 11'20" → **~1.4 s/frame**; `frame_00480.jpg` shows
  sprites — vsavj runs. The harness prints `ERROR: SDRAM rd/wr inputs
  should be zero during initialization` every run and continues (upstream
  behaviour; noted, not chased).
- **`tools/rpl2siminputs.py` + `tests/test_rpl2siminputs.sh`** (ci_
  portable): `.rpl` → jtframe v1.7.3 `sim_inputs.hex` (one hex word per
  frame, applied entering blanking; P1 + 3 usable buttons — button 4
  doubles as dip_test; NO P2). Refuses what the harness cannot express,
  loudly. Of the legacy replays, `01_attract_long` and `05_timeout_idle`
  translate; `04_select_fuzz` / `02_demitri_vs_cpu` refuse on button 4.
  Extending `test.cpp` (P2, 6 buttons) is fork work when needed.
- **NOT DONE — the comparison:** running a translated replay to a §4 sync
  anchor with `JTFRAME_SIM_IODUMP`, extracting the 68k work-RAM window
  and comparing against the MAME expectation. Hours of simulation; it is
  the next opener, with the `-setname`/reload question first.

## Session 14z-106 (3) — THE MiSTer ARC OPENED: slice A (fork scaffold +
## licence) DONE and gated; the twin proof measured; no RTL touched

**Slice A, executed (maintainer rulings 2026-08-22: 128 MB SDRAM; GPL-3.0
for everything; fork under their GitHub; core name `jtcps2w`):**
- `LICENSE` (GPL-3.0, FSF text) + README "Licence"; the pending decision
  marked DECIDED.
- **The fork:** https://github.com/DefinitelyFrenchName/jtcores (public,
  GPL-3.0), branch `vampire-saved` from upstream tag `v1.7.3` =
  `63688ce5`; one commit `b9d0565` = `cores/cps2w/` — `cfg/` a twin of
  `cores/cps2/cfg` with `CORENAME=JTCPS2W`, `game.yaml` VERBATIM (every
  `from: cps2` still resolves to cps2's hdl — the cps15 precedent), the
  MRA set restricted by `mustbe.machines=["vsav"]`, msg + README.
- **Pinned here:** submodule `emu/jtcores` (branch `vampire-saved`, 235 MB;
  jtdsp16 `87fef51d` inited; `modules/jtframe/target/pocket` is a PRIVATE
  ssh submodule — never init it); `tools/setup_jtcores.sh` (literal pin +
  pristine check + jtdsp16 init + Go build + regenerates the mirror
  `emu/jtcores-patches/0001-cps2w-scaffold.patch` = `format-patch
  v1.7.3..pin`); gate `tests/test_jtcores_twin.sh` (ci_portable: pin,
  game.yaml identical, macros/toml deltas EXACT, patch mirror == format-
  patch, must-fire control) PASS 7/7.
- **THE TWIN PROOF (measured):** jtframe's Go tool built (`go build`;
  the bash wrapper needs GNU coreutils — call the binary; env JTROOT/
  JTFRAME/JTBIN/CORES/ROM). `jtframe mra cps2` → 316 MRAs; `jtframe mra
  cps2w` → 7 (the vsav family only). The `vsavj` MRA from the two cores
  is byte-identical except `<rbf>jtcps2</rbf>` → `<rbf>jtcps2w</rbf>` —
  the reference-leg MRA exists and binds stock vsavj to OUR rbf, which is
  the stock leg of the emulator superset invariant on FPGA.
- **Facts read from the tree** (`docs/platform/mister.md`, new; indexed in
  docs/README.md): jtframe is VENDORED at v1.7.3 (not a submodule); the
  RBF name is `"jt"+<core dir>`; `JTFRAME_SDRAM_LARGE` = `SDRAMW=23` (64 MB)
  and **there is NO XL tier** (RTL grep, 0 hits — the cps2_wide.md claim
  RETRACTED in place); MiSTer's HPS exposes `ioctl_addr[26:0]` (128 MB)
  while the core-facing port is `[25:0]`; 68k ROM bus `[20:0]` = 4 MB;
  stock vsav already uses the full 32 MB GFX on jtcps2; the sim lane has
  per-frame `.cab` input scripts + IOCTL/SDRAM dumps (the `.rpl`/RAM-
  checksum twin) and jtcores' own `reg.yaml` regression lists `vsav`.
- Go installed (`brew install go`, 1.27). Static suite re-run at close.

**SLICE B EXECUTED — `docs/project/mister_fit.md`, the numbers:**
- PRG: live extension `0x400010-0x4D10F3` (+ the 30-byte facing-alias
  thunk PINNED at `0x5FFF00`, which is why `vsw.44` is written while
  `vsw.43` is empty) → the image needs **4.82 MB**, deficit vs jtcps2's
  4 MB bus **836 KB**.
- QSound: extension content 918 KB = banks **0x80-0x8E**, all in the
  jtcps15 aliasing class → the width fix is REQUIRED, not optional.
- GFX — **THE DECISIVE NUMBER:** the roster's group C is **52,347 live
  codes = 6.39 MB** (bank 4 45,737 + bank 5 6,610, `audit_gfx_merged_
  census` PASS); vanilla's entire 32 MB holds **4,028 blank tiles =
  0.49 MB** (per-bank census via `gfx_tiles.BLANK`; bank 1's 2,917
  reproduces the 14z-62e figure). 13x short — and no tenant-dropping
  variant fits either (the smallest band alone is 3.5x the blank total).
  **A MiSTer build of this roster REQUIRES a GFX tier wider than 32 MB.**
- Recommendation (Decisions pending below): **WIDE v1 VERBATIM on MiSTer**
  on the 128 MB module — the MiSTer work becomes pure WIDTH (SDRAMW
  23→24 + bank/prog/ioctl +1 bit + the core's buses), no content
  re-layout, one romset for all three implementations, zero gameplay
  consequence.

Instruments the exploration located, for the record: `tests/audit_gfx_merged_
census.sh` (as-built bank4 45,737 / bank5 6,610 of 65,536; all four pools
empty), `build/m3b_merged13/gen.log` (wide_ext high-water `0x4D1100`,
1.24 MB spare — but `vsw.44` is WRITTEN while `vsw.43` is empty, so the
extent is NOT the cursor; measure before quoting 5 MB), `tools/obj_
records.py` / `build/manifest/gfx_layout3.toml` for the static bands.

## Session 14z-106 — HOUSEKEEPING (maintainer-ruled), then the MiSTer
## alignment brief (no core work until the questions below are answered)

**Housekeeping, each item ruled by the maintainer 2026-08-22:**
- The 14z-105 verification evidence committed: 15 `build/*_w6*.log` +
  `merged13_gates*.log` (suite x3, static x3, battery, soak, m3a,
  propose, freeze builds) and `build/guard_corpus/m3b_merged13.
  1787401830.tsv` (the 316/316 soak) — precedent: freeze-evidence logs
  and the merged11/12 guard TSVs are tracked.
- The rehearsal probes `build/merged_probe_w6` (155 MB) +
  `build/probe_stock_w6` (71 MB) moved to **`../build_attic_14z105`**
  (reversible; 0 tracked files inside; every reference is prose and now
  annotated — HANDOFF x2, patch_notes, test_m3a_reproducible's comment).
- **`../build_attic_14z102` (8.1 GB) DELETED** — the 14z-102 policy
  condition ("after the next playtest cycle confirms nothing is missed")
  was met twice (14z-103, 14z-105). Recoverable via git history + tags.
- `emu/fbneo` "modified content" is NOT litter: `git apply --check -R`
  reverses both `emu/fbneo-patches/0001` and `0002` cleanly, so the
  submodule carries exactly the applied harness + WIDE patches.
- One-back dirs (don_m10 / hui46 / pyron30 / m3b_merged12 / m5_stock5)
  stay — the N-2 policy fires at the NEXT freeze.
- Tracker check: every ticket the NEXT_SESSION history tail still lists
  as open backlog (#10/#18/#19/#20/#22/#25/#28/#31/#38/#42/#77/#93/#94/
  #100) is CLOSED on GitHub; `gh issue list` is empty. Nothing queued.
- Verification: ROM audit 76/76 clean; `run_all_static --strict` on the
  pruned tree **PASS 99 / SKIP 0 / FAIL 0** (strict makes a lost input
  fatal — nothing depended on either attic). Log: `build/static_14z106.log`.

**DECIDED (maintainer, 2026-08-22): THE MiSTer FRAMING.** The MiSTer
deliverable is an **EXTENSION OF JOTEGO'S jtcps CORE** — not an FPGA
re-implementation of the MAME emulation. This agrees with and sharpens
the 2026-08-15 ruling (STATE_HISTORY "MiSTer = CORE SURGERY ONLY": PRG-cap
lift + the QSound width fix + a MiSTer-shaped WIDE profile, GFX <= 32 MB).
The alignment questions are under "Decisions pending — MiSTer alignment";
no RTL is touched before they are answered.

## Session 14z-105 CLOSE (final) — ritual complete

The session, in one line: the maintainer-directed window executed end to
end — the Oboro select hook (vanilla's Gallon-variant idiom one cell
over; the Start bit measured before authoring) and the "M6" version mark
(authored glyphs, pixel-exact; the tile codec's 14-session half-mirror
found and fixed on the way) — frozen as donovan-m11 / huitzil-m20 /
pyron-m14 / merged-m6 with every gate and both soaks green, field-
confirmed ("Tests confirm Oboro Bishamon and the M6 mark") and pushed;
then RELEASE PACKAGING landed the same session (`release/merged-m6/`, no
ROM bytes, deterministic, verifying applier, gated), ruled in-tree until
MiSTer, pushed.

The ritual's items, each done this close:
- **STATE**: this entry; the ROLLOVER executed (the 14z-102 group, 7
  entries, moved verbatim to STATE_HISTORY with a ledger line; verified
  lossless by byte-verbatim + size accounting).
- **NEXT_SESSION**: rewritten (the window shipped, the codec finding, the
  dead prediction, packaging done + the in-tree ruling; MiSTer next).
- **HANDOFF**: current-builds block, registry row, gate rows, the release
  packaging section, SUITE_ONLY.
- **GOTCHAS**: one paid (platform: the gfx_tiles half-mirror / pen 15 /
  OBJ->screen offsets).
- **patch docs**: patch_notes 14z-105 section; patch_index rows + the
  packaging tooling paragraph.
- **Issues**: none opened; tracker clean.
- **Suite**: run_all_static --strict PASS 99/0/0 at close (97 -> 99:
  test_gfx_tile_codec, test_release_roundtrip).
- Everything pushed; the tree is clean.

Where the next session starts: NEXT_SESSION's banner — MiSTer core
surgery (the maintainer's sequencing: packaging first, done).

## Session 14z-105 (2) — RELEASE PACKAGING (maintainer: packaging
## before MiSTer; "why not this session") — `release/merged-m6/` built,
## gated, deterministic; no ROM byte in the package

**The design constraint first (rule 7):** the WIDE members (`vsw.*`) are
NEW files made largely of vs2/vhunt2 content, so a patch "against
nothing" would embed ROM bytes. Every delta is therefore computed by
xdelta3 against ONE source blob — the four reference dumps' members
concatenated in a fixed documented order (sha1 954d883c…) — so copies
out of any dump are copy instructions and only generated/authored bytes
are literal. Secondary compression OFF so the scan below sees the
payload. Measured: 20 patched members (the four vm3j program members,
the twelve vsw.* WIDE members, and vm3.13m/15m/17m/19m — four GROUP-A
gfx members the effect-tail anchors write, so the rompath `vsav.zip` is
NOT entirely pristine; the 14z-62e option-A prose that said so is
corrected in place) + 22 pristine copies; 2,592,654 patch bytes total.

**Tools:** `tools/package_release.py` (deterministic — two runs byte-
identical), `tools/apply_release.py` (shipped in the package; verifies
every reference member, rebuilds the source, applies, refuses to write
unless every target sha1 matches). **Gate `tests/test_release_roundtrip.sh`
(ci_static) PASS:** 42/42 members byte-identical after the round trip,
fingerprint 64426955 + whole-artifact manifest reproduced; corrupted
patch / wrong target sha1 / one-bit-wrong dump each REFUSED with nothing
written; rule-7 scan: 2.59 MB of patch bytes against 1,384,723 indexed
64-byte reference chunks, zero hits, must-fire control caught (2 hits).
Dependency: `xdelta3` (brew install xdelta) — the gate SKIPs without it.

**Release unit decision (mine, open to veto):** merged-m6 only — the
solos are instruments, the stock twin is never distributed.
**RULED (maintainer, 2026-08-22): the package stays IN-TREE until
MiSTer; a tagged GitHub release then covers both.** Pushed.

## Session 14z-105 CLOSE — the freeze is GREEN end to end; commits
## LOCAL, awaiting the maintainer's field test before push

**Every verification of the 14z-105 freeze, final:**
- run_suite: the three solo sets re-frozen (SUITE_ONLY targeted freeze of
  the 9/10/11 self-frozen `.sha1` replays — every select-reaching tenant
  replay moved, as the two added sprites require) and then the FULL
  unfiltered verify on don_m11 / hui47 / pyron31: **SUITE GREEN x3**, 0
  FAIL, 0 NONDETERMINISTIC; all 148 window/composite specs on their
  frozen lines.
- test_m3a_reproducible: all five artifacts rebuild bit-exact on the new
  pins; whole-artifact manifests match (42/30/42/42/42).
- Merged gates on m3b_merged13: test_version_string, test_oboro_select,
  test_wheel_bank5 (AUTHORED 2), audit_select_bank_gates,
  audit_roster_pairings 111/111, test_tenant_pairings 6/6, audit_trap_
  parity, audit_fg_parity (native-parity), audit_clone_beam_lines,
  audit_hui_grunt, test_dualtrack (frozen onsets held), test_fbneo_
  legacy_oracle (frozen offset inventories held), test_merged_render_
  content (bands byte-equal to the NEW solos) — ALL PASS.
- Static: test_pcrel_escapes (solo + merged, control alive),
  test_region_overlap (2033 held), test_pointer_flow (4 new baselines),
  test_escape_triage (re-frozen, verdicts identical), test_manifest_merge
  (re-pinned), test_tenant_loop (re-pinned), test_gfx_tile_codec (new).
- run_all_static --strict: **PASS 98 / SKIP 0 / FAIL 0** (the suite grew
  97 -> 98: test_gfx_tile_codec). An earlier run showed 2 FAILs that were
  a RACE with my in-flight edits (the manifest_merge pin landing mid-run;
  tenant_row_owner edits the generator in place) — both PASS alone and
  in the clean re-run.
- run_battery_m2: 23 PASS + the wide-render self-skip, which was then
  run directly on the m5_stock6/don_m11 pair: PASS (the 14z-102 shape —
  effectively 24/24).
- audit_guard_corpus and audit_merged_legacy: run AFTER the close entry
  while the maintainer tested — both PASS (see the post-freeze note).

**Post-freeze, while the maintainer tests (2026-08-22):** the Oboro pick
measured on FBNeo too — id 0x18 / base 0x0B3450 with Start, 0x08 /
0x0A6418 without, field-for-field what MAME reads (the §4 dual-emulator
agreement for new content); frozen as leg F of test_oboro_select.sh.
The two long soaks were then run: **audit_merged_legacy PASS (rc=0)** —
leg a 47/47 legacy replays on their exact frozen classes, leg b guard-
clean vs the new solos; **audit_guard_corpus PASS — 316/316 guarded runs, zero vectors** on merged-m6 under every tenant forcing. Every verification the 14z-102 freeze had is now green on 14z-105 too.

**FIELD-CONFIRMED AND PUSHED (maintainer, 2026-08-22):** "Tests confirm
Oboro Bishamon and the M6 mark." Observation recorded: Oboro's pre-match
INTRO is very long — vanilla vsavj's own boss intro, not ours, and he is
not tournament-legal, so accepted as-is (no item). main + the four
freeze tags pushed (cfb6bd3..f1db172).

**Where the maintainer looks:** `tools/run_wide.sh build/m3b_merged13
fbneo` — "M6" bottom-right on select; Bishamon + Start held -> Oboro.

## Session 14z-105 — THE WINDOW EXECUTED: W1 THE OBORO SELECT HOOK +
## W2 THE VERSION STRING, one freeze — donovan-m11 / huitzil-m20 /
## pyron-m14 / merged-m6 (maintainer "happy with the plan, I'll test
## before we push", 2026-08-22). Every gate that has finished is GREEN;
## the suite re-freeze and the long merged batch run at close.

**The opening measurement (RH-1, before a byte was authored):** on
vanilla vsavj, with P1 Start held on the select screen, the player
struct's input word `+0x394` reads `$8000` (`$0000` without) — so the
`btst #7,$394(a6)` in vanilla's Gallon-variant confirm path at
`PRG:0x020B9C` IS the Start test, and the template is exact; `$FF8060`
reads 1 at the same time (the 14z-104 "is it live at select?" question:
yes). The committed id stays 0x08 on vanilla (no Oboro path, as
expected).

**W1 — `oboro_select_hook`:** a 30-byte profile-gated `site_thunk`
displacing the `cmpi.b #$2,$382(a6)` at 0x020B9C: Bishamon? / Start? /
`move.b #$18,$382(a6)` / re-execute the displaced cmpi (its flags feed
vanilla's `bne`) / rts. Declared identically in all three manifests
(ENGINE-SITE, deduped to one; +2 ops at every N). Generator gained a
`profile` key on site_thunk (mirrors select_wheel/sound_table; inert
for every existing row) and `id_literal_ok` carries the deliberate
0x08/0x02 compares. MEASURED on the probe and frozen as
`tests/test_oboro_select.sh` (5 legs): P1 hold -> 0x18 + base
`0x0B3450` in-match; no-hold -> 0x08 / `0x0A6418`; Start on Demitri ->
0x01; P2 (default cell 0x05, D D L L) -> 0x18 / `0x0B3450`, P1
untouched; STOCK twin -> 0x08. Stock rebuilt under the new rows =
`883e7d17` = m5_stock5, whole-artifact manifest identical (30/30).

**W2 — the version string:** `version_text/font/x/y/pal/base` knobs on
`[[select_wheel]] roster21` (all three manifests, identical); the
generator appends one 1x1 glyph entry per character to the copied
wheel record (count 20 -> 22, budget 0x55 carried over and now
asserted >= entries) and encodes `build/manifest/version_font.json`
(5x7, 0-9 A-Z - . space, authored, NEW provenance) 2x into 16x16
tiles handed to build_gfx through `wheel_bank5.json["authored"]`
(place() same-source-or-fail; audit_gfx_merged + check_wheel_bank5
know the kind). "M6" at screen (340,202) — the empty bottom-right
corner, chosen from snapshots — pal row 0x19 (Phobos' medallion row,
thunk-re-asserted every select frame, ink pen 7 = 0xFF8), codes
0x1FE40/41 (free in the merged-m5 group C ledger). 0 ops.

**THE CODEC FINDING (platform gotcha, gate `test_gfx_tile_codec.sh`):**
the first probe drew the glyphs MIRRORED per 8-pixel half inside an
opaque black box. The OBJ list had the sprites exactly where intended
(x=0x194/0x1a4, y=0xCA, bank 5, pal 0x19, codes fe40/fe41), so the
defect was in the tile bytes: `gfx_tiles.decode` had mapped plane bit i
to pixel i since the module was written, and nothing had ever consumed
pixel ORDER (cmd_match and BLANK compare raw bytes) — the first tile
this project ever SYNTHESIZED exposed it, and only because "M6" is not
symmetric ("M" looked right). Fixed both ways (bit i = pixel 7-i),
transparent pen 15, and the OBJ->screen transform measured as
(x-64, y-16). Re-probed: the MAME snapshot pixel-matches the intended
bitmap with ZERO mismatches at (340,202) and zero opaque pen-0 pixels
(`tests/test_version_string.sh` §2 — the render-layer check that a byte
round-trip cannot replace).

**The freeze (the 14z-99/102 rhythm):** op counts re-frozen with
attribution (325/365/298; 600/652; 806/907); `build/merged_probe_w6`
rehearsed, then don_m11 `1de9a027` (325) / hui47 `24a27940` (365) /
pyron31 `6bf265ab` (298) / m5_stock6 `883e7d17` (UNCHANGED) /
m3b_merged13 `64426955` (806, BIT-FOR-BIT the probe) built from the
tree; expectation sets carried-renamed m10->m11, m19->m20, m13->m14 +
registry rows; m3a pins + whole-artifact manifests moved (attributed:
program members + the four GROUP C members = the glyph tiles; no
QSound member). **Placements moved:** the thunk allocates per tenant
iteration ahead of the regions, so every huitzil placement is +0x10
and every pyron one +0x30 — bases.tsv re-derived from merged13's own
table (phobos 0x4595b0, pyron 0x4ac90c, donovan held), pcrel
[merged_*] + solo sections re-pointed (inventory unchanged 69/10/10),
pointer_flow baselines re-frozen for all four (the +1 `data:long` is
the record's count word; the merged pairs had silently stayed on
merged11 since 14z-100 — the #94 class, now current). The standing
re-point sweep executed: ~70 BUILD defaults (the m3b_merged11
one-back set, the 14z-103/104 audits, tripwire/guard-corpus/
projectile-clash, dualtrack, render-content D/H/P, region_overlap trio
(section 5 re-measured: still 2033), identity PLAY pin, battery stock
path, voice_row_range, hui_grunt per-build row, decode_stage_banners'
donovan clean leg).

**Green so far on the new artifacts:** test_oboro_select,
test_version_string, test_wheel_bank5 (AUTHORED 2), audit_select_bank_
gates, test_pcrel_escapes (solo + merged, control alive),
test_region_overlap, test_pointer_flow, test_tenant_loop, test_gfx_
tile_codec; m3a_reproducible and the long merged batch (roster
pairings, tenant pairings, trap/FG parity, clone-beam lines, hui grunt,
dualtrack, FBNeo oracle, render content) + the three run_suite
re-freezes run at close — results in the CLOSE entry below.

**Re-freezes the window forced, each attributed:** `test_manifest_merge`
site_thunk counts (19,14,6)/30/5 -> (20,15,7)/31/6 (one row per manifest,
dedupes to one); `tests/expected/escape_triage.txt` re-frozen in the
gate's sorted form — the 25 verdicts are IDENTICAL, only the merged
addresses moved (+0x10/+0x30) and with them the sort order;
`test_region_overlap` section 5 re-measured UNCHANGED (2033).
**The select-window specs did NOT move:** `propose_masked_specs` over
all 148 window/composite specs of the three carried sets proposed the
frozen line verbatim — the 14z-104 prediction ("more sprites shift the
window end") is retracted; the end is the VS-phase re-init. Only the
self-frozen `.sha1` replays were re-frozen, via a new `SUITE_ONLY=`
authoring filter on `run_suite.sh` (prints FILTERED; never a verdict —
the acceptance is the unfiltered verify run, which ran for all three
builds at close).

**N-2 policy applied (the 14z-102 standing rule):** build/don_m9,
don_m9_s4, hui45, pyron29, m3b_merged11, m5_stock4 deleted (tracked
metadata removed in this commit; recoverable via git history + the
freeze tags); every live reference had been re-pointed first (only a
per-build history row in audit_hui_grunt and a docstring still name
them). The rehearsal probes merged_probe_w6 / probe_stock_w6 stay
(evidence; the next attic pass takes them). [DONE 14z-106: moved to
`../build_attic_14z105`.]

**Retractions executed (grep'd):** "no in-game version string" (platform
gotcha §3 + test_build_identity_distinct header); "Oboro's entry path
is unlocated" qualified in id_space.md / select_screen.md — VANILLA's
stays unlocated and irrelevant; the port has its own. 0x18 stays
RESERVED for tenants (it is Oboro's).

## Session 14z-104 CLOSE — ritual complete

The session, in one line: the §4 coverage debt was RETIRED end to end
on the maintainer's direction (ten new audits, every matrix cell green
on merged-m5, four native-anchored mechanics discovered — Phobos'
untechable sweep, his no-kill half-restore throw, Donovan's
tech-neutral throw, the draw code 0x00), the pursuit mechanic was
found+instrumented after the maintainer supplied the grammar, the
Oboro question was answered with a live demonstration (vanilla vsavj
ships him complete at 0x18; selection is one profile-gated hook), and
the next session's WINDOW (Oboro hook + version string, one freeze)
is completely specified in NEXT_SESSION.

The ritual's items, each done this close:
- **STATE**: this entry; the ROLLOVER executed (the 14z-101 group, 10
  entries, and the 14z-100 group, 4 entries — 41.6 KB — moved verbatim
  to STATE_HISTORY with ledger lines; verified lossless: the rolled
  blob is byte-verbatim in the archive and a line-multiset diff against
  the pre-rollover file accounts for every line; STATE 133 KB -> 92 KB;
  the SPLIT convention paragraph re-homed between the groups and THE
  LEDGER).
- **NEXT_SESSION**: rewritten at the (4) close — the banner is the
  complete window spec (W1 Oboro hook, W2 version string, the freeze
  tail incl. the standing re-point sweep additions).
- **HANDOFF**: the §4 coverage-program block current (all ten audits).
- **GOTCHAS**: three paid this session-pair (gate_failures self-test
  litter; the arcade-draw pin class; per-character rig geometry).
- **patch docs**: untouched — no shipped byte moved in 14z-103/104.
- **Issues**: #110 opened, fixed, closed within the pair; tracker
  clean (zero open).
- **Suite**: full strict static tier green at this close (see the
  commit); every new audit green on merged-m5 in-session.
- Commits LOCAL from 6d80e72 onward — push on the maintainer's word.

Where the next session starts: NEXT_SESSION's banner — the window.

## Session 14z-104 (4) CLOSE — COVERAGE GAP 2 CLOSED (the §4 matrix is
## fully green), THE WINDOW PREPPED (Oboro hook + version string, the
## complete spec in NEXT_SESSION), session closes on the maintainer's
## instruction with the window as the next session's opening arc.

**Rulings recorded (maintainer, 2026-08-22):** coverage items 1+2 GO
(both now done); Shadow/Marionette OUT OF SCOPE for now; the OBORO
HOOK + the VERSION STRING ride ONE window with whatever select-spec
movement they cause; vanilla-vsavj Oboro confirmed as the want ("we
indeed have nothing to port... if and only if it can be selected" —
answered with the live demonstration, 14z-104 (3)).

**Gap 2 (audit_edge_cases.sh, 15 legs green on merged-m5):**
- KO DURING CAPTURE both directions: every tenant kills mid-throw and
  dies mid-capture with the judge settling (winner 0xFF) — EXCEPT
  PHOBOS AS THROWER: his throw CANNOT kill — the would-be KO converts
  to a transient death flag + an HP RESTORE to exactly half (144/144)
  with no round transition, and NATIVE vsav2 measures the IDENTICAL
  frame shape. The third native-anchored grab-family property (beside
  his untechable sweep and Donovan's tech-neutral throw).
- DOUBLE KO: mirror matches at 1 HP with same-frame jabs TRADE, and
  the judge writes the DRAW code — $FF8120 == 0x00 measured, the
  winner byte's third value (atlas row updated).
- FRAME-1 EX: the DP+2K input on the first live frame — Phobos and
  Pyron FIRE their EX from frame one (stock decrements); Demitri and
  Donovan produce an action without a spend (their EX grammars
  differ); frozen per leg.

**The window prep (complete spec in NEXT_SESSION):** W1 the Oboro hook
(Gallon-path template PRG:0x020B9C, Start source $FF8060 with a
verify-at-select first measurement, profile-gated site-thunk, probe
rehearsal, 0x18 QA legs); W2 the version string (select-screen
placement inside the ratified window; wheel-record extension via the
existing [[select_wheel]] copy machinery; vanilla-font-tile hunt vs
authored group-C blob; manifest knob; the exact text is the
maintainer's call at the window). The freeze tail moves every WIDE
artifact; stock must stay bit-identical (both features profile-gated).

## Session 14z-104 (3) — COVERAGE GAP 1 CLOSED (tech roll + throw
## tech, both directions, native-anchored where the answer surprised),
## and THE OBORO QUESTION ANSWERED WITH A LIVE DEMONSTRATION.

**Tech roll (audit_tech_roll.sh, 9/9 green on merged-m5):** the roll =
HELD direction+button through the knockdown landing (a tap does NOT
register — control leg); every tenant rolls out of a knockdown
(147/120/120px — their ported recovery states executing); the legacy
roll works off don/pyr knockdowns; **Phobos' crouch-HK knockdown is
UNTECHABLE — and native vsav2 measures the identical 14dmg/no-roll**,
so it is a ported design property, frozen native-anchored; the
maintainer-described PURSUIT-VS-ROLL counter measured working (leap
fires, victim rolls 144px, the strike whiffs the vacated spot) — the
WHIFF half of the pursuit-connect question is now gated.

**Throw tech (audit_throw_tech.sh, 8/8 green):** the tech = the
victim's own throw input held from grab-connect+2 (same-frame input is
the separate throw-vs-throw whiff event, deliberately excluded);
damage halves — every tenant escapes Demitri's throw at the uniform 7;
Victor techs Phobos 14->7 and Pyron 12->2; **Donovan's throw measures
5/5 IDENTICAL with and without the tech — and native vsav2 measures
the same identity**, frozen as the native-anchored tdon expectation.
No-tech control at the full 13.

**Oboro (maintainer question "can it be selected?", answered live):**
vsavj has NO player-facing select path (the atlas's unlocated-entry
hole = the boss-encounter logic), BUT the commit path accepts 0x18
end-to-end TODAY: poked at select on merged-m5, Oboro loads his own
native dataset (+0x60 = 0x0B3450, the bases.tsv row) and fights
(snapshot sent — the pale colorway). The Start-hold hook is exactly
the existing flavor-latch idiom writing 0x18 on Bishamon's cell —
selection is OURS to add and is small, profile-gated, freeze-window
work. vs2's Oboro dataset diffs vsavj's by only 685/8192 sampled bytes
(the cross-game operand-shift shape) — vanilla-Oboro-as-shipped is the
fidelity-default recommendation.

Remaining coverage: item 2 only (deliberate KO-frame/corner/frame-1
edge rigs — next stretch); pursuit-connect's hit half.

## Session 14z-104 (2) — THE PURSUIT ANSWERED AND INSTRUMENTED: the
## maintainer confirmed the NW leaping pursuit (U + any P/K), the
## mechanic was found and measured (my earlier screen missed it by
## inputting AFTER the flat window opened — the input registers during
## the FALL), and audit_pursuit_leap is green on merged-m5: every
## tenant's ported pursuit fires with its own arc, every downed tenant
## accepts targeting.

**Why the 12-candidate screen missed it:** the pursuit input registers
during the victim's knockdown FALL and the first flat frames; my
screen's attempts (3086/3098) came after that window closed for the
sweep knockdown. With the input at f3072 (mid-fall) the leap fires on
every button (U1/U2/U4/U6 identical — universal, as the maintainer
said).

**Mechanics measured (engine_internals "THE LEAPING PURSUIT"):** aim is
captured at INPUT time (proven with a mid-flight victim-position poke);
per-character arcs (Demitri 33f/y100, Donovan 27f/y102, Phobos 42f/y88,
Pyron 39f/y88 — the ported vs2 content executing); corner pursuits peak
over the body then the wall pushbox shoves the attacker off during
descent (measured on the ALL-LEGACY control = vanilla behavior by the
superset invariant).

**The instrument (audit_pursuit_leap.sh, green 8/8):** every tenant as
pursuer (leap fires, airborne, per-char duration band), Demitri
pursuing every downed tenant (their down state accepts targeting), and
the no-knockdown control (the same input with the victim recovered must
NOT enter 0x0E — proves the signature is knockdown-gated).

**The honest open piece — pursuit CONNECT:** a wake-vs-flight knife
edge in every geometry tried (sweep and throw knockdowns, chases,
midscreen and corner, victim-position alignment), INCLUDING the
all-legacy control — so the non-connect is a rig fact, not a port
defect, and asserting damage needs a knockdown whose flat window
outlasts the flight on both games. Carried in the matrix (1b), coupled
to the tech-roll rig family (the roll is the pursuit's designed whiff).

## Session 14z-104 — THE §4 COVERAGE DEBT TACKLED (maintainer-directed):
## the mandate measured cell by cell, six new audits built and green on
## merged-m5, and the matrix documented as a maintained artifact. Four
## rulings recorded. One maintainer question open (the pursuit grammar).

**Rulings recorded at session open (maintainer, 2026-08-22):** cosmetic
/ single-player deferred INDEFINITELY (the matrix judges cells on the
2P-competitive surface); beam color + DF/clone colors GOOD, DF time
GOOD (threads stay closed); the in-game VERSION STRING is APPROVED for
convenience — it moves shipped bytes, so it rides the next natural
freeze window (queued, NEXT_SESSION); release packaging is a real topic
whose before/after-MiSTer ordering stays the maintainer's open
question.

**The census (docs/project/coverage_matrix.md, the maintained
artifact):** measured, not recalled. Found: pursuit attacks had ZERO
coverage anywhere; tenant timeout was field-confirmed only; life-marker
rigs existed for Donovan only; Pyron had no throw rig; tech-hit has no
instrument anywhere. Well-covered: vs-18-both-sides
(audit_roster_pairings, re-run 14z-104: 111/111 on merged-m5), DF
(rigs; the audit was the missing promotion).

**Six instruments built, each with legacy controls + discriminating
negative controls, all green on merged-m5:**
- `audit_df_framework.sh` — the ruled DF table frozen (1 stock,
  360/360/377/360; span-based duration with Phobos' documented
  activation flicker bounded to onset+24).
- `audit_tenant_timeout.sh` — timer poked to 3 ($FF8109), the judge
  must award the down to the HP LEADER: $FF8120 (NEW atlas row —
  round-winner code 0xFF=P1/0x01=P2, verified discriminating both
  directions) + $FF810E (rounds counter). Lead-existence asserted
  (the Phobos jab-whiff would have passed vacuously without it).
- `audit_tenant_downwin.sh` — the KO-path life-marker transition,
  every tenant as WINNER and as VICTIM (the victim legs are the
  direct #103-class lock: a tenant's death must be judgeable); 8 legs
  + no-poke control.
- `audit_tenant_throws.sh` — normal throw both directions; the throw
  discriminator measured (strength-independent 5-dmg toss for Donovan
  vs his 24-dmg groundbound strike); Victor throwing each tenant
  exercises the #104 capture keyframes.
- `audit_down_attack.sh` — the §4 "pursuit" cell: hitting a downed
  opponent, both directions. MEASURED: grounded heavies serve
  (11-14 dmg); per-character windows both sides (Phobos wakes in 24f);
  a 12-candidate input screen produced NO leaping NW-style pursuit —
  the naming question is the maintainer's (a distinct leaping pursuit
  under another grammar gets its own rig if it exists).
- `audit_stage_sweep.sh` — every tenant x all 12 stages WITH contact:
  the $FF8100 poke window measured (f2150/2200 sticks AND the venue
  assets follow; f2450+ sticks without following); 36/36 + no-poke
  + palette-distinctness controls.

**Rigs:** `tests/replays/judge/01_timeout_lead.rpl`, `02_throw.rpl`,
`03_down_attack.rpl` — poke-generic, subdir (gate-owned, outside the
suite's account, so no expectation-set cost).

**Method paid (gotcha, project + index):** per-character rig geometry —
three instances in one session each first misread as a finding (Phobos'
LP whiff; heavies cannot be mashed into a down window; Victor's sweep
throws the victim out of reach). All four combat audits REFUSE to judge
a leg whose setup event did not happen.

**Remaining open cells (the matrix's gap list):** tech-hit (throw
escape) rigs both directions; deliberate KO-frame/corner/frame-1 edge
rigs per tenant; Shadow/Marionette N/A-until-enabled (recorded roster
decision cited, not re-measured).

## Session 14z-103 (2) — #110 FIXED AND CLOSED (maintainer-directed):
## the mechanism was the ARCADE DRAW, not cycle drift; both audits
## re-derived on pinned-opponent rigs and GREEN on merged-m5. The
## Circuit Scrapper report MEASURED: not reproduced on any variant —
## captures sent, awaiting the maintainer's scenario detail.

**Maintainer feedback opened the session** (2026-08-22): projectile
collisions confirmed in line with expectations (closes the freeze's
standing watch item); a POSSIBLE Circuit Scrapper (63214+HP/MP)
animation discrepancy vs VS2 ("might be missing a slam cycle at the
start"), unconfirmed, not gameplay-adverse; and #110 ruled "definitely
fix".

**The Scrapper measurement (confirmation loop, captures sent):**
- Archaeology first: the hold placement is the 14z-73
  grab_hold_keyframes fix (native-exact then); the throw arcs are the
  ported throw_arc_tables superset rows; replay 80's header carries an
  old "throw-arc HEIGHT differs, queued" note that predates the arc
  port. Note test_hui_grab_victim gates only HOLD_LEN=12 frames — a
  missing later cycle would be invisible to it, so the green gate does
  not contradict the report.
- Measured: rig 80 (MP), an HP variant, and a MASH variant, each on
  native vsav2 AND merged-m5 — all six runs STRUCTURALLY IDENTICAL
  (grab f3152, one slam spike y40->180, hold, launch peak y=318,
  damage 19+8), ours lagging by the documented few-frame skew only.
  Full-throw side-by-side contact sheets (every 4th frame, 3152-3268)
  sent to the maintainer. Strength and mashing change nothing on
  either game. NOT REPRODUCED — and CLOSED by the maintainer
  (2026-08-22, "Circuit Scrapper seems fine indeed") after reviewing
  the contact sheets. No item remains.

**#110 fixed (the full chain on the issue, closed):**
- The bisect sharpened by measurement: field-level A/B m6-vs-m7 on the
  fgA rig diverges at MATCH START (opponent spawn X), and the state
  check names it — merged6 fights char 0x0C on stage 0x12; merged7 and
  every build since fight char 0x00 on stage 0x0E ($FF8B82/$FF8100).
  The 14z-87 batch re-rolled the ARCADE DRAW; the audits' frozen
  values described a match no current build runs. The pcosmo leg was
  doubly dead: against the new opponent the rig spends its stock on a
  DIFFERENT move and zero satellites enter $FF9400 (measured).
- The fix removes the class: audit_fg_damage now rides NEW 2P-dummy
  rigs hui/74 + hui/75 (replay-80 scaffolding; opponent+stage pinned;
  EX fires 3/3, damage 69 both legs, bit-identical run-to-run AND
  across merged-m4/merged-m5; EXPECT re-frozen 69/69 with
  attribution). audit_pool_free_byte's pcosmo leg rides
  106_pyron_cosmo_clash (215/215 family slots tagged, vs 0); one
  liveness floor re-calibrated with attribution (b8 +0x00 100->10; the
  +0x20 lane proves the tap). Both audits PASS on merged-m5. The old
  1P rigs are untouched (their other consumers unperturbed).
- Gotcha paid (project + index): a 1P-arcade rig is pinned to the
  arcade draw; frozen-value audits must pin the opponent. The attic
  diff pair is no longer load-bearing.

## Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale
## reference re-pointed, run green, or ruled a deliberate pin), plus
## three findings the pass surfaced: the gate_failures litter class,
## GitHub #110 (two audits red since 14z-87), and four LEGACY replays
## promoted off self-frozen .sha1 (the 14z-88 class, caught by the
## re-pointed audit_legacy_pairings on its first current-set run)

**The opening triage first:** the untracked
`build/gate_failures/03_two_player_vs.<epoch>.log` in git status was
NOT a real gate failure — `test_m2a_flicker_gate.sh` (portable tier)
stubs the emulator and REQUIRES the masked gate to fail, and the gate's
failure path preserved each stub into the shared evidence directory:
141 litter files over five days (140 committed), the newest written by
the 14z-102 close's own portable re-verify 30 seconds before the close
commit. Fixed at the root (`M2A_KEEP_DIR` override in m2a_common.sh;
the self-test points it at its workdir), litter removed by content
signature (basis-identical or ffff-flip lines; the four real July-29
logs and merged1_* evidence kept), gotcha paid (project bucket +
index).

**The A4 pass (docs/project/build_dir_triage.md carries the full
disposition table):**
- Re-pointed to the m10/m19/m13/merged-m5 generation and RUN GREEN
  in-session, each: the hui43 seven (mask_ranges_reader, beam_anim_walk,
  guard_integrity, df_gold, beam_variants, hui_df_style,
  hui_grab_victim) + gfx_layout_fields_live + member_classify +
  voice_row_range; trap_shock/trap_parity (hui37/38 -> hui46);
  variant_dispatch (pyron17 -> pyron30); pyron_blink/pyron_cosmo/
  pyron_ring; flicker_attribution + obj_walker_relocation (don_m7 ->
  don_m10); voice_borrow + gfx_menus pair + legacy_pairings trio +
  frozen_rompath_guard (don_m5 -> don_m10); fg_parity, ladder_selector,
  hui_electrocute, select_bank_gates, merged_render_content,
  build_identity_distinct (m3b_merged/9 -> m3b_merged12); dualtrack
  STOCK/WIDE -> m5_stock5/don_m10 + battery leg + wide_render_content +
  tenant_row_owner; gfx_chain + audit_gfx_merged --build-h (hui31 ->
  hui32, the A2 pipeline input); record_window (hui41 -> hui46);
  m2a_flicker_gate SET pin -> donovan-m10-stock.
- `test_region_overlap` section 5 RE-MEASURED on the current trio:
  2012 -> 2033 conflicting bytes (raw 7603 -> 7624), unique regions
  13 -> 14 — the new huitzil-only #109 row-31 root region; per-span
  (53,54)/(39,50)/(461,368)/(1063,1561); control re-anchored, both
  gates PASS with the must-fire control alive.
- `audit_flicker_attribution` had been SKIPping quietly — its mask pin
  named the REMOVED donovan-m7 set dir. Re-derived to fingerprint
  resolution (the #96 mechanism); PASS on don_m10 (both frozen frames
  still attributed: 41@2313 row-0x0C, 37@7168 row-0x0A).
- `test_hui_grab_victim`: default expectation flipped `differs` ->
  `matches` — the 14z-73 grab_hold_keyframes fix is what it guards
  (patch_index says so; measured Δ=0 on hui46); the default had been
  the PRE-FIX shape since the gate's birth because every freeze ran it
  with explicit =matches. HANDOFF row corrected.
- DELIBERATE PINS ruled and annotated in place: don_m5
  (audit_walker_repoint's un-relocated negative control — nothing newer
  can serve), pyron26 + hui41 (decode_stage_banners' frozen #92 defect
  carriers; only the donovan clean-leg re-pointed to don_m10).
  OPERATIONAL reclassed: build/donovan, donovan_stage4_gate, hui4
  (gates build into them / print the rebuild recipe).

**Finding: GitHub #110 — audit_fg_damage + audit_pool_free_byte RED on
every build since 14z-87**, surfaced by the re-point, bisected on the
attic dirs: merged6 (14z-86) PASS both, merged7 (14z-87 voice-borrow +
beep batch) FAIL both, values stable across five generations since
(fgA 24 vs frozen 10; fgC 0 = the close-range rig no longer contacts;
pcosmo 0 family slots in the frozen window). NOT read as a gameplay
regression: the native-anchored invariants are green on current builds
(audit_fg_parity's staircase, test_pyron_cosmo). Both audits annotated
known-red; constants NOT absorbed — the issue carries the diff pair and
the re-derivation handoff.

**Finding: the 14z-88 class, live again** — `audit_legacy_pairings` on
its first run against current sets flagged 94_tenant_vs_tenant,
103_tenant_2pwin_auto, 105_projectile_clash_ctl, 106_pyron_cosmo_clash
as LEGACY on bare `.sha1` (all four authored AFTER the audit's last
run; under bare suite dispatch their tenant content comes from
gate-supplied pokes that run_suite never applies). Executed the audit's
own fix: vanilla basis EXTENDED (freeze_masked_basis, instrument
control green, all-or-nothing publish) and the shapes measured on all
three builds — 94/105/106 = `window vsavj/masked-v2 889 2091` on every
build (single run, the ratified select-window class, thousands of
identical match frames after); specs authored, .sha1s dropped
(STRICTER: vanilla-anchored where self-frozen saw nothing). 103 is
replay 61 + AUTO: measured per-leg — donovan-m10 loads the TENANT
(+0x60 = 0x3fa9d0, .sha1 stays); hui/pyron sets commit the UNBACKED
cell 0x13 and no fighter record forms (+0x60 == 0 at f5000) —
`.legacy-exempt` authored per the 61/62 precedent.

**Carried forward:** the m3b_merged11 one-back audit defaults must join
the freeze re-point sweep or the N-2 deletion policy rots them at the
next freeze (list in the triage doc). A4 dirs now at zero live
reference fall mechanically at the next census.

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to the archive; entries within them are marked DECIDED/FIXED
  in place, as always.

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

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

## Decisions made (maintainer, 2026-08-05): two ratifications

**1. CLAUDE.md §4 comparison class v3 — "bounded re-convergent window".**
Ratified for the select screen, which the roster deliberately alters. A
replay qualifies only when all four hold, frozen per replay: a single
CONTIGUOUS run, a fixed ONSET frame, full RE-CONVERGENCE, and match state
UNTOUCHED. Measured over five replays before the ruling (onset 890 in every
one, one run each, 2469-10498 identical frames afterwards including a full
timeout match). It is STRICTER than the frozen first-divergence constant it
sits beside, which never re-converges at all — a narrower licence for one
screen, not a loosening. §4 amended; checker `tools/compare_window.py`,
ground-truthed both directions by `tests/test_compare_window.sh` including
that a bit-identical pair is NOT a silent pass (the expectation asserts the
divergence exists).

**2. The `[[tenant]]` schema.** Ratified, and already implemented for a
single tenant (14z-60t/u) byte-identically on both tracks with the tenant
still at `0x0F`. `docs/project/tenant_manifest.md` moves PROPOSAL -> RATIFIED; its
wheel/ladder/folds sub-tables stay proposal-only because that work is not
done.

Maintainer: "I validate the two items, I don't need testing to see that they
hold on principle." The measurements above were taken before the ruling
regardless — the class's four clauses are what was measured, not what was
hoped for.

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

## Decision made (maintainer, 2026-08-05): new cells SNAP to vsav's lattice

"It feels safer to conform to arcade vsav and snap to it. As long as the UX
is good enough, I don't even mind if the look is not great." So the three
appended cells take positions derived from vsav's own hexagon rather than
PS1's pixel coordinates.

Derived layout (`build/manifest/wheel_layout_proposed.json`): vsav's wheel
is a clean hexagon, rows 1-2-3-4-3-2-1 at y=64..144 every 16, then a single
centre-line cell at y=152 (+8). Mirroring that bottom signature downward:

| cell | id | position |
|---|---|---|
| random (unchanged) | `0x0B` | (248, 152) |
| Huitzil/Phobos | `0x10` | (224, 168) |
| Donovan | `0x13` | (272, 168) |
| Pyron | `0x11` | (248, 176) |

This is geometrically IDENTICAL to the PS1 port's shape (pair, then single
on the centre line); only the id assignment differs, per the maintainer's
amendment — random keeps its vsav cell and Pyron goes to the very bottom.
28 bytes of TABLE B change. Adjacency is still a geometric DRAFT pending
the cursor-movement video.

## Decision made (maintainer, 2026-08-05): 0x360+id anim block = INHERIT

Option A: the newcomers inherit their base character's animation from the
shared 16-wide block `0x360-0x36F` (a tenant at `0x13` plays `0x363`),
exactly as vsav2 ships — Capcom left both those folds in place. Sites
`PRG:0x003E40` / `PRG:0x004082` therefore stay folded, recorded as
`inherit` in `docs/project/tenant_manifest.md`. **Fallback, if a playtest shows the
inherited animation is wrong for a newcomer: option B**, relocate the block
to a free 32-wide anim-number range and widen both masks.

## Decision made (maintainer, 2026-08-04): M5 voice samples = A then B

"A then B, gates stay strict, option C is rejected." Ship the unfaithful
voice lines silent now; revisit growing the QSound region at M3 within the
measured 16 MB `device_rom_interface<24>` ceiling; never overwrite vsav
content for sample room. Recorded in full under "Decisions pending" above,
where the option analysis lives.

## Decision made (maintainer, 2026-07-31): electrocute arc colors

Keep vsavj-native shock styling for all victims including Donovan
(option A of the 14z-20 write-up): the arcs/glow are engine-global and
victim-independent; vs2's yellow was a game-wide re-theme, not per-char
data. "Less work, less risk, and we can always come back to it after
all the more important work." LOCKED in tests/test_don_accent.sh
section 3 (shock-window vanilla lock, frozen from a vanilla run) —
revisiting requires changing that gate deliberately.

## Decision made (maintainer, 2026-08-02, round 65): M2b+ASSETS freeze

Freeze `b91647c7` as `donovan-m2c` before starting M5 sounds —
"mechanically sound as far as we can tell" (rounds 52-64 playtest
arc + full battery + suite). Frozen basis: three masked windows.

## Decision made (maintainer, 2026-08-02, round 64): third mask window

`RAM:$FF4182-$FF41A1` (palette-fade staging slot for select block-A
row 14) RATIFIED into the masked legacy basis — option A of the
14z-49b write-up, after the recolor-necessity A/B (14z-49d) showed
options B and C strictly worse. Condition attached and honored:
detailed documentation + a standing confirmation path
(`tests/audit_mask_window_ff4182.sh`; spec in docs/game/atlas/ram.md).
Extension policy stands: future palette-block ports extend the
window per measured slot, never pre-widen.

## Decision made (maintainer, 2026-08-06): select art = option A

Option A of the 14z-62e write-up: the per-hover bank thunk for the
portrait-record object + the tenant's select art in WIDE group C at
native codes; `vsav.zip` leaves the rompath entirely pristine [**14z-105:
not quite — the later effect-tail pass writes four GROUP-A members
(vm3.13m/15m/17m/19m); measured by the release packager**]. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/project/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

## Decisions pending (human)

- **THE MiSTer PROFILE SHAPE (14z-106, slice B measured).** The numbers
  (`docs/project/mister_fit.md`) remove the roster trade-off: the group-C
  art (6.39 MB) cannot fit vanilla's 32 MB GFX (0.49 MB blank, upper
  bound), so any MiSTer build needs a wider GFX tier than jtcps2's
  documented 64 MB `JTFRAME_SDRAM_LARGE`. Options: **(A) WIDE v1 verbatim
  (PRG 6 / GFX 48 / QSound 16 MB) on a 128 MB SDRAM tier** — one profile
  and one romset across FBNeo/MAME/MiSTer, MiSTer work = width plumbing
  only (jtframe `SDRAMW` 23→24 and +1 bank/prog/ioctl bit, the core's
  `main_rom_addr`/gfx/`qsnd_addr` buses, the 14z-86 QSound latch fix), no
  content change; cost: framework surgery, profile-gated in the fork,
  ONE hardware requirement (the 128 MB module the maintainer has — users
  with 32/64 MB modules cannot run it, which the README must say). **(B)
  a tighter MiSTer-only profile** (e.g. PRG 5 MB / GFX 40 MB / QS 9 MB):
  saves nothing architecturally — every bus still widens by one bit, and
  it forks the romset/manifests/tests into a second generation for no
  gain. **RECOMMENDATION: A.** Gameplay-visible consequence: none; the
  only player-facing fact is the 128 MB requirement.

- ~~**MiSTer ALIGNMENT (14z-106) — five questions before any RTL.**~~
  **ALL FIVE RULED (maintainer, 2026-08-22).** Rulings, then what each
  one commits us to; the original brief follows unchanged.
  1. **Base tree — RULED: a SEPARATE CORE**, so the reference CPS-II
     core stays separately usable; ours respects Jotego's licence(s) and
     is FOSS "if the licensing scheme allows"; the exact fork mechanism
     is left to my proposal. **Facts (jtcores README, checked
     2026-08-22):** jtcores and jtframe are **GPL-3.0** ("you are
     obliged to publish your code if you use mine") — so our core is
     FOSS by obligation, not just preference, and must ship its source.
     **PROPOSAL (my recommendation, open to veto):** (a) a PUBLIC fork of
     `jotego/jtcores` under the maintainer's GitHub, GPL-3.0 retained,
     branched from a pinned upstream tag; (b) a NEW core directory
     (working name `cores/cps2w`, final name TBD) that reuses the cps2
     RTL the way cps1/cps15/cps2 already share it through jtframe
     macros, producing its OWN RBF (`jtcps2w.rbf`) — the stock
     `jtcps2.rbf` is never rebuilt or touched; (c) pinned here as
     submodule `emu/jtcores` on the fork branch, with the fork's diff
     mirrored as `emu/jtcores-patches/0001-*.patch` for review — the
     MAME/FBNeo pattern, and what keeps Rule 1 v2's "small,
     human-reviewable set of declarative lines" honest on a third
     implementation; (d) upstream PR later, at the maintainer's
     discretion — the separate-core shape is what makes one possible.
     FIRST TASK of the arc: read the fork and VERIFY (b)'s sharing
     mechanism — it is my reading of the tree layout, not a measurement.
     **LICENCE GAP SURFACED:** this repository carries NO LICENSE file.
     The core fork is GPL-3.0 by obligation; the licence of THIS tree
     (tools, patches, docs, authored assets) is the maintainer's call and
     is now a pending decision (below).
  2. **Profile shape — RULED: measure first, choose on numbers** (the
     recommendation adopted). Arc task: merged-m6 GFX occupancy per
     group/bank + the real PRG extent, then the fit options.
  3. **Governance/oracle — RULED: the recommendation adopted** — Rule 1
     v2 extends verbatim; jtframe/Verilator SIMULATION is the gate,
     HARDWARE is the field test (the MAME-oracle / playtest split).
  4. **Environment — RULED: MiSTer with a single SDRAM module, plus a
     Jammix extension card** (CRT at original resolution/frequencies —
     the field test can be made on real video timing). **OPEN DETAIL:
     which module size?** jtcps2's own docs: CPS2 games with >= 16 MB GFX
     need a 64 MB module; a MiSTer-shaped WIDE (GFX up to 32 MB + PRG +
     QSound 16 MB) needs at least 64 MB and likely 128 MB
     (JTFRAME_SDRAM_LARGE). Confirm before the profile numbers are fixed.
  5. **Distribution — RULED: MRA + RBF over the same release members**,
     covered by the tagged release; stock `vsavj` in the MRA "if
     necessary and/or makes sense — argue for/against". **ARGUMENT:**
     an MRA binds one romset to one RBF, so a stock-`vsavj` MRA aimed at
     OUR RBF is not redundant with the official core's — it is the
     STOCK LEG of the emulator superset invariant on FPGA (the patched
     core running unmodified vsavj must behave as the reference core
     does), i.e. a test instrument that must exist in-tree regardless.
     Shipping it in the release too costs one small XML and buys players
     a same-RBF A/B and a sanity check that their dump is good. Against:
     a second menu entry people may pick by mistake. RECOMMENDATION:
     ship BOTH, the stock one labelled "(stock vsavj — reference leg)".

  ORIGINAL BRIEF: **MiSTer ALIGNMENT (14z-106) — five questions before any RTL.** Built
  only from what the record already measured (`docs/project/cps2_wide.md`
  "Known limits", source-verified 14z-86 at jtcores @1ae053f3 + jtdsp16
  @71fa564a; STATE_HISTORY 14z-85/86). The facts: jtcps15 QSound is LLE
  (jtdsp16 + the real dl-1425), but its sample path is 23-bit with a
  7-bit bank latch, so content in our QSound extension (banks 0x80+)
  would ALIAS onto legacy samples — a ~4-line RTL width fix; the stock
  core caps 68k PRG at 4 MB and GFX at 32 MB (2 x 16 MB) inside a 64 MB
  SDRAM_LARGE map, so WIDE v1 (PRG 6 / GFX 48 / QS 16) does NOT fit and a
  MiSTer-shaped profile is required; a 17-character variant is impossible
  (ruled 2026-08-15 — full roster or nothing).
  1. **Base tree.** Fork jotego/jtcores at which tag/commit, and is the
     intent an upstreamable separate machine (the `vsavjw` pattern — a
     new MRA/core variant leaving stock `vsav` untouched) or a private
     fork? RECOMMENDATION: pin a tag as a submodule under `emu/jtcores`
     exactly as MAME/FBNeo are pinned, carry our change as a patch file
     in `emu/jtcores-patches/`, and shape it as a separate machine so
     the emulator superset invariant has a stock leg to compare against.
  2. **Profile shape (gameplay-visible, yours).** PRG target: 6 MB as
     WIDE v1, or the measured minimum (D+H alone overflow 4 MB by ~310 KB;
     the three-tenant merged image's real extent should be re-measured
     before picking)? GFX must come back from 48 MB to <= 32 MB: which
     tenant tiles get per-slot exclusivity/banking, i.e. what art may
     not coexist on screen? RECOMMENDATION: measure the merged-m6 GFX
     occupancy per group/bank first (the 14z-62/66 census tooling) and
     present the fit options with numbers; do not choose blind.
  3. **Governance and the oracle.** Rule 1 v2 (profile-gated, stock
     `vsavj` bit-identical on the patched core, ratified per profile
     version) should extend verbatim — but MiSTer has no headless
     per-frame work-RAM harness. Is the gate a Verilator/jtframe
     simulation of the core (slow but deterministic and scriptable), a
     hardware capture protocol (the maintainer plays; no RAM checksum),
     or both? RECOMMENDATION: simulation as the gate, hardware as the
     field test — same split as MAME (oracle) vs playtest today.
  4. **Environment.** Does the maintainer have a MiSTer (with the 128 MB
     SDRAM module — JTFRAME_SDRAM_LARGE needs it) and the Quartus
     toolchain, or is simulation the only lane this side? This decides
     who builds the RBF and how fast the confirmation loop is.
  5. **Distribution.** MRA + RBF over the SAME release members as
     `release/merged-m6/` (the patch artifact does not change shape); the
     tagged GitHub release ruled 14z-105 then covers both. Confirm, and
     whether the MRA should also carry the stock-profile `vsavj` entry.

- ~~**ADOPT THE HIT-CLASS MAP EXTENSION + RE-FREEZE huitzil & pyron
  (14z-82b).**~~ **DECIDED 2026-08-12 (maintainer): ADOPTED** — shipped as
  huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322), 14z-82c. Original entry: The generated `hitclass_map_extend` site_thunk fixes a
  playtest-reachable crash LATENT IN BOTH FROZEN TENANT BUILDS (pyron's
  satellite type-64 contact = the f7997 vec3, measured on pyron-m2 solo;
  Huitzil's 68/72 share the pool). Numbers, all measured on a probe build
  (tests/audit_hitclass_map_cost.sh, rerunnable): fix holds through the
  11,017-frame soak that crashes the frozen build; LEGACY BIT-IDENTICAL
  over 30,284 frames on four replays, with a fire census showing legacy
  never enters the map at all [**THAT FIGURE IS RETRACTED — 14z-92 M4
  measured 230 legacy entries corpus-wide; the adoption still stands and
  the argument is "legacy enters and gets vanilla answers"**]. Cost of
  adoption: the row goes in
  huitzil.toml + pyron.toml (shared, dedups on the merge) → BOTH
  verticals re-freeze (new fingerprints; registry rows; their frozen
  masked legacy self-logs re-measured — expected unchanged given the
  zero-fire census, but measured is the standard). Donovan/stock
  untouched. RECOMMENDATION: adopt — it is the third instance of the
  "vs2 widened an index consumer" class (14z-26, 14z-35 precedents) and
  the crash needs one satellite contact to fire in a real match.
- ~~**DONOVAN's map entries 61/62 (14z-82b, separate and smaller).**~~
  **DECIDED 2026-08-12 (maintainer): (a) KEEP VANILLA'S ZEROS** — his
  sword-companion objects' hit-class reactions stay as every shipped
  build has had them; measured unexercised (0 map entries in his
  replays). Revisit only if his satellite hits ever feel wrong in
  playtest — then it is 2 bytes in the generator's policy + a Donovan
  re-freeze. Original entry:
  MEASURED SINCE: his types 59-63 are the projectile-pool objects his
  SWORD-COMPANION machine spawns (61 = the sword-routine region
  x065e5a's family; spawns measured in both his replays), and they enter
  the hit-class map ZERO times in his replays — the missing reaction is
  UNEXERCISED, so (a) costs nothing observable today. Original entry: vs2
  gives his satellite types 61/62 hit classes 0x0E/0x04 where vsavj
  holds the do-nothing 0 — so his type-61/62 projectile hits currently
  produce NO hit-class reaction on every shipped build, and always have.
  The fix above deliberately keeps vanilla's zeros (donovan-m3a
  byte-untouched). Options: (a) keep zeros — shipped behavior, nothing
  moves; (b) adopt vs2's two bytes in the same thunk body — vs2-faithful
  hit reactions for his satellite, at the cost of a Donovan re-freeze
  and a battery re-measure. If (b) is ever wanted, it is a 2-byte change
  to the generator's policy plus the measurements; playtest feel decides
  whether the missing reaction is real. RECOMMENDATION: (a) for now;
  revisit if his satellite hits ever feel wrong in playtest.

- **IF `anim` CANNOT LEAVE THE CRYPT WINDOW — the fallback order is set
  (maintainer, 2026-08-10).** Framing recorded verbatim in effect: *"we'll see
  if and how we can grow the crypt window and still have everything work, or
  if we need to cut down access to a character (in which case I'll leave Pyron
  aside, but that's kind of a last resort)"*.

  So the ladder, best to worst:
  1. **Make `anim` movable** — root-cause the odd pointer. If this works, no
     decision is needed at all, which is why it is the active task.
  2. **Grow the crypt window in the WIDE profile.** A profile change, so
     maintainer-approved by construction, and it must be shown not to break
     anything (the profile's whole justification is the emulator superset
     invariant — `tests/test_wide_profile.sh` / `test_mame_wide.sh` are the
     gates, plus `test_crypt_boundary.sh` since the window's EDGE is what
     would move). Deficit to cover if nothing else changes: **125,560 bytes**.
  3. **Ship two tenants, Pyron aside.** Explicitly a LAST RESORT. Note the
     measured irony: Pyron's reach-constrained set is **0 bytes** — he is the
     cheapest tenant on every axis except his `anim` (111,872). Dropping any
     one tenant frees roughly its own anim, so on space grounds alone the
     choice between them is close to arbitrary; it is a roster decision, not
     an engineering one.

- ~~**THE MERGED BUILD'S `[init_shim]`: ONE SHIM, THREE TENANTS (14z-77)**~~
  **DECIDED 2026-08-10 (maintainer): the recommendation below, in full** —
  adopt phase mode, dispatch flavor per id, gate the write so Pyron stays
  untouched until his polarity is measured against native, then run Donovan's
  battery on a phase-mode build before trusting the merge. **IMPLEMENTED as
  slice G** (14z-77e); the two measurements it names remain OPEN and are
  listed there. Original entry follows.

  Surfaced by slice F's collision measurement — it was one of the three real
  merge blockers, and unlike the other two it was not purely mechanical.

  **The mechanics, measured.** The shim is emitted ONCE per build at ONE site
  (`dispatch_00`'s seed hook, `seed_entry = 0x016C64` — identical in both
  manifests that declare it). It (a) seeds the object pool if the latch is
  clear, and (b) writes the VS2/VH2 **flavor** byte to `+0x3C2` of the player
  struct being initialised, or `flavor_held` when that player's Start is held.

  Three things follow, and only the first is mechanical:

  1. **Flavor polarity is per tenant and already ratified.** D1 (VS2 default)
     means `0x01` for Donovan and `0x00` for Phobos — the polarity differs
     because the engine branch each character tests differs (14z-66 measured
     it against native). A merged shim must write the id-appropriate byte,
     i.e. the same N-way dispatch the thunks need. No decision required.
  2. **`latch_mode = "phase"` is NOT per tenant — the seeder is shared, so a
     merged build either has the gate or does not.** Phobos NEEDS it: without
     it his ecosystem drains pool 0 and the round-2 char re-init re-runs the
     seeder over LIVE pools (14z-65 measured the f4890 wipe, orphaned queues,
     and a freed slot dispatched into palette space). He is in the merged
     build, so **the merged build must carry the gate**, and Donovan's shim
     bytes therefore change — the generator's own comment says his frozen
     bytes stand "until his own re-freeze adopts the mode". The gate only
     narrows WHEN the seed runs (to `$FF800C == 0x40000`, the char-load
     phase), and Donovan's first init is at that phase, so it SHOULD be inert
     for him — but that is an argument, not a measurement, and this project
     does not ship arguments. **Required before the merged build is trusted:
     Donovan's replay battery on a phase-mode build, compared to
     donovan-m3a.**
  3. **Pyron declares NO `[init_shim]` at all.** In a merged build the shim
     runs at char-init for whatever the hosted dispatch covers, so he could
     be given a `+0x3C2` flavor byte he has never had. Whether he reads that
     byte is UNMEASURED. Options: give him an explicit row (needs his own
     polarity measured against native vs2, the 14z-66 procedure), or gate the
     flavor write so only tenants that declare one receive it.

  **Recommendation:** adopt phase mode for the merged build (2 is forced),
  dispatch the flavor bytes per id (1), and gate the write so Pyron is
  untouched until his polarity is measured (3, the conservative half) — then
  measure Donovan's battery before trusting the merged build. The alternative
  worth the maintainer's attention: if Donovan's battery DOES move under phase
  mode, the fallback is a per-id gate on the phase check itself, which is more
  emitted code at a shared site and wants explicit sign-off.

- ~~**THE BEAM'S LIST-TYPE 12: FLATTEN, OR RATIFY THE HOOK? (14z-71)**~~
  **DECIDED 2026-08-09 (maintainer): NEITHER — take over the dead
  list-type 6**, with the explicit condition that the deadness assumption
  must not be load-bearing. Built as `build/hui20`; see the 14z-71
  RESOLVED section. The maintainer's framing, kept because it generalises:
  *"there is almost always a chance it actually wasn't dead and we just
  missed how it was used... if we encounter regressions in vanilla
  assets/engine, this is one of the first places to check, and should we
  ever encounter something that uses list-type 6 that we didn't know of,
  we should stop, analyse and assess the situation before continuing."*
  That is now enforced by construction (the vanilla fallback) and by a
  gate (the `$FF010C` tripwire), not by memory. See THE DEADNESS REGISTER
  below.

- **THE 14z-62e SELECT-ART ANALYSIS (decided above).** The
  last visual-de-substitution piece: the tenant's select-art subset (101
  bank-1 tiles + 4 placeholder label tiles + the 6-tile medallion) still
  overwrites Jedah's bank-1 select-figure art, garbling his select-screen
  BODY (face/name/match art are all back). Two measured options:

  **A — a per-hover bank thunk + group C (recommended).** The select
  FIGURE object's bank already follows the hovered char through the
  engine table (measured: `PRG:0x05F9EC` jsr's the bank helper; hovering
  the tenant writes 0x1000 and his standing figure draws from group C
  TODAY). The PORTRAIT-record object instead gets bank 1 ONCE at venue
  init (`PRG:0x07C428`). Option A thunks the per-hover record-pointer
  consumers (`PRG:0x05F328`/`0x06C0E0`) to also set that object's bank:
  hovered==tenant -> 0x1000, else -> 0x2000 (the value it already holds,
  so pure-legacy RAM is byte-identical; after a tenant visit the restore
  re-converges). Select art then lives in group C at native codes — NO
  fit problem — and `vsav.zip` leaves the rompath ENTIRELY PRISTINE.
  Cost: a new engine hook on the select path (cycle-only for legacy; the
  ratified hook class, but the re-freeze's flicker/window inventory must
  be re-measured with it in — the standing watch applies). The name/
  highlight-piece objects' banks need the same treatment (their sites
  are one measurement away, same method).

  **B — relocate into blank bank-1 space, no hooks.** Vanilla bank 1 has
  2,917 blank tiles (largest runs: 881 at 0xBE90-0xC200, 460 at 0x3634,
  357 at 0x6C9C — measured). Placing the ~117 tiles there needs a NEW
  greedy fit (block-geometry aware), a reference-exclusivity proof for
  the chosen ranges (blank != unreferenced: a legacy record could use
  blank tiles as transparent filler, and art there would APPEAR — the
  proof method is the medallion's whole-image scan), and `vsav.zip`
  stays patched-but-additive (nothing of Jedah's overwritten). Zero
  engine hooks, zero legacy cycle cost.

  **Recommendation: A.** It finishes the artifact story (pristine
  vsav.zip — the strongest possible provenance), reuses the established
  thunk pattern and the already-poked bank table, and avoids a new fit +
  exclusivity-proof toolchain for a one-off. The hook's legacy cost is
  cycles only, in the class the basis already tolerates; it will be
  measured before the re-freeze ratifies anything. B stays the fallback
  if the measured hook cost violates the standing watch.


- ~~**RATIFY A COMPOSITE §4 CLASS? (14z-61)**~~ **RATIFIED 2026-08-06
  (maintainer: "Your proposal is ratified").** CLAUDE.md §4 amended: the
  `composite` class is the strict CONJUNCTION of flicker-tolerated and
  bounded re-convergent window, adding no tolerance to either. The seven
  `.pending` expectations became `.masked` `composite` specs carrying the
  shapes they had already printed, and the WIDE reference freeze is
  complete — `run_suite.sh` on `donovan-m5w` is GREEN, all 63 replays
  validated or explicitly skipped. Original entry below.

- **RATIFY A COMPOSITE §4 CLASS? (14z-61) — the analysis behind the
  decision above.** Seven legacy replays measure as the frozen
  hook-flicker inventory PLUS one bounded re-convergent window per
  select-screen ENTRY (table in 14z-61). Both halves are already ratified —
  `flicker` (§4 v2) and `window` (§4 v3) — but no single class expresses
  their conjunction, so those replays cannot be frozen without either a new
  class or a fudge. They are `.pending` and fail the suite meanwhile.

  **Proposal: `composite <baseset> <flicker-csv> <window-list>`**, defined
  as the strict CONJUNCTION of the two: every divergent run must be
  accounted for by name, the flicker set must match the frozen inventory
  exactly, the window list must match exactly, and the run must fully
  re-converge. It tolerates nothing that `flicker` and `window` do not each
  tolerate, and it is strictly stronger than either alone.

  Implemented and ground-truthed ahead of the decision so ratification is
  one word rather than a session: `tools/compare_composite.py`,
  `tests/test_compare_composite.sh` (7 synthetic cases + a no-loophole
  check — extra flicker frame FAILS, missing flicker frame FAILS, onset
  moved one frame FAILS, no re-convergence FAILS, bit-identical FAILS, an
  unfrozen second window FAILS). **Nothing validates against it until you
  say so**: accepting means turning each `.pending` file into a `.masked`
  one carrying the spec it already prints.

  **Recommendation: ratify.** The alternative readings are worse — calling
  these replays `skip` hides a real comparison, and widening `flicker` to
  swallow a 900-frame run would be the loosening §4's standing watch exists
  to prevent.

- ~~**FREEZE THE WIDE TRACK? (14z-61).**~~ **DONE 2026-08-05 (maintainer:
  "yes freeze and register as wide reference first, then we resume").**
  `9bac6ee3 -> donovan-m5w`; see 14z-61. Original entry below.

- **FREEZE THE WIDE TRACK? (14z-61) — the analysis behind the decision.** `build/m5_wide` (`9bac6ee3`) is now
  playtest-confirmed with and without Donovan, both WIDE profile gates are
  green, and the new rendering + member-identity gates are green. The
  registry convention is that rows are added at FREEZE time as a STATE.md
  decision, so this is not mine to do.
  **Recommendation: freeze and register it** as the WIDE reference
  (`donovan-m5w` alongside `donovan-m2c`), for one specific reason beyond
  bookkeeping: M3a moves the tenant from `0x0F` to `0x13` and will churn
  the select records, the thunk id and the bank-table row at once. Without
  a registered WIDE reference, a regression during that work has nothing to
  bisect against on this track — which is exactly the position that made
  the sprite garble expensive.
  Cost if we skip it: none today; the risk is only felt later, and by then
  the build may not be reproducible from the tree.

- **THE SELECT SCREEN AND THE SUPERSET INVARIANT (14z-60r).** Drawing three
  new medallions requires the wheel OBJ record to grow from 18 to 21
  entries and its coordinate list likewise. Measured: neither can grow in
  place (another record starts immediately at `0x272ABA`; the coord list is
  immediately followed by the shared global pool), so both must relocate —
  cheap, one referrer at `PRG:0x2689FE`. **The problem is not placement, it
  is the invariant.**

  The record's `count` word changes and its `budget` word is debited from
  the OBJ emitter's shared per-frame budget — GOTCHAS records that exact
  coupling flipping a borderline skip decision into a one-byte work-RAM
  divergence. Three more sprites also render. **So any legacy replay that
  reaches the select screen will diverge in RAM.** M2b's select work avoided
  this by strict in-place replacement preserving the host's budget word;
  adding CELLS makes that impossible by construction.

  CLAUDE.md §1 covers "any match, **menu path**, or attract sequence", so
  this needs an explicit ruling rather than an assumption:

  **A — a bounded select-screen carve-out (recommended).** Legacy replays
  are compared as today up to select entry, and the select-screen
  divergence is MEASURED, mechanism-attributed and frozen per replay, in
  the same style as the existing `diverge` constants and masked windows.
  Rationale: the invariant's purpose is that vanilla *gameplay* is
  untouched, and a select screen that offers three more characters is by
  definition content that involves them. Condition: the divergence is
  measured and frozen BEFORE acceptance, never accepted blind, and must not
  extend past the select screen into match state.

  **B — keep the wheel vanilla**, reach the newcomers by another mechanism
  (the option-2 hold-Start alternates the maintainer already ranked lower).
  Preserves the invariant literally; costs the decided roster UX.

  **C — attempt a RAM-neutral extension.** Not viable: the budget word must
  cover the entries actually emitted, and three extra sprites change OBJ RAM
  regardless. Recorded so it is not re-proposed.

  **Recommendation: A**, with the measurement done first so the ruling is
  made on a number rather than on a prediction.

  **MEASURED 2026-08-05 (14z-60s), and the number is good.** Built
  (`select_wheel roster21`) and compared against the previous WIDE build on
  the masked basis, so the wheel change is the only variable:

  | replay | frames | divergent | window | after |
  |---|---|---|---|---|
  | `04_select_fuzz` | 3520 | 162 | 890-1051 | 2469 identical |
  | `02_demitri_vs_cpu` | 5520 | 733 | 890-1622 | 3898 identical |
  | `03_two_player_vs` | 5320 | 913 | 890-1802 | 3518 identical |
  | `09_mirror_pick` | 4720 | 993 | 890-1882 | 2838 identical |
  | `05_timeout_idle` | 12120 | 733 | 890-1622 | 10498 identical |

  Every replay: **onset at frame 890 — select-screen entry — exactly ONE
  contiguous run, and FULL RE-CONVERGENCE.** Match state is bit-identical
  in all five, including a complete timeout match (10,498 identical frames
  after the window closes). The divergence is confined to the screen we
  deliberately changed and reaches nothing else.

  That is a **stronger** guarantee than the existing frozen-`diverge`
  class, which never re-converges at all. The proposal for ratification is
  therefore a new comparison class: **"bounded select-screen window,
  re-convergent"** — onset frame, window end and run-count frozen per
  replay, with re-convergence and match-state identity as the assertions.
  Mechanism: select-screen init caches the record pointer we repointed
  (`GOTCHAS` class 4), which is why onset is identical across replays.

- ~~**THE `0x360+id` ANIM BLOCK (14z-60)**~~ **DECIDED 2026-08-05
  (maintainer): option A, INHERIT — "since we can. If it fails, we'll
  fall back to option B (relocation)."** So a newcomer at `0x13` plays
  anim `0x363` from the shared `0x360-0x36F` block, exactly as vsav2
  ships; sites `PRG:0x003E40` and `PRG:0x004082` stay folded and are
  recorded as `inherit` in the tenant manifest. Fallback if playtest shows
  the inherited animation is wrong for a newcomer: relocate the block to a
  free 32-wide anim-number range and widen both masks. Original write-up
  kept below.

- **THE `0x360+id` ANIM BLOCK (14z-60) — the analysis behind the decision
  above** — of the seven sites that fold the
  character id to 4 bits, five are ordinary porting work; two
  (`PRG:0x003E40`, `PRG:0x004082`) compute a per-character anim number in a
  block that is genuinely 16 wide (`0x360-0x36F`, with `0x370+` already
  occupied). **Option A: inherit** — a newcomer at `0x13` plays `0x363`,
  which is exactly what vsav2 ships, Capcom having left both folds in
  place. **Option B: relocate** the block to a free 32-wide range and widen
  both sites — a numbering audit plus shared-engine edits, for a family we
  cannot yet name. **Recommendation: A**, on the strength of vs2 being a
  shipped existence proof; revisit only if a playtest shows the inherited
  animation is wrong for a newcomer. Detail in session 14z-60 and
  `docs/game/atlas/id_space.md`.

- ~~**M5 SOUND NEEDS A DATA HOME (14z-52)**~~ **SETTLED 2026-08-04 by the
  dual-track decision below: it lives in `wide_ext`.** Two corrections to
  the record that got it there:
  **(a) Option B was DEAD and the recommendation was wrong.** It proposed
  reclaiming the "inert since 14z-31" `weapon_accent_t0/_t1/rowd_slot`
  rows. Measured 14z-59g: those are `data_port` rows writing 0x20 bytes
  each to `0x39FBE0-0x39FC40`, which is in NEITHER hole (`hole_a`
  `0x0BF6A0-0x100000`, `hole_b` `0x3EC720-0x400000`). They are in-place
  palette overwrites, not hole allocations, so reclaiming them frees
  **zero** of the 352 bytes needed. The original entry mistook them for
  hole tenants.
  **(b) Option C stopped being expensive.** It was rejected as "larger
  blast radius" before WIDE existed; WIDE is now demonstrated on both
  emulators, so it is the cheap option — and option A (Jedah's anim
  region) keeps its unaudited dead space AND stays available for the
  ported select web, which was its earmarked purpose all along.

- ~~**M5 VOICE SAMPLES (14z-51)**~~ **DECIDED 2026-08-04 (maintainer):
  "A then B, gates stay strict, option C is rejected."** Ship M5 with those
  specific sounds silent now (option A — it matches the current
  silent-by-design behaviour for exactly the sounds that cannot be
  faithful); revisit growing the QSound sample region (option B) at M3,
  when Huitzil and Pyron force the same question at scale, inside the
  measured 16 MB ceiling. **Option C (overwriting low-value vsav content)
  is rejected** and may not be re-proposed — it is superset-invariant-
  adjacent. Original entry with the full option analysis kept below.

- **M5 VOICE SAMPLES (14z-51) — the analysis behind the decision above:**
  6-8 of Donovan's sounds (his voice
  lines / vs2-new sfx: ids 0x71D/0x73E/0x753-0x756, likely the "Change
  Immortal" family) do not exist in vsav's sample ROMs, which are
  byte-full. Options: A) ship M5 with those specific sounds silent
  (shared sfx all restorable regardless); B) grow the QSound sample
  region via driver descriptor (vm3.11m/12m from 4MB->8MB members or
  add members; CLAUDE.md rule 1 permits load-map changes; MiSTer
  impact unknown); C) overwrite low-value vsav content (risky,
  superset-invariant-adjacent). Recommendation: A now (matches the
  current "silent by design" behavior for exactly the sounds that
  cannot be faithful), revisit B at M3 when Huitzil/Pyron force the
  same question at scale.
  **UPDATED 14z-59f — option B now has a measured hard ceiling.** CPS-2
  WIDE v1 already declares QSound at **16 MB, which is MAME's maximum**
  (`qsound_device` is a `device_rom_interface<24>`, 24 address bits). So
  B is available and proven on both emulators up to 16 MB and NOT ONE
  BYTE further: growing past it would mean widening a SHARED MAME device,
  which is outside Rule 1 v2. If Donovan + Huitzil + Pyron voice banks do
  not fit in the 8 MB the profile adds, the answer has to be exclusivity
  or banking, not more region. Worth sizing that before committing to B
  at M3. (Two duplicate copies of this entry were merged here.)

- ~~**ROSTER ACCESS MECHANISM**~~ **DECIDED 2026-08-04: option 1, an
  altered select screen keeping the existing cells and appending the three
  newcomers; hold-Start alternates are the fallback. See 14z-59l.**
- See SPEC §7 for the rest. Nothing blocks current work.

- ~~**THE REPOSITORY LICENCE (14z-106).**~~ **DECIDED (maintainer,
  2026-08-22): GPL-3.0 for everything** — `LICENSE` added (the FSF text
  verbatim), README "Licence" section. Original entry: The tree has no LICENSE file.
  The jtcores fork is GPL-3.0 by obligation; the licence of THIS tree
  (tools, patches, docs, authored assets — never ROM bytes, rule 7) is
  undecided. Options: GPL-3.0 across the board (simplest, one licence
  for the whole deliverable); MIT/BSD for tools + GPL-3.0 only for the
  core fork (more permissive tooling, two licences to explain); CC for
  docs/assets on top of either. RECOMMENDATION: GPL-3.0 for the whole
  tree — one licence, compatible with the core by construction, and the
  maintainer's stated wish is FOSS. Maintainer's call.

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
