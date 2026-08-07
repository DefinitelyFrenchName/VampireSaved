# NEXT SESSION — orientation (written at the close of 14z-65, 2026-08-07)

**Start here: HUITZIL'S BEHAVIOR BUILD IS IN PLAYTEST (ping #1 delivered;
round-1 report in STATE.md "MAINTAINER PLAYTEST ROUND 1" — that section
IS the worklist).** The frozen references are unchanged (donovan-m3a
4b7d0dc7 / m5_stock 6c93cfa8, gate-verified); Huitzil's stage-4 build is
alive end-to-end: 11,000-frame guarded chaos soak green on the real
vsavjw set, round-2 pods respawning, legacy replays masked-v2 EXACT.

## The worklist from playtest round 1 (priority order)

1. EX-move crash-reset (623+2K / 421+2K): scriptable repro — extend the
   soak replay with meter-build + the exact motions; the guard names the
   site; expect the ES-chain/meter arc (Donovan m2c precedent).
2. Speed: port his param32 velocity pairs (VALUE_SKIP currently serves
   him alias-row speeds) — re-examine the 14w-b hazard first.
3. Air dash + float dead: census the states native vs2 writes for them
   (state-tap on native), trace ours.
4. Circuit Scrapper (half-circle): content-verify his 63214 predicate
   rows at 8-byte record granularity (the 14z-48 collapse class).
5. Author the guard-cancel replay (Reflect Wall) + Dark Force pair
   replays; then the oracle battery analog (17/18-style).

## Build / validate / playtest

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh   # after every machinery change
tests/test_hui_soak.sh           # the 11k guarded soak + round-2 pods
tests/test_hui_boot.sh           # boot + masked-v2 EXACT legacy leg
tests/test_hui_ladder.sh         # stages 1-3 (hook-free, bit-identity)
tests/test_extract_hp.sh         # extraction shapes
tools/run_hui_behavior.sh        # the interactive playtest build
```

## Standing facts (this session's additions — do not re-derive)

- SET-AWARENESS: a build that touches wide_ext packs as vsavjw; any
  probe run as vsavj silently tests the PRISTINE ROM (GOTCHAS false-
  green). All H gates derive the set from the rompath.
- The shared R1 map is FROZEN for Donovan (open rows = his tripwires);
  H's rows live in build/manifest/reconciliation_huitzil.toml via the
  manifest key recon_overlay. Phase 2 replaces this with row scoping.
- H's census (driver DEFAULT_ROOTS): the widened code window, the ring
  family, the shared zones (x088512 at 0x3B40), x2b7ef4 companion-anim,
  the 12 secondary handlers 64-75. obj_hook rows are IN his manifest.
- Sound: 0x7xx newcomer-voice ids stub-on-sight; shared ids via the
  batch/M5 method ONLY (raw keyon equality is NOT the M5 verify).
- Timelines: plain-runner vs -debug guard runs DIVERGE mid-match; only
  same-timeline evidence composes. GUARD_TRACE + the guard's crash-
  instant RAM dumps (crash_<frame>_ff0000.bin) are the deep tools.
- Debug instruments: tap_writes (POKES/REGLOG/STACKLOG), force_pick_
  probe (SET-aware), force_id.lua (interactive).
- M3b phases 2/3 (multi-tenant merge, gfx coexistence) queue behind the
  behavior polish; docs/M3b_plan.md unchanged otherwise.
