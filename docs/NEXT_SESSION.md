# NEXT SESSION — orientation (session 14z-53, 2026-08-03)

Read STATE.md session 14z-53 (the CPS-2 WIDE pivot + Phase A results) and
docs/cps2_wide.md after this. The approved architecture plan is archived
at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are
the project's best instrument; reference data they provide goes straight
into gates.

## Ship state — frozen build stands; the project has pivoted to CPS-2 WIDE

Frozen reference: `b91647c7` = **donovan-m2c** (validate any copy with
`tests/run_suite.sh`; fingerprint auto-detects).
Dev head: `ae701ffb` (m2c + the 14z-52 sound restores; battery green).

**The work has re-contextualized.** The 18-character goal cannot fit a
stock CPS-2 (measured: ~886 KiB PRG and ~6-7 MB of tiles short), so the
project now has a named extended hardware profile — **CPS-2 WIDE v1**
(PRG 6 MB / GFX 48 MB / QSound 16 MB), spec in `docs/cps2_wide.md`,
governed by Rule 1 v2 (profile-gated emulator changes + an emulator
superset invariant). **Phase A measurements are all green** and two of
them corrected the design — see STATE 14z-53. The entire profile costs
ONE gated conditional of emulation logic; everything else is table data.

Phase A is rerunnable in one command:
`ROMDIR=... tests/audit_wide_phase_a.sh`

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

## Queued next — Phase B: prove the profile inert (one variable per build)

Each step is its own build and its own gate, so a failure names exactly
one variable. Gate = `tests/run_battery_m2.sh` PLUS the new emulator
superset invariant (patched binary running STOCK vsavj must reproduce the
frozen vanilla expectations bit-for-bit).

1. **B0 — QSound 8 -> 16 MB**, two zero-filled 4 MB members. Legal under
   Rule 1 even as originally written; zero core lines. Rehearses the whole
   grow-and-prove workflow at minimum risk. **Also fix the fingerprint
   here**: `tools/build_fingerprint.py` covers only the program image, so
   gfx/qsound members and the emulator profile are currently invisible to
   it (they live in a hand-written registry note).
2. **B1 — GFX 32 -> 48 MB**, four zero-filled members, no bit widening.
   Isolates `nCpsGfxLen`/`nCpsGfxMask`. A3 predicts inert; if the build
   disagrees with the prediction, stop and re-derive.
3. **B2 — the bit-12 promote line** under a new `Cps2Wide` driver flag
   (new clone descriptor beside `VsavjRomDesc[]`; never mutate the stock
   descriptor).
4. **B3 — PRG 4 -> 6 MB**, zero-filled extension (A1 says linear is safe).
5. **B4 — the canary build** (highest value per unit of work): relocate an
   EXISTING character's anim block into the PRG extension + move one
   legacy tile into the new gfx group with a bank value carrying bit 12,
   and draw it. Both have bit-exact vanilla oracles, so this tests
   reachability, pointer width, PC-relative distance, the encryption
   boundary and 19-bit addressing at once with zero RE ambiguity.
6. **B5 / B5b — MAME parity, then (only if MAME walls) suite migration to
   FBNeo.** Never drop coverage: B5b requires porting the instruments into
   harness.cpp and proving equivalence by re-deriving known findings.

Then Phase C (multi-tenant pipeline; starts with the address-space model,
which also unblocks the stuck 352-byte sound table) and Phase D
(Huitzil, Pyron, select screen).

Parked, unaffected: the M5 voice-sample decision (B0 unblocks it), the
roster-access mechanism (resolves after the roster physically exists).

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
