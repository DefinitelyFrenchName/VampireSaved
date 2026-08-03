# CPS-2 WIDE — extended hardware profile (v1 DRAFT, awaiting ratification)

Vampire Savior with all 18 characters does not fit a stock CPS-2. One
character costs ~338 KiB of program ROM and ~16-18K tiles; the stock free
space is ~1 KiB of PRG and ~370 tiles. WIDE is the named, versioned
hardware profile that makes the roster physically possible, implemented
identically by every emulator target.

**Status: DRAFT.** Sizes below are the maintainer-approved intent
(round 66); Phase A measurements are complete and recorded. Ratification
happens after Phase B proves the profile inert.

## The profile

```
CPS-2 WIDE v1
  PRG    : 6 MB    CPU $000000-$5FFFFF  ($000000-$0FFFFF encrypted, rest raw)
                   reserved, never allocate: $400000-$40000F (CpsFrg regs)
  GFX    : 48 MB   12 uniform 4 MB members (3 groups of 4)
                   19-bit tile address via the CPS-2 Turbo rule (see below)
  QSOUND : 16 MB   4 uniform 4 MB members
  Z80    : unchanged (256 KB; ~27 KB free measured, not a constraint)
  Everything else: bit-identical stock CPS-2
```

Rules that are not negotiable, because the loaders depend on them:
- GFX members come in groups of **4** and must all be the **same size**
  (`cps.cpp` consumes 4 at a time; `nGfxMaxSize` mis-sizes otherwise).
- QSound length must stay a **power of two** (`rom_mask = nCpsQSamLen - 1`).
- Stock members are never resized or reordered — new capacity is appended,
  so all legacy provenance stays trivially valid.

## Phase A measurements (2026-08-03, vanilla vsavj, full legacy corpus)

Instrument: `tests/audit_wide_phase_a.sh` (rerunnable; ground-truths itself
before trusting any null result).

| # | Question | Result | Consequence |
|---|---|---|---|
| A1 | Does vanilla ever read the candidate extension windows? | **Zero reads** across the corpus (control window saw 252,705 work-RAM reads, so the probe is not blind) | PRG growth to 6 MB is **linear and costs ZERO FBNeo core lines** — `SekMapMemory(CpsRom, 0, nCpsRomLen-1)` already covers it. The `$A00000` fallback window is not needed. |
| A2 | Is a 19th tile-address bit available in the OBJ y-word? | **bit 12 never set** on a live sprite | 19-bit addressing is available — but NOT the way first planned (see correction below). |
| A3 | Does any legacy scroll3 code rely on the 32 MB address wrap? | **No real code ≥ 0xC000** (max real code 0x0; only the 0xFFFF blank sentinel occupies high values) | Growing the gfx region does not move any legacy scroll3 address. B1's pixel gate remains the definitive confirmation. |
| A4 | Is there room in the Z80 driver for new sample-table rows? | **27,727 B free**, largest run 13,961 B | Z80 is not a constraint; QSound growth is not bottlenecked here. |

### Correction A2 — the 19th bit is bit 12, not bit 15

The first draft proposed widening the OBJ tile-address mask from `0x6000`
to `0xE000`, i.e. using y-word **bit 15**. That is wrong and would have
broken sprite rendering outright:

> **y-word bit 15 is the CPS-2 sprite-list TERMINATOR.**
> `CpsObjGet`: `if (ps[1] & 0x8000) break;   // end of sprite list`

Setting it on a sprite ends the list, dropping every later sprite.

Capcom hit the same wall on CPS-2 Turbo and solved it by **promoting bit
12** into the address after the terminator check:

```c
if (ps[1] & 0x1000) ps[1] |= 0x8000;      // bit 12 -> bit 15
n |= (ps[1] & 0xe000) << 3;               // 19 bits
```

WIDE adopts exactly that rule, so the extension follows real Capcom
hardware precedent rather than inventing an encoding. A2 confirms vanilla
vsav never sets bit 12 on a live sprite, so the bit is free.

Practical consequence: the game side may need **no code change at all** —
the bank bits are data (per-char OBJ bank table `PRG:0x282D4` plus a few
`move.w #$X000` setters), so a bank value carrying bit 12 flows through
existing tables.

## Phase B progress (proving the profile inert, one variable per build)

Gate: `tests/test_wide_profile.sh` — both invariants over the 12-replay
legacy corpus, 24 comparisons per run.

| Step | What grew | Result |
|---|---|---|
| **B0** | QSound 8 -> 16 MB (2 appended 4 MB members) | **PASS** — 24/24 bit-identical, zero core lines |
| **B1** | GFX 32 -> 48 MB (4 appended 4 MB members, one whole group) | **PASS** — 24/24 bit-identical; A3's prediction held |
| **B2** | the bit-12 promote line under `Cps2Wide` | **PASS** — 24/24 bit-identical incl. framebuffer |
| **B3** | PRG 4 -> 6 MB (4 appended 512KB members) | **PASS** — 24/24 bit-identical; A1's zero-core-lines prediction held |
| B4 | canary: content fetched from the new banks | **ATTEMPT 2 = CLEAN FAIL.** Address composition proven correct; the bytes fetched are not group C's. Narrowed to the loader/placement — see below |
| B5/B5b | MAME parity / suite preservation | pending |

