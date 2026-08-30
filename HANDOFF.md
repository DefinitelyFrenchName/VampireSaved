# HANDOFF — operational map

First read of any session after CLAUDE.md and STATE.md. Keep current in the
same commit as anything it describes. (Since 2026-08-20 STATE.md holds only
the recent session groups + a ledger; the full session archive is
`STATE_HISTORY.md` — "STATE 14z-XX" references resolve there when the
session has rolled off.)

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
**[CPE-32]** | FBNeo | `emu/fbneo` submodule + `tools/setup_fbneo.sh` | built (SDL2); TWO patches: `0001` harness (frontend-only: `-hinput/-hout/-hframes/-hdump`, plus `FBNEO_HVIDEO` framebuffer checksums, `FBNEO_HGFX` gfx-buffer dumps, and the B5b set — `FBNEO_HTAP` write tap with PC attribution, `FBNEO_HPOKE` frame-scheduled pokes, address-resolved dumps reaching OBJ/palette RAM) and `0002` the CPS-2 WIDE profile (driver descriptor + TWO gated blocks in `Cps2ObjDraw` — the promote and the canary control; "one gated core line" until 14z-114, corrected per 14z-90). **CRC WARNING:** FBNeo matches zip members by CRC — a mismatched gfx/QSound member is silently replaced by 0xFF fill while still logging `(OK)` (docs/GOTCHAS.md) |
| `tools/freeze_masked_basis.sh` (from the gate fence, 14z-123) | 14z-88: (re)generate a vanilla masked basis (logs+sha1, double-run determinism) under a given MASK_RANGES — masked bytes are SKIPPED from the checksum, so every window addition needs a NEW basis dir (masked / masked-v2 / masked-v3) | live |
| `tools/audit_walker_callers.py` (from the gate fence, 14z-123) | 14z-91: every reference that can reach a walker, enumerated BY FORM (abs.l operand / data longword / pc-relative / branch). Found 23 jsr.l and nothing else. Prints decode noise with context rather than filtering it silently. --toml emits the frozen manifest rows | live |
| `tools/probe_hook_removal.sh` (from the gate fence, 14z-123) | 14z-89: CAUSAL attribution for a legacy-cycle regression — rebuild a tenant with named hooks REMOVED and re-measure a legacy replay against the vanilla basis. The probe is not shippable (the tenant loses a feature) and does not need to be: the legacy replay never touches the tenant. Named both 14z-89 root causes after dump diffs stalled at "extra cycles somewhere": 38 <- fixture_row0f_override_bank0/1 (two cmpi.b at venue fixture-load sites LEGACY runs every venue load), 24 <- the two [[obj_hook]] table extensions. Control in the header: the unmodified build must still FAIL the same replay. ~5 min per probe | live |
| `tools/artifact_manifest.py` (from the gate fence, 14z-123) | 14z-90 (issue #8): per-member SHA-1 of every packed zip in a rompath dir. The program fingerprint covers 8.1% of the shipped bytes; this covers all of it. Refuses a ';' rompath chain (that would fold $ROMDIR into the digest) and is timestamp-free by construction. Wired into test_m3a_reproducible.sh: HARD on member inventory, ADVISORY on member content until the legacy re-freeze | live |
| Replay format + MAME runner (M1/M2a, 2026-07-25) | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` | live (paths checked 14z-123) |
| FBNeo harness (patched frontend) (M1/M2a, 2026-07-25) | `emu/fbneo-patches/0001-vampire-saved-harness.patch` (+ `0002-cps2-wide-v1.patch`), `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` | live (paths checked 14z-123) |
| Legacy suite (10 replays, frozen) (M1/M2a, 2026-07-25) | `tests/run_suite.sh`, `tests/expected/vsavj/` | live (paths checked 14z-123) |
| Watchpoint write-tracer (M1/M2a, 2026-07-25) | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`; `WATCH=addr,len[,r\|w\|rw\|b][,p\|d\|o]`, + `DUMPS` since 14z-98 so a -debug trace run carries its OWN state anchors — every -debug watch configuration is its own timeline, docs/GOTCHAS.md) | live (paths checked 14z-123) |
| Pick probe (slot mapping) (M1/M2a, 2026-07-25) | `tools/pick_probe.sh` | live (paths checked 14z-123) |
| Forced-id boot probe (14z-65) (M1/M2a, 2026-07-25) | `tools/force_pick_probe.sh <rompath> <id> <out>` — pokes the commit field across commit->load; verdicts id-hold/load/guard. Validated: vanilla ids load, variant 0x10 wedges on the stage-4 ladder | live (paths checked 14z-123) |
| Structural diff (M1/M2a, 2026-07-25) | `tools/diff_sets.py` (`--mask-pointers`) | live (paths checked 14z-123) |
| Character tables atlas (M1/M2a, 2026-07-25) | `docs/game/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) | live (paths checked 14z-123) |
| RAM atlas (M1/M2a, 2026-07-25) | `docs/game/atlas/ram.md` | live (paths checked 14z-123) |
| M1 acceptance review (M1/M2a, 2026-07-25) | `docs/project/M1_acceptance.md` (both clauses met; R2 quantified) | live (paths checked 14z-123) |
| Write/read tracer (M1/M2a, 2026-07-25) | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) | live (paths checked 14z-123) |
| Program patcher (M1/M2a, 2026-07-25) | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` | live (paths checked 14z-123) |
| M2 feasibility (M1/M2a, 2026-07-25) | `docs/project/M2_feasibility.md` (3 domains; remaining work list) | live (paths checked 14z-123) |
| Patch-tooling test (M1/M2a, 2026-07-25) | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) | live (paths checked 14z-123) |
| M2 repoint proof (M1/M2a, 2026-07-25) | `tests/test_m2_repoint.sh` (mechanism + superset invariant) | live (paths checked 14z-123) |
| Select wheel + id space (14z-60) (M1/M2a, 2026-07-25) | `tools/select_wheel.py` (decode/verify TABLE A+B, generate a full-coverage walk), `tools/check_wheel_walk.py` (measured vs predicted), `tools/audit_id_space.py` (id width at every consumer + the variant-row alias matrix), `tools/wheel_positions.py` (cell -> screen position, measured from the palette-0x1E cursor ring in OBJ RAM); atlas `docs/game/atlas/select_screen.md`, `docs/game/atlas/id_space.md` | live (paths checked 14z-123) |
| Crash guard (M1/M2a, 2026-07-25) | `tests/lua/replay_guard.lua` + `tools/run_replay_guarded.sh` (`GUARD_DEBUG=0` for cheap/checksum-canonical mode; `-debug` mode for breakpoint crash capture — its checksums are NOT comparable to non-debug runs, docs/GOTCHAS.md) | live (paths checked 14z-123) |
| Crash-guard ground truth (M1/M2a, 2026-07-25) | `tests/test_crash_guard.sh` (clean negative + vec4/vec3 positive controls) | live (paths checked 14z-123) |
| Dual-emulator field comparator (M1/M2a, 2026-07-25) | `tools/compare_fields.py` + `tests/fields_m2a.tsv` (debounced anchors; stable/settled/phase field classes; `--exact` for same-emulator) | live (paths checked 14z-123) |
| Comparator ground truth (M1/M2a, 2026-07-25) | `tests/test_compare_fields_selfcheck.sh` (§4 protocol exercised: MAME/FBNeo agree on `16_xemu_2p`, 1-frame skew) | live (paths checked 14z-123) |
| Dump-set completeness (M1/M2a, 2026-07-25) | `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS, so a lost dump silently moves the anchor instead of failing. Asserts a per-frame dump directory is complete: `--first/--last`, `--size`, `--addr`, or `--contiguous` for a directory of unknown extent. Run by `tools/run_sim_jtcps2.sh` on every `--wram` run and by `test_mister_sim_anchor` on BOTH legs (14z-107 (7)) | live (paths checked 14z-123) |
| Dual-emulator-safe replay template (M1/M2a, 2026-07-25) | `tests/replays/16_xemu_2p.rpl` (authoring rules in docs/GOTCHAS.md — vs-CPU replays have emulator-divergent content!) | live (paths checked 14z-123) |
| Slot-0x0F pick replay (M1/M2a, 2026-07-25) | `tests/replays/11_pick_donovan.rpl` (Jedah on vanilla; per-build expectations via fingerprint dispatch) | live (paths checked 14z-123) |
| Auto-detecting suite runner (M1/M2a, 2026-07-25) | `tests/run_suite.sh` — `MAME_ROMPATH` fronting, fingerprint → `tests/expected/<expset>/`, `.diverge` expectation kind (exact-frame divergence vs frozen full logs under `expected/<set>/logs/`) | live (paths checked 14z-123) |
| Fingerprint / registry (M1/M2a, 2026-07-25) | `tools/build_fingerprint.py`, `tests/expected/registry.tsv` (rows only at freeze time, STATE.md decision) | live (paths checked 14z-123) |
| Diverge checker (M1/M2a, 2026-07-25) | `tools/check_diverge.py` | live (paths checked 14z-123) |
| Flicker comparator (hooked-build legacy gate v2) (M1/M2a, 2026-07-25) | `tools/compare_flicker.py` + ground truth `tests/test_compare_flicker.sh`; frozen masked vanilla logs `tests/expected/vsavj/masked/` | live (paths checked 14z-123) |
| Dispatch ground truth (M1/M2a, 2026-07-25) | `tests/test_suite_dispatch.sh` (no emulator; fast) | live (paths checked 14z-123) |
| FBNeo runner extensions (M1/M2a, 2026-07-25) | `tools/run_replay_fbneo.sh`: `FBNEO_DUMPS` (-hdump), `FBNEO_ROMPATH` zip overlay — **verified to load CRC-changed patched zips** | live (paths checked 14z-123) |

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
Emulator cost: **two gated blocks** in `cps_obj.cpp` (the promote + the
`CPS2_WIDE_CANARY` positive control; this line said "one widened
condition" until 14z-114 — the 14z-90 correction is in `cps2_wide.md`
"Emulator change budget") plus the `Cps2Wide` flag lifecycle. Everything
else is descriptor table data.
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

**[CPE-24]** **Order is not optional.** `test_mame_parity.sh` proves the UNPATCHED
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

## RELEASE PACKAGING (14z-105) — `release/<name>/`, no ROM bytes

`tools/package_release.py <rompath> <out> --romdir $ROMDIR --name merged-m6
--version M6` turns a frozen build's two zips into a distributable package:
xdelta3 deltas per modified/new member against ONE source blob (the four
reference dumps' members concatenated in a fixed order — so a new WIDE
member is expressed as copies out of vsav2/vhunt2 and only the bytes the
port GENERATES or AUTHORS are literal), `manifest.json` (every target
member's sha1/size, which members are copied pristine and from where, the
source recipe + sha1, the fingerprint, the version string), the community
applier `apply_release.py` (pure python + xdelta3; verifies every reference
member, rebuilds the source blob, applies, and refuses to write unless
EVERY member's sha1 matches), and a README. Secondary compression is OFF so
the rule-7 scan sees the payload. **Deterministic** (two runs byte-identical).
**`release/merged-m6/`** is the shipped package for the 14z-105 freeze
(20 patched + 22 pristine members, 2.5 MB, fingerprint 64426955).
**Gate: `tests/test_release_roundtrip.sh`** (ci_static) — package -> apply to
pristine dumps -> all 42 members byte-identical + fingerprint + whole-
artifact manifest; the applier refuses a corrupted patch / wrong target
sha1 / one-bit-wrong dump WITHOUT writing; rule 7: no 64-byte-aligned
reference-ROM chunk appears verbatim anywhere in the patches (rolling scan,
must-fire control). Needs `xdelta3` (`brew install xdelta`).
MiSTer later adds a DISTRIBUTION layer (MRA/core) over the SAME members —
the patch artifact does not change shape for it.

**[VSP-100]** **SINCE merged-m10 (14z-113, maintainer-ruled 2026-08-28) A RELEASE IS ONE
DIRECTORY PER PLATFORM, EACH SELF-SUFFICIENT** — `release/<name>/{fbneo,
mame,mister}/`, the patch set above COPIED into each (produced by the same
`package_release.py`, manifests asserted identical), `emulator/0002-*.patch`
+ `EMULATOR.md` (pin + recipe, never a binary) on the emulator side, the
`.mra` files + `jtcps2w.rbf` + `BITSTREAM.txt` + `MISTER.md` on the MiSTer
side; every version releases every platform even if only one changed.
**The bitstream is a BUILD RESOURCE: canonical at
`release/bitstreams/<seed>/{jtcps2w.rbf, BITSTREAM.txt}`, `CURRENT` names
the seed (18269 today), the packager hash-verifies it into every release
and refuses a mismatch — a new bitstream is a new seed dir + a `CURRENT`
bump, never an overwrite and never a copy from another release.** Producer:
`ROMDIR=... python3 tools/package_release_platforms.py build/<dir>/rompath
release --name <name> --version <mark> --mister-src <dir with the .mra
files> [--bitstream release/bitstreams/<seed>]`. Spec: `docs/project/release_format.md`. Gate: section 4 of
`test_release_roundtrip.sh` (layout + no cross-platform leakage + a
must-fire control). `release/merged-m6..m9/` keep the old single-package
layout as history.

## MiSTer (14z-106/107) — the jtcps2w core + the simulation oracle

**THE MiSTer SKILLS (14z-114): load `mister-cps2-wide-core` (level 1,
game-independent) and `mister-vampire-saved` (level 2, this romset) before
any MiSTer work — they are the distilled discipline, ID-locked to the docs by
`tests/test_checkskills.sh`; the field test and triage live in-tree at
`docs/project/mister_field.md`.** **Read `docs/project/mister_core.md` FIRST** — the synthesis: what is TRUE
about this core, in CAUSAL order, with the logs it quotes named as its
provenance (`mister_fit.md`, `mister_map.md`, `docs/platform/mister.md`), and
the standing rule that where it and one of them disagree, THE LOG WINS. Its
diagrams are drawn by `tools/mk_mister_page.py` — a committed GENERATOR whose
`--check` mode re-derives every figure in the document (17 of them) from the
same constants the gates freeze, so the page cannot go stale silently; the
rendered page is never committed. Then `docs/platform/mister.md` for the
platform detail. The deliverable is a SEPARATE core
`jtcps2w` in a public GPL-3.0 fork of jotego/jtcores
(https://github.com/DefinitelyFrenchName/jtcores, branch `vampire-saved`
from v1.7.3), pinned as submodule `emu/jtcores` with the delta mirrored
in `emu/jtcores-patches/` as a PATCH SERIES, one file per fork commit.
`tools/setup_jtcores.sh` checks the pin, inits the five modules the cps2
yaml chain pulls, builds jtframe's Go tool and regenerates the series;
`tests/test_jtcores_twin.sh` (ci_portable) locks pin, twin and series.
**SINCE SLICE D1 (14z-107 (6)) cps2w CARRIES RTL; D2 CARRIES THE PLACEMENT;
D3+D4 (14z-107 (10)) MAKE A TENANT FETCH POSSIBLE; AND SINCE D5 (14z-107 (11))
THE WIDE ROMSET BOOTS ON THE CORE, REACHES THE SELECT SCREEN AND FETCHES THE
TENANT WHEEL ART** — 105 distinct group-C tile codes out of obj bank 5, with
the control leg at zero, and a rendered select screen showing the extended
wheel and the authored "M6" mark
(`docs/project/images/mister_select_cps2w_f2400.jpg`, beside MAME's
`mister_select_mame_f1741.png`). **AND SINCE 14z-108 A TENANT HAS FOUGHT ON THE CORE**: with the input path
fixed, `36_pick_tenant_cell` over 4,400 frames fetches **obj bank 4 — the
FIGHTER art — 9,388,928 reads over 1,735 distinct tile codes, 843 frames of
them AFTER match start**, every code inside the frozen extent, with the
control leg at zero on both group-C windows. `test_mister_gfxc_fetch` PASSES
in full, and the same run answered bank 1 under load (peak 15,496 acc/frame,
12.5% of ceiling, ZERO clashes). **AND SINCE 14z-108 IT SYNTHESISES**: Quartus 20.1.1 Lite, Cyclone V
`5CSEBA6U23I7`, target mister, with `cps2` built FIRST as the reference leg —
`cps2w` costs **+206 ALMs (+1.1%)** and +2,048 memory bits with RAM blocks,
DSPs and PLLs unchanged — **that half is settled and good**. **TIMING IS
NOT: it is a SEED LOTTERY.** Twelve `cps2w` seeds span **-0.545 .. +0.396**, four of them
FAILING, while five `cps2` control seeds span **+0.144 .. +0.665**, none
failing. `cps2w` straddles zero; the control does not. The
FAILs are jtframe's OWN gate on runs Quartus called "successful, 0 errors".
**AND `xjtcore.sh` CALLS `jtseed 4`, WHICH RETRIES `--seed $RANDOM` AND
BREAKS ON FIRST SUCCESS.** Precisely: that does NOT ship failing bitstreams
(~99% of invocations produce a gate-passing `.rbf`) — **it hides FRAGILITY.
A green build certifies "one placement was found that closes", never "this
design closes with margin".** At n=12 `cps2w` fails **4/12** with median
**+0.038 ns** (two passes under 10 ps) against `cps2`'s **0/5**, median
**+0.431 ns**; the BEST cps2w seed is worse than the MEDIAN cps2 seed. Every failing path is
inside `jtframe_sdram64` at an SDRAM address pin and RESHUFFLES between
seeds, so what is marginal is that controller's ADDRESS-GENERATION CONE as a
whole — shared infrastructure the fork does not touch, NOT WIDE's own logic.
**Consequence: +0.066 is not headroom a future slice may assume.** Spending
margin back is a Rule 1 v2 design decision for the maintainer, not a
seed-hunt. **A FAILING SEED STILL EMITS AN `.rbf` — verify the hash before
flashing; the passing baseline is `46fc74af…`.** **RELEASE POLICY (ruled
2026-08-25): a shipped bitstream is built from a NAMED SEED — currently
**18269** — with its slack and sha256 recorded and verified, never from an
`xjtcore.sh` random draw. `jtcore cps2w -mister --nodbg --seed 18269`.** **What is still never: HARDWARE — no `.rbf` has been
loaded onto a DE10-Nano, no MRA has run on real silicon, and no analog
output has been seen. An `.rbf` existing is not a field test.** The reason
bank 4 is still zero is the HARNESS, not the RTL: the simulator's direction
bits were **REVERSED end for end** — measured in full 14z-108 against the
game's own `$FF8058` mirror, all four directions, on a four-direction probe
replay (`tests/replays/107_four_directions.rpl`): Up arrived as Right, Down as
Left, Left as Down, Right as Up. So the tenant-picking replay moved the cursor
onto Victor. **FIXED 14z-108** — one dict in `tools/rpl2siminputs.py`
(jtframe's joystick nibble is MSB-first: file bit4=Right … bit7=Up), no fork
commit and no RTL. 14z-107 (12) had seen only the Left/Down half and inferred a
two-bit swap that would have fixed half of it. See `docs/platform/mister.md`
"The simulated joystick's direction nibble is MSB-FIRST — the translator had it reversed end for end". The EIGHTEEN fork commits are `b9d0565` (the `cps2w` cfg scaffold), nine
Verilator-TESTBENCH changes (`553dd56` `JTFRAME_SIM_WRAMDUMP`, `6c32be8` the
SDRAM model's dropped top address bit, `4f25cc7` the model clock, `74ed17d`
raw SDRAM stats, `692ba4d6` the optional frame writer, `7cf1eedb` the child's
`_exit`, `519aff8b` the joystick top bits, `17a5dc2b` the SDRAM READ PROBE,
`fd454393` the frame writer's frame window), `38acc638` (**slice D0**: the
`vsavjw` machine entry in `doc/mame.xml` + the QSound trim in
`cores/cps2w/cfg/mame2mra.toml`), `4840df8a` (**slice D1**, THE FIRST RTL
COMMIT: the QSound sample-bank width, gated at RUNTIME by a spare MRA header
byte), `0df6f000` (**slice D2**: THE SDRAM PLACEMENT — the bank-0 re-pack,
the group-C GFX redirect, the QSound split across two banks, two new slot
counts, and ONE new jtframe file `hdl/sdram/jtframe_ram1_7slots.v`),
`b9899fa8` (**slice D3**: THE CPS-2 TURBO OBJECT PROMOTE — a 3-bit GFX bank,
`rom0_bank[2]` untied, four override files for one gated expression) and
`dd242a65` (**slice D4**: the 6 MB PROGRAM WINDOW — a read-only decode into
`CPU:$400000-$5FFFFF` plus the `one_wait` boundary), `72738d51` (the
SIM-ONLY 68k PROGRAM-ROM READ PROBE, 14z-107 (11) — compiled out unless
`JTCPS2W_PRGPROBE` is defined; it is what D4 and D5 are measured with) and
`c00d7ce7` (**slice D5**: THE DECRYPTION RANGE — the CPS-2 key's
encrypted-opcode range word is stored COMPLEMENTED and `jtcps2_dec_ctrl`
reads it straight, so the reference core decrypts opcode fetches to
`CPU:$F03FFF` where MAME/FBNeo stop at `$0FFFFF`; one profile-gated
expression in a new `jtcps2_decrypt.v` override, with `jtcps2_dec_ctrl`
itself untouched) and `7b9a0d2d` (a COMMENT-ONLY retraction in the
`jtcps2_main.v` override header — it still claimed the extension is not
decrypted, which D5 proved false of this core). **THE PIN IS `7b9a0d2d`.**
**`cores/cps1`,
`cores/cps2` and `cores/cps15` are still BYTE-UNTOUCHED** — that is a
`git diff` assertion (`test_jtcores_twin` 2e), the fork's WHOLE-TREE delta is
held to a declared 25 paths (2f), and the THIRTEEN files in `cores/cps2w/hdl`
are enumerated with a frozen line-by-line delta (`test_mister_wide_gate` 1).
**Fork pushes are STANDING-AUTHORISED by the maintainer (2026-08-24); the
MAIN repo's push state is NOT a standing 'never' — RE-CHECKED 14z-109 AFTER PUSHING: `origin/main` holds `10cf9ce` and NOTHING is local, confirmed by `git ls-remote`. The fork is at `c97e3d14` (the README brought to D0-D5). **The earlier 14z-109 state where one commit was held back because it bumped the pin to an unpushed fork commit is RESOLVED** — the fork was pushed first, then the pin bump. Keep the ORDER in mind if it ever recurs: pushing a pin bump ahead of the fork commit it names breaks a fresh clone's `git submodule update`. Check the remote, not this sentence; pushing remains the maintainer's call.**
The RTL benches live in **`tests/rtl/*.v`** (this repo, not the fork) and the
frozen override delta in **`tests/expect/cps2w_rtl_delta.txt`**;
`tests/test_mister_wide_gate.sh` compiles the benches against the fork's real
module sources with Verilator and skips that half cleanly when Verilator is
absent. The MiSTer edition of Rule 1 v2 — what "bounded / profile-gated /
superset / mirrored / ratified" each mean on FPGA, and which check enforces
each — is `docs/project/cps2_wide.md` "THE MiSTer EDITION OF THE SAME RULE". The stock-vsavj reference-leg MRA is
produced by `jtframe mra cps2w` (byte-identical to stock cps2's except
`<rbf>` — now gated, not just measured). The fit numbers are in
`docs/project/mister_fit.md`; the placement map is
`docs/project/mister_map.md`.

**RUNNING THE WIDE ROMSET ON THE CORE — ROOT-CAUSED 14z-107 (11), FIXED IN
SLICE D5.** The boot failure below is the state BEFORE D5; its eliminations
stand and its trace is still the best description of the symptom. **What it
did not know:** the 68k EXECUTES from the program extension (ten opcode
fetches at `CPU:$4BE7C0-$4BE7C8`, simulated frame 1119) and receives the
CPS-2 DECRYPTOR'S OUTPUT, because the key's encrypted-opcode range word is
stored COMPLEMENTED and `jtcps2_dec_ctrl` reads it straight — the reference
core decrypts to `CPU:$F03FFF` where MAME and FBNeo stop at `$0FFFFF`. Every
stock CPS-2 game hides it; CPS-2 WIDE is the first thing to put executable
content above the window. Fork commit `c00d7ce7` complements the word,
profile-gated, in `cores/cps2w/hdl/jtcps2_decrypt.v`. **One claim below is
CORRECTED IN PLACE: the two profile states are NOT frame-for-frame
identical** — profile-ON completes ten reads above `$400000` and profile-CLEAR
zero. Measurement, instruments and the byte comparison:
`docs/platform/mister.md` "CAN THE 68k READ ABOVE 4 MB?".

**THE PRE-D5 TRACE, KEPT (slices D3+D4, 14z-107 (10)).** The core carries
everything the profile needs: the object promote, the 6 MB program window, the
placement and the QSound width. **It did not BOOT the WIDE romset.** Measured on `11_pick_donovan`,
`cps2w`, the real `vsavjw.rom`: reset at simulated frame 659, the CPS-2 RAM
test draws 660-925, the QSound/Capcom legal screen stands from 1578, and at
**2242 the machine RESETS and the RAM test starts over** — a ~1,580-frame
cycle. No sprite is ever drawn (the SDRAM read probe sees ZERO reads in
vanilla obj bank 2 as well as in both group-C windows), so no tenant tile is
fetched. **The same run with the profile bit CLEAR behaves identically, frame
for frame**, so the cause is NOT any of the eight `wide_en`-gated sites — it
is shared, and it is the next thing to root-cause. `docs/platform/mister.md`
"The pre-D5 boot loop: the WIDE romset reset at core frame ~448 until the decryption range was fixed" has the full trace and the
eliminations.

    ROMDIR=... JTSIM_SCRATCH=/tmp/vampire-saved-jtsim \
      tools/run_sim_jtcps2.sh tests/replays/11_pick_donovan.rpl /tmp/out \
        --core cps2w --wide build/m3b_merged21 --frames 4000 \
        --frame-output fork --frame-window 0 999999 30 \
        --rdprobe 1 0x800000 0x1000000 --rdprobe 0 0x7E0000 0xFE0000 \
        --rdprobe 2 0 0x1000000 --rdprobe 3 0 0x1000000

**THE WIDE TRANSFER IS 659 FRAMES, NOT 462**, and every absolute frame number
in the lane moves with it — `run_sim_jtcps2.sh` picks the constant from
`--wide` and prints it, and `audit_sdram_bank_load.sh` asserts it from the
run's own log before labelling a phase.

**BUILDING THE MRAs AND THE `.rom` (slice D0, 14z-107 (5)):**

```sh
export ROMDIR=/path/to/reference/sets
tools/mister_mra.sh --core cps2w --wide build/m3b_merged21 --out /tmp/mra107   # re-pointed 14z-119 <- m3b_merged20 <- 14z-118 <- m3b_merged18 (the example figures below are the 14z-107 run's)
#   -> /tmp/mra107/vsavjw.rom  66,265,152 B  (the WIDE download image)
tools/mister_mra.sh --core cps2w --out /tmp/mra107stock   # the stock leg
#   -> /tmp/mra107stock/vsavj.rom  46,407,744 B
tools/mister_mra.sh --core cps2w --no-rom --out /tmp/mraonly   # MRAs only
```

`--wide` is not cosmetic: the WIDE romset is a CLONE set. **CORRECTED
14z-112: its parent is now the PRISTINE dump, not the build's own
`vsav.zip`.** Builds no longer pack a parent at all — the four patched
members `vm3.13m/15m/17m/19m` live INSIDE `vsavjw.zip`, so both legs share
one `vsav.zip` and a MiSTer SD card can carry this profile AND stock
Vampire Savior (before, `games/mame/vsav.zip` could only be one file and a
stock MRA got wrong art SILENTLY). `jtframe mra` still reads a hard-coded
`$HOME/.mame/roms/<name>.zip`, so the tool stages a PRIVATE `$HOME` per run.
`.rom` files are ROM content: `--out` inside the repo is refused (rule 7).
**And the MiSTer MRA is pinned to ONE romset build's CRCs** — jtframe
resolves zip members by CRC32 alone, unlike FBNeo/MAME which resolve by name
and only warn (which is why the WIDE members carry sentinel hashes there).
`tools/gen_vsavjw_xml.py <zip> --check emu/jtcores/doc/mame.xml` says whether
the fork's entry is the current build's; a rebuild that moves a CRC needs a
new fork commit.

**THE MEMORY MAP, corrected 14z-107 (2) — read this before sizing any RTL.**
The PROFILE ruling (WIDE v1 verbatim, one romset) stands; the implementation
assumption that went with it does not. **"MiSTer work = width plumbing only"
is RETRACTED.** At our pin `v1.7.3` **64 MB is PHYSICAL** (jtframe's table
stops at `AW 23`, the bank geometry has no AW=24 arm and would leave
`addr[9]` undriven, and only 13 A / 2 BA / 1 nCS pins are assigned);
`JTFRAME_SDRAM_XL` (128 MB) exists **upstream only**, 3057 commits away, as
TWO CHIPS on one module with chip select on nCS polarity, and only inside the
`JTFRAME_SDRAM_CACHE` branch — setting it on `cps2w` as it stands would
silently alias (platform gotcha). Independently, the CPS-2 core caps GFX at
32 MB in the OBJECT FORMAT, the 68k at a flat 4 MB `rom_cs`, scroll at 8 MB
and QSound at a 7-bit latch — **no SDRAM tier lifts any of those**. And the
roster's total is **~56.1 MB against a 64 MB tier**: PRG 6 MB fits bank 0
today, QSound 16 MB fits bank 1 today, only GFX overflows. **THE ROUTE IS
DECIDED (maintainer, 2026-08-23): the BANK REPACK at our pin, measuring
first; `JTFRAME_SDRAM_XL` is the FALLBACK if it fails.** The measurement the
ruling required returned **GO** the same day
(`tests/audit_sdram_bank_load.sh` — bank 1's PCM is already at a 98.8%
in-match row-miss rate, so it has no locality left to lose, and the worst
case runs at 26.3% of one bank against the 32.9% bank 0 already sustains in
stock shipping configuration), and D2 SHIPPED the repack. **Beware "how big
is the art": it has THREE sizes and this project has published a wrong figure
from two of them** — live bytes **6.39 MB**, address footprint **15.45 MB**
(a CPS-2 tile code IS its SDRAM address), declared region **16 MB** (the MRA
downloads the whole region, so each group-C obj bank reserves its full 8 MB).
The last one is what SDRAM actually spends, which is why the fit has 0.125 MB
of slack and not 0.708. Full argument with every
file:line: `docs/platform/mister.md`; the arithmetic: `mister_fit.md` §6;
the synthesis: `docs/project/mister_core.md`.

**Running the simulation lane** (14z-107; needs `brew install go coreutils
gnu-sed xmlstarlet verilator imagemagick`, ~1.0-1.2 s per simulated frame):

```sh
export ROMDIR=/path/to/reference/sets
export JTSIM_SCRATCH=/tmp/vampire-saved-jtsim   # NEVER inside the repo
tools/run_sim_jtcps2.sh tests/replays/05_timeout_idle.rpl /tmp/out107 \
    --frames 2880 --wram 2540 2880     # ~47 min; run it detached, poll the PID
#   host frame output is OFF by default (--frame-output off); `fork` is
#   upstream's behaviour and `collect` also gathers <outdir>/frames
python3 tools/compare_fields.py <mame_dumps> /tmp/out107/wram \
    --fields tests/fields_m2a.tsv --follow 0,60,180 --label-a mame --label-b jtcps2
```

**AND SINCE SLICE D2 (14z-107 (9)) THE SAME TOOL RUNS THE WIDE ROMSET AND
HANDS BACK THE SDRAM IMAGE:**

```sh
tools/run_sim_jtcps2.sh tests/replays/05_timeout_idle.rpl /tmp/census \
    --core cps2w --wide build/m3b_merged21 \
    --post-frames 2 --keep-banks       # ~12 min: the download and nothing else
python3 tools/mister_sdram_census.py /tmp/census/sdram \
    --rom "$JTSIM_SCRATCH/rom/vsavjw.rom" --map wide
```

`--wide BUILD` delegates the `.rom` to `tools/mister_mra.sh` (the WIDE set is
a clone whose parent is the PRISTINE `vsav.zip` since 14z-112 — see above)
and **always generates the
image with `cps2w` whatever `--core` says** — the reference core parses
`sourcefile=["cps2.cpp"]` and cannot see the WIDE machine entry at all, which
is slice D0's profile gate working; `--post-frames N` counts from the END of
the transfer, unlike `--frames`, which assumes the 462-frame stock download
and is wrong for the 66 MB WIDE image (it takes 659); `--keep-banks` collects
the four 16 MB `sdram_bank?.bin` that `test.cpp` writes the instant a FULL
download completes. **A census run therefore costs the download and nothing
more.**

**AND SINCE D2 THE RAM-DUMP OFFSET IS PER CORE — this is the one constant
that will silently invalidate a measurement.** `--wram` dumps an SDRAM
ADDRESS, and D2 re-packed bank 0: `RAM:$FF0000` is bank 0 byte `0x600000` on
`cps2` and **`0x648000` on `cps2w`**, where `0x600000` is now VRAM.
`run_sim_jtcps2.sh` picks it from `--core` and PRINTS it, so the run's own log
says what it dumped. It cost a red `test_mister_wide_inert` (101 frames of
101, RTL innocent) to learn — `docs/platform/gotchas.md`. `tools/mister_sdram_census.py` replays the whole download
mapping — regions, the QSound split, the group-C redirect and the CPS-2 GFX
address scramble — and compares all 67 MB byte for byte, with `--perturb
<region>` as its must-fire control. Gate: `tests/test_mister_sdram_census.sh`.

**Every run pays the ROM download** — 462 simulated frames, ~7-8 min. It is
not skippable on CPS-2: the transfer also latches the decryption key into
core registers, so a run with the SDRAM banks preloaded boots into ciphertext
and work RAM stays all zeros (measured 14z-107). Because the download is
simulated, it also consumes `sim_inputs.hex` lines, so `--frames`, `--wram`
and the dump file names are ABSOLUTE (download included) and the `.rpl` is
shifted by `--offset` (default 462): **a MAME frame `f` sits NEAR simulated
frame `f + 462`** — but the offset is not constant across the boot: it is
+460 at the RAM-test onset and **+463 by the round-1 match start**
(re-measured 14z-107 (7); it read +361 and then +356 on runs whose input
script the harness's frame writer was replaying), which is why the oracle
compares at §4 ANCHORS and not at fixed indices. `--wram FIRST LAST` writes `wram/dump_<frame>_ff0000.bin`,
64 KB of 68k work RAM in 68k byte order — the same files the MAME harness's
`DUMPS=` produces. Nothing ROM-derived may land in the tree: the tool REFUSES
an out-dir inside the repo (rule 7).

~~**CAVEAT (14z-107 (2)): the Verilator SDRAM model is an 8 MB-per-bank,
32 MB module**~~ — **FIXED 14z-107 (3)** (fork commit 3). The model dropped
`addr[22]`, which `jtframe_sdram64_bank.v:219` puts on `sdram_a[9]` as the
tenth COLUMN bit; it is NOT `addr[9]` (a row bit), so the "~3 constants,
widen the column to `0x3ff`" fix this row used to name would have produced a
different wrong map. Video from this lane is now trustworthy for GFX; the
anchor oracle never moved (bank 0 is entirely below WORD address `0x400000`)
and `test_mister_sim_anchor.sh` is still green — with the anchor RE-MEASURED
to MAME 2146 / sim **2502** / skew **356** (was 2507/361 on the broken model;
the band is unchanged at +/- 30). **BOTH SUPERSEDED 14z-107 (7): the clean
anchor is 2609 / skew 463** — 2507 and 2502 were measured while jtframe's
frame writer was rewinding `sim_inputs.hex`. **Re-measured a second time
14z-107 (8), after fork commit 10 stopped `SimInputs` holding P1's and P2's
buttons 5 and 6 down: 2609 / 463, UNCHANGED** — the first reading of this
anchor taken on inputs that match the MAME leg's. The object-timing MECHANISM in
this paragraph still stands; the absolutes do not. The five frames are real:
`jtcps1_obj_draw.v:137` skips a tile whose fetched GFX word is all-ones, so
OBJECT TIMING IS A FUNCTION OF GFX ROM CONTENT. Two further harness bugs had to be fixed to measure SDRAM load at all —
see `docs/platform/gotchas.md` "`jtsim -verilator -stats` reports nothing".

The gates this table listed — this lane's (family `mister` in
`docs/project/gate_index.md`, 18 scripts) and the later additions it had
accreted (the `docs`, `character-data` and `gfx` families) — are rows of the
gate index, each script's header now carrying its slice, runtime and verdict;
the table as of 14z-123 is in `HANDOFF_HISTORY.md`. Two rows kept here as
prose:

**[MSV-27]** **THE FPGA SUPERSET INVARIANT, MEASURED DIRECTLY**: `cps2` and `cps2w` run the SAME stock `vsavj` download under Verilator and their 68k work RAM must be BIT-IDENTICAL at every frame of the window (default 540-640, `WINDOW_FIRST`/`WINDOW_LAST` to move it). Asserts the window is NON-CONSTANT first; control = the same dumps compared against themselves SHIFTED BY ONE FRAME, which must FAIL, proving the comparison would catch a one-frame timing skew. Both legs run with host frame output OFF (the default since 14z-107 (7)) and their dump sets are asserted complete by the producer. This is the inertness instrument; the anchor gate below is a cross-IMPLEMENTATION oracle and is a poor substitute for it (`tests/test_mister_wide_inert.sh`, **manual/emulator (~22 min)**.)

 `tools/charpages_internal.sh` + `tests/lua/sprite_capture.lua` + `tools/sprite_render.py` — **manual (~15 min, 48 MAME legs)**: THE INTERNAL CHARACTER PAGES WITH SPRITES (14z-121 (6)): A. `field_trace` P1's node on every naming part; B. `tools/charpages_frames.py pick` (the first frame the node is an attack node of the move's chain, else the chain's first + probes to +120 f) and `choose` (a chain without an attack node renders at the first probe where an OWNED pool object — the foot, the sword, a projectile — carries a record with real power; the page draws that object's `hitbox_proj` box at the object); C. `sprite_capture.lua` at those frames (the OBJ list + the `$90C000` palette page); D. `sprite_render.py` — the tenant's entries = its records' within-bank tile set (`obj_records.walk`) in bank 3 (vs2's id-indexed OBJ bank table `0x27530`, `0x6000` for all three tenants), mid-screen (the HUD strips are bank 1 at the top and bottom), the LEFT x-cluster (the rigs pin P1 left of P2) → PNG per move from `vsav2.zip`'s tiles; E. `charmap_html.py --sprites` — the sprite and its boxes OUTLINED in one drawing (`KX=64, KY=262`, calibrated 14z-121 (7)). Output `../charpages/` — ABOVE the working tree (unaddable, uncommittable, unpushable from this repo), NOT published; step 0 of the script builds every prerequisite from the user's own dumps, so anyone owning the ROMs regenerates the pages. Not a gate: a currency check would be a re-run


## Running a CPS-2 WIDE build (playtest)

**[VSP-119]** **RECORD YOUR SESSION (14z-99, maintainer-requested):** on the MAME leg,
**MANDATORY FOR CRASH REPORTS since 14z-111 (CLAUDE.md §4 "FIELD REPORTS ARE RECORDINGS"): record first, theorise after; track under `tests/inp/<name>/`; `tests/test_inp_corpus.sh` replays the corpus at every freeze.** `WIDE_RECORD=<name> tools/run_wide.sh <build> mame` records the whole
session as a MAME `.inp` with a FRESH named nvram start state under
`~/.cache/vampire-saved/inp/<name>/` — hand off that directory + the
build name and the session reproduces frame-exact on the same pinned
binary (`WIDE_PLAYBACK=<name>` replays it; playback runs against a
throwaway COPY of the recorded nvram, never the canonical one). Your
control mappings are untouched (cfg stays yours; host keys never enter
the .inp — it records the emulated ports). A field report that comes
with an .inp is a replay protocol: any instrument can ride the playback.
Round-trip smoke-tested 14z-99; the first real session file gets the
instrumented frame-exactness validation. FBNeo's SDL frontend has no
equivalent (its record/replay UI is the Windows frontend's; our SDL
build drives inputs through the 0001 harness instead), so record on MAME.


```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/m3b_merged21 fbneo # THE 3-TENANT BUILD (all 18
                                           # (14z-97: the build argument is
                                           # now REQUIRED. It used to default
                                           # to build/m5w — the known-bad
                                           # garble artifact this file says
                                           # not to play. Bare invocation now
                                           # lists the WIDE builds on disk,
                                           # newest first; m5w and merged1 are
                                           # refused by name.)
                                           # selectable, art included) =
                                           # merged-m14, FROZEN 14z-119 (THE
                                           # PHYSICS PORT: Donovan walks and
                                           # jumps with VS2's values, not
                                           # Victor's; carries the M11 random
                                           # select + the M10 medallion fix;
                                           # program fingerprint 6649523a).
                                           # WHAT TO LOOK AT FIRST:
                                           # (1) the select screen shows
                                           # "M12" bottom-right — THE NAKED-
                                           # EYE A/B TELL (CLAUDE.md §5,
                                           # finally implemented; the text
                                           # names the freeze generation and
                                           # is bumped at every freeze);
                                           # (2) cursor on BISHAMON, hold
                                           # START, confirm with any button
                                           # -> OBORO (vanilla vsavj's, pale
                                           # colorway; HUD name stays
                                           # "Bishamon" — aliased rows).
                                           # Works for P1 and P2. Without
                                           # Start it is plain Bishamon.
tools/run_wide.sh build/don_m18 fbneo      # or the solo builds (hui52,
                                           # pyron36); ... mame
                                           # (registry rows name the CURRENT
                                           # fingerprints — donovan-m18/
                                           # huitzil-m25/pyron-m19 since the
                                           # 14z-119 physics-port freeze)
```

**Current WIDE builds — THE 14z-119 PHYSICS-PORT FREEZE (maintainer-ruled
2026-08-29 "use VS2 parameters and not the shell character's"; mark M12):
donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14.**
`build/don_m18` (`7109f835`, 339 ops — program identical to the validated
probe `build/don_phys_probe`), `build/hui52` (`ae953657`, 370 — program
UNCHANGED from huitzil-m24, only the M12 glyph tiles moved), `build/pyron36`
(`1222df18`, 307 — likewise), `build/m3b_merged21` (program fingerprint
`6649523a`, 826 ops = merged-m13 + exactly Donovan's three physics value ops,
no address moved), stock twin `build/m5_stock13` (`38e9cb2c`, **MOVED** from
`d29fd062` — `port_param32` is a per-row data_port, not profile-gated, so the
substituted track writes his VS2 physics onto stock slot `0x0F` too: six data
ops, member `vm3j.04d` only, no legacy row written). The naked-eye tell is the
**M12** mark; Donovan walks 3.0/−2.625 and jumps with VS2's parameters.
**FIELD VERDICT GREEN 2026-08-30 (maintainer, MiSTer, 14z-121): "all green"** on bundle `../mister_fieldtest_14z119/`.
Detail: patch_notes 14z-119 / 14z-118 (charmap, 2), STATE 14z-119; the
registry row below. Previous freeze (merged-m13, M11): FIELD VERDICT GREEN
2026-08-29 (STATE 14z-118).**

**Previous batch (14z-117 PYRON-MEDALLION FREEZE, the 14z-116 fix,
field-validated on the board 2026-08-29 before freezing; mark M10):
donovan-m16 / huitzil-m23 / pyron-m17 / merged-m12.**
`build/don_m16` (`7950c844`, 332 ops), `build/hui50` (`7ade3180`, 366),
`build/pyron34` (`01b39c39`, 303), `build/m3b_merged19` (program
fingerprint `cde712e1`, 819 ops), stock twin `build/m5_stock11` (`d29fd062`,
UNCHANGED — the thunk is `only_variant_slot`, measured by rebuild: every
member identical). The naked-eye tell is the **M10** mark (three glyphs,
16 px further left); with P2 parked on a tenant cell Pyron's medallion
keeps its colours and the P2 figure's sword is orange (select screen only).
Detail: patch_notes 14z-117 and 14z-116, STATE 14z-117; the registry row
below.

**Previous batch (14z-115 SELECT-WHEEL SEPARATION FREEZE, maintainer-directed
"E2", approved on MAME snapshots 2026-08-28; emulation verdict "no
regression"): donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11.**
`build/don_m15` (`38a4becb`, 332 ops), `build/hui49` (`7bb36d0c`, 366),
`build/pyron33` (`7177229a`, 303), `build/m3b_merged18` (program
fingerprint `dea2c918`, 819 ops), stock twin `build/m5_stock10` (`d29fd062`,
UNCHANGED — the change is profile-gated, measured by rebuild). The
naked-eye tell is the **M9** mark; the three tenant medallions sit lower,
spread, each with a 1 px black ring. Detail: patch_notes 14z-115, STATE
14z-115; the registry row below.

**Previous batch (14z-111 #99 ROOT-CAUSE FREEZE, repackaged
one-zip at 14z-113 (merged-m10; FIELD VERDICT GREEN 2026-08-27/28):
donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9 -> merged-m10.**
`build/don_m14` (`772d8052`, 332 ops), `build/hui48` (`cd362ca4`, 366),
`build/pyron32` (`c403a283`, 303), `build/m3b_merged17` (program
fingerprint `32007911`, 819 ops; = `m3b_merged16` in every member, one zip),
stock twin `build/m5_stock9` (`d29fd062`, UNCHANGED from m5_stock8). The
naked-eye tell is the **M8** mark. Full rows: the registry entries for
14z-110 / 110b / 111 / 113 below; detail STATE 14z-111 and 14z-113.

**Previous batch (14z-105 WINDOW FREEZE (maintainer "happy with
the plan" 2026-08-22; FIELD-CONFIRMED + PUSHED the same day): donovan-m11 / huitzil-m20 /
pyron-m14 / merged-m6.**
`build/don_m11` (`1de9a027`, 325 ops), `build/hui47` (`24a27940`, 365),
`build/pyron31` (`6bf265ab`, 298), `build/m3b_merged13` (`64426955`, 806
ops — BIT-FOR-BIT the rehearsed build/merged_probe_w6, attic'd 14z-106), stock twin
`build/m5_stock6` (`883e7d17` — UNCHANGED from m5_stock5: both features
are profile-gated, measured by rebuild). = the 14z-102 batch + (W1) the
`oboro_select_hook` site_thunk at PRG:0x020B9C — Bishamon's cell + START
held at confirm commits vanilla vsavj's Oboro 0x18 (vanilla's Gallon-
variant idiom one cell over; the Start bit MEASURED: +0x394 = $8000) +
(W2) the select-screen version string "M6" (two authored glyph sprites on
the roster21 wheel record, group C 0x1FE40+, pal row 0x19, pixel-exact
gate). Gates: `test_oboro_select.sh` (5 legs incl. P2 + stock),
`test_version_string.sh`, `test_gfx_tile_codec.sh` (the codec half-mirror
found on the way — docs/platform/gotchas.md). Detail: STATE 14z-105;
patch_notes 14z-105.

**Previous batch (14z-102 WINDOW FREEZE (maintainer "go"
2026-08-21; beams field-confirmed on the rehearsal probe): donovan-m10 /
huitzil-m19 / pyron-m13 / merged-m5.**
`build/don_m10` (`c6a02cb0`, 323 ops), `build/hui46` (`1a7249d6`, 363),
`build/pyron30` (`dbce705b`, 296), `build/m3b_merged12` (`393f92a5`,
804 ops — BIT-FOR-BIT the rehearsed build/merged_probe_row31; hui46 is
likewise bit-for-bit the rehearsed build/hui_probe_row31), stock twin
`build/m5_stock5` (`883e7d17` — moved again: #107's reconciliation flip
is in the SHARED map, not profile-gated). = the 14z-99 batch + (#107)
the reconciliation row 0x0448a6 -> 0x04367a (verified,
callsite-anchored, re-derived at the flip) + (#109) THE CLONE-BEAM FIX:
effect-class ROW 31 (the DF clone-mode beam emitter vsavj shipped as a
stub) ported — root 0x926e4:0x11e:t0x922f0 (vh2-oracled, 6/0x11E
operand-only diffs) + beam_effect_class31 code_ptr at PRG:0x080B28.
THE ROOT CHANGED EXTRACTION: build/hui32/extract regenerated (old
kept as extract.pre-14z102), every hui placement shifted, op counts
re-frozen (hui 363; merged 804/901), tenant bases re-derived
(phobos 0x4595a0, pyron 0x4ac8dc, +0x100 each). Gold tint KEPT
(maintainer ruling 2026-08-21). WHAT TO LOOK AT FIRST: Phobos DF
(HP+HK with stocks) -> move (train forms) -> attack: the clone beams
STROBE green/blue (they were invisible before — GitHub #109; gate
audit_clone_beam_lines.sh, default EXPECT_LINES=1).
Detail: STATE 14z-102; patch_notes 14z-102.

**Previous batch (14z-99, maintainer "go"
2026-08-20): donovan-m9 / huitzil-m18 / pyron-m12 / merged-m4.**
`build/don_m9` (`428fc0c9`, 323 ops), `build/hui45` (`c4bbb375`, 361),
`build/pyron29` (`4c3c072b`, 296), `build/m3b_merged11` (`2343607a`,
802 ops — BIT-FOR-BIT the rehearsed build/probe_window), stock twin
`build/m5_stock4` (`16da59b6` — THE STOCK TWIN MOVED for the first
time since 14z-91: #103's fix is not profile-gated, by design). = the
14z-96 batch + (#43(b)) the fallback flip (one map row, zero build
effect) + (#103) the x026142/x05c800 pcrel escape fixes + the donovan
reconciliation overlay (the arcade-death stall) + (#104) the 15
capture_kf blocks (every attacker's keyframe block ported whole from
vs2; tenants hold NATIVE capture records — Victor's grab holds them
upright) + (#105) win_pal colors 8->10 (the AUTO sets; AUTO winners'
portraits colored). Every piece was REHEARSED on probe_window before
landing; suite GREEN x3 on re-frozen sets; merged gates all green.
Detail: STATE 14z-99 FREEZE.

**THE HARDENING PROGRAM (14z-100, maintainer-directed) — the
crash-candidate map of the merged build lives in
`docs/project/hardening_register.md` (maintained in the same commit as
any change to its classes).** Instruments it added, all committed:
`tools/audit_pointer_flow.py` + `tests/test_pointer_flow.sh` (ci_static
— every address the patch introduces, classified against the op map AND
the shipped image; frozen baselines in `tests/expected/pointer_flow/`);
`tools/triage_pcrel_escapes.py` + `tests/test_escape_triage.sh`
(ci_static — uncovered word-form escapes, 25 verdicts frozen, zero
live); `tests/audit_continue_switch.sh` (the #99 lock: continue+switch
through the literal Donovan-vs-CPU-Phobos pairing, five assertions);
`tests/audit_projectile_clash.sh` + replays 105/106 (the pool-vs-pool
contact surface: must-fire control + — since 14z-101 — the frozen
NATIVE-PARITY signature with a vsav2 anchor leg; the former fix mode
is refused); `tests/audit_guard_corpus.sh` (14z-101 — the whole
79-replay corpus × 4 legs under the crash guard on the build under
test; first merged-m4 run 316/316 END-clean; the known hui41 0x494de
crash is its must-fire control). Re-pointed to the current freeze
the same session: `audit_tripwire_reach.sh` (six marathon legs green),
`test_pcrel_escapes.sh` + `pcrel_escapes.toml`, `bases.tsv` (tenant
hitbox bases MOVE with freezes — re-derive at every freeze, note in the
file). Open findings (final 14z-102): #106 CLOSED (14z-101); **#107 and #109
both SHIPPED AND CLOSED at the 14z-102 freeze** (the mid-window
expected-red state resolved — both gates green on re-frozen pins; the
#109 mechanism went through two more retractions before landing on
effect-class ROW 31, see STATE 14z-102 (2) and the issue).
**#108 RESOLVED NOT-A-DEFECT (14z-101):** the satellite
word is our own load-bearing `obj_bank_word_slot` bank row, the sweep
keys on `+0x94`, and native vs2's satellites are equally sweep-inert
(STATE 14z-101). The window state: NEXT_SESSION banner.

**THE §4 COVERAGE PROGRAM (14z-104, maintainer-directed "tackle the
coverage debt") — the census and its instruments live in
`docs/project/coverage_matrix.md` (maintained in the same commit as any
change to what it names).** Six new on-demand audits, all green on
merged-m5, all poke-generic (legs choose characters by the replay-85
doctrine) with legacy controls + discriminating negative controls:
`audit_df_framework.sh` (the ruled DF table: cost 1 stock, durations
360/360/377/360); `audit_tenant_timeout.sh` (the timeout judge awards
the down to the HP leader — $FF8120/$FF810E, atlas rows added);
`audit_tenant_downwin.sh` (KO-path life-marker transition, every tenant
as winner AND victim — the direct #103-class lock);
`audit_tenant_throws.sh` (normal throw both directions; the throw
discriminator is the strength-independent toss); `audit_down_attack.sh`
(hitting a downed opponent both directions — per-character windows,
Phobos wakes in 24f; the §4 "pursuit" cell, naming question with the
maintainer); `audit_stage_sweep.sh` (every tenant x all 12 stages with
contact; the $FF8100 poke at f2150/2200 is measured load-bearing on the
venue assets). `audit_pursuit_leap.sh` (the maintainer-confirmed NW leaping pursuit:
fires per tenant both directions, per-char arcs frozen loosely,
no-knockdown discriminator; CONNECT is the documented open refinement —
a wake-vs-flight knife edge even on the all-legacy control; mechanics
in engine_internals "THE LEAPING PURSUIT"). Rigs:
`tests/replays/judge/01-03` (subdir = gate-owned, outside the suite's
account). `audit_roster_pairings` re-ran 111/111 on merged-m5 (~5 min —
run it at every freeze). Open cells: tech-hit/tech-roll rigs (also
unlocks pursuit-connect); KO-frame/corner edge cases;
Shadow/Marionette (N/A-until-enabled).

**Previous batch (14z-96, THE #101 KERNEL VOICE-TABLE PORT,
maintainer-ruled 2026-08-18): donovan-m8 / huitzil-m17 / pyron-m11 /
merged-m3.**
`build/don_m8` (`d038553d`, 289 ops), `build/hui44` (`bfd819a0`),
`build/pyron28` (`738bcfc2`), `build/m3b_merged10` (`ac3d0618`, 764
ops), stock twin `build/m5_stock3` (`a054de5c` = m5_stock2
BIT-IDENTICAL, whole-artifact digest also unchanged). = the 14z-94
batch + the kernel voice-table port (GitHub #101, option (a)): 12
variant-half words + 16 authored (base,alias) Z80 song pairs + 2 batch
scope ids. The grunt fix, measured identity-only. Registered (registry
rows d038553d/bfd819a0/738bcfc2); merged-m3 = tag + this row, NO
registry.tsv row per the merged convention. Detail: patch_notes 14z-96,
STATE 14z-96 (2)/(3).

**Previous batch (14z-91, THE LEGACY-REGRESSION FIX):**
`build/don_m7` = **`donovan-m7` (`c90b60c3`)**, `build/hui41` =
**`huitzil-m15` (`4531af1e`)**, `build/pyron26` = **`pyron-m9`
(`fac4a777`)**, stock twin `build/m5_stock2` (`a054de5c`). All four moved
because the fix is NOT profile-gated. = the 14z-87 batch + (A) the two
`fixture_row0f_override` site_thunks DELETED, (B) the obj_hook dispatch
sites left VANILLA — each 0x2C-byte object-pool walker relocated into free
space with its union table appended at copy+0x2C and only the 23 caller
OPERANDS rewritten — and (C, huitzil only) the beam_list_type6 fallback's
`$FF010C` counter removed. That cleared all six `.pending` legacy replays;
frame 829 disappeared corpus-wide and ~30 specs per set became STRICTER
(`composite … 829 889-2091` -> `window 889 2091`). `donovan-m6`/
`huitzil-m14`/`pyron-m8` are BURNED (withdrawn 14z-88), hence m7/m15/m9.
Previous batch: `build/don_m5` = `donovan-m5` (`3c599fb6`), `build/hui40` =
`huitzil-m13` (`2629561c`), `build/pyron25` = `pyron-m7` (`94ce9a48`) —
the 14z-87 voice-borrow sets + the beep fix (packing law #3, sound
members).
The 14z-87b medallion move (Pyron wheel pal_row 0x1A->0x1D, briefly
donovan-m6/huitzil-m14/pyron-m8) was WITHDRAWN 14z-88 (maintainer-
decided): the palette content on row 0x1D changed the select->VS fade's
cycles enough to cost a LEGACY pairing (replay 38, Victor vs Jedah) one
main-loop frame on the H/P/merged builds — never re-converging vs vanilla
(STATE 14z-88). Consequence: the merged-only cosmetic P2-ring-on-Donovan
medallion whitening is BACK until the collision is fixed on Donovan's
P2-hover PORTRAIT side (NEXT_SESSION). See the registry rows. Previous batch (14z-86, THE M5 VOICE BATCH):
`build/hui39` = **`huitzil-m12` (`e1f598d6`)**, `build/pyron24` =
**`pyron-m6` (`4c6e3fb6`)**, `build/don_m4` = **`donovan-m4`
(`84f49aaa`)** — each
= its predecessor + its voice block restored (79 verbatim vs2 songs at
authored vsavj ids 0x58-0xA6; WIDE v1.2 content members incl. packed
samples in `vsw.21m`; the facing-alias thunk; per-tenant remaps + farm
stubs; the whole batch PROFILE-GATED — the stock twin is bit-identical
6c93cfa8, measured). **KNOWN-OPEN on `merged-m1` (14z-93, GitHub #91/#92): it carries a
REACHABLE planted ILLEGAL.** `tests/audit_tripwire_reach.sh` measures
`CRASH 8887 vec4 PC 456930` — the tripwire for unresolved vs2 `0x494de` —
on the 40,620-frame arcade marathon with Huitzil forced. Deterministic.
**NOT Huitzil-only — retracted 14z-93:** the Pyron and Donovan legs' clean
`END 40620` is a TIMING accident, and under a sparse probe Pyron crashes
identically (#92). It is a RACE, which is why three clean playtest matches
prove nothing. The reconciliation row that resolves it is COMMITTED but this
fingerprint predates it; resolving it exposes a second crash (#92), so the
re-freeze waits for #92 rather than shipping twice. **`run_suite` does not
see this** — no suite replay is long enough, which is why the artifact was
frozen green. Playtesting a long arcade run with Phobos is the field
equivalent.
**`build/m3b_merged8` is the current merged** — `merged-m1`,
frozen 14z-92 (merged7 and merged6 superseded).
The map: `docs/project/tables/qs_voice_map.md`. Superseded:
hui38/pyron23/m5_wide (donovan-m3a — tag `freeze/donovan-m3a` is the
way back; its expectation set carried-renamed `donovan-m4`),
m3b_merged5. **COMPAT (WIDE v1.1,
14z-86): builds made before v1.1 (hui37 and older, m3b_merged4 and
older) lack `vsw.z01/z02` and DO NOT BOOT on the v1.1 emulator
binaries** — inject stock copies (2-line python, see
tests/audit_trap_parity's hui37 ground-truth recipe in STATE 14z-86)
or rebuild. `build/hui34`/`hui36` remain the parity/shock audits'
ground-truth-failing references (a ground-truth run on them now needs
the stock-member injection first — the audits do not inject). Superseded solos hui33/pyron22 stay on disk (their extract
dirs remain the tenant_loop/build_merged inputs).
`build/m5w` (`ac52eeff`) is the KNOWN-BAD artifact of the 14z-60y sprite
garble, kept as evidence — do not playtest it. `tools/audit_romset_identity.py
build/m5w/rompath` names its four shadowed members in a second.
**`build/m3b_merged8` is the MERGED BUILD WITH GFX** (14z-92; supersedes
merged7, which was built at 14z-87 and predates the whole 14z-91 legacy
fix). Fingerprint `952fc731`, **753 ops** — the 3-tenant program image
(owner tag + sfx records + damage work-var rows + the chirp/shock fixes
+ the M5 VOICE BATCH + THE 14z-91 WALKER RELOCATION, fixture deletion
and type-6 change) + the S2 gfx chain (D → H → P, group B pristine) +
the authored Z80/sample members (`vsw.z01/z02`, `vsw.21m` — both
playback laws enforced). All three tenants verify (`verify_gfx_build` +
`check_tenant_hud`). UNREGISTERED until the S6 freeze decision —
run_suite refuses it. **QUALIFIED 14z-92 on the artifact gates:**
`test_merged_render_content` PASS (after its huitzil reference was
repaired — see below), `audit_trap_parity` PASS, `audit_fg_parity`
PASS, `audit_select_bank_gates` PASS. `audit_merged_legacy` NOT run —
it builds its own gfx-free instrument from unchanged manifests, so on
this tree it is a re-run of 14z-91's green 47/47 + 6/6 at the same 753
ops, not coverage.
**`test_merged_render_content`'s huitzil reference was DEAD** (14z-92):
it named `build/hui31`, a pre-WIDE-v1.1 build MAME now refuses
(`vsw.z01 NOT FOUND`), so H/P's only render gate had produced no
huitzil measurement since 14z-86 — and printed the dead leg as a
content mismatch against an empty value. Re-pointed to `hui41`;
an empty operand is now reported as a DEAD LEG. **All three rows were
re-pointed at the 14z-99 window freeze (D/H/P -> `don_m9`/`hui45`/
`pyron29`); the standing rule remains: re-point a tenant's row whenever
it is re-frozen** (the m5_wide/pyron21 pins this paragraph used to warn
about were retired then).
`build/m3b_merged7` is superseded and was the build the #75 abort was
measured on. Superseded merged intermediates (m3b_merged4/5, pre-v1.1)
do not boot on current binaries without member injection. The pre-fix
`build/m3b_merged` (FG) and `build/hui34`/`hui36` (chirp/shock) are
kept as the parity audits' known-bad references (same injection
caveat). Rebuild: `ROMDIR=... tools/build_merged.sh build/m3b_merged11`
**— and that is now genuinely ONE COMMAND from a clean checkout (14z-95,
GitHub #27, maintainer-ruled).** It used to require three untracked
`build/*/extract` dirs plus `build/wide0` that NOTHING IN THE TREE KNEW HOW
TO MAKE — the recipe was this file's prose and an `echo` on
`audit_merged_legacy`'s SKIP path — so rule 3 was false for the milestone
deliverable. `tools/ensure_merged_inputs.sh` now produces whatever is
absent and touches nothing that exists (create-if-absent, so it does not
collide with #26's guard on the same dirs). Measured before landing: a
regenerated input set yields a BYTE-IDENTICAL merged `patch.json` (752
ops, same order) and a byte-identical WIDE overlay (21/21 members).
(~1 min, 753-op fixture); its fingerprint moves with the generator — do
not pin it.
**#75 CLOSED 14z-92, and read the second half of that sentence:** the
huitzil gfx-verify abort was a VERIFIER artifact (obj_records.walk's
pointer pass re-derived record structure from the relocated image, and
the merged placement window happened to contain a straddled datum's
value). Fixed + gated. **But the abort had already stopped happening on
its own**: 14z-91 moved `anim@huitzil` 0x41a7e0 → 0x41a6e0 and the
coincidence dissolved, so merged8 verifies green with the PRE-FIX tool
too (measured, all three tenants). Nobody knew because nobody re-ran
`build_merged.sh` after 14z-91. The fix removes the dice roll, not
today's instance of it.
`build/merged1` is the **MERGED-LEGACY INSTRUMENT** (14z-81; carries the
14z-82 type-renumber + F2 fixes) — the 3-tenant program image with gfx
SKIPPED (group C zero-filled): legacy characters render correctly, the
tenants draw BLANKS by design. **Never playtest it, never give it a
registry row** (its own `README-LEGACY-ONLY.txt` says why); it is rebuilt
from scratch by every `tests/audit_merged_legacy.sh` run, so its
fingerprint moves with the generator — do not pin it in docs. Rebuild the
pair with:

```sh
# THE FOUR TRACKS, as tests/test_m3a_reproducible.sh rebuilds them (re-pointed
# 14z-119 (physics-port freeze) <- 14z-118 <- the 14z-8x `build/m5_stock` / `build/don_m4` pair, which no longer
# exists on disk; output names are the CURRENT freeze — roll them each freeze):
python3 tools/build_wide_romset.py "$ROMDIR" build/wide0/rompath --qsound 2 --gfx 4 --prg 4
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock13      # the stock twin
KEY_SET=vsavj WIDE_ROMSET=build/wide0/rompath/vsavjw.zip \
    GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 build/don_m18                                                 # donovan (WIDE)
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 WIDE_ROMSET=build/wide0/rompath/vsavjw.zip \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/hui52
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 WIDE_ROMSET=build/wide0/rompath/vsavjw.zip \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/pyron36
tools/build_merged.sh ...                                                                   # the merged set (its header)
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

