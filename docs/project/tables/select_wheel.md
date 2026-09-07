# Select-wheel roster access — the inbound edges into the tenant row

The three tenants sit on their own appended wheel row. This table documents
the INBOUND edges — which vanilla cell, pressed in which direction, reaches
that row. They are the only wheel bytes the port writes over LEGACY content,
so they are the roster-access surface a player feels, and rule 5's "variant
selection" category ([VSP-6]).

Source of truth: `build/manifest/wheel_layout_proposed.json` `edges_in`, which
carries `# in-table` pointers back to this table; `tools/audit_rule5.py`
asserts every value below is really here, so the two cannot drift. Editing
this page does NOT change the build (option B, maintainer-ruled 2026-09-07 —
see `rule5_ledger.md`); a behaviour change edits the manifest and this table
in one commit.

Cell ids are wheel cells, not character ids: `0x08` Bishamon, `0x09` Aulbath,
`0x0B` the random "?" cell; `0x10` Huitzil/Phobos, `0x11` Pyron, `0x13`
Donovan.

## The five inbound edges

| from | direction | to | why it exists | provenance |
|---|---|---|---|---|
| 0x08 | D | 0x10 | REACHABILITY. Bishamon Down reaches Phobos; without it the tenant row has no entrance | measured 14z-60o (the wheel walk, `tools/select_wheel.py`); adjacency translated BY POSITION from the PS1 console capture (maintainer video, 2026-08-05) |
| 0x09 | D | 0x13 | REACHABILITY. Aulbath Down reaches Donovan | measured 14z-60o; same capture |
| 0x0B | D | 0x11 | UX, not reachability — Donovan and Phobos are already reachable by the two rows above, and Pyron through them | ruled 2026-08-05 (maintainer, "vanilla wins ties"): kept because pressing Down on the cell directly above the new row would otherwise do nothing while three medallions are visible below it |
| 0x0B | DL | 0x10 | UX, as above | ruled 2026-08-05 |
| 0x0B | DR | 0x13 | UX, as above | ruled 2026-08-05 |

## What dropping the three would buy, measured

The legacy footprint of the whole wheel extension falls from **5 bytes to 2**
— the two reachability edges are all the roster strictly needs. The standing
principle is that vanilla wins ties, and these three do diverge from vanilla;
they are kept anyway because the alternative is the UX failure the ruling's
own test excludes ("as long as we can select characters"). Recorded so the
trade is visible rather than rediscovered.

Horizontal wrap and the `Bishamon DL` / `Aulbath DR` cells stay VANILLA under
the same ruling. The full 21-cell layout, the cursor lattice and the coord
list are `docs/game/atlas/select_screen.md`; this page is only the edges the
port authored.
