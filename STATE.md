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
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body in newest-first order (below THE LEDGER, above the first
  archived `## Session` heading OLDER than the group)
  and add their one-line entries at the top of THE LEDGER there, composed from
  the group's own banner headers. If this file still exceeds ~150 KB, roll the
  oldest kept group early. The standing sections never roll.
- **THE LAST STEP OF THE CLOSE IS THE PUSH (maintainer-ruled 2026-09-10):**
  static tier strict green WITH every control executed (the default `all`), the doc checks green, nothing pending -> `git push
  origin main`; anything red or skipped leaves the commits local and the
  close entry says so.

## Session 14z-160 — **OPENED ON #151 IN THE MAINTAINER'S ORDER; #136 PUT BACK ON THE LIST FOR A FULL RE-EXAMINATION AT THE MAINTAINER'S INSISTENCE (Pyron and Phobos above all), AND ITS INDEX ROW CORRECTED FROM `parked` TO `open`.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION — at `docs/NEXT_SESSION.md`), `main` 4 ahead of `origin/main` at `d9330729` (the 14z-159 close's commits, local because its close tier with every control executed never ran), bbh clean at `13ff687`, `emu/fbneo` dirty by exactly the two tracked patches (780 changed lines = 680 + 100), nothing running; ROM audit **76/76**. The maintainer, on the proposed order #151 -> #147 -> #149 -> #152 -> #150/#148: *"I agree with the order but I also must insist on going over #136 again in the todo list at some point because too many things especially with Pyron and Phobos could be wrong in it"* |
| **(1) THE #136 RE-EXAMINATION MADE AN EXPLICIT ITEM** | recorded as a ruling (`DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-160)", a "Standing rulings" line, comments on #151 and #136). Found on the way: #136's index row still read `parked` and its issue carried no word of 14z-159, which built its apparatus and measured 117 of 145 moves on it — the list and the story were both behind the tree. Row set to `open`; the 14z-159 work and its caveat stated on the issue |

