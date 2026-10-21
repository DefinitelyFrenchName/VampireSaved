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
- **A SESSION GROUP'S FORM (since 14z-201, #282 item C; `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item C"):**
  `## Session KEY — banner`, then `### opened with` and one `### (N) TITLE` section per piece of work, wrapped at
  about 120 characters. Since #288 (2026-10-15) a group has no findings-table section: a finding's fact is homed in its
  document when it is paid for ([VSP-12]). Groups up to 14z-202 keep theirs (`docs/project/findings/<key>.tsv`).
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
- **THE SESSION CLOSE — ROLLOVER, CHECKLIST, TIER, SWEEP, PROCEDURE CHECK, PUSH — is `docs/project/session_close.md`**
  (#282 item C, ruled 2026-10-15): its step table is the one copy, in order, and `python3 tools/close.py` runs it.
  The rollover rule, the six-step close checklist, the close loop's cost rules and the push rule that stood here
  moved there on 2026-10-15.

## Session 14z-205c — **#292 declined; #277, #262, #263 closed; #299's MRA lock and the dead-control scoring; #229's Q1 answers and both re-rigged joins confirmed; #296 and #299 measured on ERIS and PILOT; #302, #303, #304 filed.** Opened 2026-10-20 on the same transcript (`995e7259`) after the 14z-205b close (`b91532d8`, pushed).

### opened with
The maintainer, on whether to close and start the next session without clearing, while #286 runs on PILOT: *"Should we
formally close the session and start the next (without clear or exit)? So that we can go on while #286 finishes?"*,
then *"yes"* to opening 14z-205c with the sweep and #266. No second close: the records written after the 14z-205b push
(its group, "after the push") wait for this session's close. The opener sweep: one survivor, fork X1's bounded wait on
PILOT's `score.end` (#286, started in 14z-205b), declared; an old open task (`bas3z7por`, the 14z-194 pursuit-rig search)
holds no process. #286 on PILOT at the opener: trace done (228 of 228 gates), the committed predictor's score PASS
(87,773 pairs, 0 misses; six gates non-zero under the trace), the narrowed score running, the control not started.

### (1) #266 — DONE, AWAITING RELEASE (NOT CLOSED)
PILOT's `apt` history read again (`build/agent205c/t266/pilot_apt_display.txt`, local): the build toolchain's one `apt
install` run of 2026-10-02 14:50:15 carried an `Upgrade:` line, the Mesa runtime `25.2.8-0ubuntu0.24.04.2` → `.3`, so
#266's body ("No graphics-stack package changed after 2026-10-02") read the install list and missed it; the body is
marked corrected in place. Homed: `docs/project/build_environments.md` "PILOT'S DISPLAY CARD IS VirtIO-GPU" (the card,
the crash, the gate's PASS of 14z-205b, the logged-in-session condition) and `docs/platform/gotchas.md` "AN `apt
install` ALSO UPGRADES WHAT IT PULLS IN"; `docs/GOTCHAS.md` regenerated; row 266 carries the learned and wrong answers.
**The closure was withdrawn** by rule-checker run `2026-10-20-1154` (VIOLATED Q1 Q4): the to-do ends "so the next
release carries its PASS", and the gate exits 0 on a SKIP when nobody is logged in on PILOT, which no control catches.
#266 stays open, done awaiting release: the comment of 2026-10-20 (14z-205c) says it closes when the next release's
battery records the gate PASSING on PILOT, with the maintainer logged in.

### (2) #286 — THE PILOT TRACE: BOTH PREDICTORS 0 MISSES
Fork X1 (started in 14z-205b at the maintainer's *"Can we next use PILOT for #286 ?"*), report saved verbatim to
`build/agent205b/t286/REPORT.md` (local). A clean clone of a bundle of `779bc589` on PILOT; all 228 static gates traced
under strace in 487 s; 87,773 (gate, file read) pairs. The committed predictor and the narrowed one (the parked
narrowings adapted to `779bc589`, `build/agent205b/t286/narrowings_on_779bc589.patch`, local) both score 0 misses in 0
gates; the over-narrowed control FIRED (102 missed reads); the planner's self-test passes on the narrowed copy with its
30 controls firing. The narrowing drops 8 gates from a typical close's STALE set (59 → 51 on mid2's change set). **Not
settled:** six gates exited non-zero under the trace, so their reads may be short (test_close_tools and
test_mister_mra_map are new to that list since 14z-202); one hunk collided with #298's PROGRAM-CHANGED line and the fork
kept #298's ruled line; nothing was traced at HEAD `b91532d8` (it adds test_submodule_pins). Landing it takes a
rule-checker run and a tier. PILOT keeps `~/t205/x1` (9.4 GB) for rescoring. **Re-traced at `b91532d8` (14z-205c)**: a bundle of the commit into
the x1 tree (its `build/` and submodules copied from PILOT's own checkout, `emu/fbneo` with our applied patch paths),
229 of 229 gates in 529 s; both predictors 0 misses on 88,351 pairs; the over-narrowed control FIRED (102); four gates
non-zero under the trace (the 14z-202 four); the two MRA gates also traced serially, both exit 0
(`build/agent205c/t286/pilot/`, local). **Landing was WITHDRAWN** by rule-checker run `2026-10-20-1156` (VIOLATED Q1 Q3
Q4 Q5): the scorer judges each read by `stale_reason` and never applies `predict()`'s N-F-CHANGE skip, so a run-record
read the narrowing carries is invisible to both legs. Measured on the same traces (`build/agent205c/t286/
nf_change_check.py`, `.out`): the committed predictor carries 0 of 32,695 run-record reads in 10 gates; the narrowed
one carries 1 — `test_tickets` opens `tests/rulecheck/runs/2026-09-17-22/verdict_real.txt` and is no runs reader
under the narrowed N-F. The narrowings are NOT applied to the tree (`build/agent205c/t286/landing.diff` keeps them).

### (3) #229 — Q1: BULLETA'S AND LEI-LEI'S GUARD CANCELS, AULBATH'S DIRECT SCISSORS, BULLETA'S ES COOL HUNTING, FELICIA'S ES PLEASE HELP ME CONFIRMED; JEDAH'S ES ROW IS ES IRA SPINTA
The maintainer, on `f5_gc/cap9/sheets/gc9_BU.png` rows 1-4: *"yes she has no attack but invulnerability, switches sides
and allows for punish, this is indeed her correct GC. Not sure what you mean by no A no H without you defining your
one-letter acronyms"*. Recorded in `DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205c) — #229 Q1" and
`build/agent205/t229/answers_q1.md` (local). The sheets' tile letters were never defined on the sheets (`cap9.py`). On
`gc9_LE.png` rows 1-4 the maintainer quoted mizuumi's Senpuubu entry, then: *"I would say that fits your findings"*
(mizuumi's ~20F startup invulnerability was not measured). On `esex9_AU.png` row 8 (`[22PPP]`, stock paid 3):
*"it is indeed Direct Scissors; the move didn't hit because the opponent was too far. Of note, the move is supposed to be
actually done with 22+PP (PPP works but the extra P is not needed)"* (22PP not yet measured). On `esex9_BU.png` row 6
(ES Cool Hunting, entry f5818): *"it's the correct move. Why there is so little damage I don't know. Maybe Buletta wasn't
far enough and Victor was hit by a single one of the hitboxes?"*; F3's records: fired at a 51 px gap, one HP fall,
against nine from 184 px (f5600). On `esex9_FE.png` rows 7-9 (ES Please Help Me, three
pairs): *"it is the correct move. One version didn't connect because the opponent was out of range of that specific
variant"* (F3: LK+HK made no HP fall at 64 px or 184 px; the other two hit at both ranges). On `esex9_JE.png` row 2:
*"What  I see is ES Ira Spinta (J.6324+KK) not the ES follow-up."*, agreeing with P2 that F3's ES Ira Piano join is
wrong.

### (4) #286 / #299 — WHY TWO GATES EXITED NON-ZERO UNDER THE PILOT TRACE; A LIVE COLLISION UNDER `--jobs`
- `test_close_tools` (exit 3): its section 2b REFUSED on the findings table #288 cut, which is #300, fixed in `b91532d8`
  after the traced `779bc589` (`git show 779bc589:tests/test_close_tools.sh` has no `NO-FINDINGS-TABLE` branch).
- `test_mister_mra_map` (exit 1, `FileNotFoundError` under `/tmp/vampire-saved-jtsim/release/mra/`): **two static gates
  share one scratch clone.** `test_mister_mra_map` and `test_mra_build_line` both call `tools/mister_mra.sh` on the
  default `${JTSIM_SCRATCH:-$TMPDIR/vampire-saved-jtsim}`, and the tool's `rm -rf "$RLS" "$ROM"` (line 234) deletes the
  other run's `release/mra`. In the trace they finished adjacently (`done.tsv` rows 141 and 143; 27 s and 7 s).
  Reproduced on the Mac: the two started 2 s apart, three times: pair 1 both PASS, pair 2 the map gate crashed, pair 3
  both failed; the map gate alone PASSES (`build/agent205c/t299/`, local). This is #299's collision item, live: the
  close's `--jobs 8` tier can go red on it by chance, and nothing shows a crossed copy could not pass. **Fixed** (the
maintainer: *"Lock in mister_mra.sh (Recommended)"*): `tools/mister_mra.sh` section 0b holds a lock directory beside the
scratch from the clone to the copy-out (a dead holder taken over, a live one waited for up to `MRA_LOCK_WAIT`, default
900 s); `tests/test_jtsim_scratch_heal.sh` section 6 locks it, control `lock-removed` (PASS in 11 s; the mode FAILs);
four concurrent pairs of the two gates all PASS with the lock; `docs/project/gotchas.md` "TWO STATIC GATES SHARED ONE
JTSIM SCRATCH".

### (5) #292 — WHICH STATE.md HITS ARE REAL, MEASURED ON THE PILOT TRACE
`static_confirm.py predict --changed STATE.md` at HEAD, in a scratch worktree with the #286 narrowings applied
(`build/agent205c/t292/`, local): 38 gates STALE (41 committed), 30 of them by R2 "names STATE.md". Of those 30, the
PILOT trace (`779bc589`) saw ~~11~~ **12** open STATE.md; ~~19~~ **18** did not (**CORRECTED** by rule-checker run `2026-10-20-1155`: `test_recurrence_alarm`, counted among the 19, is STALE by R5, and the opens are 12 of the 30). ~~`tools/battery_reach.py` alone makes 13 of the 19~~ **CORRECTED the same day: the planner names only the FIRST file of a reach that names STATE.md; with battery_reach.py cleaned, 11 of those 13 stay STALE through the planner's own `NARROW_R2 = _NarrowR2(("STATE.md",))` and 2 through `close_standing.py`, so battery_reach alone saves none (`build/agent205c/t292/all_namers.txt`, every naming file per gate)** (its
mentions: the docstring, the module-level `PATS` default "the control's own", and fixtures in `control()`);
`tools/close_standing.py` 3 (its `main()` defaults `--state STATE.md`, a real read on another call path);
`tools/checkskills.py` 1 (its module-level document list); `tools/agent/rulings_verbatim.py` 1 (its `main()` default);
`test_recurrence_alarm` 1 by R5 (`tickets.tsv` names STATE.md). ~~**What the 13 cost now:** in the 14z-205b close tier,
the 12 at close cadence (`test_static_runner` is at freeze cadence since 14z-204) took 209 s of gate time and ran 5
control rows~~ **CORRECTED (run `2026-10-20-1155`): that counted only the gates first named by battery_reach.py and
left out `test_static_runner`, which re-ran in that tier as "STALE: R2 tools/battery_reach.py names STATE.md"
(`build/agent205b/close/tier.run3.log:36`, 134 s) whatever its freeze cadence row says. Every STALE gate for a
STATE.md-only change that the trace did not see open STATE.md: 25, of which 19 ran in the 14z-205b close tier for
422 s of gate time and 5 control rows (6 s)**, since #298 executes controls only on a changed program; #292's 1,321 s of 14z-204 is mostly gone. **Built in the scratch
worktree** (maintainer: *"Narrow only battery_reach (Recommended)"*, then, on the corrected premise, *"Add the planner
self-exclusion (Recommended)"*): N-K (a mention inside a python `control`/`selftest`/`_selftest`/`self_test` body is no
N-B read), the planner's own file read for no N-B, battery_reach.py's control-only `PATS` default moved into its
`control()`; `test_static_confirm` PASSES with the controls `selftest-scope-off` and `planner-self-off` firing.
**It saves 0 gates on a STATE.md-only change (38 → 38):** the 11 are also STALE by R5 (the ledger, which the planner
names only in its selftest's case list) and under that by R4 (`tests/run_all_emulator.sh` reads the whole tree) and R5
through old run manifests (`build/agent205c/t292/all_rules.txt`). A trial of N-K on R5's data-file scan failed the
planner's gate and saved nothing; reverted. **#292 CLOSED `declined`** at the maintainer's word (*"Close #292, keep code out
(Recommended)"*, confirmed on the corrected figures: *"Stands: close, code out (Recommended)"*); rule-checker run
`2026-10-20-1155` (VIOLATED Q1 Q4: the counts and the cost, corrected above, resolved); the narrowing code stays out.

### (6) #291 — THE UNFILTERED S3 RUN AT `b91532d8`, ON PILOT
`python3 tools/proof_sheets.py run b91532d8 --host pilot --host-dir t205c/s3 --jobs 5`: the commit bundled and checked out
clean on PILOT, its five tracks built there, each equal to the commit's frozen reference (DON `167d870f`, STOCK
`a3910ded`, HUI `cc9c4b68`, PYR `9d135e7b`, MERGED `6148d0b1`); emulators are PILOT's pinned builds, not built from the
commit. 6,100 s; exit 0; the page is `build/sheets/b91532d88bf3/index.html` (local, 328 MB with its pictures). **58
gates drawn: 52 gave a PASS line, 6 did not;** 470 sheets, 3,839 tiles with a status: 3,206 PROVEN, 542 EVENT-PROVEN,
79 NOT THE JUDGED RUN (74 in `audit_qs_voice_wav`, 5 in `test_tenant_select_records`: both build their own legs).
The six: `test_gfx_menus` and `audit_mask_window_ff4182` need `build/donovan6`, `audit_landing_sound` needs
`build/m3b_merged30` (builds the commit does not make), `audit_flicker_attribution` needs the local masked basis
`tests/expected/vsavj/masked-v2/mask`, all four failing at 0 s; `audit_dmg_legacy_sweep` FAILED its section-6 check
"only 0 of the 32 ours legs show MAME opening .../build/m3b_merged31/rompath/vsavjw.zip" while its 32 legs were
trace-identical to vsavj and 96 of 96 hits equal (its controls fired); `audit_grenade_ground_tiles` printed its PASS
line in a form the runner does not read (exit 0). **The maintainer's review:** *"it looks good in general, it also shows area of concern (e.g.
Felicia's wall jump show no sprites at all, meaning there is no way for a human to compare and confirm. I don't deny
that maybe the memory values compared are both correct and relevant, just it can't be visually confirmed)"* and *"even if
it meant creating multiple webpages if it becomes too big, having around 9 captures per move is the reference."* A
census of the page's pictures: 136 of 3,753 are 97%+ one color (106 in `audit_merged_legacy`, 28 in
`audit_legacy_pairings`, 2 in `test_tenant_select_records`), a floor (stage-only tiles are not counted). #291 stays open
(`DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205c) — #291's unfiltered page").

### (7) FIVE FORKS ON THREE MACHINES
The maintainer: *"on PILOT: do #299 / on ERIS: do #296 (unless it needs PILOT) / on the mac:  do #284’s README draft, not
going beyond draft without validation by maintainer. Then do  #229’s ruled-wrong links and the three gotchas (note: Ira
Pino is a typo, it should be Ira Piano), then #277, #262 and #263. Parallelize if possible and ressources are
available"*. Five forks, each reporting under `build/agent205c/` and editing no record file: P (#299 on PILOT), E (#296
on ERIS), R (#284's draft, `build/agent205c/t284/` only), L (#229's two joins, the Ira Piano spelling, the three
gotchas), X (#277, #262, #263 in turn).

### (8) #277, #262 AND #263 CLOSED
Fork X fixed the three in `tools/agent/extract.py` (`build/agent205c/t277_262_263_REPORT.md`, local). The maintainer
accepted its choices (*"Accept all three (Recommended)"* for #277, *"Accept W§ (Recommended)"* for #263). The closures'
rule-checker runs found real defects in the fixes: `2026-10-20-1157` (#277, VIOLATED Q1 Q4): A@ quoted figures from
inside a hash or a session key, and nobody had measured what the rounding rule clears; on three whole transcripts it
cleared 5 of 8 flagged decimals, 2 falsely ("2.5" from `git version 2.54.0`, "1.9 MB" from a load average thousands of
records back), so the maintainer ruled *"Near + whole token (Recommended)"*: a rounded source must be a whole number
token in a tool result of the last 50 records; re-measured, 3 true clears and 0 false. `2026-10-20-1158` (#262, VIOLATED
Q1 Q4): one M line per TEXT for the whole transcript dropped a repeated message; the set is now cleared at every reply.
`tests/test_agent_extract.sh` PASSES with 45 checks and 13 controls firing, the four new controls (`cites-in-word`,
`said-global`, `rounding-far`, `rounding-version`) each failing it as their mode; `test_agent_worker`,
`test_figure_check`, `test_packet_check`, `test_recurrence_alarm` and `test_gate_follows` pass. **#277 and #262 closed
`done`** with their comments of 2026-10-21. **#263 closed `done`** (comment of 2026-10-21) after its run `2026-10-21-1160` (VIOLATED Q1 Q4): the
derivability census's output was unsaved and "mostly false" unmeasured (now saved, `build/agent205c/t263/
proto_derivable.out`, and the wording withdrawn), and W§ merged files of one basename and dropped unread or over-cap
lines silently (now per full path, a shared basename quotes neither, an unread line is marked, the cap is counted;
control `reads-merged`). The gate: 47 checks, 14 controls firing, none dead; its gotcha `docs/project/gotchas.md` "A
\"DERIVABLE AS a ± b\" CLEARANCE OF A FIGURE IS NOISE".

### (10) #296 — STEP 1'S INVENTORY ON ERIS: 24 OF 4,437 RUNS REUSED, ALL ONE GATE
Fork E (report `build/agent205c/t296/REPORT.md`, local): a bundle of `b91532d8` into a clone on ERIS (WSL2), `build/`
and submodules copied from ERIS's own checkout, the five tracks rebuilt there equal to the commit's fingerprints; the
mame and fbneo lanes at `--scope all` and `ondemand` with `MAME_SANDBOX_LOG` on (`--jobs 8`, two bounded chunks).
4,437 MAME runs from 183 gates: 4,413 fresh, 24 reused, all `tests/audit_wide_phase_a.sh` (ondemand): its `run_one`
names a sandbox by the replay alone, and sections A1-A3 each run the 12 corpus replays, so A2 and A3 boot on A1's
state — #293's shape, a defect, no gate needs `MAME_SANDBOX_REUSE=1`. Proposed, not applied
(`build/agent205c/t296/proposals/`): key that sandbox by section and replay; step 2's refusal in `tools/run_mame.sh`
(exit 3 on a reused sandbox unless `MAME_SANDBOX_REUSE=1`), the log writing absolute paths (seven gates pass a relative
`s1`). Not covered: `run_inp_guarded.sh` and `run_inp_probe.sh` bypass `run_mame.sh` (fresh `mktemp -d` each run), the
prereq and mister lanes. **Seen on the way, not investigated:** `audit_dmg_legacy_sweep`'s "0 of the 32 ours legs show
MAME opening" fails on a clean clone on ERIS too (as on PILOT, #291 S4); `audit_flicker_attribution` needs the
uncommitted masked basis (as on PILOT); `test_wide_profile`'s mtime check fails in a fresh clone; **`audit_marionette_cost`
(ondemand, in no tier) differs from its frozen expectation** — several hook rows count 8 more replays (`HIT 00895c
replays 43` → 51), which looks like corpus growth since its freeze, unexplained.

### (11) #299 — THE FOUR OPEN ITEMS MEASURED ON PILOT
Fork P (report `build/agent205c/t299/REPORT.md`, local): `b91532d8` from a bundle on PILOT, four `--strict --cadence
freeze` legs: A `--jobs 8` warm (1,269 s), B serial (3,527 s), C `--jobs 8` with the decrypt cache cold (1,272 s), D
`--jobs 8` under six busy-loops (2,051 s, load ~10 on 6 vCPU). Six failures in every leg, B included, are PILOT's
environment (#279, #280, #281, the copied `build/`'s staleness, perl locale warnings from the Mac's forwarded
`LC_CTYPE=UTF-8`, the workbook SKIP). **(1) Serial against `--jobs 8`:** of 620 gate and control logs, 612 identical;
the only verdict differences are the MRA pair (the collision, (4)); the rest are an unnormalised timestamp, a partial
copy and two git processes' stderr order. **(2) Cold cache:** the cache rebuilt byte-identical (6 of 6), but five
gates that read `build/out/*.bin` directly, bypassing `decrypt_view`, FAIL or SKIP cold under the pool
(`test_tenant_loop`, `test_tenant_row_owner`, `test_thunk_addr_literal`, `test_beam_list_type6`,
`test_decode_stage_banners`); serial cold not measured. **(3) Collision census** from the #286 trace's writes: 2,912
paths written by two or more gates; among absolute paths only the jtsim scratch (the known pair) and submodule
`index.lock`s taken by `git status` (benign). Live: leg A's MRA pair failed on a crossed image, and in leg D
**`test_mra_build_line`'s control `foreign-rompath` printed `CONTROL DEAD` (it died on the collision) and the runner
counted it HONOURED** because its mode run exited non-zero. **(4) Under load:** no results or control row moved
against serial; no gate asserts on an elapsed time. Peak memory of the pool 932 MiB (leg A, 30 processes). Proposed,
none applied: land the lock; a control whose mode run prints `CONTROL DEAD` or dies outside its perturbation counted
DIED, not HONOURED; build the decrypt views before the pool (or move the 27 direct readers to `decrypt_view`); trace
`unlinkat`/`renameat`/`mkdir`/`chdir`; remote scripts set `LC_ALL=C.UTF-8`; a ticket for ~1,690 temp dirs gates leave
in `/tmp` per four tiers.
**→ The dead-control item: fixed 2026-10-21 with a narrower rule than proposed, (12); the temp-dir ticket is #303.**

### (9) #229 — THE TWO WRONG JOINS RE-RIGGED; IRA PIANO; THE THREE GOTCHAS
Fork L (report `build/agent205c/t229/REPORT.md`, local; backups `before_fork_L.tar` and `after_fork_L.tar` beside it).
**F3's ES Ira Piano row** (the workbook spells it "ES IRA PINO"; the maintainer: *"Ira Pino is a typo, it should be Ira
Piano"*) now fires `J.63214KK~PP` on both legs (`a2:0x36`, stock 1, 5 staged records against 6 for the bare
`J.63214KK`); two lines of the draft `es_ex.tsv` changed; FREEZE, freeze-clock and a normal run pass and the five modes
fail on their own clauses. **F1's row 38** (Tsuji Hayate) is joined to a new state part `BI^`: 4123P (Karame Dama)
connecting, then 236P of the same strength 30 frames later, entering `a2:0x38>a2:0x39` with two HP falls; red 20,
white 8 and gauge 8 equal the workbook, startup 6 against its 7 (not looked into); the three neutral 236P events stay
as measured 6+P with no row; the six modes fail on their own clauses. Both stay drafts in the untracked gates (no
freeze, no registration). Sheets for the maintainer: `build/agent205c/t229/f1cap/cap9/sheets/BI^_9.png` and
`build/agent205c/t229/f3cap/cap9/sheets/esex9_JE.png` (row 2, with a tag legend). Our "Ira Pino" spellings corrected;
the workbook's key, quotes and posted text kept. **The three gotchas** written: `docs/platform/gotchas.md` (the
`-debug` pass skew; the MAME tap crash at exit), `docs/game/gotchas.md` (the backdash trap); `docs/GOTCHAS.md`
regenerated.
**→ Both sheets confirmed by the maintainer 2026-10-21 ("both are correct"), (12).**

### (12) 2026-10-21 — #229'S TWO SHEETS CONFIRMED; #284'S DRAFT EDITED; THE DEAD-CONTROL SCORING FIXED; #302, #303
The maintainer, on the two re-rigged #229 sheets (`esex9_JE.png` row 2, ES Ira Piano; `BI^_9.png`, Tsuji Hayate):
*"both are correct"*, and *"I believe #229 must stay open as I still have answers to provide for Q2 especially"*. On
#284: the maintainer edited the README drafts and template in `build/agent205c/t284/` directly (*"mostly removing the
deliverables section that held no value since you've downloaded already"*) and asked whether `apply_release.html` needs
Python: it does not — the page's own text says it builds the romset *"without Python and without a terminal"*, has no
network code, and names `apply_release.py` only as the fallback for a browser missing what it needs
(`release/merged-m23/mame/apply_release.html` 105-107, 744-747). #284 stays open (*"let's keep #284 open for next
session to not block the close of this one"*). Filed at the maintainer's word (*"File the two tickets you proposed to
file"*): **#302** (`audit_marionette_cost` reads 8 more replays per hook row than frozen on a clean clone) and **#303**
(static-tier gates leave ~1,690 temp dirs, ~2.3 GB, in `/tmp` over four tiers).
**The dead-control scoring** (*"Fix the dead-control scoring, then close"*). Fork P's proposed rule — a mode run that
prints `CONTROL DEAD` for its own control is DIED — **was measured wrong before it was applied**: four gates print their
OWN `CONTROL DEAD` as their honoured mode in all four PILOT legs (`test_df_startup_provenance` perturbed-expectation,
`test_defense_rows_census` tenant-row-moved, `test_bundle_parsers` unbundled-leftover and msys-path-untranslated), so it
would have turned 4 good controls red. A Python exception's last line alone (`FileNotFoundError: …`, the half the
collision left in the log because the gate quoted only `tail -2` of its generator) is no better:
`build/emu_rel198_eris/audit_victim_parity@no-translation.log` quotes two child `ValueError`s beside ANOTHER control's
`CONTROL DEAD` while its own control fired. **The rule landed is the conjunction:** `tests/lib/classify.sh` reads a mode
run DIED when the gate prints `CONTROL DEAD: <its own control>` AND a Python exception line stands in the log (the
runners now pass the control's name as a 4th argument). Over 2,351 control logs (#299's four PILOT legs, 1,610; the
other 139 static and 602 emulator-tier logs under `build/` since 2026-09-01) it matches exactly the one leg-D row.
Gate: `tests/test_static_runner.sh` section 12d (the dead-beside-crash stub DIED; the own-DEAD and other-DEAD
look-alikes honoured; must-fire `dead-crash-unread`, a classifier copy with the branch disabled, fires, and FAILS the
gate as its mode); `test_static_runner` and `test_emulator_runner` PASS, their `crash-unread` modes FAIL. Not covered: a
foreign failure in a mode run that prints no own `CONTROL DEAD` or no exception line still reads HONOURED (the runner
scores the exit status). Seen, not ticketed: `audit_victim_parity`'s in-gate controls tenant-planted and timing-planted
crash building their copies under the no-translation mode (release 198, ERIS).

### CLOSE (14z-205c, 2026-10-21)
Run by the step table and its driver (`docs/project/session_close.md`, `tools/close.py`; run dir
`build/agent205c/close`, local). The maintainer: *"Fix the dead-control scoring, then close"*.
- sections done by hand (pointers on (9) and (11) to (12)); the #292 worktree `build/agent205c/t292/tree` removed after
  its diff was saved beside it (`nk_worktree.diff`, local); `origin/main` fetched, nothing new;
- next-session (the 14z-205b opener moved verbatim to `docs/NEXT_SESSION_HISTORY.md`) and rollover (the 14z-205b
  group, 144 lines, to STATE_HISTORY with its ledger line; no `STATE.md §` citation pointed into it) done by hand;
  indexes regenerated (`tools/close.py next`); `docs/project/gate_coverage.md` regenerated in a clean worktree of the
  staged changes (three gate headers changed; the gate index unchanged), where `test_gate_index_current`,
  `test_gate_coverage_current`, `test_must_fire_census` (259 declaring), `test_gate_descriptions` and
  `test_gate_follows` PASS;
- dashboard re-collected for 14z-163..14z-205c (1,834 figures, 0 unclassed) and uploaded (datasets versions 12, 12, 12,
  13);
- bookkeeping gates before the tier: `test_tickets`, `test_state_open_lists`, `test_live_budget`,
  `test_gotchas_index_current`, `test_history_index`, `test_rulings_verbatim` PASS;
- **#229's untracked gates are again deliberately NOT staged** (Q1 not finished, Q2 pending), nor `build/`;
- the tier's results file, the next close's `--prev`: `build/agent205c/close/tier_results.tsv`.
- **the first tier stopped in its plan** (2 h 50 min, 150 of 229 gates judged, no gate run): 5,739 untracked proof
  sheets under `build/sheets/b91532d88bf3/` counted as changed inputs. `build/sheets/` was moved to
  `../sheets_aside_14z205c/` (outside the tree, nothing deleted) and the tier re-run; filed **#304** at the maintainer's
  word (*"Please file a ticket to review what we even include or exclude from the planner"*);
- `origin/main` fetched again before the re-run: the maintainer's two README commits (`e0bcfd0c`, `2e79bab7`)
  fast-forwarded in, so the tier covers them.
- **the restarted tier was red on `test_rule_checker`**: the ledger rows of runs 1153-1158 and 1160 were staged but
  their run directories were not (untracked, so `git add -u` left them out). The eight run directories (1159 included:
  prepared and never recorded, which the tree keeps as it keeps `2026-09-18-36`) were staged and the tier re-run with
  `--confirm` on the red run's results (`tier_results_run2.tsv`), as the tier step says.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **ROM content in the tree (2026-10-18, 14z-205):** addresses and discrete values are fine; a whole graphic or sound, or a whole algorithm, is not ([VSP-8]; the four quoted sound-driver bytes stay) — `DECISIONS_HISTORY.md` "Ruled 2026-10-18 (14z-205) — the no-ROM-bytes rule: …".
- **#291's last 22 gates (2026-10-18, 14z-205):** the tap gates prove by an EVENT-PROVEN basis (D2), groups 3-5 take a `no-picture` declaration kind (D4), D4 first — `DECISIONS_HISTORY.md` "Ruled 2026-10-18 (14z-205) — #291 S2: …".
- **An action is checked when its work is done, never held for the close (2026-10-16, 14z-203):** a ticket is closed and a recommendation put in the piece of work that finishes it, through its rule-checker run then; a run cited in a CLOSE section is the tell — `DECISIONS_HISTORY.md` "Ruled 2026-10-16 (14z-203) — an action is checked when its work is done, never held for the close".
- **The close's cost must follow the change; #286, #287, #288 are the direct priority (2026-10-15, 14z-202):** controls only on a real change, the procedure check right after each piece of work, the audit layer measured before it is cut — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-202) — the close's cost must follow the change".
- **Cross-platform checks run on demand or at release (#285, 2026-10-15, 14z-201b):** `test_release_launcher_bat`'s Windows half is a NOTE off Windows below release cadence, so a session close needs no ERIS — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201b) — #285".
- **The recording procedure lives in the release package README (#284, 2026-10-15, 14z-201):** the root README's "Report a problem" was trimmed by the maintainer (2026-10-15); #284's work moves `test_readme_recording` to the generated MAME package README — `DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — the recording procedure moves to the release package README".
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
- **The close checklist, six steps (2026-09-18, 14z-167b)** — the steps live in `docs/project/session_close.md` (since 2026-10-15, #282 item C); `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-167b)".
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
