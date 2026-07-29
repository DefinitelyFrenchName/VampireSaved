# NEXT SESSION — 60-second orientation (written 2026-07-29, session 14p end)

Dev head: **f29cf24a** (build/donovan6; `GEN_FLAGS="--allow-plausible
--tripwire-open" tools/build_donovan.sh 6 build/donovan6`). All gates
green: double M2b stage-6 (masked legacy, full frozen flicker
inventory), M2a oracle, dual-emulator, flavor. Frozen builds: M2a
a02aeeff, M2b-core 71601263. Pushed through commit "ANITA'S FEET
FIXED" + the 14p STATE/GOTCHAS updates.

## What just happened (14p)

1. **Anita's feet FIXED** — 54-record bank-2 strip in x2b7ef4 was
   going through the bank-1 effect-tail maps. Empirical attribution
   (handler bp trace) + structural closure (record stream at src
   0x2BA120) → tools/gen_anita_bank2.py → effect_tail.json
   bank2_recs/bank2_place. AWAITING PLAYTEST confirmation.
2. **Sword/statue blink ROOT-CAUSED, not yet fixed**: the 16 in-match
   companion overlay sub-objects ($FFB800-$FFBF80, bank #$2000) walk
   JEDAH's per-char record-pointer strips (pages 0x267xxx/0x268xxx →
   records 0x271Dxx-0x272Axx, his bank-1 darkness art) — his overlay
   ANIMATES where Donovan's sword-drag/statue/Anita-body belong. vs2
   truth: same population walks strips 0x2A0Axx-0x2A1Cxx → records
   0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499). Full detail in STATE 14p +
   GOTCHAS ("companion overlay draws the HOST's records").

## Next work (priority)

1. **Stage-7: overlay strip port** (fixes sword/statue blink — the top
   visible defect). T-lookup ANSWERED this session: T is HARDCODED as
   immediates at 10 sites in JEDAH's per-char engine code (0x5F8C8,
   0x5FABC, 0x5FBD0, 0x5FDDA, 0x5FE4C, 0x5FF5A, 0x6190E, 0x619FA,
   0x837D4, 0x8C678 — opcode-space search for 0x002671C6); the overlay
   runs JEDAH's code via the vanilla slot dispatch, and per-char
   behavior lives in the DATA (streams/strips) his code walks. Two
   topologies assessed:
   - **B (recommended): port the data, poke the 10 immediates.** Port
     vs2's overlay streams+strips+records (~[0x2A05E2,0x2A4000),
     bounds via three-way diff — CAUTION: engine-shared blocks
     0x2A3B40/0x2A3B7C interleave the span), then repoint Jedah's 10
     T-immediates to the ported copy. Vanilla Jedah strip BYTES stay
     (attract demo reads them; frozen-4278 class guards the poked
     sites). Risk to verify: Jedah-code stream-walker constants beyond
     T (sibling-diff his 10 routines vs vs2's Donovan analogs first).
   - A (bigger): reroute the slot dispatch to the PORTED Donovan
     overlay code (9 T-load sites already inside ported regions —
     vs2 code 0x0891F8->0x2A0600 is the prime root-load; their strip
     refs are currently open/tripwired recon rows). More faithful,
     more surface.
   Then: (b) space audit (~15KB; hole A ~0xE80 + hole B ~0x650 are
   NOT enough — needs a real ledger pass); (c) bank-1 code triage
   (effect-tail classes) for codes 0xA3E8-0xA499; (d) pool cptr
   content-match; (e) engine-shared strips 0x15ADxx content-compare
   vs2-vs-vsavj (b800/b880 walk them); (f) gates + snapshots.
2. Win-quote palette (mechanism pinned earlier: table 0x7F196 +
   ramp blocks ~0x3A14xx; repoint-safe).
3. A5 work-var displacement audit sweep (same-value class #4).
4. Small cosmetics: quote text line, HUD name "Jedah", wheel hexagonal
   mugshot, attract palette.

## Method notes (hard-won this session — see GOTCHAS)

- Debugger bp/wp traces DESYNC replays (frame counter inflates while
  stopped). Frame-accurate evidence = replay.lua DUMPS + RAM reads
  only. Companion-slot cursors survive at frame-done (live flag clear).
- Record bank = drawing OBJECT property (+0x18), never record content.
- Breakpoint traces are samplers; close every set structurally.

## Decisions pending (maintainer)

- Roster access (select-screen redesign vs Oboro-pattern combined
  input; recommendation B recorded in STATE).
- Throw-damage magnitude: vsavj-scaling by design; oracle shows test
  throw equal to vs2. If vs2-equal damage is wanted EVERYWHERE, that
  is a rules decision (comparative measurement available on request).
