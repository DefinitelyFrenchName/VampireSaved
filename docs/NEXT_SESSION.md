# NEXT SESSION — orientation (written during 14z-69, 2026-08-08)

**The DF-style opener is OPEN AND MEASURED. Start by decoding the
DF-TYPE selection between vj `0x027008` and vs2 `0x0261A6`/`0x025EE0`
(detail below). The symptom reproduces on demand now — the rig is
`tests/test_hui_df_style.sh`.**

**PING #10 = build/hui11 (5c6dbe43) is still the current build.** No
build changed this session. Frozen references untouched.

## READ THIS BEFORE ANY DARK FORCE WORK

**DF costs one banked stock.** With an empty meter the P+K pair is
DOWNGRADED to a single button and play continues normally — `seq 0x0A`
is that downgrade, NOT Dark Force. Replay 82 has no stock, so every DF
measurement in 14z-66/67/68 (including a gate that claimed "DF
activates, expires, re-activates" and the "DF mechanics are already
native-correct" conclusion) was taken outside the mode. I then published
a full A/B this session concluding the symptom "does not reproduce" —
also outside the mode. The maintainer caught it from one screenshot: an
ordinary stage and no TIME bar.

So: poke stocks (`$FF8509`), and assert the mode with **`$FF802E` = 1**
(match-level, identical on both games, off during a jump, off at
expiry). Do NOT infer a DF flag from the fighter block — `+0x1F4` and
`+0x1B5/+0x1B9` both look right and are set by JUMPING.

The native leg is reachable, and always was: the replay-80 poke
(`$FF8782 = 0x10` at f1400/1450/1500) forces Huitzil on `vsav2` in six
seconds. "The native leg is unreachable" came from ONE attempt with
replay 61, whose timing is authored for OUR wheel. Anything else parked
on "needs a native reference" (win quote, child shadow, effect art) can
be A/B'd now.

## THE OPENER: decode the DF-TYPE selection

Measured, native vsav2 vs hui11 (both verifiably in DF):

| | native | ours |
|---|---|---|
| activation seq | 0x16, cleared to 0 at once | 0x16 -> **0x18** held |
| stocks spent | **2** | **1** |
| palette row 0x0A | gold, brightened | **purple ramp** (82/82 frames) |
| his own draws | 6-8 | **28-32** (3-4 trailing copies) |

So the tenant inherits the host's **DF TYPE**, not merely its styling —
native Huitzil's DF never enters the transform state.

Site, from an FBNeo write tap on `$FF8406`:
- the seq write `1600` comes from **vs2 `0x0261A6` <-> vj `0x027008`**,
  stock debit right after (vs2 `0x0261C2` / vj `0x027024`);
- **native then runs `0x025EE0`, writing the seq back to 0** — the
  per-character branch that cancels the transform. Ours never does.

Decode what selects that branch. Expect the usual shape: an id-indexed
table with variant rows aliasing base rows — and decode BOTH views
before trusting a row (the standing view GOTCHA). Then give row 0x10
native Huitzil's DF type.

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
tests/test_hui_df_style.sh    [build]   # NEW 14z-69 — the DF native A/B
                                        # (DF_STYLE_EXPECT=matches when fixed)
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

**Assert the STATE, not the input.** Pressing the DF buttons is not
entering Dark Force; the mode costs a resource and silently degrades
without it. Three sessions of work — and one confident "does not
reproduce" from me — were spent on a match that was never in the mode,
while the visual signature (DF background, TIME bar) was free to check
and decisive. A negative result about a symptom the maintainer has SEEN
is a bug in the rig until proven otherwise: report it as "I could not
reach the state", never as "it does not reproduce".
