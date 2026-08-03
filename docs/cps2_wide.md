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
| B2 | the bit-12 promote line under `Cps2Wide` | pending |
| B3 | PRG 4 -> 6 MB | pending (A1 says linear is inert) |
| B4 | canary: real content relocated into the new space | pending |
| B5/B5b | MAME parity / suite preservation | pending |

Both invariants are enforced on every run:
1. **Emulator superset invariant** — the patched binary running STOCK
   vsavj is bit-identical to a pre-patch reference binary
   (`FBNEO_REF=...`; build one with `WIDE=0 tools/setup_fbneo.sh`). The
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
| PRG 4 → 6 MB | **zero lines** (A1) | descriptor |
| 19-bit tile address (bit-12 promote) | ~2 conditional lines, `cps_obj.cpp:429-434`, gated on a new `Cps2Wide` flag | **core, profile-gated** |
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
