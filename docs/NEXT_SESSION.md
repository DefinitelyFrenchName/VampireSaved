# NEXT SESSION — orientation (rewritten at the 14z-149 CLOSE, 2026-09-11)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE macOS PREBUILT BINARIES EXIST, ARE GATED, AND SIT IN M18 UNCOMMITTED — ONE DECISION DECIDES WHERE THEY LIVE. NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

Landed this sitting (STATE 14z-149): `tools/build_release_emulators.sh`
(the recipe run on this host, FBNeo from a clean worktree with 0002 only,
MAME through `setup_mame.sh`'s own mirror), `tools/bundle_dylibs.py` (the
Homebrew closure flat beside the binary under `@loader_path`, ad-hoc signed,
verified on the artifact), `BINARY.txt` per `release/emulators/<platform>/
macos-arm64/`, the gate `tests/test_release_binaries.sh` (record,
self-containment, signature, profile, no harness, a BOOT on each — MAME
reproducing a frozen masked expectation on the release binary; 74 s, two
executable must-fires), M18 repackaged with `emulator/bin/macos-arm64/` on
both emulator sides (150 MB on disk). Two shipped-recipe defects corrected
in place: the FBNeo fresh-tree build needs TWO passes ([CPE-26]), and
`-verifyroms` says "is bad" BY DESIGN on a content set (20 flagged = the
rewritten/new members) where the recipe said "must say good".

## START HERE — what is open

- **THE PREBUILT BINARIES — DECIDE WHERE THEY LIVE, then commit** (STATE
  "Decisions pending", 14z-149): the macOS pair is built, gated and packaged
  but UNCOMMITTED because committing ~140 MB per release into git history is
  the maintainer's call — recommendation (b): gitignore the binary files,
  track `BINARY.txt`, attach the directories as GitHub release assets on the
  freeze tag. Whatever is ruled: land it, then re-run `test_release_roundtrip`
  and `test_release_binaries`. **The floor is macOS 26.0 arm64** (Homebrew's
  bottles carry it) — lowering it means SDL from source with an older target,
  a departure from the recipe; not taken, worth a ruling if a Mac user asks.
- **WINDOWS and LINUX on the remote boxes** (Linux under WSL2 is fine — a
  real kernel and userland; the build distro's glibc sets the floor): extend
  `tools/build_release_emulators.sh` with that OS's bundling step (Linux:
  `patchelf --set-rpath '$ORIGIN'` over the `ldd` closure, or a static SDL;
  Windows: the DLLs beside the .exe) and the gate's self-containment check for
  that OS (it FAILS there today by design, never a silent pass); `test_mame_parity`
  is the migration gate for any new host ([MFI-41]). Also open: the FBNeo half
  of the stall measurement (needs the WIDE=0 reference FBNeo build).
- **At the next freeze/release sweep: the 34 emulator-tier modes HONOURED.**
  `run_all_emulator.sh --scope all --lane all --strict --controls` (the ruled
  release invocation). The ~20 expensive gates' modes were never run; a mode
  that REFUSES on a pruned prerequisite (a control build, a recording,
  Verilator/jtcores) is a dead mode, not a pass. Its COST is the number to
  record — the ruling said "we can always adjust later".
- **Zabel j.LK proximity guard** — its own session (recording first).
- **The community cross-check**: specials/supers/throws still have no naming
  rigs on vsavj; every cell on the page is arbitrated.
- Smaller: `audit_mask_window_ff42a2` deprecated-vs-case-specific;
  `release/merged-m15` never packaged; #112 option (B); the living-docs
  generalisation (ruled, not scheduled); the wider-host re-measure of the
  pull queue's gain; the `hit` rigs' LP events whiff at contact range.

## TRAPS PAID THIS SITTING — read before running a strict tier or touching bbh

1. **This MacBook is memory-tight with the apps open**: the session's
   low-memory guard killed a strict tier mid Verilator control mode and a bbh
   full selftest mid fidelity. Run a long tier DETACHED (`nohup … & disown`)
   and poll the log; never two emulator-bearing runs at once.
2. **`kill <pid>` on a background runner's child leaves the runner alive** —
   kill the PROCESS GROUP (`kill -- -$pgid`) and `pgrep` before relaunching.
3. **bbh's pre-commit NEEDS `ROMDIR` exported** or `test_fidelity_mame` SKIPs
   and F6 runs synthetic only.
4. **A verdict-text change is a BOTH-SIDES change** (bbh convention 8): land
   it in this tree and in bbh in one sitting, harness pushed first, a dated
   line in bbh's `rebaselines.md`.
5. **A re-run of a bundler on a half-rewritten directory proves nothing** —
   validate on a FRESH copy of the build output (14z-149); and the FBNeo
   fresh-tree build takes two passes ([CPE-26]).

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
