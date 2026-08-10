# HANDOFF — operational map

First read of any session after CLAUDE.md and STATE.md. Keep current in the
same commit as anything it describes.

## What exists (M0 bench, 2026-07-25)

| Piece | Where | Status |
|---|---|---|
| Reference sets | `$ROMDIR` (../ROMS, outside repo) | audited clean; all 6 zips present (vsav, vsavj, vsav2, vhunt2, vhunt2r1, qsound_hle) |
| Frozen checksum manifest | `docs/checksums.txt` | 76 members, per-file SHA-1 |
| ROM audit tool | `tools/audit_roms.py <romdir>` | verify vs manifest; `--freeze` to re-freeze |
| CPS-2 decrypt/encrypt | `tools/cps2_decrypt.py` | bit-identical to MAME oracle (both directions self-checked) |
| Null-patch builder | `tools/build_rom.py <romdir> <out.zip>` | deterministic, bit-identical vsavj |
| Build manifest | `build/manifest/vsavj.toml` | null patch; schema carries provenance |
| MAME headless runner | `tools/run_mame.sh <set> [args]` | MAME 0.288 (brew), fresh sandbox per run |
| Attract determinism | `tests/test_attract_determinism.sh` | PASS 3600 frames |
| Decrypt oracle test | `tests/test_decrypt_oracle.sh` | PASS (python == MAME opcode space) |
| FBNeo | `emu/fbneo` submodule + `tools/setup_fbneo.sh` | built (SDL2); TWO patches: `0001` harness (frontend-only: `-hinput/-hout/-hframes/-hdump`, plus `FBNEO_HVIDEO` framebuffer checksums, `FBNEO_HGFX` gfx-buffer dumps, and the B5b set — `FBNEO_HTAP` write tap with PC attribution, `FBNEO_HPOKE` frame-scheduled pokes, address-resolved dumps reaching OBJ/palette RAM) and `0002` the CPS-2 WIDE profile (driver descriptor + one gated core line). **CRC WARNING:** FBNeo matches zip members by CRC — a mismatched gfx/QSound member is silently replaced by 0xFF fill while still logging `(OK)` (docs/GOTCHAS.md) |

FBNeo build: `(cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)` — `SKIPDEPEND=1`
is mandatory (docs/GOTCHAS.md). Needs brew `sdl2`(-compat) + `sdl2_image`.

## CPS-2 WIDE — the extended hardware profile (2026-08-03, B0-B4 all green)

**Why it exists:** all 18 characters do not fit a stock CPS-2 (measured
deficit ~886 KiB program, ~6-7 MB tiles). WIDE is the named, versioned
profile that makes the roster physically possible. Spec + all measurements:
**`docs/project/cps2_wide.md`** (read it before touching any of this).

```
CPS-2 WIDE v1   PRG 6 MB | GFX 48 MB (19-bit tiles) | QSound 16 MB
```
Emulator cost: **one widened condition** in `cps_obj.cpp` plus the
`Cps2Wide` flag lifecycle. Everything else is descriptor table data.
Governed by **Rule 1 v2** (profile-gated + emulator superset invariant);
the profile runs under a separate driver entry `vsavjw`, so stock `vsavj`
and every other CPS-2 game are untouched by construction.

Status: **demonstrated, not just declared.** B0-B3 inert (24/24 RAM AND
framebuffer); B4 proves the space usable on both axes, each with a
negative control — sprites render pixel-perfect from the appended banks
(9/9), and relocated data is genuinely read from `CPU:$400000+`.

```sh
WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo /somewhere/fbneo_ref  # reference binary
tools/setup_fbneo.sh                                                    # the WIDE binary
# THE SHIPPABLE overlay (group C zero-filled). This is what content builds merge.
python3 tools/build_wide_romset.py "$ROMDIR" build/wide0/rompath \
        --qsound 2 --gfx 4 --prg 4                                      # prints the descriptor
                                                                        # rows incl. CRCs - paste them in
# THE B4 CANARY romset, separate directory, NEVER merged into a build:
python3 tools/build_wide_romset.py "$ROMDIR" build/wide_canary/rompath \
        --qsound 2 --gfx 4 --prg 4 --gfx-copy-group-b
ROMDIR=... FBNEO_REF=/somewhere/fbneo_ref tests/test_wide_profile.sh    # 36 checks, 3 sections
```

**Group C descriptor CRCs are SENTINELS (14z-62d):** 0xdec0de31..37 —
content members resolve by NAME on both emulators. Never set them to a
real member's CRC (hash-shadowing: pristine-B was the 60z garble, and the
zero-fill CRC collides with the zero QSound members in the same zip).
On variant-id builds `build_gfx_donovan` writes the band+shelf into
`vsw.31m/33m/35m/37m` (injected into `vsavjw.zip`) and vsav's group B
stays PRISTINE — the visual core of de-substitution.

**The two romsets must stay separate (14z-60z/61, cost two sessions).**
`--gfx-copy-group-b` writes byte copies of the stock group B members, so
they carry group B's CRCs. Both emulators resolve a ROM entry by HASH
before falling back to its NAME, so in a content build — whose group B
holds the ported tiles — the loader matches group B's declared CRC against
those copies and serves **pristine** tiles instead. That is exactly how the
WIDE track rendered Donovan and Anita with vanilla art while every gate
stayed green. `tools/audit_romset_identity.py` now fails any build that
carries the shape; it runs inside `build_donovan.sh`.
The reference binary MUST differ from the build under test by ONLY patch
0002 — build it from the same tree state or the comparison measures noise.
**Rebuild the reference whenever the harness changes**, and always in the
order above: `WIDE=0` now REVERTS the profile patch (it used to merely skip
applying it, so a "reference" built from a tree that already carried the
patch came out WITH the profile, and section 1 compared WIDE against WIDE —
a vacuous pass on the one invariant that justifies emulator changes at all,
14z-59e). Both the build and the gate now assert on the binary itself, so
this cannot recur silently.

Authoring into the extension: raw (no encryption above `PRG:0x0FFFFF`),
FILE byte order (`words_to_file_bytes(words_from_logical_bytes(...))`),
and `$400000-$40000F` reserved (CpsFrg registers, read-shadowed by ROM).
Descriptor CRCs: PRG/QSound extension rows carry the FILL members' real
CRCs (fixed content); gfx group C rows carry SENTINELS (variable
content — see above).

## MAME from source (B5, 2026-08-03) — the oracle now follows the profile

MAME is pinned as a submodule: `emu/mame`, tag **mame0288**, commit
`27a8d9e8`. A Homebrew binary cannot follow a descriptor change, so the
WIDE profile needs a source build.

Status: parity **62/62**, MAME WIDE gate **36/36** (superset invariant +
inertness + B4 canary, work RAM AND framebuffer). `-verifyroms vsavjw`
reports the romset good, so both emulators load byte-identical members.

```sh
WIDE=0 tools/setup_mame.sh     # reference binary -> ~/.cache/vampire-saved/mame-ref/cps2
tools/setup_mame.sh            # WIDE binary      -> ~/.cache/vampire-saved/mame/cps2
ROMDIR=... tests/test_mame_parity.sh          # RUN THIS FIRST (see below)
ROMDIR=... tests/test_mame_wide.sh            # superset invariant + inertness + B4 canary
```

**Order is not optional.** `test_mame_parity.sh` proves the UNPATCHED
source build reproduces every frozen oracle log bit-for-bit before the
profile patch is allowed near it — swapping the binary changes the
INSTRUMENT, and an instrument that moved invalidates every MAME finding
since session 1. The gate refuses to run against a binary that knows
`vsavjw`.

Three things about the build that will bite otherwise (all in GOTCHAS):
- it builds from an **rsync'd mirror under `~/.cache/vampire-saved/`**
  because MAME's GENie cannot handle the **space** in this repo's path,
  and a symlink does not help (`getcwd()` resolves through it);
- prerequisites are `brew install sdl3 pkgconf` — MAME 0.288's OSD is SDL3
  and it is found ONLY via pkg-config, otherwise the build dies minutes in;
- it is a `SOURCES=`-filtered CPS-2-only build (minutes, not hours), the
  binary is named `cps2`, and **a driver missing from `src/mame/mame.lst`
  is silently absent from it**.

Patch: `emu/mame-patches/0002-cps2-wide-v1.patch` — 164 lines added, exactly
**one** line removed (the sprite tile-code composition). Everything else is
additive. Keep it member-for-member identical to the FBNeo descriptor: one
romset zip feeds both emulators.

Two MAME-only facts that constrain the profile:
- **16 MB QSound is MAME's ceiling** — `qsound_device` is a
  `device_rom_interface<24>`. WIDE v1 fits exactly; growing further would
  mean widening a SHARED device, which is outside Rule 1 v2.
- **`$400000-$40000F` reads differ between the emulators** (FBNeo
  ROM-shadows the CPS2 output registers, MAME keeps them readable). Only the
  profile's reservation makes that unobservable — never allocate there.

`tests/lua/replay.lua` gained **`VIDEO_OUT=<path>`**, the MAME twin of
`FBNEO_HVIDEO` (per-frame framebuffer checksum, opt-in, written to a
separate file so no frozen RAM expectation moves). MAME's harness had the
same video blind spot FBNeo did, and the WIDE change is entirely a
rendering change. Ground truth: `tests/test_replay_video_selfcheck.sh`.

## Running a CPS-2 WIDE build (playtest)

```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/m5_wide fbneo      # or: ... mame
```

**`build/m5_wide` (fingerprint `9bac6ee3`) is the current WIDE build.**
`build/m5w` (`ac52eeff`) is the KNOWN-BAD artifact of the 14z-60y sprite
garble, kept as evidence — do not playtest it. `tools/audit_romset_identity.py
build/m5w/rompath` names its four shadowed members in a second. Rebuild the
pair with:

```sh
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 build/m5_wide
```

Three things must agree and `run_wide.sh` asserts all three, naming the one
that is wrong: the **patched binary** (the `vsavjw` driver exists only
there), the **set name** `vsavjw`, and a **rom search path** that fronts the
build over `$ROMDIR`.

