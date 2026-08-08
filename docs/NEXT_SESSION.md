# NEXT SESSION — orientation (written during 14z-69, 2026-08-08)

**The DF-style opener is BLOCKED ON THE MAINTAINER, not on analysis.
The native leg turned out to be reachable all along, and with it in
hand the symptom does not reproduce. Do not resume mechanism hunting
until the repro conditions come back — the questions are listed below.
Everything else on the Phobos worklist is unchanged and unblocked.**

**PING #10 = build/hui11 (5c6dbe43) is still the current build.**
Nothing in the build changed this session; the deliverables are a
replay, a gate, a checker and four corrected documents. Frozen
references untouched (donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8).

## What changed, and why it matters beyond this item

**The native leg is reachable for ANY tenant screen.** The ordinary
early-window poke forces Huitzil on native `vsav2` in six seconds:

```sh
POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"   # P2 = $FF8B82
tools/run_replay_mame.sh vsav2 <replay> out.log
```

"The native leg is unreachable" came from ONE 14z-68j attempt with
**replay 61**, whose input timing is authored for OUR wheel. Anything
parked on "needs a native reference" — the win QUOTE set, the child
shadow band, effect art — can now be A/B'd directly. Poke BOTH sides
when sprite lists are compared (P2 = 0x03 is Victor on both games).

## THE OPENER: ask the maintainer, then measure

The DF-style A/B is built and green: `tests/test_hui_df_style.sh`
(replay 85, native vsav2 vs the build). On hui11 the palette row is
byte-identical to native across 118 frames and his sprite set matches
native's — with no afterimages and no recolour — at the RAM layer, the
render layer (PNGs), on FBNeo as well as MAME, and whether he is poked
in or hand-picked on cell 0x10.

So the harness has not seen what the maintainer has. **Ask:**
1. Which build were they on when they saw it (hui11, or an earlier
   ping)?
2. 1P (arcade/CPU) or 2P? Which opponent and stage?
3. Round 1 or after a round transition?
4. Does it start at DF activation, or only after some action?
5. A screenshot or short capture, if it is cheap for them — one
   settled the win screen after hours of derivation.

Then point the existing rig at that state; the instrument is the easy
part now. **Do NOT** resume the search for a per-character style
discriminator first: the last two sessions did that, and the readings
that motivated it were artefacts (below).

**RETRACTED this session — do not re-follow (docs/GOTCHAS.md):**
- "the afterimages ARE extra sprites (22 -> 24-29 while moving,
  trailing groups ~72px)" — **native does the same** (19-31, spans to
  149px over the same window).
- "the palette ALTERNATES per frame, gold/purple" — per-frame sampling
  of the actual row shows it constant and native-identical on both
  games.
- The effect channels (`+0x318`-family) are NOT a discriminator:
  native populates them identically. The decode itself is still good
  documentation of the machinery — see engine_internals.

## The rest of the Phobos worklist (unchanged)

- **Child-companion shadow** — narrowed and independent of DF. Core
  tiles correct (bank 0x1000); the BAND is bank 0 and code =
  native - 0x16A8 (12 pieces, no exceptions). Open: which path stages
  the bank-0 pieces. OBJ RAM is DMA'd, so taps see nothing — use a
  work-RAM diff before vs during. **Now also A/B-able against native.**
- **The effect family** (beam sustain, ES big beam, grab lightning,
  214 explosion) — parked behind a TOOLING gap: `data_in_code` (census
  AND the generator's relocator) handles only `lea (d16,pc),An +
  (An,Xn.w)` and misses the post-increment reader `move.w (An)+`, so
  the ported machine carries a live embedded table reading garbage.
  Step 1 is the tooling fix, then un-park `tenant_type_stamp` + the
  `[[obj_hook_extra]]` row, narrowing the stamp per-EFFECT.
- **Win quote** — deferred, cosmetic; root-caused (the fetch's `-4`
  bias: the consumer reads index 0x60+id-1). Three-level data port.
- **FG pacing** — untouched.
- Then: H freeze (registry row + expectation set, maintainer-gated),
  then the Pyron moveset arc, then his gfx rung.

## Gates

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after ANY machinery change
tests/test_hui_df_style.sh    [build]   # NEW 14z-69 — the native A/B
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_winscreen.sh   [build]
tests/test_hui_fx_flow.sh     [build]
tests/test_hui_ex.sh          [build]
tests/test_hui_grab.sh        [build]
tests/test_hui_air.sh         [build]
tests/test_hui_pairs.sh       [build]   # RUN THIS on anything that routes
                                        # objects — it caught the DF crash
tests/test_hui_walk.sh        [build]
tests/test_hui_ladder.sh
tests/test_census_regions.sh  [build]
tests/test_gfx_layout3.sh
tests/test_hui_oracle.sh      [rompath] # ~10 min
tests/test_pyron_ladder.sh ; tests/test_pyron_soak.sh
tools/run_hui_behavior.sh               # interactive -> build/hui11
```

## Method note from this session

**A difference measured on our build alone is not a difference.** Every
number in the retracted list looked damning until the reference leg was
run at the same phase. Put the control inside the replay (85 performs
the same air dash before and during DF) so the mode's contribution is
visible without trusting two runs to line up — and when a symptom
resists three mechanism hunts, suspect the measurement before inventing
a fourth mechanism.
