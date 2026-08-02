# NEXT SESSION — orientation (session 14z-49, 2026-08-02)

Read STATE.md session 14z-49 (HUD mugshot/name + select medallion)
after this.
The maintainer tests frequently and reports precisely — their reports
are the project's best instrument; reference data they provide goes
straight into gates.

## Ship state — all three per-slot venue assets show DONOVAN

Build fingerprint `b91647c7` (dev head; register at freeze time).
The whole 14z-48b asset family is closed on it: in-fight HUD mugshot
(brown Donovan 2x2 beside the timer), HUD name plate ("Donovan" gold
script), select-wheel medallion (Donovan icon in Jedah's ringed
cell). Colors + reactions gates extended and green; battery result:
see STATE 14z-49 (queued at entry time).
Battery: `ROMDIR="/Users/koneko/Developer/Vampire Saved/ROMS" tests/run_battery_m2.sh`
(~35 min; ROM audit first per CLAUDE.md §3).
Dev builds: `GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/donovan6`
(a bare build FAILS on 58 open reconciliation refs — expected).

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

## Queued next (in order)

0. **MAINTAINER RATIFICATION NEEDED (verification-basis change):**
   third masked window `$FF4182-$FF41A1` — the palette-fade staging
   slot where the INTENDED medallion recolor surfaced in
   05_timeout_idle. Full write-up: STATE 14z-49b + Decisions
   pending. All frozen masked logs were regenerated on the new
   basis (they're in the commit).
1. ~~Maintainer verification round on `b91647c7`~~ DONE (round 63):
   "both medallion portraits are clean, no regression". Still open
   on their side: the full-cast ES-finish pass.
2. **M5 sounds** (next real milestone item): dispatcher id-table
   translation, NOT unstubbing the helper (reconciliation row note
   at vsav2=0x005122). The walker's per-node sfx call site + param
   tables are mapped (engine_internals walker section).
3. **Freeze candidacy:** the dev head has accumulated 14z-42..49
   (LS freeze, ES chain, win screen, deity states, accent fallback,
   HC farm_ports, HUD/medallion assets) — all gate-locked and
   maintainer-confirmed except 14z-49 (pending round). Consider
   proposing an M2b-CORE+1 freeze after the maintainer round.
4. Small parked items: row-0x0F fixture override port (statue
   accents), table-B 0x38C1D8 slot-0F repoint (alt-color), win-quote
   palette, mash A/B for ES version.

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
