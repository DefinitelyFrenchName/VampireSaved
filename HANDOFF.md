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
**`docs/cps2_wide.md`** (read it before touching any of this).

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
the member's REAL CRC in the descriptor, and `$400000-$40000F` reserved
(CpsFrg registers, now read-shadowed by ROM).

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

**Step-by-step Windows/WSL2 (and Linux) setup: `docs/WSL2_SETUP.md`** —
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
                                      # id_by_profile until M3a completes). ~1s
tests/test_tenant_select_records.sh   # M3a select-records mechanism (14z-62): a
                                      # variant-id build carries the tenant's OWN six
                                      # select records (space-model allocations, six
                                      # array rows poked) and the host's select-family
                                      # program bytes are VANILLA. Static re-derivation
                                      # + verdict-logic negative controls + the engine's
                                      # own row fetch onto cell 0x13 (replay 36, WIDE
                                      # MAME). Self-builds at 0x13 unless given a build
tests/test_compare_composite.sh       # ground truth for the §4 v4 composite class
                                      # (frozen flicker inventory + frozen bounded
                                      # windows, RATIFIED 2026-08-06): 7 synthetic
                                      # cases + a no-loophole check. No emulator.
                                      # donovan-m5w freezes 7 replays in this class
tests/test_romset_identity.sh         # ground truth for tools/audit_romset_identity.py:
                                      # no member may carry the PRISTINE bytes of a member
                                      # the build patched (both emulators resolve a ROM
                                      # entry by hash before name, so such a member
                                      # silently reverts the patch — 14z-60z). 4 synthetic
                                      # sets, no emulator, ~1s
tests/test_wide_render_content.sh     # the WIDE track must RENDER ported content exactly
                                      # as the stock track does: member identity + per-frame
                                      # framebuffer A/B on a Donovan replay + a POSITIVE
                                      # CONTROL (a set poisoned back into the 14z-60z shape
                                      # must fail) + the decoded tile band with a pristine
                                      # negative control. ~60s. This is the gate whose
                                      # absence let the sprite garble reach a playtest
