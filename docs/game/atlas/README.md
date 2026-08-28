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

## The three sets (measured M0; every figure still current)

All three sets: 4MB program ROM; opcode-encrypted region is
`PRG:0x000000-0x0FFFFF` only; data reads always bypass encryption;
`RAM:$FF0000-$FFFFFF` is 68k work RAM (checksummed per-frame by the
harness). Decrypted opcode-view images (68k logical order) from
`tools/cps2_decrypt.py`, each proven bit-identical to MAME's opcode space:

| Set | Key master | Watchdog (from key block) | Opcode-view SHA-1 |
|---|---|---|---|
| vsavj | `0xfa8f4e33a4b881b9` | `cmpi.l #$726A4BAF, D0` | `22bb468496cc9738d04b26f5df73c04a156a6de1` |
| vsav2 | `0xd681e4f460371edf` | `cmpi.l #$06920760, D0` | `a493d5ddd31c8e2627437caf1455a8260d11a45d` |
| vhunt2 | `0x36c1eba326b10f18` | `cmpi.l #$06920760, D0` | `cdf6930391b2d0392810eda0e2dee8235b27269f` |

vsav2/vhunt2 sharing a watchdog instruction (distinct keys) is early
evidence of the sibling-build relationship the M1 diff will map.
