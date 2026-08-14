# NEXT SESSION — orientation (written at the close of 14z-87, 2026-08-15)

> ## START HERE — THE DING RULING (maintainer decision pending)
>
> 14z-87 root-caused the sword-plant "ding" and RETRACTED the 14z-86
> diagnosis at its root. The mechanism (measured end-to-end,
> engine_internals "The per-node sfx dispatch, third pass"):
> `(0x382,A6)` is the fighter's VOICE-FLAVOR CLASS; at a
> match-sequencer event the engine BORROWS P1 a class
> (`PRG:0x0AEF6`) from the OPPONENT's row of the candidate table
> `0x00B268` — vs2's rows include the tenants' classes, vsavj's
> don't, so tenant engine-voice events play a random VANILLA flavor
> (a lottery: the in-use mask rides the QSound-latch phase; measured
> borrows 0x06/0x0C/0x09/0x00 MAME, 0x04 FBNeo).
>
> **BLOCKED ON: the maintainer ruling — STATE "Decisions pending —
> 14z-87"**: (a) accept as a per-game engine-voice deviation, or
> (b) RECOMMENDED: the tenant-keeps-own-class thunk at `PRG:0x0AEF6`
> (skip the borrow when `(0x382,A1)` pre-value ≥ 0x10) — tenant voices
> come from their own authored M5 arrays (Donovan node 13 → authored
> 0x61, sample-backed), covers H/P for free, removes the lottery; COST:
> an engine-site hook on a legacy-reached path → flicker inventories
> may move → re-measure + ratification (2026-07-27 standing watch).
> Implementation checklist if (b): measure the consumers of `$FF8114`
> (index) and `$FF8100` (voice number) before choosing skip-whole vs
> skip-write-only; then rebuild solos+merged, run
> `tests/audit_voice_borrow.sh` with `VOICE_BORROW_EXPECT=own-class`,
> the trap/voice gates, and the merged legacy audit with the flicker
> re-measurement. Option (c) optional either way: port vs2 rows
> 0x10/0x11/0x13 of `0x00B268`/`0x00BB68` into our variant rows (the
> mirrored borrow direction; data-only).
>
> **New instruments (captured):** `tests/lua/read_tap.lua` (non-debug
> PC-attributed READ+WRITE tap — serializes state-dependent values in
> ONE run; the instrument that broke the case) and
> `tests/audit_voice_borrow.sh` (the mechanism frozen as lottery-proof
> invariants; GREEN on don_m4, 2 verdict controls, ~6 min).
> **New gotchas:** cross-run correlation of state-dependent values
> [platform]; +0x382 is not the char id in match [game].
>
> **Carry-forward notes:**
> - No build shipped in 14z-87 — donovan-m4/huitzil-m12/pyron-m6 and
>   build/m3b_merged6 stand unchanged; the 14z-86 battery remains the
>   latest green.
> - OPEN SUB-ITEM (new, unattributed): the ours-only P2-block class-3
>   node-18 dispatch (ring id 0x62B at f3966 of rig 90; native does
>   not fire it in the window) — an EVENT difference, separate from
>   the flavor mechanism; the (b) thunk would not change it.
> - The 14z-86 items still open: the M5 sfx odds
>   (0x112/0x14a/0x173/0x31B), the flaky Sasquatch-intro crash rig
>   (STATE 14z-85f, stays armed), Pyron 2P-hover medallion whitening,
>   H-vs-P stuck direction, round-end flicker (needs the maintainer's
>   recording), win-screen QUOTEs, select-medallion polish.
>
> ## Load-bearing laws from 14z-87 (do not re-derive)
>
> - Never correlate a state-dependent value across runs — serialize
>   read+write in one run; write watches run UNWINDOWED first (the
>   boot POST is the liveness control).
> - Debug and non-debug are different worlds AND identical non-debug
>   runs differ where sound state feeds a decision (the QSound-latch
>   one-frame phase) — gate on run-stable invariants, not lottery
>   outcomes (audit_voice_borrow.sh is the worked example).

## Current builds (registry — unchanged from 14z-86)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged6 | UNREGISTERED (pending S6 freeze) | moves with generator (729 ops) |
| build/don_m4 | **donovan-m4** | 84f49aaa |
| build/hui39 | **huitzil-m12** | e1f598d6 |
| build/pyron24 | **pyron-m6** | 4c6e3fb6 |
| build/m5_stock | stock twin | 6c93cfa8 |

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2
tests/audit_voice_borrow.sh build/don_m4       # ~6 min — the 14z-87 mechanism gate
tools/build_merged.sh build/m3b_merged6        # ~15 min (729-op fixture)
tests/audit_qs_voice_batch.sh build/m3b_merged6  # ~10 min — keyon A/B
tests/audit_qs_voice_wav.sh build/m3b_merged6    # ~12 min — EAR-level A/B
tests/audit_trap_parity.sh build/m3b_merged6   # ~5 min — ejection+chirp
tests/test_qs_songs.sh                         # ~30 s — song machinery
tests/test_tenant_loop.sh                      # generator gate (531/729)
tests/test_m3a_reproducible.sh                 # ~6 min (all four refs)
```
