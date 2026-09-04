# STATE — living progress log

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
  A reference to `STATE "Decisions pending"` for an entry no longer here
  resolves in `DECISIONS_HISTORY.md` (entries move there verbatim once
  ruled and no longer shaping work — 14z-109 cleanup).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to STATE_HISTORY; entries within them are marked DECIDED/FIXED
  in place, as always. **DECISIONS have their own archive since 14z-109:
  once a ruled decision stops shaping active work, its entry moves
  VERBATIM to `DECISIONS_HISTORY.md`** (grep there by topic; the §5
  retraction grep covers it).

## Session 14z-132 — **THE RELEASE WINDOW OPENED, AND THE MAINTAINER RULED FOUR
## TIMES.** The version-numbering mess named and fixed at its root (the wheel mark is
## the merged build number, M16, and a gate will hold it there); the M16 tracks built and
## measured at a two-member delta; and the merged-vs-solo test-scoping question opened,
## given a general rule that is now [VSP-175], and walked two gates deep — where it hit a
## structural blocker and turned into a dispatch-key decision. **No gate re-pointed yet;
## M16 not registered.** Static 128/0/2 (both reds owed by the registration).

| | |
|---|---|
| opened with | the maintainer's four questions: field-test scope, what is left before release, "can we make the versioning easier", and what the solo builds are for |
| **the versioning mess, measured** | the wheel mark started EQUAL to the merged build number at merged-m6 and drifted by exactly the two freezes where it was not bumped (m7 kept M6, m10 kept M8). Today: build `merged-m15`, wheel `M13`, session `14z-130`, milestone namespace `M0..M12` — four numbers, two of them colliding. **RULED: option (A)** — the mark IS the merged build number, plus a gate. The conditional the maintainer attached answered itself: changing the mark changes the glyph tiles, which changes the artifact, so the bump is forced. **Landing: merged-m16 / wheel M16** |
| **and a fifth number nobody had named** | the build DIRECTORY counter, with four different offsets from the freeze name — donovan +0, merged +7, pyron +17, huitzil +27 (verified over six freezes). Not renamed (55 gates reference the paths); recorded so the "generation N" option has its evidence |
| **M16 built and measured** | five tracks. Delta is **exactly two members** (`vsw.33m`, `vsw.37m`) on each of the four WIDE tracks and **ZERO on the stock twin** — the standing prediction from `gen_donovan_patch.py:4999` (version_text is skipped when bank5 is inactive), confirmed by rebuild rather than asserted. `test_version_string` PASS on all four WIDE tracks incl. a pixel-exact snapshot and both verdict controls |
| **every program fingerprint UNCHANGED** | `8065bc92` / `08944a7e` / `a43da974` / `f42f7569` — the documented gfx blind spot. So M16's registration would have needed a FOURTH comment-out, and `build/don_m20` today resolves silently as `donovan-m19` |
| **the maintainer's core belief, and it was already measured** | *"regardless of how low the odds ... these odds are not zero, so the test is brittle intrinsically ... unless they are specific to solo builds, tests on solo builds ... should be run but on the merged build."* The premise is not a prior: `tests/expected/merged1/` exists BECAUSE merged deviated from the single-tenant builds in eight places at 14z-91 |
| **the general rule, ruled CORRECT** | [VSP-175]: a gate is solo-specific only if a single-tenant build is the SUBJECT of its assertion; a reference leg, fixture or rig convenience does not qualify. Consequences ruled the same day: solo-specific => OUT of release scope; no meaningful merged form => deprecate permanently, keep as history |
| the inventory | of 142 release-scope emulator gates: **46 merged, 25 solo-only, 3 both, 36 other build, 31 no build reference** (bound: static read of defaults + hard-wired assignments; the 31 are unopened). One correction found on the way — `audit_walker_repoint` looks solo but its `ci_emulator.tsv` row supplies `%MERGED%` |
| **gate 1 — `test_dualtrack`** | RULED stock vs merged. **And my framing of it was wrong**: I called its stock leg "solo-specific"; the stock twin is the REFERENCE LEG, which the release-scope discriminator already excludes from being the subject. Corrected in [VSP-175] as the worked instance |
| **gate 2 — `audit_legacy_pairings`, and it is not a re-point** | it resolves its expectation SET by fingerprint and hard-fails `FAIL: <dir> has no registry row`; the merged build deliberately has none. Exactly 3 of the 25 do this, all of them the legacy-oracle group |
| **so the walk turned into a dispatch-key decision** | measured: program key collapses `build/merged1`, merged-m15 and merged-m16 onto ONE value (`f42f7569`); `--full` separates all three. **(i) approved, then found NOT EXECUTABLE as stated** — only 20 of 58 live registry rows are recomputable, the other 38 having been pruned under the N-2 policy. **RULED instead: forward-only promotion, merged rows full-set-keyed ONLY** (so the fallback can never reach one) |
| **and a measurement that nearly shipped a bad key** | `--full` is ROMPATH-CHAIN DEPENDENT: `m3b_merged23/rompath` -> `fcc83fc3`, `...;../ROMS` -> `544990c4`. Callers pass both forms. The key must be defined over the build's OWN rompath only — the rule `artifact_manifest.py` already enforces for the same reason. Cost measured and irrelevant: 0.10 s -> 0.35 s |
| my own errors, corrected in-session | the `test_dualtrack` misclassification (caught by applying the maintainer's own discriminator); proposing "recompute the registry" without checking that the builds still exist (38 do not) |
| written down | two gotchas (the gfx-only-freeze key collision; the `--full` chain dependence), [VSP-175] + section 9 of `gate_scoping_method.md`, and the skill rule. Doc-touch checklist all green |

## Session 14z-131 — **THE MAINTAINER CHALLENGED A GATE AND WAS RIGHT THREE TIMES
## RUNNING.** Two rulings executed (Pyron measured, `test_phasec_image` §4 re-targeted
## and green), then Phobos's three historically-corrected throws MEASURED AGAINST NATIVE
## VS2 and found MATCHING — but only after captures refuted my own description of the
## first result, a set-comparison was replaced by an ordered one, and widening to all 18
## victims exposed a frozen constant as victim-specific. **The method is now a document.**
## No build byte moved; static 130/0/0/0.

| | |
|---|---|
| opened with | the two decisions the maintainer ruled overnight |
| **§4 re-targeted, and it WORKED** | the dead control (zeroing `CPU:$400010`, which has held Donovan's AI script since 14z-111, in a replay where he is the PLAYER) replaced by zeroing the capture-keyframe blob's victim-offset head: the hold collapses from NINE distinct offsets to `(0,0)`, **47 of 47 held frames move**. `test_phasec_image` green for the first time since 14z-110 — §1's stock pin (`ae701ffb`, four ruled twin-moves stale) now resolves from `registry.tsv` |
| **Pyron measured, then the story withdrawn** | zero-overlap hold offsets vs native, confirmed statically AND in-emulator. Then the maintainer demanded captures: they confirmed the FINDING and refuted my SENTENCE ("~130 px overhead") — raw dy/dx signs read as up/behind without ever fixing the screen convention. Then the victim's POSE was found to differ too, which the positioner CANNOT cause. **Mechanism withdrawn, port recommendation withdrawn**; ruled a keep-as-regression-marker |
| **the redirect that mattered** | *"Pyron as thrower I don't really care about... but there are throws that have been historically problematic with the VS2 tenants as THROWERS: Phobos'."* Correct target, and the observable he named — position, not sprite — is exactly what the rig measures |
| **PHOBOS'S THREE THROWS MATCH** | standard 6+HP, Circuit Scrapper, ES — **18/18 victims traverse the SAME states in the SAME order** on all three; damage identical in amount and in the POSE it lands at; arcs identical for every victim. The ES rig needed METER or it degrades SILENTLY to the MP grab (measured: byte-identical numbers to replay 80) |
| **a nine-session-old claim refuted** | replay 80's own header said "only the victim throw-arc HEIGHT differs (alias physics, queued)". It does not — arcs identical on all three throws. It predated the 14z-67 fix and was never retracted |
| **three challenges, three corrections** | (1) sets are blind to order/dwell -> replaced by the ORDERED state sequence; (2) the victim's PIXELS are cross-generation (VS's Victor vs VS2's) and are not evidence about the port -> excluded and said so; (3) damage timing unmeasured -> measured, same amount at the same POSE, offset growing +5/+7/+10, i.e. a RATE not a defect |
| **widening: cost MEASURED, not argued** | 27.7 s for Victor, 186 s for all eighteen. It then paid twice: found the ±1 damage residue the narrow gate could not see, and **exposed the frozen arc constant as VICTOR's number** rather than the throw's. Ruled within tolerance, carried open as knowledge |
| my own errors, corrected in-session | the "130 px" characterisation; a set comparison; using vsavj's pose table for TENANT victims (all three "diverged" — it was the resolver, a rule `audit_don_grab_pose` already documents); silently dropping the arc check while strengthening the gate; and the zsh no-word-split trap TWICE in one session |
| **the standing lesson, and it is the document** | `docs/project/gate_scoping_method.md`, [VSP-167]..[VSP-174]. **Every rule in it is something that went wrong here first** — which is the only reason to trust it |

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

- Session 14z-130 CLOSE — **M13 FROZEN, REGISTERED AND TAGGED** (donovan-m19 / huitzil-m26 / pyron-m20 / merged-m15, mark M13, the boot name screen reading VAMPIRE SAVED): the `gap_be27a` fold-in BYTE-NEUTRAL on all five tracks after its ownership question turned out to have a measured answer (the generic repoint would have silently reverted the 14z-64 mirror-victim fix); freeze suite 8/8 SUITE GREEN over 3h05m with every expectation set a PURE CARRY; emulator tier 131/1; the 137-file re-point sweep, which walked into the documented history-rewriting trap and needed 13 dated records restored. Static 130/0/0/0  [rolled 14z-131 close, early — STATE was 193 KB]
- Session 14z-129 CLOSE — THE TRIAGE SESSION: five red gates to green, one (`audit_type_dispatch_range`) DROPPED on measured ground after the maintainer's "better no test than a bad one", and NOT ONE red was a defect in the shipped artifact. Two decisions ruled and implemented (release scope 141/23 + the new `cadence` column that makes the MiSTer ruling enforce itself; `gap_be27a` folded into M13). [VSP-166] ruled by the maintainer against a proposal of mine and it paid for itself within the hour. No build byte moved; twelve commits, all pushed  [rolled 14z-130 close, early — STATE was 171 KB]
- Session 14z-128 CLOSE — THE EMULATOR-TIER SWEEP: the runner built (`run_all_emulator.sh` + `ci_emulator.tsv`, 164 gates enumerated where 132 had been reachable only by typing a filename), THREE DEFECTS FOUND IN IT BY RUNNING IT, the shared-writes guard caught EXEMPTING EIGHT LEGACY ROWS, and a LEGACY replay found guarded by NOTHING for five sessions. Sweep 155 gates: 136 PASS / 19 FAIL / ZERO SKIP — and not one red was a defect in the shipped artifact; eight closed in-session. Strict static 129/0/0/0  [rolled 14z-129 close — STATE was 164 KB]
- Session 14z-127 CLOSE — ONE DAY, TWO OPEN QUESTIONS ANSWERED "THE PORT IS FINE", AND THE INSTRUMENTS THAT PROVE IT: #114 REFUTED then properly scoped (its evidence was JEDAH; the cadence is the HOST ENGINE; the mash ceilings MATCH), the boot title SAVIOR -> SAVED BUILT on all five tracks, and `test_shared_writes` FOUND GREEN AGAINST 14z-91 BUILDS FOR TEN FREEZES. Ten commits, all pushed; strict static 126/0/0/0  [rolled 14z-128 close — STATE was 160 KB]
- Session 14z-126b CLOSE (3) — ritual complete for the LONG CONTINUED session: NINE ARCS — a maintainer correction to a rule I had overstated, the `14z-N` key documented as law, #113 CLOSED then MECHANISED, the MiSTer core-list name + main-MRA fix, a corpus gate that could pass while asserting nothing, #112 ROOT-CAUSED, Jedah ARBITRATED, the aerials part-resolved, and #114 opened on 421+P. No build byte moved; strict static 126/0/0/0  [rolled 14z-127 close, early — STATE was 164 KB]
- Session 14z-126b CLOSE (2) — FIVE ARCS AFTER THE FIRST CLOSE: the three grandfathered tags amended and force-pushed, a red root-caused to the macOS tmp reaper, #112 picked up and its premise refuted, the black foot found by searching the INPUTS, and two gotchas + a gate that came out of it. No build changed; strict static 126/0/0/0  [rolled 14z-127 close]

- Session 14z-126 CLOSE — THE DF-STARTUP QUESTION ANSWERED (the window is `+0x147`, armed PER CHARACTER — neither global nor inherited), which the maintainer's "where do the values come from?" turned into a PRESERVATION FINDING (vs2 and vh2 carry the VS-style DF handlers for all 18 and never reach them, so the port RESTORED Capcom's own values) with its own document `docs/game/preserved_data.md`; and the frame-data privacy rule ruled and shipped the same session. No build changed; strict static 124/0/0/0  [+1 more entries]  [rolled 14z-126b CLOSE (2), early — STATE was 152 KB]
- Session 14z-125b CLOSE — THE COMMUNITY CROSS-CHECK DELIVERED AND THEN FINISHED IN ONE DAY: all 15 vanilla characters derived for the first time, ~96% agreement per column, the JOIN measured in-emulator after a fitted model was overturned, and the residue arbitrated — two families closed, one honestly open; two defects found, both OURS; no build changed; strict static 123/0/0/0  [+2 more entries]  [rolled 14z-126b close, early — STATE was 154 KB]
- Session 14z-124 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS IS DONE (G7): engine_internals' last third rationalized and the document flipped to REFERENCE, doc_shape has ZERO PENDING, the ci floor 15 → 60, inferred_claims CLOSED; one tooling defect found on the way (the wrap-blind atlas-rows splitter); THEN CLAUDE.md PASS 2 the same day (414 → 344 lines; oracle_classes.md is the class spec of record). No build changed; portable 61/0  [rolled 14z-126 close]
- Session 14z-123 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS, ONE DAY: T1 (annotations.md CREATED, generated), G2 (three T3 rigs — EVERY claim RETRACTED: Sasquatch's DF armor, the roulette tag, the advancing guard), G3 (a)+(b), G4, G6 (HANDOFF 3,652 → 1,374; the gate index GENERATED), CLAUDE.md pass 1; no build changed; PUSHED  [+1 more entries]  [rolled 14z-125b close]
- Session 14z-122 CLOSE (2) — ritual complete for the CONTINUED session: two new rulings recorded (the annotations row is CHECK-FIRST; THE CLAUDE.md CONDENSING PASS is a named item), G1 executed after the specimen's ratification — eight document commits, the atlas retagged, 6 docs still PENDING  [+3 more entries]  [rolled 14z-125b close]
- Session 14z-121 CLOSE — ONE DAY, FROM THE M12 VERDICT TO THE CHARACTER PAGES: the board verdict GREEN; the Killshread ruling; the phase-3 remainder; the pushback = a STEP TABLE on record +0xC; the three CHARACTER PAGES; no build changed; PUSHED  [+7 more entries]  [rolled 14z-123 close, early — STATE was 158 KB]
- Session 14z-120 CLOSE — ONE DAY, THE CHARACTER-DATA MAP FROM THE MOVE LISTS TO PHASE 3: the three move lists, every chain NAMED on native vs2 (`test_move_naming`), the hitbox encoding / attack record / reaction sets MEASURED; no build changed; strict 117/0/0/0  [+4 more entries]  [rolled 14z-123 close]
- Session 14z-119 CLOSE — THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (mark M12), the stock twin MOVED by design; strict 117/0/0/0; FIELD VERDICT GREEN 14z-121  [+1 more entries]  [rolled 14z-122 close]
- Session 14z-118 CLOSE (3) — the session's close. One day, four arcs: the M11 board verdict  [+4 more entries]  [rolled 14z-121 close]
- Session 14z-117 CLOSE (3) — the session's last act. The VS/VS2 data-architecture page CORRECTED from a row-by-row measurement after the maintainer read it; the next session is RULED: a full documentation audit — measured, consis… [+4 more entries]
- Session 14z-116 CLOSE — THE COSMETIC/EXTRAS ARC: win quotes MEASURED THEN FORGONE, the hidden characters DECODED (Shadow takes the tenant — confirmed on the board), and PYRON'S MEDALLION WHITE-OUT FIXED after two years parked; 13 commits pushed; nothing frozen (the freeze battery = 14z-117). The close ritual audited: patch_notes/patch_index/HANDOFF/gotchas had been skipped on the first pass and were written.
- Session 14z-115 CLOSE — THE SELECT-WHEEL SEPARATION FROZEN (donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged), tagged at `b30611a`, strict 111/0/0/0, guard corpus 340/340; emulation verdict "no regression", the maintainer's own mockup the next cut (moved to STATE_HISTORY 14z-118)
- Session 14z-115 — THE SELECT-WHEEL SEPARATION ("E2"): the three tenant medallions repositioned by the maintainer's pixel offsets, hover rings tuned by eye, a 1 px black outline authored per cell; the OPEN FBNeo two-run-family instrument question first recorded (moved to STATE_HISTORY 14z-118)
- Session 14z-114 CLOSE — ALL SIX SKILLS DISTILLED AND LOCKED TO THE DOCS in one session (the MiSTer pair, the CPS-2 pair, the game skill and the port skill — 425 rules, every one anchored in the paragraph it distils, every number in a log; four staleness passes run first, each its own commit) (moved to STATE_HISTORY 14z-117)
- Session 14z-114 — the MiSTer SKILLS distilled with their checker: two skill packages (level 1 `[MSC-1..73]`, level 2 `[MSV-1..36]`), every rule ID-anchored in the doc paragraph it distils; the log gained the 14z-108/109 measurements it never had; the field test got an in-tree carrier (moved to STATE_HISTORY 14z-117)
- Session 14z-113 CLOSE — the MiSTer SCOPE DOCUMENT written and its three decisions ruled; the S1-S20 staleness pass run; bundle 14z112 field-verified; merged-m10 FROZEN; the RELEASE FORMAT ruled and shipped (one self-sufficient directory per platform) (moved to STATE_HISTORY 14z-116)
- Session 14z-113 — `docs/project/mister_scope.md` written (scope only, not the skills): the two-level split, the doc dependency map, and the known-stale inventory S1-S20 (moved to STATE_HISTORY 14z-116)
- Session 14z-112 CLOSE — #99 CLOSED on a green field verdict (the board on bundle 14z111 / merged-m9 M8 does not crash on Bishamon > Phobos; MAME agrees on four hand-played recordings, all guard-clean, tracked as `play-merged-m9-01`, `run-merged-m9-02..05`); #112 (Press-of-Death palette) reproduced, ruled COSMETIC and parked; #113 measured VANILLA on emulator (the one-frame white-out at a down); the WIDE profile stopped breaking stock Vampire Savior — a WIDE set is ONE zip, the four patched group-A members inside `vsavjw.zip`, the parent pristine (`build/m3b_merged17`; frozen as merged-m10 at 14z-113) (moved to STATE_HISTORY 14z-115)
- Session 14z-112 — FIELD VERDICT GREEN on merged-m9 (M8): #99 CLOSED by the maintainer; the four recordings tracked; #113 re-read as a sprite-dropout frame; playback length now MEASURED (a recording ends where the human stopped; `test_inp_corpus` plays to MAX_FRAMES=6000 by default) (moved to STATE_HISTORY 14z-115)
- Session 14z-111 CLOSE — #99 ROOT-CAUSED (CPU-Phobos ran DEMITRI's AI: the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + the same 16 repeated, so tenant classes read the aliased row) AND FIXED by option A (the tenants' own vs2 AI script blocks as data roots, zero code); frozen donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9, mark M8; board bundle 14z111 ready; FIELD REPORTS ARE RECORDINGS promoted to CLAUDE.md §4 law with `tests/test_inp_corpus.sh` (moved to STATE_HISTORY 14z-114)
- Session 14z-111 — OPENED WITH A CLOSE-RITUAL AUDIT of 14z-110b (clean but unchecked): the three in-flight validations re-run and accepted; then the field verdict RED on merged-m8 (the board STILL crashes on Bishamon > Phobos, MAME by hand too) -> the maintainer's hand-played `.inp` captured under the new `tools/run_inp_guarded.sh` found the real mechanism the two poke-derived fixes never touched (moved to STATE_HISTORY 14z-114)
- Session 14z-110b CLOSE — the 0x51->0x44 remap BUILT, FROZEN (donovan-m13 / merged-m8, M7 mark carried) and MAME-VALIDATED; the board bundle carries merged-m8; the FBNeo partial oracle's reduced refit RULED and in progress; closed at the maintainer's call (context ceiling) with three validations in flight — re-run and accepted at the 14z-111 opening audit
- Session 14z-110b addendum — THE FBNEO ORACLE RED ROOT-CAUSED TO THE RULED d2-WINDOW CYCLES (110), NOT THE REMAP (110b): m12 == m13 RAM at the failing frame; the hunt cost a paid-for instrument trap; resolution = per-replay measured-clean frame overrides, 26_don_arcade_mash dropped for 05_timeout_idle (maintainer-ruled)
- Session 14z-110b — THE RESIDUAL #99 ROOT-CAUSED AND THE REMAP RULED-BY-CONDITION: the STORED state 0x51 over-runs a SECOND 80-vs-84 dispatcher (PRG:0x2384E) the 14z-43 audit also missed; fix = 0x51 -> 0x44 on the six deity nodes + one ported immediate, measured equivalent at every consumer both engines have. (Field: STILL CRASHED — the real #99 was the AI script-table alias, found 14z-111 from the maintainer's recording.)
- Session 14z-110 (4) — CLOSE. THE RULED ORDER IS COMPLETE: FIX -> AUDIT -> RE-FREEZE. The #99 d2-window fix built, audited and frozen (donovan-m12 / merged-m7, mark M7), with the MiSTer CRC tail and a field bundle. Its verdict came later and was RED: the crash survived, and 14z-111 root-caused the real mechanism.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-109 (4) — THE #99 CRASH INVESTIGATED ON EMULATOR after the FIELD TEST PASSED on a real DE10-Nano (tenants selectable, playable, voices heard, feel better than emulator) with one 100%-reproducible crash. Root-caused the same day to vs2 type byte 0x51 in Donovan's ported block — a conclusion 14z-111 later RETRACTED as poke-contaminated. Also: the OBJ-list oracle, the DECISIONS_HISTORY split.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-108 CLOSE — ritual complete. THE FUNCTIONAL CHAIN IS COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT RELIABLY CLOSE TIMING. A tenant FIGHTS on the core and fights CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under load is GO; scroll is structurally cleared; the CPS-2 video registers are documented for the first time. AND THE SESSION'S OWN HEADLINE IS THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER THE SAME DAY — three of them mine. 22 commits, ALL LOCAL.  [rolled 14z-111 close]
- Session 14z-108 — THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END, NOT TRANSPOSED IN TWO — measured on all four before one bit was changed, and the half nobody had exercised is where the previous reading was wrong. `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no RTL), verified against the game's own input mirror on both implementations, and the gate rebuilt with a per-direction lock and a must-fire control. One of the two frozen expectations the record said would move DID NOT MOVE AND COULD NOT — which also means the frozen sim anchor could not move. AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4 — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS FOUGHT ON THE CORE. Bank 1 under load answered from the same run and it is GO. Still never: HARDWARE — and no Quartus synthesis has ever been run, so resource fit and timing closure are unknown. That is now the largest gap in the arc.  [rolled 14z-111 close]
- Session 14z-107 CLOSE (final) — THE WIDE ROMSET BOOTS ON THE CORE, draws our select screen and fetches our wheel art: six RTL slices D0-D5 (the MRA, the runtime profile gate + QSound width, the SDRAM placement, the CPS-2 Turbo object promote, the 6 MB program window, and D5 THE DECRYPTION RANGE — the CPS-2 key's encrypted-opcode range word is stored COMPLEMENTED and jtcps2_dec_ctrl reads it straight, which no stock CPS-2 game could ever expose); 105 distinct tenant tile codes out of obj bank 5 with the control leg at zero; bank 0's traffic under the redirect ANSWERED and GO; both stock legs green. **The arc's headline was methodological: SEVEN instrument and harness defects found in this lane, every one of which would have read as an RTL fault, with D5 the counter-example where the RTL genuinely was at fault.**  [+3 more entries]  [rolled 14z-108 close]
- Session 14z-106 CLOSE — ritual complete: HOUSEKEEPING executed (the 14z-105 evidence logs + the guard-corpus TSV committed, the rehearsal probes attic'd, `../build_attic_14z102` 8.1 GB deleted under the standing policy, `emu/fbneo`'s modified content verified as patches 0001+0002) and THE MiSTer ARC OPENED with no RTL touched — the framing RULED (an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA re-implementation of MAME) and all five alignment questions answered the same day (separate core, GPL-3.0 fork, measure-then-choose profile, sim = gate / hardware = field test, MRA+RBF with a stock-vsavj reference leg); LICENSE = GPL-3.0; slice A landed the public fork `DefinitelyFrenchName/jtcores@vampire-saved` with the separate core `cores/cps2w` -> `jtcps2w.rbf`, pinned as submodule `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`, and the twin proof MEASURED (the vsavj MRA byte-identical to stock cps2's except `<rbf>`); slice B measured the fit (`mister_fit.md`: PRG 4.82 MB, QSound banks 0x80-0x8E all aliasing, GFX 52,347 roster codes / 6.39 MB against 4,028 blank tiles / 0.49 MB in ALL of vanilla's 32 MB — a wider GFX tier REQUIRED) and slice C proved THE VERILATOR SIMULATION LANE ON macOS (stock jtcps2 running vsavj, ~1.4 s/frame, the full recipe in `docs/platform/mister.md`, the `.rpl` -> `sim_inputs.hex` translator gated)  [+3 more entries]  [rolled 14z-107 close (final)]
- Session 14z-105 CLOSE (final) — THE MAINTAINER-DIRECTED WINDOW EXECUTED END TO END and field-confirmed: W1 the OBORO SELECT HOOK (cursor on Bishamon + hold START -> vanilla vsavj's Oboro, id 0x18, P1 and P2, vanilla's own Gallon-variant idiom one cell over) and W2 the VERSION STRING ("M6" at the select screen, the naked-eye A/B tell CLAUDE.md §5 had wanted since 14z-92, authored glyphs pixel-exact) — frozen as donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 with the stock twin m5_stock6 = `883e7d17` BIT-IDENTICAL, every gate and both soaks green, pushed 2026-08-22; the GFX TILE CODEC was found MIRRORED on the way (plane bit i draws at pixel 7-i; 14 sessions old, nothing had ever read pixel ORDER until the first authored tile) and the 14z-104 prediction that more sprites would move the select-window specs DIED by measurement over all 148 specs; RELEASE PACKAGING landed (`release/merged-m6/`, xdelta3 against the reference dumps, no ROM byte in the package) and was ruled IN-TREE until MiSTer  [+3 more entries]  [rolled 14z-107 close]
- Session 14z-104 CLOSE — THE §4 COVERAGE DEBT TACKLED end to end (maintainer-directed): the mandate measured cell by cell, six new audits built and green on merged-m5 and the matrix documented as a maintained artifact; THE PURSUIT answered and instrumented (audit_pursuit_leap); coverage gap 1 (tech roll + throw tech, both directions) and gap 2 closed; THE OBORO QUESTION answered with a live demonstration; the 14z-105 window (Oboro hook + version string) prepped in NEXT_SESSION  [+4 more entries]  [rolled 14z-107 close]
- Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale reference re-pointed, run green, or ruled a deliberate pin) plus the three findings it surfaced (the gate_failures litter class, GitHub #110, four LEGACY replays promoted off self-frozen .sha1); #110 FIXED AND CLOSED — the mechanism was the ARCADE DRAW, not cycle drift, both audits re-derived on pinned-opponent rigs and green on merged-m5; the Circuit Scrapper report measured and not reproduced  [+1 more entry]  [rolled 14z-107 close]
- Session 14z-102 CLOSE — THE #107+#109 WINDOW frozen as donovan-m10/huitzil-m19/pyron-m13/merged-m5 (#109 re-derived from scratch to effect-class ROW 31, the DF clone-mode beam emitter vsavj stubbed; #107 row flip; gold tint kept; build-dir triage 8.1 GB atticked; N-2 deletion policy adopted)  [+6 more entries]  [rolled 14z-105 close]
- Session 14z-101 CLOSE — the agreed #108->#107->#106 sequence executed windowless (#108 INVERTED to not-a-defect: the satellite word is our own bank row, native satellites equally sweep-inert; #107 twin-anchored statically + tie-refusal landed; #106 closed via verify_pcrel_data --extract); guard-corpus built 316/316; DF mechanics measured ours-vs-native (frameworks differ BY DESIGN; ours == pristine vsavj on the legacy control); #109 found, root-caused through two in-place retractions, and fully prepped  [+9 more entries]  [rolled 14z-104 close]
- Session 14z-100 CLOSE — THE HARDENING PROGRAM opened and executed same-session (pointer/flow comb H1, escape triage H2, the #99 continue-switch lock H3, the contact rig H4 with the -debug/non-debug instrument paradox left to 14z-101); #99 CLOSED (maintainer); #106/#107/#108 filed; the build-dir decision package delivered  [+3 more entries]  [rolled 14z-104 close]
- Session 14z-99 FREEZE + field-confirmation — THE WINDOW EXECUTED END TO END (donovan-m9/huitzil-m18/pyron-m12/merged-m4; #43(b)+#103+#104+#105; merged BIT-FOR-BIT the rehearsal; stock twin moved by design); field pass CLOSED all three tickets same day (incl. transformation throws) and un-parked #99; the skipped close ritual caught up post-freeze  [+7 more entries]  [rolled 14z-102 close]
- Session 14z-98 CLOSE — #103 root-caused+staged (window = uncomment+battery), #102 answered (vanilla's own continue), #104 found/reproduced/mechanism-closed-then-14z-99-corrected, #105 filed + AUTO selection solved, "instance 2" retracted (the 2-byte-poke class); NO SHIPPED BYTE MOVED  [+9 more entries]  [rolled 14z-101 close]
- Session 14z-97 CLOSE — #96 CLOSED (the battery's target FOLLOWS THE BUILD via registry.tsv); the §4 masked-compare vocabulary unified to ONE implementation (tests/lib/masked_compare.sh, proven 3 ways); the #99 continue rig BUILT and blocked one screen short by #103 (instance 2); #102 filed (arcade chaining quirks); 08_challenger_join's 3807 attributed to $FF06E1 (ram.md:62); two measured-wrong-thing defects fixed (propose_masked_specs absolute-builddir trap; the lifted diverge branch)  [+9 more entries]  [rolled 14z-100 close]
- Session 14z-96 CLOSE — ritual complete  [+7 more entries]
- Session 14z-95 — FOUR MAINTAINER RULINGS TAKEN, #52 LANDED, and the Phobos sfx report corrected from "a sound missing" to "a WRONG sound"
- Session 14z-94 (11) — THE MERGED-M2 PLAYTEST RESULT (maintainer, 2026-08-18, build/m3b_merged9 on MAME). NO REGRESSION — and one CRASH.  [+11 more entries]
- Session 14z-93 CLOSE — ritual complete  [+3 more entries]
- Session 14z-92 CLOSE — ritual complete  [+6 more entries, incl. GitHub #75 closed — the merged gfx-verify abort was a verifier artifact]
- Session 14z-91 CLOSE — THE LEGACY REGRESSION FIXED (obj_hook de-thunked: walker relocated, callers repointed; fixture-override deletion; type-6 change), m5/m13/m7 -> m7/m15/m9 re-freeze, EIGHT maintainer rulings applied (Rule 1 v2 retitle #35, PNG goldens ruled outside rule 7 #73, CI drafted #41...). THIS GROUP ALSO HOLDS, as ### sub-entries: 14z-90 (the 2026-08-15 adversarial audit re-judged, tier 1 complete), 14z-83..89 (Phobos DF gold block huitzil-m6, M5 voice samples design + Z80 driver RE, the 14z-85 owner-tag family, 14z-86 M5 voice batch, 14z-87 voice-class borrow + 87b beep/medallion, 14z-88 medallion revert, 14z-89 QSound ledger binding)
- Session 14z-82d — the playtest reports, measured  [+3 more entries]
- Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not
- Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three traps that were not in the spec
- Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN FOR TEN SESSIONS
- Session 14z-71 — THE BEAM: row 16 of the effect-class table is a STUB in vsav, and underneath it vsav has no list-type 12
- Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted
- Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal
- Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family asks it instead of the build scalar
- Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)  [+1 more entries]
- Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a GENERATOR BUG found under it  [+1 more entries]
- Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table row for H aliased character 0's block; ported H's own block. Also: the FG "slowness" was the broken GFX, not timing — resolved by observation.  [+1 more entries]
- Session 14z-71 CLOSE — ritual complete  [+6 more entries]
- RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6 (maintainer-approved; build/hui20, fingerprint 40cc10b1)
- Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build never walks the beam anim nodes (measured, both legs, one emulator)  [+3 more entries]
- Session 14z-69 CLOSE — ritual complete  [+8 more entries]
- Session 14z-68 (the effect-flow closure — root cause found)
- Session 14z-67 (D4: the Phobos gfx vertical)
- Session 14z-66 (playtest round-1 worklist)
- Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)
- Session 14z-64 SESSION CLOSE (2026-08-07)  [+3 more entries]
- Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL MEDALLION ART, vanilla cells pixel-identical by construction)
- Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and PLAYTEST-VALIDATED: the select family serves from group C bank 5; Jedah confirmed indistinguishable from vanilla by human playtest)  [+1 more entries]
- Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the emulator; and the rendering gate that should have caught it)
- Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)
- Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)  [+1: 14z-59j dual-track invariant established — later SUPERSEDED 14z-94 (#95), see the archive's marked banner]
- Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)  [+5 more entries]
- Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)
- Session 14z-58e (handoff hygiene: reproducibility PROVEN)  [+1 more entries]
- Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)
- Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)
- Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)
- Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)
- Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)
- Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)
- Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)
- Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)
- Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)  [+2 more entries]
- Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)  [+1 more entries]
- Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)
- Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)
- Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)  [+1 more entries]
- Session 14z-44c (round 55: WIN-screen item corrected + sharpened)  [+2 more entries]
- Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)  [+1 more entries]
- Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)  [+2 more entries]
- Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)  [+1 more entries]
- Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)
- Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)
- Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)
- Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)
- Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)
- Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)
- Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)
- Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)
- Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)
- Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)
- Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)
- Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)
- Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)
- Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)
- Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)
- Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)
- Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)
- Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)
- Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)
- Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)
- Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)  [+1 more entries]
- Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)
- Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)  [+1 more entries]
- Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19
- Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)
- Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)
- Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)
- Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)
- Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)
- Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)
- Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)
- Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)
- Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)  [+2 more entries]
- Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)
- Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)
- Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)
- Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)
- Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean
- Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)
- Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)
- Maintainer priority statement (round 24, 2026-07-30)
- Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)
- Session 14z (round 22: winpal copies convicted and fully reverted)
- Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)
- Session 14w-c resolution (ALL GREEN at d6a751cb)  [+4 more entries]
- Session 14v (grab-pointer work vars fixed — the Felicia float)
- Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)
- Session 14t (win-quote palette: decoded, port REVERTED by the gate)
- Session 14s (playtest round 16: overlay REVERTED; pixel gate born)
- Session 14r (overlay port COMPLETED to a 22-site shipping config)
- Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)
- Session 14p (feet fixed; blink mechanism = Jedah's overlay records)
- Session 14 highlights (M2a FROZEN)
- Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)
- Session 14n (round 12: revert validated; two new items scoped)
- Session 14m (f8eda2ca REVERTED — regression + board reset)
- (reverted) Session 14l (bank-attribution fix)
- Session 14k-b (blink TRULY root-caused: per-record bank attribution)
- (superseded analysis) Session 14k (OBJ budget saturation theory)
- Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)
- (earlier) Session 14i-b (round-9 mechanisms pinned)
- (earlier same session) Playtest round 9 diagnosis
- Session 14h highlights (win-quote portrait ported; HUD name found)
- Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)
- Session 14f highlights (select palettes fixed; splash/win specified)
- Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)  [+1 more entries]
- Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)
- Session 14c highlights (select-screen pipeline mapped)
- Session 14b highlights (M2b static phase — R2 cracked)
- Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)
- Sessions 5-6 highlights (M2a stage 4 — the port runs)
- Session 4 highlights (M2a — the real Donovan port)
- Session 3 highlights
- Early standing sections (Current milestone / Next actions / Open items / Decisions made) — 2026-07-era snapshots, STALE, kept verbatim in the archive; the closed early decisions (base revision vsavj, per-member checksums, byte-order convention) are all recorded in CLAUDE.md/HANDOFF too
- OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES — FIXED 14z-61 (the shadowed-ROM-member hash-resolution trap); header kept as written

---

# STANDING SECTIONS (current state — never archived)
## RELEASE-TIME TEST SCOPE (maintainer, 2026-09-02)

**AT RELEASE TIME, ALL TESTS ARE RUN.** Verbatim: *"at release time, ALL tests
should be run. The only exception would be test whose scope is not applicable
to what is released, which honestly would be specific tests used momentarily or
tests on a different romset or platform. So tests that would measure VS2 or
vsavj for instance are out of scope since we release vsavjw BUT tests on native
VS within vsavjw are absolutely relevant."*

The discriminator is **THE SUBJECT OF THE TEST, NOT THE ROMSETS IT TOUCHES**:
- IN SCOPE — anything whose subject is the released artifact, **including its
  LEGACY / native-VS content**. A gate that uses `vsav2` or pristine `vsavj` as
  an ORACLE is in scope: the reference leg is not the subject.
- OUT OF SCOPE — a gate whose SUBJECT is a different romset or platform
  (a pristine-set rule lock, a stock-twin-only gate, another platform's lane),
  or a momentary//specific probe.

**THE ABSOLUTE (maintainer, 2026-09-02):** *"there is no approximation in our
testing discipline both in general and absolutely at release: unless explicitly
approved AT release time, anything red, anything skipped is a hard fail of the
release process."* And the asymmetry that makes the cost sane: *"we may not
need ALL the tests for every small change but how could we not run them when we
release, since we have them!"* — a subset during development, EVERYTHING at
release.

**CONSEQUENCE FOR SELF-SKIPPING GATES:** a gate that prints `SKIP:` and exits 0
because a prerequisite is absent has NOT been run, and in `run_battery_m2.sh`
`bat` counts a bare exit 0 as PASS — the exact class
`tests/test_battery_accounting.sh` exists to bar ([VSP-101], SKIP IS NOT PASS).
Under this policy a release-scope gate must FAIL LOUDLY on a missing
prerequisite rather than self-skip. `test_don_immortal_native.sh` was corrected
to that convention when the policy was ruled (it had two silent `exit 0`s).

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

**HOW A RED IS ADJUDICATED — the maintainer's explicit statement of the obvious
(2026-09-02):** *"to know if we should fix the gate or what it caught, we must
use data we can trust, and that means measuring or relying on data that is
known to be true for it was vetted by measurements."* **A RED GATE IS A
QUESTION, NOT AN ANSWER.** Before choosing fix-the-gate / fix-what-it-caught /
delete-as-valueless, establish WHICH SIDE'S EXPECTATION RESTS ON MEASUREMENT.
A frozen expectation whose provenance cannot be named is a claim with a number
in it. **The worked example is this session:** `test_don_reactions.sh` was
GREEN on `native == 10`, a constant of playtest-testimony provenance
(STATE 14z-42c) presented as measured — it happened to be correct, which is
luck, not method. **MEASURED 14z-127, as input to the emulator-tier arc: 30 of
45 frozen expectation files declare their provenance in their header; 15 do
not** (`advancing_guard`, `community_crosscheck`, `df_accumulator`,
`escape_triage`, `front_comparator`, `killshread_es`,
`ladder_tenant_vs_palette`, `move_naming_{donovan,huitzil,pyron}`,
`projectile_census`, `projectile_params`,
`reactions_{donovan,huitzil,pyron}`). That says the provenance is not IN THE
FILE — several have it in their gate header or a STATE entry — but the file is
what a triage is looking at, so those are where the thinking time goes.

## Decisions pending (human)

- **THE VERSION-NUMBERING SCHEME — DECIDED (maintainer, 2026-09-04, 14z-132):
  option (A), the in-game mark IS the merged build number, plus a gate that
  fails a freeze whose `version_text` does not match its registry name.
  BUILT, NOT REGISTERED.** The maintainer's complaint, verbatim in substance:
  *"It's very disturbing to have a M13 based on a merged-m14 with M14
  appearing on the character wheel (and I'm not touching on possibly other
  numbering elsewhere)."*
  **THE DRIFT, MEASURED from the tags:** the mark started EQUAL to the merged
  number (merged-m6 = M6) and drifted by exactly the two freezes where it was
  not bumped — merged-m7 kept `M6`, merged-m10 kept `M8`. Since merged-m11 the
  mark has been the build number minus two.
  **THE CONDITIONAL ANSWERED ITSELF.** The ruling attached *"we might need to
  update the merged build number for the current release if and only if the
  previous one does not reflect all the changes"*: changing the mark changes
  the glyph tiles, which changes the artifact, so by the project's own rule
  it is a new freeze name. `merged-m15` therefore CANNOT carry `M15`.
  **LANDING: merged-m16 / wheel `M16`**, with donovan-m20 / huitzil-m27 /
  pyron-m21 and the stock twin CARRIED (measured unchanged).
  **BUILT AND MEASURED 14z-132:** delta is exactly `vsw.33m` + `vsw.37m` on
  each of the four WIDE tracks, ZERO members on the stock twin (the
  `bank5_active` prediction, confirmed by rebuild); every program fingerprint
  unchanged; `test_version_string` PASS on all four incl. pixel-exact
  snapshot and both verdict controls. Dirs `don_m20` / `hui54` / `pyron38` /
  `m5_stock15` / `m3b_merged23`.
  **THE GATE'S ANCHOR — DECIDED the same day: the newest annotated
  `freeze/merged-m<N>` git tag**, chosen over HANDOFF's registry row and over
  a new manifest field because it anchors on the reviewed record rather than
  on anything the build says about itself ([VSP-166]). Accepted consequence:
  the gate is RED for the whole freeze window until tagging, which is correct
  signalling. Deliberately NOT tolerant of "N or N+1" — that tolerance would
  have accepted the exact bug being fixed (merged-m7 carrying M6, drift 1).
  **A FIFTH NUMBER, recorded but NOT changed:** the build DIRECTORY counter
  runs at four different offsets from the freeze name — donovan +0, merged +7,
  pyron +17, huitzil +27 (verified over six freezes). Renaming is refused
  (~55 gates reference the paths, re-pointed each freeze).
  **THE "GENERATION N" OPTION — OFFERED 14z-132 AND DECLINED THE SAME DAY,
  on my recommendation, maintainer-validated.** The proposal was to call a
  freeze by a single GENERATION number equal to the merged build's, so one
  number resolves to all five tracks.
  **THE MEASUREMENT THAT KILLED IT: the track offsets DRIFT, and the drift is
  INFORMATION.** At 14z-113 the merged track moved ALONE (m9 -> m10, the
  one-zip repackaging) while donovan-m14 / huitzil-m21 / pyron-m15 CARRIED
  untouched, and the offsets shifted +5/+12/+6 -> +4/+11/+5. They have been
  stable only for the six freezes since.
  **A TRACK NUMBER COUNTS THAT TRACK'S OWN FREEZES AND CARRIES WHEN THE TRACK
  DOES NOT CHANGE**, so a single generation number would either lie about a
  carried track or force a new tag onto a byte-identical artifact — which the
  project deliberately avoids. It would also be a SIXTH namespace rather than
  a replacement: the four track names are simultaneously registry row names,
  expectation-set directories and annotated tags, all cited, so none can be
  retired.
  **A CORRECTION TO MY OWN CLAIM, recorded because it is what made the option
  look attractive:** I reported these offsets as "stable, verified over six
  freezes" — true of those six, and presented as though it were a property of
  the scheme. It is not; it is a coincidence of a run in which all four tracks
  happened to move together. The same caution applies to the build-DIRECTORY
  offsets in the paragraph above: a carried track mints no new build dir
  either, so those drift by the same mechanism.
  **ADOPTED INSTEAD, zero cost:** name a freeze in prose by its MARK (= the
  merged build number) — "the M16 freeze", which HANDOFF's registry table
  nearly did already — and write the carry rule where the registry explains
  itself (`tests/expected/registry.tsv` header), so an offset drift reads as
  "a track carried" rather than as something to tidy.

- **MERGED-VS-SOLO TEST SCOPING — THE GENERAL RULE IS RULED AND IS NOW
  [VSP-175] (maintainer, 2026-09-04, 14z-132). THE WALK IS 2 OF 25 DONE;
  NOTHING RE-POINTED YET.** The maintainer's core belief, verbatim:
  *"regardless of how low the odds of a change between a solo build and the
  merged build are for a given test, these odds are not zero, so the test is
  brittle intrinsically. However, unless they are specific to solo builds,
  tests on solo builds are likely to hold value even now, therefore they
  likely should be run but on the merged build."* Plus: a solo-specific gate
  is OUT of the release "run all tests", and *"there's a strong argument for
  keeping the test as a historical artifact but deprecating it permanently if
  there is not meaning in having that test on the merged build."*
  **THE RULE, ruled CORRECT: a gate is solo-specific only if a single-tenant
  build is the SUBJECT of its assertion.** A solo build as a reference leg, a
  fixture or a rig convenience does not qualify. Spec: [VSP-175] +
  `docs/project/gate_scoping_method.md` §9.
  **THE PREDICTION ON RECORD (mine; the maintainer believes it correct but
  declined to make it absolute): the exception clause may have ZERO members** —
  no gate in the 25 has a solo build as its subject. If it holds, the walk is
  24 re-points with costs, not a classification exercise, and the
  "deprecate permanently" branch is empty too.
  **THE INVENTORY (measured 14z-132; BOUND: a static read of each script's
  defaults and hard-wired assignments — the 31 "no build reference" gates are
  UNOPENED, so 25 is a floor).** Of 142 release-scope emulator rows:
  46 merged · **25 solo-only** · 3 both · 36 other build · 31 no build ref.
  `audit_walker_repoint` looks solo but its `ci_emulator.tsv` row supplies
  `%MERGED%` — the `args` column can re-point a gate without touching it,
  and only 3 rows use it today.
  **THE 25, grouped as offered for challenge:** legacy oracle on `don_m19` (4)
  `audit_legacy_pairings` `audit_flicker_attribution` `test_fbneo_legacy_oracle`
  `test_dualtrack`; three-tenant data map (3) `test_move_naming`
  `test_projectile_params` `test_reactions`; harness self-checks using a build
  as a fixture (3) `test_guard_integrity` `test_mask_ranges_reader`
  `test_record_window`; per-tenant subject (15) `audit_df_gold`
  `audit_trap_parity` `audit_trap_shock` `audit_trap_sound`
  `audit_tripwire_reach` `audit_voice_borrow` `test_anim_node_walk`
  `test_beam_anim_walk` `test_beam_variants` `test_hitbox_encoding`
  `test_hui_df_style` `test_hui_grab_victim` `test_hui_oracle`
  `test_pyron_blink` `test_pyron_cosmo`.
  **GATE 1 — `test_dualtrack`: RULED stock vs MERGED.** Not solo-specific:
  its subject is the WIDE build's superset property and the stock twin is the
  reference leg. What a re-point re-measures: §1's frozen per-replay onsets
  (890 / 3190 / none for `06_test_mode`) and §3's onset (frame 4267,
  `$FF87A4-$FF87A7`, same writer PC both legs); §2 should be unaffected.
  **Whether pre-select bit-identity survives three tenants' hooks is UNKNOWN
  and is itself worth knowing.**
  **GATE 2 — `audit_legacy_pairings`: NOT A RE-POINT.** It resolves its
  expectation SET by fingerprint and hard-fails `FAIL: <dir> has no registry
  row`; the merged build deliberately has none. Exactly 3 of the 25 do this
  (this, `audit_flicker_attribution`, `test_fbneo_legacy_oracle`) — the whole
  legacy-oracle group — so all three wait on the dispatch-key entry below.
  **GATE 3 — `test_reactions`: WALKED, AND THE ANSWER WAS A CORRECTION OF MINE.**
  Analysed 14z-132 as a solo-defaulting gate whose frozen expectation was
  captured from our own build, and recommended re-anchoring it on vs2.
  **BOTH HALVES WERE WRONG, found by reading the gate instead of its
  provenance row:** `test_reactions` has exactly ONE emulator invocation and
  it runs **`vsav2`** — native. The three build dirs supply
  `extract/regions.json` to the chain DECODER and nothing more; no leg runs on
  our build at all. So `reactions_*` was reference-anchored all along, exactly
  like `move_naming`, and there is nothing to re-anchor.
  **THE CAUSE, and it is the thing worth keeping:** its PROVENANCE row said
  only "which chains Donovan runs AS THE VICTIM…" and its re-freeze command is
  `FREEZE=1 TENANTS=donovan tests/test_reactions.sh`, so a reader (me) inferred
  "frozen from our run" = "measured on our build". The row was UNDER-DESCRIBED,
  which is precisely the gap the 14z-132 class split exists to close — filling
  the column in is what forced the question and exposed the error. Rows
  corrected, and the description now names the native leg.
  **CONSEQUENCE FOR THE REFACTOR: the candidate set is EMPTY.** After the
  correction, every tracked expectation is reference-anchored, correct by
  construction (`static` / `hash-lock` / `derived`), a ledger, or the ONE
  deliberate open-defect marker (`ladder_tenant_vs_palette`, the
  `audit_pyron_capture_block` pattern, which stays). `df_startup_invuln` is
  honestly labelled `reference + ours` (15 vanilla + three tenants).
  **SO THE PREDICTION "it probably generalises" IS RETRACTED TWICE OVER** —
  once by measurement (4 candidates, not many), once by this correction (0).

  **GATE 4 — THE INVENTORY ITSELF WAS MEASURED ON THE WRONG AXIS (14z-132).**
  The original 25 classified by "the script names a build dir". A build dir is
  one of THREE things and only one makes a gate a merged/solo question:
  a `rompath` the gate BOOTS as vsavjw (the build is the subject, ~18 gates);
  an `extract/` a decoder reads while the only emulator leg runs NATIVE vs2
  (the build is a DATA SOURCE, not a subject — 5 gates); or both.
  **THE FIVE THAT DISSOLVE, each confirmed by reading its invocations:**
  `test_anim_node_walk`, `test_hitbox_encoding`, `test_move_naming`,
  `test_reactions`, `test_projectile_params` — every one runs
  `run_mame.sh vsav2` and nothing else (`projectile_params` touches no rompath
  at all). Gate 3 was the first instance of this class, not a one-off.
  **SO THE WALK IS 25 -> ~16 genuine candidates**, and they are HOMOGENEOUS:
  they boot our build as vsavjw, so [VSP-175] applies uniformly and the only
  per-gate work is what each re-point re-measures.

  **AND THE BELIEF CAME IN, MEASURED — `test_phasec_image` SECTION 4
  (14z-132).** RED on the M16 freeze sweep and reproducible standalone:
  *"the clean leg held the victim on only 0 frames"*. **NOT caused by the
  re-point sweep** (no commit of 14z-132 touches that file) and not a memory
  artifact. **THE MECHANISM, stated as a HYPOTHESIS ([VSP-116]):** 14z-131
  measured this control's hold window — frames 3010-3056, 47 of 47 moving — on
  `build/m3b_merged22`, the MERGED build; but the gate BUILDS ITS OWN
  SINGLE-TENANT DONOVAN WIDE track (`build_donovan.sh 6`, no
  TENANT_MANIFEST, :72) and runs the rig there. A control validated on merged
  and deployed on solo. **The liveness refusal [VSP-137] that 14z-131 added is
  what turned this into a red instead of a vacuous green** — the gate declines
  to judge a leg that produced no event.
  **THE CHEAP DISCRIMINATOR, not yet run:** put section 4's rig on
  `build/m3b_merged23` and see whether the hold appears at 3010-3056. If it
  does, the fix is gate 1's ruling applied here — the subject is "the
  extension is genuinely READ" on the SHIPPED artifact, so the leg belongs on
  merged.

  **ONE FLAGGED, NOT YET WALKED:** `audit_trap_sound` is release-scope and
  defaults to `build/hui30`, a build frozen at 14z-82c — a release gate
  asserting about a build we do not ship, regardless of the merged question.

- **THE DISPATCH KEY — DECIDED (maintainer, 2026-09-04, 14z-132): FORWARD-ONLY
  promotion of the whole-set fingerprint, with MERGED ROWS FULL-SET-KEYED
  ONLY. NOT YET IMPLEMENTED.** Why it came up: the three legacy-oracle gates
  cannot run on the merged build until the merged build is registrable.
  **THE MEASUREMENT:** the program key collapses `build/merged1` (the
  blanks-only legacy instrument), merged-m15 and merged-m16 onto ONE value
  (`f42f7569`); `--full` separates all three (`ca7ba8ac` / `033d68cd` /
  `fcc83fc3`). That is exactly the objection `registry.tsv`'s header raises
  against a merged row, so `--full` dissolves it rather than overriding it.
  **(i) "RECOMPUTE EVERY ROW" WAS APPROVED AND IS NOT EXECUTABLE — measured:
  only 20 of 58 live rows are recomputable**, the other 38 having had their
  build dirs pruned under the N-2 policy (donovan-m2b..m16, huitzil-m16..m23,
  pyron-m10..m17 and their stock/stage-4 legs). Those rows are INERT — nothing
  can dispatch on a build that no longer exists — so re-keying them buys
  nothing and would cost 38 tag checkouts and rebuilds at an unknown failure
  rate. The maintainer's ruling on that: *"the rest is valuable history but
  just legacy, we don't lose anything."*
  **THE SHAPE THAT SHIPPED THE DECISION.** No registry FORMAT change: a row's
  key is just a sha1, and the resolver computes BOTH keys and matches a row
  against either — full-set first, program second. New rows carry the full-set
  sha; historical rows keep the program sha; the two spaces are disjoint.
  **Merged rows carry ONLY the full-set sha**, so the program-key fallback can
  never resolve the blanks instrument onto a merged expectation set.
  **THE KEY'S DEFINITION, and it is load-bearing: computed over the BUILD's
  OWN rompath directory, a `;` chain REFUSED.** `--full` is rompath-chain
  dependent (`m3b_merged23/rompath` -> `fcc83fc3`; `...;../ROMS` ->
  `544990c4`), and callers pass both forms, so without this the key depends on
  who asked. `tools/artifact_manifest.py` already refuses a `;` chain for the
  same reason. Cost measured: 0.10 s -> 0.35 s per dispatch call.
  **TWO WARTS, both accepted by the maintainer:** the registry carries two key
  kinds permanently (*"fair"*); and the fallback still cannot disambiguate a
  future program-keyed collision — though after the promotion the
  program-keyed space STOPS GROWING, so a new row-vs-row collision is
  impossible by construction. What remains possible, and is live today, is a
  NEW BUILD colliding with an EXISTING row: `build/don_m20` resolves silently
  as `donovan-m19`. Hence the loud note below.
  **THE PLAN, split so the risky half is separable:**
  **B1 (mechanism only)** — dual lookup, the key defined as above, a LOUD note
  whenever a program-key match fires (after the promotion that always means
  "not registered under a whole-set key"), `test_suite_dispatch_selftest`
  extended over both spaces with a must-fire control.
  **Acceptance: everything resolves exactly as it does today.** Reversible.
  **B2** — the three legacy-oracle gates re-pointed to merged, only after B1
  is green; open-ended, because it re-measures their expectations on merged
  and may surface real differences.
  **Ordering: B1 before M16's registration**, so M16 lands natively in the new
  scheme instead of needing a fourth comment-out row.
  **WHY NOW, in the maintainer's words:** *"our current builds are extremely
  solid and have been for some time. Were it not the case I would still agree
  but I would strengthen my rigor regarding testing even more as I wouldn't
  want side-effects invalidating or, worse, validating tests while I already
  have a flaky build."*

- **~~PYRON AS THROWER~~ RULED (maintainer, 2026-09-04): NOT A CONCERN, BUT
  KEEP THE TEST.** Verbatim: *"from a historical and practical point of view
  Pyron as thrower I don't really care about because we never had any issue
  with him. But if we have the test, might as well keep it because it is a
  good regression marker."* So `tests/audit_pyron_capture_block.sh` STAYS at
  `EXPECT_MATCH=0`, freezing the observed ours-vs-native difference as a
  regression marker; **the pose mechanism (the `PRG:0x27FAA` four-sibling
  question) is NOT to be chased** and no port of row 0x11 is scheduled.
  The maintainer's own scoping caution, recorded because it is the right
  question for any widening: *"the question becomes: do we test all victims
  or only a sample and if it's a sample how to determine it"* — today the gate
  uses ONE victim (Victor), and the per-victim axis is what
  `audit_don_grab_pose` already sweeps from the other side.

- **~~PHOBOS'S THREE THROWS — historically problematic, never compared to VS2
  on geometry~~ MEASURED 14z-131 AND THEY MATCH. Maintainer-directed the same
  day; no defect found.** The ask: *"there are throws that have been
  historically problematic with the VS2 tenants as THROWERS, not victims,
  namely Phobos' throws... these have all had their share of corrections,
  especially circuit scrapper and ES circuit scrapper, and even now I am not
  100% sure they are identical both mechanically and visually to their VS2
  versions... these throws involve mostly POSITION of the victim."*
  **RESULT, ours (merged-m15) vs NATIVE vsav2, victim pinned to Victor:**

  **STRENGTHENED the same session after the maintainer's critique** — *"we
  have but 5 frames for moves that last many tens of frames... it might be a
  sample bias"* — from a comparison of SETS (blind to order and dwell) to the
  ORDERED sequence of `(pose, dx, dy)` states with dwell, over EVERY held
  frame, plus damage as `(amount, pose)`:

  | throw | ordered states | damage (amt @ pose) | arc peak |
  |---|---|---|---|
  | standard 6+HP | 29 vs 28, ours +1 tail | 14 @ 13 both | 64 == 64 |
  | circuit scrapper | **23 vs 23, IDENTICAL** | 19 @ 19 both | 278 == 278 |
  | ES circuit scrapper | 46 vs 47, native +1 tail | 2@21 2@21 15@19 both | 380 == 380 |

  **The trajectories traverse the SAME STATES IN THE SAME ORDER, and every
  damage event lands for the same amount at the same POSE.** The only
  structural differences are ONE end-of-hold state, in OPPOSITE directions.
  **AND THE CADENCE WAS MEASURED INDEPENDENTLY, three times, which is what
  turns "consistent with #114" into evidence:** the hold runs +8.5% / +9.1% /
  +8.3% longer than native across the three throws, against #114's documented
  ~1 video frame per ~11 engine ticks = 9.1% — Circuit Scrapper lands exactly
  on it. On ES the damage offsets GROW through the move (+5, +7, +10 frames),
  the signature of a RATE difference rather than a port defect. Dwell and
  frame numbers are therefore REPORTED by the gate and never gated.
  **DELIBERATELY NOT COMPARED: the victim's PIXELS.** Victor in our build is
  VS's Victor; in native vsav2 he is VS2's Victor — different generations of
  his art. A pixel difference in the victim is a cross-game fact, not evidence
  about our port (the maintainer's own second point). The pose INDEX resolves
  through each game's own `anim_index_c`, so a match means the same LOGICAL
  pose slot, which is the comparable thing.
  **A STALE CLAIM REFUTED ON THE WAY:** `80_hui_grab_2p.rpl`'s header said
  *"only the victim throw-arc HEIGHT differs (alias physics, queued)"*. It
  does not — the arcs are identical on all three throws. The claim predates
  the 14z-67 `throw_arc_tables` fix and was never retracted; it is now.
  **AND A RIG TRAP WORTH THE SESSION ON ITS OWN:** the ES version needs
  METER. With an empty stock the ES input degrades SILENTLY to the ordinary
  MP grab and returns numbers byte-identical to replay 80 — same 16 offsets,
  same poses, same 19 damage. The discriminator is P1's stock dropping 9 -> 8
  at the grab frame, which replay 80 under the same poke never does
  ([VSP-131], [VSP-123]). Documented in the new replay's header and asserted
  by the gate.
  **WIDENED TO ALL 18 ROSTER VICTIMS (maintainer asked the cost; it was
  measured, not argued): Victor alone 27.7 s, all eighteen 186 s at 6-way
  parallelism** — ~6.7x the time for 18x the coverage, so it was widened.
  **RESULT: 18/18 victims traverse the SAME states in the SAME order on all
  three throws**, the end-of-hold tail is UNIFORM across every victim (so it
  is frozen as ONE shape per throw, not 54 literals — and the uniformity is
  itself evidence it is a boundary effect rather than per-character data), and
  the ours/native hold ratio has ZERO spread across victims (1.085 / 1.091 /
  1.083), which is what an ENGINE rate looks like rather than a data defect.
  **WIDENING PAID FOR ITSELF TWICE, and both are the argument for doing it:**
  * it found a residue the narrow gate could not see — **5 of 54 victim/throw
    cells differ by exactly ±1 TOTAL damage**, sign per VICTIM not per throw:
    `0x10` +1 on all three throws, `0x13` −1 on all three, `0x0A` −1 on CS
    only. **RULED (maintainer, 2026-09-04): WITHIN TOLERANCE, NOT A DEFECT —
    *"+/- 1 damage is within tolerances. It is interesting to root-cause it to
    deepen our understanding of the engines though so let's keep that open for
    a future session."* So it is a KNOWLEDGE item, not a bug**: frozen with
    its exact deltas so it cannot drift unnoticed, and carried open for a
    future session to explain rather than to fix.
    **WHAT IS ALREADY ELIMINATED, so nobody re-derives it:** victim starting
    HP is 288 on BOTH legs for every victim (not a max-HP effect); it is TOTAL
    damage over the window, not a per-event split artifact; `bank_map`
    declares no per-character defence/damage-scaling table, so the scalar is
    somewhere that map does not model; and the sign is stable per victim
    across all three throws, so it is not throw-specific.
    **THE DISCRIMINATOR THAT MATTERS, and it is a HYPOTHESIS ([VSP-116]) not a
    finding: `0x0A` IS A LEGACY VICTIM.** Sasquatch is not ported — on our leg
    he is VS's Sasquatch, on the native leg VS2's. If Capcom retuned him
    between the games, that cell is a CROSS-GENERATION data difference and
    nothing to do with our port, which would split the residue into two
    unrelated causes (0x0A cross-generation; `0x10`/`0x13` something else).
    Testing that is the cheap first step: compare the two games' per-character
    damage/defence data for `0x0A` directly.
    **THE NAMED NEXT MEASUREMENT:** PC-attribute the writes to the victim's HP
    (`$FF8850`) on both legs with `tests/lua/tap_writes.lua`'s `REGLOG` — the
    same instrument that resolved #112's `a0` — so the routine AND its
    operands are named rather than inferred. That says which table the scalar
    lives in.
  * it exposed a frozen constant as victim-specific: the narrow gate froze the
    post-release arc peak at `278`/`380`, which were VICTOR's numbers — the arc
    is victim-dependent and spans ELEVEN values. Not wrong for Victor; wrong
    about what it was freezing, and only a second victim could show it.
  **AND ONE FALSE ALARM WORTH RECORDING:** the first widened run reported all
  three TENANT victims diverging, with unresolved pose pointers. That was the
  RESOLVER — a tenant victim on our leg is held on the PLACED copy of vs2's
  table, not vsavj's, a rule `audit_don_grab_pose` already documents. Applied,
  the unresolved count went to zero and every tenant matched.
  **THE METHOD IS NOW A DOCUMENT** at the maintainer's request (*"I want what
  we went through together documented because it's a typical example of how to
  close gaps on tests, strengthen gates, guarantee that tests are properly
  scoped"*): `docs/project/gate_scoping_method.md`, distilled into the port
  skill as [VSP-167]..[VSP-174].
  Gate: `tests/audit_tenant_throw_geometry.sh`; new replay
  `tests/replays/hui/97_hui_grab_es_2p.rpl` (replay 80 with one token
  changed, so a difference between them is the ES button and nothing else).

- **~~`test_phasec_image` SECTION 4 — ITS NEGATIVE CONTROL HAS BEEN DEAD SINCE
  14z-111~~ DECIDED (maintainer, 2026-09-04) AND **DONE 14z-131: OPTION (a)
  WORKED, SO THE GATE IS UPDATED, NOT DROPPED.** The ruling was *"I agree with
  your recommendation. If it works then we'll be able to update, otherwise
  we'll likely drop."* It works.
  **THE RE-TARGET:** section 4 now zeroes the 32-word PER-VICTIM OFFSET HEAD of
  Donovan's capture-keyframe blob in the extension (`capture_kf_ptr[0x13]`,
  `CPU:$4010E0` on the current freeze) and requires the hold to change.
  **MEASURED on `build/m3b_merged22`, P1 Donovan vs P2 Victor on
  `judge/02_throw.rpl`:** the hold runs 3010-3056 and the victim's offsets
  collapse from NINE distinct values (including a 181 px lift) to `(0,0)` and
  `(56,0)` — **47 of 47 held frames move**, and nothing crashes. The whole
  gate is green.
  **WHY THIS ANCHOR IS LEGITIMATE ([VSP-166], the law that stopped the naive
  re-point):** the blob's ADDRESS comes from the build's own table, but the
  ASSERTION does not — it is the victim position the GAME's vanilla positioner
  computes from those bytes. A wrong pointer makes the control FAIL LOUDLY, it
  cannot pass vacuously, which is the exact opposite of the dead-probe trap.
  The gate also asserts the pointer lands in the extension FIRST, so "the
  extension is read" is the thing under test, and it refuses to judge when the
  clean leg produced no hold or a single-valued one ([VSP-137]).
  **AND IT IS A BETTER CONTROL THAN THE ONE IT REPLACES:** the old one rode a
  CPU-AI read that the chosen replay could never trigger; this one rides a
  path the game runs every frame of every throw, in 2P as well as 1P.
  Original entry — measured 14z-130; [VSP-166] says I may not just
  re-point it.** Section 4 is the B4 lesson made permanent: it zeroes the
  0x160-byte block at `CPU:$400010`, replays `12_donovan_vs_cpu`, and requires
  behaviour to CHANGE — because "a relocation that passes without a control
  proves nothing, the data may simply never be read".
  **WHY IT IS DEAD, measured rather than inferred:** `build/don_m19`'s
  `placements.json` puts region **`x101aca` at `0x400010`** — Donovan's AI
  SCRIPT BLOCK, moved there by the 14z-111 #99 fix — where the control was
  written for the Phase-C SOUND TABLE. And the replay cannot read it:
  `12_donovan_vs_cpu` has Donovan as the PLAYER, so it is the CPU opponent's
  AI script that is read, never his ([VSE-75]: 2P versus never reads them at
  all). So zeroing it correctly changes nothing. Nineteen sessions.
  **SECTION 1 OF THE SAME GATE IS FIXED** (14z-130) and is a separate story:
  it pinned the stock fingerprint to `ae701ffb…`, the donovan-m2c twin from
  14z-64, while the stock twin has since MOVED FOUR TIMES, every move ruled
  and attributed in its own registry row. It now RESOLVES the expected value
  from the newest `*-stock` row in `registry.tsv`, so the anchor is the
  reviewed record and it cannot rot again.
  **THE OPTIONS FOR SECTION 4:**
  **(a) RE-TARGET at content the replay genuinely reads.** The honest
  candidate is the CAPTURE-KEYFRAME BLOB — Donovan's row 0x13 points at
  `0x004010e0`, which IS in `wide_ext` and IS read whenever he throws, on a
  path `audit_don_grab_pose.sh` already locks independently. That gives the
  control an anchor OUTSIDE the build's own placement metadata, which is what
  [VSP-166] requires; it needs a throw replay and a liveness check that the
  unzeroed run really does reach the capture pose.
  **(b) DROP section 4**, the `audit_type_dispatch_range` precedent
  ("better no test than a bad one") — but note this control defends a
  principle the project paid for at B4, and dropping it leaves "the extension
  is genuinely read" ungated dynamically.
  **RECOMMENDATION: (a)**, because unlike the dispatch-range case the liveness
  control here is CONSTRUCTIBLE — a throw either reaches the capture pose or
  it does not, and that is measurable without asking the build what it wrote.
  Cost: half a session. **Meanwhile the gate stays RED and honest**; it is not
  a regression from M13 (section 4 has failed since 14z-111 and section 1
  since 14z-110), and the M13 freeze itself is green on every other gate.

- **PYRON'S CAPTURE-KEYFRAME ATTACKER ROW `0x11` IS NOT PORTED. DECIDED
  (maintainer, 2026-09-04): MEASURE FIRST — *"Agreed, that's where to
  start."* **MEASURED 14z-131, AND IT IS A REAL, GROSSLY VISIBLE DEFECT ON A
  2P SURFACE — NOT A COSMETIC.** The port decision is now the maintainer's;
  the measurement it was waiting on is done.
  **MEASURED TWO INDEPENDENT WAYS THAT SHARE NO PREMISE, and they agree:**
  * **STATIC, from the reference ROMs.** vs2's Pyron block `0x0C7F98` vs the
    Demitri block `0x0A3D88` our build serves him: for victim Victor the
    keyframe deltas are `(-79,0) (-97,0) (-65,0) (82,29) (58,124) (100,132)
    (116,-4)` against Demitri's `(-63,0) (-63,0) (-63,0) (-26,0) (-26,0)
    (-10,32) (5,32)`. One of eight agrees, and it is the all-zero kf0.
  * **IN-EMULATOR**, P1 Pyron vs P2 Victor on `judge/02_throw.rpl`, hold
    frames 3010-3039, ours (vsavjw merged) vs native vsav2:
    ours `{(63,0)(26,0)(10,32)(-5,32)(-10,32)(5,32)}`, native
    `{(79,0)(97,0)(65,0)(-82,29)(-58,124)(-100,132)(-116,-4)(-53,116)(12,39)}`
    — **ZERO overlap.** The in-emulator numbers reproduce the static deltas
    exactly, dx sign-flipped by the positioner's own facing `neg.w d0`.
  **WHAT IT LOOKS LIKE — AND A CORRECTION TO MY OWN FIRST DESCRIPTION.**
  ~~"native hurls the victim ~130 px overhead and drops them BEHIND Pyron;
  ours holds them on the ground in front"~~ **RETRACTED 14z-131, the same
  session, after the maintainer required CAPTURES before accepting the
  finding — and they were right to.** That sentence read the raw `dy` sign as
  "up" and the `dx` sign as "behind" without ever establishing the engine's
  screen-coordinate convention for `+0x14`; it was an interpretation of two
  numbers, not an observation.
  **WHAT THE CAPTURES ACTUALLY SHOW** (PNG snapshots, ours vs native vsav2,
  frames 3012/3018/3024/3030/3036 of the same rig): the victim is held in a
  DIFFERENT PLACE and reads at a DIFFERENT ORIENTATION — ours holds Victor
  low and horizontal beside Pyron's flame; native holds him upright and
  higher through the same frames. The difference is unmistakable on screen.
  What is NOT established is any specific "N pixels up / behind" claim.
  **THE LEGACY CONTROL IS IN THE SAME CAPTURE SET AND IS VISUALLY IDENTICAL
  between the two legs** (Demitri throwing Victor, same frames), which is what
  makes the Pyron sheet readable rather than a comparison of two different
  games' art. Throws are core 2P, so the standing "cosmetic is optional"
  scope does NOT cover this.
  **STANDING LESSON, and it is [VSP-153]/[VSP-116] again:** the numbers were
  right and the sentence about them was not. Send the capture before writing
  the characterisation, not after.
  **THE RIG IS SOUND, and that is measured too:** the gate's section 0 runs a
  LEGACY attacker (Demitri) on both legs and gets 6 distinct offsets each with
  overlap 6 of 6 — identical. So the pokes, the frame window, the coordinate
  convention and the comparison all work, and the Pyron disjointness is a fact
  about the data, not the instrument ([VSP-22]).
  **GATE: `tests/audit_pyron_capture_block.sh`** (mame / release / romset),
  `EXPECT_MATCH=0` freezing the OPEN defect, flipping to `1` when the row is
  ported — the same shape `audit_don_grab_pose` used across the #104 fix, so
  the gate proves the fix rather than being rewritten to suit it.
  **THE FIX, if wanted, is the 18th instance of a mechanism used 17 times:**
  a `[[data_port]]` row in `pyron.toml` — `src = 0x0C7F98`, `orc = 0x0C782A`
  (the uniform `0x76E` sibling delta), `slot_ptr_table = 0xBE27A`,
  `hole = "wide_ext"`, `only_variant_slot = true`, with `dst`/`dst_old_head`
  naming the host block it replaces on the base track. Two things to settle
  first, both cheap: the block's LENGTH (its sub-block stride is `0xA0`, 32
  victims, so ~`0x2040`; `test_capture_pose_sources` already has the length
  rule for the other fifteen), and the signed-16-bit `lea (a0,d0.w)` bound
  that section 6 of that gate checks. One freeze.
  **STOP — THE MECHANISM IS NOT ESTABLISHED, AND THE PORT IS NOT YET THE
  RECOMMENDATION (corrected 14z-131 after the maintainer challenged the
  test's premise).** What is solid: Pyron's row 0x11 IS unported (static, from
  the manifests and the ROM), and ours-vs-native with attacker AND victim both
  held fixed differs while the Demitri control is identical. What is NOT
  solid is that the capture block CAUSES what is on screen:
  * **The victim's POSE RECORD also differs**, and the positioner cannot do
    that — it writes only `+0x10/+0x14`. Measured, victim pose-record indices
    through the hold: Demitri control ours `[6,5,2,14,23,13]` == native
    `[6,5,2,14,23,13]`; **Pyron ours `[6,5,2]` vs native
    `[2,1,0,3,11,10,29]`**. So a second mechanism is in play and it may be the
    dominant visible effect.
  * **The obvious big hypothesis is REFUTED**: our Pyron is NOT running
    Demitri's throw. His attacker records are his own — 12 distinct, span
    `0x288`, against native's 12 distinct, span `0x288` (relocated, same
    structure); Demitri's throw walks 8 records, span `0x2D8`.
  **THE NEXT MEASUREMENT, named so it is not re-derived:** the pose installer
  at `PRG:0x27FAA` selects one of FOUR sibling tables
  (`andi.w #$c,d1; movea.l $27fee(pc,d1.w),a0`) before indexing by the
  victim's id, and the requested pose id `d0` comes from the ATTACKER's side.
  So the question is whether our Pyron requests different pose ids, or the
  same ids through a different sibling table. That decides whether row 0x11 is
  the whole story, a part of it, or a red herring.
  **NO PORT RECOMMENDATION UNTIL THAT IS ANSWERED** — porting row 0x11 on the
  strength of a position measurement, while an unexplained pose difference
  sits beside it, would be fixing the half I happened to measure. Original
  entry — a throw/capture surface, so [VSP-10] (found 14z-130 while folding in the
  `gap_be27a` correction; NOT a regression, this is the state as shipped since
  the #104 work).** The capture-pose installer resolves the ATTACKER's keyframe
  block through `PRG:0x0BE27A[attacker id]`. Every legacy attacker row
  (`0x00-0x0F`, `0x0B`, `0x18`) is ported, and so are Donovan's `0x13`
  (`throw_victim_keyframes`) and Huitzil's `0x10` (`grab_hold_keyframes`).
  **Pyron's `0x11` is not**: vsavj aliases it to `0x00094954` = DEMITRI's
  block, so when PYRON throws, the capture poses are Demitri's. donovan.toml's
  own comment records it as "the recorded Pyron-as-attacker observation".
  **HOW IT SURFACED:** correcting the bank-map row made the generic
  per-character repoint want to write `0x0BE2BE <- 0x004af226`, i.e. to point
  the row at Pyron's own vs2 block (`vs2 0x000C7F98`, inside his extracted
  `hitbox` region). That write is SUPPRESSED in the shipped build — the table
  is hand-owned and the freeze had to be byte-neutral — but it is exactly the
  fix, and the generator would have made it silently.
  **WHAT IS AND IS NOT KNOWN.** Known: the source block exists in vs2 and
  vhunt2 with the uniform `0x76E` sibling delta, it lies inside a region the
  build already extracts and places, and the mechanism to repoint the row is
  the same `slot_ptr_table` one the other 17 rows use. NOT known: whether
  Pyron's throws actually LOOK wrong with Demitri's capture poses — nobody has
  compared them, and the #104 report named Donovan and Phobos precisely
  because Pyron's fold was not noticed. So this is a defect by construction,
  not by observation.
  **OPTIONS:** (a) port it, as a `capture_kf_pyron`-style row with an `orc`
  oracle and a `dst_old_head` — mechanically identical to the fifteen legacy
  rows, one freeze; (b) leave it, and record that Pyron borrows Demitri's
  capture poses as accepted. **RECOMMENDATION: measure before deciding** —
  a hand-played or scripted Pyron throw beside a native vs2 Pyron throw
  ([VSP-123] makes the native leg reachable with an ordinary poke), which
  turns "a row is unported" into "here is what it looks like". Half a session,
  and it is the cheap half of (a).

- **~~`audit_type_dispatch_range` PROBES A MECHANISM THAT NO LONGER EXISTS —
  UPDATE OR DROP~~ DECIDED (maintainer, 2026-09-03): DROP. Verbatim:
  *"better no test than a bad one. Let's drop"*.** EXECUTED 14z-129 — the
  script deleted, its `ci_emulator.tsv` and `gate_index.tsv` rows removed, and
  every live carrier marked in place (`engine_internals.md` keeps WHAT IT USED
  TO ASSERT, since the claim is still true of the design and is now simply
  UNGATED dynamically; `patch_index.md`, `harness_hardening_history.md` class
  6, `gen_donovan_patch.py`'s two comments, NEXT_SESSION). The ground is the
  measured one below — the verdict control cannot be rebuilt — NOT the
  superseded-by-`audit_type_writes` ground, which was measured FALSE.
  The measurement that produced [VSP-166] is kept in full. Original entry:
  The gate scrapes an `obj_hook thunk` address out of the build's
  `patch_notes_fragment.md` and probes it to see which type indices the merged
  build dispatches — "the dynamic census-gap detector for the 14z-82
  type-renumber fix". **MEASURED: `build/hui30` (14z-82c) has 2 such rows;
  `build/merged1` has ZERO**, so the scrape returns empty and the gate exits
  with `FAIL: could not scrape an obj_hook thunk address` before measuring
  anything.
  **WHY THERE ARE NONE: 14z-91 DELETED THE THUNKS.** The legacy-regression fix
  left "the obj_hook dispatch sites VANILLA — each 0x2C-byte object-pool walker
  relocated with its union table at copy+0x2C and only the 23 caller OPERANDS
  rewritten". No thunk is emitted any more, so no post-14z-91 build can satisfy
  this gate. Its reference leg still works only because `hui30` predates the
  change. **It has been unrunnable for ~37 sessions**, and like the others in
  this arc, unheard because no runner called it.
  **THE OPTIONS:**
  **(a) RE-TARGET** it at the shipped mechanism — probe the RELOCATED walker's
  union table instead of a thunk. The question it asks (which type indices does
  a merged build actually dispatch?) is still live and still worth a dynamic
  answer.
  **(b) DROP IT** as superseded, if `audit_type_writes` (the "DYNAMIC half of
  the 14z-82 type-stamp census", which maps observed family writes to the
  frozen static inventory) already covers the gap. **I have NOT established
  that it does** — the two ask different questions (which PCs WRITE a type byte
  vs which indices are DISPATCHED), and answering it is the first step either
  way.
  **MEASURED 14z-129, and the decision now rests on data rather than on a
  reading of our own generator ([VSP-166], which this arc produced).**
  **The (b) determination is DONE: `audit_type_writes` does NOT cover it.**
  Different BUILD (it runs on single-tenant builds, where the
  renumbering claim is VACUOUS — the lone tenant IS the first resolver and
  keeps originals by design), different QUESTION (which PCs WRITE a type byte
  vs which indices are DISPATCHED), and different SCOPE (`type_writes`
  explicitly DEFERS the 0x54470 family — "REPORTED per writer class … not
  gated" — which `dispatch_range` sections 4-6 lock). So "drop as superseded"
  is not available on the grounds proposed above.
  **THE RE-TARGET IS TECHNICALLY POSSIBLE — the site exists and carries the
  index.** The relocated walker's SITE is base+0x18 (its `jsr (A0)` is at
  +0x1E, and D0 is ZERO there — 8,990 fires, all `D0=0`, because the index has
  already been consumed to compute A0; probing the jsr would have produced a
  gate that reports "zero original-range dispatches" forever, a perfect false
  green). At base+0x18 D0 carries real dispatch indices: 8,990 fires over 10
  distinct values on `hui/70_hui_mash`.
  **BUT THE CONTROL CANNOT BE RECONSTITUTED, and that is what decides it.**
  The gate's verdict control requires a build that DOES dispatch original
  family indices, so the instrument is proven able to see what the merged legs
  claim is absent. Measured on the gate's own control replay and pokes:
  * `build/hui30` (14z-82c, pre-relocation, the gate's REF): thunk `0xfcb70`,
    **5,862 fires in [0x1C8,0x1E4)** — `D0` = 0x1cc / 0x1d4 / 0x1dc (types
    115 / 117 / 119). The control is alive there.
  * a CURRENT-manifest single-tenant huitzil vertical (`08944a7e`) at the
    equivalent relocated site: **8,990 fires, ZERO in [0x1C8,0x1E4)** — the
    highest value seen is 0x1b8 (type 110).
  So on modern builds the phenomenon the control depends on does not occur,
  and a re-targeted gate would assert "zero originals on merged" with NO
  liveness control — precisely what [VSP-166] forbids. **WHAT IS NOT
  ESTABLISHED: WHY** the modern single-tenant build shows no originals (the
  replay may not spawn those types on it; the renumbering may now apply to the
  first resolver too; something else). That is the one open question, and it is
  the difference between "drop, the class is gone" and "drop, we cannot
  instrument it".
  **RECOMMENDATION: DROP**, on the measured ground that the control is not
  reconstitutible — not on the superseded-by-`type_writes` ground, which is
  false. If the maintainer wants the class kept under watch instead, the
  honest replacement is not this gate but a rebuilt control leg, and that
  starts with the WHY above. Meanwhile the row stays `release` scope and RED,
  honestly.

- **REPLAY `105_legacy_2pwin_auto` — THE SPEC IS MEASURED AND READY TO AUTHOR;
  WHAT IS MISSING IS THE ATTRIBUTION OF TWO FRAMES (14z-128).** The replay
  entered the corpus at 14z-123 as LEGACY content and has been guarded by
  NOTHING since — no `.masked` spec, no self-frozen `.sha1`, in any of the
  three tenant sets. `audit_legacy_pairings` has been saying so for five
  sessions into an empty room ([VSP-103]); tonight's runner is what made it
  audible. **A census of all 88 top-level replays finds this is the ONLY hole**
  (the other expectation-less replay, `111_don_arcade_vs_screen`, is TENANT
  content and correctly has no vanilla oracle).
  **DONE:** the vanilla basis is frozen in `tests/expected/vsavj/masked-v2`
  (sha1 `41fffe38…`, 9,621 lines) under the sets' own mask, with
  `VERIFY_BASIS=01_attract_long` reproducing an already-frozen name
  bit-for-bit — the instrument control `freeze_masked_basis.sh` requires on
  every extension.
  **MEASURED, and IDENTICAL on all three builds** (`don_m18`, `hui52`,
  `pyron36` — which is itself evidence the mechanism is SHARED, not
  tenant-specific):
  ```
  shape: 1605/9620 frames differ in 3 runs, first 889, last ends 5868, then 3752 identical
  runs:  889-2491   2713-2713   5868-5868
  proposed: composite vsavj/masked-v2 2713,5868 889-2491
  ```
  **~~WHY IT IS NOT AUTHORED YET~~ AUTHORED AND CLOSED 14z-128 (19) — THIS
  ENTRY WAS LEFT LOOKING OPEN, corrected 14z-130.** The two flicker frames
  WERE attributed and the spec WAS authored, in commit `9ae00420` ("the two
  flicker frames ATTRIBUTED, and the spec authored — the five-session hole is
  closed"); `tests/expected/{donovan-m18,huitzil-m25,pyron-m19}/105_legacy_2pwin_auto.masked`
  each carry `composite vsavj/masked-v2 2713,5868 889-2491` and the M13 sets
  inherit them. The paragraph below is the state BEFORE that, kept because its
  reasoning is why the attribution was done first. Original text:
  `composite` is a non-exact class, and
  [VSP-27]/[VSP-29] require every non-exact class to be MECHANISM-ATTRIBUTED,
  with the standing watch ([VSP-31]) that flickers appearing outside a frozen
  inventory mean stop and root-cause. The WINDOW half is already attributed:
  onset 889 is the same onset every select-reaching legacy replay in these sets
  carries — the ratified select-wheel window of the 14z-115 separation. **The
  two single-frame flickers at 2713 and 5868 are NOT attributed.** The obvious
  reading — 2713 is the VS-screen transition, 5868 the KO/victory transition —
  is a HYPOTHESIS, not a measurement ([VSP-116]), and freezing an unattributed
  flicker inventory is exactly what the standing watch exists to refuse.
  **THE MEASUREMENT THAT SETTLES IT, ~20 min:** `DUMPS` of work RAM at 2713 and
  5868 on one tenant build and on pristine vsavj, diffed, with the differing
  bytes named against `docs/game/atlas/ram.md`. Then author, per set:
  ```
  echo 'composite vsavj/masked-v2 2713,5868 889-2491' \
      > tests/expected/<set>/105_legacy_2pwin_auto.masked
  ```
  **Authoring it is a STRICT tightening either way** — today the replay is
  compared against nothing, and composite adds no tolerance of its own (a
  bit-identical pair fails it). So the only question the maintainer needs to
  rule is whether to author on the measured shape now and attribute after, or
  attribute first. Recommendation: attribute first — it is one rig and the
  window has been open five sessions already.

- **THE EMULATOR-TIER RELEASE SCOPE — RULED IN FULL (maintainer, 2026-09-03).
  141 release / 23 out, and a NEW `cadence` column carries the MiSTer half.**
  All three judgement calls were ruled and all three are now IN the registry,
  not in prose:
  **(a) THE TWO #113 GATES -> `release`**, against the letter of the subject
  discriminator. Verbatim: *"51s is basically nothing for a release and still
  not enough cost not to run every time we freeze honestly."* Their rows carry
  the exception and the measured cost (23 s + 28 s).
  **(b) THE MiSTer LANE -> release scope KEPT, split onto a BITSTREAM
  CADENCE.** Verbatim: *"AGREED and given the time, it should be applied
  ALWAYS on release but not for a freeze, UNLESS explicitly in scope,
  typically because the changes target MiSTer specifically. If such an
  automation is unrealistic, the question should be asked at freeze if it
  should be included."* **THE AUTOMATION WAS REALISTIC, so it was built rather
  than left as a ritual step** — a ritual step that lives only in prose is the
  step that gets skipped (14z-126b: three freeze tags were missing for exactly
  that reason). `cadence` is `romset` (158 rows: runs at every freeze AND
  release) or `bitstream` (6 rows: runs at every RELEASE, and at a freeze only
  when the freeze targets MiSTer). `--freeze` (= `--cadence romset`) drops them
  AND NAMES THEM, printing the question. The two deliberate MiSTer exceptions:
  `test_mister_sdram_census` and `test_mister_gfxc_fetch` measure where THIS
  ROMSET lands in SDRAM, so they follow the romset and stay on every freeze.
  Only a `mister` row may be `bitstream` — enforced, so the concept cannot
  spread by column edit.
  **(c) THE FOUR `dev-ladder` GATES -> stay `out`.** `test_m3a_reproducible` is
  the real pipeline lock on the released artifact and is already release-scope.
  **AND THE TWO NON-JUDGEMENT OBSERVATIONS WERE AFFIRMED, in the maintainer's
  words: *"AGREED on both counts and this, again, is keeping ourselves honest
  and rely on measurements, not inference or likeliness at all stages."***
  So, recorded as standing readings of the column: **`out` does not mean
  "resolved"** (`audit_hitclass_map_cost` is `out` AND is one of the two dead
  must-fire controls — scope and control-health are orthogonal, [VSP-19]), and
  **`out` does not mean "quietly green"** (`audit_region_movability` and
  `audit_phase_mode_cost` are red right now with exact diagnoses; `out` is only
  what keeps them from blocking).
  Ground truth for the new column: `test_emulator_runner.sh` section 6b (five
  assertions incl. that the drop is NAMED, plus a romset-cadence control) and
  section 10's validator, whose three new rules were must-fire checked.
  **The original proposal follows.** *(Superseded head: PROPOSED 14z-128, THE MAINTAINER'S TO
  RULE.)* `tests/ci_emulator.tsv` gives every one of the 164 emulator-tier
  gates a `scope` of `release` or `out`, and that column is what
  `tests/run_all_emulator.sh` hard-fails on at release. **139 release, 25
  out.** The discriminator is the maintainer's own (STATE "RELEASE-TIME TEST
  SCOPE"): the SUBJECT of the test, not the romsets it touches. Every `out`
  row leads with a reason keyword so the judgement can be checked row by row
  rather than argued in bulk:
  **`romset:`** (12) — the subject is a reference romset's own behaviour, not
  ours: `audit_wide_phase_a`, `audit_id_writers`, `audit_palette_seq_ids`,
  `audit_ladder_selector`, `audit_df_accumulator`, `audit_df_dead_family`,
  `audit_front_comparator`, `test_advancing_guard`, `test_killshread_es`,
  `test_tick_durations`, `test_vanilla_frame_join`, `audit_sdram_bank_load`,
  plus `test_down_flash_vanilla` / `test_down_flash_mechanism` (#113's
  "vanilla, not ours" verdict — kept deliberately, and the borderline one:
  their subject is vanilla vsav but what they protect is a claim about OUR
  build).
  **`momentary:`** (7) — a specific probe for one investigation:
  `audit_ff0460_writer`, `audit_mask_window_ff42a2`, `audit_continue_ladder`,
  `audit_hitclass_map_cost`, `audit_phase_mode_cost`,
  `audit_objhook_owner_census`, `audit_region_movability`.
  **`dev-ladder:`** (4) — the subject is a scratch dev build:
  `test_m2a_stage1_nullreloc`, `test_m2a_stage2_data`, `test_m2a_stage3_anim`,
  `test_m2a_stage4_code`.
  **`out` NEVER MEANS "DO NOT RUN"** — `--scope all` runs them and the sweep
  does, because a gate nobody runs rots whether or not it gates a release.
  **THE JUDGEMENT CALLS worth a look:** (1) the two #113 gates above; (2) the
  MiSTer lane is `release` (a release ships `release/<name>/mister/`), which
  makes a release cost the Verilator lane — hours, and `--lane mister` is
  opt-in for that reason; (3) the four `dev-ladder` gates still exercise the
  BUILDER, so an argument exists for calling them release-scope pipeline
  locks. No change is needed for the arc to proceed; the ruling decides what a
  release hard-fails on.

- **~~THE `gap_be27a` / `gap_be2ba` BANK-MAP ROWS ARE WRONG~~ DECIDED
  (maintainer, 2026-09-03) AND **EXECUTED 14z-130** — folded into the M13
  registration, *"if folding it in allows us to pay only once, that's an easy
  choice: fold it in!"*.** **WHAT SHIPPED:** the two rows became ONE
  `capture_kf_ptr` (`0x0BE27A`, `data_ptr`, `stride 0x80`, `region auto`) and
  the table's hand-ownership was made explicit in the generator, so the
  generic repoint is suppressed. **BYTE-NEUTRAL on all five M13 tracks by
  rebuild** (fingerprint and `patch.json` sha1 identical either side).
  **THE [VSP-10] QUESTION THIS ENTRY RAISED DOES NOT ARISE**, because the two
  candidate pointers are not equivalent: the shipped `0x004010e0` carries
  `0x0d88` at `+0x1E` and the block the generic repoint would have chosen
  (`0x003fbda2`, the hitbox-region copy) carries the UNFIXED `0x0b30` — i.e.
  letting the generic path win would have silently reverted the 14z-64
  mirror-victim fix. Preserving today's bytes is the answer, and it is a
  preservation decision rather than a gameplay one.
  **ONE FIGURE IN THE ENTRY BELOW IS WRONG AND IS CORRECTED HERE:** it says
  "the ~9 writes per tenant that the `auto` containment currently leaves
  unexempted come back under exemption". **Measured: only ONE does** — row
  `0x18` (Oboro) — plus each tenant's OWN row where it has one (`0x13`
  donovan, `0x10` huitzil; pyron has none). Rows `0x08-0x0F` STAY in the
  inventory, correctly: they are LEGACY attacker rows. The root fix NARROWS
  the exemption; it does not restore the hole. Inventory counts D/H/P
  114/112/100 -> 115/113/102 (the +3 each is the M13 boot title).
  Detail: patch_notes 14z-130; gate `tests/test_capture_kf_ownership.sh`.
  Original entry follows. The three couplings
  that make one window cheaper than two, each verified 14z-129 rather than
  argued: (1) `charmap_gen.py` reads `bank_map.toml` directly (`--bank-map`,
  :364) and emits every table's tenant row, and those pages are hash-locked by
  `tests/expected/charmap_pages.sha256` — so a fix moves them and owes a
  charmap re-freeze; (2) `tests/test_m3a_reproducible.sh` pins fingerprints per
  freeze generation, so a bank_map change landing AFTER M13 is registered makes
  the registered fingerprints stale; (3) `build/manifest/shared_writes.toml` is
  per-build and per-write reviewed, M13 already owes it a re-point (the three
  `boot_title_saved_*` rows per tenant, reviewed at 14z-127), and the
  correction changes the exemption window — the ~9 writes per tenant that the
  `auto` containment currently leaves unexempted come back under exemption — so
  separating the two costs a SECOND review pass. The M13 builds exist on disk
  (`don_m19` / `hui53` / `pyron37` / `m5_stock14` / `m3b_merged22`) and are NOT
  in `registry.tsv`, so nothing is locked to them yet: this is the cheapest
  moment in the cycle to disturb them. **If the rebuild shows a named op delta
  rather than zero movement, that delta is understood BEFORE the freeze suite
  runs, not after.** Original entry follows. `bank_map.toml` models
  ONE 32-long table — the capture-keyframe pointer table `PRG:0x0BE27A`,
  entry size 4 — as TWO `kind = "auto"` rows of `stride = 0x40`, i.e. as two
  32-entry WORD tables. **Measured three ways that the entries are longwords:**
  bank_map's own `note` calls it "the 32-LONG capture-keyframe pointer table";
  `donovan.toml`'s `slot_ptr_table = 0xBE27A` places row 0x00 at 0xBE27A and
  row 0x01 at 0xBE27E; the values written are 32-bit ROM pointers.
  **Two consequences already measured.** (1) `audit_shared_writes.py` computes
  its variant-row exemption as `base + 0x10*es .. base + 0x20*es` with
  `es = stride/32`, so the wrong stride put the exemption on LONGWORD ROWS
  0x08-0x0F — eight LEGACY rows — and nine writes per tenant were invisible to
  the shared-surface guard. CONTAINED 14z-128 (a `kind = "auto"` row now grants
  no exemption at all), not fixed at the root. (2) The generated
  character-data pages read both rows at the wrong address —
  `docs/project/tables/chars/huitzil.md` prints `gap_be27a` at `0x0be29a`,
  which is BISHAMON's longword row, and donovan's `0x0be2a0` is not even
  4-aligned.
  **WHY IT IS NOT FIXED HERE:** the correction is one row
  (`vsavj = 0x0BE27A`, `kind = "data_ptr"`, `stride = 0x80`) replacing two,
  and the tiling is preserved exactly (0xBE27A + 0x80 = 0xBE2FA = `param32_b`).
  But `kind` is LOAD-BEARING: `extract_char.py` takes a different extraction
  path for `auto` than for `data_ptr` (:1289 vs :1321) and
  `gen_donovan_patch.py` gives `data_ptr`/`code_ptr` tables pointer treatment
  (:3514). So it can move BUILD OUTPUT, which makes it a measured change with
  a rebuild and a diff, not a manifest tidy.
  **PROBED 14z-129 (the measurement the ruling asked for, run before the M13
  window opens so its cost is known going in). THE ONE-ROW CORRECTION DOES NOT
  BUILD, AND THE REAL SHAPE IS AN OWNERSHIP QUESTION.** Two findings, in order:
  1. **`kind = "data_ptr"` + `stride = 0x80` is INCOMPLETE.** A `data_ptr` row
     also requires a `region` key — `extract_char.py:1291` dies
     `KeyError: 'region'` without one. `region = "auto"` is the right value
     (the 14z-111 #99 handling: the pointer's host is whichever extracted
     region contains it), and with it the build proceeds.
  2. **IT THEN COLLIDES, and the builder catches it:**
     `OP OVERLAP at 0x0BE2C6: op[86] poke32@0xbe2c6 then op[192] poke32@0xbe2c6
     — two ops write the same word and the later silently wins. Fix the
     generator (explicit ownership); do not reorder ops.`
     `0xBE2C6` is longword row **19 = 0x13 — DONOVAN's own slot**. The two
     values disagree: op[86] writes `0x003fbda2` (his placed region), op[192]
     writes `0x004010e0` (wide_ext). Ops 342 -> 343.
  **WHY IT COLLIDES:** modelled correctly, `gap_be27a` is a 32-long pointer
  table and the generic `data_ptr` path emits a pointer for every row —
  INCLUDING row 0x13, which `donovan.toml`'s `throw_victim_keyframes` /
  `grab_hold_keyframes` rows already repoint individually
  (`slot_ptr_table = 0xBE27A`, donovan.toml:831). While the row was `auto`
  with the wrong stride it emitted nothing there, so the conflict was hidden
  by the very defect being fixed.
  **SO THE M13 FOLD-IN IS NOT A MANIFEST TIDY.** It needs an explicit
  ownership rule between the bank_map table and the per-row repoint rows, and
  the rule decides which pointer Donovan's capture keyframes use — a
  throw/capture surface, so if the two values are not equivalent it is a
  [VSP-10] call, not a generator detail. Budget accordingly; the probe cost
  one build.
  **The tree is UNCHANGED — `bank_map.toml` was reverted and verified
  byte-identical to its pre-probe state.**

  **RECOMMENDED (and RULED — see the head of this entry):** do it in a
  build-touching window — rebuild one track,
  diff `patch.json` against the current freeze, and expect either zero op
  movement (then it is a pure map fix + a charmap re-freeze) or a named delta
  that has to be understood before it ships. Half a session. Meanwhile the
  containment holds and `tests/test_shared_writes.sh` section 4 locks it.
  **AND THE OTHER `kind = "auto"` ROWS ARE UNAUDITED:** 21 of them exist; only
  these two were exempting anything, but none of their strides is a
  measurement.

- **THE BOOT NAME SCREEN: "SAVIOR" -> "SAVED" — DECIDED AND SPECIFIED
  (maintainer, 2026-09-02), BUILT 14z-127 ON ALL FIVE TRACKS (mark M13),
  NOT YET REGISTERED — the registration is the arc's own next step.** Scoped and measured 14z-127; the
  mechanism and the trap are in `docs/game/gotchas.md` "THE BOOT NAME SCREEN'S
  DISPLAY SCRIPT TAKES AN EVEN COLUMN".
  **THE EDIT, at its strict minimum (maintainer: "minimal change (i.e. e, d,
  space instead of i, o, r) is perfect for me"):**
  one `data` op, **`PRG:0x01C822`, 6 bytes word-aligned, `" I O R"` ->
  `" E D  "`** — 3 bytes actually differ (`0x01C823` I->E, `0x01C825` O->D,
  `0x01C827` R->space). One program member — **`vm3j.03d`**, ~~`vm3j.10b`~~
  **CORRECTED 14z-130**: measured by member diff on all three tracks at the
  M13 freeze (merged-m14 -> merged-m15, donovan-m18 -> m19, and the stock
  twin), the changed program member is `vm3j.03d` every time. The three
  differing bytes are at ODD addresses (0x01C823/25/27) and vm3j.03d is the
  odd half of the first program pair, so it could not have been anything
  else. The start-COLUMN byte
  is NOT touched: the shorter title simply ends one character earlier and sits
  marginally left of where it did. **Verified: the minimal-span build is
  BYTE-IDENTICAL to the 30-byte-span build that was booted and photographed.**
  **BLAST RADIUS, MEASURED not argued:** work-RAM checksums patched-vs-pristine
  are **IDENTICAL across 1,621 frames of boot and attract**, so no RAM-basis
  expectation moves and the legacy corpus does NOT re-freeze. Same length, so no
  relocation and no shifted coordinates. It is TEXT, not authored tiles — the
  glyphs are an existing gfx-ROM font, reused, so no tile or font work.
  **SCOPE, ruled the same day:** JAPAN entry only (`0x01C806`'s first record) —
  *"Our region of reference is Japan anyway"*; the other six region entries are
  left alone. **The TITLE SCREEN is NOT touched** — *"the fact that the
  character wheel is different is differentiator enough"*.
  **AND A STANDING PRINCIPLE, in the maintainer's words:** *"staff references
  should be intact, after all it's a Capcom game made by Capcom staff, and
  especially since we restored dead code from them, virtually nothing we did was
  a true novelty compared to their creations."* So the staff-roll strings
  (`PRG:0x01301A`, `PRG:0x01D96A`) are NOT to be edited, now or later.
  **WHY NOT BUILT YET:** a manifest row means a rebuild and a re-freeze (new
  fingerprint, registry row, patch_notes, battery). Fold it into the next
  freeze rather than opening one mid-session.

*(Cleaned 14z-109, maintainer-directed: resolved and no-longer-shaping
entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*

- **#112's FIX — DECIDED (maintainer, 2026-09-02): (C) DO NOTHING TO THE
  BUILD — *"yes it's (C) BUT we keep the option (B) fix as possible in the
  future because depending on the scoping, it may still be a valuable
  option."* So (C) is the ruling for now and **(B) IS NOT CLOSED**: it stays a
  live candidate whose value the scoping below decides. (A) remains refused.
  The half-session that would let (B) be costed — is there a FREE PALETTE ROW,
  and do pool objects carry `+0x30`/`+0x382`/`+0x3AE`/`+0x18B`? — is
  UNSCHEDULED but no longer hypothetical: it is the gate on a decision the
  maintainer has explicitly left open. Scoped 2026-09-01 at their direction
  ("I'd want to scope the second properly before recommending it -> do it").**
  **THE SELECTION POINT, measured:** the palette source is
  `base + seq_id*32` with the base CONSTANT — Donovan's `+0x3A4` is written
  exactly twice in a 14,375-frame run (round starts, `PC 0x01C68E`, value
  `0x0CEB50`) and `[0x38C1E4]` holds the same pointer. So nothing about the
  base or the blocks varies: **only the SEQ ID does** — `1` for the default
  (Donovan's body palette, idx14 = `f111`) and `46` for the effect
  (idx14 = `fcff`). The black foot is seq 1 being re-requested 29 frames
  before the pool object finishes drawing.
  **THE PIECES AND WHO OWNS THEM** (all verified against `vanilla_op/data`):
  the copy routine `0x02AD20-0x02AD80` is VANILLA, byte-identical; the base
  pointer at `[0x38C1E4]`, the palette blocks at `0x0CEB50+`, the char-table
  row for id `0x13`, the resolver hook at `PRG:0x3FFAF0` and the palette
  animator at `PRG:0x471560` are ALL OURS (vanilla holds `0xFF` filler or a
  different pointer at each).
  **AND THE PORT ALREADY HAS OWNER-AWARE EFFECT PALETTES.** `0x3FFAF0`'s
  second branch reads the drawing object's OWNER (`+0x30`) and, if the owner
  is Donovan, resolves `[0x38C1E4] + owner(+0x3AE)*128`. It exists and is
  shipped — but it is NOT exercised here: all 24 palette writes in the window
  carry `A6 = $FF8400`, the PLAYER. The effect's sprites simply draw with
  pal row `0b`, which the player's machinery fills.
  **OPTIONS:**
  **(A) Delay the revert** — gate the seq-1 request while an owned effect is
  alive. Smallest byte-wise, WORST placed: the request site is on a path every
  character runs, so it needs a tenant-only condition on legacy-reachable
  code, plus a flicker-inventory measurement. It also changes WHEN a legacy
  data path writes, which is the class the superset invariant exists to
  refuse. NOT RECOMMENDED without a much stronger reason than a cosmetic.
  **(B) KEPT OPEN AS A FUTURE OPTION (maintainer, 2026-09-02) — The effect owns its palette** — make the pool object request its own
  palette into its own row via the EXISTING owner branch. Architecturally
  right and reuses shipped machinery. **COST, and it is the reason this is not
  free: it needs a FREE PALETTE ROW** (unmeasured, and rows are scarce), the
  pool object must carry the fields the hook reads (`+0x30`, `+0x382`,
  `+0x3AE`, `+0x18B` — none verified present on pool objects), and every
  effect sprite record must be repointed to the new row. Two to three
  sessions, and a new render gate.
  **(C) RULED (maintainer, 2026-09-02) — DO NOTHING TO THE BUILD, and say why
  in the docs.** The
  defect is one palette entry on one frame of one super, on a build the
  maintainer has already accepted as cosmetically imperfect. What CHANGED
  today is not the cost of a fix but the QUALITY OF THE RECORD: the mechanism
  is fully known, the 2026-08-28 "vanilla data" objection is retired as
  FALSE, and the work is now a scoped engineering task rather than an
  unknown. That is worth banking without spending a freeze on it.
  **WHAT IS STILL UNMEASURED, and (B) cannot be costed without it:** whether a
  free palette row exists, and whether pool objects carry the four fields the
  owner branch reads. Both are half a session.

- **THE COMMUNITY CROSS-CHECK — our data vs the best community reverse
  engineering (maintainer backlog item, 2026-08-31, 14z-124). ~~RECORDED, not
  started~~ PHASE 1 DELIVERED 14z-125 (the maintainer's order: "start with item
  2 to get proper confirmed data"): all 15 vanilla characters derived, the
  standing-normal join MEASURED in-emulator, and every comparable column
  classified — ~96% agreement per move under one stated convention each
  (`docs/project/tables/community_crosscheck.md`, gates
  `test_community_crosscheck` + `test_vanilla_frame_join`). STILL OPEN, and
  named on the page: **~~the residual ~4% outliers are not yet arbitrated
  in-emulator~~ ARBITRATED 14z-125b — two of the three families closed (the
  damage residue is the WORKBOOK double-counting records that share the engine's
  +0x10 dedup key, confirmed by a hit rig 75/78; the duration bytes are the
  engine's, 334/380, but a frame-rate trace cannot resolve a one-frame
  convention, so startup +1 / recovery +2 stay named conventions). ~~STILL OPEN:
  Jedah's crouching recovery (+3, not +2)~~ **CLOSED 2026-09-02 — ARBITRATED IN
  ENGINE TICKS, AND THE RESIDUE IS THE WORKBOOK'S.** The instrument the entry
  said did not exist does: a write tap fires per WRITE, and `PRG:0x027F70`
  (`subq.b #$1,$20(a6)`) IS one engine tick, so the multi-tick frames that
  defeated the frame-rate trace are fully visible. **18 of 18 derived totals
  equal the engine's measured tick count EXACTLY** (JE, LI, DE crouching
  normals; no tolerance). Our `startup` and `active` are not flagged and agree
  with the workbook's own conventions, and the total is now ground truth — so
  our recovery is right and the workbook's sits one frame below its own
  convention for those seven moves. `tools/tick_durations.py` +
  `tests/test_tick_durations.sh` (with a must-fire control). **THE SEVEN AERIAL OUTLIERS — PARTLY RESOLVED 2026-09-02.**
  `tick_durations.py` separates the move from the jump for chains that LOOP
  (BI 5/6 exact; the miss is the flagged `J.HP`, ours 28 vs the engine's 27; BU
  `J.LK`/`J.LP` exact). NOT separable yet: aerials whose last node HOLDS with no
  further pointer write before landing (VI, FE, SA) — those still report
  AIRTIME, and identical numbers across a character's moves are the tell.
  **THE LIKELY CAUSE IS NOW NAMED, from the community corpus that arrived
  2026-09-02:** mizuumi distinguishes NEUTRAL-jump from FORWARD-jump variants of
  the same button (`8J.LP` vs `9J.LP`, `J.HP8` vs `9J.HP`) where our slot map
  carries ONE chain per aerial button. If the flagged moves are exactly those
  whose variants differ, we are collapsing a variant, not miscounting. Needs a
  two-direction jump rig; not yet measured.
  ~~`red damage` needs the [VSE-40] scaler to be comparable at all~~ **WRONG and
  RETRACTED 14z-125b: the workbook's `red damage` is our `+8` PLUS `+9`, the
  move's total — 266/281 (94%) once compared as the sum;**
  specials / supers / throws / the `CL.` and `6`-prefixed rows need their own
  vsavj naming rigs (the bulk of the workbook's 730 rows); seven workbook
  columns have no counterpart in the tree. The WIKI half — the 146
  player-struct offsets against `ram.md` — was DEFERRED by the maintainer this
  session to item 1's session, whose lead `+0x1B3` sits in the same table; note
  the page carries NO per-move frame data, so it was never a second frame-data
  source. The original entry follows.** Two sources the maintainer will provide: a
  WEBPAGE, and an EXCEL of frame data for the VANILLA characters. What we
  have: frame data DERIVED for the three tenants only (`docs/project/tables/
  chars/<tenant>_anim.md` "Frame data (derived): startup / active /
  recovery", read off anim-node durations + attack records by the charmap,
  phase 2, 14z-120/121; move identities measured on native vs2 by
  `test_move_naming`), and NOTHING collected for vanilla characters; the
  derivation has never been checked against an independent source. Plan:
  (1) inputs — the URL and the `.xlsx`, kept OUTSIDE the tree (third-party
  work; we commit only our comparison and cite the source); (2) derive the
  same figures for the vanilla characters from vsavj's own 32-row bank
  (does `tools/charmap_gen.py` walk a vanilla character? if not, extend it —
  the bank is per-character by law) and compare per move: startup / active /
  recovery, damage, hit counts; (3) every mismatch is MEASURED in-emulator
  on vanilla (a replay + field_trace) — the emulator is the arbiter, not the
  sheet and not our derivation; (4) if the sources cover vs2, compare the
  tenants' derived figures the same way. Deliverable:
  `docs/project/tables/community_crosscheck.md` + a gate freezing the
  agreements and naming the measured disagreements. Cost: T3, one to two
  sessions. **INPUTS RECEIVED 2026-08-31 + THE RULE, maintainer's words:**
  "measurement is king, not a source that we don't know how it was measured;
  however, community information is precious: if it aligns perfectly or
  with a constant offset, then we know the measure is good; if we find an
  inconsistent pattern, then we must search whether the measurement is
  correctly done or not." So every column's deltas are classified EXACT /
  CONSTANT OFFSET (a convention difference — state it) / INCONSISTENT (a
  defect in somebody's measurement — re-measure OURS in-emulator first).
  The sheet: `../community/vsav-framedata.xlsx` — 15 sheets = the 15
  vanilla characters (FE AN AU BI BU DE GA JE LE LI MO QB SA VI ZA; ~37-68
  moves each), per move `startup / active / recovery / on hit / renda on
  hit / on block / renda on block / throw tech / red damage / white damage /
  gauge whiff / gauge block` (AN adds gauge hit / cancel / guard);
  multi-hit actives as text (`2(4)3,2`, `3{(3)3}x6`); NO vs2 characters, no
  Oboro / Dark Gallon. **Sheet names = the first two letters of the
  JAPANESE character name (maintainer-confirmed 2026-08-31), mapped to our
  ids:** BU Bulleta `0x00` · DE Demitri `0x01` · GA Gallon `0x02` · VI
  Victor `0x03` · ZA Zabel `0x04` · MO Morrigan `0x05` · AN Anakaris `0x06`
  · FE Felicia `0x07` · BI Bishamon `0x08` · AU Aulbath `0x09` · SA
  Sasquatch `0x0A` · QB Q-Bee `0x0C` · LE Lei-Lei `0x0D` · LI Lilith `0x0E`
  · JE Jedah `0x0F` (the two to not confuse: LE = Lei-Lei, LI = Lilith).
  The webpage:
  https://mizuumi.wiki/w/Vampire_Savior/Reverse_Engineering ("arguably the
  best source of deep information on Vampire Savior") — BLOCKED for any
  fetcher by a bot challenge (WebFetch 403; curl with a browser UA gets the
  challenge page) — **RESOLVED 2026-08-31: the maintainer saved it as a PDF**
  (`../community/Vampire Savior_Reverse Engineering - Mizuumi Wiki.pdf`,
  74 pages; text extracted with `pypdf` in a scratch venv — poppler is not
  installed — to `../community/mizuumi_reverse_engineering.txt`, 74 K
  chars, 421 address tokens). Both sources stay out of the tree.
  **FIRST-PASS INVENTORY of the wiki page (14z-124; an inventory, NOT an
  adoption — nothing in the atlas changes until measured):** sections =
  the CPS2 memory map, the IVT, RAM maps by base (`$FF8000` globals, `$FF8280`
  stage/camera, `$FF8400/$FF8800` the player struct — CPS2 AND the PS1
  `MIPS 0x8D8400` mirror), graphics/palettes/raster matrices, ROM function
  and per-character data/function tables, per-character move
  "Conditions" (pp. 25-63), data structures, palettes, backgrounds, HUD.
  Method not stated (credits "Thanks Jed"; disassembly-shaped comments);
  region unstated — but `0x275CE` / `0x28D50` / `0x2246E` sit exactly at our
  vsavj addresses. Their player struct: 146 offsets, 52 also named in our
  `ram.md`, 94 only theirs (candidates), ~50 only ours. CONVERGENCES with
  our measurements: `+0x110/+0x111/+0x176` the vsavj DF fields (they name
  `+0x17B` "Dark Force Flight" — Huitzil's form), `+0x189` DF timer
  reduction, `+0x3B4` "CPU Opponent Flag"; and the 14z-123 advancing guard
  field for field under VS's OWN NAME, **Tech Hit**: `0x275CE` "Tech-Hit
  Checks", `0x28D50` "Tech-Hit Chance Tables" (our RNG table), `+0x170`
  Tech Hit Input Counter, `+0x171` Tech Hit Active State (0x10 frames — the
  consumer we never traced), `+0x1AB` Tech-Hit Timer, `+0x1B0` Push-block
  Push-back Timer, `+0x126/+0x127` Mash to Escape. DIRECT LEAD for the DF
  backlog item: **`+0x1B3` "Dark Force Startup"** and `+0x1B5` "Dark Force
  type-2 (HP+HK)" (we had read `+0x1B5` as set by JUMPING — a disagreement),
  `+0x147` "Invincibility Timer" (ours: the multi-hit re-hit gate —
  compatible), `+0x143` Throw Invulnerability Timer; ROM `0x26FD2` DF
  Activate / `0x2706E` DF Deactivate bracket our activation body `0x027000`.
  DISAGREEMENTS to measure: `+0x161` "Oboro Fight Flag" vs our live-measured
  Sasquatch DF accumulator (`audit_df_accumulator`, 9 frozen lines — ours is
  a measurement, theirs a name; the byte may serve both); `0x2246E` "System
  Timer Reducers" vs our "class-0xFF block handler" (14z-123). Naming to
  adopt after measurement: "Tech Hit" beside "advancing guard". **BOTH
  RESOLVED 14z-126 (the opcode listing): `0x2246E` IS the System Timer
  Reducer (one `subq.b` per tick on `+0x147/+0x174/+0x143/+0x158/+0x1AB`);
  the block window is OPENED by the block-entry handler `0x2395A`-`0x23966`
  — 14z-123's write tap had named the decrementer, corrected in `ram.md`,
  engine_internals and `test_advancing_guard.sh`; and `+0x161` is a
  per-character DF WORK BYTE written by Sasquatch's (the measured
  accumulator), Bishamon's, Anakaris's and Aulbath's handlers — mizuumi's
  "Oboro Fight Flag" is Bishamon/Oboro's use of it: both names true. Four
  wiki rows adopted into `ram.md` with the mechanism measured or read
  (`+0x134`, `+0x145`, `+0x143`, `+0x1B3`); the other ~90 candidates stay
  unadopted [C].**

- **ZABEL j.LK PROXIMITY GUARD — A LEGACY-CONTENT PATCH, ITS OWN SESSION
  (maintainer, 2026-08-30, 14z-122). RULED as the SECOND of two future items;
  not started.** The maintainer's report, in substance: Zabel's j.LK does not
  trigger proximity guard properly — "afaik it does, but not all the time it
  should, and definitely unlike any normal of any character". The ask: a
  SURGICAL patch for BOTH vanilla vsav and the WIDE build that corrects this
  and nothing else — no side effects. What that implies for the session that
  takes it: (1) it is a deliberate change to LEGACY behaviour, so by
  definition outside the superset invariant's "untouched" set — it needs its
  own ratified expectation class and its own build flag (CLAUDE.md §1/§4; a
  stock `vsav` patch is a NEW track, not the stock twin); (2) [VSP-20]
  first — a hand-played MAME recording of the whiff BEFORE any theory;
  (3) [VSP-14] — archaeology on "proximity guard" across STATE_HISTORY and
  the engine docs before measuring; (4) measure vanilla's proximity-guard
  test against every other normal (the maintainer's own comparison class)
  so the fix is bounded by a measured difference, not an impression.
  Recommendation: a data-side fix on Zabel's j.LK record (the guard-range or
  a record flag) if the difference is in his data; a code-side change only if
  the engine special-cases the move. Nothing decided beyond "its own session".
- **DARK FORCE STOCK COST FOR THE TENANTS (14z-120, found by the naming rig). DECIDED (maintainer, 2026-08-30): option (a) — the character-specific DF at VS (vanilla) cost is ON PURPOSE; "vanilla stays untouched and guides how the game should be played"; adjustments, if any, will be per character, never to the general mechanic.** On native vs2 Donovan's Slay Shred spends TWO stocks (`+0x109` 9 -> 7 at activation; Huitzil measured the same 14z-69); on our vsav engine every Dark Force, tenants included, spends ONE (the two engines run different DF systems, [VSE-69]). So a tenant's DF is cheaper here than at home. Options: (a) keep vsav's 1 stock — every character in this cabinet pays the same, "vanilla wins ties" [VSP-21]; (b) charge the tenants VS2's 2 stocks (a per-character cost hook the vsav engine does not have — new code on the DF path). **Recommendation: (a).** Note also (maintainer, 14z-120): Phobos's and Pyron's physics rows were CHECKED — `port_param32 = true` in both manifests and every value field of the 32-row bank equals VS2 for all three tenants (the map, `docs/project/tables/chars/*.json`; only relocated pointers differ). What the bank does NOT cover — throw-arc rows, hit-freeze tuning, the generation-drift class [VSE-6] — is phase 2's measurement.
- **DONOVAN'S PHYSICS ROWS (14z-118, found by the character-data map). DECIDED (maintainer, 2026-08-29): "use VS2 parameters and not the shell character's" — option (a); `port_param32 = true` set, probe + soak below, freeze at the next battery. **FROZEN 14z-119 as donovan-m18 / merged-m14 (M12); the stock twin moved with it, by design — STATE 14z-119.**
  `param32_a` (walk fwd/back), `param32_b` and `jump_params` (three jumps x
  xv/xaccel/yv/gravity) are NOT ported for Donovan: `build/manifest/donovan.toml`
  carries no `port_param32 = true`, so gen's `VALUE_SKIP` leaves his bank
  rows at the vsavj alias — **Victor's** values (row `0x03`). Measured on
  `build/don_m17`: walk 2.5 / −2.25 vs VS2's 3.0 / −2.625; back-jump xv
  −3.625 vs −4.25, neutral yv 8.0 vs 7.75, forward yv 8.0 vs 7.875, gravity
  −0.352 vs −0.375 (16.16). Huitzil (14z-66, after his own soak) and Pyron
  port theirs. The skip was the 14w-b crash guard written for the slot-0x0F
  port ("Jedah speeds retained"); whether the hazard survives the move to a
  variant id was never re-examined for Donovan. **Options:** (a) set
  `port_param32 = true` for Donovan and run the same soak battery Huitzil
  ran (RECOMMENDED — VS2-faithful movement is the project's default; the
  cost is one freeze); (b) keep Victor's physics deliberately (record it as
  a tuning decision in `charmap_donovan.toml`'s header so the map stops
  flagging it). Gameplay feel: the maintainer's call.

- **THE `docs/project/tables/` PROMISE (14z-118, from the documentation
  audit's inventory `docs/project/doc_audit_14z118.md` §3). DECIDED
  (maintainer, 2026-08-29): option (a) — generate the two missing
  manifests and refresh all three.** The
  directory's README says "per-character data manifests for Donovan /
  Huitzil / Pyron" and still opens with "Empty until a ported character
  exists"; it holds `donovan.md` (2026-08-09, never refreshed) and no
  Huitzil or Pyron file. CLAUDE.md §2 rule 5 ([VSP-6]) makes these the
  community-facing tunables. Options: **(a) generate `huitzil.md` /
  `pyron.md` with the extractor that produced `donovan.md` and refresh all
  three from the current manifests — RECOMMENDED, it is what the rule
  says;** (b) retract the promise and name `build/manifest/*.toml` as the
  table of record. Blocks audit step 5 only; steps 1-4 proceed.

- **THE TENANTS' WIN QUOTES — FORGONE FOR NOW (maintainer, 2026-08-28,
  14z-116). DECIDED.** The ruling, verbatim in substance: *"Let's forgo for
  now but document everything so that, should we want to do it in the
  future. And should we ever do it, we'd do it the clean way, not touching
  vanilla."* So this is PARKED, not closed, and it is parked WITH A
  CONSTRAINT ON ANY FUTURE ATTEMPT: **the clean way only — the vanilla bank,
  the four-entry region root, tables A/B and `RAM:$FFF230`'s vanilla value
  all stay byte-identical. The 14z-76 whole-bank relocation is RULED OUT by
  this decision, not merely un-preferred.** The buildable shape is the one
  measured below (group C bank 5's blank font window + the shipping
  `winquote_bank_variant_id` gate + one tenant-only selector thunk), and the
  single open measurement before it could be scoped is named there. Nothing
  in the tree needs undoing: Phase 0 shipped only tools, a gate and
  corrections. Everything below is the measurement record.

  PHASE 0 AS MEASURED (14z-116): The maintainer's framing for this task: cosmetic, no 2P surface,
  so equip the suite against a silent state poison — and **forgo it outright
  if the implementation carries structural risk or costs compatibility**.
  Phase 0 was run before any shipped byte. What it found:
  - **A data-only fix is IMPOSSIBLE, confirmed.** `tools/scan_quote_window.py`
    re-derived the 14z-76 prose claim as a script: **zero** runs of `0x20`+
    free bytes within `±0x8000` of the bank base, and zero around any of the
    16 winner blocks (the second hop). A control at `0x8` finds exactly one
    9-byte run, so the scanner is not blind.
  - **The 14z-76 relocation plan is wrong in three places** (all corrected in
    place, `engine_internals.md` §8 + the `patch_index.md` header): the root
    is a FOUR-ENTRY REGION array whose other three banks are the ENGLISH
    text, not one long; the bank is `0x4104` bytes, not `0x40DC`; and lines
    can be 17 codes — the real bound is the renderer's own 66-word buffer,
    which is exactly what a bad offset overruns.
  - **The relocation is NOT legacy-invisible.** `move.l a1,$30(a4)` installs
    an absolute bank pointer at `RAM:$FFF230`, measured live during the
    VANILLA win screen (replay 23 `0x00331136`, replay 28 `0x0033101E`). So
    the deferral's "change one long" would move legacy work RAM on every
    win-reaching replay and buy a permanent superset-invariant tax, with a
    new ratified class per replay, for a cosmetic.
  - **THE REAL COST IS GLYPHS, and nobody had measured it.** The three vs2
    tenant blocks use 331 distinct codes; at the shared font base **326 of
    327 non-pad codes draw a DIFFERENT character in vsavj**. Every glyph
    DOES exist in vsavj — but at tiles `0x22000-0x2FFFF`, gfx **bank 1**,
    unreachable from a 12-bit code in the quote object's bank — and vsavj's
    bank-0 font window is **4096/4096 non-blank**, so there is no free slot
    to remap into. A code remap cannot fix this: ~330 glyph tiles must
    travel, which no version of the 14z-76 plan budgeted.
  - **AND THERE IS A CLEAN ROUTE, if you want it.** Group C **bank 5's**
    font window (in-group `0x13800-0x147FF`) is **4096/4096 blank** on
    `build/m3b_merged18`, and the shipping `winquote_bank_variant_id` gate
    (14z-62j, `site 0x05F328`, `only_variant_slot`) already flips the
    win-quote drawer to bank 5 on a TENANT WIN ONLY. So the glyphs can be
    authored into space we own, by the same mechanism the 14z-115 outline
    sprites used, with **no vanilla tile touched**; the text would ride one
    `site_thunk` on the selector for winner `>= 0x10`, leaving the vanilla
    bank, the root array and `$FFF230`'s vanilla value byte-identical.
    **NOT YET MEASURED, and it is the one thing left before a build could be
    scoped:** whether the TEXT object (set up at `PRG:0x00C840-0x00C862`,
    fed by `$30(a4)`) takes its bank from the same field that gate writes —
    the gate patches the drawer object at `0x5F328`, which is a different
    chain. If it does not, the thunk writes the bank itself.
  **THE PRICE THAT DECIDED IT:** ~330 authored glyph tiles + a thunk on a
  legacy-reachable site + a new win-quote RENDER gate (pixels — no RAM gate
  can ever see text), for a single-player cosmetic surface the standing
  "cosmetic is optional" scope calls nice-to-have. **RESUMING IT LATER
  COSTS NOTHING EXTRA**: the decoder, the font audit, the reach scan and the
  structure gate are all in the tree and green, so a future session starts
  at Phase 1 with the one open measurement, not at archaeology.

- **THE MiSTer SCOPE DOCUMENT — three decisions, ALL DECIDED (maintainer,
  2026-08-28, 14z-113; `docs/project/mister_scope.md` §8).**
  (1) **The split stands as written** ("in line with what I would do";
  the maintainer defers on the CPS-II-vs-VS specifics and follows the
  recommendation, MRA mechanics at level 1 included).
  (2) **The staleness pass (S1-S20) is MANDATORY before any distillation
  — but WAITS for the board results the maintainer is producing in
  parallel right now** (the #113 hand check and bundle 14z112's stock
  coexistence), so the pass lands on a settled state and does not have to
  be re-done. **Sequencing: board results -> record them -> the S1-S20
  pass (one commit) -> only then the skills.**
  (3) **The `.rbf` AND the MRAs are TRACKED IN-TREE** — the maintainer's
  ruling: they belong with any BPS/xdelta used to patch vanilla ROMs, i.e.
  under `release/`. **This opens a NEW item, the MiSTer RELEASE FORMAT**
  (below): what a `release/<name>/` carries for MiSTer, how and where it is
  generated, and its provenance record.

- **DOES THE STOCK CONTROL MRA STILL HAVE A USE? (maintainer's question,
  2026-08-28, after it booted fine on bundle 14z112.) DECIDED (maintainer,
  2026-08-29, 14z-118): KEEP IT, RE-SCOPED — run once per NEW `.rbf`
  (seed / slice / pin), off the per-release checklist; stays in every
  release's `mister/`. The recommendation as it was put:** It was built (14z-109) to separate a fault in our
  PROFILE from one in the bitstream/card/module/video chain, at a time when
  the bundle's `vsav.zip` was patched and no stock MRA could serve as a
  control. Two of its three jobs are now done by something else: a stock
  MRA on Jotego's own core covers "the board/card/module is fine" (and it
  just did), and the shared pristine `vsav.zip` means no bundle can poison
  stock art any more. **The job nothing else does: it is the EMULATOR
  SUPERSET INVARIANT ON SILICON** — stock `vsavj` running on OUR `.rbf`
  with the profile bit at the `0xFF` fill, i.e. CLAUDE.md rule 1 v2's
  "the patched binary running stock is untouched by construction",
  measured on hardware rather than in Verilator (`test_mister_wide_inert`
  is the simulated form). That claim is about the BITSTREAM, so the control
  needs running **once per new `.rbf` (new seed / new slice / new pin),
  NOT per romset release** — the `.rbf` has not changed since 14z-108, so
  today's pass covers it until the next synthesis. Cost of keeping: one
  XML file in the bundle and one line in the README. Recommendation: keep
  it in the release format (the MRAs are tracked in-tree now), label it
  "run when the bitstream changes", and drop it from the per-release
  checklist. Dropping it outright is also defensible — the maintainer's
  call; no gameplay surface.

- **THE RELEASE FORMAT — DECIDED (maintainer, 2026-08-28, 14z-113) AND
  IMPLEMENTED FOR merged-m10.** The ruling, verbatim in substance: the
  `release/<name>/` recommendation below is accepted WITH the caveat that
  **each platform is self-sufficient per format — not every file at the
  same level; each platform directory holds everything that platform needs
  and only that** (FBNeo needs nothing MiSTer and vice-versa; platform
  drivers packaged with their platform), and **every version releases all
  platforms even when the change touched one.** Two details I asked and the
  maintainer chose: the patch set is COPIED into each platform dir (not one
  shared dir + per-platform zips); FBNeo/MAME carry the driver PATCH + build
  recipe, not binaries. Spec `docs/project/release_format.md`; producer
  `tools/package_release_platforms.py`; gate `test_release_roundtrip.sh`
  §4; first instance `release/merged-m10/{fbneo,mame,mister}/` (manifests
  byte-identical). **Refined the same day (maintainer): the bitstream is a
  BUILD RESOURCE, canonical at `release/bitstreams/<seed>/` with `CURRENT`,
  hash-verified into every release, never copied from another release** —
  the `.rbf` (seed 18269, sha256 `46fc74af…`) is in the tree there and in
  `merged-m10/mister/`. The recommendation as it was put:
  *What ships.* `jtcps2w.rbf` (3.1 MB; GPL-3.0 output of a public fork, not
  ROM content — rule 7 is not engaged), the two MRAs (WIDE + the
  `[STOCK CONTROL]` reference leg — XML metadata: names, CRCs, offsets), and
  a provenance record: fork pin, **seed, reported slack, sha256, build
  datestamp** (the hash identifies the artefact, the seed the result —
  `mister.md` "REPRODUCING THE SHIPPING BITSTREAM"). NOT the `.rom`
  (ROM-derived, rule 7) and NOT any zip.
  *Where.* Recommendation: **inside the same `release/<name>/` as the
  xdelta package**, e.g. `release/merged-m9/mister/{jtcps2w.rbf, *.mra,
  BITSTREAM.txt}` — one release = one directory for all three
  implementations, which is what `package_release.py` already promised
  ("MiSTer later adds a DISTRIBUTION layer over the SAME members", HANDOFF).
  Alternative: a separate `release/mister/` keyed by bitstream, since the
  `.rbf` changes on a DIFFERENT cadence from the romset (it did not move
  from 14z-108 to 14z-112 while the romset moved three times). The two can
  coexist: the bitstream lives once under `release/mister/<seed>/` and each
  romset release's `mister/` holds the MRAs plus a pointer to the bitstream
  it was verified with.
  *How generated.* The MRAs already come from `tools/mister_mra.sh --no-rom`
  (ROM-free, deterministic); the bundle assembly is by hand today
  (`../mister_fieldtest_14z11x/` + README + FIELD_TRIAGE). The natural home
  is a `--mister` mode of `tools/package_release.py` (or a sibling
  `package_mister.py`) that copies the MRAs, verifies the `.rbf` against the
  recorded sha256 and refuses on mismatch, writes the provenance record,
  and runs `check_mra_parts.py` against the release's own members. Gate:
  `test_release_roundtrip.sh` gains a MiSTer leg (MRA parts resolve, hash
  matches record).
  *What it retires.* The out-of-tree field bundles as the only carrier, and
  S18 of the scope document (the untracked `.rbf` path).
  **Not started; waits behind the board results and the staleness pass by
  the maintainer's own sequencing.** No gameplay surface.

- **#112 — ROOT-CAUSED 2026-09-01 (14z-126b): AN OVERWRITE RACE ON PALETTE
  ROW `0b` INDEX 14. Still cosmetic, still accepted — this is knowledge, not a
  fix.** The foot is **row `0b` index 14**, NOT row 05. Row `0b` is written by
  VANILLA engine code (`PRG:0x02AD64` + `PRG:0x02AD78`, a 16-entry palette
  copy; both well below the relocated tenant region). Index 14's DEFAULT value
  is `f111` = rgb(17,17,17), near-black; the effect's own load writes `fcff`,
  bright cyan. Measured over f13400-14375 with `tests/lua/tap_writes.lua`
  (memory tap, no debugger, so playback stays frame-exact): **24 writes to
  index 14, only TWO of them `fcff` — one per Press of Death.**
  * CLEAN: `fcff` at **f13589** survives 56 frames to the foot draw at
    **f13645**.
  * BLACK: `fcff` at **f14313** is **OVERWRITTEN back to `f111` at f14341**,
    29 frames before the foot draws at **f14370**.
  Both values come from the SAME PC, so it is the SOURCE that differs — two
  palette-sequence requests racing, not a bad code path. That is why it is
  intermittent and cannot be reproduced on demand, and it is consistent with
  14z-112's own "the move only reaches the lift phase on some outcomes".
  **THREE PRIOR CLAIMS RETRACTED, all measured on merged-m14:** (a) "draws
  `bbe5`/`bbea` at pal 05 where every clean instance draws `0xe768-0xe796`" —
  those are DIFFERENT ANIMATION PHASES; clean f13645 and black f14370 have
  BYTE-IDENTICAL pal-05 entries (16 codes, same attrs/sizes, same `a18`/`a19`,
  differing only in x/y); (b) "real art fetched from the wrong place" — same
  art, same composed addresses; (c) "not a palette fault" — it IS one, on row
  `0b`. Row 05 is genuinely constant across the whole 14,400-frame run, which
  is why checking it alone said "no palette fault".
  **THE FOOT<->ROW LINK IS NOW CAUSAL, NOT CORRELATIONAL (2026-09-01, after
  the maintainer asked "is it truly complete?" — it was NOT).** As first
  published, "the foot is row `0b` index 14" was ASSERTED from a colour
  coincidence (`f111` = rgb(17,17,17) being the commonest colour near the
  effect) and from comparing pixel boxes at the SAME SCREEN COORDINATES in two
  frames where the effect sits at DIFFERENT positions — i.e. mismatched
  content. That was correlation dressed as a root cause. **Replaced by an
  INTERVENTION:** forcing `$90C17C` = `fcff` across the black frame moves
  EXACTLY 7,007 pixels, every one of them rgb(17,17,17) -> rgb(204,255,255),
  and the black sole and toes vanish from the snapshot. **Control fired:**
  poking the neighbouring entry `$90C17A` moves 8,898 DISJOINT pixels, none of
  them black — so the attribution is index-specific. Gated as
  `tests/test_pod_black_foot_palette.sh`.
  **LANGUAGE CORRECTED: "race" was too strong.** What is measured is an
  OVERWRITE with an ordering: the effect's `fcff` load is followed, before the
  sprite draws, by another write from the SAME palette-copy routine putting
  `f111` back. Whether two requests genuinely race or the ordering is
  deterministic is NOT established.
  **THE DETAIL CHAIN, dug out 2026-09-01 at the maintainer's direction.**
  * **The writer is VANILLA code, byte-identical to pristine vsavj**
    (`PRG:0x02AD20-0x02AD80`, verified against `vanilla_data.bin`). It is a
    generic 16-entry palette copy: dest row from `+0x18B` of the object,
    source from `a0`, and it preserves the destination's top nibble
    (`andi.l #$f000f000`).
  * **Its resolver entry (`0x02AD20`) is a TWO-LEVEL lookup:**
    `a0 = charPaletteBase[(a6+0x382)] + (seq_id & 0xFFF)*32`, with the
    per-character base table at **`PRG:0x38C218`**. `0x02AD3C` is a SECOND
    entry point with `a0` preloaded, and that is the one our writes come
    through — so the caller, not this table, chose the block.
  * **The two source blocks are FOUND:** `PRG:0x0CF110` is the CLEAN one
    (idx 14 = `fcff`) and `PRG:0x0CEB70` the BLACK one (idx 14 = `f111`).
  * **PROVENANCE, AND IT IS THE ANSWER TO THE FIX QUESTION: BOTH BLOCKS ARE
    OURS.** Pristine vsavj holds `0xFF` FILLER at both addresses — unused ROM
    space the port allocated. The char-table row for id `0x13` is also ours
    (vanilla aliases Donovan's slot to `0x393460`, Victor's base; the port
    repoints it to `0x0FF180`). The routine itself is untouched vanilla.
  **SO THE 2026-08-28 REFUSAL OF OPTION (b) RESTED ON A FALSE PREMISE.** It
  read "the sequence is vanilla vsavj data, so editing it breaks the superset
  invariant". The palette data in play is NOT vanilla — it is port-authored
  bytes in filler vanilla never reads. **That does NOT by itself make a fix
  right** (see the caution below); it means the risk must be re-assessed
  rather than assumed. Maintainer's call ([VSP-10]).
  **THE CAUTION, and it is why no fix is proposed here:** what differs
  between clean and black is WHICH BLOCK IS SELECTED, not what the blocks
  contain. Block `0x0CEB70` is used for 22 of the 24 index-14 writes in the
  window, so `f111` is presumably correct for its other uses; editing it
  would be a WORKAROUND that could damage them. A sound fix targets the
  SELECTION.
  **CLOSED 2026-09-01 — `a0` MEASURED** with `tap_writes.lua`'s existing
  `REGLOG` (no tooling needed; its own comment says it exists to "name the
  source table pointers for computed cursors"). Every index-14 write in
  f13400-14375 carries **`A6 = 0x00FF8400`, P1's FIGHTER BLOCK** — the same
  object every time — and the source varies: `0x0CEB70` (idx 0, the DEFAULT,
  20 of 24 writes), `0x0CF050` (39), `0x0CF070` (40), `0x0CF110` (**45**, the
  effect's own, idx14 = `fcff`).
  **THE TIMELINE IS THE WHOLE MECHANISM:**
  * CLEAN — seq 45 loaded f13589, **foot draws f13645**, revert to seq 0 at
    f13697: the revert lands 108 frames after the load, PAST the draw.
  * BLACK — seq 45 loaded f14313, **revert to seq 0 at f14341**, foot draws
    f14370: the revert lands 28 frames after the load, 29 frames BEFORE it.
  **THE TWO TIMELINES ARE DECOUPLED BY DESIGN: the palette is requested by the
  PLAYER OBJECT's state machine (`$FF8400`), while the foot sprite is drawn by
  a SEPARATE POOL OBJECT with its own lifetime.** When the player's state
  advances and reverts the palette before the pool object has finished
  drawing, the sprite renders against the default block. That is why it is
  intermittent, why it cannot be reproduced on demand, and why nothing about
  the tiles, the records or the addresses was ever wrong.
  **THE TRIGGER, MEASURED 11/11 (2026-09-02, the maintainer's question "why
  such a specific issue, on a single move, and not even all the time?"):
  DONOVAN IS HIT WHILE HIS OWN EFFECT IS STILL DRAWING.** The effect palette
  (seq 46) has a FIXED nominal lifetime: across the whole recording it is
  loaded ELEVEN times and survives 108/108/109x7/144 frames — except once, at
  f14313, where it survives **28**. That one load is the ONLY one whose window
  contains P1 taking damage (`hp1` 203 -> 201 exactly at the f14341 revert
  frame). Being hit moves the player's state machine to a reaction, which
  re-requests his DEFAULT body palette (seq 1); the pool object is still
  drawing and borrows his row, so it renders against the wrong block.
  **So the answer to "why only this move, and not always" is exact:** the move
  is a super whose effect OUTLIVES the player's state (~109 frames), and the
  condition is GETTING HIT during that window. Ten clean instances, none hit,
  all held the palette for its full lifetime. **This also RETRACTS the earlier
  guess** that the state advanced at outcome-dependent speeds — it does not;
  the lifetime is fixed and only an interruption shortens it.
  **WHAT A FIX WOULD TARGET, now the mechanism is known:** the LIFETIME
  RELATIONSHIP, not the palette bytes — either the player's revert waits for
  the effect, or the effect owns its palette instead of borrowing the
  player's. Both are gameplay-adjacent and neither is Claude's to choose
  ([VSP-10]). What IS now known is that the bytes in play are OURS, so the
  superset invariant is not the obstacle it was believed to be.
  **A method note worth keeping:** the first discriminator appeared to REFUTE
  this (three clean instances carried the "black" row `0b`) — they never reach
  the `bbxx` foot phase at all. Scope a discriminator to the phase that draws
  the thing, or it measures nothing. Original entry follows.
- **#112 — PRESS OF DEATH BLACK FOOT: ACCEPTED AS COSMETIC. DECIDED
  (maintainer, 2026-08-27): option (c) — accept for now; option (a) (give
  tenants their own effect animation) is PARKED for a later pass over the
  port's remaining purely-cosmetic items.** Option (b) (trim the borrowed
  sequence) is refused outright: the sequence is vanilla vsavj data, so
  editing it breaks the superset invariant regardless of what it does to the
  move. Rationale for (c): the defect is purely visual on a single-player
  surface, the project already carries small cosmetic imprecisions, and the
  mechanism is not understood well enough to patch safely — the whole draw
  path measured VANILLA (writer `PC 0x01B2BE` byte-identical to stock,
  vanilla record `0x287D7C`, vanilla sequence, vanilla art, tile window
  byte-identical to stock), and WHY a tenant runs that sequence is still
  unknown. GitHub #112 stays OPEN as the parked record; do not re-derive the
  eliminations, they are listed in the 14z-112 group above. **When the
  cosmetic pass happens, the entry point is a DISASSEMBLY-based trace of the
  effect spawn — not a byte scan** (two instruction-boundary false positives
  were paid for here: `e768 7105` and `0028394E`).

- **#113 — THE ONE-FRAME WHITE-OUT AT A DOWN IS VANILLA. CLOSED BY THE
  MAINTAINER 2026-09-01 ("I closed #113 since the behavior is indeed
  vanilla"), option (a) — GitHub #113 CLOSED 2026-09-01T11:16:19Z.** The
  board agrees with the emulator measurement: the camera/MiSTer evidence the
  2026-08-28 update was waiting for came back consistent, so the finding
  stands as measured and nothing was re-derived. The accessibility softening
  (b) was NOT taken and needs a fresh ruling if ever revived. **What survives
  as an honest boundary: the MECHANISM (palette RAM blanked vs a CPS-B
  layer/priority register) is still NOT measured — only the framebuffer is.**
  **-> ANSWERED 2026-09-01, SAME DAY THE TOPIC WAS OPENED: THE WHITE FRAME IS
  A DELIBERATE PALETTE-BASE SWAP.** The game writes CPS-A register
  `0x80410a` (`CPS1_PALETTE_BASE`, confirmed from MAME's `cps1.h`
  `CPS1_PALETTE_BASE = 0x0a/2`) from its normal `0x90c0` to **`0x9240`** for
  exactly ONE frame; the region at `0x924000` is filled wall-to-wall with
  `ffff`, so every pixel of every layer resolves to white. The next frame the
  base returns to `0x90c0`. **BOTH CANDIDATES IN THIS ENTRY WERE WRONG:** it
  is NOT palette RAM being blanked (rows `0x00-0x5f` at `0x90c000` change only
  by +/-1 colour cycling across the flash, mean luma 344 -> 344) and NOT a
  CPS-B layer/priority register. It is the palette POINTER.
  **TWO DIFFERENT "WHY"s, AND ONLY ONE IS ANSWERED — corrected 2026-09-01
  after the maintainer read this entry and said "I still don't understand why
  would Capcom want to blink the screen, but now we at least know how".** They
  are right and the first version of this entry overstated it:
  * **WHY THIS IMPLEMENTATION — ANSWERED.** Given that a full-screen flash is
    wanted, a palette-base swap is the cheapest way to get one: a single
    register write flashes every layer at once, disturbs no colour and no
    sprite, and reverses instantly.
  * **WHY A FLASH AT ALL — STILL OPEN, and it is the interesting half.**
    Nothing measured says what design purpose a one-frame white-out serves.
    THE ONE OBSERVATION WORTH CARRYING, stated as an observation and not a
    theory: all four occurrences in the run sit at STATE TRANSITIONS (the
    match-intro pair, match start, and the first down), not at arbitrary
    moments — so "an impact accent" and "a side effect of a palette swap at a
    transition" are both still live. Evidence AGAINST the second: the palette
    at `0x90c000` shows NO bulk reload around the flash (writes are a flat
    ~96/frame across f6640-6652, no burst at f6646), so if it is a swap
    artifact the reload is not happening there. Not pursued further; nothing
    depends on it.
  **DISCRIMINATOR, 4/4:** `0x9240` occurs EXACTLY FOUR TIMES in the 6,700-frame
  run — f1908, f1910, f2147, f6645 — one frame before each of the four known
  white frames (1909/1911/2148/6646) and nowhere else. Cross-implementation:
  FBNeo reproduces the same inventory at +1 frame (hash `0e86f1dc0b964325` at
  1910/1912/2149), so it is not a MAME artifact. The frame is genuinely 100%
  white (86,016 px, ONE distinct colour). Rig: `tests/lua/tap_writes.lua`
  `TAP=80410a,2` + `inp_probe.lua` `PAL_BASE=924000`, on STOCK vsavj with
  `104_1p_auto_ko_win.rpl` — the `test_down_flash_vanilla.sh` rig.
  **TWO INSTRUMENT TRAPS PAID FOR, both caught by controls:** (1) the first
  register tap used `0x800100`, which the driver's own map comments call
  "Mirror (sfa)" — NEVER written by this game, so a "zero writes" elimination
  was measuring a dead address (the tap MECHANISM was control-proven at
  `0x90c000`, which is not the same as proving the ADDRESS meaningful); the
  live block is `0x804100-0x80417f`. (2) `0x90c0` was briefly read as the
  flash value; it is the NORMAL one, and only the whole-run distribution shows
  which is rare. **Nothing is proposed and nothing changes** — vanilla
  behaviour, #113 stays closed, and the superset invariant forbids touching
  it. The original topic follows.
  **-> OPENED AS A RESEARCH TOPIC (maintainer, 2026-09-01): "we don't know the
  mechanism, much less the reason (there has to be one and I must admit I
  wonder why this is like this). We should open a research topic on it and
  tackle it after we get to the bottom of the black foot analysis."
  SEQUENCED AFTER #112.** Note it is TWO questions, and the second is the
  maintainer's real curiosity: (1) the MECHANISM — what makes the frame
  white (palette RAM zeroed vs a CPS-B layer/priority register at that
  frame); (2) the REASON — why Capcom's engine does it at all at a down.
  Knowledge work on VANILLA behaviour, not a port defect and not a fix: the
  superset invariant forbids changing legacy frames, and #113 is closed.
  WHAT EXISTS TO START FROM, so nothing is re-derived: the behaviour is
  frozen and gated (`tests/test_down_flash_vanilla.sh` — one all-white frame,
  fnv `eab1fb569cb99b25`, 57..96 frames after every down, plus the intro pair
  and the match-start frame), it is present in BOTH vsavj and vsav2
  (`37_victor_ko_vsav2`), and the framebuffer half is measured while the
  palette/register half never was. The instrument gap is the whole topic:
  a framebuffer hash cannot distinguish a blanked palette from a disabled
  layer — that wants a palette-RAM dump or a CPS-B register read AT the white
  frame ([CPE-14]: MAME read taps never fire on this driver, so a write tap
  or a frame-anchored dump is the route). `inferred_claims` row 11 is the
  standing record of the unmeasured half.
  The original entry follows. (measured 14z-112,
  `tests/test_down_flash_vanilla.sh` PASS on stock vsavj / reference MAME).
  Stock Vampire Savior draws ONE all-white frame (fnv `eab1fb569cb99b25`,
  whole framebuffer) 57..96 frames after every down, plus the intro pair and
  the match-start frame — merged-m9 reproduces exactly that inventory and
  nothing more. So it is not a port defect, and the photosensitivity concern
  is with Capcom's design. **The decision:** (a) CLOSE as vanilla behaviour
  (RECOMMENDED — the superset invariant forbids changing legacy frames, and
  the flash fires on every legacy down); (b) an OPT-IN accessibility
  softening (dip/config-gated, WIDE-only, default OFF, so default legacy
  output stays bit-identical) — a deliberate legacy-content change that
  needs its own ruling, a measured mechanism (palette-RAM vs CPS-B layer
  register at the white frame — not yet measured) and a gate; not free.
  The CRT "background stays, sprites vanish" is consistent with one white
  frame on phosphor (interpretation, not measured).
  **Maintainer's rule (2026-08-27): vanilla in VS with VS characters =>
  close regardless of vs2; measured BOTH — vsavj (104: +96) AND vsav2
  (37_victor_ko_vsav2, native Donovan: +88) show it. Awaiting the
  maintainer's own hand check on stock vsavj, then CLOSE.**
  **~~UPDATE 2026-08-28~~ SUPERSEDED 2026-09-01 — the camera evidence below
  ARRIVED and AGREED with the emulator finding; #113 is CLOSED. The
  paragraph is kept because its eliminations and its "if the board
  disagrees" clause are the reasoning that made the closure safe.**
  **UPDATE 2026-08-28 (maintainer): NOT closed, and not to be closed yet.
  The maintainer is gathering CAMERA evidence because original
  hardware/MiSTer may DISAGREE with the emulation finding, and wants
  bulletproof evidence before the topic is reopened. Until that arrives:
  the emulator measurement stands as measured, nothing is re-derived, and
  #113 stays OPEN. If the board does show something the emulators do not,
  that is a cross-implementation finding about the white frame's
  rendering (palette/CPS-B layer register at that frame — never measured,
  see (b) above), not about the game data.**
- **~~#99 — THE TYPE-0x51 REMAP~~ RE-RULED (maintainer, 2026-08-26, 14z-110):
  THE REACTION_HOOK D2-WINDOW SHAPE IS APPROVED, in the explicit order
  FIX -> AUDIT -> RE-FREEZE.** "Very well, I agree with all the proposal."
  What is approved, precisely:
  * **Shape: the reaction_hook THUNK BODY is extended — never the vanilla
    dispatcher.** The engine's patched footprint does not grow (still the one
    6-byte `jmp` at `0x018458`); the thunk's bne-arm (the only entry into
    dispatcher 2 at `0x018508`) gains the same `0x50-0x53` window test it
    already runs for dispatcher 1, dispatching via a SECOND ext table to vs2's
    dispatcher-2 twin (`0x016DE4`) handlers VERBATIM; every other index takes
    `jmp 0x018508` exactly as today. Data stays native `0x51` — dispatcher 3,
    the `es_type51_dispatch` thunk and the `property[0x51]=0x19` lookup are
    untouched.
  * **Scope: DATA-TRIGGERED, deliberately NOT tenant-id-gated.** The branch
    keys on the node byte's VALUE (`0x50-0x53`), which only vs2-numbered
    ported data can carry — vanilla data reaching dispatcher 2 with such a
    byte crashes today, so no legacy behavior can depend on the added branch
    (legacy-safe by IMPOSSIBILITY, the index_window_018468 precedent). An
    id-gate would be WRONG: the field proved the walking object can be a
    LEGACY character's (Bishamon) — the trigger is whose DATA the node lives
    in, not whose object walks it.
  * **Ownership: `donovan.toml`'s `[reaction_hook]` singleton** (merged
    inherits; solo Huitzil/Pyron don't declare it and the census measured
    them at ZERO out-of-range nodes, so they don't need it).
  * **The one global cost is CYCLES** — every object on the hit-stun path
    (`+0x38` set) executes the ~2 added compares, all characters. The
    flicker-inventory measurement (step 2 of the order) is the gate: if the
    frozen inventory moves, STOP and return to the maintainer — never widen.
  * **Order is binding: FIX (manifest + emitter) -> AUDIT on the fix build
    (flicker inventory, test_fsm_census still 6/6 native, audit_don_vs_cpu,
    guard soaks, audit_continue_switch re-measure) -> RE-FREEZE
    (donovan-m12/huitzil-m21/pyron-m15/merged-m7) + the MiSTer CRC tail.**
    Field pass on the new bundle is the actual #99 verification (MAME cannot
    reproduce the crash).
  This supersedes the 2026-08-26 (a)+(b)+(c) ruling's part (b); (a) — vanilla
  dispatcher never patched — is honored by construction, and (c)'s census came
  back EMPTY of further members. The measured basis below stands as the trail.
  **Original re-ask (14z-110), kept for the trail:** The census is
  DONE and the fix shape needed a fresh decision; (b) was not implemented.
  **WHAT THE CENSUS FOUND (measured 14z-110, `tools/audit_fsm_census.py` with
  the vs2 oracle + `tests/lua/fsm_census.lua` corpus):**
  1. **There is only ONE out-of-range family, and it is the KNOWN one.** The
     static family-aware census (node-record signature: 0x20-stride, monotonic
     +0x10 counter, +0x17 a valid state) finds exactly SIX out-of-vsavj-range
     node-state bytes across ALL THREE tenants — the six `0x51` records in
     Donovan's hitbox (`0x3FB862`-`0x3FB902`, +0x17 at blob offsets
     `0x10E9..0x1189`), which ARE the 14z-35 cluster. **Huitzil and Pyron have
     ZERO.** No `0x50/0x52/0x53` node clusters exist. **So the escalation
     clause resolves cleanly: there are no OTHER members to classify.** (Bound:
     signature-based; the dynamic corpus census found no idx >= 0x50 dispatched
     on any leg, mapping the reachable tenant node regions — a coverage bound,
     stated, not a universal proof.)
  2. **The node byte feeds THREE dispatchers, not one, and they are 80-entry
     not "~0x28".** `0x018460`/`0x018508`/`0x0185D2` (vs2 twins `0x016D34`/
     `0x016DE4`/`0x016EB6`, 84 entries -> gap `0x50-0x53`). The 14z-43
     `es_type51_dispatch` thunk's consumer audit named dispatchers 1+3 and
     MISSED dispatcher 2 (`0x018508`) — that is where #99 crashes. The records
     were left native `0x51` on purpose (dispatcher 3 + the property lookup
     need it).
  3. **A DATA remap breaks things:** `0x51 -> 0x19` diverges on dispatcher 3
     (there `0x19` -> handler `0x18694`, NOT the copy handler) AND fails the
     `es_type51_dispatch` thunk's `cmpi #0x51`. `0x51 -> 0x4E/0x4F` is
     copy-aliased on all three dispatchers, BUT the copy handler STORES the
     class and a downstream property lookup keys on it
     (`property[0x51]=0x19` vs `property[0x4E]=0x0F`, the 14z-44 ES-freeze
     family) — so it changes gameplay. **No data value is both
     dispatcher-exact on all three AND property-preserving.** Ruling (b) as
     written ("`0x51 -> 0x19`, zero gameplay surface") is therefore wrong on
     both counts.
  **RECOMMENDATION (measure-first order, port-the-handler caveat honored):**
  the clean fix is **CODE-SIDE on dispatcher 2's arm, inside a hook that
  already owns the only entry to it** — the `reaction_hook` site prefix
  (`0x018458`) already re-creates `tst.b (0x38,a1); bne 0x018508`, so its
  bne-arm gains the same `0x50-0x53` window the reaction_hook already runs for
  dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim.
  Data stays native `0x51` (dispatcher 3 + property untouched). Cost: ~2
  compares on a path legacy executes when `+0x38` is set — **must be measured
  against the frozen flicker inventory before it ships** (that is the only open
  cost; if it moves the inventory, stop and root-cause). This is NOT a "port
  the handler" import — it reuses handlers already present; it adds a window
  test, not a foreign routine. **Delivered this window regardless of the
  ruling:** the census tool + gate (`test_fsm_census`, negative controls
  green), the deterministic Donovan-vs-CPU-Phobos coverage gate
  (`audit_don_vs_cpu`, closes #111's core gap), replay 110. The fix itself
  waits on this ruling.
  **HONEST GAP unchanged:** #99 does NOT reproduce on MAME from a P1-mash
  (full venue-0x02 Donovan-vs-Phobos marathon ran clean to END 40620) — the
  bad node needs the specific cross-fighter walk the maintainer sees 100% on
  the CORE. So no MAME regression lock is possible; the fix is verified by the
  census (node no longer >= table size on dispatcher 2's reachable path) + a
  field pass.
  **~~ORIGINAL RULING (maintainer, 2026-08-26), SUPERSEDED BY THE ABOVE~~:**
  (a)+(b)+(c) — (a) data-side extraction remap, never the dispatcher; (b)
  `0x51 -> 0x19`; (c) census + escalation. (a) and (c) stand in spirit; (b) is
  the part the measurement overturns. Kept for the trail.**
  **THE MAINTAINER'S STANDING CAVEAT ON (c), recorded verbatim in spirit:**
  for escalated hits, "port the handler" LOOKS like the best default (no
  error states + vs2-consistent tenant behavior) — **but it is NOT free: not
  in memory, not in cycles, and not in side-effects. Measure first. And if
  the maintainer seems too eager to say yes to a port, RAISE THIS POINT** —
  their own instruction. The project's evidence agrees: a ported handler
  imports code that may touch fields vsav lays out differently, may call vs2
  helpers at vs2 addresses (thunk/relocation work), costs bytes and
  per-frame cycles, needs its own gates — and "consistent with vs2" can
  still be WRONG under vsav's engine (the DF-frameworks-differ-BY-DESIGN
  lesson, 14z-101; the effect-class root that pulled cascading dependencies,
  14z-102). Default order for an escalated hit: measure what the state DOES
  and how often our content reaches it -> consider neutralize-to-default ->
  port ONLY when the behavior demonstrably matters to feel.
  **Original measured entry:** Step 1 done (14z-109 (7)), all three answers:
  1. **Family**: the object-script FSM node stream — 0x18-byte nodes whose
     `+0x17` byte is the NEXT-STATE index — inside Donovan's ported
     character block. Our node `0x3FB882` = vs2 `0x0C9CAA`, ported
     byte-verbatim (single content-search hit, 0x28-byte window).
  2. **What vs2's `0x51` means**: vs2's FSM table (dispatcher `0x016D2C`,
     table `0x016D34`) has **0x54 states**; entry `0x51` (offset `0x023C`)
     is vs2's MOST-ALIASED **DEFAULT handler** — `move.b (0x17,a3),(0x54,a1);
     rts`, the plain "advance to the node's next state". ~20 vs2 states
     alias it.
  3. **The vsavj equivalent**: vsavj's default at table offset `0x017C`
     (handler `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
     **BYTE-IDENTICAL** to vs2's `0x51` handler.
  **PROPOSED RULING: remap node-state `0x51 -> 0x19`** (the lowest vsavj
  default-alias) — semantically exact, both engines run identical
  instructions, zero gameplay surface. **Plus the census before the fix
  window**: scan ALL THREE tenants' ported node streams for `+0x17` values
  `>= 0x28` (vsavj's table size) and remap each by the same
  handler-equivalence method — one missed member is how THIS one shipped.
  Fix = extraction remap rule (14z-33/35 shape), landing with #111's
  coverage work in one window. Original entry:** Root cause is on the issue: node `ROM 0x3FB899` in Donovan's
  relocated block carries vs2 type byte `0x51`; vsavj's dispatcher at
  `PRG:0x018508` has no row for it and no bounds check. The fix wants THREE
  answers before any byte moves: (1) which record family `0x3FB882` belongs
  to in the extraction; (2) what vs2's `0x51` MEANS there (its handler in
  vs2's own table); (3) the correct vsavj renumbering — then a REMAP RULE in
  the extraction per the 14z-33/35 shape, never a hand-poke. Gameplay
  surface possible (the node does something in vs2 that vsavj may express
  differently), hence maintainer-ruled. **#111 (coverage rot) should land in
  the same window**: re-point or replace `26_don_arcade_mash`, re-measure
  `audit_continue_switch`, and add the missing Donovan-vs-CPU-Phobos gate
  (the venue-byte steer makes a deterministic one possible). The build-time
  guard — validate every ported type/selector byte against the consuming
  dispatch's bounds — is what keeps the NEXT missed family member off a CRT.

- **~~THE TIMING-MARGIN RESPONSE~~ DECIDED (maintainer, 2026-08-25).**
  `cps2w` fails 4 of 12 fitter seeds (14z-108). Options were laid out A-E.
  **RULED: A + B, with C IN RESERVE. D is ACCEPTABLE. E is OPPOSED unless
  there is no better choice.**
  * **A — do nothing to the RTL.** We distribute a PREBUILT `.rbf`, so the
    fragility is ours and not the users'.
  * **B — PIN THE SEED AT RELEASE.** Every shipped bitstream is built from a
    NAMED seed with its slack and sha256 recorded and verified, never from
    an `xjtcore.sh` random draw. The current baseline is **seed 18269,
    +0.066 ns, sha256 `46fc74af…`**. Costs nothing and converts "we got a
    lucky draw" into "we know which draw, and we check it".
  * **C — shed load on the SDRAM address cone** (bank 0 carries SEVEN slots
    since D2; the rejected 14z-107 alternative was moving the Z80 out).
    HELD IN RESERVE: it is the only fix that stays inside Rule 1 v2 and
    touches no shared infrastructure, but it would invalidate the bank-1
    bandwidth measurement, so it is not to be spent on headroom we do not
    currently need. **Revisit BEFORE the next RTL slice, not after.**
  * **D — pipeline the SDRAM address path.** ACCEPTABLE if C is not enough.
    Note it means overriding jtframe's shared controller in `cores/cps2w`.
  * **E — lower the SDRAM clock.** OPPOSED unless nothing else works: bank 0
    already peaks at 43.9% of its 96 MHz ceiling, so the clock is buying
    headroom we are using.

- **~~MiSTer PACKAGING: which MRA is MAIN, and how a release carries both
  `vsav.zip` flavours~~ DECIDED (maintainer, 2026-08-25): OPTION A, a
  WIDE-ONLY RELEASE, with option B as the eventual target.**
  **The collision, named exactly (14z-108):** the four ported-art members
  are `vm3.13m/.15m/.17m/.19m`, and they live in **`vsav.zip`, not
  `vsavjw.zip`**. So the WIDE MRA needs a PATCHED `vsav.zip` while every
  stock MRA needs the PRISTINE one — same filename, one `games/mame/`
  folder — and jtframe resolves members **by CRC32 alone**, so the wrong one
  is silently filled rather than refused.
  **Ruled: ship the WIDE MRA only.** The maintainer's reasoning, recorded
  because it settles the "which MRA is main" half too: **Jotego's own
  `jtcps2` core already runs vanilla**, so our core does not need to, and
  the stock regional MRAs are a development reference leg rather than a user
  feature. The generator currently makes the **Euro** set the main MRA and
  buries the WIDE entry in `_alternatives/`, which is backwards for a core
  whose purpose is the roster.
  ~~**Option B stays the target shape "in time"**~~ **OPTION B WAS SHIPPED AT
  14z-113 AND THIS ENTRY WAS STALE FOR THIRTEEN FREEZES — corrected
  2026-09-02 after the maintainer asked for it to be "made ready for the next
  freeze" and the archaeology ([VSP-14]) found it already done.** Measured on
  `build/m3b_merged21`: the build packs NO `vsav.zip` at all, and
  `vsavjw.zip` carries all 25 members including the four patched group-A ones
  (`vm3.13m/15m/17m/19m`), so `vsav.zip` stays pristine from `$ROMDIR` and a
  user's existing romset folder works untouched. The freeze that did it is the
  14z-113 ONE-ZIP PACKAGING FREEZE (merged-m10). **What was still undone is
  the OTHER half of this decision — "which MRA is MAIN" — and that landed
  2026-09-02:** `parse.main_setnames=["vsavjw"]` in the fork's
  `cores/cps2w/cfg/mame2mra.toml` (fork `5fd9bb9a6`), the upstream mechanism
  kiwi/s16/s16b already use, so the WIDE set is no longer filed under
  `_alternatives/` while a stock regional set takes the main slot. The
  original text follows: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **THE REMAINING SKILLS — PLANNED AND ALL FOUR SHIPPED 14z-114 (`docs/project/skills_scope.md`,
  now the record); the five decisions were taken under stated assumptions and remain OPEN TO VETO — a veto means re-cutting a shipped skill, which the checker makes mechanical:** (1) FOUR
  skills — `cps2-hardware`, `cps2-emulation` (split per "MiSTer separate
  from emulation"), `vampire-savior-engine`, `vampire-saved-port`; (2) the
  game skill quotes NO ROM addresses (laws + the atlas row it names); (3)
  the port skill anchors into CLAUDE.md and points, never restates it; (4)
  each skill's staleness pass runs in the same session as its distillation
  as its own commit (the MiSTer ruling generalised); (5)
  `engine_internals.md` counts as a LOG for the game skill's number-citation
  check. Sequencing A+B (platform) -> C (game) -> D (port). Distillation of
  A+B began the same session — and all four landed in it: `[CPH-1..30]`, `[CPE-1..42]`, `[VSE-1..83]`, `[VSP-1..161]`; 425 rules across six skills, `checkskills` ALL PASS.
- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** ~~Recorded as FUTURE, UNPLANNED work — nothing scheduled.~~
  **ALL SIX SKILLS ARE DONE 14z-114** (`mister-cps2-wide-core`,
  `mister-vampire-saved`, `cps2-hardware`, `cps2-emulation`,
  `vampire-savior-engine`, `vampire-saved-port`; checker `tools/checkskills.py`;
  STATE 14z-114). The maintainer's sketch — a CPS-II skill separate from a
  VS/VS2/VH2 skill — is met by the `cps2-*` pair and `vampire-savior-engine`;
  the checker shape (docs as the human rendition, anchored IDs, numbers cite
  the log) is the pattern any future skill reuses.
  As was done for Sailor Moon S, distil the project's learnings into agent
  SKILLS, **scoped by subject rather than by task**. The maintainer's sketch:
  at least a **CPS-II** skill separate from a **VS / VS2 / VH2** skill, and
  **MiSTer** separate from **emulation**; exact scopes to be agreed. Stated
  rationale: they make further work markedly easier.
  **The precedent is concrete and observable from inside a session** — the
  SMS project produced `romhacking-methodology` (general RE/patch discipline)
  and `snes-romhacking` (platform-specific hard rules), and both load into
  Claude Code sessions on this machine today.
  **Three observations to carry into the scoping conversation:**
  1. **The split the maintainer proposes is the one `docs/README.md` already
     uses.** "Would this still be true if we abandoned the roster hack
     tomorrow?" separates `platform/` (CPS-2, MAME, FBNeo, MiSTer) from
     `game/` (Vampire Savior itself) from `project/` (this port) — and it is
     the same question that separates a CPS-II skill from a VS/VS2/VH2 skill
     from a port skill. A skill that mixes those scopes fails the same way a
     doc filed by task instead of by fact does.
  2. **A skill is loaded BEFORE the work, so it must carry what you need to
     know before you know you need it** — laws, traps and negative controls,
     not reference data. SMS made this split explicitly:
     `sms_hacking_playbook.md` quotes ZERO addresses on purpose and points at
     the checked docs instead. Skill = the discipline; docs = the facts.
     Candidate content from this project, all paid for: measure-don't-infer,
     probe sparsity, the negative-control rule, "identify moves by measured
     EFFECTS not the script's input name", "a gate that stops checking reads
     GREEN not RED", "suspect the instrument before the thing under test",
     and the §4 vocabulary of frozen non-exact classes.
  3. **Skills go stale exactly like docs, and need the same enforcement.**
     SMS ships `tools/checkskills.py`, which ID-locks the human playbook to
     the agent skill so the two cannot drift. Whatever is distilled here
     should ship with its checker in the same commit.
  Sequencing: this naturally follows the living-documentation effort above
  (a skill is a distillation, so it wants the synthesis to exist first), and
  both follow MiSTer.

- **MiSTer DOCUMENTATION + SKILL DISTILLATION, AT TWO LEVELS (maintainer
  direction, 2026-08-27). DONE 14z-114 — both levels distilled, see the
  14z-114 entry; `mister_scope.md` carries the status.** FIRST STEP AGREED 2026-08-27: produce the SCOPE
  DOCUMENT ONLY — ~~queued in `docs/NEXT_SESSION.md`~~ DONE 14z-113:
  `docs/project/mister_scope.md`; its three follow-on decisions are the
  entry "THE MiSTer SCOPE DOCUMENT — three decisions" above.** The scope document
  names what skills should exist, where each boundary falls, which existing
  docs feed which, and what is known-stale; the skills themselves wait on it.
  Rationale for splitting it out: the sources run ~4,000 lines and must be
  READ, and the state is not settled (merged17 unfrozen, two field checks
  outstanding), so writing reference material now would bake in claims that
  are still moving. Recorded as FUTURE work alongside the existing
  skill-distillation and living-documentation items, not scheduled. The
  maintainer's scoping: document (and possibly distil into skills) the MiSTer
  implementation **at each level** — (1) the **WIDE CPS-II core** level (the
  profile, the runtime profile bit, the SDRAM map, the simulation lane: all
  game-independent), and (2) the **VS-specific** level (this romset's
  placement, catalogue/MRA generation, the field-test bundle). The split
  mirrors `docs/README.md`'s own test ("would this still be true if we
  abandoned the roster hack tomorrow?") and the CPS-II-vs-VS/VS2/VH2 split
  already sketched for the skills. Raw material exists and is large:
  `docs/platform/mister.md` (core, lane, profile gate, SDRAM ceilings) and
  `docs/project/mister_fit.md` (what this port needs vs what jtcps2 offers).

- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24).** Recorded as DIRECTION, not as a task — nothing is
  scheduled and MiSTer stays the current arc. In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

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
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- ~~Minor win-screen palette issues~~ **FIXED 14z-68m** (build/hui11):
  the palette source is the OPCODE-view remap table, and the portrait
  position row needed vs2's own values. Gate: `tests/test_hui_winscreen.sh`.
- **OPEN (cosmetic):** win QUOTE TEXT — **all THREE tenants still show their
  SHELL's quote** (corrected 2026-08-27 by the maintainer; this entry used to
  say "Huitzil's", which understated the scope). Root-caused, not built: the
  first-level table at the quote bank base ALIASES its variant half
  (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — *corrected 14z-116: this entry
  said "consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`", which is
  the 14z-73 reading of the PORTRAIT fetch and was retracted in
  `engine_internals.md` the same session; it is not the quote mechanism.*
  MEASURED 14z-116 (see the session entry and "Decisions pending"): a
  data-only fix is impossible, the relocation perturbs legacy work RAM, and
  ~330 glyph TILES have to travel. NOTE the
  win-quote ART is already native and complete (14z-62e/62j, group C bank 5) —
  what remains is the TEXT. See the cosmetic backlog below.
- ~~**GitHub #114 — 421+P**~~ **CLOSED BY THE MAINTAINER 2026-09-02T17:53Z.
  THEIR VERDICT, verbatim, and it is a GAMEPLAY RULING that must not be
  re-opened as a defect:** *"Ceilings are the same, mash rate required slightly
  under VS2 for everything but LP, which is not a bad thing given how stringent
  VS2 is for max damage (max number of hits requires well above average
  mashing, it is legitimately very hard), LP is short one hit and comparatively
  slightly nerfed, which is acceptable on the whole, especially given the
  additional bit of leniency for other punch strengths. Close enough, leverages
  VS engine, good tradeoff, closing the ticket."*
  **SO THE LOWER MASH REQUIREMENT IS AN ACCEPTED POSITIVE, NOT A NEUTRAL
  FACT** — VS2's maximum is legitimately very hard to reach, and the host
  clock making ours slightly more forgiving is a good trade. Anyone re-reading
  the §5 numbers should read them that way. Detail of the investigation
  follows (PREMISE REFUTED, SCOPE MEASURED, MASH MEASURED — 14z-127,
  2026-09-02).**
  **(a) THE ISSUE'S EVIDENCE WAS JEDAH.** Replay 48's P1 path (`U,U,R` → slot
  `0x0F`) selects Donovan only on the SUBSTITUTED stock track; since the
  14z-115 wheel separation a WIDE build puts the tenants on their own appended
  row, so that path lands on vanilla **Jedah** (`+0x60 = 0x000b0d2e`) and the
  "3 hits / 11 damage, victim pushed 728 → 852" filed as ours was his 421+HP.
  Pristine `vsavj` reproduces it to the frame and is now the gate's must-fire
  control. **The confound check in the issue was sound and still could not see
  it: positions WERE identical until contact, because Jedah and Donovan stand
  at the same x. A position check establishes SPACING, never IDENTITY.**
  **(b) MEASURED AGAINST NATIVE, all four strengths, no mash, both tracks:
  LP 3h/7d · MP 5h/9d · HP 6h/10d · ES 9h/13d — OURS EQUALS NATIVE IN EVERY
  CELL**, victim held throughout, P1's identity asserted from `bases.tsv` on
  each. Gate `tests/test_don_immortal_native.sh` (native measured in-run).
  **(c) THE FRAME-CADENCE GAP IS THE HOST ENGINE'S, NOT THE PORT'S.** Our
  deity ticks run ~1 video frame slower per ~11 engine ticks. **Controlled on
  VANILLA content: Victor, Demitri, Morrigan and Bishamon mirrors, forced
  picks, identical inputs — the hit-freeze `+0x5C` = 11 drains in 9 video
  frames on vsav2 and 10 on vsavj for ALL FOUR.** vsavj runs fewer engine
  double-ticks per video frame than vsav2. A ported character cannot tick at
  vsav2's frame rate without ticking unlike every other character in the game
  it now lives in. Frozen as section 4 of the gate.
  **RULING (maintainer, 2026-09-02): "we must respect the fact that we are
  porting the character to a different engine and the engine, being vanilla
  vsav, takes precedence."** So the gate asserts HIT COUNT and DAMAGE — the
  quantities the host clock does not set — and never vsav2's frame numbers.
  **(d) MASHING — MEASURED AND CLOSED (14z-127).** Mash extends the node loop:
  each new press adds 1 to the MASH ACCUMULATOR `+0x0A` (gate: `+0x126 &
  0x770F`), and when the deciding routine finds it at **>= 7** it spends one
  unit of the ITERATION BUDGET `+0x27` — **the per-strength cap, and it is
  DATA: 2/3/3/4 for LP/MP/HP/ES, identical in both games.** Verified identical
  at three levels: the 94 chain nodes (every non-pointer field; every link
  relocated by the port delta), the deciding code (vs2 `PRG:0x059EEA` vs ours
  `PRG:0x0C00FA`, instruction for instruction, only the `jmp` relocated), and
  the budget's start value.
  **AT THE TRUE INPUT CEILING MP/HP/ES EQUAL NATIVE EXACTLY** (8/12, 10/14,
  15/19); **LP is ONE HIT SHORT (4 vs 5)** — hit PHASE: ours' last hit lands ON
  the decision node, its freeze holds that node, and the loop re-entry skips one
  node, costing one hitbox window. **RULED (maintainer, 2026-09-02): within
  "altered by the VS engine", NOT chased** — the alternative is a one-frame
  phase change on a shared path, the trade the superset invariant exists to
  refuse. Frozen as §5 of the gate, LP asserted exactly so a move either way
  fails.
  **THE MEASUREMENT TRAP THAT COST THE MOST, now a gotcha:** a one-frame-on /
  one-frame-off mash is HALF the ceiling (the release frame is dead);
  alternating buttons EVERY frame is the ceiling. Below it the two legs sit at
  different points of the same response curve, because the host clock changes
  presses-counted-per-check — which manufactured a reading of "ours never
  extends LP and over-extends HP/ES by 2" that the ceiling erased. Ruled out
  along the way: `+0x12e` (saturates at 3) and the `$FF8058` input mirrors.
  **THE GATE IS A FREEZE-BATTERY LEG (3f) — RULED MANDATORY AT RELEASE
  (maintainer, 2026-09-02): "it's mandatory and cheap whenever we want to
  release a version."** ~15 min, the longest leg of `run_battery_m2.sh`, and
  the only one that MEASURES NATIVE instead of asserting a remembered constant.
  **WHAT THE ISSUE GOT RIGHT:**  **WHAT THE ISSUE GOT RIGHT:** the provenance criticism was fair —
  `native == 10` did enter `test_don_reactions.sh` as testimony (STATE
  14z-42c). It is correct, and is now measured in-run. 14z-42's cadence root
  cause and 14z-43's dispatch fix stand untouched.
- **OPEN:** FG pacing — untouched.

- **DECLINED (maintainer, 2026-09-02): a STATIC "substituted-wheel replay
  paired with a WIDE set" gate.** *"I don't think the static wheel/track gate
  is valuable at the moment given your arguments."* The arguments, kept so it
  is not re-proposed: 26 gates match that pattern and all 26 were checked —
  most run those replays for LEGACY content where the tenant is irrelevant, and
  every Donovan-semantic one (`audit_don_ko_writer`, `audit_don_lilith_ko`,
  `audit_continue_ladder`) FORCES THE PICK with `ff8782` pokes, so the wheel
  path cannot affect them. No text scan separates those from a real defect, so
  the gate would be 26 false positives plus an allow-list that rots.
  `test_don_sound.sh` was the only live instance and it now refuses. **The
  defence that IS in place: [VSP-163] (assert `+0x60` against `bases.tsv`, or
  force the pick) and the runtime identity assertion in
  `test_don_immortal_native.sh`.**

### THE COSMETIC BACKLOG (parked, 2026-08-27 — the maintainer's own list)

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:

| item | status | what is known |
|---|---|---|
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | **FORGONE FOR NOW (maintainer 14z-116); parked WITH A CONSTRAINT — if ever done, the CLEAN way only, vanilla untouched** | the first-level table aliases the variant half; a data-only fix is IMPOSSIBLE (zero free bytes at either hop, re-derived by `tools/scan_quote_window.py`), the bank relocation perturbs `RAM:$FFF230` on legacy win screens, and ~330 glyph tiles must travel. Art side already native (14z-62e/62j) |
| **Arcade ladder OPPONENT-ROULETTE TAG for a tenant opponent** (1P, tenant-plays-1P only — the CPU draws a tenant only on a tenant's ladder row) | measured 14z-123, not fixed | the tag shows the BASE character's name and mini-art (Phobos `0x10` → "BULLETA", a 4-bit-folded consumer, PC not attributed) drawn in pool row `PRG:0x3A3CA0 + id*32`'s own colours (a brown ramp for `0x10`; `0x13` is a grey ramp). The VS screen itself is correct (pixel-identical to the 2P path). Fix shape if ever wanted: author three pool rows (`0x3A3EA0/0x3A3EC0/0x3A3F00`, 32 bytes each, in a table vanilla never indexes past `0x0F` — legacy-invisible by construction) plus un-fold the tag's name/art consumer (its own measurement). Gate `tests/test_ladder_tenant_vs_palette.sh` |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| ~~**PYRON'S MEDALLION WHITENS on the select screen**~~ **FIXED 14z-116** | **FIXED and FROZEN 14z-117** as merged-m12 (`build/m3b_merged19` rebuilt with the M10 mark, `cde712e1`; the 14z-116 candidate was `af21bc88` under M9 — same bytes) | **The long-parked residual is closed, and it was never the accent march.** WRITE-TAP ATTRIBUTION (16 word writes, PCs `0x3FFC60-0x3FFCA6`) named **our own 14z-62k sword thunk** at `PRG:0x05F9D0`: its P2 branch wrote `0x90C340` = row `0x1A`, which is also Pyron's medallion row. Not Donovan's portrait (the 14z-87b supposition), and not the marcher — the marcher was already neutralised for `0x16/0x19/0x1A` in 14z-64. **Maintainer chose the fix from three options (2026-08-28): drop the P2 write.** `tst.b $381(a4)` now `bne`s to the pop/rts, two NOPs replace `adda.w #$60,a1` — same byte count, no allocation ripple. **ACCEPTED TRADE, field-observed 2026-08-29 (and NOT what I predicted):** the P2 sword does not revert to grey — it draws with whatever row `0x1A` holds, which is now Pyron's medallion palette, so its pixels go from steel blue-white `(153,170,221)` to orange-gold `(255,136,34)` and, on Donovan's own gold-and-red costume, read as the sword being ABSENT. The grey ramp was the PRE-62k state, before a medallion lived in that row. **A partial fix is IMPOSSIBLE (measured): sword and medallion draw from THE SAME entries of row `0x1A` — 23 shared colours — so the row cannot be split by pen.** **VALIDATED ON THE BOARD (maintainer, 2026-08-29): "Confirmed, the sword is
actually orange, and only on the select wheel screen, this is a good
tradeoff. The fix is validated."** The scope confirmation matters as much as
the verdict: the trade is CONFINED TO THE SELECT SCREEN — no in-match
surface — which is what the thunk's site (`PRG:0x05F9D0`, the select figure
uploader) predicts and the board now measures. MEASURED: row `0x1A` holds Pyron's vs2 palette across the whole select with P2 on Donovan; P1's accent on row `0x17` byte-for-byte unchanged; **`38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select` BIT-IDENTICAL to merged18** (the changed path runs only on a P2 tenant hover, which no legacy replay does) — note `38` is the exact replay whose one-main-loop slip forced the 14z-88 revert of the previous attempt. Gate: **`tests/test_pyron_medallion_2p.sh`**, two legs, verified to FAIL on merged18 and PASS on merged19. **It closes a real coverage gap:** `test_wheel_bank5` 3b's two protocols are both SINGLE-PLAYER, so it could never see this and stayed green through every freeze. **NOT FROZEN — a freeze is a separate decision** |
| **#112 Press of Death black foot** (Donovan's EX foot super) | **ROOT-CAUSED 14z-126b; FIX RULED (C) DO-NOTHING (maintainer, 2026-09-02) WITH OPTION (B) EXPLICITLY KEPT OPEN for the future — see "Decisions pending"**; DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA. ~~why a tenant runs that vanilla sequence is unknown~~ **REFUTED 14z-126b: it does NOT run one** — at every instance on merged-m14 the drawing objects' `+0x1C` point into Donovan's PLACED region and no work-RAM field holds a vsavj record pointer (positive control fired 15/15); `0x28394E` is never stored anywhere (all 7 candidate sites disassembled to instruction-boundary noise); and all 9,755 tenant sprite pointers are relocated (now gated). WHAT REMAINS: the records' TILE CODES — the effect map's coverage, the builder's own "render garbled, never crash" note. The BLACK case does not reproduce on the current build (needs a rebuild from `freeze/merged-m9` or a fresh recording) |
| ~~**RANDOM SELECT should include the three tenants**~~ — ADDED TO THE LIST by the maintainer 2026-08-28; **BUILT 14z-117 at the maintainer's word ("do the random-select includes the tenants then"), gated (`test_random_select_tenants.sh`: draw = 15 vanilla + this build's tenants; confirm on a tenant frame loads the tenant's own record; must-fire control), frozen as merged-m13 (M11); FIELD VERDICT GREEN on the board (maintainer, MiSTer, 2026-08-29, STATE 14z-118)** | DONE 14z-117 — TWO sites, not one: the walker re-reads the table on its non-tick frames (`select_screen.md` "THE WALKER HAS TWO PATHS"); a bound-only thunk crashed the figure refresh with a code byte as id | the "?" cell walks a FIXED 15-entry table at `PRG:0x020C88` (`04 07 02 0C 05 0F 0A 00 0E 03 08 01 0D 09 06` = the base-half roster minus `0x0B`), 3-frame cursor, wrap `cmpi.b #$f`. Both bounds hard -> a tenant can never come up. **The siblings are the precedent**: vsav2's twin table (`PRG:0x01F8B4`) lists `10 11 13`, vhunt2's too — including the newcomers is what the source games do. FIX SHAPE: 18-entry relocated table + bound `#$f` -> `#$12`; it cannot grow in place (15 bytes + 1 pad, then code at `0x020C98`) and the table is read PC-relative, so it is a `site_thunk` on `PRG:0x020C80` + a `code` op, not a data poke. COST TO WATCH: the added cycles land on the select screen, whose legacy replays are already the bounded-window class — measure the onset before and after |
| **MARIONETTE — a vs2 character, PARKED UNTIL FURTHER NOTICE (maintainer, 2026-08-28)** | not ported, not planned | **Assets live in VS2, not in VS.** She is not in Vampire Savior at all, so nothing in our romset is missing or broken by her absence. The maintainer's framing, and it is the right one: **Marionette and Shadow are both just MIRROR-MATCH MECHANISMS** — the shared machinery at `PRG:0x009BB2` copies the opponent's id and palette, so "playing as" either is playing the opponent's character. That makes porting her a low-value item: it adds a second route to a mirror match, not a character. **Not before everything else.** If it is ever revisited, note that vs2's arming counter is the SAME single `#$5` check as vsavj's (`PRG:0x01F8D6`), so whatever arms her in vs2 is a different mechanism and has not been located |
| **Oboro's intro eats into the round** | **DECLINED by the maintainer 2026-08-28 — do NOT delay round start or cut the intro** | recorded so it is not revived: it would be a match-state TIMING change on a shared path for a cosmetic reason, which is the trade the superset invariant exists to refuse. The maintainer will instead check whether vsavj's Oboro has an alternate SHORT intro |
| ~~(#113 first-down white-out)~~ **CLOSED 2026-09-01** | **not ours** — vanilla in vsavj AND vsav2, and the board agrees | the maintainer's MiSTer check came back consistent and they closed GitHub #113 the same day. Mechanism (palette RAM vs CPS-B layer register) still unmeasured — an honest boundary, not an open item |

**THE ARCADE HIDDEN-CHARACTER ROSTER — CONFIRMED BY THE MAINTAINER
2026-08-28.** Exactly THREE exist in the arcade game: **Oboro Bishamon,
Dark Gallon and Shadow.** *(First stated as four including Marionette, then
corrected by the maintainer within the hour: **Marionette is a Vampire
Savior 2 character, not a Vampire Savior one**, and the "7 START presses"
code belongs to vs2. Recorded because the ROM agreed with the correction
before it arrived — see the Shadow row.)* *The alternate Lilith, Aulbath and
Victor are CONSOLE-PORT ONLY* — which independently confirms the 14z-116
table measurement (the only variant datasets in any of the three ROMs are
our three tenants plus two Oboros; there is no Lilith/Victor/Aulbath
alternate anywhere). Status of each on our build, all measured 14z-116:
- **Oboro `0x18`** — shipping, ours, gated (`test_oboro_select.sh`), field-confirmed 14z-105. **CAUTION for the maintainer's floated idea of removing the hold-START hook "since Oboro and Dark Gallon were already in VS" (2026-08-28): that is true of DARK GALLON and NOT of OBORO.** Measured 14z-116: the only immediate writes of a character id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — **no vanilla path anywhere writes `0x18` to `$382`.** vsavj ships Oboro's DATA complete (record `0x0B3450`, own palette block, 20 distinct bank rows) but no player-facing select path, which is precisely why 14z-105 added one. Removing the hook would make Oboro UNREACHABLE again; Dark Gallon would survive untouched, since that path is vanilla's own.
- **Dark Gallon `0x12`** — vanilla's own path (Gallon + START + 2-3 punches *or* 2-3 kicks, `PRG:0x020B9C`); our Oboro hook displaces that block's first instruction and re-executes it, so it is preserved BY CONSTRUCTION. Statically certain, **never played** — the maintainer is field-testing it.
- **FIELD VERDICT ON M9 (maintainer, MiSTer, 2026-08-28): "everything seems
  right... the new character wheel already looks almost perfect on CRT,
  Shadow works as intended, Dark Gallon is properly selectable with hold
  start + 3 punches at the same time. All seems perfectly fine."** So the
  E2 wheel is CRT-confirmed, Shadow is confirmed working on silicon, and
  **DARK GALLON IS CONFIRMED PLAYABLE** — which also validates the 14z-116
  static decode of `PRG:0x020C18` (the trigger accepts `0x300`/`0x500`/
  `0x600`/`0x700`, i.e. two OR three punches; the board used three).
  **TWO THINGS HE COULD NOT TEST IN ~2 HOURS OF TRYING, AND BOTH ARE
  STRUCTURALLY IMPOSSIBLE — the time was spent on things that cannot
  happen. Measured, so nobody spends another two hours:**
  1. **A tenant from RANDOM SELECT.** Already measured this session: the
     "?" draw is a fixed 15-entry table (`PRG:0x020C88`) holding no
     variant-half id, bound `cmpi.b #$f`. It is not luck, it cannot occur.
  2. **SHADOW vs a tenant, in 1P arcade.** NEW measurement: scanning ladder
     table A (`PRG:0x00B268`, 36 rows x 8 groups, reachable indices 0-5 —
     the scan bound `$FF8138` is 6) for a tenant candidate returns **rows
     16, 17 and 19 ONLY — i.e. classes `0x10`/`0x11`/`0x13`, the tenants'
     own rows.** A tenant appears as a CPU opponent *only when the player is
     a tenant* (which is exactly the shape of the #99 field crash: Donovan
     1P -> CPU Phobos). **Shadow's own pool is rows 32-34** (`0x800 +
     $3BD*8`) **and contains no tenant in any group.** So Shadow can never
     draw one from the ladder, however long you play.
  **HOW TO TEST IT ON THE BOARD:** 2P VERSUS — P2 picks the tenant with the
  sticks, P1 does the Shadow code. That is exactly what the emulator rig
  does (`tests/replays/113_shadow_vs_tenant.rpl`), and it is the only route
  either implementation has to that matchup.
  **-> DONE, AND GREEN (maintainer, MiSTer, 2026-08-28): "Shadow works
  perfectly even with the VS2 tenants in 2P vs, so that's a win."** The
  board agrees with the emulator leg on the one case that mattered, so the
  Shadow-vs-tenant question is CLOSED on both implementations.
- **NO LEGACY CHARACTER EVER MEETS A TENANT IN 1P ARCADE — RULED NOT A
  PROBLEM (maintainer, 2026-08-28): "not a problem since we're way focused
  on 2p vs". CLOSED, no work planned.** Kept as a measured fact because it
  explains field observations rather than because it needs fixing.** Rows `0x00-0x0F`
  contain no reachable tenant candidate at all, so a 1P run as Morrigan (or
  anyone vanilla) can never be scheduled against Donovan, Phobos or Pyron.
  The port authored the tenants' OWN rows (what they fight) and never added
  them to anyone else's. This is the same family as the random-select item
  and arguably more noticeable in play — a player's whole arcade experience
  never shows the new characters unless they pick one. **Not built, not
  scoped, no recommendation without a ruling**, and it is a GAMEPLAY-FEEL
  change (who you fight, and the ladder is already a lottery), so it is the
  maintainer's call per CLAUDE.md 5.
- **TENANT CPU AI LOOKS "LACKLUSTER" — maintainer observation (2026-08-28),
  UNPROVEN, DEPRIORITISED.** Verbatim: *"when I do fight against any of the
  VS2 tenants it seems their AI is lackluster to say the least and I'm
  pretty sure that's a side effect of the port although I can't prove it...
  but once again, we're 2P vs focused."* Recorded rather than investigated,
  with the archaeology a future session would start from so it is not
  re-derived: the four per-class AI action-script tables
  (`PRG:0x0BF01A/09A/11A/19A`) are **16 classes THEN THE SAME 16 REPEATED**
  (Capcom's aliasing guard), which is what made CPU-Phobos play DEMITRI's
  AI and was the root cause of #99; 14z-111 fixed it by making each
  tenant's OWN vs2 AI script block a data root (option A, zero code). So
  the tenants do have their own scripts now — but whether those scripts are
  as *deep* as a legacy character's on this engine has never been measured,
  and "feels weaker" is not a measurement. **If it is ever picked up, the
  first question is whether the ported script blocks are COMPLETE** (a
  truncated block would present exactly like this), not whether the tables
  are aliased. CPU-side only — 2P versus never reads them ([VSE-75]).
- **SHADOW vs A TENANT — MEASURED AND GREEN (14z-116).** The maintainer's
  question ("the big problem is not selecting him, it's knowing whether the
  game breaks", INCLUDING "does Shadow take the SHELL character instead of
  the tenant") was answered by a RUN, not by disassembly. Rig:
  `tests/replays/113_shadow_vs_tenant.rpl`, gate `tests/test_shadow_tenant.sh`
  (emulator tier, ~6 min, two runs, must-fire control). **RESULT: Shadow
  takes the TENANT.** P1 armed the code (5 START presses on "?"), beat P2
  Donovan, and at the round end flipped `0x00 -> 0x13` with the loader
  installing **Donovan's own record `0x003FA9D0`** — not Victor's
  `0x0009769E`, the shell `0x13` aliases, which is exactly the quiet failure
  the gate is written to catch. HUD reads "Donovan", art is his, and the run
  is **guard-clean END 21120** across several further morphs.
  **TWO CORRECTIONS TO MY OWN EARLIER STATIC PASS, both from this run:**
  (1) `PRG:0x009BB2` is NOT match init — it is the ROUND/MATCH-END path
  (`$13A`/`$13C` are the winner/loser pointers), so **Shadow does not keep a
  pick, he takes the character he just beat, round by round**; (2) arming
  alone leaves you playing the roulette's pick rendering NORMALLY (measured:
  Bulleta, no silhouette), so what produces the black-silhouette
  presentation on this Japan set is still unestablished — it blocks nothing.
- **Shadow** — present and vanilla: exactly 5 START presses on the "?" cell then any attack button (`select_screen.md`), which matches the community code instruction for instruction. The mechanism copies the OPPONENT's id and palette **UNMASKED** at `PRG:0x009BB2`, and every table the copied id then indexes is 32 rows with our tenant rows populated, **so Shadow-copying a TENANT is structurally expected to work**. Never run — this is the `coverage_matrix` "morphing INTO a tenant" cell, and it now has a mechanism attached rather than an unknown.


## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