## Session 14z-159 — **#136 OPENED FOR REAL (117 of 145 tenant moves measured against native, the gate committed) — THEN THE M19 FREEZE BUILT ON #147 AND WITHDRAWN IN FULL: the fix was a regression, its measurement a FORCED-PICK RIG ARTIFACT, and the maintainer's field report is what caught it.
## The durable output is the #136 apparatus, four tickets and three gotchas; no shipped ROM byte moved and the tree ends at merged-m18.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION — at `docs/NEXT_SESSION.md`), `main` 1 ahead of `origin/main` at `842433f3`, bbh clean, ROM audit **76/76**. The maintainer: *"#136"* |
| **(1) #136 — THE TENANT-MOVE RIGS RUN ON A PORT BUILD FOR THE FIRST TIME** (`fd3f164b`) | `tools/name_moves.py` already performs all 145 moves on the tenants' NATIVE game (635 events, 42 legs) and nothing had ever run them on ours. Built `tools/move_parity.py` + `tests/audit_move_parity.sh` (emulator tier, registered both ways, 27 parts frozen in `tests/expected/move_parity.tsv`, two must-fire controls firing in-gate and reaching FAIL as modes, 25 s default / 130 s ALL, frozen-then-VERIFIED). The protocol took three iterations, each failure measured: the speed level must be pinned BEFORE the match anchor (#135), the RNG only FROM it (pinned through char load our Donovan leg produced 377 live frames against 4568), and the window starts at the rig's first event because the intro variant is an RNG draw. Measured: **117/145 frame-identical**, 12 diverging, 15 unknown — later corrected to 118/12/15 (a divergence landing on its event frame mis-attributed the culprit). Damage and meter EXACT on Donovan's hit rigs, hitboxes EXACT over 3,021 frames, projectiles exact on 3 of 6 parts. **Two of three divergence families turned out to be the maintainer's own rulings** (the DF stock cost 14z-120, the defense-row swap 14z-085f), found by archaeology before being reported as defects |
| **(2) #149 — FAMILY A ROOT-CAUSED** | ~11 of Phobos's specials skip a 2-frame `seq 4 sub 4` state (node `0x245eca`) native plays; a PC-attributed tap on `RAM:$FF8406` names `PRG:0x026344` as the writer with no counterpart on ours. Candidate cause kept SEPARATE from the measurement ([VSP-116]): the reconciliation twin `vs2 0x026252` -> `vsavj 0x02706e`, marked `verified`, diverges structurally at its 7th instruction. Ruled: measurements first, no scoping |
| **(3) #147 — THE FIX THAT WAS A REGRESSION, AND THE FREEZE WITHDRAWN** | Phobos's flavor latch `RAM:$FF87C2` read 0x01 on the "native" leg and 0x00 on ours; poking ours to 0x01 took his part-1 rig to 6851/6851 frames identical. Every consumer was enumerated in all addressing forms (pristine `vsavj`: ZERO), the blast radius ran 17 gates (15 PASS, 2 investigated to root cause), and the M19 freeze was assembled: five tracks + stage-4 rebuilt, four registry rows, four expectation sets carried-frozen-verified, `test_m3a_reproducible` re-pointed with every delta named, a 116-file re-point sweep, patch_notes, HANDOFF, four set READMEs. **Then the maintainer played it:** *"phobos floats for a certain time, you can't move… In VS2 he jumps without floating"* — the VH2 mechanic. **THE MEASUREMENT WAS A RIG ARTIFACT:** the flavor latch is written at select CONFIRM (`PRG:0x01F87E`, frame 1299) and the forced-pick poke replaces the character id at 1400-1500, AFTER it, so the "native" leg was a legacy character's confirm wearing Phobos's id — and because BOTH legs used the poke, the comparison agreed with itself perfectly while anchored to nothing. `engine_internals`' own *"flavor 1: any-up pins the hover"* had said so and I overrode it. **Ruled: withdraw the freeze entirely.** Tree restored to merged-m18, `flavor_default` back to 0x00, 14z-66's note reinstated, bbh reverted, `test_bbh_fidelity` PASS |
| **(4) WHAT THE FAILURE COST, AND WHAT GUARDS IT NOW** | #151 filed at the maintainer's direction — *"if we had a failure in the discipline and guardrails, we can't be sure we've had only this one issue"*: Donovan's native leg is a REAL cursor pick, Phobos's and Pyron's are POKED, and `audit_move_parity` has controls proving it sees the level and the translation but **none proving its native leg is faithful**. So 17 of its 27 verdicts are UNVALIDATED — marked as such in the gate header and in the expectation file rather than left implying more than they measured. The missing control (poked vs real-cursor, diffed over the WHOLE fighter block) and a sweep of every other forced-pick gate are #151's work |
| **TRAPS PAID** | a `pgrep -f` waiter matched the creating shell's own command line and sat **4 h 12 min** running zero gates, and I reported it as progressing twice from an empty log — the rule is now "never wait on pgrep; prove liveness before reporting"; a re-point sweep needed three passes (a `break` after the first match per line, then space-separated lists) and damaged one file by appending a comment after a line-continuation backslash ([VSP-177]); the [VSP-13] retraction grep searched WORDING and missed `test_manifest_merge`, which encoded the retracted claim as a literal value pair; a freeze driver without `MAME_BIN` booted Homebrew's MAME on all eight passes; the merged expectation set's 16 self-frozen tenant `.sha1` must be deleted at every freeze and nothing enforces it |
| **CLOSE (2026-09-16)** | this sitting's only commit is `fd3f164b` (the #136 apparatus, measured on merged-m18 and unaffected by the withdrawal) plus this close. Tickets filed: **#148** (static-tier cost), **#149** (Phobos's seq-4 startup state), **#150** (the freeze ritual's three silent-green failure modes), **#151** (the #136 re-examination); #147 retracted in full and left OPEN with its premise void. Gotchas: the `MAME_BIN`-less freeze driver, the merged `.sha1` deletion, the forced-pick native leg. **NO FREEZE, NO RELEASE, no shipped ROM byte moved.** |

