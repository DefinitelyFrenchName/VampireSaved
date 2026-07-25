# Character data tables — three-set anchor map

Discovered 2026-07-25 by write-trace on `RAM:$FF8480` (vsavj) + disassembly
of the writer, then located in the sibling sets by instruction-pattern
search (immediates wildcarded). This is the master anchor for per-character
data across all three sets: the loader reads `char_id`, doubles it twice,
and indexes three tables.

## The loader (per-character struct fill)

vsavj `PRG:0x028DD8` (≡ vsav2 `PRG:0x0280B8` ≡ vhunt2 `PRG:0x0280E6`):

```
ext.w   d0                    ; d0 = char id (5-bit: slot | variant<<4)
add.w   d0,d0
movea.l #<word_tbl>,a0
move.w  (a0,d0.w), $132(a6)   ; per-char word -> struct+0x132
add.w   d0,d0
movea.l #<tbl64>,a0
move.l  (a0,d0.w), $64(a6)    ; per-char ptr  -> struct+0x64
movea.l #<hitbox_tbl>,a0
movea.l (a0,d0.w), a0         ; per-char hitbox base
...                           ; +0x60 = base; +0x80..0x90 = base+base[0..8]
```

## Table addresses (32 entries each: slots 0x00-0x0F, variants 0x10-0x1F)

| Table | vsavj | vsav2 | vhunt2 |
|---|---|---|---|
| hitbox base (.l) | `PRG:0x0BD97A` | `PRG:0x0D7B18` | `PRG:0x0D73AA` |
| struct+0x64 (.l) | `PRG:0x0BD9FA` | `PRG:0x0D7B98` | `PRG:0x0D742A` |
| struct+0x132 (.w) | `PRG:0x0BE17A` | `PRG:0x0D8318` | `PRG:0x0D7BAA` |

## Variant-slot semantics (structural finding)

Variant half (0x10-0x1F) aliases the base half except:

- **vsavj: slot 0x8 only** → the Dark Talbain machinery (base 0x0A6418,
  variant 0x0B3450).
- **vsav2 & vhunt2: slots {0x0, 0x1, 0x3, 0x8, 0x9}** → five characters have
  true alternate datasets. This is Capcom's own dual-flavor
  (Savior/Hunter-style via Start-hold) infrastructure — exactly the
  mechanism SPEC §3.3 wants to reuse for VS2-vs-VH2 variants. Identifying
  which characters occupy those five slots in each set is an open item
  (expected: the three ported characters among them; slot 0x8 likely
  Talbain-family again).

## Known slot→character (vsavj, empirically verified)

| Slot | Character | Evidence |
|---|---|---|
| 0x01 | Demitri | pick-trace + HUD snapshot |
| 0x03 | Victor | pick-trace + HUD snapshot |
| others | ring experiment in progress | |

## Why this matters for the port

The equivalent tables in vsav2/vhunt2 directly index Donovan/Huitzil/Pyron's
hitbox and character data. Diffing per-slot pointer *targets* across sets
(vsav2 slot k data vs vhunt2 slot k data) will produce the per-character
data manifests (M1 acceptance) without blind ROM diffing.
