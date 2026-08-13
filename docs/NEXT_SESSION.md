# NEXT SESSION — orientation (written at the close of 14z-85f, 2026-08-13)

> ## START HERE
>
> **THE FINAL GUARDIAN DAMAGE PARITY ITEM IS CLOSED — fixed and
> verified BIT-EXACT to native vs2** (STATE 14z-85f). The mechanism was
> NEITHER 14z-85e hypothesis: the ported object-hit damage applier
> (vs2 0x28A6A, tenant x028122 copies) staged damage into vs2's A5
> work vars ($FF3494/96/98) which vsavj never reads — same-value
> class #4, and EXACTLY Donovan's session-14n throw fix, never
> propagated to H/P manifests. Six port_patch rows each →
> **huitzil-m8 (build/hui34, c48cd722) / pyron-m5 (build/pyron23,
> 65e9a40e) / merged build/m3b_merged2**. Gate:
> `tests/audit_fg_parity.sh` (native A/B, frozen staircase
> 23/23/23/23/52, ground-truthed failing on the pre-fix merged).
> The damage pipeline is synthesized in engine_internals.md.
>
> **FIRST ACT: the maintainer's playtest of `build/m3b_merged2`** —
> FG damage (should now feel native), plus H/P throw/projectile
> damage spot checks (the same applier serves them). Then, in
> maintainer-pressure order:
> 1. **Plasma-trap detonation sound** parity item (UNCHANGED from
>    14z-85e): systematic on native vs2, proximity-gated on ours; the
>    id IS enqueued when "silent" → volume/pan ring-entry params
>    hypothesis; rig = full 16-byte ring-entry A/B near/far, ours vs
>    native (audit_trap_sound has the enqueue side).
> 2. **THE M5 VOICE-SAMPLES ARC** (ruled GO; brief in STATE 14z-85c;
>    Z80 RE state in 14z-85d — id table @FILE 0x11006 4B/id both
>    games; next concrete step: decode the 0x02E5 id-entry consumption
>    from the captured qtrace → entry format + sample bank/start/end).
>    Restored ids CANNOT keep vs2 numbers (0x700+ are vsavj MUSIC).
> 3. **NEW DECISION PENDING (14z-85f): tenant DEFENSE rows** — tenants
>    ride vanilla vsavj defender-curve/low-HP-threshold rows, not
>    their native vs2 values (found in the table compare; brief with
>    options in STATE). Recommended shape: variant-gated table
>    extension, hitclass precedent. Maintainer's call; nothing blocks.
>
> ## Corrections that must outlive this session (14z-85f)
>
> - The 14z-85e "per-game scaler" AND "native hit-count" hypotheses
>   are both RETRACTED by measurement: scaler tables byte-equivalent,
>   12 ticks both games. Grep-swept; audit_fg_damage reframed (its
>   10 HP = fighter-path contact damage, never the parity number).
> - A port_patch on a shared engine-family region fixes ONE tenant's
>   copy — when a tenant imports a region, grep every manifest's rows
>   for it (GOTCHAS, project). Converse: the 14x rolled-back families
>   stay at vs2 offsets (ported readers consume them).
>
> ## New/changed suite members
>
> - tests/audit_fg_parity.sh — NEW: the FG parity gate (native +
>   build vs the frozen staircase; 2 verdict controls; fails on the
>   pre-fix merged).
> - tests/replays/hui/89_hui_ex_fg_vs2.rpl — NEW: native-comparable
>   FG rig (85-opening + five 623+2K attempts, stock-decrement tells).
> - tests/audit_fg_damage.sh — REFRAMED: regression lock on the
>   fighter-path 10 HP; no longer the parity item's gate.
> - tests/lua/bp_regs.lua — NEW instrument: replay/POKES playback +
>   auto-resuming debugger breakpoints logging registers at named PCs.

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged2 | UNREGISTERED (pending playtest + S6 freeze) | moves with generator (677 ops) |
| build/m3b_merged | pre-fix merged — audit_fg_parity's known-bad reference | superseded |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui34 | **huitzil-m8** | c48cd722 |
| build/pyron23 | **pyron-m5** | 65e9a40e |
| build/hui33, pyron22 | superseded m7/m4 | 284e3b1c / ac22418f |
| build/hui32, pyron21 | superseded m6/m3 (extract dirs = tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- Plasma-trap detonation sound parity (rig named above).
- THE M5 VOICE-SAMPLES ARC (ruled GO; the next big implementation).
- Tenant DEFENSE rows decision (14z-85f brief).
- Pyron's medallion whitening on 2P hover (row-0x1A family).
- H-vs-P stuck-direction (~1/30, possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording).
- Win-screen QUOTE (both tenants); pyron win-laugh distortion
  (M5-family); select medallions polish; region_space re-freeze;
  op-tagging for test_shared_writes; 14z-83 leg-b staleness notes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2   # run_suite needs it
tools/build_merged.sh build/m3b_merged2    # ~15 min (677-op fixture)
tests/audit_fg_parity.sh build/m3b_merged2 # ~4 min — the FG parity gate
tests/test_tenant_loop.sh                  # generator gate (490/677)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged2 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: leg a verbatim
```
