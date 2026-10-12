# NEXT SESSION — orientation (rewritten at the 14z-198 CLOSE, 2026-10-12)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model).
- Every freeze and recommendation goes through the pinned `rule-checker`, with the prompt files pasted VERBATIM.
- Then `record --session <transcript id>`, and `resolve` on ONE line with one label per violated question, only AFTER the work it names exists.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.** An ERIS tier script starts headless (HANDOFF "AND ON ERIS, SPLIT BY HOST").

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the close found and did is in STATE 14z-198's CLOSE row.
   merged-m23 is RE-RELEASED (2026-10-12): the nine assets on `freeze/merged-m23` replaced, the 15 done tickets closed.
1. **FIRST — WHERE SESSION TIME GOES, AND WHY RULE-CHECKER RUNS FAIL** (the maintainer, at the 14z-198 close: *"Also, for next session, we need to take a deep look at how much time we spend on what: I have a feeling we are running each session checks and tests that really are release-only scope. More importantly, the number of violations we encounter make me wonder if it's the agents being unreliable or the instructions/checks/wording that is facilitating these failing."* — `DECISIONS_HISTORY.md` "Ruled 2026-10-12 (14z-198) — next session: where session time goes, and why rule-checker runs fail"). Data: the session dashboard (`tools/session_metrics.py`, HANDOFF's routing row) and `tests/rulecheck/ledger.tsv`. A figure to start from: the 14z-198 close tier ran 8,636 s wall, its controls 6,375 s, `test_close_tools`'s ten controls 4,065 s of that (`build/static_runs/20261012T124446Z_16164`).
2. **#265 in the near future** (the maintainer: *"the push is fine but we need to address #265 in the near future"*).
3. **Then ask the maintainer for the order of work.** The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends);
   - medium: #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #262, #263 (the C1 extract's two gaps); #265 and #266, filed at the release on the maintainer's word (below); #267 (the session ledger as a static page in `docs/site/`; hosting and what to publish are the maintainer's calls), filed after the push; #260 (the submodule-pin check is implemented and runs at every close; kept open by the maintainer).
   **#265 — the maintainer asked for a deep dive after the release** (*"carry the skip, open a ticket about it so we can deep dive after the release"*): `audit_mask_window_ff42a2` SKIPs at every release and the staleness audit has FAILed that SKIP at release cadence since 14z-197 (a SKIP newest row has no green).
4. **#266 — PILOT's GNOME Shell segfaults under Wayland at every boot since 2026-10-09**, so `audit_release_linux_desktop` cannot run; the crash report is root-only on PILOT (`/var/crash/_usr_bin_gnome-shell.120.crash`). The release carried the gate's SKIP on the maintainer's word.
5. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE 14z-198 finding (i)). The one-line correction stales the 76 emulator gates that follow `tests/replays/`, so make it in a session that runs those gates anyway.
6. **#118 — the chars gate, PARKED on branch `t118-196`** (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #118's gates and every pristine-only gate move to an ONDEMAND scope; the chars gate parked"); rule-checker run 914 of that worktree is VIOLATED on Q1 and unresolved. **#129 stays the lowest priority**, captures first.

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked").

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **An SSH that cold-starts ERIS's WSL VM brings WSLg up with no desktop, and every MAME process then waits 100-180 s on its sockets.** Unset `DISPLAY WAYLAND_DISPLAY PULSE_SERVER XDG_RUNTIME_DIR` and export `SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy` after sourcing the profile (`docs/platform/gotchas.md` "ON A WSL2 BOX REACHED ONLY OVER SSH").
- **`--jobs 12` on ERIS pushes rows past half their cap**; one gate per runner, six at a time, keeps the headroom (HANDOFF "AND ON ERIS, SPLIT BY HOST").
- **Three release gates are host-bound:** `test_mame_parity` needs a reference MAME distinct from the build under test (this Mac's Homebrew one); `test_release_binaries` and `test_readme_recording` need the host's own release binaries; the Linux-release pair runs on PILOT.
- **A replay added to `tests/replays/` is an input to every gate that globs the corpus, and a frozen basis widens more corpora** (`docs/project/gotchas.md` "A REPLAY ADDED TO THE CORPUS IS AN INPUT TO EVERY GATE THAT GLOBS IT").
- **A gate that gains a control is run through `tests/run_all_emulator.sh --controls` before it is committed**: the runner reads every declared control from the normal run (`docs/project/gotchas.md` "A DECLARED CONTROL THAT FIRES ONLY AS A").
- **The audit orders runs by the mtime of `results.tsv`**: a row copied from another host keeps its time, so the last-written row of a gate is its run of record.
- **The session dashboard** (`tools/session_metrics.py`) is refreshed by hand at each close (HANDOFF's routing row).

## WHAT CLOSED THIS SITTING (14z-198)

- **Released:** merged-m23 re-released; the done-unshipped tickets closed `done` with it: #236, #238, #239, #240, #245, #246, #247, #248, #249, #250, #251, #252, #253, #255; and #264 (the session dashboard).
- **Filed:** #265, #266.
- **Ruled:** the release is a re-release of merged-m23; the release carries the two SKIPs (`audit_mask_window_ff42a2`, `audit_release_linux_desktop`); #264's implementation was the session's choice. Each, in the maintainer's own words, is its `DECISIONS_HISTORY.md` entry "Ruled 2026-10-11 (14z-198) — ..." or "Approved 2026-10-12 (14z-198) — ...".
