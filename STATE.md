# STATE — living progress log

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved), AMENDED
2026-09-14 (CLAUDE.md [VSP-17] and [VSP-182]): this file holds the RECENT
session groups and the STANDING SECTIONS; the full detail of every older
session lives verbatim in `STATE_HISTORY.md`, under THE LEDGER at its head.**
How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md (its LEDGER first) — section names are preserved verbatim
  in the archive. A reference to `STATE "Decisions pending"` for an entry no
  longer here resolves in `DECISIONS_HISTORY.md` (entries move there verbatim
  when ruled — since 2026-09-14; before that, once they stopped shaping work).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **AN OPEN LIST HOLDS ONLY WHAT IS OPEN (maintainer-ruled 2026-09-14).**
  "Decisions pending" holds undecided items only; nothing closed stays in it,
  however it is marked (struck through, DONE, FIXED, CLOSED). Where each thing
  goes instead:
  - a RULED decision -> its whole entry moves VERBATIM to
    `DECISIONS_HISTORY.md` in the commit that records the ruling; while the
    ruling still constrains work, ONE line stating the rule sits under
    "Standing rulings" here, and the line is deleted when it stops;
  - a BUG, COSMETIC ITEM or EVOLUTION is a TICKET — listed in
    `docs/project/tickets.tsv`, its story on its GitHub issue, never listed
    here; a STATE entry for one that closes moves VERBATIM to
    `STATE_HISTORY.md` under the closing session's key (CLAUDE.md [VSP-182]:
    the four questions, the closing comment);
  - "STANDING PRINCIPLE" and "THE DEADNESS REGISTER" carry the [VSP-21..23]
    anchors and stay; the register keeps its withdrawn rows by [VSP-23].
  `tests/test_state_open_lists.sh` enforces it, with the size budget and the
  group count below.
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move every session group but the newest (this sitting's own) to the TOP of
  STATE_HISTORY.md's body in newest-first order (below THE LEDGER, above the first
  archived `## Session` heading OLDER than the group)
  and add their one-line entries at the top of THE LEDGER there, composed from
  the group's own banner headers, then regenerate the archives' indexes
  (`python3 tools/gen_history_index.py`; `tests/test_history_index.sh` fails a stale one, #282). If this file still exceeds its budget (500 lines, 50,000 bytes:
  `tests/test_live_budget.sh`, #282 item F), roll the oldest kept group early. The standing sections never roll.
  **THEN RE-POINT WHAT CITED THE ROLLED GROUP (added 14z-173, after it bit):**
  a rollover silently breaks every `STATE.md § <section>` citation into the group
  it moved, and `tests/test_tickets.sh` is what notices — at 14z-173 it went red on
  #167's `decided` link anchoring "THE CLOSE TIER", which had just left STATE.md for
  the archive. After moving a group, re-point those citations to
  `STATE_HISTORY.md § <section>` (the convention 20 rows already use) and regenerate
  the page with `python3 tools/tickets.py page`. The sweep is one command:
  `python3 -c "..."` over `docs/project/tickets.tsv` comparing every `STATE.md §`
  anchor against STATE.md's current text — do it for ALL rows, not just the one the
  gate stops at.
- **THE CLOSE CHECKLIST (ruled 2026-09-18, 14z-167b; `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-167b)")**, after the close entry
  and before the tier: (1) a FINDINGS TABLE — every finding of the group, its live home and the test that
  reproduces it, APPENDED AS EACH FINDING IS PAID (`tools/findings_add.py`, #206 closed 14z-191), so the close reviews it rather than reconstructing it; (2) `python3 tools/close_findings.py <session>` — every GAP homed, every REVIEW answered
  by a home or an open item — and, since 14z-181, `python3 tools/homes_tracked.py "(N) THE FINDINGS TABLE"`
  (every file the table names as a home or test is tracked; exit 0) and `python3 tools/retraction_grep.py
  tests/rulecheck/retractions/<key>.tsv` (the sitting's retracted wordings, its reach controls found) (never by reclassifying the finding), every PROMISE fulfilled or made an open
  item; its clean result is never cited as completeness; (3) a pointer on every earlier row the sitting
  resolves; (4) the promises (the tool's PROMISES section); (5) scratch scripts whose figures a document
  or STATE row quotes are promoted into `tools/` or `tests/` — ON TRIAL: record how many and how many
  were promoted; (6) the DOCUMENTATION PACKET through the rule-checker (`recommendation`, the table as
  the claim), its verdict resolved like any run — a finding that is only a figure, a quote or a wording on an item the
  close's checks cover is fixed and re-checked by a FULL close-checks run, then resolved with `resolve --recheck`, no
  new packet run for it (#270, `docs/project/rule_checker.md` [VSP-184]).
- **THE CLOSE LOOP'S OWN COST (maintainer-ruled 2026-09-29, 14z-185b, #187/#188 "D + E + F now"; `DECISIONS_HISTORY.md` "Ruled 2026-09-29 (14z-185b) — #187/#188: D + E + F now, carry-forward by route A"):** (E) a close's checks run through `tools/close_checks.py` from a checks TSV under `build/` (rendered since 14z-189 from the standing set `tests/close_standing_checks.tsv` by `tools/close_standing.py render`, #204; the packet's claim by `close_standing.py claim`, #207): a fix is iterated with `--only <check>` (plus its plant and the figure check), and a rule-checker `prepare` cites a FULL run whose `status` exits 0; (F) a count a close states never includes `tests/rulecheck/runs/` (each `record` adds a 6-file run directory): exclude it, or read the count at `prepare` and say so; (D) doc edits are batched BEFORE a confirmation tier and no heavy job runs beside a tier; the browser-driving gate runs last in its tier (`# ORDER: last`, read by `tests/run_all_static.sh`).
- **THE LAST STEP OF THE CLOSE IS THE PUSH (maintainer-ruled 2026-09-10):**
  static tier strict green — since #269 (14z-200) a session close runs `--strict --confirm` on the previous close's run of record (every gate it re-runs has its controls executed; the rest are carried and named; HANDOFF "How to test"), a freeze or release every gate WITH every control executed (the default `all`) — the doc checks green, **the process
  sweep CLEAN** (C0.3, #172 slice S2, since 2026-09-23: `python3 tools/agent/sweep.py`
  run AFTER the tier, which spawns processes of its own, exits 0 — every survivor
  killed leaves first, as its hint lists them, or declared in writing with
  `--declare PID "REASON"` and named in the close entry), **the procedure check (C1, #172
  slice S3, since 2026-09-23) passed or resolved** — `tools/agent/extract.py` over the session's
  transcript, a `procedure` run of `tools/rulecheck.py` on it, every VIOLATED question answered by
  `resolve`, and — ruled 2026-09-24 (14z-179, *"Standing step"*) — `python3 tools/agent/transcript_gaps.py --subagents <session> --cap` exit 0
  (every worker at most Opus-class, none fallen back); BOUND to the push by `tools/agent/hooks/pre_push.py` since 14z-176b, which refuses a
  push of this repository until such a run covers a commit in the pushed range — nothing pending -> `git push
  origin main`; anything red or skipped leaves the commits local and the
  close entry says so.

## Session 14z-201 — **#282 filed and ordered; #269 measured and closed; #282 items E, A, B and F built.** A plain Opus 5.5 session on the #172 setup (transcript `979461fd`).

| | |
|---|---|
| opened with | the maintainer: *"read handoff.md, state.md and docs/next_session.md"*; `python3 tools/agent/sweep.py` CLEAN; `main` even with `origin/main` after a fetch. |
| **(1) #282 FILED, ITS SCOPE AND ORDER RULED** | The maintainer's ticket on the size of CLAUDE.md, STATE.md, HANDOFF.md and the close ritual, filed as #282 from a `measurer` census. Scope ruled: budgets of ideally 200 lines, at most 500, on the four live documents, bytes or width capped too; STATE.md keeps only the latest session in full; the archives get an index, not a budget (`DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-201) — #282's scope"). Order ruled E, A, B, F, C, D ("— #282's order of work"). |
| **(2) #269 MEASURED AND CLOSED `done`** | The last clause of its done-when, the miss rate on the new selection: the 14z-200 close tiers' carried gates traced on PILOT and checked for any read of a changed file — 0 of 56 and 0 of 80 — through five readers, each added after a rule-checker run found a read form the last one dropped (runs 2026-10-14-1073 to -1081, each resolved by work; 1072, 1074, 1076, 1078 and 1080 withdrawn unspawned; **1082 OK**). Report `build/agent201/t269/report.md` (local). The maintainer: *"Close done (Recommended)"*. The trace tool's split-line defect filed as #283, its other gaps added there; gotcha "A STRACE TRACE SCORED BY OPENED PATH MISSES FIVE READ FORMS". |
| **(3) #282 ITEM E BUILT** | Every archive opens with a generated, line-exact index: `tools/gen_history_index.py`, gate `tests/test_history_index.sh` (three controls), `dfbf47bf`. |
| **(4) #282 ITEM A BUILT** | Ruled *"At most 2"*, *"Now, as part of A"*, *"Defer to item C"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-201) — #282 item A"): `tools/check_state_lists.py` allows two session groups; [VSP-17] and the port skill's copy amended; 14z-198 and 14z-199 rolled verbatim to STATE_HISTORY; the standing rulings cut to rule plus pointer (a `reader` found 4 drifts, restored). STATE.md 91,033 -> 39,554 bytes (112,327 at the opener). `2f962b42`. |
| **(5) #282 ITEM B BUILT** | HANDOFF.md 1,811 -> 484 lines, 216,718 -> 46,130 bytes: its detail moved VERBATIM to the new `docs/project/operations.md`, `cps2_wide.md`, `release_format.md`, `mister_core.md` and `HANDOFF_HISTORY.md`, each moved heading leaving a stub; 12 ticket anchors re-pointed, the anchor census refrozen on the moved anchors only. `1da23b43`, `1c000561`. |
| **(6) #282 ITEM F BUILT** | Ruled *"50kB sounds like a good targer"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item F"): `tools/check_live_budget.py` holds the one copy of the budget (500 lines, 50,000 bytes, WARN above 200 lines); gate `tests/test_live_budget.sh` (ci_portable; controls over-lines, long-lines, missing-document); `check_state_lists.py` takes STATE's cap from it (150 KiB -> 50,000 bytes). |

## Session 14z-200 — **The 14z-199 packet re-run; #274 built and closed; #269 built on the maintainer's "C first".** A plain Opus 5.5 session at effort High on the #172 setup (transcript `e4e310c7`).

| | |
|---|---|
| opened with | the maintainer: *"read handoff.md, state.md and docs/next_session.md"*, then *"Re-run the 14z-199 close’s documentation packet through the rule-checker over the final state. The starting point is build/agent199/close/prepare_packet.sh and its premises. Also run test_release_launcher_bat on ERIS at the pushed commit, once ERIS is reachable."* and *"Then #274 and #269"*, and later *"ERIS should be reacheable"*; `python3 tools/agent/sweep.py` CLEAN; `tools/audit_roms.py` 76 of 76 members match; PILOT idle; ERIS not answering at first, then reachable. |
| **(1) THE 14z-199 PACKET RE-RUN; THE WINDOWS GATE AT THE PUSHED COMMIT** | ERIS ran `test_release_launcher_bat` at the 14z-199 push `16ecfaf7`: PASS, its `first-found` mode exits 1 (`build/agent200/bat/`). The 14z-199 close's documentation packet re-rendered over the final state (`build/agent199/close_rerun/`) went through rule-checker runs 2026-10-14-1029..1042: 1029 and 1032 withdrawn, 1030-1041 VIOLATED and each resolved by work on the 14z-199 record (its row (13), findings (y) and (z), finding (x)'s three mechanisms, row (12)'s attribution of the recurring QP3 to #263 — GitHub comments on #277 and #263), 1042 OK (`b497471c`). |
| **(2) THE FINDINGS TABLE** (checklist step 1: every finding, its live home, the test that reproduces it) | (a) the --confirm predictor of the day missed 15,013 + 4 traced reads in two gates added after the 14z-191 trace (an R4 git call written as a python list; a sibling program reading a directory named beside it), and the 14z-199 push's confirm tier carried one of them — `docs/project/gotchas.md` A TRACE SCORES ONLY THE GATES IT COULD RUN, `tools/static_confirm.py` / `tests/test_static_confirm.sh`; (b) #274's N-C narrowing, scored at 0 misses on the full trace, missed 9 reads in test_applier_vcdiff (a directory named as a shell default) that the trace never saw because the gate SKIPped on PILOT; the #269 "C first" re-trace with the tools present found it, fixed 8e1e4bbc — `docs/project/gotchas.md` A TRACE SCORES ONLY THE GATES IT COULD RUN, `tools/static_confirm.py` / `tests/test_static_confirm.sh` shdef-off; (c) test_trace_static_reads printed FAIL and exited 1 in a control mode whether or not it caught anything, so since 14z-191 its controls could never read LIES (rule-checker run 2026-10-14-1048) — `docs/project/gotchas.md` A CONTROL MODE THAT CATCHES NOTHING MUST EXIT 0, `tests/test_trace_static_reads.sh` / none (the not-caught branch was exercised once through the real runner by a scratch rig, not promoted: no gate checks a gate's own mode exit); (d) test_escape_triage and test_jtcores_twin went red on Linux only: a UTF-8 sort/ls reorders against their byte-ordered frozen lists (fixed 23987296, 24c548fe); other gates of the class are not censused — `tests/test_escape_triage.sh`, `tests/test_jtcores_twin.sh`, GitHub #278 / #278 (open); (e) a gotcha header written this sitting ('or say it is superseded') turned test_docshape red as session-shaped; the strict tier on a4c246f7 found it, red the same at its parent b497471c (fixed 5884128a) — `docs/project/gotchas.md` A COMMAND MOVED TO THE BACKGROUND AT ITS TIMEOUT IS STILL A JOB / `tests/test_docshape.sh`; (f) the #269 re-trace found three PILOT-only reds outside the predictor: xdelta3 3.0.11 makes release patches with verbatim reference-ROM runs, test_applier_page 3b fails on Python 3.12 (_winapi), and test_applier_page_browser's control does not finish under strace; filed release-only as #279, #280 and #281 — `docs/project/tickets.tsv`, GitHub #279 / #279 (open); (g) #274's packet took twelve rule-checker runs (1043-1051 and 1055-1057; 1043 and 1055 withdrawn, 1057 OK), each resolved by saving or measuring what the claim had stated from the chat; one figure quoted to the maintainer had only been printed — `docs/project/gotchas.md` A MEASUREMENT PUT TO THE RULE-CHECKER NEEDS EVERY CHECK'S OUTPUT SAVED / none (a working practice; the rule-checker's rounds are what measure it); (h) the 14z-199 packet re-run could not resolve its presentation findings with resolve --recheck: the render binds the newest transcript, a later sitting's — `docs/project/gotchas.md` A DOCUMENTATION PACKET RE-RUN IN A LATER SITTING CANNOT USE / none (a documented limit of the --recheck route; resolved by work and fresh packet runs (2026-10-14-1029..1042)); (i) the 2026-10-13 ruling record's "#269 is built on it, with the three-gate core" was a session's gloss (the option the maintainer chose named no core), and this sitting repeated it in DECISIONS_HISTORY.md and tools/static_confirm.py until rule-checker run 2026-10-14-1054 Q5 found the core never put to the maintainer; asked, the maintainer answered "C first" — `DECISIONS_HISTORY.md` #269's core: C first / none (no deterministic check reads whether a ruling record's So line adds to the option chosen; the rule-checker's Q5 caught it); (j) a measurer whose spec command outran the Bash tool's 120 s default polled for it with commands no spec named, twice (the close's procedure check, rule-checker runs 2026-10-14-1068 and -1071 QP5); the spec now says when a command needs a longer timeout — `docs/project/worker_spec.md` What each section is for / none (a rule for writing a spec; the procedure check's QP5 is what reads a worker's calls against it); (k) a wait for the 8e1e4bbc tier's tally (task b89gkl713), moved to the background at its timeout, finished unread after another command had read the tally; the third session to pay this (rule-checker run 2026-10-14-1070 QP4) — `docs/project/gotchas.md` A COMMAND MOVED TO THE BACKGROUND AT ITS TIMEOUT IS STILL A JOB / none (an orchestrator habit; the procedure check's QP4 is what finds an unread job) |
| **(3) #274 BUILT, FIXED ON A RE-TRACE, CLOSED** | A fresh trace of all 222 static gates on PILOT (`6e329411`, the session's build scratch present) found the predictor of the day missing 15,013 + 4 reads in two gates added since the 14z-191 trace; both re-run green at HEAD. Built: R4 in list form, the reach closed over sibling programs, R3c, N-C (R3 counts a directory only where it is named as a path), N-D (the session's `build/` scratch leaves every change set but a whole-tree reader's), the scorer's N-D clause, six controls in `test_static_confirm` and `scratch-unscored` in `test_trace_static_reads`, whose mode exit was found unable to read LIES and fixed (`a4c246f7`). The #269 "C first" re-trace (row (4)) then found N-C missing 9 reads in `test_applier_vcdiff`, a directory named as a shell default: fixed `8e1e4bbc` (control `shdef-off`), with `test_escape_triage` (`23987296`) and `test_jtcores_twin` (`24c548fe`) made to compare in byte order and a gotcha header that `test_docshape` read as session-shaped reworded (`5884128a`). The landing predictor (`6120360f`) misses 0 over the full trace and the nine-gate re-trace; on the 14z-199 change set it marks 154 of 222 stale and carries 68. Strict tier on a snapshot of `8e1e4bbc`: PASS 203, SKIP 1, FAIL 0, 391 of 391 executed controls honoured; confirm tier on `24c548fe`: PASS 203, SKIP 1, FAIL 0; the SKIP, `test_release_launcher_bat`, PASS on ERIS at `24c548fe`. Rule-checker runs 2026-10-14-1043..1051 and 1055..1057 (1043 and 1055 withdrawn; 1057 OK); report `build/agent200/t274/report.md` (local). **#274 CLOSED `done`** (row (5)). |
| **(4) #269 BUILT ON THE MAINTAINER'S "C FIRST"** | Built: `tools/static_confirm.py plan` re-runs a `# CONFIRM: always` core and any gate whose base row has fewer controls honoured than declared; `tests/run_all_static.sh` refuses `--confirm` at any cadence but session; `test_static_runner` sections 20-21 with three controls; HANDOFF, `must_fire_contract.md` WHEN, STATE's header and standing ruling; the superseded every-control-at-close rulings marked in place. Rule-checker run 2026-10-14-1054 Q5 found the core never put to the maintainer (a gloss of the 2026-10-13 record); put with a cost/benefit/risk analysis, the maintainer answered *"C first"*, then installed node, Chromium and xdelta3 on PILOT (*"the install is done on PILOT"*); the re-trace ran with the community workbook copied, `emu/jtcores` on its pin, and node 22 and Chrome for Testing in PILOT's `~/opt`. Landed `d75c5d55` with the three-gate core; against this sitting's strict run of `8e1e4bbc` the plan re-runs 162 of 222 and carries 60. Rule-checker runs 2026-10-14-1052..1054 and 1058..1062 (1058 withdrawn; 1062 OK); #269's GitHub comment corrects the gloss. **#269 stays OPEN until this close runs the confirm tier** (its done-when). |
| **(5) THE RULINGS; #274 CLOSED; #278-#281 FILED** | `DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-200) — #269's core: C first, and the parked index rows" (#120/#121: the index already read `parked`, nothing changes) and "Ruled 2026-10-14 (14z-200) — #274 closes done; four release-only tickets filed; the close is run": #274 closed with its closing comment; filed release-only — #278 (a census of locale-sorted compares), #279 (xdelta3 3.0.11 patches carry verbatim reference-ROM runs; PILOT is the Linux release builder), #280 (`test_applier_page` 3b on Python 3.12), #281 (`test_applier_page_browser`'s control under strace). |
| **(6) CLOSE (14z-200, 2026-10-14)** | The maintainer: *"Run the close (Recommended)"*. **Checklist:** (1) the findings table is row (2), (a)-(k), appended with `tools/findings_add.py` ((j) and (k) from the procedure check, after the documentation packet: the row copy re-written, run 1065's staged copy kept as `build/agent200/close/findings_row_packet1065.txt`, and the close checks re-run in full, 0 not as expected); (2) the standing checks rendered for 14z-200 (38, none added; `build/agent200/close/checks.tsv`), a FULL `tools/close_checks.py` run with 0 not as expected — `close_findings`, `homes_tracked`, `findings_anchors`, `retraction_grep` over `tests/rulecheck/retractions/14z-200.tsv` (each retracted hit MARKED), `rulings_verbatim`, `promise_check`, `open_tickets`, `scratch_census`; (3) no earlier row is resolved by this sitting beyond those row (1) names; (4) no promise listed for 14z-200; (5) scratch: 24 programs classed, four of them the sources of quoted figures (`score_cand.sh`, `bench2.sh`, `trace9.sh`, `core_cost.py`), none promoted (each a per-candidate wrapper of a tracked tool or a one-time analysis); (6) the documentation packet through the rule-checker — its run follows. STATE rolled 14z-197 to `STATE_HISTORY.md`; NEXT_SESSION rewritten, the 14z-199 opener archived. **The close tier** (strict, session cadence, the first close on #269's `--confirm`, over the `8e1e4bbc` results) on a snapshot of `5648e530` (`build/snapshot_runs/20261014T180024-5648e5305ca3`): PASS 203 SKIP 1 FAIL 0, controls 394 of 394 honoured, 166 gates re-run and 56 carried, wall 2,488 s; `--strict` reads it NOT GREEN on its one SKIP, `test_release_launcher_bat`, Windows-only (ERIS, below). **What it showed for #269's done-when:** the three core gates were re-run as "the core: its script carries `# CONFIRM: always`"; every carried gate is named with its reason ("carried (PASS in the confirmed run, predicted unaffected)") and the 18 cadence-deferred gates are named; a freeze or release run is untouched by construction (`--confirm` refused there, `test_static_runner` section 20); the miss rate on this close's selection was not measured here (the predictor's misses were scored on #274's traces, row (3)). **The process sweep:** CLEAN once the tier's snapshot was removed. **The procedure check (C1):** the transcript extract in six parts (`build/agent200/c1/parts.tsv`), rule-checker runs 2026-10-14-1066 to -1071, every plant caught; **1067 OK**, the other five VIOLATED, each finding checked against the extract before it was resolved (`build/agent200/c1/findings.md`). The agent's slips: (part 1) progress figures quoted from its own commands after the opener promised worker specs ("28 gates traced so far", "38 of 38"); "both prompts have been read" said of run 1035, whose prompt b was read from line 6 on; (part 3) the packet re-run's runs told as "eleven prepared ... nine" spawned with a gap, where the ledger holds thirteen, two withdrawn and ten VIOLATED by then (chat only); (part 5) task `b89gkl713` finished unread, finding (k). Workers' breaches: two measurers polled a command the tool had moved to the background (finding (j)), one paired SKIP texts to gates by an assumed order (used only as the set of missing tools), one added an `echo` and a comparison its RETURN excludes. Carried out in a later part, so not slips: the controls promised at record 1272 (`a4c246f7`) and the correction in place promised at record 4669 (made at record 5647). `tools/agent/transcript_gaps.py --subagents e4e310c7 --cap`: 0 breaches over 90 workers, no fallback. **The dashboard (#264):** the four datasets re-collected for 14z-163..14z-200 (1577 figures, every one classed) and uploaded (`datasets/*` version 4, `tiers` 5). **The final confirm tier** (strict, session cadence, `--confirm` over the `5648e530` results) on a snapshot of `344ebc5e` (`build/snapshot_runs/20261014T191725-344ebc5e39d7`): PASS 203 SKIP 1 FAIL 0, controls 394 of 394 honoured, 142 re-run and 80 carried, wall 2,619 s; the SKIP `test_release_launcher_bat`, PASS on ERIS at `344ebc5e` with its mode `first-found` exiting 1 (`build/agent200/bat/bat200d.log`, `bat200d_ff.log`, the archive's commit read back by `git get-tar-commit-id`). The commit after it changes STATE.md only (this sentence). A wait on that tier, moved to the background at its timeout (task `bsx5emqbt`), was stopped as a duplicate of the waiter already running. **Then the push.** |

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **The live documents' budget (#282, 2026-10-14/15, 14z-201):** CLAUDE.md, STATE.md, HANDOFF.md and docs/NEXT_SESSION.md at most 500 lines and 50,000 bytes each, the aim 200 lines; the archives are indexed, not budgeted — `DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-201) — #282's scope" and "Ruled 2026-10-15 (14z-201) — #282 item F"; gate `tests/test_live_budget.sh`.
- **No swarm model at max effort, ever (2026-09-29, 14z-185);** the Sonnet 5.5 `xhigh` worker preference was dropped (14z-192) — `DECISIONS_HISTORY.md` 2026-09-29 and "Ruled 2026-10-05 (14z-192) — the opener's answers".
- **The parity gates' per-frame level and RNG pins are their equalised input (2026-09-25, 14z-182):** they may write `RAM:$FF8116` and `RAM:$FF80D4` every frame on both legs; the rule-checker's Q3 reads that as a ruled premise — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (14z-182) — the parity gates' per-frame level and RNG pins".
- **The opener's sweep survivor is killed before the push only on the maintainer's command (2026-09-25, 14z-182):** the close puts the no-adverse-effect evidence to the maintainer and waits — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (14z-182) — the opener's sweep survivor".
- **The orchestrator is Opus 5.5 at effort High (2026-09-25);** a sitting on another model says so at the opener — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (after the 14z-181 close) — the orchestrator".
- **A /btw fork is exempt from the worker cap (2026-09-25, 14z-181);** the close names the fork — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (14z-181) — the worker cap".
- **The nine 14z-181 capture reads are all IDENTICAL (2026-09-25):** Victor's one-frame throw difference is documented and validated; #175's next step is the vs2 check — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (14z-181) — the maintainer's reads".
- **#172, the agent architecture (2026-09-23 to 09-24):** a block binds the task at fault, never the session; deterministic hooks hard-block and the model checker blocks until resolved in writing; the checker reads a generic checklist, never CLAUDE.md, at every push and close; workers are capped on the call; the rule-checker is a pinned definition; the orchestrator is a plain session, and the `--cap` read is a step of every close — `DECISIONS_HISTORY.md` "Ruled 2026-09-23 (14z-175) — #172" through "Ruled 2026-09-24 (14z-179)".
- **#171 Q6, the 73 poke read-back findings, are ruled as proposed (2026-09-25, 14z-181)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-25 (14z-181) — #171 Q6".
- **#171 is closed; gate gaps are caught as they surface, each its own ticket, and a review handed to the maintainer carries its references and context (2026-10-01, 14z-187b)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-01 (14z-187b) — #171 closed `done`".
- **FBNeo patch 0003 (drop SDL2_image) is RATIFIED for RELEASE builds (2026-09-21, 14z-173):** applied by `build_release_emulators.sh`, not by `setup_fbneo.sh` — `DECISIONS_HISTORY.md` "Ratified 2026-09-21 (14z-173) — FBNeo patch 0003".
- **#144: macOS blocks the binaries and right-click > Open does not get past it (2026-09-20, 14z-173);** clearing the quarantine flag works (`PLAY.command` offers it); the player READMEs are written for a non-developer; the applier page ships as a local file, one per release — `DECISIONS_HISTORY.md` "Ruled 2026-09-20 (14z-173) — #144 is macOS BLOCKING the binaries".
- **The applied set is DEFLATED and the QSound BIOS member is OPTIONAL (`--no-qsound-bios`) (2026-09-20, 14z-173)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-20 (14z-173) — the applied set is DEFLATED".
- **The deliverables' order, macOS first (2026-09-20, 14z-173):** standalone set, launcher per platform, #144/#145 on clean hosts, README pass, the applier app; macOS and MiSTer are the proof of concept — `DECISIONS_HISTORY.md` "Ruled 2026-09-20 (14z-173) — THE DELIVERABLES".
- **The standalone set lands in the RELEASE, not the build (2026-09-20, 14z-173)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-20 (14z-173) — the standalone set lands in the RELEASE".
- **The disabled EX route does the no-stock move (2026-09-18, refined 2026-09-19):** the tenants' vs2 EX input is read as its sub-pattern at every stock level; Pyron's 623+PP is the ES move with a stock and the normal move without — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-169) — the disabled EX route does the NO-STOCK move" and "Ruled 2026-09-19 (14z-170) — Pyron's 2623+PP with stock reads NATURALLY".
- **The 0x52 fix is scoped S1 (2026-09-18, 14z-169):** Phobos's two trap remaps stay on the solo track only — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-169) — the class-0x52 fix is scoped".
- **#136: all the analysis first, then the fixes, then relentless regression testing (2026-09-18, 14z-168)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-168) — #136: ALL the analysis first".
- **The tenants' Dark Force (2026-09-18, 14z-168):** vsav's Dark Force change with the shells' common rules, each tenant's vs2 startup window and personal Dark Force; compared against the vs2 EX move; the duration stays vsavj's (360/377/360); the tenants' vs2 EX input into the mode on our build is to be disabled — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-168)".
- **The tenants' defense rows become vs2's (2026-09-18, 14z-168)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-168) — the tenants' DEFENSE rows become vs2's".
- **The column shock and the Plasma Trap take vs2's class-0x52 rule (2026-09-18, 14z-168)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-168) — the column shock and the Plasma Trap".
- **No gauge is built during Dark Force (2026-09-18, 14z-168)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-168) — no gauge is built during Dark Force".
- **The close checklist, six steps (2026-09-18, 14z-167b)** — the steps live in this file's header; `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-167b)".
- **#136 goes over again by the 14z-164 census (2026-09-17):** per-event verdicts with stock, meter fraction and P2's HP, every "in DF" event asserted in DF, a same-data P2, the 13 rows re-labelled — `DECISIONS_HISTORY.md` "Ruled 2026-09-17 (14z-164)".
- **The rule-checker's Q3 and Q4 are BOUNDED, and a VIOLATED is resolved question by question in writing (2026-09-17, 14z-163)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-17 (14z-163) — the rule-checker's questions".
- **#136 is gone over again IN FULL, not only through its faithfulness control (2026-09-16)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-160)".
- **The static tier is turned around, C1-C4 adopted (2026-10-12, 14z-199):** a session close runs the changed gates plus a core (built as #269: `--strict --confirm`), a freeze and a release run everything — `DECISIONS_HISTORY.md` "Ruled 2026-10-12 (14z-199) — where session time goes and why rule-checker runs fail: …".
- **The order of work (2026-09-17):** a stable state first, then #148, then #152, then everything else — `DECISIONS_HISTORY.md` "Ruled 2026-09-17 (14z-161b)".
- **Release scope (2026-09-02):** every test whose subject is the released artifact runs at release; anything red or skipped is a hard fail unless approved at release time — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **A red gate is a question (2026-09-02):** first establish which side's expectation rests on a measurement — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Cross-game comparisons at a matched speed level and a pinned RNG (2026-09-15, #135, #142)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-158)" and "Moved 2026-09-14 (14z-154)".
- **No static substituted-wheel gate (2026-09-02);** the defence is [VSP-163] — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Oboro's intro stays (2026-08-28):** never delay round start or cut the intro for a cosmetic reason — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Community data (2026-08-31):** measurement is king; an inconsistent pattern means re-check our measurement first — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Cosmetic is optional (2026-08-27):** competitive 2P versus is the focus — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **No legacy character meets a tenant in 1P arcade (2026-08-28):** not built, not scoped — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Linux release binaries (2026-09-13, #121):** self-containment against a host-provided list plus ruled exceptions; WSL2 Linux binaries are never published; PILOT's `linux-x86_64` pair (Ubuntu 24.04, glibc 2.39) is the next release's Linux route — `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)" and "Ruled 2026-10-05 (14z-191) — the opener's answers".
- **Generator refactor policy (2026-08-21, #50):** no dedicated refactor of `tools/gen_donovan_patch.py`'s `main()` absent a new measured cost; a handler moves only when a test needs it — `STATE_HISTORY.md` "Session 14z-102 (post-freeze rulings)".
- **Don't assume; measure first; ask if necessary (2026-09-15, clarified 2026-09-16)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)" and "Ruled 2026-09-16 (14z-158b)".
- **Pipeline-image registry rows (2026-09-15, #96):** the M2 battery dispatches on the build's fingerprint; each freeze rebuilds both pipeline images and records whether they moved — `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)".
- **The merged set carries no tenant expectations (2026-09-15, #111)** — `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)".
- **#129 is the lowest priority of the open tickets, and its decision waits for captures (2026-10-08, 14z-196)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-08 (14z-196) — #129: captures first; the ticket stays the lowest priority of the open tickets".
- **bbh is its own project (2026-10-09, 14z-196; links settled 2026-10-10):** a Vampire Saved session makes no change in it and runs none of its tests — `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — bbh is its own project: …" and "Ruled 2026-10-10 (14z-197) — bbh's remaining links: …".
- **A fixed ticket is commented and labelled `done unshipped`, not closed (2026-10-10, 14z-197)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-10 (14z-197) — a fixed ticket is commented and labelled `done unshipped`, not closed".
- **#248: the launcher prefers the newest set, always, and the shipped PLAY.bat equals the generator at release only (2026-10-10, 14z-197)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-10 (14z-197) — #248: the launcher prefers the newest set, always".
- **#228 step 4: the per-replay alignment check runs once, at the conversion (2026-10-10, 14z-197)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-10 (14z-197) — #228 step 4: …".
- **#228 step 4: the four Huitzil stage gates run on `build/hui61` (2026-10-11, 14z-197)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-11 (14z-197)".
- **Pristine-only gates are `ondemand` (2026-10-09, 14z-196),** unless a change of ours once broke what they cover — `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #118's gates and every pristine-only gate move to an ONDEMAND scope".
- **#124 is parked (2026-10-09, 14z-196)** — `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked".
- **The map screen's tags (2026-10-03, 14z-189, #124):** #124's data fix ships only with gates that show every tenant tag right and every legacy tag unchanged — `DECISIONS_HISTORY.md` "Ruled 2026-10-03 (14z-189) — the #123-#129 analysis".

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

**[VSP-21]** "vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decisions pending (human)

Only undecided items live here; a ruling moves its entry to `DECISIONS_HISTORY.md` in the
commit that records it (CLAUDE.md [VSP-17]).

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads over every frame of six replays vs a 3,872-hit control (14z-197; 1,760 on the old clock's part-replays) | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. ~~OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89"~~ **ANSWERED 14z-91: the counter was REMOVED** — the `beam_list_type6` `RAM:$FF010C` counter deleted, which cleared all six `.pending` legacy replays (`HANDOFF.md` Build registry, the 14z-91 row (C)) |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.
