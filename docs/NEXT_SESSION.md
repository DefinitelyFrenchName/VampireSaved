# NEXT SESSION — orientation (written at the close of 14z-69, 2026-08-08)

**Start with the EFFECT FAMILY. It is one root — beam, grab lightning,
ES big beam and the 214+P grenade explosion are all the same defect —
and it is now narrowed to a single question, with three of its four
suspected causes eliminated by measurement.**

**PING #12 = build/hui14 (c25b3824) is current and MAINTAINER-CONFIRMED**
on all three of this session's fixes. `tools/run_hui_behavior.sh`
points at it. Frozen references unchanged (donovan-m3a 4b7d0dc7 /
m5_stock 6c93cfa8; m3a-reproducible PASS).

## What shipped in 14z-69 (all playtest-confirmed)

1. **The child sidekick's shadow** — two tiles (0x0F8B/0x0F8C) were
   remapped into group C but never COPIED there, so they drew an empty
   tile: a solid rectangle. Fixed via the new per-tenant
   `build/manifest/extra_tiles/<char>.json`.
2. **The Dark Force palette** — he flashes his own warm gold instead of
   purple. One `[[data_port]]` row swaps palette-seq rows 0x1E-0x21 for
   the sequence native's DF actually shows. The afterimages STAY by
   design: that mode is his real Vampire Savior Dark Force, and the
   maintainer confirmed "DF looks good as is".
3. **The row-8 machine's pc-relative tables** — all seven now read
   byte-identical to vs2 (they were resolving into unrelated bytes).
   Under the hood; no visible change, and the beam still does not draw.

## THE OPENER: the effect family, narrowed to EMISSION

With the three parked thunks un-parked in a scratch build, the beam
object is native-equivalent on every axis ever suspected: created
(type stamped), routed to the ported machine, record at native's OWN
relative offset (+0x63C), param tables byte-identical — **118 of 128
bytes match native**. And it still emits nothing.

ELIMINATED BY MEASUREMENT, do not re-open: the tables, the records, the
art (both beam sprite lists are ported and byte-identical), object
creation, the beam object itself (its chain resolves to 0x48xx codes,
not the beam codes), and the pod's sub-state.

**The next step:** find which object walks the anim nodes at vs2
`0x24FCFA` / `0x251CDA` — those are what reference the beam sprite
lists. Measure it in ONE emulator with BOTH legs, anchored on an event.
The 214 explosion is the same arc: its pieces draw pal 05/06/08 out of
BANK 0 (stock art) at onset f3395/f3430 of replay 83 — the "path that
leaves +0x18 unset" class.

## Then, in order

- **Win quote** — deferred, cosmetic. Root-caused (the fetch's `-4`
  bias means the consumer reads index 0x60+id-1); a three-level data
  port, not a repoint.
- **FG pacing** — untouched.
- **H freeze** (registry row + expectation set, maintainer-gated), then
  the Pyron moveset arc and his gfx rung. **Run
  `tests/audit_empty_tiles.sh` on Pyron's first gfx build** — it is a
  complete inventory check and it found the shadow defect outright.

## Rigs you now have (do not rebuild these)

- `tests/replays/hui/85_hui_df_vs2.rpl` — runs UNCHANGED on native
  vsav2 and on a tenant build. Both sides poked; **stocks poked too**,
  because DF costs one and without it the P+K pair is silently
  downgraded (that mistake cost three sessions).
- The native leg is reachable for ANY tenant screen: the early-window
  poke forces Huitzil on vsav2 in six seconds. "The native leg is
  unreachable" was inherited from ONE attempt with a replay whose
  timing was authored for our wheel.
- `tests/audit_empty_tiles.sh`, `tests/audit_palette_seq_ids.sh`,
  `tests/test_hui_df_style.sh` (expectations: differs / colours-fixed /
  matches), `tools/verify_pcrel_data.py`, `GUARD_PROBE_MAX`.

## Method notes from this session — read before the next beam attempt

Three separate "findings" this session were measurement artefacts, and
the pattern was always the same: comparing things that were not
comparable.

1. **Never cross-reference a MAME dump and an FBNeo tap by frame
   index.** The emulators traverse identical states at different frame
   indices — the fact §4 dual-emulator agreement rests on. This
   produced a whole fake "sub-state 7506 vs 7502" finding.
2. **Assert the STATE, not the input.** Pressing the DF buttons is not
   entering Dark Force; the mode costs a resource and degrades
   silently. Check the mode flag and the resource it consumed.
3. **A uniform delta means a consistent MAPPING, not corruption** —
   check the ART before calling a tile band wrong. The shadow diagnosis
   was backwards for a whole session because of this.
4. **Check that an instrument is not truncating.** The probe cap (400)
   silently hid a palette-seq id and nearly shipped a wrong safety
   claim; a "0 hits" reading meant a broken rig twice.
5. **"Ported from vs2" does not mean correct.** Copying vs2's rows at
   the same ids gave a build that was wrong in a new colour. Verify at
   the RENDER layer.