**[CPE-40]** **"Unknown system: vsavjw" is an EMULATOR problem, not a ROM problem, and
renaming `vsavjw.zip` to `vsavj.zip` to force it is actively harmful** — it
boots under the stock 4MB descriptor with the sfx helper live and the sound
pointer aimed at the CPS2 register window, re-creating the music bug while
looking fine. See GOTCHAS.


## **[VSP-123]** THE NATIVE LEG IS REACHABLE FOR ANY TENANT SCREEN (14z-69)

Huitzil can be forced on **native vsav2** with the ordinary
early-window poke — no vs2 cursor path, no savestate:

```sh
POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"   # P1; P2 = $FF8B82
tools/run_replay_mame.sh vsav2 <replay> out.log        # ~6 s
```

Verified by `+0x382 = 0x10` on the native leg **(SELECT/commit time only — in MATCH this byte is the VOICE-FLAVOR class and the engine reassigns it; 14z-87, ram.md:85)**, with DF (seq 0x0A) and
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

## **[VSP-151]** THE DF PALETTE-SEQ BLOCK CENSUS (14z-79b) — measured, and it had to be

Which palette-seq ids each character requests in Dark Force, measured on
vanilla vsavj with `$FF802E`=1 asserted per row:
`docs/game/engine_internals.md` "THE DARK FORCE PALETTE-SEQUENCE BLOCKS".
Occupied: `0x1E-0x21` Bulleta, `0x26/0x27` Demitri, `0x44-0x47` Zabel,
`0x6F-0x72` Bishamon+Oboro, `0x264-0x267` Q-Bee, `0x29C-0x2A0` char 0x12
(five ids), and `0xAA-0xAD` **Sasquatch** — the corpus census
`tests/expected/df_palette_seq_census.txt` (14z-118 (14)); this line said
"probably Anakaris — the one character the rig could not put into DF" until
14z-123: RETRACTED 14z-118 (9)/(14), DF on, zero palette-seq calls for him.

