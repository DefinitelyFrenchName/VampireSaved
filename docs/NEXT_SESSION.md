# NEXT SESSION — orientation (session 14z-58, 2026-08-03)

Read STATE.md sessions 14z-53..58 (the CPS-2 WIDE pivot, Phase A,
Phase B0-B4) and
docs/cps2_wide.md after this. The approved architecture plan is archived
at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are
the project's best instrument; reference data they provide goes straight
into gates.

## Ship state — CPS-2 WIDE v1 is DEMONSTRATED (B0-B4 all pass)

Frozen reference: `b91647c7` = **donovan-m2c** (stock-size, untouched by
the WIDE work). Donovan content dev head: `ae701ffb`.

**The extended profile works.** PRG 6 MB / GFX 48 MB / QSound 16 MB, for
a total emulator cost of ONE widened condition in `cps_obj.cpp` plus the
`Cps2Wide` flag lifecycle. Proven, each with a negative control:

- **B0-B3 inert** — 24/24 bit-identical (work RAM AND framebuffer) on
  both the emulator superset invariant and profile inertness.
- **B4 gfx USABLE** — 9/9 replays render pixel-perfect with 15
  characters' sprites fetched from the appended 19-bit banks.
- **B4 prg USABLE** — all 20 per-char sound tables relocated to
  `CPU:$400000+` and genuinely read (the zeros control diverges).

Gate (36 checks): `ROMDIR=... FBNEO_REF=<harness-only binary>
tests/test_wide_profile.sh` — section 3 is the standing B4 canary.
Build the romset with `tools/build_wide_romset.py ... --gfx-copy-group-b`
(it prints the descriptor rows, CRCs included — **paste them in, a CRC
mismatch silently loads 0xFF**).

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

## Queued next — B5/B5b, then Phase C

1. **B5 — MAME parity.** Pin MAME 0.288 as a submodule, add
   `tools/setup_mame.sh`, and require the source build to reproduce the
   existing frozen oracle results bit-for-bit BEFORE any profile patch.
   Then port the WIDE descriptor + the one gated line.
2. **B5b — suite preservation** (gates any FBNeo-only decision). Already
   part-delivered: FBNeo now has framebuffer capture AND a gfx-buffer
   dump (`FBNEO_HGFX`). Remaining instrument gaps: write taps with PC
   attribution, probe breakpoints with register capture, frame-scheduled
   pokes, and OBJ/palette RAM dumps.
3. **Phase C — multi-tenant pipeline.** Start with the address-space
   model (declarative region list + placement classes in
   `gen_donovan_patch.py`), which also unblocks the stuck 352-byte sound
   table. Then per-tenant manifests, slot parameterisation, gfx band
   planning, and moving Donovan off Jedah's slot.

**Content may now be authored into the extension** — that was the gate
B4 existed to open. Extension authoring rules: raw (no encryption above
`PRG:0x0FFFFF`), FILE byte order
(`words_to_file_bytes(words_from_logical_bytes(...))`), real CRC in the
descriptor, and `$400000-$40000F` reserved (CpsFrg, read-shadowed).

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
