# NEXT SESSION — orientation (session 14z-54, 2026-08-03)

Read STATE.md sessions 14z-53..54 (the CPS-2 WIDE pivot, Phase A, and
Phase B0/B1) and
docs/cps2_wide.md after this. The approved architecture plan is archived
at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are
the project's best instrument; reference data they provide goes straight
into gates.

## Ship state — frozen build stands; WIDE profile half-proven

Frozen reference: `b91647c7` = **donovan-m2c** (stock-size; unaffected by
any of the WIDE work). Dev head for the Donovan content: `ae701ffb`.

**CPS-2 WIDE v1** (docs/cps2_wide.md): PRG 6 MB / GFX 48 MB / QSound
16 MB, profile-gated, governed by Rule 1 v2. Phase A all green; **B0
(QSound) and B1 (GFX) are grown and proven inert** — 24/24 bit-identical
each, on both the emulator superset invariant and profile inertness. So
far the profile has cost **zero** emulator core lines; B2 adds its only
conditional.

FBNeo now carries two separate patches: `0001` (frontend harness) and
`0002` (the WIDE driver descriptor). `tools/setup_fbneo.sh` applies both,
or `WIDE=0` for the harness-only reference binary.

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

## Queued next — Phase B continues (B0 and B1 are DONE and green)

Gate for every step: `ROMDIR=... FBNEO_REF=<pre-wide binary> tests/test_wide_profile.sh`
(build the reference once with `WIDE=0 tools/setup_fbneo.sh`, keep it
somewhere outside the tree). Rebuild the overlay with
`tools/build_wide_romset.py <romdir> build/wide0/rompath --qsound 2 --gfx 4`.

- ~~B0 QSound 8->16 MB~~ **DONE, 24/24 bit-identical.**
- ~~B1 GFX 32->48 MB~~ **DONE, 24/24 bit-identical.**
- **B2 — the bit-12 promote line**, the profile's ONLY real core edit.
  Add a `Cps2Wide` flag (set by the vsavjw driver entry, never by the
  stock ones) and make `cps_obj.cpp:429-434` do the CPS-2 Turbo promotion
  under it: `if (y & 0x1000) y |= 0x8000; n |= (y & 0xE000) << 3;`. Take
  the line, NOT the Turbo profile (which also forces 32 MHz, the PRG
  clamp, a different tile loader and a scroll hack). The gate's emulator
  superset invariant is what proves the flag never leaks into stock runs.
- **B3 — PRG 4 -> 6 MB.** A1 measured this as zero core lines
  (`SekMapMemory(CpsRom, 0, nCpsRomLen-1)` already covers it). Append four
  zero-filled 0x80000 program members to the vsavjw descriptor. Watch the
  encryption boundary: only $000000-$0FFFFF is encrypted, so extension
  space is raw — which makes it EASIER to use than hole A.
- **B4 — the canary build** (highest value per unit of work): relocate an
  EXISTING character's anim block into the PRG extension and repoint its
  bank entry, and move one legacy tile into gfx group C with a bank value
  carrying bit 12. Both have bit-exact vanilla oracles, so one build tests
  reachability, 32-bit pointer width, PC-relative distance, the crypt
  boundary and 19-bit addressing at once.
- **B5 / B5b — MAME parity, then suite preservation.** Never reduce
  coverage: FBNeo-only requires porting the instruments into harness.cpp
  and proving equivalence against known findings first.

Then Phase C (multi-tenant pipeline; its first item, the address-space
model, also unblocks the stuck 352-byte sound table) and Phase D.

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
