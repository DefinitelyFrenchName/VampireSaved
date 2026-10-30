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

## Session 14z-213 — **#267's green guard admits the ledger page (patch applied by the maintainer) and the page is on gh-pages; #335's dashboard panel built; the remote scratch cleared; #337 closed done (the mktemp census checks EXIT-trap order, five rule-checker rounds); #338's web build begun; #118's branches settled by ruling.**

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

### (5) #338 — THE PROOF SHEETS' WEB BUILD
`tools/proof_sheets.py web <local run> --to <dir> --release <tag>` and `webcheck`, and `tools/publish_sheets.sh` (webcheck,
then `<DEPLOY_TARGET>vs-proof-sheets/`). The maintainer, 14z-213: the clips **"Keep, reduced, add a short description to
explain that it is short and down sampled"**; the path **"vs-proof-sheets/ (Recommended)"**. The credits were read off the
three games' own title screens (MAME captures, `build/agent213/t338/titles/`). Trial on 14z-207's full run: 102 pages,
23,183 tiles, 152 clips in 1 min 41 s, 306 MB, webcheck PASS; headless-Chrome screenshots of the index and a gate page
(`build/agent213/t338/shots/`) led to one more scrub (session build paths). Gate `tests/test_proof_sheets_web.sh`
(ondemand; five controls); `docs/project/release_format.md` «The proof sheets' web build». The maintainer on the
screenshots: **"looks good to me"** (`DECISIONS_HISTORY.md`). Drawn and published at the next tagged release.

### (6) #118 — THE BRANCHES SETTLED, THE CLASSIFICATION IN THE TREE
Ruled (`DECISIONS_HISTORY.md`, 14z-213): t118-196 dropped and t118-196-struct deleted, both kept as `archive/` tags (41
and 5 citations on main); the struct worktree removed after its local evidence was copied in. The classification
re-derived from `ram.md` as `docs/game/atlas/mizuumi_candidates.tsv` (89 offsets: CONSISTENT 35, NOT ADOPTED 19, NO ROW 12,
OWNER ONLY 11, COVERED 5, NOT OBSERVED 4, CROSS-CHECKED 1, REFUTED 1, REFUTED IN PART 1), its derived columns held by
`tools/mizuumi_candidates.py check` in `tests/test_mizuumi_candidates.sh` (the rules on eleven known answers, two
controls). Two `ram.md` errors the derivation found were corrected (`+0x119`'s check is A4; seven rows the inputs gate
covers said "not yet gated"). The remaining measurement is batched (B1 Anakaris rig .. B7, static decode) for PILOT/ERIS.

### (7) #310 — THE CLASSIFIER'S RULES 1-4
The 14z-210 census comment, drafted and never posted, posted on the issue. Ruled **"Classifier rules 1-4 (Recommended)"**.
`tests/lib/classify.sh`: its own `CONTROL DEAD` -> LIES; a SKIP exit with no FAIL -> UNJUDGED; its own exit-3 `REFUSED:`
-> UNJUDGED; an indented traceback or a `tests/lib` abort -> DIED. Measured on #299's 14z-206 legs (413 honoured controls
each): exactly five rows move. Read one by one: `test_defense_rows_census@tenant-row-moved` and
`test_bundle_parsers@unbundled-leftover` had tested NOTHING (the row move a no-op since the ruled fix; the leftover case only
in the in-gate block), now real; the other three printed an in-gate DEAD beside a real FAIL, the in-gate copies now skip a
mode. Known answers and four controls in `tests/test_control_classifier.sh`. Both changed gates re-traced on PILOT. The
emulator tier's controls are not yet re-read under the new rules (their logs were on ERIS).

## Session 14z-212 — **#330, #333, #334 and #336 closed done on their rule-checker runs (the command throws measured, every family on three victims; the mktemp census read every `mktemp -d` form and 0 sites carry on, EXIT-trap order a stated limit filed as #337; #321's remainder, 61 gates 7,648 -> 4,163 s on ERIS; dash's write-error wording); #335 built (actions linked, first-run OK rate per decision); #267 unparked and built (the ledger as a public page, published at this close).**

