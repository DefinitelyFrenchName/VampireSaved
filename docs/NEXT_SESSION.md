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

1. **Stage-7 overlay port — ONE DECODE LEFT** (sword/statue fix; parked
   in build/manifest/overlay.wip, activate by renaming to overlay/ and
   regenerating: `python3 tools/overlay_port.py $ROMDIR/.. --ops-vsavj
   <opcode dump> --emit --out build/manifest/overlay`, then filter pokes
   per STATE 14q). PROVEN: heap placement in Jedah's dead anim area
   (legacy-clean full-length), 25 thunked T-sites (match+char-gated,
   legacy-clean), tile pipeline, object-granular closure with four
   verified grammars (see STATE 14q continuation). BLOCKER, precisely:
   streams walked at stride 8 only; the engine stepper family also has
   0x10/0x18-stride classes chosen PER OBJECT CLASS (engine
   0x15030-0x15080). Attack-id-indexed table entries whose streams use
   the bigger strides stay dead -> crash on the first 623P. NEXT: map
   each poked table (2671C6/2671E6/267224/267284 families) to its
   stepper class — disassemble the three stepper subroutines around
   0x15030/0x15057/0x150B6, find their callers/object classes, or trace
   +0x1C cursor deltas per object slot on vs2 (cursor advances by the
   stride each anim step — a RAM-dump measurement, no debugger needed).
   Then re-walk dead entries with the right stride. Probe harness:
   donprobe.sh pattern in STATE (timer-tick detector — earlier
   detectors were watchdog-fooled).
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
