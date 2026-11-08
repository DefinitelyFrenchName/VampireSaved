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

## Session 14z-223 — **#365, #366, #367 and #368 closed done; #310 group 7 batches 3-5 (166 dead-leg rows) and the Linux-only gates' 5 rows on a new release-cadence gate on PILOT, with the desktop driver's leak fixed and one harness at a time on the desktop session; the group-7 re-census found an untaken census list, and the maintainer, after a post-mortem of #310's patch-by-patch route, ruled its replacement: #369 (honoured only on positive evidence) and #370 (declared shares) filed, batch 6 dropped, #310 to close with #369.** Opus 5.5, transcript `aef5e221` (compacted).

### opened with
The maintainer: **"read handoff.md, state.md and docs/next_session.md"**, then **"I agree with the order for items 1,2,3 then
let's focus on bugs and test integrity"**. Working evidence: `build/agent223/` (local; #365/#366 in `t366/`).

### (1) #366 AND #365 — TWO STALE HEADERS, A MISSING SHEET LINE, AND A BLIND CONTROL
- **#366:** `tests/test_dead_span_reach.sh`'s header now states both frozen spans and judged-pairs 10;
  `tests/audit_pass_overrun.sh`'s says ours has no overrun since M25, as `tests/expected/pass_overrun.tsv` holds (the claim
  grepped out of `tests/ci_emulator.tsv`, `docs/game/engine_internals.md`, `docs/project/sheet_notes.md`).
- **The issue's open question, controls on every span: yes, measured.** Run by hand on #363's span, 21 of the 22 plants
  fired; fall-through did not, because it nopped the 4 bytes before the span and #363's fence is a 6-byte `jmp.l` at
  `PRG:0x029CB4`. `tools/audit_dead_span.py --plant fallthrough` now overwrites every reached instruction ending at the span
  start, whole; the gate plants every control on every span (modes on the first). PASS, 22 of 22 FIRED on both spans; wall
  18:42, against 10:31. Gotcha in `docs/project/gotchas.md`.
- **#365:** `tests/audit_crash_sweep_emu.sh` declares `# SHEET: none — …`; `tests/test_sheet_census.sh` PASS, 0 on the
  debt list.

### (2) THE CONCURRENT-CONTROLS ROWS — PILOT at scratch `3d90dfaa`
`test_dead_span_reach` (static list, its script changed) 22 HONOURED SAFE; `test_release_binaries` (emulator list, off since
its 14z-222 header correction) 4 HONOURED SAFE and listed again. PILOT's local provisional tag `freeze/merged-m26`
(`564775cf`) deleted and origin's tags fetched; PILOT is left detached at `3d90dfaa`.

### (3) #310 GROUP 7 BATCH 3 — 48 ROWS OVER 7 GATES; #367 FILED
- The seven group-7 MAME gates with two or more modes off the concurrent lists (`audit_ladder_pick_store`,
  `audit_marionette_cost`, the three `audit_mizuumi_*`, `audit_tick_cadence`, `test_proof_sheets`): all 48 modes read
  HONOURED on a dead emulator at `c5fe01b4`; each liveness exit now calls `vs_ctl_nj` (`# #310 g7 NJ`), and all 48 read
  UNJUDGED; live, all seven PASS plainly and all 48 modes read HONOURED. `tests/expected/dead_leg_unjudged.tsv` 91 rows,
  `tests/test_dead_leg_unjudged.sh` PASS. One defect of my own, found by a reader and fixed: `audit_tick_cadence`'s tagged
  binary check ran before `controls.sh` was sourced (moved; run dead with a missing binary, UNJUDGED).
