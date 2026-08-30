# CPS-2 WIDE — HISTORY (blocks moved verbatim from `cps2_wide.md`)

Moved at 14z-122 by the documentation rationalization pass. Historical
entries are not rewritten; corrections live in `cps2_wide.md`. These are
the B4 bring-up narratives: attempt 1 (the two-variable canary and what it
did establish) and the diagnostic path that found the descriptor-CRC root
cause. The REUSABLE artifacts stayed in the live file: the canary DESIGN,
the B4 results, and the gotcha ("the canary romset is NOT the shippable
romset") they produced. No `**[PFX-N]**` anchor lives in this file.

*(moved from `cps2_wide.md` at 14z-122)*

---

## B4 attempt 1 — invalid canary, and what it did establish (14z-56)

The first canary made group C a byte copy of group B, remapped 15
characters' bank rows from banks 2/3 to WIDE banks 4/5, and required
pixel-identical output. It failed on both RAM and pixels from ~frame 894.

**The failure is uninterpretable, because the edit moved two variables.**
The per-char bank word is not display-only: the same modified program
diverges in work RAM at frame 890 under MAME, which has no extended-bank
support at all. So "game behaves differently" fully accounts for the
result and says nothing about the emulator's 19-bit path.

What the attempt DID establish, both useful:
- **The game emits the WIDE encoding correctly.** A y-word census of the
  modified program (`tests/lua/objy_bits.lua` under MAME) shows
  `bit12=1` with the bank field shifted exactly as designed
  (banks 2/3 -> bit-12 + banks 0/1). Nothing in the game strips it.
- **The per-char bank word carries game logic**, now documented in
  engine_internals + GOTCHAS.

### The diagnostic path that got there (for reuse)

Attempt 2 as designed: `CPS2_WIDE_CANARY=1` relocates bank-2/3 sprites
into WIDE banks 4/5 at draw time, with gfx group C loaded as a byte copy
of group B, running the STOCK rom. Result:

- **work RAM bit-identical** (guaranteed — the ROM is untouched), so the
  canary is genuinely single-variable this time;
- **pixels differ** on ~4,400 frames.

Narrowed, with measurements:

| Checked | Result |
|---|---|
| Region actually sized? | **Yes** — emulator reports `68K 0x00600000`, `Graphics 0x03000000`, `QSound 0x01000000`. All three growths are real. |
| Group C members loaded? | **Yes** — `Loading graphics (vsw.31m/33m/35m/37m)... (OK)`. |
| Address composition? | **Correct.** Instrumented: `y=0xb065` → `n=0x0536CA` → byte `0x29B6500`. That is bank 5 at exactly the same offset within group C (`0x9B6500`) that the source tile occupies within group B. |
| Fetch guard? | Passes: `nCpsGfxMask=0x03ffffff`, `nCpsGfxLen=0x03000000`, address below the limit. |
| Does group C CONTENT matter? | **No** — a zero-filled group C and a copy-of-group-B group C render *identically*. The bytes being fetched are not the ones we placed. |

So everything from the sprite record to the pointer arithmetic is right,
and the region is real and loaded, yet the data at that pointer is not
what the loader was given. **The remaining suspect is the loader's
placement/interleave for a third group** (`Cps2LoadTiles` /
`Cps2LoadOne`, `CpsGfxLoad` advancement) — i.e. group C's bytes are
landing somewhere other than 32MB, or in a different interleave.

**That measurement is what cracked it:** a gfx-buffer dump
(`FBNEO_HGFX=<hexoff>-<hexend>`, added to the harness) showed the whole
32-48MB range reading 0xFF while groups A/B held data. Since the tile
decoder ORs into a zero-filled buffer, 0xFF could only mean the source
bytes were 0xFF — i.e. the member never arrived. From there the CRC
mismatch was two minutes away.

