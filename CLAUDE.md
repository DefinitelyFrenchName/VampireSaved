# CLAUDE.md — Project VAMPIRE SAVED

Full-roster Vampire Savior on the real CPS-2 engine. Emulator-target romhack
(FBNeo primary, MAME as independent verification oracle, MiSTer as stretch goal).
This file governs how Claude Code operates inside this repository. Read it fully
at the start of every session. Read `STATE.md` immediately after.

## 1. Mission and prime constraint

Produce a modified `vsav` romset in which all 18 series characters (the 15+1 of
Vampire Savior plus Donovan, Huitzil/Phobos, and Pyron ported from `vsav2` /
`vhunt2`) are selectable, while vanilla Vampire Savior behavior remains
**bit-identical** for all original content.

**THE SUPERSET INVARIANT (never violate, never weaken):**
Any match, menu path, or attract sequence that does not involve the three new
characters MUST produce frame-identical RAM state to vanilla `vsav` under
identical inputs. This is not a quality goal; it is the definition of the
project. A change that improves the new characters but perturbs one byte of
legacy behavior is a failed change.

## 2. Non-negotiable rules

1. **Emulator cores are never modified.** Only cartridge/driver *descriptors*
   (ROM region sizes, load maps, gfx decode lengths) may change in FBNeo/MAME.
   If a task appears to require touching CPU, sprite, timing, or QSound
   emulation code, stop and write up the problem in `STATE.md` instead. The
   trust surface of emulator changes must remain a small, human-reviewable
   set of declarative mapping lines.
2. **No untested change survives a session.** Every patch, however trivial, is
   validated through the headless harness before being committed. "It should
   be equivalent" is not a test result. This standard is inherited from the
   Sailor Moon S project, where systematic in-emulator verification was the
   difference between working and *shipping*.
3. **No hand-edited binaries.** All ROM modifications are produced by the build
   pipeline from source manifests (`build/manifest/*.toml` + assembly sources +
   extracted data tables). The repo must be able to reproduce the output set
   from pristine inputs at any commit.
4. **Provenance is tracked per region.** Every byte range in the output set is
   tagged with its origin: `VSAV` (untouched), `VS2`, `VH2`, `GEN` (generated),
   or `NEW` (authored). The provenance atlas (`docs/atlas/`) is updated in the
   same commit as the change that affects it.
5. **Behavioral values live in documented tables, not in code.** Any tunable
   that defines how the ported characters play (damage, timings, meter rules,
   variant selection) must be extracted into the data-table format of
   `docs/tables/` so the community can review and adjust without re-engineering.
6. **Failing regression halts forward work.** If the replay-checksum suite
   diverges, fixing that divergence becomes the only task until green.
7. **No copyrighted ROM content in the repo or in any distributed artifact.**
   The repo holds tools, patches (xdelta/BPS against named reference dumps),
   documentation, and authored assets only. Reference romsets live outside the
   tree in `ROMDIR` (env var) and are never committed, quoted at length, or
   uploaded anywhere.

## 3. Environment

- Reference sets (decrypted): `vsavj` (**Japan 970519 — DECIDED**, the
  competitive-standard region; do not reopen), `vsav2`, `vhunt2`,
  located in `$ROMDIR`. Verify SHA-1 against `docs/checksums.txt` before any
  session that reads them. If checksums mismatch, stop.
- Toolchain: Python 3 for analysis/extraction; vasm or asmx for 68000 assembly
  hooks; Ghidra headless for bulk disassembly (project under `re/ghidra/`);
  MAME with `-video none` + Lua for tracing and the oracle harness; patched
  FBNeo build under `emu/fbneo/` (submodule + our driver patch).
- All analysis scripts are rerunnable, take the ROM path as argument, and
  print the SHA-1 of what they read. Follow the conventions of
  `tools/` (see existing extractors for style — modeled on the SMS project's
  extraction scripts).

## 4. Verification protocol (the harness is the project's spine)

- **Oracle replays:** `tests/replays/` holds input scripts (per-frame joystick/
  button state). The harness runs each script on (a) vanilla `vsav` on vanilla
  FBNeo and (b) the hacked set on patched FBNeo, checksumming work RAM every
  frame. Legacy-content replays must match for the full script length. First
  divergent frame + RAM diff is the standard bug report format.
