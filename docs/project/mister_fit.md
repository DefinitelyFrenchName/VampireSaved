# MiSTer fit — what merged-m6 actually needs vs what jtcps2 offers

Measured 14z-106 (2026-08-22) on `build/m3b_merged13` (merged-m6,
fingerprint `64426955`) and the pristine `vsav.zip` in `$ROMDIR`. Every
figure names its instrument; re-run them before quoting. The platform
facts (bus widths, tiers) are in `docs/platform/mister.md`.

## 1. Program ROM (68k)

Instrument: a non-0xFF run scan of `vsw.41-44` in `vsavjw.zip` (python,
256-byte gap merge; STATE 14z-106 (3)), cross-checked against
`build/m3b_merged13/gen.log` (`wide_ext 0x4D1100/0x600000`).

| member | range | live bytes | content |
|---|---|---|---|
| `vsw.41` | `0x400000-0x47FFFF` | `0x7FFF0` | wide_ext from `0x400010` (the `$400000-$40000F` CpsFrg reservation honoured) |
| `vsw.42` | `0x480000-0x4FFFFF` | `0x402F4` in 28 runs, last byte **`0x4D10F3`** | the rest of the tenants' relocated code/data |
| `vsw.43` | `0x500000-0x57FFFF` | 0 | 0xFF fill |
| `vsw.44` | `0x580000-0x5FFFFF` | **30 bytes at `0x5FFF00-0x5FFF1D`** | the facing-alias thunk (`@0x5FFF00`, HANDOFF donovan-m4 row) — a FIXED-ADDRESS pin, not allocator output |

**So the image needs 4 MB + `0xD10F4` = 4.82 MB of program space, and ONE
30-byte block is pinned at the top of the declared 6 MB.** Against jtcps2's
`main_rom_addr[20:0]` = 4 MB cap the deficit is **`0xD10F4` = 836 KB**
(consistent with the 14z-85 "D+H alone overflow by ~310 KB"). Whatever
tier is chosen, the `0x5FFF00` pin should move down to sit under the
chosen ceiling (a manifest address, not an engine fact — check the thunk
for absolute self-references first).

## 2. QSound samples

Instrument: trailing-fill scan of `vsw.21m` / `vsw.22m` (8 MB extension).

- `vsw.21m`: content ends at **`0xE57F0` (918 KB)**, the rest 0x00 fill
  (the M5 voice batch, 841 KB packed + the pilot rows). `vsw.22m`: empty.
- Stock sample space is 8 MB = 128 banks of 64 KB; the extension starts at
  bank 0x80. The live content occupies **banks 0x80-0x8E (15 banks)** —
  ALL of it in the jtcps15 aliasing class (`qsnd_addr[22:16] <= dsp_ab[6:0]`
  keeps 7 bits, so bank 0x8N plays as 0x0N and MIS-PLAYS legacy audio).
- Fit: 918 KB against the 8 MB extension the width fix unlocks — no
  pressure; the fix is the ~4-line RTL change named in mister.md and it
  is REQUIRED (not optional) for any MiSTer build carrying M5 voices.

## 3. GFX tiles — the decisive number

Instruments: `tests/audit_gfx_merged_census.sh` (as-built group-C write
set of the merged build, PASS, `build/gfx_census_14z106.log`) and a
per-bank BLANK census of pristine `vsav.zip` using `tools/gfx_tiles.py`
(`load_simms` + `tile_bytes` + `BLANK`, STATE 14z-106 (3)).

**What the roster needs (group C = the WIDE banks 4/5, 16 MB of members):**

| bank | live codes | bytes |
|---|---|---|
| 4 (the three fighter bands, effects, strips) | **45,737** / 65,536 (69.8%) | 5.59 MB |
| 5 (select/wheel art incl. the M6 glyphs) | **6,610** / 65,536 (10.1%) | 0.81 MB |
| total | 52,347 codes | **6.39 MB** |

**What vanilla's own 32 MB could spare (BLANK tiles = all-00 or all-FF):**

| stock bank | blank tiles | bytes |
|---|---|---|
| group A bank 0 | 418 | 0.05 MB |
| group A bank 1 | 2,917 (= the 14z-62e figure, method cross-checked) | 0.36 MB |
| group B bank 0 | 51 | 0.01 MB |
| group B bank 1 | 642 | 0.08 MB |
| total | **4,028** | **0.49 MB** |

And blank is only the UPPER bound — a blank tile may still be referenced
as transparent filler (the 14z-62e exclusivity caveat), so the usable
figure is smaller still.

**Conclusion: the roster's art is 13x larger than every blank tile in
vanilla put together.** The "fit tenant art inside the stock 32 MB" option
is not a trade-off to present — it is impossible without overwriting
legacy art, which the superset invariant forbids. There is no
tenant-dropping variant either: the smallest single band (Pyron, 14,037
codes = 1.7 MB) is 3.5x the blank total on its own. **A MiSTer build of
this roster REQUIRES a GFX tier wider than 32 MB** — i.e. the maintainer's
128 MB module plus the width change through jtframe + the core.

## 4. Z80

`vsw.z01`/`z02` = 2 × 128 KB, the stock geometry (vm3.01/02 are 2 × 128
KB). No growth.

## 5. The profile that follows (for the maintainer's ruling)

With GFX forced onto a wider tier, the question is only HOW wide, and the
numbers say "the minimum that holds merged-m6 with headroom":

| region | stock jtcps2 | merged-m6 needs | proposal |
|---|---|---|---|
| 68k PRG | 4 MB (bus `[20:0]`) | 4.82 MB (+ a relocatable 30-B pin) | **6 MB** as WIDE v1 (bus +1 bit = 8 MB addressable; 6 MB loaded) — keeps the FBNeo/MAME profile identical, no re-layout of the image |
| GFX | 32 MB (2 × 16 MB banks, `[22:0]` words) | 32 MB stock + 6.39 MB group C (16 MB of members as shipped) | **48 MB** as WIDE v1 (bank bus +1 bit): banks 2/3 stay stock, group C lands in a third 16 MB window — again the SAME member set the emulators load |
| QSound | 8 MB (23-bit path, 7-bit latch) | 8 MB + 0.9 MB | **16 MB** as WIDE v1 = the 14z-86 width fix |
| Z80 | 256 KB | 256 KB | unchanged |
| SDRAM total | 64 MB (LARGE) | ~70 MB + work RAM/VRAM | **128 MB tier** (`SDRAMW` 23 → 24, bank/prog/ioctl ports +1 bit; the HPS side already carries `ioctl_addr[26:0]`) |

**Recommendation: WIDE v1 verbatim on MiSTer** — one profile, one
romset, one release artifact for all three implementations, and the
MiSTer-specific work is purely WIDTH (no content re-layout, no per-slot
exclusivity, no second manifest). The alternative "MiSTer-shaped" profile
(squeeze to the 64 MB tier) is ruled out by section 3 for GFX and would
only have saved the PRG and QSound widenings, which are the smallest of
the three. What this costs: the SDRAM tier change is FRAMEWORK surgery
(jtframe's `SDRAMW`/`AW` plumbing + the MiSTer target's download path),
to be done profile-gated in the fork and sized in the next slice — it is
the one part of the arc that is not a descriptor.

Gameplay-visible consequence: none — every character and every byte of
art ships exactly as on FBNeo/MAME. That is why this can be a
recommendation rather than a roster decision.
