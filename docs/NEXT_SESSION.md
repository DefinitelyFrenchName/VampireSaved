# NEXT SESSION — orientation (written at the close of 14z-68, 2026-08-08)

**Start here: the PHOBOS DF-STYLE item, and write the vs2 replay
FIRST (recipe below). Everything else on Phobos is done, parked with a
named blocker, or deferred as cosmetic.**

**PING #10 = build/hui11 (5c6dbe43) is the current build and is
MAINTAINER-CONFIRMED**: the win screen's palette and position are both
fixed on the real screen. Frozen references unchanged (donovan-m3a
4b7d0dc7 / m5_stock 6c93cfa8; m3a-reproducible PASS). Twelve gates
green at close.

## Read this first — it will save you a day

`docs/engine_internals.md` grew 810 -> 1076 lines this session
(13 -> 24 sections). **Before touching ANY per-character subsystem,
read its section there.** The 14z-68 win screen was re-derived from
scratch and got two of three pieces wrong because Donovan's identical
solution existed only in a session log. New sections: win screen,
object type dispatch + pool walker, pool seeding/init_shim,
update-queue classes, throw/physics arcs, shadow servants, Dark Force,
companion/pod family, allocator wrappers.

Standing rule, now in HANDOFF: when a symptom on tenant B resembles
one fixed on tenant A, read A's section and diff A's manifest rows
BEFORE measuring anything.

## THE OPENER: DF style (afterimages + purple recolour)

Maintainer repro (verified): **1 stock, HP+HK to trigger DF, then
move — air dash shows it best.** Native applies NEITHER the trailing
copies NOR the recolour to Huitzil.

**FIRST, WRITE THE vs2 REPLAY.** The maintainer pointed out the DF and
movement inputs are IDENTICAL on vs2, so nothing blocks running the
same test natively — the only real obstacle is SELECTING him on vs2's
select screen, which one failed poke attempt made me wrongly write off
as expensive. Author `tests/replays/hui/85_hui_df_vs2.rpl`: coin,
start, reach vs2's select, pick Huitzil (cursor path on vs2's wheel,
or an id poke at vs2's OWN select timing — replay 61's timing is
authored for OUR wheel and does NOT transfer), then DF + move. Diffing
ours-vs-native at the same phase collapses this to one comparison.
(A native savestate is the alternative; the maintainer offered one.
Keep any state OUTSIDE the repo until the Rule 7 question — do CPS-2
states embed decrypted ROM content? — is checked. It must come from
the pinned MAME build to load.)

**Already measured, do NOT redo:**
- The effect is gated on MOVEMENT. Replay 82 walks at f3300-3400;
  sampling its stationary window (f3050-3250) shows nothing and reads
  as "not reproduced" — that cost a whole detour.
- The afterimages ARE extra sprites and they are HIS: pal-0x0A count
  goes 22 stationary -> 24-29 moving, trailing groups spanning ~72px.
- The palette ALTERNATES per frame (some frames correct gold, most
  purple) — a cycle, not a static recolour.
- NOT shadow servants (installer 0x823E2 / walk 0x8245C: zero hits).
- NOT the effect channels: they do not populate at DF activation (only
  +0x396, the button register, does); the first channel write is at
  f3150 with the next MOVE input.
- NOT his DF handler: seq-0x0A is per-char dispatched and row 0x10 is
  already repointed to his own placed handler.
So the style is applied by a shared path OUTSIDE his handler and the
discriminator is per-character. Detail: the Dark Force section of
engine_internals.

## The rest of the Phobos worklist

- **Child-companion shadow** — narrowed, and independent of DF. The
  shadow's CORE tiles are correct (bank 0x1000); the BAND around them
  is uniformly bank 0 AND code = native - 0x16A8 (12 pieces, no
  exceptions), so it draws from vanilla gfx space. Two code paths
  stage the same palette family; the open question is **which path
  stages the bank-0 pieces**. Ruled out: a per-char tile-base table
  holding 0x16A8. Technique: OBJ RAM is DMA'd (taps and watchpoints
  see nothing) — use a work-RAM diff before vs during. Likely the same
  root as the 14z-67 "pieces created through a path that leaves +0x18
  unset".