## Session 14z-158 — **THE README'S RECORDING COMMAND GATED; #135 FOUND — THE EXTRA LOGIC PASS IS THE PLAY MODE'S SPEED LEVEL, AND vsav2 DEFAULTS P1 TO TURBO; #114's "LP ONE HIT SHORT" WAS THAT MODE AND #142's EXTRA HIT THE RNG;
## THE IMMORTAL GATE RE-RULED TO A PINNED LEVEL AND RNG (count, damage AND hit frames, 16/16), [VSE-84] REWRITTEN, #135 AND #142 CLOSED, THE STACK-READ INSTRUMENT DEFECT FIXED. No shipped ROM byte moved.**

| | |
|---|---|
| opened with | the opener read (HANDOFF, STATE, NEXT_SESSION — at `docs/NEXT_SESSION.md`), `main` == `origin/main` at `18c751b9`, bbh at `13ff687`, nothing running; ROM audit **76/76**. The maintainer: *"README details … done on my end, don't know for your end"*, then *"Then #135"* |
| **(1) THE README ITEM, MY END** (`bd3ed4b0`) | the maintainer's half (`e09bef2e`, `30020ac7`) applied 8 of the 9 readability proposals, the `###` lines kept by choice. The gate half had never been written: `tests/test_readme_recording.sh` reads README.md's `cps2 vsavjw … -record` line, checks its prose against it (the two empty folders, the attachment, apply_release's `--out`) and runs it token for token on this host's release MAME; the session plays back frame for frame on the release and the source-built binaries from an empty nvram (5,320 frames of work RAM identical), liveness (no playback departs at frame 300), must-fire `used-nvram` (departs at frame 73) and `truncated-inp` (MAME plays 2,661 frames), both modes exit 1, an undeclared name REFUSED. Found on the way: MAME reads the user's own `mame.ini` even under `-homepath` (a platform gotcha; the gate passes `-noreadconfig`, the wrappers do not) |
| **(2) #135 — THE DECIDER, STEPS 1-3** | a write tap on the node timer with both stack pointers logged named the call chain: the tick routine is tail-called by state handlers under the object loop (vsavj `PRG:0x02207E`), called once per pass from the game task's loop (`0x008E0C..0x008E30`). Its `$8E32` requests an extra pass when `$FF812D` is set and bit ((`$FF8081` + 1) & 31) of the level's pattern is 1, and `$8EB2` skips the frame sleep while one is pending. The level `$FF8116` comes from the play-mode menu after character select (NORMAL / TURBO / AUTO / AUTO&TURBO, seen on captures): factory NORMAL = 6 on both games, TURBO 7 on vsavj and 8 on vs2, and **vsav2 sets P1's cursor to TURBO at confirm where vsavj sets NORMAL**. Measured: the prediction matches every frame on both games; vsavj forced to level 8 ticks exactly as vs2 (130/63, 134/65 single/double-tick frames), vs2 with P1's cursor forced to NORMAL writes 6 itself and ticks exactly as vsavj (149/43, 153/45), turbo off leaves no double tick, and at matched levels the vanilla freeze drains in the same frames |
| **(3) #114 AND #142, RULED TWICE** | at matched modes LP at the ceiling equals native and §4's "+1 frame" vanishes, but MP with no mash at level 6 read 5 hits ours, 4 native. Ruled *"Matched modes, both"* and *"Ticket + root-cause"* (#142 filed). Root-caused the same sitting: the object loop picks P1-first or P2-first from RNG bit 0 (`$FF80D4-D5`), the games' RNG states differ on every frame (vanilla included), and on the pass after MP's fourth hit the order differed, so ours' attacker freeze lasted one pass longer. With level and RNG pinned: 16/16 legs identical in count, damage and every hit frame. Ruled *"Pin both, assert frames"* and *"Close as invalid"*. `tests/test_don_immortal_native.sh` rewritten: 40 legs, both pins proven from each leg's dumps, must-fire `jedah-artefact`, `unmatched-modes`, `unpinned-rng` — PASS 232 s, each mode exit 1 on the gate's own FAIL. At the close the `unpinned-rng` control's evidence grew a write tap that re-measures #142's order every run (native's attacker freeze written 3, 4, 3 on the frame after the fourth hit, ours 3, 2, 4). #135 (done) and #142 (invalid) closed with their comments, and a note on #114 |
| **(4) THE RETRACTION PASS** (`6d9e8450`) | [VSE-84] rewritten ("a cross-game comparison needs a matched play mode and a pinned RNG"; the old text kept, struck) with its skill line; engine_internals' play-mode and RNG paragraphs above the retracted one, the 14z-156 addendum relabelled, the FG-pacing gloss corrected; [VSE-85], [VSP-136] and [VSP-169] corrected in doc and skill; `test_don_reactions.sh`, `capture_sheet.sh`, `gate_scoping_method.md`, `coverage_matrix.md`, HANDOFF's capture-sheet row, `patch_notes.md` (marked in place), the project double-tick gotcha; ram.md rows `$FF8081 $FF8116 $FF8118 $FF812D $FF8134 $FF80A3 $FF8407`; the doc-anchor census re-frozen; #114 and #136 relinked; the standing ruling line rewritten; `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-158)". NOT CHANGED: `README.md`, the maintainer's file — its line 85 still says the tenants "tick on Vampire Savior's engine clock" |
| **(5) CAPTURED, AND AN INSTRUMENT FIXED** (`6d9e8450`) | `tests/audit_tick_cadence.sh` section C (16 legs: the decider, the pattern and level tables and the cursor defaults statically; the every-frame prediction; the stack chain through the game-task loop on the live user stack; the play-mode writes; the causal pairs with the RNG pinned), must-fire `frame-counter-decider` (65 and 85 of 200 frames mispredict) and `supervisor-stack` (the loop on none of 243 and 264 writes) added — PASS 90 s, all three modes exit 1. The defect: MAME 0.288's M68000 has no `A7` state and its `SP` is the supervisor stack while this game's logic runs in user mode, so `tap_writes.lua`'s `STACKLOG` and `bp_regs.lua` walked the idle stack (the 14z-85g "garbage ret"); both now read the live pointer (a platform gotcha). `walker_sp.lua` NOT changed: two walker audits consume it — NEXT_SESSION asks whether to ticket it |
| **(6) AFTER THE CLOSE (14z-158b, 2026-09-16)** | the maintainer, on the close report: #143 — *"yes but we probably want to be cautious when solving it"* (filed measure-first; `DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-158b)"); README.md — they committed their edit (`0df98b1b`), and line 85's retracted engine-clock sentence was then corrected to the measured facts (NORMAL the same speed as vsav2, TURBO one level slower at factory settings, vsav2 starting P1's menu on TURBO, 421+P equal at a matched speed and RNG). AND A FALSE CLAIM OF MINE: the close report told the maintainer their "Phobos (Huitzil outside Japan)" was wrong because "Huitzil is the Japanese name" — asserted from memory, never measured. One capture of vsav2 (Japan, id `0x10` forced both sides) shows **Phobos** on the select screen and the HUD: their text was right. Retracted in NEXT_SESSION, where the close had written it (the close commit's message keeps it; commits are not rewritten). The maintainer: *"we measure when we don't know, we measure to check when we're unsure, and that blind certainty is a marker of failure"* |
| **TRAPS PAID** | the first probe died silently inside a write tap on `st["A7"]` (710 hits, 0 lines); a 1-byte write tap on the 16-bit bus aborted a run before its first frame; a probe script set `ROMDIR` without exporting it; I labelled the object loop's first call the "reducer call" — its four calls are two player orders, and the RNG picks between them; the truncation control's first replay (inputs ending at frame 1362) reproduced every checksum from half a recording; I rewrote the immortal gate before loading the project's skills, which carried three more rule lines restating the retracted claim; a retraction grep left the FG-pacing gloss until a second pass |
| **CLOSE (2026-09-15)** | the close tier, every control executed, after every edit of this close (`build/gates_14z158/static_close.log`, started 23:12:27, wall 2,348 s): **PASS 154 / SKIP 0 / FAIL 0 / MISSING 0**, `fired 172 / declared 172`, `executed 172 honoured 172 lies 0 refused 0 died 0`, no tracked file changed during the run; this row was written after the tier. The mid-session tier (`static_mid2.log`) went 152 / 0 / 2 on two stale generated indexes (GOTCHAS.md, annotations.md), regenerated and their gates re-run before `6d9e8450`. The immortal gate PASS 240 s with its order tap, its three modes exit 1 on the gate's own FAIL (237 / 236 / 237 s); the tick audit PASS 90 s, its three modes exit 1. GitHub: #135 closed done, #142 closed invalid, each with its closing comment, and a note on #114; the ticket snapshot refreshed. STATE rolled: the 14z-155 group to the archive with its ledger line; NEXT_SESSION archived and rewritten. `README.md` carries the maintainer's own uncommitted edit and is in no commit of this sitting. This sitting's commits: `bd3ed4b0`, `6d9e8450` and this close; bbh untouched. **The close ends with a push** ([VSP-17]): `main`. **AND AFTER (14z-158b, 2026-09-16):** the continuation's own close tier, every control executed (`build/gates_14z158/static_close3.log`, started 00:20:33, wall 2,361 s): **PASS 154 / SKIP 0 / FAIL 0 / MISSING 0**, `fired 172 / declared 172`, `executed 172 honoured 172 lies 0 refused 0 died 0`, no tracked file changed during the run — an earlier run of it was STOPPED at 56 gates to take the measurement-rule edit and its result discarded. Its commits: the maintainer's `0df98b1b` (README) and the 14z-158b commit; pushed. Filed and not yet rowed at that push: #144, #145, #146, the maintainer's release-deliverable reports (macOS binaries blocked, Windows binaries not loading the game, the player READMEs thin) |

---

# STANDING SECTIONS (current state — never archived)
## Standing rulings

One line per ruling that still constrains work; the full entry lives where the line says. A line is deleted when its ruling stops constraining work (CLAUDE.md [VSP-17]).

- **#136 is gone over again IN FULL, not only through its faithfulness control (2026-09-16):** the maintainer insists it stays on the list until every part of it — the naming rigs, the pinning protocol, the 27 frozen verdicts, and the Pyron and Phobos legs above all — has been re-examined; no #136 verdict is built on until then. Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-160)".
- **The M19 freeze is WITHDRAWN (2026-09-16):** #147's fix was a regression on a rig artifact; the tree is back at merged-m18 and #151 re-examines #136's forced-pick native legs. No freeze is current beyond merged-m18. Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-159)".
- **#149 waits for its measurements (2026-09-16):** no scoping or thunk design for Phobos's skipped seq-4 startup state until the ticket's own measurement runs; the reconciliation twin-pair difference stays a CANDIDATE cause. Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-16 (14z-159)".
- **Static-tier controls at the CLOSE (2026-09-14):** a mid-session commit runs `tests/run_all_static.sh --strict --exec-controls none` plus `CONTROL=<name>` for every gate it adds or changes; the session close runs every control (the default). Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-14 (14z-154)".
- **Release scope (2026-09-02):** at release every test whose SUBJECT is the released artifact runs, its legacy content included (a reference leg on vsav2 or pristine vsavj is not the subject); anything red or skipped is a hard fail unless approved at release time, so a release-scope gate fails loudly on a missing prerequisite. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **A red gate is a question (2026-09-02):** before fixing the gate, fixing what it caught or deleting it, establish which side's expectation rests on a measurement; a frozen number whose provenance cannot be named is a claim. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Cross-game comparisons at a matched speed level and a pinned RNG (2026-09-15, #135, #142; amends the 2026-09-02 #114 line):** vsav2 defaults P1 to TURBO and vsavj to NORMAL, and the two games' RNG states differ, so `tests/test_don_immortal_native.sh` pins `RAM:$FF8116` (levels 6 and 8) and `RAM:$FF80D4-D5` on both legs and asserts ours == native in hit count, damage and hit frames; LP's accepted "one hit short" is retracted as a mode artifact and #142 is closed invalid; the 2026-09-02 ruling that the vanilla vsav engine takes precedence stands. Full entries: `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-158)" and "Moved 2026-09-14 (14z-154)".
- **No static substituted-wheel gate (2026-09-02):** declined — the pattern matches 26 legitimate gates; the defence is [VSP-163] (assert `+0x60` against `bases.tsv`, or force the pick). Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Oboro's intro stays (2026-08-28):** never delay round start or cut the intro for a cosmetic reason. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Community data (2026-08-31):** measurement is king — a community source that matches ours exactly or by a constant offset validates our measurement, and an inconsistent pattern means re-check OUR measurement first. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Cosmetic is optional (2026-08-27):** cosmetic and single-player-only surfaces are nice-to-have; competitive 2P versus is the focus. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **No legacy character meets a tenant in 1P arcade (2026-08-28):** not a problem, 2P versus is the focus; not built, not scoped. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **The living-docs generalisation, when scheduled (2026-09-08, #119):** independent of bbh but compatible with it and on the same principles; the site generator in scope; fidelity required in principle, its form argued in the scope document; the open items first. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Linux release binaries (2026-09-13, #121):** self-containment is checked against an external host-provided list plus the ruled exceptions; the WSL2 Linux binaries are never published. Full entry: `DECISIONS_HISTORY.md` "Moved 2026-09-14 (14z-154)".
- **Generator refactor policy (2026-08-21, #50):** no dedicated refactor of `tools/gen_donovan_patch.py`'s `main()` is ever scheduled absent a new measured cost; a handler moves to module level only when a test needs to drive it, with its unit test in the same change, and byte-identity under `tests/test_m3a_reproducible.sh` and `tests/test_phasec_spaces.sh` is the refactor gate. Full entry: `STATE_HISTORY.md` "Session 14z-102 (post-freeze rulings)".
- **Don't assume; measure first; ask if necessary (2026-09-15, clarified 2026-09-16):** no factual claim — about code, a count, a behaviour or a name — is stated without a measurement or a tree source behind it; a question a measurement can settle is measured first and never published as "unreconciled"; asking the maintainer is right when a measurement cannot settle it or is not enough. Full entries: `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)" and "Ruled 2026-09-16 (14z-158b)".
- **Pipeline-image registry rows (2026-09-15, #96):** the M2 battery dispatches through `tests/expected/registry.tsv` on the build's fingerprint, never a pinned set name; `donovan-mN-stock` / `-stage4` register its two pipeline images (untagged, never shipped); each freeze rebuilds both and records whether they moved, and an unregistered fingerprint is a rule-6 stop. Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)".
- **The merged set carries no tenant expectations (2026-09-15, #111; the 14z-133b B2 design):** the merged expectation set holds the legacy classes, the mask and the `.skip` markers; tenant-content `.sha1` expectations live in the solo sets, and the merged build's tenant content is covered by `audit_merged_legacy` leg (b) and the tenant gates. Full entry: `DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)".

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
commit that records it (CLAUDE.md [VSP-17]). *None open.*

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. ~~OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89"~~ **ANSWERED 14z-91: the counter was REMOVED** — the `beam_list_type6` `RAM:$FF010C` counter deleted, which cleared all six `.pending` legacy replays (`HANDOFF.md` Build registry, the 14z-91 row (C)) |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.