- **#367 filed:** `tests/lib/classify.sh` reads a `set -e` gate that dies on a tool error as HONOURED
  (`audit_marionette_cost`'s pre-fix exit 2 after `awk: can't open file`; batch 3 fixed that gate's path).
- Rule-checker run -1718 OK after -1714 to -1717 (-1713 withdrawn unspawned); the progress comment posted on #310.
  Left of group 7 (the 14z-215 census, which predates later modes): 31 concurrent-list gates (121 rows), podman's 2 rows,
  the six held out. *[Continued: (4), (6).]*

### (4) #367 — THE CLASSIFIER'S TOOL-ERROR RULE; #310 GROUP 7 BATCH 4 — 112 ROWS OVER 29 GATES; #368 FILED
The maintainer: **"continue with both #367 and the next batches of #310 unless there's a blocker. PILOT and ERIS are
available to be put to good use"**.
- **#367:** `tests/lib/classify.sh` reads DIED a mode whose log ends on a tool's error lines with no gate FAIL just before
  them and no `NOT JUDGED:` line; `tests/test_emulator_runner.sh` section 14o and its `tool-honoured` control; the replay
  over 1,382 kept honoured mode logs changes no verdict. Its first form misread two dead-run shapes (`test_hui_air`), found
  by the dead-leg gate and fixed (gotcha in `docs/project/gotchas.md`). `test_emulator_runner` re-traced SAFE on PILOT.
- **Batch 4:** the 30 group-7 gates on the emulator concurrent list; two workers tagged disjoint halves, one combined dead
  run checked them (113 UNJUDGED, 8 correctly HONOURED: evidence a dead MAME_BIN does not remove). 112 rows, the table at
  203, `tests/test_dead_leg_unjudged.sh` PASS. Live on ERIS (28 gates) and the Mac (`test_readme_recording`): every plain run
  PASSes, every mode HONOURED but one. Concurrent controls re-traced at scratch `1ecdcc22`: PILOT 15 SAFE, ERIS 13 SAFE.
- **#368 filed:** `audit_flicker_attribution`'s `shared-sandbox` control has fired on a dead leg in every kept release tier,
  never on the frozen-basis check it names; now UNJUDGED live, the gate HOLLOW and off the emulator concurrent list.
- **Two reds on the confirm tier, both mine, fixed:** the eleven gates that gained the `controls.sh` source line did not
  declare it in `# FOLLOWS:` (`test_gate_follows`), and `tests/test_plants_not_applied.sh`'s hand-built copy of
  `audit_latch_reads` lacked the file, so its `latch-fix-reverted` control went DEAD. Both gates PASS after the fix; the
  twelve changed scripts re-traced at scratch `f329dc8d`, all SAFE and every control HONOURED (PILOT five plus
  `test_plants_not_applied`, ERIS six), rows re-pointed. Gotcha
  appended in `docs/project/gotchas.md`. *[#368 resolved: (6).]*

### (5) #310 — WHAT IS LEFT, RULED BY THE MAINTAINER
Asked where the two Linux-only gates' dead-leg rows should run (`audit_release_linux_cleanhost`, 2 modes;
`audit_release_linux_desktop`, 3 modes; both SKIP off Linux before any instrument), with options A (a release-cadence
emulator gate judging them on PILOT at release, as `audit_crash_sweep_emu` carries the crash sweep's Linux row), B (a host
column the Mac's static tier skips), C (the static gate over SSH to PILOT) and D (a faked host), the maintainer: **"A. A
small release-cadence emulator gate that judges the 5 rows on PILOT at release (my recommendation). … -> agreed."** On #368:
**"do it when you can"**. On re-censusing group 7 at HEAD (the 14z-215 census predates later modes): **"do it before
closing #310 then, so after all the other #310 tasks"**. The order: batch 5, the release-cadence Linux gate, #368, the
re-census, then #310's closure (or a batch 6 first). *[Continued: (6)-(9).]*

### (6) #310 GROUP 7 BATCH 5 — THE SIX HELD OUT, 6 ROWS; #368 DONE
- **The dead-leg gate kills any instrument:** a row's dead instrument is any `<NAME>_BIN`, or `PATH:<tool>` (a stub first on
  `PATH` that exits 1); `PATH:` rows run one at a time (the MiSTer legs share one scratch clone). Wall 25:03 on 209 rows (re-run on the staged tree, every row gate's blob recorded
  against the index before and after).
- **The six:** `test_mister_obj_oracle`, `test_mister_prg_window`, `test_mister_tenant_oracle` (dead `PATH:verilator`, read
  HONOURED); `test_mister_sdram_census` (read LIES: its readout printed `CONTROL DEAD` on a leg A that never ran, and its
  C-vs-D cross-check read two missing legs as "differ"); `audit_stock_emulator_stall` (DIED on a Traceback; now checks each
  leg's END line); `test_release_roundtrip`'s `encoder-check-removed` (dead `PATH:python3`: a copy that crashed before the
  check "did not refuse"; the planted copy now prints a line where the check was). All six UNJUDGED after the fix, neutered
  copies HONOURED; `tests/test_dead_leg_unjudged.sh` PASS. Live plain PASS: on the Mac the stall, roundtrip and sdram (their
  changed modes HONOURED), on PILOT obj_oracle and tenant_oracle (read back over SSH, not fetched: PILOT went unreachable), and prg_window on
  the Mac in 3,358 s after PILOT dropped mid-run.
- **#368 done:** the `shared-sandbox` control was written in 14z-205; #296's guard (14z-206) refuses an undeclared sandbox
  reuse, so from then on the mode's f5868 legs never ran and the mode "fired" on the run's general red. The mode now declares
  the reuse (`MAME_SANDBOX_REUSE=1`), fires only on the frozen-basis check naming the case, and reads NOT JUDGED on a dead
  leg. On ERIS at scratch `7150f4c3`: plain PASS, `shared-sandbox` fired on 105 f5868 (HONOURED), `wrong-window` HONOURED,
  the write-trace SAFE; the gate is back on `tests/controls_concurrent_emu.txt`. Gotcha in `docs/project/gotchas.md`.
- **Off the static concurrent list:** `test_release_roundtrip` (its script changed; PILOT, the only host with xdelta3 and
  strace, was unreachable), by an OFF line in `tests/controls_concurrent.txt`; it goes back after a trace on PILOT.
- **Checked:** where each of the six legs dies with only its named instrument dead (each reached it; the mode's NOT JUDGED
  line names that leg), and roundtrip's plain run plus all 10 modes at the new blob (PASS, all HONOURED); #368 closed done
  and #310 commented on rule-checker run 2026-11-08-1724 OK after -1721 to -1723 (the gaps they found were evidence: blobs
  unrecorded, the sdram mode's output, where a leg died, roundtrip's other modes). *[Roundtrip re-listed: (7).]*

### (7) #310 GROUP 7 — THE LINUX GATE (5 ROWS ON PILOT AT RELEASE); A DRIVER THAT LEAKED INTO THE DESKTOP
- **`tests/audit_dead_leg_linux.sh`**, as ruled in (5): `tests/test_dead_leg_unjudged.sh` on
  `tests/expected/dead_leg_unjudged_linux.tsv` (cleanhost's 2 modes on a dead `PATH:podman`, desktop's muted-stream and
  unlinked-recorder on a dead `PATH:pw-record`, wrong-mark on a dead `PATH:xwd`), release cadence, `tests/ci_emulator.tsv`;
  SKIPs off Linux, without podman or without a live GNOME session, and says so. The two target gates call `vs_ctl_nj` at their
  liveness exits; cleanhost's modes fire only on their own evidence (C0 naming libasound.so.2 missing, C1 failing with
  libGL.so.1 dropped). On PILOT at scratch `3ce6645c`: plain PASS in 2,024 s (5 rows UNJUDGED dead, their neutered copies at
  their frozen classes, plain runs red and silent), `nj-stripped` and `plain-loud` HONOURED (2,025 s and 1,613 s), nothing
  left running.
