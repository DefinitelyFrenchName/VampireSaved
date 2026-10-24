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

## Session 14z-207 — **PILOT and ERIS online, the work run in parallel lanes: #291 closed done (the span retrofit, the fighters check on round intros, the full sheet run reviewed); #308 and #313 closed done; #286 measured, then closed done; #304 analysed and its four recommendations adopted; #314 filed and closed done; #303, #279, #280 and #281 closed done (lanes P and P2 on PILOT); #312 and #315 closed done (lane S on ERIS, fork T on PILOT).** Opened 2026-10-23 on transcript `e552692b` after the 14z-206 close (`c494fac2`, pushed).

### opened with
HANDOFF, STATE and NEXT_SESSION read; the sweep CLEAN, `main` equal to `origin/main`. The maintainer: *"no answers right
now for #229. PILOT and ERIS available. Let's parallelize work as much as we can"*. Forks, each in its own git worktree
and editing only its own files, none a record file: A-E (#291 S4-D, the 38 debt gates by family), F (#313 then #286's
done-when, the tier on PILOT), G (#308, the Windows leg on ERIS), then H (the fighters check, from lanes C and D's
finding). The green guard refuses a fork's branch commit, so each lane's work is a commit object pinned as
`refs/agent207/<lane>` (local), and each hand-back is saved verbatim by the orchestrator
(`build/agent207/<t…>/REPORT.md`, local).

### (1) #291 — S4-D's SPAN RETROFIT, ALL 38 GATES; THE FIGHTERS CHECK READS ROUND INTROS
Lanes A-E (`build/agent207/t291/{A..E}/REPORT.md`, local) gave every gate on `tests/expected/sheet_span_debt.txt` span
rows of about 9 frames per judged event, each gate's output identical with and without `SHEET_OUT` but for MAME's
teardown-segfault PID lines, every gate PASS, every picture proven on the lane's own sheet run. `audit_qs_voice_wav`'s
moments are audio clips: `tools/proof_sheets.py`'s census now counts its printed `file` rows as it counts `fields` rows.
The debt list is empty; the census passes. The maintainer, on stages shorter than 9 tiles because the next stage is its
own moment: *"Keep as is (Recommended)"* (the move shown whole across its moments). Lane H
(`build/agent207/t291/H/REPORT.md`, local): the fighters check read every round intro as no fighters (the fighters draw
with their own palette rows, and the picture is MAME's latched OBJ list, two frames behind OBJ RAM; gotcha written);
on 288 pictures classed by eye the new check reads yes on 96 of 96 intro pictures (old: 0) and no on every bare stage,
flash and non-fight screen; `test_proof_sheets` control `intro-blind`. The full sheet run of the merged tree (commit
object `a9098ffa`, `refs/agent207/merged1`; `build/agent207/t291/full/`, local): 58 of 58 gates PASS, 483 sheets, 25,561
tiles (23,107 PROVEN, 2,299 EVENT-PROVEN, 155 JUDGED FILE), 0 NOT THE JUDGED RUN, the five tracks equal to the commit's
frozen references; the 37 span-retrofitted gates show 9 tiles per event (7b663645: 1); tiles without fighters 869 of
16,932 then, 1,028 of 25,561 now (`measure.txt`, `before_after.txt`). The maintainer, on the pages: *"all looks and sounds
good"*. **#291 closed done**: rule-checker runs 2026-10-23-1207 to -1210 VIOLATED and resolved, each finding one more
short event or unnamed gap (`audit_column_flash`'s last moment at 8, ruled *"Keep 8 (Recommended)"*; two earlier span
gates' 1-tile moments, ruled *"Keep as is (Recommended)"*; `test_proof_sheets` re-run on the landing tree, PASS with 16
controls), run -1211 OK.

### (2) #308 — THE THREE WINDOWS DEFECTS FIXED
Lane G (`build/agent207/t308/REPORT.md`, local): the generator's text writes name `encoding="utf-8"` and
`newline="\n"`; the gate's `argv.txt`/`readme.env` are written LF; a missing `rec.log` reaches the FAIL line; a
host-text guard and controls `unencoded-launcher`, `crlf-argv`, `rec-log-missing`. `test_readme_recording` PASSES on the
Mac and on ERIS's Windows leg (the release `cps2.exe`, ERIS has no source-built MAME); gotcha written. The same defect
in `tools/gen_applier_page.py` is **#314** (*"File it, severity low (Recommended)"*). **#308 closed done**: rule-checker runs 2026-10-23-1198, -1200
and -1201 VIOLATED and resolved (the guard covers the README render path only; the ERIS byte counts named no run), run
-1202 OK. Added for it: `tests/test_host_text_opens.sh` (ci_portable), an ast read of every text `open()` in the two
generator files (15), refusing pathlib `write_text` (its `newline=` needs Python 3.10); controls `unencoded-open`,
`newline-dropped`, `write-text`. The three sibling release gates PASS on the main tree.

### (3) #313 CLOSED DONE; #286 MEASURED ON PILOT
Lane F (`build/agent207/t313/REPORT.md`, local; commits `refs/agent207/t313` `949a8feb`, its parent `1a2210f6` traced):
`build/sheets/` joins N-D scratch (PILOT trace of 229 of 229 gates with a replica of the sheet tree, 0 misses over 88,235
reads, the over-narrowed control 102), and the planner's per-path work is bounded with verdicts unchanged (old against
new IDENTICAL on 3x80 sheet paths and 3x110-111 tracked-diff paths on PILOT and 2 Mac sets); with the replica present
the committed planner hit its 1,800 s timeout, the fixed one planned 20,297 paths in 22.1 s. Applied to main; four new
`test_static_confirm` controls. Rule-checker run 2026-10-23-1197 VIOLATED and resolved (the sheet-path equivalence and a
planted `build/sheets/` read were not in the packet), run -1199 OK; closed, gotcha written. **#286** (progress comment):
the record-only confirm tier on PILOT re-ran 45 gates and executed 0 of 394 controls (the controls clause met); 25 of the
re-run gates open none of the changed files (R2 `battery_reach.py`/`close_standing.py`/`checkskills.py` mentions, R3
`docs` through `test_tenant_loop.sh`, R5), the next narrowing candidates. PILOT's four host reds (#279, #280, #281, its
stale emulator records) stand; its disk is down to 5.9 GB free.
**Resolved later this sitting:** #286 closed done, and #279, #280, #281 with the record-only tier and PILOT's tools — (8).

