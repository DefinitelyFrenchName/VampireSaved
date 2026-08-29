# MiSTer fit — what merged-m6 actually needs vs what jtcps2 offers

Measured 14z-106 (2026-08-22) on `build/m3b_merged13` (merged-m6,
fingerprint `64426955`) and the pristine `vsav.zip` in `$ROMDIR`. Every
figure names its instrument; re-run them before quoting. The platform
facts (bus widths, tiers) are in `docs/platform/mister.md`.
**[MSV-1]** **Provenance note, 14z-113:** the current freeze is merged-m9
(`build/m3b_merged16`, fingerprint `32007911`) and `build/m3b_merged13` was
deleted in the 14z-112 build-dir sweep. The ceilings this document feeds
into the placement — group-C `0xEE73` / `0xFFDB`, QSound live `0x8E57F0`,
PRG live `0x5FFF1E` — are RE-DERIVED from the current build on every run of
`tests/audit_mister_map_fit.sh` (`MAP_FIT_BUILD`, default = the CURRENT merged build, `build/m3b_merged20` since 14z-117b, re-pointed at every freeze — this line said `m3b_merged16` until 14z-118)
and have not moved. §1's wide_ext HIGH-WATER MARK `0x4D10F3` is NOT
gate-frozen and is merged-m6's: merged-m9 shifted the extension by
+0x10D0/+0x1ED0/+0x2B60 (STATE 14z-111), so quote that figure with its
freeze.

> **This file measures DEMAND — what the roster needs, region by region.**
> What that demand implies, in causal order, is
> `docs/project/mister_core.md`; where it lands in SDRAM is
> `docs/project/mister_map.md`. Where the synthesis and this file disagree,
> this file wins: it is the measurement.

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

