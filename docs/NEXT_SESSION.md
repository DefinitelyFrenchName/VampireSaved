# NEXT SESSION — orientation (written at the close of 14z-75, 2026-08-10)

**ALL THREE TENANTS ARE NOW FROZEN.** Donovan `donovan-m3a` (4b7d0dc7),
Phobos `huitzil-m2` (9deda080), **Pyron `pyron-m1` (d8b282da)** — the last
frozen this session, maintainer-ratified, `run_suite.sh vsavjw` GREEN
(55 PASS / 17 SKIP / 0 FAIL, 72/72 replays). All three rebuild bit-exact.

```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/pyron19 fbneo     # play it
ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
MAME_ROMPATH="build/pyron19/rompath;$ROMDIR" tests/run_suite.sh vsavjw
```

**So M3b — merging the three into one build — is the next milestone.**

---

## Before the merge: three things that will collide

1. **Free-pool HUD anchors are per tenant and must stay disjoint.** Donovan
   0xBE8C/0xBE90, Phobos 0xBE92/0xBE9A, Pyron 0xBE94/0xBE9C. All six of
   Pyron's cells were chosen blank + inside `protected_tiles.json`'s audited
   pool for exactly this reason.
2. **The EFFECT palette hazard is SHARED.** The table at `0x38C218` has only
   sixteen rows, so a variant id indexes past it into the adjacent shared
   table — Pyron's 0x11 lands on its row 0x01, Phobos' 0x10 on row 0x00, both
   values vanilla uses. Neither is ported. Resolve it once, for both.
3. **Phobos carries one latent aliased row.** `0x2A8A4` row 0x10 is `0x004A`
   (row 0x00's handler) where vs2 has the default. Benign today (0 hits at
   the resolver) but not what native does, and `huitzil-m2` is frozen — so
   changing it is a maintainer decision. `tests/test_variant_dispatch.sh`
   reports it every run.

## Open on Pyron (none blocked the freeze)

- **The win QUOTE** — still the host's line, for all three tenants. ONE
  shared `id & 0x0F` fold, not three fixes. Detail + two failed attempts:
  `docs/game/engine_internals.md` "Win screen".
- **His EFFECT palette** — unported (see hazard 2). Unconfirmed whether it is
  even visible; ask the maintainer to look before spending on it.
- **`tests/replays/pyron/80_pyron_cosmo_pairsweep.rpl` still resets at
  f4840.** INDEPENDENT of everything fixed this session — it reproduces on
  pyron14 too. Most likely another out-of-range index of the same class as
  the Cosmo one. Needs a contrived 12-attempt sequence, so it is low priority
  but it is a real defect. Repro:
  ```sh
  POKES="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;3300:ff8509:09;3900:ff8509:09;\
  4500:ff8509:09;5100:ff8509:09;5700:ff8509:09;6300:ff8509:09"
  # watch P1 +0x382: 0x11 while alive, 0x00 once the watchdog has cleared RAM
  ```

## THE INDEX-SPACE CLASS — the lesson of this session

vsavj's tables are SMALLER than vs2's. A ported character carries vs2's
indices verbatim, and any index past the end of vsavj's table dispatches into
whatever follows it. Pyron's Cosmo sub-state 81 hit a table with 80 entries
and jumped into the table's own bytes.

**The fix belongs in the TENANT'S DATA, never in the shared table.** 14z-74
wrote the engine word instead: it stopped the crash and corrupted every
character's dispatch, and cost this session a blocked freeze to find. When a
tenant drives an out-of-range index, retarget HIS index to an in-range entry
that already reaches the right handler — one byte, unreachable by legacy.

**Sweep for it:** `tests/test_variant_dispatch.sh` finds the aliased-variant
row shape. There is no equivalent sweep yet for OUT-OF-RANGE indices — worth
writing before the fourth tenant.

## Rules that cost real time — carried forward

- **BUG ARCHAEOLOGY FIRST — grep the history before fixing anything.** It may
  already have been fixed once; the old fix or its withdrawal is the fastest
  route to the mechanism. Find the last-known-good build and diff it against
  its predecessor. **If the record is ambiguous about whether it was ever
  fixed, ASK THE MAINTAINER** — they were there and will usually remember.
  (14z-75: this is what cracked the Cosmo crash, after I had concluded the
  opposite from rigs that never fired the move.)
- **A negative result from a rig is a fact about the RIG until proven
  otherwise.** Prove the rig produces the EVENT, not just that it ran. Cosmo
  needed the right button pair, a long enough hold, AND meter — 4 of 12
  attempts fired in one rig and 0 of 12 in another, and "no crash" from a
  downgraded input means nothing.
- **Point `run_suite.sh` at a tenant build EARLY.** Every tenant-scoped gate
  was green while a legacy replay diverged permanently; only the vanilla
  suite sees that.
- **Never chain a legacy measurement onto a build in one command**, and
  re-run before believing a gate that contradicts a previous green.
- **Read a table BASE off the code that indexes it**, never off a content
  match (cost: a confidently wrong elimination).
- **A jump table ENDS WHERE CODE BEGINS.** Count entries before writing one.
- **A deadness measurement is only as good as the replay it ran on** — 0
  reads on `02_demitri_vs_cpu`, 6 reads on `05_timeout_idle`, same address.
- **Check the MODE FLAG before believing a mode** ($FF802E for Dark Force).
- **MAME's `-debug` can perturb a timing-sensitive crash AWAY**, and its
  frame numbers do not transfer to non-debug runs. Use FBNeo's non-perturbing
  tap when the debugger cannot see the bug.
- **THE DEAD-ROW CLASS** — `docs/game/engine_internals.md`. The most common
  defect shape in this port. When a ported character does something vanilla
  never does, suspect a dead row first.

## Instrument blind spots still open

1. **The extractor's dead-filler classifier is VIEW-BLIND** — it compares
   siblings in the OPCODE view, where embedded data always differs. It
   labelled the air-dive velocity table "dead filler". Discriminator: if the
   siblings' DATA views match, it is DATA.
2. **`tools/census_regions.py` bails in `_redefines_an`** on
   `lea (An,Xn),An`. Re-run the census across all tenants after fixing.

## Gates added in 14z-75

- `tests/test_variant_dispatch.sh` + `tools/audit_variant_dispatch.py` — the
  aliased-variant-row sweep. Run it for every tenant.
- `tests/test_pyron_blink.sh` + `tools/check_pyron_blink.py` + replay 76.
- `tests/test_pyron_cosmo.sh` — rewritten: the withdrawn engine word must
  stay out, the EX must FIRE, and rig 72 must not reset.
- Replays 76-82 (blink rig, Cosmo rigs incl. the two that reproduce) and
  `40_pick_pyron_cell.rpl` (real wheel pick onto his cell).