### opened with
The 14z-211 close's opener; the sweep CLEAN, `main` = `origin/main` at `33f85438`; PILOT and ERIS reachable again. The
maintainer agreed the order (#333/#334 first, #330 beside) and ruled the other low-priority tickets "can be considered to
be done when a machine is available" (`DECISIONS_HISTORY.md`, 14z-212). Working evidence: `build/agent212/` (local).

### (1) #333 AND #334 — THE PILOT RE-TRACE, ERIS'S TIMINGS
**The concurrent-controls re-trace** (PILOT, a fresh clone of the working tree as a commit-tree, `6829e446`): 46 static and
22 emulator gates SAFE, none SHARED. Four first read HOLLOW: the clone setup skipped build dirs that hold tracked files
(`hui30`, `merged1`: no `rompath/`) and never initialised `emu/jtcores`; topped up and re-traced SAFE (gotcha "A FRESH
CLONE'S `build/` IS NOT THE MAIN TREE'S").

**#334 item 2** ("All 62", 14z-211; its entry was never written and is recovered verbatim from 14z-211's transcript): each
gate alone on ERIS, HEAD's script against the #334 tree, one at a time. 61 edited gates: **7,648 s -> 4,163 s, every verdict
PASS on both sides, none slower by more than 5 s**; `test_release_binaries` ruled out (each step needs the one before).
`test_wide_profile` first FAILed on both sides on a fresh clone's patch mtime (gotcha above), re-timed after `touch -r`:
352 -> 122 s. `audit_id_writers` had been edited but left out of the batch reports; timed: 174 -> 59 s.
`operations.md` «WHAT #321 MEASURED AND RULED OUT».

**#334 closed done** (run 2026-10-29-1378 OK). Run 1376 had stopped it (Q1, Q4, Q5):
- **Q5:** the Mac leg's ruling was a gloss. The picked option's own text is now quoted: *"Rule out the Mac-under-load leg
  except parity, because the Mac runs no other knob gate in any tier."*
- **Q1:** `audit_guard_cancels` had FAILed at both settings on PILOT (its table is absent there). On the Mac it PASSes at 2
  and 6. The load tier's five FAILs are named.
- **Q4:** could an edited gate still FAIL when its pool loses a run? Each of the 61 was run on a Mac snapshot, as is and
  with the pool's first run dropped. 59 FAILed; `audit_type_writes` and `audit_id_writers` PASSED (each globbed the
  traces it found). Both now name their legs and fail on a missing one, so all 61 fail.
- Kept as **`tests/audit_pool_drop.sh`**, with the hook `VS_POOL_DROP_FIRST` in `tests/lib/jobs.sh`. It is ondemand under
  a new reason keyword `harness:`; the maintainer: **"Ondemand, new 'harness:' (Recommended)"**.
- New gotcha: "A POOLED GATE THAT GLOBS ITS OUTPUTS CANNOT SEE A LOST RUN".

### (2) #330 — THE COMMAND THROWS RE-MEASURED; THE VICTIMS; CLOSED DONE
**24 grabs have no whiff** (the maintainer: "No whiff (Recommended)", then "Yes, no whiff (Recommended)" for the 360s): the
632[4] / 6324 grabs of AU FE GA JE MO QB ZA and BI/DE's 360 MP/HP start their move only when the throw check
(CPU:$029406) passes; far, or at contact on a jumping Victor (4 timings), the input is the plain normal or a jump. The
four ES grabs' own seq 0x12 is their whiff ("Yes, it is the whiff"). My "20, not 28" to the maintainer was wrong (28 of 78
far whiffs were three kinds) and was corrected before the next question. Cryptic Needle's far whiff is its own move.
**The gate**: CMD_GATED, CMD_ES_WHIFF; a whiff must start the seq its input starts when it connects and never hold; new
controls gated-whiff, es-exemption-dropped, whiff-at-contact; the command family in the default run; the script blob in
every log header. **Victims**: air on Demitri (28) verified, Lilith (20: AU GA JE VI never hold on her, left out), command on
Demitri (78) and Lilith (76). **Classified**: command whiffs sheet = ours +1 on 32 of 41; the air tech against the victim
range (Bulleta inside it). **Captures** read: ES/360 pages, gated pages ("Yes, it stands"), the command-whiff LP page ("Yes").
Rule-checker runs 1364 (Q1 Q2 Q4), 1365 (Q1 Q4), 1369 (Q1) stopped it, each answered; **1370 OK**. Two edits to the gate
while a run read it broke that run ([MJC-54]; re-run on the unchanged script both times).

### (3) #333 — THE CENSUS'S REACH, ROUND BY ROUND; CLOSED DONE
Run 1366: the census read only line-start `X="$(mktemp -d …)"`; widened (else arms, `[ -n ] ||`, case arms, inline
arguments, after `;`, `-dt`), an arithmetic `<<` no longer read as a heredoc; 10 more sites guarded. The maintainer: "Finish
it now (Recommended)". Run 1368: `export`/`readonly` never guarded, `|| true` not a guard, `set -e` by position (one real
site found: `test_rompath_reject.sh`, before its `set -eu`). Run 1371: here-strings, quoted `<<`, `(( << ))`, backticks,
`--directory`, continuations, `||` arm scoping, `[ -n ]` from code; the maintainer: "Fix when back (Recommended)". Run 1374
(NOT RUN: the Mac slept mid-reader; its findings taken): a mktemp not first in its substitution, quoted `set -e`.
- **Rounds six to eight** (runs 1379, 1380, 1382): quoted `exit`, `return` outside a function, a subshell's `set -e`, the
  escaped-quote test, `|| (exit 2)`, `set ±o errexit`, a conditional `set -e`. The maintainer: **"Fix all four now"**,
  **"Fix both forms, name (c)"**, then **"Fix these + state the limit"**: the census is a lint over shell text, not an
  interpreter.
