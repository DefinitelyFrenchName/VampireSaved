# NEXT SESSION — orientation (rewritten at the 14z-153 CLOSE, 2026-09-14)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE WINDOWS BINARIES ARE PUBLISHED, A RELEASE RUN'S COST IS MEASURED, AND TWO OLD UNKNOWNS ARE CLOSED. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

**WHERE THE RELEASE BINARIES STAND:**

| os-arch | built | gate | published |
|---|---|---|---|
| macos-arm64 | 2026-09-11 | PASS (14z-153 re-run, 0 CR) | yes, `freeze/merged-m18` |
| windows-x86_64 | 2026-09-13, rebuilt on the box (MSYS2) | PASS at `666b14d9`; again after the CR fix, 0 CR | yes, `freeze/merged-m18` (14z-153) |
| linux-x86_64 | 2026-09-13, rebuilt on WSL2 (Ubuntu 26.04) | PASS at `a145562c` | never — a PROOF run, glibc 2.43 floor |

**WHAT A RELEASE RUN COSTS — MEASURED 14z-153, and it is an overnight job:**
`tests/run_all_emulator.sh --scope all --lane all --strict --controls --jobs 4`
took **5 h 37 min** on this MacBook (PASS 210 / SKIP 1 approved / FAIL 0).
Serially the controls add **+33%** (4.5 h on 13.6 h of gates), and 4.1 h of that
is the four Verilator gates, each control a full re-run of its gate. HANDOFF has
the figures beside the command.

**HOW THE WINDOWS BOX IS WORKED (maintainer-ruled 2026-09-13):** from this Mac,
over SSH, never a separate Claude session on the box. Scripts go on stdin wrapped
in ONE `{ …; } </dev/null` block (no child can eat the rest of the script); the
`^**` banner is filtered out; files come back with
`scp -r musicmaking:C:/msys64/home/alexr/vampire-saved/<path>`.

| route | command | clone | dumps |
|---|---|---|---|
| MSYS2 MINGW64 | `ssh musicmaking 'C:\msys64\usr\bin\env.exe MSYSTEM=MINGW64 CHERE_INVOKING=1 /usr/bin/bash -l -s' <<'EOF'` | `/home/alexr/vampire-saved` | `/home/alexr/roms` |
| WSL2 (Linux user **`koneko`**) | `ssh musicmaking 'wsl.exe -e bash -l -s' <<'EOF'` | `/home/koneko/vampire-saved` | `/home/koneko/roms` |

`gh` is not installed on MSYS2: uploads run from the Mac (ruled 2026-09-13).

## START HERE — what is open

- **FIRST THING — THE STATE.md DISCIPLINE PASS: the law, the skill, a gate, then the
  clean-up.** The maintainer, 2026-09-14: *"we again have many open items (decisions,
  bugs, etc.) that are still listed as open with a mention that they are actually
  closed. This is a bad pattern that we must avoid by actually updating the correct
  documents, github issues, etc. and removing the closed items from the open ones.
  This will also shorten considerably STATE.md, limiting the size gymnastics"* — and
  the discipline must be *"documented and enforced, either in CLAUDE.md or in
  skills"*, not *"just a mention somewhere that never sees any systematic action"*;
  *"do it first thing in next session"*.
  **Measured 14z-153:** STATE.md 146.7 KB = three session groups 41.5 KB + THE LEDGER
  48.0 KB (184 lines) + standing sections 55.4 KB; at least 11 closed-but-listed
  entries in the open lists (Decisions pending, Open bugs, the cosmetic backlog, the
  deadness register); 0 open GitHub issues. **What writes the bad pattern down:**
  STATE.md's own header (standing entries "are marked DECIDED/FIXED in place, as
  always"; a decision leaves only once it "stops shaping active work"); the port
  skill ([VSP-10] "Mark rulings DECIDED in place", [VSP-17] "corrections are marked in
  place"); CLAUDE.md [VSP-17]/[VSP-10] say nothing of an item's exit. **What enforces
  it: nothing** — no gate reads STATE's open lists, its ~150 KB budget or its
  three-group rule, and STATE.md has no `doc_shape.tsv` row.
  **The order:** (1) the law in CLAUDE.md [VSP-17], its WORDING approved by the
  maintainer first — an open list holds only what is open; when an item closes, in
  the same commit its facts go where they belong (doc, register, gate, issue), its
  entry moves verbatim to its archive, and it is deleted from every open list;
  (2) STATE.md's header rule, with an archive named per open list; (3) the port
  skill's [VSP-10]/[VSP-17] (checkskills needs the law paragraph first); (4) a
  ci_static gate `test_state_open_lists` — a closed-marked entry in an open list
  fails, plus the size budget and the group count, with a must-fire control on a
  perturbed copy; (5) the clean-up, the gate's red as the checklist.
  **Questions to put:** the archive for closed bugs and backlog rows; a "standing
  rulings" home for decisions that still constrain work; the 48 KB ledger, whose
  home CLAUDE.md fixes.
- **The dedicated Linux server, once it exists:** (a) build the PUBLISHED Linux
  binaries there on the oldest LTS worth supporting and add a release-time
  resolution on a machine with no `-dev` packages (ruled option 3); (b) **the
  maintainer's todo** — run the same `--controls` tier there and compare its speed
  with this Mac's (`build/emu_controls_14z153/results.tsv`), at `--jobs 4` like for
  like. The WSL2 binaries are never published.
- **`tools/bundle_win_dlls.py` prints U+FFFD on MSYS2** (its em dash through
  cp1252) — build logs only, no record or verdict carries it.
- **Zabel j.LK proximity guard** — its own session (recording first).
- **The community cross-check**: specials/supers/throws still have no naming rigs
  on vsavj.
- Smaller, carried: `audit_mask_window_ff42a2` deprecated-vs-case-specific;
  `release/merged-m15` never packaged; #112 option (B); the living-docs
  generalisation (ruled, not scheduled); the wider-host re-measure of the pull
  queue's gain; the `hit` rigs' LP events whiff at contact range.

## TRAPS PAID THIS SITTING

1. **A capture that records its own exit status under `set -e` ends the script**
   and takes its reason with it — `x="$( (set +e; cmd 2>&1; echo "exit=$?") )"`.
   It was the whole of 14z-152's red without a reason; bbh now lints the shape.
2. **A native Windows python writes CRLF per PROCESS** — every python block that
   prints verdict text needs `sys.stdout.reconfigure(encoding="utf-8", newline="\n")`.
3. **A Finder `.DS_Store` in `release/` turned `test_release_asset_shape` red** on
   this Mac — the gate measured the host. Ignored by ruling since 2026-09-14
   (`tests/lib/os_metadata.sh`); a new release listing that uses `find` must pipe
   through it.
4. **A pull onto the box refuses when a commit adds files it has UNTRACKED** — move
   them aside, pull, re-verify the committed records there.
5. **Do not wait on a task that may already have ended** (the maintainer's
   reminder): poll its PID, or arm a Monitor on the PID — never `pgrep -f`, which
   matches its own command line.
6. **This MacBook kills harness background tasks under memory pressure** — run a
   long tier DETACHED (`nohup … &!`) and watch its PID.

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
