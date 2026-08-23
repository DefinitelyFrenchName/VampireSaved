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
  QSOUND : 16 MB   4 uniform 4 MB members; since v1.2 (14z-86) the two
           EXTENSION members vsw.21m/22m are CONTENT members (sentinel
           CRCs 0xdec0de3a/3b — the old shared zero-fill CRC would
           hash-shadow a content-bearing 21m onto the still-zero 22m).
           The M5 voice batch packs absent vs2 sample windows there
           (banks 0x80+; tools/build_qs_songs.py [voice_batch]).
  Z80    : 256 KB unchanged in SIZE; since v1.1 (14z-86) the two driver
           members are CONTENT members `vsw.z01/z02` (sentinel CRCs
           0xdec0de38/39 in both descriptors, resolve by NAME) so builds
           can carry authored M5 song rows (tools/build_qs_songs.py +
           build/manifest/qs_songs.toml; gate tests/test_qs_songs.sh).
           Stock names vm3.01/02 would hash-shadow to vsav.zip's
           pristine members (the 14z-60z class). The canonical overlay
           ships STOCK bytes; content builds patch free id rows + zero
           runs only (vanilla-span identity gated). ~27 KB free measured.
  Everything else: bit-identical stock CPS-2
```

Rules that are not negotiable, because the loaders depend on them:
- GFX members come in groups of **4** and must all be the **same size**
  (`cps.cpp` consumes 4 at a time; `nGfxMaxSize` mis-sizes otherwise).
- QSound length must stay a **power of two** (`rom_mask = nCpsQSamLen - 1`).
  **SCOPE, 14z-107 (4): this binds the ROMSET because it is FBNeo's loader
  rule.** MAME's ceiling is a 24-bit `device_rom_interface`, and jtcps2 has
  **no mask at all** on the sample path (`PCM_AW` is an address width;
  `grep mask cores/cps15/hdl/jtcps15_sound.v` is empty), so MiSTer may PLACE
  a non-power-of-two slice of the same 16 MB region — and must, because the
  verbatim `.rom` overflows the 26-bit `ioctl_addr`. See
  `docs/project/mister_map.md` §3, §7.
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
| **B4 (gfx)** | content fetched from the new 19-bit banks | **PASS** — 9/9 replays RAM+pixel identical with 15 characters' sprites served from banks 4/5 |
| **B4 (prg)** | code/data fetched from above 4MB | **PASS** — all 20 per-char sound tables relocated to CPU $400000+, RAM identical; negative control (same rows -> zeros) DOES diverge, so the reads are real |
| **B5** | MAME parity + the profile ported to MAME | **PASS** — parity 62/62 on the unpatched source build; the MAME WIDE gate 36/36 (superset invariant + inertness + B4 canary, RAM **and** framebuffer) |
| B5b | suite preservation | pending |

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

**The canary romset is NOT the shippable romset (14z-60z, paid for with
two sessions).** `--gfx-copy-group-b` fills group C with byte COPIES of the
stock group B members, so those copies carry group B's CRCs. Both emulators
resolve a ROM entry by hash before falling back to its name, so in a
CONTENT build — whose group B holds the ported tiles — the loader matches
group B's declared CRC against the copies and serves **pristine** tiles for
the patched member. That shipped: Donovan and Anita rendered with vanilla
art from character select through the match, on both emulators, while every
RAM gate stayed green.

So the two romsets live in separate directories and always have:

| directory | group C | used by |
|---|---|---|
| `build/wide0/rompath` | zero fill | content builds (`pack_build.sh --merge`), profile inertness |
| `build/wide_canary/rompath` | byte copy of group B | the B4 canary section ONLY (`CANARY_ROMPATH`) |

`tools/audit_romset_identity.py` enforces the invariant that made the
difference — no member may carry the pristine bytes of a member the build
patched — and runs inside `tools/build_donovan.sh`.

## Emulator change budget (measured, not estimated)

| Change | FBNeo | Class |
|---|---|---|
| QSound 8 → 16 MB | descriptor only (**B0 verified**) | descriptor |
| GFX 32 → 48 MB (4 appended members) | descriptor only (**B1 verified**) | descriptor |
| PRG 4 → 6 MB | **zero lines** (A1; **B3 verified**) | descriptor |
| 19-bit tile address (bit-12 promote) | one condition widened at `cps_obj.cpp:429-434` + flag definition/extern/init/reset, gated on `Cps2Wide` (**B2 verified**) | **core, profile-gated** |
| New driver entry carrying the profile | new `BurnRomInfo` + `BurnDriver` beside `VsavjRomDesc[]` | descriptor |

So the entire profile costs **two gated blocks** in emulation logic, both in
`Cps2ObjDraw`, and everything else is table data. CORRECTED 14z-90 (GitHub
issue #35): this line said "one gated conditional". The second block is the
`CPS2_WIDE_CANARY` positive control, which `docs/project/patch_index.md`
explicitly retains ("CPS2_WIDE_CANARY stays as the B4 positive control") — so
it is deliberate and ratified, but it is not zero, and a governance summary
that undercounts the change budget is the kind of claim this project's
retraction discipline exists to catch. The canary is test-only and gated on
the same `Cps2Wide` flag.

## Governance (Rule 1 v2)

Emulator changes are permitted only inside this profile, and each must be:
bounded and declarative; **profile-gated** (a driver flag set by a new
driver entry, so stock vsavj and every other CPS-2 game are untouched by
construction); subject to the **emulator superset invariant** — the
patched binary running stock unmodified vsavj must reproduce the frozen
vanilla expectations bit-for-bit, enforced as a battery gate; mirrored in
a second emulator where practical; and ratified per profile version.

### B4 prg: PASSED, with the control that made it meaningful

Relocated **all 20 per-character sound record arrays** into the program
extension (`CPU:$400000+`, 1KB per character) and repointed every row of
the pointer table at `PRG:0xBF41A`. Result: RAM bit-identical across
02/01/30.

**The first attempt at this was VACUOUS and the control caught it.**
Relocating only char 00's array passed — but pointing that same row at
zero fill *also* changed nothing, proving the row is simply never read in
those replays. A pass with no negative control is not evidence. With all
20 rows relocated, the zeros variant DOES diverge, so the identical
result is real: **the 68k is genuinely fetching data from above 4MB.**

Note for authors: everything above `PRG:0x0FFFFF` is outside the
encryption window, so extension content is written RAW (no re-encryption)
— but it must still be laid out in FILE byte order, i.e. converted with
`cps2_decrypt.words_to_file_bytes(words_from_logical_bytes(...))`, and
the member's real CRC must go into the descriptor.

## Where the profile stands

Declared and proven inert: **PRG 6 MB, GFX 48 MB, QSound 16 MB** — the
full v1 shape. Total emulator cost so far: **one widened condition** in
`cps_obj.cpp` plus the flag's definition/extern/init/reset. Everything
else is descriptor table data.

**B4 has now proven the space USABLE on both axes**, each with a negative
control: sprites render pixel-perfect from the appended 19-bit gfx banks
(9/9 replays), and the 68k reads relocated data from `CPU:$400000+`
(RAM-identical, and provably not vacuous). The profile is no longer just
"declared and inert" — it is demonstrated.

Remaining before content work: B5/B5b (MAME parity, or the suite-
preservation gate if MAME cannot follow).

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

### B4 gfx: PASSED — the new banks are real and usable

With `CPS2_WIDE_CANARY=1` relocating bank-2/3 sprites into WIDE banks 4/5
at draw time, gfx group C loaded as a byte copy of group B, and the STOCK
rom: **9/9 legacy replays are RAM- and pixel-identical.** Fifteen
characters' sprites are being fetched from address space that did not
exist before, and nothing moves by a single pixel.

That closes the question the whole profile hinged on: **the 19-bit tile
address works end to end** — descriptor -> loader -> bank bits -> promote
-> fetch -> render.

**Root cause of the earlier failure: the descriptor CRC.** FBNeo matches
zip members by CRC. The appended members carried the CRC of zero fill
while the file held a copy of group B, so FBNeo loaded **0xFF fill** for
them — and still printed `(OK)`. Everything else in the chain had been
verified correct, which is why the failure was so confusing. Fullwrite-up in
GOTCHAS; `tools/build_wide_romset.py` now prints the exact descriptor
rows (name/size/CRC) for every member it writes.

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

### The canary design (kept — it is the reusable proof for future banks)

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

## B5 — MAME parity, and the profile ported to MAME

MAME is the project's independent verification oracle. A Homebrew binary
cannot follow a descriptor change, so B5 pins MAME **0.288** as a submodule
(`emu/mame`, tag `mame0288`, commit `27a8d9e8`) and builds it from source.

### The order matters: parity BEFORE the patch

Every MAME-side expectation this project owns was frozen against the
Homebrew binary. Swapping in a source build changes the INSTRUMENT, not the
subject. So `tests/test_mame_parity.sh` proves the **unpatched** source
build is indistinguishable from the reference first, and refuses to run at
all against a binary that knows the `vsavjw` driver. Only then does the
profile patch go near it. Same discipline as `FBNEO_REF`.

Build: `tools/setup_mame.sh` (`WIDE=0` for the reference binary). Two
things about it are non-obvious and are written up in docs/GOTCHAS.md:
the build runs from an rsync'd **space-free mirror** because MAME's GENie
cannot handle the space in this repository's path (and symlinks do not
help — `getcwd()` defeats them), and it is a **SOURCES-filtered** CPS-2-only
build, minutes instead of hours. Whether that filtering changes emulation
is not argued, it is measured by the parity gate.

### The emulator change, MAME side

`emu/mame-patches/0002-cps2-wide-v1.patch` — **164 lines added, exactly ONE
line removed**, and that one line is the sprite tile-code composition:

```c
-		const int code = base[i + 2] + ((y & 0x6000) << 3);
+		const int code = base[i + 2]
+				+ ((m_cps2_wide ? cps2_wide_bankbits(y) : (y & 0x6000)) << 3);
```

`cps2_wide_bankbits()` is the same CPS-2 Turbo rule FBNeo uses (promote bit
12 into bit 15 after the list walk). Everything else is additive: two
widened address maps, a `cps2wide` machine config, the `vsavjw` ROM
descriptor, one `GAME()` row and one `mame.lst` row. The flag is a driver
member set at machine-config time, so — unlike FBNeo's file-scope
`Cps2Wide`, which must be explicitly cleared in `DrvExit` — it cannot leak
into another game: MAME builds a fresh driver object per run.

### Two things MAME taught us that FBNeo did not

1. **16 MB of QSound is exactly MAME's ceiling.** `qsound_device` is a
   `device_rom_interface<24>` — 24 address bits. WIDE v1's 16 MB fits with
   nothing to spare. Growing QSound further would mean widening a SHARED
   MAME device, which is outside what Rule 1 v2 permits (it would stop
   being profile-gated). **WIDE v1's QSound size is therefore a hard
   ceiling, not a chosen number**, and any future voice-bank pressure has
   to be solved by exclusivity/banking rather than by growing the region.
2. **`$400000-$40000F` behaves differently in the two emulators.** FBNeo's
   `SekMapMemory(CpsRom, 0, nCpsRomLen-1)` read-shadows the CPS2 output
   registers with ROM (writes still reach the handler); MAME keeps them
   readable, because its base map re-declares them after the ROM range.
   This is a genuine divergence and it is unobservable ONLY because the
   profile reserves that window. **Never allocate there** — the reservation
   is now load-bearing for dual-emulator agreement, not just tidiness.
   **THIRD IMPLEMENTATION, 14z-107 (4): jtcps2 makes it a three-way
   divergence.** `jtcps2_main.v:190` decodes `objcfg_cs` over the whole
   `$400000-$4FFFFF` but qualifies it with `!RnW`, so today a READ there
   asserts nothing; under the proposed 6 MB `rom_cs` it would return ROM.
   The reservation is what keeps all three behaviours unobservable.
   (`docs/project/mister_map.md` §8.)

### Gates added

| Gate | What it establishes | Result |
|---|---|---|
| `tests/test_mame_parity.sh` | the unpatched source build reproduces every frozen oracle log bit-for-bit, and is byte-identical to the reference binary on every other replay, on vsavj **and** vsav2 | **62/62** |
| `tests/test_replay_video_selfcheck.sh` | replay.lua's new `VIDEO_OUT` framebuffer checksum is live, deterministic, non-perturbing, and detects a known pixel difference **without** crying wolf on a known-identical frame | **4/4** |
| `tests/test_mame_wide.sh` | the MAME twin of `test_wide_profile.sh`: superset invariant + inertness + the B4 canary, each on work RAM **and** framebuffer | **36/36** |
| `tests/test_mame_determinism.sh` | bounds the run-to-run divergence rate the whole oracle assumes is zero | 480/480 on the boot probe (see the caveat in STATE 14z-59) |

Independent confirmation that the two descriptors agree: MAME's own
`-verifyroms vsavjw` reports **"romset vsavjw [vsav] is good"** against the
romset `tools/build_wide_romset.py` writes for FBNeo. Both emulators are
demonstrably being fed the same bytes.

**The MAME B4 canary passing is not a repeat of the FBNeo result, it is a
second opinion on it.** Two unrelated codebases, each with its own loader,
its own interleave and its own gfx decode, both fetch fifteen characters'
sprites from address space that did not exist before and render every one
of twelve legacy replays pixel-identically.

`tests/lua/replay.lua` gained `VIDEO_OUT=<path>`, the MAME twin of
`FBNEO_HVIDEO`. It had to exist before any MAME WIDE result could be
believed: the 19-bit tile address is entirely a rendering change, and a
RAM-only gate reports it green without executing the modified line. This is
the same blind spot 14z-55 found on the FBNeo side, in the other emulator.

## Group C 3-tenant layout (measured + ratified 14z-67, D4 opener)

The D4 flip condition ("three tenants cannot fit group C → stop and
redesign") was tested by measurement and does NOT trigger. Instrument:
`tools/obj_records.py` over the three ratified extraction anim spans;
locks: `tests/test_gfx_layout3.sh`; ledger:
`build/manifest/gfx_layout3.toml`.

The decisive fact: **vs2 ships all three newcomers' art in one 64K bank
(bank 3) at mutually compatible codes** — so group C bank 4 can hold all
three with H and P at **delta 0** (native codes → no record remap) and
Donovan at his frozen +0x2750:

| in-group codes | tenant | tiles |
|---|---|---|
| 0x0000-0x06D8 | H low shared-effect (native) | 25 |
| 0x003F-0x3615 + scatter | P scattered (native) | 51 |
| 0x0AF6-0x4EFC | **Huitzil main band** (delta 0) | 14,870 |
| 0x4ED5-0x8647 | **Pyron main band** (delta 0, share RESERVED) | 14,037 |
| 0x8648-0xA42B | free pool | 7,652 codes |
| 0xA42D-0xAD7F | free pool | 2,387 codes |
| 0xAD80-0xEE73 | **Donovan band+shelf** (FROZEN m3a, +0x2750) | 15,662 |
| 0xEE74-0xFFFF | free pool | 4,492 codes |

Occupancy 68.1%; worst-case bound (H∪P exact + Donovan's whole safe
window) 45,645/65,536. Boundary overlaps between tenants are shared
tiles (same bank, same code) — the multi-tenant gfx pass's collision
rule is "same-source-or-fail". Bank 5 holds select/wheel art at native
bank-1 codes (374 codes as of m3a) — not a constraint.

## Known limits, stated up front

- **MiSTer** (source-verified 14z-86, jtcores @1ae053f3 + jtdsp16
  @71fa564a — replaces the 14z-85c filed-not-verified note):
  - QSound IS LLE (jtcps15_sound.v instantiates jtdsp16 running the
    real dl-1425.bin, streamed to BRAM at download) — the 14z-85c
    premise holds.
  - **BUT the stock sample-address path is 23 bits (8 MB) and the
    bank latch keeps only 7 bits** (`jtcps15_sound.v:47,361-367`:
    `qsnd_addr[22:16] <= dsp_ab[6:0]`) — banks 0x80+ ALIAS onto
    0x00-0x7F, i.e. relocated samples would MIS-PLAY legacy audio,
    not stay silent. MAME's 16-bit bank register has no such mask.
  - The 16 MB growth is a ~4-line RTL width fix (qsnd_addr 23→24,
    bank latch [6:0]→[7:0], PCM_AW 23→24): SDRAM bank 1 already
    holds 16 MB under JTFRAME_SDRAM_LARGE and the loader path is
    [23:1] — region sizes are header-driven, no MRA/toml change.
    **CORRECTED 14z-107 (4): the WIDTH fix stands, but "no MRA/toml
    change" is FALSE and 16 MB must NOT be placed.** The WIDE `.rom`
    mapped verbatim is 70.26 MB, which overflows both the 26-bit
    `ioctl_addr` game port (`jtframe_mem_ports.inc:1`) and the 16-bit
    header start word; and bank 1's spare is needed for tenant art. The
    MRA trims QSound to 8.9375 MB and the region is SPLIT across SDRAM
    banks 0 and 1 on `pcm_addr[23]`. Map, arithmetic and slice plan:
    `docs/project/mister_map.md`.
  - **The full WIDE set does not fit stock jtcps2**: GFX is capped at
    32 MB, 68k PRG at 4 MB, scroll at 8 MB, QSound at 8 MB with a 7-bit
    bank latch. **REFINED 14z-107 (2): three of those four are the OBJECT/
    ADDRESS FORMAT in the CPS-2 core, not the memory tier** — a 16-bit tile
    code plus a 2-bit bank from `table_y[14:13]`
    (`cores/cps2/hdl/jtcps2_obj_scan.v:47,152`) = 2^18 codes x 128 B = 32 MB;
    `jtcps2_main.v:184` `rom_cs <= A[23:22] == 2'b00;` = a flat 4 MB;
    `jtcps1_sdram.v:121,179,209` = 8 MB of scroll with no bank input. **No
    SDRAM tier lifts any of them**, and the GFX one is the SAME 19-bit tile
    promote this profile already ratified on FBNeo (Correction A2 above).
    Details and the fit arithmetic: `docs/platform/mister.md` "What the
    CPS-2 CORE caps" and `docs/project/mister_fit.md` section 6.
  - **THE `JTFRAME_SDRAM_XL` STATUS — RETRACTED 14z-106, PARTIALLY
    UN-RETRACTED 14z-107 (2). Read the version qualifier, it is the whole
    point.**
    - **At our pin (`jtcores` v1.7.3, the submodule `emu/jtcores`) there is
      NO XL tier, and 64 MB is PHYSICAL** — not a default with something
      behind it. `grep -rn SDRAM_XL modules/jtframe` = 0 hits; the only tier
      macro is `JTFRAME_SDRAM_LARGE` (`localparam SDRAMW=23` vs 22,
      `target/mister/jtframe_emu.sv:168-172`); the bank-core table stops at
      `AW 23 = 64 MB`; row/column geometry (`ROW=13`, `COW = AW==22 ? 9 : 10`)
      has no AW=24 arm and would leave `addr[9]` undriven; and `sys.tcl`
      assigns exactly 13 A pins, 2 BA pins and one nCS. The 14z-106
      measurement is CONFIRMED, not withdrawn.
    - **As a claim about jtframe, the original sentence in this document was
      RIGHT.** Upstream `jotego/jtcores` master DOES carry a 128 MB tier —
      `` `ifdef JTFRAME_SDRAM_XL / localparam SDRAMW=24; `` in
      `modules/jtframe/target/mister/hdl/jtframe_emu.sv:175-181`, added
      2026-06-19 (`5981db26`), consumed for real by `cores/cps3`. Its
      mechanism is TWO CHIPS on one module selected by the top address bit,
      with chip select carried on nCS POLARITY.
    - **So: right about the framework, wrong about the version we pinned.**
      And XL is not a flag — it lives only in the `JTFRAME_SDRAM_CACHE`
      branch, which nothing forces you to enable (a silent-aliasing trap,
      filed in `docs/platform/gotchas.md`). The route question — uprev to
      master, or bank-repack inside the 64 MB pin — is a pending decision in
      STATE ("THE MiSTer MEMORY-MAP ROUTE"). Full argument, with every
      file:line: `docs/platform/mister.md`.
  - Consequence for M5: sfx restored at banks < 0x80 (the 14z-86
    ejection pilot rides vsav's own image at bank 0x18) are
    MiSTer-compatible as-is; only content placed in the QSound
    extension (banks 0x80+) needs the width fix.
- **Netplay**: FBNeo is the primary target because it is the GGPO rollback
  reference platform. A custom build means peers need the same binary and
  the same set — release notes must say so.
- **MAME**: cannot follow any descriptor change as a Homebrew binary; a
  pinned source build is a Phase B prerequisite. If MAME cannot follow,
  the suite migrates to FBNeo *before* MAME is set aside — no path reduces
  total test coverage.
