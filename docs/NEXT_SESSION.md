# NEXT SESSION — orientation (session 14z-57, 2026-08-03)

Read STATE.md sessions 14z-53..57 (the CPS-2 WIDE pivot, Phase A,
Phase B0-B3, and the two B4 canary attempts) and
docs/cps2_wide.md after this. The approved architecture plan is archived
at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are
the project's best instrument; reference data they provide goes straight
into gates.

## Ship state — WIDE v1 fully declared and proven INERT; not yet proven USABLE

Frozen reference: `b91647c7` = **donovan-m2c** (stock-size, untouched by
any WIDE work). Donovan content dev head: `ae701ffb`.

**CPS-2 WIDE v1 is declared in full and inert**: PRG 6 MB / GFX 48 MB /
QSound 16 MB. B0-B3 all pass 24/24 (work RAM AND framebuffer) on both
invariants. Total emulator cost: **one widened condition** in
`cps_obj.cpp` plus the `Cps2Wide` flag lifecycle — everything else is
descriptor table data.

**Every grown region is still ZERO-FILLED and the space is declared, not
demonstrated.** B4 attempt 1 was an invalid canary (see below); the
redesigned one is the immediate next task. Do not author content into the
extension until it passes.

Run the gate:
```
WIDE=0 tools/setup_fbneo.sh          # once: harness-only REFERENCE binary
cp emu/fbneo/fbneo /somewhere/fbneo_ref
tools/setup_fbneo.sh                 # the WIDE binary
python3 tools/build_wide_romset.py "$ROMDIR" build/wide0/rompath \
        --qsound 2 --gfx 4 --prg 4
ROMDIR=... FBNEO_REF=/somewhere/fbneo_ref tests/test_wide_profile.sh
```
The reference MUST come from the same tree state with only patch 0002
reverted — a drifting reference produces noise that looks like findings.

FBNeo carries two patches with deliberately separate trust surfaces:
`0001` (frontend harness, now incl. framebuffer capture) and `0002` (the
WIDE driver + the one gated core line).

## What 14z-52 did (read STATE 14z-52 for the full measurement)

- Root-caused the music bug; restored 13 sound rows (correct but
  currently inaudible — they never fire in our replays).
