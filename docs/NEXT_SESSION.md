# NEXT SESSION — orientation (rewritten at the 14z-152 CLOSE, 2026-09-13)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## ALL THREE PLATFORMS' RELEASE GATES ARE GREEN, THE WINDOWS BOX IS DRIVEN OVER SSH, AND A REGISTER RECORDS WHERE A BUILD IS KNOWN TO WORK. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

**HOW THE WINDOWS BOX IS WORKED (maintainer-ruled 2026-09-13):** from this Mac,
over SSH, never a separate Claude session on the box. `ssh musicmaking`, scripts
on stdin, the `^**` post-quantum banner filtered out:

| route | command | clone | dumps |
|---|---|---|---|
| MSYS2 MINGW64 | `ssh musicmaking 'C:\msys64\usr\bin\env.exe MSYSTEM=MINGW64 CHERE_INVOKING=1 /usr/bin/bash -l -s' <<'EOF'` | `/home/alexr/vampire-saved` | `/home/alexr/roms` |
| WSL2 (Linux user **`koneko`**) | `ssh musicmaking 'wsl.exe -e bash -l -s' <<'EOF'` | `/home/koneko/vampire-saved` | `/home/koneko/roms` |

A WSL2 job survives a disconnect only while the maintainer keeps a WSL window
open; run MSYS2 jobs inside a live session. The memory note
`remote-build-machines` has the rest.

**WHERE THE RELEASE BINARIES STAND:**

| os-arch | built | gate | published |
|---|---|---|---|
| macos-arm64 | 2026-09-11 | PASS (74 s, 2026-09-13) | yes, `freeze/merged-m18` |
| windows-x86_64 | 2026-09-13, rebuilt on the box (MSYS2) | PASS at `666b14d9` | yes, `freeze/merged-m18` (14z-153) |
| linux-x86_64 | 2026-09-13, rebuilt on WSL2 (Ubuntu 26.04) | PASS at `a145562c` | never — a PROOF run, glibc 2.43 floor |

## START HERE — what is open

- ~~**Publishing the Windows binaries — the maintainer's word**~~ **DONE 14z-153:**
  rebuilt on MSYS2 with the capturing builder, gated there, uploaded from the Mac
  (`gh` is absent on MSYS2); M18 serves seven assets. The route that worked, step
  by step, is STATE 14z-153.
- **The Linux clean-machine check (ruled option 3, the goal):** once the dedicated
  Linux server exists, build the PUBLISHED Linux binaries there on the oldest LTS
  worth supporting, and add a release-time resolution on a machine with no `-dev`
  packages. The WSL2 binaries are never published.
- ~~**OPEN, not root-caused — a red that did not say why.**~~ **ROOT-CAUSED AND
  FIXED 14z-153:** the HARNESS lost its reason, not the kept log — F11's four
  status captures had no `(set +e; …)`, so a stale guide ended the script under
  errexit before its FAIL line (reproduced in a clean worktree: 33 lines vs 38);
  bbh fixed and a lint selftest bars the shape. See STATE 14z-153.
- ~~**One CR byte** remains in the Windows gate's output~~ **LOCATED AND FIXED
  14z-153:** the `-verifyroms` Python block printed its PASS line through native
  Windows text-mode stdout; reconfigured like the other block, 0 CR on the box.
- **At the next RELEASE run** (cadence ruled 14z-148 (a)): the **39 control modes
  in 36 gates** (`run_all_emulator.sh --scope all --lane all --strict --controls`)
  — "34" was the pass-3 GATE count. Estimated ~5.5 h serial from M18's runtimes,
  4.6 h of it the four Verilator gates; measure and record.
- **Zabel j.LK proximity guard** — its own session (recording first).
- **The community cross-check**: specials/supers/throws still have no naming rigs
  on vsavj.
- Smaller, carried: `audit_mask_window_ff42a2` deprecated-vs-case-specific;
  `release/merged-m15` never packaged; #112 option (B); the living-docs
  generalisation (ruled, not scheduled); the wider-host re-measure of the pull
  queue's gain; the `hit` rigs' LP events whiff at contact range.

## TRAPS PAID THIS SITTING — read before writing code for a host you do not have

1. **A check keyed on one line of output fails wherever that line cannot print.**
   FBNeo's Windows frontend drops every core message; the proof that stayed was the
   member loads. Key a check on evidence the host can produce.
2. **On a Linux build host every bundled library also lives under /usr/lib**, so a
   resolution check cannot see a missing one. Judge what the folder ASKS FOR.
3. **A `$(shell …)` inside a flag can become a different flag** — a missing
   `qmake6` turned `-I` into the eater of `-std=c++20`. Read `make -n`, not the
   makefile.
4. **`var=$(cmd)` under `set -e` ends the shell when `cmd` fails** — the
   environment capture died on an absent package in its own test; every query ends
   `|| true`.
5. **Repeat a test with its confounder removed before relying on it** — "WSL2 jobs
   survive a disconnect" was really the maintainer's open window.
6. **Editing an anchored paragraph stales its skill GUIDE** —
   `tools/gen_skill_guide.py --prefix <PFX>` in the same commit; a strict tier went
   147/0/2 on it.
7. **Check an instrument with a positive control** — `ldconfig -p` puts a TAB before
   each soname; "0 of 18" was the pattern, not the host.
8. **This MacBook kills harness background tasks under memory pressure** — run a
   strict tier DETACHED (`nohup … &!`) and wait on its PID.

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