**The two emulators take that third one completely differently**, which is
what made this fail confusingly:

| | how it finds roms |
|---|---|
| **MAME** | `-rompath "<build>/rompath;$ROMDIR"` — supported, works |
| **FBNeo** | **no `-rompath` option exists.** `szAppRomPaths[]` defaults to `/usr/local/share/roms/` and **`roms/` relative to cwd** (`src/burner/sdl/drv.cpp:6`) |

So for FBNeo the script builds an overlay dir (reference zips first, the
build's zips win) and runs the emulator from it. Passing `-rompath` to
FBNeo is silently ignored — it does not error, it just looks in the wrong
place and reports the set as missing.

### If it still will not start, in order

1. **Is there a WIDE build to run?**
   `ls build/m5w/rompath/vsavjw.zip`. If instead you have `vsavj.zip`, that
   build was made without `--profile cps2-wide-v1` and there is nothing
   WIDE to launch — rebuild:
   `KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" tools/build_donovan.sh 6 build/m5w`
2. **Does the binary carry the profile?**
   FBNeo: `strings -a emu/fbneo/fbneo | grep "CPS-2 WIDE v1"` (plain
   `grep -q` on the binary is unreliable — GOTCHAS).
   MAME: `~/.cache/vampire-saved/mame/cps2 -listfull vsavjw`.
   Either silent → build it: `tools/setup_fbneo.sh` / `tools/setup_mame.sh`.
3. **Is `ROMDIR` exported and clean?** `python3 tools/audit_roms.py "$ROMDIR"`.
4. **Read the emulator's own load log.** A healthy FBNeo start prints
   `CPS-2 WIDE v1 profile active`, `68K ROM size: 0x00600000`,
   `Graphics data: 0x03000000`, `QSound data: 0x01000000`, then
   `Loading program (vsw.41)... (OK)` through `vsw.44`. **31 members load
   OK.** A member reading `(OK)` is not proof by itself — FBNeo substitutes
   0xFF fill on a CRC mismatch while still printing `(OK)` (GOTCHAS) — but
   a *missing* line or a wrong region size localises the problem fast.

**"Unknown system: vsavjw" is an EMULATOR problem, not a ROM problem, and
renaming `vsavjw.zip` to `vsavj.zip` to force it is actively harmful** — it
boots under the stock 4MB descriptor with the sfx helper live and the sound
pointer aimed at the CPS2 register window, re-creating the music bug while
looking fine. See GOTCHAS.


## THE NATIVE LEG IS REACHABLE FOR ANY TENANT SCREEN (14z-69)

Huitzil can be forced on **native vsav2** with the ordinary
early-window poke — no vs2 cursor path, no savestate:

```sh
POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"   # P1; P2 = $FF8B82
tools/run_replay_mame.sh vsav2 <replay> out.log        # ~6 s
```

Verified by `+0x382 = 0x10` on the native leg, with DF (seq 0x0A) and
the air dash (seq 0x14) both firing. **Poke BOTH sides** when sprite
lists are compared: the cursor path lands on different characters on
the two wheels (P2 = 0x03 is Victor on vsav *and* vsav2).

**And when the state under test is a MODE, prove it was entered.** Dark
Force costs a banked stock; with an empty meter the P+K pair is
downgraded to a single button and the match looks normal. Poke
`$FF8509` and assert `$FF802E`=1 — never infer a mode flag from the
fighter block (`+0x1F4`, `+0x1B5/+0x1B9` are set by JUMPING).

This retires "the native leg is unreachable", which was inherited from
a single 14z-68j attempt with **replay 61** — a replay whose input
timing is authored for OUR wheel and does not transfer. Anything still
parked on "needs a native reference" (the win QUOTE set, the child
shadow, effect art) can now be A/B'd directly. Do not characterise a
tenant symptom without this leg — 14z-69 retracted two findings that
were artefacts of measuring our build alone (docs/GOTCHAS.md).

## DOCS ARE SPLIT THREE WAYS (14z-69) — `docs/README.md`

`docs/game/` (Vampire Savior itself) | `docs/platform/` (CPS-2, MAME,
FBNeo) | `docs/project/` (this port). The discriminator: **would this
still be true if we abandoned the roster hack tomorrow?** File by the
FACT, not by the task you were doing when you learned it.

`docs/GOTCHAS.md` is now an INDEX of all 135 entries grouped by bucket;
the entries live in `docs/{game,platform,project}/gotchas.md`. Every
existing citation of `docs/GOTCHAS.md` still lands there.

Looking for whether we already know something? The index is the fastest
topic list; `docs/game/atlas/ram.md` is the fastest address lookup.

## PRIOR ART FIRST — check the subsystem doc before re-deriving (14z-68m)

Huitzil's win screen was re-derived from scratch and got two of three
pieces wrong; Donovan's identical solution had been sitting in
STATE.md since 14z-45. The analysis existed, it just was not
DISCOVERABLE from "I am working on tenant X's screen Y".

**Before porting any per-character screen or subsystem for a new
tenant, read the matching section of `docs/game/engine_internals.md`** —
it now carries the worked instances for BOTH tenants (win screen,
select family, HUD, effect system, palettes). If the subsystem has no
section there, write one as you go: a session-log entry is a record of
what happened, not a document anyone will find later.

Cheap rule that would have caught it: when a symptom on tenant B
resembles one already fixed on tenant A, `grep -n "<subsystem>"
docs/game/engine_internals.md docs/project/patch_index.md` and diff A's manifest
rows against B's BEFORE measuring anything.

## Repo path changed (2026-08-05): `Vampire Saved` -> `Vampire_Saved`

The project root is now `/Users/koneko/Developer/Vampire_Saved/VampireSaved`
— the space is gone. Nothing in git was affected, but:

- An in-flight worktree pinned to the old absolute path was orphaned
  mid-session. **Commit before anything that moves the tree**, and
  `git worktree prune` after a path change (a stale locked entry survives
  the directory it names).
- A fresh worktree branches from `origin/main`, which trails local `main`
  badly here — `git reset --hard main` immediately after creating one.
- **`tools/setup_mame.sh`'s rsync mirror exists ONLY because GENie could not
  handle the space.** That constraint is gone, so the mirror could be
  dropped — but it changes the INSTRUMENT, so `tests/test_mame_parity.sh`
  must be green before and after. Not attempted yet.

## Platform / migration notes (14z-59d)

**The focus problem is already solved in place.** `tools/run_mame.sh` now
exports `SDL_VIDEODRIVER=dummy`, so SDL creates **no window at all** — there
is nothing to take focus and nothing for a stray keystroke to land on.
Measured non-perturbing: work RAM bit-identical to the frozen expectations,
and `VIDEO_OUT` still captures a live framebuffer (3,952 distinct checksums
over 5,520 frames — the emulated bitmap is internal to MAME and owes
nothing to SDL). Combined with the input-provider isolation and the
per-frame integrity assertion, a migration is now a *choice*, not a
necessity.

**What is actually at risk in a move: only the MAME expectations.**
- `tests/expected/**` are ABSOLUTE frozen values, and they are **MAME-only**
  — `run_suite.sh` drives MAME.
- Every FBNeo gate (`test_wide_profile.sh`, `test_fbneo_replay_determinism.sh`,
  the xemu gates) is a **live A/B comparison** and carries no frozen file,
  so it is machine-independent by construction. Verified by inspection.
- So `tests/test_mame_parity.sh` **is the migration gate**, and it covers
  the entire exposure. Run it on the target before trusting anything. If it
  fails, do NOT re-freeze to make it green — that silently redefines the
  baseline the superset invariant rests on.

**Does CPU architecture matter (ARM64 vs x86_64)?** It should not, and the
reason is specific rather than hopeful:
- MAME emulates CPS-2's 68000, Z80 and QSound DSP16 with **interpreters**.
  MAME's DRC/UML recompilers cover other CPU families (MIPS/PPC/SH), none
  of which CPS-2 uses — so there is no JIT whose codegen could differ.
- FBNeo ships an **A68K x86 assembly** 68000 core, but `BUILD_A68K` is
  commented out in its makefile and x64 targets undefine it anyway, so both
  ARM64 and x86_64 builds use the portable Musashi C core.
- All candidate hosts are little-endian, and `replay.lua` reads with an
  explicit `"<i8"`, so the checksum stream is endian-pinned regardless.

Still: that is an argument, not a measurement. `test_mame_parity.sh` is the
measurement, it is cheap, and it exists.

**Step-by-step Windows/WSL2 (and Linux) setup: `docs/project/WSL2_SETUP.md`** —
written for someone who has not used WSL2, and section 7 is the acceptance
test that decides whether a machine can be trusted.

**Target ranking for this toolchain** (POSIX shell + SDL builds):
| Target | Verdict |
|---|---|
| **Linux** | Best destination. Native SDL builds for both emulators, every `tests/*.sh` runs unchanged, true headless trivially. Only edit: `sysctl -n hw.ncpu` → `nproc` in `tools/setup_mame.sh`. |
| **Intel Mac** | Lowest friction *today* — the scripts are already macOS-shaped and brew provides sdl3/pkgconf. Good stepping stone; architecture is a non-issue per the analysis above. |
| **Windows 10** | Highest porting cost natively: the harness is POSIX shell plus FBNeo's **SDL** frontend, so it needs MSYS2 for both emulators and a POSIX shell for every gate. **Use WSL2 and treat it as the Linux target** — that is the pragmatic path if this is the machine that is free. |

## How to build

```sh
export ROMDIR=/path/to/reference/sets     # holds vsavj.zip, vsav.zip, vhunt2*.zip, qsound_hle.zip
python3 tools/audit_roms.py "$ROMDIR"     # always first; stop on FAIL
python3 tools/build_rom.py "$ROMDIR" build/out/vsavj.zip
```

Decrypted views for analysis (68k logical byte order — see docs/GOTCHAS.md
before touching any byte-order code):

```sh
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" build/out/vsavj_opcodes.bin --data-out build/out/vsavj_data.bin
```

## How to test

```sh
export ROMDIR=...
tests/test_decrypt_oracle.sh          # decryption == MAME's, both byte orders sane
tests/test_null_build.sh              # null build bit-identical + deterministic
tests/test_attract_determinism.sh     # 60s attract, per-frame RAM checksums, 2 runs
tests/test_fbneo_smoke.sh             # FBNeo headless boot + 15s crash-free soak
tests/test_m2a_stage4_code.sh         # stage-4 gate: veto lock + guarded moveset
                                      # + masked legacy gate (amended §4 basis;
                                      # frozen masked exps in tests/expected/vsavj/masked/)
tests/test_m2a_stage4_oracle.sh [rp]  # vsav2-as-oracle: anchors/neutral-exact/
                                      # HP-trajectory/comparative bound (17+18 replays)
tests/test_m2a_stage4_xemu.sh  [rp]   # dual-emulator: MAME+FBNeo field agreement
tests/test_m2a_flavor_selector.sh [rp]# Start-hold flavor latch (stage 5)
tests/test_don_sword.sh        [rp]   # sword-swing behavior gate (anim node)
tests/test_don_accent.sh       [rp]   # palette locks: accent steadiness, VICTOR
                                      # byte guard + cycle, fixture-override rows,
                                      # shock-window vanilla lock (palette ROM->RAM
                                      # is RAM-gate-blind — these are the only locks)
tests/test_don_sound.sh        [rp]   # sound-ring gate: NO vsavj music-range id may
                                      # be enqueued + frozen per-replay id inventories
                                      # (sound is invisible to every other gate)
tests/run_battery_m2.sh [outbase]     # THE deliverable battery: audit + all of the
                                      # above in order; run before ANY build commit
tests/audit_wide_phase_a.sh           # WIDE Phase A measurements (rerunnable; ground-
                                      # truths its own instrument before trusting nulls)
tests/test_wide_profile.sh            # WIDE profile gate: emulator superset invariant
                                      # + inertness + the B4 canary (needs FBNEO_REF)
tests/test_mame_parity.sh             # B5 PREREQUISITE: the pinned MAME source build
                                      # reproduces every frozen oracle log bit-for-bit
                                      # (refuses to run on a WIDE-patched binary)
tests/test_mame_wide.sh               # the MAME twin of test_wide_profile.sh
tests/test_replay_video_selfcheck.sh  # ground truth for replay.lua VIDEO_OUT (the MAME
                                      # framebuffer checksum) — both directions
tests/test_mame_determinism.sh        # RUNS=/JOBS=/PROBE= repetitions; measures the
                                      # run-to-run divergence rate the whole oracle
                                      # assumes is zero (see STATE 14z-59)
tests/test_crypt_boundary.sh          # code above the encryption window is stored RAW
                                      # (load-bearing: character code in the extension)
tests/test_dualtrack.sh               # dual-track: WIDE is legacy-IDENTICAL to stock,
                                      # differs only on patched-slot content, and the
                                      # attract difference is byte-attributed
tests/test_phasec_image.sh            # Phase C step 2: image grows to 6MB, WIDE romset
                                      # shaped+runs, extension PROVABLY READ (negative
                                      # control), stock build untouched
tests/test_phasec_spaces.sh           # Phase C: the declarative address-space model is
                                      # byte-for-byte inert on a stock build, and the
                                      # WIDE extension is gated by construction
tests/test_fbneo_instruments.sh       # B5b: FBNeo write tap (non-perturbing + re-derives
                                      # a known MAME finding), pokes, and address-resolved
                                      # dumps cross-checked byte-for-byte against MAME
tests/test_input_integrity.sh         # ground truth for the input-integrity check:
                                      # silent on clean runs, catches a stray
                                      # un-scripted press at the right frame. MAME's
                                      # window takes focus even under -video none,
                                      # so host keys reach the emulated controls
tests/test_compare_window.sh          # ground truth for the §4 v3 "bounded
                                      # re-convergent window" class: accepts the
                                      # select-screen shape; rejects flicker, a
                                      # drifting onset, a run that never
                                      # re-converges, and a silently-identical
                                      # pair. No emulator needed
tests/test_select_wheel.sh            # the select cursor, 4 sections: tables decoded
                                      # from the ROM; a generated walk over all 128
                                      # (cell,direction) pairs measured in MAME; four
                                      # negative controls on the checker's verdicts;
                                      # and all 16 cell screen positions measured
tests/test_id_space.sh                # freezes the id space: 0 out-of-range variant
                                      # rows, the 5 sites that fold the id to 4 bits,
                                      # and vsav2's 2-fold/6-widened reference shape
tests/audit_id_writers.sh             # on-demand (22 MAME runs): every character-id
                                      # VALUE vanilla ever assigns, both player structs.
                                      # Fails if any legacy gameplay path writes an id in
                                      # 0x10-0x1F — the invariant that would make a tenant
                                      # on a variant id superset-safe by construction
tests/audit_mask_window_ff4182.sh     # on-demand: proves the masked palette-staging
                                      # window hides the designed diff and nothing else
tests/test_select_arrays.sh           # the select record-pointer arrays (M3a): all THREE
                                      # UI pieces (portrait 0x26742A, name 0x2675AA,
                                      # highlight 0x268A02), 32 rows per player with P2 at
                                      # +0x80, indexed by cell/id with NO 4-bit fold, rows
                                      # 0x10-0x1F variant aliases. A tenant at 0x13 costs
                                      # SIX longs. Static model + a one-byte corruption
                                      # control + the ENGINE's own row sequence for each
                                      # piece. ~13s
tests/test_tenant_id.sh               # the tenant id is a BUILD INPUT: resolution,
                                      # the variant-id-needs-profile refusal, and the
                                      # frozen-reference reproducibility guard (no
                                      # id_by_profile until M3a completes). EXTENDED
                                      # 14z-77 (M3b slice C) with ROW OWNERSHIP: the
                                      # per-FILE stamp, row_owner resolution, the
                                      # row_applies truth table, row_hex selection, and
                                      # the multi-tenant refusal in BOTH directions
                                      # (asserted by no test before this; the loop
                                      # slice deletes the refusal and flips it).
                                      # Pure functions, no ROMs, no emulator. ~1s
tests/test_manifest_merge.sh          # 14z-77 (M3b slice F): what the three
                                      # tenant manifests DO when merged. Freezes
                                      # the shared-row dedup counts (space 9->3,
                                      # obj_hook 6->2, wheel 3->1, site_thunk
                                      # 34->28, port_patch 90->87) and the exact
                                      # 12-collision inventory in TWO classes:
                                      # THREE real blockers ([init_shim] once,
                                      # [table_fix] twice — TOML singletons, so
                                      # the schema cannot express two) and SIX
                                      # that DISSOLVE on the WIDE track (all
                                      # three tenants agree on new_hex_variant,
                                      # and a merged build is a WIDE build by
                                      # construction). A span collision is
                                      # invisible to row dedup AND to
                                      # patch_prg.py's overlap assertion, hence
                                      # its own check. 4 permissiveness
                                      # controls. No ROMs, ~1s
tests/test_tenant_row_owner.sh [ex]   # 14z-77 (M3b slices C+D): is the row-OWNER
                                      # threading LOAD-BEARING? Every slice of the
                                      # multi-tenant refactor is INERT by design, so
                                      # a threading accidentally DISCONNECTED from
                                      # the emitted ops leaves the four fingerprints
                                      # unchanged too and reads as a success. This
                                      # gate perturbs ONE owner-derived row at a time
                                      # and requires the generator's OUTPUT to
                                      # change. 10 sites (slices C/D/E).
                                      # Compares the WHOLE OUTPUT DIR, not
                                      # patch.json: region blobs leave as side
                                      # .bin files, so a byte changed inside a
                                      # blob moves no op — the first version
                                      # had that blind spot and its own
                                      # controls caught it.
                                      # Runs the GENERATOR ALONE against an existing
                                      # extract dir (default build/m5_wide/extract,
                                      # SKIPs without one), so each control costs
                                      # seconds not a 4-min four-target rebuild.
                                      # Verdict logic ground-truthed: it perturbs an
                                      # intentionally UNUSED binding and requires the
                                      # checker to call it DEAD. Edits the generator
                                      # in place; trap restores on EXIT/INT/TERM and
                                      # a section asserts byte-identity. ~9s. Run it
                                      # WITH test_m3a_reproducible.sh on every M3b
                                      # machinery commit — opposite questions
tests/test_tenant_select_records.sh   # M3a select-records mechanism (14z-62): a
                                      # variant-id build carries the tenant's OWN six
                                      # select records (space-model allocations, six
                                      # array rows poked) and the host's select-family
                                      # program bytes are VANILLA. Static re-derivation
                                      # + verdict-logic negative controls + the engine's
                                      # own row fetch onto cell 0x13 (replay 36, WIDE
                                      # MAME). Self-builds at 0x13 unless given a build
tests/test_wheel_bank5.sh      [ob]   # the select-wheel bank-5 move (14z-63): site +
                                      # re-derived tile inventory + group C member
                                      # identity straight from the zips + negative
                                      # controls + the engine's own bank-5 walk.
                                      # Self-builds at 0x13 unless given a build
tests/test_tenant_hud.sh       [ob]   # variant-id HUD (14z-63): the tenant's own
                                      # in-match mugshot/name via row 0x13 of the
                                      # 32-row-aliased HUD tables + free-pool art;
                                      # host cells pristine; staged codes measured
                                      # in-match. Self-builds at 0x13 unless given
tests/test_tenant_winpal.sh    [ob]   # variant-id win-screen palette (14z-63): the
                                      # sparse block + TT thunk at 0x5F1B6; BOTH
                                      # thunk paths measured on real 2P victories
                                      # (replays 61/62). Self-builds at 0x13 unless
tests/test_don_throw_mirror.sh [ob]   # the 14z-2 mirror-victim fix (applied 14z-64):
                                      # base-slot mirror throws use the Donovan-victim
                                      # block — static 2-byte assertion + a matched
                                      # runtime control pair on replay 65. SKIPs on
                                      # variant-id builds (correct by construction)
tests/test_accent_census.sh    [ob]   # accent/march census (14z-63): 4 frozen
                                      # family-base sites (0 direct T0/T1 refs),
                                      # all jsr-routed on variant builds. Static
                                      # + negative control, ~30s (self-builds)
tests/test_index_space.sh             # 14z-76: THE OUT-OF-RANGE INDEX SWEEP.
                                      # vsavj's dispatch tables are SHORTER than
                                      # vs2's, so a ported index can run past the
                                      # end (Pyron's Cosmo sub-state 81 into an
                                      # 80-entry table). Derives every
                                      # `jmp (d8,PC,Dn.w)` table's entry count in
                                      # BOTH roms from two structural bounds — a
                                      # target cannot land inside the table, and a
                                      # table cannot overlap the next dispatcher —
                                      # and reports where vs2 is longer. Frozen:
                                      # 110 tables, 81 twinned (24 by instruction
                                      # SHAPE, which survives relocation where a
                                      # byte-context match does not), 29 NOT
                                      # JUDGED, 3 risky. The unjudged count is part
                                      # of the verdict. Positive control: it must
                                      # re-derive the Cosmo table at 80 vs 84.
                                      # tools/audit_index_space.py. Static, seconds
tests/test_effect_palette_table.sh    # 14z-76: the per-character palette POINTER
                                      # tables are 32-row and id-INDEXED. 0x38C198
                                      # (sprite) and 0x38C218 (effect) each hold 32
                                      # rows; 0x38C1D8/0x38C258 are their variant
                                      # halves, never a base (0 refs in either ROM
                                      # view); both alias the base half except rows
                                      # 0x12/0x18 (Oboro Bishamon is real); and the
                                      # 5 readers take the id byte UNMASKED. This is
                                      # what licenses repointing a tenant's row —
                                      # the "only sixteen rows" reading deferred
                                      # Pyron's effect palette for two sessions.
                                      # 4 negative controls (a fold in the reader,
                                      # a reference to the second half, a de-aliased
                                      # variant row, a build clobbering a base-half
                                      # row). tools/audit_effect_palette_table.py.
                                      # Static, seconds
tests/test_compare_composite.sh       # ground truth for the §4 v4 composite class
                                      # (frozen flicker inventory + frozen bounded
                                      # windows, RATIFIED 2026-08-06): 7 synthetic
                                      # cases + a no-loophole check. No emulator.
                                      # donovan-m5w freezes 7 replays in this class
tests/test_hui_boot.sh                # Huitzil stage-4 BOOT gate (14z-65): the
                                      # forced-pick match forms with HIS data
                                      # (base read from the build's own patch),
                                      # guard clean, legacy bit-identical
tests/test_hui_ladder.sh              # Huitzil stage 1-3 ladder gate (14z-65):
                                      # builds from huitzil.toml + THE OP
                                      # INVARIANT (every op = free space or a
                                      # variant row) + legacy replay bit-identity.
                                      # Build any tenant: TENANT_MANIFEST=...
                                      # TENANT_CHAR=0x10 tools/build_donovan.sh
tests/test_hui_oracle.sh [rp]         # THE vsav2-as-oracle battery (14z-66): the
                                      # m2a template's 4 locks on H's full moveset
                                      # (anchors/neutral-exact/HP-trajectory/
                                      # comparative bound); RNG determinized on
                                      # both legs. ~10 min, 8 MAME runs
tests/test_hui_pairs.sh        [bd]   # Reflect Wall GC + Dark Force gate (14z-66):
                                      # both native-matched signatures (GC seq 0x0E +
                                      # blowback; DF 0x0A at both activations).
                                      # Self-builds stage 4 unless given a build
tests/test_hui_grab.sh         [bd]   # Circuit Scrapper gate (14z-66): the 2P-dummy
                                      # grab connects with the NATIVE damage datum
                                      # (frame-identical A/B of record). Early-window
                                      # 2P pokes only — see the replay 80 header.
                                      # Self-builds stage 4 unless given a build
tests/test_list_type_census.sh         # 14z-74: the ONE-SOURCE-BANK re-check per
                                      # tenant. gfx_layout3 assumes a tenant's art is
                                      # one band in one source bank; a list TYPE 4
                                      # composes its OWN bank word and breaks that
                                      # (Huitzil's beam). Frozen counts: H 26 type-4
                                      # (the POSITIVE CONTROL — its first version was
                                      # blind and read 0 for him), D 1, PYRON 0 (so his
                                      # delta-0 placement needs no strip-tiles). Static
tests/test_pyron_cosmo.sh      [bd]   # 14z-74: the Cosmo Disruption crash. 3 sections —
                                      # static (the guarded word + table+0x224 IS vs2's
                                      # handler byte-for-byte), DEADNESS (0 dispatcher
                                      # reads of entry 81 vs a live 12/7 control; watches
                                      # the OPCODES space because the table is read
                                      # pc-relatively, and filters BY PC because the boot
                                      # ROM-checksum sweep touches every byte), and
                                      # runtime (no crash, the EX still FIRES, the match
                                      # survives — a watchdog reset is not a 68k
                                      # exception, so the field trace proves it, not the
                                      # guard). Defaults to build/pyron18
tests/test_variant_dispatch.sh [bd]   # 14z-75: THE VARIANT-ROW DISPATCH SWEEP.
                                      # vsav aliases rows 0x10-0x1F of 32-row
                                      # per-character JUMP TABLES onto 0x00-0x0F, so a
                                      # tenant silently inherits a base-half character's
                                      # routine — the most common defect shape in this
                                      # port. Sweeps every `jmp (d8,PC,Dn.w)` word table
                                      # with a mostly-aliased variant half (5 exist) and
                                      # requires ours[tenant row] == vs2's. Rows where
                                      # OURS RUNS A ROUTINE vs2 DOES NOT fail; rows where
                                      # vs2 runs one we do not are reported only (a
                                      # missing feature, not a spurious one). Catches all
                                      # THREE of Pyron's blink tables on pyron15. Two
                                      # controls: a reintroduced aliased row must be
                                      # caught, and NO table may be "unjudgeable" (vsav
                                      # ships two identical dispatchers, so the twin
                                      # finder matches by ORDINAL — demanding a unique
                                      # context silently skipped the first defect).
                                      # tools/audit_variant_dispatch.py. Static, seconds
tests/test_pyron_blink.sh      [bd]   # 14z-75: the sprite/HUD BLINK. Palette row 10
                                      # (0x90C140) carries Pyron's SPRITE and his
                                      # in-match HUD MUGSHOT, so both blink. Native
                                      # vsav2 vs the build on replay 76 (one rig, both
                                      # games), compared by a PHASE-INDEPENDENT property
                                      # — distinct row-10 values over 40 CONSECUTIVE
                                      # frames — because the two games are never on the
                                      # same frame and a frame-indexed diff produced a
                                      # confounded figure that stood a whole session.
                                      # native 1/0 changes, ours 2/39. Attribution is
                                      # part of the verdict: ours' two values must be
                                      # NAMED (native's constant + vsavj palette-seq row
                                      # 0x26 under the uploader's 0xF000 OR), so a
                                      # look-alike defect fails. REFUSES to judge unless
                                      # both legs show +0x382=0x11. 7 verdict controls.
                                      # FIXED 14z-75 (a DEAD ROW: per-char palette-routine
                                      # table 0x2A8A4 row 0x11 aliased row 0x01's ANIMATED
                                      # handler; one word 0x2A8C6 008E->0040 = vs2's own
                                      # value). PYRON_BLINK_EXPECT=fixed (default) |
                                      # blinks (reproduces the pre-fix shape on pyron15).
                                      # Checker tools/check_pyron_blink.py. Defaults
                                      # build/pyron17
tests/test_hui_grab_victim.sh  [bd]   # grab-victim placement A/B (14z-73): native
                                      # vsav2 vs the build, replay 80 through
                                      # field_trace.lua, comparing the victim offset
                                      # RELATIVE to the attacker (dx=p2x-p1x — cancels
                                      # the ~21px global camera shift, so NO corner rig
                                      # is needed). Refuses to judge unless both legs
                                      # grabbed (seq 0x0E + 0x13 dmg); 2 verdict controls.
                                      # GRAB_VICTIM_EXPECT=differs (default) freezes the
                                      # OPEN teleport (~109px, victim placed behind not
                                      # in front); =matches is the post-fix target.
                                      # Checker tools/check_grab_victim.py. Defaults hui25
tests/test_hui_air.sh          [bd]   # Huitzil air-movement gate (14z-66): the
                                      # float hovers (Y pinned) and the air dash
                                      # engages (seq 0x14, flat advance) — mode
                                      # signatures, not just no-crash.
                                      # Self-builds stage 4 unless given a build
tests/test_hui_ex.sh           [bd]   # Huitzil EX-move gate (14z-66): FOUR
                                      # sections (ES, FG-connect, FG-full-seq,
                                      # FG+aftermath chaos) — each fires with the
                                      # stock decrementing (anti-coverage-loss).
                                      # Self-builds stage 4 unless given a build
tests/test_hui_walk.sh         [bd]   # Huitzil velocity-port gate (14z-66):
                                      # param32 rows 0x10 static + measured
                                      # walk-speed deltas (16.16-exact).
                                      # Self-builds stage 4 unless given a build
tests/test_pyron_ladder.sh            # the Pyron stage 1-4 ladder (14z-67):
                                      # builds from pyron.toml, per-stage op
                                      # invariant (stage 4 exempts exactly the
                                      # four generator hook sites), forced-pick
                                      # boot probe, stage-3 UNMASKED legacy
                                      # bit-identity + stage-4 masked-v2 EXACT
tests/test_census_regions.sh [bd]     # ground truth for tools/census_regions.py
                                      # (14z-67): the data_in_code + pcrel-escape
                                      # censuses — H's frozen inventory (5 sites,
                                      # 89/35 + 9/6 escapes, adjacency-safe class,
                                      # 2 known false positives, the x05c800
                                      # KNOWN-OPEN latent pair) + Pyron clean.
                                      # Self-builds stage 4 unless given a build
tests/test_gfx_layout3.sh             # the 3-tenant group-C layout fact-locks
                                      # (14z-67, D4): one-source-bank premise,
                                      # frozen H/P/D tile inventories, H/P
                                      # delta-0 disjoint from D's frozen band
                                      # by interval, the flip-condition bound.
                                      # Static, ~90s. Ledger:
                                      # build/manifest/gfx_layout3.toml
tests/test_extract_hp.sh              # Huitzil/Pyron extraction gate (14z-65):
                                      # frozen region shapes (piecewise shifts,
                                      # dead filler, the H insertion sliver) +
                                      # unanchored-char refusal control. ~2min
tests/test_patch_overlap.sh           # ground truth for the patch_prg op-overlap
                                      # assertion (14z-65): two ops writing one word
                                      # is a NAMED build error; disjoint and
                                      # word-adjacent ops stay clean. ~2s, no emulator
tests/test_m3a_reproducible.sh        # M3b Phase 0 gate: ALL FOUR frozen references
                                      # (donovan-m3a 4b7d0dc7 / m5_stock 6c93cfa8 /
                                      # huitzil-m2 9deda080 / pyron-m2 69e8c6f0)
                                      # rebuild bit-exact from the tree (scratch
                                      # dirs). Extended from the original PAIR in
                                      # 14z-76; its value scales with the count —
                                      # three independent tenant fingerprints are
                                      # three independent oracles over one refactor.
                                      # Needs only ROMDIR, no emulator. ~4 min.
                                      # Run after EVERY M3b machinery commit
tests/test_romset_identity.sh         # ground truth for tools/audit_romset_identity.py:
                                      # no member may carry the PRISTINE bytes of a member
                                      # the build patched (both emulators resolve a ROM
                                      # entry by hash before name, so such a member
                                      # silently reverts the patch — 14z-60z). 4 synthetic
                                      # sets, no emulator, ~1s
tests/test_hui_winscreen.sh    [bd]   # the WIN-SCREEN gate (14z-68m): palette
                                      # SOURCE (the OPCODE-view remap table, proved
                                      # by Donovan's frozen row), the SELF-LABELLING
                                      # marker (last word of each palette row = 5*row
                                      # — the check that would have caught shipping
                                      # Donovan's palette), all 8 colour sets, and the
                                      # portrait POSITION row. Static, seconds.
                                      # Negative control: FAILS on build/hui10
tests/test_hui_fx_flow.sh      [bd]   # the effect-flow attribution gate (14z-68):
                                      # leg 1 fighter-side flow identity (H's ray runs
                                      # HIS per-char handlers; the REFUTED 0x56D68 entry
                                      # must stay cold); leg 2 piece-side machine
                                      # attribution, auto-detecting pre/post-port from
                                      # the build's own patch notes. Rig: replay 83b
                                      # (2P dummy, 3 spaced 236LP, FBNeo taps).
                                      # Ground-truthed on hui9 + a bad-thunk negative
                                      # control. Self-builds stage 6 unless given
tests/test_hui_df_style.sh     [bd]   # the DARK FORCE gate (14z-69): replay 85
                                      # on NATIVE vsav2 vs the build. DF COSTS A
                                      # BANKED STOCK — the replay pokes $FF8509 and
                                      # the checker (tools/check_df_style.py) REFUSES
                                      # to judge unless both legs show $FF802E=1 and
                                      # a stock spent (seq 0x0A with an empty meter is
                                      # the DOWNGRADE, not DF — it fooled three
                                      # sessions). Freezes the OPEN defect's shape
                                      # (--expect differs: purple row 0x0A vs native
                                      # gold, his art drawn ~4x over); set
                                      # DF_STYLE_EXPECT=matches when fixed. Three
                                      # verdict controls. Defaults to build/hui25
tests/audit_empty_tiles.sh    [bd]     # 14z-69o: does the build DRAW any sprite whose
                                      # group-C tile is BLANK? A remapped-but-uncopied
                                      # tile renders as a SOLID RECTANGLE and no other
                                      # gate can see it (records/codes/walk all correct).
                                      # Complete, not a sample. Ground-truthed: PASSES on
                                      # build/hui14, FAILS on build/hui12 naming both
                                      # shadow tiles. RUN FOR EVERY NEW TENANT
tests/audit_palette_seq_ids.sh        # 14z-69p: which palette-seq ids does LEGACY ever
                                      # request? (uncapped probe on 0x2AD82, 8 replays).
                                      # The DF-palette data row is legacy-inert ONLY
                                      # because the answer is {0x26, 0x27} — and the
                                      # palette path never transits work RAM, so this
                                      # audit is its ONLY guard. Use GUARD_PROBE_MAX:
                                      # the default 400-hit cap truncated it once and
                                      # hid id 0x27
tests/test_beam_variants.sh    [bd]   # 14z-70h: the beam-port premises. All THREE
                                      # variants (236+P / 236+K / 236+2P==2K) are ONE
                                      # art path — pal 0x0C from the tenant band — and
                                      # every tile they draw is ALREADY in group C, so
                                      # the port needs no copy-inventory work. Encodes
                                      # two paid-for traps: ES CONSUMES A METER STOCK
                                      # (empty meter = silent downgrade, like DF, so it
                                      # asserts the ES is richer than P), and multi-tile
                                      # sprites must be expanded w*h at base+row*0x10+col
                                      # (obj_records_dump reports the BASE code only).
                                      # Native leg only, ~1 min
tests/test_beam_anim_walk.sh   [bd]   # 14z-70: does the build ever WALK the anim
                                      # nodes that carry the beam sprite lists?
                                      # Native reads 0x24FCFA twice in its beam
                                      # window; ours reads the placed twin 0x0E2DD8
                                      # ZERO times — the defect is anim-sequence
                                      # SELECTION, not the draw path. 4 sections
                                      # (static port check 11/11 relocated pointers,
                                      # native leg, our leg, 3 verdict controls).
                                      # BEAM_WALK_EXPECT=walks (default since 14z-71) |
                                      # absent reproduces the pre-fix state.
                                      # Defaults to build/hui25. ~2 min
tests/test_beam_list_type6.sh         # 14z-71: the list-type 6 TAKEOVER gate. The
                                      # thunk body must be Capcom's composite handler
                                      # (vs2 0x01A1FC) with EXACTLY six scratch
                                      # displacements, bsr.w -> jsr 0x1AFAE and one
                                      # loop displacement changed — checked by
                                      # RECONSTRUCTING it from vs2's bytes, not by
                                      # diffing with a tolerance. Also proves the
                                      # non-tenant FALLBACK reproduces vsav's own
                                      # type-6 head and rejoins at 0x01B6B2, which is
                                      # the entire safety argument and which legacy
                                      # never exercises. Static, seconds
tests/audit_effect_class_rows.sh      # 14z-71: the THREE deadness measurements the
                                      # beam port rests on — effect-class row 16 is
                                      # never dispatched by vanilla (0 reads, against
                                      # a 1760-hit control on row 37); the composite
                                      # handler's A5 scratch $FF3578-$FF3581 IS used
                                      # (39/replay) so vs2's displacements cannot be
                                      # kept; and drawer list-type 10 is NOT a spare
                                      # slot (2702 reads) — the closed shortcut.
                                      # EVERY section carries a same-instrument
                                      # positive control: this file exists because a
                                      # blind watchpoint and a real zero look
                                      # identical, and both traps bit here (GOTCHAS)
tests/test_wide_render_content.sh     # the WIDE track must SERVE the ported content's
                                      # tiles (RE-SHAPED 14z-67 for m3a semantics —
                                      # cross-track pixel identity ended BY DESIGN):
                                      # member identity + decoded band equivalence at
                                      # the correct banks (WIDE 0x4AD8F == stock
                                      # 0x2AD8F; WIDE 0x2AD8F == PRISTINE, the
                                      # de-substitution invariant) + a true-shadow
                                      # audit control + liveness (replay 36). This is
                                      # the gate whose absence let the sprite garble
                                      # reach a playtest — AND the gate that sat
                                      # stale-red from 14z-64 to 14z-67 (GOTCHAS:
                                      # the not-in-the-battery class)
```

Diagnostic instruments added with that gate (MAME Lua, all rerunnable):
`tests/lua/snapshot_frames.lua` (real PNG snapshots headlessly — MAME
renders its bitmap internally even under `-video none`, so `video:snapshot()`
works and the screen can be LOOKED at in-loop), `tests/lua/obj_records_dump.lua`
(the live sprite list with the composed 18/19-bit tile address per entry;
**both gained `POKES` in 14z-68** — replay.lua grammar, so forced-pick rigs
can finally be photographed and OBJ-dumped; reach for these BEFORE the third
RAM-layer iteration, docs/GOTCHAS.md "verify at the RENDER layer"),
`tests/lua/gfx_region_dump.lua` (decoded tile bytes at a TILE index —
compose the bank bits first, see GOTCHAS).

All tests are self-contained, take state only via env/args, print PASS/FAIL,
and exit nonzero on failure. Every dev-time in-emulator probe must land here
before session end (persistent suite doctrine, CLAUDE.md §4).

## Build registry

**Every frozen build is git-tagged `freeze/<name>`** (annotated; the tag
message carries the fingerprint and how to reproduce). `git tag -l 'freeze/*'`
lists them. This matters most for SUPERSEDED builds — `pyron-m1` and
`huitzil-m1` cannot be produced from today's tree because their manifests
moved on, and their tag is the only way back to a tree that does.
NOTE: the tags mark the commit at which each build was frozen and was
reproducible AT THAT TIME; no one has re-verified the older ones since.


| Build | SHA-1 (zip) | Notes |
|---|---|---|
| pyron-m1 — SUPERSEDED by pyron-m2 (14z-76); no longer producible from the tree (pyron.toml now carries the effect-palette row) | fingerprint `d8b282daab75fcb3c52e75170a05a600fd0f3ad7` | `build/pyron19`; REGISTERED `-> pyron-m1`. The THIRD full-roster tenant, at his native vs2 id 0x11. Everything the 14z-74/75 arc landed: his art at delta 0, select family + 21-cell wheel, sprite palettes, win screen, his own variant-id HUD (anchors 0xBE94/0xBE9C), physics, the air 214+P fix, THE BLINK (three aliased palette-routine tables, one word each — sweep them with `tests/test_variant_dispatch.sh`), and THE COSMO CRASH fixed in HIS OWN DATA (sub-state index 81 is out of range for vsavj's 80-entry table; retargeted 81->79 at vs2 0x0D0C7F, one byte, tenant-scoped — the 14z-74 engine-side repoint of the shared word is WITHDRAWN, it broke four legacy replays). Expectation set `tests/expected/pyron-m1/`: 42 `.sha1` + 13 `.masked` + 17 `.skip` = 72/72 replays, `run_suite.sh vsavjw` **GREEN (55 PASS / 17 SKIP / 0 FAIL)**. Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/pyron19/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. OPEN (non-blocking): the win QUOTE (shared fold), his EFFECT palette (PORTED 14z-76 on `build/pyron20` `69e8c6f0`, awaiting playtest — the "16-row table" reason this row was deferred is RETRACTED, see the pyron20 row below), and replay 80's f4840 reset — an INDEPENDENT defect present on pyron14 too. |
| **pyron-m2 — PYRON RE-FROZEN (14z-76, 2026-08-10, maintainer playtest) — supersedes pyron-m1** | fingerprint `69e8c6f08b9fc5859948e50cfb41156d62adf1ec` | `build/pyron20`; REGISTERED `-> pyron-m2`; rebuilds bit-exact. = pyron-m1 + his EFFECT palette block, delta EXACTLY two ops (`data_file 0x3faba0` from vs2 `0x3AC45C` len `0xDC0`, and `poke32 0x38c25c -> 0x003faba0` = row 0x11 of the effect-palette pointer table). **The "16-row table" premise that deferred this for two sessions is RETRACTED** — `0x38C218` is ONE 32-row id-indexed table and `0x38C258` is its second half (0 references in either ROM view; both tables alias their variant half except rows 0x12/0x18, the Oboro-class datasets), so row 0x11 is an ordinary variant alias row. Gate `tests/test_effect_palette_table.sh`. **Visibility was undecidable automatically** (0 reads of any effect block across two vanilla fighting replays + a 6000-frame soak, against a 60-read positive control on his sprite block — a rare-event palette); the maintainer playtest decided it: Pyron's shock aura RED on pyron19 / YELLOW on pyron20 = vs2, and **Demitri identical on both builds and correct**, which is the legacy check no RAM gate can make. Expectation set `tests/expected/pyron-m2/` (renamed from pyron-m1, content unchanged), `run_suite.sh vsavjw` GREEN 55 PASS / 17 SKIP / 0 FAIL. Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/pyron20/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. OPEN: the win QUOTE (14z-76 measured its real path and eliminated the arrays every prior attempt targeted) and replay 80's f4840 reset. |
| **huitzil-m2 — PHOBOS FROZEN (14z-74, supersedes m1)** | fingerprint `9deda0808e87601b10e2171405805d4669ba2624` | `build/hui27`; REGISTERED `-> huitzil-m2`. = m1 + decision D5 (the pcrel-scan no longer corrupts the ported OBJ bank table; delta exactly 24 bytes). Maintainer playtest clean; the m1 expectation set (renamed to huitzil-m2) is GREEN on it, and Phobos-vs-Demitri/Sasquatch/Q-Bee/Bishamon are bit-identical to m1 across 14,621 frames each. **m1's 22c016ac can no longer be produced from the tree** — that is why it was superseded rather than kept. Prior m1 text follows: The first full-roster tenant frozen. Expectation set `tests/expected/huitzil-m1/`: 38 `.sha1` (self-frozen determinism) + 13 `.masked` (vanilla-legacy under the ram.md mask: exact/window/composite/diverge — classes MATCH the donovan-m3a basis, confirming the beam hooks are legacy-inert) + 17 `.skip` — all 71 replays accounted for, `run_suite.sh vsavjw` GREEN (54 PASS / 17 SKIP). One deviation from the donovan-m3a inventory: `11_pick_donovan` is `.skip` here (it picks the Donovan cell 0x13, unbacked on this Huitzil-only build; the tenant pick is covered by `37_pick_huitzil_cell`). Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/hui26/rompath;$ROMDIR" tests/run_suite.sh vsavjw`. = hui25 + one `[[data_port]]` `grab_hold_keyframes`. The victim's per-frame HOLD position is written by a shared capture positioner (`victim_pos = attacker_pos ± facing-flipped keyframe (Xoff,Yoff)`) that selects a per-ATTACKER keyframe block via pointer table `0xBE27A[attacker_id]`; H reaches it through his ported CLONE `0xc9eb0` (0x27282 fell inside region x026142). vsavj row 0x10 = `0x092C4A` ALIASED character 0's block, so H held the victim with char-0's offsets (dx −27 vs native +74, a ~109px teleport). Fix ports H's OWN vs2 block `0x0C56AA` (len `0x1D80`, sibling-identical to vh2 `0x0C4F3C` through `0x1E1A`) into `wide_ext` `0x40b220` and repoints row `0xBE2BA` — host block `0x092C4A` and every vanilla row untouched. The exact twin of Donovan's `throw_victim_keyframes` (`donovan.toml:711`). **Maintainer-confirmed clean on BOTH grabs (6MP/6HP + 63214) in MAME and FBNeo.** Also this session: FG "slowness" was the broken GFX, not timing — resolved by observation. Gates: full H battery GREEN (boot=legacy masked-v2 EXACT, grab, grab_victim `matches` peak Δ=0, winscreen, pairs, ex, air, walk, df_style, empty_tiles, beam_variants/walk/list6, gfx_layout3, m3a_reproducible). New gate `tests/test_hui_grab_victim.sh` + `tools/check_grab_victim.py` (phase-tolerant relative-offset A/B). OPEN: only the cosmetic win quote (does not block freeze). Retraction (STATE 14z-73): "positioner never invoked" was a false negative — I breakpointed the vanilla copy `0x2802e`, not H's clone `0xc9eb0`. |
| **hui25 — THE BEAM DRAWS CLEAN (14z-71, maintainer-confirmed, superseded by hui26)** | fingerprint `b0fb2f948e04aa53b5e6ab21e2426a47540854bc` | `build/hui25`; prior launcher default. = hui20 + the STRIP fix, i.e. the third defect under the first two. The beam's middle piece is a procedural list-type-4 strip, and (a) vsav's type-4 handler biases tile codes `+0x3800` where vs2's biases `+0x4200` — ONE byte in otherwise byte-identical routines, so ported vs2 data drew art 0x0A00 low (the freeze/reflection tiles); (b) that handler **composes its own bank word** (`ori.w #$2000` = bank 1) instead of taking the object's, so the art could never reach group C through the record path. Fix: a ported type-4 copy carrying bank 4 + vs2's bias + our 0x1000 placement shift, dispatched only to the tenant's children, plus `--strip-tiles` copying the vs2 bank-1 span `0x4EA0-0x4FBF` into group C at `+0x1000`. Maintainer playtest: all three beam variants clean incl. the ES, AND the grab lightning confirmed on both the regular grab and Circuit Scrapper — **the effect family is CLOSED** — and THREE of its four members shared one cause, the dead effect-class row 16 (maintainer A/B: hui17 no electricity, hui18 yes, and hui18 differs by exactly that repoint). Only the 214 explosion stood apart (uncopied tiles). OPEN on this build: the grab VICTIM's sprite placement glitches mid-animation (endpoints correct; per-frame victim-offset data is the suspect), the win quote, FG pacing. Gates: hui_boot (legacy masked-v2 EXACT), beam_list_type6 (now freezing BOTH games' biases for types 4/6/8), beam_anim_walk, beam_variants, audit_empty_tiles on the beam replays, audit_effect_class_rows incl. the tripwire, m3a_reproducible, gfx_layout3, hui_pairs/ex/grab/air/walk/winscreen — all PASS. Docs: `docs/game/atlas/sprite_lists.md`, `docs/game/engine_internals.md` "The sprite-list DRAWER", `docs/project/porting_sprite_lists.md` |
| **hui20 — THE BEAM DRAWS (14z-71, NOT yet frozen, awaiting playtest)** | fingerprint `40cc10b1b6ed1275cb69893393e2530ae38aef2d` | `build/hui20`. = hui17 + the two-stage beam fix, both at ZERO legacy cost. (a) **Effect-class row 16**: every secondary-object pool dispatches on the object's class byte `+0x02` through a 38-row handler table (vsavj `0x080AAC`), index-aligned 1:1 across all three sets; vsav ships rows 16/17/19/31 as STUBS where vs2/vh2 fill 16/17/19. Row 16 is the beam's — measured, our build already set class 16 on the same object at the same frames and loaded the stub (native 598 reads of `0x093460`, ours 593 of `0x080B44`). New root `0x93460:0x306:t0x9306c:f` + `[[code_ptr]]`. (b) **Drawer list-type 6 takeover**: the beam's sprite list is type 12, a composite vsav lacks; its table cannot grow (entry 0's offset IS the length) or move (`(d8,PC,Xn)`), so the port takes over vsav's UNUSED list-type 6 — 0 reads across six legacy replays vs controls of 4329/2702/2260/321 on types 2/10/0/4. **The deadness assumption is NOT load-bearing**: non-tenant lists fall through to vsav's original type-6 code and arm a `$FF010C` tripwire that fails a gate. Legacy inventory identical to baseline run-for-run; `test_hui_boot.sh` masked-v2 EXACT. Gates: beam_anim_walk (flipped to `walks`), beam_list_type6, beam_variants, audit_effect_class_rows, m3a_reproducible, gfx_layout3, hui_pairs/ex/grab/air/walk/winscreen, audit_empty_tiles — all PASS |
| **hui17 — + the 214+P GROUND EXPLOSION (PING #13, 14z-70f, MAINTAINER-CONFIRMED)** | fingerprint `699de9b7ed40e4662f1943b7baaf606082d29dcf` (program unchanged from hui15/16 — the fix is gfx-only, as the shadow fix was) | `build/hui17`. = hui14 + (a) the x088512 root grown 0x3B40 -> 0x3B98 with a RAW tail from +0x3B78, repairing three pc-rel tables that resolved into the ANIM region — a REAL latent repair that is behaviourally inert today (the code that reads them never runs); (b) `extra_tiles/0x10.json` 2 -> **569 tiles**, fixing the grenade's ground detonation, which drew a solid FUCHSIA rectangle because its codes were remapped bank 3->4 but the tiles were never copied. Reproduce ONLY with `tests/replays/hui/83d_hui_grenade_ground.rpl` — 214+**LP** with both fighters walked to their corners; every earlier rig fired MP from start distance, so the bomb hit the OPPONENT and the capture showed the on-contact explosion instead. Gates: gfx_layout3, hui_boot (legacy masked-v2 EXACT), hui_winscreen, pairs, ex, grab, air, walk, audit_empty_tiles, m3a_reproducible — all PASS |
| **hui14 — + the DARK FORCE PALETTE (14z-69p, NOT yet frozen)** | fingerprint `c25b3824a82bcf482069bbd14291078cbf8abbbd` | `build/hui14`. = hui13 + one `[[data_port]]` row: palette-seq rows 0x1E-0x21 (vsavj `0x39ACC0`) replaced with the sequence native's DF actually shows (vs2 `0x3ABEDC`, vh2 twin `0x38BEB0`). He now flashes his own warm gold instead of purple; the afterimages stay by design. Legacy-inert because vanilla never requests those ids — guarded by `tests/audit_palette_seq_ids.sh` (10,504 sampled calls, only 0x26/0x27), which is the ONLY guard since the palette path never transits work RAM. Gate `test_hui_df_style.sh` now defaults to `--expect colours-fixed` |
| **hui13 — + the CHILD SHADOW FIX (14z-69o, playtest-confirmed)** | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` (same as hui12 — the fix is gfx-only, the program is unchanged) | `build/hui13`. = hui12 + two tiles (`0x0F8B`, `0x0F8C`) added to the group-C copy inventory via the new per-tenant `build/manifest/extra_tiles/<char>.json`. The child sidekick's shadow CORE resolved to an EMPTY group-C tile and rendered as a solid rectangle; the tiles are referenced by records the `obj_records.py` pointer walk never reaches, so they were never copied. Verified: 0 empty-tile draws over replay 82 (was 2), both tiles byte-identical to vs2, and a pixel A/B at f3500 shows the rectangle become native's tapered shadow (159 px changed, bbox x139-186 y184-199). Gates: gfx_layout3, boot, m3a-reproducible, pairs, ex, grab, air, walk, winscreen, wide_render_content — all PASS |
| **hui12 — the pc-rel TABLE FIX (14z-69i, NOT yet frozen, not yet playtested)** | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` | `build/hui12`. = hui11 + region `x06cac0` forced to its declared 0xEBC (`:f0xca8`) so the row-8 machine's seven pc-rel DATA TABLES sit inside it, with the tail EMITTED RAW (CPS-2 decrypts opcode fetches only, so a data read returns the stored bytes). All seven now read byte-identical to vs2 — they previously resolved into unrelated bytes, which was the "ported machine reads garbage" park. Legacy untouched: boot masked-v2 EXACT, m3a-reproducible bit-exact, and every H gate green (pairs, ex, grab, air, walk, fx_flow, winscreen, df_style, ladder, census). **The beam still does not draw** — measured against native at its own frames (see STATE 14z-69i), so the residual is the emitter/draw path, not the tables |
| **hui11 — PING #10 (14z-68m, NOT yet frozen)** | fingerprint `5c6dbe43e017cb4ee785ef27b63e4790bc9e0622` | `build/hui11` (pinned, PING10_ARTIFACT.md); playtest default. = hui10 + **the win screen actually fixed**: (a) PALETTE — hui10 had given H *Donovan's* set; the byte table at vs2 0x6B2F2 reads through the OPCODE view (proved by Donovan's frozen `vs2_src` 0x3C365C == pool + 0x11*0xA0), so H is row 0x0B = **0x3C329C**, a bright orange/yellow ramp matching the native capture. Self-check: each palette row's last word = 5*row (H 0x37-0x3B, Donovan 0x55-0x59). (b) POSITION — the portrait sat 64px too far LEFT and 24px too low; the per-winner table 0x5F200 row 0x10 was a plain alias (0x0080,0x0098) where vs2 has (0x00C0,0x0080). Fixed with the same slot-following `code_word` rows as Donovan's 14z-45 `win_pos`. Snapshot-verified against the maintainer's native capture. STILL OPEN: the win QUOTE text (root-caused — the fetch's `lea -4(a0,d0.w)` bias means the consumer reads index 0x60+id-1 = 0x6F while we repointed 0x70; his records are vs2 0x2A5F36/0x2A6346 via bases 0x267426/0x2674A6), plus the beam family, child-companion shadow, DF style, FG pacing. Gates: boot masked-v2 EXACT, ex, grab, air, pairs, walk, m3a, **and Donovan's own win-pal gate** — all PASS |
| **hui10 — PING #9 (14z-68 close, NOT yet frozen)** | fingerprint `64128aa7465e15378c0082afcc953aa9730744ce` | `build/hui10` (pinned, PING9_ARTIFACT.md); playtest default of `tools/run_hui_behavior.sh`. = hui9 + **the win-screen palette fix** (source re-derived from vs2's win drawer 0x6B29C: the char id is remapped through the byte table at 0x6B2F2 — read via the DATA view — giving H row 0x59, i.e. 0x3C2BBC + 0x59*0xA0 = 0x3C635C, a GOLD ramp; the old 0x3C347C was the pink/lavender guess). Verified in-emulator: win-screen palette RAM reads the gold ramp at both sample frames. Plus three behaviourally-inert shipped fixes (spawner-region boundary, two newcomer-id mask widenings, the obj_hook_extra facility). Gates at cut: boot masked-v2 EXACT, ex, grab, air, pairs, walk, fx_flow, ladder, m3a — all PASS. STILL OPEN: win-pose garbled art blocks, the beam/effect family, the child-companion shadow, DF style, FG pacing |
| **hui9 — PING #8 (14z-67 close, NOT yet frozen)** | fingerprint `9e3105e0be8a5b5c85f5c792c5c9947f49196098` | `build/hui9` (pinned, PING8_ARTIFACT.md); = hui6 + the ping-round fixes: effect byte-map rows (236P ray spawns), c5 companion-record art in bank 5 + spawner bank flips, the throw-arc superset tables (63214 launch yv 16.0 native-exact). Playtest default of `tools/run_hui_behavior.sh`. REMAINING before freeze: the effect-flow closure (NEXT_SESSION recipe), shadow restore, win-pal, DF style, FG pacing |
| hui6 — the ping-#7 reference (superseded by hui9) | fingerprint `b99b73597b7ab09761e0da58e81527db8747c7e5` | `build/hui6`; rebuild: `TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/hui6`. Huitzil at native 0x10 with HIS REAL ART end to end: fighter band at delta 0 in group C bank 4 (native codes, no record remap), select figure/portrait/name, 21-cell wheel, VS splash, HUD mug/plate (pool 0xBE9A/0xBE92), sprite+effect+win palettes, x05c800 escape fix. Cell 0x10 hand-pickable (replay 37: D,D,D from default). Every gate green incl. behavior battery ON this build + oracle (1741). Playtest: `tools/run_hui_behavior.sh`. FREEZE after maintainer confirmation (registry row + expectation set) |
| **donovan-m3a — THE WIDE REFERENCE (FROZEN 2026-08-06, 14z-64, maintainer-ratified)** | fingerprint `4b7d0dc7319ed6cf94a02b22938cdb18946dfddd` | `build/m5_wide` (rebuilds bit-exact from the tree); REGISTERED `-> donovan-m3a`. The M3a de-substitution complete: tenant at native 0x13 via `id_by_profile` (build with `--profile cps2-wide-v1`, no id flag), Jedah fully restored, select family + wheel from group C bank 5 with real medallion art/palettes, ring reuse, variant-id HUD/win-pal, the 14z-2 mirror-victim fix. Masked basis V2 (per-set `mask` file; staging-slot windows for rows 0x16/0x19/0x1A; vanilla logs `tests/expected/vsavj/masked-v2`). Stock twin **6c93cfa8** at `build/m5_stock` (= old ae701ffb + exactly the 2-byte mirror fix). Validate: `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="build/m5_wide/rompath;$ROMDIR" tests/run_suite.sh vsavjw` |
| donovan-m5w — superseded by donovan-m3a | fingerprint `9bac6ee378e1a5ce0674423279c357a4d2a076ec` | `build/m5_wide`; REGISTERED `-> donovan-m5w`. Rebuilt through the fixed romset pipeline (group C zero-filled; `audit_romset_identity.py` clean) + the 14z-60 select-wheel extension. Maintainer playtest confirmed with and without Donovan. Gates: `test_wide_profile.sh`, `test_mame_wide.sh`, `test_wide_render_content.sh` (3,721/3,721 frames pixel-identical to the stock track), `test_romset_identity.sh` — all PASS. Expectation set `tests/expected/donovan-m5w/`: 33 self-frozen `.sha1` + full logs, 14 authored `.masked` (`diverge` ×3, §4 v3 `window` ×4, §4 v4 `composite` ×7), 16 `.skip` — all 63 replays accounted for and **`run_suite.sh` GREEN**. Validate any WIDE build with `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="<rompath>;$ROMDIR" tests/run_suite.sh vsavjw` |
| **m5_stock (the stock twin, re-frozen 2026-08-06)** | fingerprint `6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5` | `build/m5_stock`; rebuilds bit-exact. = the former ae701ffb + EXACTLY the 2-byte mirror-victim fix (PRG:0x0B1A16, byte-attributed). Not registered — the dual-track partner and the rendering gate's reference. Full battery GREEN at freeze |
| ~~m5w~~ **KNOWN-BAD, kept as evidence** | `ac52eeff` | the 14z-60y sprite garble: its `vsavjw.zip` carries group C as byte copies of group B, so the loader served pristine tiles for the patched group B. Do not playtest. `python3 tools/audit_romset_identity.py build/m5w/rompath` names all four shadows |
| null vsavj | `12fbb0e1a137a1420824856d3efb0af8fff57be6` | == reference members; zip repacked deterministically |
| **donovan-m2c (M2b+ASSETS FROZEN 2026-08-02)** | fingerprint `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` | `tools/build_donovan.sh 6 build/donovan6`; REGISTERED `-> donovan-m2c`; the 14z-42..49 arc on top of M2b-CORE: LS hit-freeze thunks, full ES chain + meter decode, win screen, deity seq-states, accent owner-link fallback, HC motion farm_ports, HUD mugshot/name, select medallion; masked legacy basis = THREE windows (palette staging slot $FF4182-$FF41A1 ratified round 64; audit `tests/audit_mask_window_ff4182.sh`); gates: full battery GREEN (battery_49b) + `run_suite.sh` GREEN by fingerprint auto-detection; maintainer-confirmed rounds 52-64; gfx member sha1s in registry note |
| **donovan-m2b-core (M2b-CORE FROZEN 2026-07-28)** | fingerprint `71601263474dfd7e4afd0741dae696cde22eda4e` | `tools/build_donovan.sh 6 build/donovan6`; REGISTERED `-> donovan-m2b`; sprites/palettes/effects in Jedah's gfx space; rompath carries patched vsav.zip (gfx sha1s in registry note); gates: tests/test_m2b_stage6.sh + oracle/xemu/flavor + tests/test_m2b_scroll3.sh — ALL PASS; select portrait/name/mugshot + attract palette remain (docs/game/engine_internals.md) |
| **donovan-m2 (M2a FROZEN 2026-07-28)** | fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa` | `tools/build_donovan.sh 5 build/donovan5`; all gates green (4 guarded soaks incl. ES-DP spam, round-2, input-chaos / 13-replay masked legacy / oracle / xemu / flavor); supersedes eda50a18 (214P/214K music: engine_data-masquerade farm rows + direct helper stubbed; farm-ref audit clean — 25 stubbed / 4 live); REGISTERED: `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv; validate any build with `ROMDIR=... [MAME_ROMPATH="<rompath>;$ROMDIR"] tests/run_suite.sh` (fingerprint auto-detects the expectation set; masked legacy basis applied automatically) |

## M1 additions (2026-07-25, session 2)

| Piece | Where |
|---|---|
| Replay format + MAME runner | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` |
| FBNeo harness (patched frontend) | `emu/fbneo-patches/0001-…`, `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` |
| Legacy suite (10 replays, frozen) | `tests/run_suite.sh`, `tests/expected/vsavj/` |
| Watchpoint write-tracer | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`) |
| Pick probe (slot mapping) | `tools/pick_probe.sh` |
| Forced-id boot probe (14z-65) | `tools/force_pick_probe.sh <rompath> <id> <out>` — pokes the commit field across commit->load; verdicts id-hold/load/guard. Validated: vanilla ids load, variant 0x10 wedges on the stage-4 ladder |
| Structural diff | `tools/diff_sets.py` (`--mask-pointers`) |
| Character tables atlas | `docs/game/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) |
| RAM atlas | `docs/game/atlas/ram.md` |
| M1 acceptance review | `docs/project/M1_acceptance.md` (both clauses met; R2 quantified) |
| Write/read tracer | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) |
| Program patcher | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` |
| M2 feasibility | `docs/project/M2_feasibility.md` (3 domains; remaining work list) |
| Patch-tooling test | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) |
| M2 repoint proof | `tests/test_m2_repoint.sh` (mechanism + superset invariant) |
| Select wheel + id space (14z-60) | `tools/select_wheel.py` (decode/verify TABLE A+B, generate a full-coverage walk), `tools/check_wheel_walk.py` (measured vs predicted), `tools/audit_id_space.py` (id width at every consumer + the variant-row alias matrix), `tools/wheel_positions.py` (cell -> screen position, measured from the palette-0x1E cursor ring in OBJ RAM); atlas `docs/game/atlas/select_screen.md`, `docs/game/atlas/id_space.md` |

