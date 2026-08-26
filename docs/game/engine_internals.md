# engine_internals — how the engine works, by subsystem

The synthesis document (CLAUDE.md taxonomy): what a stranger reads to
understand the game. Started session 14 with the gfx subsystem; other
subsystems (object system, anim, sound farm, dispatch banks) are still
scattered across docs/game/atlas/character_tables.md, docs/project/tables/
reconciliation.md and patch_notes — fold them in as they get touched.

## NOT YET SYNTHESISED — the standing backlog (audited 14z-68m)

**This document is thin relative to the analysis that exists.** Measured
at 14z-68m: engine_internals 810 lines vs STATE.md 8417 lines. Most
subsystem knowledge still lives only in session logs, which is where
the 14z-68 win-screen re-derivation came from (Donovan's solution was
in STATE since 14z-45; nobody could find it from the task).

**Policy:** when you work on any subsystem below, write its section as
part of that work — the marginal cost is small while the analysis is
fresh in the session, and it is the difference between "documented"
and "findable". Delete the line when the section exists.

**STATUS 14z-71: swept again, at the maintainer's request.** The gap
ratio is down from ~10:1 (14z-68m: 810 vs 8417 lines) to ~4.5:1 (2118 vs
9643). No subsystem is now absent from the docs — but the sweep found a
worse failure than absence: **three section HEADERS described superseded
states**, and one of them ("the 214+P grenade explosion — NOT a
tile-inventory defect") asserted the opposite of what was later measured.
A skimmer reads headers. When a finding is overturned, fix the HEADER in
the same commit, not just append a subsection under it. Two new documents
came out of the same sweep: `atlas/sprite_lists.md` and
`../project/porting_code_regions.md`.

**STATUS 14z-68n: the audited backlog is now CLEARED** — all eight
subsystems below were written the same session the gap was found
(object type dispatch + pool walker, allocator wrappers, pool seeding
/ init_shim, update-queue classes, throw/physics arcs, shadow
servants, Dark Force, companion/pod family). The table is kept as the
FORM to use next time: when you find a subsystem living only in
STATE, add a row, then delete it by writing the section.

| Subsystem | Where the analysis currently lives | Why it will bite |
|---|---|---|

Adjacent docs that ARE current and should be linked rather than
duplicated: `docs/project/cps2_wide.md` (the WIDE profile), `docs/game/atlas/`
(ROM/RAM maps, id space, select screen), `docs/project/patch_index.md`
(mechanism inventory).


## THE DEAD-ROW CLASS — vsav ships table rows as STUBS or ALIASES where
## vs2/vh2 fill them (named 14z-74; SIX instances and counting)

**The single most common defect shape in this port.** vsav and vs2 share an
engine, and their per-character / per-state dispatch and data tables are
index-aligned — but **vsav leaves rows the newcomers need either as a STUB
(pointing at an `rts`, or at a displacement inside the table itself) or as an
ALIAS of a base-half row.** Legacy never notices, because legacy never
indexes those rows. A ported character indexes them immediately.

Recognise it by this signature: **the ported character does something vanilla
never does, and the failure is total rather than subtly wrong** — nothing
draws, or the game resets, or a value is wildly out of range. Nothing
"upstream" is broken: the object, the class, the id and the dispatch are all
correct. One dead row is the whole defect.

| # | instance | vsav holds | vs2 holds | fix |
|---|---|---|---|---|
| 1 | effect-class row 16 (the beam) `0x080AEC` | stub -> bare `rts` | the beam's handler | `[[code_ptr]]` port + repoint (14z-71) |
| 2 | sprite-list drawer, type 12 | table has no such type, and can neither grow (entry 0 IS the length) nor move (`(d8,PC,Xn)`) | a composite handler | takeover of list-type 6 (14z-71) — **NOT unused: legacy lists reach it too (measured 14z-89, 387/948 tripwire arms on replays 21/26); the fallback to vsav's own type-6 code is what keeps that correct** |
| 3 | grab-hold keyframe ptr table `0xBE27A` row 0x10 | ALIAS of row 0x00 (char 0's block) | the tenant's own block | `[[data_port]]` + row repoint (14z-73) |
| 4 | sub-state jump table `0x18468` entry 81 (Cosmo Disruption) | `0x0006` — a displacement pointing back INTO the table | a real handler | **one word**: repoint to `0x0224`, which already holds vs2's identical 8-byte handler (14z-74) |
| 5 | in-fight HUD mugshot `0x89884` + name `0x898C4`, rows `0x10-0x1F` | pure ALIASES of `0x00-0x0F` (both tables) | rows 0x10/0x11/0x13 filled for H/Pyron/Donovan | three tenant-gated pokes + place the art at free-pool anchors (14z-63/75) |
| 6 | per-character palette-routine tables `0x2A8A4`, `0x2B650`, `0x73790` row 0x11 (THREE of them) | ALIASES of row 0x01 (its ANIMATED palette handler) | the DEFAULT no-op handler | **one word each**: `0x2A8C6`/`0x2B672`/`0x737B2` -> `0040` (14z-75, Pyron's blink; sweep with `tests/test_variant_dispatch.sh`) |

**Diagnostic recipe** (all six were found this way):
1. Find the table and the index the tenant drives it with (a breakpoint on
   the dispatcher, or the crash PC).
2. Read the SAME row in vs2/vh2. If vs2 has a real target where vsav has a
   stub or an alias, you are done looking.
3. Before writing: **measure the row DEAD in vanilla** — a read watchpoint on
   that slot across legacy replays, with a **same-instrument positive control
   on a live row**. Two traps, both paid for: the table may be read
   PC-relatively (use the OPCODES space — `wposet`; a plain `wpset` is
   silently blind), and the boot ROM-checksum sweep touches every ROM byte
   once, so **filter by PC** or a dead row looks live.
4. Prefer the cheapest mechanism that reproduces vs2: a one-word repoint if
   vsav already contains identical code somewhere in reach (instance 4), a
   ported handler if not (1), a takeover of a provably unused slot with the
   deadness NOT load-bearing (2), or a data port + row repoint (3).

**Watch for the ALIAS variant specifically** (instances 3 and 4's cousin):
32-row tables whose rows `0x10-0x1F` alias `0x00-0x0F` mean a tenant at a
variant id silently inherits a vanilla character's data — no crash, just
someone else's behaviour. Pyron's physics were another case: without
`port_param32` his velocity rows folded onto a vanilla character's and he
jumped under the wrong gravity. **Check every per-character table a new
tenant touches for its variant-half rows.**

## GFX ROM (sprite/tile) subsystem

- 8 gfx simms per game (x.13m-x.20m, 4MB each) = 32MB = 0x40000
  16x16 4bpp tiles. Group A (13,15,17,19) = tiles 0x00000-0x1FFFF,
  group B (14,16,18,20) = 0x20000-0x3FFFF. 13m/15m hold each tile's
  LEFT 8x16 half (planes 0-1 / 2-3), 17m/19m the right half. Within a
  simm, tile bytes are 16 pairs at stride 4 (canonical extraction:
  tools/gfx_tiles.py; trap: docs/GOTCHAS.md).
- vsavj is a program-only clone set: its gfx (and QSound) members come
  from the parent vsav.zip in the rompath. Any M2b tile work targets
  vsav-member content (or a renamed copy in the build rompath) — NOT
  vsavj.zip, which has no gfx to patch.
- **Measured layout relationships (2026-07-28, locked by
  tests/test_gfx_tiles.sh):**
  - vsav2 vs vhunt2: 202,941 tiles identical at the SAME index — the
    sibling pair shares one gfx layout.
  - vsav2 vs vsav: 201,117 of ~257K non-blank vsav2 tiles exist in vsav
    content-addressed, but only 6,495 at the same index. The shared-cast
    art is the SAME ART, REPACKED at different tile indices. ~56K tiles
    (~7MB) of vsav2 content are absent from vsav: the three newcomers +
    VS2-specific stages/UI (attribution to characters pending the OBJ
    tile-code inventory).
  - One 84KB window (group-A simm offsets 0x200000-0x215000, tiles
    ~0x10000-0x10A80) is byte-identical at the same offsets across
    vsav/vsav2 — system/font tiles that survived the repack in place.
- Consequence for M2b: porting Donovan's tiles is NOT an index-preserving
  copy; his 16-bit OBJ tile codes (+ whatever banking selects among the
  0x40000 tiles) must be remapped from the vsav2 layout to wherever his
  tiles land in the vsav-member space. The shared-tile relocation map
  (content-addressed vsav2-index -> vsav-index) covers effects/shared
  assets he references outside his own art.

## OBJ (sprite) pipeline — the R2 answer (session 14, static decode)

Emitter chain (vsavj): per-frame builder `PRG:0x01ABC8` (clears head of
$708000 list, budget d7=0x380 entries, ~20 subsystem emitters, 0x8000
terminator) -> player dispatcher `0x01AC68` ($FF8400/$FF8800 + linked
companions via +0x28..+0x2E, layer-ordered) -> single-object emitter
`0x01AF9E`: A0 = [[obj+0x1C]+4] = OBJ record; record[0] selects a format
handler (jump table 0x1AFBA; format 2 -> 0x1B234).

Record: format.w, budget.w, count.w (entries=count+1), cptr.l -> X/Y
word-pair list, then (tile.w, attr.w) per entry. Emit: X|=obj+0x1A,
Y|=obj+0x18, tile written RAW — **tile codes are ABSOLUTE 16-bit values;
no per-character base is added**. The 18-bit tile space is reached via
**Y-word bits 13-14 = tile bits 16-17** (FBNeo cps_obj.cpp:
`n |= (ps[1] & 0x6000) << 3`), i.e. the bank rides object field +0x18.
Per-char bank init: `move.w table(pc,d0.w), $18(a6)` — vsavj table
`PRG:0x282D4`, vsav2 `PRG:0x27530` (PC-relative => read via OPCODE
space, the encrypted-read gotcha). Multi-tile entries: bx=(attr>>8&15)+1,
by=(attr>>12&15)+1, cell tile = (n & ~0xF) + (dy<<4) + ((n+dx) & 0xF) —
row stride 16, within-row wrap: **code remaps must be 16-aligned**.

Measured inventories (tools/obj_records.py, locked in
tests/test_gfx_tiles.sh):
- Donovan (vs2, bank 3 = table row 0x13 value 0x6000 + hardcoded #$6000
  setters in his own regions, e.g. vs2 0x5CF38): main band
  0x863F-0xC2EF, 15,171 tiles (1.9MB), extent 0x3CB1; +112 scattered
  low-code shared-effect tiles.
- Jedah (vsavj, bank 2 = slot-0x0F table value 0x4000): main band
  0xAD3D-0xEEBB, 16,658 tiles (2.1MB), extent 0x417F; secondary band
  0xA0A0-0xA51D (1,036 tiles).
- Huitzil (vs2, bank 3 = table row 0x10 value 0x6000): main band
  0x0AF6-0x4EFC, 15,010 tiles (1.88MB), extent 0x4407; +24 low
  shared-effect tiles 0x0057-0x06D8. 15,034 unique total (14z-67b:
  walker entry-bounds fix + per-tenant sweep window).
- Pyron (vs2, bank 3 = table row 0x11 value 0x6000): main band
  0x4ED5-0x8647, 14,171 tiles (1.77MB), extent 0x3773; +54 scattered
  (0x003F-0x3615, 0x40AF, 0x462A-0x47C3, 0xA42C). 14,225 unique total
  (14z-67b).

**The three tenants natively coexist in ONE bank (14z-67, the D4
budget measurement, locked by tests/test_gfx_layout3.sh):** vs2 packs
all newcomer art into bank 3 at mutually compatible codes — H, P, D
bands nearly back-to-back, boundary overlaps (H∩P 39 / P∩D 33 / H∩D 82
codes) being SHARED tiles. Consequence: H and P place into WIDE group C
bank 4 at DELTA 0 (native codes, no record remap at all), disjoint from
Donovan's frozen +0x2750 band+shelf by interval (max H∪P code 0xA42C <
his SAFE_LO 0xAD80). Layout ledger: build/manifest/gfx_layout3.toml.

**M2b consequence: DONOVAN FITS IN JEDAH'S MAIN BAND** (extent 0x3CB1 <=
0x417F, 15,171 <= 16,658) — no gfx ROM expansion needed for him. Port
shape: (1) re-encode Donovan's tile data into vsav gfx members at
Jedah's band positions (bank 2, 16-aligned constant delta); (2) add the
same delta to every main-band tile word in his ported anim records;
(3) patch his hardcoded #$6000 bank setters to #$4000 (slot-0x0F table
row already provides 0x4000 for free); (4) map the 112 shared-effect
tiles via the content-addressed vsav2->vsav relocation map (their art is
shared, positions differ). Exclusivity (measured, session 14): player-OBJ side, Jedah's band is
exclusive across all 0x18 slots EXCEPT Sasquatch (slot 0x0A, also bank
2) sharing 44 tiles at the band head, 0xAD3E-0xAD74 — the safe Donovan
placement floor is 0xAD80 (16-aligned), leaving extent 0x413C >= the
needed 0x3CB1. Caveat: slot 0x04 (Zabel) walked to 0 records (walker
gap — different format or region bounds; he is bank 3, so no
Jedah-band conflict either way, but close the gap before trusting the
walker for other purposes). Remaining exclusivity unknowns: STAGE
(scroll) tiles — scroll layers address the same 32MB via their own
banking, and Jedah's stage is LEGACY content (all stages stay); the
scroll-side inventory must confirm the absolute range 0x2AD80-0x2EEBB
holds no stage art before any tile write. Also open:
portrait/name tiles (select screen) are a separate inventory; Anita's
bank attribution rides the same +0x18 machinery (her spawn sets it).

### M2b tile-data step (session 14, static build + verification)

`tools/build_gfx_donovan.py`: places Donovan's 15,171 main-band tiles
from vsav2 group-B simms (bank 3) into copies of vsav's group-B simms
(bank 2) at delta +0x2750 — placed codes 0xAD8F-0xEA3F, above the
Sasquatch-shared head, inside Jedah's band. Uses the canonical
extraction plus its verified inverse (`gfx_tiles.write_tile`;
scatter-back round-trip asserted on every placed tile). Verified every
untouched tile byte-identical. Emits `remap_spec.json` (delta, band,
bank words) for the PRG-side patcher. Visual check: placed range
renders Donovan sprite art.

STAGE 6 BUILT (fingerprint 06f99f4e…, statically verified end to end):
generator gfx_remap pass rewrites the 13,171 main-band tile words in
all 1,122 OBJ records (runs post-relocation — record/coordinate
pointers validated against PLACED addresses); six #$6000 bank setters
port_patched to #$4000 (stage-gated rows); [table_fix] pads x026142 to
0x1440 and rewrites the WHOLE ported per-char bank table with vanilla
vsavj values — fixing two stage-5 latent defects: the table was
truncated at row 9 (the x088512 effect caller d0=0x0A read past the
ported end) and carried VS2 bank values (row 0x0F = 0x0000 => bank-0
reads — likely THE main-sprite garble mechanism). Output-image checks:
placed records walk clean, band exactly 0xAD8F-0xEA3F matching the
placed tiles, table decrypts to vanilla values, setters #$4000. The
rompath carries the patched vsav.zip (ROMDIR pristine); stage-5
rebuilds still reproduce frozen a02aeeff byte-identically.
Still open before playtest-ready graphics: the effect-record map — 85
of 114 low-code effect tiles resolve content-addressed into vsav
(scattered banks 0/2 => per-record bank+code remap; one record = one
object = one bank), 27 unresolved (effects stay garbled this stage,
never crash — tile codes cannot fault); portrait/name (select screen)
tiles; in-emulator verification (QUEUED).
In-emulator verification queued behind the maintainer's machine
availability, incl. the scroll3-vs-band watch (stage art exclusivity has
strong static evidence — 99.3% band saturation by Jedah's own records +
visual — but the frame-level confirmation wants a Jedah-stage replay).

### Sprite palette pipeline (session 14b, playtest-driven)

Character sprite palettes: per-char pointer table (vsavj `PRG:0x38C198`,
vs2 `PRG:0x396B94`; one long per char, indexed by the pre-scaled runtime
char id), each pointing at a 0x500-byte block (12 rows to palette RAM
`0x90C140` + confirm-button variants). Uploader vsavj `PRG:0x1C3FE`
(vs2 twin `0x1AE6E`), copy helper 0x1C3A4; the A5+0x7404..0x7410 page
slots + fade scheduler (0x142C2) are the separate stage/system path
(atlas). The M2b port places Donovan's whole block (vs2 0x39CB9C, VS2
provenance) and poke32s row 0x0F — replaced-slot content, superset-
clean. Portrait/select-art palette tables (vsavj 0x3B5988/0x3BAEA8
family, keyed >=0x18-split) ride with the portrait work. Other
0x90C140 writers (vsavj 0xB0AC attract path, table 0x3A3CA0 keyed by
$114(a5)) not yet repointed — if the attract demo shows wrong Donovan
colors, that is the mechanism.

### M2b in-emulator verification (session 14c, machine window)

All green on stage-6 fingerprint 71601263:
- tests/test_m2b_stage6.sh (the permanent M2b gate): stage-6 build with
  static output verification inside, five guarded soaks (moveset, DP
  spam, round-2, input chaos, 40K arcade marathon) END-clean, and the
  full masked legacy gate — flicker inventory UNCHANGED (the gfx work
  perturbs zero bytes of legacy live RAM).
- Oracle + dual-emulator + flavor gates re-run against the stage-6
  rompath: PASS (HP trajectories, anchors, latches identical to the
  frozen-stage behavior).
- tests/test_m2b_scroll3.sh: scroll3-vs-placement exclusivity measured
  live — tests/lua/scroll3_watch.lua scans the scroll3 tilemap every
  frame; 0 danger frames over the attract stage rotation, the arcade
  marathon, and match replays. The scroll3 base register is write-only,
  written ONCE at boot (PC 0x926, base 0 => map at VRAM 0x900000;
  proven constant across 42,000 marathon frames via trace_writes
  WATCH=800106). MAME Lua traps recorded: emu.register_frame_done is a
  single slot (replay.lua clobbers it — use add_machine_frame_notifier)
  and add_machine_*_notifier subscriptions must be pinned in globals.

Remaining before an M2b freeze: select-screen portrait/name art (+their
palettes, vsavj 0x3B5988/0x3BAEA8 family), the attract palette path
(0xB0AC/0x3A3CA0), and the x2b7ef4 engine-effect tail (385 non-same-idx
tiles — minor effect artifacts if any).

## The ARCADE LADDER: who you fight next, and where (14z-94, measured on
## the #92 crash; decoded end to end and confirmed on screen)

Depends on `atlas/ram.md` rows: `$FF8100` (stage index), `$FF1E48`/`$FF1E50`
(the pick block), `$FF8110` (in-use mask), `$FF8114` (chosen index),
`$FF8121` (venue byte), `$FF8138` (scan bound), `$FF8782`/`+0x382` (voice
class).

**Two parallel 36-row tables drive it.** `PRG:0x00B268` (table A) holds
candidate CLASSES; `PRG:0x00BB68` (table B) holds the STAGE for each. Each
row is 8 groups of 8 bytes; a row is one character's ladder and a group is
one rung.

`0x00af16` copies 8 bytes from each table into `$FF1E48` and `$FF1E50`, at
offset `($382(a0) << 6) + $FF8121` — the row is the character's voice class,
the group is the venue byte. `0x00aeca` then scans **one index across both
lists**: it walks until it finds a candidate whose class bit is clear in the
in-use mask `$FF8110.l`, or until the index reaches the bound `$FF8138`
(measured 6), whichever comes first. It writes the chosen CLASS to the
opponent's `$382` and table B's byte **at the same index** to `$FF8100`. So a
ladder entry is a PAIR: *fight this class, at this stage.*

That structure is why the two tables cannot be reasoned about separately, and
why the in-use mask makes the pick a lottery — the same rig can take a
different branch run to run, which is what made #92 present as a race.

**`$FF8100` is the stage, and it is not just a caption.** Three readers,
measured:

| PC | what it does with `v` |
|---|---|
| `0x05ffa6` | `A0 = 0x26775A + 2v - 4`, stored to `$1c(a6)` — the stage-name banner record |
| `0x01bf5e` | indexes a `0xA0`-strided palette block into palette RAM `$90C2C0` |
| `0x004daa` | `v/2 + 9`, into a dispatch at `0x31da` |

Confirmed on screen: poking `$FF8100` after the selector runs changes both
the banner on the arcade map screen and the venue the following match is
fought in — same rig, same frame, same matchup, different stage.

**The banner family is a run of fmt-4 glyph records**, addressed from an
ANCHOR that is the family's first row, not the pointer table's base:

    vsavj  anchor 0x26775a = table 0x26771e row 0x0f   12 stages, v = 0x00..0x16
    vsav2  anchor 0x2a0a96 = table 0x2a0a4a row 0x13   13 stages, v = 0x00..0x18

Both games number `v=0x00` at their own first row, so **the twelve shared
stages are identical at identical values** — a port owes no renumber. vs2's
thirteenth, `v=0x18`, is REVENGER'S ROOST, which vsav does not have; selecting
it walks off the family into the `0x00400000` terminator (#92). Decode either
game with `tools/decode_stage_banners.py`, and read the anchor out of the code
rather than assuming the table base — assuming it invents a "+8 renumber"
between the games that does not exist.

**Two marker values in table A are not classes**, measured over all 36 rows:
`0x18` sits at group index 7 of every row (never scanned — the bound is 6),
and `0xff` fills rows `0x0b` and `0x1b` entirely, an empty-ladder marker.
Class `0x0b` correspondingly never appears as anyone's candidate.

**Legacy rows never reference a tenant class** (0 occurrences over classes
`0x00-0x0F`), so in arcade mode the fifteen original characters never
schedule Donovan, Phobos or Pyron. Extending that is a content decision
nobody has taken, not a defect.

## Select-screen (portrait/name) pipeline — mapped (session 14c)

Decoded via read/write/breakpoint traces on the live pick replay
(trace_writes gained mode "b" = execution breakpoints):

- Menu objects ($FFB800+0x80*n) are OBJ objects drawn by the standard
  emitter; each gets its anim chain via [obj+0x1C] -> 8-byte frame
  structs (flags.l with 0xFF top byte, payload.l = OBJ record; flag
  bit6 = stop, bit7 = indirect). The LIVE character preview at select
  is the char's own ported records — already correct in stage 6.
- Element dispatch: master word-offset table `PRG:0x267112` (vs2 twin
  `0x2A0426`; consumer `lea table; move.w (a0,d0.w); lea (a0,d0.w)` at
  0x15084), element ids per UI piece — 16-BIT OFFSETS, cannot reach
  ported regions; not the porting handle.
  **DECODED 14z-93.** The consumer is `andi.w #$00ff,d0 / add.w d0,d0 /
  move.w (0,a0,d0.w),d0 / lea (0,a0,d0.w),a0 / move.l a0,(0x1c,A6)` at
  `0x015084-0x015095`, so it writes a MENU object's `+0x1C` chain pointer.
  **The table BASE is supplied by the CALLER, not baked in** — the same
  resolver is used with the owner's anim table (`donovan.toml:985-1000`,
  the select-companion keeper), and `0x15088` is a documented UNMASKED
  entry point that skips the `andi.w #$00ff,d0`. So an address near
  `0x267112` does NOT imply this table was the source.
  **`flags.l` here does NOT have the 0xFF top byte** the menu anim chain
  uses; `0x00400000`/`0x04000000`/`0x06000000` are the real values, so that
  test is not a validity discriminator for this table.
  **`0x400000` reads IDENTICALLY on stock and WIDE (measured 14z-93):**
  `7080 807d 6421 0000 0040 0010` on both, diverging only from +0x0C. So a
  vanilla pointer of `0x00400000` dereferenced there is NOT a WIDE-profile
  artefact — the reservation holds, and a stock build reaching the same
  state would take the same garbage index `0x7080`. Recorded because the
  opposite was proposed and falsified.
  **Do not conclude a base offset from arithmetic alone (14z-93, GitHub
  #92).** A crash pointer `0x267786` is `0x26778a - 4` AND is row 0x1A of
  the per-char long-pointer table `0x26771E` — two tables sitting near each
  other make several stories fit. Measured attribution (full-replay write
  tap on the field, PC-histogrammed) put the writer at `0x05ffb6`, the
  SELECT family — not this resolver at all. The off-by-4 reading was
  retracted.
- THE PER-CHAR ROOT: helper `PRG:0x5F328` — `movea.l #$2672AA,a0;
  andi #$ff; lsl #2; lea -4(a0,d0.w)` with d0 from the +0x382 select id
  (P2 side +0x20 rows; other index families pre-scaled). Root cells
  read during a full slot-0x0F pick (bp-enumerated): [0x26739A,
  0x2674AA, 0x2678BA, 0x2678DA, 0x26791A, 0x26799A] — 32-bit longs,
  FULLY REPOINTABLE. Their chains cover the hover portrait, the
  confirm-zoom animation (records 0x271Cxx), and small pieces; the
  name banner rides the per-char long-pointer table `0x26771E` row 0x0F
  (record 0x2690B6, fmt-4, +0x3800 system glyph codes) with vs2 twin
  `0x2A0A4A` row 0x13 (record 0x2A1FDC).
- Jedah's select art: ~2,000 tiles at codes 0xAxxx-0xBxxx in BANK 1
  (menu objects run +0x18 = 0x2000) — absolute ~0x1A5xx-0x1B9xx; freed
  when he goes. Donovan's equivalents: vs2 root table `0x2A05E2` rows
  0x13/0x33 (P1/P2) + the newcomer select-data zone 0x2A1FDC-0x2A8xxx
  (records/structs; NOT part of any ported region yet), art in vs2
  bank 1 (the 0x10EF6-0x12728-area vsav2-only clusters).
- Sibling code twins: vs2 select module ~0x6B3DE (root helper), plus
  two more root-helper twins at vs2 0x3D314/0x3ED4C reading table
  0xD153E — a DIFFERENT consumer family (likely in-match intro/win
  portraits) to inventory when those screens get ported.

Phase-1 attempt (session 14d) — measured corrections to the map:
- THE LIVE PREVIEW at select ALREADY WORKS in stage 6 (obj $FFB880
  carries [0x1C] into the ported anim region with bank 0x4000).
- The still-Jedah elements at frame 2000 (patched build, live dumps):
  big portrait = obj $FFB980 [0x1C]=0x267462, frame piece = $FFB900
  [0x1C]=0x2675E2, more pieces $FFB800/BA00 at 0x2689FA/0x268A3A,
  wheel = $FFBB00+ at 0x268B8A+ (shared). These chains are INLINE
  POINTER ARRAYS in the shared web (plain 4-byte record pointers, the
  walker's flag bytes overlap pointer bytes — semantics still not fully
  decoded), NOT reached through the three cells phase 1 poked: pokes at
  0x26739A/0x26768A/NAME_ROW landed and changed nothing on screen.
- A Demitri-pick dump shows menu objects riding the SHARED element
  window (0x267F32-0x267F72) during select — the 150-entry records are
  most likely the WHEEL (15 chars x 10 entries); the per-char big-art
  group attribution (0x2719xx Jedah confirm records etc.) still needs a
  two-char differential dump AT THE HOVER moment.
- SPACE FACT for the eventual port: both PRG holes are nearly full
  (hole A free ~0xE80, hole B ~0x32A0); the ported select web (~51KB)
  must live in JEDAH'S FREED ANIM REGION [0x248B88, ~0x267000) — pure
  slot-0x0F data orphaned by the port; the shared tail 0x267xxx+ is
  live and must not be overwritten.
tools/select_port.py holds the phase-1 machinery (zone extraction,
structure-walked relocation, prg-dir chaining) — NOT wired into the
build until the real per-char handles are proven by differential dumps
(hover-moment, two chars). Next session: dump $FFB980's [0x1C] at the
HOVER frame for two different picks; diff the group spans; patch the
inline pointers in place (32-bit, slot-0x0F rows only).

### Select-screen phase 2 (session 14e): the real handles, empirically

Differential cursor dumps (menu objects at frames 960-1100 of the pick
replay) settle it:
- The three still-Jedah UI pieces ride PER-WHEEL-SLOT pointer arrays,
  advanced by CURSOR MOVEMENT (stride 8 per wheel step): big portrait
  (obj $FFB980, array ~0x267416+), name/frame (obj $FFB900, ~0x267596+),
  highlight (obj $FFBA00, ~0x2689F6+). Jedah's record cells: [0x267466]
  = 0x271CE8 (big portrait, fmt 2, 17 entries), [0x2675E6] = 0x27221A
  (name), [0x268A3E] = 0x2724A2 (highlight). P2 arrays are +0x40 copies
  POINTING AT THE SAME RECORDS — replacing record CONTENT fixes both
  sides with zero pokes.
  **CORRECTED 14z-61 (docs/game/atlas/select_screen.md, measured):** that
  `+0x40` block is the **VARIANT HALF** (rows 0x10-0x1F, byte-identical
  aliases of 0x00-0x0F), not the P2 array. It looks like P2 from a
  differential dump precisely because it aliases. The real player offset is
  **+0x80**, confirmed both in the consumer code (`d1 = 0x80` at
  `PRG:0x06C0E0`) and in-emulator (P2's object fetches its own record from
  the +0x80 block). The in-place conclusion still holds for slot 0x0F — the
  two players' rows point at the same records there — but the reason
  matters for M3a: at a variant id the tenant has its OWN rows in both
  blocks, so the mechanism becomes a two-long repoint instead of content
  surgery.
- Donovan's equivalents (live dump on real vsav2, oracle replay, cursor
  on him): records 0x2A63F0 (7 entries, 38B) / 0x2A657E (14B) /
  0x2A6750 (14B) — ALL SMALLER than Jedah's → in-place replacement
  fits, coordinate lists fit inside Jedah's cptr space likewise.
