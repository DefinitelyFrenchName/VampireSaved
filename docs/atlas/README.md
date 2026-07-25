# atlas — the verified ROM/RAM map (project bible)

One file per romset (`vsavj.md`, `vsav2.md`, `vhunt2.md`) plus `ram.md` for
work-RAM maps. Every byte range in the output set is provenance-tagged:
`VSAV` (untouched), `VS2`, `VH2`, `GEN` (generated), `NEW` (authored).
Entries are added only with evidence (diff, trace, or disassembly reference),
in the same commit as the change that affects them.

Address notation (CLAUDE.md §5): `PRG:0x0F1234` / `CPU:$0F1234` /
`GFX:tile 0x1A2B3` / `RAM:$FF8000`.

## Known so far (M0)

### vsavj
- `PRG:0x000000-0x0FFFFF` — opcode-encrypted region (key master
  `0xfa8f4e33a4b881b9`); data reads bypass encryption. Decrypted opcode view:
  `tools/cps2_decrypt.py` output, SHA-1 `22bb468496cc9738d04b26f5df73c04a156a6de1`.
- `PRG:0x100000-0x3FFFFF` — never opcode-encrypted.
- `RAM:$FF0000-$FFFFFF` — 68k work RAM (checksummed per-frame by the harness).
- Watchdog instruction (from key block): `cmpi.l #$726A4BAF, D0`.
