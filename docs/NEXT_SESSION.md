# NEXT SESSION — orientation (rewritten at the 14z-133b CLOSE, 2026-09-05)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **M16 IS FROZEN, PACKAGED AND PUSHED. THE EMULATOR TIER IS 134/0/0/0
> ## GREEN TWICE (14z-133, and 14z-133b under the new runner-level MAME default,
> ## row-by-row identical). NOTHING IS OWED TO THE HARNESS.** All 14z-133/133b
> ## commits PUSHED 2026-09-05 at the maintainer's word (`0b973956`).
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
> ## since 14z-108 — seed 18269, verify the hash before flashing. Neither M16
> ## nor M13 has been to the board; M12 was green twice.
> ## **THE RELEASE.** `release/merged-m16/` is packaged for all three platforms.
> ## A release run is `--scope all` PLUS `--lane mister` (hours); anything red
> ## or skipped is a hard fail unless approved. **THREE `out`-scope rows are
> ## known problems** — two RED with exact diagnoses, one dead must-fire
> ## control — and need fixing or explicit approval first.
> ## **DECIDED AND DONE (14z-133b):** the runner exports `MAME_BIN` = the WIDE
> ## build unless the caller set one (`test_emulator_runner` §11 locks it); the
> ## full sweep re-run under it is 134/0/0/0 with the 24 instrument-changed
> ## gates named in `build/emu_sweep_14z133b/affected_set.txt`.
> ##
> ## # THREAD 3 — THE MERGED/SOLO WALK, 25 -> ~16, AND ONE OPEN QUESTION
> ##
> ## The rule is [VSP-175] + `gate_scoping_method.md` §9. Gate 1
> ## (`test_dualtrack`) RULED stock-vs-merged. Gates 2 + `flicker_attribution`
> ## + `fbneo_legacy_oracle` wait on B2. FIVE gates DISSOLVED (they run `vsav2`
> ## only). The remaining ~16 are HOMOGENEOUS: they boot our build as `vsavjw`.
> ## **THE OPEN QUESTION, asked and not yet answered:** keep walking one gate at
> ## a time, or re-point the ~16 defaults in one pass and let the RESULTS raise
> ## the exceptions?
> ##
> ## # ALSO OPEN
> ##
> ## * **B2** — the merged registry row + re-pointing the three legacy-oracle
> ##   gates. Deferred by ruling; B1 (the dual-key resolver) IS SHIPPED.
> ## * **STATE.md is ~210 KB** against ~150 KB. The 14z-131 group rolled early
> ##   (three groups now); the bulk is the standing **Decisions pending**
> ##   section, so **the `DECISIONS_HISTORY.md` pass** (ruled decisions that no
> ##   longer shape work move there verbatim, 14z-109) is the mechanism that
> ##   matters. Still owed.
> ## * **`audit_trap_sound`** passed the sweep — on `build/hui30`, a 14z-82c
> ##   build we do not ship. Flagged, not walked.
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
