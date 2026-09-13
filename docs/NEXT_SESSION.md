# NEXT SESSION — orientation (rewritten at the 14z-151 CLOSE, 2026-09-13)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE WINDOWS AND LINUX RELEASE BUILDS ARE BEING RUN BY THE MAINTAINER RIGHT NOW, AND THE LOOP IS LIVE. NO BUILD BYTE MOVED ALL SESSION.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

**THE LOOP, and it is the fastest way back in:** the maintainer runs a command
on their box, sends the console output, the defect is diagnosed HERE, fixed,
gated, pushed; they `git pull` and run again. **Twelve defects in one sitting,
every one ours, none in a shipped ROM byte** — STATE 14z-151 (6a)-(6g) and (8).
Every durable fact is in `docs/platform/gotchas.md`'s last five entries: READ
THOSE FIRST before touching any non-macOS host.

**WHERE THE MAINTAINER IS, exactly:**

| | |
|---|---|
| MSYS2 native (`windows-x86_64`) | FBNeo + MAME BUILT and recorded; the release gate is mid-loop |
| WSL2 (`linux-x86_64`) | FBNeo built; MAME restarted with `JOBS=8` after the memory thrash |
| a dedicated Linux server, 8c/64 GB | coming — the better home for the Linux binaries (glibc floor = the build host's) |

**WHAT WINDOWS HAS PROVEN:** both emulators build; MAME's `-verifyroms` passes
on an applier-built romset (20 members flagged, exactly the rewritten set).
**WHAT IS STILL UNPROVEN OUTSIDE macOS:** the FBNeo boot leg (it has never
printed `CPS-2 WIDE v1 profile active` there) and MAME reproducing
`05_timeout_idle`'s frozen expectation. Those two are the whole remaining
question, and both now leave evidence: `build/fbneo_boot_<os>.log` is kept
whatever the verdict.

**THE MAINTAINER'S NEXT THREE COMMANDS** (they were given these at the close):
`rm -rf release/emulators/fbneo/windows-x86_64/{config,recordings,roms,savestates,screenshots}`
(one-time cleanup of the pollution the gate itself caused),
`pacman -S --needed diffutils`, then `git pull && MERGED=build/fromrelease
tests/test_release_binaries.sh`.

## START HERE — what is open

- **WINDOWS and LINUX: BEING RUN NOW (2026-09-12), and it is going exactly as the
  last opener predicted.** The maintainer has both tracks on the Windows box
  (MSYS2 native -> `windows-x86_64`, WSL2 -> `linux-x86_64`); a DEDICATED Linux
  server, 8 cores / 64 GB, comes later and is the better home for the Linux
  binaries (the glibc floor is the build host's, so build on the oldest LTS
  worth supporting). **Seven defects so far, every one of them ours and none in
  a shipped ROM byte** — STATE 14z-151 (6a)-(6f) and five new platform gotchas.
  **STATUS: FBNeo built on both tracks; MAME built and recorded on MSYS2
  (`standalone: 16 import(s)`, a `-static` binary); MAME on WSL2 restarted with
  `JOBS=8` after the memory thrash.** What is still unrun anywhere: the release
  GATE on either Windows track (`MERGED=build/fromrelease
  tests/test_release_binaries.sh` — the romset comes from the applier in a
  minute, no build pipeline), and therefore the upload of those assets.
  **READ `docs/platform/gotchas.md`'s last five entries before touching a
  non-macOS host** — they are the whole cost of today in one place.
- **~~`test_bbh_fidelity` WENT RED INSIDE THE STATIC TIER AND GREEN ALONE~~ ROOT-CAUSED
  2026-09-12 (14z-151): A WALL-CLOCK DURATION INSIDE TEXT COMPARED EXACTLY.** bbh's F1
  diffs the two static runners line for line; the output carries each gate's duration,
  which is not verdict text, so `norm()` masked it — but only in the COLUMN form
  (`PASS    1s`). The controls readout appends it as a SUFFIX, `(1s)`, and the regex
  demanded a space before the digits and a space or end-of-line after the `s`. So when
  one runner's stub gate straddled a second boundary and the other's did not, two
  IDENTICAL verdicts differed by one character. Caught by running the gate SIX times
  with every log kept: 1 red, and the diff above was its whole content. Fixed in the
  harness (`529f9d2`, pushed) by masking the suffix form, PROVEN deterministically (the
  two real lines: differ under the old mask, identical under the new) and corroborated
  8/8 green. **NOT CLAIMED: that the two 2026-09-11 occurrences were this** — their logs
  are gone; this is the leading and the only measured explanation. The kept-log
  instrument is what made the third one readable, so read `build/gate_failures_static/`
  first if anything like it returns.
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
