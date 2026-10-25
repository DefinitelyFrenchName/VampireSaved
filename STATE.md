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

## Session 14z-208c — **#278, #326, #319, #324 and #325 closed done at this push; #229's F4 re-rigged on the maintainer's answers and every row confirmed (the motion test; the air throws moved to the normal throws; #319's hashes); #121 reconciled.** A continuation of 14z-208b after its close (`25dbfea1`, pushed), on the same transcript (`7462776e`).

### (1) AFTER 14z-208b'S CLOSE (written as 14z-208b (6) until this close) — #278: COLLATION PINNED IN THE RUNNERS; COMMITTED LOCALLY, CLOSES AT THE NEXT PUSH
The maintainer asked why #278 was not considered at the freeze: its comment of 14z-207 left a freeze-cadence locale
run, and the opener named it only as "measured, open" (the lesson: `docs/project/gotchas.md`, the UTF-8 collation
entry). Ruled *"Both"*, *"A with only that one per-line pin"*, *"Commit stays local"*, *"Close at the next push"*
(`DECISIONS_HISTORY.md` "Ruled 2026-10-25 (14z-208b) — #278: …").
- **PILOT, at `25dbfea1`, before the change:** the strict static tier at freeze cadence under `LC_ALL=en_US.UTF-8` and
  under `LC_ALL=C`: PASS 217, FAIL 2 under both, the 219 per-gate verdicts identical; the two reds are host state, not
  collation (`test_emulator_staleness`: PILOT's emulator records; `test_release_reuse`: its synthetic repo's reuse plan
  refuses, "the freeze run's identity moved during it" — a Linux-only red at `25dbfea1`, filed as #326 after the
  commit: the gate's synthetic repo has no `.gitignore`, and Linux Python's `__pycache__` changes its untracked key mid-run). The five release-cadence
  gates were deferred in both runs. Evidence: `build/agent208/t278/evidence278.txt` (local).
