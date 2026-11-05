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

## Session 14z-221 — **#361 and #362 closed done (rule-checker runs -1633 and -1640); #362's fix committed `d3e8810d` after a GREEN strict tier, its three gates re-traced SAFE on PILOT; #357 attributed and put to the maintainer (run -1637); #358's intro difference captured and a draw-order difference sent to the maintainer; #310 group 7 batch 1: 25 control modes read UNJUDGED on a dead leg, proven live on PILOT.**

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

### (2) #362 — FIXED, COMMITTED `d3e8810d`, CLOSED DONE

`tools/crash_sweep.py copy` pins a copy's `REPO=` line to `CS_REPO`, and `tests/test_crash_sweep.sh` writes its perturbed
copies under its scratch directory, never in `tests/`; `tests/test_gate_descriptions.sh`' `perturb` picks its target from
the copy and refuses an unchanged file (section 3 proves it). Reproduced with a planted `tests/.cs_aaa_plant.sh`: the old
modes exit 0 (LIES), the new ones FAIL. Re-traced on PILOT at scratch commit `bb407777`: 26 control runs of the three gates
at once, 3 SAFE; their rows back on `tests/controls_concurrent.txt` (the trace grep's positive control run once PILOT was
reachable again: the pre-fix copy step's `tests/.cs_*` write is named, the post-fix one's is not). Static tier on the staged tree: first run red on `test_tickets` only (#362's row
linked removed list lines), confirm GREEN, PASS 110. Rule-checker runs -1638 and -1639 VIOLATED (the tool's blob at the
traced commit not shown; the confirm's carry not stated), each resolved by work; -1640 OK; closed on GitHub.

### (3) #357 — ATTRIBUTED, PUT TO THE MAINTAINER

Donovan's round set-up (vs2 `0x05AE3C`, ours `0x0C104C`) creates a type-0x13 watcher in the `$FFD400` pool; vsavj's table row
0x13 for that pool is a bare `rts`, so on ours it never spawns the eight orbs. Measured on donovan_15 (taps
`build/agent221/t357/lua/`, local): the same watcher and trigger on both legs; at runtime, on the opcodes space, row 0x13
reads native `0x090EDA` / ours `0x080B44`, native stamps the orbs from `0x090FF4`, ours none. Fact homed in
`docs/game/engine_internals.md`. The recommendation (Huitzil's row-16 precedent, deadness first) through runs -1634/-1635
(withdrawn unspawned on wording), -1636 VIOLATED (no runtime proof; a cosmetic ruling misapplied — its words cover
out-of-combat items only), resolved by the runtime tap, -1637 OK; posted on #357, the maintainer's call.

### (4) #358 — THE INTRO DIFFERENCE CAPTURED

The figure's types are renumbered on ours (0x75/0x77 → 0x83/0x87). The legs part at the round intro: native Phobos drives in
on his car with the child (P1 x 0x168 → 0x228), ours stands at 0x228 from the first frame; the child ends at x 0x1C5 (sub
0x06) against native's 0x1F8 (sub 0x00). Sheet `build/agent221/t358/sheets/358_intro.png` sent to the maintainer, who read
it: **"Phobos has multiple intros. Off the top of my head 3 (the car, the one where the child is carried by Phobos, the one
where the child is standing between Phobos and their opponent as if trying to defend Phobos) so the captures do represent
two of these intros and both are different"**, and of the beams: **"As for the ES beams, I haven't check them in detail
yet"**.

**The census figure is the entrance draw; the capture shows a second difference it could not see.** The entrance is the
14z-168 fact (`tests/audit_entrance_draw.sh`): each game draws it from its own RNG state at char load. Where they part, on
huitzil_4 (read tap on `RAM:$FF80D4-D7` by CURPC, f2200-2370): both legs hold 4c02 to 2306; at 2307 native only reads
`$FF80D7` (vs2 `PRG:0x0079E2`, a side pick in match init) while ours calls the RNG routine once (vsavj `0x014E8A`, the same
routine as vs2 `0x01357E`); from the anchor both are pinned. With one RNG poke `2250:ff80d4:0000` ours draws the drive-in
too (P1 x 0x168 at 2363, the figure at 0x1F8 by 2599, equal to native) and its figure reads visible on 240 of 240 frames over
the [PP] event, against 177 of 240 without the poke: the 177/240 of #356's census is the entrance. But the capture of the
same event on three rows (native, ours as frozen, ours on the drive-in; `build/agent221/t358/sheets/358_beam_3row_p1.png`,
`_p2.png`, `358_zoom_corner.png`) shows that from the beam (f2660-2690) to f2839 native draws Cecil IN FRONT of Phobos's legs
and ours, on both rows, BEHIND them; before it (f2600) all three show him in front. The figure's slot (type, sub, state, x,
+0x18, the cull flag) is constant over 2560-2860 on both legs, so the change is on Phobos's side of the draw order — not
measured. Sent to the maintainer before any mechanism work; their read is pending.

