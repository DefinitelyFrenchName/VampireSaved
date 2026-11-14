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

## Session 14z-227 — **the #310 family stops: its cost and the value of the 100 debt rows measured; #372 fixed and #370 finished by a simpler rule; #310, #369, #370 and #372 closed done (`e5bfe9dd`); #373 filed and fixed (the known-crash rig re-timed for the emulated clock, its gate migrated off the debt list).** Opus 5.5, transcript `006806e6` (compacted), 2026-11-13 to 2026-11-14.

### opened with
The maintainer: **"read handoff.md, state.md and docs/next_session.md"**; on the cost breakdown, **"do it"**; then **"I
think either we stop here or we go all the way. But first my bigger question is : how do we measure the value of
#310"** and **"measure first"**; on the three questions put after the measurement, **"didn't we say that most of the 100
were non-issues or weaker challenges anyway?"**, **"a ticket"** and **"we should at least look into them"**; on stopping,
**"agreed on both"**; on the finish line, **"yes, that's the best way forward"**; on the narrowed figures, **"Yes,
close on these (Recommended)"**; after seven rule-checker rounds, **"Resolve in writing, close (Recommended)"**; after
`e5bfe9dd`, **"Old scratch can be all erased"** and **"Do #373 then close"**. Working evidence: `build/agent227/` (local;
`cost310/`, `m310/`, `kc/`, `fin/`, `close/`, `bis/`, `rt/`, `kc373/`).

### (1) THE COST AND THE VALUE OF #310'S FAMILY, MEASURED
The cost (`build/agent227/cost310/`, local): #310, #364, #369, #370, #371 and #372 took 35.65 to 40.49 active hours of
210.14 over 22 session transcripts (two attribution rules), and 120.61 of 303.61 background machine hours. The value:
every declared mode of the 100 gates left on `tests/expected/ctl_caught_debt.tsv` read blind with hidden controls
(`build/agent227/m310/`, local); the figures are in `docs/project/must_fire_contract.md` § What the 100 cost to leave.
Ruled: stop (`DECISIONS_HISTORY.md` "Ruled 2026-11-13 (14z-227) — #369 and #310 close").

### (2) #373 FILED — THE KNOWN-CRASH CONTROL NO LONGER REPRODUCES ITS CRASH
The reading's one defect: `audit_guard_corpus`'s `known-crash` firing line claims the vec4 tripwire, and every kept run
since 2026-10-12 (ERIS, PILOT, the Mac at HEAD) crashes at vec3 PC 01afb6. Filed as #373, as ruled ("a ticket").
Resolved in (4).

