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

## Session 14z-205 — **#291 S2 complete (58 gates draw, 174 declare; the event basis D2 built); #293 found and fixed; #120's rebuild spec pushed to its own repository and #120 closed; the static tier's scope cut (#297, #298, #299).** Opened 2026-10-18 on Opus 5.5 (the ruled orchestrator); transcript `995e7259`.

### opened with
The maintainer: *"read handoff.md, state.md and docs/next_session.md"*. The opener's sweep read CLEAN; `main` at
`6dee2be7`, level with `origin/main`; PILOT and ERIS unreachable. Then: *"yes, do #291"*, and asked how much of S2 to
take (the 228-row debt list split as 164 declaration-only gates and 64 comparing gates in four groups by what proves
their pictures: A the leg's `replay.lua` log, B its `field_trace.lua` fields, C taps only, D ROM pokes or an FBNeo leg):
*"A + B + the 164 lines"*.

### (1) #291 S2 — THE 164 DECLARATIONS, GROUPS A AND B
- **164 gates declared** (`none` 155 with the S-class reason among them, `no-reference-leg` 10 as ruled), each classed
  from a reader's verbatim quotes of its leg launches (nine reader specs, `build/agent205/s2/decl/`, local); the line
  follows each gate's `# FOLLOWS:` block.
- **42 gates draw**: `audit_fg_parity` (the pilot) and 41 retrofitted by five parallel forks of this session, each run
  plainly and with `SHEET_OUT` by `build/agent205/s2/check_gate.sh` (outputs identical once temporary paths, the shell's
  segfault notice and a timestamped directory are normalised) and every picture proven; the combined page
  `build/sheets/s2_14z205/index.html` (local, 65 MB): 2,141 pictures, 2,120 PROVEN, the 21 others the carried-nvram runs
  of #293 (re-proven after its fix). Five fork gates moved to the tap group (C): nothing they log proves a frame.
- **Tool fixes:** `tools/proof_sheets.py` resolves a relative `--out` (every capture failed on one: ground truth section
  3b, control `relative-unresolved`; the gotcha is homed); the page reads verdict lines like `AUDIT PASS`
  (`verdict_line`, cases in `test_sheet_census` 3b).
- **Caught by looking at the pictures:** three declarations named the wrong P2 character (`audit_fg_parity`,
  `audit_ex_refused`, `audit_df_moves`), corrected; and a fork's line had split `audit_win_pal_auto`'s `# FOLLOWS:` block
  (`test_gate_follows` red, fixed).
- **Retracted the same hour:** a fork's report that a fresh merged run draws another 1P CPU opponent than vanilla; a
  fresh oracle run of replay 02 equals the frozen vanilla log at f2146 (`fa9d83bbfa84cea0`).

### (2) #293 — TWO GATES RAN ON CARRIED NVRAM; FIXED
Found by the sheets (a re-run on a fresh sandbox refused the gates' pictures). `audit_flicker_attribution` shared a
sandbox between replay 105's two cases; `audit_legacy_pairings` ran each replay three times into one sandbox and one
file, and its three tenant controls into one file. The maintainer: *"Ticket + fix both now"*. Fixed: a sandbox per case
plus a frozen-basis check on each vanilla leg (control `shared-sandbox`); one sweep leg per distinct build, a file per
tenant control with a check that it loads that id, and an atomic `mkdir` that refuses an existing sandbox (control
`shared-sandbox`). On fresh boots the flicker attribution held (f5868: 3 bytes in `obj-builder-stack`); 7 pairings
verdicts moved TENANT to LEGACY, each already carrying a `.masked`. Rule-checker runs 2026-10-18-1125 and -1126
(VIOLATED, resolved: the control sandboxes' naming shown, then a real freshness check added for the sweep legs).
**Closed** on GitHub after `bf92acd2`, its row `done` in the close commit (§ CLOSE).

### (3) #291 — THE DESIGN FOR THE LAST 22 GATES, RULED; D4 BUILT
Put after rule-checker runs 2026-10-18-1120 to -1123 (VIOLATED, resolved) and -1124 (OK); posted on #291. The
maintainer: *"EVENT-PROVEN basis (D2)"*, *"A no-picture kind (D4)"*, *"D4 first"*. D4 built: the `no-picture` kind in
`tools/proof_sheets.py`, `test_sheet_census` (two grammar cases) and the contract, and eight gates declared (two
corpus-wide censuses, `audit_walker_ghost`, three `-debug` gates, `audit_move_parity_attribution`,
`test_fbneo_legacy_oracle`). Census: 45 legs, 10 no-reference-leg, 8 no-picture, 155 none, 14 on the debt list.

### (4) #291 — D1 RETROFITTED, D2 BUILT (D3 NEEDS NOTHING OF ITS OWN)
- **D1:** `audit_column_flash` (6 pictures) and `test_hui_df_style` (10) draw on their legs' own checksum logs, outputs
  identical; `audit_dmg_legacy_sweep` waits for D2 (half its legs ran with ROM pokes).
- **D2, measured before it was built** (`build/agent205/d2/`, local): a scratch wrapper loading `read_tap.lua` itself and
  adding a snapshot hook wrote a byte-identical tap log (69 lines) to the plain run, and its f2050 picture equals
  `sheet_capture.lua`'s f2050 pixel for pixel and differs from f2049 and f2051. Built on it:
  `tests/lua/sheet_tap_capture.lua`, `sheet_tap` in `tests/lib/sheet.sh`, the `tap` row, the `event` basis and the
  EVENT-PROVEN status in `tools/proof_sheets.py` (event lines: a frame in the first or second token; run summaries
  excluded), clips (`.wav`) played on the page. Ground truth `tests/test_proof_sheets.sh` section 4b: events reproduced
  EVENT-PROVEN, a one-frame shift and an altered value refused, an empty window UNPROVEN, the re-run's f2198 pixel-equal
  to the checksum capture's; control `count-only` fires in-gate and FAILs as a mode.
- **D3:** a leg's ROM pokes, opcode patch and sweep pokes are its instrument's env, which the wrapper passes unchanged —
  no mechanism of its own (the contract says so).
- **S2 complete:** the last 12 gates retrofitted by five more forks (6-10), each IDENTICAL and fully proven: ten tap gates
  EVENT-PROVEN (`audit_throw_registration` 72, `audit_facing_sweep` 384, `audit_rng_draws` 16, `audit_column_flash_cause`
  6, `audit_grenade_ground_tiles` 6, `audit_hui_grunt` 10, `audit_trap_parity` 15, `audit_air_gc_legacy` 21,
  `audit_landing_sound` 70 plus 4 clips, `audit_qs_voice_wav` 148 clips) and `audit_dmg_legacy_sweep` (200 PROVEN, 12
  EVENT-PROVEN through `rom_poke.lua`); `audit_qs_voice_batch` declared `no-picture` (it judges whole-run multisets over
  two id lists). Two tool limits found by the forks and fixed: `capture_tap` routes `FIELD_OUT` (rom_poke.lua hands off
  to field_trace.lua), and a tap env value keeps its own `;` (read_tap's multi-range RTAP; reader cases in
  `test_sheet_census`). Census: 58 legs, 10 no-reference-leg, 9 no-picture, 155 none, **0 on the debt list**.
- **#293 follow-up census** (`build/agent205/sbx/`, local): 273 explicit sandbox sites in 168 gates; the 86 with no
  per-run variable read where two runs could reach them, none shared. The #293 shape itself (a variable key whose values
  repeat) is NOT covered by a static read: a dynamic check would refuse an existing sandbox in `tools/run_mame.sh` behind
  an env flag — put to the maintainer; ruled *"it's a good idea, do it"*: #296, § (8).

### (5) #120 — THE REBUILD'S SPEC, DRAFTED AND PUSHED TO ITS OWN REPOSITORY
- Drafted while tiers ran, from the maintainer's brief and answers (verbatim in `DECISIONS_HISTORY.md`, "#120: the
  rebuild's brief…"): `SPEC.md`, `docs/tests_inventory.tsv` (the 464 top-level `tests/*.sh` in seven reuse classes: E1
  119, E2 76, F 65, P 55, and T, M, R) and `tools/classify_tests.py`, pushed to `DefinitelyFrenchName/VampireSaved-Rebuilt`
  (`8c1862d` v0.1, `4cce084` v0.2 with the four §10 answers); linked on #120. Working copies: `build/agent205/t120/`
  (local). Rule-checker runs 2026-10-18-1129 to -1132, each VIOLATED and resolved; the last one's finding: the
  index-currency check named no tree, now stamped before and after by `tree_id.py` (both equal the inventory's line).
- The classes are a script's reading of each gate's code, unconfirmed gate by gate. Phase 0 (the rule-5 extraction,
  gameplay values first) is work in THIS repository; no ticket moves to the rebuild. #120 later closed, § (8).

### (6) THE FIRST TIER WAS RED: test_poked_legs; THE CENSUS RE-FROZEN
- The tier on the staged tree (`build/agent205/tier1/`, local): PASS 199, FAIL 1, `test_poked_legs` (the forced-pick census
  23 rows longer, none removed). 7 rows were false native legs from this sitting's `# SHEET: none` comments naming vsav2
  in three poked gates (the documented comments-included trap, paid again; `docs/project/gotchas.md`); the comments now
  say vs2. The other 16 come from the sheet blocks' poke text in `audit_df_startup_invuln` and `audit_dmg_legacy_sweep`
  (12 PARAM like the frozen `$_v` rows, 3 CROSS-INERT, 1 SAME; CROSS-FLAVOR unchanged, accepted list unchanged).
  Rule-checker run 2026-10-18-1136 (VIOLATED Q1 Q4, resolved with `build/agent205/poked/census_evidence.txt`); the
  maintainer saw the 16 rows and ruled *"re-freeze"*; `tests/expected/poked_legs.tsv` re-frozen (+16, -0), the gate
  PASSes with both controls fired. Not built: a control for the census tool's loop-variable resolution.

### (7) #295 FILED, #294 RECORDED, AND A NOTE ABOVE EACH SHEET (#291)
- Reading `audit_dmg_legacy_sweep`'s sheet, the maintainer asked why it compares vsavj with vs2 and not with our build:
  it was built for #191 (an engine difference between the original games); no gate runs those legacy legs on our build,
  and the 53-replay oracle does not include them. Filed as #295 on the maintainer's word (`DECISIONS_HISTORY.md`,
  "#295"); not built. #294 (Killshread's aura palette), filed parked by the maintainer, has its row and its local record.
- **Sheet notes:** `docs/project/sheet_notes.md` (one section per gate, shown above its pictures by
  `tools/proof_sheets.py page`; `test_sheet_census` section 3c, control `orphan-note`); one note written, the sweep's,
  and its page re-rendered (`build/agent205/s2/gates/audit_dmg_legacy_sweep/sheets/`, local). The other 57 are #291's
  (commented 2026-10-18).

### (8) #120 CLOSED, #296 STEP 1, THE ROM-CONTENT RULING
- **#120 closed `done`** at the maintainer's request; what is left is VampireSaved-Rebuilt#1 (the drafts' review, the
  ledgers' ten flags and their 201 adapted and 18 dropped rules, phase 0 in THIS repository, phase 1's setup, phases
  1-4). The CLAUDE.md, skills and swarm went to the new repository as `d11c9a3` after rule-checker run 2026-10-18-1134
  (resolved); the closure after run -1137 (resolved).