### (5) #310 GROUP 7, BATCH 1 — 25 MODES MADE UNJUDGED ON A DEAD LEG

The maintainer: **"I'd welcome #310 group 7 before the close, or any other open ticket that is compatible with the ongoing
work"**. Batch 1 is the gates of the 14z-215 re-census's group 7 with one PRESENT mode
(`build/agent215/t310/census57/group7.tsv`, local): 31 candidates, run at `d3e8810d` with `MAME_BIN=/usr/bin/false`
(`build/agent221/t310g7/base/classes.tsv`, local): 25 HONOURED, 1 LIES, 4 DIED (a traceback: a crash is not a verdict), 1
REFUSED (a header-only mode). In the batch: the 24 HONOURED gates whose leg runs on MAME, plus `audit_dispatch_census`
(its drift-clock read LIES because its plain run PASSED on zero legs: it now requires every launched leg's output).
`test_dualtrack` (its leg runs on FBNeo; a dead MAME cannot kill it) and the DIED and REFUSED rows are left for later batches.

`tests/lib/controls.sh` gains `vs_ctl_nj <why>`: under a control mode (VS_CTL, or CONTROL for the gates that read it
themselves) it prints `NOT JUDGED: under control mode <mode>, <why>`, which `tests/lib/classify.sh` reads UNJUDGED; it is
silent in a plain run. Each gate calls it beside each liveness check, tagged `# #310 g7 NJ`; the seven gates that parsed
CONTROL themselves now source the library. Where a mode's close fired on any FAIL, it now fires only on the gate's own
finding (`audit_id_writers`, `audit_kill_poke_shape`, `audit_ladder_selector`, `audit_legacy_pairings`,
`audit_move_parity_attribution`, `audit_pass_overrun`). New gate `tests/test_dead_leg_unjudged.sh` with
`tests/expected/dead_leg_unjudged.tsv` (25 rows): every mode reads UNJUDGED with a dead emulator, every plain run is red and
silent, and each gate copied with its tagged lines NEUTERED reads HONOURED again (its `nj-stripped` control). Its
`plain-loud` control plants a helper that prints in a plain run, in section 1 and in every row's gate, and reports FIRED
only when that line shows (23 of 25 plain runs print it; `audit_dispatch_census` and `audit_id_writers` call the helper
only where a dead emulator does not reach in a plain run). Its first form fired on a CRASH of its own planted copy
(`CONTROL: unbound variable` under `set -u`), caught by rule-checker run 2026-11-05-1641; a copy with the old plant now
reads LIES. A fourth gotcha records it. The table frozen on rule-checker run 2026-11-05-1644 OK, after -1641 VIOLATED
(Q1: six candidates never baselined, unnamed; Q4: the crash), -1642 VIOLATED (Q1: two wordings the artifacts did not
back), each resolved by work, and -1643 withdrawn unspawned (a reason its one-line log does not show).
At the close the tier REFUSED at its `--confirm` plan, before any gate: 12,203 changed untracked paths, 12,163 of them
under `build/legacy_pairings/dead/`. `audit_legacy_pairings` keeps every dead leg's sandbox there (#233), and this sitting's
dead-emulator runs had left 78 such directories. The gate now runs its rows with `PAIRINGS_OUT` in its own scratch; the 78
directories (all this sitting's, 2026-11-04T22:38Z on) were removed. After the change the gate and both controls PASS and
FIRE again, and nothing new lands under `build/` (`build/agent221/t310g7/rc/post_close_fix/`, local). The frozen table is
unchanged. Its rule-checker run, -1644, read the gate before this line.

Measured on PILOT at scratch commit `aefcb1a7` (`refs/scratch/t310g7`; `build/agent221/t310g7/pilot_out/`, local): with a
live emulator 25 of 25 plain runs PASS and 28 of 28 modes read HONOURED, so the added lines do not fire on a real leg;
`test_dead_leg_unjudged` PASSES on Linux; `audit_move_parity_attribution` re-traced alone, 2 controls, SAFE, its row on
`tests/controls_concurrent_emu.txt` rewritten. The batch's gates and the library differ from `aefcb1a7` only by five
FOLLOWS lines naming `tests/lib/controls.sh` (`build/agent221/t310g7/scratch_vs_tree.diff`, local), the new gate by its
`plain-loud` fix (run on the Mac; it runs no emulator). Gotchas: a planted copy that crashes fires its control for the wrong reason; a stripped copy that deletes its
tagged lines deletes their commands; a verdict that counts only the legs that wrote output passes on zero legs; an
apostrophe inside `${VAR:?message}`; and the must-fire contract's dead-leg paragraph. Seen, not this batch's:
`audit_guard_corpus@known-crash` reads HONOURED on PILOT on a vec3 crash while its FIRED text names vec4 (predates the batch).

### CLOSE (14z-221, 2026-11-05)

Driver `build/agent221/close/` (`--prev build/agent221/tier362b_results.tsv`, the GREEN confirm run on #362's commit, the
most recent run of record; `--row` (5)). Committed before this close: `d3e8810d` (#362's fix and #361's closure). Riding this
close: #310 group 7 batch 1 (the 25 gates, `tests/lib/controls.sh`, `tests/test_dead_leg_unjudged.sh` and its table, the
emulator concurrent-list row), the records (STATE's 14z-221 group, 14z-220 rolled, the opener, four gotchas, the must-fire
contract paragraph, the regenerated indexes) and rule-checker runs -1634 to -1644. On GitHub before the close: #361 and #362
closed; the attribution on #357; the progress comment on #310. Steps: sections (this group); next-session (the 14z-220 opener moved VERBATIM to
the top of `docs/NEXT_SESSION_HISTORY.md`, 104 lines, 0 missing; `docs/NEXT_SESSION.md` rewritten: #310 batch 2, #357 and
#358 awaiting the maintainer); rollover (the 14z-220 group, 83 lines, to `STATE_HISTORY.md` below its HISTORY INDEX with its
ledger line; 0 lines missing); indexes (by the driver); dashboard (14z-163..14z-221, 3,583 figures, 0 unclassed; five assets
uploaded, `datasets` re-pointed: actions v10, costly v30, figures v30, rc_runs v30, tiers v31). The bookkeeping gates on the
working tree before staging: 13 PASS (`build/agent221/close/book/`, local). The first tier REFUSED at its plan (12,203 changed
untracked paths: the dead-leg gate's debris, (5)), no gate judged, so `--prev` stands; fixed, re-staged, re-run. The second tier: PASS 159, FAIL 3,
MISSING 1, all four the new gate's: it was not executable (MISSING, and `test_static_runner`'s registry check), its ROMDIR
demand sat after its EXIT trap (`test_demand_after_trap`), and its plain-loud refusal exited 3 with no REFUSED line on that
path (`test_dead_exit_census`). Fixed (mode 755, an explicit ROMDIR test, a REFUSED line); the three gates PASS on the
working tree and the new gate and its controls PASS and FIRE (`build/agent221/close/red/`,
`build/agent221/t310g7/rc/post_close_fix/`, local); re-staged and re-run on the red run's results. The third tier: PASS 162,
FAIL 1, the new gate, `controls RED: plain-loud(not fired)`. The runner reads every declared control's FIRED line from
the plain run (the 14z-198 gotcha, paid again), and `plain-loud` fired only under its mode. It now also runs in-gate in
every run: it builds the loud copies and FIRES only when section 1's plain case and some row's plain run print (23 of 25),
and a copy with the crashing plant reads CONTROL DEAD in both forms. The gate, both controls and eight header and
contract gates PASS on the working tree (`build/agent221/close/red3/`, `build/agent221/t310g7/rc/post_close_fix/`,
local); re-staged and re-run on the third run's results. The tier's results:
`build/agent221/close/tier_results.tsv`, the next close's `--prev`.

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
