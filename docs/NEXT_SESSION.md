# NEXT SESSION — orientation (session 14z-59, 2026-08-03)

Read STATE.md session **14z-59** (B5) and 14z-53..58 (the CPS-2 WIDE pivot,
Phase A, Phase B0-B4), then docs/cps2_wide.md. The approved architecture
plan is archived at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are
the project's best instrument; reference data they provide goes straight
into gates.

## Ship state — CPS-2 WIDE v1 is demonstrated on BOTH emulators

Frozen reference: `b91647c7` = **donovan-m2c** (stock-size, untouched by
the WIDE work). Donovan content dev head: `ae701ffb`.

PRG 6 MB / GFX 48 MB / QSound 16 MB, for a total emulator cost of **one
gated conditional** in each emulator plus descriptor table data.

| | FBNeo | MAME 0.288 (`emu/mame`, tag `mame0288`) |
|---|---|---|
| profile patch | `emu/fbneo-patches/0002` | `emu/mame-patches/0002` (164 lines added, **1** removed) |
| gate | `tests/test_wide_profile.sh` — 36 checks | `tests/test_mame_wide.sh` — **36/36** |
| B4 canary | 9/9 pixel-identical | 12/12 pixel-identical |

**B5 is done.** MAME is pinned, built from source, parity-proven **62/62**
on the UNPATCHED build before the patch went near it, and now carries the
profile. `-verifyroms vsavjw` confirms both emulators load byte-identical
romsets.

```sh
WIDE=0 tools/setup_mame.sh      # reference binary  -> ~/.cache/vampire-saved/mame-ref/cps2
tools/setup_mame.sh             # WIDE binary       -> ~/.cache/vampire-saved/mame/cps2
ROMDIR=... tests/test_mame_parity.sh    # ALWAYS FIRST, on the unpatched build
ROMDIR=... tests/test_mame_wide.sh
```
Prereqs: `brew install sdl3 pkgconf`. The build runs from a space-free
mirror under `~/.cache/` — MAME's GENie cannot handle the space in this
repo's path (GOTCHAS).

## READ THIS BEFORE TRUSTING ANY MAME GATE

**Two run-to-run divergences were observed, and the cause is still
UNKNOWN.** `08_challenger_join` and `41_don_altcolor_vsav2`, both in the
boot window, both re-converging, neither a source-vs-Homebrew difference.

**Policy RATIFIED by the maintainer 2026-08-03: "A, then B".** A (measure
first) is DONE; B (**every MAME gate stays strict**) is in force. Option C
(a tolerance class for unreproducible transients) is **not adopted and may
not be re-proposed** — A found no rate, so nothing justifies loosening.
CLAUDE.md §4 is unchanged; no comparison class was added or weakened.

What the measurement established (STATE 14z-59 has the tables):
- ~2,400 clean runs across four regimes since.
- **Flat per-run boot-window rate: RULED OUT** (1-in-8,300). The
  520-frame `tests/probes/boot_probe.rpl` is bit-identical to `08` for
  frames 1-299 — verified, not assumed — so it genuinely covers the window
  both events began in, and 2,080 clean probe runs contradict the rate.
- **Machine load: RULED OUT** (600 runs at parallelism 6).
- **Both events fall in ONE parity execution**; three further full gate
  executions are clean. Reads as a transient local to that ~35-minute
  window. What that condition was is NOT established.

**LEADING EXPLANATION (maintainer, 14z-59c): host input.** MAME has no
true headless mode — `-video none` still creates a window that can TAKE
FOCUS, and the harness runs on the maintainer's working laptop. A host
keystroke lands on MAME's default map (P1 directions/buttons/coins/start)
and is injected into the emulated controls; RAM then diverges while the key
is held and RE-CONVERGES when the script's staging reasserts — exactly the
observed signature, and it explains the clustering into one window while
~2,400 idle-machine runs stayed clean. Not confirmed (the events predate
input logging), but the hole is closed both ways:

- `tools/run_mame.sh` disables all four host input providers.
- `replay.lua` asserts every frame that the live controller bits are what
  it staged, writes `INPUT-VIOLATION`, and the runner rejects the run.
  Always on; `NO_INPUT_CHECK=1` disables.
- `tests/test_input_integrity.sh` ground-truths both directions.
- `INPUT_OUT=<path>` logs raw per-frame port values when you want evidence.

**So if a MAME gate ever goes red again, check the log for
`INPUT-VIOLATION` FIRST** — that turns the whole class of problem into a
named, one-line answer. Then `tools/analyze_divergence.py` (ground-truthed)
classifies the preserved pair as PHASE SHIFT k / TRANSIENT / PERMANENT.
Both gates keep artifacts under `build/gate_failures/`, which **IS tracked
in git** — failure logs are evidence, do not gitignore it.

Note also: MAME can crash outright. Already covered — `run_replay_mame.sh`
requires a terminating `END` line, so a truncated run fails rather than
being silently compared.

Rerunnable: `RUNS=`, `JOBS=`, `PROBE=`, `SET=` on
`tests/test_mame_determinism.sh`.

## MOVING THE HARNESS TO ANOTHER MACHINE — full analysis in HANDOFF.md

**The move is no longer urgent.** `SDL_VIDEODRIVER=dummy` (now the default
in `tools/run_mame.sh`) means SDL creates NO window at all, so the
focus-stealing hazard is gone on the current machine — measured
non-perturbing, and `VIDEO_OUT` still works. Migrate deliberately, not
under pressure.