**The gate compares work RAM AND the framebuffer.** That second half was
added at B2 and is not garnish: the FBNeo harness historically ran with
`pBurnDraw = NULL`, so it never rendered a pixel and the RAM checksum is
structurally blind to the entire video path. A rendering change — exactly
what the 19-bit tile address is — produces byte-identical RAM logs whether
it works perfectly or draws garbage. Enable with `FBNEO_HVIDEO=<path>`.

**Inertness is not functionality.** B2 proves the 19-bit path is HARMLESS
(vanilla never sets bit 12, so nothing changes). Proving it actually
REACHES the new banks is B4's job, and B4 must include that positive
control — a build where a legacy tile is moved into group C with bit 12
set and is observed to render from there.

Both invariants are enforced on every run:
1. **Emulator superset invariant** — the patched binary running STOCK
   vsavj is bit-identical to a pre-patch reference binary
   (`FBNEO_REF=...`; build one with `WIDE=0 tools/setup_fbneo.sh`, from the
   SAME tree state so it differs ONLY by the profile patch). The
   gate exits 2 and says so loudly if no reference is supplied — an unrun
   invariant must never read as green.
2. **Profile inertness** — the WIDE set is bit-identical to the stock set
   on the same binary.

Build the overlay with `tools/build_wide_romset.py <romdir> <outdir>
--qsound 2 --gfx 4` (symlinks the reference zips, writes one clone zip;
ROMDIR is never modified).

## Emulator change budget (measured, not estimated)

| Change | FBNeo | Class |
|---|---|---|
| QSound 8 → 16 MB | descriptor only (**B0 verified**) | descriptor |
| GFX 32 → 48 MB (4 appended members) | descriptor only (**B1 verified**) | descriptor |
| PRG 4 → 6 MB | **zero lines** (A1; **B3 verified**) | descriptor |
| 19-bit tile address (bit-12 promote) | one condition widened at `cps_obj.cpp:429-434` + flag definition/extern/init/reset, gated on `Cps2Wide` (**B2 verified**) | **core, profile-gated** |
| New driver entry carrying the profile | new `BurnRomInfo` + `BurnDriver` beside `VsavjRomDesc[]` | descriptor |

So the entire profile costs **one gated conditional** in emulation logic.
Everything else is table data.

## Governance (Rule 1 v2)

Emulator changes are permitted only inside this profile, and each must be:
bounded and declarative; **profile-gated** (a driver flag set by a new
driver entry, so stock vsavj and every other CPS-2 game are untouched by
construction); subject to the **emulator superset invariant** — the
patched binary running stock unmodified vsavj must reproduce the frozen
vanilla expectations bit-for-bit, enforced as a battery gate; mirrored in
a second emulator where practical; and ratified per profile version.

## Where the profile stands

Declared and proven inert: **PRG 6 MB, GFX 48 MB, QSound 16 MB** — the
full v1 shape. Total emulator cost so far: **one widened condition** in
`cps_obj.cpp` plus the flag's definition/extern/init/reset. Everything
else is descriptor table data.

What is NOT yet proven: that the new space is *usable*. Every growth step
so far is zero-filled, and the 19-bit path is only shown to be harmless
(vanilla never sets bit 12). **B4 must supply the positive control** —
relocate an existing character's anim block into the PRG extension and
move a legacy tile into gfx group C with bit 12 set, both against
bit-exact vanilla oracles. Until B4, treat the extension as declared, not
demonstrated.

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

### Attempt 2 (emulator-side canary) — a clean, single-variable FAIL

Implemented as designed: `CPS2_WIDE_CANARY=1` relocates bank-2/3 sprites
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

**Next step (one measurement, not a guess):** dump `CpsGfx` around byte
`0x29B6500` at runtime and compare against the expected 128-byte tile
from group B at `0x19B6500`. If they differ, the loader placed the data
elsewhere and the fix is in the load map, not the address path. A gfx-RAM
dump is a small harness addition and is on the B5b instrument list
anyway.

### The canary design (kept — it worked as a diagnostic)

Change the EMULATOR, not the ROM, so game state is identical by
construction and only pixels can move:

1. Build group C as a byte copy of group B (already scripted).
2. Add a TEST-ONLY flag (env-gated, never part of the shipped profile)
   that ORs `0x1000` into the y-word of sprites whose bank field reads
   bank 2/3, at the same point the promote happens in `cps_obj.cpp`.
3. Run the stock ROM. Work RAM MUST be bit-identical (guaranteed — no ROM
   change), and the framebuffer MUST be bit-identical too, because banks
   4/5 now hold the same tiles as banks 2/3.

Pixel-identical output then proves exactly one thing and nothing else:
the 19-bit address path plus group C placement/loading are correct. A
difference localises to the emulator with no game-side ambiguity.

The PRG half of B4 (relocating real code/data above 4MB) is unaffected by
this and can proceed independently — but note the same discipline: pick a
relocation whose only observable is "the data was read", e.g. copy a data
block into the extension and repoint one pointer, and require
bit-identical RAM.

## Known limits, stated up front

- **MiSTer**: ~70 MB of ROM is out of reach for 32 MB configurations. WIDE
  v1 is a desktop-emulation profile; a MiSTer-shaped variant would need
  the per-slot exclusivity work to pull GFX back toward 32 MB.
- **Netplay**: FBNeo is the primary target because it is the GGPO rollback
  reference platform. A custom build means peers need the same binary and
  the same set — release notes must say so.
- **MAME**: cannot follow any descriptor change as a Homebrew binary; a
  pinned source build is a Phase B prerequisite. If MAME cannot follow,
  the suite migrates to FBNeo *before* MAME is set aside — no path reduces
  total test coverage.
