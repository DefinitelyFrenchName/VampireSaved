# `roster_pairings` — the class → hitbox-base table the pairing matrix asserts

Created 14z-97 for `tests/audit_roster_pairings.sh`, which runs the CLAUDE.md
§4 coverage mandate for a ported character: **"vs each of the 18 (both
sides)"**.

## Where these numbers come from — DERIVED, not observed

`bases.tsv` is read out of the **merged image's own per-character table at
`PRG:0x0BD97A`** (the address `docs/game/atlas/character_tables.md:30`
records for vsavj), from the build's data view. It is not a transcript of
what a run happened to print.

That distinction is the whole point. An expectation harvested from the run it
is meant to police cannot fail: it would assert "the build does what the
build did". Reading the table the engine itself indexes gives an independent
source, so a pairing that loads the WRONG character is a detectable event
rather than a new baseline.

**Two-source check, and it passed (14z-97):** all 16 legacy rows plus `0x18`
are **byte-identical between vanilla `vsavj` and the merged build**. That
agreement is a superset-invariant result in its own right — the port did not
move a legacy character's hitbox base. Only the three tenant rows differ, and
they differ the way they should:

| class | vanilla | merged | why |
|---|---|---|---|
| `0x10` Phobos | `0x00091f98` | `0x004477b0` | vsavj's variant half is a COPY of the base half (`0x10` aliases Bulleta); the merged build points it at the ported table in the WIDE extension |
| `0x11` Pyron | `0x00093b6a` | `0x0049ab7c` | same, aliasing Demitri |
| `0x13` Donovan | `0x0009769e` | `0x003fa9d0` | same, aliasing Victor |

The three merged values independently reproduce the constants
`tests/test_tenant_pairings.sh` froze at 14z-95 by measurement — two
different routes to the same three numbers.

## Who is in the table, and who is not

The 18 of CLAUDE.md's mission statement: "the 15+1 of Vampire Savior plus
Donovan, Huitzil/Phobos and Pyron".

- **`0x0B` is deliberately absent.** The slot map
  (`character_tables.md:265`) records it as *"special: 1898 B,
  byte-identical in all three sets (Shadow/Marionette machinery?)"* — it is
  not one of the 18 and not a selectable character. Excluding it is a
  decision, recorded here so it is not read as an oversight and quietly
  "fixed" into the matrix.
- **`0x18` (Oboro Bishamon) IS included** — it is the "+1", a variant class
  like the tenants themselves.

## When this moves

The legacy rows should never move: if one does, that is a superset-invariant
violation and the matrix is the wrong place to absorb it. The tenant rows
move whenever a tenant's ported tables are relocated, which is a re-freeze —
re-derive from the new merged image and say so in STATE.

Regenerate by reading `PRG:0x0BD97A` from `<merged build>/verify_data.bin`;
`tools/pick_probe.sh:43` carries the same table read for the single-slot case.
