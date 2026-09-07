# atlas — the verified ROM/RAM map (project bible)

Files (the "one file per romset" plan of M0 never materialised — the atlas
grew by SUBJECT, all three sets side by side; corrected 14z-114):
`ram.md` (work RAM), `character_tables.md` (the per-character bank, all
three sets), `id_space.md` (the 5-bit id and its folding sites),
`select_screen.md` (the wheel, cell↔id, the record arrays),
`sprite_lists.md` (the drawer and list formats), `venue_assets.md`
(per-slot presentation assets). Every byte range in the output set is provenance-tagged:
`VSAV` (untouched), `VS2`, `VH2`, `GEN` (generated), `NEW` (authored).
Entries are added only with evidence (diff, trace, or disassembly reference),
in the same commit as the change that affects them.

Address notation (CLAUDE.md §5): `PRG:0x0F1234` / `CPU:$0F1234` /
`GFX:tile 0x1A2B3` / `RAM:$FF8000`.

**IF YOU WANT TO KNOW WHAT ADDRESS X IS, READ Y** (the routing table — the
atlas grew by SUBJECT, so the file to open follows from what the address is,
not from which romset it is in):

| if the address is… | read |
|---|---|
| a work-RAM field — `RAM:$FF8xxx`, the player blocks, the object pools, the mode flags | `ram.md` |
| a row or field of the per-character bank, in any of the three sets | `character_tables.md` |
| a character id, a variant slot, or a site that folds the 5-bit id | `id_space.md` |
| the select wheel, a cell, the cursor, or the select record arrays | `select_screen.md` |
| a sprite list, a drawer entry, or an OBJ record field | `sprite_lists.md` |
| a per-slot presentation asset — a venue, a banner, a portrait | `venue_assets.md` |
| any other `PRG:` address | `docs/annotations.md` (GENERATED): every address the tree names, with the file and section that names it. An index, not a source — grep the address, land in the carrier |
| named nowhere, and you want the MECHANISM behind it | `docs/game/engine_internals.md` — the subsystem synthesis; each section names the atlas rows it rests on and the gates that lock it |

## The three sets (measured M0; every figure still current)

All three sets: 4MB program ROM; opcode-encrypted region is
`PRG:0x000000-0x0FFFFF` only; data reads always bypass encryption;
`RAM:$FF0000-$FFFFFF` is 68k work RAM (checksummed per-frame by the
harness). Decrypted opcode-view images (68k logical order) from
`tools/cps2_decrypt.py`, each proven bit-identical to MAME's opcode space
(`tests/test_decrypt_oracle.sh`). **The SHA-1 column is re-derived by
`shasum build/out/<set>_opcodes.bin` after `tools/build_donovan.sh` (or
`tests/lib/decrypt_cache.sh`) has written the views — re-derived 14z-118,
all three unchanged; it has no second home in the tree, so this is the
only place it is checked:**

| Set | Key master | Watchdog (from key block) | Opcode-view SHA-1 |
|---|---|---|---|
| vsavj | `0xfa8f4e33a4b881b9` | `cmpi.l #$726A4BAF, D0` | `22bb468496cc9738d04b26f5df73c04a156a6de1` |
| vsav2 | `0xd681e4f460371edf` | `cmpi.l #$06920760, D0` | `a493d5ddd31c8e2627437caf1455a8260d11a45d` |
| vhunt2 | `0x36c1eba326b10f18` | `cmpi.l #$06920760, D0` | `cdf6930391b2d0392810eda0e2dee8235b27269f` |

vsav2/vhunt2 sharing a watchdog instruction (distinct keys) is early
evidence of the sibling-build relationship the M1 diff will map.
