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

## Session 14z-221b — **#358's beam difference re-read as position, not draw order (the 14z-221 reading RETRACTED): Phobos's ES Plasma Beam slides the victim on ours because vsavj's reaction-table rows 0x4E/0x4F are default rows; the maintainer ruled it mechanical, filed as #363 (bug) with #358 kept as its look; the measurements made rerunnable: `tests/audit_beam_slide.sh` (frozen on rule-checker run -1649), the `FIELDS_EXTRA` census knob on `audit_move_parity` and `tools/move_parity_p2x.py`, both write-traced on PILOT.** A continuation of 14z-221 after its close (`0ddac362`), on the same transcript (`218de16e`), Opus 5.5 at effort High.

### opened with

The maintainer's read of #358's beam pages (`build/agent221/t358/sheets/358_zoom_corner.png`, `358_beam_3row_p1.png`,
`_p2.png`, local), sent at 14z-221: **"RNG pin at 0000 provides the same results as native on page 2/3 but not on the other pages. No idea if
it's a rendering issue or different planes of render issue. cosmetic in all cases, but a potential gap"**.

### (1) #358 — POSITION, NOT DRAW ORDER; THE SLIDE

**The beam sheets read; it is position, not draw order (after 14z-221's close commit).** The
maintainer: **"RNG pin at 0000 provides the same results as native on page 2/3 but not on the other pages. No idea if
it's a rendering issue or different planes of render issue. cosmetic in all cases, but a potential gap"**. Measured
(`build/agent221/t358/od/`, `tests/lua/obj_records_dump.lua` at f2600/2720/2810 on the three sheet legs; the `rv/` taps):
- **Not draw order.** On all three legs Cecil's entries (palette 0x0D, 5-6 entries) come BEFORE Phobos's body (palette
  0x0A) in the live OBJ list, every entry with x-word priority 7 — the same order and priority on native and ours.
- **Cecil is moved on ours.** His slot x is 0x1F8 on native from 2560 to 2860; on ours it walks right from f2743 to 0x210
  (drive-in, by 2752) or from 0x1C5 to 0x20F (frozen, by 2772). That puts him under Phobos's legs, which the list draws
  over him on both games. Native and ours agree on the order; on native he simply stands clear of the legs. f2720's empty
  corner on ours is the camera: Cecil's OBJ x is 0x18 left of native's there, i.e. off screen.
- **The cause upstream: Demitri slides on ours.** P2 x on ours slides 0x2D8 → 0x329 on the ground at f2642-2654 (P2 y
  constant), where native's P2 does not move until the launch at 2665; the launch arcs then step identically, so P2 ends
  0x377 against native's 0x346. With P1 at 0x228 on both, (0x228+0x377)/2 − 0xC0 = 0x20F and (0x228+0x346)/2 − 0xC0 =
  0x1F7: Cecil's resting x on each leg is the left edge of a 384-px screen centred between the two (an arithmetic match;
  the camera word and the writer of Cecil's x are not read).
- ~~**Not measured:** why the beam's early hits slide vsavj's Demitri~~ — measured below. `audit_move_parity` compares
  the tenant's own state and P2's HP, not P2's x, which is why huitzil_4:0 reads IDENT.

**The maintainer, on the slide: "it needs further testing but this finding is indeed mechanical NOT cosmetic, thus of
greater severity".** Measured after it (`build/agent221/t358/push*/`, local, tap `lua/p2push_tap.lua`;
`p2x/`):
- **The cause: rows 0x4E and 0x4F of vsavj's reaction table are DEFAULT rows.** The beam's three hits (2640, 2645, 2654)
  give Demitri the same damage, the same pushback index `+0x59` = 2 and the same class `+0x54` = 0x4F on both games.
  The reaction table indexed by `+0x54` (vs2 `0x022388`, vsavj `0x02385C`, vhunt2 `0x0223B6`; engine_internals "Who uses
  class 0x51") sends 0x4F on vs2 and vh2 to a handler (vs2 `0x02296C`: sub 08, a hold in place — tapped writing it at
  2641) and on vsavj to its default row (`0x0238FC`, the code of vs2's default row `0x022430`), which runs the pushback
  slide (seq 02, the `+0x164` counter, x written by vsavj `0x027E22`/`0x0281FC`). Of the rows the three tables share,
  only 0x4E and 0x4F differ in kind: vs2 and vh2 give both a handler at the same offsets, vsavj the default.
- **Legacy content does not reach those rows** (`tools/audit_reaction_classes.py` on the pristine images,
  `build/agent221/t358/rclass.txt`): no reachable legacy record of either game carries class 0x4E or 0x4F (both in the
  "unused<50" lists), and no vsavj instruction writes either as an immediate to `+0x54`. Not covered by that tool: a
  `+0x54` written from a register (its header: the live census, `tests/audit_reaction_class_live.sh`, not run here).
- **The census of P2's position** (`p2x/`: `audit_move_parity` copied with P2 x/y added to FIELDS, `ALL=1`; it read
  PASS, all 526 events as frozen; `p2x_events.py` per event window): 24 of 526 events move Demitri differently. With
  the tenant's own x identical (p1max 0): huitzil_4:0 and :1 (the two ES Plasma Beams, +49 px each, from the slide) and
  pyron_1:26 (Rushing Punch, 8 px, back to 0 by the window's end). The other 21 are on events whose tenant x or state
  already differs (DIFF / NOT-IN-DF rows, or donovan_1's carried 8 px — the b:0x10 push-box confound named in
  `tools/move_parity.py`) and are not attributed.
- **Not measured:** which other tenant records carry 0x4E/0x4F (the tool walks legacy ids only); what row 0x4E's
  handler does; vs2's rows 0x50-0x53 beyond vsavj's 80 are the 14z-110 `reaction_hook` window, not these. Any fix
  (a vs2 handler for rows 0x4E/0x4F, Huitzil's row-16 precedent) is the maintainer's call ([VSP-10]).
- **The ticket: #363 (bug), filed after it.** The maintainer: **"Yes. Make the new bug related to #358. If Cecil looks
  are solved via the new bug then #358 could be closed".** #363 holds the slide; #358 stays open as its presentation
  side (comment posted on #358), to be re-captured once #363 is fixed.
- The maintainer's page-2 read is not what the pixels show: on f2720-2839 the frozen and drive-in rows differ by 0-59
  pixels a frame (both hide Cecil), so the RNG pin changes page 1's f2600-2660 (the entrance) and not page 2.

### (2) #363 — FILED, #358 KEPT AS ITS LOOK

The maintainer, to the proposal to file the slide as a new bug: **"Yes. Make the new bug related to #358. If Cecil looks
are solved via the new bug then #358 could be closed"**. Filed as #363 (`bug`, `needs-maintainer-ruling`: the fix is the
maintainer's call, [VSP-10]; no severity label, theirs to pick), its row in `docs/project/tickets.tsv`; a comment on #358
says it stays open as #363's presentation side, to be re-captured and closed if Cecil matches native once #363 is fixed.

### (3) THE MEASUREMENTS MADE RERUNNABLE ([VSP-18])

The maintainer, to the proposal to capture them before the session ends: **"I'd do it now if you have the time, since
it's the only way to keep [VSP-18]. -> do it. Also, PILOT should be ready for any other tasks"**.
- **`tests/audit_beam_slide.sh`** with tap `tests/lua/beam_slide_tap.lua` (emulator tier, MAME, 2 runs, ~4 s on the Mac):
  step 0 reads the three reaction tables' rows 0x00/0x4E/0x4F from the opcode images (the table is read through the
  opcode view: a data-view read gives junk targets); step 1 runs huitzil_4 f2560-3080 on native vs2 and ours; the checks
  require, in both beam windows, class 0x4F from f2640 / f2880 on both legs, native's P2 x constant with sub 08, ours'
  +81 px slide with seq 02 and a +49 px end offset, and the same P2 HP on the last frame before the part's own HP pin
  (its 2950 pin sits in the KK window: a compare after it is forced to agree, found by run -1647). FROZEN AS THE BUG STANDS: it goes red when #363 is fixed, and the
  fix re-freezes it. Controls `held` (ours' P2 x replaced by native's) and `class-cleared` (native's +0x54 zeroed),
  in-gate and as modes; each mode on a dead emulator reads UNJUDGED (`vs_ctl_nj`). On the Mac and on PILOT (scratch
  commit `090acd0d`, `refs/scratch/t363`): plain PASS, both modes HONOURED, both dead UNJUDGED, an undeclared mode
  REFUSED (`build/agent221/t358/rc/`, local).
- **The census:** `tests/audit_move_parity.sh` gains the probe knob `FIELDS_EXTRA` (more traced fields; refused under
  `FREEZE=1`), and `tools/move_parity_p2x.py` (the investigation's script, its docstring, usage and REPO line changed)
  reads P2's position per event from the kept traces. `ALL=1` with `FIELDS_EXTRA=ff8810:w:p2x,ff8814:w:p2y` PASSES, and
  the tool reproduces the investigation's 526-event table byte for byte (`build/agent221/t358/knob/`, local). Not frozen.
- **The capture of the slide** (`build/agent221/t358/sheets/slide/363_slide_p1.png`-`_p3.png`, local;
  `tools/naming_pair_sheet.sh`, native above ours): every frame f2638-2655 and the launch to f2799, sent to the maintainer
  before the freeze; the beam pages read at 14z-221 had no frame inside the slide, and the ruling came on the figure. Seen on
  it, not analysed: at f2649-2652 native draws a pale effect at the hit that ours does not.

- **Rule-checker:** the gate's freeze, `expectation`: run 2026-11-05-1645 withdrawn unspawned (the packet named no capture
  the maintainer read); -1646 VIOLATED on Q1 (PILOT showed six of the seven runs claimed; the `.fig` traces read as binary;
  the knob run's command, the census diff's files and the scratch commit's parent not shown), resolved by work (the
  dead-plain case run on PILOT, `.txt` copies, the runner script, the diff re-cut, the parent recorded); -1647 VIOLATED on
  Q1 (the packet's sheets not the three pages sent), Q2 (no capture inside the slide; the ruling came on the figure) and
  Q3 (the HP compare after the rig's HP pin), resolved by work (the gate's HP compare moved before the pin, re-run on the
  Mac and PILOT; the slide captured and sent; the sent pages put in the packet); -1648 VIOLATED on Q1 (PILOT's blob list unlabelled; its plain
  run not shown to be the fixed gate's), resolved by work (the blobs by path on both hosts, PILOT's plain log); -1649 OK.
- **PILOT:** both gates' controls write-traced at `6993aef7` (9 runs, 242 s, PILOT running nothing else): SAFE; `audit_beam_slide`
  re-traced after its fix at `090acd0d` and after its FOLLOWS line (`tools/name_moves.py`, asked by
  `test_gate_follows` in the clean-checkout bookkeeping run) at `4f53e4f0`, the staged close tree (2 runs, 8 s each): SAFE;
  `tests/controls_concurrent_emu.txt` rows for `audit_move_parity` (its blob changed) and `audit_beam_slide`.
- **Gotcha:** a reader took a `.fig` text file for binary (`docs/project/gotchas.md`).

### CLOSE (14z-221b, 2026-11-05)

Driver `build/agent221/close221b/` (`--prev build/agent221/close/tier_results.tsv`, 14z-221's GREEN close tier; `--row`
(3)). Riding this close: (1)-(3) above, the 14z-221 group rolled to `STATE_HISTORY.md` with its ledger line, the 14z-221
opener moved to `docs/NEXT_SESSION_HISTORY.md`, the new opener, rule-checker runs -1645 to -1649, the regenerated indexes.
On GitHub before the close: #363 filed; the comment on #358. Steps: sections (this group); next-session (the 14z-221 opener moved VERBATIM to the top of `docs/NEXT_SESSION_HISTORY.md`, 112 lines; `docs/NEXT_SESSION.md` rewritten); rollover (the 14z-221 group to `STATE_HISTORY.md` with its ledger line); indexes (by the driver); dashboard (14z-163..14z-221b, 3,604 figures, 0 unclassed; five assets uploaded, `datasets` re-pointed: actions v11, costly v31, figures v31, rc_runs v31, tiers v32). The tier's results: `build/agent221/close221b/tier_results.tsv`, the next close's `--prev`.

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
