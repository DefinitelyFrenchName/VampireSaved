# engine_internals — how the engine works, by subsystem

The synthesis document (CLAUDE.md taxonomy): what a stranger reads to
understand the game. Started session 14 with the gfx subsystem; other
subsystems (object system, anim, sound farm, dispatch banks) are still
scattered across docs/atlas/character_tables.md, docs/tables/
reconciliation.md and patch_notes — fold them in as they get touched.

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
