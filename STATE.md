# STATE — living progress log

Updated: 2026-08-06 (sessions 14z-62..62k — the M3a program side DONE,
the gfx core LANDED (the band serves from group C), OPTION A PHASES 1-2
LANDED (the select family from bank 5, zero group-A placements), and
FIVE maintainer playtest rounds: two real packaging/coordinate bugs
caught and fixed (the stale group-B repack; the medallions off-screen
since birth), JEDAH CONFIRMED INDISTINGUISHABLE FROM VANILLA, and the
select-sword palette found, root-caused and fix-validated. Evidence
build 048521c2. Remaining: phase 3 (wheel/medallions + ring source),
cosmetic folds, the re-freeze bundle. Read 14z-62j/62k, then
docs/NEXT_SESSION.md.)

## Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and
## PLAYTEST-VALIDATED: the select family serves from group C bank 5;
## Jedah confirmed indistinguishable from vanilla by human playtest)

Full detail in docs/patch_notes.md (62j/62k); the shape:

- **All four select-family pieces** (portrait bust, name banner, VS
  splash, win quote) keep NATIVE vs2 tile codes at the variant id; the
  art (146 tiles) is copied vs2 -> WIDE group C BANK 5 at 0x10000+code
  (bank 4 is the fighter band — native bank-1-family codes would collide
  inside its window). select_tiles.json = ZERO group-A placements; the
  placeholder class is dead for these pieces.
- **Four drawer-object bank gates**, each measured before authoring, two
  corrected mid-flight by taps: portrait (palette thunk v2), name
  (per-hover refetch 0x5FCE0 — v1 compared d0 and NEVER FIRED: d0 is
  id*4 there; v2 gates via the live owner ptr), VS splash (0x6C0E0 on
  the object-cached id $A(a6)), win quote (the shared consumer 0x5F328
  with d0 = winner+0x40 — the new TU substitution; tenant-win-only
  write, zero legacy RAM effect).
- **Maintainer rounds 3-5**: JEDAH INDISTINGUISHABLE FROM VANILLA
  (select incl. the former mid-face band, VS, match, win screen with
  proper art and quote); Donovan's bust/banner/splash in his real art
  and colors. Group B pristine; group A additive-only (the effect-tail
  engine-page families at verified-free anchors — full-pristine
  vsav.zip needs that band moved, queued).
- **62k**: the pre-confirm select SWORD drew the palette-RAM INIT GREY
  RAMP (measured verbatim: f111 f222 ...) — the figure upload covers
  only pal base+0, the sword rides base+2, and the 0x0F in-place accent
  slots had masked the gap. Thunk at the dest lea copies the tenant's
  block+0x40 accent row (per color, both sides, F000 alpha). Round-5
  playtest VALIDATES, no regression.

All gates green throughout; stock reproduces `ae701ffb` after every
change; the WIDE reference 9bac6ee3 remains non-rebuildable since the
62i medallion-coordinate fix (known; folds into the re-freeze).
Evidence build: `build/m3a_selrec` = `048521c2`.

**PHASE 3 (next session), specified**: real medallion art via the wheel
bank move (the wheel object is single-bank: copy the 18 vanilla
medallion tiles byte-identical into group C + the newcomers' real vs2
medallions, flip the wheel drawer's bank — vanilla-cell pixels identical
by construction); the ring drawer's per-cell position source (stale base
at appended cells — the misplaced-label interim); the ring-vs-label
content decision (maintainer); then the folded venue family (HUD
name/mugshot), the win-pal sparse block, and the RE-FREEZE bundle
(mirror-victim fix + id_by_profile + new masked classes + registry).

## Session 14z-62d (same day — THE GFX HALF LANDS ITS CORE: the tenant's
## band serves from WIDE group C, and the host's group B is PRISTINE)

The minimal-change design that made it tractable: **keep every record
code word, flip only the bank words, move the tile data.** The band
(codes 0xAD8F-0xEA3F) and the effect shelf (to 0xEEBB) keep their exact
in-group tile indices — so not one record byte changes — but the data is
written into the four appended vsw simms (group C, bank 4 = y-word
0x1000, the bit-12 Turbo promote) and every bank-word source follows the
tenant: the six OBJ bank setters (`new_hex_variant`), the engine table
row (`obj_bank_word_slot`), the ported table row (bank_word(4) — NOT
`4 << 13`, which is the sprite-list TERMINATOR bit; `gfx_tiles.bank_word`
is now the single encoding), and `normalise_tenants` defaults a variant
tenant's gfx bank to 4.

**The descriptor CRC question got measured twice before it got right.**
Group C content varies per build, so a fixed CRC can never match it —
and any REAL value shadows: the pristine-B CRCs were the 14z-60z bug,
and the "obvious" zero-fill CRC hash-collides with the ZERO QSOUND
members in the same zip (measured: vsw.31m resolved to vsw.21m, the
whole B4 canary went dark while the zero-build sections stayed green).
The answer is SENTINEL CRCs (0xdec0de31..37) that match nothing, so the
members always resolve BY NAME — which both loaders demonstrably do for
every patched vm3 member already. Both emulator patches updated, both
emulators rebuilt, FBNeo profile gate PASS (superset + inertness +
canary); the MAME twin re-run against the sentinel build.

**Measured, on build `464eaf1f`:**
- Donovan renders IN-MATCH from group C — the 19-bit path carrying real
  roster content in a real match, pixel-correct, his own colors.
- **Jedah's match is PIXEL-IDENTICAL TO VANILLA** — raw-decoded MAME
  snapshots at four frames, work RAM bit-identical (window 890-2362
  unchanged), OBJ lists entry-identical. Two false scares on the way,
  both instrument lessons (GOTCHAS): his ES super's shred-ribbon art
  read as "garble" until compared against vanilla's own frame, and MAME
  VIDEO_OUT across DIFFERENT machine configs flags thousands of
  pixel-identical frames as divergent — cross-driver pixel comparison
  must use FBNeo HVIDEO or raw snapshots.
- The tenant gate passes all four sections unchanged.

**What remains of the gfx half** (bank-1/group-A, mechanism understood):
the tenant's select-art subset still occupies Jedah's bank-1
hover-figure anchors, so the host's select-screen BODY figure garbles —
his face, name banner, and all match art are back. Moving select art to
group C needs one measurement first: the select-venue OBJECTS' bank
fields (can a select record be drawn from bank 4, and what sets those
objects' +0x18?). Then the four placeholder label tiles and the
medallion art ride the same move. HUD plate / palette-grid / win-pal
interims unchanged from 14z-62c.

## Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the
## emulator; and the rendering gate that should have caught it)

The open bug is closed. Both hypotheses the previous session left standing
were wrong, and the previous session's own exculpatory measurement was
taken at the wrong address.

### The fault: a member that carried another member's pristine bytes

`tools/build_wide_romset.py --gfx-copy-group-b` fills the appended gfx
group C with **byte copies of the stock group B members** — the B4 canary
shape. Copies carry the originals' CRCs. Content builds patch group B
(`vm3.14m/16m/18m/20m` — where Donovan's tiles live) and merge that canary
romset in (`build_donovan.sh` -> `pack_build.sh --merge`, the recipe
HANDOFF documented). **Both emulators resolve a ROM entry by HASH before
falling back to its NAME**, so group B's declared CRC matched the canary
copies sitting in the same set and the loader served PRISTINE tiles for the
members the build had patched. Donovan and Anita drew with vanilla art:
right geometry, wrong pixels, no error, no `0xFF` fill, every RAM gate
green.

MAME says it in its own log if you know what to read — on the stock track
all eight gfx members report `WRONG CHECKSUMS` (the patched art loading by
name); on the WIDE track `vm3.14m/16m/18m/20m` are **silent**, because a
hash match was found for the wrong file. FBNeo says it in its own source,
`src/burner/sdl/bzip.cpp:158`: `// Search by crc first`, then
`// Failing that, search for possible names`. **The name is the fallback,
not the identity** — two files with the same bytes are the same member as
far as either loader is concerned.

### Measured, with controls, on both emulators

Decoded tile band at Donovan's select portrait, tile `0x2AD8F`
(`tests/lua/gfx_region_dump.lua` under MAME, `FBNEO_HGFX` under FBNeo):

| set | tiles at the ported band |
|---|---|
| WIDE build `m5w` (garbled) | **== PRISTINE vsavj** |
| WIDE build, group C zero-filled | == stock track (the patched art) |
| stock build `m5_stock` (renders fine) | the patched art |
| pristine reference | pristine |

FBNeo four-way, same conclusion: `m5w` `4dd0db77…` == pristine; `m5w_fix`
and `m5_stock` both `5189ccca…`. Two unrelated loaders, one behaviour.

### Two dead hypotheses, and why they looked alive

- **"The tiles load fine, so the fault is tile ADDRESSING at draw time"**
  (14z-60y). The dump behind it read byte `0x56C780` = tile `0xAD8F` —
  the sprite's code word **without its bank bits**. The address the
  hardware composes is `code | ((y & 0x6000) << 3)` = `0x2AD8F`, byte
  `0x156C780`. The band compared was unrelated vanilla data, identical on
  every build by construction. GOTCHAS entry added.
- **"y-word bit 12 is both the promoted address bit and a legitimate Y
  bit"** — false twice over. `objy_bits.lua` over the whole Donovan
  replay: `bit12=0`, `max19 == max18 = 0x33812`, so the WIDE promote line
  never fires on this content; and in `cps_obj.cpp` the drawn Y is masked
  to `0x03FF`, so bit 12 is not a coordinate bit either.
- Positive proof it is not the emulator at all: **the OBJ records are
  bit-identical between the two tracks** — 2,277 live entries at the
  select-screen and in-match frames, zero differences
  (`tests/lua/obj_records_dump.lua`). Same records, different pixels =
  the difference is in what the loader put in memory, not in how the
  draw path read it.

### The fix, in the pipeline rather than in a file

1. `build/wide0/rompath` is the **shippable** overlay again (group C zero
   fill); the canary shape lives only in `build/wide_canary/rompath`.
   `tests/test_wide_profile.sh` and `tests/test_mame_wide.sh` now read
   `CANARY_ROMPATH` for their B4 section, so the split does not silently
   cost that coverage.
2. `tools/audit_romset_identity.py` — **no member of a set may carry the
   pristine bytes of a member that build patched.** Byte-identical
   placeholders (the zero-filled 4 MB units) are reported, not failed:
   they can shadow nothing. Wired into `build_donovan.sh` (hard fail,
   after the gfx stage so it sees the whole set) and `pack_build.sh`.
   Run against the garbled build it names all four shadows.
3. `--gfx-copy-group-b` now prints a NOT-SHIPPABLE warning explaining the
   shadowing.

Rebuilt through the fixed pipeline: WIDE `9bac6ee3`, stock `ae701ffb`
(the stock rebuild reproduces the registered fingerprint exactly — a free
reproducibility check). Donovan renders correctly on both emulators;
snapshots in the session artifacts.

The WIDE rebuild also picks up the 14z-60 wheel work absent from `m5w`:
`PRG:0x2689FE` (the wheel-record referrer), `PRG:0x021227` (TABLE B), and
148 bytes in the extension member — attributed, not mysterious.

### The gate that should have caught it (and now does)

`tests/test_wide_render_content.sh`, ~60 s, four sections:

1. member identity on both tracks (static, no emulator);
2. **pixel A/B**: per-frame framebuffer checksums of a Donovan replay on
   stock vs WIDE must be identical — measured **3,721/3,721 frames
   identical**, so the tracks do not skew and this is an exact comparison,
   not an anchor comparison;
3. **positive control**: a set poisoned back into the 14z-60z shape must
   fail both — it does, diverging on 2,542 frames;
4. the decoded tile band is the build's, not pristine, with a pristine
   negative control — which caught a field-index slip in the gate's own
   checker on its first run.

`tests/test_romset_identity.sh` ground-truths the audit over four
synthetic sets (~1 s, no emulator, no build): patched-clean PASS, shadowed
FAIL naming both members, benign placeholders PASS, nothing-patched PASS.
Both are wired into `tests/run_battery_m2.sh` — the identity check as a
build-independent rule lock, the rendering gate on WIDE builds that have a
stock twin to compare against.

### MAINTAINER PLAYTEST — CONFIRMED (2026-08-05, on `build/m5_wide` `9bac6ee3`)

> "Initial tests with and without Donovan look good. No obvious regression,
> all graphics look good, gameplay feels genuine, all present sounds are
> good."

Both halves matter: **with** Donovan (the ported content that was garbled)
and **without** (the legacy path the superset invariant protects). The
rebuilt WIDE build also carries the 14z-60 select-wheel extension that
`m5w` predated, so this is a confirmation of the wheel work in a human's
hands too, not only of the tile fix.

"All PRESENT sounds are good" is consistent with the M5 decision of
2026-08-04 (option A: the unfaithful voice lines ship silent) — not a gap
found, a gap already chosen.

### M3a RESUMED: the select-record mechanism at `0x13`, measured — it gets
### SIMPLER, not harder

The queued unknown was: "`select_port.py` replaces Jedah's select records
IN PLACE, so at `0x13` the tenant needs its OWN records — that mechanism
changes shape." Measured answer: **at a variant id the whole mechanism is
two longs.**

```
P1 array   PRG:0x26742A    stride 4    rows 0x00-0x1F
P2 array   PRG:0x2674AA    = P1 + 0x80
index      the CELL/ID — the consumer masks to EIGHT bits, not four
rows 0x10-0x1F  byte-identical aliases of 0x00-0x0F (the variant half)
```

So id `0x13` owns `PRG:0x267476` (P1) and `PRG:0x2674F6` (P2), today
aliasing Victor's records. Repointing them gives the tenant its own select
records: **no widening, no fold to defeat, no legacy row touched** — no
legacy id can index the variant half (`audit_id_writers.sh`). This is the
14z-60 prediction paying out: moving to a variant id makes the superset
invariant EASIER, by construction, than the in-place surgery slot `0x0F`
demands.

**Measured, not inferred, and over-determined.** A read tap over the array
during `11_pick_donovan` (default → U → U → R → Jedah) fetches
`0x27195E, 0x2719DA, 0x271B0E, 0x271CE8` — exactly the records the model
puts at rows `0x01, 0x03, 0x07, 0x0F`. Four points fix base, stride and
index. A 2P replay pins the player offset: P2's object fetches its own
record from `+0x80`, agreeing with `d1 = 0x80` in the consumer at
`PRG:0x06C0E0`.

**And it corrected a recorded claim.** `engine_internals.md` had the P2
arrays as "+0x40 copies pointing at the same records" (from a differential
cursor dump). `+0x40` is the VARIANT HALF, which aliases the base half and
therefore looks exactly like a P2 copy from that angle. Both documents now
say so. The old conclusion still holds at slot `0x0F` — it just holds for a
different reason, and the difference is the whole M3a mechanism.

New: `tools/select_arrays.py`, `tests/test_select_arrays.sh` (static model
+ a one-byte corruption control + the engine's own row sequence, ~10 s),
`docs/atlas/select_screen.md` section.

**All three UI pieces now measured** — same model, each confirmed on all
four cursor positions:

| piece | P1 array | P2 array | id 0x13 owns (P1 / P2) |
|---|---|---|---|
| big portrait | `PRG:0x26742A` | `PRG:0x2674AA` | `0x267476` / `0x2674F6` |
| name banner | `PRG:0x2675AA` | `PRG:0x26762A` | `0x2675F6` / `0x267676` |
| cursor highlight | `PRG:0x268A02` | `PRG:0x268A82` | `0x268A4E` / `0x268ACE` |

**The tenant move costs six longs**, all in the variant half, all currently
Victor aliases. The gate freezes all six plus the adjacent wheel record
pointer.

One structural fact fell out while attributing tap noise: `PRG:0x2689FE`
(the wheel record pointer, the single referrer 14z-60r must repoint to
relocate the wheel) sits **immediately before** the highlight array's row
`0x00`. Its record is read every other frame throughout the select screen,
which is what the interleaved constant in the highlight tap was. The region
is packed end to end — more evidence for "relocate, never grow in place".

### M3a IN PROGRESS: the program half MOVES; the two content halves do not

**Landed and verified.**

- **The tenant id is now a build input, not a constant.** `--tenant-id`
  overrides the manifest for one build; `[[tenant]] id_by_profile` exists
  in the generator for when the move lands as the WIDE default. It is
  deliberately NOT in the manifest yet: the moment the WIDE profile maps to
  `0x13`, the frozen reference `donovan-m5w` (`9bac6ee3`) stops being
  reproducible from the tree, and a reference that cannot be rebuilt is not
  a reference. Verified both ways after the change — WIDE rebuilds to
  `9bac6ee3` exactly, and `--tenant-id 0x13` moves the tenant.
- **The program half moves correctly and by construction.** Built at
  `0x13`: **all 31 slot-indexed table rows land exactly `+0x10` from their
  `0x0F` addresses** (four slots x 4-byte stride) and the 30 `0x1F` mirror
  pokes are GONE — a variant-id tenant has no mirror, so Victor's `0x03`
  is never touched. The 14z-60w preparation paid: the thunk ids substitute,
  the bank-table row is written at `0x13` (`= 0x4000`), and nothing had to
  be hand-chased.
- A variant-id tenant without a profile is now REFUSED with the reason
  (its tiles cannot share the host's gfx band, and a stock build has
  nowhere else to put them).

**What is NOT done, stated plainly.** Both remaining halves are CONTENT
placement, and both would be plausible-but-wrong if rushed:

1. **Select records.** `select_port.py` still does in-place surgery on
   Jedah's records, so the `0x13` build regresses Jedah's select screen and
   the tenant shows Victor's (aliased) records. The mechanism is measured
   (six longs, table above) but the tenant's record BYTES need a home, and
   picking one by hand is the "never write an unverified gap" trap — it has
   to go through the generator's allocator, which runs BEFORE select_port
   in the pipeline. That ordering is the real work.
2. **Gfx.** The tenant's tiles still occupy Jedah's band, so at `0x13` the
   tenant renders correctly and **Jedah renders as the tenant**. Moving
   them means writing group C (WIDE banks 4/5, currently zero fill) instead
   of vsav's group B, with the WIDE bank encoding (`bank 4 = y-word 0x1000`,
   `bank 5 = 0x3000` — NOT `bank << 13`), and it makes the group C
   descriptor CRCs load-bearing, which is the hygiene item already queued.

So `build/m3a` (`f4769b55`) is a scratch build, not a candidate: its
program half is de-substituted and its content halves are not. It is kept
only as the evidence that the program move works. **The acceptance
criterion — legacy Jedah replays return to bit-identical vanilla — cannot
be claimed until both halves land**, and I have not claimed it.

### THE WIDE REFERENCE FROZEN (maintainer: "freeze and register as wide
### reference first, then we resume")

Registered `9bac6ee378e1a5ce0674423279c357a4d2a076ec -> donovan-m5w`.
The withdrawn `ac52eeff` row is kept in `registry.tsv` **commented out, on
purpose**: the known-bad build must fail as UNREGISTERED rather than
validate against this set. Verified both ways — the new build resolves to
`donovan-m5w`, `m5w` exits 2 with the loud message.

Expectation set `tests/expected/donovan-m5w/`: 16 `.skip` (replays that
target other romsets), the Donovan-specific replays self-frozen as `.sha1`
+ full logs, and the legacy replays authored from MEASUREMENT against the
frozen vanilla masked logs — never copied from another build's set.

**What the measurement showed, and why it stops short of a complete freeze.**
Eight legacy replays fit an existing ratified class exactly:

| replay | class | vs donovan-m2c |
|---|---|---|
| `01_attract_long` | `diverge 4278` | unchanged |
| `06_test_mode` | `diverge 700` | unchanged |
| `11_pick_donovan` | `diverge 890` | moved from 1080 — the select screen now differs EARLIER (wheel extension), then the pick diverges as before |
| `02`, `05`, `07` | `window 890 1622` | were `exact`; now the §4 v3 select window |
| `30_demitri_throw` | `window 890 1962` | was `exact` |

The other **seven show a composite shape that no single class can
express**: the frozen hook-flicker inventory PLUS one bounded window per
select-screen ENTRY. The decomposition is exact — every flicker frame
matches donovan-m2c's frozen inventory, **not one added and not one
missing**:

| replay | flicker (== m2c inventory) | window(s) | identical after |
|---|---|---|---|
| `03_two_player_vs` | 829, 2093 | 890-1802 | 3227 |
| `04_select_fuzz` | 1525, 2009, 2195 | 890-1051 | 1325 |
| `08_challenger_join` | 3507 | 890-1622, **3809-4542** | 2378 |
| `09_mirror_pick` | 829 | 890-1882 | 2838 |
| `10_midattract_start` | 3007, 3129 | 3190-5712 | 408 |
| `16_xemu_2p` | 829 | 890-2022 | 2298 |
| `29_felicia_walljump` | 2436 | 890-1962 | 1884 |

Two of those rows are mechanism confirmations rather than anomalies:
`08_challenger_join` has TWO windows because the challenger join enters the
select screen a second time, and `10_midattract_start`'s onset is 3190 (not
890) because it starts mid-attract, so select entry comes later. Both are
what the mechanism predicts, which is the point of writing predictions
down.

§4 says a replay may not be reclassified without a new measured mechanism
AND maintainer sign-off, so those seven were first frozen as `.pending` —
a new expectation kind that reports `PENDING — not validated`, prints the
measured shape and the proposed spec, and **fails the suite**. An
unvalidated replay must never read as green; `.skip` would have been the
comfortable lie.

**RATIFIED the same day** (maintainer: "Your proposal is ratified"). The
`composite` class is now CLAUDE.md §4 v4, the seven `.pending` files became
`.masked` `composite` specs carrying exactly the shapes they had printed,
and the freeze is complete: **`run_suite.sh` on `donovan-m5w` is GREEN** —
47 validated (33 self-frozen, 3 `diverge`, 4 `window`, 7 `composite`) and
16 explicitly skipped, out of 63 replays. `.pending` stays in the runner as
the correct way to record "measured but not yet ratified" without ever
reading as green.

Also wired: the ratified §4 v3 `window` class is now a `.masked` class in
`run_suite.sh` (it existed as a checker with ground truth, but nothing in
the suite could express it).

### Gates re-run after the change (§6)

| gate | result |
|---|---|
| `tests/test_wide_profile.sh` (FBNeo) | **PASS** — superset invariant + inertness + B4 canary, 12 replays, RAM and framebuffer |
| `tests/test_mame_wide.sh` | **PASS** — the same three sections on the MAME side |
| `tests/test_wide_render_content.sh` | **PASS** — new |
| `tests/test_romset_identity.sh` | **PASS** — new |
| stock rebuild | fingerprint `ae701ffb` reproduced exactly, so the build-pipeline edits are inert |

**One false FAIL on the way, worth knowing about:** the B4 canary section
failed on all 12 replays the first time it ran from its new home, because
`build/wide_canary/rompath` had been generated BEFORE the repo path lost
its space and its symlinks into `$ROMDIR` were all dangling. The overlay
builder in `run_replay_fbneo.sh` copies the overlay's links over the good
reference ones, so the whole set goes unreadable and it reads as "the
emulator renders the appended banks wrongly". Regenerating the romset fixed
it. GOTCHAS entry added — every generated rompath overlay built before the
rename needs the same treatment.

New instruments, all rerunnable: `tests/lua/snapshot_frames.lua` (MAME
renders its bitmap internally even under `-video none`, so
`video:snapshot()` gives real PNGs headlessly — this is how the bug was
first SEEN in-loop), `tests/lua/obj_records_dump.lua`,
`tests/lua/gfx_region_dump.lua`.

### What this says about the testing posture

The previous session called this "a coverage failure, not a
testing-cadence one" and was right. Worth adding: the failing component
was not the emulator, the ROM builder, or the port — it was the
**romset assembly step**, which no gate looked at, sitting between two
that were heavily gated. And the one instrument that could have seen it
(a gfx-band dump) was pointed at the wrong address by a hand-composed
tile number, then trusted because it returned a clean null. A null result
needs a negative control exactly as much as a positive one does.

## Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)

Two queued items closed, in the order the maintainer set: re-verify and
record the cursor mapping, then census the id space.

New: `docs/atlas/select_screen.md`, `docs/atlas/id_space.md`,
`tests/test_select_wheel.sh` (9 checks), `tests/test_id_space.sh` (7),
`tools/select_wheel.py`, `tools/check_wheel_walk.py`,
`tools/audit_id_space.py`. No ROM change; no build produced.

### Why this ran before the roster design

The cursor mechanism 14z-59l/59n recorded existed **only in
`docs/NEXT_SESSION.md`** — not in STATE.md, the atlas, or any test. STATE's
own 14z-59l section said the opposite ("that mechanism is NOT yet
located"), and NEXT_SESSION is rewritten wholesale every session, so the
finding was one rewrite from being lost and nobody but its author could
check it. Re-deriving it cost half a session and **corrected it**.

### The mechanism, re-derived and measured

Full detail in `docs/atlas/select_screen.md`. What changed versus the log:

- **The commit site is `PRG:0x020A7C` (cell) and `PRG:0x020A80` (char id),
  not `PRG:0x020A84`.** `0x020A84` is the `bsr.w $20C98` after them, and
  the `bmi` target for the no-move path. Measured: 145/145 navigation
  writes came from `0x020A7C`. The 14z-41 lesson, repeated verbatim — a
  cited address in a session log is a claim.
- **Direction order is R,L,D,U (bits 0-3), not U,D,L,R.** TABLE A's
  structure cannot distinguish the two: "opposing pairs are illegal" is
  symmetric under swapping which pair is vertical. Pinned by two prior
  independent records — `11_pick_donovan.rpl` (U,U,R → `0x0F`) and the
  atlas's Aulbath path (L,L,D → `0x09`) — which have a UNIQUE joint
  solution over all 8 labellings × 16 start cells, and which also recover
  the documented default cell `0x01`.
- **Both tables are DATA-space**, reached by `lea`/`movea.l` + `(An,Dn)`.
  In the opcode image they are convincing garbage.
- The substance of the original claim stands: both stores take the same
  `d0`, so **the wheel cell index IS the character id**.

Also found while measuring: `PRG:0x0209DA` writes the default cell,
`PRG:0x020AA6` clears it on confirm, and `PRG:0x020A98` special-cases cell
`0x0B` at confirm — the slot `character_tables.md` lists as "special".

### Measured, not just read

`select_wheel.py` generates an input script visiting **every** (cell,
direction) pair and states what each press must produce;
`check_wheel_walk.py` requires the emulator to produce exactly that.
Result: **145 presses, all 128 pairs, exact**, constant frame offset, no
write to the cell byte from anywhere but the commit PC. Four negative
controls on the checker — one of which feeds it the old `0x020A84` and
must fail, so the correction is evidenced by the gate itself.

### THE ID-SPACE ANSWER: conventional

| vsavj | |
|---|---|
| layout-verified id-indexed tables | 39 |
| variant rows that are byte copies | 603 |
| variant rows with their own data | 21 |
| **variant rows that do not exist** | **0** |

Every id `0x00-0x1F` has real storage in every one of them. The bank is
physically 32 rows (64 tables packed back-to-back, each ending exactly
where the next begins); the OBJ bank table and the wheel table agree.

The narrowing is not in the data but in a small set of **consumer sites
that mask to 4 bits — 5 in vsavj**, enumerated with addresses in
`id_space.md`. And the reference case settles how to read that:

| | vsavj | vsav2 |
|---|---|---|
| `andi #$0f` (folds `0x1x`→`0x0x`) | **5** | **2** |
| `andi #$1f` (full 5-bit) | 3 | **6** |

**vsav2 ships three characters on variant ids by widening the folding
sites** — 2 remaining, and it kept those two deliberately (a newcomer
sharing its base character's sound-id base and slot-6 special case). So
this is a finite per-site work list, not a wall.

Two findings worth keeping:
- `word_pos_a[0x16] = 0x0018` — every character holds `0x0010` except
  Anakaris (`0x06` = `0x0020`), and his VARIANT id holds a third value.
  vsavj already uses a variant row differentially outside slot 8.
- `PRG:0x04FAC4` folds because the table it indexes (`PRG:0x04FFA8`,
  24-byte records) genuinely has 16 rows. Widening that site means growing
  a table — the mask is a symptom of the structure behind it, so each of
  the five needs its own judgement.

**Bounding the claim honestly:** 226 of 269 read sites showed no mask
within 10 instructions of the read (the walk stops at the first branch).
That is not proof they never narrow the id — **the list is a
LOWER BOUND** (it grew to seven later the same session, see 14z-60e), and `test_id_space.sh` freezes it so growth is visible.

### Follow-up pass: the bound pushed, and one of my own claims corrected

Done without maintainer input, after the first write-up.

**The lower bound is now much tighter.** A second scan strategy — running
*through* conditional branches and tracking the register until it is
redefined, 40 instructions deep instead of 10 — finds **exactly the same
five sites**. Two walkers with different failure modes agreeing is the
strongest evidence short of full dataflow. What remains genuinely open is
named rather than hidden: **62 of the 269 reads copy the id into another
memory field** (14 distinct fields; `$a(a6)`×16, `$a(a4)`×13, `$b1(a6)`×11
lead), and a complete census must follow those to their consumers.

**CORRECTION to my own first pass.** I wrote that `PRG:0x04FAC4` "folds
because the table it indexes genuinely has 16 rows". Wrong — and wrong in
the house style: I read that table out of the OPCODE image, where a
`lea (pc)` + `(An,Dn)` table is high-entropy noise, and 16 rows of noise
look exactly as much like 16 rows as like 32. From the DATA image it is
plainly **32 rows × 24 bytes** (12 words/char, 6 pairs, `$bc(a5)` picks
+0/+2, values `0x0370-0x03D7`), ending cleanly at `0x0502A8`, upper 16
byte-identical to lower 16. The mask there is convention, not structure —
which makes the answer *stronger*. Now measured by the gate as table
`anim_pairs` (counts moved to 40 tables / 619 alias / 21 distinct /
**0 out-of-range**).

**The sites are not equal work** (full table in `id_space.md`; two more
were found later this session — 14z-60e — bringing the total to seven):

| Site | Fix class |
|---|---|
| `0x04FAC4` anim-pair table | **easy** — rows already exist; fill and widen |
| `0x0409EC` slot-6 behavioural test | **trivial** — a slot test, no table |
| `0x00A43E` → `$130(a5)` | **medium** — written only here, read at 15 sites beside the select code: the per-slot venue-asset arrays (mugshot/name/medallion), 16-wide, already on the port's list |
| `0x03E40` / `0x04082` anim `0x360+id` | **hard** — the anim NUMBER BLOCK really is 16 wide: `0x370+` is already occupied by the `0x04FFA8` table, so widening the mask collides. **These are the two vs2 left folded.** |

### Per-tenant manifest: schema PROPOSED (14z-60h)

`docs/tenant_manifest.md`, unblocked by the id-space answer. Not
implemented and nothing consumes it — written to be argued with first.
`[[tenant]]` replaces `[port]`; `mirror_variant` disappears (a tenant that
IS a variant id has no mirror, and one at `0x13` must not touch Victor at
`0x03`). Each tenant declares the three registries measurement turned up —
select wheel (cell, position, adjacency, `reachable_from`), arcade ladder
(opponent list + VS palette), and a decision for **every** folding site, so
that a census which grows fails a stale manifest rather than silently
inheriting. Migration is three falsifiable steps: byte-identical refactor
at `id=0x0F` (Phase C discipline), then the move to `0x13` with its own
battery and playtest, then Huitzil and Pyron.

### TWO MORE FOLDING SITES — and Capcom's fix, one nibble wide

Continuing without input, and it corrected the count. Chasing "does vanilla
ever assign a variant-half id" turned up the **id-cycling selector**:

```
vsavj 010E28  addq.b #$1,$382(a4)     vsav2 00F48E  addq.b #$1,$382(a4)
      010E2C  andi.b #$0f,$382(a4)          00F492  andi.b #$1f,$382(a4)
      010E36  subq.b #$1,$382(a4)           00F4AE  subq.b #$1,$382(a4)
      010E3A  andi.b #$0f,$382(a4)          00F4B2  andi.b #$1f,$382(a4)
```

**The same instruction in both games, one nibble apart.** vsavj wraps the
cycling id to `0-15`; vsav2 wraps to `0-31`. That is Capcom's widening of
this exact site, and it is the most direct evidence in the whole
investigation that the variant half is convention plus a finite edit list.

**Both my walkers were structurally blind to it.** Both keyed on register
dataflow; these instructions read-modify-write memory with no destination
register. Found only by disassembling the selector by hand. The count is
now **7 folding sites in vsavj** (5 register-path + 2 direct-to-memory)
against **2 in vsav2**, and `audit_id_space.py` scans the class separately.
So yesterday's "LOWER BOUND" caveat was not throat-clearing — it was
load-bearing, and it paid out within a day.

A verdict bug of my own in the same pass: the first version flagged vs2's
`andi.b #$01,$382(a4)` as a fold because `imm < 0x10`. It is a **2-value
toggle over ids 0/1** on a second cycling path (flag at `a5-0x50B8`), i.e.
a range restriction. `mask_class()` now separates `#$0f` (folds the variant
half) from `#$1f` (full 5-bit) from everything else.

### THE SUPERSET ARGUMENT, now measured over the whole corpus

Done: `tests/audit_id_writers.sh` (on-demand, 22 MAME runs). Both player
structs tapped — the CPU opponent, attract assignment and challenger path
write **only** to P2, so a P1-only tap misses three of the six writers.

**11 legacy replays × 2 fields = 22 tap logs, all with their `END` line.**
Six gameplay writers found:

| writer | ids | |
|---|---|---|
| `0x020A80` | `00 01 03 05 06 08` | select commit |
| `0x00AEF6` | `0A 0C 0E` | CPU opponent |
| `0x005BF4` / `0x005BFA` | `02 0F` / `00 03` | attract |
| `0x008A86` | `05` | challenger join |
| `0x009008` | `01` | P1 init |

Union: `00 01 02 03 05 06 08 0A 0C 0E 0F` — **not one variant-half value.**

So a tenant at `0x13` would occupy rows no legacy content can reach, and
the superset invariant would hold *by construction* instead of by the
in-place record surgery slot `0x0F` demands (the three superset traps in
GOTCHAS exist because legacy cursors visit Jedah's cell). Moving a tenant
onto a variant id should make the invariant EASIER, not harder — which is
the strongest argument yet for the `0x13` move.

**The gap, stated plainly:** `0x18` (Oboro) IS a variant id vanilla uses —
four sites compare against it (`0x018F9A`, `0x026FBE`, `0x0293A8`,
`0x043000`) — and no replay in the corpus reaches it. Established is "no
legacy replay here writes the variant half", not "vanilla cannot". Nothing
static sets bit 4 of the id directly; the confirm path `PRG:0x020ABE` takes
its value from `$45(a6)` gated on `$43(a6)`, which is the thread to pull.
Verdict logic ground-truthed both ways (injected variant write fails;
missing `END` line fails — MAME segfaults in teardown after writing a
complete log, so the exit code is ignored by design).

### RESERVED IDS — vanilla DOES use part of the variant half (14z-60k)

The most consequential finding of the session, and it corrects a working
assumption I had been carrying. Scanning for `move.b #imm,$382(An)` — a
hardcoded id stored into the id field:

| set | reserved variant ids | where |
|---|---|---|
| **vsavj** | **`0x12`** | `PRG:0x020BB6`, `PRG:0x020BC6` |
| **vsav2** | `0x19` | `PRG:0x01F864` |

vsavj's is the **Gallon variant** path on the select screen: cursor on
Gallon (`0x02`), an input bit held (`btst #$7,$394(a6)`), confirmed with
**2-3 punches** (`d0` in `300/500/600/700`) or **2-3 kicks**
(`3000/5000/6000/7000`) → id becomes `0x12`, `d1` recording which. Id
`0x12`'s per-char rows are byte-identical aliases of `0x02` (hitbox,
dispatch, anim index, `word132`) — the same character under a different id.

That is very likely the **Dark Talbain** mechanism `character_tables.md`
has carried as an open item ("must ride a different mechanism"). Recorded
as consistent-with, not proven — nobody has selected it and watched.

vs2's `0x19` is its second Oboro-class dataset, and its neighbouring
`#$08` writes at `0x01F5A8`/`0x01F5BC` sit inside the match-init id
normalisation the atlas already places at `PRG:0x01F5A0`. Two independent
records agreeing is why the scan is trusted.

**What it changes.** The free-id set is smaller than "anything above
`0x0F`": taken are `0x00-0x0F`, **`0x12`**, and `0x18`. Free are `0x10`,
`0x11`, `0x13` — exactly what the plan targets, **but only by luck**. Had
the plan reached for `0x12` it would have collided with a shipped secret.
`tests/test_id_space.sh` now locks the reserved set (14 checks), so growth
fails the gate rather than surfacing after a build.

It also scopes the corpus audit correctly: its PASS means "no legacy replay
HERE writes the variant half", never "vanilla cannot" — vanilla plainly
can, on an input no replay performs.

### A FOURTH work item found: the arcade-opponent path

Tapping the **P2** id field surfaced three writers the P1 tap never sees:
the CPU-opponent picker `PRG:0x00AEF6`, the attract assignment
`PRG:0x005BFA`, and the challenger/2P join `PRG:0x008A86` (plus the same
select commit with `a6`=P2). None writes a variant-half id either.

The picker uses an **order list in work RAM at `a5-0x61B8`, length
`$138(a5)`**, and a **32-bit** already-fought mask (`btst.l $110(a5)`) —
so the mask needs no widening, but the newcomers must be added to the
ladder list, which is a distinct job from the select wheel and easy to miss
because the wheel is the visible half. Downstream, `PRG:0x00B094` indexes
the VS-screen palette pool at `PRG:0x3A3CA0 + id*32`; that pool has real,
non-aliased data at variant ids (id `0x13` is a placeholder grey ramp), so
it is content to author, not a bound to fix. **Selectable is not
fightable** — now item 5 on the per-tenant declaration list.

### Prep for the capture: cell POSITIONS measured, and a negative result

So the maintainer's PNG lands on ready ground.

**Cell → screen position, all 16, measured** (`tools/wheel_positions.py`,
frozen in gate section 4). They cannot be read statically — the wheel
record lists 18 OBJ entries in DRAWING order, not cell order — so the
cursor is parked on each cell and its ring (**palette `0x1E`**) read out of
OBJ RAM. Cell `0x0F` measures (248, 64), which corroborates 14z-49's
independent identification of Jedah's medallion at (236, 57) by art
rendering: same cell, two unrelated methods, offset by the ring size.

**NEGATIVE RESULT worth more than the map: the adjacency is HAND-TUNED.**
Fitting TABLE B with "step to the nearest cell in this direction's sector"
reaches at best **100/128 (78%)** — with horizontal wrap (period 184; the
wheel wraps left↔right, which is why cell `01` at x=160 goes L to `05` at
x=336), no vertical wrap, ±65° sectors. Plain nearest-in-sector gets 67%.
About a fifth of Capcom's entries are deliberate choices no simple rule
predicts. **So the three new rows and the neighbouring edits must be
AUTHORED and verified, never generated** — a generated table would be
plausibly wrong in exactly the way only playtesting catches. The validator
(`select_wheel.py`) and the emulator gate are the safety net.

### DECISION FOR THE MAINTAINER (gameplay-visible)

The `0x360+id` anim family is the one item the measurement cannot settle
alone, and it is a "player could feel it" call, so it is not mine:

- **Option A — inherit (recommended).** A newcomer at `0x13` plays anim
  `0x363` (Victor's number in that block). **This is exactly what vsav2
  ships** — Capcom kept both folds — so it is known not to break their
  version of these characters.
- **Option B — relocate the block.** Find a free 32-wide anim-number range
  and widen both sites. Costs a numbering audit and touches shared engine
  code for a family we cannot yet name.

What is known about the family: entry `PRG:0x003E3A` (kernel save `$330E`
→ set anim `0x360+id` via `$4CE2` → restore `$3306`), called from the
state handler at `PRG:0x024002`, which sets `$140(a6)=0x20`,
`$14E(a6)=0x10` and then routes `$54(a6)` through the property table
`0x28D00` into the anim setter `0x27EC0`. **Naming it needs a runtime
probe** — deliberately not guessed. Recommendation stands at A regardless,
because vs2 is a shipped existence proof.

### Consequence for the roster (option 1)

**No indirection is needed.** Give the newcomers their native vs2 ids —
Huitzil `0x10`, Pyron `0x11`, Donovan `0x13` — and every ported bank row
lands at its own index with no renumbering, matching the cells vs2 already
ships. Remaining work: three TABLE B rows plus reachability edits to
neighbouring rows, and a decision per folding site. `id_space.md` lists
what a per-tenant manifest must declare.

Note this moves Donovan off slot `0x0F` (Jedah) to `0x13` — the "moving
Donovan off Jedah's slot" item already queued, now with a target id.

### Independent confirmation, from the bytes alone

vs2's wheel table has live rows at `0x10`/`0x11`/`0x13` and DEAD (`$ff`)
rows at `0x02`/`0x09`/`0x0A`. Against the atlas slot map those three are
Gallon, Aulbath and Sasquatch — **exactly the characters Vampire Savior 2
dropped** to make room for Donovan, Huitzil and Pyron. The public roster
swap falls out of the adjacency bytes, which is independent confirmation
that the cell index is the character id.

### A process failure worth recording

`EnterWorktree` branched from **`origin/main` (6fe3c04, 14z-41)**, not
local `main` (ed5dc10) — origin is ~18 sessions stale. The first half of
the measurement therefore ran on 14z-41-era tooling, including
`run_mame.sh` from before the 14z-59 input-provider isolation. Caught by a
missing test file; the branch was moved to local `main` and **everything
was re-measured**. The decrypted images came out byte-identical (same
SHA-1s) and the walk gave the identical result, so nothing was invalidated
— but that was luck, not method. This is the "the instrument moved" hazard
in a new costume, and it is now in GOTCHAS.

## Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)

### Decision (maintainer, 2026-08-04)

**Option 1 — an altered character select screen — is the target.** Capcom
made one for the Vampire Collection / Chronicle console ports, and the
maintainer owns them and can supply a pixel-accurate capture.
Simplification they set: **keep the existing roster's cells exactly where
they are and append the three newcomers**, keeping the random-select
medallion in its original place. Imperfect medallion art on the three new
cells is acceptable; **mechanical soundness is not**.

**Option 2 (fallback): the hold-Start alternate-selection system.** Lesser
implementation — the vs2 characters have their own alternates, so vsav
characters would have to be "stacked" to free slots. Only if option 1 fails.

### What vs2 actually contains (measured 14z-59l; corrects two of my claims)

I twice reported that vs2 hands us the layout we want. Both were wrong, and
both came from a MISALIGNED record base found by pattern-searching for the
newcomer icon codes rather than by following the header pointer.

The wheel records are located by a coord-list longword at `base-4` (that is
how vsavj's `0x0032A50A` sits at `0x272A6E`). Scanning for those pointers
finds the real records:

| Record | Coord list | Entries | 3x3? | Notes |
|---|---|---|---|---|
| vsavj `0x272A72` | `0x32A50A` | 18 | **yes** (idx 8, Gallon, pal 07) | the shipped vsav wheel |
| vs2 `0x2A6D8C` | `0x303AAC` | 18 | — | list byte-identical to vsavj's 18 |
| **vs2 `0x2A6E5C`** | **`0x303B68`** | **24** | **NO** | the newcomer wheel |

**CORRECTION 1:** I said "entry 8 is still 3x3, so appending does not force
demoting Gallon's cell". False. The real 24-entry record has **zero** 3x3
cells — the pal-07 character is split into a 3x2 (`b113`) plus a 2x1
(`b0ee`). The original 14z-49 note ("nobody is 3x3") was right.

**CORRECTION 2:** I said vs2 "appends three cells at (-24,-88) (-8,-88)
(+8,-88)" to the shared layout. False — those are entries 0-2 of a
DIFFERENT list. Measured properly, the 24 entries occupy **21 distinct
positions**: the three newcomer cells overdraw three placeholder cells.

| newcomer | entry | draws over | position |
|---|---|---|---|
| Huitzil `b108` pal 13 | 21 | entry 8 (`b100`) | raw (256,104) |
| Pyron `b0f5` pal 11 | 22 | entry 0 (`b0cf`) | raw (232,88) |
| Donovan `b10b` pal 05 | 23 | entry 12 (`b100`) | raw (208,104) |

### So what is actually usable

vs2 **does** give us Capcom's own **21-position wheel geometry** — but it is
a REARRANGEMENT, not vsavj's 18 plus three. Its coord list is a different
list, and its positions do not match vsavj's. Two paths follow:

- **(a) Adopt vs2's 21-position layout wholesale.** Official geometry,
  already in a ROM we own, ports with existing machinery. Cost: every
  existing cell moves, and the 3x3 is lost — contrary to the maintainer's
  "keep the original roster in its state".
- **(b) Keep vsavj's 18 positions and author 3 new ones** (the decision).
  vs2 still supplies the three medallion ART codes and palette rows, which
  is the expensive part; only the three coordinates and the navigation are
  new. **This is where the console-port capture is needed** — as the
  reference for where Capcom put them in a VSav-style wheel.

### The unanswered — and harder — half: CURSOR NAVIGATION

Everything above is where cells are DRAWN. What makes it "mechanically
sound" is what the cursor does: how a direction press maps to the next
cell. That mechanism is NOT yet located. It is the real work of this task,
it is independent of the art, and it is what a wrong answer would make
unplayable rather than merely ugly. Next investigative step.

> **CLOSED in 14z-60 — and the record it left was partly wrong.** The
> mechanism is now measured and lives in `docs/atlas/select_screen.md`
> (gate `tests/test_select_wheel.sh`). The follow-up notes written into
> `docs/NEXT_SESSION.md` after this section named `PRG:0x020A84` as the
> commit site; the commit stores are `PRG:0x020A7C` / `PRG:0x020A80`, and
> the direction order is R,L,D,U rather than U,D,L,R. See session 14z-60
> at the top of this file.

## Session 14z-59j (dual-track invariant ESTABLISHED, byte-attributed)

The dual-track decision is only coherent if the WIDE build is a genuine
SUPERSET of the stock one. `tests/test_dualtrack.sh` establishes that as a
live A/B between the two builds — no frozen expectations, so it needs no
freeze decision and is machine-independent.

| | Result |
|---|---|
| 11 legacy replays (never reach the patched slot) | **bit-identical** |
| 5 patched-slot replays (attract + 4 Donovan) | **differ**, as they must |
| attract difference, byte-attributed | 57 bytes: 54 dead-stack, 3 sound-driver, **0 gameplay** |

**Why this matters operationally:** legacy behaviour being bit-identical is
what lets every gate that passes on the stock build transfer to the WIDE
build without re-plumbing ten gates for the `vsavjw` set.

### A misclassification my own gate made, and the measurement that fixed it

The first run failed `01_attract_long`. I had put it in the LEGACY group —
wrong: the attract demo **features the patched slot**, which is exactly why
the stock build already carries `diverge vsavj/masked 4278` for it. The
existing expectation was the evidence, sitting in the repo the whole time.

Rather than reclassify and move on, the divergence was attributed byte for
byte (whole work-RAM dumps from both builds at frame 4400):

- **54 bytes in `$FF7FA0-$FF7FEF`** — inside the dead-stack window
  `$FF7F00-$FF7FFF` that CLAUDE.md §4 already masks (hook cycle skew, below
  resting SP; ghost bytes, not live state).
- **3 bytes at `$FF055B-$FF055D`** — `RAM:$FF05xx` is the **sound-driver
  work area** per docs/atlas/ram.md, i.e. precisely what a live sfx helper
  is supposed to touch.
- **Zero bytes of gameplay state.**

Second lesson banked: the gate had also been comparing WHOLE work RAM,
which includes the dead-stack window — the wrong basis for a
hooked-vs-hooked comparison. §4's masked basis exists for exactly this.

### New instrument: `tools/attribute_ramdiff.py`

"The two builds differ, and that's expected" is not a verdict, it is the
absence of one. This turns it into an assertion: every differing byte must
fall inside a window the caller can NAME, and stray addresses are printed
so the next question ("what lives at `$FFxxxx`?") is immediately askable
against the RAM atlas. It refuses to be quieted by widening a window —
that instruction is in its own failure output.

## Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)

### Donovan's move sounds now play — and no music

The 14z-52 blocker is fully closed. Placing the record array was only half;
the **per-node sfx helper** (vs2 `0x5122` -> vsavj `0x4CE2`) was still
stubbed, absorbing ~400 calls per match. Un-stubbed on the WIDE track:

| Replay | ids that now reach the QSound ring |
|---|---|
| 12_donovan_vs_cpu | 0x110, 0x111, 0x112 |
| 19_don_dp_spam | 0x110, 0x111 |
| 25_don_darkforce | 0x110 |
| 56_don_es_ls | 0x119 |

Every one is from the `keep_ids` allowlist (samples verified byte-identical
on vsavj), `missing=[]`, and **zero music-range ids** — the `0x700-0x7FF`
tripwire in `tests/test_don_sound.sh` never fired. That tripwire is the
whole point: it is the round-2 "music instead of sfx" bug, and it stays
shut. Stock track unchanged and still green.

This answers the 14z-52 caveat directly ("those entries never fire in any
of our 8 Donovan replays"): with the helper live they fire in all four
sound replays.

### The safety coupling is STRUCTURAL

Un-stubbing the helper while slot 0x0F still resolves to JEDAH's array
(~40 entries, Donovan indexes to 43) reads PAST it and enqueues whatever
follows — including the music range. So the un-stub is driven by the
`unstub` field of the SAME `[[sound_table]]` row that places the array, not
by a reconciliation status or a profile name. **No ordering of edits can
produce a live helper with no array.**

### THE CORRECTION: 14z-59h reported a fingerprint that was not the build's

`build_donovan.sh` fingerprinted without `--set`, so it defaulted to
`vsavj`; a WIDE build (packed `vsavjw`) found no `vsavj.zip` in its own
rompath, **fell through to `$ROMDIR`, and reported the PRISTINE reference
ROM's fingerprint**. `b0eb9ecd` is the vanilla row already in
registry.tsv. Two different builds reported the same value, and it was
neither of theirs — and it made the helper un-stub look like a no-op.

Also fixed: `_PRG_RE` did not match `vsw.41-.44`, so extension CONTENT was
invisible to build identity — 14z-54's gfx/QSound blind spot in a new
region. Both in GOTCHAS.

Real fingerprints, measured after both fixes:

| Build | Fingerprint |
|---|---|
| stock (vsavj) | `ae701ffb…` (unchanged) |
| WIDE, helper live | **`ac52eeff…`** |
| WIDE, helper stubbed (control) | `ec457c9d…` |

The control proves the un-stub is real end-to-end, which the broken
fingerprint had hidden.

### Registered (task 2)

`ac52eeff… -> donovan-m5w` in `tests/expected/registry.tsv`.
`tests/test_don_sound.sh` gained `SET=` (default `vsavj`, so stock is
untouched) and a WIDE inventory overlay. Both tracks PASS.

### READY FOR PLAYTEST

Build: `KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open
--profile cps2-wide-v1" tools/build_donovan.sh 6 <out>`
Run: patched FBNeo, driver **vsavjw**, `-rompath "<out>/rompath;$ROMDIR"`.
What to listen for: Donovan's normals/specials should now have their shared
impact/sword sfx. His VOICE lines are still silent by design — those
samples do not exist in vsav's ROMs (STATE "M5 voice samples", still open).

## Session 14z-59h (Phase C step 2 — the image grows; M5 SOUND UNBLOCKED)

**The 352-byte sound table has a home, and the 68k provably reads it.**
The blocker that has stood since 14z-52 is gone.

| Link | Evidence |
|---|---|
| generator states the requirement | `image: 0x400000 -> 0x600000 (+4 x 0x80000)` in patch.json |
| patcher grows the image before ops | table lands at `CPU:$400010` |
| packer emits `vsavjw.zip`, merging gfx/QSound | 4 extension + 6 profile members, sizes checked |
| runs on FBNeo (`vsavjw`) | 9,320 frames, clean END |
| runs on MAME (`vsavjw`) | 9,320 frames, clean END |
| **NEGATIVE CONTROL** | zeroing the table diverges at **frame 3121** |
| stock build | still `ae701ffb`, byte-identical |

Gate: `tests/test_phasec_image.sh` (all four properties at once).
WIDE build fingerprint: ~~`b0eb9ecd`~~ **WRONG — see 14z-59i.** That is the PRISTINE vsavj fingerprint; the builder was fingerprinting the reference ROM. Real value: `ac52eeff`.

**The negative control is the point.** B4 taught that a relocation which
"passes" proves nothing if the data is never read, so the gate zeroes the
table and REQUIRES behaviour to change. Without that, "it booted" would
have been indistinguishable from "the pointer row is dead".

### Two design rules banked

1. **Image shape follows the PROFILE, not the content.** The first attempt
   emitted one extension member because only 0x160 bytes were used — but
   the emulator descriptors declare four, and a set carrying fewer simply
   fails to load. Geometry is the profile's business; content decides
   nothing about it.
2. **The packed set name is DERIVED from the generator's own output.**
   `patch.json` carries an `image` block only when a profile-gated space
   was actually used, so the set name (`vsavj` vs `vsavjw`) can never
   disagree with what was built. No second place to keep the profile in
   sync.

### Note on `-verifyroms`

MAME reports `romset vsavjw [vsav] is bad` on CRC for this build. That is
expected for ANY patched build — patching a member changes its CRC, and
the stock Donovan build has always done the same — and both emulators run
it regardless. The consequence worth remembering: **the ROM audit cannot
distinguish "patched as intended" from "corrupted"**, which is exactly why
the negative control carries the weight instead of the audit.

### Pipeline changes (all shared code — hence property 1 of the gate)

- `gen_donovan_patch.py`: emits the `image` block; extension addresses are
  legal only in a profile-gated space.
- `patch_prg.py`: `image` support — grows the word array with 0xFF fill
  BEFORE ops, appends the members on write.
- `pack_build.sh`: `--merge` (fold in members this build does not produce;
  ours always win) and `KEY_SET` (a profile clone takes its parent's key).
  The key is fetched AFTER the merge, since ROMDIR has no `vsavjw.zip`.
- `build_donovan.sh`: detects the `image` block and packs as `vsavjw`.
- `verify_gfx_build.py`: discovers the packed set instead of hard-coding
  `vsavj.zip`.

### What this unblocks, and what it does NOT

M5 sound can proceed on the WIDE track. Still open and unchanged: the
**voice samples** decision (8 MB of QSound headroom, hard-capped by MAME's
16 MB ceiling), and whether those 6 shared sfx ids actually fire in a
replay — the table is now READ, which is not the same as AUDIBLE. The
14z-52 caveat stands: those entries were never observed firing in the
8 Donovan replays, so an audible test still needs a replay that triggers
them.

## Session 14z-59g (DECISIONS RATIFIED: dual-track build; upstreaming deferred)

**Maintainer, 2026-08-04.**

### 1. DUAL-TRACK — ratified

- **WIDE is the ROSTER build.** Content that needs the extension goes
  there; M3 (Huitzil + Pyron) has no other option — Phase A measured
  1,112 bytes free against a ~886 KiB deficit, so that was arithmetic, not
  preference.
- **The stock-size build stays**, frozen at `ae701ffb`, as the
  compatibility artifact that runs on unpatched FBNeo/MAME. It keeps
  playtesters off custom binaries until M3 forces the move, and keeps the
  frozen `donovan-m2c` expectations exercised.
- Cost: one extra build in the battery. The profile gating built in
  14z-59f already produces both from ONE manifest, and
  `tests/test_phasec_spaces.sh` asserts the stock build stays
  byte-identical.

**Consequence to hold on to:** the stock build must never silently gain a
dependency on the extension. That is enforced by construction —
profile-gated spaces and profile-gated content rows do not exist for a
build that did not ask for them — not by remembering.

### 2. UPSTREAMING — deferred, "too early"

Not a goal yet, not ruled out. Practical effect: **keep both 0002 patches
minimal and separable**, which is already the standing discipline (the
harness patch is frontend-only and deliberately split from the profile
patch; the profile costs one gated conditional per emulator). Nothing to
change today; revisit once the roster actually works. If upstream ever
accepted `vsavjw`, players would get the profile in stock builds and the
custom-binary objection would largely evaporate — worth remembering when
weighing distribution later.

### 3. Correction banked while settling this

The M5 sound-home entry's recommendation ("option B: reclaim the inert
weapon_accent rows") was based on a misreading — those rows are palette
`data_port`s outside both holes and free ZERO hole bytes. Detail in
Decisions pending below.

## Session 14z-59f (Phase C step 1 — the address-space model)

**The allocator is now declarative, and the refactor moved ZERO bytes.**

Placement used to be two hard-coded holes with a bump allocator and an
a→b fallback. It is now an ordered `[[space]]` list in
`build/manifest/donovan.toml`, each with a class (`crypt` = inside the
CPS-2 encryption window so code is re-encrypted / `raw`), an optional
`profile` gate, and a `fallback`. Legacy `alloc("a"/"b")` call sites
resolve through it unchanged.

Proven bit-identical **three times** — refactor alone, then with the
spaces declared, then with the WIDE profile enabled — all
`ae701ffb06d0cbf3462cad1a9faa47534a3c00e4`, matching the documented dev
head. Gate: `tests/test_phasec_spaces.sh`.

### What the new summary line reveals

```
stage 6: 224 ops, hole_a 0x100000/0x100000 (free 0x0),
                  hole_b 0x3FFEF0/0x400000 (free 0x110)
```
**hole_a is completely full; hole_b has 272 bytes left.** The 14z-52 space
crisis, now a number the build prints on every run instead of a claim.
The stuck sound table needs 0x160 = 352 bytes.

### Profile gating, by construction rather than by discipline

`wide_ext` (`$400010-$600000`, 2 MB) is declared but carries
`profile = "cps2-wide-v1"`, so it **does not exist** for a stock build —
enabling the profile alone still produced the identical fingerprint,
because nothing allocates there yet. Content rows gate the same way: the
`[[sound_table]]` row is now uncommented with `profile = "cps2-wide-v1"`
and `hole = "wide_ext"`, and a stock build skips it entirely.

Note the extension is CONTIGUOUS with hole_b, which ends exactly at
`$400000`; the 16-byte gap is the CpsFrg window, reserved and never
allocated (and the emulators disagree about reads there — 14z-59, so the
reservation is load-bearing).

### THE NEXT CONCRETE STEP, now precisely specified

Allocating into the extension fails with a diagnosis rather than a crash:

> `space wide_ext allocation 0x400010+0x160 for sound_table
> don_sfx_records lies beyond the 0x400000-byte program image. The
> profile's extension is declared and the ADDRESS SPACE is proven usable
> (WIDE B4, both emulators), but the build pipeline does not yet GROW the
> program image or emit the extra ROM members.`

So the remaining work is **pipeline, not address space**: grow the program
image to 6 MB and emit the four appended 512 KB members (`vsw.41-44`) with
their real CRCs, through `patch_prg.py` / `pack_build.sh`. The address
space itself is settled and proven.

### Consequence the maintainer should weigh

A build that uses the extension **requires the `vsavjw` driver and a
patched emulator** — today's Donovan builds run on STOCK FBNeo/MAME. For
netplay that means peers need the same binary and the same set
(docs/cps2_wide.md already says so). That is a shipping decision, not a
placement detail, which is why the sound_table row is profile-gated rather
than simply switched on. **It also supersedes the M5 SOUND DATA HOME
decision still listed below**: option C ("grow the program region via
driver descriptor") was rejected then as "larger blast radius", but WIDE
has since been demonstrated on both emulators, so it is now the cheap
option and options A/B (evicting live thunks, auditing Jedah's anim
region) are no longer forced.

## Session 14z-59e (B5b — FBNeo instruments; and a VACUOUS gate uncovered)

### THE FINDING: the FBNeo emulator superset invariant was never actually tested

`WIDE=0 tools/setup_fbneo.sh` printed *"harness-only build (reference
binary for the superset invariant)"* and built a binary that **carried the
WIDE profile**. It only ever SKIPPED applying the patch; it never reverted
it, and the submodule working tree keeps the patch from the previous
build. So `tests/test_wide_profile.sh` section 1 — reference vs WIDE
binary on stock vsavj — was comparing **WIDE against WIDE**, which passes
trivially.

That section is the **emulator superset invariant**, Rule 1 v2 clause 3:
the entire justification for permitting emulator changes at all. A vacuous
pass there is the most expensive kind of green, and it is not knowable
retroactively how the maintainer's `fbneo_ref` was built.

Fixed and then **established for real**: with a reference verified free of
the profile (the driver title string is compiled in, so `grep` on the
binary settles it), the gate is **36/36** — RAM *and* framebuffer, over the
12-replay corpus. The invariant now measures what it claims.

- `WIDE=0` **reverts** the patch and refuses to build if `Cps2Wide` survives.
- Both builds assert on the ARTIFACT, in both directions (a reference that
  carries the profile and a WIDE build that lacks it are equally broken).
- `test_wide_profile.sh` FAILS if `FBNEO_REF` contains the profile string.

Third member of one family this session — after `git apply` silently
skipping with exit 0, and the MAME submodule gitlink drifting the WIDE
binary to 0.289. **The tool reports success while the artifact is not what
was asked for.** The standing lesson: assert on the artifact, never on the
exit code.

### The instruments (B5b proper) — all frontend-only

FBNeo is the PRIMARY target (GGPO netplay reference), yet the oracle had
strictly better debugging than the platform players use. Closed, via the
public 68k interface only (`SekMapHandler` / `SekSetWrite*Handler` /
`SekGetPC`) plus the CPS RAM pointers — **no emulation-core file touched**:

| Env | Instrument |
|---|---|
| `FBNEO_HTAP="lo-hi[;...]"` | write tap with **PC attribution** (handler slot 7; capcom uses 0-6) |
| `FBNEO_HPOKE="frame:addr:hex"` | frame-scheduled pokes |
| `FBNEO_DUMPS` | now resolves by ADDRESS — reaches OBJ RAM `$708000` and palette `$900000`, not just work RAM |

Gate: `tests/test_fbneo_instruments.sh`, and it tests the way this project
requires rather than "it ran":
- **NON-PERTURBATION** — the tap swaps direct memory mapping for a handler
  that must write through faithfully. A tapped replay is checksum-identical
  to an untapped one, so a wrong write-through cannot hide.
- **POSITIVE CONTROLS** — 1,048,406 writes captured with PCs; the poke
  diverges at exactly the poked frame. An instrument that reports nothing
  proves nothing (the B4 vacuous-relocation lesson).
- **ORACLE CROSS-CHECK** — palette `$900000` dumps are **byte-identical to
  MAME**, which independently validates the `^1` byte-order swap (the
  repo's #1 gotcha). Taken at a frame where the region is stable across the
  known MAME/FBNeo frame skew, so the match is not a timing coincidence.

### B5b acceptance: a known finding RE-DERIVED on FBNeo

Per STATE 14z-53 the bar is not "features exist" but "re-derive known
findings". The FBNeo tap on `RAM:$FF5D94` independently lands on the HUD
stagers documented in 14z-49 from MAME: PCs `089376/08937c` at **0x89370**
and `0893a0/a4/a8/ac` at **0x8939C**, with the boot RAM-clear at `0x000d36`.
It also **refines** the record: the emitter `PRG:0x1BB3C` does NOT write
those records directly — the stagers do.

### BLOCKED BY RULE 1: probe breakpoints with register capture

The last instrument on the B5b list cannot be built frontend-only.
`src/cpu/m68000_intf.h` exposes no instruction-level hook or breakpoint
API — only memory handlers, `SekGetPC`, and the IRQ callback. A PC-matching
probe needs a per-instruction callback, which lives in the CPU core.
Per CLAUDE.md rule 1 this is written up rather than worked around.

Options if it is ever needed: **A)** approximate with a write tap on a
address the routine touches (covers most "did we reach here" questions and
is already available); **B)** use MAME's `GUARD_PROBE`, which still exists
and now has proven parity — the reason to reach for FBNeo probes largely
evaporated when B5 succeeded; **C)** widen Rule 1 to admit a gated
instruction hook — a real emulator-core change, needing maintainer
ratification, and not justified by current need.

Reproducibility (14z-58e standard): the FBNeo submodule was reverted to
pristine, `tools/setup_fbneo.sh` re-applied both patches from the committed
files, and the instruments gate passed on the result.

## Session 14z-59 (B5 — MAME parity + the profile ported; and the determinism finding)

**B5 IS COMPLETE AND GREEN:** parity **62/62**, MAME WIDE gate **36/36**
(superset invariant + inertness + B4 canary, work RAM AND framebuffer over
the 12-replay legacy corpus), VIDEO_OUT self-check **4/4**. MAME's own
`-verifyroms vsavjw` reports the romset good, so both emulators are
provably fed identical bytes. **The B4 canary passing on MAME is a SECOND
OPINION, not a repeat**: two unrelated codebases, each with its own
loader, interleave and gfx decode, both serve fifteen characters' sprites
from the appended 19-bit banks with every legacy replay pixel-identical.

### What B5 delivered

- **MAME 0.288 pinned**: submodule `emu/mame`, tag `mame0288`, commit
  `27a8d9e8`. `tools/setup_mame.sh` builds it; `tools/run_mame.sh` gained
  `MAME_BIN` (default `mame`, so every existing gate is untouched).
- **Parity proven BEFORE the patch** (`tests/test_mame_parity.sh`): the
  UNPATCHED source build reproduces all 24 frozen vsavj oracle logs
  bit-for-bit AND is byte-identical to the Homebrew reference on the other
  38 replays, on vsavj and vsav2 alike — 62/62. The gate refuses to run
  against a binary that knows `vsavjw`, because calling that "parity"
  would be a lie. Swapping the binary changes the INSTRUMENT; if the
  instrument moved, every MAME finding since session 1 would be in
  question.
- **The profile ported**: `emu/mame-patches/0002-cps2-wide-v1.patch`,
  **164 lines added, exactly ONE removed** — the sprite tile-code
  composition, gated on a `m_cps2_wide` driver member. Everything else is
  additive (two widened maps, a `cps2wide` machine config, the `vsavjw`
  descriptor, one `GAME()` row, one `mame.lst` row). Verified to apply
  cleanly to the pristine pinned tree.
- **`VIDEO_OUT`** added to `tests/lua/replay.lua` — the MAME twin of
  `FBNEO_HVIDEO`. MAME's harness had the SAME video blind spot 14z-55
  found in FBNeo's, and the WIDE change is entirely a rendering change, so
  a RAM-only MAME gate would have reported it green without executing the
  modified line. Ground-truthed both ways by
  `tests/test_replay_video_selfcheck.sh` against the known donovan6
  medallion diff (frame 650 must MATCH, frames 950/1250 must DIFFER).
  Measured: 3,952 distinct framebuffer checksums over 5,520 frames, and
  the RAM log stays bit-identical to the frozen expectation with it on.

### Two MAME-only facts that CONSTRAIN the profile

1. **16 MB of QSound is MAME's hard ceiling.** `qsound_device` is a
   `device_rom_interface<24>` — 24 address bits. WIDE v1's 16 MB fits with
   nothing to spare. Growing QSound further would mean widening a SHARED
   MAME device, which stops being profile-gated and falls outside Rule 1
   v2. **The v1 QSound size is therefore a ceiling, not a chosen number** —
   future voice-bank pressure has to be solved by exclusivity/banking.
2. **`$400000-$40000F` reads differ between the emulators.** FBNeo's
   `SekMapMemory(CpsRom, 0, nCpsRomLen-1)` read-shadows the CPS2 output
   registers with ROM; MAME's base map re-declares them after the ROM
   range, so they stay readable. A genuine divergence, unobservable ONLY
   because the profile reserves that window — the reservation is now
   load-bearing for dual-emulator agreement, not tidiness.

### DETERMINISM POLICY — RATIFIED (maintainer, 2026-08-03)

Maintainer, on the options recorded below: *"I agree with your conclusions
in STATE.md: 'RECOMMENDATION: A, then B until the measurement says
otherwise' can be enforced."*

**The policy, now in force:**
- **A — measure first.** Bound the run-to-run divergence rate before any
  §4 policy changes. Instrument: `tests/test_mame_determinism.sh`
  (`RUNS`, `JOBS`, `PROBE`, `SET`).
- **B — every MAME gate stays STRICT until that measurement says
  otherwise.** Any divergence is a hard failure requiring root-cause. No
  automatic re-run, no tolerance class, no "flake" verdict.
- **C (a new "unreproducible transient" comparison class) is NOT adopted**
  and may not be proposed again without the measurement from A. It is the
  tolerance-shaped option and the one most able to hide a real bug.

This does not amend CLAUDE.md §4 — it declines to. The existing classes
(exact / flicker-tolerated / frozen first-divergence constant) are
unchanged, and nothing has been loosened.

**Proxy validated before spending the budget:** the 520-frame
`tests/probes/boot_probe.rpl` is **bit-identical to `08_challenger_join`
for frames 1-299**, so it genuinely exercises the window both divergences
appeared in — at ~3s per run instead of ~15s. That is what makes a
high-volume measurement affordable, and it is a measured fact, not an
assumption.

**MEASUREMENT RESULT (A, executed 2026-08-03): all regimes CLEAN, and the
clean result is itself the finding.**

| Regime | Runs | Divergences |
|---|---|---|
| 1 — boot probe, sequential | 1000 | 0 |
| 2 — boot probe, parallel x6 (load hypothesis) | 600 | 0 |
| 3 — full `08_challenger_join`, sequential | 150 | 0 |
| (earlier) boot probe, 4 combos | 480 | 0 |
| (earlier) full-length replays, all sources | 312 | **2** |

**A flat per-run boot-window rate is RULED OUT.** The probe is a validated
proxy for frames 1-299 and both divergences began at frames 190/218,
inside that window. 2,080 clean probe runs against a 0.43%/run point
estimate from full-length replays is a **1-in-8,300** coincidence
(`P(0 | 0.43%) = 1.2e-4`). The two events are real — they have diffs — but
they are not a simple per-run property of emulating those frames.

**What that leaves.** Every controlled regime repeated ONE replay on ONE
romset. The parity gate — the only place the phenomenon has ever appeared —
alternates replays AND romsets (vsavj/vsav2) across ~250 processes. So
regime 4 re-ran the GATE ITSELF twice rather than doing more repetitions of
a single replay, which the statistics say would be wasted time. The load
hypothesis is already dead (regime 2, parallel x6).

| Regime 4 — the exact failing configuration | Comparisons | Divergences |
|---|---|---|
| parity execution 1 | 63 | **2** |
| parity executions 2, 3, 4 | 189 | 0 |

**BOTH EVENTS ARE IN ONE EXECUTION.** That clustering is the strongest
signal available: an intrinsic per-run property would scatter across
executions, and heterogeneity-as-trigger would have reproduced in three
more full gate runs. Two events inside a single ~35-minute window, then
nothing in ~2,400 subsequent runs, reads as a **transient condition local
to that window**, not a property of the emulator, the build, the replay or
the gate. What that condition was is NOT established.

### 14z-59c — THE MAINTAINER SUPPLIED THE MECHANISM

Offered explicitly as context rather than a diagnosis, and it fits
everything the measurement could not explain:

> the harness runs on the maintainer's **main laptop**, which they
> sometimes need to use. MAME has no true headless mode — even under
> `-video none` it creates a window that **takes focus**. Focus was
> reclaimed and inputs were made during that period. Separately, MAME can
> crash in some circumstances.

**Why this explains the signature and the statistics both.** MAME's
default keyboard map covers P1 directions, buttons, coins and start, so a
host keystroke on that window is injected into the EMULATED controls. RAM
then diverges for as long as the key is held and **re-converges** the
moment the replay's own per-frame staging reasserts every field — exactly
the bounded, self-healing windows observed (190-205, 218-245). It also
explains the clustering: both events fall in one ~35-minute execution (the
machine was in use), and ~2,400 later runs on an idle machine found
nothing. A flat per-run rate and machine load were both RULED OUT by
measurement; this survives all of it.

**Not confirmed** — the two events predate any input logging, so this
cannot be proven retroactively. It is the leading explanation, and the
hole is now closed in both directions:

- **PREVENT** — `tools/run_mame.sh` now passes `-keyboardprovider none
  -mouseprovider none -joystickprovider none -lightgunprovider none`.
  A run that can absorb a stray keypress is not an oracle. Verified
  non-perturbing: the frozen suite reproduces bit-for-bit.
- **DETECT** — `tests/lua/replay.lua` verifies EVERY frame that the live
  controller bits are exactly what it staged, writes `INPUT-VIOLATION`
  into the log otherwise, and `run_replay_mame.sh` rejects the run.
  Always on (`NO_INPUT_CHECK` to disable). Had this existed, the two
  divergences would have been diagnosed in seconds instead of costing
  ~2,400 runs of statistics.
- **GROUND TRUTH** — `tests/test_input_integrity.sh`, both directions:
  silent and non-perturbing on a clean run; a single-frame un-scripted
  press caught at exactly the injected frame
  (`INPUT-VIOLATION 1 frame 500 port :IN0 expected 7f7f got 7f6f`).
  The positive control uses `INPUT_INJECT_TEST=<frame>`, which presses a
  button without recording it in `held[]` — what a host keystroke looks
  like to the harness.

**A bug the ground truth caught in the checker's first draft:** comparing
whole ports flagged EVERY replay at frame 77, because `:IN2` mixes the
**EEPROM data line** in with the coin/start bits. The check now masks to
bits the harness can actually drive. Testing verdict logic before trusting
it is doctrine for exactly this reason.

**The crash half** is already covered: `run_replay_mame.sh` requires a
terminating `END` line, so a crashed or truncated run fails rather than
being compared.

**Status: BOUNDED AND OPEN, not root-caused.** Honest summary of what A
bought: it killed two hypotheses (flat per-run rate; machine load), showed
the events cluster, and put an upper bound of ~0.14%/run on the boot
window. It did not find a mechanism. Four clean regimes are not a
resolution — the two events have diffs and happened.

**Policy consequence: nothing loosens.** The measurement did not find a
rate, so by its own terms it cannot justify relaxing anything; **B stays
in force**, C remains un-adopted, gates stay strict, and
`tools/analyze_divergence.py` + the preserved artifacts stand ready to
classify occurrence #3 the moment it appears. If it recurs, the first
question to answer is what else was running on the machine — that is the
hypothesis this measurement leaves standing, and the one nothing in the
harness currently records.

### THE FINDING: MAME is not perfectly deterministic run-to-run

The first full parity execution produced **two divergences in 126 runs**,
and neither is a source-vs-Homebrew difference:

| Replay | Set | Window | Comparison |
|---|---|---|---|
| `08_challenger_join` | vsavj | frames 190-205 | source vs source (same binary!) |
| `41_don_altcolor_vsav2` | vsav2 | frames 218-245 | reference vs source |

Both sit in the **boot window**, both **re-converge**, and both refuse to
reproduce on demand: `08` is 48/48 identical on re-runs, `41` is 12/12
identical across six runs of EACH binary. The immediate re-run of the
whole gate came back **62/62 clean**. So the phenomenon is real, rare, and
belongs to the emulator/harness — not to the WIDE work and not to the
source build.

This matters beyond B5: **every frozen MAME expectation this project owns
assumes run-to-run determinism**, and `run_suite.sh`'s twice-run check has
been green for many sessions, which is hard to square with two failures in
one 126-run execution. Either something changed, or the rate is low and
two landed together.

**What the follow-up measurements say (all run this session):**

| Regime | Runs | Divergences |
|---|---|---|
| parity gate, execution 1 (full-length replays) | 126 | **2** |
| parity gate, execution 2 (identical, clean machine) | 126 | 0 |
| targeted repeats of `08` and `41` (full-length, both binaries) | 60 | 0 |
| boot probe, 4 combos (src/ref x vsavj/vsav2), 120 each | 480 | 0 |

Point estimate from full-length replays: **2 in 312 ≈ 0.6%/run**. The
480-run boot-probe sweep is clean, but it does **not** refute that: the
probe is 520 frames against replays of 3,000-12,000, and if it covered the
same trigger, 0-in-480 at 1.6%/run would be a ~0.04% coincidence. The
honest reading is that **the probe probably does not cover the trigger**,
and the boot window is where the divergence SURFACED, not necessarily
where it originates. Getting real statistical power needs ~300 full-length
runs of one replay (~1.5 h); `PROBE=<rpl>` on the determinism gate does
exactly that and is the recommended next measurement.

Instruments built to settle it rather than argue about it:
- `tools/analyze_divergence.py` — classifies a divergent pair as
  **PHASE SHIFT k** (timing: B[n] == A[n-k], nothing computed a different
  value), **TRANSIENT** (real state differed, then was overwritten) or
  **PERMANENT**. Its verdict logic is itself validated against a synthetic
  phase shift and an identical pair before use (CLAUDE.md §4).
- Both new gates now **preserve divergent logs** to `build/gate_failures/`.
  Deleting the evidence in an EXIT trap is what made both of today's
  occurrences unanalysable; that cost is not paid twice.
- `tests/probes/boot_probe.rpl` (400 frames, ~2s) + a new
  `tests/test_mame_determinism.sh` measure the RATE at volume, since the
  boot window is where both anomalies appeared. `tests/probes/` exists
  because `run_suite.sh` demands a frozen expectation for every
  `tests/replays/*.rpl`, and a diagnostic probe must not force an
  expectation row into all four expectation sets.

### The trap that nearly shipped a false green

The first WIDE build succeeded, ran nine minutes, printed "CPS-2 WIDE
profile patch applied" — and produced a **completely STOCK binary**.
`$HOME` on this machine is itself a git repository, so the build mirror at
`~/.cache/vampire-saved/mame` sits inside its working tree; `git -C
<mirror> apply` therefore read the diff's paths as $HOME-repo-root-
relative, found them outside the current prefix, printed `Skipped patch
'src/...'` and **exited 0**. `git apply --check` "passed" for the same
reason. Nothing in any exit code disagreed.

The only thing that caught it was the `-listfull vsavjw` assertion, which
existed only because the mame.lst gotcha had already been written up.
Fixed three ways: `patch -p1 -d` instead of `git apply` (no repository
semantics), a post-apply grep asserting both files carry the change, and
an end-to-end assertion that the BUILT BINARY knows `vsavjw` — plus the
inverse for `WIDE=0`, so a reference binary that accidentally carries the
profile also fails loudly. Same family as the FBNeo CRC trap: **the
toolchain reports success while silently substituting nothing.** Treat
"it said OK" as unverified in every build step.

### The SECOND false green, caught the same way

The first WIDE gate run came back 36/36 — and was **invalid**. The WIDE
binary was MAME **0.289**, the reference **0.288**, so the emulator
superset invariant compared two MAME VERSIONS rather than measuring the
patch. Cause: `git submodule add` stages the DEFAULT BRANCH head, and the
subsequent `git -C emu/mame checkout mame0288` touched only the working
tree — never re-staged. `setup_mame.sh` runs `git submodule update` every
invocation, which faithfully restored the indexed commit (master) and
silently moved the tree to 0.289. The reference had been built before that
reset, the WIDE binary after it. **The drifting-reference trap of 14z-55,
in a new costume: the comparison passes and stops meaning anything.**

Fixed and re-run VALID at **36/36**, both binaries reporting 0.288 and the
two build mirrors differing in exactly the two files the patch touches:
- submodule staged at `27a8d9e8` (annotated-tag note: `git rev-parse
  mame0288` gives the TAG OBJECT `2c38dc6e`, not the commit);
- `setup_mame.sh` hard-codes the pinned SHA and **refuses to build any
  other revision** — a build that silently changes the instrument is worse
  than one that fails;
- `test_mame_wide.sh` now asserts the two binaries report the SAME version
  before comparing them.

Banked observation: 0.288 and 0.289 are **bit-identical** on work RAM and
framebuffer across the 12-replay corpus, so CPS-2 emulation did not change
between those releases. Useful, and not a substitute for pinning.

### A useful side effect: replay.lua's change is proven non-perturbing

`VIDEO_OUT` was added to `tests/lua/replay.lua` BEFORE the second parity
execution, which then reproduced all 24 frozen vsavj oracle logs
bit-for-bit and matched the reference binary on 38 more. So the harness
edit is not merely believed harmless when disabled — it is measured
harmless across the entire frozen corpus.

### Build traps paid for (all in GOTCHAS)

- **MAME's GENie cannot handle a space in the source path**, and this repo
  has one. `scripts/genie.lua:18` has the escaping line commented out
  upstream, and `SOURCES=` builds shell out to `makedep.py` with
  `MAME_DIR` unquoted. **Symlinks do not help** — `getcwd()` resolves
  through them. Hence the rsync'd space-free mirror under
  `~/.cache/vampire-saved/`, with the submodule kept pristine.
- rsync `--exclude 'build/'` is unanchored and also drops `scripts/build/`,
  whose `complay.py` every layout rule needs — surfacing as a baffling
  "No rule to make target ...18w.lh".
- MAME 0.288's OSD is **SDL3, found only through pkg-config**; without it
  the build silently picks framework linkage and dies minutes in on
  `'SDL3/SDL.h' file not found`. Prereqs: `brew install sdl3 pkgconf`,
  then `REGENIE=1`.
- A `SOURCES=`-filtered build **silently omits any driver missing from
  `src/mame/mame.lst`**; both WIDE gates assert `-listfull vsavjw` first.
  The binary is named `cps2`, not `mamecps2`.

## Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)

Build `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` (donovan6, stage 6).

- **HUD pipeline mapped (in-fight top strip is OBJ, staged from
  per-char tables):** emitter `PRG:0x1BB3C` → RAM records at
  `RAM:$FF5D94` → stagers `PRG:0x89370/0x8939C` (mugshot) and
  `PRG:0x89684` (name) → per-char tables `PRG:0x89884` (mugshot
  code words) and `PRG:0x898C4` (name entries, 8B/char). **Stager
  bases differ per game: vsavj adds +0x3800 to table codes, vs2
  adds +0x4200** (live-OBJ measured after the first placement from
  +0x3800-assumed vs2 addresses drew garbage). vs2 twins: tables
  `0x990CE`/`0x9910E`, Donovan row 0x13 (mugshot 0x0B62 → OBJ
  0x4D62 2x2; name 0x0B55.. → 0x4D55 3x1 pal 02).
- **HUD fix (uncommitted last session, corrected + committed now):**
  mugshot = effect_tail place `'0x4D62,2,2' -> '0x3DC8'` (into the
  cells slot 0x0F's own table entry 0x05C8 already points at — no
  code patch); name = place `'0x4D55,3,1' -> '0xBE8C'` (bank-1 pool
  tail) + aux_pokes `hud_name_entry_0f_hi/lo` repointing name-table
  entry 0x0F (0x8993C ← 0x868C0202, 0x89940 ← 0xFFE80003; 0x868C =
  0xBE8C − 0x3800). Live-verified: mugshot entry (0x3DC8 2x2 pal 0A
  at 200,32), name plate (0xBE8C 3x1 pal 02 at 144,40), f2600
  replay 56. Gate: reactions §4 extension.
- **SELECT WHEEL DECODED (docs/engine_internals.md):** the wheel is
  ONE static OBJ record at data `0x272A72` — 18 (code,attr) pairs,
  coords via header pointer → list `0x32A50A` (center-relative,
  shared byte-identical with vs2's list). Cells are fixed
  perspective sizes (3x2/2x2, ONE 3x3); the wheel does not rotate
  or hover-zoom; the cursor ring (pal-1e pieces) just moves.
- **WRONG-CELL TRAP PAID FOR (GOTCHAS entry): the big 3x3 pal-07
  cell (code b4e3 at 264,64) is GALLON's medallion** (top-front
  perspective cell, werewolf face — first read as "Jedah" from the
  pal-07 = char-07 numerology). **Jedah's actual cell = code
  0xB526 attr 0x1214 pal 14 at (236,57)** — identified by
  measuring the cursor-ring center (256,72) in replay 58 and by
  color-rendering the art (purple wing-wrapped icon = the
  maintainer's "still Jedah's" medallion). First attempt shipped
  Donovan onto Gallon's cell (attr+coord retune included); caught
  same-session by ring-center check; fully reverted.
- **Medallion fix (minimal — same 3x2 geometry as the vs2 icon):**
  art = effect_tail place `'0xB10B,3,2' -> '0xB526'` (vs2 Donovan
  icon, identified against Pyron b0f5/Huitzil b108 by color render
  — vs2's wheel pal indices ≠ char ids for the appended trio);
  colors = data_port `med_pal_row14_a` (select pal row 14, block A
  copy 0x3A3A80 only — block B's row 14 belongs to another
  sub-venue — ← vs2 row-05 source 0x3BAFDC). No record retune
  needed. Live row 14 lands byte-equal to vs2's live Donovan-icon
  row. Gate: colors §4 extension (row-14 freeze + record intact +
  Gallon-cell-intact tripwire).
- **Tooling gotcha (GOTCHAS): replay.lua DUMPS separator is `;`,
  not `,`** — comma-joined multi-dumps die rc=3 with no artifacts;
  same-frame multi-window dumps are fine with `;`.
- Verification: colors + reactions gates extended and green on
  `b91647c7`; full battery queued (results below when done).
- Select screens (mode-select wheel view + VS splash) visually
  re-verified: Donovan medallion in Jedah's ringed cell, Gallon's
  werewolf 3x3 restored, VS-splash big portrait + name were already
  correct.

## Session 14z-58e (handoff hygiene: reproducibility PROVEN)

Closing checks before handing off, all green:

- **The committed patches rebuild the emulator from a pristine tree.**
  Reverted the submodule working tree entirely (including deleting
  `harness.cpp`), ran `tools/setup_fbneo.sh`, and the resulting binary
  passes the full WIDE gate — **36 checks**. So `0001` (frontend harness
  incl. framebuffer + gfx dumps) and `0002` (WIDE descriptor + the one
  gated core line) are complete and self-sufficient; nothing this session
  achieved lives only in an uncommitted working file.
- HANDOFF.md updated: it is the first read of any session and still
  described only the Donovan/M2b world. Now carries the WIDE section
  (what/why/status/exact commands/authoring rules) and the gates added
  since. Its FBNeo row also corrected — the old "loads CRC-changed
  patched zips" claim is what made the 14z-57 CRC trap so expensive.

Handoff state: B0-B4 green, gate 36/36, working tree clean apart from the
expected submodule modification. Next session starts at B5 (MAME parity)
or Phase C (address-space model) — both specified in NEXT_SESSION.

## Session 14z-58 (WIDE B4 GFX: PASS — the new banks are real, and the CRC trap)

**The profile's central question is answered: the appended graphics banks
are usable.** With the emulator-side canary relocating bank-2/3 sprites
into WIDE banks 4/5 at draw time, group C loaded as a byte copy of group
B, and the STOCK rom on both sides: **9/9 legacy replays RAM- AND
pixel-identical.** Fifteen characters' sprites are being fetched from
address space that did not exist before, and nothing moves by one pixel.
The 19-bit tile address works end to end: descriptor -> loader -> bank
bits -> bit-12 promote -> fetch -> render.

### B4 PRG half: PASS — and the control that saved it from being a lie

Relocated **all 20 per-char sound record arrays** into the extension
(`CPU:$400000+`, 1KB each) and repointed every row of the table at
`PRG:0xBF41A`. RAM bit-identical across 02/01/30.

**My first PRG attempt was VACUOUS and the negative control caught it.**
Relocating only char 00's array "passed" — but pointing that same row at
ZERO FILL also changed nothing, i.e. the row is never read in those
replays. With all 20 rows relocated the zeros variant DOES diverge, so
the identical result is real evidence. Always pair a relocation pass with
"point it at garbage and prove the behaviour changes".

Authoring notes for extension content: above `PRG:0x0FFFFF` there is no
encryption (write raw), but the member still needs FILE byte order
(`words_to_file_bytes(words_from_logical_bytes(...))`) and its REAL CRC
in the descriptor.

### Root cause of the 14z-57 failure: FBNeo matches zip members by CRC

The appended members declared the CRC of ZERO FILL while the file held a
copy of group B. FBNeo therefore loaded **0xFF fill** for them — and
still printed `Loading graphics (vsw.31m)... (OK)`. Everything else in
the chain had already been verified correct, which is exactly why it was
so confusing.

**This CONTRADICTS an earlier note in this repo** ("FBNeo verified to load
CRC-changed patched zips (no descriptor change needed)"). That is true
only in the sense that FBNeo does not refuse to run; for gfx/QSound
members a CRC mismatch silently substitutes 0xFF. Corrected in GOTCHAS.

Diagnostic path worth reusing (it is now written up in cps2_wide.md):
1. `FBNEO_HGFX=<off>-<end>` gfx-buffer dump (new harness capability) —
   showed 32-48MB reading 0xFF while groups A/B held data;
2. the decoder ORs into a ZERO-filled buffer, so 0xFF proves the SOURCE
   bytes were 0xFF, i.e. the member never arrived;
3. from there the CRC mismatch was two minutes away.
   Memory-content shorthand: **0xFF = not loaded; 0x00 = loaded but
   empty** (the buffer is memset to 0 at allocation).

### Hardening

- `tools/build_wide_romset.py` now PRINTS the exact descriptor rows
  (name/size/CRC) for every member it writes — paste them into the
  descriptor; a mismatch is silent.
- `tests/test_wide_profile.sh` gained **section 3, the B4 canary**, so
  "the appended banks actually render" is now a standing gate, not a
  one-off experiment. It self-skips (loudly) if the romset was not built
  with `--gfx-copy-group-b`. Full gate: **36 checks green**.
- Temporary debug probes removed; both FBNeo patches regenerated with
  clean scopes.

### Status

PRG 6MB / GFX 48MB / QSound 16MB: declared, inert, and — for gfx — proven
USABLE. Remaining for B4: the PRG half (relocate real data above 4MB and
repoint one pointer; require bit-identical RAM). Then B5/B5b.

## Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)

The redesigned canary works as a diagnostic: `CPS2_WIDE_CANARY=1`
relocates bank-2/3 sprites into WIDE banks 4/5 **at draw time**, with gfx
group C loaded as a byte copy of group B, running the STOCK rom. Work RAM
is bit-identical (the ROM is untouched — single variable, as intended);
pixels differ on ~4,400 frames.

**What is now PROVEN (all measured this session):**
- The regions are genuinely real, from the emulator's own load report:
  `68K ROM 0x00600000`, `Graphics 0x03000000`, `QSound 0x01000000`.
  B0/B1/B3 are not paper changes.
- All twelve gfx members load OK, group C included.
- **The 19-bit address path is CORRECT.** Instrumented at the composition
  point: `y=0xb065` -> `n=0x0536CA` -> byte `0x29B6500` = bank 5 at
  offset `0x9B6500` within group C — exactly the offset the source tile
  occupies within group B. The guard passes (`mask=0x03ffffff`,
  `len=0x03000000`).
- **Group C's content is not what gets fetched**: a zero-filled group C
  and a copy-of-group-B group C render identically.

**Therefore:** sprite record -> bank bits -> promote -> address -> guard
are all correct, and the failure lies in WHERE THE LOADER PUT THE BYTES.
Suspect `Cps2LoadTiles`/`Cps2LoadOne`/`CpsGfxLoad` advancement for a
third group.

**Next step is one measurement, not a guess:** dump `CpsGfx` around byte
`0x29B6500` at runtime and compare with the expected tile at
`0x19B6500` (group B). Differ -> load-map bug, and the address path is
exonerated. A gfx-buffer dump is a small harness addition and is on the
B5b instrument list regardless.

Housekeeping: debug printfs removed; the env-gated canary probe is kept
(it is a genuine diagnostic and is off by default); patch 0002
regenerated; **profile gate re-run green 24/24 with the canary off**, so
the tree is in a known-good state.

Also worth recording: two self-inflicted detours cost real time — running
the instrumented build WITHOUT `FBNEO_HVIDEO` (no video => the sprite
path never executes => no output, which looked like "the flag is not
set"), and forgetting that the runner captures the emulator's stdout to
`<sandbox>/fbneo_replay.log` rather than the terminal.

## Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)

**Result: the canary was wrong, not the profile.** Recording it in full
because the reasoning matters more than the outcome.

The canary: make gfx group C a byte copy of group B, remap 15 characters'
per-char bank rows from banks 2/3 to WIDE banks 4/5, require
pixel-identical rendering. It diverged on RAM *and* pixels from ~f894.

Diagnosis, in order:
1. Suspected the game masked the new bank bit away. Found five
   `andi.w #$6000` sites and widened them all to `#$7000` — **no change**,
   hypothesis dead.
2. Ruled out `nCpsObjectBank` (it is the OBJ RAM double-buffer selector,
   not a tile bank).
3. **The isolation that actually worked, and should have been first:** ran
   the modified program under MAME, which has NO extended-bank support at
   all. RAM diverges there too, at frame 890. So a game-behaviour change
   fully accounts for the result and the canary says NOTHING about the
   emulator's 19-bit path.

**Two findings banked (both documented in engine_internals + GOTCHAS):**
- **The game emits the WIDE encoding correctly.** y-word census of the
  modified program (objy_bits.lua under MAME): `bit12=1`, bank field
  shifted exactly as designed. Nothing strips the bit — the game side of
  19-bit addressing is fine.
- **The per-char OBJ bank word (PRG:0x282D4, opcode view) is NOT
  display-only** — it drives game logic too. Vanilla row values recorded
  in engine_internals. Any future tile-bank repoint must expect a
  behavioural change, not a cosmetic one.

**Redesigned canary (next action, spec in docs/cps2_wide.md):** change the
EMULATOR under a test-only env flag instead of the ROM — OR 0x1000 into
bank-2/3 sprites' y-words at the promote point, run the STOCK rom, and
require both RAM (guaranteed identical, no ROM change) and framebuffer
identical. Then exactly one subsystem can explain any difference.

Profile status is UNCHANGED and still honest: PRG 6MB / GFX 48MB / QSound
16MB declared and proven inert (B0-B3, 24/24 each); usability of the new
space remains UNPROVEN until the redesigned B4 passes. No content should
be authored into the extension before then.

## Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)

**B2 done: the profile's ONLY core emulator edit is in and proven inert.**
`Cps2Wide` flag (defined beside `Cps2Turbo` in cps_rw.cpp, extern in
cps.h, set by `Cps2WideInit` for the vsavjw driver only, cleared in
DrvExit so it can never leak into another game) gates the 19-bit sprite
tile address in cps_obj.cpp:

    if (Cps2Turbo || Cps2Wide) {
        if (ps[1] & 0x1000) ps[1] |= 0x8000;      // bit 12 -> bit 15
        n |= (ps[1] & 0xe000) << 3;               // 19 bits, 64MB reach
    }

Gate: 24/24 bit-identical, work RAM AND framebuffer.

### THE FINDING OF THIS SESSION: the FBNeo gate never rendered a pixel

The harness ran every frame with `pBurnDraw = NULL`. Correct for a
work-RAM oracle, but it means **the emulator-side gate was structurally
blind to the entire video path** — and B2's change lives ENTIRELY in the
video path. A RAM-only gate would have reported B2 green without ever
executing the modified line. (Every pixel test the project owns is
MAME-side; FBNeo had none.)

Fixed: opt-in framebuffer checksums in harness.cpp (`FBNEO_HVIDEO=<path>`,
16bpp off-screen render, per-frame FNV-1a; default still pBurnDraw=NULL so
every frozen expectation is untouched). Verified live: 384x224, 3,932
distinct checksums across one replay, so it is genuinely rendering.
tests/test_wide_profile.sh now compares RAM **and** framebuffer on both
invariants. This is also the first delivery of a B5b instrument — FBNeo
now has a pixel gate, which the FBNeo-only fallback would require anyway.

**Inertness is not functionality** — stated explicitly in the gate output.
B2 proves the 19-bit path is harmless (vanilla never sets bit 12). Proving
it REACHES the new banks is B4's job, and B4 must carry that positive
control.

### B3 — PRG 4 -> 6 MB: green, and A1's prediction held exactly

Four appended 512KB program members. **Zero emulator core lines**, as A1
measured: FBNeo maps program ROM as `SekMapMemory(CpsRom, 0,
nCpsRomLen-1)`, so the declaration is the mapping. 24/24 bit-identical
(RAM + framebuffer). Notes for whoever authors into it:
- everything above `PRG:0x0FFFFF` is OUTSIDE the CPS-2 encryption window,
  so extension space is RAW — easier to author into than the original
  in-crypt hole A;
- `$400000-$40000F` (CpsFrg registers) is now read-shadowed by ROM and is
  reserved, never-allocate. Writes still reach the register handler.

**The full v1 shape is now declared and inert: PRG 6MB / GFX 48MB /
QSound 16MB, for a total emulator cost of ONE widened condition.**

But: every step so far is ZERO-FILLED. The space is declared, not
demonstrated. B4 is the step that proves it usable, and it must carry the
positive controls (relocated anim block executing from the extension; a
legacy tile rendering from gfx group C with bit 12 set).

Also fixed: the `--full` fingerprint's region classifier put the new
program members under gfx/qsnd (it keys off filename; FBNeo keys off
descriptor type). WIDE members are now named so the heuristic stays
right, and the tool documents that it hashes the union of resolved zips —
a superset of what the driver loads, so it is an artifact identity, not a
statement of what was mapped.

### Second trap: a drifting A/B reference is worse than none

The first emulator-superset run "failed" 5 replays. Cause: the reference
binary predated the harness video feature, so it emitted no framebuffer
log — noise, not signal. A reference must differ from the build under test
by EXACTLY the patch under test; `WIDE=0 tools/setup_fbneo.sh` now builds
one from the same tree state, and the docs say so.

Patch hygiene: the two FBNeo patches were regenerated with clean scopes —
`0001-vampire-saved-harness.patch` (frontend only: makefile, main.cpp,
harness.cpp incl. video) and `0002-cps2-wide-v1.patch` (exactly the five
CPS-2 driver files). Trust surfaces stay separable, as Rule 1 v2 requires.

## Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)

Both steps green on the new gate `tests/test_wide_profile.sh`
(12-replay legacy corpus x 2 invariants = 24 comparisons per run):

- **B0 — QSound 8 -> 16 MB.** New FBNeo driver entry `vsavjw` (clone of
  vsav) declaring four uniform 4 MB QSound members. **Zero core lines** —
  FBNeo derives nCpsQSamLen from the descriptor table and masks with
  `nCpsQSamLen-1`. 24/24 bit-identical.
- **B1 — GFX 32 -> 48 MB.** One appended group of four uniform 4 MB
  members (the loader consumes gfx four at a time and mis-sizes if any
  member differs, so groups of four / equal sizes are structural, not
  stylistic). 24/24 bit-identical — **A3's prediction held**: no legacy
  draw depended on the 32 MB address wrap.

**The two invariants, both enforced every run:**
1. *Emulator superset invariant* (Rule 1 v2 clause 3) — the patched binary
   running STOCK vsavj is bit-identical to a pre-patch reference binary.
   `WIDE=0 tools/setup_fbneo.sh` builds that reference. The gate exits 2
   with a loud notice if no reference is supplied; an unrun invariant must
   never read as green.
2. *Profile inertness* — WIDE set vs stock set on the same binary.

**Fingerprint blind spot confirmed and partly closed.** The dispatch
fingerprint hashes PROGRAM members only, so gfx/QSound content and the
emulator profile were invisible to build identity (they survived only as
hand-written registry notes — and the patched builds DO change gfx
members). Added `build_fingerprint.py --full`: whole-set fingerprint plus
a per-region breakdown, which now reports WIDE as 16 gfx/qsnd members /
64 MB against stock's 10 / 40 MB. Promoting --full to the dispatch key is
deliberate future work: it changes every fingerprint and so needs the
registry rows recomputed (expectation CONTENT is unaffected — a registry
update, not a re-freeze).

Artifacts: `emu/fbneo-patches/0002-cps2-wide-v1-qsound16.patch` (kept
SEPARATE from the frontend harness patch so the trust surfaces stay
separable), `tools/build_wide_romset.py`, `tests/test_wide_profile.sh`,
`tools/setup_fbneo.sh` gains WIDE=0/1.

Two traps paid for: FBNeo's `d_cps2.cpp` is not valid UTF-8 (game titles
in local encodings) so scripted edits must be byte-mode; and SKIPDEPEND=1
does not track header/driver changes, so a driver edit needs its object
touched explicitly or the build silently keeps the old descriptor.

NEXT: B2 (the bit-12 promote line under a `Cps2Wide` flag — the profile's
only real core edit), B3 (PRG 4->6 MB, which A1 says costs zero lines),
then B4 the canary build.

## Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)

**The maintainer re-stated the goal and it changes the shape of the
work:** the target is all 18 characters; a stock CPS-2 provably cannot
hold them; the target platform is EMULATION with **FBNeo primary** (it is
the GGPO rollback-netplay reference, which is in the ideal scope), MAME
as oracle where it can follow, MiSTer nice-to-have. The Donovan work is a
**proof of concept** — it proved characters can be ported and surfaced
the limits; it never addressed structuring the ROM for three characters.

**The measured wall** (this is why the pivot is forced, not chosen):

| Resource | Free today | 1 char costs | 3 need | Deficit |
|---|---|---|---|---|
| PRG | 1,112 B | ~338 KiB | ~1.0 MB | ~886 KiB |
| GFX | ~370 tiles | ~16-18K tiles | ~50K tiles | ~6-7 MB |
| QSound | 0 | — | 3 voice banks | ~8 MB |

Slot replacement cannot pay: only ~134 KiB of Jedah's PRG was ever
identified as dead (unaudited, already double-booked), and the GFX
equivalent audit already found the "dead" band held 358 protected codes.

### Decisions taken (maintainer, round 66)

1. **Rule 1 v2 — profile-gated emulator changes.** Emulator edits allowed
   only inside a named versioned profile, bounded/declarative, gated on a
   driver flag, and subject to an **emulator superset invariant** (patched
   binary + stock vsavj must reproduce frozen vanilla expectations
   bit-for-bit). Ratified per profile version.
2. **Size the profile ONCE**: PRG 6 MB / GFX 48 MB / QSound 16 MB
   (every size change forces a full expectation re-freeze).
3. **MAME**: attempt the pinned source build; FBNeo is primary if
   alignment becomes a wall — **but losing MAME must never mean losing
   test coverage** (maintainer's rider). The FBNeo-only path is gated
   behind porting the instrument set into harness.cpp and PROVING
   equivalence by re-deriving known findings.
4. Phase A measurements before any growth.

Profile spec drafted: **docs/cps2_wide.md** (v1 DRAFT, awaiting
ratification after Phase B). Approved plan archived at
~/.claude/plans/glowing-bouncing-iverson.md.

### Phase A — ALL FOUR GREEN (tests/audit_wide_phase_a.sh, vanilla corpus)

- **A1: PRG growth is FREE.** Zero reads into any candidate extension
  window across the whole legacy corpus. FBNeo already maps program ROM
  as `SekMapMemory(CpsRom, 0, nCpsRomLen-1)`, so growing to 6 MB costs
  **zero core lines** — the `$A00000` fallback window is unnecessary.
  Instrument ground-truthed first (control window saw 252,705 work-RAM
  reads) so the null result is evidence, not blindness.
- **A2: the 19th tile bit exists — but NOT where the plan said.**
  **y-word bit 15 is the CPS-2 sprite-list TERMINATOR** (`CpsObjGet:
  if (ps[1] & 0x8000) break`), so the proposed 0x6000->0xE000 mask
  widening would have dropped every sprite after the first one carrying
  it. Capcom's own CPS-2 Turbo solves this by promoting **bit 12** after
  the terminator check; measurement confirms vanilla never sets bit 12 on
  a live sprite, so WIDE adopts the Turbo rule. The whole profile now
  costs **one gated conditional** of emulation logic.
- **A3: gfx growth does not disturb scroll3.** No real legacy code
  reaches the 0xC000 wrap threshold (max real code 0x0; only the 0xFFFF
  blank sentinel sits high). First pass reported a false BLOCKED because
  the raw census counted the sentinel — corrected with a real-vs-sentinel
  split. B1's pixel gate remains the definitive confirmation.
- **A4: Z80 is not a constraint.** 27,727 B free in vm3.01/02 (largest
  run 13,961 B) — ample for new sample-table rows. This was the only
  completely unmeasured region in the project.

New instruments (committed, rerunnable): tests/lua/unmapped_probe.lua,
tests/lua/objy_bits.lua, tools/audit_z80_space.py, plus a real-vs-sentinel
census added to tests/lua/scroll3_watch.lua (its existing SCROLL3SUMMARY
contract untouched; the new data is a separate SCROLL3CENSUS line).
Three GOTCHAS paid for: the terminator trap, censusing without knowing a
structure's terminator, and the tap-installer reentrancy segfault.

### NEXT: Phase B (prove the profile inert, one variable per build)

B0 QSound 16 MB (legal today, rehearses the workflow, fixes the
fingerprint's blind spot) -> B1 GFX 48 MB zero-filled -> B2 the bit-12
line under `Cps2Wide` -> B3 PRG 6 MB -> B4 the canary build (relocate an
EXISTING character's anim block into the extension + one legacy tile into
the new gfx group, both against a bit-exact vanilla oracle) -> B5 MAME
parity / B5b suite preservation.

## Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)

**THE MUSIC BUG, SOLVED (measured, not theorised):** vsavj's sound-id
range **0x700-0x7FF holds MUSIC TRACKS**; vs2 reuses that exact range
for **Donovan's voice bank**. Profiling every id his table uses on both
sets (voice count / key-on count / sample identity — the music
signature is unmistakable: 8-15 voices, dozens of key-ons, 4-12
distinct samples) gives the definitive breakdown of his 47 table ids:
  - **6 SHARED** (0x110 0x111 0x112 0x119 0x152 0x202) — same id, same
    sample content on both sets;
  - **30 are MUSIC TRACKS on vsavj** (0x700-0x71F, 0x750-0x757);
  - **9 have NO sample in vsav at all** (vsav's sample ROMs are full);
  - 2 are vs2-silent anyway.
That is why 214P/214K played music in round 2. The session-5 theory
("same ids mean different things") was wrong in general — most ids ARE
shared — but accidentally right about the range Donovan leans on.

**Phase 1 shipped (build ae701ffb):** 13 stubbed sound-farm rows
restored to their vsavj same-id entries (content-verified per id,
including the odd-shaped 0x18d entry whose vsavj twin is byte-identical
at 0x424E); 11 rows kept silent, each now carrying its MEASURED reason
instead of the blanket session-9 note. **Honest caveat: those 13
entries never fire in any of our 8 Donovan replays** — correct, but
currently inaudible.

**Where Donovan's sound actually lives (and why it is still silent):**
the per-node walker path — ported dispatcher (built at ~0xCE3B8) reads
`lea 0xBF41A,a0; movea.l (a0,charid*4),a0; move.w (a0,idx*8),d1` then
calls the helper. That helper stub absorbs **~400 calls per match**.
Enabling it needs Donovan's own record array because slot 0x0F still
resolves to JEDAH's array (~40 entries) while Donovan's scripts index
up to **43** (measured, replays 12/25/56) — so it would both play
Jedah's sounds and read past the array end into neighbouring data
(random ids, music range included).

**Implemented but BLOCKED ON ROM SPACE:** a new declarative generator
kind `[[sound_table]]` (tools/gen_donovan_patch.py) ports a per-char
record array with an **id allowlist**, zeroing every unplayable id —
the engine's dispatcher skips `id == 0` (`tst.w d1; beq`), so those
sounds stay silent instead of playing music. The manifest row
(don_sfx_records: 44 entries, keep_ids = the 6 shared) is written and
COMMENTED OUT: it needs 0x160 bytes and **both code holes are full** —
allocating it evicts the two ls_freeze site_thunks. Tried hole a and
hole b; neither fits. New decision queued (see Decisions pending).

**Gate added: tests/test_don_sound.sh** — sound is invisible to every
RAM and pixel gate we own, so this is the only detector. It replays 4
Donovan scripts, taps the 68k sound ring, and (a) FAILS if any
0x700-0x7FF id is ever enqueued (the music tripwire), (b) freezes the
exact id inventory per replay. Green on ae701ffb; inventories verified
deterministic across two passes each.

Instruments promoted: tests/lua/ring_tap.lua (ring id tap),
tests/lua/qs_sweep.lua + tools/qs_analyze.py (14z-51). Gotcha paid:
a 68k `move.l` reaches a memory tap as TWO word writes, so the sound
id lands at entry+2, not entry+0 — a tap keyed on +0 sees only zeros.

## Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)

Method: built the ring-poke + chip-write-tap instrument
(tests/lua/qs_sweep.lua + tools/qs_analyze.py; full path decode in
engine_internals "Sound subsystem"). Swept ids 0x000-0x7FF on BOTH
games in silent test mode; extracted per-id QSound key-ons
(bank/start/end -> sample address -> content compare across images).

FINDINGS (docs/m5/keyons_*.json = the measured id maps):
- **Shared sfx keep IDENTICAL ids across the family.** All 14
  content-shared stubbed MOVE-sfx ids exist on vsavj as the same id
  keying the same (relocated) sample. NO id translation table is
  needed for these.
- **The session-5 "same-id = music in vsavj" theory is DEAD** —
  vsavj 0x136/0x137/etc are the same sword/impact sfx as vs2's. The
  round-2 music-on-214P bug therefore has a DIFFERENT mechanism
  (suspects: the (6,a0,d2.w) dispatcher-table indirection, or id
  corruption through the farm-call path). MUST be re-diagnosed with
  the new instrument before any unstub ships.
- **vs2-only content (absent from vsav's sample ROMs): ids 0x71D,
  0x73E, 0x753, 0x754, 0x755, 0x756** — Donovan voice lines/new sfx;
  0x14A and 0x173 are same-id-DIFFERENT-content (vsavj reuses them);
  0x747 keys nothing on either side yet (params/window). vsav's
  11m/12m are FULL (zero blank blocks): porting voices = grow the
  QSound sample region (descriptor-level change, CLAUDE.md rule 1
  allows load-map changes) or replace something. DECISION MATERIAL.
- Instrument notes: ring FF0E0E/index FF1E0E (a5=FF8000, negative
  displacements — the FF8E0E literal is a sign-extension trap);
  Z80 chip triplets at D000-D002; bank reg belongs to voice+1;
  12-frame sweep windows misattribute delayed-attack sfx.

NEXT (in order): (1) re-diagnose the 214P/214K music mechanism with
the sweep instrument on the DONOVAN BUILD (poke the exact farm-path
ids, watch what reaches the ring); (2) decide + implement the
shared-sfx unstubs; (3) the voice-samples decision.

## Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)

Maintainer decision: freeze before starting M5 sounds ("this is
mechanically sound as far as we can tell"). Procedure per the
M2b-CORE precedent (e14e591):

- `tests/expected/registry.tsv`: `b91647c7…` -> `donovan-m2c`
  (all 8 patched vm3 gfx member sha1s in the note — group A now
  carries effect-tail/HUD/medallion art, so A-members are recorded
  alongside B for the first time).
- `tests/expected/donovan-m2c/`: 14 authored .masked rows (the
  current battery-measured inventory — NOTE 08_challenger_join is
  `flicker 1 3507` here vs m2b's `2 3507,3807`, and 29/30 gained
  masked rows, both post-m2b gate additions), 16 .skip rows (every
  vsav2-target replay incl. the 14z-era native ground-truth
  replays 51/52/57), and self-frozen sha1+log expectations for the
  33 vsavj Donovan replays, frozen on b91647c7 (each run twice,
  determinism-checked, by run_suite --freeze).
- SYNC BUG CAUGHT AT FREEZE TIME: `run_suite.sh` carries its own
  MASK copy ("must stay in sync with M2A_MASK") — it still had the
  two-window basis; the third window would have failed every
  masked row of the freeze suite. Synced + comment updated. The
  duplication is a standing trap; if a fourth window is ever
  added, grep for MASK_RANGES consumers.
- Validation: freeze pass green; plain `run_suite.sh` pass green
  end-to-end by pure fingerprint auto-detection (masked rows
  validated against authored expectations in that pass — freeze
  mode does not check them).
- HANDOFF build registry row added; patch_index status updated.

## Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)

- Maintainer asked whether Donovan's icon could ride Jedah's vanilla
  row 14 (no recolor -> no mask window at all). MEASURED, twice:
  (a) raw palette swap: Donovan renders purple-faced (skin indices
  land on Jedah's lavenders); (b) index-remapped art onto the
  vanilla row (best hand-tuned map): the icon's 7-step brown ramp
  collapses onto Jedah's 3 browns — face flattens to two tan bands,
  hair goes muddy blue-grey. Both renders shown to the maintainer
  (session scratch med_pal_ab.png / med_pal_tuned.png; method: the
  gfx_tiles offline renderer + live palette dumps). CONCLUSION: the
  recolor is genuinely required; option C (remap) rejected on
  quality, option B (truncate 05's verification) rejected on
  coverage.
- **THIRD MASK WINDOW RATIFIED (maintainer, round 64): option A
  stands.** Decision moved from pending to made below. Their
  condition — "document in detail what's the window we're ignoring
  ... best be prepared in case we need to confirm one day" —
  honored three ways: the expanded docs/atlas/ram.md row (now
  carries both expected content values + when-to-rerun triggers),
  the m2a_common.sh basis comment, and a NEW SCRIPTED AUDIT:
  `tests/audit_mask_window_ff4182.sh` — reruns the original
  attribution measurement (05_timeout_idle f9126 on vanilla +
  build) and asserts (1) vanilla slot == vanilla row, (2) build
  slot == the designed ported row, (3) every neighborhood byte
  OUTSIDE the window ($FF4140-$FF41DF) is identical — i.e., the
  blind spot hides the designed diff and NOTHING else. On-demand
  (not battery): run on any new $FF41xx-adjacent divergence, row-14
  retune, or before extending the window family for Huitzil/Pyron.

## Session 14z-49c (round 63: 14z-49 maintainer-CONFIRMED)

- Maintainer, on `b91647c7`: **"both medallion portraits are clean,
  no regression, great success"** — the select medallion and the
  in-fight HUD mugshot/name close CONFIRMED. The whole 14z-48b
  venue-asset family is done.
- Still outstanding from their side: the full-cast ES-finish pass
  (their earlier commitment, unprompted here).
- The third-mask-window ratification was NOT explicitly addressed
  in the confirmation message — it remains in Decisions pending
  until they answer it directly.

## Session 14z-49b (battery divergence root-caused: the palette-fade staging buffer; THIRD MASK WINDOW — **MAINTAINER RATIFICATION NEEDED**)

First battery on the 14z-49 build FAILED two ways; both root-caused
to completion the same session (rule 6 honored):

1. **05_timeout_idle masked live-state diverged at f9126** (first
   red on this replay ever; batteries 43-48 green). Byte-for-byte
   attribution: the divergent bytes `RAM:$FF4183-$FF41A1` are select
   palette-block-A row 14 — vanilla values vs the 14z-49 ported
   Donovan-icon values, F-bright applied, row slot based at $FF4182.
   Mechanism: **venue fades stage palette-block rows through a
   work-RAM staging buffer** ($FF4182 + row*0x20 family); f9126 is
   the match→win fade after the round-1 timeout (Lilith CPU win).
   The medallion recolor is a DESIGNED content change to that ROM
   row, so the buffer now legitimately differs wherever a fade
   stages block A — even in legacy replays that never touch slot
   0x0F. Crucially: the live select screen itself does NOT stage
   through this buffer (frames 1-9125 incl. the full select were
   bit-identical), and the win screen's OWN palette overwrites row
   14 — **legacy win screens pixel-compare 0-diff vanilla vs
   patched (f9200 + f9400 measured)**. Display-only, no gameplay
   surface, no visible surface.
   FIX: third masked window `$FF4182-$FF41A1` (M2A_MASK
   "4182-41a2"), narrowly the one row slot; docs/atlas/ram.md row
   added; all 14 frozen masked vanilla logs regenerated with the
   new basis (m2a_freeze_masked). Chosen over demoting 05 to a
   first-divergence constant because the mask keeps all 12,120
   frames verified (the replay's post-round state machine coverage
   lives AFTER f9126). **This is a legacy-oracle basis change —
   the two existing windows are maintainer-approved, so this one
   is flagged PENDING MAINTAINER RATIFICATION** (revert = drop the
   mask range + re-freeze, cheap). Standing-watch note: this was
   root-caused, not tolerated — the class is "designed content on
   a display path", not flicker growth.
   Follow-on fact for M3: ANY select palette-block content change
   (Huitzil/Pyron rows later) will surface in this buffer family —
   extend the window with measured slots at that time.

2. **Pixel menu gate FAIL frames 950/1250 (880 px)** — the gate's
   own 14s design note predicted this exactly ("full-frame compare
   is valid until the wheel mugshot itself is ported, then this
   needs a mask"): the 880 pixels are the intended Donovan
   medallion diff on the two wheel-visible frames. FIX: the
   promised mask — the 48x32 cell box screen (172,41)-(220,73)
   zeroed on both sides for 950/1250; the box's correctness is
   covered by the colors-gate medallion locks + the build-time
   byte-exact art assert. Title frame 650 stays full-frame.

**Battery re-run on the new basis: GREEN** (battery_49b): 05 masked
bit-identical full-length again; flicker inventory IDENTICAL to
frozen (03@829,2093 / 10@3007,3129 / 16@829 / 04@1525,2009,2195 /
08@3507 / 09@829 / 29@2436 — no growth, standing watch satisfied);
divergence constants unchanged (06@700, attract@4278, pick@1080);
pixel gates pass with only the medallion box masked (650
full-frame). All 14z-49 gates green on `b91647c7`.

## Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)

- **All half-circle moves register and execute properly; graphics
  good** (maintainer, dbbcd74c).
- Maintainer challenged the "no vsavj equivalent" wording —
  correct challenge; precision note added to 14z-48 below (their
  standing ask honored: findings documented — the command/motion
  subsystem now has an engine_internals section).
- **IN-FIGHT HUD ITEM SHARPENED (maintainer captures, Desktop
  22.42.45 ours / 22.38.20 vs2): the mugshot beside the timer is
  JEDAH'S ART (yellow/red) and the name text reads "JEDAH" — vs
  vs2's brown Donovan mugshot + "Donovan" name.** Not a palette
  issue: the wrong PORTRAIT + NAME. Visible in every session
  snapshot in hindsight. = the M2b "select portrait/name/mugshot"
  remainder, one family with:
- **RE-LISTED: character-select portrait MEDALLION still Jedah's**
  (forgotten off the queue; now tracked). All three surfaces
  (select medallion, HUD mugshot, HUD name) = per-slot venue asset
  tables — one investigation, the 14z-45 method (find the venue's
  per-char art/palette/name sources, repoint slot 0x0F; the name
  text also needs Donovan's glyphs — check what the VS-screen name
  uses, ours shows correct "Donovan" there... verify).

## Session 14z-48 (round 58: HALF-CIRCLE MOVES FIXED — the farm-helper-match had collapsed distinct motion tables; battery pending at entry time)

Round-58 results first: ES arc fully maintainer-confirmed (their
input issue, feel adequate, finishes clean incl. match-end ES LS);
select blink confirmed dead; NEW MINOR tracked = in-fight HUD
portrait palette (task list); NEW BLOCKER = no half-circle move
works (41236P Blizzard Sword / c.63214MP-HP Sword Grapple / 41236K
Press of Death EX) — all fine on vs2, never tested before on ours.

ROOT CAUSE (fully traced, build dbbcd74c):
- Command flow: per-char eval handler (table 0xD7718[char] -> the
  ported Donovan code) calls tiny ENGINE MOTION HELPERS (`lea
  <step-table>(pc),a3; bra <tracker-dispatcher>`; family at vs2
  0x29114-0x291EC = vsavj 0x29DC2-0x29F42), each = one motion shape.
  Trackers live in the player obj (+0x308..+0x338 per command);
  dispatcher state machines: state 2 = 4-bit direction-code match
  vs +0x12A, state 4 = 0x7700-bitmask match vs +0x1AC|+0x1AE; the
  dispatchers ARE proper twins (vs2 0x292A4 == vsavj 0x29F4A etc.).
  Step tables are DATA-view (lea(pc) + (a3,d0) reads — the 14z-43
  gotcha applied to the analysis itself: first dump used the wrong
  image).
- THE BUG: three reconciliation rows from the fuzzy
  "farm-helper-match" ladder mapped vs2 helpers to WRONG vsavj
  helpers: 0x2915C AND 0x29164 (the 63214 pair, tables
  [1,5,4,6,+12]) BOTH -> vsavj 0x29EBA (different table AND
  different dispatcher kind); 0x2916C (the 41236 triple-table) ->
  0x29E42 (shifted table). PRECISION (round-59 maintainer
  challenge, verified by caller scan): vsavj HAS half-circle
  motion tables — its near-match helpers (0x29E22/2A/32/3A...) are
  called from a dozen vanilla char code blocks (Morrigan Valkyrie
  Turn, Lilith Mystic Arrow / Gloomy Puppet Show, Bulleta et al.).
  What vsavj lacks is a BYTE-EXACT copy of VS2'S RE-TUNED versions
  of these three tables: 63214 = vsavj [1,5,4,16] (4 steps, final
  dir+flag fused) vs vs2 [1,5,4,6,12] (5 steps, final step SPLIT)
  — an input-leniency retune between engine generations, the same
  tuning family as the 14z-42 freeze constants. DECISION EMBEDDED
  IN THE FIX: Donovan's HCs use vs2's exact tables (vs2 input
  feel — the project default); mapping to vsavj's native
  near-tables (vanilla-cast HC feel) remains a two-line
  alternative if playtest ever prefers it. All OTHER
  Donovan helper rows content-verify EXACT (0x29114/1C/24/2C/54/
  9C/D4 -> their targets ✓; 0x29184/8C were already correct
  farm_port rows — the mechanism existed!).
- FIX: the three rows converted to kind=farm_port (param_hex = the
  vs2 table spans verbatim: 0x299CE/0x299DA 6 words each,
  0x299E6..0x29A06 16 words; common = 0x29F4A = the content-
  verified dispatcher twin). The generator's existing farm_port
  emitter places the tables as raw data (data-space reads correct
  in hole a) + 12-byte stubs.
- VERIFIED: Blizzard Sword chain entered at f2627 = ported analog
  0xD7980 of native 0x283E58 AT THE SAME FRAME; snapshots: ice
  deity + snowflake ✓, Sword Grapple giant-sword whip ✓, Press of
  Death deity press with stock consumed ✓. GATE: reaction gate
  section 5 (Blizzard + Grapple chain locks; replays 59/60).
- Census discipline note: matched helpers by TABLE CONTENT +
  dispatcher kind, not code similarity — the farm ladder's
  similarity matching is exactly what collapsed two motions onto
  one target (GOTCHAS entry).

## Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)

The last tracked cosmetic (14z-32) closed, build b43c7352:
- **Mechanism (measured):** at the select venue the accent-marching
  object is NOT the player (a6 = venue obj ffb880, +0x382 = venue
  id 0x07) so the color-aware thunks' char check always fell to the
  vanilla punch-color slots -> post-confirm blink for non-punch
  picks. The venue objects carry the standard OWNER LINK at +0x30
  (ffb880 -> 0x8400; P2 twin ffba80 -> 0x8800), and the PLAYER
  object already holds the picked color (+0x3AE, e.g. 5 for HK)
  at confirm time.
- **FIX:** all four accent_color_aware thunks extended with a venue
  fallback: owner via +0x30 (movea.w sign-extend), owner char ==
  0x0F -> block = [0x38C1D4].l + color*0x80 (the EXACT match-init
  computation 0x1C670-0x1C68E against the ported block array at
  0x0CEAF0). Null/foreign owner links read ROM byte 0x382 = 0xA5
  != 0x0F -> vanilla (verified). In-match path untouched; legacy
  changes only for owner-char-0x0F.
- **Verified NATIVE-EXACT:** post-confirm (HK) P1 accent rows
  0x0A-0x0D steady across consecutive frames AND byte-equal to
  native vs2's select post-confirm state (direct A/B, both games
  select-confirm-6 at the same frames). Gate: test_don_colors
  section 4 (frozen native rows + steadiness; replay 58 promoted).
- Method note: an early "expected" reference computed from block
  indexing was WRONG (grey ramp) — the direct native A/B was the
  authority; per-frame CONSECUTIVE sampling needed (20f sampling
  phase-locks with the 4f march = false steadiness).

## Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)

The round-41 item (ours yellow deity/lightning vs vs2 blue/white)
root-caused to a SYNTHESIS BUG in the session-8/9 [state_hook]
machinery (build c45bdc45):
- **Mechanism:** the swordless summon fires ext state 0xBE (k=6);
  our stub uploaded seq record 0x2D3 (consecutive-id assumption
  seq_first_id+k); vs2's own case for that state carries **0x2D4**
  (trace-proven, both games, upload at f2913 -> P1 row 0x0B family).
  The full vs2 case census (dispatch table 0x29B6C idx 89-100):
  ids [2cd 2ce 2cf 2d3 2d1 (fixture) 2d4 (290+color) 29e (29e+bsr)
  2cd (fixture)] — consecutive ONLY for the first three (why the
  synthesis sampling looked uniform). Two cases are direct fixture-
  block uploads (base 0x3CB7DC +0x140 by +0x3C3, +color*0x20 —
  targets rows 0x14/0x15 and 0x0E), one adds the COLOR to id 0x290,
  one double-acts via bsr+bra. Vanilla-range ids 0x290-0x29E:
  records DRIFTED between engines (vsavj's content differs).
- **Live-state census (image scan for move.b #state,$14E):**
  Donovan's code writes only 0xB2/B4/B6/B8/BA/BE/C6 (k=0,1,2,3,4,
  6,10). ALL the awkward cases (both fixture, 290+color, bsr) are
  DEAD STATES. Beyond the deity (k=6), two LIVE latent wrong-record
  bugs fixed in the same stroke: state 0xB8 (2d0 -> 2d3) and state
  0xC6, 4 write sites (2d7 -> 2cd).
- **FIX:** [state_hook] seq_ids per-stub map (comma-string;
  _minitoml has no array-of-int support) + generator emits per-stub
  ids, build-time-verified against vs2's OWN dispatch table; dead
  states get safe no-op stubs (jmp ret_equiv — no palette change;
  if a future port writes one, upgrade to the real vs2 case shape —
  the census above is the spec; hole-b budget note: the fixture
  block would need ~0x240, only ~0x1F0 free).
- **Verified:** deity rows 0x0B/0x0C byte-MATCH native at f2960;
  snapshot = blue deity + white/blue lightning (the native look).
  Victim-shock coloring differences at the same frame = shock PHASE
  (ours 2-HIT vs native 3-HIT at the sample — alternating X-ray
  frames), not palette. GATE: test_don_column.sh + native-locked
  rows 0x0B/0x0C (frozen from plant_vs2 f2960).
- Replay promoted: 57_vs2_plant_native.rpl (the native ground
  truth; datums in its header).

## Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)

- **Win screen fixed ✓** (maintainer).
- **Lose/continue screens: NO ISSUE** — maintainer clarifies the
  flow: losing shows the OPPONENT'S win screen (their venue, their
  tables — vanilla content, unaffected) then the SHARED continue
  screen; both clean. The whole rounds-51/55/56 win-screen arc
  closes.

## Session 14z-45 (WIN SCREEN FIXED — palette + composition, native-locked; battery pending at entry time)

One measurement session closed all three round-51/55 defects (build
4f69589d):
- **Mechanism (all measured):** the win-portrait drawer object
  (ffb800; the second object ffb880 = text/frame, already correct)
  takes position AND palette from per-WINNER-char engine tables:
  - position: pc-relative table 0x5F200 (4B/char), read at
    0x5F1A0/A6 by the setter (winner id from +0x382(a4)); entry
    0x0F = Jedah's (0x70,0x80) vs vs2 Donovan (0xF0,0x98) [vs2 twin
    0x6B1EC/table 0x6B210] = EXACTLY the (-128,+24) OBJ shift
    measured entry-for-entry at f4100.
  - palette: `movea.l #$3AD700,a0` at 0x5F1B6 + (color*17+id)*0xA0
    -> 5 rows (0x15-0x19) via uploader 0x1C3A4 (d7=4). Slot 0x0F =
    Jedah's rows = the purple wash (rows 15-17) AND Anita's grey
    silhouette (rows 18-19 = pure grey ramps).
  - vs2's Donovan win-palette: contiguous 5-row sets per color at
    0x3C365C + color*0xB40 (stride = 18 chars x 5 rows; verified
    row-for-row vs native win-screen palette RAM at f4100).
- **FIXES:** code_word x4 (position entries 0x0F AND 0x1F ->
  0x00F0/0x0098; table is pc-relative/program-space -> code rows,
  the 14z-43 gotcha respected) + data_port x8 win_pal_slot0f_c0..c7
  (Jedah's 8 color slices of the vanilla table REPLACED IN PLACE
  with vs2's sets — first-choice hole-b thunk didn't fit: hole B
  watermark 0x3FFE10, only 0x1F0 free; in-place slot-content
  replacement is the cleaner class anyway).
- **Verified:** rows 0x15-0x19 byte-MATCH native at f4100 for the
  gate color; OBJ base entry native-exact (160,32); snapshot
  visually identical to the native reference. GATE: reaction gate
  section 3 extended with win-screen locks (frozen native rows +
  composition base). Tool note: replay.lua DUMPS ranges are
  END-INCLUSIVE (dump = end-start+1 bytes) — trim before comparing
  to frozen hex.
- Residual to watch (maintainer eyeball): non-gate COLORS (the 8
  ported sets are all vs2-verbatim so all should be right); rows
  outside 0x15-0x19 (vs2 has extra win-venue sub-uploads, e.g. its
  0x3C2A3C one-row-per-color block targeting other rows — if any
  element still looks off, A/B rows 0x1A+ next). HOLE-B PRESSURE
  NOTED: 0x1F0 bytes free — future data-carrying thunks need a plan
  (reclaim staged-99 rows or a second hole).

## Session 14z-44c (round 55: WIN-screen item corrected + sharpened)

Maintainer corrections to the round-51 screen captures (they show
the WIN screen — Donovan's victory art over the continue counter —
NOT a lose/continue-specific screen):
- Anita is NOT garbled — she is hard to see because of the wrong
  palette + "weird rendering" (so: palette/render-path defect, not
  missing/corrupt art).
- NEW datum: **BOTH Donovan and Anita are shifted LEFT vs VS2's
  composition** (compare the two captures). Smells like a
  coordinate-BASE difference in the win-venue record composition —
  same investigation family as the 14z-23 select-sword offset
  (which resolved to draw-order/occlusion, via OBJ section bases),
  or a genuine base-X drift in the ported win-screen records.
- Investigation entry points when this item runs: the win-quote/
  win-screen records were ported at M2b ("select/VS/win-quote
  records"); palette = the slot-0x0F-indexed family (maintainer's
  Jedah-colors hunch, round 52); position = OBJ dumps at the win
  screen on both games (the 14z-23 full-entry method) + check the
  venue's section-base words.

## Session 14z-44b (round 54 on 314568f5: ES arc maintainer-CONFIRMED; round-34 speed-mode item closed NO-BUG)

- **ES hit counts correct ✓. ES visuals look correct ✓** (the 14z-28
  aura concern rides the native path and passes the eyeball round).
- **ES finishes "seem corrected"** — provisional ✓ pending the
  maintainer's full-cast pass; the gate (section 4) plus round-1 +
  match-end scripted kills stand as the harness evidence. If any
  cast member shows the neutral pose again, the six 0x51-positional
  records' property-0x19 path is the first suspect (STATE 14z-44).
- **Round-34 item 2 (speed-mode menus: STANDARD/TURBO/AUTO/
  AUTO&TURBO inconsistencies) CLOSED NO-BUG by the maintainer:**
  the same behavior reproduces on NATIVE vsavj — the original
  remark traced to European-vsav expectations or a test-harness
  difference on their side, not our build. The Start-hold-shim
  interaction hypothesis is moot; nothing to investigate.

## Session 14z-44 (maintainer go-ahead: disassembly — the whole ES arc closes in one session)

The round-53 clarification ("1 stock = one banked full bar") +
disassembly go-ahead produced a clean chain of discoveries:

- **METER SYSTEM DECODED (write-tap -> disasm of the writers, most
  of which live in OUR ported hole-a code):**
  - obj+0x109 (ff8509 P1) = **BANKED STOCK COUNT**, cap 0x63 (99) —
    the maintainer's displayed stocks. THE ES GATE FIELD.
  - obj+0x10A.w = current bar fraction, **full at 0x90 units** (the
    gauge adder converts 0x90 -> +1 stock; my "gauge 0x54" readings
    were fractions of 0x90 — no scripted run ever banked a bar).
  - obj+0x105 = ~48f transient raised by any special (gauge-blink);
    obj+0x107 ff/fe = resolver markers (fe = pair downgraded), NOT
    consumption. obj+0x102 = resolved strength/flavor byte.
  - **The ES/strength resolver = ported code at 0xCF598**: reads
    press masks +0x126|+0x128, bits 4-6 = punches, pair table ->
    (strength, flag); for pairs tests **+0x109 nonzero** -> ES,
    else downgrade to lowest-button strength + 0xFE marker.
  - => **NO ACCEPT BUG EVER EXISTED.** All scripted "ES" attempts
    (LS pairs, replay 19's own DP pairs, the vanilla Demitri
    control) had 0 banked stocks. Replay 19's ES coverage
    evaporated because the 14z-42 freeze fix REDUCED HIT COUNTS ->
    less meter -> the same prologue stopped banking a stock (the
    exact "silent soak coverage loss" mechanism).
  - **Scripted ES recipe: POKES ff8509 (e.g. :09) + pair press.**
    Verified on BOTH games (vs2 field identical — the resolver is
    ported vs2 code).
- **ES chain confirmed both sides: vs2 0x284A64 == ours 0xD858C**
  (the block after HP's chain — 14z-43's inference correct), 9-node
  loop x4 base (HP: x3).
- **ES 8-hit undershoot ROOT CAUSE: a THIRD deity record subset.**
  The raw hitbox blob has 14 strided 0x4E type bytes at
  +0x11A9..+0x1349: 14z-36 remapped only the first 7 (sworded).
  The other 7 (+0x1289..+0x1349) = the ES-variant records, still
  0x4E -> class 0x4E -> vsavj property[0x4E]=0 (the 14z-28 revert)
  -> victim's stun peaked 3f, escaped after ~3 hits. Restoring
  property[0x4E]=0x0F alone moved the failure to the 14z-26
  "static shake node, no re-hit" second-consumer divergence (1
  hit) — property is NOT sufficient for class 0x4E, exactly as
  14z-26..28 found. FIX = the 14z-36 pattern extended: 7 region_fix
  rows 0x4E -> 0x06 (vs2-alias-proven: word[0x4E]==word[0x06]) ->
  native class-8 electric chain end-to-end, where the 14z-42
  ls_freeze_vs2 thunks already supply vs2 constants.
- **MEASURED (build 314568f5): ES = 9 hits at ~10f, damage
  011b->0113 == native EXACTLY** (native f2632-2710, ours
  f2633-2718).
- **ROUND-52 ES-FINISH NEUTRAL-POSE KO: FIXED by the same remap**
  (class 8 death = the proven native electric chain): round-1 ES
  kill -> grounded 0x158210 ✓; MATCH-END ES kill (the maintainer's
  exact scenario, replay-54 variant) -> fall 0x157FCC -> grounded
  0x158210 ✓. The death-path class-0x4E hole (14z-28 finding #3)
  remains OPEN in general but is no longer on any live path (no
  record emits class 0x4E/0x51... the six 0x51 ES-positional
  records remain 0x51 -> property 0x19; their hits didn't connect
  at gate spacing — if a maintainer round shows ES anomalies at
  other spacings, A/B the 0x19 handler pair next).
- hit_class_props_ext_lo added (property[0x4E/4F] = vs2 0f 1b):
  vs2-authentic future-proofing; no live consumer after the remap.
- Gate: test_don_reactions section 4 (ES 9-hit lock via stock poke
  + ES-kill grounded lock; replay 56 promoted with native datums).
  Replay 55 (WIP scaffold) superseded by 56.
- RAM atlas: +0x102/+0x105/+0x107/+0x109/+0x10A rows added.

## Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)

Round-52 maintainer results:
- **ES vs Morrigan: still 8 hits** (native claim 9). Maintainer
  suspects distance-dependence — plausible (the far-HP=6 datum);
  needs a same-victim same-spacing native A/B before calling it a
  divergence. PENDING the ES-input/meter work.
- **NEUTRAL-POSE KO REPRODUCED: ES finish at final KO** (vs
  Morrigan). RECLASSIFIES the round-50 flaky bug: it was an ES kill
  all along (trigger = move VARIANT — why the 4 non-ES match-end
  repro variants stayed clean and why the maintainer couldn't
  re-trigger it). MECHANISM SUSPECT: the death path re-reads victim
  +0x54 (the 14z-28 finding #3) — an ES kill leaves class 0x51
  (this build) / 0x4E-with-property-0 (previous build) there, and
  vsavj's death-path class consumer knows neither -> collapse never
  chains -> standing neutral. Native vs2 handles class 0x51 on its
  death path (tables extend to 0x53).
- Visuals: "slightly faster, possibly more VS2-like" (soft signal,
  consistent with property-0x19 now live).
- REPRO ATTEMPT (class poke): normal deity kill + victim+0x54 = 0x51
  poked f2638-2642 -> death chain STILL correct (0x158210).
  INCONCLUSIVE, not a refutation: frame-boundary pokes likely miss
  the same-frame class consume at the fatal hit. The real repro
  needs an actual ES kill.
- **SCRIPTED PAIR-ES ACCEPT IS BROKEN ON CURRENT BUILDS (new hard
  fact, both moves):** replay 19's own ES DP pairs (DR12/DR13, both
  buttons SAME frame, stock byte ff8505=01 present) now produce the
  LP-fallback DP chain (0xD6EE8) — as do 1f-offset pairs with the
  diagonal held, and every LS pair variant. Chain-start nodes prove
  the fallback (DP chains: LP 0xD6EE8 / MP 0xD7050 / HP 0xD71B8,
  stride 0x168). Replay 19 demonstrably produced ES DPs when
  written (session 11 measured the ES crash from them) — the
  behavior evaporated at some unknown build and the no-crash soak
  stayed green (GOTCHAS entry added). MANUAL ES works on the same
  builds (maintainer, rounds 51-52). Also mapped: the stock decays
  during idle (ff8505 1->0 between f3360 and f3455 with no inputs)
  — earlier "too late" ES attempts were doubly doomed.
- **14z-43c meter-field facts (round-53 datum: maintainer ES'd with
  1 DISPLAYED stock — a persistent state):**
  - +0x105 (ff8505) = a ~45-48f TRANSIENT raised by performing any
    special (measured 1 at f3325-3355, 0 at f3370 after DP3 at
    3318; re-raised by the next special). NOT the persistent stock
    the maintainer uses. The real stock counter = UNMAPPED.
  - +0x107 ff->fe fires when a special is performed with +0x105
    recently set — including with NO stock (vanilla Demitri control)
    — it is NOT ES consumption; every earlier "meter consumed" read
    based on it was wrong.
  - Vanilla Demitri scripted-pair control: INVALID as run (no
    stock; chain 0x12E51A = one stride below HP fireball 0x12E69A =
    a fallback, not the ES). Vanilla needs real meter too before it
    discriminates harness-vs-port.
  - Post-DP timing: actionable ~f3360, +0x105 dead ~f3365 — the
    window is ~empty; pair presses during recovery are eaten. More
    replay threading is the wrong tool.
- **NEXT SESSION (bounded, static-first): disassemble the ENGINE's
  ES-accept + meter check** — find the command-accept code that
  distinguishes ES (two buttons) from normal and READS the meter
  (who reads ff8505/06/07 and the real stock field at accept time;
  start from writers via tap on ff8500-ff8510 during a
  stock-gaining flow, then disassemble the readers). That yields
  (a) the true stock field -> POKE it to script the ES reliably,
  (b) whether Donovan's accept differs from vanilla at all. Then
  unlock the whole ES chain: gate, 9-hit A/B, mash, neutral-pose
  repro. Also: disassemble the ported handler's ES branch — Donovan's LS/DP handlers are ported vs2
  code; find the ES-vs-normal decision (which input/meter field at
  which offset, what threshold) in the vs2 source region, check
  what it reads on vsavj, and whether scripted vs manual input
  states differ there (suspect family: the pressed-pair mask read
  at a vs2-era offset, or a meter-threshold field our port doesn't
  feed identically). Fixing scripted-ES accept unlocks: the ES
  gate (chain family after HP's = 0x284A64+/0xD8588+), the 9-hit
  A/B, the mash-to-11 check, AND the ES-kill neutral-pose repro
  (task: death-path class consumer for 0x51). MAINTAINER QUESTION
  queued: what is your meter state when the ES comes out (full
  bar? banked stocks?) — cheap discriminator for the accept
  condition.

## Session 14z-43 (ES class-0x51 port BUILT + crash-gated; the pc-relative/data-space gotcha paid; ES behavior measurement blocked on meter mapping)

The 14z-42c queue item 1 implemented (build 22ada38e, battery run at
session end):
- **The port:** six region_fix 0x51->0x4E rows RETIRED (staged 99,
  the ES-deity records carry native type 0x51 again) + site_thunk
  es_type51_dispatch. Consumer audit of all three $17(a3) readers
  in STATE 14z-42c's plan held up: reaction dispatch already
  extended (case_a2), KO-branch dispatch = the new thunk, byte-table
  assigner unreachable for 0x51 (same as native vs2).
- **GOTCHA PAID (vec3 at the first KO hit, fully traced):** the
  first thunk shape hooked the dispatch's read site and absolutized
  `move.w $185DA(pc,d0),d0` as `lea/move.w (a0,d0)` — but
  pc-relative operands are 68000 PROGRAM-space references
  (CPS-2-decrypted) while (An)-based are DATA-space (raw bytes):
  the read returned ciphertext (data-view table[6] = 0x53BF = the
  measured odd jmp target). Fix: hook the PRECEDING moveq/move.b
  pair (0x185CA) and rts into the untouched vanilla read+jmp — the
  reaction_hook ghost-clean topology. docs/GOTCHAS.md entry added
  (includes the corollary: table-view choice follows the READ MODE,
  not the address — pc-relative tables live in opcodes.bin,
  lea(pc)+(a0,dn) tables in data.bin).
- **Crash coverage GREEN on 22ada38e:** guarded deity-KO (poke),
  guarded ES-attempt run, test_don_reactions all 3 sections
  (round-1 KO, match-end KO, sword-kill) PASS. Residual exposure =
  the property-0x19 reaction handler receiving live ES hits — a
  LEGACY handler (property 0x19 serves vanilla classes 0x09/0x33/…)
  so no crash surface; possible freeze-constant drift there is the
  known follow-up (A/B once an ES replay lands hits).
- **ES behavior measurement BLOCKED, parked:** scripted ES attempts
  all fell back to the LP chain. Chain map established (even 0x244
  spacing, both games): LP 0x284398/0xD7EC0, MP 0x2845DC/0xD8104,
  HP 0x284820/0xD8348 — and the "extension block" the no-mash loop
  jumps over (0x284A60+) is therefore almost certainly THE ES
  CHAIN, never a mash extension (14z-42's mash datum — 3->4 loop
  iterations — stands independently). Pair-button fallback picks
  the LOWEST button (13->LP, 23->MP). Meter fields partially
  mapped: P1 gauge byte ff850B (grows ~0x0C-0x30/action), stock
  encoding at ff8505/06/07 NOT yet decoded (+07 00->ff->fe pattern
  recurs across ES attempts on both games; can't distinguish
  "no stock" from "consumed" yet). NEXT SESSION (bounded): map the
  stock byte properly (tap writes to ff8500-ff8510 across a known
  manual-ES flow), then author the ES gate replay (recipe: replay
  19 prologue + 421+pair with the accept-shape variants — pair 1f
  apart or long DL hold both accept on ours), assert ES chain
  0xD8xxx (ES = HP+0x244 family) + 9 base hits + mash to 11 + KO
  clean. Scratch replays es3/es4/es5 + all findings in the session
  log; input-accept EDGE note: exact-simultaneous pair at DL-release
  frame is accept-flaky on ours no-debug (variants v1/v4 accept).

## Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)

Round-51 maintainer answers:
- **LP/MP mash CLOSED NO-BUG:** maintainer struggles to extend LP/MP
  on native VS2 too ("mechanism likely sound") — matches our
  instrumented 3->4 extension proof. Native behavior.
- **ES UPGRADED to gameplay-accuracy item:** definitely 9 base on
  VS2, ours 8 — and ES mash extends on neither... ours at all.
  MECHANISM HYPOTHESIS (connects to the 14z-35/36 interim): the ES
  deity's 6 records were remapped type 0x51 -> 0x4E (crash fix —
  vsavj's type dispatch ends at 0x4F); vsavj property[0x4E] = 0
  (14z-28 revert) -> ES hits take a PLAIN reaction, not vs2's
  class-0x51/property-0x19 electric path -> different freeze/re-hit
  pacing (one hit fewer) and plausibly no mash sampling. FIX SHAPE
  (next session, 14z-33 discipline — this area crashes when done
  casually): extend the record-type dispatch to 0x51 (existing
  engine-hook pattern), route to the 6-byte copy handler (class :=
  0x51), property[0x51] = 0x19 already present in
  hit_class_props_ext_hi; then A/B the property-0x19 reaction
  handler pair for constant drift (the 14z-42 freeze lesson — may
  need a third freeze thunk there).
- **NEW TRACKED ITEM: Donovan lose/continue screen** (maintainer
  captures, Desktop screenshots 2026-08-01 22.38/22.42): ours has
  (a) the Donovan figure in a wrong washed-purple palette, (b)
  garbled tile blocks bottom-left where Anita's portrait art
  belongs, (c) wrong background composition vs VS2's moon/Anita
  arrangement. Loser-portrait art/palette family — group with the
  M2b select-portrait remainder. MAINTAINER HUNCH (round 52): the
  washed palette "looks a lot like Jedah colours" — mechanically
  plausible (slot-0x0F-indexed palette table unported = serves
  Jedah's rows; the accent/fixture failure family). Check the
  lose-screen palette source first when this item runs.
- **Match-end neutral-pose KO PARKED (maintainer's call):** happened
  once vs Morrigan, not reproducible since ("very flaky... worth
  leaving alone for now"). Our 4-variant clean repro + the new gate
  section 3 stay as the tripwire. If it recurs: victim char + what
  the victim was doing at the kill are the wanted datums.

## Session 14z-42b (round 50: freeze fix CONFIRMED; neutral-pose match-end KO reported — 4 repro variants all CLEAN; context question queued)

Round-50 maintainer results on 4f8220fc:
- **Core fix confirmed: no strength overshoots; feel/speed similar
  to VS2 overall.** HP mash reaches 9 (their reliable native max) ✓.
- **TRACKED (non-blockers, maintainer's words):** (a) ES undershoots
  — 8 minimum vs the 9-13 reference (and 10 max-mash vs theory 11);
  (b) LP/MP get NO mash extension (should reach ~5 / 6-9). Note HP
  mash works (9) and the scripted mash A/B extended 3->4 on both
  games — so the mash READ works; the per-strength extension
  windows/loop params are the suspects. Investigate with per-strength
  node taps (LP=btn1, MP=btn2, ES) vs native.
- **BLOCKER REPORTED: match-end KO with Lightning Sword (possibly
  any special) leaves the opponent in neutral pose again** (the
  round-38 bug family). REPRO ATTEMPTS THIS SESSION — ALL CLEAN on
  4f8220fc (correct grounded death 0x158210 + SPECIAL FINISH, snaps
  verified): (1) round-1 mid-shock kill; (2) MATCH-END (round-2
  clinching) mid-shock kill; (3) match-end kill by the INITIAL
  SWORD HIT (different records than the deity); (4) match-end kill
  during MASH-EXTENSION iterations. All vs Victor, 2P mode,
  standing victim. New replay 54_don_matchend_ko + gate section 3
  close the gate's round-1-only blind spot permanently.
- The bug therefore needs context we don't have: candidates =
  victim char (theirs != Victor?), ARCADE/vs-CPU mode (moving/
  crouching/airborne victim at the kill — our victims always stand),
  the swordless variant or 421K column as the killer, or a round
  pattern other than 2-0. NOTE: 14z-25 (round 38, 421K) never
  reproduced either — this may be the SAME never-fixed pre-existing
  bug, newly visible because the move is now good enough to close
  matches with; not necessarily a freeze-fix regression. QUESTIONS
  SENT to maintainer: exact killer move/variant, victim char, mode
  (arcade or 2P), victim state at the kill (standing/crouch/air/
  mid-move), round pattern, SPECIAL FINISH banner shown or not.

## Session 14z-42 (Lightning Sword: ROOT CAUSE = hit-freeze engine drift; 14z-40/41 suspects all exonerated)

Measurement session on native vs2 (scratch replay recreated per
NEXT_SESSION spec) vs our build (replay 48, no poke). Every 14z-40/41
suspect died under instrumentation; the real mechanism emerged whole:

- **14z-41's PAIR-1 "lost spawner" theory: DEAD, twice over.**
  (a) GUARD_PROBE at vs2 0x82AE2 across the whole native replay:
  ZERO hits — the spawner is never called during Lightning Sword
  (move confirmed on-screen in the same run). (b) The reconciliation
  row was ALREADY CORRECT: manifest maps 0x082AE2 -> 0x077376 and
  the built image calls jsr 0x77376 at 0xCD438. **14z-41 misread
  0x77376 as 0x73376** (one hex digit) and analyzed the phantom
  address; vsavj 0x77376 is the byte-identical spawner twin (alloc
  0x16FBA = vs2 0x15702's analog, ids 0x01006000/0x01006002, unique
  in the image). GOTCHAS entry added.
- Pair 2 (vs2 0x2CE82): also ZERO probe hits whole-replay. Pair 3 =
  the deliberate sound stub. **None of the three reconciled walker
  calls executes during the move** — the 14z-40 inference collapses.
- **Node-path A/B (tap ff841c both sides): IDENTICAL structure.**
  Same 14-node ramp, same 9-node loop (native 0x284988-0x284A48 =
  ours 0xD84B0-0xD8570, port offset +0xB3B28), **exactly 3 loop
  iterations no-mash on BOTH**, same exit link over the extension
  block (4A48 -> 4CA8 = 8570 -> 87D0), same 10-node tail. The
  14z-38 "permanently mashed" theory is DEAD: 7/11/15 were never
  mash caps — they're base-loop hit counts inflated per-iteration.
- **THE DIVERGENCE: attacker hit-freeze per deity hit.** Timer tap
  (obj+0x20) + P2-HP tap, both sides: native = 6 hits, 4-5f freeze
  starting at each hit frame; ours = 14 hits, 9-11f freeze. Longer
  freeze stretches the same 3-iteration loop ~2.1x; the deity's own
  ~10-12f hit cycle fills the longer window with more hits. ONE
  drift = BOTH maintainer symptoms (count + visible slowness).
- **Freeze source found (full-obj tap at hit frame + disasm):** the
  victim-reaction handler pair — vs2 0x226E0 == vsavj 0x23AC8
  (structural twins; property tables 0x27FD8/0x28D00 byte-identical
  through class 0x4D; both handlers fire once per hit, probed). The
  CONSTANTS drifted between engine generations: victim +0x5C = 0x0C
  (vs2) vs 0x18 (vsavj); **attacker +0x5C = 0x04 (vs2) vs 0x0B
  (vsavj)**; vs2 also writes victim $147=0xC which vsavj's handler
  lacks. vsav = older engine; vs2 retuned the electric-shake
  reaction for its rapid multi-hits.
- **FIX (built this session): site_thunks ls_freeze_vs2_victim /
  ls_freeze_vs2_attacker** on the two 6-byte freeze writes (vsavj
  0x23AD8/0x23ADE): attacker link a4 must be a player block
  (0x8400/0x8800 guard — non-player +0x32 words would make +0x382 a
  garbage read) AND char id 0x0F -> vs2 constants (0x0C/0x04); else
  byte-identical vanilla write (CCR-safe: last else-op = the
  original move.b). $147=0xC was first left out and measured:
  constants alone gave freeze 5f ✓ but hit period 7f and STILL 14
  hits — the victim freeze had been doubling as vsavj's only
  re-hit gate; **vs2's victim $147=0xC IS the re-hit gate**. Ported
  into the Donovan branch (flag-identical CCR).
- **RESULT (build fingerprint 4f8220fc, replay 48 no-poke):
  NATIVE-EXACT CLASS — 6 damage events at ~10f period (native: 6
  at ~10f), total damage 10 == native 10 exactly (5-point initial
  sword hit + 5 deity ticks; pre-fix: 22), 3 loop iterations,
  cadence histogram near-identical (1-5f), move 113f vs native
  106f.** Both maintainer symptoms resolved in one
  mechanism-attributed change of two site_thunks.
- **MASH VERIFIED NATIVE-EQUAL: both games extend 3 -> 4 loop
  iterations under identical mash input** (LP/MP alternating every
  3f through the loop window). The mash mechanic was never broken;
  14z-38's input-struct theory retired. Replays promoted:
  51_vs2_immortal_native / 52_vs2_immortal_mash /
  53_don_immortal_mash (native datums in the headers).
- Instruments this session (all no-debugger tap_writes or
  GUARD_PROBE; scratch replay 48_immortal_v2 recreated for vsav2 —
  picks R,R / R,R, 421+HP at 2610-2624, no poke): node tap ff841c,
  timer tap ff8420, HP tap ff8850, full-obj tap ff8400,400 at the
  hit frame, probes 82ae2/2ce82/226e0/23ac8.
- **14z-40's side finding (region-tail zeroed routine, +0x142E)
  CLOSED — NO CALLERS:** vs2's only reference to 0x27570 is `bsr.w`
  at 0x20C9E inside the ENGINE's object-init chain (never ported;
  vsavj objects init through the vsavj twin and its own per-char
  tables). The built image has ZERO references to ours 0xCE7BE
  (jsr/jmp/bare-long/relative all searched). Dead code; the
  table_fix pad stands.
- Walker mechanics decoded along the way (engine_internals TODO):
  node = 0x18 bytes, +0 duration byte -> obj+0x20 countdown
  (decrement PC vs2 0x271C4 = ours 0xCE412), +1 flags (0x80 =
  follow link at +0x18), +4 sprite record ptr, +0x10 the
  [cf14]..[0b] op family; loop node 4A48 links back via +0x18
  pointer 0x284988; freeze holds the decrement (the "floating
  holds" that tracked hit frames, not fixed nodes).

## Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)

## Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)

- Kick-color pick AND Donovan-mirror both byte-identical to native vs2
  (P1 rows 0x0A-0x0F, P2 rows 0x10-0x15; ground truth replays 41/43 on
  vsav2). The alt color set = block+0x180 inside the already-ported
  0x500 sprite block; the mirror alternate is engine-composed from the
  same block. **Table B (0x38C1D8) is never consulted on Donovan's
  paths — the 14z-19 open item closes with no patch.** Locked in
  tests/test_don_colors.sh (frozen native rows; battery section 3b).
- Select-web P2 navigation mapped via live +0x382 hover walks: P2 ->
  Jedah orb = U,U,U (vsavj); P2 -> Donovan = L,L,L,L (vs2 grid).
  Replays 41-43 capture the paths permanently.
- Also validated live: the fixture-override thunk's char-id condition
  ($FF8782 reads exactly 0x0F at the sites' run time in a real match
  flow, both mirror sides trigger).

## Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)

- Pair 3 (vs2 0x5122 -> vsavj 0x2A7E0): DELIBERATE — the
  "stubbed_sound" reconciliation row (the 214-input music-change fix;
  correct vsavj twin 0x4CE2 documented in the row's own note; sfx
  return at M5 with id-table translation). Flow-equivalent (rts), so
  NOT the mash/cadence divergence. Side-answer: this is why Donovan's
  moves are silent.
- Pair 2 (vs2 0x2CE82 -> vsavj 0x2D62A): previously verified
  engine_data row; not re-audited (low suspicion).
- **PAIR 1 (vs2 0x82AE2 -> vsavj 0x73376): THE SUSPECT.** vs2's
  routine = a SPAWNER helper: `jsr 0x15702; beq; move.l #$01006000,
  (a4); move.w a6,$30(a4)` — twice = allocates & initializes TWO
  support objects, owner-linked. The mapped vsavj 0x73376 reads as an
  instruction-fragment tail falling into rts = an EFFECTIVE
  (unintended) STUB — the walker's early-frame call spawns nothing.
  Two lost support objects during Lightning Sword = prime candidate
  for the cadence/hit-count divergence (e.g., the objects drive the
  hit timing/mash sampling).
- NEXT SESSION: (1) understand vs2 0x82AE2's role for this move
  (what the two objects do — tap their slots on native during the
  move); (2) find vsavj's TRUE analog (search for the same spawn
  pattern `4eb9 ... 671c 28bc 0100...` in vsavj) or port the helper
  (it's ~0x30 bytes, calls 0x15702 = the shared alloc — check that
  address's vsavj analog too); (3) fix the reconciliation row,
  rebuild, measure hits (expect 6-7 no-mash HP) and cadence (expect
  ~1.5-5f/node); (4) gate both.

## Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)

- Full instruction-level diff of the ported walker block (x026142 @
  0xCD390, 0x1440 bytes) vs the vs2 original: 92 changed longs, ALL
  accounted for — anim-table repoints (0xD7xxx -> 0xBD87A-family),
  internal port retargets, and the DELIBERATE [table_fix] bank table
  (+0x13EE). The walker's own logic is byte-faithful. Two findings:
  1. The mash/cadence divergence must therefore live in one of the
     THREE RECONCILED ENGINE CALLS inside the walker:
       - vs2 0x082AE2 -> vsavj 0x073376   (region+0xA8)
       - vs2 0x02CE82 -> vsavj 0x02D62A   (region+0xEB2)
       - vs2 0x005122 -> vsavj 0x02A7E0   (region+0x1074)
     One of these is the advance/input helper whose vsavj analog
     drifts semantically (sibling-verified structurally, engine-
     drifted behaviorally). NEXT SESSION: disassemble each pair,
     compare, bridge the drifted one.
  2. SIDE FINDING (potential separate bug): the region tail (+0x142E)
     originally holds a small per-char lookup routine (`move.w
     $100(a5),d0; move.w (pc-table,d0),$1A(a6); rts`) that the
     table_fix pad ZEROED in our build. If anything calls
     region+0x142E it executes zeros. Audit callers next session;
     if called, restore the routine above the rewritten table.

## Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)

Maintainer-provided ground truth (community-corroborated):
- Plant = **214K "Killshread Plant"** (not 421K; input leniency
  accepts both — matches the 14z-31 finding).
- **Lightning Sword (sworded 421P) hit ranges: LP 3-5, MP 5-9,
  HP 7-11, ES 9-13** (base to max-mash). Far HP = 6 only (range:
  after 6 hits the opponent exits reach despite the shock's pushback
  limiting). Max counts need VERY fast mashing; regular mashing gives
  ~half the bonus (maintainer reliably reaches 9 on HP).
- **Our fixed counts (7/11/15) EXCEED the community maxima (5/9/11)**
  — two readings: (a) the engine's hard loop ceiling sits above
  human-reachable mash (ours = ceiling), or (b) our loop count is
  outright wrong. Distinguish next session at the code level.
- **NEW: animation speed** — VS2/vanilla Savior play the move MUCH
  faster; ours is visibly slower. This matches the 14z-37 cadence
  measurement (ours ~11 frames/node vs native ~1.5-5) — a SECOND
  divergence beyond the loop count. Note: ours advances nodes via
  PORTED code (PC ~0xCE38A, in the x05c800 character-code region =
  Donovan's own move handler), while native vs2 advances via its
  ENGINE walker (0x2713C) — the handler/walker division of labor
  differs between the builds and is the prime suspect for BOTH the
  cadence and the loop-count divergence (e.g., handler = the
  mash-advance path firing on garbage input reads; walker = the
  default-timer path).
- NEXT SESSION (bounded): disassemble the ported handler around
  0xCE38A via its vs2 source in the x05c800 region; map the advance
  logic + its input read; bridge; then gate: no-mash HP = 6-7 hits
  AND cadence within native bounds.

## Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)

- Poke experiments: zeroing obj +0x126 / +0x12E / +0x1B0 continuously
  during the move does NOT shorten it (14 hits regardless) — the
  loop condition does not read those obj fields.
- Sharpened theory: ours behaves as PERMANENTLY MASHED — the ported
  vs2 walker's loop-op likely reads the per-player INPUT-STATE
  structures at vs2 offsets; vsavj's input layout differs, so the
  read returns garbage/nonzero = "still mashing" = always loop to the
  cap (7/11/15 per strength = the caps).
- Interpreter note: vs2 advances these nodes with its ENGINE walker
  (PC 0x2713C); ours with the PORTED copy (PC ~0xCE38A, hole a) —
  same vs2 semantics, so the divergence is in what the READ hits, not
  the opcode logic.
- MAINTAINER QUESTION that would confirm cheaply: in VS2, what is the
  actual maximum hit count with maximum mashing? If ~7/11/15 (our
  fixed counts), ours == permanently-mashed exactly, confirming the
  input-read theory.
- NEXT SESSION (bounded, fresh context): statically disassemble the
  ported walker's loop-op handler (the script-op dispatch for the
  node ops [cf14][0b][target]-family) in the vs2 original around the
  0x27xxx walker; find the input/mash read; bridge with a thunk
  (vsavj input state -> the expected field/offset). Then gate the
  no-mash base counts (6-7 hits HP version).

## Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)

- Maintainer: the electric shake holds like VS2 ✓ — but hit counts
  are FIXED MAXIMA (7 LK / 11 MK / 15 HK) vs VS2's mash mechanic
  (base 3/5/7-or-6, extended by mashing; ~9 reachable with HK+mash).
  Measured: ours 14-15 hits vs native 6 at identical inputs (no
  mash) — ours always plays the cap.
- Mechanism mapped this session (all measured):
  - The deity = Donovan's own anim; the multi-hit = a NODE LOOP
    (loop-back node relocated correctly; node data byte-faithful).
  - The loop is executed by the PORTED VS2 WALKER (ours advances
    nodes at PC ~0xCE38A in hole a = vs2's own interpreter code) —
    opcode semantics authentic; the loop DECISION therefore reads an
    ENGINE-MAINTAINED field that vsavj doesn't feed the same way.
  - Candidate fields from the vs2 walker's upstream code: +0x126
    (press mask, `move.w $126(a6)`) gated by +0x169; also +0x1B0
    counter. Registers at the loop-back write are identical across
    games (decision is upstream of the write).
- NEXT SESSION: disassemble the ported walker's loop-op handler
  (around 0xCE2xx-0xCE4xx in the built image / vs2 0x270xx),
  identify the exact mash-condition read, check whether vsavj's
  engine maintains that field during button mashing (tap writes on a
  vanilla mash move), and bridge it (init_shim/site_thunk feeding
  vsavj's input state into the field the ported walker reads). Gate
  afterward: hit-count assertions (no-mash = base counts).
- Ship state: 0a55bc58 remains strictly better than pre-14z-36
  (shock + death correct; counts too generous). The maintainer's
  caveat = the one open gameplay-accuracy item.

## Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)

- The decisive fact: **vs2's dispatch maps record type 0x4E to the
  TYPE-6 handler** (word[0x4E] == word[0x06] == 0x11A) — on vs2 the
  sworded deity's hits were ALWAYS native class 8 (the tiny type-6
  handler: victim+0x117 flag + class := 8). Our "class 0x4E" was
  vsavj's renumbered copy-handler artifact. The whole three-consumer
  property plan (14z-28) is RETIRED — nothing legitimate ever
  referenced class 0x4E.
- FIX: 7 region_fix remaps (hitbox +0x11A9..+0x1269): sworded deity
  record types 0x4E -> 0x06 = the same proven mechanics as the
  working swordless column. Measured: full electrocute shake
  (alternating nodes), fall sequence, grounded death 0x158210 on the
  fatal hit; NON-fatal = 10 damage steps (the electric stun holds the
  victim through the full multi-hit — up from 2 pre-fix, matching
  vs2's behavior), no knockdown on a standing opponent.
- test_don_reactions.sh: death-chain assertions restored (section 2)
  alongside the gameplay lock. hit_class_props_ext_hi (0x50-0x53)
  stays as inert future-proofing.
- Remaining queue (all cosmetic): swordless-deity palette (yellow vs
  vs2 blue), select-screen post-confirm blink (tracked minor), ES
  deity nuance (its records now class-0x4E-copy interim = plain
  reactions; if the maintainer wants ES-specific presentation, map
  vs2's class-0x51 property intent 0x19 properly).

## Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)

- Read vs2's "dedicated" type-0x51 handler: SIX BYTES — `move.b
  $17(a3),$54(a1); rts` = "copy my type byte into the victim's
  hit-class field". VSAVJ HAS THE IDENTICAL HANDLER — serving ITS
  types 0x4E/0x4F (it is the class-writer PC 0x1868C from the 14z-26
  taps). The engines renumbered this record family; for it, "hit
  class" == record type. This RECONCILES the whole arc: the sworded
  deity's 0x4E records already used vsavj's copy handler correctly
  (same semantics by luck of the numbering); no handler port needed
  anywhere.
- The 6-record type-0x51 cluster (region hitbox, 0xC9CA1+ stride
  0x20, 3 distinct records x2 — ES-variant deity hits by position) =
  LATENT WILD-JUMP CRASHES on vsavj (type 0x51 indexes past the
  0x50-entry dispatch table). Remapped 0x51 -> 0x4E (region_fix x6):
  identical handler, victim class 0x4E = consistent with the rest of
  the deity family. Preempted before any playtest hit it (probably
  the ES Change Immortal KO).
- Dispatch-table geometry corrected on the record: vsavj table = 0x50
  entries (0x00-0x4F; 0xA0 bytes; first handler at +0xB2 after a
  0x12-byte gap); vs2 table = 0x54 entries (0x00-0x53).
- Queue after this: the sworded-421P on-hit shake/death (= the
  original consumer-2/3 property work — the type insight did NOT
  supersede it after all, since the sworded records were already
  correctly classed 0x4E; their missing shake = the property-table
  interim, unchanged), swordless-deity palette, select-screen
  post-confirm blink (tracked).

## Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)

- Maintainer: crash no longer reproducible ✓ AND Morrigan gets the
  proper shock effect on swordless 421P ✓ — the type remaps restored
  the hit PRESENTATION too: the record TYPE (not only the hit class)
  routes the reaction/shock. Types 0x0F/0x06 = electric-presentation
  record families.
- REFRAME of the open queue: the SWORDED 421P's missing shock (the
  14z-28 interim) is likely the SAME mechanism — its records are the
  type-0x51 cluster (region hitbox, 0xC9CA1+ stride 0x20). Re-analysis
  of vs2's dispatch: entry 0x51 -> displacement 0x0BA = PAST the
  table end = a small DEDICATED vs2 handler (not an alias — the
  earlier "inside-table anomaly" was a miscount; vs2's table = 0x54
  entries/0xA8 bytes, so 0xBA is a legit handler just after it).
  Type 0x51 = genuinely new vs2 behavior -> next session: port that
  small handler (patched_clone class) + route type 0x51 to it via a
  thunk at the dispatch's `d040 303b 0006` site (6 bytes; bounds-
  extend for d0==0xA2), then the sworded shake/death and possibly the
  whole consumer-2/3 plan collapse into this one port. The property-
  table extension (consumer 1) may become redundant — re-evaluate
  after the handler port.

## Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)

- Root cause (completing 14z-32's decode): the column's KO records
  carry vs2's EXTENDED record types (3x 0x52 + 6x 0x50 in region
  hitbox_proj, record stride 0x20); vsavj's record-type dispatch
  table (0x185CC family) ends at entry 0x4F -> those types fetch CODE
  BYTES as jump displacements (0x52 -> 0xB26D -> odd jmp = the vec3
  reset). The 14z-32 "content-match over-reach" theory was WRONG (the
  aux0 regions are proper ports; retracted) — the data was faithful;
  the ENGINE's table was short. Same +6-extension pattern as the hit
  classes (0x4E-0x53), one table deeper.
- FIX: region_fix type-byte remaps, alias-PROVEN by vs2's own
  dispatch table (the 14z-27 lesson codified: remap only when the
  source engine itself proves equivalence): 0x52 -> 0x06 (vs2 words
  identical) and 0x50 -> 0x0F (same). All 9 records fixed. The
  type-0x51 cluster (region hitbox, 0xC9CA1+ stride 0x20 — likely the
  SWORDED variant's records) is NOT alias-provable from the table
  read (entry 0x51's vs2 word = 0x0BA, inside-table anomaly) — LOGGED
  UNTOUCHED; if a sworded-421P context ever faults, start there.
- Verified: guarded crash replay END-clean; visual = SPECIAL FINISH +
  YOU WIN over a properly downed victim (this KO path even ends
  correctly downed). Permanent gate tests/test_don_column.sh (guarded
  replay 50, battery 3d).
- The plant = QCB+K (214K) — replay 50 documents the working input.

## Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)

- Round-45 maintainer: blinking gone in-match for all colors ✓; ONE
  residual — the select screen at/after CONFIRMING Donovan still
  blinks. TRACKED as minor cosmetic (maintainer's call): hypothesis =
  select-venue objects don't carry the +0x3A4 cached block ptr (the
  match char-init at 0x1C68E sets it), so the color-aware thunk's
  nonzero-guard falls back to the vanilla punch-color slots on that
  screen only. Revisit if it proves important (fix shape: fallback
  via owner-link's block or a select-venue init of +0x3A4).
- This session: the column-crash mechanism FULLY decoded (fix scoped,
  next session):
  - The fault instruction = the record-type JUMP DISPATCH (0x185Cx:
    `move.b $17(a3),d0; add; move.w (pc-table,d0); jmp (pc,d0)`) — a
    garbage type byte from A3=0xCAA5A produced displacement 0xB26D ->
    jmp to odd 0x13847 = vec3.
  - 0xCAxxx refs in the ported anim region are NOT stale: the
    extractor's pool CONTENT-MATCHER mapped vs2 pool spans
    (0x33xxxx) onto byte-identical VANILLA data (21 fields inventory:
    0xE9514/56/64, 0xEFBFA/C12/C2A, 0xF21BC/2208/2252/22DA,
    0xFF038/40, +9 more — scan script in the session log). For COORD
    LISTS that is sound; for the swordless-variant's ATTACK RECORDS
    the match extent is shallower than what the KO path walks -> the
    walk exits the matched span into unrelated vanilla bytes ->
    garbage record -> wild jump.
  - FIX (next session): port the vs2 pool spans behind the
    swordless-variant fields properly (vs2 sources 0x3358E8/0x33746C/
    0x335908/0x33CCF4 + extents from the record format) into a hole
    and region_fix the node fields; OR narrow the content-matcher to
    coord-list cptrs only and let the extractor port the rest. The
    deterministic guarded repro (experiments/421k_ko/50 + POKES
    2890:ff8850:00010001) becomes the gate when green.

## Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)

Round-44 maintainer answers unblocked both fronts:

**BLINK ("from the moment you select Donovan") — FIXED:**
- Root cause: the accent march's static slots T0/T1 hold PUNCH-color
  row-C content; selecting with any other button loads the alt block,
  so the march cycles alt-base vs punch-accent = grey-shade blink
  (select screen AND in-match). The accent gate stayed green because
  its replay picks with LP — a coverage gap, now closed.
- Fix: accent_color_aware_{0..3} site_thunks at the uploader's four
  family-base sites (lea 0x39A900): owner char 0x0F -> a0 = the
  object's cached palette-block ptr (+0x3A4 = the SELECTED color,
  nonzero-guarded), d0=2 (-> block+0x40 = row C) — every march phase
  reads the same color-correct row = vs2's steady semantics for any
  color. Else-branch byte-equivalent. Measured: kick-color row 0x0C
  single-variant == the frozen ALT row-C content; punch path
  unchanged (accent gate green). test_don_colors gains the alt-
  steadiness assertion.

**CRASH — DETERMINISTIC REPRO + FAULT SITE:**
- The plant move is QCB+K (214K — the flavor-consuming sword throw;
  the "421K" notation confusion cost the previous session's attempts;
  the thrown sword plants where it lands, right side from round
  start).
- Repro (tests/experiments/421k_ko/50_column_crash.rpl + HP poke
  2890): plant, then swordless 421P(214P-side motion works too) —
  the column kills P2 -> MACHINE RESET at f~2943.
- Guarded: **vec3 ADDRESS ERROR, PC 0x185D8 (hit-apply family, near
  the 0x1868C class writer), faulting address 0x13847 (odd), A3 =
  0xCAA5A = VANILLA JEDAH'S ATTACK-DATA REGION, A6 = 0xFF9400 (the
  column projectile obj)** — the column's attack-record pointer was
  never repointed to ported data; the KO path dereferences a garbage
  field from Jedah's records -> odd-address access. NEXT: find what
  loads A3 for the column obj (per-projectile record table or the
  spawner's immediates — same porting class as the throw-table fix)
  and repoint; the crash repro then becomes the permanent gate.
- Also explains round-43 item 2 fully; the sworded 421P KO does NOT
  crash (its records are ported) — matching the maintainer's report.

## Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)

Round-43 reports classified:
1. "421P lost electric/shock properties" — EXPECTED interim: the
   current build's class/property state is byte-identical to the
   round-38 builds (the revert); the victim shake returns with
   consumers 2+3.
2. **CRASH (blocker): swordless 421P round-ending kill with the victim
   at the planted-sword location (user: vs Morrigan).** Repro scaffold
   built (49_column_ko_wip: plant -> P2 walks onto the sword -> HP
   poke -> column kill, guarded + POKES now supported in
   replay_guard.lua) but BLOCKED: scripted 421K does not produce the
   plant (tried HK + LK with the deity-proven motion shape; LK gives
   a low sword action that ends re-armed). NEED FROM MAINTAINER: the
   exact plant input nuance (button? held? ES/meter? special state?)
   — or whether the crash also occurs with the SWORDED 421P at
   point-blank. Suspicion: the swordless variant's attack records
   (hitbox_proj region?) carry extended classes or the KO path for
   that variant runs vs2-only code. SCANNED (14z-30 addendum):
   hitbox_proj carries ONLY vanilla-range classes (0x0F, 0x14) — the
   crash is NOT the extended-class family. Redirected suspicion: the
   three EXCLUDED overlay KILLER_SITES (0x5D8B8/0x5EE22/0x918F0 —
   attack-id table walkers, "residual wrong-art, no crash" verified
   on NORMAL paths only) — a round-end KO in the swordless state may
   reach them in an unverified context. Next: reproduce (needs the
   plant input), then a guarded run with the exception-vector report.
4. "Sword/statue blinking again (grey shades)" — the normal-state
   accent rows are GATE-VERIFIED steady on this exact build (battery
   green, test_don_accent). Hypothesis: the blink lives in the
   PLANTED-SWORD state (a separate accent surface for the swordless
   weapon rows — same family as the fixed one, new territory from the
   round-43 421K testing). NEED FROM MAINTAINER: does the blink
   appear from round start, or only after a 421K plant?
5. Auras yellow ✓ (no regression).
- Select-web: P1 default hover = Demitri (0x04); U,U,D,D = Aulbath
  (0x09). 0x08/0x0B (Morrigan/Lilith candidates) still unmapped.

## Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)

Started the per-consumer extension (round-42 go-ahead). Facts added
this session (build work was local-only; repo/ship state remains
d6cfdaf3 = the 14z-28 interim — the consumer-1 restore alone would
re-introduce the reported wrong-aura state, so it ships only together
with consumer 2):

- Consumer-1 restore verified REPRODUCIBLE: re-adding the 6-byte
  property port rebuilds BIT-IDENTICAL fd8f0628 (the 14z-26 state).
- The shake TINT mechanism is NOT per-hit palette uploads: zero
  palette-RAM writes land during the hit/shake window; the victim's
  flash-row fields are correctly initialized (+0x18B = 0x10, +0x3A4 =
  base block, +0x3A8 = 0x90C200); the post-shake write at ~f2667 is
  the base-row REFRESH, not a tint. The tint is therefore OBJ-attr
  and/or preloaded-row content — per-victim wrongness must come from
  content preloaded per victim (match-init staging) or per-victim row
  choice in the reaction records.
- With VICTOR as the victim, the shake state is NATIVE-EQUIVALENT at
  the palette+OBJ level (full A/B vs vs2: row contents match mod
  pulse phase; victim-zone attr histograms match) — consistent with
  the maintainer's list (Victor-family correct). The divergence ONLY
  manifests with victims like Lilith/Morrigan.
- NEXT SESSION PREREQ: map P2 select paths for Lilith and Morrigan
  (web ids 0x08/0x09/0x0B were never visited in the 14z-21 walk) ->
  author deity-shake repros with those victims -> A/B the shake state
  vs native to catch the divergent element (attr row vs preloaded
  content) -> then consumers 2+3 fixes per the 14z-28 map.

## Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)

Round-41 results: auras fixed ✓, match-end death fixed ✓ — BUT the
class remap broke the MOVE: 421P became a single-hit hard knockdown
(class 0x04 semantics) instead of a standing up-to-8-hit multi.
Gameplay regression outranks the cosmetics it fixed -> REVERTED to
round-38 behavior (class 0x4E, property 0): the move plays correctly;
the match-end neutral-pose cosmetic returns, accepted interim.

**THE DEFINITIVE MAP (all measured; the next-session fix is a
per-consumer extension of class 0x4E with vs2 semantics, NOT a class
remap):**
1. ON-HIT reaction: property table 0x28D00[class]. vs2 value 0x0F =
   standing electric shake, no knockdown (correct for the multi-hit).
   Restoring 0x0F alone reproduces 14z-26: move correct, shake on
   hits, but wrong per-victim aura colors + no death chain.
2. PER-VICTIM AURA ROW: with property 0x0F the vsavj engine uploads
   victim_effect_block[row 0x0F] — row semantics drifted between
   engines (vsavj victims hold other art there: Lilith green,
   Morrigan red; some chars coincidentally yellow). Fix = find the
   effect-row derivation from the property (uploader 0x2AD20 family
   feed) and remap 0x0F -> the native electric row for this venue
   (site_thunk or table extension at THAT consumer).
3. DEATH PATH: re-reads victim+0x54 (class) beyond the property table
   — with class 0x4E the collapse never chains (shake self-loops 255f
   then idle). Fix = find the death-path's class consumer (tap the
   victim node writes during the KO with class 0x4E + property 0x0F
   and follow the non-chaining branch) and extend ITS 0x4E entry.
   (Poke-proof exists: with class 0x04 the full chain runs to node
   0x158210 — the target end state.)
- Gate test_don_reactions.sh REWRITTEN as the gameplay lock: 421P
  must multi-hit (>=2 damage steps) and never enter knockdown-family
  nodes vs a standing opponent. The death-chain assertions to restore
  when the fix lands are preserved in the file comment + git history.
- Round-41 also CONFIRMS (with A/B captures): the SWORDLESS deity
  (421P after 421K plants the sword) has wrong palettes — ours
  yellow-centric with yellow lightning at the sword, vs2's
  blue-centric with white lightning. Same family as consumer 2 (the
  deity's own object palette rows for the swordless variant) — fold
  into the same fix session.
- hit_class_props_ext reduced to classes 0x50-0x53 only (unreferenced
  today, future-proofing); 0x4E/0x4F revert to vanilla zero.

## Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)

Round-40 report (bug persists at match end + wrong shock-aura palettes
on Lilith/green, Morrigan/red under some shocks) resolved completely:

- Legacy exonerated first: pure-legacy Victor-shock palette RAM is
  byte-identical to vanilla (full-row diff, replay 40) — the wrong
  auras occur only under DONOVAN'S OWN electric hits (the deity),
  i.e. they were enabled by 14z-26's property extension.
- Root cause, full depth: the deity's 7 attack records carry vs2's
  EXTENDED hit class 0x4E. Multiple engine consumers index per-class
  structures the vsavj engine only sizes to <=0x49: the property table
  (14z-26 fixed one consumer), the DEATH PATH (re-reads the class ->
  collapse never chained), and the per-victim EFFECT-ROW selection
  (vs2's row semantics drifted: vanilla victims hold other art at the
  row vs2's property selects -> per-victim wrong aura colors).
- FIX (14z-27): remap all 7 deity records to the NATIVE electric
  class 0x04 (Victor's) at the extraction-blob level — new generator
  kind [[region_fix]] (guarded old/new byte patches inside extractor
  region blobs; region "hitbox" +0x11A9..+0x1269 stride 0x20).
  Measured end to end WITHOUT pokes: full electric reaction chain ->
  grounded death node 0x158210 (the same terminal node as any healthy
  electric KO), SPECIAL FINISH + PERFECT over a properly downed
  victim. Aura = native effect rows every vanilla victim supports ->
  correct yellow by construction (the class-0x4E path no longer
  exists). The 14z-26 property-table extension STAYS (classes
  0x4F-0x53 remain routed for any future ported move; the 0x4E slot
  is now unreferenced).
- Gate test_don_reactions.sh STRENGTHENED: asserts the grounded death
  node at f2950/f3030 (idle loop = the old bug).
- Trade-off recorded: the deity now uses vsavj's class-0x04 semantics
  (Victor-electric) rather than vs2's 0x4E nuances — visually and
  mechanically equivalent at the level playtest can see (reaction,
  aura, death); if a nuance difference surfaces, revisit with a
  per-consumer extension instead of the remap.

## Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)

Maintainer corrected round-38's report: the bug move is **421P with
sword (Change Immortal — the blue deity multi-hit summon)**, kill by
its damage at any spacing; capture shows SPECIAL FINISH + victim
standing neutral. Reproduced deterministically in one 2P run (replay
48 + HP poke), then traced end to end:

- The reaction dispatch (0x2380C family, ~60 call sites) indexes the
  per-HIT-CLASS property table 0x28D00 with victim+0x54. The deity's
  hits carry class 0x4E. **vs2 EXTENDED the table with classes
  0x4E-0x53 (values 0f 1b 1f 19 0f 03); vsavj's table is zero there**
  -> the special branch (electrocute/special-finish reaction — native
  control shows the victim shaking in the lightning X-ray, hence the
  SPECIAL FINISH banner) never fires; the victim's plain hitstun
  expires into idle. Also explains the attacker link: the deity's
  hits attribute to Donovan himself (+0x32 = 0x8400), so this is
  class-driven, not attacker-object-driven.
- FIX SHIPPED: data_port hit_class_props_ext — 6 bytes vs2 0x28026 ->
  vsavj 0x28D4E (zero-filled spare capacity; terminator untouched).
  Legacy-safe by construction: no vanilla attack emits classes >
  0x49. Measured: deity KO now fires the electrocute shake (node
  0x157EBC) with the X-ray burst — and other ported moves using the
  new classes get their reactions routed too (the maintainer's
  "other specials" suspicion).
- REMAINING (next session): the shake->COLLAPSE handoff. Native: shake
  loop (two alternating nodes) then collapse node; ours: single
  static shake node, then release to idle — a second consumer of the
  property value diverges (engine-version drift in the dispatch's
  branch targets, or a follow-up resolver). Same comparative-tap
  methodology, one level deeper. Gate test_don_reactions.sh freezes
  the current partial (shake fires) and carries a STRENGTHEN-note for
  the collapse.
- Also logged from round 39: possible wrong palette on the deity when
  summoned WITHOUT the sword (maintainer double-checking).

## Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)

- **Round 38 maintainer confirmation: the select-screen sword renders
  as expected** (cursor on Jedah's cell). 14z-24 closes confirmed.
- **NEW BUG (maintainer, non-blocking): Donovan 421K (at least 421HK)
  ending a MATCH leaves the opponent in neutral pose** — no KO anim,
  no knockdown; the same move ending a non-final round triggers its
  hard knockdown correctly. Repro hunt this session did NOT land the
  bug: match-end KOs on the move's LAUNCHER hit animate correctly in
  both 2P and arcade environments (three clean repros) — the bug
  needs the hard-knockdown-causing hit as the killer, which scripted
  spacings never achieved. All experiments + facts + timeline banked
  in tests/experiments/421k_ko/ (persistent-suite doctrine); needs
  the killing-hit configuration from the maintainer or a spacing
  sweep. GOTCHA-class note recorded there: POKE VALUES feed the CPU
  AI — any poke change reshuffles downstream choreography.

## Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)

The 14z-23 "offset+priority" resolved to pure LIST ORDER — and the
"32px offset" was an occlusion illusion (the sword spans x=99-163 in
BOTH games; native's body occludes 99-128, showing only hilt + hip
tip; ours drew the whole span on top). Chain of proof:

- Full-word entry compare (the 14z-23 masked-bits suspicion): the Y
  high bits are the TILE BANK field (ours 0x4000=bank2, native
  0x6000=bank3 — both correct for their art locations; the earlier
  "spawn position difference" was a misread of this field).
- Software compositor over the dumped entries reproduced the visual
  difference from identical data -> not art, not palette, not values:
  DRAW ORDER. List maps: native emits sword-copy1, sword-copy2, THEN
  body (sword behind); ours emitted sword1, BODY, sword2 (second copy
  over the body).
- vs2's Donovan handler carries `move.b #8,$3C(a4)` — sets the
  OWNER's draw-behind flag for the companion; the instruction has ZERO
  occurrences in vsavj. POKE experiment: one-shot set of owner+0x3C=8
  flips our list order to native's and PERSISTS (45+ frames).
- FIX: the two resolver-call thunks' 0x0F branch now also does
  `movea.w $30(a6),a1; move.b #8,$3C(a1)` (owner ptr; a1 dead at both
  sites). Result: OBJ order native-exact, snapshot A/B shows the
  tucked back-sword matching vs2.
- All five rows LIVE at stage 6 (build d1db9c0b). New gate:
  test_don_colors.sh section 3 (sword entries present + all-before-
  body order + frozen code set; replay 44_don_select_hover promoted).
  replay.lua gained POKES (mirrors tap_writes; persistent-suite
  capture of the poke experiment mechanism).
- 14z-21c LEGACY CHECKPOINT pending the battery: select_fuzz flicker
  inventory / pick divergence may shift now that slot-0F hover
  activates the companion. Any drift -> mechanism-attributed and
  reported for maintainer sign-off, NOT silently refrozen.

## Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)

Continued investigation with the machinery temporarily reactivated
(local only; restaged 99 + bit-identical 73f4f5a5 at session end).
The 14z-22 "record-walk gap / raw-code second drawer" hypothesis is
WRONG — corrections:

- The "raw vs2 codes" OBJ entries are STALE UNRENDERED JUNK beyond the
  active list extent (a full-window write tap over frames 1000-1292
  shows those values are never written; they are leftovers in OBJ RAM
  the parse picked up). Red herring; no walk gap on that evidence.
- The sword TILE ART is verified correct two ways: byte-compare AND
  rendered side-by-side (shapes identical to vs2 bank-3 originals at
  our bank-2 positions, incl. all block-expansion cells).
- The OBJ ENTRY SETS are byte-identical to native (positions, attrs,
  sizes, palette row, duplication) — yet the RENDER differs. Four-way
  snapshot comparison (native f1210/f1500, ours f1700) shows the real
  defect: ours draws the same-size sword ~32px RIGHT of native and IN
  FRONT of the body; native draws it tucked BEHIND the sprite (hilt
  above the head, blade mostly hidden). So: a COORDINATE-BASE and/or
  PRIORITY/list-order difference in how the select venue composes the
  companion — not art, not palette, not the entry values themselves.
- Suggestive measured fact: the companion (and owner) POSITION words
  differ between engines at spawn — ours 0x4000/0xA000 vs vs2
  0x6000/0xA000 (0x2000 = 32px in 8.8 — matches the observed shift).
  The dumped entry coords nonetheless MATCH native (x=99...), implying
  the visible copy is rendered via a base/section mechanism the flat
  entry parse does not capture (CPS2 list sections carry base offsets;
  the e0ef/2058-class entries are candidates for section headers).
- NEXT SESSION (fresh head, systematic): (1) decode the OBJ list
  SECTION structure (headers/bases/order) in both dumps rather than
  flat entries; (2) attribute the visible copy: poke a single tile's
  art in a scratch build and see which rendered copy changes; (3) the
  32px delta likely traces to the keeper's spawn-position source
  (owner mirror at +0x10/+0x14) — find where vs2's select positions
  its owner vs ours; (4) priority: check attr bit-5/list-order
  semantics for the select venue. All five manifest rows remain staged
  99; build bit-identical to shipped 73f4f5a5.

## Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)

Implemented the 14z-21c plan and verified it end-to-end, then found one
deeper blocker and staged the feature off (build back to bit-identical
73f4f5a5 — the staging discipline's no-regression proof).

WHAT WORKS (all measured on live builds):
- code_word generator kind added (guarded 2-byte code patch — jump-table
  entries can't take a 6-byte site_thunk without clobbering neighbors).
- Jump-table entry 0x0F -> +0x46 handler; the keeper activates the
  companion (alive, positioned, char id 0x0F).
- The handler's number source reads 0 on the vsavj select engine, and
  index limits bite: the flourish node (index 0xFC) SELF-LOOPS (a
  permanent oversized blade), and the settled back-sword node sits at
  index 0x10B > 0xFF — beyond the MASKED resolver's 8-bit range. Fix
  shape: thunk the handler's two resolver CALL SITES (0x84602 state-1,
  0x84624 state-2) — owner 0x0F -> inject d0=0x10B + tail-jump the
  UNMASKED resolver entry 0x15088 (the 0x5C77A/E masked/unmasked pair
  pattern, third occurrence). Result: companion holds ported node
  0x0E1780 (= vs2 0x28DC58, the settled pose) and the page-A OBJ
  entries match native BYTE-FOR-BYTE mod +0x2750 (positions, attrs,
  sizes, palette row 0x17, duplication pattern).

THE BLOCKER (fully measured, not yet fixed):
- Activation also wakes a SECOND select drawer whose record subset the
  gen's anim-region record walk NEVER REMAPS: second-page OBJ entries
  carry RAW vs2 band codes (0x97xx body pieces of a different anim
  frame, 0x8650/0x8658 etc.) which index VANILLA vsav art — visually
  Jedah's giant blade diagonally across the select sprite. This walk
  gap also explains the 4 unreferenced-looking tiles (0x8644-47) and
  the old "extra piece 0xEC47" note (14z-21b) — those drawers were
  always running; activation made their output prominent.
- DEAD END LOGGED: placing "missing" tiles via a new build_gfx
  --extra-tiles path + reserving their cells in the generator pool
  CASCADED the first-fit allocation (267 effect placements moved — the
  allocator is block-aware; removing 4 cells splits runs). Reverted
  entirely. Any future fixed-position tile need must allocate at the
  POOL TAIL or ride the existing exception flow, never carve early
  cells.
- NEXT: find how the second drawer's records are referenced (separate
  record-pointer table or cptr indirection the walk misses), extend
  the walk (or add the records to the remap set), verify raw-code
  entries gone, THEN restage the five rows to 6. All five rows +
  comments sit in donovan.toml staged 99; flipping stage is the only
  re-enable step.
- Legacy checkpoint from 14z-21c still pending a stage-6 battery run
  (the staged-99 build needed none — bit-identical to green).

## Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)

Correction to 14z-21b: NOT the companion-overlay record system — the
select venue has its own dedicated select-companion machinery. Complete
chain (all measured live on vs2 + twin-located in vsavj):

- The select-companion OBJECT exists on our build (obj $FFD480, char id
  0x0F cached) but stays DORMANT: alive flag +1 stays 0, no anim.
- vs2 activation (frame-1159 trace, hover-change to Donovan): a
  per-frame companion KEEPER routine dispatches on the hovered CHAR ID
  through a 32-entry PC-relative jump table; most entries -> deactivate,
  Donovan (0x13) -> a handler doing `lea 0x289EF6,a0; jsr 0x13778`
  (resolver: node = table + table[id*2]; writes obj+0x1C) -> initial
  node 0x28DAF0; sets +4=0x0202, +0/+1=0x0101 (alive).
- The sword pieces are then drawn per frame by select-engine walker
  PC 0x19E24 from records at ~0x29AFE0+ (format: [attr,code] pairs +
  0x11x0x09 header + coord-list long; per-anim-frame records), coord
  lists at 0x352150+ (INSIDE the overlay pool window [0x300000,
  0x361000)), tile codes 0x863F-0x864D (in-match sword band — remap
  exists), palette row 0x17.
- vsavj TWIN keeper found at ~0x844E0 (owner-id cache sig 1d6b0382000a
  is unique); its jump table (after the second `4efb 1002`, ~0x8456C+4)
  has entry 0x0C (and one later entry) -> handler at disp +0x46 doing
  `lea 0x2083BC,a0` (or 0x2087CA by flag a6+3) `; jsr 0x15084`
  (resolver twin, sig-verified). Entry 0x0F = 0x0040 (deactivate).

FIX PLAN (next session):
1. Port the data chain: vs2 node-offset table 0x289EF6 (extent TBD),
   nodes ~0x28DAxx, records 0x29AFxx-0x29B1xx(+ per-frame set), coord
   lists 0x352150+ (check overlay-pool coverage first — POOL_LO/HI in
   tools/overlay_port.py may already carry them), tile-code remap via
   the existing gfx_remap map.
2. Route vsavj jump-table entry 0x0F (word 0x0040 -> 0x0046) so slot
   0x0F enters the existing char-0x0C handler.
3. site_thunk the handler's two `lea` sites (0x2083BC/0x2087CA
   immediates) char-conditionally: owner id 0x0F -> ported table (the
   fixture_row0f pattern; check flag-dead safety + also the later
   state's `lea 0x283690` site).
4. LEGACY RISK CHECKPOINT: the keeper consults entry 0x0F whenever the
   select cursor hovers the Jedah cell — 04_select_fuzz (flicker
   inventory) and the pick frozen-divergence may shift. If flickers
   drift, that is EXPECTED mechanism here, but per the standing watch
   it must be mechanism-attributed and re-frozen with maintainer
   sign-off — flag it in the session report, do not silently refreeze.
5. Gate: extend test_don_colors.sh (or new) — select-hover OBJ list
   must contain the 8 sword entries at frozen native positions/codes
   (remapped); include a vanilla-side assertion that a non-companion
   char's hover keeps entry-0x0F path dormant.

## Session 14z-21b (select-screen sword: mechanism PINNED, fix scoped; 2026-07-31)

OBJ-RAM A/B at select hover (ours frame 1290 vs native vs2 frame 1350,
dumps in the walk transcripts; select A/B crop saved):
- The standing select sprite = record-drawn from the ported in-match
  tile placements (our codes 0xBE9D-0xBF7E, pal row 0x15, positions
  matching native's 0x97xx/0x98xx piece-for-piece) — the M2b select
  port works for the BODY.
- Native vs2 additionally draws **8 sword entries: codes 0x863F,
  0x8640, 0x8642, 0x8643, 0x8648, 0x864B, palette row 0x17, each
  duplicated, x=99-115 y=102-166** (hilt above head + blade at hip).
  Ours has none. The duplication + separate palette row + in-match-band
  codes = the COMPANION-OVERLAY record system running on the select
  venue in vs2 — a venue not among the 22 verified overlay poke sites
  (14r port verified on match/win paths only).
- FIX SHAPE (next session): locate vs2's select-venue overlay spawner
  site (tap the ported-zone record walks during vs2 select; the tsite
  cross-match machinery in tools/overlay_port.py), find the vsavj
  analog site, context-verify, add to VERIFIED_SITES, re-emit, and
  probe with the timer-tick detector on the SELECT path (the 14r
  methodology). Watch: select venue runs on legacy paths for every
  char — the site must be char-gated like the rest of the overlay
  system. Also noticed (cosmetic, low): ours draws one extra piece
  (code 0xEC47, effect band) at x=80 y=120 that native lacks —
  investigate alongside.

## Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)

- **Row-0x0F fixture override (the statue's steady miscolor) DONE:**
  two [[site_thunk]] rows hook the staged fixture sites 0x1C586 (bank
  0, staging+fade) and 0x1C59A (bank 1) — shared by match intro AND
  attract (measured; the six direct fixture sites serve other venues
  and are NOT hooked pending measured need). Thunk: if either char id
  byte ($FF8782/$FF8B82 = obj+0x382) == 0x0F, a0 = embedded vs2
  override block (vs2 0x3CB7DC, 0x40 bytes — row 0 byte-identical to
  the vanilla fixture's row 0x0E, row 1 = the statue red ramp); else
  vanilla 0x3B5940, flag-safe (both sites' fall-throughs kill CCR).
  Measured on build 73f4f5a5: palette rows 0x04-0x0F ALL byte-equal
  to native vs2 in-match; rows 0x0E/0x0F frozen into
  tests/test_don_accent.sh.
- **GOTCHA PAID (generator extended):** hole "a" lies inside the CPS-2
  crypt range — site_thunk bodies placed there are stored re-encrypted
  for opcode fetches, so EMBEDDED DATA read via data loads comes back
  as ciphertext (first build produced garbage palette rows). site_thunk
  now takes hole = "b" (required for any thunk carrying data);
  docs/GOTCHAS.md entry added.
- **Sword-shock red-vs-yellow RESOLVED as engine-global aesthetics,
  decision pending:** the electrocute arc/glow writes to P1 rows 0-3
  come from GLOBAL vsavj tables (accent family idx ~0x711/0x970/0x9A4
  region; base row block 0x39A7E0) — identical sources for Donovan,
  vanilla Jedah, AND a non-slot-0F victim (three-way tap). vs2 simply
  re-themed those global tables yellow. Our build shows correct
  VSAVJ-native shock colors; there is NO porting defect and NO
  side-effect risk (nothing of ours touches that system). Making
  Donovan's shock yellow would need either a global re-theme (legacy
  visual change — ruled out) or a slot-0F-conditional arc-table hook
  (inconsistent with vsavj's victim-independent styling). See
  "Decisions pending".
- Control-run GOTCHA within a gotcha: the first "vanilla control" for
  the shock tap used the SAME slot (vanilla Jedah = slot 0x0F picks) —
  worthless for per-slot attribution; the discriminating control was a
  DIFFERENT victim (default-cursor char). Vanilla controls must vary
  the dimension under test, not just the build.

## Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)

Maintainer playtest on b80e0e67: **sword and statue no longer blink;
electrocuted sprites clean including Donovan.** The rounds-16..35
blink saga is closed.

- **NEW TRACKED ITEM (round 36):** during Victor's electrocute, the
  electric effect SURROUNDING THE SWORD renders red instead of vs2's
  yellow (the body X-ray + body aura are correct). Maintainer: not a
  blocker, but track it — "might not be purely cosmetic or without
  other side-effects." Mechanism hypothesis (untested): the sword is a
  separate OBJ from the body; its shock-overlay pieces may resolve
  their palette row through a path we haven't repointed — candidates:
  (a) the un-ported row-0x0E/0x0F fixture override (open item — red =
  could be residual Jedah-theme content in a row the overlay
  references), (b) an effect-table row indexed by the sword object's
  own identity rather than the owner char (the effect [[palette]] port
  covered char-indexed tables 0x38C218/0x38C258 only). Investigate
  together with the row-0x0F port: same measurement setup (replay
  34/35 electrocute window, palette-RAM dumps + OBJ record palette-row
  attributes of the sword overlay pieces).

## Session 14z-19 (round 35: LEGACY VIOLATION found+reverted; accent march understood; sword blink fixed for real)

Round-35 captures (19-29) showed both fixes had failed. Root-caused by
direct palette-RAM per-frame dumps (a new discriminating instrument —
DUMPS over 0x90Cxxx) + vanilla control taps. The corrected world model
(several 14z-17/18 conclusions were WRONG — corrections below):

- **THE PALETTE-ROW MAP (corrected):** rows 0x0A-0x0F = P1 character
  extended region; **rows 0x10+ = P2 CHARACTER's rows** (not "statue
  rows"). 0x38D1A0 = VICTOR's sprite block (char id 3 — every probe
  match had P2=Victor, which is why rows 0x10/0x11 "matched native":
  both games upload Victor identically). Char id 0x0F = JEDAH in
  vanilla (the U,U,R select cell); our dev builds replace his slot.
- **14z-18's statue_accent_rows was a SUPERSET VIOLATION:** 0x39B040
  is Victor's OWN accent data (his in-match glow cycle — vanilla
  control alternates row 0x10 between 0x38D1A0/0x39B040 exactly like
  our build). The data_port overwrote it → Victor's glow deadened in
  ALL matches incl. pure-legacy. Invisible to the masked RAM gate
  (ROM->palette-RAM path never transits work RAM) and outside the
  pixel-gate frames. REVERTED (row deleted; bytes pristine again);
  permanent guard added (tests/test_don_accent.sh asserts 0x39B040-7F
  == vanilla + Victor's row-0x10 cycle alive in-match).
- **The sword blink, actual mechanism:** the engine MARCHES row 0x0C
  through a 4-frame source cycle: accent T0 (0x39FBE0), T1 (0x39FC00
  = T0+0x20, overlapping window — the slide animates Jedah's glow),
  sprite block +0x40 ×2. Row 0x0D is never accent-cycled. vs2 has no
  march (re-reads block+0x40 steadily). 14z-18's "super-cycle tail to
  0x39FC3F" was an A0 post-increment misread (second time paying that
  trap). FIX: T0 and T1 both hold vs2 row-C content (weapon_accent_t0/
  _t1); 0x39FC20 holds row-D content (weapon_accent_rowd_slot — the
  would-be row-D slot, no observed reader, authentic content either
  way). Measured on the new build: row 0x0C single-variant across the
  idle window, byte-equal to native vs2. The statue's BLINK was the
  same row-0x0C march (statue pieces share the row) — also dead now.
- **Statue steady miscolor remains (open):** palette row 0x0F is
  wrong — it's filled by the venue fixture (2 rows 0x0E/0x0F from
  0x3B5940, global legacy data, untouchable) and vs2 then OVERRIDES it
  per-char from Donovan's intro block at vs2 0x3CB7DC (2 rows; the red
  ramp for the statue keyhole/accents lives at 0x3CB7FC). vsavj's
  engine has NO per-char override path for slot 0x0F (vs2 added CODE
  for it — immediates at vs2 0x1a97e/0x1ac24/0x1aff8/0x2acc6/...).
  Porting needs a slot-0F-conditional 2-row upload hook (rows 0x0E/
  0x0F, dst 0x90C1C0 + bank 0x91C1C0, post-fade or via staging) — NEXT
  SESSION. Expected visible result meanwhile: statue/sword no longer
  blink; some statue accent pieces steadily miscolored (vsavj fixture
  colors: blue/grey ramp instead of vs2's red ramp).
- **NEW open item:** per-char table B at 0x38C1D8 (second sprite-
  palette pointer table — alt punch/kick color sets; true table family
  layout at 0x38C198 is FOUR 16-slot tables at +0x00/+0x40/+0x80/+0xC0
  + 2 misc pointers, data starts +0x108) — slot 0x0F NOT repointed:
  alt-color Donovan likely loads Jedah's palette. Port vs2's table-B
  block (check vs2 analog) or interim-repoint to the same block.
- **ROMDIR event:** qsound_hle.zip had vanished from ROMDIR (audit
  FAIL per §3; the dir also carries fresh cfg/nvram — an emulator has
  been run against it directly). Restored byte-verified copy from
  build/donovan6/rompath (dl-1425.bin SHA-1 matches the frozen
  manifest); audit green again. Maintainer: please keep the reference
  dir play-free.
- Build entry point note: stage-6 dev builds require
  GEN_FLAGS="--allow-plausible --tripwire-open" (as test_m2b_stage6.sh
  does); a bare build_donovan.sh 6 fails on 58 open reconciliation
  refs — expected, not a regression.

## Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19

- Round-34: the first blink fix was HALF the cycle. Measured over 200
  frames: phase 2 reads 0x39FC00-0x39FC3F (starts +0x20 into phase 1's
  range and extends 0x20 past it — the residual "darker grey + red
  spots"). Tail row covered (data_port weapon_accent_tail).
- THE STATUE: rows 0x10/0x11, alternating base rows 0x38D1A0-DF
  (correct grey) with a second accent family 0x39B040-7F (the blink).
  Zero legacy reads (audited). Fixed by making the accent phase
  identical to the base phase — vanilla->vanilla copy via the new
  data_port src_image option. Build 53223293.
- Verified: the row C/D upload spectrum now carries only authentic art
  values (pale metals + his sash browns; the graduated red RAMP is
  gone; isolated warm accents are his real palette content).
- NEW ITEMS (round-34 report, logged for next sessions):
  1. SELECT-SCREEN Donovan big sprite missing the back-mounted sword
     (user captures; likely the select-art strip lacks the weapon
     overlay piece — task #18 territory).
  2. SPEED-MODE menus: the maintainer pushes back on an earlier claim
     of auto/auto+turbo availability — measured behavior: non-Donovan
     chars offer Standard/Turbo only in 1P; PvP produces inconsistent
     per-side option sets (captures show P1 NORMAL/AUTO vs P2 NORMAL/
     TURBO/AUTO/AUTO&TURBO). Possibly vanilla-quirk, possibly an
     interaction with the Start-hold flavor shim (it reads Start state
     during match load — the same input the speed menu consumes).
     UNINVESTIGATED; the maintainer marks it not-urgent.

## Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)

The rounds-16..33 blink is dead. Final mechanism + fix:
- The engine's accent path caches nothing: the red phase reads FOUR
  global accent rows at 0x39FBE0-0x39FC1F (the A0-was-post-increment
  correction; base family 0x39A910). A collector audit over the pure-
  legacy replays (02/30/29) found ZERO reads of those rows by any
  non-slot-0F content — they are JEDAH's theme rows, exclusively.
- FIX (in-place slot-0F class, zero code, zero legacy cycles):
  data_port `weapon_accent_rows` — vs2's sprite-block rows +0x40
  (0x39CBDC, the exact pale-metal tones vs2 displays steadily) written
  over the four red rows. The vsavj accent mechanism keeps alternating
  — between identical values — yielding vs2's steady look through the
  host engine. Verified: uploads now carry ffff/fcdf/f9ad/f87a (pale
  family, no red); four consecutive-phase snapshots show a steady
  pale sword. Also expected fixed: the statue blink and the red arcs
  around the sword (same rows).
- Session-14z-16's POKES facility (tap_writes) and the pointer-nuke
  differential were the tools that exonerated the stage-script system
  and exposed the +0x3A4 cache / global-path split; the +0x3A4 cache
  is correctly initialized (0x1C68E reads the repointed table-1 ✓) —
  no further work needed there.

## Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)

Ground truth closed the loop (live taps, both games, same replay):
- NATIVE VS2: Donovan's weapon rows 0x0C-0x0D refresh EVERY frame from
  ONE steady source — his sprite block +0x50/+0x60. NO alternation.
  (The maintainer's wager confirmed: vs2 does not cycle at all.)
- VANILLA VSAVJ (Jedah control): the SAME 4-frame alternation we see —
  sprite block +0x50 vs the global rows 0x39FBF0-0x39FC2F (base
  0x39A910 + ids 0x297-0x29A; the 14z-13 id model was right, base off
  by a 0x10 header). The red accent is UNIVERSAL vsavj styling (fine on
  vanilla art that was designed for it); Donovan's vs2-designed sword
  art + vsavj's red accent = the blink.
- The refresh script (0x376518) is installed ONCE per match by engine
  setup (immediates 0x1F142/0x1F14A -> job block $FF82B0/B4; +0x34 is
  the active script). vs2 uses different scripts (installers at
  0x1D846/0x1DCC4/0x1E088: 0x36BD34/0x37F534/0x38FD94 by mode).
FIX DESIGN (zero legacy execution, reuses proven machinery):
1. Place a PRIVATE copy of the 0x376518 script with the red-sourcing
   phases changed to block-sourcing (or waits) — the one remaining
   unknown is the command semantics ("0dXY 018Z" entries + waits);
   determined by a short experiment: NOP/modify entries in the private
   copy and observe the upload sources shift (2-3 build cycles, the
   REGLOG row tap is the readout).
2. Revive the 14z-7 countdown mechanism (init-shim marker + sword-exit
   blob — Donovan-gated by construction, once per match, post-install):
   payload = `move.l #PRIVATE,$FF82B4` (swap the active script pointer
   in the RAM job block; the engine re-installs per match, our blob
   re-swaps per match ✓).
3. Acceptance: sword/statue steady grey (multi-phase pixel A/B incl.
   odd frames), vanilla control UNTOUCHED (the swap only runs in
   Donovan matches), full battery, playtest.

## Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)

Final layer measured (continuing 14z-14 without playtest input):
- The job block at $FF8280 is installed ONCE at match load by the
  ENGINE's stage setup (PC 0x1F142/0x1F14A: `move.l #$371C98,$30(a6)` /
  `move.l #$376518,$34(a6)` — hardcoded engine immediates; a6=FF8280).
  Upstream: a PER-STAGE palette-anim descriptor is copied from table
  0x1F92E (indexed by the stage number at $100(a5)) into -$3C78(a5),
  0x80 bytes; the script 0x376518 carries `0dXY 018Z` row-refresh
  commands (waits 0x0020...).
- The 4-frame cycle = the script refreshing char palette rows 0x0C-0x0D
  (the weapon rows): row 0x0C sources the ported block (+0x50 = grey ✓)
  while row 0x0D's refresh resolves 0x39FBF0 = JEDAH's block +0xCD0 —
  a FOURTH slot-0F-sourced resolution (id 0x18E-family -> address),
  whose map is the last unpinned link.
- NEXT (first move): run the identical REGLOG tap on the VANILLA
  control (Jedah vs Victor, replay 34 inputs) — vanilla-Jedah should
  ALSO read 0x39FBF0 (his own rows; correct for him). Then resolve how
  id 0x18E maps to that address (the stage descriptor at -$3C78(a5) or
  a fourth per-char table) and repoint the slot-0F resolution to the
  ported effect block rows (the vs2 block is 0xDC0 and contains the
  analog rows). All prior repoints (tables 1-3) remain correct and
  shipped.

## Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)

Progress (build 40256bae):
- SHIPPED: the THIRD per-char palette table (0x38C258) row 0x0F
  repointed to the ported effect block ([[palette]] extra_tables
  support; vanilla shares one block between tables 2+3, we now mirror
  that). Harmless-by-construction (slot-0F only, row content = his own
  block); may serve other status paths.
- The repoint did NOT stop the red frames: live source still 0x39FBF0.
  Driver chain mapped this session (each link measured):
  * The uploads run under a6=DONOVAN with A3=$FF8280 = a palette JOB
    QUEUE in engine work RAM; jobs carry ROM SCRIPT pointers (live:
    0x371C98, 0x376518) + the target row (0x0C observed).
  * The script at 0x376518: entries like `0020 0000` (waits) and
    `0d0X 018Y` commands (ids 0x181/0x18E family) — the id->source
    computation NOT yet pinned (0x39FBF0 not literal anywhere in the
    queue page or scripts; computed).
  * +0x14E is set-and-cleared within the frame (frame-done dumps
    always 0 — the transient GOTCHA); the observed clear PC 0x2A7DA.
- NEXT (one focused session, first move pre-planned): find the RAM
  long/word feeding A0 for the red job — REGLOG tap candidates: the
  queue slot fields around $FF82A8 (the two script pointers sit at
  ~$FF82A0/AC per the dump), and/or bp the job-processor entry
  upstream of 0x2AD3C reading (a3). Once the enqueuer/computation is
  named, redirect per the established slot-0F patterns. All probes/
  replays in place; the 4-frame cycle fingerprint: 2 frames from
  0x39FBF0 (0x40 bytes), 2 from sprite-block+0x50.

## Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)

- Round-33 playtest: the electrocute is CORRECT — structure AND colors,
  yellow burst included. The 14z-12 purple-vs-yellow decision DISSOLVES:
  the burst/tint colors ride the per-char effect-palette block, so
  Donovan naturally brought vs2's yellow while vanilla characters keep
  their own — the ideal outcome, zero engine surface. (My "global
  purple" analysis was half-right: the global rows exist but the
  per-char block dominates the visible result.)
- SWORD/STATUE BLINK — mechanism fully decoded (round-33 two-frame
  captures: grey frame + red frame cycling):
  * The sword idles through a stride-8 palette-seq stream (his
    companion data in x2b7ef4; sword nodes @0xF77E2+, statue twin
    @0xFA89A+; per-node seq id = 0x200 | flags byte -> ids 0x292-0x29D).
  * Streams are IDENTICAL vs2-vs-build; the ids resolve in the GLOBAL
    palette-seq table (vsavj 0x39A900 / vs2 0x3B0A3C, 0x20-byte rows):
    vs2 rows 0x297-0x29A = blue-grey shimmer (0322/0433/0744 family —
    the sword's intended subtle sheen); vsavj rows at the same ids =
    RED fade records (0d00/0b02 family) = the red frames. Uploader =
    0x2AD64-family writing pal RAM row 0x0C; live-tap confirmed the
    alternation grey(ported block rows)/red(global rows).
  * No data-only fix exists: vsavj's global table has NO matching grey
    rows anywhere (full scan) and NO free ids (no FF gaps in the
    0x1000-id window); the table itself is legacy surface.
  * FIX DESIGN (state_hook precedent, next session): locate the seq-
    TRIGGER call in the ported companion handler (it computes
    0x200|flags and invokes the engine uploader); wrap it (ported-code
    call site = legacy-clean): ids 0x292-0x29D -> a GEN blob uploading
    from 4 privately-placed vs2 rows (vs2 0x3B0A3C + id*0x20, 0x80
    bytes total) to the row from context; other ids -> original path.
    Acceptance: sword/statue steady grey-shimmer, no red; pixel A/B
    at multiple phases (the odd-frame rule); battery.
- NOTE the param-word difference build-vs-vs2 in those nodes
  (0x2C -> 0x0F, all nodes): predates this session's changes; the
  drawn palette row (0x0C) comes out right regardless — investigate
  during the fix, do not assume it is wrong.

## Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)

Round-32 captures confirm the 14z-11 sweep: the electrocute X-ray now
renders Donovan's own silhouette (structure correct). Remaining color
layer, split in two:
1. FIXED (build fbf10960): the X-ray/status BODY TINT came from the
   SECOND per-char palette table (vsavj 0x38C218 = main+0x80, uploader
   family 0x2AD20: per-char blocks of 0x20-byte effect/flash palette
   rows) — never repointed, serving Jedah's greys (the round-4 body-
   palette bug, one table over). Ported vs2 Donovan's block (0x3ADFDC,
   0xDC0, per-char stride uniform) via the palette machinery
   (now multi-entry [[palette]]); row 0x0F repointed. Expected side
   effect: the red/purple sword & statue blink is the same sequence
   family — playtest should re-check it.
2. NOT A BUG (measured): the PURPLE electricity/flash. The flash rows
   upload from the GLOBAL palette-sequence table (0x39A900 family; live
   A0=0x39FBF0 = global row ~0x297) — vanilla vsavj presents ALL
   electrocutes purple (control: vanilla Victor-vs-Jedah, same purple)
   while vs2 styles its own engine yellow. Making Donovan-victim
   electricity vs2-yellow would need per-victim redirection of a
   GLOBAL engine sequence (new mechanism, legacy surface) and would
   make him inconsistent with the rest of the vsavj cast.

DECISION PENDING (maintainer): electric-flash color for Donovan
victims — (a) keep vsavj-native purple (RECOMMENDED: consistent with
every other character, zero legacy surface, faithful to the host
engine), or (b) engineer vs2-yellow for slot-0F victims (new
per-victim seq-redirect mechanism on a global table; visible
inconsistency with the cast; nontrivial legacy-risk surface).

## Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)

Round-31 captures (Victor P1 vs CPU Donovan P2, electrocute at the
knockdown) pinned the LAST piece of the garble family:
- The electrocute draws a per-victim X-RAY OVERLAY record every frame
  of the reel. Donovan's X-ray records live in the anim region but are
  reached by OFFSET COMPUTATION (the aux/+0x64 chain) — no in-region
  pointer — so BOTH the inventory walk (extraction) and the gfx_remap
  walk missed them: their vs2-band tile words shipped UNREMAPPED and
  their art was never copied. On vsavj they drew whatever sat at the
  raw vs2 code positions (Jedah/mixed art on pre-14z-10 builds; the
  user's white-block captures ✓). Proof: NAT and POR OBJ dumps showed
  IDENTICAL RAW code values (ae10/adfb/b041...) at the overlay pieces.
- FIX: a SWEEP pass in obj_records.walk AND the generator's gfx_remap
  walk — every even offset validated as a record head (fmt/budget/
  count/cptr window + sweep-only strictness: budget<=0x40, block
  pieces <=8x8, >=50% band-coherent entries). 38 new records / 338 new
  tiles inventoried, remapped, and placed (parity 1160/14764 both
  sides). The static pool is now also trimmed dynamically at gen time
  against the actual band output (the sweep grew the inventory past
  the baked manifest pool).
- Verified: zero unremapped vs2-band codes in the electrocute OBJ zone
  (was: raw ae10/adfb family every frame); protected 358/358; probes
  17@3479 and 31@2618 pixel-IDENTICAL standalone. Measurement GOTCHA
  paid: pixel probes run IN PARALLEL with a battery can flake the
  replay timeline (a probe showed Morrigan's intro at a match frame;
  standalone rerun identical) — never run probes concurrently.
- Round-31's other lessons: the X-ray shows on EVERY zap (the three
  captures at timers 96/93/90), no knockdown needed; the KO/hard-
  knockdown framing was mine, not the data's.

## Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)

Implemented the 14z-9c plan end-to-end (build 272bfbbb):
- build/manifest/protected_tiles.json: 358 in-match vanilla-referenced
  positions (runtime audit via tap_writes COLLECT mode over the pure-
  legacy suite; full-run union of 574 recorded as observed_full_run —
  attract-cutscene-only usage NOT enforced, pool capacity + accepted
  attract divergence). Pool = 1256 doubly-vetted free cells (window
  minus our outputs minus ALL audited usage minus build-run residuals,
  clamped >= 0xAD80: the Sasquatch-shared band head is not free — the
  build_gfx SAFE_LO assert caught my pool overreach).
- gen_donovan_patch gfx_remap: unified rectangle first-fit allocator
  over the hole-punched pool serves the effect shelf AND band blocks
  whose remapped span hits a protected position (775 band srcs
  exception-relocated); emits tile_exceptions.json (skip list) +
  extended effect_map pairs; excludes effect_tail bank2 spans.
- build_gfx_donovan: skips exception srcs in the band loop; readback
  verifier exception-aware. build_donovan.sh: set -o pipefail (a
  crashed build_gfx had been silently packing STALE tiles — two full
  "fix" builds shipped unchanged gfx before the readback-assert crash
  was noticed; GOTCHAS).
- effect_tail.json: 11 Anita bank2 blocks relocated off protected
  positions; generator now coordinates with its spans.
- verify_gfx_build: pool-aware containment + a standing "no tile on
  protected positions" assertion.
VERIFIED: 358/358 protected positions byte-identical to vanilla; the
electric-hold frame renders clean (no chunk columns); pixel probes
17@3479 and 31@2618 IDENTICAL to goldens; battery running at commit
time (result in the round-30 report).

## Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)

The vanilla control run (replay 34's inputs on VANILLA vsavj = Jedah vs
Victor) collapsed every prior model and exposed the truth:
- The OBJ curtain buckets are IDENTICAL vanilla-vs-build (fc1b/c625/
  fbc9/f76d/fbee columns) — c625 is a VANILLA code, not our remap
  output. 14z-6/7/9b's bucket theories are all void.
- Vanilla vsavj does NOT darken on electric normals (the darken is a
  VS2-only presentation feature) — the "missing darken" is
  vanilla-faithful. vs2-Victor's hold-pose order difference likewise.
- THE ACTUAL DEFECT (tile render, vanilla vs build, tiles 0x2C625+):
  vanilla holds soft pale curtain/smoke art; the BUILD holds DONOVAN
  BODY CHUNKS — because the tile port's band remap TARGETS
  0xADCF-0xEA3F inside the "SAFE" window 0xAD80-0xEEBB (build_gfx
  session-14 assumption: Jedah's band is free once Jedah is replaced).
  VANILLA CONTENT REFERENCES TILES IN THAT WINDOW: measured consumer =
  the VS-fade/curtain columns (code c625 drawn by slot-0F-adjacent
  system compositions, displayed during electric holds -> Donovan
  chunks as columns = round-27 "garbled tiles on Donovan"); the
  electrified-knockdown sprite sighting (round 29) is the same class.
  Lilith matches don't reference those codes -> clean ✓.
- EVERY other layer is verified vanilla-faithful (records, anims,
  cptr, coords, spark, banks) — the garble is purely stolen tile
  positions.

FIX (next session, M2b-scale, machinery already parameterized):
1. AUDIT: enumerate vanilla-REFERENCED tile codes in 0xAD80-0xEEBB
   (walk vanilla OBJ records reachable in gameplay + the VS/system
   compositions; gfx_tiles + obj_records tooling) -> the set of
   positions that must NOT be overwritten.
2. Re-place: choose a new DELTA / placement (build_gfx_donovan.py
   DELTA + [gfx_remap] band values + effect_map shelf) that avoids the
   audited positions (or split placement around them). Rebuild gfx +
   prg (the remap machinery regenerates codes everywhere).
3. Acceptance: render-compare the audited vanilla positions
   (byte-identical to vanilla), the hold replay 33 curtain columns
   (soft dark, not chunks), electrified knockdown by playtest, plus
   the full battery + all pixel probes.

## Session 14z-9b (round 29: THE UNIFIED MODEL — it's the electric-hit DARKEN curtain)

Round-29 precision (electrified state at the hard knockdown) + odd-frame
sampling finally exposed the real subsystem: the ELECTRIC-HIT SCREEN
DARKEN. Measured (replay 35, odd frames 2671-2681): native darkens the
whole screen through the electrified reel; PORTED DOES NOT DARKEN AT
ALL on the 5HP hit. The darken is drawn by extending the OBJ list into
the curtain buckets (0x600/0xA00 tails) WITHOUT rewriting them — the
engine relies on them holding dark tiles. This unifies every sighting:
- vs2: VS-screen leftovers there are dark 444f columns -> darken works.
- vsavj+Donovan: the VS screen leaves HIS PORTRAIT PIECES there (c625)
  -> when the buckets are displayed (the electric hold / Mega Shock),
  they draw Donovan-band tiles over the victim = the round-27 "garbled
  tiles on Donovan" (and Lilith stays clean: her VS layout leaves
  benign content). In the 5HP case the darken never engages on ported
  (activation divergence, cause not yet traced) so the electrified reel
  plays bright-but-clean = matches every "coherent" probe this session.
- The 14z-7 clear targeted the RIGHT buckets with the WRONG value
  (transparent, not dark) and its A/B compared frames OUTSIDE the
  darken window (why clear-on/off looked identical) — the round-28
  "body garbled" was likely the hold viewed with transparent-vs-dark
  curtain compositing.
NEXT (the actual fix, two parts):
1. Fill the curtain buckets with the proper DARK tile entries (vsavj's
   own curtain code — read what vanilla vsavj leaves there in a
   Lilith-victim run, e.g. the fc1b-family, and reproduce that grid)
   at match start — the 14z-7 countdown mechanism is EXACTLY right for
   the timing (arm at init, fill ~0x50 frames in); only the payload
   changes from clr.l to writing proper (x,y,code,attr) entries.
2. Trace why the darken extension doesn't engage on ported for normal
   electric hits (list-terminator/extension length at the hit frames;
   compare NAT/POR 2671 OBJ list extents) — possibly the same bucket
   content participates in the activation decision, in which case fix
   1 alone may resolve it. Acceptance: replay 35 odd-frame pixel A/B
   (darken present, no garble, body coherent) + replay 33 hold frames
   + the full battery + pixel probes 17/31.

## Session 14z-9 (round 28 correction chased to ground: the electric-family display chain is VERIFIED CORRECT end-to-end; no reproducible garble)

Round-28 correction (the reported move = Victor 5HP / f.6HP normals,
not the grab) prompted probe 34 (both games, standing 5HP + f.6HP,
four clean single hits). Every link measured, all CORRECT:
- Hit-reaction anim: entry + every step maps EXACTLY (0xDB890 =
  map(0x287D68), 0x18-node steps in lockstep).
- The displayed record: fmt2 head, piece codes (band +0x2750), attrs,
  cptr RELOCATION (0x3F1CC8 = mapped aux0_4), and the coordinate-list
  CONTENT — all byte-verified against vs2.
- Phase-aligned pixels (POR f2668 vs NAT f2666, same record): Donovan
  coherent — beads, tunic, reel pose. The earlier "scattered pieces"
  crop was a 2-frame PHASE ARTIFACT (engines skew; the flail pose reads
  as garble when compared against a different record's frame).
- The grab-hold "wrong node" of 14z-8 is ALSO RESOLVED as legitimate:
  REGLOG capture shows vs2-Victor commands victim poses (0x29E ->
  0x286) while vsavj-Victor commands (0x286 -> 0x29E) — HIS OWN script
  data differs between the games; Donovan's table resolves BOTH numbers
  to the correctly-mapped nodes. The two games display different
  (each-legitimate) hold poses. Cross-game-legit class, like the
  attract-demo divergence.
STATUS: after three probes (32 grab/Mega-Shock family, 33 close grab,
34 normals) NO instrumented garble reproduces on the current build
(2da7d910); every display chain checked is byte-correct. The round-27/
28 reports remain REAL-BUT-UNREPRODUCED — the missing variable is
WHICH exact situation the maintainer saw (candidates: ES versions,
crouching/air victim state, dizzy electrocution loop, specific move).
AWAITING maintainer round-29: exact move + situation (screenshot
ideal). Tooling ready to pin it within minutes once identified
(REGLOG tap, phase-aligned snaps, OBJ pairing).

## Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)

- Round-28 report (Victor 6HP: effect ~fine, DONOVAN'S BODY garbled)
  prompted a controlled A/B: clear-on (ccb4ab6a) vs clear-off
  (2da7d910) on the new 6HP probe replay 33 — PIXEL-IDENTICAL on every
  shock frame. The clear changed NOTHING for the real move; the body
  garble exists on both builds and is THE SAME defect as round-27's
  report (one bug seen twice, not two bugs). objram_clear disabled
  (build restored byte-exact 2da7d910); test_don_shock.sh REMOVED (it
  asserted the phantom); the 14z-7 mechanism survives in git if the
  transparent-tail idea is ever wanted for real.
- 14z-7's validation error, recorded: the probe snapshotted only ZAP
  frames (flash silhouette hides the body) and the 236HP-grab framing
  measured curtain buckets that the actual defect never touches.
- REAL MECHANISM (measured, replay 33, NAT 2742 / POR 2744):
  * Donovan's held-body pieces draw with band codes ~0x20 OFF native's
    (adjacent tiles: recognizable colors, garbled chunks ✓ user
    report); burst pieces likewise resolve into his band instead of
    the shared low-code fire art.
  * The victim's held-pose cursor ENTERS the sequence wrong: NAT
    enters 0x287430 then settles 0x287418; POR enters map(0x287418)
    then settles map(0x287430) — the SAME two nodes, OPPOSITE order
    (the +0x18 "phase skew" noted in 14z-6 was this defect, not skew).
  * The entry cursor is NOT resolved via the anim-number tables (no
    index in either game's table yields those nodes) and NOT stored as
    a data long — it is computed by the reaction/state machinery. Next
    thread: the seq_set path (vsavj 0x2AD94, the +0x14E state
    machine's cursor initializer, cf. state_hook config) and how the
    hold-reaction's seq record resolves per char for slot 0x0F.
- Probes: replay pair 33_victor_6hp (committed); the 26-frame drain
  confirms 32/33 exercise the same electric-grab family.

## Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)

Fix shipped for the round-27 shock garble (build 1507c286-family, final
fingerprint in the registry/commit). Mechanism recap: the shock curtain
re-displays OBJ-list tail buckets holding VS-screen leftovers; with
Donovan those leftovers are his portrait pieces (band tiles) = garble.
Fix (two GEN pieces, both Donovan-gated, zero legacy execution):
- init_shim (objram_clear flag) now ARMS a countdown marker 0x50 at
  $FF7F00 (dead-stack scratch, legacy-masked; clobber failure modes
  benign in both directions).
- A new blob detours the ported sword routine's per-frame exit
  (vs2 0x65F00 jmp, placed site 0xCC110): while match-active
  ($FF8004==0x40000) it decrements the marker; at zero it clears the
  full 8KB OBJ list ONCE, in the object-update phase (same-frame
  rebuild repaints all active entries — no visible blank; stale tails
  stay zero).
Journey (measured, in GOTCHAS-worthy detail): single-shot clears at
char-init and at first-sword-exit both LOST to pre-match drawers (VS
screen redraws through ~f2470; char-init runs DURING the VS screen;
the match-active flag is set during the VS screen too). The countdown
makes the timing replay-independent (~80 frames into the round).
Verified: tail buckets all-zero at the shock zap; zap pixels coherent
(no patchwork); pixel probes 17@3479 (spark+Anita) and 31@2618 (sword
arc) IDENTICAL to goldens. New permanent gate tests/test_don_shock.sh.
Note vs native: where vs2 shows benign dark leftovers in the curtain,
we show transparent — an accepted M2a-class approximation (recorded).

## Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)

- Round-27 playtest: SWORD VISIBLE ON EVERY MOVE TRIED — the 14z-5 fix
  is confirmed in play. The blocker is CLOSED (cosmetics remain: blade
  palette family, non-blocker).
- New report: Victor's electricity (236HP) garbles tiles ON Donovan
  (clean on Lilith). Scoped this session (replay pair 32_victor_shock,
  OBJ-RAM dumps + write taps, snapshots):
  * Reproduced deterministically; multi-hit shock connects on both
    games; Donovan's shock POSE anim resolves the correct ported family
    (0xDAF58 ~ vs2 0x287418+skew) and his shock record head
    (fmt2/budget 0x23/count 0x0D) is byte-identical to vs2's.
  * The garbled art = the shock's darkening/cage GRID: native draws a
    uniform repeated-tile grid; ported draws a MIX of correct columns
    (Victor's vsavj codes f76d/fbc9) and STALE OBJ-list entries never
    rewritten since the match-intro (frame ~2313, e.g. code c625 = a
    Donovan band tile from his intro pieces; written by engine drawer
    PC 0x1B8BE, exposed at shock time with zero writes in between —
    proven by whole-run offset taps).
  * => mechanism = Donovan-specific OBJ-list length/terminator
    divergence during the shock composition exposes stale list tail;
    the divergence source (piece counts / budgets of other records in
    the composition, or the curtain drawer's slot arithmetic) is NOT
    yet pinned. Shock ENTRY-node number lookup needs a T-walk (0xDAF58
    is an interior node — direct T_d[2n] search fails).
  * Class: non-blocker (maintainer hierarchy); almost certainly NOT a
    regression — present since the record/tile port (user had not
    fought Victor before).
- Instrumentation ready for the fix session: replays 32_victor_shock_
  {vsavj,vsav2}, OBJ-RAM dump/pairing scripts (transcript), tap_writes
  with 32-bit data logging (this session's fix).

## Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)

The armed-normal sword swing is FIXED at root. Full chain (each link
measured): Donovan's anim nodes carry a sword-pose word at node+0xE;
his ported sword-command routine (vs2 0x65EBA family, placed 0xCC0CA)
adds 0x23 and calls set-anim-by-number on the sword object; numbers are
0x124-0x201. vs2 calls the UNMASKED resolver entry (0x5C77E — vs2
hoisted `andi.w #$ff` to a skippable pre-entry at 0x5C77A); vsavj's
twin embeds the mask, and the auto-matched reconciliation row sent
ported calls into it -> numbers truncated -> wrong-but-valid nodes in
Donovan's own (correctly repointed) number table at 0xBD07A[0x0F] ->
sword idled through every attack. Everything else (pose data, table
repoint, tiles, +0x9C char id) was verified correct along the way.
- Fix: new reconciliation kind `patched_clone` (gen) — vanilla resolver
  bytes minus the andi, placed in hole a, ported refs only; vanilla
  callers untouched (36 vanilla call sites keep the masked original).
- Verified: sword walks 0xE19D8-0xE1AB0 (= vs2 0x28DE98-0x28DF28 swing
  family), idx-0 command lands, SNAP pixel shows the blade arc, Anita
  present, spark clean. New permanent gate tests/test_don_sword.sh
  (replay 31_don_6hp probe, node 0xE1A20 assertion).
- Red-herring bookkeeping (measured, valuable): the type-3 "spark" is
  the GENERIC hit starburst (vs2's global effect table T=0x2B7EF4 = the
  head of ported region x2b7ef4) and renders CORRECTLY on our build;
  the 14z-3 "sword-arc effect object" interpretation was wrong. Effect
  strip tables: vsavj T=0x283690 (12 abs code refs), per-char anim
  number tables: vsavj 0xBD07A / vs2 0xD7218 (row 0x0F repointed to
  0xDDA1E by the bank port — verified correct).

## Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean

On-hit effects verified clean in play; no regression observed. State
clean for further work. Current work: the sword-swing display-side
redirect (the one remaining blocker step; see 14z-3/14z-4 and
NEXT_SESSION for the full map and the atomic-change design rules).

## Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)

- Round-25 report (maintainer): garbled effect sprites on hit. Pixel
  A/B (new probe: SNAP_FRAMES on replay 17, frames 3477-3481) convicts
  BOTH 14z-3 thunks: bank_swap garbles the spark (Donovan tile bank
  under vanilla strips), and spawn_mark makes ANITA vanish while a
  marked spark is live (+0x9A = owner-char-id with display semantics;
  "spare field" assumption WRONG). Both rows staged to 99; per-row
  stage filters added to site_thunk/data_port loops (they were being
  applied unconditionally at stage >= 6). Build restored byte-exact to
  597ae55b (round-24 throw-confirmed); battery green.
- The sword-swing fix design is updated: tile bank + strip redirect +
  a PROVEN-dead discriminator must land as ONE change, accepted only
  with the pixel probe alongside the battery (new GOTCHAS entry).
- 597ae55b hit sparks verified CLEAN pixel-wise (the user's "maybe the
  previous build too" is answered: no — the garble was 14z-3-only).

## Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)

Round-24 continuation. The missing "circular sword attack" on armed
normals is DECODED end-to-end (replay 17, native-vs-ported A/B):

- vs2 draws armed-normal sword swings as TYPE-3 EFFECT objects
  (hit-located, ~10-frame strips). Spawn chain: shared engine spark
  spawner (vsavj 0x18EFC / vs2 0x178C2; a3=attack record, +0x12 spark
  id & 0x7F, remap tables byte-IDENTICAL between the games, allocator
  vsavj 0x16FBA / vs2 0x15702) -> type-3 first-tick case (vsavj 0x5E7B2
  / vs2 0x6A7A6, dispatched through the obj_hook-extended table
  0x5E556) -> variant (+0x59) -> param record (anim number 0x102) ->
  set-anim (0x4CE2: facing adds 0x300) -> COMMAND QUEUE (0x31DA) ->
  display processor resolves number->record via PER-CHAR strip tables.
- On the ported build everything matches native (type 3, variant 3,
  position, timing, 10-frame life) EXCEPT the resolved strip: native
  walks vs2 0x2B8190+ (Donovan sword-arc records, ALREADY PORTED at
  0xF420C+ in region x2b7ef4); ported walks vanilla 0x28391C+ (slot-0F
  = Jedah-family effect art) — because the display-side strip-table
  selection still serves slot-0F vanilla tables. Self-relative 16-bit
  offsets make in-place table repointing impossible (ported records are
  1.6MB away; the effect-table zone is overlap-packed shared pool).
- STAGED (build cfe757a1, gated slot-0F-attacker-only, legacy-inert by
  construction): [[site_thunk]] generic construct (gen) + two thunks:
  spark_spawn_mark (allocator wrapper: marks spark +0x9A=0x0F when the
  ATTACKER (a6!) is char 0x0F) and spark_bank_swap (first-tick: +0x18
  tile-bank 0x0000 -> 0x4000 for marked sparks — the same vs2-bank-3 ->
  vsav-bank-2 remap as his six port_patch bank setters). Verified live:
  mark + bank land; anim unchanged as expected (tile bank != anim
  table).
- REMAINING STEP (next session): redirect the DISPLAY-side strip-table
  selection for slot-0F effect objects to a rebuilt Donovan effect
  table (vs2 T at 0x2B0786 family) — the same per-char display-site
  thunk pattern proven in 14q, and the same site family already
  catalogued by tools/overlay_port.py (VERIFIED_SITES). The +0x9A mark
  gives the consumer a per-object Donovan discriminator if needed.
  Sword-arc RECORDS and TILES are already in the build; only the table
  selection is missing.

## Maintainer priority statement (round 24, 2026-07-30)

Round-24 playtest CONFIRMS the throw fix (597ae55b). Standing compromise
hierarchy from the maintainer, recorded verbatim in intent: the MISSING
SWORD SPRITE on armed normals (e.g. 6HP: circular swing not rendered,
hitbox possibly the unarmed variant) is a TRUE BLOCKER for the port.
Palette issues (win-quote, HUD mini-portrait) and the red/purple
sword/statue blinking are NOT blockers — ship-compromisable if it comes
to it. This is a compromise hierarchy, not an ordering command for the
work queue.

## Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)

- Round 23: throw still broken on byte-exact ad372a6b -> round-21
  confirmation was a sampling miss; winpal conviction was WRONG (as was
  the grab-row one). Mechanism trace (new tools/lua: tap_writes.lua):
  victim X/Y written by ported positioner (PC 0xCE51C, region x026142,
  vs2 0x0272CE) walking the pointer-of-tables 0xBE27A[thrower id] —
  slot 0x0F still pointed at JEDAH's keyframe table (0x0B19F8, stride
  0x198/victim) while Donovan's anim indices assume vs2's 0xC8-stride
  layout. Pre-14w the gap auto-table class covered this table; the 14w
  wholesale disable reverted it (Felicia-fix collateral).
- Fix: new [[data_port]] manifest construct (gen_donovan_patch.py) —
  vs2 Donovan's victim-keyframe table (0x0CA1CA, 0xE50, vhunt2 twin
  0x0C9A5C byte-identical, both asserted at build time) placed in-place
  over Jedah's slot-0F zone (fits in 0x1828), mirror-victim offset word
  fixed [0x0F]: 0x0B30->0x0D88. Replay 27 trace: 21 teleport-scale
  jumps -> 4 structured slam keyframes (authentic cinematic motion).
  Build 597ae55b. Legacy surface: slot-0F throwers only; attract@4278
  unchanged (diverges before any throw).
- 27_don_quotewin/27 drift note: the throw connects at 3050/3650 on
  current builds; re-freeze of the 27 oracle still queued.

## Session 14z (round 22: winpal copies convicted and fully reverted)

- The throw victim-teleport reappeared on e7682289 and the timeline
  convicts the WINPAL COPIES (0x248D80), not the 14v grab rows: the
  zone holds throw-cinematic data; no legacy replay threw (coverage
  blindness). Full revert to byte-exact ad372a6b; 14y doctrine
  amendment VOID (02/05/07 exact restored, pick 1080); new permanent
  masked-EXACT gate 30_demitri_throw. Palettes were NOT visibly
  improved by the copies anyway — the quote/HUD row consumer remains
  UNDECODED (none of 0x1BF56/0x1C1FA/0x1C426/0x7D4FC/0x1C5CE feeds
  the visibly-wrong rows). Next palette attempt starts from a runtime
  trace of the ACTUAL row writes on the quote screen/HUD, with the
  throw + pixel gates watching.

## Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)

- Round 20: triangle jump CONFIRMED FIXED. But the 14v grab-pointer
  reconciliation BROKE Donovan's throw in play — maintainer decision:
  roll it back, keep only the Felicia fixes. Done (the 8 rows gated
  to stage 99 with a full post-mortem note in donovan.toml): the
  vsavj engine consumes its grab-pointer vars with native-throw
  semantics that conflict with the ported throw's flow; the original
  stray writes are silent and the throw worked for 19 rounds with
  them. Re-attempt requires decoding the engine-side consumer first.
- NEW MECHANICS/RENDERING ITEM (round 20): on some normals the SWORD
  ATTACK doesn't render even when equipped — e.g. round-start 6HP:
  Donovan's sprite and damage look right, but the sword's circular
  swing isn't drawn and the hitbox may be the unarmed one. Ties into
  the sword/overlay rendering work (the parked overlay + the sword
  records) — keep in scope for the sword-rendering search: the
  armed/unarmed variant selection may involve the same per-state
  record webs.
- Fingerprint ad372a6b; battery at session end.

## Session 14w-c resolution (ALL GREEN at d6a751cb)

- The halt lifted: the type-63 handler's crash was its hit-reaction
  id 0x50 — past vsavj's vanilla table, below the hook's old ext
  range. One-slot reaction_hook extension (case verified verbatim
  against vs2) closed it. Full battery green including both new
  gates (29_felicia_walljump, pixel menus). SHIPPING d6a751cb.
- PLAYTEST (round 20): (a) Felicia's triangle jump — wall latch back,
  and her walk now byte-exact vanilla; (b) throw anyone repeatedly
  (the grab-pointer fix from 14v rides along); (c) deep arcade runs
  with Donovan — the type-63 moment (~his 2nd match win region)
  should now just work; report anything odd there; (d) win-quote
  palette is STILL Jedah's (known: preload-staging consumer decode
  queued); sword blink unchanged (overlay parked).

## Session 14w-c original halt record (kept for the mechanism)
## Session 14w-c (type-63 chain: RULE-6 HALT — the only open task)

- The pair-table fix changed CPU-Felicia's fight flow in 21_don_mash,
  and at frame ~10050 Donovan's own deep-arcade path SPAWNED
  SECONDARY-OBJECT TYPE 63 for the first time ever — hitting its M2a
  tripwire (0xCB880). The "types 59-62 only" assumption is
  measured-wrong. Handler ported (extra root 0x6717c:0x154:t0x671b0,
  clean extraction: 13 refs, all engine rows verified) — the tripwire
  no longer fires, but 13 frames later the REACTION DISPATCH
  (engine 0x18460) crashes: vec3 at PC 0x18466, ADDR 0x1B6A3.
- Crash math (exact): jump-table fetch with d0 = -8 -> d1 = the
  dispatch's own first opcode word (0x323B) -> odd target 0x1B6A3.
  d0 = -8 means a GARBAGE/UNINITIALIZED reaction id, not an OOB
  vs2 id. Leading hypothesis: OBJECT FIELD LAYOUT divergence
  (same-value class #5 candidate) — the ported handler writes vs2
  object offsets (+0x9E/9F/A2/B0/B3/B4 observed) while vsavj's
  reaction system reads its id from a different offset; the handler
  disassembly (STATE-annotated above) never writes vsavj's +0x38.
  NEXT: diff the two engines' reaction-id field offsets (find vs2's
  site_prefix analog of `tst.b 0x38(a1)` and its dispatch d0 load),
  then add a field-offset port_patch to the handler.
- RULE 6: the battery is RED on 21_don_mash until this lands; no build
  ships. Felicia's legacy fixes are verified and committed (29 gate
  green throughout); the last all-green build (dc6b2d36) is NOT
  shippable knowingly (it carries the Felicia legacy violations).

## Session 14w-b (second Felicia defect: the pair-table stride bug)

- vsav.zip restored; rebuild 53ec9c51 fixed the WALL LATCH (verified
  byte-identical trajectory) — but the freshly frozen 29 gate caught a
  SECOND defect: her walk-back speed off by a subpixel fraction
  (whole-pixel motion vs vanilla's accumulating fractions). Root
  cause: param32_a/b are 8-byte PAIR tables (fwd/back velocities)
  registered at 4-byte stride — "slot 0x0F" hit Felicia's walk-back
  half; the extractor read the equally wrong vs2 half. bank_map fix:
  rec8/stride-0x100; Donovan now ports his true velocity pair onto
  Jedah's true pair. Felicia byte-matches vanilla except one
  spawn-boundary flicker frame (29@2435) — 29 reclassified to the
  approved FLICKER class. Fingerprint 340673da.
- LESSON (GOTCHAS updated): the new-replay-then-freeze loop caught in
  ONE day what 19 playtest rounds missed twice — every mechanics bug
  fix must ship with its oracle replay, and per-char tables' ENTRY
  layout must be verified against vanilla content (pair-sign
  signatures), never assumed from spacing.

## Session 14w (FELICIA'S TRIANGLE JUMP: root-caused to the gap-write
class; gen fixed; REBUILD PENDING vsav.zip restoration)

- Round 19 clarified the float = Felicia's WALL JUMP broken (no wall
  latch; rises off-screen, wraps twice). New replay 29_felicia_walljump
  reproduces it deterministically — in a PURE LEGACY match (Felicia vs
  Bulleta): a superset violation that every RAM gate missed because no
  replay ever played Felicia and per-char physics only surface in use.
- Root cause via restore-bisection (31 candidate groups eliminated:
  winpal, all four engine hooks, the select/pool writes, all data
  members, per-char table rows): the generator's speculative GAP
  writes. gap_bdc7a[0x1F] (vanilla 0xFFFF4800, the wall-jump-back
  velocity) was overwritten with Donovan-derived 0xFFFFEC00. 42 gap
  writes existed, 31 changing vanilla engine bytes — ALL disabled in
  the gen (session-14w comment in gen_donovan_patch.py). With every
  gap restored: Felicia latches at the exact vanilla Y and Donovan
  soaks clean — the writes were pure harm.
- ALSO exonerated this session: the 22 overlay thunk sites (CCR
  audit), the sound-farm stubs (ported-call-only by design).
- **BLOCKED: vsav.zip is missing from ROMDIR** (folder shows recent
  Finder activity — likely the maintainer's reorganization; cfg/nvram
  dirs from some unsandboxed MAME run also present). The audit gate
  correctly halts all builds. Once restored: rebuild, full battery,
  freeze 29_felicia_walljump's expectation (vanilla-exact class — it
  is a LEGACY replay), and re-run the throw-oracle refreeze.

## Session 14v (grab-pointer work vars fixed — the Felicia float)

- Round 18: quote palette STILL Jedah's => the quote screen consumes
  the select-time preload staging; decoding the staging CONSUMER is
  now the path (the 14u copy-and-repoint plumbing stays — correct and
  needed either way). And Felicia floated off-screen after a throw:
  root-caused to 8 unreconciled A5 work-var refs in the ported throw
  code (grab POINTER stores + a state clr through vs2's layout —
  garbage into two vsavj engine vars every throw). The A5 audit
  (open since 14o) is now COMPLETE: no other unreconciled refs in
  0xB000-0xBFFF anywhere in ported code. 8 port_patch rows shipped;
  analogs triple-verified in both engines' native throw code.
- 27_don_throw oracle has drifted (pre-throw hits connect on current
  builds) — re-freeze needed; grab rows shown outcome-neutral on it.
- PLAYTEST asks: (a) throw Felicia (or anyone) repeatedly in a
  Donovan match — the float should be gone; (b) throws should feel
  vs2-correct.

## Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)

- Four masked-gate iterations distilled the survivable design (see
  patch_notes 14u): patched block COPIES in dead space + a private
  pointer table + exactly ONE poked reader site (0x1C1FA, the only
  exclusively-quote-time one) + the 0x60-view lea. Three select-time
  bulk preloaders identified by per-site gate bisection (0x1BF56 /
  0x1C5CE 2P / 0x7D4FC challenger-join) stay vanilla.
- All gates green on 1f5fa38e. PLAYTEST QUESTION: does a Donovan match
  win now show his quote palette? If not, the quote screen consumes
  the preloaded staging and the staging consumer is next.

## Session 14t (win-quote palette: decoded, port REVERTED by the gate)

- Round 17: menus clean. The palette chain is fully decoded (see
  patch_notes 14t) but the in-place slice port DIVERGED legacy 2P
  replays (03/16, 3229/2008 frames from select entry): the per-side
  blocks are bulk-staged through work RAM MID-FRAME on legacy paths —
  transient divergence visible only to the checksum's sample point.
  Reverted; shipping stays 37269fff. Next attempt needs the staging
  reader decoded (find the mid-frame copier of 0x39FDC0/0x3A18E0 and
  make its slot-0F slice source conditional), or a maintainer-approved
  masking amendment for the staging buffer.
- Diagnostic GOTCHA earned: per-frame unmasked checksum/dump runs READ
  the QSound latch and perturb both builds identically — legacy
  comparisons must replicate the gate's exact mask set, and mid-frame
  transients require comparing at the checksum's sample point, not
  frame-done dumps.
- NEW REPLAY 28_don_quotewin: wins a match (23 turned out to LOSE on
  current builds), reaches the story card + continue/quote screens.
  New cosmetic: loss-path quote screen shows Jedah's win-quote art.

## Session 14s (playtest round 16: overlay REVERTED; pixel gate born)

- Round 16 (maintainer): Anita/Donovan render correctly BUT (1) the
  red/purple flicker persists over the grey sword/statue (unpoked
  table families still draw Jedah art on top) and (2) MASSIVE menu
  corruption: title, select, speed menus, VS portraits garbled.
- Overlay PARKED again (build/manifest/overlay.wip). Cause of (2):
  the tile pool used OBJ-dead positions whose BYTES back scroll-layer
  menu art — CPS-2 scroll1/2/3 decode the same ROM bytes (GOTCHAS).
  Every RAM gate was green throughout: gfx is invisible to RAM-basis
  comparison. The overlay redesign needs a BYTE-dead pool.
- **NEW GATE**: tests/test_gfx_menus.sh — pixel-exact comparison of
  title/select/speed-menu frames vs frozen vanilla goldens
  (tests/expected/vsavj/menus/), wired into test_m2b_stage6.sh. On its
  first run it caught a LATENT SHIPPED BUG: the speed-menu TURBO/AUTO
  text sat 8px off since the select-screen work — select_port's
  in-place coordinate write hit one byte of the menu record's list
  (head shared inside Jedah's banner list span). First fix attempt
  (relocate all lists + repoint cptrs) FAILED the masked gate —
  cptr values are RAM-visible on select paths (fourth stored-anchor
  class; 02/03/08 diverged at ~820). Final fix: cptrs untouched,
  in-place list writes kept, and SHARED lists (the banner's) simply
  not written — Donovan's banner draws at Jedah's position. Shipping
  fingerprint 37269fff; pixel gate green; full battery at session
  end.
- Overlay next steps (with the WIP): byte-dead tile pool (candidates:
  bytes of Jedah band art already replaced in group B — his band
  minus scroll-shared spans, TBD by a scroll-usage census — plus 0xFF
  padding); the red/purple flicker = the unpoked families
  (0x2675AA/0x26772A/0x26775A + dead-entry tables).

## Session 14r (overlay port COMPLETED to a 22-site shipping config)

- Round 15 (maintainer): no regressions on f29cf24a.
- The stride-8 stream grammar was completed (flags 0x80 = 12-byte
  jump node — the attack-anim loops that caused every attack-input
  crash; 0x40 = terminal; ptr 0 legal), the heap port regenerated
  (segB collapsed 22KB -> 496B once stream extents were真 bounded),
  and every context-verified site probed individually on the Donovan
  path with the watchdog-proof timer-tick detector. 22 sites ALIVE
  through DP-spam and win screens; 3 crashers excluded and documented
  in tools/overlay_port.py (VERIFIED_SITES / KILLER_SITES policy —
  the emit is deterministic; fingerprint cf2109d8 after the fmtA-opaque fix — the guarded soak caught a frame-8424 address error from streams truncated at skipped fmtA records).
- VISIBLE: Anita fully drawn dragging behind Donovan; sword on his
  back; clean win pose. The Jedah-darkness blink is gone. Open
  question for playtest: the hat piece alternates per frame (vs2
  dither vs residue).
- Remaining for a later pass: the 3 excluded sites (indexing-variant
  decode: ±4-anchored table entries / site-biased ids), the four
  100%-dead tables (0x2A0862 family — win/vignette features via
  whdr-strips partially live), fmtA composite records (20 skipped).
- Gates: full battery re-running clean at session end (a first run
  was voided by a build-tree race with foreground rebuilds — gate
  scripts rebuild build/donovan6 themselves; never rebuild while the
  battery runs).

<!-- superseded header: session 14q -->
Updated (superseded): 2026-07-29 (session 14q — overlay port 80% built, PARKED as
build/manifest/overlay.wip; shipping build = f29cf24a (feet fix,
playtest-confirmed round 14); M2a frozen a02aeeff…, M2b-core frozen
71601263…)

## Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)

- **Round 14 (maintainer): Anita's feet fully clean incl. shadow, no
  regressions** — f29cf24a validated.
- Stage-7 build attempt (topology B) reached a proven architecture with
  one remaining blocker. What is PROVEN (each by masked 02 probes,
  full-length identical unless noted):
  1. **Placement**: vs2 overlay slice [0x2A0426,0x2A63F0) split at
     0x2A4A48 (above max self-relative table reach), segA+cptr-tail at
     0x248D80, segB at 0x2557B0 — inside JEDAH'S OWN ANIM AREA, the
     only proven-dead space (slot 0x0F always runs Donovan). Legacy
     CLEAN. (First two placements failed: Jedah's strip-area "gaps"
     interleave the shared MUSIC POOL — see GOTCHAS.)
  2. **Site repoints**: 25 context-verified Jedah T-sites, thunked
     (`movea.l #T,a0` -> `jsr thunk`; ported T iff match-active AND a
     slot-0x0F participant). Legacy CLEAN with all 25 active. Static
     pokes are IMPOSSIBLE (attract cutscene IS Jedah ~888; shared
     display flows hang other-char matches — measured both).
  3. **Tile pipeline**: 3929 bank-1 pairs (874 blocks; fmt4/6/8 draw
     stored+0x3800 — handler decode) placed at dead-Jedah positions +
     padding; build_gfx --overlay-tiles chain verified.
- **BLOCKER**: with data+rewrites active the DONOVAN path watchdog-
  crashes at match start. Cause class: the slice's 293 blind long
  relocations + 2811 tile-word rewrites in 163 scan-validated records
  include false positives that corrupt stream/coordinate data (fmt4
  validation is cptr-less; coordinate words alias pointer prefixes).
  Fix path: STRUCTURAL CLOSURE — decode the stream node language
  (tables -> strips -> tag-streams -> records), restrict relocation
  and rewrites to the closure, leave everything else byte-intact.
  Groundwork in place: fmt handlers decoded (0x1AFC6/0x1B234/0x1B61A/
  0x1B6AA/0x1B73E/0x1B7CC; A0=rec+2), strip = plain long array,
  tag-stream = (FF-tag,ptr) pairs, walker 0x15082 = T + T[2*id]
  self-relative.
- Everything parked in build/manifest/overlay.wip/ (gen ignores it
  until renamed back to overlay/); tools/overlay_port.py +
  gen thunk assembly + build wiring are committed and inert. Shipping
  fingerprint re-verified f29cf24a after parking.
- New GOTCHAS: attract-cutscene-is-Jedah (conditional thunks), music
  pool interleave (watchpoint read maps have a computed-addressing
  blind spot), blind relocation corrupts mixed data blobs.
- **14q continuation (same session): closure v5 built and iterated.**
  Object-granular heap port (closure walk tables->strips/streams->
  records; heap over Jedah's dead anim areas; per-object placement
  map; table entries recomputed only when validated, verbatim
  otherwise). Grammar discoveries, each verified against data:
  (1) stream nodes = (tag.l, ptr.l) stride 8, tag = (duration.b,
  flags.b, param.w), NULL-ptr nodes legal ("no record this phase");
  (2) grammar-4 = word header + bare long array at +2 (the
  0x2A0862-family targets); (3) fmt4 record size is 14B; (4) the
  engine stepper family ALSO walks 0x10/0x18-stride node forms —
  stride is an OBJECT-STEPPER-CLASS property (0x15030-0x15080 lea
  variants), NOT table- or data-derivable (a longest-run stride
  heuristic corrupts real 8-streams — measured, reverted).
  Probe results (detector: round-timer tick + match flag — earlier
  detectors were fooled by watchdog reboots keeping stale RAM):
  data-only ALIVE and legacy-clean; pokes for the 2671C6/267224/
  267284 tables ALIVE through round start but CRASH ON THE FIRST
  623P (attack-id-indexed entries hit still-dead table slots);
  2671E6 (attack-id table, walker 0x15084/inline variants) worst.
  REMAINING DECODE: map each poked table to its stepper class
  (which stride its streams use) — then re-walk dead entries with
  the right stride and the closure should complete. All probe
  tooling: /Users/koneko/.claude/jobs/*/tmp/donprobe.sh pattern
  (rebuild-with-poke-subset + timer-tick verdict), op_v5_all.json
  site list. Shipping build re-parked at f29cf24a.

## Session 14p (feet fixed; blink mechanism = Jedah's overlay records)

- **ANITA'S FEET FIXED** (build f29cf24a): the garble was record
  0x0FCECA (x2b7ef4) whose 54-record strip draws at BANK 2 (#$4000
  sub-objects) but was triaged by the BANK-1 effect-tail maps (+0x47
  reloc → codes 0x0FD2/3 = wrong-page garbage; the earlier "solid
  green" was the same entries pre-reloc). Empirical attribution per
  the f8eda2ca mandate: handler-breakpoint trace over 9 replays
  (tests/lua/obj_record_bank_trace.lua) found the ONE bank-2 record;
  closure came from its sub-object's record stream (54 recs, 37
  blocks, vs2 codes 0x0F8B-0x0FBC). Data-only fix:
  tools/gen_anita_bank2.py → effect_tail.json bank2_recs/bank2_place
  (shelf rows 0xEAC0-0xEAFF); the generator's surviving bank-2 branch
  does the rest. OBJ RAM + screenshot verified; gates re-run.
- **SWORD/STATUE BLINK ROOT-CAUSED** (no fix yet — next surgery): the
  in-match companion overlay sub-objects ($FFB800-$FFBA00, bank
  #$2000) walk per-char record-pointer strips; on our build the char
  slot resolves to JEDAH's strips (0x2674AA-0x268Axx → records
  0x271D70/0x272156/0x272800/0x272A68…, codes 0xAFxx/0xB4xx/0xCDxx =
  Jedah's bank-1 darkness art, tile content verified vanilla≠vs2). The
  "blinking sword/statue" is Jedah's overlay ANIMATING where Donovan's
  sword-drag/statue belong. vs2 ground truth (handler trace on
  vsav2, 27_don_throw_vsav2): ~16 sub-objects draw records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, strips 0x2A0Axx-0x2A1Cxx
  after root 0x2A05E2). Fix class: select_port-style IN-PLACE
  strip+record replacement inside Jedah's per-char region — all three
  superset traps apply (budgets, cell pokes, legacy coord reads);
  bank-1 codes go through the effect-tail triage (content-match /
  reloc / place), NOT raw copy. New GOTCHAS entries: bank attribution
  is an object property; breakpoint traces are lossy SAMPLERS —
  structural closure required; overlay-strip mechanism.
- New tools (persistent): tests/lua/obj_record_bank_trace.lua,
  tests/lua/obj_record_full_trace.lua (all six fmt handlers via the
  0x1AFBA jump table — vsav2 sibling addresses in header),
  tools/gen_anita_bank2.py.
- **Overlay strip inventory MEASURED** (exact, RAM-dump method — the
  debugger-desync gotcha rules out bp traces for this): 16 sub-objects
  $FFB800-$FFBF80, all bank #$2000, cursors in Jedah strip pages
  0x267xxx/0x268xxx (b800/b880 also walk engine-shared strips
  0x15Axxx); b900/b980/ba00 dual-phase to bank #$4000 with PORTED
  cursors (0x0E2xxx sword-anim / 0x0DDxxx / 0x0F619C feet — already
  correct). Cursor-setter decoded: engine routine 0x15082 computes
  cursor = T + T[2*id] (T = per-char self-relative word-offset table;
  Jedah's T = 0x2671C6 measured at one call). vs2 sibling: same 16-slot
  population walks Donovan strips 0x2A0Axx-0x2A1Cxx → records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, bank 1).
- **Stage-7 surgery sketch (next)**: port vs2 overlay region
  (~[0x2A05E2,0x2A4000), bounds to refine) as a new manifest region;
  reroute the char-0x0F strip-base lookup (find who loads T=0x2671C6 —
  per-char table row or computed; repoint to the ported copy); bank-1
  code triage via the effect-tail classes; coordinate cptrs via the
  pool content-match; placement needs ~15KB (hole A ~0xE80 + hole B
  ~0x650 are TIGHT — space audit first; Jedah dead zones are
  attract-demo-read, gate-guarded by the frozen-4278 class). Vanilla
  Jedah strip bytes stay untouched.
- Throw-damage magnitude (round 13 note "lower than Savior 2"):
  recorded as a maintainer-feel item — the port routes Donovan's raw
  damage through VSAVJ's global defense scaling by design; the oracle
  measured the test throw EQUAL to vs2 (-5). If it should match vs2
  everywhere, that's a rules decision, not a bug.

## Session 14 highlights (M2a FROZEN)

- **Playtest round 3 (maintainer): fully clean** — no crashes over
  multiple matches, no music from any input. The 214P/214K stragglers
  were two sound-farm entries masquerading as `engine_data` rows since
  the session-5 bare-long pass (0x4F14/0x5052 — byte-match locks onto
  the same-id vsavj entry = the same-id-different-meaning trap with a
  verified sticker) + the direct-called helper 0x5122. Full farm-ref
  audit (jsr/bsr/jmp/pea from all ported zones): 25 stubbed / 4 live
  init-zone rows. GOTCHAS entry added: when a structure class gets
  understood, re-audit earlier generic rows in its range by MECHANISM,
  not row kind. Note: sound wrongness is invisible to every RAM-basis
  gate (music state lives in QSound RAM) — playtest is the only surface
  catching this class until an M5 harness exists.
- **M2a FREEZE EXECUTED** (playtest-gated per the standing decision;
  maintainer confirmation 2026-07-28): registry row
  `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv;
  `tests/run_suite.sh` gained the `.masked` expectation kind (exact /
  flicker-frozen-inventory / diverge classes per CLAUDE.md §4 v2, masked
  runs auto-selected) and `.skip` (other-romset replays);
  `tests/expected/donovan-m2/` authored from the frozen gate inventory;
  Donovan-replay self-expectations frozen on a02aeeff; vanilla
  expectations frozen for replays 17-26 (drift check on pre-existing
  vanilla sha1s: none). Validation: `run_suite.sh` GREEN on BOTH builds
  by pure fingerprint auto-detection — the one-command-validates-any-
  build doctrine is now real for hooked builds.

## Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)

- Donovan's throw deals correct damage (oracle-measured: 288->283 = -5,
  byte-matching vs2's result at identical inputs, flowing through
  vsavj's own defense scaling). ROOT CAUSE = the FOURTH same-value
  sibling-coincidence class: A5-relative WORK-VAR DISPLACEMENTS. The
  ported throw-damage writer (x028122, vs2 0x28AC2-0x28AF6) stored
  scaled damage into VS2's work-var layout (-0x4B6C/6A/68) while
  vsavj's post-process reads ITS layout (-0x4BBE/BC/BA) — damage into
  dead variables = landed-but-zero. Six displacement port_patches
  (uniform family shift -0x52; vsavj native analog byte-verified at
  0x29790). Diagnosed AND verified by the NEW 27_don_throw oracle pair
  (permanent suite replays; vanilla expectation frozen 086476eb).
- Fingerprint eb051b12: double gate + oracle/xemu/flavor green.
- OPEN AUDIT: sweep ALL ported code for (d16,A5) vs2-layout work-var
  displacements — other dead-var writes may lurk.

## Session 14n (round 12: revert validated; two new items scoped)

- Round 12 on restored 569859d1: specials correct, NO resets — the
  board reset is pinned to the reverted f8eda2ca with certainty.
- NEW COSMETIC: solid-green background tiles around ANITA'S FEET (her
  sprite clean). Likely one/few mismapped tiles in the effect-map or
  tail placements rendering opaque green where transparency belongs —
  find by dumping her OBJ entries at the artifact moment and checking
  which placed tile draws the green block.
- NEW BEHAVIORAL (present since the beginning, priority — gameplay):
  DONOVAN'S THROW deals almost no damage vs Savior 2 / native chars.
  An R1 damage-path gap: his ported throw handler's damage source
  (immediate value, per-char table row, or engine damage id) resolves
  wrong on vsavj. Method: bp-trace the damage post-process during a
  throw on our build AND on real vsav2 (matching inputs), diff the
  damage arguments; then fix the data path (reconciliation row or
  value repoint) — oracle-gated. Needs a throw replay (the test
  matrix's throw/tech coverage gap — write 27_don_throw as part of
  the fix, per the persistent-suite doctrine).

## Session 14m (f8eda2ca REVERTED — regression + board reset)

- Playtest round 11 on f8eda2ca: blink unchanged, 623P degraded, and a
  BOARD RESET mid-fight (watchdog class). Rule 6 halt: the bank-2
  config stripped from effect_tail.json; the build restores 569859d1
  BYTE-EXACT (the round-10-validated build: specials good, sword
  blinks = known open issue).
- Post-mortem of the failed fix: the content-voting attribution was
  wrong — the ownerbox dump already showed the sword records live in
  the ANIM region (rec 0x0F32C8 ∈ anim dst), not x2b7ef4; the 14
  rerouted records were misattributed and the loose record validation
  (731 detections vs ~151 real) makes false-positive rewrites — the
  likely reset mechanism. LESSONS: content voting is too weak for
  bank attribution; only EMPIRICAL object-correlation counts; and any
  pass that rewrites record bytes must validate records STRICTLY
  (known-record lists, not heuristic scans).
- The blink remains open. Correct next method (fresh session):
  side-by-side sword-object comparison — dump the sword object's
  [0x1C]/records/entries on real vsav2 and on our build at matched
  moments; diff entry-by-entry; fix exactly what differs. No rewrites
  without an empirically-verified record list.

## (reverted) Session 14l (bank-attribution fix)

- The x2b7ef4 walk now attributes records by drawing bank via content
  voting: 14 records (109 blocks, 312 tiles — the sword/statue class,
  bank-2 objects) route through band-tail placements (vs2 bank-3
  content at 0xEA40+, 722 tail positions spare); the rest keep the
  bank-1 effect-tail path. Fingerprint f8eda2ca: double gate green,
  companions green. Playtest verdict wanted on: sword steadiness,
  round-start statue, specials still good, win-quote palette (still
  pending implementation), general sweep.

## Session 14k-b (blink TRULY root-caused: per-record bank attribution)

- The saturation theory was an artifact: the ~540 null entries are the
  CLEARED TAIL of the OBJ list (the drawer processes a separate count;
  real usage ~357/896 — headroom fine). Bisect (worktree rebuild of
  8248296e) also proved the coord surgery innocent (identical state).
- REAL MECHANISM (live object dumps): the sword/statue objects draw at
  BANK 2 (their #\$6000->#\$4000-patched setters) but their records
  (x2b7ef4 region, e.g. 0x0FCECA with entry codes ~0x0FD2) were treated
  with BANK-1 semantics by the effect-tail pass. Their anim frames with
  engine-page codes hit wrong bank-2 positions -> invisible frames =
  blinking at the anim rate (matches the playtest report exactly:
  different rate than vs2, statue identical).
- FIX (next): per-record bank attribution in the x2b7ef4 walk —
  content-addressed (bank-2 records' low codes match vs2 BANK-3 art =
  Donovan effect art; bank-1 records match the engine page) — route
  bank-2 records through the band-tail placement (effect-map style)
  and keep bank-1 records on the effect-tail path.

## (superseded analysis) Session 14k (OBJ budget saturation theory)

- Playtest round 10: specials CONFIRMED fixed; sword still blinks and
  the round-start statue blinks identically (same palette; vs2 clean).
- ROOT CAUSE FOUND: the per-frame OBJ list is SATURATED — 897 of 896
  budgeted entries every frame, of which ~545 are ALL-ZERO entries from
  a runaway record (suspected fmt-0 count-0 -> subq/dbra wraparound
  emitting nulls until the budget dies). The sword/statue draw last and
  get budget-skipped on marginal frames = the blink. NOT the class-7
  queue (only one site, already remapped; no live 0x0E-class objects),
  NOT palette-row conflict (row 3 written once), NOT engine budget
  difference (both games 0x380).
- NEXT (precise): (1) dump objects + correlate [0x1C] to find the
  runaway record's owner; (2) rebuild commit 0867b25 (8248296e) and
  count nulls there to bisect pre/post the coord surgery — the blink
  predates it per playtest, but the 545-null magnitude needs the same
  verification; (3) fix = correct the record/chain terminator (and
  audit the coord-surgery's loose record validation for false-positive
  rewrites in the x2b7ef4 blob — 731 detections vs ~151 real records
  is suspicious in itself).

## Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)

- 623P/214K elemental summons render again (snapshot: the flaming Ifrit
  sword + fire pillar in full). Triage of the 491 companion-effect
  blocks: 344 same-index; 70 relocatable by content match (page shift
  +0x47 class, wrap-safety enforced); 77 blocks (263 tiles = vs2's
  newcomer extension of the engine effect page, 0x0E17-0x0F02) PLACED
  at vsav bank-1's padding run 0x3640+ (460 blank positions before the
  system band). Per-entry code remap in the gen (effect_tail pass,
  build/manifest/effect_tail.json).
- BONUS LATENT BUG FIXED (third sibling-coincidence strike, GOTCHAS):
  the records' coordinate lists point into vs2's GLOBAL X/Y pool —
  same-value across siblings, never relocated; effects have read
  garbage coordinates since M2a. Fix: 114 lists content-matched into
  vsavj's own pool, 617 Donovan-specific lists ported (11.3KB fragment,
  hole B). Sword-glint/blink expected fixed by the same pass.
- Fingerprint 569859d1: double gate green, oracle/xemu/flavor green.
  Playtest wanted: 623P/214K/sword in-match, win-quote palette still
  pending (next), quote text line, HUD name, wheel face, attract pal.

## (earlier) Session 14i-b (round-9 mechanisms pinned)

- WIN-QUOTE "left shift" = NOT a defect: both records' coords are
  identically centered on the object anchor; vsavj's own win-screen
  layout places the winner's art LEFT (Bulleta's screen confirms).
  Recorded as a feel item (default = host layout); no code change.
- WIN-QUOTE PALETTE mechanism found: per-char pointer table at CODE
  0x7F196 (PC-relative, indexed by winner char*4 from $140(a5), rows to
  palette RAM 0x17 band) + the ramp path (PC 0x153C2, per-char fade
  blocks ~0x3A14xx, seeding chain via the win module scripts at
  0x7E662). Pointers are consumed transiently (A0, никогда stored) —
  unlike the record cells, ROW REPOINTS ARE RAM-INVISIBLE here: plan =
  place Donovan's vs2 win-palette blocks (vs2 twin tables to locate by
  the same code idiom) in Jedah's freed region + repoint row 0x0F in
  the vsavj tables. Verify with the masked gate as always.
- Effect tail (elemental swords/sword glint): plan unchanged
  (block-content matching + placement + record remap) — next session's
  main chunk with fresh context.

## (earlier same session) Playtest round 9 diagnosis

Playtest round 9 (on 8248296e): win-quote ASSETS correct but palette
wrong + image shifted left (vs2 layout is right-side); Donovan's sword
blinks/vanishes in-match; the elemental-sword specials (623P Blizzard
/ 214K Ifrit) LOST their big blue/yellow effect sprites. Diagnosis:
- FLASH/SWORD = the deferred x2b7ef4 engine-effect tail, NOT a fresh
  regression: those effect records were never remapped in ANY build
  (deliberately left as-is because 1,070/1,455 tiles are same-index in
  vsav); the elemental-sword and sword-glint art is among the ~385
  tiles whose vsav bank-1 positions moved — codes point at wrong/blank
  art. Promoted from 'minor tail' to MUST-FIX. Plan: block-level
  content matching (vs2 bank-1 blocks -> vsav bank-1 relocated
  positions; place the truly-missing into free bank-1 space), per-entry
  code remap in the ported x2b7ef4/anim records via the gen effect-map
  mechanism.
- WIN-QUOTE X-SHIFT: Donovan's ported coordinate list is vs2-layout
  (right side); fix = constant X translation computed from the two
  records' bounding anchors, applied when writing coords.
- WIN-QUOTE PALETTE: the win screen ramps its palette from ANOTHER
  per-char grid (~0x3A14xx for Bulleta; ramp writer PC 0x153C2,
  source-formula base to pin down like the select grid at 0x3AC000).

## Session 14h highlights (win-quote portrait ported; HUD name found)

- Win-quote screen: the family is d0 = 0x40+char over the same root
  table (found via the Bulleta-quote object dump — no replay reaches
  Donovan's own quote screen, so visual confirmation is playtest's).
  His 35-entry win-pose record replaced in place (host budget kept);
  art fit into Jedah's own freed win tiles + the pool tail (pool-math
  lesson: variant alias rows 0x1F point at the SAME records — skip
  them when computing exclusivity). Fingerprint 8248296e, double gate
  green + companions. The quote TEXT line is a separate object family
  (cell area 0x2681xx) — next target if the playtest shows Jedah's
  line under Donovan's portrait.
- NEW COSMETIC FOUND (snapshot): the in-match HUD name label still
  reads "Jedah" — added to the list (with wheel mugshot face and
  attract palette).

## Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)

- VS-splash busts ported (playtest round 8): the six per-char cells'
  FIRST records are the live ones (object durations read garbage-huge
  values, so chains never advance). Final surgery set: splash P1/P2 +
  pal P1 in place (with the wheel portrait + name from phase 2); the
  hover-P2/pal-P2 records PROVEN SHARED with the win screen on legacy
  paths and left vanilla; 130 more bank-1 tiles placed. Snapshot: the
  VS screen shows Donovan's praying-hands bust, correct colors + name.
- THE MASKED LEGACY GATE CAUGHT THREE REAL SUPERSET VIOLATIONS in this
  surgery series, each root-caused to the byte (GOTCHAS entry): cell
  pokes are RAM-visible via stored anchors; record budget words debit a
  shared frame budget ($FF811B one-byte proof); the win screen reads a
  "select" record's coordinate list on legacy paths (frame-10732 trace,
  PC 0x8C6E2). Fixes: in-place only, host budgets preserved, shared
  records left vanilla. Fingerprint 189fdff3: double gate run green,
  oracle/xemu/flavor green.
- Remaining cosmetics: wheel hexagonal mugshot face (background scroll
  art), win-quote screen (still Jedah — the winner-portrait family, to
  be found the same way), attract palette.

## Session 14f highlights (select palettes fixed; splash/win specified)

- Playtest round 7 (portrait/name correct, PALETTES wrong; splash+win
  still Jedah) -> palette grid found and ported in place (11 variant
  rows; vs2 keeps Donovan's rows behind a code special-case +0xC6).
  Fingerprint 4fc8d14b, full battery green. Splash/win screens fully
  mapped (bust objects, three char-scaled cell families, six pokes
  needed); blocked only on the struct flag-byte termination decode for
  exact chain inventories — then it is the phase-1 zone port with the
  right cells. See engine_internals.

## Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)

- Donovan's big portrait and name banner render at the select screen
  (snapshot-verified) — in-place record surgery (select_port.py phase
  2) + 101 bank-1 tiles placed in Jedah's freed select/splash art.
  Build e98a357a; splash-frame OBJ dump closed the placement safety
  gate; cursor-highlight record deliberately kept Jedah's (vs2 wheel
  geometry mismatch). Full battery: soaks, oracle, xemu, flavor,
  scroll3 green; masked legacy green on rerun x2.
- GATE ANOMALY under standing watch: one invocation failed 02/10 masked
  (84 frames @663 on 10); same build passed everything on reruns,
  deterministically at the frozen inventory. Unreproduced; failing-log
  preservation added (build/gate_failures/). Recurrence = stop and
  root-cause.

## Session 14e (earlier): handles found, surgery specified

- Differential cursor dumps found THE handles: per-wheel-slot pointer
  arrays advanced by cursor movement; Jedah's three record cells
  identified; P2 arrays alias the same records => in-place record
  replacement fixes both sides, zero pokes. Donovan's three records
  dumped live on real vsav2 (all smaller => fit in place). Art fit
  computed (9 blocks incl 8x8 into Jedah's exclusive family art).
  ONE open safety gate: empirically prove the chosen tile positions
  are not shared with other chars' VS-splash art (in-match module
  family, root 0x0B76C0 — structure differs, needs a live dump).
  Then implement + snapshot-verify + battery. Map in engine_internals.

## Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)

- Attempted the select-portrait port via the three traced root cells
  (select_port.py: zone port into Jedah's freed region + pokes). Pokes
  landed, screen unchanged — the live chains are INLINE pointer arrays
  in the shared web, not those cells (live object dumps on the patched
  build; engine_internals corrected). Reverted from the build (stage 6
  back to verified 71601263 byte-for-byte); select_port.py kept as WIP
  machinery. The LIVE PREVIEW at select already shows Donovan+Anita
  correctly; only the big portrait, name banner, and mugshot remain
  Jedah. Next: two-char differential dumps at the hover moment to pin
  the per-char inline groups, then in-place 32-bit pointer surgery.
- Space fact: the eventual select web (~51KB) must live in Jedah's
  freed anim region — both PRG holes are nearly full.

## Session 14c highlights (select-screen pipeline mapped)

- Select-portrait/name pipeline fully mapped by live instrumentation
  (docs/engine_internals.md new section): per-char 32-bit root cells
  enumerated by breakpoint trace (six cells for a full pick), name-table
  row located, vs2 twins located (master 0x2A0426, roots 0x2A05E2,
  name 0x2A0A4A row 0x13), Jedah's freed select art sized (~2K bank-1
  tiles) — the port is a repoint-six-cells + region-port + art-place
  job, all slot-0x0F-only. trace_writes.lua gained breakpoint mode.
- MAME Lua gotchas recorded: single-slot register_frame_done vs
  multi-subscriber notifiers (subscriptions must be pinned).

## Session 14b highlights (M2b static phase — R2 cracked)

- MAME WITHHELD all session (user needs the machine; static analysis
  only). gfx groundwork: canonical CPS-2 tile extraction
  (tools/gfx_tiles.py — the simms are NOT tile-contiguous, see GOTCHAS),
  measured: vsav2/vhunt2 share one gfx layout; vsav2-vs-vsav = same art
  REPACKED (content-addressed match 201K tiles, same-index only 6.5K);
  vsavj is a program-only clone (gfx lives in vsav.zip).
- **R2 RESOLVED STATICALLY** (was: "the hard wall"): OBJ tile codes are
  absolute 16-bit + bank bits from object field +0x18 (Y-word bits
  13-14; per-char slot-indexed init table vsavj 0x282D4). Full decode of
  the OBJ record format + emitter chain in docs/engine_internals.md.
- **Donovan FITS in Jedah's tile band**: 15,171 tiles extent 0x3CB1 vs
  Jedah's 16,658 extent 0x417F (both measured by tools/obj_records.py,
  locked in tests/test_gfx_tiles.sh). Port = tile-data re-encode into
  Jedah's positions + 16-aligned constant delta on record tile words +
  patch his #$6000 bank setters to #$4000 (slot table gives 0x4000
  free). No ROM expansion needed for M2b.
- Exclusivity walk (player-OBJ, all slots): Jedah's band clean except
  a 44-tile Sasquatch-shared head (0xAD3E-0xAD74) — safe floor 0xAD80,
  usable extent 0x413C >= needed 0x3CB1. STILL FITS.
- Tile-data step BUILT AND VERIFIED (tools/build_gfx_donovan.py):
  Donovan's 15,171 tiles placed into patched vm3 group-B members at
  codes 0xAD8F-0xEA3F bank 2 (delta +0x2750), readback + untouched-byte
  verification green, placed range visually renders Donovan art.
  Scroll-side exclusivity: scroll1/2 cannot reach bank 2 (measured from
  the CPS2 draw path, no mapper); scroll3 can, but Jedah's band is
  99.3% saturated by his own OBJ records and renders as pure sprite art
  — residual risk queued as an in-emulator scroll3 watch.
- Playtest round 4 (maintainer, on their own quick build of 06f99f4e):
  sprites GOOD and animating correctly; palette = Jedah's (palette port
  not yet done — expected); blinking/alternating tiles esp. at char
  select. Root cause: format-0 OBJ records have 2-BYTE tile-only
  entries (my unified 4-byte walk remapped alternate tiles) — fixed
  format-aware in obj_records.py + the generator; new stage-6
  fingerprint f83ff57e… (13,177 words remapped; output re-verified;
  2 stray sub-band tiles 0x813C/0x822C belong to the effect-tail
  class). GOTCHAS entry added. PALETTE PORTED same session: per-char
  palette pointer table found (vsavj 0x38C198 / vs2 0x396B94; uploader
  0x1C3FE -> palette RAM 0x90C140), Donovan's 0x500-byte block (all
  confirm variants) placed + row 0x0F poke32'd — stage-6 fingerprint
  5cb2b2a9…, output-verified. Awaiting playtest: colors + blink both
  fixed. Then: effect-record map, portraits (art + palettes), attract
  palette path (0xB0AC/0x3A3CA0) if playtest shows wrong attract colors.
- Playtest round 5 (palettes good; residual blink left-of-P1 + one on
  Anita; specials clean) -> root-caused STATICALLY: the mixed-record
  shared-effect entries (116 tiles drawn at bank 2) were still
  unmapped. Effect map landed: gen shelf-packs their blocks into the
  freed Jedah-band tail (0xEA40+) + build_gfx places the tiles
  (effect_map.json); x2b7ef4 companion-effect records verified
  NO-ACTION (bank 1, engine page byte-identical in place, 1070/1455).
  EN ROUTE: the count+1 misread of fmt-0 records CORRUPTED build
  08a12dc6 (next-record format words clobbered) — caught by the
  output re-walk BEFORE any playtest; fmt-0 = COUNT entries (subq
  before dbra); tools/verify_gfx_build.py now gates every stage-6+
  build (record parity + code containment + table check). Current
  stage-6 fingerprint: 71601263… (parity 1122/1122, all codes in
  [0xAD8F,0xEAB1], stage 5 still a02aeeff). Playtest round 6: SPRITES
  CLEAN (palettes good, blink gone, effects clean; portraits unchanged
  as expected). MACHINE WINDOW USED: full battery green on 71601263 —
  new permanent gates tests/test_m2b_stage6.sh (guarded soaks incl 40K
  marathon + masked legacy, flicker inventory unchanged) and
  tests/test_m2b_scroll3.sh (0 danger frames; scroll3 base boot-
  constant, one write in 42K frames) + oracle/xemu/flavor PASS against
  the stage-6 rompath. M2b CORE IS VERIFIED. Remaining for the M2b
  freeze decision: portraits/name art + their palettes, attract palette
  path, engine-effect tail refinement.
- STAGE 6 (superseded 06f99f4e) — original notes: fingerprint 06f99f4e… —
  gfx_remap (13,171 tile words / 1,122 records), 6 bank setters
  #$6000->#$4000, [table_fix] (ported bank table was TRUNCATED at row 9
  and carried vs2 values — two latent stage-5 defects, now vanilla
  vsavj values), rompath carries patched vsav.zip. Stage 5 still
  reproduces a02aeeff. AWAITING MAME ALL-CLEAR for: legacy gate battery
  on stage 6, first look at Donovan rendered, scroll3 watch.
- Open for next (static): effect-record map (85 resolved/27 open),
  portrait/name inventory, Zabel slot-0x04 walker gap, then SCROLL-side (stage art vs absolute range
  0x2AD80-0x2EEBB — Jedah's stage is legacy and must stay intact),
  Zabel slot-0x04 walker gap, the 112 shared-effect tiles
  (content-map), portrait/name inventory, then the gfx builder +
  in-emulator verification (QUEUED until the maintainer frees the
  machine).

## Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)

- **The session-6 "anim state-index delta" was NOT a state-space delta.**
  It was extraction tooling corruption: the bare-long relocation heuristic
  fused instruction operand pairs (e.g. `clr.b $6(a6); moveq #0,d0` =
  `0006 7000`) into plausible pointers and rewrote them — 47 false
  rewrites latent in the two source-only zones; one destroyed the
  `moveq #0,d0` anim-state reset, sending an X-distance value into the
  engine anim setter (the vec3 at 0x015096/frame 3025). Diagnosed with a
  new guard instrument (`GUARD_PROBE`/`GUARD_PROBE_COND` conditional
  logging breakpoint — the D0 hit sequence told the whole story).
- **Extractor hardened (tools/extract_char.py + scan_code_refs.py):**
  immediate loads (`movea.l #imm`/`move.l #imm`) are now labeled refs;
  every bare-long candidate is validated against the vhunt2 SIBLING
  (context match with labeled operands wildcarded): identical sibling
  bytes → vetoed (operand pair), host-shift-consistent → confirmed,
  conflicting/absent evidence → rejected loudly. 47 vetoed/rejected,
  5 confirmed real, 0 silent keeps. Details: docs/GOTCHAS.md.
- **RESULT: the full 12_donovan_vs_cpu moveset replay (9320 frames) runs
  END-clean under the -debug crash guard.** No crash, no tripwire. The
  stage-4 bring-up ladder has no frontier.
- **Legacy gate measured honestly (this predates session 7's changes):
  the stage-4 build fails bit-exact whole-RAM comparison** — NOT from a
  behavior change: engine hooks cost cycles on the every-object dispatch
  path; interrupts then land at skewed boundaries → dead-stack ghost
  bytes ($FF7F00-$FF7FFF, below resting SP at frame-done) + the QSound
  handshake latch $FF043C phase-shifts one frame. Hooks converted to a
  ghost-clean topology (vanilla `jsr (A0)` kept in place; thunk jmps back
  to it) removing the push-value ghost; the interrupt-skew ghosts are
  physically unavoidable (zero-cycle table extension proven impossible —
  GOTCHAS). **With exactly those two windows masked, 02 is bit-identical
  to vanilla full-length and attract first diverges at exactly 4278 (the
  Jedah demo).** Live state is vanilla.
- `MASK_RANGES` opt-in on replay.lua (canonical checksums unchanged when
  unset); new gate `tests/test_m2a_stage4_code.sh` locks all of the above.
- **Session-7 extension (after the maintainer approved the masked basis):
  widening the masked legacy gate from 1 to all 7 exact replays found the
  v1 masks are not sufficient alone.** Measured:
  - 03/10/16 each show 1-2 ISOLATED single-frame divergences that fully
    re-converge (03: frames 829+2093 — 829 is the S2 input-accept
    boundary; 10: 3007+3129; 16: 829). Transition state captured one
    frame apart; bytes involved: $FF80B5, object-slot heads
    $FF8400/$FF8800. A real bug in this deterministic engine cannot
    re-converge to bit-identical whole-RAM; bounded re-converging
    flickers are a timing-phase signature. New ground-truthed comparator:
    `tools/compare_flicker.py` + `tests/test_compare_flicker.sh`.
  - 06_test_mode diverges PERSISTENTLY from exactly frame 700 — the TS
    press. Root cause is hook-caused, not ROM-content (stage-3 builds,
    ROM-modified but hook-free, ran 06 bit-identical): service-mode code
    reads the phase-shifted QSound latch and the offset propagates into
    live service state (residue: sound mirror + two checksum/accumulator
    words). Benign, no gameplay surface, but a letter violation.
  - 02/05/07 masked-exact full length; attract 4278 and pick 1080 masked
    diverge-constants hold. Whole-live-state identity therefore holds for
    all match gameplay; the exceptions are input-boundary flickers and
    service mode.
- **2026-07-27 (session 11): STAGE 5 BUILT AND FULLY GREEN — M2a is
  functionally complete pending the freeze decision.** Stage-5 build
  fingerprint **d6d8f273…** (updated after the playtest fixes —
  see the session-11 playtest entry below): the Start-hold flavor selector is LIVE
  (init shim reads the per-player Start bitmask $FF8060 at char-init;
  hold YOUR Start through match load → VH2 flavor; verified 3-way by
  the new `tests/test_m2a_flavor_selector.sh` — plain 01 / P1-held 00 /
  P2-held 01, per-player isolated); the unreachable Anita alternate-
  anim-table operand is poisoned (new imm_poison generator mechanism —
  loud vec3 at a named block if a future writer arms the branch); the
  aux_poke survey concluded none are needed for the M2a bar (select
  behavior works via bank repoints; portrait/name = M2b GFX). ALL gates
  green (initially on 4b65bc63; superseded by d6d8f273 after the
  playtest fixes below): guarded moveset, masked legacy, oracle,
  dual-emulator, flavor selector. **Freeze = pending maintainer build
  decision (see Decisions pending).**
- **2026-07-27 (session 11, first human playtest):** four findings, all
- DECIDED (round 22, maintainer): palette-uploader poke ACCEPTED —
  02/05/07 reclassified flicker@829, pick constant 829; revert path
  documented if playtest shows problems. (original entry follows:)
- **Palette-uploader poke vs exact-gate class (session 14y)**: poking
  the select/HUD palette-row uploader (CODE:0x1BF56 -> the patched
  win-palette copies) fixes the HUD mini-portrait green pixels
  (round 21), the select-portrait palettes and most likely the
  win-quote palette — all through one site. Cost: the select-entry
  bulk upload leaves a ONE-FRAME work-RAM trace at the known
  spawn-boundary flicker frame (829), so 02/05/07 would move from
  masked-EXACT to masked-FLICKER (inventory @829, the already-
  approved mechanism class; verified: exactly 1 divergent frame,
  full re-convergence, pixel gates green). Recommendation: accept
  the reclassification — it is the same mechanism class the other
  six legacy replays already carry at the same frame. Until signed
  off, the poke is reverted and the palettes stay Jedah's.

  dispositioned (docs/tables/reconciliation.md "Session 11"): garbled
  sprites = M2b expected; flavor hard to eyeball = expected (QCB+K is
  the fork); 4-option select = REFUTED as port artifact (vanilla shows
  the identical menu on factory EEPROM — snapshot-proven); **DP-spam
  crash = REAL — reproduced deterministically (19_don_dp_spam, ES DP),
  root-caused to a third extended brief-word engine table (defender
  hit-reaction dispatch, vs2 adds ids 0xA2/0xA4/0xA6, ES DP inflicts
  0xA2), FIXED via [reaction_hook]** (verbatim vs2 case stubs from
  config hex, ghost-clean thunk, original dispatch untouched for
  vanilla ids). Also closed a gate coverage gap: 04/08/09 restored to
  the masked legacy gate (measured pure flicker class; frozen logs
  added) — the gate now covers all 13 original replays. 19_don_dp_spam
  joined the code gate's guarded set. New freeze candidate d6d8f273,
  everything green.
- **2026-07-27 (session 12): the palette-seq hijack is FIXED (private
  stub entry; vanilla flows untouched — the session-9 base-swap had
  hijacked LIVE vanilla seq ids 0x2CD+); all gates green on b2e34c87.
  The sustained-mash wedge REMAINS OPEN — deterministic repro, display
  freezes while logic runs; eliminated: palette hijack (fixed, wedge
  persists), meter anomaly (+0x3B2=0 and 99-cap are normal — identical
  on native vs2 AND vanilla), the "Lilith scene" reading (it was the
  post-game-over attract flow). Mechanical bisection protocol written
  (reconciliation.md Session 12). FREEZE ON HOLD until resolved.**
- **2026-07-27 (session 11b, second playtest round): the mash/time crash
  is FIXED.** DP confirmed fixed by the maintainer; new crash on heavy
  activity reproduced with 21_don_mash (input-chaos soak) — the type-114
  effect's creation code loads an ENGINE-SHARED anim table via a raw
  un-hosted movea immediate (vs2 0x1D7428). Fixes: extractor now
  classifies un-hosted movea.l #imm ROM targets as ENGINE refs (row or
  tripwire — retires the manual imm_poison, 0x36784A auto-tripwired);
  new engine_data row 0x1D7428→0x1F3FD2 (unique content match). Round
  transition alone proven clean (20_don_round2); both soaks join the
  code gate (4 guarded replays). Full battery green on the NEW freeze
  candidate **cdf62d8c**.
- **2026-07-27 (session 10): BOTH stage-4 gates PASS on one build
  (fingerprint 67753ee3) — the first all-green run with every system
  active.** The "0x17522 trio" turned out to be the DAMAGE PIPELINE and
  is mapped, not ported: the KO-write signature located vsavj's
  byte-parallel damage wrapper (0x189BA ↔ vs2 0x17330) and every bsr
  position voted — 0x17522→0x18B8C (defense-scaling), 0x17422→0x18AB0
  (post-process), 0x17B22→0x19128 (KO). Donovan uses vsavj's own damage
  machinery (correct superset semantics). Moveset replay END-clean 9320
  frames; code gate green (incl. masked legacy, flickers unchanged);
  oracle gate green. **And the dual-emulator gate PASSED
  (test_m2a_stage4_xemu.sh: patched build on MAME + patched FBNeo,
  anchors 2363/2364 — 1-frame skew — all mapped fields agree at follow
  0/60/180). ALL THREE STAGE-4 GATES GREEN on fingerprint 67753ee3:
  STAGE 4 IS CLOSED.** Next: stage 5 (select plumbing + Start-hold
  flavor selector), soak, freeze.
- **2026-07-27 (session 9): the +0x14E frontier is CLOSED and the
  ORACLE GATE PASSES as a scripted test.** The state hook landed
  (synthesized case stubs + ghost-clean thunks + relocated palette-seq
  records + 4 consumer base-swaps — patch_notes session 9); Donovan's 8
  sound-farm calls stubbed silent (M5 restores; sfx ids recorded in
  reconciliation.toml); anim_index_a2 resolved from gap auto-kind (was
  feeding Jedah's anim rows to Donovan's attacks). Moveset replay
  END-clean again. `tests/test_m2a_stage4_oracle.sh` PASS: anchors equal
  (2363), neutral window exact, P2 HP trajectories equal (hits land,
  same damage), and the comparative bound — ported Donovan diverges
  LESS across the two engines (890 mismatches) than vanilla Demitri
  does (2379): the residual ~1-frame action-latency skew is the
  ENGINES' cross-game difference, proven by the 18_veteran_ctl control
  pair. Remaining stage-4 behavior work: dual-emulator gate (16-pattern
  Donovan replay on MAME + FBNeo), then stage 5.
- **2026-07-27 (session 8): the vsav2-as-oracle behavior gate is BUILT
  and immediately caught two real bugs.** Replay pair 17_don_oracle_*
  (both games anchor at frame 2363 — sibling engines run identical menu
  timelines). Bug 1 FIXED+verified: "gap_bd7fa" was really dispatch_14
  (per-char code dispatch); row 0x0F still ran JEDAH's state routine
  against Donovan's data (the session-4 "ignores inputs" family) —
  reclassified, extractor de-hardcoded (walks all dispatch_NN), rows
  repointed; neutral-idle field compare now agrees on all fields for
  1100 frames. Bug 2 OPEN (the current frontier): the +0x14E engine
  state dispatch (vsavj table 0x2A7E2, 89 entries) is EXTENDED in vs2
  (101 entries — 12 newcomer states); Donovan's VS2-flavor QCB+K writes
  state 0xB6 → indexes past the vanilla table → ILLEGAL → soft reset.
  Fix design + details: docs/tables/reconciliation.md "Session 8".
  HP-decrease sanity holds natively (Victor −11 ×2). NOTE: with
  dispatch_14 active the 12_donovan moveset replay also reaches the
  +0x14E states and crashes at 3815 — stage-4 gate lock 2 is KNOWN-RED
  until the hook lands (legacy gate green; one fix closes both).
- **2026-07-27: v2 approved (see Decisions made) and the Start-hold
  flavor mystery RESOLVED** — community protocol confirmed (Donovan +
  Huitzil only), mechanism pinned end-to-end with the new instruments
  (masked comparison found the behavioral fork at the exact QCB+LK
  frame; read-watch named both consumers, both inside ported regions).
  One consequence gates the upcoming vsav2-as-oracle behavior gate: the
  ported build's latch byte defaults to the WRONG flavor (VH2) — the
  oracle's native side defaults VS2, so QCB+K would diverge at the field
  compare until the default-flavor decision lands (Decisions pending).
  Note: 12_donovan_vs_cpu's battery includes QCB+K — the ported
  VH2-branch code path already runs crash-free under guard.

## Sessions 5-6 highlights (M2a stage 4 — the port runs)

- **Companion (Anita) chain decoded end-to-end**: pool geometries are
  identical per-index in both games; allocator family mapped (never
  ported — it reads the game's own RAM bookkeeping); creation handler's
  anim-table pointer was the last unrelocated piece; class-7 (vs2-only
  update queue) remapped to vsavj's equivalent class.
- **New extraction capabilities** (all in `tools/extract_char.py`):
  data-kind extra roots with forced twins; *segmented* gap-tolerant
  oracle diff (resyncs after cross-game insertions — Anita's 44.2K asset
  region: 2065 pointer fields over 75 segments); self-pointer
  classification for micro-shifted multi-blob regions; chunk-BFS graph
  sizing before committing space; PC-relative word-table discovery with
  full-extent protection.
- **New generator capabilities** (`tools/gen_donovan_patch.py`): layout
  groups (PC-referencing families keep source-relative spacing, gaps
  recycled), near_map satellite placement within d16, pcrel entry
  rewrites with shared per-region tripwires, slot-clearing allocator
  wrappers, port_patch byte edits, stage-1 scaffolding gated to stages
  1-3.
- **SPACE BUDGET CLOSED**: ~335K placed of 336.6K free (hole A ~1.4K
  spare, hole B ~12.9K). Achieved by honest region bounding, porting only
  Donovan's own sub-object handler types (others tripwired), and tighter
  margins.
- **Result**: char-init completes, match runs (timer, CPU opponent, HP
  structs). Crash frontier moved 2886 → 3025.
- **Frontier**: vec3 at engine 0x015096 — the anim word table is
  byte-identical to native vsav2 (data+relocation correct) but the INDEX
  into it is wrong; a state/substate byte carries a vs2-flavored value.
  Full detail + next probe: docs/tables/reconciliation.md "Session 6",
  docs/NEXT_SESSION.md.
- **GOTCHAS paid**: PC-relative reads are decrypted reads on CPS-2;
  PC-relative word tables are DATA (a fused pair of word entries was
  silently corrupting a dispatch table).

## Session 4 highlights (M2a — the real Donovan port)

- **M2a plan approved** (staged: C0 harness → C1 extraction → C2 generator →
  bring-up ladder stages 1-5 → close-out). Stage design: null-relocation of
  Jedah's own data first (tooling proof, zero R1 ambiguity), then Donovan
  data → anim → code dispatch (R1 surface) → select plumbing.
- **C0 COMPLETE (harness primitives, all verdict logic ground-truth tested):**
  - Crash guard: breakpoints on 68k exception handlers, fault PC/ADDR from
    the exception frame, stack sketch, RAM dump (`replay_guard.lua`,
    `run_replay_guarded.sh`, `test_crash_guard.sh` — vec3/vec4 positive
    controls trip correctly).
  - Dual-emulator field comparator per amended §4: debounced match-start
    anchors, stable/settled/phase field classes (`compare_fields.py`,
    `fields_m2a.tsv`, selfcheck green: MAME/FBNeo agree on 16_xemu_2p with
    1-frame skew).
  - Auto-detecting suite runner: program-image fingerprint →
    `tests/expected/<expset>/` dispatch; `.diverge` expectation kind
    (exact-frame divergence vs frozen full logs). Suite green, 12 replays
    (added 11_pick_donovan, 16_xemu_2p).
  - FBNeo verified to load CRC-changed patched zips (no descriptor change
    needed); `run_replay_fbneo.sh` gained `FBNEO_DUMPS`/`FBNEO_ROMPATH`.
- **Cross-emulator findings (GOTCHAS paid):** MAME `-debug` perturbs
  multi-CPU timing (checksum gates must run non-debug); vs-CPU replays have
  emulator-divergent content (different CPU-picked opponents); menu presses
  near transitions land on opposite sides of input-accept boundaries;
  match-start predicate flickers during intros (debounced).
- **C1/C2 COMPLETE:** oracle-validated extraction (`extract_char.py` —
  every cross-sibling diff byte must classify as a pointer field under a
  measured shift; auto-discovers new region shifts, e.g. the sprite/OBJ
  sub-tables at −0x2002C), staged patch generator, `find_equiv.py`
  (validated at score 1.00 on the known loader), `build_donovan.sh` driver.
  Donovan footprint closed at ~235KB, 9+ regions.
- **STAGES 1-3 PASS** (gates in tests/): null relocation (Jedah copy,
  10018 B — matches M1 exactly), Donovan passive data (full round under
  guard), anim + sprite sub-tables (idle-coherent; select-screen hover
  reads anim → pick divergence pin moves 2886→1080 at stage 3+).
- **STAGE 4 (in progress, deep):** R1 mechanized (`reconcile_batch.py`:
  pattern ladder, stub-deref, callsite anchoring via veteran parallelism,
  codebytes, farm-param matching; ~120 verified rows) + per-target
  TRIPWIRES for opens (fault PC names the target). Ported regions: +0x34
  newcomer-support zone, 17 extra secondary-object handlers, engine
  char-init pair, VS2-only 0x8xxxx companion zone (source-only). TWO
  engine hooks live (extended type-dispatch tables 59→76 and 114→124,
  jsr-thunk pattern; vanilla rows byte-identical). **Donovan RUNS on the
  vsavj engine** (match, timer, CPU opponent, HP structs, guard clean,
  screenshot in scratch). [Superseded by sessions 5-6 above: the companion
  chain is decoded and the port fits; see that section for the current
  frontier.]
- Suite GREEN, 13 replays (added 11_pick_donovan, 12_donovan_vs_cpu
  moveset-exercise, 16_xemu_2p; vanilla expectations + full logs frozen).
- **Next actions (stage 4 close):**
  1. Decode the pool-index correspondence + spawn-node field protocol
     (vsav2 node writer = the 0x8A5A8 hook; vsavj consumer =
     `PRG:0x0155D0-0x015650` jump-table on `(0x9,A6)`; watch $FF79BE+
     pool heads). Consider REWRITING the hook to vsavj's protocol
     (synthesized, GEN provenance) instead of porting VS2's.
  2. Then: stage-4 gates (vsav2-as-oracle field compare at anchors —
     native Donovan pick on vsav2 = cursor R×2 from default; dual-emulator
     on 16-pattern replay; legacy gate every build).
  3. Then stage 5 (select plumbing aux pokes) + soak + freeze.

## Session 3 highlights

- CLAUDE.md §4 dual-emulator amendment applied (maintainer-approved).
- **Donovan/Huitzil/Pyron located and pinned** (char IDs 0x13/0x10/0x11,
  hitbox bases + handler code addresses in both vsav2 and vhunt2).
- Per-character table bank semantically labeled (14 dispatch tables +
  hitbox pairs + parameter tables); bank layout identical across all three
  sets (same internal deltas from a per-set origin).
- RAM atlas: round timer $FF8109, HP +0x50/+0x52 (max 0x120), X/Y
  +0x10/+0x14 added.
- Remaining for M1 acceptance: per-character manifests' remaining columns
  (anim scripts, tile ranges, palettes, sound cues); meter/rounds-won RAM
  offsets; formal Aulbath slot-9 pick; vhunt2-side pick verification of
  D/H/P; Start-hold flavor mechanism (VS2-vs-VH2 behavioral deltas are NOT
  in hitbox data — identical across both games).

## Current milestone

**M2 — Proof of life. IN PROGRESS.** Replaced slot = Jedah (0x0F).
- Program-patch tooling (`tools/patch_prg.py`) DONE and MAME-verified: data
  raw, code re-encrypted, null bit-identical (`tests/test_patch_prg.sh`).
- **Mechanism PROVEN end-to-end on trusted tooling** (`tests/test_m2_repoint.sh`):
  repointing vsavj Jedah's hitbox-base bank entry to Demitri's takes effect
  in a live match (RAM:$FF8460 loads the new base), AND the superset
  invariant holds exactly — 6/6 non-Jedah legacy replays bit-identical;
  attract bit-identical through frame 4277, diverges at 4278 precisely where
  its CPU demo shows Jedah (char id 0x0F, verified). Attract legitimately
  involving the modified slot is correct superset behavior, not a violation.
- Feasibility assessed (docs/M2_feasibility.md): behavior data portable via
  ~337KB free vsavj space + data-reads-bypass-encryption; sprite tiles are
  the R2 wall (may pull M3 forward); QSound = M5.
- **M2a IN PROGRESS (sessions 4-7, see highlights above):** extraction,
  generation and relocation tooling complete; stages 1-3 PASS; stage 4
  bring-up DONE — the full moveset replay runs END-clean under guard
  (session 7; the session-6 "state-index delta" was extraction
  corruption, fixed). Legacy-gate basis decided (live-RAM masked windows,
  see Decisions made) and the masked legacy gate is green over all 9
  legacy replays. Remaining for stage-4 close: the behavior gates
  (vsav2-as-oracle field compare at anchors, native pick = cursor R×2;
  dual-emulator on the 16-pattern replay). Then stage 5 (select
  plumbing) and M2b graphics.

### M1 — Map. ACCEPTED (2026-07-25).
Both SPEC §4 clauses met; full assessment in docs/M1_acceptance.md.
Deferred sprite-bound exact addresses (tile/palette/sound) are
proven-reachable and scoped to M3/M4/M5.

### M1 detail (all complete)
- Replay harness: DONE both emulators. Shared `.rpl` input-script format;
  MAME runner (`tests/lua/replay.lua` — inputs, checksums, snapshots, RAM
  dumps) and patched-FBNeo runner (`emu/fbneo-patches/0001-…-harness.patch`,
  `tools/run_replay_fbneo.sh`). Both proven deterministic run-to-run.
- 10-replay legacy suite: DONE, green, expectations frozen
  (`tests/run_suite.sh`, `tests/expected/vsavj/`). Semantics spot-verified by
  snapshot (2P pick, challenger interrupt, mid-attract start all confirmed).
- **Cross-emulator finding (important):** MAME and FBNeo agree bit-exactly
  for the first 71 boot frames, then run the same states on *different frame
  indices* (transitions land ±frames apart; static screens re-sync; ~37
  work-RAM bytes differ at title — phase-shifted counters + sound-driver
  area $FF05xx). **Frame-exact whole-RAM dual-emulator comparison does not
  hold.** Superset-invariant enforcement is unaffected (oracle = same
  emulator, vanilla vs patched). Recommendation for CLAUDE.md §4 amendment
  (human sign-off requested, non-blocking): new-content dual-emulator
  verification = mapped gameplay fields (player structs, HP, positions,
  timer) compared at sync anchors (match start), not whole-RAM checksums.
- RAM map: community anchor imported and verified (player structs
  $FF8400/$FF8500, hitbox ptr offsets, match-active flags), extended by
  differential experiments + write-traces. See docs/atlas/ram.md.
- **Character-data plumbing CRACKED (the big one):** write-trace on
  $FF8480 → per-character loader (vsavj PRG:0x028DD8) → three 32-entry
  tables indexed by 5-bit char id → located in ALL THREE sets by
  instruction-pattern search → a whole bank of ~20 per-character tables
  (vsavj PRG:0x0BD0FA-0x0BE8xx). Slot→name map ~10/16 done empirically
  (pick + snapshot + pointer readback). Variant slots: vsavj {8}=Oboro
  Bishamon; vsav2/vhunt2 {0,1,3,8,9} with per-slot hitbox data
  byte-identical between vsav2 and vhunt2 (both games carry both flavors).
  **vsavj slot→character map COMPLETE** (16/16, one by elimination).
  **DONOVAN/HUITZIL/PYRON LOCATED** (pick-verified on vsav2): char IDs
  0x13/0x10/0x11 — the variant half of slots 3/0/1 — with hitbox bases in
  both vsav2 and vhunt2 recorded. Base-half slot assignments are identical
  across the whole series. Full detail: docs/atlas/character_tables.md.
- Three-way diff: window/masked diff built (`tools/diff_sets.py`);
  **finding:** vsavj↔vsav2 share <10% at window level even pointer-masked —
  engines were rebuilt (shifted code, changed PC-relative displacements) and
  most of the 4MB is game-specific data. The atlas grows from anchored
  RE (traces + tables) — which the character-table crack has now proven out.

### M0 — Bench. COMPLETE (2026-07-25). Acceptance status:
- Null-patch output bit-identical to reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay deterministic across two runs: **PASS** (`tests/test_attract_determinism.sh`, MAME)
- Headless MAME runner: **DONE** (`tools/run_mame.sh`, MAME 0.288 via Homebrew)
- Headless FBNeo runner: **DONE** (`emu/fbneo` submodule, SDL2 build,
  `tools/run_fbneo.sh` with dummy SDL drivers + sandboxed HOME;
  `tests/test_fbneo_smoke.sh` PASS). The SDL2 frontend has no scripting, so
  the per-frame RAM-checksum probe on the FBNeo side is a frontend patch —
  first M1 task (see below)

Bonus beyond plan: CPS-2 decryption/encryption pipeline
(`tools/cps2_decrypt.py`) proven bit-identical to MAME's implementation via
opcode-space dump oracle (`tests/test_decrypt_oracle.sh`). Both directions
(decrypt for analysis, encrypt for future patch injection) self-check.

## Next actions

1. **M2b — Donovan graphics** (docs/M2_feasibility.md: the R2 tile
   wall). First step: measure — tile inventory for slot 0x0F (portrait,
   name, sprite banks), what the garbled-but-recognizable rendering
   implies about tile-index vs tile-data remapping, whether M3 (gfx
   ROM extension via descriptor lines) must be pulled forward.
2. Suite/watch duties continue: flicker inventory is frozen — any growth
   or systematic divergence is stop-and-root-cause (CLAUDE.md §4
   standing watch).
3. Parked (register per milestone): M5 sound restoration (25 stubbed
   rows + dispatcher table), Huitzil/Pyron tripwired handlers (M3),
   bank-tail parked tables, 0x2c31xx data opens.

## Open items

- None blocking. Reference collection is COMPLETE: vsav, vsavj, vsav2,
  vhunt2, vhunt2r1, qsound_hle — all MAME `-verifyroms` green, all 76
  members frozen in `docs/checksums.txt` (vsav2 supplied by maintainer
  mid-session 2026-07-25 and folded in; re-freeze recorded here).
- ROM packaging fixes from the 2026-07-25 audit are confirmed applied:
  `vhunt2.key` present in both vhunt2 zips (CRC 61306b20), `qsound_hle.zip`
  present (`dl-1425.bin` CRC d6cf5ef5).

## Decisions made

- **M2b-CORE FROZEN at fingerprint
  `71601263474dfd7e4afd0741dae696cde22eda4e`** — 2026-07-28, maintainer
  ("freeze core deliverables"). Scope: Donovan's sprites, palettes, and
  effects living in Jedah's gfx space — playtest-clean (rounds 4-6) and
  fully gate-verified (M2b gate incl. 40K marathon + masked legacy with
  unchanged flicker inventory; oracle; dual-emulator; flavor; scroll3
  exclusivity live-measured). Registry row `71601263 -> donovan-m2b`
  (gfx member sha1s in the registry note — the program fingerprint does
  not cover them). Deliberately OUT of the core freeze: select-screen
  big portrait/name banner/mugshot (still Jedah's; pipeline mapped,
  in-place pointer surgery pending), attract palette path,
  engine-effect tail. Those continue as follow-up work.
- **M2a FROZEN at fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa`**
  — 2026-07-28, playtest-gated as decided: maintainer's round-3 playtest
  came back fully clean ("no more graphical bug/crash, even over
  multiple matches"; "no more music trigger from inputs"). The M2a bar
  (Donovan selectable, crash-free, behavior observable, R1 logged) is
  met; graphics deliberately garbled (M2b), Donovan's own sfx
  deliberately silent (M5, 25 stubbed rows + the 0x271B6 dispatcher id
  table recorded in reconciliation.toml). Registry row + suite
  expectation kinds landed the same day (session 14 highlights).
- **Legacy-gate basis for hooked builds = live-RAM (masked windows)** —
  2026-07-25, maintainer approved ("the invariant interpretation reads
  sound and reliable which is paramount"). For builds carrying engine
  hooks, legacy comparison masks exactly `RAM:$FF043C` (QSound handshake
  phase latch) and `RAM:$FF7F00-$FF7FFF` (dead stack below resting SP);
  every other byte compared every frame (confinement by construction).
  CLAUDE.md §4 amended; windows documented in docs/atlas/ram.md; masked
  vanilla expectations frozen under tests/expected/vsavj/masked/ (this
  session). Suite-runner masked-expectation-kind support lands with the
  stage-5 freeze. New masked windows require the same route: measured
  mechanism + atlas entry + maintainer sign-off.
- **Ported-Donovan default flavor = VS2** — 2026-07-27, maintainer
  ("Default should be VS2, as you proposed"). Implemented as a tunable
  in `build/manifest/donovan.toml` (`[init_shim] flavor_disp=0x3C2,
  flavor_default=0x01`, rule-5 style): the init shim writes the flavor
  latch into the initing player's struct (A6+0x3C2) — vsavj never writes
  it; the ported QCB+K handler + projectile consume it. Verified live:
  P1 $FF87C2=01 in-match on the flavor-defaulted build. Start-hold
  selector wiring (clear-to-00 on held Start) = stage-5 select-plumbing
  scope, §3.3/§3.4 variant policy (Donovan + Huitzil only).
- **Legacy-gate v2 refinement APPROVED** — 2026-07-27, maintainer
  ("I'd rather we iterate with as tight setups as we can build rather
  than try to be perfect and not go forward"). Per-replay classes on the
  masked basis: exact (02/05/07), flicker-tolerated 03/10/16
  (`tools/compare_flicker.py`, stretch ≤2 / re-converge ≥60 / total ≤8),
  frozen diverge constants 06@700, attract@4278, pick@1080. CLAUDE.md §4
  updated to v2. **Standing watch (maintainer caveat): if flickers grow
  beyond the frozen inventory (5 frames across 3 replays: 03@829+2093,
  10@3007+3129, 16@829) or divergences turn systematic, stop and
  root-cause — that would indicate a deeper issue.** The tolerance caps
  themselves fail loudly on growth; treat any new flicker frame as a
  finding to attribute, not noise to absorb.
- **M2 replaced slot = Jedah (slot 0x0F)** — 2026-07-25, maintainer
  approved. Donovan replaces Jedah in vsavj for the proof-of-life
  milestone. Rationale: footprint fit (Jedah 10018 B ≥ Donovan 9358 B),
  boss character (least playtest disruption), keeps Demitri/Victor so the
  M1 replay suite stays valid.
- **CLAUDE.md §4 dual-emulator amendment** — 2026-07-25, maintainer:
  new-content cross-emulator verification is field-level at sync anchors
  (mapped gameplay state), not whole-RAM frame-exact; within-emulator
  oracles stay whole-RAM frame-exact. Text updated in CLAUDE.md §4.
- **Project name = "Vampire Saved"** — 2026-07-25, maintainer.
- **Base revision = `vsavj` (Japan 970519)** — 2026-07-24, maintainer. Closed.
- **Checksum manifest is per-member**, so zip repackaging never matters —
  2026-07-25, session decision (mechanical, no gameplay impact).
- **Raw-image byte-order convention** — 2026-07-25, session decision: ROM
  files are LE-word storage; all derived images are 68k logical (BE) order.
  See docs/GOTCHAS.md first entry.

## OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES

Playtest of `build/m5w` (the M5-sound WIDE build `ac52eeff`, built Aug 4 —
NOT anything from session 14z-60): mechanically sound, no gameplay issue,
but **Donovan's and Anita's sprites are garbled from character select
through the match** — wrong art, while shapes, specials and hit/hurtboxes
all align. Minor palette issues on some win screens, tracked separately.
`run_wide.sh` only launches, so nothing was rebuilt for the test.

**The load hypothesis is DEAD, measured.** `FBNEO_HGFX` dumped the decoded
tile buffer at Donovan's band (tile `0xAD8F` -> byte `0x56C780`) from the
WIDE build and from the known-good stock build `donovan6`:

    WIDE  sha1 f3cb6aa95b294b9506206d93e335f8a09f43347e, 0 bytes of 0xFF
    STOCK sha1 f3cb6aa95b294b9506206d93e335f8a09f43347e, 0 bytes of 0xFF

Byte-identical, no 0xFF fill — so the FBNeo CRC trap did NOT fire and the
tiles load correctly on both tracks. ROM and loader are fine.

**Therefore the fault is in tile ADDRESSING at draw time**, which is exactly
what the WIDE profile changes: its single removed line in `cps_obj.cpp` is
the sprite tile-code composition for 19-bit addressing. That matches the
symptom (record geometry right, only the fetch displaced) and matches its
being identical on FBNeo and MAME, which carry the same profile patch.

**Named suspect, not yet confirmed:** `docs/GOTCHAS.md` records the free
tile-address bit as **y-word bit 12**, on the CPS-2 Turbo precedent. Bit 12
is also a legitimate Y-COORDINATE bit. A sprite drawn at a Y with that bit
set would have its tile address shifted by a 64K page under WIDE — wrong
art, right shape. It would also explain why the B4 canary passed: that
proved LEGACY replays pixel-identical, and legacy content may never place a
sprite at such a Y.

Next measurement: dump OBJ RAM for a Donovan sprite on the WIDE build,
check his entries' y-words for bit 12, then A/B the same frame's
framebuffer against stock. If confirmed this is a defect in OUR emulator
profile (Rule 1 territory), not in the port — and it would block the WIDE
track until fixed.

## Decisions made (maintainer, 2026-08-05): two ratifications

**1. CLAUDE.md §4 comparison class v3 — "bounded re-convergent window".**
Ratified for the select screen, which the roster deliberately alters. A
replay qualifies only when all four hold, frozen per replay: a single
CONTIGUOUS run, a fixed ONSET frame, full RE-CONVERGENCE, and match state
UNTOUCHED. Measured over five replays before the ruling (onset 890 in every
one, one run each, 2469-10498 identical frames afterwards including a full
timeout match). It is STRICTER than the frozen first-divergence constant it
sits beside, which never re-converges at all — a narrower licence for one
screen, not a loosening. §4 amended; checker `tools/compare_window.py`,
ground-truthed both directions by `tests/test_compare_window.sh` including
that a bit-identical pair is NOT a silent pass (the expectation asserts the
divergence exists).

**2. The `[[tenant]]` schema.** Ratified, and already implemented for a
single tenant (14z-60t/u) byte-identically on both tracks with the tenant
still at `0x0F`. `docs/tenant_manifest.md` moves PROPOSAL -> RATIFIED; its
wheel/ladder/folds sub-tables stay proposal-only because that work is not
done.

Maintainer: "I validate the two items, I don't need testing to see that they
hold on principle." The measurements above were taken before the ruling
regardless — the class's four clauses are what was measured, not what was
hoped for.

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

"vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decision made (maintainer, 2026-08-05): new cells SNAP to vsav's lattice

"It feels safer to conform to arcade vsav and snap to it. As long as the UX
is good enough, I don't even mind if the look is not great." So the three
appended cells take positions derived from vsav's own hexagon rather than
PS1's pixel coordinates.

Derived layout (`build/manifest/wheel_layout_proposed.json`): vsav's wheel
is a clean hexagon, rows 1-2-3-4-3-2-1 at y=64..144 every 16, then a single
centre-line cell at y=152 (+8). Mirroring that bottom signature downward:

| cell | id | position |
|---|---|---|
| random (unchanged) | `0x0B` | (248, 152) |
| Huitzil/Phobos | `0x10` | (224, 168) |
| Donovan | `0x13` | (272, 168) |
| Pyron | `0x11` | (248, 176) |

This is geometrically IDENTICAL to the PS1 port's shape (pair, then single
on the centre line); only the id assignment differs, per the maintainer's
amendment — random keeps its vsav cell and Pyron goes to the very bottom.
28 bytes of TABLE B change. Adjacency is still a geometric DRAFT pending
the cursor-movement video.

## Decision made (maintainer, 2026-08-05): 0x360+id anim block = INHERIT

Option A: the newcomers inherit their base character's animation from the
shared 16-wide block `0x360-0x36F` (a tenant at `0x13` plays `0x363`),
exactly as vsav2 ships — Capcom left both those folds in place. Sites
`PRG:0x003E40` / `PRG:0x004082` therefore stay folded, recorded as
`inherit` in `docs/tenant_manifest.md`. **Fallback, if a playtest shows the
inherited animation is wrong for a newcomer: option B**, relocate the block
to a free 32-wide anim-number range and widen both masks.

## Decision made (maintainer, 2026-08-04): M5 voice samples = A then B

"A then B, gates stay strict, option C is rejected." Ship the unfaithful
voice lines silent now; revisit growing the QSound region at M3 within the
measured 16 MB `device_rom_interface<24>` ceiling; never overwrite vsav
content for sample room. Recorded in full under "Decisions pending" above,
where the option analysis lives.

## Decision made (maintainer, 2026-07-31): electrocute arc colors

Keep vsavj-native shock styling for all victims including Donovan
(option A of the 14z-20 write-up): the arcs/glow are engine-global and
victim-independent; vs2's yellow was a game-wide re-theme, not per-char
data. "Less work, less risk, and we can always come back to it after
all the more important work." LOCKED in tests/test_don_accent.sh
section 3 (shock-window vanilla lock, frozen from a vanilla run) —
revisiting requires changing that gate deliberately.

## Decision made (maintainer, 2026-08-02, round 65): M2b+ASSETS freeze

Freeze `b91647c7` as `donovan-m2c` before starting M5 sounds —
"mechanically sound as far as we can tell" (rounds 52-64 playtest
arc + full battery + suite). Frozen basis: three masked windows.

## Decision made (maintainer, 2026-08-02, round 64): third mask window

`RAM:$FF4182-$FF41A1` (palette-fade staging slot for select block-A
row 14) RATIFIED into the masked legacy basis — option A of the
14z-49b write-up, after the recolor-necessity A/B (14z-49d) showed
options B and C strictly worse. Condition attached and honored:
detailed documentation + a standing confirmation path
(`tests/audit_mask_window_ff4182.sh`; spec in docs/atlas/ram.md).
Extension policy stands: future palette-block ports extend the
window per measured slot, never pre-widen.

## Decision made (maintainer, 2026-08-06): select art = option A

Option A of the 14z-62e write-up: the per-hover bank thunk for the
portrait-record object + the tenant's select art in WIDE group C at
native codes; `vsav.zip` leaves the rompath entirely pristine. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

## Decisions pending (human)

- ~~**HOW THE TENANT'S SELECT ART LEAVES JEDAH'S ANCHORS (14z-62e)**~~
  **DECIDED 2026-08-06 (maintainer): option A.** Analysis kept below.

- **THE 14z-62e SELECT-ART ANALYSIS (decided above).** The
  last visual-de-substitution piece: the tenant's select-art subset (101
  bank-1 tiles + 4 placeholder label tiles + the 6-tile medallion) still
  overwrites Jedah's bank-1 select-figure art, garbling his select-screen
  BODY (face/name/match art are all back). Two measured options:

  **A — a per-hover bank thunk + group C (recommended).** The select
  FIGURE object's bank already follows the hovered char through the
  engine table (measured: `PRG:0x05F9EC` jsr's the bank helper; hovering
  the tenant writes 0x1000 and his standing figure draws from group C
  TODAY). The PORTRAIT-record object instead gets bank 1 ONCE at venue
  init (`PRG:0x07C428`). Option A thunks the per-hover record-pointer
  consumers (`PRG:0x05F328`/`0x06C0E0`) to also set that object's bank:
  hovered==tenant -> 0x1000, else -> 0x2000 (the value it already holds,
  so pure-legacy RAM is byte-identical; after a tenant visit the restore
  re-converges). Select art then lives in group C at native codes — NO
  fit problem — and `vsav.zip` leaves the rompath ENTIRELY PRISTINE.
  Cost: a new engine hook on the select path (cycle-only for legacy; the
  ratified hook class, but the re-freeze's flicker/window inventory must
  be re-measured with it in — the standing watch applies). The name/
  highlight-piece objects' banks need the same treatment (their sites
  are one measurement away, same method).

  **B — relocate into blank bank-1 space, no hooks.** Vanilla bank 1 has
  2,917 blank tiles (largest runs: 881 at 0xBE90-0xC200, 460 at 0x3634,
  357 at 0x6C9C — measured). Placing the ~117 tiles there needs a NEW
  greedy fit (block-geometry aware), a reference-exclusivity proof for
  the chosen ranges (blank != unreferenced: a legacy record could use
  blank tiles as transparent filler, and art there would APPEAR — the
  proof method is the medallion's whole-image scan), and `vsav.zip`
  stays patched-but-additive (nothing of Jedah's overwritten). Zero
  engine hooks, zero legacy cycle cost.

  **Recommendation: A.** It finishes the artifact story (pristine
  vsav.zip — the strongest possible provenance), reuses the established
  thunk pattern and the already-poked bank table, and avoids a new fit +
  exclusivity-proof toolchain for a one-off. The hook's legacy cost is
  cycles only, in the class the basis already tolerates; it will be
  measured before the re-freeze ratifies anything. B stays the fallback
  if the measured hook cost violates the standing watch.


- ~~**RATIFY A COMPOSITE §4 CLASS? (14z-61)**~~ **RATIFIED 2026-08-06
  (maintainer: "Your proposal is ratified").** CLAUDE.md §4 amended: the
  `composite` class is the strict CONJUNCTION of flicker-tolerated and
  bounded re-convergent window, adding no tolerance to either. The seven
  `.pending` expectations became `.masked` `composite` specs carrying the
  shapes they had already printed, and the WIDE reference freeze is
  complete — `run_suite.sh` on `donovan-m5w` is GREEN, all 63 replays
  validated or explicitly skipped. Original entry below.

- **RATIFY A COMPOSITE §4 CLASS? (14z-61) — the analysis behind the
  decision above.** Seven legacy replays measure as the frozen
  hook-flicker inventory PLUS one bounded re-convergent window per
  select-screen ENTRY (table in 14z-61). Both halves are already ratified —
  `flicker` (§4 v2) and `window` (§4 v3) — but no single class expresses
  their conjunction, so those replays cannot be frozen without either a new
  class or a fudge. They are `.pending` and fail the suite meanwhile.

  **Proposal: `composite <baseset> <flicker-csv> <window-list>`**, defined
  as the strict CONJUNCTION of the two: every divergent run must be
  accounted for by name, the flicker set must match the frozen inventory
  exactly, the window list must match exactly, and the run must fully
  re-converge. It tolerates nothing that `flicker` and `window` do not each
  tolerate, and it is strictly stronger than either alone.

  Implemented and ground-truthed ahead of the decision so ratification is
  one word rather than a session: `tools/compare_composite.py`,
  `tests/test_compare_composite.sh` (7 synthetic cases + a no-loophole
  check — extra flicker frame FAILS, missing flicker frame FAILS, onset
  moved one frame FAILS, no re-convergence FAILS, bit-identical FAILS, an
  unfrozen second window FAILS). **Nothing validates against it until you
  say so**: accepting means turning each `.pending` file into a `.masked`
  one carrying the spec it already prints.

  **Recommendation: ratify.** The alternative readings are worse — calling
  these replays `skip` hides a real comparison, and widening `flicker` to
  swallow a 900-frame run would be the loosening §4's standing watch exists
  to prevent.

- ~~**FREEZE THE WIDE TRACK? (14z-61).**~~ **DONE 2026-08-05 (maintainer:
  "yes freeze and register as wide reference first, then we resume").**
  `9bac6ee3 -> donovan-m5w`; see 14z-61. Original entry below.

- **FREEZE THE WIDE TRACK? (14z-61) — the analysis behind the decision.** `build/m5_wide` (`9bac6ee3`) is now
  playtest-confirmed with and without Donovan, both WIDE profile gates are
  green, and the new rendering + member-identity gates are green. The
  registry convention is that rows are added at FREEZE time as a STATE.md
  decision, so this is not mine to do.
  **Recommendation: freeze and register it** as the WIDE reference
  (`donovan-m5w` alongside `donovan-m2c`), for one specific reason beyond
  bookkeeping: M3a moves the tenant from `0x0F` to `0x13` and will churn
  the select records, the thunk id and the bank-table row at once. Without
  a registered WIDE reference, a regression during that work has nothing to
  bisect against on this track — which is exactly the position that made
  the sprite garble expensive.
  Cost if we skip it: none today; the risk is only felt later, and by then
  the build may not be reproducible from the tree.

- **THE SELECT SCREEN AND THE SUPERSET INVARIANT (14z-60r).** Drawing three
  new medallions requires the wheel OBJ record to grow from 18 to 21
  entries and its coordinate list likewise. Measured: neither can grow in
  place (another record starts immediately at `0x272ABA`; the coord list is
  immediately followed by the shared global pool), so both must relocate —
  cheap, one referrer at `PRG:0x2689FE`. **The problem is not placement, it
  is the invariant.**

  The record's `count` word changes and its `budget` word is debited from
  the OBJ emitter's shared per-frame budget — GOTCHAS records that exact
  coupling flipping a borderline skip decision into a one-byte work-RAM
  divergence. Three more sprites also render. **So any legacy replay that
  reaches the select screen will diverge in RAM.** M2b's select work avoided
  this by strict in-place replacement preserving the host's budget word;
  adding CELLS makes that impossible by construction.

  CLAUDE.md §1 covers "any match, **menu path**, or attract sequence", so
  this needs an explicit ruling rather than an assumption:

  **A — a bounded select-screen carve-out (recommended).** Legacy replays
  are compared as today up to select entry, and the select-screen
  divergence is MEASURED, mechanism-attributed and frozen per replay, in
  the same style as the existing `diverge` constants and masked windows.
  Rationale: the invariant's purpose is that vanilla *gameplay* is
  untouched, and a select screen that offers three more characters is by
  definition content that involves them. Condition: the divergence is
  measured and frozen BEFORE acceptance, never accepted blind, and must not
  extend past the select screen into match state.

  **B — keep the wheel vanilla**, reach the newcomers by another mechanism
  (the option-2 hold-Start alternates the maintainer already ranked lower).
  Preserves the invariant literally; costs the decided roster UX.

  **C — attempt a RAM-neutral extension.** Not viable: the budget word must
  cover the entries actually emitted, and three extra sprites change OBJ RAM
  regardless. Recorded so it is not re-proposed.

  **Recommendation: A**, with the measurement done first so the ruling is
  made on a number rather than on a prediction.

  **MEASURED 2026-08-05 (14z-60s), and the number is good.** Built
  (`select_wheel roster21`) and compared against the previous WIDE build on
  the masked basis, so the wheel change is the only variable:

  | replay | frames | divergent | window | after |
  |---|---|---|---|---|
  | `04_select_fuzz` | 3520 | 162 | 890-1051 | 2469 identical |
  | `02_demitri_vs_cpu` | 5520 | 733 | 890-1622 | 3898 identical |
  | `03_two_player_vs` | 5320 | 913 | 890-1802 | 3518 identical |
  | `09_mirror_pick` | 4720 | 993 | 890-1882 | 2838 identical |
  | `05_timeout_idle` | 12120 | 733 | 890-1622 | 10498 identical |

  Every replay: **onset at frame 890 — select-screen entry — exactly ONE
  contiguous run, and FULL RE-CONVERGENCE.** Match state is bit-identical
  in all five, including a complete timeout match (10,498 identical frames
  after the window closes). The divergence is confined to the screen we
  deliberately changed and reaches nothing else.

  That is a **stronger** guarantee than the existing frozen-`diverge`
  class, which never re-converges at all. The proposal for ratification is
  therefore a new comparison class: **"bounded select-screen window,
  re-convergent"** — onset frame, window end and run-count frozen per
  replay, with re-convergence and match-state identity as the assertions.
  Mechanism: select-screen init caches the record pointer we repointed
  (`GOTCHAS` class 4), which is why onset is identical across replays.

- ~~**THE `0x360+id` ANIM BLOCK (14z-60)**~~ **DECIDED 2026-08-05
  (maintainer): option A, INHERIT — "since we can. If it fails, we'll
  fall back to option B (relocation)."** So a newcomer at `0x13` plays
  anim `0x363` from the shared `0x360-0x36F` block, exactly as vsav2
  ships; sites `PRG:0x003E40` and `PRG:0x004082` stay folded and are
  recorded as `inherit` in the tenant manifest. Fallback if playtest shows
  the inherited animation is wrong for a newcomer: relocate the block to a
  free 32-wide anim-number range and widen both masks. Original write-up
  kept below.

- **THE `0x360+id` ANIM BLOCK (14z-60) — the analysis behind the decision
  above** — of the seven sites that fold the
  character id to 4 bits, five are ordinary porting work; two
  (`PRG:0x003E40`, `PRG:0x004082`) compute a per-character anim number in a
  block that is genuinely 16 wide (`0x360-0x36F`, with `0x370+` already
  occupied). **Option A: inherit** — a newcomer at `0x13` plays `0x363`,
  which is exactly what vsav2 ships, Capcom having left both folds in
  place. **Option B: relocate** the block to a free 32-wide range and widen
  both sites — a numbering audit plus shared-engine edits, for a family we
  cannot yet name. **Recommendation: A**, on the strength of vs2 being a
  shipped existence proof; revisit only if a playtest shows the inherited
  animation is wrong for a newcomer. Detail in session 14z-60 and
  `docs/atlas/id_space.md`.

- ~~**M5 SOUND NEEDS A DATA HOME (14z-52)**~~ **SETTLED 2026-08-04 by the
  dual-track decision below: it lives in `wide_ext`.** Two corrections to
  the record that got it there:
  **(a) Option B was DEAD and the recommendation was wrong.** It proposed
  reclaiming the "inert since 14z-31" `weapon_accent_t0/_t1/rowd_slot`
  rows. Measured 14z-59g: those are `data_port` rows writing 0x20 bytes
  each to `0x39FBE0-0x39FC40`, which is in NEITHER hole (`hole_a`
  `0x0BF6A0-0x100000`, `hole_b` `0x3EC720-0x400000`). They are in-place
  palette overwrites, not hole allocations, so reclaiming them frees
  **zero** of the 352 bytes needed. The original entry mistook them for
  hole tenants.
  **(b) Option C stopped being expensive.** It was rejected as "larger
  blast radius" before WIDE existed; WIDE is now demonstrated on both
  emulators, so it is the cheap option — and option A (Jedah's anim
  region) keeps its unaudited dead space AND stays available for the
  ported select web, which was its earmarked purpose all along.

- ~~**M5 VOICE SAMPLES (14z-51)**~~ **DECIDED 2026-08-04 (maintainer):
  "A then B, gates stay strict, option C is rejected."** Ship M5 with those
  specific sounds silent now (option A — it matches the current
  silent-by-design behaviour for exactly the sounds that cannot be
  faithful); revisit growing the QSound sample region (option B) at M3,
  when Huitzil and Pyron force the same question at scale, inside the
  measured 16 MB ceiling. **Option C (overwriting low-value vsav content)
  is rejected** and may not be re-proposed — it is superset-invariant-
  adjacent. Original entry with the full option analysis kept below.

- **M5 VOICE SAMPLES (14z-51) — the analysis behind the decision above:**
  6-8 of Donovan's sounds (his voice
  lines / vs2-new sfx: ids 0x71D/0x73E/0x753-0x756, likely the "Change
  Immortal" family) do not exist in vsav's sample ROMs, which are
  byte-full. Options: A) ship M5 with those specific sounds silent
  (shared sfx all restorable regardless); B) grow the QSound sample
  region via driver descriptor (vm3.11m/12m from 4MB->8MB members or
  add members; CLAUDE.md rule 1 permits load-map changes; MiSTer
  impact unknown); C) overwrite low-value vsav content (risky,
  superset-invariant-adjacent). Recommendation: A now (matches the
  current "silent by design" behavior for exactly the sounds that
  cannot be faithful), revisit B at M3 when Huitzil/Pyron force the
  same question at scale.
  **UPDATED 14z-59f — option B now has a measured hard ceiling.** CPS-2
  WIDE v1 already declares QSound at **16 MB, which is MAME's maximum**
  (`qsound_device` is a `device_rom_interface<24>`, 24 address bits). So
  B is available and proven on both emulators up to 16 MB and NOT ONE
  BYTE further: growing past it would mean widening a SHARED MAME device,
  which is outside Rule 1 v2. If Donovan + Huitzil + Pyron voice banks do
  not fit in the 8 MB the profile adds, the answer has to be exclusivity
  or banking, not more region. Worth sizing that before committing to B
  at M3. (Two duplicate copies of this entry were merged here.)

- ~~**ROSTER ACCESS MECHANISM**~~ **DECIDED 2026-08-04: option 1, an
  altered select screen keeping the existing cells and appending the three
  newcomers; hold-Start alternates are the fallback. See 14z-59l.**
- See SPEC §7 for the rest. Nothing blocks current work.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- Minor win-screen palette issues, same playtest. Lower priority, and
  probably unrelated — keep them separate until one is root-caused.

## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
