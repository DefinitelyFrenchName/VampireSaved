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

## Session 14z-221 — **#361 closed done on rule-checker run -1633 (after -1632 VIOLATED, resolved by a mutant dry-run); its gotcha records the third payment.**

### opened with

**"read handoff.md, state.md and docs/next_session.md"**; the opener's sweep CLEAN; asked whether to start with #361's closure
check, the maintainer: **"yes."**

### (1) #361 — CLOSED DONE

The fix is in the M25 freeze commit `91bde83b`. Measured by measurer workers in clean worktrees (`build/agent221/t361/`,
local): the emulator runner's dry-run registry check reads 254 of 255 with `audit_crash_sweep_emu` a DEAD ROW at
`d19546c7`, 255 of 255 at `8bc62bf4`, and 254 of 255 again at `8bc62bf4` with only the new alternative removed;
`tests/test_emulator_runner.sh` PASSES on `8bc62bf4` and fails exactly its new crash-sweep case on that mutant. Rule-checker
run 2026-11-04-1632 VIOLATED (Q1, Q4: nothing tied the real row to the alternative alone; resolved by the mutant dry-run),
-1633 OK. Closing comment posted and the issue closed; the row `done`; the gotcha «A GATE THAT REACHES AN EMULATOR THROUGH
SOMETHING THE TIER CLASSIFIER DOES NOT NAME» now names #361 as its third payment (`docs/project/gotchas.md`).

## Session 14z-220 — **M25 FROZEN at `91bde83b` (#356, Donovan's dash speed lines, and #345 option A1b; tags donovan-m29, huitzil-m36, pyron-m30, merged-m25) after freeze rule-checker run -1631 OK and the static freeze tier on that tree (PASS 237, its one red confirmed GREEN); the S6 tier's five relocation-moved expectations re-frozen (run -1614); pass_overrun's re-freeze re-checked to OK (run -1629); #361 and #362 filed; the jtcores fork's M25 catalogue commit pushed.**

### opened with

**"read handoff.md, state.md and docs/next_session.md"**; told the next opener's first item was the M25 freeze and asked whether
PILOT and ERIS were up, the maintainer: **"all are up"**.

### (1) THE M25 FREEZE — COMMITTED `91bde83b`, TAGGED

