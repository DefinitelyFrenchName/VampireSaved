# NEXT SESSION — orientation (written at the close of 14z-79, 2026-08-11)

> ## START HERE
>
> **M3b's remaining milestone is unchanged and still specified: the N-tenant
> loop plus the N-way dispatch form.** Nothing in 14z-79 touched the generator;
> read "NEXT SLICE — region identity, then the N-way dispatch FORM" in STATE
> 14z-78 and the ORDERING INVARIANT under it. The loop is one mechanical
> re-indent plus one gate, and both are written down.
>
> Before that, if you want a small high-value piece first, take **the op
> invariant extension** (below). It is the gate that would have caught this
> session's legacy defect at build time.

## The state in one paragraph

**Phobos is re-frozen as `huitzil-m3` (34c8b47d).** The (b') thunk landed and
fixes both his defects — Plasma Trap and Reflect Wall. In the same commit a
LEGACY defect that had shipped since 14z-69 was withdrawn: the DF-palette row
was overwriting **Bulleta's** Dark Force palette. All four frozen verticals
rebuild bit-exact. `run_suite.sh` is green on the re-frozen baselines.

## What (b') is, in case a symptom points back at it

A 470-byte thunk at engine site `PRG:0x018460` covering the out-of-range window
of dispatch table `0x018468` (vsavj has 80 entries, vs2's twin has 84). Entries
80-83 run vs2's handlers inline; every other index takes the vanilla path;
anything else is a defined vec3. Legacy-safe by IMPOSSIBILITY — vanilla
reaching 80-83 crashes today. The body is GENERATED
(`tools/gen_index_window_thunk.py`), never hand-edited, and
`tests/test_index_window_thunk.sh` reconstructs all 470 bytes from the ROMs.
Two properties it depends on, both measured, both in
`docs/game/engine_internals.md` "The SUB-STATE DISPATCHER FAMILY":
the table reads through the **opcode** view, and **D1 must come out holding the
vanilla offset**.

## Open, in rough priority order

1. ~~Extend the op invariant to stage 6~~ **DONE (14z-79b):
   `tests/test_shared_writes.sh` + `tools/audit_shared_writes.py` +
   `build/manifest/shared_writes.toml`.** Every write landing outside declared
   free space and outside a known variant row is now frozen per tenant
   (donovan 67 / huitzil 59 / pyron 50) and any change fails the gate.
   Ground-truthed: it flags the withdrawn DF-palette write on `build/hui27`.
   **Read its honest limit before trusting a green run** — it proves the set is
   UNCHANGED SINCE REVIEWED, not that the writes are safe; an entry frozen
   without checking whose bytes it lands on stays wrong and green. NOT done,
   and worth doing: tagging each op with its emitting mechanism in the
   generator, which would let the gate say WHAT a new write is, not just that
   it appeared. (Post-hoc attribution does not work — measured, the atlas
   fragment covers ~30% of shared writes by exact address.)
2. **Phobos' own palette-seq block** — the proper fix for his Dark Force. Free
   4-row id block + a copy of Bulleta's routine with that base + `0x02A8A4` row
   0x10 repointed. Start from the rebuilt audit's inventory
   (`1e 1f 20 21 26 27 44 45 46 47`), but note it is a **4-character sample** —
   "free" must be established across all 18 before anything is written.
3. **Pyron's Zodiac Fire has no rig** (236+P, ES 236+2P) — guard-cancel only,
   so it is ours to build, and it is the last unswept move of the three
   movelists.
4. `80_pyron_cosmo_pairsweep.rpl` still resets at f4840 — independent, real,
   low priority.
5. Polish the three NEW select medallions and their selection ring: imperfect
   shapes, slightly shifted placement, correct portraits at correct locations.
   Cosmetic, maintainer-described as **polish, not rework**.

## KNOWN-OPEN RED — do not "explain it away" again

`tests/test_variant_dispatch.sh` FAILS on table `0x02a8a4` row 0x10
(`ours 0x004a`, vs2 `0x0040`). **That is a real defect**, not noise: it is the
aliased row that puts Phobos on Bulleta's palette routine, and it is what made
14z-69p overwrite her Dark Force block. It stays red until item 2 lands. It had
been red since 14z-74 and was recorded as "benign — 0 hits at the resolver";
that zero came from replays in which nobody activated Dark Force.

## Rules this session paid for

- **"Dead on ENTRY" is not "dead."** A sweep over handler first-instructions
  says nothing about what happens after their `rts`. Prefer reproducing a
  displaced instruction's WHOLE architectural effect over proving each part of
  it unobserved.
- **Separate "the hook is wrong" from "the hook is expensive" BEFORE
  theorising.** Measure the dispatch rate and diff the two images. They look
  identical in the logs and have opposite fixes.
- **An audit whose replays cannot produce the mode it guards cannot report on
  that mode** — and a MODE control must sample several frames, because a
  one-frame sample is a coin toss on the onset. Both halves of that were paid
  for this session, the second by me, immediately after criticising the first.
- **Classify the CONSEQUENCE before valuing a clean observation.** "I never saw
  it" cleared the vanilla medallions (all 18 visible every session — loud) and
  was worth nothing for Bulleta's DF (mode-gated — silent). Same evidence,
  opposite weight.
- **The HOST character is the exposed one.** A tenant at variant `0x1N` aliases
  base slot `0xN`: Bulleta←Phobos, Demitri←Pyron, Victor←Donovan. When a tenant
  change misbehaves, test the host first.
- **Never edit a script while it is running** — bash re-reads it by byte
  offset and dies with a bogus syntax error.
- **Redirect long background jobs straight to a file**; piping through `tail`
  buffers everything and a kill loses the lot.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/hui29 fbneo        # play it
ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
MAME_ROMPATH="build/hui29/rompath;$ROMDIR" tests/run_suite.sh vsavjw
```

Rebuild the tenant verticals with `tests/test_m3a_reproducible.sh` (all four
frozen references, ~4 min, no emulator). Run it after EVERY M3b machinery
commit, together with `tests/test_tenant_row_owner.sh`.