- **Hooked-build legacy comparison (amended 2026-07-25 v1, refined to v2
  2026-07-27, both maintainer-approved):** for builds carrying engine
  hooks (code the vanilla game executes routed through added
  instructions), the legacy oracle compares **live RAM**: all work RAM
  except two named windows, both documented in `docs/atlas/ram.md` — the
  dead-stack window `RAM:$FF7F00-$FF7FFF` (below resting SP at the
  frame-done sample point) and the QSound handshake latch `RAM:$FF043C`
  (one-frame phase). On that masked basis, per-replay comparison classes
  (v2): **exact** by default; **flicker-tolerated** where measurement
  shows isolated ≤2-frame divergences that fully re-converge (≥60 frames)
  with ≤8 divergent frames total (`tools/compare_flicker.py`,
  ground-truth tested — the input-accept/spawn-boundary phase artifact);
  **frozen first-divergence constant** where a masked byte's phase
  provably propagates into live state on a path with no gameplay surface
  (test mode reading the sound latch); and, **added v3 2026-08-05
  (maintainer-approved), bounded re-convergent window** — for a screen the
  roster work deliberately alters. A replay may sit in this class only when
  all four hold, each frozen per replay: a single CONTIGUOUS divergent run;
  a fixed ONSET frame; full RE-CONVERGENCE to bit-identical; and **match
  state untouched**. Introduced for the select screen, whose wheel must gain
  three cells for the roster (option 1) — measured over five replays before
  ratification: onset frame 890 in every one, one run each, windows ending
  1051/1622/1802/1882/1622, and 2469-10498 bit-identical frames afterwards
  including a full timeout match. Mechanism: select-screen init caches the
  record pointer the wheel extension repoints (docs/GOTCHAS.md class 4).
  Note this class is STRICTER than the frozen first-divergence constant
  above, which never re-converges at all — it is a narrower licence for one
  screen, not a loosening. Checker `tools/compare_window.py`, ground-truthed
  by `tests/test_compare_window.sh`. Every non-exact class must be
  mechanism-attributed and its expectation frozen; a replay may not be
  reclassified to a looser class without a new measured mechanism and
  maintainer sign-off. **Standing watch (maintainer, 2026-07-27): if
  flickers grow beyond the frozen inventory or divergences turn
  systematic, stop and root-cause — that pattern would indicate a deeper
  issue, not tolerance noise.** Rationale (measured, session 7,
  docs/GOTCHAS.md): hooks cost cycles; interrupts land at skewed
  instruction boundaries in otherwise-vanilla frames; zero-cycle hooking
  is impossible on this engine. Whole-RAM frame-exact remains the
  standard for vanilla oracles, run-to-run determinism, and hook-free
  builds.
- **Dual-emulator agreement (amended 2026-07-25, maintainer-approved):** for
  new-character content (no vanilla oracle exists), the same replay is run on
  patched FBNeo and patched MAME and the two must agree on **mapped gameplay
  state compared at sync anchors** (match start, round transitions):
  character IDs, HP, positions, timer, meter, and the other fields in
  `docs/atlas/ram.md` — not whole-work-RAM checksums frame-by-frame.
  Rationale (measured, session 2): the emulators traverse identical states
  on slightly different frame indices after boot, so frame-exact whole-RAM
  equality is unachievable between codebases; field-level agreement at
  anchors preserves the original intent — a bug would still have to manifest
  identically in two unrelated codebases to slip through. Whole-RAM
  frame-exact checksums remain the standard **within** each emulator
  (vanilla-vs-patched superset oracle, run-to-run determinism).
- **Test matrix growth:** every new capability adds replays. Minimum coverage
  for a ported character: vs each of the 18 (both sides), each stage, Dark
  Force activation/expiry, life-marker transition, timeout, throw/tech
  situations, pursuit attacks, Shadow/Marionette interaction once enabled.
- **Edge-case bias:** when writing replays, prefer pathological inputs
  (simultaneous presses, frame-1 actions, corner interactions, KO-frame
  events). The SMS experience: bugs live at state transitions, not in the
  middle of matches.