- **The driver leaked (found by this work):** `tools/desktop_session_play.py` stopped the emulator and the sink recorder
  after its step loop; a dead `xwd` made the `cap` step raise, so the two baseline runs left two emulators and two recorders
  playing into the session, and the next plain desktop run FAILed on a leftover's silent stream. Fixed: the stop is in a
  `finally` (group TERM, then KILL even after the leader exits); the driver refuses to start beside another emulator's
  stream (`stray`, exit 3); `apprec` records only its own process group's node; a missing capture is logged. Shown on
  PILOT: D1 (the old driver, xwd dead) left 4 processes and read DIED; D2 (the new driver beside them) refused, 5 "already
  on the session" lines; D3 (the new driver, xwd dead) read UNJUDGED with both own-stream checks ok and left 0. The new gate
  also names and kills any release emulator or recorder its runs leave (shown on PILOT with a stub inner gate leaving a
  process named as a release FBNeo: named, killed, FAIL; with nothing left: PASS; not a frozen control). The desktop gate's plain run and its 3 modes then
  PASS/HONOURED under the runner (783 s, one after another).
- **One harness at a time on the desktop session (rule-checker run -1727):** nothing in the runner keeps two gates apart
  in a pooled run, and a desktop run refused inside a dead-leg row (the driver's `stray`, exit 3) reads UNJUDGED, that
  row's frozen class: a false green. `tests/lib/desktop_session.sh`: the desktop gate and the dead-leg gate claim the
  session (an owner file) and are REFUSED (exit 3) beside a live owner or a release emulator already running; the driver
  refuses unless it runs under the owner (`owned`, exit 3); nested runs claim nothing. Shown on PILOT at scratch
  `d29fa100`: with a foreign owner both gates and the driver refuse; with a leftover both gates refuse and leave it
  alone; a stale owner is ignored. Then the desktop gate PASS with 3 modes HONOURED (794 s) and the dead-leg gate PASS
  (2,027 s) with both modes HONOURED (5,687 s), nothing left running, the owner file gone after each.
- **The desktop gate off the emulator concurrent list, never to be listed:** its modes share the desktop session (the null
  sink, the PipeWire graph, the X display and its focus), which a write trace cannot see; its `pilot:a10866d0` SAFE said
  nothing about them. M26's release ran it alone (`--only`), so no release was judged side by side.
- **Back on the static concurrent list:** `test_release_roundtrip` (10 controls, SAFE, 10 HONOURED) and
  `test_emulator_runner` (new cases 3f and 3g) re-traced on PILOT at `3ce6645c`. The runner's first trace read all 22
  modes UNJUDGED (HOLLOW): the pass ran under `gnome-session-inhibit`, which leaves SIGPIPE ignored for every child, so each
  runner copy's write into a closed pipe printed `printf: I/O error` and the error scan read the copies as unable to run;
  each mode had reached the gate's own FAIL. Both gates re-traced through `env --default-signal=PIPE` (roundtrip's first trace,
  in the same phase, had read SAFE; rule-checker run -1725 asked for it to be re-run too). The pass's gate runs and M26's
  desktop runs (also under the inhibitor) carry no such line.
