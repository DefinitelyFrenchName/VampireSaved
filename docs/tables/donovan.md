# Donovan (char id 0x13) — extraction manifest & behavioral values

Produced by `tools/extract_char.py` (vsav2 source, vhunt2 oracle) —
rerunnable; regenerate with:
`python3 tools/extract_char.py "$ROMDIR/vsav2.zip" build/donovan/extract --char 0x13 --oracle "$ROMDIR/vhunt2.zip"`
Every region is oracle-validated: all vsav2↔vhunt2 diff bytes classify as
pointer fields under the measured shifts (code +0x30, bank −0x76E, anim
−0x13B74, objtab −0x2002C) or are recorded as variant sites below.

## Region manifest (vsav2 addresses; total 234.7 KB — fits hole A)

| Region | vsav2 | Length | Contents |
|---|---|---|---|
| code | `PRG:0x059490` | 0x3200 | 14 dispatch handlers + shared newcomer stubs (only dispatch_00 target 0x05AE20 is Donovan-unique; 01-13 → shared stubs 0x0594xx-0x05ADxx, several aliased) |
| hitbox | `PRG:0x0C8BB8` | 0x25C2 | player-path hitbox data (base 0x0C8DF8, comp 0x0C8BB8) |
| hitbox_proj | `PRG:0x0D0CA8` | 0x435A | projectile-path hitbox data (base 0x0D0CA8, comp 0x0D1002) |
| anim | `PRG:0x27F548` | 0x20F00 | anim index tables (a=0x27F548 b=0x28709C c=0x287192 proj=0x289EF6) + scripts; 3979 internal pointer fields |
| aux0_0..4 | `PRG:0x334B80`… | 0x1190/0x410/0x420/0x410/0xE2F0 | sprite/OBJ sub-tables (24-bit frame ptr targets; shift −0x2002C; 1088 distinct targets in 5 clusters) |

## R1 surface (from the code region, oracle + operand scan)

- **105 distinct engine targets** (467 reference sites) — the reconciliation
  worklist for stage 4. Machine list: `build/donovan/extract/regions.json`
  (`regions.code.refs`, class `engine`).
- 2 distinct bank-neighborhood data refs (`0x0D609E`, `0x0D8398`, 4 sites) —
  candidates for the bank delta rule (vsavj = 0x0BD0FA + (target −
  0x0D7298)), to be verified at generation time.
- 1 PC-relative escape (code +0x3133 → vsav2 0x1BAB) — needs a thunk or
  displacement rewrite.
- **0 char-id 0x13 immediates** in his code (no self-id checks found).

## Per-character values (slot 0x13 rows — the tunables, CLAUDE.md rule 5)

| Table (vsavj addr) | Kind | Value |
|---|---|---|
| param32_a (0x0BD87A) | long | `FFFD0000` |
| param32_b (0x0BE2FA) | long | `FFFD0000` |
| rec8_a (0x0BDB7A) | 2×long | `00080000 FFFFA600` |
| rec8_b (0x0BE3FA) | 2×long | `00096000 FFFF8400` |
| word132 (0x0BE17A) | word | `0018` |
| word_pos_a (0x0BE1BA) | word | `0010` |
| word_pos_b (0x0BE1FA) | word | `0008` |
| word_y_off (0x0BE7FA) | word | `0000` |
| word_range (0x0BE83A) | word | `0000` |
| byte15b (0x0BE87A) | byte | `3C` |
| byte2d_a (0x0BE89A) | 30 B | `0A0A030303030A0A0A0A03030A0A030A0A030303030A0A030303030A0A03` |
| byte2d_b (0x0BEC5A) | 30 B | `0C0C030303030C0C0C0C03030C0C030C0C030303030C0C030303030C0C03` |

Gap tables classified by the oracle (no documented consumers yet): most are
value tables (velocity-looking `FFFFxxxx` constants — full rows in
regions.json `auto_tables`); `gap_be27a`/`gap_be2ba` are clean pointer
tables; **`gap_bcefa` and `gap_bd7fa` are UNRESOLVED** (diff doesn't classify
cleanly — need consumer-site disasm; stage 2/4 gates will surface whether
they matter).

## VS2-vs-VH2 variant deltas (maintainer-facing; SPEC §3 variant policy)

Real data differences between the sibling games inside Donovan's shared
data — the first hard evidence of where per-game flavor lives:

- **hitbox region tail (+0x24BD..+0x25BD, 24 bytes):** a patterned block
  (vsav2 `07 xx` pairs vs vhunt2 `00/04 xx`) — vsav2 values are used for
  the port; the block is a candidate for the "VS2 vs VH2 flavor" tunable
  set once its consumer is identified.
- **code region: 1 byte** (+0x3135 area, adjacent to the pcrel16 site).
- anim + all aux0 clusters: **zero** variant bytes (fully shared).
