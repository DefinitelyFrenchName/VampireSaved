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
> ##         --scope all --jobs 3 --resume --log build/emu_sweep_14z128
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
> ## **(1) `test_wide_profile` — REAL, and the fix is a rebuild.** The only FBNeo
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
> ## **(3) `audit_legacy_pairings` — WAS a real hole, now CLOSED and the spec
> ## ACCEPTED by `run_suite` on all three builds (`PASS masked-composite`, SUITE GREEN).** `105_legacy_2pwin_auto` sat in the corpus from 14z-123 as LEGACY
> ## content guarded by NOTHING. Basis frozen, shape measured identical on all
> ## three builds, both flickers attributed, `composite vsavj/masked-v2 2713,5868
> ## 889-2491` authored in all three sets. A census says it was the only such hole
> ## of 88 replays.
> ##
> ## # THEN, IN ORDER
> ##
> ## **(a) FINISH THE SWEEP** and triage what it finds. Adjudicate, never
> ## re-freeze: *"to know if we should fix the gate or what it caught, we must use
> ## data we can trust"*. `tests/expected/PROVENANCE.md` (new) answers the first
> ## question — which side rests on a measurement — in seconds.
> ## **(b) REGISTER THE M13 FREEZE** (`don_m19` / `hui53` / `pyron37` /
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
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index --check`
> ## + `gen_gotchas_index --check` + `doc_anchor_census --check`, exit statuses
> ## captured directly. Regenerate the GENERATED indexes in the commit that changes
> ## what they index, and AFTER the prose (a 14z-128 red came from exactly that
> ## ordering slip — the shared-writes re-freeze moved `annotations.md` by 16
> ## addresses).