### (4) #304 — ANALYSED, FOUR RECOMMENDATIONS ADOPTED, THE BUILD IN A FORK
Fork I (`build/agent207/t304/REPORT.md`, local): session scratch is 5,182,386 of the 5,241,597 files a snapshot copies,
and setup grows with the files copied (recorded runs: under 100k files mean 52 s, over 2M mean 1,037 s). Rule-checker
runs 2026-10-23-1194 and -1195 VIOLATED and resolved (the fork's parallel-plan script skipped plan()'s submodule
fingerprints and marked 12 gates STALE; the pathspec glob and the scratch regex disagree on `build/agent7-x/`), run
-1196 OK. The four recommendations (`build/agent207/t304/recommendation.md`, local): one tracked list classing each
`build/` top dir with a census gate; the snapshot without scratch, after a with/without tier comparison; the planner
prunes scratch from its listing (pathspec and rule generated from the one list), judges tracked changes first, runs its
gate loop in parallel, refuses past a path budget; sharding only if still too slow. The maintainer: *"Adopt all four
(Recommended)"* (DECISIONS_HISTORY.md). Fork J built items 1 and 3 and the census on `949a8feb`
(`build/agent207/t304/J/REPORT.md`, local; `refs/agent207/t304-J` `a2ed6c65`): `tests/expected/build_dirs.tsv` (scratch,
input, kept, fixture), `tools/build_dirs.py` generating the planner's scratch regex and pathspecs, the planner's pruned
listing with a lazy scratch check for R4 readers, tracked-first judging, forked workers, a path budget and a time limit,
and `tests/test_build_dirs.sh`; plan identical to `949a8feb`'s on F's three change sets (23,552 sheet paths included) and
on the main tree's two bases (reasons differ on 7 gates of the old base, from the tracked-first order). Its four
judgement calls went to the maintainer, who discussed them, then: *"I'd go by default for planner processes = 12, the
rest can stay as is"* — measured here, 12 processes plan in 7.3/7.1 s against 27.2/26.8 s serial, plans identical. Item
2 waits for its with/without comparison; fork J found emulator-tier audits reading scratch-named dirs (`audit_chains174`
reads `build/agent185`), which item 2 must reclass first. Folded into this sitting's commit. Its census had passed only
because `tools/build_dirs.py` was untracked in the fork: tracked, it read its own selftest plants; the reader now skips
itself (gotcha written).