Run a patched build: `MAME_ROMPATH="<packed_dir>;$ROMDIR" tools/run_mame.sh vsavj ...`


## M2a port pipeline (2026-07-25, sessions 4-6) — how to build/debug Donovan

```sh
export ROMDIR=/path/to/reference/sets
# full chain: audit -> extract (vhunt2 oracle) -> generate -> patch -> pack
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan
# run it (guarded: exception breakpoints + register dump at fault)
MAME_ROMPATH="$PWD/build/donovan/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavj tests/replays/12_donovan_vs_cpu.rpl out.log box
```

Stages: 1 null-relocation scaffolding, 2 passive data, 3 anim + sprite
sub-tables, 4 code + support zones + engine hooks, 5 select plumbing.
Stage gates: `tests/test_m2a_stage{1,2,3}*.sh` (all PASS).

| Piece | Where | Role |
|---|---|---|
| Extractor | `tools/extract_char.py` | vsav2→vsavj extraction, **vhunt2 as correctness oracle**: every cross-sibling diff byte must classify as a pointer field under a measured shift. Handles: transitive closure, auto-discovered region shifts, extra roots (`addr:len[:tTWIN[:d]|:s]`), segmented gap-tolerant diff, self-pointer regions, PC-relative word tables, **bare-long sibling veto in source-only zones** (operand pairs masquerading as pointers — GOTCHAS) |
| Ref scanner | `tools/scan_code_refs.py` | 68k operand triage (abs.l after known opcodes, bare longs, char-id immediates) |
| R1 resolver | `tools/reconcile_batch.py` | batch vsav2→vsavj engine mapping: pattern ladder, stub-deref, call-site anchoring, code/data byte match, farm-param matching |
| Single lookup | `tools/find_equiv.py` | one wildcarded pattern search (validated at 1.00 on the known loader) |
| Generator | `tools/gen_donovan_patch.py` | staged op-list: hole allocator + layout groups + near_map, pointer/pcrel rewriting, bank repoints (0x0F **and** 0x1F), engine hooks, alloc wrappers, tripwires |
| Driver | `tools/build_donovan.sh` | the whole chain; `EXTRA_ROOTS` / `GEN_FLAGS` override |
| Manifests | `build/manifest/{bank_map,donovan,reconciliation}.toml` | table map / port config (holes, groups, hooks, patches) / R1 map |

