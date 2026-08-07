# NEXT SESSION — orientation (written at the close of 14z-66, 2026-08-07)

**Start here: THE ROUND-1 PLAYTEST WORKLIST IS CLOSED — all four fix
items maintainer-confirmed in play (rounds 2-6), D1 RATIFIED (VS2
default), and the coverage replays (Reflect Wall GC + Dark Force)
landed native-matched. build/hui4 = 2898c495 (ping #5, confirmed) is
current.** Frozen references unchanged (donovan-m3a 4b7d0dc7 /
m5_stock 6c93cfa8; m3a-reproducible PASS on every commit).

## What 14z-66 closed (details: STATE 14z-66; bytes: patch_notes)

1. EX crash-resets — three distinct sites (farm-voice tripwire,
   shadow-seq over-index on capture victims, the capture-pose
   data-in-code garble). Mechanisms added: [[data_in_code]] +
   crypt-region census (5 reroutes), the shadow_seq_guard thunk.
2. Speed — param32 rows 0x10 (32-row/no-fold tables measured);
   port_param32 opt-in.
3. Float + air dash — THE BIG ONE: vs2 routes the jump seq BY CHAR ID
   to a per-char handler (0x2592A); cloned (x02592a), thunk-routed at
   vsavj's live twin head 0x22A0E. NEW mechanism [[pcrel_escape_fix]]
   (engine-style regions carry oracle-invisible pcrel escapes —
   x026142 had them SINCE 14z-65; fixing them ALSO healed item 4 and
   several would-be future mysteries). Flavor polarity corrected by
   measurement (H's VS2 = +0x3C2 0x00).
4. Circuit Scrapper — healed by the x026142 escape fix;
   native-matched on the 2P dummy (frame-identical, damage-identical).
5. Coverage replays 80/81/82 (grab, RW GC, DF) — all native-A/B'd.

## DONE SAME SESSION: the oracle battery (landed; see below). THE
## OPENER IS NOW: the alias-physics port (the one family behind every
## remaining feel delta), then M3b Phase 2 (Pyron) / gfx.

## the oracle battery analog (item 5's remainder) — LANDED

The 17/18-style native-vs-ported field comparison: a long input
script run on native vs2 AND ours, compared at anchors
(tools/compare_fields.py + tests/fields_m2a.tsv are the template;
tests/test_m2a_stage4_oracle.sh the pattern). The 2P-dummy rig
(replays 80-82: EARLY-WINDOW pokes 1400-1500 ONLY — later 2P pokes
leak into P2's load, measured) is the clean-room. Known deltas it
should quantify (all one family — ALIAS-ROW PHYSICS, the 14w gap
tables): float ceiling 109.4 vs 121.1, grab throw-arc height, RW
knockback 474 vs 487, the ~15px DF-walk drift, ground-dash length.
Decoding the jump/knockback physics consumers (the mover context is
half-decoded — STATE) turns all five into one port.

## Gates (all green at close; run before ANY commit)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after machinery changes
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_soak.sh                  # 11k chaos + round-2 pods
tests/test_hui_ex.sh    [build]         # 4 sections incl. FG aftermath
tests/test_hui_walk.sh  [build]         # velocity port
tests/test_hui_air.sh   [build]         # float + air dash signatures
tests/test_hui_grab.sh  [build]         # Circuit Scrapper native datum
tests/test_hui_pairs.sh [build]         # RW GC + Dark Force
tests/test_hui_oracle.sh [rompath]      # THE oracle battery (4 locks, ~10 min)
tools/run_hui_behavior.sh               # interactive (build/hui4)
```

## Standing facts (14z-66 additions; do not re-derive)

- 2P forced-pick pokes: frames 1400-1500 ONLY (late pokes leak into
  P2's load and make P2 a variant id — the invalidated victim sweep).
- The content-twin trap: vsavj keeps byte-identical copies of engine
  code inside per-char families (0x26A58 = ANAKARIS's jump handler,
  not the live generic one at 0x22A0E via stepper 0x225C4) — find
  live handlers by TRACING the dispatch, never by byte search alone.
- Engine-style regions (clones/shared zones) need [[pcrel_escape_fix]]
  — pcrel escapes are invisible to the sibling oracle. The census
  scan for crypt-region data tables is in the session log; run BOTH
  censuses for Pyron's regions and at Donovan's next re-freeze.
- Site-twin resolution (bracketing known pairs, reading vsavj's own
  branch at the interpolated site) beats pattern search for
  drifted engine subs; double-site agreement = the verification.
- Anim node headers carry the float license (bit 7 of +0x21's word);
  node stride 0x18; shadow-seq id = low 13 bits of node +0xC.
- After the behavior polish: M3b Phase 2 (multi-tenant merge with
  Pyron) + Phase 3/4 (gfx — H's art, the garble's end) per
  docs/M3b_plan.md.
