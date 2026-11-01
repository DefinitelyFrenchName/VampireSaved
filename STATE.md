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

## Session 14z-216 — **in progress: #310's crash-injection sweep; #127, #128, #162 and #294 unparked, under analysis.**

### opened with
The 14z-215 close's opener; the sweep CLEAN, `main` = `origin/main` at `3979abea`, the CLOSE section's last lines and the
opener's note uncommitted as they said; ROMDIR audited 76/76. The maintainer, on the proposed order (the remote scratch,
then #310's crash-injection sweep, then group 7's first batch): **"your order recommendation is fine. Of note, I unparked 4
tickets on github, they can be worked on in parallel but each one requires analysis before implementation and the green
light for implementation is done by the maintainer"** (`DECISIONS_HISTORY.md`, 14z-216). The remote scratch's deletion
(PILOT's `~/t215*`, about 31 GB; ERIS's `~/t129b`, `~/t129w`) was refused by the session's permission classifier; the
maintainer, 2026-11-01: **"-> do it"**. ERIS's two deleted (1.1 GB and 933 MB, no process using them; read back absent).
PILOT did not answer (ssh timed out, no ping reply), so its `~/t215*` waits until it is back. Working evidence:
`build/agent216/` (local).

### (1) #127, #128, #162, #294 — ANALYSIS, IN PARALLEL
Four analysis workers (`build/agent216/COMMON_BRIEF.md`, one directory each, local); nothing built. All four reported
(`build/agent216/t<N>/REPORT.md`, saved by the session: the harness refuses a subagent's own file). #127 and #162 are one
defect: the palette reload at `PRG:0x02ADAC` keeps vsavj's mask word at `PRG:0x02ADB4` without Donovan's bit 0x13 (vs2 sets
it), so his block rows 1-3 overwrite rows 0x0B-0x0D at every palette-state change (the black foot when hit during Press of
Death; the orange deity at the column's end; a 22-frame cyan sword burst after three moves); vs2's value, probed in the
opcode share, matched native on every compared frame and changed nothing on five legacy replays. #294 is the sword on
Donovan's back while he is electrocuted, drawn from his row 0x0C, which vs2's per-frame per-character routine (vs2
`0x2A316`, in the twin of vsavj's per-frame table `0x02ADEC`) rewrites and ours leaves at vsavj's no-op; the 2026-07-31
"engine-global" ruling was measured on a quick press that does not electrocute. 14z-171's "vs2 `0x02A142` twins vsavj
`0x02A8A4`" is wrong (it twins `0x02ADEC`), a retraction to make. #128: cost 0.30% of a frame; her identity is presentation;
the port changes a vanilla menu input (7 START on "?"). Captures sent to the maintainer for their read; no recommendation
put yet. **#127's sheet read (2026-11-01), the maintainer, verbatim:** *"#127: build/agent216/t127/sheet_127_pod_hit.png. Is
the right-hand column (the one-word probe) the Press of Death you expect  -> yes"*. The recommendation, (M) (vs2's mask word,
instead of the ticket's option (B)), went to rule-checker run `2026-11-01-1525` (`build/agent216/rc127/`). Runs -1525,
-1526 and -1527 VIOLATED, each resolved by work: the rig's shared id poke named and the result carried by the census, whose
legs poke no id; a positive control for the inertness probe's palette half (Donovan part 4: 5365 frames differ); the census
script reading census.sh's own pokes; the unparking attribution dropped. With #162's read in, the two went as ONE
recommendation, (M) for both (`build/agent216/rc127/recommendation_127_162.md`): run `2026-11-01-1528` **OK**; put to the
maintainer. #294's recommendation (A, port vs2's per-frame routine after a dead-byte check; the worker's 1.2% of a frame was
on a wrong ~198k-cycle frame, 0.9% on the tree's 268,288) went to run `2026-11-01-1529`.
**#294's sheets read (2026-11-01), the maintainer, verbatim:** *"Yes: Donovan's shock aura is yellow, as it should, but his
sword his red on our build, yellow on native."* (the question and sheets: `build/agent216/rc294/capture_read_294.txt`).
**#162's sheets read (2026-11-01), the maintainer, verbatim:** *"probe is indeed the correct behavior (hard to see during play
as it is very few frames, maybe only one frame, but still incorrect."* (`build/agent216/rc162/capture_read_162.txt`).
**#128's sheets read (2026-11-01), the maintainer, verbatim:** *"this is indeed the correct behavior in vs2 and the current state
of our build since it does not implement Marionnette. An implementation should follow vs2's behavior"*
(`build/agent216/rc128/capture_read_128.txt`).
**#128 PARKED AGAIN (ruled 2026-11-01):** *"let's park again, documenting what we now know"* (`DECISIONS_HISTORY.md`, 14z-216);
the findings in `docs/game/atlas/select_screen.md` "WHAT 14z-216 MEASURED (#128, parked again", the issue relabelled `parked`
with a summary comment and its stale "has not been located" line struck; the index row `parked`. A gate gap found on the way:
`tests/audit_marionette_cost.sh`'s asset census walks only record `0xB3` (`0xB2`, 44 cells, is hers too), recorded, not fixed.
**#127 + #162: GREEN LIGHT FOR (M) (ruled 2026-11-01):** *"1. Yes, (M) at the next freeze, closing both (recommended) ->
agreed"*. In progress: the `[[code_word]] palette_reload_mask_hi` row in `donovan.toml`; `build_merged.sh` refused on the
op-count fixture (849 vs 848), `test_tenant_loop` measured +1 Donovan only and re-frozen (354 / 636 / 849, PASS); rule 5
reports the row's `only_variant_slot` as one new baked value (a declared growth, M23's precedent). Rule-checker run `2026-11-01-1534` VIOLATED (the row's comment put vs2's mask
at `0x02A106`, copied from the #127 worker's report; listed: it is `0x02A108`, and the two high words differ in bit 0x13 only),
corrected; `-1535` **OK**. Rule 5 re-frozen with the declared growth (221 -> 222) and its ledger row; `test_rule5_census` PASS.
**BUILT** (`build/agent216/mb_m`, scratch, fingerprint `48f729b9`): the opcode view differs from `m3b_merged31` in exactly one
byte, `0x02ADB5`; on BUILT images the five legacy replays are identical every frame (work RAM and OBJ palette), and Donovan
part 4 differs exactly as the opcode-patch counterfactual did (RAM 1691, palette 5365 frames) (`build/agent216/rc127/`).
`docs/project/patch_notes.md` has the 14z-216 entry. **(M)'s gates, written and frozen on `mb_m`** (the maintainer: *"Then do it"*): the new `tests/audit_don_row0b.sh` (tap `tests/lua/pal_rows_tap.lua`, rigs `tests/replays/127_pod_hit.rpl` / `127_pod_nohit.rpl`) requires P1's row 0x0B to equal native vs2 on every frame from 2500 on #127's hit rig, its no-hit control, the 15 Donovan naming parts and donovan_4's column — PASS on `mb_m`, 0 frames; its known-bad leg (vsavj's mask word in the opcode share) differs in R1 206 / R2 124 / R4 26 frames and in 13 of 15 parts, the two parts whose moves never show the defect (donovan_8, donovan_13) frozen as a blind set; the mode fails R1-R4. `audit_column_flash` and `audit_column_flash_cause` changed and RE-FROZEN to "ours = native" (the old shape is now the cause gate's BAD leg; the flash gate's control plants row 10 into row 11 and judges the hash rows alone) — both PASS on `mb_m` against the new expectations, all controls fired, the cause gate's two modes fail as required. Rule-checker `2026-11-01-1536` VIOLATED (the flash control fired on stale rows — fixed), `-1537` VIOLATED (a false claim that the cause gate names the build; the known-bad leg not required per check — fixed), `-1538` **OK**. All three gates expect the (M) build: at the default BUILD (m3b_merged31) they FAIL by design until the freeze re-points them (and `audit_column_flash`'s build row is re-frozen on the registered build). Still to do for (M): the freeze. **#294:** the maintainer, on the recommendation as first summarised: *"indeed if the 6 free bytes exist,
given the cost this seems like the best solution"*; the packet's runs `-1529`..`-1532` each VIOLATED on real gaps (the
dispatcher's head diverts into the state hook on ours, so whether ours reaches the per-frame table was measured: Donovan
enters `0x02ADDC` on all 66 frames of the shock window; every leg re-run with its pokes recorded); `-1533` **OK**; the recommendation re-put to the maintainer for an explicit green light.
Asked *"Do you give the green light, starting with the free-byte search?"*, the maintainer: **"Yes"** (DECISIONS_HISTORY,
"#294: A ... after the dead-byte check"). **The search found six:** vsavj `PRG:0x024024-0x024029`, an orphaned
`moveq #$4b,d0 / bra.w 0x27EC0` tail between the class-0x20 and class-0x21 handlers of the victim reaction dispatch
(`0x2385C`), behind row 0x20's own `bra.w` (the idiom's six other copies are reached by fall-through). Judged DEAD by
the new `tools/audit_dead_span.py` (no instruction at any even address, no long in either view, no table row names a
span byte; fenced by reached code); its gate `tests/test_dead_span.sh` (static tier) passes with four controls fired, each
also failing as a mode. Runtime bound `tests/audit_dead_span_exec.sh` (on demand): 64/64 legacy replays on MAME, 0
executions at the span — weak, the corpus never dispatches rows 0x20/0x21 either; the live-site control (`0x02ADDC`,
597,329) fired. The vs2/vh2 twins sit in the same place but the tool does not prove them dead. Recorded in
`engine_internals.md`. Next for #294: the port itself (vs2 `0x2A316` transcribed with its calls re-pointed, its private
palette-sequence rows, row 0x13 -> `0x024024` -> `jmp` to it), with the rule-checker before the build. **The port, written** (the maintainer: *"Then do it"*): a new generator section `[perframe_hook]` (`tools/gen_donovan_patch.py`) reads vs2 `0x2A316` from the vs2 opcode view at build time (no ROM bytes in the tree), re-points its 26 external references (9 to a local rts, 5 to `jmp 0x2ADC8`, 10 to a PRIVATE sequence entry over vs2's records 0x2D4-0x341 placed in hole B, 2 lea tables copied from vs2's data view), each fixup checked at build, the records checked against vhunt2 (a missing twin fails the build); the body in hole B, `jmp` on the dead span, row 0x13 -> `0x024024`. Manifest `[perframe_hook]` in `donovan.toml`. Static checker `tools/audit_perframe_hook.py` (finds the routine's external references from the SOURCE, compares the built body instruction by instruction; reads `absent` on m31 and `mb_m`). Emulator gate `tests/audit_don_row0c.sh` written (row 0x0C equal native on the electrocute rig `tests/replays/294_don_electrocuted.rpl` and the 15 naming parts; known-bad leg reverts row 0x13 in the opcode share), not yet run. `test_tenant_loop` re-frozen +4 Donovan (358/640/853) with its one-iteration bound made relative (the fixed `< 300` tripped at 303 with the loop iterating); rule 5: the 24 keys classified, the one new baked value re-frozen with a ledger row. `+0x1CA` (the routine's counter) searched with controls: no reached instruction uses it. Record corrections made: `engine_internals.md` (vs2 `0x02A142` twins vsavj `0x02ADEC`, not `0x02A8A4`), `test_don_accent.sh` section 3's comment, the 2026-07-31 premise in DECISIONS_HISTORY (marked, kept). Rule-checker `2026-11-01-1539` VIOLATED (the packet's diffs carried (M)'s edits, the re-freezes stated but not made, the ruling excerpt wrong, `+0x1CA` unscoped, the twin check skippable — all fixed); `-1540` VIOLATED (the `+0x1CA` split leaned on the descent; the dead span unjudged on our image — each candidate placed in a jump table, the span judged DEAD on `mb_m`'s full ranges), `-1541` **OK**. **Built:** `build/agent216/mb_294` (scratch, (M) + #294), fingerprint `0e6f423b`. `tools/audit_perframe_hook.py`: hooked, the body equal to vs2's instruction for instruction, all 26 references on their stubs, records/tables equal; its four plants FAIL. `tests/audit_don_row0c.sh`: row 0x0C = native on every frame of the electrocute rig (reverted leg: 55 differ) and of the 15 parts outside native's Dark Force frames; inside them 1,511 frames differ (parts 3/4/6/7) — cause NOT ESTABLISHED: first attributed to the ruled Dark Force CHANGE never setting `+0x1C3`, RETRACTED (poking `+0x1C3` over native's window left it unchanged, a poke with no positive control; rule-checker `-1543`/`-1544`). The Dark Force look goes to the maintainer (`build/agent216/rc294/sheets/sheet294_df.png`). Blind set frozen (10 parts). The gate PASSES on `mb_294`, both controls fire, both modes fail as required. Rule-checker on the gate's expectation: `-1542` (run 1541 and the dead-span result not in the packet; the CHANGE ruling unquoted), `-1543` (the `+0x1C3` premise unshown — tested: the poke leaves the difference, attribution retracted), `-1544` (the colour split measured on donovan_6 only; R5 without a positive control), `-1545` (the mode log from the previous wording) all VIOLATED and fixed; `-1546` **OK**. `audit_don_row0b` re-run on `mb_294`: PASS ((M) intact). Built-image legacy replays vs `mb_m`: 01 identical; 02/03/07/105 differ on ONE frame (890), 2 bytes `RAM:$FF06CC-CD` = a stacked return address into ported select code moved by 0xDC0 by the new allocations (execution position; for the legacy MAME oracle at the freeze); OBJ palette identical. Capture sheet for the maintainer: `build/agent216/rc294/sheets/sheet294_p1..p3.png`. **The maintainer, on page 3** (first reading the burnt Killshread at f3458 as missing on our build, then seeing the #294 column): *"Also, sheet294_p3 shows a difference in rendering I had missed: the burnt state after electrocution is different in our build because the burnt palette is not applied to killshread in our build apparently"* — then *"oh but you corrected it already, my bad"*. Dark Force colours ticketed as **#344** (*"ticket and attach the capture"*; *"the difference is very small rendering wise and certainly not game breaking, but good catch"*). The body-check static gate wrapper (`tests/test_perframe_hook.sh`) is added at the freeze, when the default build carries the port.
**PILOT** went down at 01:00:13 CET right after a Proxmox `guest-fsfreeze` (the host's backup job, most likely); back at
02:42, its 14z-215 scratch deleted on the maintainer's word (32 GB; disk 86% -> 73%).

### (1b) THE M24 FREEZE — (M) + #294 (the maintainer, 2026-11-01: *"I suggest compacting then freeze"*, *"You can start the freeze"*)
Evidence: `build/agent216/m24/` (local). **Builds** (mark M24; `build_all.sh`): `build/don_m28`, `hui62`, `pyron47`, `m3b_merged32`,
stock `m5_stock23`, stage-4 — programs donovan `167d870f` -> `5ebd4fea`, huitzil/pyron UNCHANGED, merged `6148d0b1` -> `0e6f423b` (=
`mb_294`), stock `a3910ded` and stage-4 `2fa7c2f1` UNCHANGED; ERIS reproduced all six (program, set key, manifest). **Delta** +5 ops on
donovan and merged (body, records, `0x024024`, `0x02AE12`, `0x02ADB4`), the rest relocated pointers (`attribution.txt`,
`site_delta.txt`; the tool's 617 "differing" targets straddle its 8-byte window, `apd_straddle_merged.txt`); byte diff
`tests/expected/freeze_bytediff/merged-m24.txt` (313,332 ranges, every fixed site explained, `bytediff_fixed_review.txt`).
**Registry** donovan-m28 `3beb0d2c` / huitzil-m35 `1fb00f39` / pyron-m29 `c7f6a2cf` / merged-m24 `43505a12`; **sets** frozen on the Mac
and ERIS, 472 files equal; the legacy oracle GREEN (frame 890 inside the frozen select windows). **Sweep** 412 lines (16 rewritten
dated records restored — a gotcha); `test_m3a_reproducible`, charmaps, MiSTer tail (fork `8d527341`, patch 0040), `release/merged-m24`.
**Battery** ERIS `--freeze` on snapshot S1: 26 FAIL, 4 SKIP, every red read — relocated placed addresses/PCs, build rows, the hitbox
base table (Phobos `0x45B6F0`, Pyron `0x4AF86C`), the 40,620-frame arcade leg's clock and counts (110_don_arcade_mash, the only replay
whose defense reads changed), Donovan's move parity moving TOWARD native (32 events DIFF -> IDENT under the 0000 pin), #294's two
+0x1C3 reads. **Real findings fixed**: the three 14z-216 rigs sat in the suite's legacy corpus (moved to `tests/replays/don/`);
`audit_don_row0b`'s native legs CROSS-FLAVOR (two `audit_latch_reads` legs: no reader fires; accepted); three gates missing from
`ci_emulator.tsv`; `audit_tenant_cpu_ai`'s seven hard-coded placed PCs; `audit_column_flash_cause`'s C1 fixed string (now ours =
native leg); 14z-215's mode-only last-bar controls in `audit_edge_cases`/`audit_tenant_downwin` (now in-gate). **Rulings**: #294's
lag frame accepted (`audit_lag_budget` ACCEPTED list); #345's rows exempt in `audit_rng_forms`, 0000 kept. **Re-frozen** on ERIS
at snapshot S2 and verified by a second whole battery (`s2_results.tsv`: 2 FAIL re-frozen since, 4 SKIP host-covered — Mac
`test_release_binaries`/`test_readme_recording`, PILOT `audit_release_linux_cleanhost` PASS); the Mac MiSTer lane PASS 2 +
`test_mister_prg_window` re-frozen from its legs. **Tickets** #345 (Blizzard Sword overrun, the maintainer confirmed it on the
sheets), #346 (the ice streak, cosmetic); sheets `build/agent216/s345/`. **The re-freeze rule-checker** (packet `build/agent216/m24/rc_refreeze/`): runs `-1550` (VIOLATED Q1-Q5), `-1551` (Q1 Q2 Q4),
`-1552` (Q1) — each resolved (the clean-host gate re-run on merged-m24 itself, `rng_forms` verified fresh, the release binaries
re-run on PILOT's linux-x86_64, `audit_column_flash_cause`'s in-gate control fixed, `audit_lag_budget`'s accepted frame tied to
`pass_overrun.tsv`'s native row with a new control `native-basis-moved`, the maintainer's re-confirmation on the captures: *"Still
accepted but as a tradeoff. #345 is there to fix it later"*, the attribution window shown); `-1553` (Q1 Q4: `rule5_baked`'s growth note re-frozen for both rows, 251 -> 253; the defense-row attribution over all 97
replays with a planted-change control) — resolved; **`-1554` OK** (the plant caught). **Remote state**: ERIS's checkout
at S2 `6263d617` plus the re-frozen files (copied to the Mac); PILOT at S2 with merged-m24's linux-x86_64 binaries copied in and a
SCRATCH tag `freeze/merged-m24` on its checkout only. **Since the S3 tier** (all evidence `build/agent216/m24/`):
`audit_release_linux_desktop` on PILOT first read the mark absent on both emulators with FBNeo paused — the gate's driver
focused the window's FRAME (`mutter-x11-frames`), which since mutter `.18` (PILOT 2026-10-20, loaded by the 02:42 reboot)
takes focus from the game; `tools/desktop_session_play.py` now targets the client window (gotcha in
`docs/platform/gotchas.md`), and the gate PASSes on merged-m24 (mark 0/147 both, sound -30.0/-29.8 dBFS), its three CONTROL=
modes failing (`rc_freeze/desktop/`). **The S3 static freeze tier**: PASS 227 FAIL 10 — fixed: the five new gates frozen in
the description/follows censuses and three FOLLOWS widened, coverage and index pages regenerated, two unguarded `mktemp`,
`test_phasea_a3_liveness` (latent since 14z-212: its copy's REPO lost `tests/lib/jobs.sh`), `test_checkdocs_rom`'s
denominator 394 -> 407 (the 13 addresses of this session's #128 paragraph, `denominator_diff.txt`); waiting:
`test_rule_checker` (the freeze run), `test_controls_concurrent` (both lists re-traced on PILOT by a fork — the maintainer:
*"Re-trace all 45 (Recommended)"*), `test_emulator_staleness` (the battery records brought to the Mac). **Snapshot S4**
`d1aed6a8`: Mac `test_mame_parity` GREEN (`build/emu_m24_parity_s4`); ERIS `--stale --freeze --scope all` (the 22 NOTE-class
instruments `--skip`ped: the runner's `--stale` names them at the audit's default cadence and refuses — a ticket to file)
PASS 29 SKIP 4 FAIL 1 (`build/emu_e216s4`); the red, `audit_ladder_selector`, was M24's timeline shift (match 2's selection
960 frames earlier) moving its frame-pinned saturation window past the selection — window moved 7100-7290 -> 6140-6330,
PASS on merged-m24 with merged-m23's original reading. **Open, in order**: the Mac's runner rows on S4 for
`test_release_binaries`, `test_readme_recording`, `test_mister_prg_window` (running); PILOT's runner rows for the desktop and
clean-host gates after the trace; the freeze rule-checker run; snapshot S5 and the static freeze tier on it; commit; re-cut
the four tags; comments on #127/#162/#294. #344, #345, #346 stay open. #338's publisher: `BatchMode=yes` dropped and
`--dry-run` passed through (the maintainer, 14z-216: "That's fine by me"; DEPLOY_TARGET is their site deploy's).

### (2) #310 — THE CRASH-INJECTION SWEEP, DISCOVERY
A python3/sh shim crashes the commands a mode runs (a 30-frame Python stack; a syntax error in an untracked shell copy, a
tracked file never edited), each plant on the gate as it stands and on a copy with `vs_ctl_show_err` neutered; the 47 helper
call sites tagged. Discovery over the 20 static gates (`build/agent216/t310/`, local; the runner gates on PILOT): every runner
mode PROVEN but one LIES; first finding F1, `test_agent_hooks`' twins read a copy that could not be made as FIRED and the
plain run PASSes (`build/agent216/t310/FINDINGS.md`). Two defects of the session's own rig caught and fixed: a shell shim
resolving only a symlink's directory (would have written through a mirror's link into a tracked script; nothing was
written) and a relative shim dir on PATH. The gate is not built yet.

# STANDING SECTIONS (current state — never archived)
## Standing rulings


One line per ruling that still constrains work: the rule and where its full entry lives. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]). Shortened to the rule plus its pointer 2026-10-14 (#282 item A); the longer lines are in git history at `44a09f7f`.

- **#345's rows may turn DIFF under a non-zero RNG; the parity gates keep the 0000 pin (2026-11-01, 14z-216):** `tools/rng_forms.py` exempts rows `after:` a SLOWDOWN root, by name — `DECISIONS_HISTORY.md` "Ruled 2026-11-01 (14z-216) — #345's rows under a non-zero RNG".
- **A new zero-pass frame native vs2 has too is accepted, frame by frame (2026-11-01, 14z-216, #294):** `audit_lag_budget`'s ACCEPTED list (today donovan_2:3094, vs2's 3098, checked against `pass_overrun.tsv`'s native row), re-confirmed on the captures as *"a tradeoff. #345 is there to fix it later"*; the no-new-lag rule stands for every other frame — `DECISIONS_HISTORY.md` "Ruled 2026-11-01 (14z-216) — #294's lag frame" and "…re-confirmed on the captures".
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
