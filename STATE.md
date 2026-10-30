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

## Session 14z-213 — **#267 and #335 closed done (the green guard admits the ledger page, published to gh-pages; the dashboard's actions panel); #337 closed done (EXIT-trap order); #338 done, awaiting release (the proof sheets' web build, fourteen controls, after thirteen rule-checker rounds); #310's classifier rules 1-4 and the whole emulator tier read on ERIS (222 honoured, five LIES fixed; kept open); #340 found and fixed (a dead registry row turned every strict emulator run red); #339 filed; #118's branches settled and its static pass S0 run.**

### opened with
The 14z-212 close's opener; the sweep CLEAN, `main` = `origin/main` at `d6393610`. The maintainer: **"Let's start with item
1,2 and 3"**, then the order #337, #338, #310, and PILOT/ERIS for #118 and light parked tickets (`DECISIONS_HISTORY.md`,
14z-213). Working evidence: `build/agent213/` (local).

### (1) #267 — THE GREEN GUARD ADMITS THE LEDGER PAGE; PUBLISHED
The guard (`tools/git-hooks/green_guard.py`, edit-locked) lets ONE push through with no tier row: a parentless commit of
exactly `.nojekyll index.html ledger.css ledger.js` to `refs/heads/gh-pages`; any other commit to gh-pages, or the page to
another branch, is judged as before. Drafted and proven in a worktree (`build/agent213/t267/`), applied by the maintainer
(*"guard part applied for item 1"*). `tests/test_green_guard.sh` section 7 (seven cases) and three controls
(`guard-page-any-ref`, `-shape`, `-parent`); `tests/test_ledger_page.sh` now publishes through the real hooks (it FAILs on
the unpatched guard). `test_green_guard` re-traced on PILOT (SAFE); `test_ledger_page` is not on the concurrent-controls
list, so it needs none. Published `12a87ea0` to gh-pages; the maintainer switched Pages to it (**"I switched GH pages
deploy from a branch to gh-pages branch"**); live and byte-identical to the commit, all 11 sections rendered; the own-site
leg SKIPPED (`DEPLOY_TARGET` unset, as ruled). **Closed done** on rule-checker run 2026-10-30-1416 (after -1412, -1415).

### (2) #335 — THE DASHBOARD'S ACTIONS PANEL
"Actions: OK at the first check" added to the dashboard page (store version 2): tiles, per-decision first-run OK rate and
questions on first runs (selected session or all), the per-session trend, the actions table; the two not-counted kinds
shown apart. Two `dash.calc`s; every calculated value equals the collector's own figure (635 checked; the 171 session
totals equal their decision rows' sums). The maintainer: **"The dashboard new sections are fine"** (`DECISIONS_HISTORY.md`).
**Closed done** on rule-checker run 2026-10-30-1425, after nine VIOLATED runs (-1413, -1417 to -1424), each a real gap: the
charts' notes now state the collector's class (ESTIMATED, store version 6); `tests/test_session_metrics.sh` gained five
controls (`lowest-question`, `later-run-questions`, `calibration-counted`, `not-run-ignored`, `void-only-dropped`) and a
VOID-only action in its synthetic ledger, re-traced on PILOT (12 runs, SAFE); the collector as gated reproduces the
page's dataset (306 actions, 816 action figures identical). Found on the way and filed as **#339**: 37 ledger rows carry
session `-` and both ledger pages drop them without a word.

### (3) THE REMOTE SCRATCH
PILOT: 76 entries of 14z-211/212 removed (50 -> 65 GB free); ERIS: four dirs, 13 GB. The cited evidence is local under
`build/agent212/`.

### (4) #337 — EXIT-TRAP ORDER CHECKED; CLOSED DONE
`tools/tmp_hygiene.py`: TRAPPED (an EXIT trap set before a guarded site's stop naming `"$X/..."`), UNREADTRAP, a shlex
trap reader, every `trap` word not an argument read, a quote-aware comment cut (shared with #333's check). Fifteen trapped
forms, eight safe, two unreadable; controls `planted-trapped`, `planted-unread-trap`. On the tree: 487 guarded sites, 481
EXIT traps, 0 TRAPPED; a second reader sharing no census code agrees; every one of 744 `trap` lines accounted for.
Rule-checker runs 2026-10-30-1406, -1407, -1409, -1410 each caught a real gap; the maintainer then ruled **"Fix (b), state
(a)"** (cross-file pairing a stated limit, measured 0), and run -1411's last form (EXIT spelled `exit`) was stated as a
limit. Closed with its comment. Re-traced on PILOT five times; `tests/controls_concurrent.txt` refreshed.

### (5) #338 — THE PROOF SHEETS' WEB BUILD; DONE, AWAITING RELEASE
`tools/proof_sheets.py web <local run> --to <dir> --release <tag>` and `webcheck`, and `tools/publish_sheets.sh` (webcheck,
then `<DEPLOY_TARGET>vs-proof-sheets/`). The maintainer, 14z-213: the clips **"Keep, reduced, add a short description to
explain that it is short and down sampled"**; the path **"vs-proof-sheets/ (Recommended)"**; on the screenshots **"looks
good to me"**, **"they look good"**, on the footers **"they do"**, on the clip caption **"do it"**, on the intro's JUDGED
FILE line **"…this exact image or sound clip” has my preference"**, on the builds sentence **"Count from the run
(Recommended)"** (`DECISIONS_HISTORY.md`). The credits were read off the three games' own title screens (MAME captures).
Every page links one `sheets.css` with no inline style or script, so the site's `style-src 'self'` serves it (all 102 pages
rendered under that policy, 0 refusals). webcheck finds a local path by the scrub's own pattern and a detector of its own,
and refuses any link to anything but a file inside the build. Gate `tests/test_proof_sheets_web.sh` (ondemand; fourteen
controls). Trial on 14z-207's full run with the final tool (`93b75d9b`): 102 pages, 23,183 tiles, 152 clips, 1 min 42.5 s
(1 min 39.0 s at `d84a7eb1`), webcheck PASS; a second reader sharing no code with the tool (its own token-based path
detector, 16 known answers) and a raw-bytes search of every file agree; the final draw equals the one the maintainer saw
after exactly the intended substitutions. **Done, awaiting release** on rule-checker run 2026-10-30-1440, after
thirteen VIOLATED runs (-1414, -1427 to -1429, -1431 to -1439), each a real gap fixed (`build/agent213/t338/closure/`,
local); its comment is posted after the close commit. Drawn and published at the next tagged release, which closes it.

### (6) #118 — THE BRANCHES SETTLED, THE CLASSIFICATION IN THE TREE
Ruled (`DECISIONS_HISTORY.md`, 14z-213): t118-196 dropped and t118-196-struct deleted, both kept as `archive/` tags (41
and 5 citations on main); the struct worktree removed after its local evidence was copied in. The classification
re-derived from `ram.md` as `docs/game/atlas/mizuumi_candidates.tsv` (89 offsets: CONSISTENT 35, NOT ADOPTED 19, NO ROW 12,
OWNER ONLY 11, COVERED 5, NOT OBSERVED 4, CROSS-CHECKED 1, REFUTED 1, REFUTED IN PART 1), its derived columns held by
`tools/mizuumi_candidates.py check` in `tests/test_mizuumi_candidates.sh` (the rules on eleven known answers, two
controls). Two `ram.md` errors the derivation found were corrected (`+0x119`'s check is A4; seven rows the inputs gate
covers said "not yet gated"). The remaining measurement is batched (B1 Anakaris rig .. B7, static decode) for PILOT/ERIS.
The batch plan was drafted (`build/agent213/t118/batch_plan_draft.md`, local) and, on the maintainer's word (**"Run S0 of the
#118 plan now, we're waiting anyway"**), its static pass S0 run on the Mac (`build/agent213/t118/s0/S0_REPORT.md`, local; no
emulator): a census of the 16 offsets in every addressing form, its known-answer control +0x3BD equal to the 44 frozen
rows of `tests/expected/latch_readers.tsv`. Its readings are static leads, not ram.md facts (the plan: a row changes only
after the measurement): among them +0xB2 a damage scaler, +0x316 Bishamon's charge counter, Gallon's tables never making
+0x366 non-zero, +0x3A8 a long. It flags `docs/game/atlas/character_tables.md:76` ("14 tables", 15 measured) — unchecked.

### (7) #310 — THE CLASSIFIER'S RULES 1-4
The 14z-210 census comment, drafted and never posted, posted on the issue. Ruled **"Classifier rules 1-4 (Recommended)"**.
`tests/lib/classify.sh`: its own `CONTROL DEAD` -> LIES; a SKIP exit with no FAIL -> UNJUDGED; its own exit-3 `REFUSED:`
-> UNJUDGED; an indented traceback or a `tests/lib` abort -> DIED. Measured on #299's 14z-206 legs (413 honoured controls
each): exactly five rows move. Read one by one: `test_defense_rows_census@tenant-row-moved` and
`test_bundle_parsers@unbundled-leftover` had tested NOTHING (the row move a no-op since the ruled fix; the leftover case only
in the in-gate block), now real; the other three printed an in-gate DEAD beside a real FAIL, the in-gate copies now skip a
mode. Known answers and four controls in `tests/test_control_classifier.sh`. Both changed gates re-traced on PILOT. The
emulator tier's controls run on ERIS at the session commit `0a1b9233`: the prereq lane stopped the run at once on
`audit_kill_poke_shape@two-byte-flowed`, read LIES by rule 1 — its forced-FLOWED mode reached the gate's own FAIL branch,
which also printed `CONTROL DEAD: two-byte-flowed` (the same in-gate DEAD shape as the three gates above). The DEAD line now
prints only outside a mode; on the Mac the gate PASSes and its mode is read HONOURED (`build/agent213/t310/killpoke/`).
Re-run on ERIS at scratch commit `3117828a` (0a1b9233 + that line), in a fresh log directory (a reused one kept the old
run's rows and commit of record: new gotcha): the whole emulator tier, every control executed, 3 h 21 min — 222 HONOURED,
5 LIES, no DIED or UNJUDGED (`build/agent213/t310/eris/e213c_out/`). The five are the same in-gate shape:
`audit_move_parity`'s mode perturbs every comparison, so section 3's in-gate controls printed their own DEAD (four modes;
section 3 now does not run under a mode, every mode still FAILing in section 2 or 2b, read in the ERIS logs), and
`audit_walker_repoint`'s main check printed its own DEAD beside its FAIL (now only outside its mode). Mac: both gates'
12 rows PASS or honoured; PILOT re-traced both, 10 controls HONOURED, SAFE (`pilot:dd0c9357`). **#340 found and fixed:**
`audit_pool_drop` (14z-212) names no emulator wrapper, so the emulator runner called its registry row DEAD and every
strict emulator run read NOT GREEN; both runners' classifier now counts a gate that reads `tests/ci_emulator.tsv` (240 of
240), `test_emulator_runner` §3 gains both sides of the case (PASS on the Mac and on PILOT; its 17 controls re-traced on PILOT, SAFE, `pilot:7172e62d`). #310's census shapes beyond rules
1-4 stay as ruled "Record and defer". The maintainer: **"Keep open (Recommended)"** — rules 1-4 and the ERIS census are progress, the deferred
shapes #310's remaining work.