- **#296** (the run-time sandbox guard, the maintainer: *"it's a good idea, do it"*), step 1 built: `MAME_SANDBOX_LOG`
  in `tools/run_mame.sh` logs per run whether the sandbox already held an earlier run's state; the gate
  `tests/test_mame_sandbox_log.sh` (ci_portable, a stub binary, control `state-blind`). NEXT: run the emulator lanes
  with the log on (a remote box) and attribute every reuse; then step 2, refusal by default.
- **ROM content in the tree, ruled:** addresses and discrete values are fine, whole graphics, sounds and algorithms are
  not (`DECISIONS_HISTORY.md`, "the no-ROM-bytes rule"); the four quoted sound-driver bytes stay.
- A page for the maintainer on what a tier does: https://claude.ai/artifact/1DzrvoGUphYYmtyRKvhJtZ (private).

### (9) THE STATIC TIER'S SCOPE — SIX FAMILIES TO FREEZE (#297), CONTROLS ON A CHANGED PROGRAM (#298), PARALLEL GATES (#299)
- Asked what a commit or close runs: the static tier only; the emulator tier runs at a freeze and a release (the tiers
  page, https://claude.ai/artifact/1DzrvoGUphYYmtyRKvhJtZ, private). Asked whether the session scope is too broad, the
  record measured (`build/agent205/tier_history.py`, local): 104 static runs 2026-10-02..18; session reds by family
  pipeline 3, review-triage 1, gfx, oracle, mister, tenant 0; 9,367 executed controls since 2026-10-04, all HONOURED;
  controls 1,500-1,800 s of a close against 600-1,000 s of gates. Ruled (`DECISIONS_HISTORY.md`, "the static tier's
  scope"): all three, the controls' middle option, and *"Own code changed (Recommended)"* for the moved gates.
- **#297:** 109 gates to freeze cadence with the `@code` trigger (`tools/static_confirm.py reach`, the R1 closure; a
  failed reach fails safe); `test_static_runner` 14j, control `code-trigger-off`. Open until a freeze runs them green.
- **#298:** a stale gate's controls execute at a commit or close only when a program of its reach changed (R1; before,
  R2/R6 data reads too); on the 14z-205 tier-2 plan 117 -> 17 gates; `test_static_runner` 22d/22e, controls
  `controls-always`, `controls-never`. To be measured on this close's tier.
