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

## Session 14z-205b — **#229: six gates to registration standard (unregistered), the questions put, the maintainer's Q3/Q4 answers probed, Q1 partly confirmed on 9-tile sheets; #301 filed; #291 S3.** A continuation of 14z-205 after its close, on the same transcript (`995e7259`).

### opened with
The work after the 14z-205 close commit is recorded under STATE_HISTORY 14z-205 "CLOSE (14z-205, 2026-10-18)", in its bullets
"After the close commit" to "#273's replication, and #273 closed" (#276, #295, #257, #260, #273, #275, #299, #300 and
#291's notes). Then the maintainer: *"let's do #229"*, *"feel free to parallelize what you can: the whole machine is
yours"*, and on the plan, *"All in parallel"*.

### (1) #229 — SIX GATES BUILT TO THE REGISTRATION STANDARD, NOT REGISTERED
Six forks measured the community workbook `vsav-framedata.xlsx` against vsavj in MAME, one family each, naming every
move by what the engine did (its chain, the stock spent, the objects spawned; [VSE-47]), never by the input:
`tests/audit_vanilla_specials_a.sh` (F1), `tests/audit_vanilla_specials_b.sh` (F2), `tests/audit_es_ex.sh` (F3),
`tests/audit_command_throws.sh` (F4), `tests/audit_guard_cancels.sh` (F5) and `tests/audit_vanilla_pursuits.sh` (F6).
Each final run PASSES and every control fails as its own mode (the forks' `REPORT_followup.md`,
`build/agent205/t229/f<N>_*/`, local). **They are not registered and not committed:** their expectations wait for Q1
(identity by eye) and a rule-checker run before any freeze. The 105 untracked files (the six gates, their
expectations, rigs, Lua and `tools/*_rigs.py`) are listed in `build/agent205/t229/pending_gates_229.list` and backed up
in `pending_gates_229.tar` beside it (local). F5's expectations are drafts in its own directory. Per-move values stay
out of the tree (identity in the clear, a hash of the numbers; the 14z-126 ruling).

### (2) #229 — THE QUESTIONS AND THE COMMUNITY CROSS-CHECK; #301 FILED
The maintainer: *"Can you make a document that lists all the questions I need to answer and the pointers/links to the
ressources they relate to. Also, if you have inconsistencies than would be valuable to report to the community and/or
cross check with the japanese reverse engineered data, can you make a document of it and create a related ticket"*,
then *"I think the empty doc got closed but otherwise please create and fill both documents"*.
- The questions doc (Q1-Q7): https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE (private; local source
  `build/agent205/t229/questions_for_maintainer.md`); rule-checker run `2026-10-20-1150` (VIOLATED Q1 Q2 Q4 Q5,
  resolved).
- The community cross-check doc: https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK (private; it quotes per-move values;
  local source `build/agent205/t229/community_report.md`); rule-checker run `2026-10-20-1151` (VIOLATED Q1-Q4, resolved).
- **#301 filed** (evolution): report the workbook differences once identity is confirmed, and check the open
  questions against seesaawiki vswiki. Its body names classes only.

### (3) #229 — Q3 AND Q4 ANSWERED IN THE DOC; FOUR PROBE ROUNDS
The maintainer answered most of Q3 (how the never-fired moves are performed) and Q4 (rows whose workbook input
differs) in the questions doc; copied verbatim to `build/agent205/t229/answers_q3_q4_rev1216.md` (local) and recorded
in `DECISIONS_HISTORY.md` "Read 2026-10-20 (14z-205b) — #229". Four probe forks (P1-P4, no gate edits,
`build/agent205/t229/p<N>_*/REPORT.md`, local) tried every answered input; every one fires. What they add:
- **Big Swing's LK grab** (F4 measured it; the maintainer had written "never light"): re-checked, it stands; shown on
  `p3_throws/sheets/row1_light_grabs.png`, the maintainer: *"you are correct, light grabs on the specific command grabs
  you show on the capture sheet"*.
- Catch and Release, Karame Dama and Hell's Gate: the engine's trackers are 4-1-2-3 + button, so mizuumi's 4123 and the
  Japanese RE's 41236 both work. Demon Billion is 263KK; ES Rolling Buckler is one paid move (236PP); Tenraiha fires
  on LK,HK,MP,MP,8; HK SXP never spends stock.
- Situational moves: Kienzen (623P/PP) is accepted only in a window as stun or a knockdown ends or on landing (his
  guard cancel's chains); Tsuji Hayate only after Karame Dama connects; BI ES 22PP, FE 22P and ES 22PP are pursuits;
  Pit of Blame only from a knockdown; Prova di Servo needs a second K; Victor's air throw connects only when both
  fighters converge.
- **F3's "ES Ira Pino" join is wrong:** `J.63214KK` alone is ES Ira Spinta; the paying ES Piano is `J.63214KK` then P.
- **F1's row-38 join is wrong:** the maintainer, on the 236P rows: *"maybe they are 236+P but since Karame Dama has not
  been sucessfully performed on the opponent before, even if the input was 236+P, it only results in 6+P"*.
- A rig trap: `nm.hcf`'s gapped back taps make Bishamon backdash before the button.
The community doc and its local source carry these (40 candidate differences).

### (4) #229 — Q1 ON 9-TILE SHEETS; WHAT IS CONFIRMED
The maintainer: *"For Q1, I really could use more captures, 5 per move is the strict minimum and 9 is likely
preferable."* Three sheet forks remade every family's sheets at 9 tiles per move (one more per extra hit on
pursuits), from each frozen gate's own events, every tile's frame checked against the gate's trace
(`build/agent205/t229/f<N>_*/cap9/`, local). The maintainer then: *"FYI I don't see any row boxed or highlighted"*:
the rows to look at first carried only tinted text or a thin outline. Re-rendered from the same snapshots with a
filled band and a thick frame, and an index of every flagged row by sheet and row number
(`build/agent205/t229/look_first_index.md`, made by `look_first_index.py`). **Confirmed so far** (verbatim in
`build/agent205/t229/answers_q1.md`, local, and the DECISIONS_HISTORY entry): every pursuit (*"For Q1 all the
pursuits look good"*), the five light grabs, Hell's Gate and Ira Piano. Not yet looked at: the rest of the specials,
ES/EX, the guard cancels and the command throws.

### (5) #229 — TWO RUNS ON PILOT (PROBES ONLY), AND A RULE BROKEN
The maintainer: *"checking all of this will take a bit of time. While I do that, can you check if you can reach PILOT?"*,
then *"yes"*. PILOT was reachable (6 vCPU, 47 GB; `ROMDIR=~/roms`, 76 of 76 members against `docs/checksums.txt`).
- **Ira Piano's startup** (R1, `build/agent205/t229/r1_ira_piano/`): the workbook's 62 is the duration-byte sum from the
  K press (Ira Spinta 36 + Piano 26); live it is 59 ticks (Piano's last node never plays); F1's 26 times Piano alone.
  A counting convention, not a disagreement.
- **The pursuits mid-screen** (R2, `build/agent205/t229/r2_pursuits_mid/`): all 75 events equal F6's on every field it
  reads; the bands and 8K's start edge unchanged; none of Q2's four claims moves toward the workbook. F6's own presses
  were in the corner on 51 of 60 knockdowns, not all (P4's "every press" held for P4's rigs only).
- **Broken:** both runs used an rsync of the uncommitted working tree, where `docs/project/working_methods.md` "When
  to commit" says work handed to PILOT is a bundle of a commit. Nothing from them entered a gate or an expectation.

### (6) #291 S3 — BUILT FROM THE COMMIT, `--host pilot|eris`; PROVEN ON PILOT WITH A FILTER
The maintainer: *"Since PILOT is available, could we make it do the remaining of #291?"*, then *"I don't mind the commit
and we could even close and start #291 on a fresh session, just make sure that we keep track of all of #229 that is
still ongoing/todo/waiting for me."* `tools/proof_sheets.py run <commit>` now bundles the commit, clones it clean,
checks the ROMs against that commit's `docs/checksums.txt`, builds the five tracks its `tests/run_all_emulator.sh` names
(the `tests/test_m3a_reproducible.sh` recipe) and refuses the run unless every track's fingerprint equals the commit's
own `EXPECT_*`; an `ours` picture whose leg did not run on a build made in that checkout is NOT THE JUDGED RUN
(`commit_check`). The working-tree mode of S1 is gone ("Built from the commit"). `--host pilot|eris` sends the bundle
and the tool, runs detached with bounded polls, and brings `build/sheets/<commit>/` back; ERIS is written and untested.
Ground truth: `tests/test_proof_sheets.sh` section 4c, controls `build-blind` and `fingerprint-blind` (each FAILs the gate
as its mode); `test_proof_sheets` and `test_sheet_census` PASS. **On PILOT, filtered** (`audit_entrance_draw`,
`test_hui_grab_victim`, `audit_trap_shock` at `779bc589`): 319 s end to end, the five tracks equal their references,
27 pictures, 27 PROVEN (`build/sheets/779bc589d39e/`, local; the fork's report `build/agent205/t291s3/REPORT.md`).
Not run: the unfiltered run (estimated 2-3 h on PILOT), which runs from this close's commit next session. Three gates
default to builds a commit does not make (`test_gfx_menus` and `audit_mask_window_ff4182` on `build/donovan6`,
`audit_landing_sound`'s control on `build/m3b_merged30`) and will show NOT THE JUDGED RUN.

### (7) #299 NOT CLOSED: ITS CLOSURE'S RULE-CHECKER FOUND THE PLAN UNFINISHED
START HERE had #299 closing at this close. Rule-checker run `2026-10-20-1152` (VIOLATED Q1 Q3 Q4, plant caught): the
plan's step 2 asked for every gate's output compared, and only verdicts and summaries were; the cold decrypt cache,
collisions between concurrent gates and wall-clock gates under load are uncontrolled. Resolved by withdrawing the
closure: #299 stays open, its comment of 2026-10-20 names the four items left. The close's `--jobs 8` default stands
(ruled 2026-10-19).

### CLOSE (14z-205b, 2026-10-20)
Run by the step table and its driver (`docs/project/session_close.md`, `tools/close.py`; run dir
`build/agent205b/close`, local). The maintainer, on closing now: *"I don't mind the commit and we could even close and
start #291 on a fresh session"*.
- sections, next-session and rollover done by hand (the 14z-205 group rolled to STATE_HISTORY with its ledger line; no
  `STATE.md §` citation pointed into it); indexes regenerated (`tools/close.py next`);
- dashboard re-collected for 14z-163..14z-205b (1,814 figures, 0 unclassed) and uploaded (datasets versions 11, 11,
  12, 11);
- bookkeeping gates before the tier: `test_tickets`, `test_state_open_lists`, `test_live_budget`,
  `test_gotchas_index_current`, `test_history_index`, `test_rulings_verbatim` PASS; `test_gate_index_current` FAILS on
  the working tree only because of #229's six untracked gates (the staged snapshot does not hold them);
- **#229's 105 untracked files are deliberately NOT staged** (expectations not yet rule-checked, Q1 unfinished; listed
  in `build/agent205/t229/pending_gates_229.list`, backed up beside it);
- the tier's results file, the next close's `--prev`: `build/agent205b/close/tier_results.tsv`.
- **tier run 1 RED** (PASS 95 FAIL 3: `test_gate_follows`, `test_gate_coverage_current`, `test_tickets`) and **run 2 RED**
  (PASS 95 FAIL 3: the last two and `test_gate_index_current`), both at `--jobs 8`
  (`build/agent205b/close/tier.run1.log`, `tier.run2.log`, local). All four were real, not a collision between
  concurrent gates as I first told the maintainer (my snapshot probe's filter hid the failure lines; a clean worktree of
  the staged commit showed them): S3 changed `test_proof_sheets`' header without the gate index, the coverage page or
  its FOLLOWS (`build/manifest/`, which the widening rule asks of a gate naming `/rompath`) being regenerated or
  widened, and #301's repro column named the six untracked #229 gates (set to `none` until they register, NEXT_SESSION
  START HERE 2). Fixed and re-staged; the six gates pass in a clean worktree of the staged tree.

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