The staged patch `build/manifest/staged/356_345a1b.patch` applied and removed; the mark M25; the six builds made on the Mac and,
independently from snapshot S0 `a252b89e`, on ERIS: program and whole-set key field-for-field equal on both (the zip containers
differ, member manifests equal; cause not measured). Registry rows donovan-m29 `20672b01` (program `63447128`), huitzil-m36
`815488af` and pyron-m30 `930ce568` (the mark only, programs unchanged), merged-m25 `add7bc1a` (program `a24aa560`); stock twin
and stage-4 unchanged. The four expectation sets frozen on the Mac and on ERIS at S1: 454 files equal. Every region placed after
M25's two new head regions (`x06e1d2` at `0x400010`, `x1d7428` at `0x4013E0`) moved `+0x1610`: the re-point sweep (m3b_merged33,
don_m29, hui63, pyron48, m5_stock24) and the relocation re-freezes, each through its own rule-checker run (-1607..-1612, OK at
-1612); A1b's accepted timing re-frozen (rng_forms -1601, the lag-budget exemption removed -1604, donovan_2's parity rows -1606,
pass_overrun -1629 — see (3)). The freeze battery on ERIS at S3 (PASS 183, SKIP 4 host-only); the 17 gates the freeze-cadence
staleness audit then named re-run at S7 (ERIS 14, the Mac's MiSTer lane 3, all PASS); the Linux desktop and clean-host rows on
PILOT at S6 (PASS; the provisional PILOT tag deleted after); the Mac's parity and the release rows. Both concurrent-controls lists
re-traced: static at S2 on PILOT (631 runs; test_gate_descriptions, test_crash_sweep, test_emulator_runner and the HOLLOW ones
kept off); emulator 45 rows at S3, S4 and S6 split between PILOT and ERIS. The MiSTer tail: fork commit `930818f5` (doc/mame.xml,
the CRC catalogue), patch 0041 mirrored, the pin moved; pushed to the fork at the close. release/merged-m25 packaged and identical
to a fresh package of build/m3b_merged33 (a control build differing). The classifier dead row fixed (`audit_crash_sweep_emu`,
#361). Static freeze tier on snapshot S8 `c48bcc87` = the commit's tree: PASS 237, FAIL 1 — `test_emulator_staleness`,
`test_don_sound`'s row stale on `docs/project/gotchas.md`, which the freeze's own gotcha moved after S7; `test_don_sound` re-run
at S8 through the runner (PASS), then `--strict --confirm` on the freeze run: GREEN, PASS 170. Freeze rule-checker run -1631 OK.
Tags `freeze/donovan-m29`, `freeze/huitzil-m36`, `freeze/pyron-m30`, `freeze/merged-m25` re-cut on `91bde83b` (the S1 scratch
tags replaced, never pushed). Evidence local under `build/agent220/m25/` (packet `rc/freeze/`).

### (2) THE S6 STATIC TIER'S FINDS — RE-FROZEN AND FIXED (run -1614)

The first freeze tier, on S6, read PASS 228, FAIL 10. Five static expectations read placed addresses and had not been re-frozen
(`latch_readers`, `df_field_readers`, `reaction_classes`, `escape_triage`, `donovan.md`): every changed line attributed, +0x1610
or a header, the build row, or the two new regions (`build/agent220/m25/rc/r_s6fix/attribution.txt`, its matcher with a
planted control). `test_jtcores_twin`: patch 0041 needed its `PATCH_NAMES` entry, and its mirror had been written with plain
`format-patch` (a signature trailer); regenerated `--no-signature`, as `tools/setup_jtcores.sh` does. `test_recurrence_alarm`:
Q1 3094 + 3098, cited in three packets of #345's timing, acknowledged under #345. Rule-checker run -1613 VIOLATED (the three
other reds' causes asserted without logs; the ruling the acknowledgement cites, unquoted), resolved, -1614 OK. The order lesson
is a gotcha (`docs/project/gotchas.md`, "A FREEZE'S STATIC EXPECTATIONS ARE NOT ONLY THE ONES THE BATTERY NAMES").

### (3) THE FREEZE'S RULE-CHECKER — RUNS -1615 TO -1631, AND WHAT THEY CAUGHT

The freeze check took runs -1615 to -1631 (-1615, -1616, -1617, -1620, -1626 and -1630 withdrawn unspawned on packet-check
flags or a wording slip; -1618, -1619, -1621 to -1625 and -1627 VIOLATED, each resolved; -1631 OK; -1628, withdrawn, and
-1629 are pass_overrun's re-check, below). Real defects it found, each
fixed in the tree or named untested in the claim: `build/agent220/m25/edit_classes.py` silently skipped the length-changing EDIT
ops (the relocated walker), rewritten as `edit_classes2.py` with an EDIT-count check and a dropped-op control; a fact measured
before the S6-tier fixes cited after them; the stock twin, stage-4 and the control build's program asserted, not measured;
"the .rbf is unchanged" asserted (the fork's change is doc/mame.xml only, measured); two counters of `test_mister_prg_window`'s
red not attributed (named). And a misattribution carried from run -1602's own resolve: it cited "the 14z-209 ruling" for closing a
Q1 finding in writing, but that ruling is scoped to #229's freezes, and 14z-163's option C covers Q3 and Q4; pass_overrun's
re-freeze was therefore re-checked afresh, run -1629 OK. Two slips of mine, both corrected in the records: twice a checker's
verdict ran its Q4 over several lines; once (run -1625) I joined the lines myself before recording, then had the checker restate
its own six lines and replaced `verdict_real.txt` with them (the resolve says so); and run -1631's claim says the final tier would
run with `--confirm` on S6's results — the runner refuses `--confirm` at freeze cadence, so it ran in full, stricter than stated.

### (4) TICKETS AND COMMENTS

Filed #361 (the classifier missed `audit_crash_sweep_emu`'s emulator call; fixed in `91bde83b`, open until its closure check)
and #362 (`test_crash_sweep` writes its perturbed copies into the live `tests/`; `test_gate_descriptions`' modes do not refuse a
vanished target). Comments posted on #345, #346 and #356: done, awaiting release (`91bde83b`, its gates, closes with the release
that ships M25).

### CLOSE (14z-220, 2026-11-04)

Driver `build/agent220/close/` (`--prev build/agent220/m25/static_confirm_results_s8.tsv`, the freeze's confirm run on S8 —
the most recent run of record, on the freeze commit's own tree; `--row -`). Committed before this close: the freeze `91bde83b`
(tags re-cut on it). Riding this close: STATE's 14z-220 group (14z-219 rolled), the opener, the ticket rows for #361 and #362,
the regenerated indexes; the jtcores fork commit `930818f5` pushed to `DefinitelyFrenchName/jtcores` before the pins check
(`8d527341..930818f5`). Steps: sections (this group); next-session (the 14z-219 opener moved VERBATIM to the top of
`docs/NEXT_SESSION_HISTORY.md`, 0 lines missing; `docs/NEXT_SESSION.md` rewritten: #361's closure check first); rollover (the
14z-219 group, 77 lines, to `STATE_HISTORY.md` below its HISTORY INDEX with its ledger line; 0 lines missing); indexes (by the
driver); dashboard (14z-163..14z-220, 3,529 figures, 0 unclassed; five assets uploaded, `datasets` re-pointed: actions v9,
costly v29, figures v29, rc_runs v29, tiers v30). On GitHub before the close: #361 and #362 filed; done-awaiting-release
comments on #345, #346, #356. The tier's results: `build/agent220/close/tier_results.tsv`, the next close's `--prev`.
After the commit (these lines ride the next close): the tier on the staged tree, strict, `--jobs 8`, `--confirm` on the S8
confirm run: GREEN, PASS 109, FAIL 0 (74 carried); committed `8bc62bf4` (the green guard read that row); nothing new on
`origin` at the fetch; pins OK; sweep CLEAN; pushed `d19546c7..8bc62bf4`, origin/main equal to HEAD, and the four freeze tags
(`freeze/donovan-m29`, `huitzil-m36`, `pyron-m30`, `merged-m25` -> `91bde83b`); ledger page published on `gh-pages`
(`ab09c137` -> `d2a53258`, 358 sessions); the maintainer's own site SKIPPED, `DEPLOY_TARGET` not set
(`build/agent220/close/ledger.out`). Every step of the close is done.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **#356 is built as Option 1 (a tenant-only copy of the speed-line effect with vs2's 14-row tables), with the raw allocator, and frozen as M25 as built (frozen 14z-220, `91bde83b`); its one-frame Dark Force phase is accepted and is #360 (2026-11-02 and 2026-11-03, 14z-218/219)** — `DECISIONS_HISTORY.md` "Ruled 2026-11-02 (14z-218) — #356" and "Ruled 2026-11-03 (14z-219) — #356".
- **#345's option A1b is built and its timing ACCEPTED: frozen in M25 with #356 (14z-220, `91bde83b`) — ours loses no logic frame in Blizzard Sword where native does; the moved expectations (pass_overrun, the stale lag exemption, donovan_2's parity and RNG-form rows) re-frozen at the freeze, each through its own rule-checker run; vsavj's table PRG:0x1F3FD2 is never touched; B stays held (2026-11-02 and 2026-11-03, 14z-218/219)** — `DECISIONS_HISTORY.md` "Ruled 2026-11-02 (14z-218) — #345", "Ruled 2026-11-03 (14z-219) — #345: option A is built as A1b" and "… the built A1b's timing is accepted".
- **#345's rows may turn DIFF under a non-zero RNG; the parity gates keep the 0000 pin (2026-11-01, 14z-216):** `tools/rng_forms.py` exempts rows `after:` a SLOWDOWN root, by name — `DECISIONS_HISTORY.md` "Ruled 2026-11-01 (14z-216) — #345's rows under a non-zero RNG".
- **A new zero-pass frame native vs2 has too is accepted, frame by frame (2026-11-01, 14z-216, #294):** `audit_lag_budget`'s ACCEPTED list (empty since the M25 freeze, 14z-220: A1b took the frame donovan_2:3094 away and the stale entry was removed, run 2026-11-04-1604; an entry is checked against `pass_overrun.tsv`'s native row), re-confirmed on the captures as *"a tradeoff. #345 is there to fix it later"*; the no-new-lag rule stands for every other frame — `DECISIONS_HISTORY.md` "Ruled 2026-11-01 (14z-216) — #294's lag frame" and "…re-confirmed on the captures".
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
