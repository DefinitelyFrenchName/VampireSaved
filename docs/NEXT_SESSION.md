# NEXT SESSION — orientation (rewritten at the 14z-128 CLOSE, 2026-09-03)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. THE SWEEP MAY STILL BE RUNNING.** 14z-128 built the emulator-tier
> ## runner and left its mame lane going. **FIRST COMMAND, before anything else:**
> ##
> ##     cat build/emu_sweep_14z128/results.tsv | column -t -s$'\t'
> ##     pgrep -f run_all_emulator     # empty = it finished or was killed
> ##
> ## **RESUME IT** (it skips everything already recorded):
> ##
> ##     ROMDIR=... tests/run_all_emulator.sh --lane fbneo --lane mame \
> ##         --scope all --jobs 3 --resume --timeout 14400 \
> ##         --log build/emu_sweep_14z128
> ##
> ## **`--timeout 14400` IS NOT OPTIONAL for this lane.** The 5400 s default is
> ## too low for the corpus soaks — `audit_guard_corpus` alone is 79 replays x 4
> ## legs = 316 guarded MAME runs, ~2 h at `JOBS=2`. A TIMEOUT row there means
> ## the runner's default, not the build. A per-row timeout in
> ## `ci_emulator.tsv` would be the real fix.
> ##
> ## Per-gate logs are `build/emu_sweep_14z128/<gate>.log`. Nothing is red that
> ## was not adjudicated below. No build byte moved this session.
> ##
> ## # WHAT THE RUNNER IS, in one paragraph
> ##
> ## `tests/run_all_emulator.sh` is `run_all_static.sh`'s twin for the tier that
> ## needs MAME, FBNeo or the simulator; `tests/ci_emulator.tsv` is its registry,
> ## one row per gate (`gate / lane / scope / args / note`), completeness enforced
> ## BOTH ways on every run. Lanes: `prereq` (instruments — runs FIRST,
> ## sequentially, and a red there STOPS the run, [CPE-24]), `fbneo`, `mame`,
> ## `mister` (opt-in, HOURS). `--scope all` adds the out-of-release-scope rows.
> ## Ground truth: `tests/test_emulator_runner.sh`. Read [VSP-164].
> ##
> ## **PREREQ LANE WAS 20/20 GREEN**, `test_mame_parity` included — so the
> ## instruments are sound and everything measured after them is evidence.
> ##
> ## # THE THREE REDS, ALREADY ADJUDICATED — do not re-freeze any of them
> ##
> ## **(1) `test_wide_profile` — WAS real, FIXED AND GREEN.** The reference
> ## binary was three days older than the harness patch; both binaries were
> ## rebuilt from one tree state and the gate PASSES in full — section 1, the
> ## emulator superset invariant, 12/12 replays bit-identical in work RAM AND
> ## framebuffer, plus inertness 12/12 and the B4 canary 12/12. The reference
> ## now lives at the canonical path the gate defaults to, and the gate refuses
> ## it if it ever falls behind the harness again. Kept here for the record:** The only FBNeo
> ## reference binary on this machine (`~/.cache/vampire-saved/fbneo_ref`) was
> ## built 2026-08-14 while harness patch `0001` last changed 2026-08-17. The gate
> ## now defaults to that path AND REFUSES it as stale, with the commands in its
> ## own failure message. **DO THIS FIRST WHEN NO LANE IS USING FBNeo:**
> ##
> ##     WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo ~/.cache/vampire-saved/fbneo_ref
> ##     tools/setup_fbneo.sh            # restore the WIDE binary — do not skip
> ##     ROMDIR=... tests/test_wide_profile.sh
> ##
> ## It cannot be done while the mame lane runs: reverting the profile patch hands
> ## `test_m2a_stage4_xemu` (position 14 of that lane) a non-WIDE binary.
> ##
> ## **(2) `test_phasec_image` — two STALE PREMISES, neither a defect in the
> ## build.** Section 1 compares against a hardcoded donovan-m2c-era stock
> ## fingerprint; the value it measured, `e86e1d04`, is exactly the M13 stock twin,
> ## so the pipeline reproduces correctly and the CONSTANT is what is wrong (fix it
> ## at the M13 registration, ideally by resolving through `registry.tsv` instead of
> ## a 40-hex literal). Section 4 zeroes CPU:$400010 expecting the Phase-C sound
> ## table, but wide_ext's first placement is now region `x101aca` = DONOVAN'S CPU
> ## AI SCRIPT BLOCK, which replay `12_donovan_vs_cpu` never reads because Donovan
> ## is the PLAYER there. Needs a zeroing target that replay reads, or a replay
> ## where a tenant is CPU-controlled.
> ##
> ## **(3) `audit_legacy_pairings` — WAS a real hole, now CLOSED, the spec
> ## ACCEPTED by `run_suite` on all three builds, and the gate itself RE-RUN
> ## GREEN (`LEGACY-PAIRING COVERAGE: PASS`). Its FAIL row in the sweep log is
> ## the pre-fix state — do not re-triage it.** `105_legacy_2pwin_auto` sat in the corpus from 14z-123 as LEGACY
> ## content guarded by NOTHING. Basis frozen, shape measured identical on all
> ## three builds, both flickers attributed, `composite vsavj/masked-v2 2713,5868
> ## 889-2491` authored in all three sets. A census says it was the only such hole
> ## of 88 replays.
> ##
> ## **(4) `audit_merged_vec3` — FIXED, and it was never the game.** It reported
> ## "rig dead — the replay or pokes moved" since 14z-109, when `A1`/`A3` were
> ## added to the PROBE line and its A0 extractor still required `A6` to follow
> ## `A0` directly. Parses by field name now; PASSES, and confirms the 14z-81
> ## satellite defect stays fixed. Its FAIL row in the sweep log is pre-fix.
> ##
> ## # THE SEVENTEEN REDS, BY WHAT THEY NEED — the whole triage, done
> ##
> ## 132 PASS / 17 FAIL of 149 recorded (prereq 20 + fbneo 6 + mame 129 = 155;
> ## the six unrecorded are all `out` scope). **NOT ONE was a defect in the
> ## shipped artifact.** Seven are already CLOSED:
> ##
> ## | gate | state |
> ## |---|---|
> ## | `test_wide_profile` | **FIXED, GREEN** — reference rebuilt; 12/12 superset invariant |
> ## | `audit_legacy_pairings` | **FIXED, GREEN** — the five-session hole, spec authored + accepted |
> ## | `audit_merged_vec3` | **FIXED, GREEN** — its parser; confirms the 14z-81 defect stays fixed |
> ## | `test_m2a_stage4_oracle` | **FIXED, GREEN** — re-pointed off an M2a build |
> ## | `test_hui_oracle` | **FIXED, GREEN** — re-pointed off pre-v1.1 `build/hui4` |
> ## | `audit_walker_repoint` | **VERIFIED PASS** — needed an operand; vanilla walkers take 0 hits |
> ## | `audit_empty_tiles` | **VERIFIED PASS** — needed an operand; no blank group-C tile |
> ## | `audit_mask_window_ff42a2` | **FIXED** — an instrument; SKIPs with its reason now |
> ##
> ## **STILL OPEN, and what each needs:**
> ## * `test_m2b_stage6` + `test_phasec_image` — **ONE cause: register M13** (b).
> ## * `test_pyron_soak` + `test_pyron_ladder` — **the only CRASH class**, on
> ##   stage-image builds the gates make themselves. `audit_guard_corpus` PASSED
> ##   on the MERGED build (1727 s, corpus x 4 legs), so the artifact is not
> ##   implicated. Needs a bisect; the select flow they force id 0x11 through has
> ##   changed three times since the soak was last clean (14z-67).
> ## * `audit_continue_switch` — the frozen arcade trajectory moved ([VSP-132]);
> ##   re-measure it, do not re-freeze the verdict.
> ## * **TWO DEAD MUST-FIRE CONTROLS, and this is the class to take most
> ##   seriously** — a dead control is how a gate goes GREEN while asserting
> ##   nothing, which is the failure [VSP-19] exists for. Both gates caught
> ##   their own and refused to give a verdict, which is the system working.
> ##   `audit_qs_voice_wav`: the LAST-voice control does not fire (a last-window
> ##   boundary in the checker; the audio itself is clean, 74 windows 0
> ##   suspects). `audit_hitclass_map_cost`: the no-thunk twin does NOT crash,
> ##   so an END-clean run proves nothing about the thunk — and its own message
> ##   forbids re-pointing the control until section 4's map probe says why.
> ##   **Neither is fixed by relaxing the control.**
> ## * `audit_type_dispatch_range` — probes a mechanism 14z-91 deleted; the
> ##   update-or-drop decision in STATE.
> ## * `audit_region_movability`, `test_m2a_stage2_data` — `out` scope; a
> ##   duplicate manifest key and a half-pruned M2a dir, both diagnosed in the
> ##   registry rows.
> ##
> ## # THE PATTERN IN THE SWEEP'S REDS, so the next batch is quick
> ##
> ## Ten reds by the time the lane was a third done, and **every one was the
> ## suite, not the build**. Four shapes, in falling frequency:
> ## 1. **A STALE DEFAULT BUILD** — the gate names an M2a-era dir nothing has
> ##    maintained (`test_m2a_stage4_oracle`, `test_m2a_stage2_data`). Re-point,
> ##    or give it `args` in the registry, then RE-RUN before believing it.
> ## 2. **A REQUIRED OPERAND WITH NO DEFAULT** — dies on its own usage line in
> ##    0 s (`audit_walker_repoint`, `audit_empty_tiles`). **That class is now
> ##    CLOSED**: a census found exactly two and both have `args`.
> ## 3. **A PARSER OR AN INJECTION THE TREE OUTGREW** — `audit_merged_vec3`
> ##    (PROBE line gained registers at 14z-109), `audit_region_movability`
> ##    (injects a `region_space` key donovan.toml has carried since 14z-111),
> ##    `audit_type_dispatch_range` (scrapes a thunk 14z-91 deleted).
> ## 4. **A FROZEN CONSTANT THE RULING MOVED** — `test_phasec_image`'s
> ##    donovan-m2c stock fingerprint, against a stock twin that legitimately
> ##    moves at every freeze ([VSP-94]).
> ## **A 0-SECOND FAIL IS ALWAYS SHAPE 1 OR 2**, and a fail far shorter than the
> ## gate's own quoted runtime means it bailed before measuring — read that
> ## number first, it is the cheapest triage signal in the log.
> ##
> ## # THEN, IN ORDER
> ##
> ## **(a) FINISH THE SWEEP** and triage what it finds. Adjudicate, never
> ## re-freeze: *"to know if we should fix the gate or what it caught, we must use
> ## data we can trust"*. `tests/expected/PROVENANCE.md` (new) answers the first
> ## question — which side rests on a measurement — in seconds.
> ## **(b) REGISTER THE M13 FREEZE — AND IT IS NOT HOUSEKEEPING: IT CLEARS TWO
> ## RELEASE-SCOPE REDS.** `test_m2b_stage6` and `test_phasec_image` section 1
> ## both fail for ONE reason — the current manifests build the M13 generation
> ## (fingerprint `e86e1d04`, the M13 stock twin) and M13 is not in
> ## `registry.tsv`, so the fingerprint dispatch finds no expectation set.
> ## Everything else in `test_m2b_stage6` passed: five guarded soaks END-clean,
> ## three pixel frames identical.** (`don_m19` / `hui53` / `pyron37` /
> ## `m5_stock14` / `m3b_merged22`, boot title SAVED): `run_suite.sh --freeze` per
> ## track (~5 h), registry rows, `freeze/*` tags, HANDOFF's build-registry row and
> ## "Current WIDE builds", and the one-line shared-writes re-point it owes (three
> ## `boot_title_saved_*` rows per tenant, already reviewed at 14z-127).
> ## **(c) NO RELEASE** — still deliberately held back.
> ##
> ## # TWO DECISIONS WAITING ON THE MAINTAINER (STATE "Decisions pending")
> ##
> ## **THE RELEASE SCOPE** — `ci_emulator.tsv` marks 139 gates `release` and 25
> ## `out`, each `out` row leading with the reason keyword. That column is what a
> ## release hard-fails on, so it is a ruling, not a preference. Three judgement
> ## calls are named in the entry.
> ## **THE `gap_be27a` BANK-MAP ROW** — it models ONE 32-long table as two 32-entry
> ## WORD tables, which is what blinded the shared-writes guard and what makes the
> ## generated character pages read two rows at the wrong address. The correction
> ## is one row, but `kind` is load-bearing in `extract_char.py` and
> ## `gen_donovan_patch.py`, so it can move BUILD OUTPUT: half a session in a
> ## build-touching window, rebuild one track and diff `patch.json`.
> ##
> ## # OPERATIONAL, and each was paid for tonight
> ##
> ## * **Never edit a running `.sh`** — sh reads by byte offset ([VSP-110]). Two
> ##   runner fixes needed the sweep stopped first; killing it and relaunching with
> ##   `--resume` costs only the gates in flight.
> ## * **Do not run the static tier while the sweep runs** — it timed out at two
> ##   minutes under load. Batch static work, run it when the machine is quiet.
> ## * **Name `MAME_BIN` for a `vsavjw` run.** A bare `run_replay_mame.sh vsavjw`
> ##   with the default binary produces NO dumps and NO error.
> ## * **Name the SET for `run_suite.sh`, and READ THE DISPATCH LINE it prints.**
> ##   `tests/run_suite.sh` with no `[set]` argument defaults to `vsavj`, so a
> ##   WIDE rompath chain falls through to the pristine set in `$ROMDIR` and it
> ##   dispatches to the `vsavj` expectation set — [VSP-58] in a new tool. It
> ##   SAYS SO (`build fingerprint -> expectation set '...'`); that line is the
> ##   check.
> ## * The runner batches `--jobs` gates and waits for ALL of them before the next
> ##   batch, so one slow gate idles the other slots. A proper slot loop would help
> ##   throughput; it is not a correctness problem.
> ## * `test_build_ref_rot.sh` has NO synthetic must-fire control — its
> ##   extraction and verdict logic are inline and can only be exercised against
> ##   the real tree. Its pattern was extended twice (14z-97, 14z-128) by
> ##   hand-verification. Factoring the block behind a root override would let it
> ##   be controlled properly; small, and it is the one gate about rot that
> ##   cannot demonstrate it detects rot.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index --check`
> ## + `gen_gotchas_index --check` + `doc_anchor_census --check`, exit statuses
> ## captured directly. Regenerate the GENERATED indexes in the commit that changes
> ## what they index, and AFTER the prose (a 14z-128 red came from exactly that
> ## ordering slip — the shared-writes re-freeze moved `annotations.md` by 16
> ## addresses).
