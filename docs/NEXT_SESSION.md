# NEXT SESSION — orientation (written at the close of 14z-75, 2026-08-10)

**SESSION GOAL: the legacy divergence. Nothing else until it is green.**

**BLOCKING (CLAUDE.md rule 6).** pyron17 fails the vanilla-legacy basis on
`01_attract_long`, `05_timeout_idle`, `07_mash_storm`. 05 and 07 carry a
SECOND divergence (05: frames `4024..12120`) that NEVER re-converges — under
§4 that means match state was touched. The freeze was attempted and STOPPED;
the registry row is withheld. Full measurement:
`tests/expected/pyron-m1/NOT_RATIFIED.md`.

Already established, do not re-derive: it is **pre-existing** (pyron14 is
byte-identical), **not `port_param32`** (measured with the flag off),
**Pyron-specific** (huitzil-m2 is ONE select window then 10,446 identical
frames), and the **same matchup** runs on both legs. At onset f4024 the diff
is the P1 fighter block plus `$FFBF00-$FFBF3x` — an **effect-piece pool slot**
vanilla leaves zeroed. Suspects: the two `[[obj_hook]]` unions
(`0x54470`/`0x5E542`) and `alloc_wrap`.

**Reproduce in one command:**
```sh
ROMDIR=... MAME_ROMPATH="$PWD/build/pyron17/rompath;$ROMDIR" \
MASK_RANGES=043c-043d,4182-41a2,41c2-41e2,4222-4262,7f00-8000 \
  tools/run_replay_mame.sh vsavjw tests/replays/05_timeout_idle.rpl out.log
# then diff out.log against tests/expected/vsavj/masked-v2/logs/05_timeout_idle.log
```

**PROCESS LESSON: run `run_suite.sh` against a tenant build EARLY.** Every
tenant-scoped gate was green while this was broken; the vanilla-legacy suite
is the only thing that sees it, and it had never been pointed at a Pyron
build because Pyron was never frozen.

His HUD and his BLINK are both DONE and maintainer-confirmed. Two cosmetic
items also remain open.

**Current build: `build/pyron17` (`5dc6da06`) — this is the one to
playtest.** Not frozen. Run it:
```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/pyron17 fbneo      # or: ... mame
```
Rebuild:
```sh
TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 build/pyronNN
```
**Phobos is FROZEN as `huitzil-m2` (`9deda080`, `build/hui27`)**; Donovan as
`donovan-m3a`. All three references rebuild bit-exact — keep it that way
(`tests/test_m3a_reproducible.sh` after every machinery change, and rebuild
huitzil too if you touch anything shared like `effect_tail.json`).

---

## 1. THE BLINK — FIXED (nothing to do; here is what it was)

A **DEAD ROW**, in **THREE** per-character palette-routine jump tables whose
rows `0x10-0x1F` alias `0x00-0x0F` — so Pyron's row 0x11 handed him row
0x01's ANIMATED palette handler where vs2's row 0x11 is the default no-op:
`0x2A8A4` (in-match), `0x2B650` and `0x73790` (select screen + route map).
One word each, to vs2's own value: `0x2A8C6`, `0x2B672`, `0x737B2` -> `0040`.

**pyron16 fixed only the first and the blink survived on two screens** — the
tell was the second resolver site `0x2B7E8` at 523 calls vs native's 180.
Now 0 and 180, exactly native's and Huitzil's.

**THE LESSON: an aliased-variant-row table is rarely ALONE. Sweep for the
SHAPE, don't chase the screen** — `tests/test_variant_dispatch.sh`.

**Latent on Huitzil:** his row `0x10` in `0x2A8A4` is `0x004A` (row 0x00's
handler) where vs2's is the default — the only spurious row the sweep still
reports. Benign today (0 hits at the resolver) but not what native does.
`huitzil-m2` is FROZEN and maintainer-confirmed — **changing it is a
maintainer decision**, and it is worth raising before the M3b merge. His
rows in the other two tables already match vs2.