- **THE PERSISTENT SUITE DOCTRINE (SMS lesson, promoted to law):** every
  in-emulator test executed during development — measurement, probe, or
  verification — is captured as a scripted, rerunnable case in `tests/` before
  the session ends. No throwaway manual checks. These behavioral tests are the
  project's most valuable artifact, above unit/integration tests; the suite
  only grows. Budget the time; it is time well spent.
- **Auto-detecting regression runner:** the suite runner fingerprints the
  build under test (which features/patches are present) and selects
  expectations accordingly, so one command validates any build variant
  (SMS `test_regression.lua` pattern). Engine-invariant "rule locks" for
  vanilla behavior run on every build.
- **Verdict logic is itself tested.** A test's classification code
  (HIT/BLOCK/TECH/etc.) must be validated against known ground-truth
  scenarios before its verdicts are trusted — SMS shipped a wrong conclusion
  ("blockable frame trap") from a verdict bug, not a game bug. Never again.
- **Savestate hygiene:** key states are tagged to the exact build they were
  created on, named accordingly, and force-added to git when demos/tests
  depend on them; regeneration procedure documented per state.

## 5. Working style

- Sessions begin by reading `STATE.md` (current milestone, open bugs, decisions
  pending) and end by updating it. STATE.md is the single source of truth for
  progress; do not rely on chat memory.
- Address notation: 68k addresses as `PRG:0x0F1234` (program ROM offset) or
  `CPU:$0F1234` (address-space); tiles as `GFX:tile 0x1A2B3`; RAM as
  `RAM:$FF8000`. Never bare hex without a namespace.
- **Documentation taxonomy (SMS-proven; respect the splits, don't merge):**
  - `HANDOFF.md` — operational map: current state, build registry, how to
    build, how to test, key findings. The first read of any session after
    this file.
  - `docs/NEXT_SESSION.md` — 60-second orientation, rewritten at session end.
  - `docs/engine_internals.md` — how the engine works, by subsystem (the
    synthesis; the document a stranger reads to understand the game).
  - `docs/atlas/` — the verified ROM/RAM map per romset (the project bible).
  - `docs/annotations.md` — raw address → label/comment stream.
  - `docs/patch_notes.md` — per-change detail: every byte, and why.
  - `docs/patch_index.md` — one-page registry: status, dependencies,
    exclusivity, deprecation candidates. Updated in the same commit as any
    patch change.
  - `docs/GOTCHAS.md` — traps that cost real debugging time (tool quirks,
    ordering hazards, misleading symptoms). Append the moment one is paid for.
  Findings land in the right document *at discovery time*, not at milestone
  end. An undocumented discovery is a discovery we will pay for twice.
- **Anti-hyperfocus checkpoint (standing order):** deep-dive focus is the
  project's engine but also its failure mode. At natural boundaries — a
  finding confirmed, a test suite green, ~20 tool iterations on one problem —
  stop and do the meta-pass unprompted: update the docs above, capture the
  scratch tests into the suite, reassess whether the current approach is
  still the right one, and check STATE.md for drift. The human should never
  have to be the one to say "step back and document."
- **Build conventions (SMS-proven):** builders are Python, take `(src, out)`
  positionals so they chain onto any input ROM, and every tunable is a
  builder flag — never a hex edit. Bundles are built by chaining builders
  then diffing ONCE against clean; never by chaining standalone binary
  patches (the SMS bank-collision trap). Shipped builds carry a visible
  in-game version string as the naked-eye A/B tell for playtesters, and
  every build's SHA-1 goes in the registry.
- When a decision has gameplay consequences (anything a player could feel),
  it is not Claude's to make: record it in `STATE.md` under "Decisions
  pending" with options and a recommendation, and continue on unblocked work.
- Prefer diff-driven reverse engineering: the three romsets are three official
  builds of one engine. Before free-form disassembly of any subsystem, check
  what the three-way diff says about it.

## 6. What the human provides

Vision and final say on all gameplay-feel decisions; playtesting (structured
reports welcome as replay scripts when possible); base resources (reference
dumps, community docs); community liaison for the VS2-vs-VH2 variant policy.
Claude does the code archaeology, tooling, patch engineering, and testing.
Neither side skips the harness.