### CLOSE (14z-213, 2026-10-30)
Opened on the maintainer's **"Start the close now (Recommended)"**. Driver `build/agent213/close/` (`--prev
build/agent212/close/tier_results.tsv`). Before it, within the sitting: #267 and #335 closed on GitHub with their comments
(runs `2026-10-30-1416`, `-1425`), #337 closed with its comment (after runs `-1406` to `-1411`); #338 done, awaiting release
on run `-1440` (its comment is posted after the close commit); #339 and #340 filed; `origin/main` fetched before staging
(nothing new; HEAD `0a1b9233` one commit ahead).
Steps: sections ((1)..(7), the group retitled); next-session (the 14z-212 opener to `docs/NEXT_SESSION_HISTORY.md`, L110);
rollover (the 14z-212 group, 154 lines, to `STATE_HISTORY.md` with its ledger line); indexes (the archives', the ticket
page, the gotchas index); dashboard (14z-163..14z-213, 3,023 figures, 0 unclassed; datasets versions 22, 23, 22, 22 and
`actions` 2) — done. The tier's results: `build/agent213/close/tier_results.tsv`, the next close's `--prev`.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **ERIS tiers skip parity; the Mac's parity run is the row of record (#321, 2026-10-26, 14z-209):** ERIS runs `--skip test_mame_parity` — `DECISIONS_HISTORY.md` "Ruled 2026-10-26 (14z-209) — #321 phase 2".
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
