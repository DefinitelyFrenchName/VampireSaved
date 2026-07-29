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

1. **Stage-7 overlay port — FINISH THE CLOSURE** (sword/statue fix;
   80% built, parked in build/manifest/overlay.wip — rename to
   overlay/ to activate). PROVEN legacy-clean: placement in Jedah's
   dead anim area (segA+tail 0x248D80, segB 0x2557B0, split 0x2A4A48),
   25 thunked T-sites (match-active + slot-0x0F gate), tile pipeline
   (3929 pairs). BLOCKER: Donovan-path watchdog crash at match start —
   false-positive relocations/rewrites corrupt stream data (blind
   long-scan; 293 relocs + 2811 tile words). FIX: structural-closure
   walk (T tables -> strips [plain long arrays] -> tag-streams
   [(FF-tag,ptr) pairs] -> records [fmt handlers all decoded, see
   STATE 14q]); restrict ALL rewrites to the closure; regenerate via
   tools/overlay_port.py; iterate with the 02-masked probe
   (/tmp bisect harness pattern) then full gates. See the three new
   GOTCHAS before touching anything.
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
