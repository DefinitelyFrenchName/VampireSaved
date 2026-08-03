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

**MAME is not provably deterministic run-to-run.** Two divergences appeared
in one 126-run parity execution (`08_challenger_join`, `41_don_altcolor_vsav2`),
both in the boot window, both re-converging, neither reproducible in 666
subsequent runs, and neither a source-vs-Homebrew difference. Point
estimate ~0.6%/run on full-length replays.

This is in **STATE.md "Decisions pending"** and needs the maintainer,
because §4's comparison classes are their call and a non-zero rate is a
false-failure rate on every MAME gate we own. Gates are STRICT today —
any divergence fails. Recommended next measurement (~1.5 h, background):

```sh
PROBE=tests/replays/08_challenger_join.rpl RUNS=300 \
  ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame-ref/cps2 \
  tests/test_mame_determinism.sh
```
If it recurs, `tools/analyze_divergence.py` classifies the preserved pair
(PHASE SHIFT k = timing / TRANSIENT / PERMANENT) and both gates now keep
their artifacts under `build/gate_failures/`.

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

1. **B5b — suite preservation** (gates any FBNeo-only decision). Part
   delivered: both emulators now have per-frame framebuffer capture
   (`FBNEO_HVIDEO`, `VIDEO_OUT`) and FBNeo has a gfx-buffer dump
   (`FBNEO_HGFX`). Remaining instrument gaps on the FBNeo side: write taps
   with PC attribution, probe breakpoints with register capture,
   frame-scheduled pokes, OBJ/palette RAM dumps.
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
