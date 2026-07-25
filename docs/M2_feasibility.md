# M2 feasibility — Donovan into vsavj by replacing Jedah (slot 0x0F)

Analysis 2026-07-25, before implementation. Governs M2 scope and sequencing.

## The three data domains

Donovan's data splits across three ROM domains with very different
difficulty:

### 1. Program-ROM behavior data (code, hitbox, anim, params) — FEASIBLE

- All of Donovan's behavior lives in the 4MB **program ROM**: code handlers
  in the encrypted zone (`~0x05Axxx`), hitbox/param blocks (`0x05xxxx`),
  and animation data appended high (`0x22xxxx-0x28xxxx` in vsav2).
- **vsavj has ~337KB of free program-ROM space**: a 258KB `0xFF` hole at
  `PRG:0x0BF69A-0x100000` and 78KB at `PRG:0x3EC718-0x400000`. This is
  precisely the space vsav2 fills with its extra characters — vsavj leaves
  it as padding. Room to relocate Donovan's blocks.
- **Key enabler:** CPS2 encryption only affects *opcode* fetches. Donovan's
  DATA (hitbox/anim/params, read as data) can be written **raw** anywhere,
  including inside the encrypted address zone. Only his CODE (opcode-fetched
  handlers) must be re-encrypted with vsavj's key at its placement address.
- Bank tables hold **absolute** pointers, so blocks may be relocated freely
  by repointing vsavj's slot-0x0F entries across the ~25 bank tables.
- Caveat: Donovan's code may contain absolute JSR/JMP/data pointers into
  vsav2's address layout that need relocation, and may call vsav2 engine
  subroutines that live at different addresses (or don't exist) in vsavj —
  this is the R1 engine-delta surface, exactly what M2 exists to find.

### 2. Sprite tiles (GFX ROM) — THE HARD WALL (R2, concrete)

- Donovan's sprites are tiles in the **32MB GFX ROM**, referenced by 16-bit
  OBJ tile codes in his anim/sprite sub-tables. Those codes index vsav2's
  tile layout.
- vsavj's GFX ROM is full of its own 15 characters' tiles; Donovan's tiles
  are absent. Under M2's "no ROM expansion," they would have to overwrite
  **Jedah's** tiles, and the 16-bit codes in Donovan's data would need
  remapping from vsav2's layout to the Jedah tile range in vsavj.
- This is R2 made real. It is the genuinely hard part of M2 and may show
  that correct graphics require the GFX-region expansion planned for M3 —
  in which case M2 proves *behavior* on trusted tooling (its stated
  purpose: surface R1) and graphics correctness moves to M3.

### 3. QSound samples — deferred (M5 domain)

- Donovan's voice/SFX are QSound samples in the QSound ROM. Same "overwrite
  Jedah" constraint. Sound is explicitly an M5 concern; for M2 the character
  can run with wrong/placeholder audio.

## M2 sequencing (revised, honest)

M2's SPEC purpose is to **surface the engine delta (R1) early on trusted
tooling** and let findings decide the reconciliation approach. Graphics
perfection is not the point of M2; proving the behavior port is.

- **M2a — behavior proof of life:** inject Donovan's program-ROM behavior
  data into vsavj's free space, repoint slot 0x0F, re-encrypt his code.
  Get the slot selectable, the match running, his moves/hitboxes/timing
  executing. Placeholder graphics acceptable (point sprite refs at Jedah's
  tiles or accept garbled output). Deliverable: selectable, crash-free,
  behavior observable; **R1 reconciliation findings logged.**
- **M2b — graphics:** tile porting + 16-bit code remapping into Jedah's GFX
  range. If this proves infeasible without expansion, that is itself the
  key finding that pulls M3 forward — documented, not forced.
- Throughout: **legacy (non-Jedah) replays must stay bit-identical** — the
  superset invariant. The patch tooling's null round-trip guards this.

## Immediate next steps

1. Patch tooling (`tools/patch_prg.py`): inject blobs + repoint bank slots +
   re-encrypt code, operating on the decrypted image, splicing back to
   program files. Null round-trip = bit-identical vsavj (test gate).
2. Precise extraction of Donovan's program-ROM blocks from vsav2 (the
   transitive closure from slot-0x13 bank entries).
3. M2a injection + selectable test.
