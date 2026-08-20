# `donovan-m8-stock` — the M2 battery's stage-6 target

Created 14z-97 (GitHub #96, maintainer-ruled option (a) 2026-08-19: *"the
battery asserts 'the pipeline, built fresh, reproduces the CURRENT freeze'.
Its specs re-point at each freeze"*).

## What build this is

`tools/build_donovan.sh 6` with `GEN_FLAGS="--allow-plausible
--tripwire-open"` and no `--profile` — the recipe `tests/test_m2b_stage6.sh`
runs, and the same one that produces `build/m5_stock3`. Fingerprint
**`a054de5c0cfe868cb0aa9722abebdffd9dfcdb0d`**, measured identical to
`m5_stock2` since 14z-91.

It is the **STOCK TWIN of the donovan-m8 freeze**: Donovan substituted over
Jedah's slot `0x0F` on stock CPS-2 hardware, versus the shipping WIDE build
(`build/don_m8`, `d038553d`) which carries him at his native `0x13` with the
extended 21-cell wheel. The twin is what proves the WIDE freezes are
profile-gated — every freeze record since 14z-86 reads "stock twin
BIT-IDENTICAL".

## Why it is a SEPARATE set from `donovan-m8`

Because the two builds carry different rosters by construction, and the
select screen is where that shows. `donovan-m8`'s specs are dominated by the
§4 v3/v4 `window`/`composite` classes with onset 889 — the wheel extension's
three appended cells. This build does not extend the wheel, so those windows
do not exist here:

| replay | `donovan-m8` (WIDE) | this set (stock twin) |
|---|---|---|
| `02_demitri_vs_cpu` | `window 889 1675` | `exact` |
| `04_select_fuzz` | `composite 2009 889-1104` | `flicker 2 1525,2009` |
| `08_challenger_join` | `composite 3507 889-1675;3807-4610` | `flicker 2 3507,3807` |
| `09_mirror_pick` | `window 889 1951` | `exact` |

Pointing the battery at `donovan-m8` would therefore red every
select-reaching replay while nothing was wrong — which is the same
generation-mismatch failure #96 was filed for, one track over. This is also
why `tests/test_dualtrack.sh` exists and why its scope was corrected in
14z-94: the tracks are *deliberately* not identical past select entry.

## Mechanism attribution for every non-`exact` spec

CLAUDE.md §4 requires it, and none of these is inherited on trust —
all were measured on this fingerprint, 14z-97, against
`tests/expected/vsavj/masked-v2`:

- **`01_attract_long` `diverge 4278`** — the attract demo reaches its Jedah
  slot, which this track patches. Ratified since M2
  (`tests/test_m2_repoint.sh`); the constant has not moved in fourteen
  generations.
- **`11_pick_donovan` `diverge 1080`** — the select-screen anim hover on the
  patched slot. Same class, same reason: the replay deliberately involves
  patched content.
- **`03` @2093, `04` @1525/2009, `08` @3507/3807, `29` @2436 (`flicker`)** —
  the ratified §4 v2 hook-cycle flicker: hooks cost cycles, interrupts land
  at skewed instruction boundaries, the frame re-converges. **Attributed
  byte-for-byte on `08` (14z-97, full-RAM dump diff vanilla vs this build at
  both frames): the only differing live byte is `$FF06E1`** — inside the
  OBJ-builder secondary stack `$FF06D0-$FF06EF`, which `docs/game/atlas/
  ram.md:62` describes as *"execution POSITION, not state … one byte at
  `$FF06E1`, one frame, identical the next frame"*. Everything else that
  differed was dead stack (`$FF7F00-$FF7FFF`), which the mask already skips.

### The one that needed root-causing: `08_challenger_join`'s 3807

This is the frame the whole of #96 came down to. `donovan-m2c` froze
`flicker 1 3507`; this build measures `2 3507,3807`, and under the §4
standing watch a grown inventory is stop-and-root-cause, not widen. It was
root-caused rather than absorbed:

1. **It is the PIN that is the outlier, not this build.** Every generation's
   expression of this replay carries 3807 except the one the gate was pinned
   to:

   | generation | `08_challenger_join` |
   |---|---|
   | `donovan-m2` | `flicker 2 3507,3807` |
   | `donovan-m2b` | `flicker 2 3507,3807` |
   | **`donovan-m2c`** (the pin) | **`flicker 1 3507`** |
   | `donovan-m5` | `composite 3507 889-1675;3807-4610` |
   | `donovan-m5w` | `composite 3507 890-1622;3809-4542` |
   | `donovan-m8` | `composite 3507 889-1675;3807-4610` |
   | **this set** | **`flicker 2 3507,3807`** |

   So "the inventory grew" was never the right reading — `donovan-m2c` is a
   single generation in which the frame happened to be absent, and the gate
   was pinned to exactly it.
2. On the WIDE track the same frame is not a flicker at all but a **window
   ONSET** (`3807-4610`): the challenger join RE-ENTERS the select screen.
   Same trigger, same frame; the wheel extension turns it into an 800-frame
   window there and leaves only the cycle-phase byte here.
3. The byte is `$FF06E1`, per the dump diff above — the documented phase
   class, not gameplay state.

## Scope: this set is BATTERY-SCOPED, deliberately

It carries the M2 battery's legacy list (14 replays) and nothing else. The
tenant-content replays are covered on this track by the battery's own
behaviour gates (`test_don_sword`, `test_don_accent`, `test_don_colors`,
`test_don_reactions`, `test_don_column`, `test_don_sound`, the oracle and
xemu gates), which is what the battery is.

**So `tests/run_suite.sh` on this fingerprint will report `NO-EXPECTATION`
for every other replay, and that is CORRECT** — an unvalidated replay must
never read as green (the 14z-61 doctrine). If someone wants corpus coverage
on the stock track, that is a freeze decision and a measuring session, not a
file to add here quietly.

## When this set moves

At the next freeze, with the rest of the generation: carry-rename it to
`donovan-m9-stock` (or whatever the generation is called), re-measure the
shapes, and move the registry row. The name is tied to the WIDE freeze it
twins on purpose — that pairing is the thing the battery asserts.