**Do not derive this from table `0x02A8A4`.** Ten rows share routine `0x0040`
yet only some request ids; the routine is conditional and a static reading
gives a confident wrong map. **And the resolver masks to 12 bits**
(`0x39A900 + (d0 & 0x0FFF)*0x20`), so a tenant block must live inside
`0x39A900-0x3BA8E0` and CANNOT go in `wide_ext`.

Run it: `CHARS="00 01 02 ... 18" tests/audit_palette_seq_ids.sh`.

## DOCS ARE SPLIT THREE WAYS (14z-69) — `docs/README.md`

`docs/game/` (Vampire Savior itself) | `docs/platform/` (CPS-2, MAME,
FBNeo) | `docs/project/` (this port). The discriminator: **would this
still be true if we abandoned the roster hack tomorrow?** File by the
FACT, not by the task you were doing when you learned it.

`docs/GOTCHAS.md` is now an INDEX of every entry, grouped by bucket
(the count used to be quoted here; it was stale by 25 within a few
sessions, so it is deliberately not repeated);
the entries live in `docs/{game,platform,project}/gotchas.md`. Every
existing citation of `docs/GOTCHAS.md` still lands there.

Looking for whether we already know something? The index is the fastest
topic list; `docs/game/atlas/ram.md` is the fastest address lookup.

