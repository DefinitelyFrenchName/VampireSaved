# NEXT SESSION — orientation (rewritten at the 14z-133b CLOSE, 2026-09-05)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## RELEASE DAY (M16) — the checklist (written 14z-134 while the run was in flight)

The run: `env -u MAME_BIN ROMDIR=../ROMS tests/run_all_emulator.sh --scope all
--lane all --strict --log build/emu_release_m16` (165 gates; `--lane all`, NOT
`--lane mister`, which would select only that lane). Everything below happens
AFTER it exits, in this order; steps 2-5 are `tests/`/`release/` edits the
runner's tree check would have flagged mid-run.

0. **READ THE VERDICT, NOT THE EXIT STATUS.** `build/emu_release_m16/runner.out`
   tail: PASS/SKIP/FAIL/TIMEOUT counts, the `== working tree ==` line must say
   `ok: no tracked file changed during the run`, and `results.tsv` is the record.
   **Expected: PASS 164 / SKIP 1 / FAIL 0** — the one SKIP is
   `audit_mask_window_ff42a2`, an instrument with no default subject, and under
   `--strict` it reads RED. Its approval is the entry at the top of STATE
   "Decisions pending" (recommendation (a): approve + record as a standing
   exception in its `ci_emulator.tsv` note). Anything ELSE non-green is a
   question, not an answer (STATE "HOW A RED IS ADJUDICATED"): which side rests
   on a measurement?
0b. **ONE PASS IS A HOLE — RE-RUN IT BEFORE READING THE RUN AS GREEN.**
   `test_mister_obj_oracle` recorded `PASS 0s`: it died at its
   `${JTSIM_SCRATCH:?}` demand (unset under the runner; siblings default it)
   and macOS bash 3.2 returns exit 0 for a `:?` abort after an EXIT trap
   (gotcha, `docs/project/gotchas.md`; STATE 14z-134). After the run: (i) the
   gate defaults `JTSIM_SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"`
   like its siblings and every `${…:?}` demand after a trap in the five-gate
   class becomes an explicit `[ -n … ] || { echo FAIL; exit 1; }`; (ii) the
   runner treats a log carrying a `.sh: line N:` shell error and NO verdict
   line as FAIL, with a `test_emulator_runner` control; (iii) delete that one
   row from `results.tsv` and `--resume` under the runner's shape (~65 min);
   (iv) only then read the totals. The four other shell-error lines in this
   run's logs are MAME teardown segfaults after the summary line — known,
   benign ([MFI-12]).
1. **STATIC TIER in the worktree, then fast-forward.** `ROMDIR=../ROMS
   tests/run_all_static.sh --strict` in `.claude/worktrees/decisions-pass`;
   gate on its GREEN line. Then `git merge --ff-only worktree-decisions-pass`
   on `main`, `git worktree remove .claude/worktrees/decisions-pass`,
   `git branch -d worktree-decisions-pass`.
2. **`tests/test_release_roundtrip.sh`: re-point the default `NAME` to
   `merged-m16`** (code says `merged-m14`, header says `merged-m15` — both
   stale; the M16 layout has NEVER been gated) and run it explicitly:
   `ROMDIR=../ROMS tests/test_release_roundtrip.sh build/m3b_merged23/rompath
   merged-m16` — sections 1-3 (round trip, applier refusals, the rule-7 chunk
   scan) and section 4 (the per-platform layout of the tree's
   `release/merged-m16/`). Verified read-only 14z-134 already: 3 platforms ×
   20 patches, manifests byte-identical (`f42f7569`, `M16`), BITSTREAM.txt
   canonical, `.rbf` sha256 matches, MRA parts 31/31 + 22/22, MRAs
   byte-identical to the field-tested bundle.
3. **MAINTAINER'S CALL — the release MRAs and the BUILD block.** The release
   copy predates the 14z-133b build line (0 occurrences). The ruling then:
   *"the current bundle on the board is untouched; the next freeze's MRAs and
   bundle carry it."* The RELEASE copy has not shipped. Options: keep it
   byte-identical to the field-tested bundle (as today), or regenerate the WIDE
   MRA with `tools/mister_mra.sh --no-rom --wide build/m3b_merged23 --out
   <tmp>` and copy it in (parts unchanged — the block is an XML comment;
   re-check 31/31 and `test_mra_build_line`). Recommendation: regenerate — a
   release MRA that names its build is what the build line was for, and the
   field verdict is about the parts, which do not move.