### (9) #312 AND #315 CLOSED DONE: A GATE'S CONTROLS RUN AS POOL JOBS; THE LIST HELD BY A CENSUS GATE
**Lane S** (ERIS WSL, `build/agent207/S/REPORT.md`, local; `refs/agent207/s312` `434f1bbf`): `tests/lib/static_pool.py`
replaces the runner's `xargs -P` pool and queues a gate's controls as jobs of their own once its run ends; for the gates on
`tests/controls_concurrent.txt` they run side by side, chosen from a `strace -f -y` write census of every control. On ERIS
a `--jobs 8` freeze tier went from about 1,670 s to about 760 s wall, 1.7 to about 4.1 cores, with results (220 rows)
and controls (390 rows) equal to a serial run. Landed in the fourth commit (`723b148f`) with 8 changed gates held off
the list. The maintainer ruled a census gate and a re-trace at each freeze (DECISIONS_HISTORY.md, 2026-10-24), filed as
**#315**. **Fork T** (PILOT, `build/agent207/T315/REPORT.md`, local; `refs/agent207/t315` `1c459df3`):
`tests/test_controls_concurrent.sh` (`tools/controls_concurrent.py`; controls unregistered, one-control,
changed-script) fails a listed gate that is unregistered, has fewer than two controls or whose script changed since its
trace; the list records each gate's traced blob and host; `tools/trace_controls.sh` and `tools/controls_overlap.py`
tracked, the re-trace added to HANDOFF.md's freeze steps. The re-trace cleared the 8 (test_static_runner among them) and
found that lane S had listed four jtcores gates from ERIS traces where they SKIPped: `test_mister_mra_map`'s two controls
share 340 written paths and stay serial. 97 gates listed. Rule-checker runs 2026-10-24-1237..-1240 and -1242 VIOLATED
and resolved, -1243 OK (-1241 prepared and not run); the named gaps include: no trace on macOS, no serial leg of the final
code, 18 listed gates that did not PASS on ERIS, the census seeing a gate's own script only. Two gotchas filed. Also
2026-10-24: ERIS's lane folders deleted (ruled); #279/#280/#281 kept closed (ruled). The commit tiers this sitting:
commit 4's GREEN, PASS 100, `test_static_runner`'s 23 controls serial (2,689 s), 4,730 s wall with snapshot setup.

### (8) #286, #303, #279, #280 AND #281 CLOSED DONE; LANES P AND P2 APPLIED
**#286** (rule-checker runs 2026-10-23-1215, -1216, -1218, -1219, -1222, -1225 VIOLATED and resolved, -1227 OK;
`build/agent207/R/claim286.txt`, local): a record-only probe `f3445a70` on `bbeedfed` ran a strict `--confirm` tier,
GREEN, 30 of 231 gates re-run, 0 controls executed; every traced opener of a record file re-ran or was deferred, none
carried. The readers found three blind spots of the trace, all now named on the ticket: 15 gates exited non-zero under
it, 15 printed a SKIP and 8 no verdict (4 skipped gates were carried here, on the planner's text rules alone) — a new
gotcha (`docs/project/gotchas.md` "A TRACE TAKEN WHERE A GATE SKIPS"). **Lanes P and P2** (`build/agent207/P/`,
`build/agent207/P2/`, local; `refs/agent207/p207`, `refs/agent207/p2`) applied to the main tree: the temp cleanups, the
new static gate `tests/test_tmp_hygiene.sh` (`tools/tmp_hygiene.py`; controls planted-mkdtemp, planted-mktemp,
planted-unsandboxed), callers passing a sandbox, the audits' default-folder cleanup as ruled, the packager's xdelta3
>= 3.2.0 check, section 3b's import order, the trace tool's named limit. PILOT now carries xdelta3 3.2.0 and Node
v24.22.1 user-local (ruled); its `/tmp` was cleared (ruled). **#303** (runs -1220, -1223, -1226, -1228, -1232, -1235
VIOLATED and resolved, -1236 OK): the audits remove their default folder and keep a given one (both measured on the
Mac, `build/agent207/P/close/audit_ctl/`, local). **#279, #280, #281** (runs -1230, -1231, -1233 VIOLATED and resolved,
-1234 OK): both release gates PASS on PILOT on a snapshot of the final tree (`7d38f1b5`); the packager refuses PILOT's
real apt xdelta3 3.0.11. Closed before a release because their done-whens are met with no release step left (the
maintainer had filed them release-only; flagged to them). Five gotchas filed (two project, three platform). Not run:
`test_mister_prg_window` on the final tree (~55 min), `run_suite.sh`'s sandboxed calls, a whole tier measured for
leftovers. Runs -1217, -1221, -1224, -1229 prepared and not run (NOT-RUN.txt in each).

### (7) #314 CLOSED DONE; #286'S HEREDOC NARROWING (N-K) LANDED
Lane Q (`build/agent207/Q/REPORT.md`, local; `refs/agent207/q314` `faef92f4`): `tools/gen_applier_page.py` named no
encoding — on ERIS it did not only write CRLF but stopped at its page write with `UnicodeEncodeError`; fixed, the guard
shared as `tests/lib/hosttext.py`, `test_applier_page` control `unencoded-page`, the static gate over all four release
text tools (control `applier-no-newline`); the pages ERIS writes, guarded and plain, equal the Mac's shipped pages; a
source-built MAME builds on ERIS's MSYS2 unchanged (709 s) and `test_readme_recording` passes there as designed.
Rule-checker runs 2026-10-23-1212, -1213 VIOLATED and resolved, -1214 OK; **#314 closed done**. Lane R
(`build/agent207/R/REPORT.md`, local; `refs/agent207/r286` `04e8324b`): N-K, a Python heredoc read as Python for R3,
scored on an ERIS WSL trace (0 misses over 94,317 reads, control 90); predicted record-only re-runs 52 → 44, 15 open a
record file, 0 controls. The other 29 the maintainer accepted as precision cost (DECISIONS_HISTORY.md). #286 closes on
a measured record-only `--confirm` tier of the tree with N-K.
**Resolved:** #286 closed done — (8).

