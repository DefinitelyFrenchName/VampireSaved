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
  about 120 characters. The findings table is the section `### (N) THE FINDINGS TABLE`, naming
  `docs/project/findings/<key>.tsv`, which `tools/findings_add.py` appends to (`--create` the first time) and
  `tools/findings_table.py` reads. Groups archived before 14z-201 keep their one-line table rows.
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

## Session 14z-201 — **#282 filed and ordered; #269 measured and closed; #282 items E, A, B, F, C and D built, #282 closed; the root README's scale re-measured, the recording procedure ruled into the package README (#284).** A plain Opus 5.5 session on the #172 setup (transcript `979461fd`).

### opened with
the maintainer: *"read handoff.md, state.md and docs/next_session.md"*; `python3 tools/agent/sweep.py` CLEAN; `main`
even with `origin/main` after a fetch.

### (1) #282 FILED, ITS SCOPE AND ORDER RULED
The maintainer's ticket on the size of CLAUDE.md, STATE.md, HANDOFF.md and the close ritual, filed as #282 from a
`measurer` census. Scope ruled: budgets of ideally 200 lines, at most 500, on the four live documents, bytes or width
capped too; STATE.md keeps only the latest session in full; the archives get an index, not a budget
(`DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-201) — #282's scope"). Order ruled E, A, B, F, C, D ("— #282's order of
work").

### (2) #269 MEASURED AND CLOSED `done`
The last clause of its done-when, the miss rate on the new selection: the 14z-200 close tiers' carried gates traced on
PILOT and checked for any read of a changed file — 0 of 56 and 0 of 80 — through five readers, each added after a
rule-checker run found a read form the last one dropped (runs 2026-10-14-1073 to -1081, each resolved by work; 1072,
1074, 1076, 1078 and 1080 withdrawn unspawned; **1082 OK**). Report `build/agent201/t269/report.md`
(local). The maintainer: *"Close done (Recommended)"*. The trace tool's split-line defect filed as #283, its other gaps
added there; gotcha "A STRACE TRACE SCORED BY OPENED PATH MISSES FIVE READ FORMS".

### (3) #282 ITEM E BUILT
Every archive opens with a generated, line-exact index: `tools/gen_history_index.py`, gate `tests/test_history_index.sh`
(three controls), `dfbf47bf`.

### (4) #282 ITEM A BUILT
Ruled *"At most 2"*, *"Now, as part of A"*, *"Defer to item C"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-14 (14z-201) —
#282 item A"): `tools/check_state_lists.py` allows two session groups; [VSP-17] and the port skill's copy amended;
14z-198 and 14z-199 rolled verbatim to STATE_HISTORY; the standing rulings cut to rule plus pointer (a `reader` found 4
drifts, restored). STATE.md 91,033 -> 39,554 bytes (112,327 at the opener). `2f962b42`.

### (5) #282 ITEM B BUILT
The maintainer, on the split plan: *"yes this looks right"*. HANDOFF.md 1,811 -> 484 lines, 216,718 -> 46,130 bytes: its detail moved VERBATIM to the new
`docs/project/operations.md`, `cps2_wide.md`, `release_format.md`, `mister_core.md` and `HANDOFF_HISTORY.md`, each moved
heading leaving a stub; 12 ticket anchors re-pointed, the anchor census refrozen on the moved anchors only. `1da23b43`,
`1c000561`.

### (6) #282 ITEM F BUILT
Ruled *"50kB sounds like a good targer"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item F"):
`tools/check_live_budget.py` holds the one copy of the budget (500 lines, 50,000 bytes, WARN above 200 lines); gate
`tests/test_live_budget.sh` (ci_portable; controls over-lines, long-lines, missing-document); `check_state_lists.py`
takes STATE's cap from it (150 KiB -> 50,000 bytes).

### (7) #282 ITEM C BUILT: THE CLOSE IS ONE TABLE, ITS DRIVER, AND THE FINDINGS TSV
A `reader` census at `de82c957` found the close ritual in 58 places across 30 files, none of them the whole procedure,
8 sets disagreeing. Ruled *"Doc + driver (Recommended)"* and *"Sections, findings TSV (Recommended)"*
(`DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201) — #282 item C"). `docs/project/session_close.md` holds the close as
one 20-step table, the 8 disagreements settled there from the rulings, and STATE's four close paragraphs moved there;
`tools/close.py` reads that table and runs it (`start`, `next`, `done`, `status`), gate `tests/test_session_close.sh`
(four controls). Every live place that restated the close now points to it, CLAUDE.md [VSP-17]'s rollover sentence
among them. The findings table became `docs/project/findings/<key>.tsv`, read through `tools/findings_table.py` by
every close tool; this group's rows became these sections. A driver trial on `build/agent201/close_trial` (local)
ran `indexes` and `live-docs` green and stopped RED at `inputs`, naming the four close-time files; it found that a
step calling the driver again could not find a run directory outside the default, fixed by `CLOSE_RUN`.
`a47e7fe4` (the TSV part).