- **#299:** `--jobs N` (`tests/lib/static_job.sh`, a pool, results classified in registry order). Portable tier without
  controls: 89 gates, the same verdict each, 11 min 7 s serial, 4 min 54 s at 8 jobs (`build/agent205/t299_*`, local).
  The decrypt cache was already race-safe (atomic rename). NEXT: the full tier with controls, serial against 8 jobs on
  this close's snapshot.
- **#296 step 1 on the real binaries:** the emulator prereq lane, 23/23 GREEN with the new `run_mame.sh`; its inventory,
  324 MAME runs, every one on a fresh sandbox (`build/agent205/t296/`, local).

### CLOSE (14z-205, 2026-10-18)
- Run directory `build/agent205/close/`; `--prev` is this sitting's tier-2 run (`build/agent205/tier2/tier_results.tsv`,
  strict GREEN on the tree of `bf92acd2`), not the 14z-204 close's: the same base the commit's guard read, and a plan of
  ~80 s instead of 2 h 21 min (tier 1's).
- Steps: sections, next-session (the 14z-204 opener moved verbatim, a new opener), rollover (14z-204's 141 lines to
  `STATE_HISTORY.md`, byte-equal to HEAD's group, its ledger line on top), indexes (auto), dashboard (four datasets,
  keys 14z-163..14z-205, 1,797 figures all classed; `datasets/*` re-pointed in one batch) — all DONE.
- The tier's results: `build/agent205/close/tier_results.tsv` (the next close's `--prev`), on a snapshot of the staged
  tree; its controls file measures #298's narrowing; the #299 serial-against-8-jobs comparison runs on the same commit
  after the commit.
- Commits this sitting: `bf92acd2` (#291 S2, #293, the census re-freeze), then this close's; both local until its push.

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