- Art: Donovan needs 106 bank-1 tiles (9 blocks incl. an 8x8 portrait
  core); Jedah's select-only exclusive scatter (106 positions) cannot
  host the 8x8, but his full select+confirm family exclusive art
  (1,173 positions incl. the VS-bust rectangles) fits all 9 blocks
  (greedy fit verified; placements recorded in session log).
- OPEN SAFETY GATE before writing tiles: the placements borrow from
  what is believed to be Jedah's VS-splash bust art; the in-match
  module family (root table vsavj 0x0B76C0, helpers 0x3C6CE/0x3DE84 —
  STRUCTURE DIFFERS from the select table, chains did not parse) must
  be empirically dumped (VS-splash frame OBJ list) to prove no OTHER
  character's splash tiles overlap the chosen positions. Then:
  select_port phase 2 = in-place record surgery + tile placement +
  code remap, verified by select-screen snapshots + the M2b gate.

### Select phase 2 SHIPPED (session 14e, fingerprint e98a357a)

In-place record surgery works: Donovan's big portrait and name banner
render on the select screen (snapshot-verified, both the hover and
speed-select phases). tools/select_port.py replaces Jedah's two records
(0x271CE8 big portrait, 0x27221A name) with Donovan's (both smaller;
coordinate lists overwritten inside Jedah's own list space; tile codes
rewritten to the placements), and build_gfx_donovan places the 101
bank-1 tiles into Jedah's freed select/splash art (group-A members now
patched too). The third piece (cursor highlight 0x2724A2) is
deliberately NOT replaced: its vs2 coordinates assume vsav2's wheel
geometry — replacing it drew a displaced label. Remaining select
cosmetics: wheel face (background scroll art), highlight ring, VS
splash bust + win screens (the 0x0B76C0 in-match family), attract
palette.

GATE ANOMALY (recorded per the CLAUDE.md §4 standing watch): one gate
invocation showed 02 masked-diverged + 10 with 84 divergent frames from
frame 663; the SAME build then passed 02/10 individually (twice,
deterministic, exact frozen inventory) and a full gate rerun was
entirely green. Unreproduced one-off — possibly environmental; the
masked-legacy helpers now PRESERVE failing logs (build/gate_failures/)
so any recurrence self-documents with a RAM-diffable log. If it recurs,
stop and root-cause before any freeze.

### Select palettes + the splash/win map (session 14f)

- SELECT PALETTE FIXED (playtest round 7): the portrait/name palette
  rows upload from an 11-variant x 16-char grid at vsavj 0x3AC000
  (uploader 0x5F136: row = base + (variant*16 + char)*0x20, char from
  the +0x382 select id; palette RAM rows 0x1B/0x1C). vs2 special-cases
  Donovan in code (0x6B1A0: cmpi #$13 -> += 0xC6): his 10 variant rows
  at 0x3C117C + (0xC6+v)*0x20. select_port overwrites Jedah's 11 grid
  slots in place (clamping to Donovan's last row). Battery green
  (fingerprint 4fc8d14b).
- VS SPLASH / WIN SCREENS mapped: the busts are drawn by objects
  ($FFC100/$FFC180) whose [0x1C] anchors are ROOT-TABLE CELLS in three
  char-scaled families — d0 = char, 4*char, and 0x80+char (P2 = +0x20
  within each) — over the same table (0x2672AA; vs2 0x2A05E2). The
  chains are multi-record slide-in animations whose record sizes do NOT
  pair with Jedah's => in-place replacement impossible; the port needs
  the phase-1 zone machinery (vs2 web -> Jedah's freed region,
  structure-walked relocation) + SIX cell pokes. Blocking decode: exact
  chain termination (flag-byte semantics of the 8-byte structs) so the
  per-chain record/tile inventory is exact (naive walks wander into
  neighbors' chains); then art placement (Jedah's freed pool: ~1,072
  positions left after the select placements).

## Anim-script walker + hit-freeze / reaction subsystem (session 14z-42, measured)

The per-object anim interpreter ("walker") both engines share
(vs2 block 0x26142-0x27582; vsavj twin family at 0x27Exx; our port of
the vs2 block sits at PRG:0x0CD390, so ported-object node writes show
PC 0xCE38A = vs2 0x2713C + port offset):

- **Node format (0x18 bytes):** +0 duration byte — loaded into
  obj+0x20 as a countdown (`move.l (a0),$20(a6)` on node set;
  decrement at vs2 0x271C4 `subq.b #1,$20(a6)`, ours 0xCE412); +1
  flags (bit7 = follow the LINK at +0x18 instead of advancing
  sequentially — loop-backs are links, e.g. the Lightning Sword loop
  node 0x284A48 links +0x18 -> 0x284988); +4.l sprite-record ptr;
  +8.w/+0xA hitbox-family words; +0x10.. the [cf14]..[0b] script-op
  area; +0x16 byte nonzero -> per-node sfx (jsr 0x5122 on vs2 with
  d1/d2/d3 from the per-char table 0xD95B8 — the call our
  stubbed_sound row silences).
- **Node write:** `move.l a0,$1c(a6)` at vs2 0x2713C. Two writes in
  one frame = a zero/1-duration chain, normal.
- **Hit-freeze ("the floating holds"):** on each connected hit the
  victim-side reaction handler freezes BOTH parties via obj+0x5C
  (walker timer hold — obj+0x20 simply stops decrementing while
  +0x5C runs). Because freezes track hit frames, holds float across
  nodes between loop iterations; they are NOT data durations.
- **Victim-reaction handlers** (dispatched per hit; the electric-
  shake one: vs2 0x226E0 == vsavj 0x23AC8, structural twins, probed
  1 hit = 1 entry): write victim +0x5C / attacker +0x5C (attacker
  found via victim+0x32 link), +0x14E=4, victim +0x120->+0x0B,
  +0x3A->+0x14, clr +0x16, then property-table lookup
  (vs2 0x27FD8 == vsavj 0x28D00, byte-identical through class 0x4D)
  -> reaction node. **ENGINE-GENERATION DRIFT: the constants.**
  vsavj (older): victim 0x18, attacker 0x0B, no +0x147 write.
  vs2 (newer): victim 0x0C, attacker 0x04, PLUS victim +0x147=0x0C —
  and **+0x147 is the multi-hit re-hit gate** (period ~10f with it,
  ~victim-freeze-length without it: vsavj-constants gave 12f, vs2
  freeze without $147 gave 7f, vs2 full semantics 10f).
- **Mash extension:** extends the LOOP-LINK iteration count (3 base
  -> 4 measured with LP/MP-alternating mash on both games; maintainer
  max-mash datums 5/9/11 per strength). The mechanism is
  engine-equivalent between the games — no port surface.
- Our fix for Donovan-attributed electric hits:
  ls_freeze_vs2_{victim,attacker} site_thunks at vsavj
  0x23AD8/0x23ADE (see donovan.toml 14z-42 block).

## Command-input / motion-tracker subsystem (session 14z-48, measured both engines)

How special-move inputs are recognized (identical architecture in
vsavj and vs2; addresses vs2 / vsavj-twin):

- **Per-char command evaluation:** engine table 0xD7718[char_id]
  (vs2) -> the character's own eval handler, run per frame. The
  handler calls one MOTION HELPER per command it owns.
- **Motion helpers:** tiny routines, one per motion shape+facing:
  `lea <step-table>(pc),a3; bra <tracker-dispatcher>`. Families:
  vs2 0x29114-0x291EC (tables 0x29974-0x29A80), vsavj
  0x29DC2-0x29F42 (tables 0x2A610-0x2A780). Right/left facing =
  paired tables (terminators 0x0F00 / 0xF000). The step tables are
  read via (a3,d0) = DATA-space (the pc-relative lea only computes
  the address): read them from data.bin, and any port must place
  them as raw data (the farm_port emitter does).
- **Trackers:** per-command progress structs in the player object
  (+0x308..+0x338, 8 bytes each: +0 state, +1 step index, +4
  timeout counter). A helper's dispatcher advances its tracker:
  state machine with (state 2) exact-direction match — step word
  low nibble vs the 4-bit direction code at obj+0x12A, flag bit 7
  = mask-mode — and (state 4) bitmask match — step word & 0x7700
  vs obj+0x1AC|+0x1AE — plus flag bits (bit 4 = advance-and-
  continue same frame, bits B/F = diagonal-leniency classes).
  Completion returns d0=1 to the char handler, which stamps the
  matched command id at obj+0x106 (+0x105 = trigger latch); the
  trigger dispatcher (0x21BFC / table 0xD7398[char]) then runs the
  move-start.
- **Dispatcher kinds:** several dispatcher entries exist per engine
  (vs2 0x292A4/0x2938A/0x29422..., vsavj 0x29F4A/0x2A030/0x2A0C8/
  0x2A128/0x2A1B4/0x2A2EA/0x2A42E) — motion vs charge vs
  button-sequence families. The state machines of corresponding
  kinds are proper twins ACROSS engines; only the TABLES differ.
- **Engine-generation retune (the 14z-48 trap):** VS2 changed some
  motion TABLE definitions vs vsavj — e.g. 63214: vsavj
  [1,5,4,16] (final step dir+flag fused) vs vs2 [1,5,4,6,12]
  (final step split; extra required entry) — an input-leniency
  retune. vsavj's own HC tables serve the vanilla cast (Morrigan/
  Lilith/Bulleta...; verified by caller scan). Ported newcomers
  should carry vs2's exact tables via farm_port rows (vs2 input
  feel); reconciliation of helper families MUST match by table
  content + dispatcher kind, never code similarity (GOTCHAS).

## In-fight HUD asset tables + the select-wheel record (session 14z-49, measured)

Two venue-asset families, both per-slot, both now serving Donovan on
slot 0x0F.

### In-fight HUD top strip (mugshot beside the timer, name under the bar)

OBJ sprites, staged per frame from per-char tables:

- Emitter `PRG:0x1BB3C` reads RAM-staged records at `RAM:$FF5D94`.
- Stagers: mugshot `PRG:0x89370`/`0x8939C`, name `PRG:0x89684`.
- Per-char tables: mugshot code words `PRG:0x89884` (entry 0x0F =
  0x05C8), name entries `PRG:0x898C4` (8 bytes/char: code word,
  attr word, x offset word, width word).
- **Stager base is per-GAME: vsavj adds +0x3800 to table codes, vs2
  adds +0x4200.** (Measured from live OBJ: vs2 Donovan mugshot OBJ
  code 0x4D62 = table 0x0B62 + 0x4200; assuming +0x3800 placed the
  wrong vs2 art on the first attempt.)
- vs2 twins: tables `0x990CE` / `0x9910E`, Donovan row 0x13.
- Live lock values (replay 56 f2600, P1 Donovan vs P2 Victor):
  mugshot (200,32) code 0x3DC8 2x2 attr 0x112A; name (144,40) code
  0xBE8C 3x1 attr 0x0202. P2 mugshot rides (280,32) with its own
  table entry. Gate: test_don_reactions ES section.
- The in-match strip does NOT exist on the VS splash (different
  venue with its own big-portrait records — that one was already
  correct for Donovan).

### Select wheel (the medallion ring)

ONE static OBJ record, no rotation, no hover zoom — the cursor ring
(pal-1e pieces) is the only thing that moves:

- Record at data `0x272A92` region (pairs start `0x272A72`): 18
  (code word, attr word) pairs; a header longword `0x0032A50A`
  points at the coordinate list (center-relative x,y word pairs;
  wheel center raw ≈ (256,176); list byte-identical to vs2's at
  `0x303AAC` for the shared 18 entries).
- Cells are fixed perspective sizes: 3x2 close, 2x2 far, ONE 3x3
  (the top-front cell). Cell → char map is by ART, not by pal
  index: **the 3x3 pal-07 cell at (264,64) is GALLON's** (werewolf
  face); **Jedah's cell = code 0xB526 attr 0x1214 pal 14 at
  (236,57)** — the purple wing-wrapped icon, the cell the cursor
  ring brackets when picking slot 0x0F (ring center (256,72),
  replay 58).
- Palette: each cell owns a select-venue palette row (row == attr
  pal index). Row sources live in two 32-row blocks: A `0x3A3800`
  (the wheel view — live-verified rows land at `90C000 + row*0x20`
  with the bright nibble forced to F) and B `0x3A3C00` (another
  sub-venue; its row 14 content differs — only block A's row 14 is
  the wheel's).
- vs2's wheel: same record family at `0x2A6D8C+` with THREE record
  variants (base 18-cell + two 21-cell variants appending the
  newcomers) — there Jedah is demoted to 3x2 `b113 1207` and
  nobody is 3x3. The vs2 newcomer icons: Donovan = `0xB10B` 3x2
  (vs2 pal row 05), Pyron = `0xB0F5` (row 11), Huitzil = `0xB108`
  (row 13, the gold one). Identified by color render, NOT by pal
  numerology (see GOTCHAS).
- Donovan-on-slot-0x0F fix: art `'0xB10B,3,2' -> '0xB526'`
  (effect_tail), colors data_port `med_pal_row14_a` (block A row 14
  <- vs2 `0x3BAFDC`). Record and coords untouched. Gate:
  test_don_colors select section (frozen row 14 + record-intact +
  Gallon-cell tripwire).

### The palette-fade staging buffer (14z-49b, measured)

Venue FADES stage palette-block rows through a work-RAM buffer before
they land at `90C000`: select block-A row 14's slot is
`RAM:$FF4182-$FF41A1` (family: $FF4182 + row*0x20). Measured on the
match→win fade (05_timeout_idle f9126). The LIVE select screen does
NOT go through this buffer (a full select traversal stays
bit-identical), and the destination venue's own palette overwrites
the staged rows — so buffer content is display-only and transient.
Consequence: any ROM-side select palette-block content change (the
medallion recolor; future Huitzil/Pyron rows) surfaces in this buffer
during fades in LEGACY replays. Handled by the third masked window
(the per-set `mask` file, default in tests/lib/masked_compare.sh, +
docs/game/atlas/ram.md; ratified round 64, STATE 14z-49b; the
m2a_common.sh copy this line used to cite was removed 14z-97). The family is `slot(row) = $FF3F02 + row*0x20`
(14z-64); the WIDE track masks the medallion rows' slots too — V2 rows
0x16/0x19/0x1A (14z-64), V3 adds row 0x1D (14z-88, after the 14z-87b
medallion move 0x1A→0x1D). **A palette-ROW move is a STAGING-SLOT move**
— the mask, and the vanilla masked basis it is compared against, must
move with it (docs/game/atlas/ram.md "Masked windows"). Atlas rows this
section depends on: ram.md `$FF4182-$FF41A1`, `$FF41C2/$FF4222/$FF42A2`
family row, and "The palette staging area".

### The palette-SEQUENCE uploader (14z-75, measured on the Pyron blink)

A second, separate path writes `90C000` — not the fade buffer above, and
not the match-start palette load. **Read this before attributing any
"his colours flicker/blink" symptom on a ported character.**

- **Resolver** `PRG:0x02AD82`: `a0 = 0x39A900 + (d0 & 0xFFF) * 0x20`, i.e.
  a global table of 0x20-byte palette rows indexed by a *sequence id* in
  `d0`. Table base `0x39A900`; vs2's twin is **`0x3B0A3C`** (read off vs2's own
  resolver immediate — do NOT derive it by content-matching a row, which
  is how 14z-75 first got `0x3B093C`, exactly 8 rows out). **The two
  tables are NOT row-aligned: vsavj row `0x26` == vs2 row `0x1E`**, a
  uniform +8 shift from row 0x1E up, so a ported script's seq ids must be
  remapped +8. The port already does this correctly (measured: ours asks
  0x26/0x39/0x3A where native asks 0x1E/0x31/0x32).
- **Uploader** `PRG:0x02AD68` (row start) and `0x02AD7C` (row+0x10) copy
  the resolved row into palette RAM, applying `0xF000` — a stored
  `0x0RGB` becomes a palette-RAM `0xFRGB`. Do not expect to find a
  palette-RAM value verbatim in the ROM; search for it with the top
  nibble of each even byte cleared.
- **It is driven by the ANIM SCRIPT**, node by node: `a0` walks the
  0x18 anim-node stride, `a6` is the requesting object's fighter block.
  So a palette sequence is *animation data*, not a per-character palette
  table row — which is why a character can request one continuously.
- **Legacy only ever requests ids `{0x26, 0x27}`** — frozen by
  `tests/audit_palette_seq_ids.sh`, and that audit is the ONLY guard on
  this path, because it never transits work RAM and so is invisible to
  every RAM gate.

**The Pyron instance (14z-75, FIXED) — a DEAD ROW.** His palette row 10
alternated every frame between his own palette and seq row `0x26`; native
held it constant. The cause was NOT the sequence machinery at all but the
**per-character palette-routine dispatcher** that feeds it:

    0x2A894  moveq #0,D1 / move.b ($382,A6),D1     <- the CHARACTER ID
             add.w D1,D1 / move.w ($6,PC,D1.w),D1 / jmp ($2,PC,D1.w)

a word-displacement table at **`0x2A8A4`**, indexed by `id*2`. Most
characters carry displacement `0x0040` = the DEFAULT handler, which animates
nothing. vsavj's rows `0x10-0x1F` alias `0x00-0x0F`, so **row 0x11 handed
Pyron row 0x01's ANIMATED handler** (`moveq #$26,D0 / add.b ($3AE,A6),D0 /
bra 0x2AD82`) where vs2's own row 0x11 is the default.

**THERE ARE THREE SUCH TABLES, not one**, and fixing only the first left the
blink alive on the select screen and the between-fight route map (maintainer
playtest of pyron16). All three carry the same shape and the same one-word
fix to vs2's own value:

| table | dispatcher / index | row 0x11 vsavj -> vs2 | patch |
|---|---|---|---|
| `0x2A8A4` | `0x2A894`, `move.b ($382,A6)` | `008E` -> `0040` | `0x2A8C6` |
| `0x2B650` | `0x2B64C`, `move.b ($382,A4)` | `0042` -> `0040` | `0x2B672` |
| `0x73790` | `0x7378C`, `move.b ($39,A6)`  | `0042` -> `0040` | `0x737B2` |

`0x2B650`'s row-0x11 body carries the SAME `moveq #$26,D0 / add.b ($3AE,A4),D0`
request, branching to the second resolver site `0x2B7E8` — which our build
called 523 times against native's 180, the tell that the first fix was
incomplete. After all three: **0 and 180, exactly native's counts** (and
exactly Huitzil's).

**Find these by SWEEPING for the shape, not by chasing a screen** —
`tools/audit_variant_dispatch.py` / `tests/test_variant_dispatch.sh` do it
statically for any tenant. Legacy-safe by
construction (vanilla never puts an id in `0x10-0x1F`), and measured
legacy-inert: replay 02 bit-identical across the fix.

