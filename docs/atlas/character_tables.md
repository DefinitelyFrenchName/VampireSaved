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

- **vsavj: slot 0x8 only** — slot 0x8 is Bishamon (verified by pick), so the
  variant dataset 0x18 (base 0x0B3450) is **Oboro Bishamon**, the hidden
  boss version. (Early hypothesis "Dark Talbain" was wrong — Dark Talbain
  must ride a different mechanism; open item.)
- **vsav2 & vhunt2: slots {0x0, 0x1, 0x3, 0x8, 0x9}** → five true alternate
  datasets. This is Capcom's own dual-flavor (Start-hold) infrastructure —
  the mechanism SPEC §3.3 wants to reuse. Which characters occupy them in
  those sets: open item (naming runs on vsav2 planned).
- **vsav2 ≡ vhunt2 per-slot hitbox data is byte-identical** (all 32 entries)
  — both games carry both flavors; they differ elsewhere (defaults/UI).

## The full per-character table BANK (vsavj)

The three loader tables are part of a contiguous bank of 32-entry tables,
stride 0x80, at **PRG:0x0BD0FA-0x0BE8xx**: ~16 code-pointer tables
(targets in PRG:0x02C000-0x036000 — per-character handler routines), the
hitbox tables, more data-pointer tables (e.g. 0x0BDA7A/0x0BDAFA), and
word/byte parameter tables (0x0BE17A+). Semantic labeling per table: open
item; this bank is the master index for per-character manifests.

## Slot→character map, vsavj (COMPLETE; select-name/HUD verified picks)

| Slot | Character | | Slot | Character |
|---|---|---|---|---|
| 0x00 | Bulleta (B.B. Hood) | | 0x08 | Bishamon (0x18 = Oboro Bishamon) |
| 0x01 | Demitri | | 0x09 | Aulbath (Rikuo) *by elimination* |
| 0x02 | Gallon (J. Talbain) | | 0x0A | Sasquatch |
| 0x03 | Victor | | 0x0B | special: 1898 B, byte-identical in all three sets (Shadow/Marionette machinery?) |
| 0x04 | Zabel (L. Raptor) | | 0x0C | Q-Bee |
| 0x05 | Morrigan | | 0x0D | Lei-Lei (Hsien-Ko) |
| 0x06 | Anakaris | | 0x0E | Lilith |
| 0x07 | Felicia | | 0x0F | Jedah |

Every entry except 0x09 was pinned by a scripted pick: cursor path →
select-screen name snapshot + in-match `RAM:$FF8460` pointer readback
against the table (tools/pick_probe.sh). 0x09 is the only unclaimed
character (Aulbath) in the only unclaimed slot; one targeted pick can
close it formally.

## Cross-set slot correspondence (hitbox-blob similarity, coarse)

vsavj[k] ≈ vsav2[k] for k ∈ {0,1,2,3,4,6,8,9,10,11,12,13,14} (diagonal
dominant). vsav2 slots {5,7,15} are NOT well-claimed by any vsavj slot —
candidate homes of the three newcomers (Donovan / Huitzil / Pyron). Note
the similarity metric is coarse (vsavj 5=Morrigan, 7=Felicia, 15=Jedah are
definitely *in* VS2's lineage, so if {5,7,15} really are D/H/P in vsav2,
Capcom re-slotted those three veterans elsewhere or dropped them — VS2's
roster history says Morrigan stayed, so treat ALL of this as UNCONFIRMED
until the vsav2 naming runs; the select-flow probes for vsav2 are the next
mapping step).

## Why this matters for the port

The equivalent tables in vsav2/vhunt2 directly index Donovan/Huitzil/Pyron's
hitbox and character data. Diffing per-slot pointer *targets* across sets
(vsav2 slot k data vs vhunt2 slot k data) will produce the per-character
data manifests (M1 acceptance) without blind ROM diffing.