- PILOT crashed or powered down (the maintainer: "For some reason PILOT has either crashed or powered down. It's
  now back up"); it booted at 05:22 CET with no shutdown record, after batch 5 lost it (6); both passes of this work ran after that
  (from 05:26 and 05:42). Pass 1 was stopped by hand in its dead-leg run, its desktop run having failed on the leaked
  processes; pass 2 ran whole.
- **Checked:** rule-checker run 2026-11-08-1730 OK after -1725 to -1729 (each found a real gap: roundtrip's trace with
  SIGPIPE ignored, the leftover check never fired, pass 1's stop, the dead-leg gate beside the desktop gate, the driver
  blob the leak evidence ran, where each PATH row dies — measured on PILOT: each stub called, each NOT JUDGED naming its leg). Three gotchas in `docs/project/gotchas.md`. Evidence:
  `build/agent223/t310lx/` (local; PILOT `~/t310lx`, `~/t310lx2`).

### (8) #310 — THE RE-CENSUS FOUND AN UNTAKEN LIST; A POST-MORTEM BEFORE ANY BATCH 6
The group-7 re-census at the staged tree (`build/agent223/recensus/`, local): 1,191 declared control modes in 312 gates;
214 are rows of the two dead-leg tables; 124 modes in 32 gates the 14z-215 census marked PRESENT or CANNOT TELL have none:
118 from its "new instances" list, which batches 1-5 never drew from, and 6 that batch 4 judged need no row. 439 modes
were never censused. Their dead-emulator baseline (`build/agent223/b6/`, local): 95 HONOURED, 23 DIED, 6 UNJUDGED.
The maintainer: **"I can't shake the feeling that while there is proper root causes, we are making things very
complicated incrementally. … we'll need to post mortem that"**, then **"Post-mortem first (Recommended)"**
(`DECISIONS_HISTORY.md`, 14z-223): the Linux gate lands; batch 6 waits for a post-mortem and a greenfield proposal. *[Resolved: (9).]*

### (9) THE POST-MORTEM RULED: #369 AND #370 FILED; #310 CLOSES WITH #369
The post-mortem (posted on #310; the lesson in `docs/project/gotchas.md`, "A FIX THAT LISTS THE WRONG ANSWERS NEVER
FINISHES") found #310 enumerative from day one and made three recommendations. The maintainer: **"I agree with all 3
recommendations"** (`DECISIONS_HISTORY.md`, 14z-223). Filed: **#369** (a control mode is honoured only on positive
evidence from its own check; batch 6 dropped) and **#370** (gates declare what they share; the runners schedule by it,
replacing the write-traced allow-lists and the desktop-session lock). #310 stays open until #369 lands, then closes.
#369's migration size is in its body and `DECISIONS_HISTORY.md` (static run: `build/agent223/postmortem/static_fired/`).