Short version of the HANDOFF analysis:
- **Only the MAME expectations are at risk.** `tests/expected/**` is
  absolute and MAME-only; every FBNeo gate is a live A/B with no frozen
  file, so it is machine-independent by construction.
- **Architecture (ARM64 vs x86_64) should not matter**: MAME uses
  interpreters for CPS-2's 68000/Z80/DSP16 (its DRCs cover other CPU
  families entirely), FBNeo's x86 A68K asm core is disabled in its
  makefile, and all hosts are little-endian with an endian-pinned
  checksum. That is an argument, not a measurement — run the gate.
- **Ranking**: Linux best; Intel Mac lowest-friction today; Windows 10
  natively costly (POSIX shell + SDL frontends) — **use WSL2 and treat it
  as Linux**.

**Run `tests/test_mame_parity.sh` on the new machine BEFORE trusting any
result there.** It is not just the B5 gate — it is the machine-migration
gate, and it already asks exactly the right question: does this build, on
this hardware, reproduce every frozen oracle log bit-for-bit? A different
CPU, compiler version or libc is a change of INSTRUMENT in precisely the
sense that gate was written to catch. If it passes, every frozen
expectation in `tests/expected/` transfers unchanged. If it fails, STOP —
do not re-freeze to make it green; that would silently redefine the
baseline the whole superset invariant rests on.

Portability notes for `tools/setup_mame.sh` (currently macOS-shaped):
- `sysctl -n hw.ncpu` for the job count → `nproc` on Linux.
- Prereqs `brew install sdl3 pkgconf` → distro packages (`libsdl3-dev`,
  `pkgconf`). The SDL3-via-pkg-config requirement is not macOS-specific.
- The space-free build mirror stays regardless: it costs one rsync, keeps
  the submodule pristine, and avoids re-discovering the GENie space bug if
  the repo ever lands on a path with a space again.
- `$HOME` being a git repository broke `git apply` here (GOTCHAS). The
  script now uses `patch(1)`, so the new machine is unaffected either way.
- `ROMDIR` is machine-specific and deliberately not recorded in the repo —
  re-export it, and run `tools/audit_roms.py` first as always.

## Two MAME facts that CONSTRAIN the profile

1. **16 MB QSound is MAME's hard ceiling** — `qsound_device` is a
   `device_rom_interface<24>`. WIDE v1 fits with nothing spare; growing it
   further means widening a SHARED device, outside Rule 1 v2. Future
   voice-bank pressure must be solved by exclusivity/banking, not size.
   (Relevant to the M5 voice-samples decision still pending.)
2. **`$400000-$40000F` reads differ between the emulators** (FBNeo
   ROM-shadows the CPS2 output registers, MAME keeps them readable). Only
   the profile's reservation makes that unobservable — **never allocate
   there**; it is load-bearing for dual-emulator agreement now.

## Queued next

1. ~~**B5b — suite preservation**~~ **DONE (14z-59e)**, except one item
   blocked by Rule 1. FBNeo now has `FBNEO_HTAP` (write tap with PC
   attribution), `FBNEO_HPOKE` (frame-scheduled pokes) and address-resolved
   dumps reaching OBJ/palette RAM, all frontend-only and gated by
   `tests/test_fbneo_instruments.sh` (non-perturbing, positive controls,
   and a byte-for-byte cross-check against MAME).
   **BLOCKED: probe breakpoints with register capture.** `m68000_intf.h`
   exposes no instruction-level hook, so it cannot be done without touching
   a CPU core file. Written up in STATE 14z-59e with three options; the
   need largely evaporated when B5 gave MAME proven parity, so its
   `GUARD_PROBE` is the answer for now.
   **Also uncovered there: the FBNeo emulator superset invariant had been
   passing vacuously** (`WIDE=0` never reverted the profile patch, so the
   "reference" carried it). Fixed, asserted in both the build and the gate,
   and the invariant is now established for real at 36/36.
2. **Phase C — multi-tenant pipeline.** Start with the address-space model
   (declarative region list + placement classes in `gen_donovan_patch.py`),
   which also unblocks the stuck 352-byte sound table. Then per-tenant
   manifests, slot parameterisation, gfx band planning, and moving Donovan
   off Jedah's slot.
3. The determinism measurement above, whenever there is idle machine time.

**Content may be authored into the extension** — B4 opened that gate and
B5 confirmed it on a second emulator. Rules: raw (no encryption above
`PRG:0x0FFFFF`), FILE byte order
(`words_to_file_bytes(words_from_logical_bytes(...))`), the member's REAL
CRC in BOTH descriptors, and `$400000-$40000F` reserved.

## Gotchas most likely to bite next session

- **"It said OK" is not evidence.** `git apply` silently skips and exits 0
  when the target is inside another repo's worktree (`$HOME` is one here);
  FBNeo silently loads 0xFF fill on a CRC mismatch while printing `(OK)`.
  Assert on the ARTIFACT, not the exit code.
- A SOURCES-filtered MAME build silently omits any driver missing from
  `src/mame/mame.lst`; `mame.lst` has no inline comments anywhere.
- DUMPS separator is ';' — comma multi-dumps exit rc=3 with no artifacts.
- Venue asset cells: identify by cursor-ring measurement + color render,
  never by pal-index/char-id numerology (the Gallon trap).
- A cited address in a session log is a CLAIM — grep the manifest and xxd
  the built image before building a theory on it.
- POKE VALUES feed the CPU AI — any poke change reshuffles downstream
  choreography in multi-round scripted replays.
- The battery script builds donovan6 itself — never rebuild while it runs.
  Background any run >10 min.
- ROMDIR must pass tools/audit_roms.py first; keep it play-free.
