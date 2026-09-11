# NEXT SESSION — orientation (rewritten at the 14z-148 CLOSE, 2026-09-10)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE MUST-FIRE MACHINE IS COMPLETE ON BOTH SIDES; THE RELEASE CADENCE IS RULED. NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state (the close ends with a push
when all is green).

Landed this sitting (STATE 14z-148): the `--controls` cadence RULED (a) — part
of every RELEASE run, the invocation in HANDOFF "THE EMULATOR-TIER COMMAND";
and the must-fire reader LIFTED INTO bbh AS A COPY (harness `02d58f3`,
`lib/sh/controls.sh`, [BBH-88..91]), F1 extended over declaring stubs and F2
exact at 70 rows, the readout header and the controls-red FAIL row made the
same text on both sides and re-baselined loudly. Static strict 145/0/0.

## START HERE — what is open

- ~~**Define what is IN a release, and ship the end-user how-to README**~~
  **DONE 14z-148 (2)** — inventory ruled and enforced, README shipped, applier
  Python-only, the stock-emulator stall measured and locked. **OPEN FROM IT:
  the PREBUILT EMULATOR BINARIES (ruled 1+2)** — build the 0002-only FBNeo and
  the CPS-2-subtarget MAME per OS, each into
  `release/emulators/<platform>/<os-arch>/` with a `BINARY.txt` (sha256 per
  file, pin, patch sha1); macOS from this MacBook (a CLEAN build without the
  0001 harness patch — `tools/setup_fbneo.sh` applies 0001 always, so a
  release build needs its own recipe), Windows and Linux on the two remote
  boxes; then repackage M18 (or the next freeze) so `emulator/bin/` appears.
  Also open: the FBNeo half of the stall measurement (needs the WIDE=0
  reference FBNeo build).
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

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
