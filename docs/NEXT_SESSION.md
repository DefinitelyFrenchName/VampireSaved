# NEXT SESSION — orientation (written at the close of 14z-74, 2026-08-10)

**Session goal: finish Pyron's rung.** He RENDERS and three of his four
playtest defects are fixed and maintainer-confirmed. Four things are open,
one of them half-built.

**Current build: `build/pyron14` (`34f4b77d`)** — not frozen. Rebuild:
```sh
TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 build/pyronNN
```
**Phobos is FROZEN as `huitzil-m2` (`9deda080`, `build/hui27`)**; Donovan as
`donovan-m3a`. Both rebuild bit-exact — keep it that way
(`tests/test_m3a_reproducible.sh` after every machinery change).

---

## THE RULE THAT COST A WRONG COMMIT (14z-74)

**Never chain a legacy measurement onto a build in one command**, and
**re-run before believing a gate that contradicts a previous green.** I
recorded "port_param32 breaks legacy", refused the fix, and committed that
claim while the contradicting output was on screen. It was an artifact of
chaining; the same artifact also failed a build that did NOT carry the flag,
which is what exposed it. Two isolated re-runs were clean.

## 1. HUD — HALF BUILT, plate currently BLANK

The three table entries are ported and correct; nothing places his ART at
the free-pool anchors, so the plate shows nothing (it used to show
"Demitri"). **Gap located:** the per-tenant HUD config in
`tools/check_tenant_hud.py`'s `TENANTS` dict has rows for 0x13 and 0x10 and
NONE for 0x11. Pyron's values (derived + cross-checked against the other
two, which sit adjacent in the vs2 table):
```
0x11: mug_src 0x4D60  name_src 0x4D53  name_bx 2
      name_hi 0x86920102  name_lo 0xFFF00002
```
Reusing H's anchors (0xBE9A/0xBE92) is fine single-tenant but COLLIDES on
the M3b merge — give him his own then. Still to find: the PLACER that copies
that art into group C (`check_tenant_hud.py` is the gate, not the placer).
If a wrong name is preferable to none meanwhile, revert the three
`[[aux_poke]]` rows in `pyron.toml`.

## 2. The sprite/HUD BLINK

Palette RAM row 10 (0x90C140) alternates every frame; native holds it
constant. Row 10 is shared by his sprite AND the in-match HUD mugshot, which
is why both blink and why the mugshot showed DEMITRI's art in PYRON's
colours. Writer is the palette-SEQUENCE uploader (PC 0x02AD68), driven by an
anim script (A0 walks the 0x18 node stride), starting DURING SELECT.
**His anim nodes are CORRECT** (byte-identical to vs2 bar a properly
relocated pointer), so this is NOT the air-dive class.
**Do not act on the "ours 543 calls / native 0" figure** — the hits are in
the select screen, where our flow and native's are not at the same point on
the same frame. RE-MEASURE ANCHORED ON SCREEN STATE (both legs sitting on
his select portrait), then compare.

## 3. Effect palette — deferred, and it is a SHARED hazard

Not ported: the effect palette table 0x38C218 has only SIXTEEN rows, so a
variant id indexes past it into the adjacent shared table (row 0x11 ->
0x38c25c = that table's row 0x01, a value vanilla uses). **Huitzil's FROZEN
row has the same shape** (his 0x10 lands on its row 0x00) — worth resolving
before the M3b merge. Understand how the engine resolves an effect palette
for a variant id before writing anything there.

## 4. Win QUOTE — the shared variant-id fold

Still wrong for every tenant: Donovan shows VICTOR's quotes, Phobos a
Bulleta line (`id & 0x0F` folding). ONE universal fix, not three. Pyron is
now the third data point. Detail + two failed attempts:
`docs/game/engine_internals.md` "Win screen".

---

## Instrument blind spots found in 14z-74 — fix before more tenants

1. **The extractor's dead-filler classifier is VIEW-BLIND.** It compares the
   two sibling ROMs in the OPCODE view, where an embedded data table always
   differs, so real data is indistinguishable from junk. It labelled the
   air-dive velocity table "1 dead filler zone (+0x234)". Cheap
   discriminator: if the siblings' DATA views are byte-identical, it is DATA.
2. **`tools/census_regions.py` bails in `_redefines_an`** on
   `lea (An,Xn),An` — an index add where the pointer plainly survives. That
   is why `pyron.toml`'s "0 data_in_code" census line was wrong. Re-run the
   census across all tenants after fixing.

## Gates added this session

- `tests/test_list_type_census.sh` — the one-source-bank re-check per tenant,
  with a live positive control (its first version was blind to type 4 and
  read 0 for HUITZIL, whose beam is one).
- `tests/test_pyron_cosmo.sh` — the Cosmo fix: static, deadness (opcodes
  space + PC filter, with a control), runtime.
- `tests/test_hui_grab_victim.sh` + `tools/check_grab_victim.py` (14z-73).

## Recurring lesson worth re-reading

Three defects this session and last were the SAME shape: **vsav ships a
table row as a stub/alias where vs2 fills it** (the beam's effect-class row
16, Pyron's Cosmo sub-state 81, the grab-hold keyframe row). When a ported
character does something vanilla never does, suspect a dead row first.