- **The effect family** (beam sustain, ES big beam, grab lightning,
  214 explosion) — PARKED behind a TOOLING gap, not a decode gap. The
  union-type mechanism is BUILT and MEASURED WORKING (dispatch,
  records and art all native-equivalent for the beam object); it is
  blocked because `data_in_code` — both the census and the generator's
  relocator — only handles `lea (d16,pc),An + (An,Xn.w)` and MISSES
  the post-increment reader `move.w (An)+`, so the ported machine
  carries a live embedded table that reads garbage. **Step 1 is the
  tooling fix**, then un-park `tenant_type_stamp` + the
  `[[obj_hook_extra]]` row — narrowing the stamp per-EFFECT first, as
  it crashed Dark Force when scoped per-character.
- **Win quote** — deferred, cosmetic. Root-caused (the fetch's `-4`
  bias means the consumer reads index 0x60+id-1, not 0x60+id) but it
  is a THREE-LEVEL data port (record -> per-line entries 0x1BADxx ->
  glyph data 0x1C4Cxx), not a repoint.
- **FG pacing** — untouched.
- Then: H freeze (registry row + expectation set, maintainer-gated),
  then the Pyron moveset arc, then his gfx rung.

## What shipped in 14z-68

Four defects, all gate-locked: the win-screen PALETTE source (I had
given him Donovan's row) and the POSITION row; the ported spawner
region's boundary (it excluded its own record-base load); and two
newcomer-id MASK widenings (vsavj loads a WORD where vs2 loads a LONG,
so ids >= 16 branched on a stale register bit). Plus the
`[[obj_hook_extra]]` generator facility (inert until a manifest row
declares one).

## Gates (all green at close)

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after ANY machinery change
tests/test_hui_boot.sh                  # masked-v2 EXACT legacy leg
tests/test_hui_winscreen.sh   [build]   # NEW 14z-68m — static, seconds
tests/test_hui_fx_flow.sh     [build]   # effect-flow attribution
tests/test_hui_ex.sh          [build]
tests/test_hui_grab.sh        [build]
tests/test_hui_air.sh         [build]
tests/test_hui_pairs.sh       [build]   # RUN THIS on anything that routes
                                        # objects — it caught the DF crash
tests/test_hui_walk.sh        [build]
tests/test_hui_ladder.sh
tests/test_census_regions.sh  [build]   # re-frozen 14z-68 (x022400 added)
tests/test_gfx_layout3.sh
tests/test_hui_oracle.sh      [rompath] # ~10 min
tests/test_pyron_ladder.sh ; tests/test_pyron_soak.sh
tools/run_hui_behavior.sh               # interactive -> build/hui11
```

## Method notes from this session (five retractions' worth)

1. **Verify at the RENDER layer.** RAM and ROM both checked out while
   the screen was wrong, twice — because "matches vs2" is only as good
   as the ROW compared against. Prefer self-labelling checks (the
   5*row palette marker) over internal-consistency ones.
2. **Diff against the previous build before theorising.** Two wrong
   mechanisms came from reading a single rendered frame.
3. **Sampling a state-gated effect at the wrong moment reads as "not
   reproduced".** Enumerate what the mode gates on (active vs moving
   vs attacking); ask for repro steps BEFORE measuring.
4. **Pair engine sites through the DISPATCH TABLE, not byte
   similarity** — that is what killed the 14z-67 seq-D entry theory.
5. **Ask for the reference early.** A maintainer screenshot closed an
   item after hours of derivation; their pointer to Donovan's fix
   closed another. Their pattern-matching was right every time it was
   offered this session.