**[MSV-2]** **Conclusion: the roster's art is 13x larger than every blank tile in
vanilla put together.** The "fit tenant art inside the stock 32 MB" option
is not a trade-off to present — it is impossible without overwriting
legacy art, which the superset invariant forbids. There is no
tenant-dropping variant either: the smallest single band (Pyron, 14,037
codes = 1.7 MB) is 3.5x the blank total on its own. **A MiSTer build of
this roster REQUIRES a GFX tier wider than 32 MB** — ~~i.e. the maintainer's
128 MB module plus the width change through jtframe + the core~~.
**CORRECTED 14z-107 (2): the GFX conclusion STANDS (the art does not fit
vanilla's 32 MB), but "i.e. the 128 MB module" does not follow.** Section 6
shows the overflow also fits the SPARE of the existing 64 MB map, and
`docs/platform/mister.md` shows the 128 MB tier is not at our pin and is not
a flag. **ROUTE RULED 14z-107 (3): BANK REPACK.** ~~(bank 1, above the
PCM)~~ **CORRECTED 14z-107 (4): not bank 1 alone.** The table above is a
LIVE-BYTE count; the ADDRESS FOOTPRINT of group C is **15.45 MB** (up to
code `0xEE73` in obj bank 4 and `0xFFDB` in obj bank 5 — a CPS-2 tile code
IS its SDRAM address), so it takes the spare of banks 0 AND 1 plus the
QSound extension moved out of bank 1. It still fits, by **0.125 MB** of 64:
`docs/project/mister_map.md`.

**AND CORRECTED AGAIN 14z-107 (9), BY THE SDRAM IMAGE CENSUS: the slack is
0.125 MB, not 0.708, and SDRAM bank 1 is EXACTLY FULL.** The 15.45 MB
footprint is the right number for where the ART lives; it is the WRONG number
for what SDRAM RESERVES. The MRA maps the whole declared 48 MB GFX region, so
each group-C obj bank occupies its full 8 MB — 16 MB, not 15.45 — whatever
the art does inside it. Measured byte for byte on the real image; see
`docs/project/mister_map.md` §5. Two consequences that point opposite ways:
tenant art may now grow freely inside the existing 16 MB, and the group-C
ROMSET REGION cannot grow past 16 MB at all.

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
| SDRAM total | 64 MB (LARGE) | ~~~70 MB + work RAM/VRAM~~ **56.1 MB measured, §6** | ~~**128 MB tier** (`SDRAMW` 23 → 24, bank/prog/ioctl ports +1 bit)~~ **RETRACTED 14z-107 (2) — see §6.** The total FITS 64 MB; only bank PLACEMENT blocks it, and `SDRAMW` 23→24 is not reachable at our pin at all |

**Recommendation: WIDE v1 verbatim on MiSTer** — **RULED (maintainer,
2026-08-23); section 6 does NOT reopen the profile, only the implementation
route.** One profile, one
romset, one release artifact for all three implementations, and ~~the
MiSTer-specific work is purely WIDTH (no content re-layout, no per-slot
exclusivity, no second manifest)~~ **[RETRACTED 14z-107 (2) — see the block
below and section 6: it is core FORMAT work, not width]**. The "no content
re-layout / no second manifest" half stands. ~~The alternative
"MiSTer-shaped" profile (squeeze to the 64 MB tier) is ruled out by section
3 for GFX and would only have saved the PRG and QSound widenings, which are
the smallest of the three.~~ **REFINED 14z-107 (2): section 3's GFX finding
stands, but "squeeze to the 64 MB tier" was never the only 64 MB option —
section 6 keeps the profile IDENTICAL and repacks the BANKS instead, which
changes no content and no manifest.** ~~What this costs: the SDRAM tier change is FRAMEWORK surgery
(jtframe's `SDRAMW`/`AW` plumbing + the MiSTer target's download path),
to be done profile-gated in the fork and sized in the next slice — it is
the one part of the arc that is not a descriptor.~~ **RETRACTED 14z-107 (2):
"the MiSTer-specific work is purely WIDTH" is FALSE.** The CPS-2 core carries
FORMAT caps that no SDRAM tier lifts — a 16-bit tile code + 2-bit bank
(32 MB of GFX), a flat 4 MB `rom_cs`, an 8 MB scroll path with no bank input,
and the 7-bit QSound latch. See `docs/platform/mister.md` "What the CPS-2
CORE caps" and section 6 below.

Gameplay-visible consequence: none — every character and every byte of
art ships exactly as on FBNeo/MAME. That is why this can be a
recommendation rather than a roster decision.

## 6. THE FIT THAT CHANGES THE OPTIONS (measured 14z-107, added 14z-107 (2))

**The roster FITS 64 MB by TOTAL. The constraint is bank PLACEMENT, not
capacity.** Section 5 above concluded "128 MB tier" from a total that was
never computed; 14z-107 read the bank allocation out of
`cores/cps1/hdl/jtcps1_sdram.v` and the total lands under 64 MB. What
follows does NOT change the profile ruling (WIDE v1 verbatim, one romset —
maintainer, 2026-08-23); it changes what implementing it costs, and it makes
a 64 MB route real enough to put on the table. The platform facts behind it
are in `docs/platform/mister.md` ("What the CPS-2 CORE caps", "The SDRAM
ceiling at our pin").

### The bank map jtcps2 actually uses (v1.7.3, `SDRAM_LARGE` = 4 x 16 MB)

Offsets are `jtcps1_sdram.v:158-164`, in 16-bit WORDS — doubled below to
bytes. Slot geometry: `:258-282` (bank 0), `:332-345` (bank 1), `:365-381`
(bank 2), `:403-426` (bank 3).

| bank | contents | occupied | of | spare |
|---|---|---|---|---|
| 0 | 68k PRG `0-4 MB`; VRAM @4 MB; ORAM @5 MB; **work RAM @6 MB**; sound @7 MB | ~8 MB | 16 MB | **~8 MB** |
| 1 | QSound PCM, ALONE (`SLOT0_AW = PCM_AW = 23`) | 8 MB | 16 MB | **8 MB** |
| 2 | GFX (objects) | 16 MB | 16 MB | 0 |
| 3 | GFX (scroll) + two DEAD star slots (`jtcps2_game.v:521-528`) | 16 MB | 16 MB | 0 |
| | | **48 MB** | **64 MB** | 16 MB |

### The arithmetic, with the numbers used

Content figures are this document's own measurements (sections 1-4):

| region | live content | source |
|---|---|---|
| 68k PRG | **4.82 MB** (4 MB + `0xD10F4`) | section 1 |
| VRAM + ORAM + work RAM + sound windows | 4 x 1 MB = **4 MB** | bank map above |
| QSound | 8 MB stock + **0.918 MB** extension = **8.9 MB** | section 2 |
| GFX | 32 MB stock + **6.39 MB** group C = **38.4 MB** | section 3 |
| Z80 | 256 KB (inside the 1 MB sound window) | section 4 |
| **total live content** | **~56.1 MB** | vs a **64 MB** tier |

So the tier is not the binding constraint. Region by region against the
CURRENT 64 MB map:

- **PRG 6 MB FITS BANK 0 TODAY.** Pushing the PRG window from 4 MB to 6 MB
  moves VRAM/ORAM/WRAM/SND up by 2 MB, filling bank 0 to ~10 of 16 MB. (The
  30-byte pin at `0x5FFF00` from section 1 then sits inside the window
  instead of at its ceiling.) What this needs is the core-side 68k decode
  change — `jtcps2_main.v:184` `rom_cs <= A[23:22] == 2'b00;` and the
  `0x400000` objcfg collision — **not** a wider SDRAM.
- ~~**QSound 16 MB FITS BANK 1 TODAY.** PCM is alone in a 16 MB bank; only
  `PCM_AW` 23 -> 24 and the 14z-86 latch fix are needed.~~ **BOTH HALVES
  CORRECTED.** `PCM_AW` 23 -> 24 does not compile at all: the 8-bit slot's
  address arithmetic is `{SDRAMW-AW{1'b0}}` and goes negative past
  `AW = SDRAMW = 23` (measured 14z-107 (6), `docs/platform/mister.md`
  "jtframe's 8-bit SDRAM slot CAPS AT SDRAMW"), so one slot reaches 8 MB and
  the extension needs a SECOND slot in another bank. Live content is
  8.9 MB, leaving **~7.1 MB spare at the top of bank 1**.
  **CORRECTED 14z-107 (4): 16 MB of QSound must NOT be placed** — the WIDE
  `.rom` mapped verbatim is 70.26 MB, which overflows both the 26-bit
  `ioctl_addr` game port and the 16-bit header start word. QSound is placed
  at 8.9375 MB and SPLIT across banks 0 and 1. See `mister_map.md` §3, §5.
- **ONLY GFX OVERFLOWS, by ~6.4 MB.** Banks 2+3 are exactly full at 32 MB
  with vanilla's own art, and the roster adds 6.39 MB.
  ~~6.39 MB~~ **RETRACTED 14z-107 (4): 6.39 MB is a LIVE-BYTE count, not an
  ADDRESS FOOTPRINT.** A CPS-2 tile code IS its SDRAM address (the download
  scramble at `jtcps1_prom_we.v:105` undoes the `.rom`'s 4-way interleave),
  and the tenant art is sparse across BOTH group-C obj banks — up to code
  `0xEE73` in bank 4 and `0xFFDB` in bank 5. **The footprint is 15.45 MB**
  (7.452 + 7.995), so the art cannot go into one bank's spare at all. Full
  arithmetic and the map that does work: `docs/project/mister_map.md`.

### What that opens

A 64 MB route exists that was previously written off: **leave vanilla's
32 MB of GFX exactly where it is in banks 2+3** (so the superset invariant is
untouched by construction) and put the group-C art in the spare of the other
two banks, reached by the promoted tile-code bit — which is the RTL
expression of the profile-gated 19-bit promote CPS-2 WIDE v1 already makes on
FBNeo. ~~6.39 MB into ~7.1 MB of spare.~~ **CORRECTED 14z-107 (4): the art's
ADDRESS FOOTPRINT is 15.45 MB, not 6.39 MB, and it needs BOTH banks' spare —
one group-C obj bank each, plus the QSound extension moved out of bank 1 into
bank 0.** It still fits, by **0.125 MB** of 64 — ~~0.708 MB~~, **corrected
14z-107 (9) by the SDRAM image census: SDRAM bank 1 is EXACTLY FULL**,
because the download reserves each group-C obj bank's whole 8 MB REGION and
not just the art's 15.45 MB footprint. The placement map, the
arithmetic, the PRG decode proposal and the slice plan are
`docs/project/mister_map.md`; the extents the fit depends on are frozen by
`tests/audit_mister_map_fit.sh`.

Named honestly, the risk is throughput, not capacity: object reads would then
share bank 1 with PCM streaming, on exactly the path jtframe hand-tunes per
target (`jtcps1_sdram.v:167-175`, `OBJ_LATCH` 0 on MiSTer "to increase object
throughput"). **It is UNMEASURED.**

The alternative — upstream's `JTFRAME_SDRAM_XL` 128 MB tier — is real but is
not at our pin and is not a flag (`docs/platform/mister.md`). ~~Both options,
with their costs, are the pending decision **THE MiSTer MEMORY-MAP ROUTE** in
STATE.~~ **DECIDED (maintainer, 2026-08-23): the BANK REPACK at our pin,
measuring first; XL is the FALLBACK. The measurement returned GO the same day
(`tests/audit_sdram_bank_load.sh`) and the repack SHIPPED in slice D2
(14z-107 (9), fork commit `0df6f000`) — the placement is
`docs/project/mister_map.md` §5.** **Either route still requires the
core-side format work**: the GFX tile-code promote, the 68k `rom_cs` window,
and the QSound latch/width fix — of which the QSound width fix shipped in D1
and the promote is D3.

**Superseded here, kept for the record:** section 5's SDRAM row ("**128 MB
tier** (`SDRAMW` 23 -> 24, bank/prog/ioctl ports +1 bit)") and its closing
paragraph ("the MiSTer-specific work is purely WIDTH") described neither the
framework nor the core correctly. The PROFILE recommendation in that section
— WIDE v1 verbatim, one romset — stands and was ruled.
