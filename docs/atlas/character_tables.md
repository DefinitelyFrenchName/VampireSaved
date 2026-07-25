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

## THE PORTED THREE — located (2026-07-25, pick-verified on vsav2)

The newcomers live in the **variant half** of the ID space, as directly
selectable wheel entries:

| Character | Char ID | vsav2 hitbox base | vhunt2 hitbox base |
|---|---|---|---|
| **Huitzil (Phobos)** | `0x10` (variant of slot 0/Bulleta) | `PRG:0x0C4370` | `PRG:0x0C3C02` |
| **Pyron** | `0x11` (variant of slot 1/Demitri) | `PRG:0x0C75FE` | `PRG:0x0C6E90` |
| **Donovan** | `0x13` (variant of slot 3/Victor) | `PRG:0x0C8DF8` | `PRG:0x0C868A` |

Every table in the per-character bank indexes them with these same IDs —
so "where does Donovan's <table-thing> live" is now `table[0x13]` in each
set's bank. Per-slot pointed-to data is byte-identical between vsav2 and
vhunt2 (hitbox tables verified); pointers differ by a constant-ish shift.

Remaining variant slots in vsav2/vhunt2: `0x18` (Oboro Bishamon, matching
vsavj) and `0x19` (occupant unnamed — variant of slot 9; check next).
Open question for the Start-hold flavor mechanism: the VS2-vs-VH2
*behavioral* differences for D/H/P are NOT in the hitbox data (identical
across both games) — the flavor toggle must select different rows in other
tables (movesets/frame data) or different code paths; locate in M1 wrap-up
or M2.

## Cross-set slot correspondence (verified)

Base-half slot assignments are IDENTICAL across the series where the
character exists: verified by picks — vsav2 slot 0 = Bulleta, 1 = Demitri,
3 = Victor, 8 = Bishamon (+ diagonal blob similarity for the rest). The
earlier "vsav2 {5,7,15} unclaimed" reading was similarity-metric noise —
the newcomers are in variant space, not replacing anyone.

## Why this matters for the port

The equivalent tables in vsav2/vhunt2 directly index Donovan/Huitzil/Pyron's
hitbox and character data. Diffing per-slot pointer *targets* across sets
(vsav2 slot k data vs vhunt2 slot k data) will produce the per-character
data manifests (M1 acceptance) without blind ROM diffing.