### CLOSE (14z-223, 2026-11-08)
Riding this close: (9) above (the post-mortem's ruling, #369 and #370 filed, their rows and #310's decided and wrong
links, the gotcha "A FIX THAT LISTS THE WRONG ANSWERS NEVER FINISHES", `DECISIONS_HISTORY.md`'s two 14z-223 rulings' second),
and STATE's row (8) trimmed under the byte cap. Commits this sitting before the close: `c5fe01b4` (#365, #366), `d9014d34`
(#367; batches 3-4), `9b83394d` (#368; batch 5), `8973b301` (the Linux gate). Tickets closed on GitHub this sitting:
#365, #366, #367, #368; filed: #367, #368, #369, #370. Steps: sections (this group; pointers on (3)-(6) and (8)); next-session (the 14z-222 opener, 110 lines, quoted, to
`docs/NEXT_SESSION_HISTORY.md`); rollover (the 14z-222 group, 86 lines, to `STATE_HISTORY.md` with its ledger line);
indexes (by the driver); dashboard (14z-163..14z-223, 3,734 figures, 0 unclassed; five assets uploaded, `datasets`
re-pointed: actions v14, costly v34, figures v34, rc_runs v34, tiers v35). The tier's results:
`build/agent223/close/tier_results.tsv`, the next close's `--prev`.

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
| effect-class row 19 (`0x080AF8`, #357, staged 14z-221c, FROZEN M26 14z-222) | vanilla never dispatches class 0x13 in the `$FFD400` pool | `tests/audit_effect_class_rows.sh` §1b, 0 reads over every frame of six replays vs §1's 3,872-hit row-37 control (14z-221c) | NOT safe-and-loud: a vanilla type-0x13 object would run Donovan's orb watcher (it reads a fighter through `+0x30` and can spawn eight effect pieces) — visible on screen, never silent |
| victim reaction row 0x4F (`0x0238FA`, #363, staged 14z-221c, FROZEN M26 14z-222) | vanilla never lands reaction class 0x4F | `tests/audit_effect_class_rows.sh` §1c, 0 reads on six replays vs a 21-read control on the table's rows 0x00-0x3F (14z-221c); static: no reachable legacy record carries 0x4F (`tests/test_reaction_classes.sh`) | a vanilla 0x4F hit would freeze the victim (vs2's reaction) instead of the default slide — a gameplay change, visible |
| dead span `0x029CBA-0x029CBF` (#363's jump, staged 14z-221c, FROZEN M26 14z-222) | nothing executes or reads the six bytes | `tests/test_dead_span.sh` (rules A, C, T, D, R, L: DEAD with three bases above the span accepted at their named sites, by reading: two word tables indexed after `andi.w #$3e`, a decode of data the descent never reaches) + `tests/audit_dead_span_exec.sh` (0 executions there and at the `bra.b` after it, 64-replay corpus) + `tests/test_dead_span_reach.sh` (on the built images) | an execution would jump into the freeze handler instead of setting `+0x3B5` = 4 — the reaction state corrupted, loud |
| dead span `0x024024-0x024029` (#294's jump, 14z-216; CORRECTED 14z-221c) | nothing executes or reads the six bytes | `tests/test_dead_span.sh` (DEAD with three references accepted at their named sites: rule D's byte table `0x023F84` read at `0x023F68` with the victim's unmasked `+0x56`, on its runtime bound; rule R's value `0x00024000` at `0x0433B8`/`0x077516` and rule T's row 0x8A of `0x02A646`, by reading) + `tests/audit_dead_span_exec.sh` (0 executions of the span AND of `0x023F68`, 64-replay corpus) + `tests/test_dead_span_reach.sh` | a `+0x56` >= 0xA0 at that read would take a jump opcode byte as an anim index — wrong pose, visible |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.
