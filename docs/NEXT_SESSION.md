# NEXT SESSION — orientation (rewritten at the 14z-134 CLOSE, 2026-09-06)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M16 IS RELEASED — LOCALLY. THE PUSH IS THE MAINTAINER'S WORD.

The release run (`--scope all --lane all --strict`, 165 gates, four lanes)
ended **PASS 164 / SKIP 1 / FAIL 0 / TIMEOUT 0** in three passes, all kept in
`build/emu_release_m16/`. The SKIP is `audit_mask_window_ff42a2`, APPROVED by
the maintainer 2026-09-06 as a standing exception (its registry note says so);
whether it becomes deprecated or case-specific is a LATER decision. Every
structural assertion the MiSTer lane makes on merged-m16 passed on every pass.
`release/merged-m16/` is TRACKED (it had sat untracked since the 14z-132
freeze), its WIDE MRA regenerated with the BUILD block, `test_release_roundtrip`
PASS on the m16 layout, HANDOFF's registry row says RELEASED. **14 commits
sit on `main` ahead of `origin/main`. Push when the maintainer says.**

## WHAT THE RUN COST — five harness defects, none the artifact (STATE 14z-134)

1. a `${VAR:?}` abort after an EXIT trap EXITS 0 on macOS bash 3.2 — a 65-min
   Verilator gate read `PASS 0s`; the runner now FAILS an exit-0 log with a
   shell error, `test_demand_after_trap` (ci_portable) bars the shape;
2. one 90-min timeout for 165 gates — two 3-hour gates killed; a row's 7th
   column is now its own timeout, the nine MiSTer rows carry MEASURED values;
3. a FRESH scratch clone could not simulate (a comment after a
   line-continuation backslash in the driver, 14z-133b) — fixed, and the
   fresh-clone census is the control;
4. `test_mister_prg_window`'s frozen pair was merged-m10's walker address
   (five freezes stale; cadence was `bitstream`, its pair follows the
   ROMSET) — re-frozen from the run's own measurement, cadence `romset`,
   `tests/expect/` now inside `test_expectation_provenance`'s scope;
5. `test_mister_qsound_ext` read its liveness probe by SLOT number where the
   driver numbers slots by ORDER — a probe counting 171 M reads read as dead;
   keyed on the bank now.
**The gate headers' runtimes were low by 40-140 %; the corrected figures are
in the headers and the registry.** [MSC-54] was paid AGAIN on a worktree copy:
a running script is the same file to the process reading it.

## THE VERILATOR LANE IS PARALLEL (maintainer-directed, built this session)

One scratch clone was the whole constraint. Now: `--jobs N` on the mister lane
gives each job slot its own clone (`<base>-slotN`, provisioned at the pin on
first use, under a minute), and the three two-leg gates run their legs at
once on `<scratch>` and `<scratch>-b` via the driver's `--profile-off` copy
(the shared `.rom` is never patched in place any more). Measured: four
clones, four cores at 99-100 %, ~100 MB each; qsound_ext + prg_window in
1 h 41 against ~4 h 55 serial. `test_emulator_runner` §13 is the ground
truth. **Two other machines are on offer** (a Windows Ryzen 9 3900X / 32 GB,
a coming Linux 5700G / 64 GB) — a remote runner is the next shape to cost;
`test_mame_parity` is the migration gate for any new host ([MFI-41]).

## ALSO THIS SESSION

* **The DECISIONS_HISTORY pass** — STATE 249 -> 134 KB; thirty ruled entries
  moved verbatim; seven stay (the two backlog directions, the
  living-documentation direction, Pyron's row 0x11, the Phobos ±1 residue,
  the community cross-check, the Zabel j.LK session).
* **The LEVEL-0 SKILL CUT** (backlog item 1, ruled accepted): `mame-fbneo-
  instruments` [MFI-1..46] and `mister-jtframe-core` [MJC-N], 109 of 145
  CPS-2 rules lifted with their NUMBERS, every old ID a redirect, a GENERATED
  `GUIDE.md` per level-0 skill (`tools/gen_skill_guide.py`, gate
  `test_skill_guides`) — the skill DIRECTORY is the portable unit. The finding:
  `cps2-emulation` had no CPS-2 content. Record: `skills_scope.md` §7.
* **Backlog item 2 (the generic harness) still waits**; its scope document is
  the natural next step (the MiSTer precedent: scope first).

## OPEN, IN ORDER

1. **PUSH** the 14 commits (maintainer's word). Then remove the merged
   worktree branch if it still exists (`git branch -d worktree-decisions-pass`).
2. **The deferred ruling**: `audit_mask_window_ff42a2` — deprecated or
   case-specific (maintainer: *"let's circle back to that later"*).
3. **The per-row timeout is IN; the runtimes are measured** — the next release
   run needs no `--timeout` flag; run it `--jobs 4` on the mister lane.
4. **`release/merged-m15` was never packaged** — superseded before release,
   recorded, not owed.
5. The standing items unchanged: Pyron's row 0x11 (measure-first was done;
   the port decision is the maintainer's), the Phobos ±1 residue, the
   community cross-check aerials, the Zabel j.LK session, #112 option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54], paid twice now).
