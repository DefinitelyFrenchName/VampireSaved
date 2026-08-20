# `donovan-m8-stage4` — the M2a stage-4 gate's target

Created 14z-97 (GitHub #96, maintainer-ruled 2026-08-19). The sibling of
`donovan-m8-stock`: same generation, same track, one stage earlier.

## What build this is

`tools/build_donovan.sh 4` with `GEN_FLAGS="--allow-plausible
--tripwire-open"` — what `tests/test_m2a_stage4_code.sh` builds. Fingerprint
**`22c804c8b3330078362c539967c07c24f1757ef2`**, reproduced from a clean tree
14z-97.

**This is a pipeline STAGE, not a shipping artifact.** Nothing is ever
frozen at stage 4; no playtest runs it; it has no registry row anywhere else
in the project. The row it has in `tests/expected/registry.tsv` exists so
that the gate's target follows the pipeline instead of a name — if the
stage-4 image moves, the gate says `unregistered fingerprint` and stops,
which is the loud version of what #96 was: a gate quietly judging today's
build against a five-generation-old expectation.

## Why it is not the same set as `donovan-m8-stock`

Because a stage-4 image genuinely diverges from vanilla where the stage-6
one does not. Measured 14z-97, same mask, same basis, both fingerprints:

| replay | stage 4 (this set) | stage 6 (`donovan-m8-stock`) |
|---|---|---|
| `03_two_player_vs` | `exact` | `flicker 1 2093` |
| `29_felicia_walljump` | `exact` | `flicker 1 2436` |
| `04_select_fuzz` | `diverge 2009` | `flicker 2 1525,2009` |

The first two are the ordinary direction (stage 6 adds the graphics work,
which costs cycles, which is what the flicker class *is*). The third is the
one that needs a paragraph.

## `04_select_fuzz`: why `diverge`, and what it is NOT

At stage 4 this replay diverges at frame 2009 and **never re-converges**
(1512 of 3520 frames, one run to the end). `tools/describe_masked_shape.py`
refuses to propose a class for that shape, correctly — it is outside the
ratified vocabulary and §4 says root-cause it rather than widen anything.

**It was root-caused, in 14z-95, and it is a STAGE artifact:**

- Not the mask: re-measured under V2 against the V2 basis, identical shape.
- Not the track: `m5_stock2` (stock, stage 6) measures `flicker 2
  1525,2009`; `don_m7` (WIDE, stage 6) measures its shipping composite.
  Only the stage-4/5 image shows it.
- Byte attribution at f2200: 134 unmasked differing bytes spread across live
  work RAM (an 8-stride family at `$FF5DF9-$FF5EC9`, plus `$FF06C5`,
  `$FF06D1`, `$FF1E79`, `$FF1EA7` and ~112 more) with **no match formed** —
  both legs read character class `00` and hitbox base `0x00091f98`. It is
  the select screen in a half-ported state, which is what an incomplete
  stage *is*: stage 5 is "select plumbing" and this build predates it.

So the spec is `diverge vsavj/masked-v2 2009` — the ratified
first-divergence class, chosen over dropping the replay from the list
because it asserts strictly more: bit-identity through frame 2008, and a
divergence at exactly 2009.

**An onset moving EARLIER is the failure.** That is the whole content of
this expectation. A stage-4 build that starts diverging before 2009 has
broken something upstream of the select screen, and this catches it; a
`.skip` would not have.

**And the superset invariant is NOT asserted here.** It is asserted on the
completed artifact — by `donovan-m8-stock` at stage 6, and by
`tests/run_suite.sh` on the shipping WIDE build. Nothing about this file
licenses a legacy divergence in anything anyone plays.

## The rest

`01_attract_long` (`diverge 4278`), `11_pick_donovan` (`diverge 1080`) and
`08_challenger_join` (`flicker 2 3507,3807`) are identical to
`donovan-m8-stock`'s and are attributed in that set's README — including
the `$FF06E1` dump-diff attribution for 3507/3807, which was measured on the
stage-6 twin and holds at both frames on both stages.

Scope, and when this moves: same as `donovan-m8-stock`'s README. Both are
battery-scoped, and both carry-rename together at the next freeze.
