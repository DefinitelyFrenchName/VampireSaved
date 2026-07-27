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

### Animation index tables (bank extends below bank[0])

The bank's true start is `PRG:0x0BCE7A` (vsavj): three anim-related
per-character pointer tables at bank[0]−0x280/−0x180/−0x100
(0x0BCE7A/0x0BCF7A/0x0BCFFA) + the projectile-side table at −0x80
(0x0BD07A). Anim lookup (writer `PRG:0x027EC0`): per-char anim index table
→ word offsets → anim scripts; script+0 → struct+0x20, script[8] indexes
the struct+0x64 table; anim ptr lives at struct+0x1C.

**Per-character anim bases (table A rows; the "animation scripts" manifest
column):**

| Character | vsavj | vsav2 | vhunt2 |
|---|---|---|---|
| Demitri 0x01 | `0x12C2FE` | `0x11DED8` | `0x11036C` |
| Victor 0x03 | `0x150910` | `0x137E7E` | `0x134FC2` |
| Huitzil 0x10 | (aliases slot 0) | `0x245872` | `0x231CFE` |
| Pyron 0x11 | (aliases slot 1) | `0x264086` | `0x250512` |
| Donovan 0x13 | (aliases slot 3) | `0x27F548` | `0x26B9D4` |

The newcomers' anim data sits in an appended region
(`PRG:0x23xxxx-0x28xxxx`, outside the encrypted 1MB) — ~110-125KB per
character by inter-base spacing.

### Palette pipeline (partial)

Palettes live in CPS2 palette RAM `0x90C000+`, uploaded straight from ROM
by the system blitter at `PRG:0x000EF2` (`move.l (a0)+,(a1); or.l
#$F000F000` — sets full brightness, and **feeds the CPS2 encryption
watchdog inline**: `cmpi.l #$726A4BAF,d0` lives inside this loop). Fixed
system pages upload from `PRG:0x38C2A0`/`0x3D7E58` (callers
`0x000EA8-0x000EE8` → pages `0x90C800/CC00/D000/D400`).

**Per-character sprite palettes (traced):** four ROM palette-source
pointer slots at `A5+0x7404/0x7408/0x740C/0x7410` (A5 = CPS driver work
base). The scheduler at `PRG:0x0142C2` copies from those sources into
palette RAM `0x90C000/C400/C800/CC00` each frame through the fade-in-place
loop `PRG:0x014034` (via a per-object RAM work buffer, e.g. `RAM:$FF033C`,
so brightness ramps). A5 = `RAM:$FF8000` (resolved), so these slots are `RAM:$FFF404..0xFFF410`;
their Demitri values (`0x3A3400/0x3C03C8/0x3D15F0/0x3DE258`) are
**stage/system pages, character-independent** (identical for Demitri and
Victor on the same stage). **Per-character SPRITE palettes are separate:**
confirming Demitri with button 1 vs button 2 changes palette RAM at rows
`0x90C140-0x90C1A0` (4 sprite palettes), so a character's own palette rides
its **sprite object's palette bank** (keyed to the sprite set), not a flat
indexable ROM table like hitbox/anim. Manifest fact established (palette =
per-character sprite-palette bank, 4×16-color, confirm-button selects the
color variant); the exact ROM address binds to the sprite set and is
resolved during sprite porting (M2/M4), not a standalone table lookup.

### Sprites / tiles / sound — pipelines mapped, addresses sprite-bound

**Animation → sprites → tiles chain (decoded):** per-char anim index table
(§ above) → word offsets → anim scripts → each frame carries a 24-bit ROM
pointer (e.g. Demitri anim[0] frame → `PRG:0x134B0A`) to a sprite/OBJ
sub-table → CPS2 OBJ output at `RAM:$708000+` (8-byte entries: X.w, Y.w,
**tile#.w (16-bit)**, attr.w). Demitri's live tiles cluster ~`0xA3F0-0xA540`.

**R2 (tile index space) — quantified finding:** the OBJ hardware tile field
is **16-bit** (max 65536 tiles), but the vsav GFX ROM is 32MB ≈ 2^18-2^19
tiles — so 16 bits cannot address the whole GFX space directly. This is
almost certainly *the* wall that forced Capcom's two-game split (SPEC §2's
"graphics address-space ceiling"), now seen concretely. Resolution hinges
on how the extra high bits are supplied: CPS2 OBJ `attr` high bits and/or a
gfx bank base. **Concrete next R2 step:** decode the `attr` word bitfield
(palette / flip / **tile high bits or bank**) from the OBJ emit code, and
determine whether frame tile#s are per-character-relative (→ port = copy
tiles to new gfx space + set base; no index surgery) or absolute (→ harder).
This is the single most important open item for M3 (ROM expansion) and is
flagged as the R2 deliverable.