- Found where Donovan's sound actually lives: the per-node dispatcher
  path (~400 helper calls/match), which needs his own record array
  (slot 0x0F still resolves to Jedah's, and it is too short).
- Wrote `[[sound_table]]` (generator kind + manifest row, id-allowlisted)
  — COMMENTED OUT, blocked on space.
- Added `tests/test_don_sound.sh` (music-range tripwire + frozen id
  inventories) and wired it into the battery.

## What 14z-49 closed

- **HUD mugshot + name (was: Jedah's art + "JEDAH" text).** Pipeline
  mapped end-to-end (engine_internals 14z-49 section): per-char
  tables 0x89884/0x898C4, stagers, and the per-GAME stager base —
  vsavj +0x3800, vs2 +0x4200 (live-OBJ measured after a wrong-base
  first placement). Fix: two effect_tail places (0x4D62→0x3DC8 2x2,
  0x4D55→0xBE8C 3x1) + name-table entry 0x0F aux_pokes.
- **Select medallion (was: Jedah's icon).** Wheel = ONE static OBJ
  record (0x272A72, coords 0x32A50A) — full decode in
  engine_internals. Donovan's icon (vs2 0xB10B 3x2) placed over
  Jedah's cell tiles 0xB526 + select pal row 14 block A ported.
  **The first attempt hit GALLON's 3x3 cell (pal-07 numerology
  trap) — reverted same-session; GOTCHAS entry; the colors gate now
  carries a Gallon-cell-intact tripwire.**
- Two new GOTCHAS: venue-asset cell identification (measure the
  cursor ring + color-render the art, never trust index==char-id)
  and the replay.lua DUMPS separator (';' — commas rc=3 silently).

## Queued next — B4 is ONE MEASUREMENT from its answer

State: the canary is now a clean single-variable experiment and it FAILS
in an informative way. Everything except one link in the chain is proven.

**Proven (don't re-derive):**
- Regions are genuinely real — FBNeo's own load report says
  `68K 0x00600000`, `Graphics 0x03000000`, `QSound 0x01000000`.
- All 12 gfx members load OK, group C included.
- The 19-bit address path is CORRECT: `y=0xb065` -> `n=0x0536CA` ->
  byte `0x29B6500`, i.e. bank 5 at the same offset within group C
  (`0x9B6500`) that the source tile has within group B. Guard passes.
- Group C's content is NOT what gets fetched (zero-filled vs
  copy-of-group-B render identically).

**So the bug is in where the loader PUT the bytes.** Do this:

1. Add a gfx-buffer dump to the harness (`CpsGfx` + offset + length ->
   file). Small, and it is on the B5b instrument list anyway.
2. Dump 128 bytes at `0x29B6500` and at `0x19B6500` on the canary build.
   Equal -> the address path and placement are both fine and the fault is
   further down (palette/decode); different -> **load-map bug**, fix in
   `Cps2LoadTiles` / `Cps2LoadOne` / the `CpsGfxLoad` advancement for a
   third group.
3. Re-run the canary; pixel-identical is the pass condition.

Reproduce the canary:
```
python3 tools/build_wide_romset.py "$ROMDIR" build/wide0/rompath \
        --qsound 2 --gfx 4 --prg 4 --gfx-copy-group-b
CPS2_WIDE_CANARY=1 FBNEO_HVIDEO=/tmp/can.vid ROMDIR=... \
  FBNEO_ROMPATH=$PWD/build/wide0/rompath \
  tools/run_replay_fbneo.sh vsavjw tests/replays/02_demitri_vs_cpu.rpl /tmp/can.log /tmp/sb
# compare /tmp/can.vid against the same replay on stock vsavj
```
Emulator output (region sizes, per-member load lines, any printf) goes to
`<sandbox>/fbneo_replay.log`, NOT the terminal. And no `FBNEO_HVIDEO`
means the sprite path never executes.

**Do not author content into the extension until B4 passes.** PRG 6MB /
GFX 48MB / QSound 16MB are declared and inert (B0-B3, 24/24 each, gate
re-run green with the canary off) but the gfx half is not yet usable.
The PRG half of B4 is independent and can proceed in parallel: copy a
data block into the extension, repoint ONE pointer (candidate: a per-char
sound record array via `PRG:0xBF41A`, ~400 reads/match), require
bit-identical RAM.

## Measurement kit (14z-49 additions)

- Wheel/HUD OBJ anatomy: dump 708000-709ff8 at the venue frame
  (in-match HUD f2600 on replay 56; select f1500 on replay 58) —
  HUD strip entries are OBJ, staged fresh each frame; the in-match
  strip does not exist on the VS splash.
- Cell identification kit: cursor ring = pal-1e pieces (center it
  over cell boxes); color-render candidate art with its LIVE
  palette row (gfx_tiles decode + 90c000 dump; the decode viewer
  needs the half-swap — see session transcript renders).
- Select palette live rows: 90C000 + row*0x20, bright nibble F at
  runtime, ROM sources bright-0 (search masked).
- Prior kit (14z-42): tap_writes.lua, GUARD_PROBE, POKES/DUMPS on
  replay.lua — DUMPS entries ';'-separated, END-INCLUSIVE ranges.

## Gotchas most likely to bite next session

- DUMPS separator is ';' — comma multi-dumps exit rc=3 with no
  artifacts after a full boot.
- Venue asset cells: identify by cursor-ring measurement + color
  render, never by pal-index/char-id numerology (the Gallon trap).
- A cited address in a session log is a CLAIM — grep the manifest
  and xxd the built image before building a theory on it.
- Engine-side tuning constants can drift between engine generations
  with zero ported-byte differences — A/B-tap obj fields.
- POKE VALUES feed the CPU AI — any poke change reshuffles
  downstream choreography in multi-round scripted replays.
- The battery script builds donovan6 itself — never rebuild while
  it runs. Background any run >10 min.
- ROMDIR must pass tools/audit_roms.py first; keep it play-free.