- **The record, measured** (`rounds_census.txt`: today's census over each round's tree): 120 unguarded before #333
  (`33f85438`), 11 after the first-round edits, 1 after run 1366's fixes, 0 from run 1368's on. Two questions to the
  maintainer had stated it inexactly ("none ever occurred", "0 real instances"); both corrected in `DECISIONS_HISTORY.md`
  and asked again on the exact record: **"Ruling stands, fix record"**, then **"Stands, use exact wording"**.
- **Runs 1385 to 1403 found gaps in the EVIDENCE**, each measured and answered:
  - the mtime search's idioms widened twice; still `test_wide_profile` alone;
  - a `-d` after a nested substitution hides from the census and its reach check alike: 0 on the tree, named;
  - the reach check listed files with `git ls-files "tools/*.sh"`, whose `*` matches `/`. That exposed the **two real
    unguarded sites outside the census**: `tools/agent/probe_agents.sh` and `probe_hooks.sh`. The maintainer: **"Guard
    both, name scope"**. Both guarded and checked live; every evidence script re-run over the census's own file list.
  - **EXIT-trap order** (a trap installed before a guarded site runs on the guard's stop): six successive readings, the
    last order-free (`rm_any.py`: every `rm` of the variable with a suffix, 183 pairs, 11 trap-reachable, 0 real), each
    with a planted control, and each stopped on a premise of its own. The maintainer: **"State it as a limit + ticket"** —
    a stated limit, its readings best-effort evidence, every premise named; **#337 filed** to have the census check it.
- **Closed done** on run 2026-10-30-1404 OK (22 runs; the closing comment and row in `build/agent212/t333/closure/`).
  Today: 0 unguarded of 487 read; thirty-seven unguarded and twenty guarded known answers; `test_tmp_hygiene` re-traced
  on PILOT after each round of its own changes.

### (4) #335 — THE LEDGER'S ACTIONS: FIRST-RUN OK RATE, AND WHICH QUESTION FAILS
Filed at the maintainer's word (the side chat's analysis recorded as a hypothesis, not agreed), then built while the Mac
was off the network.
- **The rulings:** the first run by **"Link, else wording"** (with *"Is it possible to implement an action id in the
  future?"*, built now), **"Every question (Recommended)"** and **"Excluded, shown apart (Recommended)"**.
- **`tools/rc_actions.py`** decides which runs are one action: the action `meta.tsv` records, else a same-decision run
  the subject names, else wording (ESTIMATED).
- **`prepare --redoes <run>`** and an `action` line in every run's `meta.tsv`; a reworded re-check without it gets a NOTE.
- **The dashboard collector** emits per-session actions, first-run OK and rate per decision, questions on first runs,
  packets not run, and `actions.json`.
- **Measured over the whole ledger:** 337 actions, 21 OK on their first run. On first runs Q1 264 and Q4 222 lead;
  Q2 35 is the rarest.
- **Gates:** `test_session_metrics` (three new controls) and `test_rule_checker` (PREPARE REDOES, control `ok-redone`).
- **At the close:** `actions.json` uploaded as a fifth dataset (`datasets/actions`); the dashboard's page has no panel
  reading it yet, so #335 stays open (NEXT_SESSION START HERE).

### (5) #267 UNPARKED AND BUILT — THE SESSION LEDGER AS A PUBLIC PAGE
The maintainer: **"Unpark #267 and build it"**; *"Claude hosting comes with limitations, including on visibility that
will become a problem."*
- **Rulings:** **"gh-pages is fine"** (their personal website the alternative), **"All but your own figures"**, **"Keep
  both for now"**.
- **`tools/ledger_page.py`:** one self-contained page, the datasets gzip-embedded, no fetch; checked by hand in headless
  Chrome over the real 61 sessions, 275 KB.
- **`tools/publish_ledger.sh --push`:** one orphan commit on `gh-pages`, force-pushed under a lease.
- **The close:** a new step `ledger-page` after main's push. **Gate:** `tests/test_ledger_page.sh` (two controls).
- **Waiting on the maintainer:** switch Pages on for `gh-pages` (Settings → Pages; the session account has no admin).
  The first publish is this close's.
- **Rewritten for its audience.** The maintainer: *"the audience was people interested in how the self-checking swarm
  performs … the ledger should be understandable"*; then **"yes to all of that"** for three additions.
  - **For a newcomer:** what the swarm is, how a check works, a glossary, every question's own text (read from the
    spec's checklists).
  - **Figures:** headline tiles, the trend per session, time to pass in hours (from each run's "prepared run"
    transcript result), and which questions fail together.
  - **Five worked examples** (`tests/rulecheck/catches.tsv`), quoted from their runs.
  - **Gates:** `test_ledger_page` (three controls); `test_session_metrics` (seventh control, `same-run-hours`).
- **#129 and the guard:** #129 parked (and kind `evolution`) as its GitHub labels say. `tools/tickets.py check` now
  compares `parked` with the GitHub label (control `parked-disagrees`); its first run found #129 and #267.
- **Hosting** (the maintainer: **"both is good"**; **"At the close"**; **"The close uploads it"**):
  - GitHub Pages from `gh-pages`, and alexrichard.org/vs-swarm-ledger/.
  - The page is now three files, so the site's strict policy serves it (`tools/ledger_csp_check.sh`: 0 refusals under
    it).
  - `publish_ledger.sh --own-site` rsyncs it there.
  - **The maintainer:** set `DEPLOY_TARGET` (and `DEPLOY_PORT`) in `~/.zshrc`, key-based ssh from the Mac, and switch
    Pages on after the first push.

