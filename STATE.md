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

## Session 14z-206 — **PILOT and ERIS offline: the Mac carries the work in parallel. #299's cold cache fixed and #299 closed done; #296 and #309 closed done; #286's code half; #284 done awaiting release; #291 S4-A..F landed and S4-G shown, kept open for S4-D's 38 gates; #305..#313 filed; the sheet gates run on demand only.** Opened 2026-10-21 on transcript `fc0caa60` after the 14z-205c close (`b89fc9d7`, pushed).

### opened with
HANDOFF, STATE and NEXT_SESSION read; the sweep CLEAN, `main` equal to `origin/main`. The maintainer: *"Currently PILOT
and ERIS are offline, what does that change?"*, then, on the offline order proposed: *"start in the offline order, and
don't hesitate to parallelize the task, you have the whole machine to you"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-21
(14z-206) — PILOT and ERIS offline …"). Forks, each editing only its own files and none a record file: S (#291 S4's
plan), R (#284's proposal), C (#299), M (#296), T (#286); then A (#291 S4-A), R2 (#284 applied), K (two tickets and
#296's text), B4 (#291 S4-B onwards, in its own git worktree). The harness refuses a subagent's write of a report file,
so each hand-back is saved verbatim by the orchestrator (`build/agent206/<t…>/REPORT.md`, local).

### (1) #291 — S4-A..F LANDED, S4-G SHOWN, `audit_qs_voice_wav`'s VARIANT FIXED; OPEN UNTIL S4-D's 38 GATES GET SPANS (ruled 2026-10-23)
Fork S's plan (`build/agent206/t291/PLAN.md`, `REPORT.md`, local), read-only on the S3 page: the 136 near-blank pictures
come from two selection paths, 104 from the round-end fade anchor (102 in `audit_merged_legacy`, 2 in
`test_tenant_select_records`) and 28 from `audit_legacy_pairings`' load frame; Felicia's wall jump is never drawn; no tag
on the page is defined. The maintainer's answers (`DECISIONS_HISTORY.md` "Ruled 2026-10-21 (14z-206) — #291 S4: …"): a
move is a judged event, ~9 tiles unless it has more; the replay oracle draws up to 18 frames at the replay's inputs;
frames without fighters go in a separate labelled strip; Q4/Q5 as recommended. **S4-A** (fork A, `build/agent206/t291/
s4a/REPORT.md`, local): the six gates that did not pass on a clean checkout now pass there with every picture proven
(temporary commit objects `d82803e55787`, `4c6ba05794ea`, never refs): `audit_flicker_attribution` reads the tracked
`MASK` (it failed on every case-sensitive filesystem, proven on an APFS case-sensitive image); `audit_dmg_legacy_sweep`'s
ours legs pass `-verbose` (the zip-opened check rested on the maintainer's own `mame.ini`, `verbose 1`; reproduced on the
Mac with a HOME that has none; control `zip-check-blind`), its gotcha retracted in `docs/platform/gotchas.md`;
`audit_grenade_ground_tiles` prints an unindented PASS line; the two menu gates run on the stock twin (`%STOCK_RP%`);
`tools/proof_sheets.py` builds `audit_landing_sound`'s control from `freeze/merged-m22` (`# SHEET-BUILD:`), and resolves
a relative rom path against the gate's own tree (it had re-run both menu gates on pristine vsavj; control
`rompath-unresolved`). S4-B onwards ran in fork B4's worktree (*"Now, in a worktree (Recommended)"*). **Since then
(2026-10-22): S4-B..F landed in `8b82d5d2`** (the fighters predicate, legends, ~9-tile spans, input frames per round,
paging; `tests/expected/sheet_span_debt.txt`, 38 rows). **S4-G ran on the Mac** (`tools/proof_sheets.py run 8b82d5d2
--jobs 4`, `build/agent206/t291/s4g/run.log`, local): exit 0, 58 gates all PASS, 483 sheets, 5,563 pictures, the five
tracks equal to their frozen fingerprints; one sheet with unproven pictures (`test_tenant_select_records`, 5 of 10 NOT
THE JUDGED RUN: every one its `ours` leg, refused by S3 because the gate builds its own 0x13 image with
`tenant_build_13` in its `mktemp` dir, a build with no frozen fingerprint; ruled 2026-10-22 *"Built in checkout, stated (Recommended)"*: the tool builds a gate-declared variant in the checkout's `build/` and states its fingerprint, `DECISIONS_HISTORY.md`); 26 sheets where no picture shows the fighters (attract, select, test mode, KO
frames). Shown to the maintainer: *"generally very good, it would be great if each test / gate had a concise
description: basically which characters and what setup is tested"*; ruled measured + one written line, in both places
(DECISIONS_HISTORY "Ruled 2026-10-22 (14z-206) — #291 S4-G reviewed …"). In the working tree: `screen_state.lua`
reads c1/c2/lv (`$FF8782`, `$FF8B82`, `$FF8116`), `proof_sheets.py` names them per sheet, per gate and in the index,
58 `Setup: ` lines in `docs/project/sheet_notes.md`, `test_proof_sheets` section 6b and control `who-swapped` —
rendered on a two-gate copy, the gate not yet run (the Mac carries #299's whole tier). Next: the gate, then S4-G
again, shown to the maintainer. #291 stays open.
**Later in 14z-206 (2026-10-23):** S4-G ran on `7b663645`. All 58 gates PASS and the five tracks match their frozen
references (`build/agent206/s4g_7b663645/`, local). It was shown to the maintainer: *"pages are looking good"*. The 74
unproven cells, all `audit_qs_voice_wav`'s ours clips, were fixed in `e5d6f445` (`# SHEET-VARIANT: QSV_OUTBASE`,
`tests/lib/qs_voice_build.sh`, plus its supplied-build ledger, gotcha written); that gate's sheet on `e5d6f445` reads
0 NOT THE JUDGED RUN. The closure went to the rule-checker: run `2026-10-23-1190` VIOLATED, then `-1192` VIOLATED, each
resolved by work; `-1189` and `-1191` were withdrawn unspawned. Run `-1193` found S4-D unfinished: 38 gates, 541 judged
events at 1 tile each (`build/agent206/t291/close/span_measure_7b663645.txt`, local). The maintainer: *"Keep #291 open
(Recommended)"*. #291 stays open until those 38 get spans (NEXT_SESSION).