**Debug env** (all on `run_replay_guarded.sh`): `GUARD_DEBUG=0` cheap mode
(canonical checksums), `GUARD_TRACE=a-b` instruction trace,
`GUARD_PC_LOG=a-b` per-frame PC, `GUARD_BREAK=hexaddr` break+report,
`GUARD_MATCH=a-b` in-match flag watch, `GUARD_PROBE=hexaddr`
[+`GUARD_PROBE_COND=expr`] conditional LOGGING breakpoint (PROBE lines:
regs + (SP); run continues — how the session-7 corruption was caught).
Faults log `CRASH` + `REGS` + `STACK` lines and dump work RAM.
`MASK_RANGES="043c-043d,7f00-8000"` on replay.lua = live-state comparison
(dead-stack + QSound-latch windows excluded; docs/GOTCHAS.md); unset =
canonical whole-RAM checksums, bit-identical to frozen expectations.

**Ground truth for behavior**: native Donovan on vsav2 — pick with cursor
**R×2** from the default select position.

## M2a C0 additions (2026-07-25, session 4) — verification harness upgrade

| Piece | Where |
|---|---|
| Crash guard | `tests/lua/replay_guard.lua` + `tools/run_replay_guarded.sh` (`GUARD_DEBUG=0` for cheap/checksum-canonical mode; `-debug` mode for breakpoint crash capture — its checksums are NOT comparable to non-debug runs, docs/GOTCHAS.md) |
| Crash-guard ground truth | `tests/test_crash_guard.sh` (clean negative + vec4/vec3 positive controls) |
| Dual-emulator field comparator | `tools/compare_fields.py` + `tests/fields_m2a.tsv` (debounced anchors; stable/settled/phase field classes; `--exact` for same-emulator) |
| Comparator ground truth | `tests/test_compare_fields_selfcheck.sh` (§4 protocol exercised: MAME/FBNeo agree on `16_xemu_2p`, 1-frame skew) |
| Dual-emulator-safe replay template | `tests/replays/16_xemu_2p.rpl` (authoring rules in docs/GOTCHAS.md — vs-CPU replays have emulator-divergent content!) |
| Slot-0x0F pick replay | `tests/replays/11_pick_donovan.rpl` (Jedah on vanilla; per-build expectations via fingerprint dispatch) |
| Auto-detecting suite runner | `tests/run_suite.sh` — `MAME_ROMPATH` fronting, fingerprint → `tests/expected/<expset>/`, `.diverge` expectation kind (exact-frame divergence vs frozen full logs under `expected/<set>/logs/`) |
| Fingerprint / registry | `tools/build_fingerprint.py`, `tests/expected/registry.tsv` (rows only at freeze time, STATE.md decision) |
| Diverge checker | `tools/check_diverge.py` |
| Flicker comparator (hooked-build legacy gate v2) | `tools/compare_flicker.py` + ground truth `tests/test_compare_flicker.sh`; frozen masked vanilla logs `tests/expected/vsavj/masked/` |
| Dispatch ground truth | `tests/test_suite_dispatch.sh` (no emulator; fast) |
| FBNeo runner extensions | `tools/run_replay_fbneo.sh`: `FBNEO_DUMPS` (-hdump), `FBNEO_ROMPATH` zip overlay — **verified to load CRC-changed patched zips** |

## Key findings so far

- vsavj key/range: master `0xfa8f4e33a4b881b9`, encrypted range
  `PRG:0x000000-0x100000` (first 1MB only; the other 3MB of program ROM is
  never opcode-encrypted). Watchdog instruction: `cmpi.l #$726A4BAF, D0`.
- ROM file byte order vs 68k logical order trap: docs/GOTCHAS.md first entry.
- MAME 0.288 `-verifyroms` passes all four sets with `-rompath` pointed at
  `$ROMDIR`; `qsound_hle.zip` and the copied `vhunt2.key` resolved the audit.
