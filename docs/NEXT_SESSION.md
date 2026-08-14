# NEXT SESSION — orientation (written at the close of 14z-85g, 2026-08-14)
#
# EAR-CHECK FIRST: the trap-detonation chirp is restored on
# build/m3b_merged3 (and solo build/hui36) — the maintainer's ears are
# the final gate for a sound item.

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
> ~~FIRST ACT: the maintainer's playtest of `build/m3b_merged2`~~
> **DONE (maintainer, 2026-08-14): "Final Guardian corrected, overall
> everything is as expected"** — but the playtest surfaced ONE flaky
> crash reset (Don-perfect-win → Sasquatch intro; see Still open
> below and STATE 14z-85f). Next, in maintainer-pressure order —
> the crash rig first if the maintainer hits it again:
> 1. ~~Plasma-trap detonation sound parity~~ **CLOSED AND THE
>    DETONATION RESTORED (14z-85g, huitzil-m9)**: the chirp's sample
>    is byte-identical in vsav's own QSound image (the maintainer's
>    field call, proven) — vs2 farm stub 0x4F2E's blanket 14z-65
>    silence replaced by a synthesized sound_stub playing vsavj
>    0x199. Fires at native timing on replay 87, both attempts. The
>    EJECTION sound (0x739, record node 10) stays silent — the one
>    remaining M5 item for the trap (no vsavj equivalent exists).
>    0x049A = periodic ambient (14z-82d attribution retracted). Gate:
>    audit_trap_parity (re-frozen to the restored state). MAINTAINER
>    EAR-CHECK PENDING on build/m3b_merged3 / build/hui36.
> 2. **THE M5 VOICE-SAMPLES ARC** (ruled GO; brief in STATE 14z-85c;
>    Z80 RE state in 14z-85d — id table @FILE 0x11006 4B/id both
>    games). **OPENS WITH THE TRAP PILOT (14z-85g): port vs2's two
>    trap samples (0x73A ≈ one ~20KB window bank 108; 0x739 needs the
>    45-frame re-probe) into the WIDE QSound upper 8MB, NEW free
>    vsavj ids, remap record nodes 10/11, re-freeze
>    audit_trap_parity** — two ids, one array, the smallest end-to-end
>    proof of the whole arc. First concrete step unchanged: decode the
>    0x02E5 id-entry consumption from the captured qtrace → entry
>    format + sample bank/start/end. Restored ids CANNOT keep vs2
>    numbers (0x700+ are vsavj MUSIC).
> 3. ~~Tenant DEFENSE rows decision~~ **DECIDED (maintainer,
>    2026-08-14): keep the vanilla vsavj approximation** — choice +
>    exact values + the option-(a) change recipe documented in
>    docs/project/tables/defense_rows.md (Pyron needs nothing either
>    way; the delta is 2 rows + 2 threshold bytes). No work item.
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
> - tests/audit_trap_parity.sh — NEW (14z-85g): the trap-sound parity
>   gate (native + build, frozen per-attempt inventories, forbids
>   0739/073a on ours, verdict control).
> - tests/lua/ring_tap.lua — FULL=1 mode: complete 16-byte entry
>   capture (default mode line-compatible).
> - tests/audit_trap_sound.sh — RE-SCOPED: spawn + ring-liveness lock
>   (0x049A = periodic ambient; the detonation attribution retracted).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged3 | UNREGISTERED (pending ear-check + S6 freeze) | moves with generator (678 ops) |
| build/m3b_merged2 | superseded (pre-chirp merged; FG-fix reference) | superseded |
| build/m3b_merged | pre-FG-fix merged — audit_fg_parity's known-bad reference | superseded |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui36 | **huitzil-m9** | 3d9ffc89 |
| build/hui34 | superseded m8 (audit_trap_parity's known-bad reference) | c48cd722 |
| build/pyron23 | **pyron-m5** | 65e9a40e |
| build/hui33, pyron22 | superseded m7/m4 | 284e3b1c / ac22418f |
| build/hui32, pyron21 | superseded m6/m3 (extract dirs = tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- **FLAKY CRASH RESET (14z-85f field report, priority by maintainer
  pressure): 2P Don-vs-Pyron → Donovan PERFECT win → COM Sasquatch
  second match → reset at the intro.** Not reproduced (maintainer
  tried; no prior record — archaeology done). Full recipe, mechanism
  candidates (stale pool tags across the transition / perfect-path
  stamp site / wrong pointer) and the designed rig (forced-Sasquatch
  poke + tripwire breakpoints via bp_regs.lua + pool dumps, N=20)
  in STATE 14z-85f. NOTE: a tripwire fire here is the instrument
  working — capture the reset PC before theorizing.
- THE M5 VOICE-SAMPLES ARC (ruled GO). The trap DETONATION no longer
  needs it (restored 14z-85g); the trap EJECTION (0x739) is now the
  smallest single M5 target, alongside the voice blocks.
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