### (6) PILOT AND ERIS LANES (P, P2, Q, R, S and T done and applied; see (8) and (9))
The maintainer: use PILOT and ERIS for other tickets, preparing a freeze+release *"as soon as we have a stable situation"*,
and chose the lanes (DECISIONS_HISTORY.md "Ruled 2026-10-23 (14z-207) — the PILOT and ERIS lanes"): P on PILOT — its disk first (98% full; the maintainer
approved deleting the old session work folders after a check: *"Yes, after the check (Recommended)"*), then #303, then
the release-only #279, #280, #281, #278; Q on ERIS (Windows) — #314, the Windows packaging leg, a source-built MAME; R on
ERIS (WSL) — #286's 25 narrowings, each scored on a trace; S on ERIS (WSL) — #312. All four from commit object
`2a155ba3` (`refs/agent207/base2`, the whole tree). #298 is measured at this sitting's close; #304 item 2 stays on the
Mac.

### (5) THE FIRST COMMIT TIER WAS NOT GREEN — FIXED
The strict `--confirm` tier of the staged tree (snapshot of `4dfd9fd3`, `build/agent207/commit_tier/tier.log`, local):
PASS 99, FAIL 4, MISSING 1. Causes: `tests/test_host_text_opens.sh` created without its execute bit (MISSING, and
`test_static_runner` FAIL on it); the rule-checker run directories 1194-1202 never staged (`git add -u` skips new
files; `test_rule_checker` FAIL); `test_poked_legs` FAIL on four new `test_proof_sheets` census rows (lane H's vsav2
leg; CROSS-INERT, as `test_hui_oracle`'s); `test_poke_readback` FAIL on three findings with no row. The maintainer
classed them (DECISIONS_HISTORY.md, three entries): `test_proof_sheets` c1 CROSS-LEG; `audit_trap_air_hit` p1x first
OBSERVES, then — rule-checker run 2026-10-23-1204 showed its frozen steps hold the pinned 540 the whole window —
READS-BACK, labelled in the gate's header; vx OBSERVES, its 3511 rows (the pin held the whole window, run -1205) noted
in the header. The two expectation edits: rule-checker runs 2026-10-23-1203..-1205 VIOLATED and resolved, -1206 OK.

### CLOSE (14z-207, 2026-10-24)
The close's steps (`docs/project/session_close.md`, `tools/close.py`, run `build/agent207/close/`, local), filled as they run.
The maintainer, asked what next once every lane had reported: *"Close the session now (Recommended)"*. **sections:** (1)-(9),
with pointers in (3) and (7) to (8). **next-session:** `docs/NEXT_SESSION.md` rewritten as the 14z-207 opener; the 14z-206
opener moved verbatim to the top of `docs/NEXT_SESSION_HISTORY.md`. **rollover:** nothing to move (this group is the
only one). **indexes:** regenerated. **dashboard:** 14z-163..14z-207 collected (1,916 figures, 0 unclassed; 14z-207: 40,
transcript `e552692b`), the four files uploaded, datasets versions 14, 14, 15, 14. Also before the record: #278's
progress comment posted (lane P's locale measurement; no closure). **The tier's results:**
`build/agent207/close/tier_results.tsv`, the next close's `--prev`; its verdict and time line go in the close commit's
message (the staged tree cannot hold them) and the next sitting's opening record. The staged tree carries fork T's #315 change (`refs/agent207/t315`) with the records.
**The first close tier was NOT GREEN** (snapshot of `fd4dbb54`, `build/snapshot_runs/20261024T100115-fd4dbb549dd1`, local):
PASS 95, FAIL 2, the runner's wall 822 s (commit 4's tier: 3,156 s). `test_live_budget`: fork T's freeze step took
HANDOFF.md to 503 lines and 50,369 bytes; the step moved to `docs/project/operations.md` "THE CONCURRENT-CONTROLS
RE-TRACE", a two-line pointer left. `test_build_dirs`: `tests/test_controls_concurrent.sh`'s synthetic strace lines named
`/r/build/a` and `/r/build/b`, which the census read as unclassed `build/` directories; renamed `/r/w/…`. Both PASS
after, the census gate's three modes still exit 1. A new gate's fixture strings tripped a tree census twice this
sitting (also `test_mame_bin_pinned`, (8)).

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