### (8) #282 ITEM D LANDED: CLAUDE.MD AS RULE PLUS POINTER
Ruled *"Rule + pointer (Recommended)"* and *"Draft first (Recommended)"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-15
(14z-201) — #282 item D"). The draft, built by `build/agent201/t282/claude_draft.py` (local), was compared clause by
clause by two `reader`s (10 of 13 drifted in the first, 3 wording changes in the second, all restored) and approved by
the maintainer: *"the CLAUDE.md draft looks good."* CLAUDE.md 448 -> 244 lines, 30,203 -> 18,557 bytes; every
`**[VSP-N]**` stays in it with its rule, the long paragraphs moving verbatim to `docs/project/oracle_classes.md`
(VSP-24/25/26/31/32), the new `docs/project/working_methods.md` (VSP-20/13/14, the runner) and
`docs/project/session_records.md` (VSP-17/182/162), and `docs/README.md` (VSP-12, the condensing history). Four ticket
links re-pointed in `docs/project/tickets.tsv`. 17 doc gates pass on the tree.

### (9) THE ROOT README: THE MAINTAINER'S EDITS MERGED, THE SCALE RE-MEASURED
The maintainer edited `README.md` on GitHub (12 commits, merged, never rebased). The edit removed the
`apply_release.py --out ./rompath` build step, which `tests/test_readme_recording.sh` read to check the "Report a
problem" command's rompath; the maintainer: *"this had no business being there as it should be in the delverables
README.md, which it is"*. The gate now reads that `--out` from the package README's source, `tools/package_release.py`
(PASS on macos-arm64, both controls fired). At the maintainer's ask (*"I'd welcome update numbers for this
paragraph"*), "The scale" was re-measured by `measurer`s on the 14z-183b definitions, calibrated at `22c56655`
(all seven 2026-09-26 figures reproduced) and read at `edd1b323`: 461 test scripts, 225 emulator-free checks (133
portable + 92 static), 394 controls executed at the 14z-200 close, 231 emulator/FPGA checks, 233 replays, 10
recordings, 283 tickets. Only the paragraph's date and numbers changed; the maintainer's text is untouched.
The maintainer then corrected the README on GitHub and trimmed the paragraph (no tickets or cadence clause); the
merge conflicted on it and kept their version whole (`9e65edea`). It read 203 emulator/FPGA checks where the
measurement at `edd1b323` gave 231; raised with the maintainer, whose next commits (*"more corrections done, can you
recheck"*) made it 231. As merged at `1989d119` (`README.md:117-119`) it carries 461, 225, 394, 231, 233 and 10, each
equal to the `edd1b323` measurement (`build/agent201/readme_scale_figs.txt`, local), compared by hand at the close.

### (10) THE RECORDING PROCEDURE MOVES TO THE PACKAGE README (#284)
On ERIS, with the published m23 Windows MAME package, the root README's recording command failed in cmd and PowerShell
(`cps2.exe` is under `emulator\bin\windows-x86_64\`; `<…>` placeholders are redirections); by its path, with
`-rompath rompath` alone, it records (exit 0); the MAME applier needs `qsound_hle.zip`, which the root README omits.
The maintainer: *"I think we should put the "how to report a problem" details into the README.md of the release
zips"*, then *"I'll trim it, add the instructions needs to #284"* (`DECISIONS_HISTORY.md` "Ruled 2026-10-15 (14z-201)
— the recording procedure moves to the release package README"). #284 got its index row and the requirements. On the root README's dump list, the maintainer: *"qsound is needed for
evertything but MiSTer, but might as well set it as necessary as you can decide in the applier to apply it or not."*
The maintainer trimmed the root README (merged); `test_readme_recording` (release cadence) now fails: the command it reads
is gone; the ruling's So line makes its move to the package README #284's work, and its header says so; the reach control 4 of `tests/rulecheck/retractions/14z-181.tsv` was re-pointed to the
reworded opening sentence ("what ifs are tantalizing"), `test_retraction_reach` PASS.

### (11) THE FINDINGS TABLE
`docs/project/findings/14z-201.tsv` — every finding, its live home, the test that reproduces it (checklist step 1).

### (12) CLOSE (14z-201, 2026-10-15)
The maintainer: *"then let's close. That'll also be a good moment to see how much time it takes."* The first close run
by the step table and its driver (`docs/project/session_close.md`, `tools/close.py`; run dir `build/agent201/close`,
local), started 15:21:53. Step by step:
- **findings:** (a)-(t) in `docs/project/findings/14z-201.tsv`; (p)-(t) paid during the close itself, two of them
  defects in the close's own tools — the claim tool dropped a premise starting `#282` (s), the scratch census never
  counted `.bat`/`.ps1` (t); both fixed with self-test cases that fail on the old code.
- **sections / next-session / rollover:** this section opened; 14z-200's #269 section points here; the 14z-200 opener
  moved verbatim to `docs/NEXT_SESSION_HISTORY.md`, `docs/NEXT_SESSION.md` rewritten; the 14z-200 group (11 lines)
  moved verbatim to `STATE_HISTORY.md` with its ledger line. #282 closed `done` (*"Close it done (Recommended)"*).
- **inputs / render / checks:** 21 then 25 scratch programs classed, 1 promise carried by #284, 11 maintainer messages
  exempted with reasons, `tests/rulecheck/retractions/14z-201.tsv` (2 reach controls, 1 gone); 38 checks, the last
  full run every exit as expected.
- **packet:** runs 2026-10-15-1083 to -1085 withdrawn unspawned (a premise lost to (s); a claim prepared beside a red
  check; a stale subject); 1086, 1087 and 1088 VIOLATED on the real packet, every fixture caught, each resolved by work:
  the stale README "203" sentence, unnamed gaps (the README figures, the GitHub comment bodies — fetched back, each
  equal to its draft, `build/agent201/close/gh_posted.txt`, local — and #276's undercount), the census (t), and two
  attributions without the maintainer's words. `resolve --recheck` was refused once because the run directory was
  passed relative while the render holds it absolute; that resolution is in writing.
- **commit:** `6544c713`. **tier:** strict `--confirm` on a snapshot of `6544c713`: PASS 206 SKIP 1 FAIL 0, controls
  404 of 404, wall 2,371 s; the SKIP `test_release_launcher_bat` PASS on ERIS at `6544c713` (its first-found mode exits
  1), `build/agent201/bat/bat201.log` (local). **sweep:** CLEAN.
- **procedure (C1):** the extract in five parts, runs 2026-10-15-1089 to -1093, every fixture caught; 1090 and 1093 OK.
  Confirmed against the extract (`build/agent201/c1/findings.md`, local) and resolved: the agent filed #282 without the
  maintainer's go after promising to wait for it (1089); reported item B "every doc gate is green" after edits no gate
  re-ran (1091, as finding (j)); told the maintainer HANDOFF went from "1,811 lines and 216,324 bytes" — the pair is
  1,811 lines and 216,718 bytes (1091); said "Every gate these changes touch passes" while `test_close_tools` was red
  (1092, as finding (k)). Workers: the census reader ran grep patterns its spec did not name (1091); a measurer ran on
  past a failed command against its STOP rule (1092); a rule-checker could not read the 878 KB ledger in full (#258).
  The saved copy of one reader's answer first dropped its last sentence; corrected to the reader's text.
- **cap:** 0 breaches over 46 workers, no fallback. **dashboard:** 14z-163..14z-201 re-collected (1,621 figures, each
  classed) and uploaded (`datasets/*`: figures, rc_runs and costly version 5, tiers 6); tier runs on a snapshot are
  still uncounted (#276).
- **Not mine, named:** two scratch worktrees from 14z-200 (`wt274`, `wt_bench` under its scratchpad) remain.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

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