### (6) BACK ON THE NETWORK — THE RE-TRACES; #336 FOUND AND FIXED
- **Seven static gates re-traced on PILOT** (tree `e1b87efa`, 64 control runs, SAFE, every run HONOURED):
  `test_claim_lint`, `test_emulator_runner`, `test_packet_check`, `test_rule_checker`, `test_session_metrics`,
  `test_tickets`, `test_tmp_hygiene`.
- **PILOT's pre-tier** (on `293c988d`) was NOT GREEN:
  - the expected generated indexes and tickets page;
  - `test_jtsim_scratch_heal`: the trace clone's `fx68k` submodule was never initialised (the clone trap);
  - **`test_static_runner`, section 32**, on unchanged code. It reproduced on today's tree.
- **#336, filed and fixed.** #327's premise check counted only bash's `write error: Broken pipe`. Ubuntu's `sh` is
  dash, which writes `printf: I/O error`, so the section FAILed on every Linux host since 14z-209.
  - The fix counts either wording, and the gate now passes on the Mac and on PILOT.
  - New platform gotcha: "A SHELL'S WRITE-ERROR TEXT IS ITS OWN".
  - Its row was re-traced on PILOT (tree `ad206269`).
  - **Closed done** (run 2026-10-29-1393 OK). Runs 1388, 1390 and 1391 stopped it on the evidence: the traced
    script's blob not shown, the PILOT clone not fresh, the gate's own `sh` not shown. Answered with
    `pilot_r6_blob.txt`, a fresh-clone run with its status recorded (`test_static_runner_pilot3.log`) and
    `pilot_sh_env.txt` (`/usr/bin/sh` -> dash in that run's environment).

### CLOSE (14z-212, 2026-10-30)
Driver `build/agent212/close/` (`--prev build/agent211/close/tier_results.tsv`). Before it, each ticket closed on GitHub
with its comment, on its own rule-checker run: #330 (`2026-10-29-1370`), #334 (`-1378`), #336 (`-1393`), #333
(`2026-10-30-1404`); #337 filed; `origin/main` fetched before staging (nothing new).
Steps: sections ((1)..(6)); next-session (the 14z-211 opener to `docs/NEXT_SESSION_HISTORY.md`); rollover (the 14z-211
group, 115 lines, to `STATE_HISTORY.md` with its ledger line); indexes (the archives', the ticket page, the gotchas index;
the GitHub snapshot refreshed, `tools/tickets.py check` PASS); dashboard (14z-163..14z-212, 2,969 figures, 0 unclassed;
datasets versions 21, 21, 22, 21 and the new `actions` 1) — done. The tier's results:
`build/agent212/close/tier_results.tsv`, the next close's `--prev`.
The first tier was NOT GREEN (165 PASS, 4 FAIL): the gate index, gate coverage and annotations pages not regenerated,
and `build/ledger_page/` (`tools/publish_ledger.sh`'s output) unclassed. Regenerated in a clean worktree of the staged
tree, `ledger_page` classed `scratch` in `tests/expected/build_dirs.tsv`, and the tier re-run on the red run's results.
The re-run read GREEN (169 PASS); committed `d6393610`; pins and sweep done; pushed `33f85438..d6393610`. **`ledger-page`
NOT PUBLISHED:** the page built, the own site SKIPPED (`DEPLOY_TARGET` unset), and the `gh-pages` push REFUSED by the
pre-push green guard (#290; the page's tree has no tier). The maintainer: "Fix the guard next session (Recommended)"
(`DECISIONS_HISTORY.md`, 14z-212). This paragraph and that entry were written after the push and ride the next close.

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