### (2) #284 — THE TEMPLATE IN THE PIPELINE; DONE, AWAITING RELEASE
Fork R rebuilt the pre-edit drafts from the 14z-205c transcript and diffed the maintainer's edits (`build/agent206/t284/
PROPOSAL.md`, local); the maintainer's answers (`DECISIONS_HISTORY.md` "Ruled 2026-10-21 (14z-206) — #284: …"). Fork R2
(`build/agent206/t284/apply/REPORT.md`, local) put the template in as `tools/package_release_readme.template.md`, with
"Play on" and "Report a problem" moved into it; `tools/package_release.py` and `package_release_platforms.py` fill it
(a marker line removed whole; a left-over token stops the packaging). Rendered from the M23 manifest
(`build/agent206/t284/rendered/`): FBNeo equals the maintainer's edit but for the kept `EMULATOR.md` clause. Gates:
`test_release_roundtrip` (the proposal's version went red on the published M23 READMEs, fixed, control
`generator-report-dropped`), `test_release_launcher_bat`, `test_release_recipe_text` and `test_readme_recording` (macOS:
the set built by the package's `apply_release.py`, 5,320 frames reproduced on both MAMEs) PASS with their controls; its
Windows and Linux legs not run (ERIS, PILOT offline) — since run: Linux PASS on PILOT
(`build/agent206/remote/pilot/REPORT.md` job 3, local); Windows not a pass, three host defects, #308. The new READMEs
ship with the next release; the "done unshipped" comment and label are on the issue (citing `a8fa5350`).

### (3) #299 — THE COLD DECRYPT CACHE FIXED; CLOSED DONE (rule-checker run `2026-10-22-1178` OK)
Fork C (`build/agent206/t299/REPORT.md`, local): 36 gates and 11 tools read `build/out/*.bin` by path; with the cache
cold, the five gates FAIL or SKIP under `--jobs 8` and PASS serially, saved there only by the tier's order (the first
gate, `test_m3a_reproducible`, builds the views). Fixed: `tests/run_all_static.sh` builds the views before the tier
(`decrypt_cache_ensure`, ~24 s cold, six size checks warm), and `tests/lib/decrypt_cache.sh` makes its temp dir inside
`build/out` (a `mv` across filesystems is a copy a reader could catch half-written). In an isolated copy, cold: all five
PASS at `--jobs 8` and `--jobs 1`; `test_static_runner` sections 28-29, control `decrypt-warm-off`. The two gaps are
**#305** (*"New ticket, close #299 (Recommended)"*). Its closure: rule-checker runs below, then the maintainer's *"option A"* (the landing commits, #299 stays open). Rule-checker runs `2026-10-21-1161` (VIOLATED Q1 Q3 Q4: PILOT's six environment-failed gates
and an unchecked comparer) and `2026-10-21-1162` (VIOLATED Q1 Q4: the open-only census's unresolved relative paths) were
resolved by work: a Mac serial-against-pool mini-tier of those six on the landing commit (`build/agent206/t299/c2/`;
planted differences found `compare_legs.py` blind to hex ids, large numbers and sizes, a corrected copy is not), and a
re-traced write census on PILOT with every path resolved (`build/agent206/t299/x2/`), which found one new hazard,
fixed: `test_checkdocs_rom`'s control 5 rewrote a tracked file in place (`tools/checkdocs_rom.py --covered`). Runs
`-1163`, `-1165` resolved by work too (the final tree's confirm tier; PILOT's diffs printed in full; date and epoch plants,
which found the epoch class erasing an epoch-shaped real number, shown to hide nothing), `-1164` withdrawn unspawned (a
summed figure). **`-1166` VIOLATED (Q1 Q4), resolved as the closure withdrawn (`a8fa5350`):** PILOT's logs came from a faulty 2-second copier, a confirm-log
line does not show its claim, and the comparer's duration/PID/date/temp-name classes were never planted with a real value.
The maintainer, offered to commit the landing first: *"option A"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-21 (14z-206) —
the landing commits now; #299 stays open …"). #299 stays open; `build/agent206/CHECKPOINT.md` holds its next steps.
**Closed done, later in 14z-206** (GitHub comment of 2026-10-22, `build/agent206/t299/closing_comment.md`): the Mac's
whole tier of `8b82d5d2`, serial against `--jobs 8` on one snapshot with the log-keeping rig corrected, read `PASS 213
SKIP 0 FAIL 1` in both legs with equal results and controls tables (`build/agent206/t299/c3/v2/`); a 19-gate loaded leg
beside 12 busy-loops (`build/agent206/t299/load/`); `test_checkdocs_rom`'s guard stamps mtime, inode, size and content
(control `restored-write`) and its `vacuous-validator` mode, dead since 14z-147b, is fixed. Rule-checker runs
`2026-10-22-1170` to `-1177` VIOLATED, each resolved by work; `-1178` OK. Filed from it: **#310** (an unjudged mode run
reads HONOURED), **#311** (the browser gate red under heavy load), **#312** (a `--jobs 8` tier keeps about 2.4 of its 8
slots busy). The maintainer ruled the "70-80%" target met as 8 job slots (*"Close #299, new ticket (Recommended)"*,
`DECISIONS_HISTORY.md`, 2026-10-22).

### (4) #296 — THE CODE HALF: THE SANDBOX KEY AND THE REFUSAL; CLOSED DONE (rule-checker run `2026-10-22-1185` OK)
Fork M (`build/agent206/t296/REPORT.md`, local): `audit_wide_phase_a` keys its sandbox by section and replay;
`tools/run_mame.sh` refuses a sandbox that holds an earlier run's state (exit 3) unless `MAME_SANDBOX_REUSE=1`, and
logs absolute paths; `test_mame_sandbox_log` gains the refusal section and control `refusal-removed`. Phase A PASSES in
231 s with 37 fresh runs and its A1-A4 decisions unchanged; the old phase-A script now fails loudly; 13 MAME gates
sampled, 54 runs, all fresh. No gate needs the override. The live text that called an explicit sandbox a reuse made past
tense by fork K ([VSP-117], `SKILL.md`, two comments, `operations.md`). Not closed: its "done when" is the mame and
fbneo lanes green with the refusal on, on the Mac after the landing.
**Closed done, later in 14z-206** (GitHub comment of 2026-10-22, `build/agent206/t296/closing_comment.md`): every lane
ran on `04a53769` with the refusal on (ERIS fbneo, mame, prereq; PILOT mister GREEN 8 of 8 after a voided row was
re-run): 4,775 MAME runs, all `fresh`, no `REFUSED` line. Four reds, none the refusal's, ruled acceptable by the
maintainer (*"Close, reds named (Recommended)"*, `DECISIONS_HISTORY.md`, 2026-10-22). Rule-checker runs `-1179` to
`-1184` VIOLATED, each resolved by work (`-1183` withdrawn unspawned); `-1185` OK.

### (5) #286 — THE SCORER JUDGES AS `predict()` DOES; STATE 14z-205c (2) RETRACTED IN PART
Fork T (`build/agent206/t286/REPORT.md`, local): `tools/static_confirm.py` exposes `runs_reader`, `change_reason` and
`whole_covers`, which `predict()` and `tools/trace_static_reads.py`'s scorer both call (nine change sets' predictions
byte-identical before and after); control `nf-change-unscored`. The committed predictor carries `test_tickets`' read
of `tests/rulecheck/runs/2026-09-17-22/verdict_real.txt` too (row 156 of `tickets.tsv` links it; `tools/tickets.py`
opens every link target): 14z-205c's check script took every gate as a runs reader on the committed leg, so its "0 of
32,695" could not find a miss (retracted in (2) of 14z-205c and NEXT_SESSION). `landing.diff` adds N-F-LINK. **Since
then (2026-10-22): rescored and applied.** PILOT (fork P2, `build/agent206/remote/pilot/REPORT.md`, local) scored 14z-205c's
traces of `b91532d8` (229 gates, 88,351 pairs): committed predictor MISSES 1 (`test_tickets`), narrowed + N-F-LINK 0,
narrowed without N-F-LINK the same miss, the over-narrowed control fired (103). Rule-checker runs `2026-10-22-1167`
(VIOLATED Q1: four change sets counted where five differ, a log naming no tree, the four gates short under the trace
unnamed), `-1168` (VIOLATED Q1: the wrong four modes called new; PILOT's committed leg not tied to `a8fa5350`), each
resolved by work (logs with a tree header, all five new modes run and failing on their own case, the tool blobs tied);
**`-1169` OK.** `landing.diff` is applied in the working tree (one header line of `runs-self-off` reworded as the
checker noted); it lands with the next tiered commit. Not tested: a fresh trace of `a8fa5350`, reads through git or on
an untaken branch, the four gates short under the trace. #286's done-when is still open.

### (6) #305, #306, #307, #308, #309 FILED; #309 CLOSED DONE (rule-checker run `2026-10-23-1188` OK); #305 AND #306 SEVERITY LOW (ruled 2026-10-23)
At the maintainer's word: **#305** (#299's two gaps) and **#306** (nine emulator gates default to `build/donovan6`,
which only `test_m2b_stage6` builds, so a clean checkout's gate order decides whether the others find it — a correction
of S4-A's "a build the commit does not make" for those nine). **#307** (*"file that ticket"*): `build/` has no retention
rule for logs and session evidence, 47 GB in 1,134 entries; measure what references each family before pruning.
**#308** (*"you can"*), filed after the landing commit `a8fa5350`: #284's Windows leg on ERIS found three host defects
that predate #284 — the generator's unencoded writes (cp1252 on Windows), the gate's own CRLF `argv.txt`, and its silent
exit 2 under `set -eu` (`build/agent206/remote/eris/REPORT.md`, local). Its first body named the README as the CRLF
source; corrected on the issue the same evening.
**#309** (*"Yes"*): `test_proof_sheets`' control `relative-unresolved` is dead wherever the repository path is as
deep as the capture's work dir (ERIS in #296's prereq lane): the relative SHEET_OUT under `/tmp` climbs out with one `..`
per repository level, the surplus stop at `/`, and the unresolved name still reaches the replay. Measured by fork P3 on
PILOT (a six-deep symlink: DEAD; the plain clone: FIRES; `build/agent206/remote/pilot3/REPORT.md`, local). **The fix
is applied in the working tree** (`relunres.diff`: the dir under `$REPO/build/.proof_rel.XXXXXX`, and a FAIL if the
name climbs out). On the Mac (`build/agent206/t309/`, local), from a logical repo path 9 deep, HEAD's gate is DEAD and
the fixed one FIRES; the "relative rom path" FAIL on both is the symlink rig's (logical `pwd` vs physical path);
from the plain tree the fixed gate PASSES; with `R3="$W/rel"` put back the new check FAILS ("climbs out"). macOS
`mktemp -d` ignored `TMPDIR=/tmp`, so a first "shallow temp" leg tested nothing (gotcha written). Not closed: the
ticket's to-do runs it on ERIS's deep clone, unreachable from this network.
**Closed done, later in 14z-206** (GitHub comment of 2026-10-23, `build/agent206/t309/closing_comment.md`): the fix
landed in `7b663645`; the committed gate and tool were then run on PILOT in a 7-deep plain worktree of `7b663645`
(`8b82d5d2`'s gate DEAD, the committed gate FIRED and PASSES) and on the Mac (FIRED and PASSES; the old line restored
FAILS on the climbs-out check), `build/agent206/t309/commit_legs/`; ERIS's deep clone ran the fix on `04a53769` first
(`build/agent206/t309/eris/`). Rule-checker runs `2026-10-23-1186`, `-1187` VIOLATED, resolved by work; `-1188` OK.
**Severity, 2026-10-23:** #305 and #306 labelled `severity: low` (*"Both low (Recommended)"*, `DECISIONS_HISTORY.md`).

### (7) #313 FILED — THE `--confirm` PLANNER STALLS ON AN UNTRACKED `build/sheets/` TREE
At the maintainer's word (*"Yes"*, 2026-10-23): `tools/static_confirm.py plan` took 1,902 s for 25 of 229 gates in the first commit
tier (it hit its 2 h timeout; the commit was tiered again without `--confirm`), against 37 s for all 229 the day before.
Its changed set held 23,803 paths. A recount gives 23,848, of which 20,273 are judged path by path, all but 2 under
`build/sheets/8b82d5d247c6/`, #291's sheets, which the N-D `SCRATCH` filter does not drop (`build/agent206/t_confirm_slow/`, local).

### (8) THE SHEET GATES RUN ON DEMAND ONLY (ruled 2026-10-23)
The maintainer, unprompted (*"if we have any tests/gates on the captures sheets, they really
should be ondemand scope"*, DECISIONS_HISTORY.md): `test_proof_sheets` moves to emulator scope `ondemand` (reason `sheets:`),
and `test_sheet_census` to static cadence `ondemand`. Both PASS run by hand after the move, as do `test_emulator_runner`,
`test_lane_carry` and `test_gate_follows`.

### CLOSE (14z-206, 2026-10-23)
The maintainer: *"let's keep the end of #291 for next session. Let's try to aim closing this one, making sure that
tickets that need updating/commenting/tagging/closing are updated accordingly"*. The sitting's commits, all local until
this close's push: `a8fa5350`, `8b82d5d2`, `7b663645`, `e5d6f445`, each on a strict GREEN tier of its staged tree.
**Tickets:** a GitHub check of every ticket this group names (#284, #286, #291, #296, #299, #305-#313). #305 and #306
labelled (ruled); the `sessions` column of #284, #286 and #291 gains 14z-206; progress comments on #286 and #291 go up
after the push, so they cite pushed commits. #296, #299 and #309 were closed on GitHub as their work finished.
**The tier runs without `--confirm`** (#313): `tools/static_confirm.py plan` stalls on this sitting's untracked sheet
trees under `build/sheets/`, as it did on the first commit tier. So the tier is the whole strict tier at `--jobs 8`
(session cadence), and the table's `tier` step is passed by hand with that evidence.
Steps (`tools/close.py`, run dir `build/agent206/close/`): **sections** done (headings to reality; #313 and the
ondemand ruling split into (7) and (8)); **next-session** done (14z-205c's opener moved verbatim to
`docs/NEXT_SESSION_HISTORY.md`; the opener rewritten, `test_live_budget` PASS); **rollover** nothing to move; **indexes**
done; **dashboard** done (14z-163..14z-206 collected, 1,876 figures, 0 unclassed; this heading now names transcript
`fc0caa60`; the four files uploaded, datasets at versions 13, 13, 13, 14). **record** this paragraph; **stage** 41 files (`git add -u` and the five new rule-checker run directories), 0 under
`build/`, the bookkeeping gates PASS; **tier**: first the whole strict tier without `--confirm` (#313) on the staged
tree `74c64b0b`, GREEN, PASS 91, 323 of 323 controls honoured, 609 s wall (`build/agent206/close/tier_results_full.tsv`);
then the table's `--confirm` tier based on that run, since a base newer than this sitting's sheet trees keeps the
planner clear of #313; its results `build/agent206/close/tier_results.tsv` are the next close's `--prev`. Then commit,
pins, sweep, push, and the #286 and #291 progress comments.

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
