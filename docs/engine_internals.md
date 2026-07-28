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
