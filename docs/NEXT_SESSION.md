# NEXT SESSION — orientation (rewritten at the 14z-150 CLOSE, 2026-09-11)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE PREBUILT-BINARY TOOLING IS THREE-OS NOW, AND THE LINUX/WINDOWS HALVES HAVE NEVER BEEN RUN. That is the next session's first sentence, not a footnote. NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

Landed this sitting (STATE 14z-150): `tools/bundle_elf_libs.py` (Linux,
`patchelf --set-rpath '$ORIGIN'`, the glibc floor measured from the artifact)
and `tools/bundle_win_dlls.py` (Windows/MSYS2, the DLLs beside the .exe,
nothing to rewrite and no signature to apply); `tools/build_release_emulators.sh`
made three-OS with a `CHECK=1` mode that resolves and prints a host's plan
without building; `tests/test_release_binaries.sh` given Linux and Windows
self-containment checks (RESOLUTION checks through the host's own `ldd`, never
the bundler's allowlist read back) with its second must-fire control kept ALIVE
on all three OSes; `tests/test_bundle_parsers.sh` (ci_portable) proving the
parsers, the closure walk and both bundlers' refusal of an empty closure
against stub tools; `docs/project/WSL2_SETUP.md` §10, the one-command-per-
machine runbook. Plus two finds: `test_release_roundtrip`'s inventory regex
would have REJECTED `linux-x86_64` and `windows-x86_64` (no underscore in the
character class), and `run_all_static.sh` now KEEPS a failing gate's full log.

## START HERE — what is open

- **WINDOWS and LINUX: RUN IT.** Everything is written; nothing is proven on
  those hosts. On each box: `CHECK=1 tools/build_release_emulators.sh fbneo`
  first (if the os-arch is not what you expect, stop — the gate looks for that
  exact directory and would otherwise SKIP, which reads as "nothing to check"),
  then the two builds, then `ROMDIR=... tests/test_release_binaries.sh`, then
  `tools/upload_release_assets.sh freeze/merged-m18` or hand the two
  directories back. The runbook, the prerequisites and the four things most
  likely to go wrong are `docs/project/WSL2_SETUP.md` §10.
  **EXPECT TO FIX SOMETHING** — that is the honest state, not pessimism.
  **THE MAINTAINER OFFERED A DEDICATED SESSION ON THE WINDOWS MACHINE (2026-09-11)** — take it:
  Windows is the half most likely to need work (MSYS2 shell, the MINGW64 package set, no
  signature to apply), and a session ON that box turns every claim here into a measurement.
  `test_mame_parity` is the migration gate for any new host ([MFI-41]).
  The one thing only a SECOND machine can find: a library wrongly left to the
  host. And the glibc floor is whatever the build host carries, so build on the
  oldest LTS worth supporting.
- **`test_bbh_fidelity` WENT RED INSIDE THE STATIC TIER AND GREEN ALONE, TWICE,
  AND THOSE TWO ARE STILL NOT ROOT-CAUSED** (14z-149, and 14z-150's FIRST strict
  run). Both reported only `FAIL: see above` at ~126 s, with no surviving
  evidence. **Do not confuse them with 14z-150's THIRD red, which IS explained**
  — that one was the `(full log: …)` line this session added to the static
  runner, a verdict-text change bbh's F1 compares line for line, landed on both
  sides the same sitting. The blindness is fixed: the runner now keeps
  `build/gate_failures_static/<gate>.log`, and it named that third red in
  seconds on its first run. So the NEXT occurrence carries its own evidence —
  read that file before theorising. The two originals are not known to be
  harmful; they are known to be unexplained, and [VSP-31]'s standing watch says
  a pattern is root-caused, not tolerated.
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

## TRAPS PAID THIS SITTING — read before writing code for a host you do not have

1. **A tool you cannot run needs a REFUSAL, not a hope.** Both bundlers
   hard-refuse an empty closure: without that, a parser returning nothing makes
   the bundler "succeed" and its verifier then finds no leftovers — a vacuous
   green on a binary that runs only on the build host ([VSP-148]).
2. **A `CONTROL=` mode that echoes FAIL is a LIE.** Mine did, until they were
   rewritten as shadow-tool perturbations that disable ONE guard in a copy and
   let the gate fail on its own ([VSP-181]).
3. **A character class silently narrows an inventory.** `[a-z0-9-]+` admitted
   `macos-arm64` and rejected every underscore-bearing os-arch.
4. **An illustrative hex address in a docstring lands in the address index** —
   `gen_annotations.py` reads `0x00007ffd…` as `PRG:0x007FFD`. Elide sample
   addresses in tool documentation.
5. **This MacBook is memory-tight**: run a long tier DETACHED and poll the
   PROCESS, never two emulator-bearing runs at once.

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
