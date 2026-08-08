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
(tests/lib/m2a_common.sh M2A_MASK + docs/game/atlas/ram.md; pending
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

### 3. Win QUOTE — the same big record table, with a `-4` BIAS
Fetch helper vsavj `0x5F328`: `movea.l #$2672AA,a0; andi.w #$ff,d0;
lsl.w #2,d0; lea -4(a0,d0.w),a0`. The caller sets `d0 = 0x60 + id`
(P1) or `0x80 + id` (P2).
**Because of the `-4`, the entry actually read is index `0x60+id-1`**,
i.e. array base `0x2672AA + 4*0x5F = 0x267426` (P1) and
`0x2674A6` (P2) indexed by id. Repointing the naive `0x60+id` row
changes nothing and looks like "the record is right but the text is
wrong" (14z-68m). vs2's twin table is `0x2A05E2` (bases `0x2A075E` /
`0x2A07DE`); Huitzil's records are `0x2A5F36` (P1) / `0x2A6346` (P2).
NOTE the same table serves the SELECT portrait at base `0x26742A`
indexed by id WITHOUT the bias — the arrays OVERLAP (`0x26742A` row
0x10 IS `0x2672AA` row 0x70), which is exactly what makes it easy to
repoint the wrong entry.

**Scope warning (14z-68p/r): the quote is a THREE-LEVEL data
structure, not a repoint.** Levels measured:
1. the table entry -> a quote record (12-byte header, then 4-byte
   entries whose low 3 bytes are a ROM address);
2. those addresses point into `0x1BADxx` (vs2) / `0x1BB2xx` (vsavj) —
   per-line entries, themselves holding 3-byte addresses;
3. which reference glyph data at `0x1C4Cxx`.
So porting a tenant's quote means carrying levels 2 and 3 as well (or
re-encoding the glyphs against the host font). Mechanical but not
small, and purely cosmetic — defer behind visible defects.
CONFIRMED 14z-68r: on a tenant build the quote renders the HOST's line
(Huitzil on Bulleta's row 0x10 shows her child-voice quote), because
the `-4`-biased entry is the one the drawer reads and it is still
vanilla.

### Per-tenant win-screen checklist
1. `[[code_word]]` x2 — position x/y (slot-following, CODE rows).
2. `[[win_pal_variant]]` — palette; pick the row from the OPCODE view
   of `0x6B2F2` and CONFIRM with the 5*row marker.
3. Quote records at the `-4`-biased bases `0x267426` / `0x2674A6`.
4. Snapshot the actual screen and compare against a native capture —
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

## Dark Force (14z-66/67 — MECHANICS UNPROVEN, STYLE measured 14z-69)

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

Gate: `tests/test_hui_df_style.sh` (replay 85). It refuses to judge
unless BOTH legs are verifiably in DF, and freezes the defect's shape
(`--expect differs`) so it goes red if the symptom changes in either
direction; flip to `--expect matches` when the fix lands.

Open observations queued from the same replay, unattributed: ~15px X
drift over the DF walk (speed modifier vs recoil) and a pod anim phase
difference at the f3250 sample.

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