## **[VSP-155]** PRIOR ART FIRST — check the subsystem doc before re-deriving (14z-68m)

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

**[CPE-41]** **What is actually at risk in a move: only the MAME expectations.**
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
| **Linux** | Best destination. Native SDL builds for both emulators, every `tests/*.sh` runs unchanged, true headless trivially. Only edits: `sysctl -n hw.ncpu` → `nproc` in `tools/setup_mame.sh`, and note `tools/build_donovan.sh` requires **bash** (it relies on `set -o pipefail`; shebang corrected 14z-90 — the earlier "runs unchanged" claim was written three days after pipefail landed and was never validated under dash). |
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

### **[VSP-101]** THE PRE-COMMIT COMMAND (14z-94, GitHub #30) — run this, not a filename

```sh
tests/run_all_static.sh                    # portable tier: ROM-free, ~1 min
ROMDIR=... tests/run_all_static.sh         # + the static tier, ~8 min
ROMDIR=... tests/run_all_static.sh --strict   # SKIP counts as failure too
tests/run_all_static.sh --list             # what is registered
ROMDIR=... tests/test_inp_corpus.sh        # EMULATOR tier: every tracked hand-played recording, no exception (14z-111)
ROMDIR=... tests/test_down_flash_vanilla.sh  # EMULATOR tier: the one-frame white-out at a down is VANILLA (#113 ground truth, 14z-112)
ROMDIR=... [SNAP_FRAMES=a,b DUMP_FRAMES=..] tools/run_inp_probe.sh <build> <inp>   # per-frame video hash + HP/death/OBJ counts, snapshots, OBJ dumps (also REPLAY= driven)
python3 tools/audit_effect_rects.py --ours <hashes> --stock <hashes> --donor n=<hashes> --blocks <log>  # multi-tile OBJ blocks vs the donor rectangle (14z-112). INSTRUMENT, NOT A GATE — read its header first; hash maps come from run_inp_probe's GFXRANGE, block lists from RECT_AUDIT
```