- **The census widened** to every tracked shell file (lane P's covered the 231 static gates): 212 unpinned
  `sort`/`ls`/`comm`/`join` lines in 92 of 536 files; 134 lines in 61 files past the order-free shapes
  (`build/agent208/t278/census278b.txt`, `classify278.py`, local).
- **The change:** `tests/lib/collation.sh` (`vs_pin_collation`), called once at the top of `tests/run_all_static.sh`,
  `tests/run_all_emulator.sh` and `tests/run_battery_m2.sh`, sourced only when present (the runner tests' synthetic
  repos carry part of `tests/lib`; the first tier on the change was red on those four gates); `test_charmap_current.sh`'s
  FREEZE=1 write sorts under `LC_ALL=C` and leaves `tests/controls_concurrent.txt` until the next freeze's re-trace; the
  new gate `tests/test_runner_collation.sh` (five controls), PASS on the Mac and on PILOT, where the pinned sort gives
  byte order under `en_US.UTF-8`. The opener's #278 line now says to read a ticket's comments before planning a freeze.
- **Two of the session's own statements corrected before the commit:** macOS's `en_US.UTF-8` does collate (case and
  punctuation; this Mac's sessions run under `LANG=C.UTF-8`, byte order), so the gate's probe now compares against a
  `C` sort and works on both systems; and nine gates, not one, write a frozen file whose order comes from a shell sort on
  a hand-run `FREEZE=1` — the one-pin ruling was re-confirmed on that basis (*"yes"*). The maintainer asked for the gates
  explained plainly: `docs/project/gates_explained.md`.
- **After the change, on PILOT** (the commit object `6a9051e1`, freeze cadence, `LC_ALL=en_US.UTF-8`): PASS 218, FAIL 2,
  the 220 per-gate verdicts equal to the two earlier runs' apart from the new gate's PASS. A probe gate run through the
  real static runner reads `en_US.UTF-8` and a dictionary sort under the old runner, `LC_COLLATE=C` and byte order under
  the changed one (`build/agent208/t278/p278_probe.sh`).
- **Rule-checker:** run `2026-10-25-1279` withdrawn unspawned (its packet check flagged an unshown absolute in the
  closing comment); `-1280` VIOLATED on Q1, Q3 and Q4 (no freeze-cadence tier on the change; nothing showed the locale
  reached the gates in the earlier runs), resolved by the after-change run and the probe; `-1281` OK.
- **Not done here:** #278 stays `open` in `docs/project/tickets.tsv` and on GitHub until the next push; its closing
  comment is `build/agent208/t278/closing_278.md` (local). PILOT's clone sits at `25dbfea1`; `~/p208b_t278/`, `~/t278chk/` and
  `~/p278_*.sh` there are this work's scratch.
- **After the commit, uncommitted for the next close:** #326 filed (above); refreshing the ticket snapshot showed #121
  closed by the maintainer on GitHub (2026-10-25T09:27Z, their comment quoted in `DECISIONS_HISTORY.md`), reconciled to
  `done`; #123's title follows their edit.
- **#229 Q1, the maintainer's fourteen answers on F4's sheets (2026-10-25), each quoted and read against the capture:** moved VERBATIM to `DECISIONS_HISTORY.md` "Read 2026-10-25 (14z-208c) — #229 Q1: the maintainer's answers on F4's 18-tile command-throw sheets" (the live budget). Ruled among them: every air throw leaves the command-throw set for the normal throws.
- **#229 F4 RE-RIG, DONE ON THE MAC (the maintainer: *"do it"*, 2026-10-25; PILOT was the plan, the batch was small
  enough to run here — about 5 min a gate run).** Probes `build/agent208/RR/` (`probe.py`, `run_all.sh`, `summ.py`), then:
  - `tools/command_throw_rigs.py` (local, untracked): the 14 air-throw rows removed (ruled); Pit of Blame after a P2
    sweep, 623K at +20, P2 brought over the portal (walk-in + pursuit, or a jump toward), HK and KK, plus a no-623K
    control — the press counted from the 623K (from the sweep, Victor's own sweep record fell in the window and read
    foreign: the first freeze REFUSED, 5 events); Prova di Servo's second HK at +30 from the far pin plus a no-second-K
    control (+24..+36 all grab); Ira Spinta HK at +16 after the jump — at the F4 cadence (+12) it grabbed or whiffed with
    the walk-in (whiffed at 130/110/90/70/50, grabbed at 150/30/0), at +8 and +16 it grabbed at every walk-in, so the
    whiff was the cadence, not the range; MEGA SPIKE 360 LP/MP/HP/PP (all three punches grab, chain `a2:0x33`, 23/39; PP
    is NOT an ES, stock 9→9 — as the maintainer said), declared `NOT_IN_WORKBOOK`; Bishamon's labels carry the names;
    THE MOTION TEST, 71 events. 167 events, 37 rigs; row set 54 workbook rows + Mega Spike.
  - THE MOTION TEST's result (`build/agent208/RR/motion_table.txt`; `docs/game/engine_internals.md` "Which half-circle
    spellings vsavj accepts"): half circle back — 63214, 6324, 6214, 624 grab on all 14 rows, 6321 never (a crouching
    normal); half circle forward — all five spellings work (Q-Bee ground and air; Prova di Servo's start).
  - `tests/audit_command_throws.sh` (local): header and the five controls' counts from the frozen lines (155 events stage
    a record, 34 spend stock, 155 have a fall; unsigned-chain 12 of Sasquatch's 13, all but motion 6321HP). Frozen
    (`FREEZE=1`, run `RR/g2`), clocks frozen (`RR/g3`), plain run `RR/g4`.
  - `tests/audit_ground_throws.sh` + `tools/ground_throw_rigs.py` (TRACKED): the air throws joined as one `gt_XX_air` rig per
    character at GAP 624 (the 28 old rig files regenerate byte-identical), Bulleta's at +18, Victor's converging (P1
    UR, P2 UL 4 frames ahead, toward+button at +16: both MP and HP throw, chain `a2:0x37`, 15/23); the leg-falls plant
    reads the rig schedules instead of the 600-frame grid, the counts come from the rigs (`NEV`). 70 events; the 42 old
    expectation lines and 42 old clocks unchanged; plain run `RR/gt3` PASS, all 8 controls FIRED. Needs the close's
    bookkeeping (gate descriptions, generated indexes) and its tier.
  - Sheets (18 tiles per move, the changed rows only, P2 HP equal to the trace at every tile): `build/agent208/RR/capA/
    sheets/f4_AN.png` (Pit of Blame ×4 + control), `f4_JE.png` (Ira Spinta HK, Prova di Servo + control),
    `f4_VI.png` (Mega Spike ×4), `build/agent208/RR/capV/sheets/f4_VI_airthrow.png` (Victor's air throw, the gate's own
    set-up). Backups of everything replaced: `build/agent208/RR/before/`.
- **#229, the maintainer on the re-rig sheets (2026-10-25):** *"All is correctd except prova di servo's second part which
  is correctly input but Victor is too close to get grabbed by the blood hand so the second part whiffs."* Measured: in
  the gate the event read NOT held, no fall (the "7 hits" reported to the maintainer were the PROBE's, a wrong report
  from the probe rows instead of the gate's rows — every other changed row was re-read from the gate run and holds).
  Cause: a "far" event's x pins (t-230) do not hold when the previous event is a throw still running: after San Bassale
  HK Jedah stood at x 664, 64 px from Victor, not 176. Fixed by ordering: Prova di Servo's two events now open rig
  `ct_JE_5` (`tools/command_throw_rigs.py`); in the gate the hand grabs, 7 falls, 32/48, and the control holds nothing
  (re-frozen `RR/g5`; the three record controls now 156). New sheet `build/agent208/RR/capP/sheets/f4_JE_prova.png`. The
  same defect sits under three rows the maintainer confirmed: AN 236MP "far" (gap 127) and 236HP "far" (gap 78) — the
  F4 "HP Mummy Drop never reached in its slot" — and MO Cryptic Needle "far" (gap 64; it grabs anyway). RULED *"Fix all,
  re-show"* (`DECISIONS_HISTORY.md` 2026-10-25): every event walking in under 150 frames is re-placed at t-50-walk
  (`tools/command_throw_rigs.py` gen). Measured (`RR/g7`): AN 236MP/HP start at 176 px and BOTH grab now (19/31; HP
  never had), the walk20 pair at 140, Cryptic Needle at 160 (EX, held, 35/37 — its damage moved), Prova di Servo 176
  and grabs. Record controls now 157. Sheets `build/agent208/RR/capF/sheets/f4_AN.png` (Mummy Drops), `f4_MO.png`.
  The maintainer on the three sheets (`capF/sheets/f4_AN.png`, `f4_MO.png`, `capP/sheets/f4_JE_prova.png`), 2026-10-25:
  *"all good"* — every F4 row is now confirmed.
- **#326 DONE, closes at the next push** (the maintainer: *"both"*, PILOT for #326 and #324): the synthetic repo of
  `tests/test_release_reuse.sh` takes the real `.gitignore`'s two bytecode lines (checked present). On PILOT in a scratch
  clone, scratch commit object `1c314f83` (HEAD + the fix, never pushed; `refs/agent208/t326`): before FAIL, 5 controls
  fired, 2 dead; after PASS, 7 fired; on the Mac PASS, 7 fired. Re-traced on PILOT (`tools/trace_controls.sh`): 7
  controls SAFE, `tests/controls_concurrent.txt` row on blob `11376be2`, trace `pilot:1c314f83`; test_controls_concurrent
  PASS. Evidence `build/agent208/t326/` (incl. `pilot_p326/`). Rule-checker run 2026-10-25-1282 OK (plant caught); the closing comment `build/agent208/t326/closing_326.md` (local), posted at the push.
- **#324, the writer found and its leak already closed; the guard open** (`build/agent208/t324/evidence324.md`): the
  stub `xdelta3` of `tests/test_package_release_safety.sh` before `031c09d8` had no `-V` branch, and `031c09d8` (14z-207,
  developed 2026-10-23) added the packager's `xdelta3 -V` check (#279) and the stub's branch together — the old stub
  answering the new check writes `stub patch` to `./-V`, reproduced; the gate cds to the repo root. PILOT's `-V` saved
  and removed. Open: the done-when's guard — the static runner compares tracked files only (`grep -v '^??'`).
- **#319 CONVERTED (ruled *"Convert now"*):** `tests/expected/ground_throws.tsv` holds sheet, key, input and a 16-hex
  SHA-256 per event; the full lines go outside the tree (`../charpages/framedata/ground_throws_full.tsv`, `GT_FULL`), a
  red prints the run's own, `snaps` reads the first-fall offsets there (no file: no snapshots). On `RR/gt3`'s rows the
  70 full lines equal the old plain lines byte for byte, expect 70/0 bad, snap frames unchanged. The gate's plain run `RR/gt4`:
  PASS, 70/0 bad, 70 snapshots, all 8 controls FIRED. CLOSES AT THE NEXT PUSH: rule-checker run 2026-10-25-1283
  withdrawn unspawned (an attribution flag), 1284 VIOLATED Q1 Q3 Q4 (no red shown through the hashed compare; the
  hash check used the tool's own function) and resolved (evidence sections 7-8: class-raw's 8 reds print got/want/run/
  was; a shasum-CLI hash of the 70 lines, 0 mismatches), 1285 OK; closing comment `build/agent208/t319/closing_319.md`. Command-throw gate after the re-placement `RR/g8`: PASS, 8 FIRED.
- **#324's guard BUILT (ruled *"Runner-wide check"*):** `tests/run_all_static.sh` lists the untracked files outside
  `build/` (its own results files aside) before and after, names a new one (`LEFT BEHIND`), and `--strict` is NOT GREEN
  on it (`STRAY-CHECK`); `tests/test_static_runner.sh` sections 30/31, control `stray-blind`: PASS, 24 fired; the mode
  exits 1. A strict session tier on PILOT on scratch commit `6eefd93c` (the tracked change set): `ok: no new untracked
  file outside build/`; its 6 reds: PILOT's own staleness rows (red before too), 3 generated pages (the close's
  bookkeeping), test_build_dirs (section 30 named build/inside_324 — moved to build/agent324/, PASS) and
  test_controls_concurrent (test_static_runner re-traced: 24 SAFE, `pilot:b7d2f4dd`). CLOSES AT THE NEXT PUSH: rule-checker runs
  2026-10-25-1288 withdrawn unspawned, 1289-1292 VIOLATED and resolved (a mis-counted dead control; PILOT's deletion and the
  reproduction through the packager not shown; the cause not separated from the stray — section 11's causation runs;
  the named limits: a non-strict run stays GREEN, ignored files are not compared, and a file written OUTSIDE a runner run
  is never flagged — PILOT's `-V` came at 17:26Z, before the 17:35Z run, so this check would not have caught it), 1293
  OK; closing comment `build/agent208/t324/closing_324.md`.
- **#325 FIXED on the Mac** (the maintainer: *"#325 can maybe run since we're waiting for PILOT?"*):
  `tests/run_on_snapshot.sh` names the snapshot and its record by commit, second AND process id, and makes each with
  one atomic `mkdir`, refusing cleanly if another run holds it (`SNAP-NAME`). `tests/test_run_on_snapshot.sh` section 6:
  a stub `date` pins the stamp, two runs of one commit start together — both exit 0, two snapshots, two records; control
  `same-name` (the old names) collides (the second REFUSED) and FIRES; PASS in 26 s; the mode exits 1. Its
  `controls_concurrent.txt` row re-traced on PILOT (13 controls SAFE, `pilot:1589fd17`). CLOSES AT THE NEXT PUSH: run
  2026-10-25-1286 withdrawn unspawned (an absolute in the comment), 1287 OK; closing comment
  `build/agent208/t325/closing_325.md`.

### CLOSE (14z-208c, 2026-10-25)
Driver `build/agent208/close208c/` (`--prev build/agent208/close208b/tier_results.tsv`, the 14z-208b close's run of
record). Before it, each ticket closed on GitHub with its comment, on its rule-checker run: #278 (`2026-10-25-1281`),
#326 (`-1282`), #319 (`-1285`), #325 (`-1287`), #324 (`-1293`); the snapshot refreshed (`tools/tickets.py refresh`).
Steps: sections (the work of this sitting is section (1), written as 14z-208b (6) until this close); next-session (the
14z-208b opener to `docs/NEXT_SESSION_HISTORY.md`); rollover (the 14z-208b group, 77 lines, to `STATE_HISTORY.md` with its
ledger line; its one `STATE` citation re-pointed; today's post-close rulings relabelled 14z-208c); indexes (regenerated
in a clean checkout of the staged tree, with the gate index, coverage and crosscheck pages, where test_tickets,
test_state_open_lists, test_live_budget, test_history_index, test_gate_index_current, test_gate_coverage_current,
test_controls_concurrent, test_build_dirs, test_docshape, test_doc_anchor_census, test_gate_descriptions and
test_must_fire_census PASS); dashboard (14z-163..14z-208c, 1,960 figures, 0 unclassed; datasets versions 17, 17, 18, 17)
— done. The tier's results: `build/agent208/close208c/tier_results.tsv`, the next close's `--prev`. The push carries
`e0965d4d` (#278) and this close's commit. Left local and untracked: #229's 131 files
(`build/agent205/t229/pending_gates_229.list`). The tier went RED on one control (`test_static_runner`'s `pool-concurrency-off`
DIED: `printf: write error: Broken pipe`, a `printf | grep -q` race in its section 22); the maintainer: *"Ticket it, re-run
tier (Recommended)"* — filed #327; the driver re-ran the red (`build/agent208/close208c/tier_results.red-*.tsv`).


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