**Sound cues (traced):** attacks emit QSound commands via `PRG:0x003190`
(→ QSound port `0x61800F-0x618019`) and `PRG:0x003140` (→ `0x618001-9`);
timing verified (voice cues fire exactly on button-press frames). The cue
ring lives at `RAM:$FF0E0E` (A5-0x71F2); per-character voice sample IDs are
triggered from the move/anim code. Manifest fact established (sound = per-
character QSound sample set, triggered by anim/move events); exact per-
character sample-table ROM address is QSound-bank work for M5.

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

### Start-hold flavor: RESOLVED (community-confirmed 2026-07-27, mechanism pinned)

Community (via maintainer): the Start-hold flavor select exists
**exclusively for Donovan and Huitzil** — hold Start on the character,
then press punch/kick to select. Not Pyron.

Mechanism, fully measured in vsav2 (Japan 970913), Donovan
(`tests/experiments/start_hold_flavor/don_specials*.rpl`):

- **Latch:** `RAM:$FF87C2` (P1 block +0x3C2; P2 mirror +0x3C2 off
  $FF8800). Default 01; holding Start through select confirm clears it
  to 00 (= the other game's flavor). Session-3 finding stands: with only
  normals/chains the latch is never read — the consumers are in one
  command move.
- **Consumers (read-watch across a full motion battery):** exactly two,
  both firing on the **QCB+K special**: the command handler at vsav2
  `PRG:0x05A654` (reads the latch at move start, A6=player struct) and
  the spawned projectile's code at `PRG:0x065FE6` (reads it again,
  A6=projectile slot). No other special/super/DF input in the battery
  reads it.
- **Behavioral fork proven:** identical replays ± Start-hold are
  bit-identical (latch masked) until frame 4296 — the exact QCB+LK
  completion frame — then diverge permanently (the two flavors of the
  move differ). Pre-battery state is identical except the latch; the
  pick identity is unchanged (hitbox base 0x0C8DF8 both runs).

**PORT CONSEQUENCE (measured on the stage-4 build):** both consumers live
inside regions the port already relocates (Donovan code region and
x065e5a), so the flavor fork ships with the port — but vsavj's engine
never writes +0x3C2, and on the ported build the byte is **00**: ported
Donovan currently gets the **VH2 flavor by accident**. DECIDED 2026-07-27
(maintainer): default = VS2. The init shim writes 01 to (0x3C2,A6) on
Donovan init (tunable in donovan.toml `[init_shim]`); verified live on
the ported build. **Stage 5 (session 11): the Start-hold SELECTOR is
implemented on vsavj** — the shim additionally tests the per-player
Start bitmask `RAM:$FF8060` (bit 0 = P1, bit 1 = P2; live through
char-init — unlike the menu-context mirror at struct +0x44, which
clears at match load) and seeds 00 (VH2) when the initing player's own
Start is held. Verified 3-way (`tests/test_m2a_flavor_selector.sh`).
Huitzil gets the same wiring at his port (M3).

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

## M2a extraction findings (session 4, oracle-validated)

`tools/extract_char.py` (vsav2 source, vhunt2 oracle) closed Donovan's full
program-ROM footprint — see docs/tables/donovan.md for the manifest. Atlas
facts established in the process:

- **Sprite/OBJ sub-table region located** (the anim→sprite chain's next
  link): Donovan's 24-bit frame pointers target `PRG:0x334B80-0x360404`
  (vsav2), shifting by **−0x2002C** to vhunt2 — a distinct region family
  from anim (−0x13B74). 1088 distinct sub-tables in 5 clusters; leaf data
  (no further pointers).
- **Anim region measured**: Donovan `PRG:0x27F548+0x20F00` (135KB — the
  earlier ~110-125KB estimate was close). Index tables a/b/c/proj at
  0x27F548/0x28709C/0x287192/0x289EF6 all point inside it.
- **Projectile-path hitbox data is a separate area**: Donovan proj base
  `PRG:0x0D0CA8`, comp `0x0D1002` (bank shift family), ~0x435A span —
  distinct from the player-path block at 0x0C8BB8.
- **Newcomer dispatch structure**: only bank[0]'s slot-0x13 entry
  (0x05AE20) is Donovan-unique; dispatch 01-13 target shared newcomer stubs
  (0x0594xx-0x05ADxx, several tables aliasing one stub). The shared stubs
  sit below his unique handler inside one contiguous code region
  (0x059490+0x3200).
- **Bank gap tables classified by oracle** (docs/tables/donovan.md): most
  are per-char value tables; `0x0BE27A`/`0x0BE2BA` are pointer tables;
  `0x0BCEFA`/`0x0BD7FA` remain unresolved (need consumer disasm).
- **Donovan's code references the bank neighborhood** at vsav2
  `0x0D609E`/`0x0D8398` — below/above bank[0], mapping to vsavj by the bank
  delta rule if the neighborhood layout matches (verify at patch
  generation).