**One command, every gate that does not need an emulator.** Until 14z-94 there
was no CI and no aggregator, and 101 of 130 test scripts had no shell caller —
so running the reproducibility gate depended on somebody remembering its
filename. What that cost, measured: `test_dualtrack.sh` sat RED for 11 days
(GitHub #95) while CLAUDE.md §4 cited it as one of FBNeo's three guarantees.

It reports **PASS / SKIP / FAIL separately, because SKIP is not PASS**
(GitHub #29): a gate whose build dir is absent prints `SKIP:` and exits 0, and
counting that as a pass is how a fresh checkout reports green while asserting
nothing. `--strict` makes skips fatal.

It also prints a **registry-coverage check** — any emulator-free gate in
neither `tests/ci_portable.txt` nor `tests/ci_static.txt` is named. That check
is the anti-orphan mechanism; without it the runner would just become a
smaller thing to forget to update. Its classifier is TRANSITIVE (follows
`tests/lib/*.sh` sources), because two gates reach an emulator indirectly and
were mis-registered on the first pass.

Emulator gates, soaks and one-off rigs are deliberately NOT here — they stay
manual, and this file is their index. This is also not `run_battery_m2.sh`,
which builds a ROM and is the stage-6 dev-build chain.

Ground truth for the runner itself: `tests/test_static_runner.sh`.

### Individual gates — the index

Every script under `tests/` is one row of **`docs/project/gate_index.md`**
(GENERATED: kind, tier, family, needs, the script's OWN header sentence;
`tests/test_gate_index_current.sh` keeps it current and complete — a new
script without a family row in `tests/gate_index.tsv` fails it). A gate's WHY
lives in its header (maintainer-ruled 14z-122). The hand-written per-gate
fence this section carried until 14z-123 — 168 entries, 113 scripts
unindexed, one entry duplicated — is verbatim in `HANDOFF_HISTORY.md`
"Individual gates (as of 14z-123)", and every comment of substance it held
was appended to its script's header in the same commit ("HANDOFF's
gate-index note"). The four tool entries it carried are rows of "What
exists".

### **[VSP-102]** THE REVIEW-TRIAGE GATES (14z-94, GitHub #74's index)

Every one of these was written while closing a finding from the adversarial
review. They are ROM-free and in `tests/ci_portable.txt` unless the row says
otherwise (a "not portable" gate needs ROMDIR, a build dir, or a MAME
binary, and would SKIP on a clean checkout — which `ci_portable` treats as
failure). The portable set runs in about a minute — `tests/run_all_static.sh` since
14z-94 (60+ gates today); if you loop `tests/ci_portable.txt` by hand, **close stdin** — a gate that reads it
swallows the rest of the list, which is how a 32-entry run silently became 28.

The 30 gates are family `review-triage` in `docs/project/gate_index.md`
(each row's header now carries its issue and what it locks); the table as
of 14z-123 is in `HANDOFF_HISTORY.md`.

**One helper worth knowing about:** `tests/lib/shadow_tools.sh` gives a test a
WRITABLE copy of a tool inside a throwaway repo ROOT. The root matters —
`gen_donovan_patch.py` resolves the repo from `Path(__file__).parent.parent`
and imports its siblings off its own directory, so a bare `/tmp` copy finds
neither its manifests nor `cps2_decrypt`. Use it for any control that must
perturb a tool; never edit tracked source from a test.

**Two tools that now exist because of this batch:** `tools/qs_ledger.py`
(resolve the voice ledger BOUND to a romset — the audits call it instead of
carrying their own rule) and `tools/decode_stage_banners.py` (names the #92
value space).

### **[VSP-150]** THE OUT-OF-RANGE INDEX TOOLKIT (14z-78) — three instruments, one class

`audit_index_space.py` names the DANGER WINDOWS (entries vsavj's table cannot
answer but vs2's can). Two crashes had already landed in the same window
before anyone asked who drives them:

| table | valid | entry | consequence | driver |
|---|---|---|---|---|
| `0x018468` | 0..79 | 80 | ODD -> vec3 — LOUD | (none live) |
| | | 81 | jumps into the table -> reset — LOUD | Pyron Cosmo (fixed 14z-75) |
| | | 82 | ODD -> vec3 — LOUD | **Phobos Plasma Trap** |
| | | 83 | even, real code — **SILENT** | **Phobos Reflect Wall** |
| `0x0185da` | 0..85 | 86-89 | all LOUD | none live (cleared by playtest) |
| `0x03975e` | 0..9 | 10 | SILENT | dispatcher never reached (measured) |

**Read the CONSEQUENCE before valuing any evidence.** "No crash" clears a LOUD
entry completely and a SILENT one not at all — the same clean playtest cleared
Donovan's 15 candidates and said nothing about Phobos' entry 83.

- `tools/audit_index_users.py` — WHICH tenant data lands in a window. Learned
  from the ratified Cosmo fix (index = low byte of `0x01NN`), windows taken by
  RUNNING `audit_index_space.py` so the two cannot disagree. Reports a `shape`
  signal, never filters on it: that 3-sample signature would have pruned entry
  83, which is real. **Does NOT narrow the moves to playtest** — it reports
  addresses, not moves, and sees one defect class only.
- `tests/lua/index_watch.lua` — attributes a dangerous dispatch to the MOVE
  during LIVE play (breakpoints are cheap: ~11 dispatches per 130s). Carries a
  HEARTBEAT because a dead watch once produced a tidy-looking empty log for a
  whole sweep; an idle watch now says so. Prove it with `INDEX_ALL=1` before
  trusting quiet. `INDEX_WATCH="jmp:n_valid,..."` overrides the windows.
- `tests/replays/hui/87_hui_plasma_trap.rpl` — reproduces the crash (forward
  jump, 214 at +10f, MK). **NOT a gate**, and its scripted strengths are NOT
  authoritative: its "LK" variant crashes where the maintainer's real LK does
  not.

Diagnostic instruments added with that gate (MAME Lua, all rerunnable):
`tests/lua/snapshot_frames.lua` (real PNG snapshots headlessly — MAME
renders its bitmap internally even under `-video none`, so `video:snapshot()`
works and the screen can be LOOKED at in-loop), `tests/lua/obj_records_dump.lua`
(the live sprite list with the composed 18/19-bit tile address per entry;
**both gained `POKES` in 14z-68** — replay.lua grammar, so forced-pick rigs
can finally be photographed and OBJ-dumped; reach for these BEFORE the third
RAM-layer iteration, docs/GOTCHAS.md "verify at the RENDER layer"),
`tests/lua/gfx_region_dump.lua` (decoded tile bytes at a TILE index —
compose the bank bits first, see GOTCHAS), and **`tests/lua/read_tap.lua`
(14z-87)** — the non-debug PC-attributed READ+WRITE tap that serializes a
state-dependent value's writes and reads in ONE run (work-RAM only; ROM
read taps are RH-15-blind). Reach for it whenever a written value and a
read value must be compared — never correlate them across runs (GOTCHAS).

All tests are self-contained, take state only via env/args, print PASS/FAIL,
and exit nonzero on failure. Every dev-time in-emulator probe must land here
before session end (persistent suite doctrine, CLAUDE.md §4).

## Build registry

**[VSP-94]** **Every frozen build is git-tagged `freeze/<name>`** (annotated; the tag
message carries the fingerprint and how to reproduce). `git tag -l 'freeze/*'`
lists them. This matters most for SUPERSEDED builds — `pyron-m1` and
`huitzil-m1` cannot be produced from today's tree because their manifests
moved on, and their tag is the only way back to a tree that does.
NOTE: the tags mark the commit at which each build was frozen and was
reproducible AT THAT TIME; no one has re-verified the older ones since.


**TWO REGISTRY ROWS ARE NOT BUILDS** (14z-97, GitHub #96; carried at the
14z-99 window freeze): `donovan-m9-stock` (`16da59b6`, the stock twin of
the donovan-m9 freeze — it MOVED from `a054de5c` at 14z-99, deliberately,
because #103's pcrel rows are not profile-gated) and `donovan-m9-stage4`
(`35e948a1`) are the M2 battery's two legs. They are registered so the battery
can dispatch on the fingerprint instead of a pinned set name — an unregistered
image there means the pipeline no longer reproduces the current freeze, which
is the rule-6 signal the maintainer's ruling asks for. Neither is playtested,
neither is a shipping artifact, and both carry-rename with each freeze
(m8 -> m9 executed 14z-99; the superseded m8 rows stay in the TSV as
history, annotated).
Their expectation sets are BATTERY-SCOPED and say so in their own READMEs.

**The registry is a TABLE; each row's narrative (what the freeze changed,
how it was measured, what it superseded) is verbatim in `HANDOFF_HISTORY.md`
"Build registry narratives" and in the matching `docs/project/patch_notes.md`
entry and STATE close. Newest first; the top row is the CURRENT freeze.**

| build (mark) | fingerprint(s) | dir · tag | what changed | detail |
|---|---|---|---|---|
| THE 14z-119 PHYSICS-PORT FREEZE | donovan-m18 `7109f835` (`build/don_m18`, 339 ops — program identical to the validated probe `build/don_phys_probe`), huitzil-m25 `ae953657` (`build… | tags `freeze/donovan-m18`, `freeze/huitzil-m25`, `freeze/pyron-m19`, `freeze/merged-m14` | donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (stock twin MOVED = donovan-m18-stock). Maintainer-ruled 2026-08-2… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-117b RANDOM-SELECT FREEZE | `90a225ce` / `ae953657` / `1222df18` / merged program fingerprint `a1b7cb82`; stock twin `d29fd062` UNCHANGED (whole-artifact manifest identical) | `build/don_m17`, `build/hui51`, `build/pyron35` … · tags `freeze/donovan-m17`, `freeze/huitzil-m24`, `freeze/pyron-m18`, `freeze/merged-m13` | donovan-m17 / huitzil-m24 / pyron-m18 / merged-m13 (stock twin UNCHANGED = donovan-m13-stock). Maintainer-directed th… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-117 PYRON-MEDALLION FREEZE | `7950c844` / `7ade3180` / `01b39c39` / merged program fingerprint `cde712e1`; stock twin `d29fd062` UNCHANGED (`only_variant_slot`, measured by reb… | `build/don_m16`, `build/hui50`, `build/pyron34` … · tags `freeze/donovan-m16`, `freeze/huitzil-m23`, `freeze/pyron-m17`, `freeze/merged-m12` | donovan-m16 / huitzil-m23 / pyron-m17 / merged-m12 (stock twin UNCHANGED = donovan-m13-stock). The 14z-116 fix, FIELD… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-115 SELECT-WHEEL SEPARATION FREEZE | `38a4becb` / `7bb36d0c` / `7177229a` / merged program fingerprint `dea2c918`; stock twin `d29fd062` UNCHANGED (profile-gated, measured by rebuild) | `build/don_m15`, `build/hui49`, `build/pyron33` … · tags `freeze/donovan-m15`, `freeze/huitzil-m22`, `freeze/pyron-m16`, `freeze/merged-m11` | donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11 (stock twin UNCHANGED = donovan-m13-stock). Maintainer-directed "E… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-113 ONE-ZIP PACKAGING FREEZE | `vsavjw.zip` sha1 `5aeefbec…` (merged16's was `eee7e4b1…` — the zip gained the four patched group-A members); program fingerprint **`32007911` UNCH… | `build/m3b_merged17` · tags `freeze/merged-m10`, `freeze/donovan-m14`, `freeze/huitzil-m21`, `freeze/pyron-m15` | merged-m10 (M8 mark UNCHANGED; donovan-m14 / huitzil-m21 / pyron-m15 and the stock twin CARRIED, untouched). Maintain… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-111 #99 ROOT-CAUSE FIX FREEZE | `772d8052` / `cd362ca4` / `c403a283` / merged program fingerprint `32007911`; stock twin `d29fd062` UNCHANGED (the port is WIDE-only; M8 mark is gf… | `build/don_m14`, `build/hui48`, `build/pyron32` … · tags `freeze/donovan-m14`, `freeze/huitzil-m21`, `freeze/pyron-m15`, `freeze/merged-m9` | the #99 root cause: CPU Phobos ran Demitri's AI — the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + the same 16 repeated; the tenants' rows 0x10/0x11/0x13 unparked from vs2's own tables | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-110b REMAP FREEZE | `ec86330f` / merged program fingerprint `73690f21` / stock twin `d29fd062` (MOVED — data edit, not profile-gated) | `build/don_m13`, `build/m3b_merged15`, `build/m5_stock8` · tags `freeze/donovan-m13`, `freeze/merged-m8`, `freeze/huitzil-m20`, `freeze/pyron-m14` | donovan-m13 / merged-m8 (+ stock update; huitzil-m20 / pyron-m14 CARRIED). The residual #99 (board crash after Donova… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-110 #99-FIX FREEZE | `60b55a12` / merged program fingerprint `761fd35a` / stock twin **`cf455760` (MOVED — the fix is not profile-gated)** | `build/don_m12`, `build/m3b_merged14`, `build/m5_stock7` · tags `freeze/donovan-m12`, `freeze/merged-m7`, `freeze/huitzil-m20`, `freeze/pyron-m14` | donovan-m12 / merged-m7 (+ stock update; huitzil-m20 / pyron-m14 CARRIED, rebuilt bit-exact). Maintainer-ruled 2026-0… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-105 WINDOW FREEZE | `1de9a027` / `24a27940` / `6bf265ab` / merged program fingerprint `64426955` | `build/don_m11`, `build/hui47`, `build/pyron31` … · tags `freeze/donovan-m11`, `freeze/huitzil-m20`, `freeze/pyron-m14`, `freeze/merged-m6` | donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 (FROZEN 14z-105; FIELD-CONFIRMED AND PUSHED 2026-08-22 — "Tests con… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-102 WINDOW FREEZE | `c6a02cb0` / `1a7249d6` / `dbce705b` / merged program fingerprint `393f92a5` | `build/don_m10`, `build/hui46`, `build/pyron30` … · tags `freeze/donovan-m10`, `freeze/huitzil-m19`, `freeze/pyron-m13`, `freeze/merged-m5` | donovan-m10 / huitzil-m19 / pyron-m13 / merged-m5 (FROZEN 14z-102, maintainer "go" 2026-08-21). #107 + #109 in one wi… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE 14z-99 WINDOW FREEZE | `428fc0c9` / `c4bbb375` / `4c3c072b` / merged program fingerprint `2343607a` | `build/don_m9`, `build/hui45`, `build/pyron29` … · tags `freeze/donovan-m9`, `freeze/huitzil-m18`, `freeze/pyron-m12`, `freeze/merged-m4` | donovan-m9 / huitzil-m18 / pyron-m12 / merged-m4 (FROZEN 14z-99, maintainer "go" 2026-08-20). #43(b) + #103 + #104 +… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE #101 KERNEL VOICE-TABLE PORT | `d038553d` / `bfd819a0` / `738bcfc2` / merged program fingerprint `ac3d06184f8c248717ba754275d5ab0147c69f07` | `build/don_m8`, `build/hui44`, `build/pyron28` … · tags `freeze/donovan-m8`, `freeze/huitzil-m17`, `freeze/pyron-m11`, `freeze/merged-m3` | donovan-m8 / huitzil-m17 / pyron-m11 / merged-m3 (FROZEN 14z-96, maintainer-ruled option (a) + freeze 2026-08-18). Th… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| THE #91+#92 FIX BATCH | `da734d49` / `e29cac23` / merged program fingerprint `081e2e53c5debff6d2d5bb4d4376d2a1ef6be842` | `build/hui43`, `build/pyron27`, `build/m3b_merged9` · tags `freeze/huitzil-m16`, `freeze/pyron-m10`, `freeze/merged-m2` | huitzil-m16 / pyron-m10 / merged-m2 (FROZEN 14z-94). The first builds on which a planted tripwire is NOT reachable in… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| merged-m1 | program fingerprint `952fc73138b93e2024516872b95ddc615694d900` | `build/m3b_merged8`, `build/merged1` · tags `freeze/merged-m1` | THE FIRST FROZEN MERGED BUILD (14z-92, maintainer-decided). All 18 characters, one image. | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| ~~donovan-m6 / huitzil-m14 / pyron-m8~~ | `57754602` / `66feb5e8` / `fab92eb7` | `build/don_m5`, `build/hui40`, `build/pyron25` · tags `freeze/donovan-m6`, `freeze/huitzil-m14`, `freeze/pyron-m8`, `freeze/donovan-m5` | THE 14z-87b BATCH (beep fix + medallion fix) WITHDRAWN 14z-88 (maintainer-decided revert): the medallion row move cos… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m5 / huitzil-m13 / pyron-m7 | `3c599fb6` / `2629561c` / `94ce9a48` | `build/don_m5`, `build/hui40`, `build/pyron25` · tags `freeze/donovan-m5`, `freeze/huitzil-m13`, `freeze/pyron-m7` | THE VOICE-CLASS BORROW FIX (14z-87, maintainer-decided b+c) — CURRENT again since the 14z-88 revert (tags freeze/{don… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m4 / huitzil-m12 / pyron-m6 | `84f49aaa` / `e1f598d6` / `4c6e3fb6` | `build/don_m4`, `build/hui39`, `build/pyron24` · tags `freeze/donovan-m4`, `freeze/huitzil-m12`, `freeze/pyron-m6` | THE M5 VOICE BATCH (14z-86) — superseded by the 14z-87 row above (tags freeze/{donovan-m4,huitzil-m12,pyron-m6} are t… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| huitzil-m11 | fingerprint `6eed421be848c2de333bec9a82ef74de18cd88c9` | `build/hui38`, `build/manifest/qs_songs.toml` · tags `freeze/huitzil-m11`, `freeze/huitzil-m10` | PHOBOS FROZEN (14z-86) — supersedes huitzil-m10 | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| huitzil-m4 | fingerprint `e66678d087824d1639750d2b9565c0b99ad2b250` | `build/hui30` · tags `freeze/huitzil-m4`, `freeze/huitzil-m3` | PHOBOS RE-FROZEN (14z-82c, maintainer-adopted 2026-08-12) — supersedes huitzil-m3 | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| pyron-m3 | fingerprint `6c7f7322da793c12b3681dd3ef5a76b3792ae5d0` | `build/pyron21` · tags `freeze/pyron-m3`, `freeze/pyron-m2` | PYRON RE-FROZEN (14z-82c, maintainer-adopted 2026-08-12) — supersedes pyron-m2 | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| pyron-m1 | fingerprint `d8b282daab75fcb3c52e75170a05a600fd0f3ad7` | `build/pyron19`, `build/pyron20` · tags `freeze/pyron-m1`, `freeze/pyron-m2` | SUPERSEDED by pyron-m2 (14z-76); no longer producible from the tree (pyron.toml now carries the effect-palette row) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| pyron-m2 | fingerprint `69e8c6f08b9fc5859948e50cfb41156d62adf1ec` | `build/pyron20` · tags `freeze/pyron-m2`, `freeze/pyron-m1` | PYRON RE-FROZEN (14z-76, 2026-08-10, maintainer playtest) — supersedes pyron-m1 | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| huitzil-m3 | fingerprint `34c8b47de5a43a67e7292f16d0ad133d287fa7e4` | `build/hui29` · tags `freeze/huitzil-m3`, `freeze/huitzil-m2` | PHOBOS RE-FROZEN (14z-79, maintainer playtest) — supersedes huitzil-m2 | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| huitzil-m2 | fingerprint `9deda0808e87601b10e2171405805d4669ba2624` | `build/hui27` · tags `freeze/huitzil-m2` | PHOBOS FROZEN (14z-74, supersedes m1) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui25 | fingerprint `b0fb2f948e04aa53b5e6ab21e2426a47540854bc` | `build/hui25` | THE BEAM DRAWS CLEAN (14z-71, maintainer-confirmed, superseded by hui26) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui20 | fingerprint `40cc10b1b6ed1275cb69893393e2530ae38aef2d` | `build/hui20` | THE BEAM DRAWS (14z-71, NOT yet frozen, awaiting playtest) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui17 | fingerprint `699de9b7ed40e4662f1943b7baaf606082d29dcf` (program unchanged from hui15/16 — the fix is gfx-only, as the shadow fix was) | `build/hui17` | + the 214+P GROUND EXPLOSION (PING #13, 14z-70f, MAINTAINER-CONFIRMED) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui14 | fingerprint `c25b3824a82bcf482069bbd14291078cbf8abbbd` | `build/hui14` | + the DARK FORCE PALETTE (14z-69p, NOT yet frozen; the palette row was WITHDRAWN in 14z-79 — it overwrote Bulleta's D… | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui13 | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` (same as hui12 — the fix is gfx-only, the program is unchanged) | `build/hui13` | + the CHILD SHADOW FIX (14z-69o, playtest-confirmed) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui12 | fingerprint `31d576bebc8fcd3230205d5f5f9ce41659930ea3` | `build/hui12` | the pc-rel TABLE FIX (14z-69i, NOT yet frozen, not yet playtested) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui11 | fingerprint `5c6dbe43e017cb4ee785ef27b63e4790bc9e0622` | `build/hui11` | PING #10 (14z-68m, NOT yet frozen) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui10 | fingerprint `64128aa7465e15378c0082afcc953aa9730744ce` | `build/hui10` | PING #9 (14z-68 close, NOT yet frozen) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui9 | fingerprint `9e3105e0be8a5b5c85f5c792c5c9947f49196098` | `build/hui9` | PING #8 (14z-67 close, NOT yet frozen) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| hui6 | fingerprint `b99b73597b7ab09761e0da58e81527db8747c7e5` | `build/hui6` | the ping-#7 reference (superseded by hui9) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m3a | fingerprint `4b7d0dc7319ed6cf94a02b22938cdb18946dfddd` | `build/m5_wide`, `build/m5_stock` · tags `freeze/donovan-m3a` | THE WIDE REFERENCE (FROZEN 2026-08-06, 14z-64, maintainer-ratified) | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m5w | fingerprint `9bac6ee378e1a5ce0674423279c357a4d2a076ec` | `build/m5_wide` · tags `freeze/donovan-m5w`, `freeze/donovan-m3a` | superseded by donovan-m3a | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| m5_stock (the stock twin, re-frozen 2026-08-06) | fingerprint `6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5` | `build/m5_stock` | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| ~~m5w KNOWN-BAD, kept as evidence~~ | `ac52eeff` | — | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| null vsavj | `12fbb0e1a137a1420824856d3efb0af8fff57be6` | — | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m2c (M2b+ASSETS FROZEN 2026-08-02) | fingerprint `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` | tags `freeze/donovan-m2c` | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m2b-core (M2b-CORE FROZEN 2026-07-28) | fingerprint `71601263474dfd7e4afd0741dae696cde22eda4e` | tags `freeze/donovan-m2b` | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |
| donovan-m2 (M2a FROZEN 2026-07-28) | fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa` | tags `freeze/donovan-m2` | — | history §Build registry narratives; `docs/project/patch_notes.md`; STATE close |

## The port pipeline — its tools, and the guarded-replay debug environment (M2a, 2026-07-25)

The build recipe is the four-track one in "Running a CPS-2 WIDE build
(playtest)" — `tests/test_m3a_reproducible.sh` rebuilds exactly those tracks;
the M2a-era single-tenant recipe and its stage ladder (1 null-relocation, 2
passive data, 3 anim + sprite sub-tables, 4 code + hooks, 5 select plumbing;
gates `tests/test_m2a_stage{1,2,3}*.sh`) are in `HANDOFF_HISTORY.md`.
| Piece | Where | Role |
|---|---|---|
| Extractor | `tools/extract_char.py` | vsav2→vsavj extraction, **vhunt2 as correctness oracle**: every cross-sibling diff byte must classify as a pointer field under a measured shift. Handles: transitive closure, auto-discovered region shifts, extra roots (`addr:len[:tTWIN[:d]|:s]`), segmented gap-tolerant diff, self-pointer regions, PC-relative word tables, **bare-long sibling veto in source-only zones** (operand pairs masquerading as pointers — GOTCHAS) |
| Ref scanner | `tools/scan_code_refs.py` | 68k operand triage (abs.l after known opcodes, bare longs, char-id immediates) |
| R1 resolver | `tools/reconcile_batch.py` | batch vsav2→vsavj engine mapping: pattern ladder, stub-deref, call-site anchoring, code/data byte match, farm-param matching |
| Single lookup | `tools/find_equiv.py` | one wildcarded pattern search (validated at 1.00 on the known loader) |
| Generator | `tools/gen_donovan_patch.py` | staged op-list: hole allocator + layout groups + near_map, pointer/pcrel rewriting, bank repoints (0x0F **and** 0x1F), engine hooks, alloc wrappers, tripwires |
| Driver | `tools/build_donovan.sh` | the whole chain; `EXTRA_ROOTS` / `GEN_FLAGS` override |
| Manifests | `build/manifest/{bank_map,donovan,reconciliation}.toml` | table map / port config (holes, groups, hooks, patches) / R1 map |

**[VSP-152]** **Debug env** (all on `run_replay_guarded.sh`): `GUARD_DEBUG=0` cheap mode
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

## Where the M1 / M2a inventories went (14z-123)

The "M1 additions", "M2a C0 additions" and "Key findings so far" sections
(July 2026) and the M2a single-tenant build recipe are in `HANDOFF_HISTORY.md`.
Every tool and gate they listed still exists (checked by `ls` at the move) and
is a row of "What exists" at the top of this file. The key findings live
where they belong: the crypt key/range and the watchdog instruction in
`docs/game/atlas/README.md`; the byte-order trap and the `-verifyroms` notes
in `docs/platform/gotchas.md`.
