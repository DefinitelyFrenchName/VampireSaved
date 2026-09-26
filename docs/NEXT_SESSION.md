# NEXT SESSION — orientation (rewritten at the 14z-183b CLOSE, 2026-09-26)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line. Say so at the opener.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-183 and 14z-183b closes found and did
   is in their CLOSE rows (STATE 14z-183, 14z-183b).
0b. **A FREEZE OR RELEASE TIER NOW RUNS ON A SNAPSHOT (#153, ruled 2026-09-26):**
   `ROMDIR=... tests/run_on_snapshot.sh -- tests/run_all_static.sh --strict --cadence freeze|release` —
   immune to the working tree while it runs, its commit and inputs recorded under `build/snapshot_runs/`
   (`docs/project/snapshot_runs.md`). Work may continue in the tree beside it. The emulator tier is #181
   (not yet on a snapshot: run it in place, never beside edits to what it reads).
1. **M20 IS FROZEN, NOT RELEASED.** `freeze/merged-m20` (and donovan-m24 / huitzil-m31 / pyron-m25), commit
   `d4cd4d51`, `release/merged-m20/` packaged. The GitHub release (README still names merged-m19) is a
   separate decision — the maintainer's. A release run executes every emulator control (`--controls`) and
   the bitstream-cadence MiSTer gates; **the re-frozen `test_mister_prg_window` pair was copied from the
   freeze lane's own log and NOT re-run** — the release run is its verify.
2. **Nothing is pending a ruling** — STATE "Decisions pending" is empty.
3. **Open tickets, the maintainer's to order:** **#181** (the emulator tier on a snapshot — slice 2 of #153;
   probe its `~/.cache/vampire-saved` inputs first, the way slice 1's census did), **#179** (Phobos's Sitting Attack landing after a throw —
   ours displaced 31 px and not turning; the NEXT STEP is a native-vs-ours capture for the maintainer,
   before any mechanism work), **#180** (two stock-spend throws pay the thrower 0 on M19 and M20 alike; the
   third store pair never observed writing — a vs2 leg on the same inputs first), **#177** (movement parity
   vs native), **#178** (Hop Kick in Donovan's Dark Force), **#176** (the RNG's advance), #174, #145, #170,
   #159.
4. **Three close-time checkers are ON TRIAL** (`build/agent183/`, untracked): `packet_verify.py` (re-opens every
   packet quote), `class_letters.py` (every finding letter in exactly one test class), `classing_cover.py`
   (every retracted hit classed). Each has a plant that fires. Promote them to `tools/` beside
   `homes_tracked.py`, with a gate, or let them go. The 14z-183 CLOSE row, step (6), says why they exist.
5. **Three gate headers changed at the 14z-183 close, comments only** (`audit_move_parity`,
   `audit_df_field_readers_live`, `audit_reaction_class_live`: the part count 30 -> 32). The staleness gate
   will list them as a NOTE at session cadence; at the next freeze, `--stale` re-runs them.

## WHAT CLOSED THIS SITTING

**14z-183b:** #153 (the freeze/release static tier on a snapshot, immune to the tree: `tests/run_on_snapshot.sh`,
`tests/test_run_on_snapshot.sh`); slice 2 opened as #181. Ruled: *"Build slice 1"*, *"Listing + fingerprints"*, *"Close; new ticket
 for slice 2"* — `DECISIONS_HISTORY.md` "Ruled 2026-09-26 (14z-183b)". **14z-183:** #157 (FIXED in M20: a tenant throw pays the thrower the record's meter, and the damage scaler reads the
attacker — the two measured by `tests/audit_throw_registration.sh` / `tests/audit_move_parity.sh`), #134,
#138, #140, #154. Item 0b (every #175 figure re-derived, `tools/trap_air_static.py`). Ruled: *"Freeze M20
now"*, the #112 gate *"Pin it to M19"*, Phobos's landing *"Freeze, ticket it"* (#179).

## TRAPS PAID THIS SITTING (14z-183, 14z-183b)

9. **A per-gate re-run is a probe, not the runner** — mine dropped the runner's `VS_CADENCE` and read a
   freeze-cadence red as PASS (`docs/project/gotchas.md`). **`sh` reads a script as it runs** — editing
   `run_on_snapshot.sh` under a live run killed it at a syntax error; the runner now re-execs from a private copy.
10. **A control that "fires" because its copy crashed proves nothing** — three did at first; a control now
   counts only when the perturbation REACHES the run.

1. **A gate's printed diff is a `head -40` window.** Comparing two builds through gate logs compared a
   window; freeze the table on BOTH builds (copy aside, restore) and diff the files whole (gotcha filed).
2. **A rig or corpus commit re-frozen in the gates it was made for leaves every other gate that reads it
   stale** — four were, since 14z-181; `tests/run_all_emulator.sh --stale` names them once a run of record
   exists (gotcha filed).
3. **A kept parity work dir holds an UNPINNED native trace for its control part** — a timing reported to the
   maintainer from one was an artifact and retracted (gotcha filed).
4. **The freeze-cadence staleness gate wants the emulator run of record ON THE COMMITTED TREE** — so the order
   is: freeze commit, tags, `run_all_emulator.sh --freeze --stale`, then the freeze tier; three tier reds
   (tags, the `freeze` row, staleness) clear only in that order.
5. **A self-frozen `.sha1` passes by construction** — compare each to its predecessor's file before a freeze
   packet says the sets verified (the rule-checker's run 249 caught it).
6. **zsh**: an unquoted `$A` of `--artifact` flags does not split — use `${=A}`; `setopt null_glob` before a
   glob that may match nothing.
7. **The documentation packet took eleven rule-checker runs (251-261).** Each missed item was real: findings
   left out of the table, a test credited with replaying what it only guards, a stale count in a quoted
   header, a count restated in prose. Build the table from a FULL re-read of the session's rows, not a
   keyword scan. State each test's reach (replays / runs the fixed state / none) per finding. Point at
   artifacts instead of restating counts.
8. **The procedure check (runs 262-264) found two working-method slips.** At the opener, state the delegation
   scope exactly: figures that enter documents and freezes come from worker specs, and figures from my own
   runs are labelled as such in chat. Do not promise that every figure goes through a worker. Pass a
   rule-checker an EXCERPT, not a whole gotchas bucket: its readers cannot read ~6000 lines in one pass, and
   an OK then rests on slices. A session extract over ~580k characters is split into spans (`extract.py
   --from/--to`), one procedure run per span.
