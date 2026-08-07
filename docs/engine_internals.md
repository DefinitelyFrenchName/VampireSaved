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
  **CORRECTED 14z-61 (docs/atlas/select_screen.md, measured):** that
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
(tests/lib/m2a_common.sh M2A_MASK + docs/atlas/ram.md; pending
maintainer ratification, STATE 14z-49b).

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

### The 14z-51 id-space result (docs/m5/keyons_*.json)

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

- Per-char pointer tables: vsavj `0xBF41A`, vs2 `0xD95B8` (20 rows,
  4-byte pointers; row = char id). Record entries are 8 bytes:
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