## 2. Effect palette — deferred, and a SHARED hazard

Not ported: the effect palette table `0x38C218` has only SIXTEEN rows, so a
variant id indexes past it into the adjacent shared table (row 0x11 ->
`0x38c25c` = that table's row 0x01, a value vanilla uses). **Huitzil's FROZEN
row has the same shape** (his 0x10 lands on its row 0x00) — worth resolving
before the M3b merge. Understand how the engine resolves an effect palette
for a variant id before writing anything there. Note this is NOT the blink:
14z-74 already proved removing the effect palette does not stop it.

## 3. Win QUOTE — the shared variant-id fold

Still wrong for every tenant: Donovan shows VICTOR's quotes, Phobos a
Bulleta line (`id & 0x0F` folding). ONE universal fix, not three. Pyron is
the third data point. Detail + two failed attempts:
`docs/game/engine_internals.md` "Win screen".

---

## Instrument blind spots still open — fix before more tenants

1. **The extractor's dead-filler classifier is VIEW-BLIND.** It compares the
   two sibling ROMs in the OPCODE view, where an embedded data table always
   differs, so real data is indistinguishable from junk. It labelled the
   air-dive velocity table "1 dead filler zone (+0x234)". Cheap
   discriminator: if the siblings' DATA views are byte-identical, it is DATA.
2. **`tools/census_regions.py` bails in `_redefines_an`** on
   `lea (An,Xn),An` — an index add where the pointer plainly survives. That
   is why `pyron.toml`'s "0 data_in_code" census line was wrong. Re-run the
   census across all tenants after fixing.

## Gates added in 14z-75

- `tests/test_variant_dispatch.sh` + `tools/audit_variant_dispatch.py` — THE
  sweep for the port's most common defect shape (aliased variant rows in
  per-character jump tables). Run it for every tenant. It also reports, for
  information, rows where vs2 runs a routine we do not — Donovan's 0x13 is
  the no-op in all five tables, a missing feature rather than a spurious one.
- `tests/test_pyron_blink.sh` + `tools/check_pyron_blink.py` + replay 76 —
  the blink, checked by MECHANISM (both values named), not just by symptom.
  NOTE it only sees the IN-MATCH instance; pyron16 passed it while still
  blinking on two other screens.
- `tests/replays/40_pick_pyron_cell.rpl` — walks the wheel onto his cell,
  the 0x11 twin of replays 36/37. Used by `test_tenant_hud.sh` section 3.

## Rules that cost real time — carried forward

- **Never chain a legacy measurement onto a build in one command**, and
  re-run before believing a gate that contradicts a previous green (14z-74:
  produced a wrong commit). The other side of the same coin, 14z-75: a
  commit that touches a manifest and does NOT rebuild can leave it
  unparseable — `pyron.toml` was broken for a whole session that way.
- **Compare the two games by a PHASE-INDEPENDENT property.** They are never
  on the same frame. A frame-indexed diff produced the "543 vs 0" figure
  that stood for a session and was wrong.
- **`placements.json` dst/src is LINEAR; the extractor shifts sub-regions.**
  Correlate to find the true source offset — mapping through it made a
  correctly-ported region read as 75% corrupt (14z-75).
- **Read a table BASE off the code that indexes it, never off a content
  match.** A row-content match put vs2's palette-seq base 8 rows out and
  produced a confidently wrong elimination (14z-75).
- **Check the MODE FLAG before believing a mode.** The blink ran through the
  Dark Force palette resolver while `$FF802E = 0` on both legs.
- **THE DEAD-ROW CLASS** — `docs/game/engine_internals.md`, the section of
  that name. SIX instances now (Pyron's HUD rows and his palette-routine row) and the
  most common defect shape in this port. **When a ported character does
  something vanilla never does, suspect a dead row first.**