4. **TRACK THE RELEASE:** `git add release/merged-m16` and commit
   (`14z-134 RELEASE: merged-m16 …`, the run's counts and log dir in the
   message). Add `RELEASED 14z-134 (run 164/1/0 …)` to the M16 row of HANDOFF
   "Build registry" — release_format.md: the registry row, the tag and
   STATE's entry ARE the release's history.
5. **PUSH at the maintainer's word** (never unasked). `release/merged-m15`
   (M13) was never packaged — superseded before release; recorded, not owed.
6. **THE CLOSE RITUAL:** STATE 14z-134 entry completed (the run's row), this
   file rewritten, rollover check (STATE is ~135 KB), the doc-touch checklist,
   static tier. Stop the monitor; keep `build/emu_release_m16/` as the
   evidence log (the 14z-133b sweep dir is the precedent); sweep leftover
   emulator processes.

> ## **M16 IS FROZEN, PACKAGED AND PUSHED. THE EMULATOR TIER IS 134/0/0/0
> ## GREEN TWICE (14z-133, and 14z-133b under the new runner-level MAME default,
> ## row-by-row identical). NOTHING IS OWED TO THE HARNESS.** All 14z-133/133b
> ## commits PUSHED 2026-09-05 at the maintainer's word (origin/main = `98f305bc` + this note).
> ##
> ## # WHAT 14z-133 WAS, IN ONE LINE
> ##
> ## The owed run was made and went 131/3; the three reds were ONE class and not
> ## the artifact: a gate that boots `vsavjw` through `run_mame.sh` with
> ## `MAME_BIN` unset runs HOMEBREW's mame, which does not know the set, so the
> ## leg measures nothing and the liveness checks refuse. The runner exports no
> ## `MAME_BIN`; a developer shell that exported it hides the defect — which is
> ## how 14z-132's phase-C fix (a REAL relative-`$ROMDIR` defect, same symptom)
> ## came to be called complete. Four gates pinned, the class GATED
> ## (`test_mame_bin_pinned`, ci_portable), `--resume` re-ran the three under
> ## the runner: green. STATE 14z-133 has the 2×2 that establishes both defects.
> ##
> ## **VERIFY A GATE FIX IN THE RUNNER'S SHAPE: `env -u MAME_BIN ROMDIR=../ROMS
> ## tests/<gate>.sh`** — a shell with the variable exported proves nothing about
> ## what a release run will see.
> ##
> ## # READY FOR THE MAINTAINER, NOT YET DONE
> ##
> ## **THE FIELD TEST.** Bundle `../mister_fieldtest_14z132/` (both MRAs run
> ## `jtcps2w`; parts resolve 31/31 and 22/22; README lists what is new and the
> ## two structurally impossible things not to hunt). The `.rbf` has not moved
> ## since 14z-108 — seed 18269, verify the hash before flashing. **M16 IS
> ## FIELD-GREEN (maintainer, 2026-09-05): "Field tests are green." THE RELEASE
> ## IS ON.** M12 was green twice before it; M13 was never fielded alone.
> ## **THE RELEASE.** `release/merged-m16/` is packaged for all three platforms
> ## — ~~and~~ **BUT UNTRACKED (found 14z-134): it sits `??` in the main tree, never
> ## `git add`ed, unlike every earlier release directory; tracking it is step 4 of
> ## the RELEASE DAY checklist below.**
> ## A release run is `--scope all` PLUS `--lane mister` (hours); anything red
> ## or skipped is a hard fail unless approved. **THREE `out`-scope rows are
> ## known problems** — two RED with exact diagnoses, one dead must-fire
> ## control — and need fixing or explicit approval first.
> ## **DECIDED AND DONE (14z-133b):** the runner exports `MAME_BIN` = the WIDE
> ## build unless the caller set one (`test_emulator_runner` §11 locks it); the
> ## full sweep re-run under it is 134/0/0/0 with the 24 instrument-changed
> ## gates named in `build/emu_sweep_14z133b/affected_set.txt`.
> ##
> ## # THREAD 3 — THE MERGED/SOLO WALK: DONE, 16/16 GREEN ON THE MERGED BUILD
> ##
> ## One pass (16 gates = 271 s). 15 defaults re-pointed; `audit_tripwire_reach`
> ## already ran merged legs; `test_dualtrack` kept by ruling and brought in line
> ## with it (class v6, `oracle_classes.md`: six frozen offsets, never windows;
> ## onsets unmoved; must-fire control) — PASS on merged, PASS with zero flickers
> ## on solo. No merged-vs-solo difference in the artifact; the field verdict
> ## stands. B2 done the same sitting (below).
> ##
> ## # ALSO OPEN
> ##
> ## * **THE CI IS GREEN ON THE RUNNER — the first time ever (14z-133b, 62/0/0/0).**
> ##   It never needed ROMs. Six classes fixed across three pushes: BSD `sed -i ''`,
> ##   a tagless/submodule-less checkout, five mis-tiered gates, a hand loop that
> ##   classified unlike the runner, a reference-rot gate misreading force-added
> ##   side files, the patch series carrying its git's signature, and one libc-
> ##   specific control made platform-aware. It runs `run_all_static.sh --tier
> ##   portable --strict` with `FAIL_TAIL=80`. Deactivation was the maintainer's
> ##   conditional; the condition was false.
> ## * **TWO BACKLOG ITEMS (maintainer, 2026-09-05), recorded as DIRECTION in
> ##   STATE "Decisions pending" (top): (1) a level-0 skill split — what in
> ##   [CPE]/[CPH]/[MSC] is transferable to MAME/FBNeo or MiSTer work that is
> ##   not CPS-2; (2) a GENERIC, REUSABLE TEST HARNESS extracted from this
> ##   project's rules and rulings (CLAUDE.md included), as a separate thing,
> ##   then its skill. Neither scheduled; both wait behind the field test and
> ##   the release.
> ## * **B2 — DONE (14z-133b):** `merged-m16` registry row (whole-set key only),
> ##   `tests/expected/merged-m16/` verified 53/53 on the shipped build, the three
> ##   legacy-oracle gates on merged and green. The merged-vs-solo question is
> ##   CLOSED. The release runs every legacy oracle on the build it ships.
> ## * **STATE.md is ~210 KB** against ~150 KB. The 14z-131 group rolled early
> ##   (three groups now); the bulk is the standing **Decisions pending**
> ##   section, so **the `DECISIONS_HISTORY.md` pass** (ruled decisions that no
> ##   longer shape work move there verbatim, 14z-109) is the mechanism that
> ##   matters. Still owed.
> ## * **`audit_trap_sound`** — was asserting about `build/hui30` (14z-82c); re-pointed
> ##   to the merged build in thread 3 (14z-133b), PASS. Closed.
> ## * **THE TMP REAPER NOW HEALS ITSELF** (14z-133b): a hollowed jtsim scratch
> ##   clone is restored by `mister_mra.sh --ensure-scratch` (gate
> ##   `test_jtsim_scratch_heal`). If a MiSTer gate dies in 0 s at "generating
> ##   MRAs" again, that is a NEW mechanism — do not reach for `rm -rf` first.
> ## * **Two normalisations must stay at the point the value is first read:**
> ##   `$ROMDIR` (182 gates, 14z-132) and now `MAME_BIN` (per gate for `vsavjw`
> ##   legs, gated; plus the runner's exported default). In a runner they would resolve against
> ##   the changed directory / the launching shell and reproduce the bug.
> ##
> ## **IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
> ## --no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
> ## `gen_gate_index --check` + `gen_gotchas_index --check`, exit statuses
> ## captured directly — and in zsh, loop with `${=cmd}` or every one of them
> ## reports rc=127 (paid again 14z-133). A TEMPORARY script under `tests/`
> ## trips BOTH generators: delete it before the checks. Adding an anchored
> ## `**[VSP-N]**` also obliges the SKILL to define it, and the census must be
> ## re-frozen.
