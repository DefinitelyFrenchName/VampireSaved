# NEXT SESSION — orientation (updated mid-14z-66, 2026-08-07)

**Start here: playtest round-1 worklist in progress — items 1+2 CLOSED
and committed, build/hui4 = 44be1266 is PING #3 (EX crash fixes — BOTH
FG crash sites — + his true walk speeds). Round-2 maintainer report:
speed + ES confirmed; the second FG crash root-caused and fixed same
session. Items 3+4 are measured to root-cause class; STATE.md 14z-66
sections are the worklist.** Frozen references unchanged (donovan-m3a
4b7d0dc7 / m5_stock 6c93cfa8, m3a-reproducible PASS on every commit
this session).

## Where each worklist item stands

1. EX crash-reset — CLOSED (both crashes). (a) Voice-cue tripwire (->
   vs2 0x4EFA farm row) explained the shared first crash; three
   stubbed_sound overlay rows. (b) The round-2 FG crash was the
   capture-anim shadow over-index — victim's shadow servant walks the
   shared table with his vs2 seq 0x488; fixed by the shadow_seq_guard
   site thunk (ungated range clamp at 0x8245C, patch="jmp"); boot gate
   masked-v2 EXACT with the thunk live. Gate tests/test_hui_ex.sh (3
   sections: guard-clean AND stock-decrement; replay 77 = the
   full-sequence FG).
2. Speed — CLOSED. param32 tables are 32-row/no-fold; his true pairs
   serve from variant rows 0x10 (port_param32 opt-in; Donovan
   flagless). Gate tests/test_hui_walk.sh; 11k-soak hazard re-exam
   clean.
3. Air dash + float — OPEN, root-cause CLASSED: the float is a vs2
   ENGINE jump-seq extension (0x25948: sub-state +2, 0x78-frame timer
   at +0x1C0, flavor-forked via +0x3C2) that vsavj's engine lacks —
   the state_hook/engine-hook class. First probe: catch the +0x21
   bit-7 float-license writer on native. Second deficit found:
   alias-row jump physics (the 14w gap tables; mover context is half
   the consumer decode). Instruments: replay 75, the tap recipes in
   STATE.
4. Circuit Scrapper — OPEN, narrowed: 63214 predicate tables
   byte-correct (collapse class ruled out), match branch FIRES
   (probe at placed 0xBFD98); break is at/after move-start. Next: 2P
   dummy repro (16_xemu pattern), A/B the move-start chain. Replay 76.
5. Reflect Wall + Dark Force replays — not started.

## Build / validate / playtest

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh   # after every machinery change
tests/test_hui_soak.sh           # 11k guarded soak + round-2 pods
tests/test_hui_boot.sh           # boot + masked-v2 EXACT legacy leg
tests/test_hui_ex.sh    [build]  # EX moves fire + guard clean
tests/test_hui_walk.sh  [build]  # velocity port static + measured
tools/run_hui_behavior.sh        # the interactive playtest build (hui4)
```

## Standing facts (do not re-derive; see also 14z-65 list in STATE)

- Plain-runner vs -debug guard timelines DIVERGE mid-match: tap
  windows measured in one do NOT transfer to the other (cost a probe
  this session).
- tap_writes/replay-guard runs on NATIVE vs2 take the same forced-pick
  POKES (same commit field) — replays 71-76 run unchanged on vsav2 as
  ground-truth legs.
- The anim relocation delta for H is 0x16FC02 (ours = vs2 - delta) —
  read ours' anim pointers through it when comparing dumps.
- SET-AWARENESS: wide_ext builds pack as vsavjw; a vsavj-set run
  silently tests the PRISTINE ROM (GOTCHAS false-green).
