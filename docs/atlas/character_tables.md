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

## The full per-character table BANK — layout identical in all three sets

A contiguous bank of 32-entry tables, stride 0x80 between neighbors. Bank
origin (= first dispatch table) per set — **all internal deltas are
preserved across sets**, so any table found in vsavj is `origin + same
delta` in the others (verified for bank[0], hitbox pair, +0x132 word
table):

| Set | bank[0] (dispatch) | hitbox anchor (delta +0x880) |
|---|---|---|
| vsavj | `PRG:0x0BD0FA` | `PRG:0x0BD97A` |
| vsav2 | `PRG:0x0D7298` | `PRG:0x0D7B18` |
| vhunt2 | `PRG:0x0D6B2A` | `PRG:0x0D73AA` |

Semantic skeleton (from disassembly of every vsavj consumer site):

- **bank +0x000..+0x700 (0xBD0FA-0xBD7FA, 14 tables): per-character CODE
  dispatch** — `movea.l (a0,d0.w),a0; jmp/jsr (a0)`. Each table = one
  engine event (state handlers); entries = per-character routines.
- +0x780 (0xBD87A), 0xBE2FA: per-char 32-bit parameter values (loaded to
  D0, not pointers).
- +0x880/+0x900 (0xBD97A/0xBD9FA): hitbox base + companion ptr (player
  load path, PRG:0x028DD8). 0xBDA7A/0xBDAFA: the same pair used by the
  projectile/secondary-object path (PRG:0x0546E6).
- 0xBDB7A, 0xBE3FA: per-char 8-byte records (two longs read together —
  movement velocity pairs by usage context).
- 0xBE17A → struct+0x132 (word); 0xBE1BA/0xBE1FA: word params used in
  position math; 0xBE7FA: word ADDED to struct+0x14 (Y position) — per-char
  height/offset; 0xBE83A: range-check word; 0xBE87A → struct+0x15B (byte);
  0xBE89A/0xBEC5A: 2D byte tables → struct+0x167.

### Ported-three handler code (bank[0] rows; the "code" manifest entry)

| Character | vsav2 handler | vhunt2 handler |
|---|---|---|
| Huitzil 0x10 | `PRG:0x057450` | `PRG:0x057486` |
| Pyron 0x11 | `PRG:0x059424` | `PRG:0x059454` |
| Donovan 0x13 | `PRG:0x05AE20` | `PRG:0x05AE50` |

Veteran handlers sit in `PRG:0x02Fxxx-0x04Axxx`; the newcomers' code was
appended at `PRG:0x057xxx-0x05Cxxx` (vsav2/vhunt2 differ by a small
constant shift ≈0x30 — sibling builds).

## Slot→character map, vsavj (COMPLETE; select-name/HUD verified picks)

| Slot | Character | | Slot | Character |
|---|---|---|---|---|
| 0x00 | Bulleta (B.B. Hood) | | 0x08 | Bishamon (0x18 = Oboro Bishamon) |
| 0x01 | Demitri | | 0x09 | Aulbath (Rikuo) |
| 0x02 | Gallon (J. Talbain) | | 0x0A | Sasquatch |
| 0x03 | Victor | | 0x0B | special: 1898 B, byte-identical in all three sets (Shadow/Marionette machinery?) |
| 0x04 | Zabel (L. Raptor) | | 0x0C | Q-Bee |
| 0x05 | Morrigan | | 0x0D | Lei-Lei (Hsien-Ko) |
| 0x06 | Anakaris | | 0x0E | Lilith |
| 0x07 | Felicia | | 0x0F | Jedah |

Every entry pinned by a scripted pick: cursor path → select-screen name
snapshot + in-match `RAM:$FF8460` pointer readback against the table
(tools/pick_probe.sh). Aulbath closed via path L,L,D (pointer 0x0A7EFA →
slot 9, name verified).

## THE PORTED THREE — located (2026-07-25, pick-verified on vsav2 AND vhunt2)

The newcomers live in the **variant half** of the ID space, as directly
selectable wheel entries. Verified independently in both source sets: same
cursor paths (R×2/R×3/R×4 from Demitri), same slot IDs, pointer readback
matching each set's own table. vhunt2 base-half assignments also verified
(1 Demitri, 3 Victor, 4/5/6/7/8 as vsavj):

| Character | Char ID | vsav2 hitbox base | vhunt2 hitbox base |
|---|---|---|---|
| **Huitzil (Phobos)** | `0x10` (variant of slot 0/Bulleta) | `PRG:0x0C4370` | `PRG:0x0C3C02` |
| **Pyron** | `0x11` (variant of slot 1/Demitri) | `PRG:0x0C75FE` | `PRG:0x0C6E90` |
| **Donovan** | `0x13` (variant of slot 3/Victor) | `PRG:0x0C8DF8` | `PRG:0x0C868A` |

Every table in the per-character bank indexes them with these same IDs —
so "where does Donovan's <table-thing> live" is now `table[0x13]` in each
set's bank. Per-slot pointed-to data is byte-identical between vsav2 and
vhunt2 (hitbox tables verified); pointers differ by a constant-ish shift.

### The other two variant datasets: two Oboro-class Bishamons

Match-init ID normalization (vsav2 `PRG:0x01F5A0`, mirrored in vhunt2;
vsavj has the 0x18 case only): IDs `0x18` AND `0x19` both remap to slot-8
(Bishamon) *code* while keeping their own *data* rows — so VS2/VH2 carry
two distinct Oboro-class datasets (0x18 ≈ vsavj's Oboro; 0x19 = a second
flavor, vsav2/vhunt2-only). The five variant datasets in the siblings are
therefore: **Huitzil 0x10, Pyron 0x11, Donovan 0x13, Oboro 0x18,
Oboro-alt 0x19**.

### Start-hold flavor: NOT REPRODUCED (flagged for maintainer)

Measured in vsav2 (Japan 970913), Donovan: holding Start (through select
confirm and match load) latches exactly one byte — `RAM:$FF87C2` (P1 block
+0x3C2, default 01 in BOTH games, cleared when Start held) — which is
never read back during play (read-watchpoint trace across idle AND
attack-chain sequences), and post-chain full-work-RAM state is IDENTICAL
except that byte. So with these inputs, "hold Start for the other game's
flavor of D/H/P" (SPEC §2 background fact) produces no behavioral
difference in vsav2. Either the input method differs, the effect is
vhunt2-only, it manifests only in untested moves, or the lore is
imprecise. The latch byte and its one writer/clearer are mapped; revisit
with maintainer/community input. NOTE for the port: since vsav2≡vhunt2
per-slot data is byte-identical, the port can carry BOTH Oboro flavors and
the three newcomers from either set — the "VS2 vs VH2 variant" question
may reduce to system-mechanics presentation, not character data.

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