### (3) THE FINISH LINE — #372 AND #370
As ruled (`DECISIONS_HISTORY.md` "Ruled 2026-11-13 (14z-227) — the family's finish line"): the emulator runner's run temp
moves out of the repo (#372), and in a pooled lane a gate naming a token of `tests/shares.tsv` runs after the pool, one
at a time (#370); `tests/test_emulator_runner.sh` sections 21 and 18f, controls `tmp-in-repo` and `token-serial-off`;
#370's write audit declined. #310, #369, #370 and #372 closed `done` with their comments. Rule-checker runs: #369/#310
2026-11-13-1790 to -1797 (-1791 withdrawn unspawned), each VIOLATED round a real narrowing of the claim (the batches'
controls, the 5 non-OWN items, the two log trees, #373's false OWN, the narrowed figures put back, the readers' blindness
checked), finished in writing at the maintainer's choice; #370/#372 2026-11-13-1799 OK (-1798 withdrawn unspawned).
PILOT: `test_mister_wide_inert` PASS with TMPDIR unset through the new runner (`build/agent227/fin/pilot/`);
`test_mister_gfxc_fetch` got past the refusal and was stopped without a verdict at 71 min by the run script's own
2 h bound (`timeout 7200`), the runner reaping its session and removing its run temp. Committed `e5bfe9dd` (strict
confirm tier GREEN, PASS 123, FAIL 0, 7 carried, `build/agent227/tier1/`); the hash posted on #370 and #372. PILOT's
old scratch directories (`~/od`, `~/r371*`, `~/m310*`, `~/f372`, about 10 G) deleted on the maintainer's word.

### (4) #373 FIXED — THE CRASH RIG RE-TIMED FOR THE EMULATED CLOCK, ITS GATE OFF THE DEBT LIST
On "Do #373 then close": bisected on the Mac to `ce64cb0e` (14z-197, `replay_guard.lua` on the emulated clock, #228):
its parent `4980bd96` and five other commits sampled back to `79dc2d03` (2026-09-22) give `CRASH 14767 vec4 PC 0fb6e0`, `ce64cb0e` gives
`CRASH 20100 vec3 PC 01afb6` (`build/agent227/bis/`, local). The rig was timed on the old clock's one-frame lead: at HEAD
under `INSTR_CLOCK=frame_done` it gives the tripwire, and on the emulated clock with its replay and picks moved 1 frame
earlier `CRASH 14765 vec4 PC 0fb6e0` (2: a vec3 at 9194; 3, 4: END clean; `build/agent227/rt/`, local).
`tests/audit_guard_corpus.sh` now builds that shift at run time, its mode is HONOURED only on the tripwire's own line,
and its plain run executes the rig (about 25 s) and fires only on that line, else CONTROL DEAD and FAIL; it left
`tests/expected/ctl_caught_debt.tsv` (99 rows) and its dead-leg row's stripped class is UNJUDGED-CAUGHT; the gotcha is in
`docs/platform/gotchas.md`. Evidence (`build/agent227/kc373/`, local): on the Mac the mode HONOURED, a plain run FIRED, a
shift-0 shadow UNJUDGED-CAUGHT and DEAD, a dead MAME UNJUDGED on the gate's own line, `test_dead_leg_unjudged` on the row
PASS; on PILOT the full plain soak PASS (388 of 388 legs clean, control FIRED) and the mode CAUGHT.
Rule-checker run 2026-11-14-1801 OK after 2026-11-14-1800 (VIOLATED on Q1: "every commit" back to 2026-09-22 where six
were run, the parentage, the `cmp` and PILOT's input hashes not in evidence; the wording narrowed, the evidence added).
#373 closed `done` with its comment (`build/agent227/close/c373.md`).

### CLOSE (14z-227, 2026-11-14)
Riding this close: (4) (#373's fix, its ticket row set to done, the debt list's and dead-leg table's rows, the gotcha,
the contract's note). Commits this sitting before the close: `e5bfe9dd`. Tickets closed: #310, #369, #370, #372 (in
`e5bfe9dd`'s work; the hash posted on #370 and #372) and #373 (its comment says the commit follows; it reaches GitHub
with this close's push); filed: #373. Steps: sections (this group); next-session (the 14z-226 opener, 126 lines, quoted,
to `docs/NEXT_SESSION_HISTORY.md`); rollover (the 14z-226 group to `STATE_HISTORY.md` with its ledger line); indexes (by
the driver); dashboard (14z-163..14z-227, 3,936 figures, 0 unclassed; five assets uploaded, `datasets` re-pointed:
actions v18, costly v38, figures v38, rc_runs v38, tiers v39). The tier confirms on
`build/agent227/tier1/tier_results.tsv` (`e5bfe9dd`'s GREEN tier). The tier's results:
`build/agent227/closerun/tier_results.tsv`, the next close's `--prev`.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **#364/#371 are fixed by design R, without the lint (2026-11-11, 14z-226):** the emulator runner reaps each gate's session (TERM, up to 10 s, KILL) and removes its per-gate TMPDIR; the 276 EXIT-only files are not patched — `DECISIONS_HISTORY.md` "Ruled 2026-11-11 (14z-226) — #364/#371: design R is built, without the lint".
- **#352: the desktop gate's `minimised` control is a release-time mode only, its in-gate form the drawn overlay (2026-11-10/11, 14z-225)** — `DECISIONS_HISTORY.md` "Ruled 2026-11-10 (14z-225) — #352: the PAUSE-reading gate change …" and "Ruled 2026-11-11 (14z-225) — #352 is finished as a matrix, then committed".
- **#369 lands with a shrink-only debt list and a lint with a stated limit (2026-11-08/09, 14z-224):** a mode is HONOURED only on its own `CONTROL CAUGHT:` line unless its gate is on `tests/expected/ctl_caught_debt.tsv`, which only shrinks — `DECISIONS_HISTORY.md` "Ruled 2026-11-08 (14z-224) — #369's design …" and "Ruled 2026-11-09 (14z-224) — #369's lint …"; the further limits the session named are accepted as stated limits (14z-225) — `DECISIONS_HISTORY.md` "Ruled 2026-11-09 (14z-225) — #369's lint: the further limits the session named stand"; batch 1's eight review CHECKs: items 1, 3 and 4 fixed (14z-226), the other five and ERE tightness in general stand as stated limits — `DECISIONS_HISTORY.md` "Ruled 2026-11-11 (14z-226) — #369 batch 1's session-named limits: items 1, 3 and 4 fixed, the rest stand".
- **#370 is built as A1, B1, C1 (2026-11-08, 14z-224):** today's sharing written down, every gate carries a `# SHARES:` line, a host-wide per-token lock — `DECISIONS_HISTORY.md` "Ruled 2026-11-08 (14z-224) — #370's design …"; the host lock is an OS file lock (`fcntl.flock`, `tests/lib/share_lock.py`), never a hand-written one (14z-225) — "Ruled 2026-11-09 (14z-225) — #370's host claim is an OS file lock …".
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
| effect-class row 19 (`0x080AF8`, #357, staged 14z-221c, FROZEN M26 14z-222) | vanilla never dispatches class 0x13 in the `$FFD400` pool | `tests/audit_effect_class_rows.sh` §1b, 0 reads over every frame of six replays vs §1's 3,872-hit row-37 control (14z-221c) | NOT safe-and-loud: a vanilla type-0x13 object would run Donovan's orb watcher (it reads a fighter through `+0x30` and can spawn eight effect pieces) — visible on screen, never silent |
| victim reaction row 0x4F (`0x0238FA`, #363, staged 14z-221c, FROZEN M26 14z-222) | vanilla never lands reaction class 0x4F | `tests/audit_effect_class_rows.sh` §1c, 0 reads on six replays vs a 21-read control on the table's rows 0x00-0x3F (14z-221c); static: no reachable legacy record carries 0x4F (`tests/test_reaction_classes.sh`) | a vanilla 0x4F hit would freeze the victim (vs2's reaction) instead of the default slide — a gameplay change, visible |
| dead span `0x029CBA-0x029CBF` (#363's jump, staged 14z-221c, FROZEN M26 14z-222) | nothing executes or reads the six bytes | `tests/test_dead_span.sh` (rules A, C, T, D, R, L: DEAD with three bases above the span accepted at their named sites, by reading: two word tables indexed after `andi.w #$3e`, a decode of data the descent never reaches) + `tests/audit_dead_span_exec.sh` (0 executions there and at the `bra.b` after it, 64-replay corpus) + `tests/test_dead_span_reach.sh` (on the built images) | an execution would jump into the freeze handler instead of setting `+0x3B5` = 4 — the reaction state corrupted, loud |
| dead span `0x024024-0x024029` (#294's jump, 14z-216; CORRECTED 14z-221c) | nothing executes or reads the six bytes | `tests/test_dead_span.sh` (DEAD with three references accepted at their named sites: rule D's byte table `0x023F84` read at `0x023F68` with the victim's unmasked `+0x56`, on its runtime bound; rule R's value `0x00024000` at `0x0433B8`/`0x077516` and rule T's row 0x8A of `0x02A646`, by reading) + `tests/audit_dead_span_exec.sh` (0 executions of the span AND of `0x023F68`, 64-replay corpus) + `tests/test_dead_span_reach.sh` | a `+0x56` >= 0xA0 at that read would take a jump opcode byte as an anim index — wrong pose, visible |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.
