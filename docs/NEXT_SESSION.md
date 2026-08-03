# NEXT SESSION — orientation (session 14z-56, 2026-08-03)

Read STATE.md sessions 14z-53..56 (the CPS-2 WIDE pivot, Phase A,
Phase B0-B3, and the invalid B4 canary) and
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

## Queued next — B4 REDESIGNED (attempt 1 was an invalid canary)

Attempt 1 remapped 15 characters' per-char bank rows to the new gfx banks
and required pixel-identical output. It failed uninterpretably, because
**the per-char bank word also drives game logic** — the same program
diverges in work RAM under MAME, which has no extended-bank support at
all. Two variables moved; neither could be blamed. Full write-up: STATE
14z-56 + docs/cps2_wide.md.

It did establish something valuable: **the game emits the WIDE encoding
correctly** (y-word census shows bit 12 set with the bank field shifted
exactly as designed — nothing strips it). So the remaining question is
purely emulator-side.

**Do this — change the EMULATOR, not the ROM, so only pixels can move:**
1. Group C as a byte copy of group B (already scripted; see the canary
   build steps in STATE 14z-56 / the scratch scripts).
2. A TEST-ONLY env flag (never part of the shipped profile) that ORs
   `0x1000` into the y-word of bank-2/3 sprites at the promote point in
   `cps_obj.cpp`.
3. Run the STOCK rom. Work RAM must be bit-identical (guaranteed — the
   ROM is untouched) and the framebuffer must be bit-identical too, since
   banks 4/5 now hold the same tiles as banks 2/3.
   Pixel-identical then proves exactly one thing: the 19-bit path and
   group C placement/loading are correct.
4. PRG half, same discipline: copy a data block into the 6 MB extension
   and repoint ONE pointer to it; require bit-identical RAM. Candidate
   with heavy exercise: a per-char sound record array via the pointer
   table at `PRG:0xBF41A` (~400 reads/match).

**Do not author content into the extension until this passes.** The space
is declared and inert (B0-B3, 24/24 each) but its usability is unproven.

Then B5/B5b (MAME parity, suite preservation — note FBNeo already gained
framebuffer capture), Phase C (multi-tenant pipeline; its address-space
model also unblocks the 352-byte sound table), Phase D.

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