Other tenants, from the same sweep: Donovan's `0x13` is `0x0040` in all
three tables — the no-op — where vs2 runs his own routines; that is a
MISSING feature, not a spurious one, and harmless. **Huitzil's `0x10` is
`0x004A` in `0x2A8A4`** (row 0x00's handler) where vs2's is the default —
the same spurious class, latent and benign today (0 hits at `0x2AD82` on the
frozen build). `huitzil-m2` is frozen, so that is a maintainer call.
**CAVEAT ADDED 14z-78: that "0 hits" has the provenance problem Plasma Trap
exposed.** It was measured over replays that never fired the move — and
Plasma Trap crashed on every Phobos build ever made while every gate stayed
green, because nobody had played air 214+MK. "0 hits at the resolver" is only
as strong as the moveset the resolver was watched over. Not a claim the row is
live; a claim the evidence is weaker than it reads. The maintainer's 14z-78
full movelist sweep is the coverage it lacked — re-probe `0x2AD82` across it
before treating "benign" as settled.

**The symptom lied about its cause.** `0x2AD82` is the DF-family palette-seq
resolver (H's 14z-69p work), so this read as "a Dark Force recolour without
Dark Force" — but `$FF802E = 0` on both legs. Check the mode flag before
believing a mode.

**Measuring this path at all:** a watchpoint on the palette ADDRESS works
on both games regardless of their different PCs (`WATCH=90c140,20,w`),
which is how the native leg was measured without first finding vs2's
uploader. Compare legs by a PHASE-INDEPENDENT property (distinct values
over N consecutive frames), never frame-indexed — the two games are not
on the same frame, and a frame-indexed diff produced a confounded figure
that stood for a whole session (STATE 14z-74/75 retraction).

### 14z-105: two more things the select screen carries (atlas: select_screen.md)

- **The wheel record now draws the VERSION STRING.** The copied roster21
  record (21 cells) gained N 1x1 glyph entries — authored tiles in group
  C's upper bank (`0x1FE40+`), pal row 0x19 (thunk-re-asserted every
  select frame), placed at screen (340,202) = OBJ (404,218). Measured on
  the live OBJ list and pixel-exact against the intended bitmap. The
  OBJ->screen transform on this screen is `(x-64, y-16)`; the transparent
  pen is 15; plane bit i is pixel 7-i within each 8-px half
  (`gfx_tiles` was mirrored until 14z-105 — docs/platform/gotchas.md).
- **Oboro is hand-pickable.** Bishamon's cell + Start held at confirm ->
  id 0x18, vanilla's Gallon-variant idiom at `PRG:0x020B9C` one cell over
  (`btst #7,$394(a6)` IS the Start test, measured). Profile-gated
  `oboro_select_hook`; gate `tests/test_oboro_select.sh`.

## Sound subsystem: the QSound command path (session 14z-51, measured)

Architecture (all measured live, both games):

- **68k side is id-only.** Game code queues `{id.l, d2.l, d3.l, pad}`
  16-byte entries into a ring at `RAM:$FF0E0E` (0x100 entries), write
  index word at `RAM:$FF1E0E` (enqueue routine PRG:0x31EA, a5=FF8000
  with negative displacements). A per-frame pump transmits pending ids
  to the sound board as 16-byte port packets (`0x618000-0x61801E`,
  id hi/lo at +0/+2; keepalive at 0x619FFC). No sample knowledge on
  the 68k side at all.
- **The sound driver is a Z80** (`vm3.01/02`, 256KB banked; vs2 twins
  `vs2.01/02`). Family-shared code head (identical to 0xD85), then
  per-game data. It drives the QSound chip via the classic triplet
  interface at Z80 `0xD800`→ no: **`0xD000/D001/D002`** (data hi, data
  lo, reg#).
- **QSound chip regs:** voice v params at reg v*8+k — k=1 start addr,
  2 pitch, 3 phase (0x8000 = KEY-ON marker), 4 loop, 5 end, 6 vol;
  **bank for voice v is written at reg ((v-1)&15)*8** (the +1 hardware
  quirk). Sample address = (bank&0x7F)<<16 | start, into the 8MB
  11m+12m image.
- **Instrument (promoted): tests/lua/qs_sweep.lua** — replay-driven
  venue + ring-poke id sweeps + chip-write log; parse with
  tools/qs_analyze.py (key-on extraction with last-known reg
  tracking). Sweeps run in TEST MODE (silent; ring index rests at
  0x70 in both games at f1050 on replay 06). 12-frame windows
  misattribute delayed-attack sfx — re-probe suspects with 45-frame
  spacing.

### The 14z-51 id-space result (docs/project/m5/keyons_*.json)

Sweeping ids 0x000-0x7FF on both games (2048 pokes each): 1613 vsavj /
1370 vs2 ids key voices. **For the shared sfx library the two games
use IDENTICAL ids** — vs2 0x136/0x137/0x13d/0x142/0x146/0x112/0x156/
0x157/0x158/0x15a/0x18b/0x18d/0x299/0x2d4 all exist on vsavj as the
SAME id keying the SAME sample content (relocated in the image;
content-verified). The session-5 "same-id means music in vsavj" theory
is dead — the 214P/214K music bug's real mechanism must be re-diagnosed
(suspect: the per-char dispatcher table indirection `(6,a0,d2.w)` or
corrupted id flow through the farm path) BEFORE unstubbing.
vs2-ONLY samples (absent from vsav's 8MB — Donovan voice/new sfx):
ids 0x71d, 0x73e, 0x753, 0x754, 0x755, 0x756 (+0x14a and 0x173 are
same-id-different-content — vsavj reuses those ids for other sounds).
0x747 keys nothing in either probe so far (needs params or longer
window). Sample ROMs are FULL (no blank 64K blocks) — porting voice
samples means growing the QSound region (descriptor change) or
sacrificing content; maintainer decision material.

### The per-node sfx dispatcher and per-char record arrays (14z-52)

The walker's per-node sound call (node +0x16 nonzero) runs a dispatcher
that is ported into our build at ~`PRG:0xCE3B8` (vanilla twin
`PRG:0x27F16`, vs2 `PRG:0x271B6`):

    moveq #0,d1 ; move.b $382(a6),d1 ; lsl.w #2,d1     ; char id * 4
    lea  $BF41A,a0 ; movea.l (a0,d1.w),a0              ; per-char array
    lsl.w #3,d0 ; move.w (a0,d0.w),d1                  ; d1 = sound id
    tst.b $BC(a5) ; beq +4 ; move.w (2,a0,d0.w),d1     ; alt id variant
    tst.w d1 ; beq skip                                ; **id 0 = SILENT**
    ... move.b (4/5,a0,d0.w),d2 ; move.w (6,a0,d0.w),d3 ; jsr helper

- Per-char pointer tables: vsavj `0xBF41A`, vs2 `0xD95B8` (**32 rows**,
  4-byte pointers, variant half 0x10-0x1F aliasing the base half —
  re-verified 14z-87, matches bank_map `tail_data_ptr` stride 0x80; the
  "20 rows" previously written here was wrong; row = char id — see the
  third pass below for when the row index is NOT the char id). Record
  entries are 8 bytes:
  `id.w, alt_id.w, p4.b, p5.b, d3.w`.
- **`id == 0` is the engine's own silence path** — the clean way to
  suppress a sound with no faithful equivalent (used by the
  `[[sound_table]]` allowlist).
- Array lengths are implicit (indexed, never bounded): vsavj Jedah's
  array runs ~40 entries, Donovan's vs2 array 44 (his scripts index up
  to 43 — measured). Porting a newcomer's array is therefore mandatory
  before enabling this path for a replaced slot: the vanilla slot's
  array is both wrong AND too short.
- Helper: vsavj `0x4CE2` / vs2 `0x5122` — `btst #0,$70(a6)` then
  `addi.w #$300,d1` (the +0x300 id alias seen in the sweep maps) and
  jumps into the enqueue path.

### Ring-level facts from the trap parity A/B (14z-85g, measured on
### replay 87 ours-vs-native, FULL ring tap)

- **Id 0x049A is PERIODIC AMBIENT**: ~144-frame cadence starting
  f2594 (pre-trap, both games; the enqueue PCs are the vanilla
  `PRG:0x31EA` routine at identical addresses in both engines). Its
  `+6` param word sits at 0x1200 baseline and rises to 0x1400/0x1500
  around action — the first live observation of a non-id entry field
  varying (level-ish semantics, not yet decoded). The 14z-82d
  "detonation id 0x049A" attribution was two cadence beats — RETRACTED.
- **The trap's real sfx (measured end-to-end 14z-85g):** the
  spawn-EJECT sound is per-node record node 10 (id 0x0739, dispatched
  on Phobos' anim context via the record path); the TIMER-DETONATION
  sound is NOT a record dispatch — it is **sound-farm stub vs2
  `0x4F2E`** (`jsr $330E; move.l #$73A,d1; bsr helper; jmp $3306`),
  jsr'd from the mine handler at `x068458+0x120`. vs2's engine
  carries a FARM of such one-id stubs around 0x4EE0-0x4F60. vsavj
  keys MUSIC-family content at the same 0x7xx ids — but 0x73A's
  SAMPLE CONTENT is byte-identical in vsav's own QSound image
  (0x6C0000), keyed as the 0x198/0x199 family [CORRECTED 14z-95,
  GitHub #93: identical for 20,480 of 20,481 bytes — the INCLUSIVE
  endpoint 0x6C5000, the byte packing law #3 says is PLAYED, differs
  between the two games' original sample ROMs (vsav 0xFF, vsav2
  0x00)]: the restoration is a
  synthesized vsavj twin stub playing 0x199 (kind=sound_stub recon
  row, huitzil-m9), no sample port needed. ~~0x739 has no vsavj
  equivalent~~ CORRECTED 14z-86: 0x739's sample content, sample
  record (#0x5C, bank 0x18 @0x18D800) AND note-table-1 entry 0x28
  all exist on vsavj — only the Z80 SONG (id row + song block) is
  missing; see "The QSound Z80 driver" below. CAUTION for future
  silencing calls: a 0x7xx id's FAITHFULNESS is a property of its
  sample CONTENT, not its number — content-search vsav's image
  before writing a stubbed_sound row.
- **Ours 0x010A vs native 0x010B** at the same event (~throw+40f):
  both shared-library single-voice sounds (same start/end, relocated
  banks), reached through a per-char engine row — the defense-rows
  family (tenant rides the vanilla vsavj row). Cosmetic, recorded in
  the audit header, not gated.

### The QSound Z80 driver: id table, songs, streams, sample records
### (14z-86 — reader-traced end to end on live vsavj, id 0x119, then
### confirmed static; RETRACTS most of the 14z-85d filed detail)

**THE FILE-MAPPING TRAP that poisoned 14z-85d (read this first).**
MAME loads `vm3.01` split: file 0x0000-0x7FFF at region 0, file
0x8000-0x1FFFF at region 0x10000 (`ROM_CONTINUE`), `vm3.02` at region
0x28000. The 14z-85d session assumed region==file+0 above 0x10000 and
derived "id table at FILE 0x11006, entry for 0x119 = `33 07 50 18`" —
bytes read from the WRONG file offset that happened to look plausible.
The tap-verified truth: **the driver's 24-bit logical addresses ARE
flat-file offsets** (vm3.01+vm3.02 concatenated, 0x40000 total). CPU
mapping: fixed region CPU<0x8000 == flat; banked window $8000-$BFFF
with bank b == flat `CPU + b*0x4000`. Bank register $D003 =
`((addr>>14)-2)|0x80`; the HARDWARE masks the bank to 4 bits (MAME
`qsound_banksw_w`: `data & 0x0f`, overflow → bank 0), so only the low
18 bits of an address reach ROM.

**The Z80 is NOT encrypted** (RETRACTS 14z-85d "KABUKI-encrypted").
Proven three ways: file bytes at PC 0x1E82 and 0x0271 equal the traced
instructions verbatim, and MAME's cps2 config maps AS_OPCODES only for
the 68k. KABUKI is the CPS1-QSound generation. Static disassembly of
the member works directly (`dasm <f>,<off>,<len>,1,:audiocpu` in the
MAME debugger — the device is the FIFTH param; fourth is a bool, and a
device in slot four fails silently). The "garbage" that suggested
encryption was the wrong-offset reads above.

**Fixed-ROM anchor block** (everything below derives from it):
`word($3B00)` → sound-bank header (vsavj 0x9000): `[id-mod word BE]
[2 config bytes]`, id table at header+6. `word($3B02)` → sample-record
table (vsavj 0x45FA, vs2 0x4798). `word($3B04)` → ARRAY of note-table
pointers (vsavj 0x3B12/0x3D02/0x3ED6/0x3F92) — $3B04 is pointer[0],
selected per track by stream cmd `1F n` (handler 0x17D5).

**Id table** (vsavj flat 0x9006, mod 0x6D8 ids; vs2 mod 0xA70): 4 B
per id = `[addr-hi][addr-mid][addr-lo][tail]`, a 24-bit BE flat-file
address of the song block. The consumer (0x0271) normalizes the ring
id MOD ($F010) — **the id space WRAPS: 0x739 ≡ row 0x61 on vsavj**
(the "0x700+ = music" boundary is a 68k-side convention only).
`addr-hi == 0` → the consumer RETURNS (0x02E1 `ld a,d / ret z` with Z
still set): **b0==0 rows are FREE / no-op ids** — and therefore a song
block below flat 0x10000 is UNREACHABLE from the table (that free run
in fixed ROM cannot hold songs). Ring id high byte 0xFF → system
commands (jump table 0x0992 indexed by id low). Census tool:
`tools/audit_qs_id_table.py` (derives every base from the anchors;
vsavj: 1512 live / 240 free rows incl. 0x58-0xDC and 0x3D8-0x3FF).

**Song block**: `[priority][16 slot words BE]`; slot word w≠0 → track
on that slot at song_base+w. Slot index == voice number (id 0x119:
slot 13 → the measured ch13 keyon). Track init (0x0431): priority
gate vs (ix+$40), zero 0x50-byte track state at $F200+slot*0x50, then
+0x01=bank byte, +0x02/03=folded CPU stream ptr, +0x40=priority,
+0x25=tick 1, +0x30/31=note-table ptr[0] default, +0x33=5.

**Stream grammar** (cmds <0x20 via handler chain; ≥0x20 = wait/dur
events; table @0x1126 is a DOUBLING-MASK table, RETRACTS "commands
≥0x20 via table @0x1126"): `09 n` tempo bits (ix+$04); `05 hi lo`
16-bit param → ix+$41/42 (or ($F020) when ($F004)≠0); `06 n`, `1F n`
note-table select (ptr array at $3B04); `08 n` — THE SAMPLE SELECT:
n&0x7F ×4 into the note table → `[sample# LE][→ix+$0D][instr#&0x7F]`;
`07 p` pitch (xlate 0x34F1); `19 v` volume (handler 0x15E1); `01 g v`
key-on; `03 n` long wait; `17 n` end-of-track.

**Instrument (envelope) rows**: `0x5A1A + instr*8` on vsavj (vs2
0x5BD8 — these two immediates at 0x0D85/0x129F are the ONLY code-region
diffs between the games' fixed ROMs; the interpreters are otherwise
byte-identical, which is the licence for verbatim stream copies). Five
row bytes are indices through xlate tables 0x36F1/0x3771/0x35F1 into
ix+$36..$3F.

**Sample records** (routine 0x1350): `base + sample#*8`, 8 B =
`[bank][start LE][loop LE][end LE][transpose→ix+$0C]`. Chip writes
through the $D007-busy-wait choke: reg v+2 ← 0, v+1 ← start, v+5 ←
end, v+4 ← **end−loop**, reg ((v-1)&15)*8 ← data hi 0x80 : lo BANK.
**The bank field is a full 8-bit byte → banks 0x80-0xFF (the WIDE
upper 8 MB) are natively expressible** — the 14z-85c "verify bank
field width" item, answered. (RETRACTS the "8-byte table @FILE
0x5219 / 0x119-shaped row at 0x55C9" candidate: 0x5219 is a
MISALIGNED mid-table phase of the real 0x45FA table — 8-byte-periodic
data pattern-matches at any offset; the reader (0x1350) decides.)
Tables are adjacent: vsavj samples 0x45FA-0x5A19 (644 records),
envelopes 0x5A1A-0x5E19; free zero runs 0x5C4F-0x9000 (unused
envelope tail + scratch — UNREACHABLE for songs, see b0==0 above) and
flat 0x3C977-0x40000 (banked, b0=0x03 — song-capable).

**The trap sounds, fully resolved static** (14z-86): vs2 id 0x73A
(detonation) = song @0x34365, slot 15, stream `... 1F 01, 08 23` →
note-table-1 entry 0x23 → sample record bank 0x6C start 0 end 0x5000
— byte-identical record AND content on vsavj (the m9 chirp, now
confirmed through the full chain). vs2 id 0x739 (ejection) = song
@0x34332 (0x33 bytes), slot 11, one note: `08 28, 07 5A, 19 1E, 03
B4, 17 30` → vs2 sample #0x9D (bank 0x25 @0x255800-0x257FFF) whose
0x2800 content bytes sit **byte-identical in vsav's image at
0x18D800 = vsavj's own record #0x5C = exactly what vsavj
note-table-1 entry 0x28 already points to.** The ejection port
therefore needs NO sample packing and NO table growth: one free id
row + vs2's 0x33-byte song block copied verbatim into the banked
free run. Envelope row 0 (both songs' instrument) is byte-identical
across the games.

### Z80 driver, second pass (14z-86, the voice batch) — dispatch table,
### note-table array semantics, the dead type-C song class, the alias bit

- **The real command dispatch**: the fetch loop at 0x1166 reads a
  byte; ≥0x20 RETURNS to the tick path (a WAIT/sustain event); <0x20
  dispatches via the pointer table at **0x1186** (32 × 2B). Operand counts (both games, byte-identical
  interpreters): 00-03 zero-op flag toggles (ix+$04 bits), 04/05 two
  ops, 06-11 one op, 12-15 zero (read track state not stream), **16 =
  16-bit signed STREAM JUMP** (loops), **17 = end-of-track, no
  operand** (the "17 30" reading of 14z-86 morning was the end marker
  plus the NEXT song's priority byte), 18 pan/level, 19 volume, 1A-1E
  one op (xlates 0x38F1/0x39F1/0x37F1 etc.), **1F = note-table select**.
- **cmd 1F indexes the pointer array at $3B04 with an UNBOUNDED byte**
  — vsavj has SEVEN slots (0x3B12…0x455A), **vs2 has EIGHT: slot 7 is
  its VOICE note table**, which is why every voice song runs `1F 07`
  and why vsavj cannot resolve them natively. No phantom index (7-255,
  the out-of-array reads land in table data) yields a pointer into
  authorable space — measured exhaustively. The port's answer:
  RELOCATE table 0 byte-identically (repoint the $3B04 word) and write
  the vacated word at the old table-0 base as the 8th slot pointer →
  an authored voice table in the fixed-ROM free run. Every consumer
  follows the moved pointer to identical bytes; no deadness proofs.
- **Note-table bases are 16-bit** (ix+$30/31; cmd-08 does base+op*4
  with one carry bit) — authored note tables must live below ~flat
  0x10000. Sample RECORDS are 16-bit-indexed from 0x45FA and
  bank-switched — high indices land in the post-envelope free zero run
  (0x5E22+), so authored records need NO table growth.
- **A third SONG CLASS exists and is DEAD CODE in both games** (zero
  of 3,000+ live songs use it): header byte0 = 0x80|voice → a FLAT
  11-byte one-shot format parsed at 0x0311: [80|voice][priority]
  [→ix+06][→ix+05][→ix+09][→ix+08][pitch via 0x34F1][sample# BE →
  ix+2F/2E][b9,b10 → ix+14/15 pitch base]. **Proven EXECUTABLE by
  authored probe** (14z-86: a hand-crafted row keyed the exact record
  with the same keyon tuple as the multi-track version). Kept as a
  capability reserve — the batch shipped verbatim multi songs instead.
  Related: the note-on resolver at 0x0D0A treats ix+$2F bit7 as a
  dual-mode switch (set = (table,entry) indirection, clear = RAW
  sample number).
- **The +0x300 id alias is the FACING bit** (`btst #0,$70(a6)` — the
  same helper idiom id_space.md documents as facing) and natively
  selects a per-facing TWIN SONG: measured over the 81 scoped voice
  pairs, 74 differ ONLY in the channel-slot word, 6 are identical, 1
  other — the alias is CHANNEL ALLOCATION, not sound content. The
  voice batch skips it for the authored range 0x58-0xA6 (a range-gated
  thunk clone of the helper at PRG:0x5FFF00) because only 38 free
  (base, base+0x300) row pairs exist against 79 voices; kept vanilla
  ids keep vanilla aliasing through the thunk's else-branch. Deviation
  surface: simultaneous same-voice triggers share a channel (restart)
  instead of layering on two.
- **Song extents**: songs are stored contiguously; a song's length =
  the gap to the next song start (sorted id-table addresses). Verified
  batch-wide: no track stream overruns its extent.
- The keyon-window disciplines: qs_sweep IDLIST mode takes STEP (the
  12-frame default is attack-window-blind), qs_analyze takes the
  window as its 3rd arg, and per-id window attribution is VENUE-FLAKY
  for delayed keyons — batch A/Bs compare WHOLE-RUN (voice, length,
  content) multisets instead (tools/check_qs_voice_batch.py; a
  signature ours-only whose content exists in vs2's library is a
  priority-suppressed track echo, measured moving with injection
  timing).

### The per-node sfx dispatch, second pass (14z-86) — RETRACTED 14z-87;
### superseded by "third pass: the VOICE-CLASS BORROW" directly below

[RETRACTED 14z-87 — kept for the eliminations; the conclusions are
superseded. What survives: the dispatcher head decode (`move.b
(0x382,a6),d1; lsl.w #2,d1; lea $BF41A,a0` @vsavj 0x27F16, vs2 twin
0x2716A), the per-game anim-node divergence (vsavj node 13 / vs2 node
28, anim bytes 0x0D@0x1FDF20 vs 0x1C@0x19D832), and the rig. What was
WRONG, each re-measured 14z-87: (1) "the dispatch reads class 0x0C on
both games / the class-0x0C arrays are byte-identical and 0x29B sits at
their node 28" — 0x29B lives at class row 0x07/0x17 node 28 in BOTH
games (exhaustive 32-row × 48-node scan), the 0x0C arrays are NOT
byte-identical over their extent, and the classes actually read were
run-varying (see below); (2) "who writes the class is unmeasured;
mirror-write suspected" — the writer is PRG:0x0AEF6, it fires ~536
frames BEFORE the watched window, and no RAM mirror exists (the MAME
cps2 map is one flat range); the "invisible write" was an artifact of
correlating a STATE-DEPENDENT value across different runs
(docs/platform/gotchas.md, 14z-87); (3) the row-0x1C fix design is dead
— the class is a dynamic borrow result, not a 0x0C constant.]

### The per-node sfx dispatch, third pass (14z-87) — THE VOICE-CLASS
### BORROW: (0x382,A6) is the fighter's voice-FLAVOR class

**Atlas rows this section depends on:** `atlas/ram.md` ($FF1E48 pool,
$FF8110 mask, fighter +0x382), `bank_map.toml` `tail_data_ptr`
(0x0BF41A).

- **The model:** table `0x0BF41A`'s 16 base rows are PER-CHARACTER
  voice arrays; the per-node sfx dispatcher (`0x27F16`) plays
  `row[(0x382,A6)][node]` — the NODE names an effect-sound slot, the
  CLASS picks whose FLAVOR voices it. The byte usually holds the char
  id, but the engine reassigns it.
- **The borrow (measured end-to-end, rig 90):** at a match-sequencer
  event (caller chain by history probe: state machine `PRG:0x0206DA`
  sub-state advance → `jsr $AE7C`; ~f3463 in the rig), the engine hands
  P1 a voice class: populator `PRG:0x0AF16` copies an 8-byte candidate
  list into pool `RAM:$FF1E48` (paired voice-number list from
  `0x00BB68` into `RAM:$FF1E50`) from ROM table **`0x00B268`**, row =
  `(0x382,A0)<<6` + venue byte `$121(A5)` — **A0 is the OPPONENT**
  after the entry exg dance (A5=$FF8000 here, so A0/A1 are the
  $FF8400/$FF8800 fighter blocks). The scan at `PRG:0x0AEDA` takes the
  first candidate whose bit in in-use mask `RAM:$FF8110` is clear and
  writes it to `(0x382,A1)` at **`PRG:0x0AEF6`**. Verified with
  independent redundancy: live pool bytes == ROM row 3 (Victor)
  venue-slot 3 on both games. There is a tagged path too
  (`tst.b $3bc(a0)` → row `0x800 + $3bd(a0)*8` — engine-tag rows after
  the 32 char rows), and a `$AC(a5)==3` path that picks a voice number
  by RNG — not yet needed for any port question.
- **The candidate rows are ROSTER-AUTHORED:** vs2's Victor row is
  `{13,00,0C,08,01,11,0F,18}` — Donovan's class first — so native
  Donovan-vs-Victor keeps HIS OWN voice row for engine-voice events
  (measured borrow = 0x13). vsavj's Victor row is
  `{06,0C,01,08,07,02,0F,18}`: vanilla classes only, so a tenant P1
  gets a vanilla flavor — the sword-plant "ding" is
  `row[borrowed][13]` (node 13 per vsavj's engine anim). Rows
  0x10-0x1F of both tables alias 0x00-0x0F (row 0x13 == row 0x03,
  verified) — the tenant rows are unported.
- **The borrow result is a LOTTERY:** the in-use mask is
  sound-state-fed; identical-input runs measured borrows
  0x06/0x0C/0x09/0x00 (MAME) and 0x04 (FBNeo) — the QSound-latch
  one-frame phase (the standing masked non-determinism) flips it. So
  the ding's exact id varies per run/venue; 14z-86's
  ours{0x62B,0x308} / native{0x29B} ring signature reproduces
  canonically but is one outcome, not a constant (0x308 = row0C[13];
  0x29B = row07[28]).
- **Fix status: SHIPPED 14z-87 (maintainer-decided option b+c,
  2026-08-15).** (b) the tenant-keeps-own-class thunk at the borrow
  write (`voice_borrow_keep_tenant` site_thunk @0x0AEF2 + site-pad
  code_word @0x0AEF8, all three manifests, deduped): when `(0x382,a1)`'s
  pre-value is 0x10/0x11/0x13 the borrow write is skipped
  (skip-write-only — the scan and its $FF8114/$FF8100 side effects run
  unchanged); tenants keep their own class and their engine-voice
  events play their AUTHORED voice rows. [CORRECTED 14z-87b: the
  "plant-end fires authored 0x6A" measurement came from rig 90, which
  NEVER FORMED A MATCH (no joins/confirms — the captures observed a
  timed-out CPU game; gotcha filed). On the REAL plant (rig 91, match
  verified by snapshots + ring) the plant fires authored voices
  0x5D/0x62 (vs2 0x705/0x70A). The borrow-mechanism findings stand —
  they were measured on a real (if unintended) running match.] (c) vs2's candidate/voice-number rows 0x10/0x11/0x13
  ported over the variant aliases (per-tenant [[data_port]] rows).
  All only_variant_slot-gated; the stock twin measured BIT-IDENTICAL.
  Cost measured: ~60 cycles on an event firing 0-1×/match (0 hits in
  8000 frames of replay 03); the visible footprint on tenant-content
  .sha1 logs is the hook-cycle dead-stack class (3 bytes in
  $FF7F00-$FF7FFF at the event frame, live state identical) plus the
  intended voice-content changes; legacy masked classes held with NO
  flicker-inventory movement. Gate: `tests/audit_voice_borrow.sh`
  (own-class default; lottery mode = the ground-truth-failing pair vs
  build/don_m4).

### The KERNEL per-class voice tables (14z-96) — a SECOND voice family,
### in the sound kernel itself, NOT the 0x0BF41A record path

**Atlas rows this section depends on:** `atlas/ram.md` fighter +0x382
(the voice-flavor class), `atlas/id_space.md` (the fold-site table —
this family is the id_space "rows 0x10-0x1F are copies" shape, not an
`andi` fold).

Distinct from BOTH per-node record dispatch (0x0BF41A) and the voice
borrow: the sound KERNEL (the low-PRG region around the enqueue
`0x31EE` / save-restore `$330E/$3306` / helper `$4CE2`) carries **four
per-class voice-id word tables**, one per voice EVENT, each as a
16-entry base table + a 16-entry VARIANT table directly after it
(reads go through the OPCODE view — the tables sit inside the crypt
window and the data view shows ciphertext at the same offsets):

| event | vsavj base | vsavj variant rows (0x10-0x1F) | vs2 twin |
|---|---|---|---|
| .0 | `PRG:0x3BCE` | `PRG:0x3BEE` | `PRG:0x3C04`/`0x3C24` |
| .1 | `PRG:0x3C3A` | `PRG:0x3C5A` | `PRG:0x3C70`/`0x3C90` |
| .2 | `PRG:0x3CA6` | `PRG:0x3CC6` | `PRG:0x3CDC`/`0x3CFC` |
| .3 | `PRG:0x3D10` | `PRG:0x3D30` | `PRG:0x3D46`/`0x3D66` |

The event suffix is literal: every entry of event .N ends in nibble N
(class 0's row is `0x1d0/0x1d1/0x1d2/0x1d3`), so an id names
(character, event) in one word. **On vsavj the variant half is a
byte-identical COPY of the base half; on vs2 it carries the
newcomers' real voices** — Phobos `0x730/0x2a1/0x2a2/0x733`, Pyron
`0x720/0x2a1/0x2a2/0x723`, Donovan `0x700/0x701/0x702/0x703` (rows
0x12 keep the copy). **`0x2a1`/`0x2a2` are FREE rows in the Z80 id
table of BOTH games** — Capcom voices the robot's hurt events with a
deliberately silent id.

Measured mechanism (x4 electrocute rig, replay 95): the .2 event
fires on EVERY OTHER electrocution (engine-side alternation, both
games); the fired id follows the victim's +0x382 class through the
variant table — poking class 0x01 moved the fired id `0x1d2 → 0x202`
(= row 0x01), which is what pins "table row" over any arithmetic
reading. A tenant class therefore fires the row-copy alias — the
LEGACY character's voice (class 0x10 → row 0x00 = Bulleta) — which is
the merged-m2 "grunt after the electrocution, every other time"
defect. The M5 voice batch never touched this family: it ported the
0x0BF41A per-node RECORD arrays; these kernel tables were a separate
consumer no manifest row named until the 14z-96 port (GitHub #101, the
`*_kernel_voice_e*` rows + the qs_voice_map "kernel voice pairs" table).

Three more measured facts about the family (14z-96):
- **The dispatch calls the REAL helper `0x4CE2`** (`bsr` at each event
  site), so the `+0x300` facing alias applies on this path — the
  batch's alias-skip thunk covers only unstubbed call sites. Native
  accordingly backs every newcomer kernel voice with a `+0x300` twin
  song (`0x700→0xA00` etc.); the port mirrors that with authored
  (base, alias) pairs.
- **The firing PATTERN is engine-side and victim-data-fed**: each event
  site gates on `btst #0,d0` before the table read, and the phase
  differs across victims and across the two games (vsavj fires a
  Donovan victim's .2 event at attempts 2+4 of 5 where native vs2
  fires none; ours-Phobos fires attempt 2 only where native-Phobos
  fires 2+4). Measured identical PRE- and POST-port on our side —
  the port changes voice IDENTITY only, at the exact same frames.
- **Silence can be the authored sound**: vs2 voices Phobos' hurt
  events with `0x2a1/0x2a2` — free Z80 id rows (null songs), with
  free `+0x300` aliases (`0x5a1/0x5a2`), in BOTH games' tables.

## The sprite-list DRAWER: how an object becomes sprite entries
## (measured 14z-71 on the Huitzil beam; the layer ABOVE the OBJ entry)

**Atlas rows this section depends on:** `atlas/sprite_lists.md` (the
drawer, the handler table, all list formats, the per-game bias table),
`atlas/ram.md` (object fields `+0x02` class, `+0x04` effect type, `+0x0B`
facing, `+0x0F` palette, `+0x18`/`+0x1A` OBJ word bits, `+0x1C` anim node,
`+0x30` owner), `atlas/character_tables.md` (the per-char OBJ bank table).

The section below it describes the OBJ *entry* the hardware reads. This one
describes the machinery that PRODUCES those entries — the layer where every
"the effect does not draw" bug in this project has actually lived.

### The chain, end to end

```
pool walker
  -> object CLASS byte +0x02  ->  x4  ->  38-row handler table  ->  jsr
       (vsavj 0x080A90 / table 0x080AAC; one such pair per object pool)
  -> the class handler reads the effect TYPE byte +0x04 and dispatches again
  -> some state machine sets the object's ANIM NODE at +0x1C
  -> the DRAWER (vsavj 0x01AFA6) reads node +0x04 -> the SPRITE LIST
  -> the list's TYPE word selects a handler (table 0x01AFBA)
  -> the handler writes 8-byte entries through A2 into OBJ RAM
```

Four dispatches, each indexed by a different byte, each with its own table.
When an effect does not draw, the question is always *which* of them
stopped — and the answer has never once been the draw path itself.

### The three failure modes, all paid for

**1. A dead table ROW.** vsav ships rows 16/17/19/31 of the effect-class
table as stubs pointing at the bare `rts` after the table, where vs2/vh2
carry real handlers. Huitzil's beam object set class 16 correctly, at the
same frames as native, and loaded the stub. Nothing upstream was wrong;
the effect simply had nowhere to go. (14z-71. The same shape as the
`obj_hook` type-dispatch work — a table the host built smaller.)

**2. A missing list TYPE.** vsav's drawer has six list types, vs2 seven,
and the table cannot grow or move (see the atlas — entry 0's offset IS the
length). Type 12, the composite, does not exist in vsav at all, so a
ported list of that type jumps off the end of the table into data.

**3. A game-specific CONSTANT inside an otherwise identical handler.**
Types 4, 6 and 8 bias every emitted tile code — vsav by `+0x3800`, vs2 by
`+0x4200`. One byte. Ported vs2 list data run through vsav's handler
addresses tiles 0x0A00 low and draws whatever is there. On the beam that
was the freeze/reflection art, and the maintainer identified it from a
screenshot faster than the analysis did.

**Mode 3 is the dangerous one** because the routines look the same. A diff
saying "255/256 bytes identical" invites the conclusion that the one
difference is a relocated address. Here it was the entire defect, and
dismissing it cost most of a session.

### Where the BANK comes from — and why it differs per list type

The gfx bank lives in the OBJ y-word (bits 13-14, plus WIDE's bit 12). Two
handlers source it two different ways, and this decides whether a
tenant's art can be relocated at all:

| list type | bank source | relocatable by the record path? |
|---|---|---|
| 0, 2, 8 | the OBJECT's `+0x18` (per-char OBJ bank table) | **yes** |
| 4 | **hardcoded** `ori.w #$2000` = bank 1 | **no** — needs a ported handler |

So a character's effects can legitimately draw from **more than one gfx
bank**: Huitzil's beam takes its muzzle and tip from his own band (bank 3)
and its stretching middle from bank 1. Any port that assumes a character's
art is one contiguous band will silently mis-address the type-4 pieces.

This is the same family as the **sword/statue blink** (see "known class"
below and `gotchas.md`): there, records belonging to two different banks
were processed with one bank's semantics, and the frames that landed in
the wrong bank went invisible at the animation rate. Same root — **bank
attribution is per-record, and per-list-type, not per-character.**

### How to attribute one of these in one run

Do not reason about it. Anchor on what the effect must READ (the ANCHOR
METHOD section below), and if the question is specifically "why is the art
wrong rather than absent", dump the OBJ records on both legs and compare
`code`, `pal` and the y-word BANK BITS over a WINDOW, never per frame — the
legs drift in phase. `tests/lua/obj_records_dump.lua` prints all three, plus
the composed tile address under both the stock and WIDE addressing rules.

Two instrument rules that this subsystem enforces harder than most:

- every one of these tables is read PC-relatively, so a watchpoint must use
  the **opcodes** space (`wposet`) or it reports zero and reads as "never
  used" (`../platform/gotchas.md`);
- `obj_records_dump` reports a multi-tile sprite's BASE code only — expand
  `w×h` with the row-wrap rule before concluding anything about tiles.

### What a port has to supply

The project-side consequences — bank sourcing, the bias, tile inventories
as SPANS, and the group-C placement shift — are
`../project/porting_sprite_lists.md`, with Huitzil's beam as the worked
instance.

### OBJ sprite-list structure (measured 14z-53, WIDE Phase A)

The CPS-2 sprite list is 8-byte entries `(x.w, y.w, code.w, attr.w)`, up
to 0x400 of them, in one of two buffers 0x8000 apart (FBNeo selects with
`CpsRam708 + ((nCpsObjectBank ^ 1) << 15)`). Two terminators end the walk:

- **y-word bit 15 set** — end of list (`CpsObjGet`);
- **attr >= 0xFF00** — end of list (the "ringdest" case).

Anything after either terminator is stale data that is never drawn; a
census that ignores this over-counts badly (GOTCHAS).

y-word bit layout as used by vanilla vsav (measured, full legacy corpus):

| Bits | Meaning | Vanilla usage |
|---|---|---|
| 0-9 | Y position (10-bit signed) | live |
| 13-14 | tile-address bits 16-17 (the gfx bank) | live: banks 0-3 |
| 15 | **list terminator** | live (as terminator) |
| 8-12 | unused by vsav | **bit 12 free** — the WIDE 19th address bit |

The 19-bit rule (CPS-2 Turbo precedent, adopted by WIDE): promote bit 12
into bit 15 for address composition only, after the terminator check —
`if (y & 0x1000) y |= 0x8000; n |= (y & 0xE000) << 3`. Since the bank
bits are supplied from data (per-char OBJ bank table `PRG:0x282D4` and a
few `move.w #$X000` setters), reaching banks 4-7 may require no game-side
code change at all.

### Per-char OBJ bank table (PRG:0x282D4) — measured 14z-56

0x18 word rows indexed by character id, read through the **opcode
(decrypted)** view — a pc-relative access, so it lives in
`vsavj_opcodes.bin`, not the data view (the standing pc-relative/data-space
rule). Values are the OBJ y-word bank bits: `0x0000/0x2000/0x4000/0x6000`
= tile-address bits 16-17, i.e. which 8MB gfx bank the character's sprites
are fetched from. Vanilla vsavj rows (char 00..17):

    6000 6000 0000 2000 6000 0000 4000 4000 0000 6000 4000 6000
    6000 0000 0000 4000 6000 6000 0000 2000 6000 0000 4000 4000

Slot 0x0F reads `0x4000` (bank 2) — the value the Donovan gfx build
asserts after porting.

**It is not display-only.** Changing a row alters game state as well as
tile fetch: a build with 15 rows remapped diverges in work RAM at frame
890 under MAME, which has no extended-bank support at all (14z-56
measurement, GOTCHAS). Treat the row as behaviour-bearing.


## The CPU AI action-script system (14z-111, measured on the #99 capture)

**Atlas rows this section depends on:** `ram.md` fighter `+0x205` (script
index), `+0x210/+0x214/+0x218/+0x21C` (channel cursors; `+0x224` mirrors
channel 0's start), `+0x241` (current command byte), `+0x242/+0x244/+0x246`
(the three stream words each command pulls), `+0x382` (class);
`character_tables.md` `ai_script_0..3` (`PRG:0xBF01A/09A/11A/19A`).

- **Tables.** Four per-class tables of script-start pointers, 32 longs each:
  entries 0-15 = the 16 classes, **entries 16-31 = the same 16 repeated**
  (Capcom's aliasing guard for ids with bit 4 set — Oboro Bishamon 0x18
  legitimately aliases Bishamon 0x08). Consumers: `0x2CCB6` (table 0,
  indexed by `+0x205`, writes `+0x210` and `+0x224`), `0x2CCF2` / `0x2CD40` /
  `0x2CD9C` (tables 1-3: `+0x382<<2` row, then `jsr 0x14E8A` (RNG) `andi #$1F`
  `+ (0x20A,a6)` picks one of 32 starts inside the row's block; write
  `+0x214/+0x218/+0x21C`). CPU-side only (14z-98 trace); 2P never reads them.
- **Scripts.** Word-offset streams (position-independent): the start block
  is a table of word offsets to the actual script; each command pulls three
  words into `+0x242/+0x244/+0x246`, the command byte lands in `+0x241`.
- **Interpreter.** `0x2B96A`-`0x2C7D0`: 15 nested `move.b (0x241,a6),d0;
  move.w (6,pc,d0.w),d1; jmp (2,pc,d1.w)` dispatchers. vs2's twin
  (`0x2B144`-`0x2BFAA`) is structurally identical (same table count and
  entry counts); the bodies differ in absolute operands plus one guard
  (table 1 command 17). The **jump command** (`0x2BD72` / vs2 `0x2B54E`,
  byte-identical) writes `move.l #$0200060E,(4,a6)`: class 02, seq 6, sub-
  state 0x0E — vsavj's generic jump handler (`0x22A24`, 10 sub-states) takes
  it; **Phobos's private vs2 jump handler (`0x2592A`, 5 sub-states) does not**,
  and vs2's own Phobos scripts never issue it.
- **The #99 crash (RESOLVED 14z-111):** a tenant class read the aliased row
  (Phobos 0x10 -> Demitri's scripts), Demitri's jump command reached Phobos's
  5-entry table at index 7, the displacement read from code landed in
  `x05c800` data, line-F at `PRG:0x422BAC`. CPU-only, Phobos-only (the only
  tenant with a private jump handler), time-dependent (the RNG must pick the
  script). The port now provisions rows 0x10/0x11/0x13 in the alias half
  from vs2's own tables (`0xD91B8/238/2B8/338` by bank-origin arithmetic).

## The class-02 sequence system, per-char jump handlers, and the air
## system (session 14z-66, measured on the Huitzil port)

- **Class-02 seq dispatch:** the per-frame stepper (vsavj 0x225C4 /
  vs2 0x20FA8) dispatches on the seq byte +0x06 via a word table
  (vsavj 0x225EE / vs2 0x20FD2 — first four entries identical across
  the generations, drift after). Seq 06 = the jump.
- **Per-char jump handlers:** the jump handler HEAD routes BY CHAR ID
  — vsavj 0x22A0E: `cmpi #6 -> 0x2678C` (Anakaris's private family,
  including a byte-identical COPY of the generic head at 0x26A58 — the
  content-twin trap); vs2 0x213F2 adds `cmpi #$10 -> 0x2592A` (PHOBOS's
  own handler: five sub-states — 0 = rise/conversion, 1 = the
  flavor-forked FLOAT, 3 = the +0x23-gated air action, 4 = the jump
  restart). The port clones 0x2592A whole (region x02592a) and
  reproduces vs2's id routing with a thunk at the vsavj head.
- **The float:** licensed by anim-node header bit 7 (+0x21), converts
  sub-state +2, arms +0x1C0 = 0x78, and forks on the flavor byte
  +0x3C2 in its FIRST instruction — flavor 0 (VS2 default): falling-
  only, min height 0x40, EXACTLY straight up, timer-limited; flavor 1
  (VH2): any-up pins the hover indefinitely. During the hover the
  mover is not called at all.
- **Jump physics:** per-char rows at the jump_params table (see the
  RAM atlas addendum) installed by the routine every seq-0600 starter
  calls. Air/ground dash physics are NOT table rows — they live in the
  character's own handler code (H: ground dash xv 6.0 at his 0x56DEA,
  air dash at his 0x586F0 family; seq 0x14 = the air dash).
- **Shadow/reflection servants:** each player gets a class-0x0C trio
  (spawner 0x489DE) that MIRRORS a linked object's animation by
  reading each anim node's +0xC word (low 13 bits = a seq into the
  SHARED shadow tables 0x2083BC/0x2087CA — NOT per-char; row space
  0x40E). Capture supers make the VICTIM play attacker-supplied nodes,
  so out-of-range shadow seqs surface on the victim's servant (the
  shadow_seq_guard clamp).
- **Capture-pose system:** capture supers select the victim's held
  pose via per-VICTIM tables (0xBCE7A family) indexed by a seq id from
  the ATTACKER's code — H's FG draws it RANDOMLY (table16[rand&15],
  ids 1/3/5) per barrage hit. The intro-variant at +0x0A is likewise
  RNG-drawn at char load.
  - **DURING-HOLD victim placement — a per-ATTACKER keyframe block
    (14z-73, FIXED).** The victim's per-frame position during a grab is
    written by a shared engine CAPTURE POSITIONER (vsavj `0x28058`):
    `victim_pos = attacker_pos ± facing-flipped (Xoff,Yoff)`, where the
    offsets come from a per-ATTACKER KEYFRAME block selected through
    pointer table `0xBE27A` indexed by the attacker's char id
    (`movea.l #$be27a,a0; movea.l (a0,id*4),a0`; the victim-side per-record
    offset is then added, indexed by the VICTIM id). This is DISTINCT from
    the victim-side pose tables (`0xBCE7A` family, ported wholesale) and
    from the post-release throw ARC (`throw_arc_tables`, the vertical
    launch). The table is 32 rows; rows 0x10-0x1F alias 0x00-0x0F, so a
    ported tenant at a variant id inherits a VANILLA character's block
    unless its own row is repointed — exactly Donovan's
    `throw_victim_keyframes` (`donovan.toml:711`) and Huitzil's
    `grab_hold_keyframes` (`huitzil.toml`, 14z-73). Measured (Circuit
    Scrapper 63214, `tests/test_hui_grab_victim.sh`): before the fix H's
    row 0x10 aliased character 0's block, holding the victim −27px behind
    vs native +74 in front; after porting H's own vs2 block `0x0C56AA` the
    victim tracks native's exact keyframe sequence. **A ported tenant's
    per-attacker `slot_ptr_table` rows are a REQUIRED port item — check
    them for every new grappler/thrower.** NOTE for measurement: compare
    `dx = p2x − p1x` (relative), never absolute victim-x — the ~21px
    cross-emulator camera shift cancels only in the relative measure (an
    absolute-x comparison stalled 14z-72 for a session). And a ported
    tenant reaches this positioner through a CLONE of it (H's is `0xc9eb0`,
    because `0x27282` fell inside region x026142), not the vanilla copy at
    `0x2802e` — breakpoint the tenant's clone, not the engine twin.

## Select-portrait palette dispatch + HUD stager biases (14z-67,
## measured on the H gfx rung)

vs2's select-portrait palette uploader (compare chain at vs2 0x6B1A6,
the twin of vsavj's 0x5F146 window) special-cases the newcomers THREE
DIFFERENT WAYS — the per-tenant fact that decides each port's
mechanism:
- id 0x10 Huitzil: `moveq #$B,d6` — remapped INTO the shared grid at
  column 0x0B (grid base 0x3C117C, row = (variant*16+id)*0x20). His
  10 variant rows are STRIDED (0x3C12DC + v*0x200) — ported via the
  data_subst gather form.
- id 0x11 Pyron: `addi.w #$BC,d0` — a dedicated row block past the
  grid (contiguous; ports like Donovan's).
- id 0x13 Donovan: `addi.w #$C6,d0` — his dedicated block (0x3C2A3C).

HUD per-char tables (both DATA-view, both 32-row aliased): the staged
OBJ code = table entry + the game's STAGER BIAS — vsavj +0x3800, vs2
+0x4200. vs2 entries row 0x10 (H): name 04AB 0102 FFE8 0002 (2x1
plate), mug 05A0 (2x2). The HUD index field is populated by the REAL
pick flow only — forced-pick pokes load the character but leave the
HUD reading the alias row (GOTCHAS).

## The per-char effect system (14z-67, decoded on the H ping rounds)

Three coupled mechanisms drive character effects (beams, grab
lightning, explosions):

1. **The seq-D per-char driver.** The class-02 stepper's jump-table
   entry 0xD (vs2 head 0x22008) is a PER-CHAR JMP DISPATCH:
   `move.b $382(a6),d0; lsl #2; movea.l #$D9538,a0; jmp ([a0+d0])`.
   Table 0xD9538 rows 0x0F-0x13 point at the newcomers' own drivers
   (H row 0x10 -> 0x56D68 in his code region). vsavj's seq-D
   (0x22500) has NO dispatch — a straight vanilla handler. Seq D is
   a COMMON state (fires every frame for every fighter), so gating
   it per-char requires the target flow's full dependency closure.
2. **The effect-object machine.** Effect objects ($FFBxxx pool,
   0x80 stride: +0x54 effect id, +0x56 sub-id, +0x30 owner link,
   +0x1C record chain) run a state machine whose entry stub maps
   id -> handler index via a BYTE MAP (vj DATA 0x28D00 / vs2
   0x27FD8; identical through id 0x4A, vs2 adds ids 0x4E-0x53) and
   installs records via three per-char record-table entries (movea
   heads: vj 0x27EB4/BC/C4 reading 0xBCE7A/EFA/F7A rows — the
   bank_map anim_index family). BOTH games carry TWO copies of the
   machine stub (content-twin hazard); vsavj's copies serve LEGACY
   effects — any thunk there costs legacy cycles.
3. **The fleet spawner** (vs2 0x6D282 family, in 0x6D240+0x500;
   vh2 twin +0x174): repeated 0x15702 allocations build multi-piece
   effects (lightning bolts, beam segments); headers 0x01000800,
   subtypes 0x25/0x26, +0x18 bank word deliberately 0 until each
   subtype's first tick. Reached by tail-jmps from four zone
   segments.

Related physics: the throw-arc installer (vj 0x28386 / vs2 0x275E4,
unique tail twins) writes victim +0x40 xv / +0x44 yv / +0x48 xacc /
+0x4C gravity (16.16) from 16-byte rows selected by
map1[2*(+0x5A) + d0]; vs2's map1 exceeds vsavj's by five entries
(rows 0x32-0x36 — the newcomer throw arcs, incl. the 63214
off-screen launches yv 16.0/20.0). Ported via the throw_arc_tables
superset-table thunk (statically proven identical for all shared
indexes).

## The WIN SCREEN subsystem (measured on Donovan 14z-45, re-measured
## and corrected on Huitzil 14z-68m)

**Read this before touching any tenant's win screen.** Donovan's win
screen was fully solved in 14z-45; Huitzil's was then re-derived from
scratch in 14z-68 and got TWO of three pieces wrong, because the prior
analysis lived only in a session log. Everything a tenant needs is
below, with both characters as worked instances.

**WHICH FLOWS REACH IT (measured 14z-99, corrected by the maintainer the
same session):** the screen shows after match wins in BOTH 1P-vs-COM
(corner: PRESS START) and 2P (corner: the loser's CONTINUE countdown).
An earlier same-session reading — "a 2P-flow surface; 1P never shows it;
a legacy 2P winner skips it" — is RETRACTED: it came from two rig traps,
(a) coarse post-KO sampling landing on the MAP/tally screens that come
AFTER the win screen, and (b) mash inputs running past the KO pressing
through it (game gotchas, 14z-99). Rigs for this screen must end their
inputs at the KO and sample densely between the settle and the map.
**KNOWN-OPEN ON IT (GitHub #105):** with AUTO (= auto-guard, a handicap
mode — the human still plays) selected by the WINNER, a TENANT winner's
portrait renders WHITE on the merged build: the `0x90C2A0` win-pal
window holds all-0xFFFF during the screen and the real colors arrive
AFTER it — the upload is LATE, not absent. Vanilla renders its AUTO
winner colored (not the engine's own behavior). Locked by
`tests/audit_win_pal_auto.sh` + `replays/103_tenant_2pwin_auto.rpl`.

The victory screen draws from THREE independent per-winner tables, all
indexed by the winner's char id from `+0x382(a4)`, all UNMASKED (so a
variant id 0x10-0x1F reads its own row — which in vanilla vsavj is a
plain ALIAS of the base row, hence "the tenant gets the host's X"):

### 1. Portrait POSITION — table `0x5F200`, 4 bytes/char (x at +0, y at +2)
Read at vsavj `0x5F1A0/0x5F1A6` (`move.w 0x5F200(pc,d0.w),$10(a6)`
with `d0 = id<<2`). vs2's twin table is `0x6B210`.
**This table is pc-relative PROGRAM space, so its rows are CODE words**
— patch with `[[code_word]]`, never `data_port` (the 14z-43 gotcha).
The manifest mechanism is slot-following: `slot_table`, `slot_stride=4`,
`slot_off` 0 or 2, `slot_mirror`.
| tenant | vsavj row (alias) | vs2 row (correct) | symptom if unfixed |
|---|---|---|---|
| Donovan 0x0F->0x13 | (0x0070,0x0080) | (0x00F0,0x0098) | portrait offset |
| Huitzil 0x10 | (0x0080,0x0098) | (0x00C0,0x0080) | 64px too far LEFT, 24px too low |

### 2. PALETTE — pool + a per-char REMAP TABLE
Base loaded at vsavj `0x5F1B6` (`movea.l #$3AD700,a0`), then
`offset = (colour*17 + id) * 0xA0`, 5 rows of 0x20 uploaded to palette
RAM rows **0x15-0x19** by the uploader `0x1C3A4` (d7=4).
vs2's twin drawer is **`0x6B29C`** (pool **`0x3C2BBC`**) and differs in
two ways: an 18-row stride, and it remaps the id through a BYTE TABLE
at **`0x6B2F2`** first — `offset = (colour*18 + table[id]) * 0xA0`.
- **THE VIEW RULE (this is what I got wrong):** that byte table reads
  through the **OPCODE view**. Its DATA view decodes to plausible
  garbage. Do not reason about which view from the addressing mode —
  **verify against a known-good row**: Donovan's frozen `vs2_src`
  0x3C365C == pool + 0x11*0xA0, and opcode-view `table[0x13] = 0x11`.
  That single check settles the view for every tenant.
- **THE MARKER SELF-CHECK (use it every time):** the LAST WORD of each
  0x20-byte palette row is a marker equal to **5*row**. Huitzil's rows
  carry 0x37-0x3B (5*0x0B); Donovan's carry 0x55-0x59 (5*0x11). If the
  block you are about to declare does not carry the marker for the row
  you think you picked, you have the wrong block. In 14z-68 I shipped
  a block whose markers said "Donovan" — it was labelled all along.
| tenant | opcode `table[id]` | vs2_src = pool + row*0xA0 | colour stride |
|---|---|---|---|
| Donovan 0x13 | 0x11 | 0x3C365C | 0xB40 (18*0xA0) |
| Huitzil 0x10 | 0x0B | 0x3C329C | 0xB40 |
Mechanism: `[[win_pal_variant]]` — the SPARSE BLOCK design (a wide_ext
block laid out with the VANILLA 0xAA0 stride carrying only the tenant's
8 sets, plus a thunk that rebases `a0 = block - id*0xA0` when
`d6 == tenant`, so the vanilla arithmetic lands on the tenant's set).

### 3. Win screen — PORTRAIT and QUOTE are DIFFERENT mechanisms (14z-73,
### measured in-emulator; the earlier 14z-68 account was wrong on both)
The shared fetch helper vsavj `0x5F328`: `movea.l #$2672AA,a0;
andi.w #$ff,d0; lsl.w #2,d0; lea -4(a0,d0.w),a0; move.l a0,$1c(a6)` —
it stores the *slot address* as the anim ptr (+0x1C); the anim
interpreter then reads the record from it.

**RETRACTED (14z-73): `d0` is `0x40 + WINNER id`, not `0x60+id`.**
Breakpointing `0x5F328` at the actual win screen (replay 28 + forced
pick) measured `d0 = 0x50` for a Huitzil (id 0x10) win — so the slot is
`0x2672AA + 4*(0x40+id) - 4`; for id 0x10 that is `0x2673E6`. The
14z-68/NEXT_SESSION `0x60+id` (index `0x6F`, slot `0x267466`) was wrong;
repointing it changes nothing (measured — hui27 did exactly that and the
screen was unchanged). There is no separate P2 slot in evidence — the id
is the WINNER's, and the arcade win screen (the one with the CONTINUE
counter) always has a P1 winner.

**The PORTRAIT already WORKS and is a DIFFERENT array from the quote.**
The `[[select_records]]` entry misnamed `win_quote` in `huitzil.toml`
ports Huitzil's victory PORTRAIT correctly (renders since hui16,
maintainer-confirmed hui26): it reads array `0x2A06E2` (index id, NO `-4`
bias) and pokes vsavj `0x2673ea` <- the placed vs2 `0x2A881E` = Huitzil's
portrait record (tiles bank-1 `0xb7xx`, pal 15-19). Its tiles ARE placed.
Do NOT touch it — a 14z-73 attempt to repurpose it for the quote stopped
poking `0x2673ea` and BROKE the portrait (self-inflicted "placeholder"),
reverted. The `d0=0x50 -> 0x2673E6` fetch measured at `0x5F328` was some
OTHER piece; poking `0x2673E6` changed neither portrait nor quote, so it
is not the lever for either.

### The WIN-QUOTE TEXT SYSTEM — fully decoded (14z-76)

Three sessions attempted this by repointing per-character POINTER arrays.
None of them could ever have worked: **the quote system contains no absolute
pointers to repoint.** It is a 2D winner-x-loser lookup built entirely from
16-bit relative offsets and pc-relative byte tables.

**1. What the quote actually is.** The **pal-0** objects — 32 of them, two
lines of 16 chars at y=176/192, font tiles ~`0x3EE5-0x427F`, `0x3820` = space
(short lines are space-padded). The 44 **pal-09** objects on the same screen
are static furniture and are NOT the quote; proved by forcing the winner to
two different ids on one rig — portrait palettes differ, pal-09 is
byte-identical, pal-0 differs.

**2. The two indices** (`PRG:0x0098BC`):

```
move.w a0,$13a(a5) / move.b $382(a0),d0 / bsr 0x9996 / move.b d0,$158(a5)  ; WINNER
move.w a1,$13c(a5) / move.b $382(a1),d0 / bsr 0x9996 / move.b d0,$159(a5)  ; LOSER
```

The mapper `0x9996` is **pass-through** but for two special cases
(`0x0B -> 0x04`, `0x1B -> 0x14`, the Shadow/Marionette slots). **It does NOT
fold to 4 bits** — measured: a verified tenant win writes `$158 = 0x13`.

**3. The selector** (`PRG:0x00C87C-0x00C8C8`) installs the text pointer:

```
move.b  $93(a5),d0 / movea.l #$112BC,a1 / movea.l (a1,d0.w),a1  ; text bank
move.b  $158(a5),d0 / add.w d0,d0
move.w  (a1,d0.w),d2 / lea (a1,d2.w),a1        ; 16-bit offset RELATIVE to a1
asl.w   #4,d0 / add.b $159(a5),d0
move.b  $C912(pc,d0.w),d0                      ; TABLE A, index ($158*2)<<4 + $159
ext.w d0 / asl.w #4,d0 / add.w d1,d0
move.b  $C8E2(pc,d0.w),d0                      ; TABLE B, 16 wide
add.w   d0,d0 / adda.w (a1,d0.w),a1            ; final 16-bit offset -> the string
move.l  a1,$30(a4)                             ; INSTALL
```

**4. The renderer** (`PRG:0x089062`) reads `$30(a6)` and walks
`len.w, chars.w[len], len.w, chars.w[len], 0x0000`, masking each char with
`andi.w #$fff`; the drawer adds the `0x3800` font base. Strings sit in flat
runs (observed stride `0x46` for the 2x16 form).

**5. WHY EVERY TENANT SHOWS A HOST LINE — it is the ALIAS class.**

The per-character split is the **first-level table at the bank base**, indexed
by the winner id as 16-bit offsets. vsavj's bank (`root 0x0112BC -> bank
0x32D28A`) has **32 entries, and its variant half is exactly aliased**:

```
winner 0x10 -> offset 0x0042 = winner 0x00's (Bulleta)
winner 0x11 -> offset 0x04a2 = winner 0x01's (Demitri)
winner 0x13 -> offset 0x0d62 = winner 0x03's (Victor)
```

which is precisely the reported symptom for all three tenants.

**RETRACTED (mine, same session):** I first diagnosed this as the INDEX-SPACE
class — "table A is authored only to `0x1EF`, the tenant reads `0x263` in a
zero region and falls back to a default". That is wrong. **Table A
(`0xC912`, vs2 `0xB1EA`) is not the per-character selector at all** — it is a
special-matchup flag, near-entirely zero in BOTH games including for vs2's own
newcomers, its one non-zero being winner 0x01 vs loser 0x01 (a mirror match).
Zero there is the correct default, not a fallback. The deadness measurement I
took of that span is sound but measures a span the fix does not need.

**6. VS2 HAS THE DATA, for exactly our three tenants** (`root 0x00F954 ->
bank 0x09CA24`, same 32-entry shape). Its variant half is aliased too, EXCEPT:

| tenant | id | vs2 block | offset span |
|---|---|---|---|
| Phobos | `0x10` | `0x09FE24` | `0x3400`, len `0x360` |
| Pyron | `0x11` | `0x0A0184` | `0x3760`, len `0x460` |
| Donovan | `0x13` | `0x0A05E4` | `0x3BC0` |

**7. THE FIX, and it is in-family.** Per tenant: copy his vs2 block into free
space, then write the 16-bit offset at `0x32D28A + id*2`. That is a **two-byte
variant-row repoint plus data**, the same shape as the sprite/effect palette
rows, and legacy-safe by the same argument — vanilla never puts an id in
`0x10-0x1F` (`tests/audit_id_writers.sh`).

**THE ONE HARD CONSTRAINT:** the offset is **16-bit and relative to the bank
base**, so a ported block must live within `0x32D28A + 0xFFFF`. Offset space
is not the problem (vanilla's last block sits at offset `0x3C5A`, and three
blocks add ~`0xC20`); **whether there is free ROM immediately reachable from
the bank is the open question**, and it is what decides whether this is a
simple data port or needs the bank relocated.

### Per-tenant win-screen checklist
1. `[[code_word]]` x2 — position x/y (slot-following, CODE rows).
2. `[[win_pal_variant]]` — palette; pick the row from the OPCODE view
   of `0x6B2F2` and CONFIRM with the 5*row marker.
3. PORTRAIT record: array `0x2A06E2` (index id), poke vsavj `0x2673ea` <-
   the tenant's portrait record (Huitzil = vs2 `0x2A881E`). Already done
   and working via the (misnamed) `win_quote` select_records entry.
4. QUOTE text: separate structure (record → line char codes → shared
   bank-1 `0xb6xx` font, pal 09) — STILL the un-ported part. Path measured
   14z-76: drawer `0x01B300`/`0x01B3F8`, sprite list `0x28D866`+, char codes
   `0x2F3A7A`. **Do NOT repoint the `0x267xxx` arrays for this — all three
   already carry a tenant repoint and none is read at the win screen.**
   Open: what selects the `0x28D866` record per character.
5. Snapshot the actual screen and compare against a native capture —
   the RAM and ROM can both check out while the screen is wrong
   (14z-68: palette RAM matched vs2 and all 134 tiles matched vs2,
   and the screen was still Donovan-coloured, because "matches vs2"
   was matching the WRONG vs2 row).

## Object TYPE dispatch and the pool walker (decoded 14z-65, fully
## measured 14z-68d on the Huitzil effect arc)

Every secondary object — companions, pods, effect pieces, the victory
portrait drawer — is ticked from a per-frame walker that dispatches on
a TYPE byte. This is the single most load-bearing shared mechanism for
a ported character, and the one most likely to route a tenant's object
into host code.

**The walker** (vsavj `0x5E52A`): iterates 0x80-stride slots, and for
each live slot
```
move.b $2(a6),d0      ; TYPE is at slot +0x02
add.w  d0,d0
add.w  d0,d0           ; index = type*4
movea.l $5E556(pc,d0.w),a0
jsr (a0)
```
so the per-type table is at **vsavj `0x5E556`** (vs2 **`0x6A51C`**),
LONG entries, and a type >= the vanilla entry count is unreachable for
vanilla objects **by construction** — which is what makes an authored
tenant type safe.
There is a second, smaller dispatch of the same shape at vsavj
`0x54470` / table `0x54484` (vs2 `0x5C620`).

**Table sizes** (the `[[obj_hook]]` rows): vanilla 114 entries at
`0x5E556`, vs2 124 at `0x6A51C` — rows 114-120 are vs2's newcomer
types (the `0x88512` pod-zone family). Vanilla 59 / vs2 76 at the
other site. The generator builds a UNION table: vanilla rows verbatim,
then the source's extras resolved (placed region first, then recon,
else a tripwire so an unported type is LOUD).

**Reading the tables:** they are consumed pc-relatively from program
space, so decode them from the **OPCODE view**. The data view yields
garbage (this is the same class as the win-screen remap table).

**HOW THE UNION TABLE IS REACHED: the walker is relocated, the dispatch
site is not patched (14z-91).** The extended table cannot live at the
vanilla table's address — live code follows both (`0x054570`,
`0x05E71E`, and `0x05E71E` is entry 0's own target as well as another
`jmp (d8,PC,Dn.w)` dispatcher). The obvious answer, and the one that
shipped for many sessions, is to put the union table in free space and
replace the 6 vanilla bytes at the dispatch site with `jmp thunk`.

**That hook is a legacy-cycle cost and it was a superset-invariant
regression.** Site `0x05E542` dispatches **270,991 times** across the
49-replay legacy corpus (`0x054470` 8,586 times, in only 5 of 49
replays). The added jumps tipped frames already sitting at the VBL edge,
the main loop lost or gained one iteration, and because replay inputs are
scheduled by FRAME the streams never re-converged — reaching HP and
position differences. Attributed by removal experiment
(`tools/probe_hook_removal.sh`).

The fix is to relocate the WALKER instead. Each dispatch site is the tail
of a 0x2C-byte pool walker (`0x54458`, `0x5E52A`), so the generator copies
the walker verbatim into free space, appends the union table at
copy+0x2C, and rewrites only the 4-byte OPERAND of every
`jsr <walker>` — 2 callers for the small site, 21 for the large one, and
`tools/audit_walker_callers.py` proves that is the complete set (no data
longword anywhere equals either walker address, no pc-relative
jsr/jmp, and every branch hit is the walker's own loop).

It works because `site == walker + 0x18` and the dispatch is
`movea.l (0x12,PC,D0.w),A0`: 0x18 + 2 + 0x12 = 0x2C, so **the copy's own
instruction lands on the copy's own table by construction**.

Legacy cost is then zero by construction rather than by census: identical
opcodes in identical order, and `jsr abs.l` costs the same whatever its
operand while `movea.l (d8,PC,Dn.w)` costs the same wherever PC points.
Measured either side of the move, the dispatch counts are IDENTICAL
(1243 and 40236 on the same replay set), with the vanilla entries silent.

Exactly one byte of state differs — the `jsr (A0)` pushes copy+0x20
instead of walker+0x20. `tests/audit_walker_ghost.sh` measured A7 at both
walkers as a **constant 0xff7ff6** over 279,577 dispatches in all 49
corpus replays, so that longword lands at 0xff7ff2-0xff7ff5, inside the
masked dead-stack window `$FF7F00-$FF7FFF`.

Two things a repeat of this work will get wrong:
- **the table must be emitted as a `code` op** once a relocated walker
  reads it pc-relatively (it was `data` while a thunk read it
  An-relatively). See `docs/platform/gotchas.md`.
- **hole_a is FULL on a 3-tenant merge**, so the allocation must be
  allowed to follow its fallback chain — which is safe, because `code` is
  the correct op kind in raw space too.

**Why not repoint tenant types onto "never dispatched" table entries?**
Because the free lists are not free. `build/manifest/dispatch_census.toml`
records 50 and 83 indices never observed across the legacy corpus, but a
pool-attributed STATIC sweep (scanning forward from every call site of
each pool's allocator — `0x16F8E` for `$FF9400`, `0x16FBA` for `$FFB800`)
finds the true free lists are **1 index and 6**. The corpus touches 9 of
58 real spawn types at one site and 31 of 108 at the other. That is the
same coverage artefact that falsified the list-type 6 deadness claim,
about 40x larger — and it would have traded a guarantee (a vanilla object
CANNOT carry a type >= the vanilla entry count) for an inference.

### The shared-type trap, and `[[obj_hook_extra]]`
Row 8 of the big table is the COMPANION machine — vsavj `0x606AC`,
vs2 `0x6CAC0` — and **vs2 rewrote its own row 8**. So a tenant's
companion/effect object, which carries type 0x08 on both games, is
ticked by vsavj's machine and resolves vsavj's records. Symptom
(14z-68): the object exists with correct fields and the right record
offset, but plays host content.

Row 8 is SHARED, so it must stay vanilla. The mechanism for reaching a
rewritten machine is `[[obj_hook_extra]]` (14z-68): an AUTHORED union
row `{site, index, src}` appended after the ported extras, resolved
like them, with a no-gap assertion (the engine indexes by type*4, so a
hole dispatches into whatever the allocator left). Give the tenant's
instances a NEW type >= the vanilla count and point its row at the
ported machine.

**Two hazards, both paid:**
1. **Scope the stamp per EFFECT, not per character.** Stamping the
   type at a victim-spawn site routed EVERY hit of that class from the
   tenant into the ported machine, and Dark Force crashed on it
   (vec3, an index underflowing the placed region). One character
   reaches a shared site through several different moves.
2. **Base, stream, count and updater are ONE unit.** Swapping only a
   record base while the caller still supplies vanilla-relative
   offsets produces odd/negative indices and an address error. Port
   the region, or leave it alone.

### Per-tenant TYPE NUMBERS on multi-tenant builds (14z-82)

A MULTI-OWNER type — one whose handler region every tenant ports as its
own reconciled copy (site `0x5E542`'s 114-120, the x088512 family) —
cannot dispatch through one union entry: the copies carry per-tenant
literals and each other's tripwire addresses as data (the merged Huitzil
vec3, STATE 14z-81b), and dispatch-time owner reads are transient at
spawn instants (the withdrawn 14z-81c stub). So on a multi-tenant build
the generator renumbers the types at BUILD time: the FIRST resolver
tenant keeps 114-120; every later tenant that STAMPS a type gets its own
number (124+ appended entries resolving into its OWN copy) and the stamp
immediates in its copies are rewritten — no runtime read at all.

The mechanism rests on a FROZEN census, `build/manifest/type_stamps.toml`
(tools/audit_type_stamps.py; gate tests/test_type_stamp_census.sh):
* **Stamp forms are TWO, not one**: `move.l #$01xxTTss,(A4)` header
  stamps AND `move.b #type,(2,A4)` byte stamps — the spawn idiom is
  `beq.s <alloc-fail>; move.b #1,(A4); type at +2; owner/sub at +3`.
  The 14z-81b ad-hoc scan knew only the move.l form and was blind to
  ~26 sites.
* Type 117 has exactly ONE stamp (x088512+0x27CE); 116/119 are
  x088512-only; 114 has ~25 sites across 8 per-tenant region names;
  **type 120 has ZERO stamp sites in any ported span** (its only vs2
  stamp 0x00B63C is unported) and keeps first-wins.
* The 115→117 mid-frame type "morph" (14z-81c) is simply the 117 header
  re-stamp running later in the same copy — stamps renumber together,
  so the morph is timing-proof under renumbering.
* NO code in any tenant's regions COMPARES or table-indexes the type
  byte for this family (census passes 3/4 + the dynamic writer census
  tests/audit_type_writes.sh) — the exposure is the walker alone.

Atlas rows this section depends on: `docs/game/atlas/ram.md` object-pool
rows ($FFB800 0x80-stride, +0x02 type / +0x03 owner-sub, +0x30 owner
link; $FF9400 projectile pool; $FFC800 local pool below).

**Embedded walkers inside the ported spans (census pass 4):** the copies
CONTAIN two more dispatchers of the same shape — vs2's own 0x54470-site
walker at src 0x5C602 (76-entry table at 0x5C620, TRUNCATED by every
tenant's region end) and a THIRD pool walker at src 0x8B988
(x088512+0x3476, hui/pyron copies only): pool **$FFC800**, 24 slots ×
0x80, with its own LOCAL table at +0x3494 — a separate type numbering
space (its +0x02 values index 0..~23). Neither sees 114-120 (vanilla's
own pool separation), so renumbering does not touch them — but any
0x54470-family (59-75) renumbering would, which is why that family is
served by the SPAWN-TIME OWNER TAG instead (14z-85, below), never by
renumbering.

**The 0x54470 family (59-75): the SPAWN-TIME OWNER TAG (14z-85,
maintainer option (a)).** Renumbering is blocked here by vs2's own
embedded 0x5C602 walker (truncated table) and the hit-class map's
64-entry domain, so the merged build routes on a fact baked at spawn:
every frozen 59-75 stamp site (both forms are exactly 6 bytes) is
detoured through a `jsr` thunk that writes the stamping tenant's id
into the object's tag byte — **+0x7F of the $FF9400 slot** (0x100
stride, walker 0x54458; measured free 14z-85: 804 live-slot obs, zero
writes under byte-lane accounting) — then executes the original stamp
CCR-last. obj_hook entries 64-75 are tag stubs (`cmpi.b #id,(0x7F,A6)`
per resolving tenant); a zero or unclaimed tag falls into a planted
ILLEGAL — an untagged family object is a stamp site the emission
missed, loud by design. Nothing clears +0x7F, so stale tags in reused
slots are unread (stubs run only for family types; every family spawn
re-tags). Entries 59-63 are single-resolver (donovan's copies) and
carry no stubs — H/P stamp those types at (currently dead) shared
sites; their tags are emitted anyway so any future live spawn
tripwires under its own tag instead of silently running donovan's
copy. Side file: `patch/tag_map.json`. NOTE the register asymmetry:
the tag WRITE is `(0x7F,A4)` (A4 = slot pointer at every stamp site);
the tag READ is `(0x7F,A6)` (A6 = object at walker dispatch).

Dynamic gate: tests/audit_type_dispatch_range.sh — on the merged build,
ZERO dispatches in the original range [0x1C8,0x1E4) during later
tenants' replays (a census-missed stamp would land there), renumbered
range live for Huitzil, originals still serving tenant-0; and (14z-85)
0x54470 family dispatch live on H and P legs with the tag-stub
tripwire SILENT. The tag bytes themselves: tests/audit_pool_free_byte.sh
(post-tag mode — family slots carry the stamper's tag, +0x7F writer PCs
are exactly the emitted thunks).

### The projectile-pool HIT-CLASS map — a second type consumer, bounded at 64 (14z-82b)

The walkers are not the only consumers of the type byte. The
projectile-pool hit sweep (`vsavj PRG:0x1A770-0x1A886`) is SEVEN
dispatchers — one per collision pairing — that on an OVERLAP (`bhi.s`
skips otherwise; the dispatch is per-collision, not per-frame) map BOTH
objects' type bytes through ONE shared routine:

```
0x1A888: move.b (4,PC,D0.w),d0 ; rts    map at 0x1A88E, 64 entries
```

then `move.w (6,PC,D0.w),d1; jmp (2,PC,D1.w)` through per-dispatcher
8-word tables. vs2's sibling map (routine 0x19292, map 0x19298) has **80
entries**: 0-58 byte-identical (vanilla's true domain — its type table
has 59 rows), 59-63 divergent (vs2 gives Donovan's 61/62 classes
0x0E/0x04; vsavj zeros them), 64-79 the newcomer extension. So **any
ported type >= 64 in the $FF94xx pool that lands a hit over-indexes
vsavj's map** — map[64] = the following rts opcode's 0x4E — and takes a
wild jump: the f7997 vec3, latent in frozen pyron-m2 (satellite type 64)
and shared by Huitzil (68/72 in the same pool). Third instance of the
"vs2 widened an index consumer" class (14z-26 property table, 14z-35
dispatch table, 14z-79's 0x018460 window is the same family).

Fix — **ADOPTED, not pending** (corrected 14z-91; the "ADOPTION PENDING"
here contradicted HANDOFF's registry row for a whole session). The
`hitclass_map_extend` site_thunk is declared by `huitzil.toml:2048` and
`pyron.toml:1044` and is present in their builds; it was maintainer-adopted
2026-08-12 and huitzil-m4 / pyron-m3 were re-frozen on it.

**Because it IS shipped, it is a live hook on a SHARED engine site**, and
**its "legacy never enters the map" evidence was FALSIFIED by measurement
(14z-92, M4).** That claim rested on two census replays, and both of them
happen to score zero. Over the 46-replay legacy corpus legacy enters the map
**230 times** (`24_don_winmash` 2, `26_don_arcade_mash` 228). The fix is
still sound and the argument is now the true one: every observed legacy index
is 0x02/0x04/0x09/0x0b, far below 64, so legacy reads VANILLA's own bytes out
of the thunk — "legacy enters constantly and receives vanilla answers", not
"legacy never enters". Corroborated by 43/46 bit-identical in the same run.
It was the same coverage shape that falsified the list-type 6 deadness claim
and produced the 14z-91 legacy regression, and this time it did fire. It is a `jmp` over `0x1A888` plus a
`cmpi.w`/`bcc` on every collision-map lookup. The dispatch is per-COLLISION,
not per-frame, so it is far colder than the obj_hook site was — but if a
legacy replay ever fails to re-converge and the walker relocation is not the
cause, look here next and re-run `tests/audit_hitclass_map_cost.sh`, whose
corpus IS the full 46 legacy pairings since 14z-92 (it had a four-replay
default until then).

**THE SWEEP IS POOL-vs-POOL (measured, 14z-82d).** Both loop registers
stride pool slots, so a projectile hitting a FIGHTER never transits this
map at all — only a pool object overlapping another pool object does. That
is the mechanism behind how rarely anything enters it, and it is why
`tests/replays/hui/88_hui_plasma_trap_contact.rpl` was authored and still
scores zero: a walking fighter is not a second pool object. Read any zero
from this map against that fact before concluding anything about content.

**THE TENANT SIDE — what the thunk BUYS — is measured by
`tests/audit_hitclass_map_cost.sh` section 3 (14z-93)**, over all 37
Huitzil/Pyron rigs, on verticals built from the CURRENT manifests, with the
indices binned into in-domain (< 64) / vs2 EXTENSION (64-79) / TRAP (>= 80).
Scope is Huitzil and Pyron by construction: Donovan's projectile types are
59-63, they fit vanilla's map, and `donovan.toml` deliberately does not
declare the row. The section reports THREE verdicts and never collapses
them — "reaches the extension", "enters but stays below 64", and "no rig
produces a pool-vs-pool contact at all". The third is a gap in the RIGS,
not a finding about the thunk, and treating it as one is the coverage
artefact that produced the retracted legacy claim below.

**Counting the exposure (corrected 14z-93):** the frozen stamp inventory
has 93 rows with `type >= 64`, but only **36** are in the 64-75
projectile-pool band that can over-index THIS map. The other 57 are the
114-120 obj_hook family, served by the spawn-time owner tag and never
reaching the hit-class sweep. Quoting 93 against a 64-entry map overstates
the exposure by 2.6x.

Generated and reconstructed by (STATE 14z-82b):
`tools/gen_hitclass_map_thunk.py` + `tests/test_hitclass_map_thunk.sh` +
`tests/audit_hitclass_map_cost.sh`.

> **RETRACTED 14z-92.** This paragraph used to end "Legacy content measured
> entering this map ZERO times across four replays — the sweep serves
> secondary-object collisions vanilla content doesn't produce there." The
> four-replay figure was falsified by the corpus-wide run: legacy enters
> **230 times** (see the paragraph above). The sentence survived four lines
> below its own retraction for a session — the §5 failure mode exactly.

Atlas rows this depends on: the $FF9400 projectile-pool row and the
+0x02 type-byte row in `docs/game/atlas/ram.md`.

## Allocator wrappers and slot recycling (14z-65)

vs2's allocators `0x15702` / `0x1572E` are wrapped (`alloc_wrap` in the
tenant manifest) with an 0x80-byte clear: vs2's allocator semantics
differ from vsavj's, and without the wrapper a RECYCLED slot keeps
stale bytes under the new object's init — which surfaces as a
round-2-only bug, after the pool has been through one cycle.

## Pool seeding and the `[[init_shim]]` (14z-65 — the watchdog class)

**Vanilla vsavj never seeds the secondary-object pools during a normal
match; vs2 always does.** Every newcomer's ecosystem allocates from
those pools, so an unseeded pool means the allocator spins on an empty
free list — and it **hangs without an exception**: no crash, no
tripwire, just a watchdog reboot (measured symptom: handler entered,
no fault, reset). If a new tenant reboots the machine on its first
special move, look here first.

The shim intercepts per-char init and calls vsavj's OWN seeder
aggregator (`seed_entry = 0x016C64`) — an ENGINE fact, not a
Donovan-specific address. Fields: `dispatch` (which per-char dispatch
row to intercept), `latch_disp` (pool-0 free-list head), and
`latch_mode`:
- `head` — plain latch;
- `phase` — phase-gated, REQUIRED when the tenant's ecosystem drains
  pool 0, because the bare head latch re-seeds LIVE pools at the
  round-2 re-init and wipes them (measured on Huitzil).

The shim is also where the VS2/VH2 flavor latch lives (`flavor_disp`,
`flavor_default`, `flavor_held`, `flavor_hold_flag` — Start-held at
confirm selects the alternate flavor). **Polarity is per character and
must be MEASURED, not copied:** Huitzil's native vs2 default is
`+0x3C2 = 0x00` where Donovan's convention was 0x01; copying Donovan's
selected the wrong branch and was only caught when the float landed.

## Update-queue classes (14z-65)

vs2 registers companion-class objects in update-queue **class 7**,
which does not exist on vsavj (classes 0-6). Unremapped, the
registration leaves a stale vs2-encoded queue node; after the round-2
pool re-seed that node dispatches a FREED slot — a crash with the PC
in palette space, two rounds after the real mistake. Fix is a
`[[port_patch]]` remapping 7 -> vsavj's last class 6 (for the shared
`x088512` zone: `0x08B0F8`, `000e` -> `000c`).

## THE CAPTURE-POSE INSTALLER (14z-99, measured on Victor's 6+HP grab)

**Read this before touching any grab/capture surface for a tenant.** It is
the site of GitHub #104 and it is a variant-row alias defect, not a data
port problem — the ported data is correct.

A held (captured) victim's pose is installed by a shared engine routine
whose two entry points sit at `PRG:0x27FA0` and `PRG:0x27FAA`:

```
0x27FA0  moveq #0,d1 ; movea.l #$bcffa,a0   <- anim_index_c DIRECTLY
0x27FAA  andi.w #$c,d1 ; movea.l $27fee(pc,d1.w),a0   <- one of FOUR siblings
0x27FB2  movea.w $32(a6),a4        ; a4 = the VICTIM
         move.b $382(a4),d1 ; lsl.w #2 ; movea.l (a0,d1.w),a0
                                   ; a0 = the victim's per-char offset table
         andi.w #$ff,d0 ; add.w d0,d0
         move.w (a0,d0.w),d0 ; lea (a0,d0.w),a0     ; record = table + word[D0]
0x27FCE  move.l a0,$1c(a4)         ; install on the victim
```

Two facts that cost time in 14z-98/99, both measured:

- **`0x27FAA` is never executed.** It is real, correct code and the
  four-sibling table at `0x27FEE` is real, but every live path enters
  `0x27FA0` — 0 probe hits at `0x27FAA` against 904 at `0x27FA0` on the
  same replay. The sibling in play is always `anim_index_c` (`0x0BCFFA`).
- **`D0` — the capture index — is supplied by the CALLER**, and the caller
  is the attacker's own anim-node walk: `0x27F70` advances the attacker's
  node (`($1c,A6)`, 0x18 stride) into the capture positioner at
  `0x028072`, which writes the victim's position from the node's keyframe
  (`add.w ($10,A6),D0` / `add.w ($14,A6),D1` -> `($10,A4)`/`($14,A4)`) and
  tail-branches `move.w (A0),D0 ; bra $27fa0`. So one node supplies BOTH
  the victim's offset and its pose index.

**The index is per VICTIM and the convention is SHARED between the
engines** — this is the load-bearing measurement, and it is what refutes
the "reaction-index generation drift" reading (STATE 14z-98 (9),
retracted). Same rig, ours vs native vsav2, index installed at victim
`+0x1C`: Bulleta 12/12, Demitri 11/11, Victor 6/6, Lilith 9/9.

**The defect:** the victim's capture set resolves through 32-row
per-character structures whose rows `0x10-0x1F` are byte-copies of
`0x00-0x0F` (the port's most common defect shape), so a TENANT victim is
served the base character it folds onto — Donovan `0x13`->`0x03` gets
Victor's index 6 where native gives 11; Phobos `0x10`->`0x00` gets
Bulleta's 12 where native gives 26. **Pyron `0x11`->`0x01` gets Demitri's
11, which is also his correct value** — right by coincidence, and exactly
why the field report named Donovan and Phobos and not him.

**THE RESOLVING STRUCTURE, located 14z-99 — it is the head of the
attacker's own keyframe block**, and the whole defect is seven
instructions at `PRG:0x02802E`:

```
02802E  movea.w $32(a6),a4        ; a4 = the VICTIM
028032  tst.b $134(a4) ; beq      ; only while the victim is captured
02803A  movea.l $1c(a6),a0        ; the ATTACKER's current anim node
02803E  move.b $12(a0),d0 ; lsl.w #3,d0    ; keyframe index * 8
028046  move.b $382(a6),d1 ; lsl.w #2,d1   ; the ATTACKER's id
02804C  movea.l #$be27a,a0 ; movea.l (a0,d1.w),a0   ; -> his keyframe BLOCK
028058  move.b $382(a4),d1 ; add.w d1,d1            ; the VICTIM's id, RAW
02805E  add.w (a0,d1.w),d0        ; += block[victim]   <- THE PER-VICTIM TABLE
028062  lea (a0,d0.w),a0          ; = block + block[victim] + keyframe*8
028066  move.w (a0)+,d0 ; move.w (a0)+,d1  ; Xoff, Yoff -> victim +0x10/+0x14
02809E  move.w (a0),d0 ; bra.w $27fa0      ; and the victim's RECORD INDEX
```

So **the first 32 words of every attacker's keyframe block are a
per-victim offset table, indexed by the victim's char id UNMASKED** — and
in vsavj **all sixteen blocks alias their variant half onto the base half**:
fourteen by OFFSET (rows `0x10-0x1F` are word-copies of `0x00-0x0F`) and
two — Zabel `0x04` and the special slot `0x0B` — by MATERIALIZATION (32
distinct offsets whose variant sub-block CONTENT byte-copies the base
sub-blocks, 15/16 rows; row `0x1F` is the known exception in both). A
tenant victim therefore lands in the base
character's capture sub-block and takes BOTH its position keyframes and
its record index, which is precisely the "half right, half a knocked-down
sprite, very horizontal" the field reported.

Static and dynamic agree exactly. Victor's block `0x098C28`:
`block[0x13] == block[0x03] = 0x0568`, `block[0x10] == block[0x00] =
0x0040`, `block[0x11] == block[0x01] = 0x01F8`; every measured A0 is
`block + block[victim] + 0x106` — same keyframe, different sub-block, five
victims for five.

**vs2 is not aliased and already holds the answer.** Its twin blocks carry
real, distinct rows for the newcomers (vs2 Victor `0x0A8824`: row 0x10 =
`0x1A08`, 0x11 = `0x1BC0`, 0x13 = `0x1D78`; row 0x12 stays an alias
because vs2 has no character there). The port gap is that vsavj's blocks
have no tenant sub-blocks at all.

**(A superseded reading, kept for the record: "the two exceptions are the
useful part / read them first — their 32-entry tables are the shape the
fix needs" — RETRACTED the same session, 14z-99.** Zabel `0x04` and the
special slot `0x0B` do carry 32 distinct offsets at uniform `0x190`
stride, but their variant-half sub-blocks measure as BYTE-COPIES of the
base sub-blocks, 15/16 rows with `0x1F` the exception — the SAME defect
stored as materialized content, not populated tenant data.)

**THE FIX IS MEASURED FEASIBLE AND ITS SHAPE IS SETTLED (14z-99;
maintainer-ruled option (a) — full — conditioned on these measurements,
which came back clean; every premise below is frozen in
`tests/test_capture_pose_sources.sh`):**
- **Source data exists for all 16 attackers in BOTH source games**, with
  distinct tenant rows (`0x10/0x11/0x13`), sub-block stride EQUAL to
  vsavj's per attacker (the keyframe-index-space compatibility signal),
  and vs2 == vhunt2 on every tenant sub-block (cross-oracle).
- **Every BASE sub-block is byte-identical between vsavj and vs2**, all
  16 attackers — the capture keyframe data for legacy victims never
  changed between generations. (Zabel's table LAYOUT differs — vs2
  merges Zabel+special into one shared block `0x0ABC56` — but the
  content each game's offsets reach is equal.) This is what makes a
  wholesale vs2 port legacy-safe by CONTENT; and the addresses never
  enter work RAM — the positioner emits VALUES (keyframes and a record
  index), and the victim's `+0x1C` comes from `anim_index_c`, untouched.
- **The signed-16-bit bound holds everywhere**: the offset is a WORD
  consumed by `lea (a0,d0.w)`, so sub-blocks must sit within ±32 KB of
  the block base; the worst extended blob reaches `0x3730`.
- **Implementation = the shipped `throw_victim_keyframes` mechanism, 15
  times**: port each of the 15 DISTINCT vs2 blocks (Zabel+special share
  one) into `wide_ext` — `0x11BD0` bytes, ~71 KiB — and repoint `0xBE27A`
  rows `0x00-0x0F` plus `0x18` (Oboro Bishamon is a real attacker id and
  must follow row `0x08`'s new block). Exactly 5 code sites consume
  `0xBE27A`, all through the table, so the repoint covers every consumer.
  Rows `0x10/0x13` are already tenant-ported; **row `0x11`
  (Pyron-as-attacker) still aliases Demitri's block** — an open
  observation for the window (it matters only if Pyron has a capture
  move that runs this positioner).
- The repointed rows are LEGACY-DEREFERENCED pointers — the 14z-91
  walker relocation is the precedent (byte-identical content at a new
  address, proven by legacy A/B at the probe build).

Gate: `tests/audit_don_grab_pose.sh` (legacy-victim control in section 0).

## Throw / physics-arc tables (14z-67, measured on the command grab)

The victim's launch physics come from a per-throw ROW installed by
vsavj `0x28386` (vs2 `0x275E4` — a unique tail twin pair):
```
row = table2[ map1[ 2*subidx + d0 ] * 16 ]
```
and the row writes the victim's **xv +0x40, yv +0x44, xacc +0x48,
gravity +0x4C** (all 16.16 fixed point on the fighter struct).

**vs2's `map1` carries FIVE entries past vsavj's end** (indexes
0x4A-0x53 -> rows 0x32-0x36; the 63214 command-grab arcs are rows
0x33/0x34, yv 16.0 and 20.0). On vsavj a newcomer's index reads PAST
map1 into table2's bytes and lands on a regular-arc row — symptom:
"both grabs look identical / the victim does not leave the screen".

Both vsavj tables are jammed in place (data follows immediately), so
the fix is a full tail-replacement `[[site_thunk]]` (patch=jmp,
jmp_ok, body ends `rts` to the installer's caller) reading PLACED
copies of vs2's FULL tables. **Superset proof, static:** map1's prefix
0x00-0x49 and table2 rows 0x00-0x31 are byte-identical across the
games, so vanilla content reads identical values through the clone and
the thunk can be unconditional.

## The DAMAGE pipeline: two appliers, one scaler chain (14z-85e/85f,
## measured on Phobos' FINAL GUARDIAN; twins verified in both engines)

Depends on atlas rows: fighter structs `$FF8400/$FF8800` (`+0x50` HP,
`+0x52` white HP, `+0x144` combo counter, `+0x382` char id AT SELECT ONLY
(in match it is the voice-flavor class — 14z-87; use `+0x60.l` hitbox base
for in-match identity),
`+0x3B3` per-char stat byte, `+0x8C` attack-record table ptr,
`+0x32` attacker/owner link), the A5 work-var families below, and
docs/game/gotchas.md "Same-value class #4".

**Two parallel damage APPLIERS feed one staging protocol** (all
addresses vsavj; vs2 twins in parentheses, verified instruction-
parallel):

- **Fighter-hit stager** `PRG:0x0189BA` (vs2 `0x01732C`): the path for
  fighter-vs-fighter contacts. Reads base power from the hit record —
  real `(8,A3)`, white `(9,A3)` — through the scaler chain below into
  the staging vars, then falls into the post-process.
- **Object-hit applier** `PRG:0x29738` (vs2 `0x28A6A`): the path for
  pool-object hits (projectiles, beams). Called BY per-hit REACTION
  handlers (54 call sites in vsavj, 78 in vs2 — one per hit class
  family). Entry: D0 = attack id; `A3 = ($8C,a6) + id*32` (a6 = the
  ATTACKER context), victim via `($32,a6)`; writes hitstop
  `#$3C/(0x13A,a1)` + `#$0A/(0x13B,a1)`, then the same staging
  protocol, then `jsr` post-process. The applier ends with the shared
  white-HP/KO logic (the KO signature `move.w #$FFFF,(0x50,a1)` +
  `(0x52,a1)` — the session-10 reconciliation anchor).

**The scaler chain** (`bsr` targets of both appliers):
- `PRG:0x18B8C` (vs2 `0x17522`) attack scaling: `class = power & 0x1F`;
  `d2 = attack_table[class*32 + attacker (+0x3B3)]` — table at
  `PRG:0x0B8140` (vs2 `0x0D22BE`), **byte-identical between the
  games**. Bit 5 of the raw power byte skips the stat add. Then the
  damage-level config jump (`(0xB2,a6)`; both games: ×1, ×1.25, ×0.5,
  ×0.25 — vs2 adds ×0.75), a random spice pass (`0x18D22`, table
  `0x0BB240`/vs2 `0x0D53DE`), and **the minimum floor: d2==0 → 1,
  cap 0x7F**. Class 2 rows cap at 2 — small-tick beams are 1-2
  HP/tick BY DESIGN in both games.
- `PRG:0x18C08` (vs2 `0x175AE`) defense/apply: defender-side d3 from
  defense table `0x0B8940` (vs2 `0x0D2ABE`; 32B per char id — rows
  0x0A/0x10/0x13/0x19/0x1A differ between the games = the roster id
  shuffle, see the port note below), combo-counter tables
  (`0x19610/0x19A10/0x19E10/0x1A210`; identical), low-HP rally
  (threshold/char `0x0BCC80`, spice `0x0B8D40`), then **final damage =
  2D map `0x0B9140[d3*0x80 + d2]`** (negative d3 → `0x0BA1C0`; both
  maps byte-identical to vs2's `0x0D32DE/0x0D435E`). The "walker
  A0=0xB91C0 +0x180/tick" seen live in 14z-85e was this map's row
  pointer moving as d3 grows with the combo.
- Post-process `PRG:0x18AB0` (vs2 `0x17422`): reads the staged words
  and applies them — HP decrement `sub.w d4,(0x50,a1)` @`0x18AC0`.

**The staging protocol is A5 work vars, and the layouts differ by a
uniform -0x52** (gotchas class #4): vsavj stages real/white/flag at
`-0x4BBE/-0x4BBC/-0x4BBA(a5)` = `$FF3442/44/46`; vs2 at
`-0x4B6C/-0x4B6A/-0x4B68(a5)` = `$FF3494/96/98`. Attacker/victim
registration: vsavj `-0x4BC6/-0x4BC4`, vs2 `-0x4B74/-0x4B72`.
**Ported engine-family code (region x028122 carries the vs2 applier +
reaction handlers per tenant) must have its staging displacements
port_patched to the vsavj layout** — the reconciler rewrites absolute
addresses, not d16 displacements. Donovan's six session-14n rows are
the template; propagated to H/P 14z-85f after Phobos' FG beam ticks
measured 12 combo-counted hits with ZERO HP (damage staged into the
vs2 vars nobody reads). The 14x rollback rule still holds: the
attacker/victim-registration and state-byte family
(`-0x4B74/-0x4B72/-0x4B3D`) is consumed by PORTED readers and must
stay at vs2 offsets. Gate: `tests/audit_fg_parity.sh`.

**The victim-side REACTION CLASS dispatch (14z-85g(2), measured):**
after the appliers, the victim's reaction is chosen at `PRG:0x2384E`:
`move.b (0x54,a6),d0; add.w d0,d0; move.w (0x2385C,pc,d0.w),d1;
jmp (pc,d1)` — the class byte (copied from the hit record, byte +0x1D
of the 0x20-stride hitbox/hitbox_proj records) indexes a PC-relative
word jump table. vs2's twin (dispatch 0x2237A, table 0x22388) has
0x54 entries; **vsavj's table ends earlier — any vs2-extended class
(0x4E+) over-indexes into code bytes** (the Donovan 421P/column class,
14z-33/34; the trap dome's class 0x52, 14z-85g(2)). vs2's table
carries ALIASES (0x52 ≡ 0x06 ≡ 0x38 → the shock install 0x22656),
which is the remap licence: vsavj entry[0x06] = the native
electric-shake 0x23AC8, a structural twin of vs2's 0x52 handler minus
the attacker-freeze exemption (vs2 skips the attacker's 0x0B when the
"attacker" is a mine). The handlers end in property[class] (the
0x28D00/0x27FD8 byte map — property 0x0F = electric) → the common
install (vsavj 0x27EC0 ↔ vs2 0x27114). Atlas rows: victim `+0x54`
class, `+0x5C` freeze, `+0x07` seq sub-state (4 = shock), attacker
link `+0x32`.

**Multi-hit accounting:** the gate at `PRG:0x18090` dedups by hit id —
record byte `+0x10` vs the victim's recent-hit ring at `+0x6C`
(rotating index at attacker context `+0x70`). The combo counter
(`+0x144`, victim) is incremented by the REACTION handlers (vs2 beam
reaction `0x56002`: +3/tick), not by the appliers.

**Port note (defense side, DECIDED 2026-08-14):** tenant ids sit on
vanilla vsavj defense-table rows — row 0x10's curve and low-HP
threshold (vsavj 0x38 vs vs2 0x28 for Huitzil) are vanilla values,
NOT the characters' native vs2 tuning. Maintainer-ruled KEPT as the
deliberate vsavj approximation; the values and the would-be change
recipe live in docs/project/tables/defense_rows.md. (Pyron's rows are
identical between the games — unaffected either way.)

## THE ROUND JUDGE: death is the SIGN OF WHITE HP, and the phase
## machine that consumes it (14z-98, measured end to end on #103)

Depends on atlas rows: fighter `+0x50` / `+0x52` (the judge tests
`+0x52`) / `+0x54` / `+0x5C` / `+0x11F`, work vars `$FF3442/$FF3444`
(staged damage — the "Same-value class #4" family), `$FF800C` (phase
cursor), `$FF810C` (KO mask), `$FF8129` (judge gate byte, 14z-97 (8)).

**The phase machine.** `$FF800C` is a jump-table CURSOR (0,2,4,…)
advanced by `addq.w #2,$c(a5)` at the transition sites. Several outer
modes each own a dispatcher + word table; the IN-MATCH one is
`PRG:0x93CE` with table `0x93C0` (phase 6 = fighting -> handler
`0x97DC`; phase 8 = KO/judge presentation -> `0x9A04`). (`0x9C9E`
/table `0x9CCE` is a different mode's machine — its phase-6 handler is
a press-or-timer screen; do not conflate, its round-over test `0xAD06`
is an INPUT-EDGE test on `$FF8058-$FF8067`, which is the INPUT
register block, not combat state.)

**The death detect** (phase-6 handler `0x97DC`, every frame):

    0x97FC  tst.w $852(a5)   ; P2 +0x52 (WHITE hp) < 0 -> d0 |= 1
    0x9804  tst.w $452(a5)   ; P1 +0x52            < 0 -> d0 |= 2
    0x980C  move.b d0,$10c(a5)  ; the KO mask
    0x9840  beq rts / 0x9844 bsr $9880 (judge prep) / bsr $99a8
    0x984C  addq.w #2,$c(a5)    ; PHASE 6 -> 8

It reads **+0x52, never +0x50**. vs2's twin (`0x800C/0x8014`) tests
the same offsets — NOT an engine-generation drift. The timeout path is
the `$10A/$109` chain above it; `0x9880` resolves winner/loser structs
and folds ids via `0x9996` (0x0B->0x04, 0x1B->0x14 — the Oboro fold).

**Why testing white alone is sound (the invariant):** both appliers
subtract the staged damage from BOTH words (`0x18AB0`: real from
`$FF3442`, white gets real + the `$FF3444` extra), and white sits AT
OR BELOW hp, so white crosses zero first. The death decision runs on
white right after the subtract (`0x18A42-0x18A66`): `< 0` -> the KILL
COMMIT `0x18A7C` (`hp := -1, white := -1`, death flag `+0x11F := 1`);
`0 < white <= $138(a1)` -> the near-death commit `0x18B12` (also sets
`+0x11F/+0x117`, writes `+0x54` from attack byte `$17(a3)`). Measured
live on an arcade KO: applier writes hp 17->6 / white 15->**-3**, then
`0x2980A/0x29810` write both `-1` in the same frame. The no-kill
attack flags are `$8(a3)/$9(a3)` bit 7 (clamp real/white at the floor
instead of killing).

**The settle:** in phase 8 the loser's sequencer walks his death
records and the settle helper `0x995A` (run for both structs) tests
`+0x111` then `+0x11F` and dispatches the dead fighter PER-CHAR
through `0x0BF61A` row `$382<<2` (dispatch_19 — ported at row 0x13);
`+0x1C` is cleared ~KO+240, the stage word moves ~KO+560.

**The failure mode this section exists for (#103):** any state with
`hp < 0` while `white >= 0` is UNJUDGEABLE — the phase machine never
leaves 6, the presentation runs (reactions key off +0x50) but the
round never ends until an engine failsafe (~8,000f). No legacy path
can produce that state (the appliers keep the invariant); Donovan's
ported x026142 pc-rel escape did (a pool-object durability init
`+0x50 := 1` running on the fighter — see docs/project/gotchas.md
14z-98 and GitHub #103 for the port-side mechanism).

## Shadow / reflection servants (14z-66; premise CORRECTED 14z-68f)

Per-player shadow servants (class-0x0C trio, vanilla spawner
`0x489DE`+) mirror their owner's animation by reading each anim NODE's
`+0xC` word (low 13 bits = a seq id) into SHARED tables:
- installer vsavj `0x823E2` / `0x823F2` -> table `0x2083BC` or
  `0x2087CA` (chosen on `+0x38`), stored to `+0x40(a6)`;
- the walk re-reads on seq CHANGE only (`cmp.w $50(a6),d0; beq`) and
  jumps the walker at `0x8245C`.

A ported character's nodes carry SOURCE seq ids verbatim, and an
out-of-range id over-indexes into sequence DATA -> garbage offset ->
vec3 at the engine installer. `shadow_seq_guard` clamps
`seq*2 >= 0x40E` to seq 0. **The clamp is deliberately UNGATED by char
id**, because capture supers put a VANILLA victim's servant through
tenant-supplied seq ids.

### The child-companion shadow item (14z-68g/q — measured, still open)
Symptom (maintainer): Phobos's human child companion has a RECTANGULAR
shadow, **all the time**. Narrowed as follows, all measured:
- The shadow's CORE tiles are CORRECT: codes `0F8B`/`0F8C`, palette
  0x16, at bank word **0x1000** (H's band in group C bank 4 — i.e. the
  `table_fix` row 0x10 works for them).
- The BAND around them is wrong, and uniformly: every piece carries
  **bank word 0** and **code = native - 0x16A8** (12 pieces, no
  exceptions: 0F96->F8EE, 0FB7->F90F, 0FA4->F8FC, 0FA2->F8FA,
  0FA3->F8FB). With bank 0 they draw from VANILLA gfx space, which is
  why they read as flat rectangles.
- **NOT Dark-Force-specific**: the same band appears in a plain
  projectile replay, confirming "all the time" and ruling out a DF
  interaction.
- So TWO different code paths stage sprites of the same palette
  family: one honours the tenant bank table, one does not. The open
  question is which path stages the bank-0 pieces.
- Ruled out: a per-char tile-base table holding 0x16A8 (data scan
  found no clean candidate). Note the OBJ list is DMA'd, so write taps
  and debugger watchpoints on OBJ RAM see nothing — the technique that
  worked for finding an emitter was a **work-RAM diff between a frame
  before and during** the effect (14z-68b).
- Related, likely the same root: the 14z-67 note "ours spawns
  F8FC/F90A/F15x-family pieces WITH BANK WORD 0 that native NEVER
  stages — created through a path that leaves +0x18 unset".

**CORRECTION (14z-68f), do not repeat the old note:** vs2's tables are
**NOT larger** — vs2 installer `0x90B0C`, tables `0x1E42D2`/`0x1E46E0`,
exactly `0x40E` apart, the same row space as vsavj's; the walk sites
are structurally identical; the only content difference is a uniform
+2 (one extra index entry). So "port the bigger table" cannot fix a
shadow item. Also measured: on a build where Huitzil's summon pieces
are live, the installer and walk take **0 probe hits** — whatever
draws a companion's shadow is NOT this servant path. The remaining
child-companion shadow item is attributed instead to the bank-0 piece
family (uniform -0x16A8 tile-code delta, bank word 0 vs 3).

### THE DARK FORCE PALETTE-SEQUENCE BLOCKS — measured census (14z-79b)

Which palette-seq ids does each character request in Dark Force? Measured on
**vanilla vsavj**, one MAME run per character, `$FF802E`=1 asserted on every
row (`tests/audit_palette_seq_ids.sh`, `CHARS="..."`). This is the input to any
future "give a tenant his own block" work, and it is a MEASUREMENT because the
static route does not work — see the warning below.

| ids | owner |
|---|---|
| `0x1E-0x21` | **Bulleta `0x00`** |
| `0x26`, `0x27` | Demitri `0x01` |
| `0x44-0x47` | Zabel `0x04` |
| `0x6F-0x72` | Bishamon `0x08` **and** Oboro Bishamon `0x18` (same block) |
| `0x264-0x267` | Q-Bee `0x0C` |
| `0x29C-0x2A0` | `0x12` — **five ids, not four** |
| none | Gallon `0x02`, Victor `0x03`, Morrigan `0x05`, Felicia `0x07`, Aulbath `0x09`, Sasquatch `0x0A`, Lei-Lei `0x0D`, Lilith `0x0E`, Jedah `0x0F` |

**NOT MEASURED: Anakaris `0x06`.** Two attempts, both `$FF802E`=0 — the rig
never entered Dark Force for him, so his zero is a fact about the RIG. (`0x0B`
is also unmeasured and is not a character — Shadow/Marionette machinery.)

**STRONG INFERENCE, NOT A MEASUREMENT:** the routines hardcode seven base
constants — `0x1E 0x26 0x44 0x6F 0xAA 0x264 0x29C` (e.g. `0640 001e` at
`0x02a92c`). Six have measured owners above. The seventh, **`0xAA`, has no
measured owner and Anakaris is the one character not measured**, so `0xAA-0xAD`
is very probably his. Treat it as OCCUPIED until someone reaches his DF.

**WHY THIS CANNOT BE DERIVED FROM TABLE `0x02A8A4`.** The obvious model — row
per character, each pointing at a routine with one hardcoded base — is WRONG.
Rows `0x02-0x07`, `0x09`, `0x0D-0x0F` all hold `0x0040` and reach the SAME
routine at `0x02a8e4`, yet `0x04` requests `0x44-0x47` and `0x02/0x03/0x05/0x07`
request nothing. That routine is conditional (`cmp.b (0x14f,a6),d0 / bne.w
0x030ee8`) and at least some ids arrive by another path entirely. A static
reading of the table produces a confident and wrong map.

**ADDRESSING LIMIT for anyone allocating a block.** The resolver is
`a0 = 0x39A900 + (d0 & 0x0FFF) * 0x20`, so the reachable window is
`0x39A900-0x3BA8E0` — a block cannot live in `wide_ext`. And "no character
requests id N" is NOT sufficient to call row N free: those bytes may belong to
another structure entirely. Establish what the bytes ARE, not just that nobody
asked for them — the 14z-69 row satisfied "nobody asked" on a sample that
could not ask.

**THE TENANT ANSWER (14z-84, shipped in huitzil-m6): none of the above.**
Phobos' own block does NOT allocate in the window and does NOT touch the
resolver: table 0x02A8A4 row 0x10 (his variant row — the alias that made
his DF purple) is repointed at a tenant thunk that computes a0 = a gold
block in wide_ext (vs2 0x3ABEDC, both player sides) and enters the shared
uploader at 0x2AD3C exactly as the resolver does. Two mechanism facts this
work measured: the row routines' id = base + step(0..3, every-other-frame
via the $B4(a5) parity bit) + $381(a6)*4 (the PLAYER SIDE — every block is
really 8 rows, and this census's per-char id lists are the P1 halves); and
vs2's resolver reaches BELOW its base via the lea's SIGNED word index
(ids >= 0x400 wrap negative), which is how his native gold ids
(0x5A5-family) resolve to 0x3ABEDC there.

## The SUB-STATE DISPATCHER FAMILY at 0x018460 (14z-79)

Three sibling dispatchers sit back-to-back and share ONE handler pool. All are
reached by fall-through from a guard chain, not by call, so a handler's `rts`
exits the enclosing subroutine (`0x018230`, whose only located caller is the
`bsr.w` at `0x018216` — a handler therefore returns to `0x01821A`).

| dispatcher | shape | table | entries | table ends |
|---|---|---|---|---|
| `0x018460` | `323b 0006` / `4efb 1002` | `0x018468` | 80 | `0x018508` |
| `0x018508` | `323b 0006` / `4efb 1002` | `0x018510` | 80 | `0x0185B0` |
| `0x0185D2` | `303b 0006` / `4efb 0002` (D0, not D1) | `0x0185DA` | 80 | `0x01867A` |

Handler pool: **`0x01867A`-`0x0187BA`**. Dispatchers 2 and 3 target handlers
inside the same pool, and dispatcher-1 handlers branch INTO dispatcher-3's
handler space (e.g. `0x0186A2`). **Do not relocate that pool piecemeal.**

The index arrives as `moveq #0,d0 / move.b (0x17,a3),d0 / add.w d0,d0` at
`0x018438` — entry*2, with **no bounds check**. Four guards
(`0x018440`-`0x01845F`) can divert to `0x0185B0` or to dispatcher 2 before the
dispatch happens; a hook that must run after them therefore cannot sit earlier
than `0x018460`, and no 6-byte instruction-aligned window ends there (the two
preceding instructions are 4+4 bytes).

**Two properties measured in 14z-79 that anyone re-hosting this dispatcher
needs.** (1) The table is read PC-relatively, so it lives in the OPCODE view;
an An-relative replacement reads the DATA view and gets ciphertext — 38 of the
80 targets come out odd. (2) **D1 is dead on ENTRY to every handler and live
afterwards**: none of the 23 distinct handlers reads the CCR or D1 before
writing it, but they `rts` into a `bsr.w` chain that does consume D1. A
replacement must leave D1 holding the vanilla table offset.

vsavj's table has 80 entries where vs2's twin (`0x016D34`, dispatcher
`0x016D2C`) has 84 — the index-space class. See the (b') thunk
(`build/manifest/huitzil.toml`, `index_window_018468`).

## Dark Force (14z-66/67 mechanics UNPROVEN; style measured 14z-69;
## the 14z-69p PALETTE FIX WAS WITHDRAWN 14z-79 — it broke Bulleta)

> Status: the DF palette is **OPEN**, and his DF is purple on purpose.
> The 14z-69p `[[data_port]]` row that rewrote palette-seq rows
> 0x1E-0x21 is WITHDRAWN: those ids are **Bulleta's Dark Force block**
> (236 resolver calls in one vanilla DF, measured), so the row rendered a
> legacy character wrong on every Huitzil build from 14z-69 until 14z-79.
> Phobos only lands on her ids because row 0x10 of the per-character
> palette-routine table `0x02A8A4` is `0x004A` — row 0x00's handler — and
> the base id is hardcoded in that routine (`0640 001e` at `0x02a92c`).
> The collision is structural: in vs2, slot 0x10 IS Huitzil and id 0x1E is
> HIS (180 calls, `$FF802E`=1, measured native). Repointing the row at
> vs2's `0x0040` has an **unknown** outcome (RETRACTED 14z-79b: "that routine
> has no DF path at all" came from reading five instructions at `0x02a8e4` and
> not following the `bne.w` to `0x030ee8`; char `0x04` shares that same row
> value and DOES request `0x44-0x47`). Measure it before assuming either way.
> PROPER FIX, deferred: give him his own free 4-row block plus a copy of
> the routine with that base. Retracted claim: "legacy only ever requests
> seq ids 0x26/0x27" — false; `tests/audit_palette_seq_ids.sh` sampled
> replays in which Dark Force never activates, and 0x26 is Demitri's own
> block. The palette path never transits work RAM, so no RAM gate can see
> any of this; the maintainer's playtest found it. The
> afterimages remain by design, and the underlying MECHANICS are still
> unproven; the analysis below stands.

**Atlas rows this section depends on** (`atlas/ram.md`): `+0x109`
banked stock count, `+0x107` resolver marker (0xFE = pair downgraded,
no stock), `+0x006` sequence, and the match-level DF flag `$FF802E`.

**READ FIRST: DF COSTS ONE BANKED STOCK.** With an empty meter the P+K
pair is DOWNGRADED to a single button and the match continues normally
— `seq 0x0A` is that downgrade, NOT Dark Force. Everything in the two
subsections below was measured on replay 82, which has no stock, so it
describes the downgrade path and ordinary movement. The DF facts start
at the 14z-69 section.

Split the item in two; they have different answers.

**DF MECHANICS are already native-correct for a ported tenant.**
Measured on Huitzil (replay 82, native A/B of record): activation
enters seq **0x0A** at the same frames on both games, expiry and
re-activation both fire, and the DF summon pieces (secondary types
**0x75 / 0x77**) are present in pool B on both at the sample frame.
Nothing in the activation path needs porting.

**DF STYLE is a HOST per-character effect and is what looks wrong.**
The engine applies a per-char DF presentation (palette treatment plus
afterimages) selected by char id, so a tenant on a variant row inherits
the HOST character's style. Maintainer capture of native vs2: Huitzil
gets **no palette change and no afterimages at all**; ours shows
inverted colours + afterimages, i.e. the host's style.
**Fix shape (not yet implemented):** locate the per-char DF style
selection and give the tenant's row the NULL style. This is a
selection-table item of the same family as the win-screen tables
above — expect an id-indexed table with variant rows aliasing base
rows, and expect the same view question (decode both, verify against a
known-good row).

**Measured 14z-68s/t/u — CAUTION, ALL OF IT WAS MEASURED OUTSIDE DARK
FORCE (14z-69).** Every number in this block comes from replay 82, which
presses the pair with an empty meter and therefore never enters the
mode; read it as a description of ordinary movement, not of DF. The
"extra sprites" conclusion happens to be right (DF really does draw him
3-4 times over — but that is measured in 14z-69 below, not here), and
the "palette alternates per frame" reading does not survive: in real DF
the row holds ONE purple ramp for the whole mode. Kept for the ruled-out
list, which is still useful.

**THE EFFECT ONLY APPEARS WHILE THE CHARACTER IS MOVING.** In 14z-68t
I sampled replay 82 at f3050-3250 (the stationary window), measured no
sprite gain and no palette change, and wrote the symptom up as "not
reproduced". That was a SAMPLING ERROR. The maintainer's repro note —
"move around, especially visible when air dashing" — located it
immediately. Replay 82 walks at **f3300-3400**; sample THERE.

Maintainer repro (no replay needed): 1 stock, **HP+HK** to trigger DF
(MP+MK / LP+LK equivalent), then move — air dash shows it best.

Corrected measurements (replay 82, id-0x10 poke, build hui11):
- **The afterimages ARE extra sprites, and they are HIS.** pal-0x0A
  sprite count goes **22 stationary -> 24-29 while moving**, drawn as
  additional groups at trailing positions spanning ~72px. The captures
  show 3-4 ghost copies.
- **The palette ALTERNATES per frame**: some frames render his correct
  gold/yellow, most render purple. So it is not a static recolour —
  it cycles.
- **NOT shadow servants**: the servant installer `0x823E2` and walk
  `0x8245C` take ZERO probe hits across the whole replay, moving
  window included. The copies come from the fighter's own draw path.
- Still true from the earlier pass: there is no DF-specific palette
  ROUTINE (same writer PCs before and during), so the recolour is a
  palette SOURCE/selection change, not different code.

### The mechanism, as far as it is decoded (14z-68v)
DF drives the FIGHTER'S EFFECT CHANNELS — the `+0x318 / +0x320 /
+0x330 / +0x340` sub-structs documented in the effect-system section.
Measured by diffing the fighter block pre-DF vs during-DF-moving: the
channels go from all-zero to populated (`+0x318`=[2,2] `+0x31C`=4
`+0x320`=[2,2] `+0x324`=5 `+0x32C`=13 `+0x330`=[2,2] `+0x334`=11,
plus flags at `+0x395`/`+0x397`).

Those channels run SCRIPTS through a small state machine:
- per-frame CLEAR path (runs always): `0x029F60` / `0x02A57C`;
- the DF-only writers, i.e. the channel actually doing something:
  **`0x029F86`, `0x029F9A`, `0x029FD2`, `0x029FDA`, `0x02A528`,
  `0x02A538`, `0x02A582`** (these PCs appear ONLY while DF is up);
- the machine reads a script through `a3`, matches script words
  against the fighter's `+0x12A`, and steps a channel struct via `a4`;
- the script tables are loaded by `lea $2A768(pc),a3` /
  `lea $2A770(pc),a3` / `lea $2A778(pc),a3`, selected by a
  program-byte dispatch at `0x029F4A`
  (`move.b (a4),d0; move.w (pc,d0.w),d1; jmp`).

**Where the trail stops (14z-68w), and the cheapest way past it:**
- The channels do NOT populate at DF activation. Tapping
  `+0x318..+0x340` across the activation window shows the only write
  is `+0x396` = 0x1100 (the button register, pc `0x014E58`); the first
  non-zero channel write is at **f3150**, coinciding with the next
  MOVE input, not with DF. So the channels are move-driven and are
  probably not themselves the style selector.
- Ruled out as the cause: the seq-0x0A (DF) handler is per-char
  dispatched like every other seq head, and on a tenant build its
  table row 0x10 IS already repointed to H's own placed handler
  (consistent with "DF mechanics are native-correct"). The style is
  therefore applied by something OUTSIDE his handler.
- Native applies NEITHER the trailing copies NOR the recolour to
  Huitzil, so the discriminator is per-character somewhere in the
  shared path.

### 14z-69: THE NATIVE LEG EXISTS — and with a rig that ACTUALLY
### enters Dark Force, the symptom reproduces and is measured

Two premises had to be fixed before anything here was worth measuring.

**1. The native leg was never blocked.** 14z-68j recorded "the early-
window id poke does NOT force him on vsav2" from one attempt with
**replay 61**, whose input timing is authored for OUR wheel. The
replay-80 poke flow reaches him natively in six seconds: on `vsav2`,
`$FF8782 = 0x10` across commit->load gives `+0x382 = 0x10`. No vs2
cursor path, no savestate, no Rule 7 question.

**2. DARK FORCE COSTS A BANKED STOCK, AND NOTHING ABOVE HAD ONE.**
Replay 82 — the rig behind every DF measurement in 14z-66/67/68 — runs
with `+0x109 = 0` on BOTH games. With an empty meter the P+K pair is
DOWNGRADED to a single button (`+0x107` = 0xFF/0xFE) and play continues
normally. **`seq 0x0A` is that downgrade, not Dark Force.** Poke stocks
in (`$FF8509`, the documented ES-scripting poke) and the same input
produces something completely different.

**What Dark Force actually is, measured on both games:**
| | native vsav2 | ours (hui11) |
|---|---|---|
| activation seq | 0x16, immediately cleared to 0 | 0x16 settling to **0x18** |
| stocks spent | **2** | **1** |
| fighter fields | `+0x13A/+0x13B`, `+0x1C3/+0x1C7/+0x1C8` | `+0x110/+0x111/+0x17B`, `+0x189` |
| palette row 0x0A | his gold, slightly brightened | **a purple ramp** |
| his own draws | 6-8 | **28-32** (3-4 trailing copies) |

Match-level DF flag: **`RAM:$FF802E`** = 1 for the whole mode, 0 before
and at expiry, identical on both games. Chosen by dumping all of work
RAM at five phases on both games and keeping only bytes with that
shape — 18 qualify. Do NOT infer this flag from the fighter block:
`+0x1F4` and `+0x1B5/+0x1B9` both look like DF flags and are set by
JUMPING (each cost a wrong conclusion this session).

**So the tenant inherits the HOST character's DF TYPE, not merely its
styling.** Native Huitzil's DF does not enter the transform seq 0x18
and spends a different number of stocks; ours takes a transform branch
that brings the afterimages and the recolour with it.

**The activation site is located (FBNeo write tap, `$FF8406`):**
- the seq write `1600` comes from **vs2 `0x0261A6` <-> vj `0x027008`**
  (the DF activation routine's twin pair), with the stock debit
  immediately after (vs2 `0x0261C2` / vj `0x027024`);
- **native then runs `0x025EE0`, which writes the seq back to 0** —
  i.e. vs2 takes a per-character branch that cancels the transform.
  Ours has no such write and stays in 0x18.
So the DF-type selection sits between those sites. That is the next
thing to decode, and it is the same shape as every other per-character
selection here: expect an id-indexed table with variant rows aliasing
base rows, and decode both views before trusting a row.

### 14z-69c: THE MECHANISM, traced end to end

The two engines run DIFFERENT Dark Force systems, and the tenant is
caught between them.

| | vsavj (host engine) | vsav2 (native) |
|---|---|---|
| activation body | `0x027000` | `0x02619E` |
| fields set | `+0x111`, `+0x110`, `+0x176` | `+0x1C3`, `+0x1C8`, `+0x1C4`, `+0x13A`, `+0x13B` |
| stock cost | `subq.b #1,$109(a6)` | `subq.b #2,$109(a6)` |
| per-char byte table | `0x02704E` | `0x02620A` |
| tail calls | `0xD69A / 0x77376 / 0x61588` | `0xBCE6 / 0x82AE2 / 0x6D9D4` |

Both write **seq 0x16** and both read a per-character byte table indexed
by `+0x382` (value -> `+0x189`/`+0x1C7`, and value+0x1E -> `+0x188`/
`+0x1C6`). **Those two tables are byte-identical between the games and
give id 0x10 the same value 4** — so the table is NOT the discriminator.
Read them through the OPCODE view (`04 04 03 04 ...`); the data view is
noise.

**What actually diverges is what happens to seq 0x16 next:**
- **native** clears it back to 0 in the SAME frame (`0x025EE0`), and the
  fighter returns to ordinary states for the rest of the mode — measured
  seq 0x04/0x06/0x14 throughout, no extra draws, palette unchanged;
- **ours** keeps it: the seq-0x16 state is per-char dispatched through
  table **`0xBF31A` (dispatch_16)**, whose row 0x10 our builds repoint to
  H's placed port of vs2's handler. That handler is a `+0x07`-keyed
  sub-state machine which calls **`0x2A7E0`** — the DF effect-channel
  script machine (the `+0x318/+0x320/+0x330` channels decoded in
  14z-68v) — and then drives him to **seq 0x18**, where he stays for the
  whole mode. The channels are what draw the trailing copies; the mode
  is what recolours row 0x0A.

Native has the identical handler at vs2 `0x056D70`-family and NEVER
EXECUTES IT: vs2's activation does not set `+0x111`, and both the
seq-0x16 path and the DF-tick dispatcher (`0xBF61A` / vs2 `0xD97B8`,
guarded on `+0x11F` and `+0x111`) are therefore unreachable in vs2's own
DF. Probe-measured with positive controls: native 0 hits at `0x56D70`,
ours 1 hit at its placed twin `0x0C1780` — and that one hit is at frame
3667, DF EXPIRY, where vs2's handler does exactly what it says
(`moveq #0,d0; move.b d0,$17b/$111/$110/$1b5; rts` — a CANCEL body: vs2
wrote it to switch the vsav-style DF off).

**Legacy is unaffected and this is not "the host's style":** on vanilla
vsavj a legacy character (Victor) in DF shows no recolour and no extra
draws (11 -> 9 -> 11 pal-0x0A draws, palette row constant). The
afterimages come from the ported handler being reachable at all.

### 14z-69e: the mode is SOUND; only the COLOUR is wrong, and it is a
### known class (the sword/statue blink, STATE 14z-33)

> **The general rule this is an instance of (added 14z-71):** bank
> attribution is **per-record and per-list-type**, never per-character.
> The sword/statue blink came from processing records of two different
> banks with one bank's semantics; the Huitzil beam's corrupt strip came
> from a list type that composes its own bank word instead of taking the
> object's. Both render *real art from the wrong place* — geometry
> correct, content someone else's — which is the signature to recognise.
> See "The sprite-list DRAWER" above and `atlas/sprite_lists.md` §4.


**Donovan does not have this problem, with identical wiring** — his
build repoints `dispatch_16` row 0x13 to his placed vs2 handler exactly
as H's repoints row 0x10, and measures clean: palette row 0x0A
unchanged by DF, draws 12-16 against native's 15-18, seq back to
0x04/0x06. The difference is the CONTENT of each character's vs2
DF-form handler: Donovan's is benign, Huitzil's calls the channel
machine and enters the form.

**What Huitzil's form actually is: a FLIGHT/HOVER mode.** Measured
across the mode — native stays grounded at y=40 the whole time; ours
rises to **y=124-133 and moves horizontally** (x 834 -> 937 -> 1000),
holds for the mode's duration, then **descends (y=91 at f3660) and
lands (y=40 at f3670)**, with `+0x110/+0x111/+0x17B` cleared, seq back
to 0x00 idle, the palette restored to his gold, and no residue for the
next 240 frames. Entry costs **one** stock — vsav's cost, not vs2's.
That is a coherent, correctly-terminating mode, and it is almost
certainly Huitzil's ORIGINAL Vampire-Savior Dark Force: vs2 still
carries the per-char code in its tables but replaced the DF system, so
the handler is vestigial THERE and live HERE. Our engine is vsav.

**The purple is a separate, known-class defect.** The recolour is a
palette-SEQUENCE animation, not a static swap: one writer, **engine
`0x02AD68`** (the `0x2AD64`-family uploader), rewrites row 0x0A every
frame from DF entry, cycling **four contiguous rows of the global
palette-seq table at vsavj `0x39ACD0`-`0x39AD4F`**. Their vs2 twins
(mapping `+0x1613C`, i.e. `0x3B0E0C`-) hold a GOLD ramp
(`0111 0fea 0fb8 0e96 0b75 ...`) where vsavj holds PURPLE
(`0222 0fff 0faf 0fcf 0e8f ...`).

**The ids are 0x1E, 0x1F, 0x20, 0x21** — rows vsavj `0x39ACC0`,
`0x39ACE0`, `0x39AD00`, `0x39AD20`; vs2 twins `0x3B0DFC`, `0x3B0E1C`,
`0x3B0E3C`, `0x3B0E5C`. Cross-check that these are the right pairs:
each row's last word is its own frame index (0000/0001/0002/0003) and
matches across the two games. The API that resolves them is
**`0x02AD82`**: `a0 = 0x39A900 + (d0 & 0xFFF) * 0x20`, measured taking
152 calls during one DF with d0 cycling 0x1E-0x21. (NOTE for probes:
`0x02AD68` sits after a `movem.l (a0)+`, so the A0 you see there is the
row start PLUS 0x10.)

**A sibling API takes the source as a POINTER instead** — `0x02ADA6` /
`0x02ADAC` use `movea.l $3A4(a6),a0`. If the channel script can be made
to use that variant, the fix is DATA-ONLY: point `+0x3A4` at privately
placed copies of the four vs2 rows. Measured: H's DF takes the id-based
entry (0x2ADA6 zero hits, 0x2ADAC zero during DF), so this is a
candidate route, not the current one.

**PARKED HERE, and why:** the trigger is not a call we own. There is no
absolute `jsr/jmp` to `0x2AD82` anywhere in vanilla or in the built
image — it is reached through the channel machine's program-byte
dispatch at `0x029F4A` (`move.b (a4),d0; move.w (pc,d0.w),d1; jmp`),
i.e. from ENGINE code driven by H's ported SCRIPT data. So the
legacy-clean intervention is in the script, and that needs the opcode
table decoded first — and it does NOT decode as a flat array of pc-rel
words at one base (best single-base fit: 15/24 targets valid, the rest
odd addresses). Decode that table before designing the fix; do not
guess it.

That is exactly the sword/statue blink of 14z-33: same seq ids,
different global-table contents between engines, and the table is
legacy surface so it cannot simply be edited. **The fix design already
exists there** (STATE, "FIX DESIGN (state_hook precedent)"): wrap the
seq-TRIGGER call inside the PORTED handler — legacy-clean by
construction because the call site is our own code — routing the
tenant's ids to privately placed copies of the vs2 rows (0x80 bytes
here) and leaving every other id on the original path.

**Fix shape — [STALE REFERENCE CORRECTED 14z-109: this decision was made
and IMPLEMENTED long ago (the gate is `tests/test_hui_df_style.sh`); the
paragraph below is the pre-fix design discussion, kept as analysis]:** the
tenant's seq-0x16 row must not run vs2's DF-form machine under vsav's
DF. Candidates: leave `dispatch_16` row 0x10 alone (careful: vanilla
row 0x10 is an ALIAS of row 0x00, i.e. Bulleta's handler, not a null),
or point it at a thunk that reproduces native's "clear the seq"
behaviour. Porting vs2's whole type-A DF is the other end of the scale
and is legacy-hot. Measure the candidate with the gate at
`DF_STYLE_EXPECT=matches`.

Gate: `tests/test_hui_df_style.sh` (replay 85). It refuses to judge
unless BOTH legs are verifiably in DF, and freezes the defect's shape
(`--expect differs`) so it goes red if the symptom changes in either
direction; flip to `--expect matches` when the fix lands.

Open observations queued from the same replay, unattributed: ~15px X
drift over the DF walk (speed modifier vs recoil) and a pod anim phase
difference at the f3250 sample.

## The child companion's shadow — SOLVED (14z-69o)

The reported symptom was "the human child sidekick's shadow is a
rectangle, all the time". **The 14z-68g diagnosis had it backwards** and
that is the lesson worth keeping.

14z-68g measured, correctly, that our shadow BAND pieces carry
`code = native - 0x16A8` with bank word 0 instead of 3, and concluded
the band was the defect and the core ("both games draw 0F8B/0F8C/0F8B")
was fine. Comparing the ART at those addresses inverts it:

| piece | native | ours | art |
|---|---|---|---|
| core | `0x30F8B` bank 3 | `0x40F8B` group C bank 4 | **all zeros — EMPTY** |
| band | `0x30F96` bank 3 | `0x0F8EE` bank 0 | byte-identical to native |

The band is CORRECT: those are shared system tiles that exist in the
stock set at `native - 0x216A8` in full address space, and the vanilla
engine path draws them from there. The uniform delta was the sign of a
consistent mapping, not of corruption — **a uniform delta means
arithmetic, not garbage; check the ART before calling it wrong.**

The core is the defect: the tenant gfx remap rewrites codes in
`[0xAF6, 0x4EFC]` from bank 3 to bank 4 (`remap_spec.json`), and
`0x0F8B`/`0x0F8C` fall inside that window — so the bank was rewritten,
but the tiles were never COPIED into group C, because
`tools/obj_records.py`'s pointer walk never reaches the records that
reference them (the documented "record walks that follow POINTERS miss
offset-computed records" trap). Bank rewritten + tile absent = a solid
empty rectangle.

**Fix (14z-69o):** a per-tenant `build/manifest/extra_tiles/<char>.json`
merged into the copy inventory by `build_donovan.sh`. Two tiles for
Huitzil. Program bytes unchanged — the build fingerprint is identical to
hui12's, which is itself the evidence that this is gfx-only.

**How to find these in general, cheaply:** decode every group-C sprite a
build draws over a replay and flag any whose tile is all-zero. Over
replay 82 that returned exactly these two and nothing else, so the
inventory hole was provably this size. Re-run it for any new tenant —
it is a complete check, not a sample.

## The 214+P grenade explosion — FIXED 14z-70f (it WAS a tile-inventory
## defect; the 14z-69q triage below is RETRACTED)

> **Read this before the triage that follows.** The header used to say
> "NOT a tile-inventory defect". It was one: **569 group-C tiles were
> remapped bank 3 -> 4 and never copied**, and the ground detonation drew
> a solid fuchsia rectangle. The triage was not sloppy, it was
> MIS-RIGGED — every rig fired 214+**MP** from 2P start distance, where
> the bomb reaches the opponent, so the capture showed the ON-CONTACT
> explosion and never the ground mushroom. Reproduce only with
> `tests/replays/hui/83d_hui_grenade_ground.rpl` (214+**LP**, both
> fighters walked to their corners). The empty-tile audit also sampled
> every 25 frames and saw 10 of 113. Both instruments are fixed; the
> reasoning below is kept because the *elimination* steps are still
> valid, only the conclusion was wrong.

The original triage, superseded. It is
NOT the shadow class: scanning every group-C sprite the build draws
across the 214MP window of replay 83 (f3390-3555) returns **zero**
empty-tile draws, so nothing is missing from the copy inventory.

What it IS: at explosion onset (**f3395** and **f3430** in replay 83)
the pieces draw with **pal 05 / 06 / 08 out of BANK 0 — stock group A/B
art**, while everything of his around them comes from group C bank 4/5.
That is the documented "pieces created through a path that leaves
`+0x18` unset" class (14z-67), the same root as the beam/lightning
work. It belongs to the effect-family arc and cannot be fixed from the
gfx side.

Rig for whoever picks it up: `tests/replays/hui/83_hui_fx.rpl` does a
clean 236LP then a 214MP at f3380 (arcing projectile -> ground
explosion). Dump OBJ over f3390-3560 and compare bank words against a
native leg — the poke flow reaches him on vsav2 unchanged.

### 14z-70: the explosion's tiles LOCATED — vs2 common-bank art that was
### never ported, drawn against vsav's unrelated art at the same indices

**READ THIS FIRST — replay 83 is NOT cross-leg comparable.** It is a
1P-vs-CPU script (`sys=C1`, `sys=S1`, no C2/S2), and the two games pick a
DIFFERENT CPU opponent and a DIFFERENT stage: at f3436 native is on the
village stage against one character and ours is on a different stage
against Felicia, with no explosion on screen at all. Any "ours draws
tiles native never draws" conclusion from a frame-matched sprite diff on
this replay is measuring two different matches. One was computed this
session (101 our codes vs native's, zero overlap) and DISCARDED. Identify
the effect on ONE leg by position and timing, or author a 2P replay.

**What the native leg alone shows.** The explosion is a large orange
flame pillar (snapshot f3436, right of screen). Locating it by screen
position rather than by palette guesswork gives a compact cluster:

```
native f3436, flame region x 210-320 y 30-190:
  pal 06, BANK 0, codes 4a2f 4a4d 4a70 4a76 4a96 4aa0
  across the whole window: pal 06 bank 0, ~95 codes in 0x48EA-0x4C56
```

So the explosion is drawn from **vs2's BANK 0 — its shared/common effect
art**, not from H's own character band (bank 3 native / bank 4 ours).
That is why the port misses it: the tenant gfx work moves his BAND, and
this art is not in it.

**The tiles are genuinely absent from our set.** Comparing vs2 against
the stock vsav gfx at those same indices (`tools/gfx_tiles.py`, group A):
**14 of 14 sampled tiles DIFFER, and none is blank.** Rendered sheets at
0x4A00 confirm it by eye — vs2 holds soft organic flame/smoke texture
there, vsav holds unrelated sharp-edged art.

**This is a DIFFERENT class from the child-shadow defect, and that is why
`audit_empty_tiles.sh` is silent on it:**

| | shadow (14z-69o) | explosion (this) |
|---|---|---|
| code | remapped to bank 4 | NOT remapped — stays bank 0 |
| tile present? | no — empty group C slot | yes, but it is vsav's OWN art |
| renders as | solid rectangle | a wrong, plausible-looking picture |
| empty-tile audit | catches it | cannot see it |

A complete-inventory empty-tile check can only find art that resolves to
nothing. Wrong-but-present art needs a source comparison, which is what
the table above is.

**Consequence for the fix:** these tiles must be COPIED into group C
(they are vs2 content absent from our set) *and* the emitter's codes
remapped to that bank — copying alone leaves the codes pointing at
vsav's art, and remapping alone would point at empty group C slots (the
shadow failure mode). Both halves, or neither.

### 14z-70b: measured again on a COMPARABLE rig — the effect runs
### correctly and only the tile CODES are wrong, by exactly +0xA220

`tests/replays/hui/83c_hui_grenade_2p.rpl` is the 2P twin of replay 83,
authored because 83 is unusable for this (see the warning above). BOTH
sides are poked — P1 = H (0x10), P2 = Victor (0x03 on vsav and vsav2) —
so the two legs run the same match on the same stage. They do: snapshots
show Phobos vs Victor on the subway stage on both, native with a large
orange flame pillar and ours with a small yellow burst.

**The effect object is running correctly.** Position-matched across the
window, the two legs agree frame for frame:

```
f3432  native  n=13  x 273-401  y 57-201
f3432  ours    n=13  x 273-401  y 57-201
```
Same sprite counts, same screen positions, same palette (06), same bank
(0). For comparison, in the same dump `pal 0a` (98 vs 91 codes) and
`pal 0c` (42 vs 42) carry IDENTICAL code ranges correctly remapped bank
3 -> bank 4, so the band machinery is fine; this effect is the exception.

**Only the codes differ, and by a constant.** Ours = native **+ 0xA220**:

```
native 49EE -> ours EC0E     4A0E -> EC2E
native 49EF -> ours EC0F     4A2A -> EC4A
41 of 88 native codes appear in ours at +0xA220 (the rest are
animation-phase — the legs sample different steps of the animation)
```
Beware: pairing these two legs by SPRITE INDEX or by position alone
gives noise, because the animation is about one step out of phase. The
constant only appears once you test `native_code + D in ours_codes` as
sets. An index-paired delta histogram shows a smear of 0xA1C0-0xA262 and
looks like "no constant" — it was read that way once this session.

**And the art at the shifted index is mostly wrong**, which is the
symptom: of the 41 matched codes, **9 have identical art and 32 differ**
(none blank). So ours draws vsav's own effect page at native+0xA220 —
right shape of thing, wrong picture, and never an empty tile, which is
why `audit_empty_tiles.sh` is correctly silent.

**Where +0xA220 does NOT come from — checked, so do not re-check.**
`build/manifest/effect_tail.json` carries exactly one reloc delta,
`+0x47` (x70), and no `place` target in 0xEC00-0xEF00. It is not the
effect_tail map.

**Prior art that the fix must be reconciled with (14z-67, huitzil.toml
~line 753).** For the `x2b7ef4` companion-effect records the designed
mechanism on a delta-0 group-C tenant is `c5_mode`: keep every tile word
NATIVE (skip the bmap rewrite), emit the referenced codes as
`effect_c5.json` so the art is placed at native codes in group C bank 5,
and flip the ported piece spawners' bank setters `#$2000 -> #$3000`.
This explosion is NOT going through that path — it draws bank 0 with
non-native codes, i.e. neither half applies to it.

### 14z-70c: a REAL latent defect in `x088512` — fixed and shipped — but
### it is NOT the explosion's root. Claim RETRACTED, see 14z-70d below.

Chased the emitter down the chain, and it lands on the defect class this
project has now paid for three times.

**The chain, measured on the 83c rig.** The vanilla sprite emitter at
`PRG:0x01B2BC` (`move.w (A0)+,D2` / `(A0)+,D3`, with `or.w 0x18(A6),D1`
folding in the bank word — this is also the authoritative proof that
`+0x18` IS the bank field) draws the pieces for the object at
`RAM:$FFB980`, reading its list from **`0x288C78` — a VSAVJ address**.
The list start `0x288C6E` is fetched at `PRG:0x01AFAE` from the vsavj
table at `0x283C10`.

**Everything ported is correct — that is what makes this diagnosable.**
- the object's `+0x1C` is written on BOTH legs at the same frames from
  exact twins: ours `PC:0x0D7A6E` / `A0=0x40223C`, native `PC:0x08B170`
  / `A0=0x2BA120`, mapping through the `x088512 -> 0x0D4E10` and
  `x2b7ef4 -> 0x400010` deltas;
- that selection table is byte-perfect (16/16 entries relocated);
- the placed `x2b7ef4` is 2054/2060 intra-region pointers correctly
  relocated (the 6 exceptions are word-misaligned false positives);
- the ported list IS present and IS referenced correctly — ours
  `0x400760`/`0x400848 -> 0x40557A` mirrors native `0x2B8644`/`0x2B872C
  -> 0x2BD45E`.

Native, meanwhile, NEVER reads `0x2B8644` in the window (its only
watch hit is the frame-1 arming artefact). So ours is not "using the
host's table where native uses the ported one" — ours is arriving at a
host address that native never visits at all.

**Why: three pc-relative tables resolve past the end of their region.**
`tools/verify_pcrel_data.py build/hui14` reports **72 checked, 72
BROKEN**, and three of them are the effect machine's own:

```
x088512 src 088512-08c052   placed 0d4e10-0d8950   (len 0x3B40)
  lea 08c014 -> table 08c08a   past the region end by 0x38
  lea 08c026 -> table 08c09a   past the region end by 0x48
  lea 08c038 -> table 08c0a2   past the region end by 0x50
```
The `lea`s are INSIDE the region; their targets are not. The
displacement is copied verbatim, so each resolves to `target + delta` =
`0x0D8988` / `0x0D8998` / `0x0D89A0` — which is **inside the anim region
placed at `0x0D8950`**. The machine reads animation bytes as its
parameter tables, and a garbage parameter is exactly how an object ends
up pointed at an unrelated vsavj sprite list.

**This is the x06cac0 defect again** (14z-69h/i/j): a region extracted
shorter than the tables its own code references, because `fixed_len` is
a CAP and `oracle_extend` stops where the sibling stops agreeing. The
fix mechanism already exists and is proven — root spec `:f<off>` force-
length with the forced tail EMITTED RAW (CPS-2 decrypts opcode fetches
only, so a data read returns stored bytes), landed for x06cac0 in
14z-69j and green there.

**Recipe, not yet executed.** Force `x088512` long enough to contain the
furthest table (starts at +0x3B90 against a declared 0x3B40, so the
length must cover 0x3B90 + that table's extent) and split code/data at
the FIRST table, `0x08C08A`. Per 14z-69h the split must be checked by
disassembly rather than assumed, and landing `:f` ALONE changes shipped
bytes — it must arrive with the raw-emit. Then rebuild and re-run the H
gates plus the legacy masked-v2 basis.

Also still unchased: `pal 10` and `pal 11` bank-0 sprites sit in the
same screen region and may belong to the same effect.

### 14z-70d: the fix was BUILT and it does NOT fix the explosion — the
### causal claim above is RETRACTED

Executed the recipe. `build/hui15` (**699de9b7**): root
`0x88512:0x3b98:s:f0x3b78`, plus a small `extract_char.py` change so a
SOURCE-ONLY (`:s`) root honours `f<off>` at all — the `:s` branch
returns early and never set `raw_from`, while the generator already
reads it per region. Extract log confirms: *"x088512: raw DATA tail from
+0x3b78 (0x20 bytes emitted unencrypted for runtime DATA reads)"*.

**The repair is real.** `verify_pcrel_data.py` drops from 72 BROKEN to
69, with all three `x088512` rows gone — the tables now sit inside the
region and resolve to themselves.

**And it changes the explosion not at all.** Measured, not eyeballed:

```
native pal06/bank0 codes : 88
hui14 : 84   shared with native 0   at +0xA220: 41
hui15 : 84   shared with native 0   at +0xA220: 41
hui15 code set == hui14 code set : True
```
Byte-for-byte the same sprite codes, and the snapshot at f3430 is
unchanged. **Why: the code that reads those tables never runs.** An
execution breakpoint at the placed twin `PRG:0x0D8912` (= `0x08C014` +
the `x088512 -> 0x0D4E10` delta) over the whole replay fires **zero**
times (the single logged line is the frame-1 arming artefact).

**The error, named so it is not repeated: co-location is not
causation.** The reasoning was "the effect machine lives in `x088512`;
`x088512` has three tables resolving into the anim region; therefore
those tables feed the effect machine." Every clause was true and the
conclusion still did not follow — the tables are on a path this
scenario never enters. **Before attributing a symptom to a broken
table, put an execution breakpoint on the code that READS it.** That is
one cheap run, and it would have preceded a whole rebuild here. Same
family as this session's other two: measuring something real, then
assuming it was the thing in front of us.

**Status of the change: KEPT, and gates green.** It repairs a genuine
latent defect of the class the project has already ratified a fix for
(x06cac0, 14z-69j), it is behaviourally inert today, and it is proven
safe: `test_m3a_reproducible.sh` PASS (both frozen references rebuild
bit-exact, so the shared-tool edit is inert on Donovan) and
`test_hui_boot.sh` PASS with legacy **masked-v2 EXACT**. It is a latent
repair with no observable effect — worth keeping for the same reason the
x06cac0 one was, but it buys no visible change and should not be
described as fixing anything a player can see.

### 14z-70g: the BEAM — the object is never CREATED, and the creator is
### a vs2-only effect handler that was never ported

Anchor method, one link at a time, both legs, replay 83b (maintainer-
confirmed rig: 236LP, 2P distance; LP/MP/HP look identical, 236+2P is the
girthier ES beam, 236+K is the low beam).

The pool is documented already — `docs/project/tables/reconciliation.md`
`$FFD400/0x80/cat14`, and "GEOMETRIES ARE IDENTICAL in both games,
pool-for-pool", which is what makes the address comparable across legs:

| | native | ours |
|---|---|---|
| beam sprite-list reads | 2 (f3165/3167, `PC:0x019E0E`, `A6=$FFD400`) | 0 |
| anim-pointer writes f3160-3210 | 26 (`PC:0x01378A`) | **0** |
| pool-slot HEADER writes f3150-3210 | 30 (`PC:0x0934B4`) | **0** |

**The beam object is never created.** That also explains the symptom
shape the maintainer confirmed: the FREEZE WORKS (hit logic, elsewhere)
while the muzzle orb and the beam are both missing — they are one object
that never exists.

**The creator is vs2-only code.** `PC:0x0934B4` is the state-0 body of an
effect-object state machine:

```
09349A clr.b 0x38(A6) / 09349E moveq #0,D0 / 0934A0 move.b 0x03(A6),D0  <- sub-state
0934A4 move.w (0x06,pc,D0.w),D1 / 0934A8 jmp (0x02,pc,D1.w)             <- state table 0934AC
0934B0 clr.b 0x01(A6) / 0934B4 move.b 0x382(A4),D0 ; cmp.b 0x0A(A6),D0  <- the id gate
```

Counting that id-gate signature across the images:

```
vs2 (native)   : 4 sites  0x8FAD2 0x91562 0x934B4 0x937BA
vsavj pristine : 2 sites  0x813A8 0x82CD0
our build      : 2 sites  (unchanged)
```
vs2 added two of these machines for the newcomer effects, and **0x0934B4
is outside EVERY ported root** (the nearest, `0x0905AE+0x300`, ends at
0x0908AE). All four sites sit ~0xC after a state-dispatch `jmp`, i.e.
each is the state-0 body of its own machine; none is reached by an
absolute pointer, so entry is a computed dispatch.

**This is a sibling of the 14z-67 effect-zone clone, not a duplicate of
it.** That work cloned the OTHER machine (`x06cac0`, the row-8 /
sustained-beam family) and ported the effect byte-map rows so ids
0x4E-0x53 stop collapsing to index 0. This machine at `0x093xxx` was
never in scope.

**Fix shape (NOT yet executed, and it is a design decision):** port the
vs2-only handler as a new root and route the tenant's effect objects into
it via the owner-gated `site_thunk` pattern the other machines already
use. Open first: which TWO of the four vs2 sites are the newcomer ones
(pair them against vsavj's two through the R1 map — raw addresses do not
transfer), and each machine's extent.

### THE ANCHOR METHOD — how to attribute any "this effect does not draw"
### (14z-70, maintainer-endorsed; use this FIRST)

Do not start from object layout, pool slots, or which region the machine
lives in. Start from the **data the effect is forced to read**, and let
the registers hand you the object:

1. Find the effect's **sprite list** in the reference set (the art is
   usually already located, or a before/during OBJ diff names the tiles).
2. Put a READ watchpoint on it on the NATIVE leg. The hit gives you the
   emitter PC and, in the address registers, the object drawing it
   (`A6`), its owner (`A4`), and the OBJ RAM target (`A2`).
3. Put the same watchpoint on the PORTED twin address on our leg.
4. Walk one link back at a time — sprite list -> anim node -> the object
   field that holds it -> whoever writes that field -> whoever creates
   the object — measuring each link on BOTH legs.

Why it beats reasoning about layout: **it is self-correcting**. If the
anchor is never read on our leg, that IS the finding, and it is
unambiguous — no assumption about which slot or which pool was involved
can contaminate it. It found the explosion's emitter (`PC:0x01B2BC`,
object `$FFB980`) and the beam's (`PC:0x019E0E`, object `$FFD400`) in one
run each, after two sessions of layout reasoning produced only retracted
claims.

Two rules that go with it: cross-leg register/PC comparisons are only
valid where a KNOWN mapping exists (region delta, or the R1 map — raw PCs
do not transfer), and before attributing a symptom to any code, put an
execution breakpoint on that code and confirm it runs.

### 14z-70e: THE EXPLOSION IS NOT BROKEN. Everything above about "wrong
### art" is RETRACTED — it was an index-join error and a phase offset

Maintainer proposal: diff the screen before vs during the explosion, take
the tiles that appear, and search BOTH games for that CONTENT. Doing the
content join instead of an index join overturns the whole entry.

**1. Native's explosion tiles are already in our build.** Hashing all 88
and searching our entire gfx (groups A/B from the patched vsav.zip, C
from vsw): **87 of 88 present**, 84 in group A, 3 in group B.

**2. The mapping is a PERMUTATION, not a constant** — `0x0EC0E` holds
vs2 `0x495F`'s art, NOT `0x49EE`'s. So **+0xA220 was a statistical
artefact**: two dense ~85-value clusters of similar width offset by
~0xA220 will overlap about half the time by construction (41/88 "hits").
It described nothing. Any "constant delta" between two dense code sets
must be confirmed by CONTENT before it is believed.

**3. Ours draws the RIGHT tiles.** Window-level content join over the
explosion:
```
native 88 contents   ours 84 contents
IDENTICAL CONTENT drawn by both: 76      native-only 12   ours-only 8
ours drawing BLANK tiles: 0
```
Per-FRAME the intersection is 0 at every frame, which is what sent this
whole entry wrong — the legs are ~2-4 frames out of phase (ours has 0
explosion sprites at f3426 where native has 7), so a per-frame set
intersection reads as total disagreement while the window agrees 76/84.

**4. And it LOOKS right.** Snapshots at the SAME frame f3440: native and
ours both show the large flame pillar, same shape, same white-blue base
with orange top, same position. The earlier "native has a flame pillar,
ours has a small yellow burst" was f3430 versus f3430 across a ~10-frame
phase lag — ours reaches the same pose at f3440.

**Where the false alarm came from.** 14z-69q's triage ("pieces draw pal
05/06/08 out of BANK 0, the +0x18-unset class") was measured on replay
83 — the 1P-vs-CPU rig where our leg has Felicia point-blank and the
projectile never travels. It characterised sprites that were not the
explosion. The original maintainer report (ping #7, the fuchsia class)
predates the 14z-67 effect work and was most likely fixed there.

**Status: the 214+P explosion is believed CORRECT and needs a playtest to
close.** Residuals, both unexplained and neither necessarily a defect:
the ~10-frame phase lag, and 8 ours-only / 12 native-only contents (part
of which is sampling — the dump is every 2 frames). If the maintainer
confirms, remove it from the effect-family worklist; the BEAM remains
genuinely open and is a separate defect (never walks its anim nodes).

**Method, promoted:** to identify what an effect draws, diff the OBJ list
before vs during, then join the two legs by TILE CONTENT — never by tile
index, and never per-frame across legs that can drift in phase.

## The beam / effect family — CLOSED 14z-71, all four members
## (history kept below)

> **All four are closed, and NO TWO SHARED A CAUSE.** The family was
> grouped in 14z-69 as "one root — one port covers it". That was RIGHT for
> three of the four, and the exception is the interesting part:
> the **214 explosion** was an uncopied tile inventory; the **beam** and
> the **ES big beam** were a stub effect-class row + a missing sprite-list
> type + a per-game code bias; and the **grab lightning** shares the
> beam's first cause — the dead effect-class row 16 (maintainer A/B:
> hui17 none, hui18 yes, and hui18 differs by exactly that repoint). So
> three of the four DID share a root; only the explosion stood apart.
> Grouping by SYMPTOM
> ("this effect does not draw") sent the search after a single root that
> did not exist.

> **RESOLVED.** The beam draws, maintainer-confirmed on all three
> variants (`build/hui25`). It was never an emission defect. Three
> stacked causes, all in the sprite-list layer:
> **(1)** vsav ships effect-class table row 16 as a stub where vs2/vh2
> carry the beam's handler — the object selected class 16 correctly and
> was dispatched into an `rts`;
> **(2)** the beam's sprite list is TYPE 12, a composite vsav's drawer
> does not have, and its table can neither grow nor move;
> **(3)** the beam's middle piece is a procedural type-4 strip whose
> handler biases tile codes by a **game-specific constant** (vsav
> +0x3800, vs2 +0x4200) and **composes its own gfx bank**.
> The mechanism is documented in "The sprite-list DRAWER" above and
> `atlas/sprite_lists.md`; the porting recipe is
> `../project/porting_sprite_lists.md`.
>
> The 14z-69j state below is KEPT because its eliminations are sound and
> they are what narrowed the search — but every "open" item in it is
> closed, and its framing ("EMISSION is the open one") is wrong.

### The 14z-69j state, superseded

Where the arc stands, measured on replay 83b against native vsav2.

**Native's beam, so you can recognise it:** pal-0x0C sprites in H's own
band at `a19=3xxxx` — codes 0x1DF4/0x1DB4 at the muzzle (f3164-3172),
then 0x1E2F/0x1E42/0x1E52/0x1E5F marching x=0x95..0xEF (f3178-3208) —
plus the long stretch segments `code=4EC0` at `a19=14ec0`, sz 4x1/6x1/
16x1, at y=0x2074. The window is **f3164-f3208** with a ~12-frame
cadence, 3-13 pieces per hit frame. Sample THERE; outside it native
draws none either (a blind sample reads as "native has no beam").

**What is now native-equivalent** (scratch build with `tenant_type_stamp`
+ `obj_hook_extra` + `piece_prebake` un-parked, on top of the shipped
table fix):
- the object is CREATED — our stamp writes type `0x7C02` at f3179 where
  native writes `0x0802` at f3177 (tap on the pool's type word);
- it is routed to the PORTED machine (type >= 114 by construction);
- the machine's seven pc-relative param tables now read byte-identical
  to vs2 (14z-69j raw-emit);
- its record pointer is the PLACED twin at **native's own relative
  offset**: ours `0x40064C` = placed base `0x400010` + 0x63C, native
  `0x2B8530` = `0x2B7EF4` + 0x63C;
- owner (`+0x30` = 0x8800, the victim) and bank word (`+0x18`) match;
- **the whole object is 118/128 bytes identical to native's.**
- the fleet pieces are created too: `type<-080C` fifteen times on both
  (native pc 0x6D218 / ours its placed twin 0x0D4648).

**And it still emits ZERO sprites.** Chased further (14z-69k):

**The beam object is NOT the emitter** — that was an assumption, and it
is now refuted. Its record chain resolves to sprite codes 0x48xx, not
the beam codes. Attribution by killing a pool slot does NOT work: the
object respawns within 3 frames (poke `+0x00` to 0 at f3174 -> the slot
is clear at f3175 and fully back at f3178), so all four kills leave the
beam untouched. Attribute by RECORD CHAIN instead.

**The beam art is ported and correct.** The sprite lists are at vs2
`0x2621D6` / `0x26233A`, inside the `anim` region (src 0x245872, delta
-0x16CF22): ours' `0x0F5418` is byte-identical, and `0x0F52B4` differs
only in one correctly relocated pointer (+0xB61C0, the aux0_1 delta).
They are referenced from anim nodes at `0x24FCFA`-family and
`0x251CDA`-family — so the beam is drawn by an ANIM SEQUENCE, not by a
piece the machine spawns.

**All four pool objects now correspond 1:1 to native's, at native's own
relative record offsets** (beam +0x63C, companion +0x1E4, 0x77 +0x222C).
CAUTION when reading these dumps: the slot ORDER differs between the
games and an object's type byte changes frame to frame — compare the
same object across the same frame, or you will "find" differences that
are phase (this cost a wrong read in-session).

**Traced further (14z-69m), and where it now stands.** The "become the
emitter" sequence is IDENTICAL on both games: at **f2364** slot FFB800's
type word takes `0x7500`, at **f2365** its sub-state takes `08` then
`06`, from twin PCs (native `0x8ACE6` / `0x8A6CA` / `0x8A6DE` <-> ours
the placed `0x0D75E4` / `0x0D6FC8` / `0x0D6FDC`), with A6 = P1 on both
and a single probe hit each at f2363. Between f2365 and f3170 NEITHER
game writes that type word again.

Yet by f3162 native has one 0x75 object at FFB800 with sub-state **06**,
and ours appeared to have one at FFB900 with sub-state **02**. THAT
APPEARANCE WAS AN ARTEFACT — see immediately below before using it.

**BOTH LEADS ABOVE ARE DEAD — the clean re-measure killed them
(14z-69n). This is the useful part of the entry.**

1. The `FFB802 <- 0000` at f2363 from `pc=0x0FB2F8` is **ours' own
   documented slot-clearing alloc wrapper** (`0x0FB2E0`, "0x80 cleared,
   +8 preserved" — the 14z-65 allocator-wrapper family) zeroing a
   freshly allocated slot; `0x0FB2F8` is its `clr.l (a0)+` loop. Native
   has no such write because native's allocator does not clear, which is
   exactly why the wrapper exists. Benign.
2. **The sub-state difference does not exist.** Measured on ONE build in
   ONE run with tap and dumps together (hui18, FBNeo): slot FFB800 takes
   `0x7500` at f2364, sub-state `08` then `06` at f2365, and still reads
   **`type=7506`** at f3162 and f3186 — native's shape exactly.

The earlier "native 7506, ours 7502" came from comparing MAME frame
dumps against FBNeo taps **by frame number**. The emulators traverse
identical states at slightly different frame indices — the very fact §4
dual-emulator agreement rests on — so f3162 is not the same moment in
both, and neither is a slot's occupancy. **Never cross-reference a MAME
dump and an FBNeo tap by frame index: measure both legs in one
emulator, or anchor on an event rather than a frame number.**

So the beam residual is UNATTRIBUTED again — but the eliminations are
real and hold: not the tables, not the records, not the art, not object
creation, not the beam object (its chain resolves to 0x48xx codes), and
not the pod's sub-state. The honest next step is to find which object
walks the `0x24FCFA` / `0x251CDA` anim nodes that carry the beam lists —
measured in ONE emulator, both legs, anchored on an event.
(Also noted, and subject to the SAME caveat since it came from the same
cross-emulator comparison: the beam object's `+0x44` — Y velocity, which
the mover integrates into `+0x14` — read `ffff8000` native vs `0000a000`
ours while the other 118/128 bytes matched. Re-measure it in one
emulator before treating it as a difference.)

Regression state of that scratch build: pairs, ex, grab, air all PASS —
**including the Dark Force crash that parked `tenant_type_stamp` in
14z-68d, which is GONE** (it was a vec3 from an index underflowing the
placed region, consistent with the machine having walked the garbage
param streams the table fix repaired).

The three thunks stay PARKED in the tree: they buy no visible change
until emission is solved, and nobody has playtested them.

### 14z-70: the anim nodes are NEVER WALKED on our build, and the
### selection mechanism is now named

The step named above was taken. Measured in ONE emulator (MAME), both
legs, replay `83b_hui_ray_2p` with the standard early-window pokes,
`trace_writes.lua` read-watch, 3,230 frames each.

**1. The nodes themselves are correctly ported — a further elimination.**
`anim` places vs2 `0x245872` at `PRG:0x0D8950`, delta **-0x16CF22**
(atlas fragment). Both node families are structurally identical to
native and *every* differing byte is a 3-byte pointer relocated by
exactly that delta — 11/11 correct, verified statically:

```
vs2 0x24FCFA -> ours 0x0E2DD8      vs2 0x251CDA -> ours 0x0E4DB8
vs2 0x2621D6 -> ours 0x0F52B4      vs2 0x26233A -> ours 0x0F5418   (the known-good pair)
```

**2. Native walks them; we never do.**

| leg | watch | reads in 3,230 frames |
|---|---|---|
| native vsav2 | `0x24FCFA,2,r` | **2** (f3165, f3167 — inside the documented f3164-3208 window) |
| ours (hui14) | `0x0E2DD8,2,r` | **0** |

(A `frame 1 PC 000926` line with all registers zero appears on BOTH
legs — that is the watchpoint-arming artefact, not a hit. Count hits
only after it.)

So the residual is NOT a draw flag and NOT the emitter's output stage:
**nothing in our build ever points an object at the beam animation.**

**3. The mechanism, decoded from the walker.** At the native hit the
accessing instruction is `movea.l 4(A0),A0` at `PRG:0x0199D8`; MAME
reports `CURPC` as the FOLLOWING instruction (`0x0199DC`, `move.w
(A0)+,D0`), so read the PC as "the instruction after the access":

```
0199D4  movea.l 0x1C(A6),A0     ; A6 = the animating object
0199D8  movea.l 4(A0),A0        ; <-- the access: node+4 = sprite-list ptr
0199DC  move.w  (A0)+,D0        ; CURPC as logged
```
Confirmed by the registers: `[A6+0x1C] = 0x24FCF6`, and `4(A0)` there
holds `0x002621C8` — exactly the logged `A0`.

So **object field `+0x1C` is the running anim-sequence pointer**. The
setter (vs2 `PRG:0x01378A`) advances it 8 bytes per step, 37 times
across the window, as `A0 = base 0x24EDD4 + D0` — exact on every row
(`D0` 0x0F12, 0x0F1A, 0x0F22 …). The sequence is entered by SELECTING
that base+offset, which is why no absolute pointer to `0x24FCFA` exists
in either image: the tight-window scan finds exactly one reference, an
internal loop-back (`0x24FCE2 -> 0x24FC22`), itself correctly ported in
ours (`0x0E2DC0 -> 0x0E2D00`).

**4. Suggestive, NOT yet a finding.** At the fixed address `$FFD400`
ours' `+0x1C` is last written at f2365 (to `0x0F72E4`, a placed-region
address) and never advances again, while native writes it 37 times in
the window. This compares a fixed RAM ADDRESS across legs, which is the
documented slot-order trap above — the object must be identified by
TYPE before this counts. Do not promote it without that.

**Method note, paid for this session: a PC logged on one leg does not
name the same routine on the other — and SOME of them coincide anyway,
which is what makes it dangerous.** The native leg is vsav2 and ours is
vsavj-based: two different builds of the engine, which is the whole
reason `tools/reconcile_batch.py` exists. In this one run:

```
0x000926 1/1   0x000D36 2/2   0x000D3C 2/2   0x000DDC 1/1   <- identical, counts and all
0x01378A 37 native / 0 ours       0x015668 8 native <-> 0x016F56 8 ours
```

Four low addresses match exactly while the routine actually under
investigation does not. So the rule is NOT "PCs never correspond" — it
is that the matching ones invite you to assume the rest match too.
Correspondence comes from the R1 map or a known region delta, never
from an address looking familiar. Leg-independent counts (did it
happen, how often) always transfer. Different axis from the
frame-index trap, same bite.

**NEXT:** identify the animating object by TYPE on both legs (not by
slot address), then find what selects base `0x24EDD4` + offset for it.
That selection is the defect.

## The companion / pod object family (14z-65, generalised 14z-67 on Pyron)

The newcomers' satellites (Donovan's Anita, Huitzil's pods, Pyron's
satellite) are all secondary objects of the SHARED zone `x088512`, and
they are the reason a new tenant inherits a long list of manifest rows
that have nothing to do with that character.

- **Types**: pods/companions are secondary types **0x73-0x77**
  (struct: `+0x02` type, `+0x03` owner id). The newcomer-satellite
  HANDLER family is types **64-75** — 12 regions that looked like "H's
  farm zones" until Pyron's first satellite spawn tripped type 64's
  tripwire and proved they are SHARED newcomer handlers.
- **Records**: companion-effect records live in `x2b7ef4`, placed as a
  region; consumers resolve `base + word_offset` and some index
  NEGATIVELY relative to the base (see the WIDE note below).
- **Art**: for delta-0 group-C tenants the generator keeps companion
  record bank-1 words NATIVE (`c5` mode, `effect_c5.json`) and flips
  the ported spawners' bank setters `#$2000 -> #$3000` so the art
  serves from group C bank 5 at native codes.

### THE INHERITANCE RULE (the expensive lesson, paid twice)
**A tenant that ports a SHARED region inherits every region-scoped
mechanism row that region carries — copy them ALL, up front.** Pyron's
first chaos soak crashed three separate ways and every fix was a row
Huitzil already carried for the same zones: the `x088512` pod-table
`data_in_code` reroute, the queue class-7 remap, both `obj_hook` union
sites, the `x026142`/`x05c800` escape pads plus twin rows, and the
satellite handler roots. The rows are properties of the SHARED SOURCE
BYTES, not of the tenant. Diff the other tenants' manifests for every
row scoped to a region you are pulling in, BEFORE the first probe run.

### Placement hazards specific to this family
- **`data_in_code`**: the pod zone embeds data tables in code. Placed
  in the crypt hole they are stored re-encrypted, so runtime DATA
  reads see garbage while opcode fetches decode fine. This class has
  bitten FIVE times. **Known tooling gap (14z-68):** both the census
  and the relocator only recognise the
  `lea (d16,pc),An + read (An,Xn.w)` shape and MISS the
  post-increment reader `move.w (An)+`, so a region can report clean
  and still carry a live embedded table. RAW placement does not fix
  it either — raw storage holds one image (the opcode view, so it
  executes), so data reads still see the wrong bytes.
- **Negative indexing vs the WIDE extension**: these consumers index
  their record base with SIGNED offsets that go BELOW it (measured
  -13). Allocated at the very start of `wide_ext` (0x400010) a
  negative index reaches the RESERVED CpsFrg window `$400000-$40000F`,
  which the two emulators read DIFFERENTLY. Leave headroom below any
  region whose consumers index negatively.

## THE LEAPING PURSUIT ATTACK (measured 14z-104, maintainer-confirmed mechanic)

vsav retains Night Warriors' pursuit: with the opponent knocked down,
U + any single P/K leaps onto them (ES variant on two buttons, meter).
Measured on the merged build's legacy pairings (= vanilla by the
superset invariant), rig `tests/replays/judge/03_down_attack.rpl`:

- **Input window:** the command REGISTERS during the victim's knockdown
  FALL and the first frames of lying flat; a later input during the
  flat period is ignored (a sweep victim lies only ~20-45 frames — the
  window is genuinely brief, as players know it).
- **Button-independent:** U1/U2/U4/U6 produce the identical leap
  (seq 0x0E) — the strength choice is cosmetic for the standard
  pursuit, per the universal-command design.
- **Aim is captured at INPUT time:** the leap targets the victim's
  position when the command registered, not at landing (measured with
  a mid-flight victim-position poke: the arc still aimed at the
  pre-poke spot).
- **Per-character arcs** (tenants run their PORTED vs2 content):
  Demitri 33-34f to y=100; Donovan 27f to y=102; Phobos 42f to y=88;
  Pyron 39f to y=88.
- **Corner behavior:** a pursuit at a cornered victim peaks directly
  over the body, then the wall pushbox shoves the attacker off during
  the descent and the strike lands beside them — measured on the
  all-legacy control, i.e. vanilla behavior, not a port artifact.
- **The connect race:** with a sweep or throw knockdown, the victim's
  auto-wake and the pursuit's flight time run neck-and-neck (a Victor
  dummy woke at ~+22-45f; every rig geometry tried landed 1-10 frames
  late or beside the body). Connecting cleanly likely needs a longer
  knockdown than these rigs produce — carried as the pursuit-connect
  refinement in docs/project/coverage_matrix.md.

Gate: `tests/audit_pursuit_leap.sh` (leap fires per tenant both
directions + the no-knockdown discriminator).

## CPU exceptions and the soft-reset path (14z-109)

**Atlas rows this section depends on:** `ram.md` `$FF0000.w` (exception
code), `$FF0018-$FF0053` (saved registers), `$FF0054.l` (saved SP).

The game installs REAL handlers on every 68k exception vector (`vec2` bus
error through `vec11` line-F; handler ladder at `PRG:0xC0-0x14E`). Each
handler:

1. writes its identity to `RAM:$FF0000.w` (`move.w #vector-2, $FF0000.l` —
   0 bus, 1 address, 2 illegal, ...),
2. pops the group-0 extra frame words where present, saves SP to
   `$FF0054`, re-points SP at `$FF0054` and pushes `movem.l d0-a6` (so
   D0..A6 land ASCENDING at `$FF0018-$FF0053`),
3. branches to a common restart that reboots the GAME — the abbreviated
   white-on-black check list ("WORK RAM OK / CPS0..2 RAM OK / OBJECT RAM
   OK / Q SOUND RAM OK") and then the name screen. NOT the gold full RAM
   test: that is the cold/watchdog path.

**Why it matters for diagnosis:** on hardware with no debugger, the reboot
STYLE is the first instrument — *name screen = the game caught a CPU
exception; gold full test = cold/watchdog reset* (the pre-D5 decryption
boot loop was the second kind; the 14z-109 Donovan crash was the first,
confirmed by the field video). And `$FF0000` plus the register block are a
free post-mortem — with the caveat recorded in the atlas that a frozen
(guarded/debugged) machine never runs the handler, so under the crash
guard the registers must be read live (`GUARD_PROBE`), not from RAM.

## The object-script state dispatcher at `PRG:0x018508` (14z-109)

**Atlas rows this section depends on:** `ram.md` `$FF8400`/`$FF8800`
(player blocks); `character_tables.md` (per-character data blocks).

A per-object script walker whose per-node state transition is:

```
01843A  move.b (0x17,A3),D0      ; A3 = the current DATA NODE; its +0x17
01843E  add.w  D0,D0             ;   byte is the next-state INDEX, doubled
...
018508  move.w (6,PC,D0.w),D1    ; offset table at 0x018510
01850C  jmp    (2,PC,D1.w)       ; -> 0x018510 + offset
```

The offset table holds **80 entries** (`0x018510 + 80*2 = 0x0185B0`; valid
indices `0x00-0x4F`), aliasing onto ~0x17 distinct handlers
(`0x018694-0x01877c`; several write follow-up states into `(0x54,A1)`).
**CORRECTED 14z-110: this section originally said "~0x26 states", conflating
the ~0x26 distinct HANDLERS with the 80-entry TABLE. The crash is a TABLE
overrun, so the table size is what matters.** This is one of THREE sibling
dispatchers that read `(0x17,A3)` — see "The SUB-STATE DISPATCHER FAMILY at
0x018460": `0x018460`/`0x018508`/`0x0185D2`, all 80-entry, reached by
guard-chain fall-through. **vs2's twin tables (`0x016D34`/`0x016DE4`/
`0x016EB6`) have 84 entries** — so the RENUMBER GAP is exactly `0x50-0x53`:
valid in vs2, out of range in vsavj. **There is NO bounds check on the node
byte.** An index past the table reads whatever words follow; the first odd
fetched "offset" faults the `jmp` with a vec3 address error, which the
exception path above converts into a clean name-screen reboot — i.e. a
data-side bad byte presents as a "flaky reset" with zero corruption
beforehand. (#99 = node `0x3FB899` in Donovan's block carries vs2 state
`0x51`; census tool `tools/audit_fsm_census.py`.)

Interaction shape worth knowing: the walker runs with A1 = one fighter's
OBJECT and A3 = a node that can live in the OPPONENT'S data block
(measured: P2-Phobos's object walking a node inside Donovan's block — the
same cross-fighter shape as the 14z-73 grab-victim keyframes). So a bad
node in character X's data is triggered by X's OPPONENT, whoever that is.