```

Diagnostic instruments added with that gate (MAME Lua, all rerunnable):
`tests/lua/snapshot_frames.lua` (real PNG snapshots headlessly — MAME
renders its bitmap internally even under `-video none`, so `video:snapshot()`
works and the screen can be LOOKED at in-loop), `tests/lua/obj_records_dump.lua`
(the live sprite list with the composed 18/19-bit tile address per entry),
`tests/lua/gfx_region_dump.lua` (decoded tile bytes at a TILE index —
compose the bank bits first, see GOTCHAS).

All tests are self-contained, take state only via env/args, print PASS/FAIL,
and exit nonzero on failure. Every dev-time in-emulator probe must land here
before session end (persistent suite doctrine, CLAUDE.md §4).

## Build registry

| Build | SHA-1 (zip) | Notes |
|---|---|---|
| **donovan-m5w — THE WIDE REFERENCE (FROZEN 2026-08-05, 14z-61)** | fingerprint `9bac6ee378e1a5ce0674423279c357a4d2a076ec` | `build/m5_wide`; REGISTERED `-> donovan-m5w`. Rebuilt through the fixed romset pipeline (group C zero-filled; `audit_romset_identity.py` clean) + the 14z-60 select-wheel extension. Maintainer playtest confirmed with and without Donovan. Gates: `test_wide_profile.sh`, `test_mame_wide.sh`, `test_wide_render_content.sh` (3,721/3,721 frames pixel-identical to the stock track), `test_romset_identity.sh` — all PASS. Expectation set `tests/expected/donovan-m5w/`: 33 self-frozen `.sha1` + full logs, 14 authored `.masked` (`diverge` ×3, §4 v3 `window` ×4, §4 v4 `composite` ×7), 16 `.skip` — all 63 replays accounted for and **`run_suite.sh` GREEN**. Validate any WIDE build with `ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 MAME_ROMPATH="<rompath>;$ROMDIR" tests/run_suite.sh vsavjw` |
| **m5_stock (the stock twin, 2026-08-05)** | fingerprint `ae701ffb06d0cbf3462cad1a9faa47534a3c00e4` | `build/m5_stock`; the rebuild reproduces this fingerprint exactly. Not registered — it is the dual-track partner and the rendering gate's reference |
| ~~m5w~~ **KNOWN-BAD, kept as evidence** | `ac52eeff` | the 14z-60y sprite garble: its `vsavjw.zip` carries group C as byte copies of group B, so the loader served pristine tiles for the patched group B. Do not playtest. `python3 tools/audit_romset_identity.py build/m5w/rompath` names all four shadows |
| null vsavj | `12fbb0e1a137a1420824856d3efb0af8fff57be6` | == reference members; zip repacked deterministically |
| **donovan-m2c (M2b+ASSETS FROZEN 2026-08-02)** | fingerprint `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` | `tools/build_donovan.sh 6 build/donovan6`; REGISTERED `-> donovan-m2c`; the 14z-42..49 arc on top of M2b-CORE: LS hit-freeze thunks, full ES chain + meter decode, win screen, deity seq-states, accent owner-link fallback, HC motion farm_ports, HUD mugshot/name, select medallion; masked legacy basis = THREE windows (palette staging slot $FF4182-$FF41A1 ratified round 64; audit `tests/audit_mask_window_ff4182.sh`); gates: full battery GREEN (battery_49b) + `run_suite.sh` GREEN by fingerprint auto-detection; maintainer-confirmed rounds 52-64; gfx member sha1s in registry note |
| **donovan-m2b-core (M2b-CORE FROZEN 2026-07-28)** | fingerprint `71601263474dfd7e4afd0741dae696cde22eda4e` | `tools/build_donovan.sh 6 build/donovan6`; REGISTERED `-> donovan-m2b`; sprites/palettes/effects in Jedah's gfx space; rompath carries patched vsav.zip (gfx sha1s in registry note); gates: tests/test_m2b_stage6.sh + oracle/xemu/flavor + tests/test_m2b_scroll3.sh — ALL PASS; select portrait/name/mugshot + attract palette remain (docs/engine_internals.md) |
| **donovan-m2 (M2a FROZEN 2026-07-28)** | fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa` | `tools/build_donovan.sh 5 build/donovan5`; all gates green (4 guarded soaks incl. ES-DP spam, round-2, input-chaos / 13-replay masked legacy / oracle / xemu / flavor); supersedes eda50a18 (214P/214K music: engine_data-masquerade farm rows + direct helper stubbed; farm-ref audit clean — 25 stubbed / 4 live); REGISTERED: `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv; validate any build with `ROMDIR=... [MAME_ROMPATH="<rompath>;$ROMDIR"] tests/run_suite.sh` (fingerprint auto-detects the expectation set; masked legacy basis applied automatically) |

## M1 additions (2026-07-25, session 2)

| Piece | Where |
|---|---|
| Replay format + MAME runner | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` |
| FBNeo harness (patched frontend) | `emu/fbneo-patches/0001-…`, `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` |
| Legacy suite (10 replays, frozen) | `tests/run_suite.sh`, `tests/expected/vsavj/` |
| Watchpoint write-tracer | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`) |
| Pick probe (slot mapping) | `tools/pick_probe.sh` |
| Structural diff | `tools/diff_sets.py` (`--mask-pointers`) |
| Character tables atlas | `docs/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) |
| RAM atlas | `docs/atlas/ram.md` |
| M1 acceptance review | `docs/M1_acceptance.md` (both clauses met; R2 quantified) |
| Write/read tracer | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) |
| Program patcher | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` |
| M2 feasibility | `docs/M2_feasibility.md` (3 domains; remaining work list) |
| Patch-tooling test | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) |
| M2 repoint proof | `tests/test_m2_repoint.sh` (mechanism + superset invariant) |
| Select wheel + id space (14z-60) | `tools/select_wheel.py` (decode/verify TABLE A+B, generate a full-coverage walk), `tools/check_wheel_walk.py` (measured vs predicted), `tools/audit_id_space.py` (id width at every consumer + the variant-row alias matrix), `tools/wheel_positions.py` (cell -> screen position, measured from the palette-0x1E cursor ring in OBJ RAM); atlas `docs/atlas/select_screen.md`, `docs/atlas/id_space.md` |

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
