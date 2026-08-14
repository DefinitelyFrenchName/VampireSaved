# NEXT SESSION — orientation (written at the close of 14z-85g(2), 2026-08-14)

> ## START HERE — THE M5 VOICE ARC OPENS (planned at 14z-85g(2) close)
>
> Everything else is CLOSED and field-confirmed: FG damage native-parity
> (14z-85f), the trap detonation chirp ("correct and happening at all
> times"), the trap shock ("plasma trap feels good") — all frozen,
> gated, play-checked. Current builds: **build/m3b_merged4** (merged),
> huitzil-m10 (build/hui37, 9a948a11) / pyron-m5 / donovan-m3a solos.
>
> **THE PLAN (read STATE 14z-85d — the Z80 RE state — and 14z-85c —
> the ruled design brief — before starting):**
>
> 1. **Decode the 0x02E5 id-entry consumption** — DONE 14z-86, and it
>    rewrote the 14z-85d picture (retraction banner there; corrected
>    decode in engine_internals "The QSound Z80 driver"): the Z80 is
>    NOT encrypted; entries are 24-bit flat-file song addresses (mod
>    0x6D8, b0==0 = free row); sample records @0x45FA found by their
>    reader 0x1350; the bank field is 8-bit (banks 0x80+ expressible).
> 2. **Free-id census** — DONE 14z-86: tools/audit_qs_id_table.py
>    (bases derived from the $3B00 anchors; vsavj 240 free rows incl.
>    0x58-0xDC, 0x3D8-0x3FF). Note the id space WRAPS mod 0x6D8
>    (0x739 ≡ row 0x61); "0x700+ music" is a 68k-side convention.
> 3. **THE EJECTION PILOT (0x739 — the smallest end-to-end proof)**:
>    (a) locate vs2 0x739's sample — it keyed NOTHING in the 12-frame
>    sweep (delayed attack): re-probe on vs2 with the 45-frame window
>    (qs_sweep + qs_analyze); (b) pack the sample window into the WIDE
>    QSound image's free upper 8 MB (banks 0x80+; MAME LLE bank reg is
>    15-bit — measured; verify FBNeo's HLE side too); (c) add the Z80
>    id-table row at a free vsavj id (Z80 member patch — the driver
>    has 27,727 B free, WIDE A4; the row format from step 1); (d) wire
>    hui record node 10 via the EXISTING remap_ids machinery
>    ("0x739:NEWID" — the m9 precedent); (e) verify: qs-level keyon on
>    the new id matches vs2's, ring shows it at mine spawn, EAR-CHECK.
>    Re-freeze audit_trap_parity deliberately (0739-slot expectation).
> 4. **MiSTer check** (the ruling's condition): jtcores' QSound region
>    growth for 16 MB — a descriptor/core question, scoped in the
>    14z-85c brief step 5.
>
> **Carry-forward notes:**
> - ~~The merged legacy audit gap~~ CLOSED 14z-86: the audit ran on
>   m3b_merged4, AUDIT-EXIT 0 (leg a 14/14 verbatim). Its frozen op
>   count was re-frozen 677→678 (the m9 sound_stub op) per its own
>   protocol — tenant_loop had been re-frozen FIRST at 14z-85g.
> - tools/m68dis.py is the promoted session disassembler (capstone;
>   opcode-view vs data-view discipline in its header).
> - The flaky Sasquatch-intro crash rig (STATE 14z-85f) stays armed if
>   the maintainer hits it again.
>
> ## Corrections that must outlive 14z-85g (still load-bearing)
>
> - 0x049A is PERIODIC AMBIENT — the 14z-82d "detonation id"
>   attribution is RETRACTED (two cadence beats).
> - A 0x7xx sfx id's faithfulness is a property of its sample CONTENT,
>   not its number — content-search vsav's image (2 lines) before any
>   stubbed_sound row or M5 plan (GOTCHAS; the chirp shipped from it).
> - vsavj's victim-reaction jump table (0x2385C) ends before the vs2
>   extension classes — any ported record carrying class 0x4E+ needs
>   the alias licence check (engine_internals, the damage pipeline).
>
> ## New/changed suite members (14z-85g/g(2))
>
> - tests/audit_trap_parity.sh — chirp restored state (fails pre-m9).
> - tests/audit_trap_shock.sh — dome shock + deviation (fails pre-m10).
> - tests/replays/hui/89_hui_ex_fg_vs2.rpl / 92_hui_trap_shock.rpl —
>   native-comparable FG and deep-overlap trap rigs.
> - tests/lua/ring_tap.lua FULL mode; tests/lua/bp_regs.lua (A7-first).
> - tests/audit_fg_parity.sh / audit_fg_damage.sh (14z-85f pair).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged4 | UNREGISTERED (pending play-check + S6 freeze) | moves with generator (678 ops) |
| build/m3b_merged3 | superseded (pre-shock merged) | superseded |
| build/m3b_merged2 | superseded (pre-chirp merged; FG-fix reference) | superseded |
| build/m3b_merged | pre-FG-fix merged — audit_fg_parity's known-bad reference | superseded |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/hui37 | **huitzil-m10** | 9a948a11 |
| build/hui36 | superseded m9 (audit_trap_shock's known-bad reference) | 3d9ffc89 |
| build/hui34 | superseded m8 (audit_trap_parity's known-bad reference) | c48cd722 |
| build/pyron23 | **pyron-m5** | 65e9a40e |
| build/hui33, pyron22 | superseded m7/m4 | 284e3b1c / ac22418f |
| build/hui32, pyron21 | superseded m6/m3 (extract dirs = tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- ~~Trap SHOCK status~~ **FIXED (14z-85g(2), maintainer-ruled option
  (a), huitzil-m10 = build/hui37 9a948a11 / merged build/m3b_merged4)**:
  class remaps 0x52→0x06 route the dome hit into vsavj's native
  electric-shake — shock install verified (seq7=4, freeze 0x18).
  PLAY-CHECK CONFIRMED (maintainer, 2026-08-14): "plasma trap feels
  good" — deviation accepted in play. The trap is CLOSED except the
  M5-scoped ejection sound. Gate: audit_trap_shock (rig 92).

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
tools/build_merged.sh build/m3b_merged4    # ~15 min (678-op fixture)
tests/audit_fg_parity.sh build/m3b_merged4 # ~4 min — the FG parity gate
tests/audit_trap_parity.sh build/m3b_merged4 # ~5 min — the chirp gate
tests/audit_trap_shock.sh build/m3b_merged4  # ~4 min — the shock gate
tests/test_tenant_loop.sh                  # generator gate (491/678)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged4 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min: leg a verbatim —
                                           # RUN ONCE before any S6 motion
                                           # (last ran on the merged2 gen)
```
