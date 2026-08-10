# NEXT SESSION — orientation (written at the close of 14z-75, 2026-08-10)

**Session goal: finish Pyron's rung.** His HUD is now DONE. Three items are
open, and the blink is root-caused down to one remaining question.

**Current build: `build/pyron15` (`3fb71586`)** — not frozen. Rebuild:
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

## 1. THE BLINK — one question left

**Do not re-derive the mechanism; it is measured and frozen** by
`tests/test_pyron_blink.sh` (replay 76, one rig for both games, 7 verdict
controls). Palette row 10 carries his SPRITE and his HUD MUGSHOT, so both
blink. Over 40 consecutive in-match frames: **native 1 value / 0 changes,
ours 2 values / 39 changes**, and ours' two values are named — native's
constant, and vsavj palette-seq row `0x26` (`0x39ADC0`) under the uploader's
`0xF000` OR. Writer `PC 0x02AD68`. The seq uploads are purely ADDITIVE.

Already eliminated (do not spend a session on these again): the anim nodes
(byte-identical to vs2 `0x2650EC`), the seq table content (vsavj row 0x26 ==
vs2's), a dead row (0x26 is live in legacy), and row misdirection (native
animates only stage rows 0x00-0x03).

**THE QUESTION: what GATES the request?** Same script, same id, same data —
ours animates, native does not. Lead: probing the resolver `0x2AD82` returns
`RET 0x00FF02DC` with `A6 = 0xFF8400` (his own fighter block), i.e. the
request is issued from a work-RAM thunk on his object's behalf. Get the
equivalent site on the native leg and diff the state that reaches it.
Subsystem write-up: `docs/game/engine_internals.md`, "The palette-SEQUENCE
uploader".

When fixed, flip the gate: `PYRON_BLINK_EXPECT=fixed`.

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

- `tests/test_pyron_blink.sh` + `tools/check_pyron_blink.py` + replay 76 —
  the blink, frozen by MECHANISM (both values named), not just by symptom.
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
- **THE DEAD-ROW CLASS** — `docs/game/engine_internals.md`, the section of
  that name. FIVE instances now (Pyron's HUD rows are the newest) and the
  most common defect shape in this port. **When a ported character does
  something vanilla never does, suspect a dead row first.**
