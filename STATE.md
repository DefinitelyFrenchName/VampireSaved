# STATE — living progress log

## Session 14z-104 (3) — COVERAGE GAP 1 CLOSED (tech roll + throw
## tech, both directions, native-anchored where the answer surprised),
## and THE OBORO QUESTION ANSWERED WITH A LIVE DEMONSTRATION.

**Tech roll (audit_tech_roll.sh, 9/9 green on merged-m5):** the roll =
HELD direction+button through the knockdown landing (a tap does NOT
register — control leg); every tenant rolls out of a knockdown
(147/120/120px — their ported recovery states executing); the legacy
roll works off don/pyr knockdowns; **Phobos' crouch-HK knockdown is
UNTECHABLE — and native vsav2 measures the identical 14dmg/no-roll**,
so it is a ported design property, frozen native-anchored; the
maintainer-described PURSUIT-VS-ROLL counter measured working (leap
fires, victim rolls 144px, the strike whiffs the vacated spot) — the
WHIFF half of the pursuit-connect question is now gated.

**Throw tech (audit_throw_tech.sh, 8/8 green):** the tech = the
victim's own throw input held from grab-connect+2 (same-frame input is
the separate throw-vs-throw whiff event, deliberately excluded);
damage halves — every tenant escapes Demitri's throw at the uniform 7;
Victor techs Phobos 14->7 and Pyron 12->2; **Donovan's throw measures
5/5 IDENTICAL with and without the tech — and native vsav2 measures
the same identity**, frozen as the native-anchored tdon expectation.
No-tech control at the full 13.

**Oboro (maintainer question "can it be selected?", answered live):**
vsavj has NO player-facing select path (the atlas's unlocated-entry
hole = the boss-encounter logic), BUT the commit path accepts 0x18
end-to-end TODAY: poked at select on merged-m5, Oboro loads his own
native dataset (+0x60 = 0x0B3450, the bases.tsv row) and fights
(snapshot sent — the pale colorway). The Start-hold hook is exactly
the existing flavor-latch idiom writing 0x18 on Bishamon's cell —
selection is OURS to add and is small, profile-gated, freeze-window
work. vs2's Oboro dataset diffs vsavj's by only 685/8192 sampled bytes
(the cross-game operand-shift shape) — vanilla-Oboro-as-shipped is the
fidelity-default recommendation.

Remaining coverage: item 2 only (deliberate KO-frame/corner/frame-1
edge rigs — next stretch); pursuit-connect's hit half.

## Session 14z-104 (2) — THE PURSUIT ANSWERED AND INSTRUMENTED: the
## maintainer confirmed the NW leaping pursuit (U + any P/K), the
## mechanic was found and measured (my earlier screen missed it by
## inputting AFTER the flat window opened — the input registers during
## the FALL), and audit_pursuit_leap is green on merged-m5: every
## tenant's ported pursuit fires with its own arc, every downed tenant
## accepts targeting.

**Why the 12-candidate screen missed it:** the pursuit input registers
during the victim's knockdown FALL and the first flat frames; my
screen's attempts (3086/3098) came after that window closed for the
sweep knockdown. With the input at f3072 (mid-fall) the leap fires on
every button (U1/U2/U4/U6 identical — universal, as the maintainer
said).

**Mechanics measured (engine_internals "THE LEAPING PURSUIT"):** aim is
captured at INPUT time (proven with a mid-flight victim-position poke);
per-character arcs (Demitri 33f/y100, Donovan 27f/y102, Phobos 42f/y88,
Pyron 39f/y88 — the ported vs2 content executing); corner pursuits peak
over the body then the wall pushbox shoves the attacker off during
descent (measured on the ALL-LEGACY control = vanilla behavior by the
superset invariant).

**The instrument (audit_pursuit_leap.sh, green 8/8):** every tenant as
pursuer (leap fires, airborne, per-char duration band), Demitri
pursuing every downed tenant (their down state accepts targeting), and
the no-knockdown control (the same input with the victim recovered must
NOT enter 0x0E — proves the signature is knockdown-gated).

**The honest open piece — pursuit CONNECT:** a wake-vs-flight knife
edge in every geometry tried (sweep and throw knockdowns, chases,
midscreen and corner, victim-position alignment), INCLUDING the
all-legacy control — so the non-connect is a rig fact, not a port
defect, and asserting damage needs a knockdown whose flat window
outlasts the flight on both games. Carried in the matrix (1b), coupled
to the tech-roll rig family (the roll is the pursuit's designed whiff).

## Session 14z-104 — THE §4 COVERAGE DEBT TACKLED (maintainer-directed):
## the mandate measured cell by cell, six new audits built and green on
## merged-m5, and the matrix documented as a maintained artifact. Four
## rulings recorded. One maintainer question open (the pursuit grammar).

**Rulings recorded at session open (maintainer, 2026-08-22):** cosmetic
/ single-player deferred INDEFINITELY (the matrix judges cells on the
2P-competitive surface); beam color + DF/clone colors GOOD, DF time
GOOD (threads stay closed); the in-game VERSION STRING is APPROVED for
convenience — it moves shipped bytes, so it rides the next natural
freeze window (queued, NEXT_SESSION); release packaging is a real topic
whose before/after-MiSTer ordering stays the maintainer's open
question.

**The census (docs/project/coverage_matrix.md, the maintained
artifact):** measured, not recalled. Found: pursuit attacks had ZERO
coverage anywhere; tenant timeout was field-confirmed only; life-marker
rigs existed for Donovan only; Pyron had no throw rig; tech-hit has no
instrument anywhere. Well-covered: vs-18-both-sides
(audit_roster_pairings, re-run 14z-104: 111/111 on merged-m5), DF
(rigs; the audit was the missing promotion).

**Six instruments built, each with legacy controls + discriminating
negative controls, all green on merged-m5:**
- `audit_df_framework.sh` — the ruled DF table frozen (1 stock,
  360/360/377/360; span-based duration with Phobos' documented
  activation flicker bounded to onset+24).
- `audit_tenant_timeout.sh` — timer poked to 3 ($FF8109), the judge
  must award the down to the HP LEADER: $FF8120 (NEW atlas row —
  round-winner code 0xFF=P1/0x01=P2, verified discriminating both
  directions) + $FF810E (rounds counter). Lead-existence asserted
  (the Phobos jab-whiff would have passed vacuously without it).
- `audit_tenant_downwin.sh` — the KO-path life-marker transition,
  every tenant as WINNER and as VICTIM (the victim legs are the
  direct #103-class lock: a tenant's death must be judgeable); 8 legs
  + no-poke control.
- `audit_tenant_throws.sh` — normal throw both directions; the throw
  discriminator measured (strength-independent 5-dmg toss for Donovan
  vs his 24-dmg groundbound strike); Victor throwing each tenant
  exercises the #104 capture keyframes.
- `audit_down_attack.sh` — the §4 "pursuit" cell: hitting a downed
  opponent, both directions. MEASURED: grounded heavies serve
  (11-14 dmg); per-character windows both sides (Phobos wakes in 24f);
  a 12-candidate input screen produced NO leaping NW-style pursuit —
  the naming question is the maintainer's (a distinct leaping pursuit
  under another grammar gets its own rig if it exists).
- `audit_stage_sweep.sh` — every tenant x all 12 stages WITH contact:
  the $FF8100 poke window measured (f2150/2200 sticks AND the venue
  assets follow; f2450+ sticks without following); 36/36 + no-poke
  + palette-distinctness controls.

**Rigs:** `tests/replays/judge/01_timeout_lead.rpl`, `02_throw.rpl`,
`03_down_attack.rpl` — poke-generic, subdir (gate-owned, outside the
suite's account, so no expectation-set cost).

**Method paid (gotcha, project + index):** per-character rig geometry —
three instances in one session each first misread as a finding (Phobos'
LP whiff; heavies cannot be mashed into a down window; Victor's sweep
throws the victim out of reach). All four combat audits REFUSE to judge
a leg whose setup event did not happen.

**Remaining open cells (the matrix's gap list):** tech-hit (throw
escape) rigs both directions; deliberate KO-frame/corner/frame-1 edge
rigs per tenant; Shadow/Marionette N/A-until-enabled (recorded roster
decision cited, not re-measured).

## Session 14z-103 (2) — #110 FIXED AND CLOSED (maintainer-directed):
## the mechanism was the ARCADE DRAW, not cycle drift; both audits
## re-derived on pinned-opponent rigs and GREEN on merged-m5. The
## Circuit Scrapper report MEASURED: not reproduced on any variant —
## captures sent, awaiting the maintainer's scenario detail.

**Maintainer feedback opened the session** (2026-08-22): projectile
collisions confirmed in line with expectations (closes the freeze's
standing watch item); a POSSIBLE Circuit Scrapper (63214+HP/MP)
animation discrepancy vs VS2 ("might be missing a slam cycle at the
start"), unconfirmed, not gameplay-adverse; and #110 ruled "definitely
fix".

**The Scrapper measurement (confirmation loop, captures sent):**
- Archaeology first: the hold placement is the 14z-73
  grab_hold_keyframes fix (native-exact then); the throw arcs are the
  ported throw_arc_tables superset rows; replay 80's header carries an
  old "throw-arc HEIGHT differs, queued" note that predates the arc
  port. Note test_hui_grab_victim gates only HOLD_LEN=12 frames — a
  missing later cycle would be invisible to it, so the green gate does
  not contradict the report.
- Measured: rig 80 (MP), an HP variant, and a MASH variant, each on
  native vsav2 AND merged-m5 — all six runs STRUCTURALLY IDENTICAL
  (grab f3152, one slam spike y40->180, hold, launch peak y=318,
  damage 19+8), ours lagging by the documented few-frame skew only.
  Full-throw side-by-side contact sheets (every 4th frame, 3152-3268)
  sent to the maintainer. Strength and mashing change nothing on
  either game. NOT REPRODUCED — and CLOSED by the maintainer
  (2026-08-22, "Circuit Scrapper seems fine indeed") after reviewing
  the contact sheets. No item remains.

**#110 fixed (the full chain on the issue, closed):**
- The bisect sharpened by measurement: field-level A/B m6-vs-m7 on the
  fgA rig diverges at MATCH START (opponent spawn X), and the state
  check names it — merged6 fights char 0x0C on stage 0x12; merged7 and
  every build since fight char 0x00 on stage 0x0E ($FF8B82/$FF8100).
  The 14z-87 batch re-rolled the ARCADE DRAW; the audits' frozen
  values described a match no current build runs. The pcosmo leg was
  doubly dead: against the new opponent the rig spends its stock on a
  DIFFERENT move and zero satellites enter $FF9400 (measured).
- The fix removes the class: audit_fg_damage now rides NEW 2P-dummy
  rigs hui/74 + hui/75 (replay-80 scaffolding; opponent+stage pinned;
  EX fires 3/3, damage 69 both legs, bit-identical run-to-run AND
  across merged-m4/merged-m5; EXPECT re-frozen 69/69 with
  attribution). audit_pool_free_byte's pcosmo leg rides
  106_pyron_cosmo_clash (215/215 family slots tagged, vs 0); one
  liveness floor re-calibrated with attribution (b8 +0x00 100->10; the
  +0x20 lane proves the tap). Both audits PASS on merged-m5. The old
  1P rigs are untouched (their other consumers unperturbed).
- Gotcha paid (project + index): a 1P-arcade rig is pinned to the
  arcade draw; frozen-value audits must pin the opponent. The attic
  diff pair is no longer load-bearing.

## Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale
## reference re-pointed, run green, or ruled a deliberate pin), plus
## three findings the pass surfaced: the gate_failures litter class,
## GitHub #110 (two audits red since 14z-87), and four LEGACY replays
## promoted off self-frozen .sha1 (the 14z-88 class, caught by the
## re-pointed audit_legacy_pairings on its first current-set run)

**The opening triage first:** the untracked
`build/gate_failures/03_two_player_vs.<epoch>.log` in git status was
NOT a real gate failure — `test_m2a_flicker_gate.sh` (portable tier)
stubs the emulator and REQUIRES the masked gate to fail, and the gate's
failure path preserved each stub into the shared evidence directory:
141 litter files over five days (140 committed), the newest written by
the 14z-102 close's own portable re-verify 30 seconds before the close
commit. Fixed at the root (`M2A_KEEP_DIR` override in m2a_common.sh;
the self-test points it at its workdir), litter removed by content
signature (basis-identical or ffff-flip lines; the four real July-29
logs and merged1_* evidence kept), gotcha paid (project bucket +
index).

**The A4 pass (docs/project/build_dir_triage.md carries the full
disposition table):**
- Re-pointed to the m10/m19/m13/merged-m5 generation and RUN GREEN
  in-session, each: the hui43 seven (mask_ranges_reader, beam_anim_walk,
  guard_integrity, df_gold, beam_variants, hui_df_style,
  hui_grab_victim) + gfx_layout_fields_live + member_classify +
  voice_row_range; trap_shock/trap_parity (hui37/38 -> hui46);
  variant_dispatch (pyron17 -> pyron30); pyron_blink/pyron_cosmo/
  pyron_ring; flicker_attribution + obj_walker_relocation (don_m7 ->
  don_m10); voice_borrow + gfx_menus pair + legacy_pairings trio +
  frozen_rompath_guard (don_m5 -> don_m10); fg_parity, ladder_selector,
  hui_electrocute, select_bank_gates, merged_render_content,
  build_identity_distinct (m3b_merged/9 -> m3b_merged12); dualtrack
  STOCK/WIDE -> m5_stock5/don_m10 + battery leg + wide_render_content +
  tenant_row_owner; gfx_chain + audit_gfx_merged --build-h (hui31 ->
  hui32, the A2 pipeline input); record_window (hui41 -> hui46);
  m2a_flicker_gate SET pin -> donovan-m10-stock.
- `test_region_overlap` section 5 RE-MEASURED on the current trio:
  2012 -> 2033 conflicting bytes (raw 7603 -> 7624), unique regions
  13 -> 14 — the new huitzil-only #109 row-31 root region; per-span
  (53,54)/(39,50)/(461,368)/(1063,1561); control re-anchored, both
  gates PASS with the must-fire control alive.
- `audit_flicker_attribution` had been SKIPping quietly — its mask pin
  named the REMOVED donovan-m7 set dir. Re-derived to fingerprint
  resolution (the #96 mechanism); PASS on don_m10 (both frozen frames
  still attributed: 41@2313 row-0x0C, 37@7168 row-0x0A).
- `test_hui_grab_victim`: default expectation flipped `differs` ->
  `matches` — the 14z-73 grab_hold_keyframes fix is what it guards
  (patch_index says so; measured Δ=0 on hui46); the default had been
  the PRE-FIX shape since the gate's birth because every freeze ran it
  with explicit =matches. HANDOFF row corrected.
- DELIBERATE PINS ruled and annotated in place: don_m5
  (audit_walker_repoint's un-relocated negative control — nothing newer
  can serve), pyron26 + hui41 (decode_stage_banners' frozen #92 defect
  carriers; only the donovan clean-leg re-pointed to don_m10).
  OPERATIONAL reclassed: build/donovan, donovan_stage4_gate, hui4
  (gates build into them / print the rebuild recipe).

**Finding: GitHub #110 — audit_fg_damage + audit_pool_free_byte RED on
every build since 14z-87**, surfaced by the re-point, bisected on the
attic dirs: merged6 (14z-86) PASS both, merged7 (14z-87 voice-borrow +
beep batch) FAIL both, values stable across five generations since
(fgA 24 vs frozen 10; fgC 0 = the close-range rig no longer contacts;
pcosmo 0 family slots in the frozen window). NOT read as a gameplay
regression: the native-anchored invariants are green on current builds
(audit_fg_parity's staircase, test_pyron_cosmo). Both audits annotated
known-red; constants NOT absorbed — the issue carries the diff pair and
the re-derivation handoff.

**Finding: the 14z-88 class, live again** — `audit_legacy_pairings` on
its first run against current sets flagged 94_tenant_vs_tenant,
103_tenant_2pwin_auto, 105_projectile_clash_ctl, 106_pyron_cosmo_clash
as LEGACY on bare `.sha1` (all four authored AFTER the audit's last
run; under bare suite dispatch their tenant content comes from
gate-supplied pokes that run_suite never applies). Executed the audit's
own fix: vanilla basis EXTENDED (freeze_masked_basis, instrument
control green, all-or-nothing publish) and the shapes measured on all
three builds — 94/105/106 = `window vsavj/masked-v2 889 2091` on every
build (single run, the ratified select-window class, thousands of
identical match frames after); specs authored, .sha1s dropped
(STRICTER: vanilla-anchored where self-frozen saw nothing). 103 is
replay 61 + AUTO: measured per-leg — donovan-m10 loads the TENANT
(+0x60 = 0x3fa9d0, .sha1 stays); hui/pyron sets commit the UNBACKED
cell 0x13 and no fighter record forms (+0x60 == 0 at f5000) —
`.legacy-exempt` authored per the 61/62 precedent.

**Carried forward:** the m3b_merged11 one-back audit defaults must join
the freeze re-point sweep or the N-2 deletion policy rots them at the
next freeze (list in the triage doc). A4 dirs now at zero live
reference fall mechanically at the next census.

## Session 14z-102 CLOSE — ritual complete

The session, in one line: the #107+#109 window opened on the
maintainer's go, #109's prepped mechanisms DIED BY MEASUREMENT and the
defect was re-derived from scratch to effect-class ROW 31 (a vsavj
stub — the clone-mode beam emitter), fixed with the ratified row-16
pattern, field-confirmed on the rehearsal probe, FROZEN as
donovan-m10 / huitzil-m19 / pyron-m13 / merged-m5 with every gate
green (suite x6, battery, corpus soak 316/316, statics 97/0/0),
PUSHED with #107/#109/#50 closed on GitHub, and the post-freeze
rulings all taken (DF durations kept categorically, tint confirmed,
build-dir triage executed: 8.1 GB atticked, strict tier zero-skip
green).

The ritual's items, each done this close:
- **STATE**: this entry; the ROLLOVER executed (the 14z-99 group moved
  verbatim to STATE_HISTORY + ledger line; diff-verified lossless).
- **NEXT_SESSION**: rewritten at the freeze and again at each ruling —
  the banner carries the frozen state, the A4 pin-cleanup pass as the
  named next item, and the attic-deletion hand-off.
- **HANDOFF**: current-builds block, registry-table row, and run_wide
  line all moved to the m10 generation at the freeze.
- **GOTCHAS**: two paid in this session (quiet-frame presence
  profiling for event-scoped OBJ A/Bs; MAME palette RAM is poke-blind
  for rendering).
- **patch docs**: patch_notes 14z-102 sections (the #107 flip, the
  row-31 fix, both updated to frozen state this close); patch_index
  rows current.
- **Issues**: #107 CLOSED, #109 CLOSED (fix shipped+field-confirmed),
  #50 CLOSED as standing policy. Open: the A4 pin-cleanup (new
  session), the attic deletion (maintainer's playtest-cycle call).
- **Suite**: 97/0/0 strict at the triage check; portable tier
  re-verified at this close. The 4f1a519+ commits are LOCAL — push on
  the maintainer's word.

Where the next session starts: NEXT_SESSION's banner — the A4
pin-cleanup pass, plus whatever the maintainer's continued testing
surfaces.

## Session 14z-102 (post-freeze rulings) — #50 CLOSED AS POLICY, the
## BUILD-DIR TRIAGE RULED AND EXECUTED (8.1 GB atticked, both green
## gates clean), the DF-duration and tint threads closed

- **#50 CLOSED (maintainer-ruled):** the issue's own handoff adopted as
  STANDING POLICY — lift a generator handler to module level only when
  a test wants to drive it (unit test in the same change; the six
  existing extractions are the template), byte-identity as the refactor
  gate (m3a_reproducible + phasec — re-proven real at this freeze), the
  allocator (~1401-1552) the named first candidate whenever allocator
  work happens for its own reasons. No refactor is ever scheduled
  absent a new measured cost. Full policy on the issue.
- **BUILD-DIR TRIAGE RULED AND EXECUTED (maintainer-agreed):** C + B2 +
  B3 + B4 + B1 + the 14z-102 probe duplicates = 85 dirs, 8.1 GB, moved
  to `../build_attic_14z102` (REVERSIBLE; delete after the next
  playtest cycle). build/ 13 GB -> 4.4 GB. Verified on the pruned
  tree: `run_all_static --strict` PASS 97/0/0 with ZERO skips (strict
  = a lost input is fatal, and none was), battery 23 PASS + the known
  wide-render self-skip (that gate ran green directly at the freeze).
  Tracked metadata in the moved dirs is deleted in this commit —
  recoverable from git history + the freeze tags (the B4 meaning).
  **STANDING POLICY adopted: at every freeze, the N-2 generation's
  dirs are deleted (keep current + one back).**
  **A4 (34 dirs, 2.56 GB) is deliberately NOT bulk-ruled** — a fresh
  session does the pin-cleanup pass (retire/re-point stale references;
  the dirs then fall to zero-reference and go mechanically). Full
  ruling: docs/project/build_dir_triage.md header.

## Session 14z-102 FREEZE — THE #107+#109 WINDOW EXECUTED END TO END:
## donovan-m10 / huitzil-m19 / pyron-m13 / merged-m5. Every gate that
## has finished is GREEN; the corpus soak and battery tail run at close.

**Maintainer "go" 2026-08-21 ("tint is good, projectile collisions seem
good, we can freeze"); the #109 fix was FIELD-CONFIRMED on the
rehearsal probe BEFORE the freeze; gold tint KEPT (their ruling).**

**The new reference state:**
| artifact | build dir | fingerprint | ops |
|---|---|---|---|
| donovan-m10 | build/don_m10 | c6a02cb0 | 323 |
| donovan-m10-stock | build/m5_stock5 | 883e7d17 | — |
| donovan-m10-stage4 | build/don_m10_s4 | d32059e1 | — |
| huitzil-m19 | build/hui46 | 1a7249d6 | 363 |
| pyron-m13 | build/pyron30 | dbce705b | 296 |
| merged-m5 | build/m3b_merged12 | 393f92a5 | 804 |

**hui46 and m3b_merged12 are BIT-FOR-BIT the rehearsed probes**
(hui_probe_row31 / merged_probe_row31 — the 14z-99 rehearsal pattern
held again), and m5_stock5 reproduces the phasec measurement exactly.

**What landed (both committed pre-freeze as W1/W2/W3):**
- (#107) reconciliation row 0x0448a6 -> 0x04367a — verified,
  callsite-anchored, re-derived at the flip. Rides the SHARED map:
  every tenant + stock moved (delta per artifact: vm3j.04d only).
- (#109) THE CLONE-BEAM FIX — effect-class ROW 31 (vsavj stub; the DF
  clone-mode per-frame beam emitter) ported: root 0x926e4:0x11e:t0x922f0
  + beam_effect_class31 code_ptr at PRG:0x080B28. The root changed
  EXTRACTION (hui32/extract regenerated, old kept extract.pre-14z102;
  hui placements shifted; op counts re-frozen 363 / 598/648 / 804/901;
  tenant bases re-derived phobos 0x4595a0 / pyron 0x4ac8dc, +0x100).

**The freeze verification, everything finished so far GREEN:**
- run_suite x6 (freeze + verify for don_m10 / hui46 / pyron30): SUITE
  GREEN every pass — every legacy masked replay on its EXACT frozen
  class, including hui46 whose placements all moved.
- test_m3a_reproducible: all five artifacts rebuild bit-exact;
  whole-artifact manifests re-frozen AFTER member-digest diffs named
  every delta (program members only — no gfx/QSound member moved).
- Merged gates: trap parity, FG parity, select-bank gates,
  render-content (bands byte-equal to the NEW solos, poison controls
  fired) — all PASS.
- audit_clone_beam_lines: defect signature was frozen on merged-m4
  BEFORE the fix; fix-mode PASS on hui46-class and merged-m5-class
  images; default now EXPECT_LINES=1.
- test_pcrel_escapes: 69/10/10 inventories UNCHANGED across the
  extraction shift (source-side keys held); merged legs identical to
  solos; wrong-suffix must-fire control alive.
- test_tenant_loop: PASS end to end on the re-frozen op counts.
- test_biased_list_inventory (NEW, ci_static): the #109-B sweep
  verdicts frozen; must-fire control verified.
- test_dualtrack PASS on the new pair (m5_stock5 + don_m10; frozen
  onsets held); test_fbneo_legacy_oracle PASS on don_m10 (frozen
  offset inventories held).
- run_battery_m2: FAILED FIRST at test_thunk_addr_literal — the gate's
  huitzil leg pinned build/hui27/extract (ancient; predates the #109
  root's region -> generation refuses). THE #94 ROT CLASS, caught by
  the battery exactly as designed; re-pointed to hui46/extract with a
  re-point-on-new-root note, gate PASS. Battery rerun: 23 PASS + the
  wide-render gate (self-skips on the stock outbase) run directly on
  the m5_stock5/don_m10 pair — PASS. Effective 24/24.
- audit_merged_legacy: exit 0 with the pass epilogue (leg a on the
  merged1 class table, leg b guard-clean vs the frozen solos). The
  per-leg counts were lost to a tail-only capture — honest limit of
  this record; the audit's own exit is the verdict.
- run_all_static FULL: **PASS 97 / SKIP 0 / FAIL 0** — the two
  formerly-expected-red gates (m3a_reproducible, phasec) are green on
  their re-frozen pins; the suite grew 96 -> 97
  (test_biased_list_inventory).
- The guard-corpus soak COMPLETED GREEN: **316/316 guarded runs,
  zero vectors** on merged-m5 under every tenant forcing (verdict map
  build/guard_corpus/m3b_merged12.1787322215.tsv). Every planned
  verification of the 14z-102 freeze is now green.

**Re-points executed with the freeze** (the #94 class, swept): pcrel
[solo+merged] sections, bases.tsv, render-content D/H/P rows,
tripwire-reach builds, guard-corpus/projectile-clash/beam-lines BUILD
defaults, biased-list BUILD defaults, the FBNeo oracle build, phasec's
stock pin, m3a pins + whole-artifact manifests, HANDOFF (current-builds
block + registry-table row + run_wide line), patch_index rows.

**PLAY: `tools/run_wide.sh build/m3b_merged12 fbneo`.**

## Session 14z-102 (4) — #109-B CLOSED: every sweep candidate has a
## measured verdict and the inventory is FROZEN AS A GATE. The
## maintainer field-confirmed the beams on the merged probe.

- **Field confirmation (maintainer, 2026-08-21):** the beams on
  `build/merged_probe_row31` are good in hand — the freeze is
  unblocked on their side.
- **The B-sweep candidates, all dispositioned (their question):**
  - hui anim `0x2499F0/0x249B18` — **FP** (anim-node stream misread
    as list heads; the 0x25729A frame pointers run through them).
  - don anim `0x28A300` — **FP**, same node-stream class
    (0x29AF78/0x29AF34 pointers, zero-entry "head").
  - `x2b7ef4 0x2BC09A/0x2BC0F8` — ONE shared item, not per-tenant
    (the region ships in every tenant): REAL type-4 strips (11x tile
    0x0090, flip pair) on a looping 6-node effect anim with no
    static referent. **ACCEPTED-WITH-EVIDENCE:** reachability
    measured — 321 type-4 dispatches on hui/83_hui_fx serve ONLY
    vanilla lists 0x269034/0x2693AA; zero in-match dispatches on
    df/100; zero on the pyron cosmo rig. If ever reached, the
    failure is a bounded wrong-art draw at vanilla bank-1 0x13890
    (valid list type — no over-index, no crash surface).
  - The remaining "22 uncovered" were the tool's documented
    hitbox/aux FP families; the covered-children include the
    clone-beam line strips, which the row-31 fix now actually draws.
- **The gate:** `tests/test_biased_list_inventory.sh` (NEW,
  ci_static) — the filtered per-tenant inventory frozen with the
  verdicts in its header; a new row or a status change fails loudly
  (must-fire control verified: wrong placements -> exit 1, drift
  named). BUILD_H defaults to the probe — re-point at the freeze.

## Session 14z-102 (3) — the window tail REHEARSED to the merged probe:
## the fix works on the merged composition; the freeze awaits the
## maintainer's in-hand beam confirmation

- **Rulings recorded (maintainer, 2026-08-21):** gold tint KEPT
  (default; community research may revisit — the neuter stays a
  one-line manifest edit, rehearsed as build/hui_probe_tint); the
  palette-event hunt = the fix path (executed, see (2)).
- **Contact A/B (the issue's damage half):** rigs df/103 (ours,
  HP+HK activation) / df/104 (native, 263+2P) authored — the pair
  splits on activation exactly as df/100/df/102 do. Measured
  non-debug both legs: P2 HP 288->288 UNCHANGED through all three
  close-range attacks on BOTH games — zero-zero parity at standing
  geometry (the 14z-101 "flying-clone altitude" geometry note holds
  natively too). A positive-contact leg (P2 jumped into the beam
  band) stays owed on #109. Instrument gotcha re-paid: the first
  A/B ran -debug and measured a NON-EVENT on both legs (hp=0 until
  f3720 — the -debug timeline shifts the match start; both legs
  "agreeing" was two dead rigs agreeing).
- **The window tail, executed to rehearsal depth:**
  `build/hui32/extract` REGENERATED with the new root (old kept as
  `extract.pre-14z102`; ensure_merged_inputs did the make);
  op-count constants RE-FROZEN with attribution (solo hui 361->363,
  2T 596/646->598/648, 3T 802/899->804/901 — the +2 = code_ptr +
  region op, huitzil-only, nothing dedupes) and
  `test_tenant_loop.sh` PASS end to end on the new constants;
  merged probe `build/merged_probe_row31` (`393f92a5`, 804 ops)
  built with every internal verification green;
  **`audit_clone_beam_lines.sh` fix-mode PASS on the MERGED probe**
  (lines at group C 0x486D0, burst control fired).
- **What the freeze still needs** (the 14z-99 rhythm, on the
  maintainer's go after they see the beams in hand): build the four
  named artifacts + stock twin from the tree, full battery +
  run_suite re-freeze (hui/merged expectation sets MOVE — the new
  root shifts every hui placement), registry rows m10/m19/m13/
  merged-m5 + tags, re-point pcrel_escapes [merged_*] + bases.tsv +
  render-content rows + audit BUILD defaults, and the B-sweep
  inventory gate. Note test_m3a_reproducible/test_phasec_spaces stay
  EXPECTED RED until then.

## Session 14z-102 (2) — #109 ROOT-CAUSED TO THE ROW AND FIXED AT PROBE
## LEVEL: vsavj ships effect-class ROW 31 as a STUB, and row 31 is the
## DF clone-mode BEAM EMITTER. One ported root + one code_ptr — the
## 14z-71 row-16 pattern, second verse — and the beams RENDER.

**The maintainer's rulings opened the work** (2026-08-21): gold tint
KEPT (default; community research may revisit — the rehearsed neuter
stays one line away), and GO on the palette-event hunt.

**The hunt's own reversals, honestly:** the palette-line/fade theory
DIED first (the "sweep" was the native stage's ambient palette cycler
— writer 0x13AB4, 64 words/10 frames; ours runs a near-static venue;
the fade steppers' beam-frame writes were boot-time screen fades; the
$FFF400 header change was a red herring both instruments refused to
attribute). What replaced it, each link measured:
- The visible beams = 4px LINES that STROBE (on 3722/3728/3730, off
  between — CPS-2 alternating-frame translucency), drawn by transient
  **16x1+4x1 sprites `code=4ED0 pal 05 bank 1`** (raw 0x0CD0 + vs2
  bias) — invisible to single-frame dumps because the dump reads the
  LIVE list while the screen shows the LATCHED one (phase gotcha #2).
- The line sprites are drawn by BEAM OBJECTS at $FFD600/$FFD700
  (alternating slots, respawned per frame = the strobe), dispatched
  through the effect-class pool with **class 31**. vs2 row 31 =
  0x0926E4 (the emitter); **vsavj row 31 = THE STUB 0x080B44** — and
  ours dispatches class 31 INTO IT constantly through the mode
  (measured: slot reads at PC 0x080A9C, D0=0x7C, objects live;
  native control: 405 reads/run, 34 in-beam). The 14z-101 "no new
  pool objects" was wrong about this pool. Also corrected in place:
  14z-71's "vs2/vh2 fill 16/17/19" — both also fill 31 (vh2 0x922F0).
- Everything downstream ALREADY SHIPPED: the line strips (anim
  0x25201C family), their composite (retyped 000C->0006, sweep-listed
  as covered-children all along), the frame table with the strobe
  flags, the line TILES (vs2 bank-1 0x14ED0, inside the 14z-83
  strip_tiles span -> group C 0x86D0-region), palette row 05
  (byte-identical to native at beam time, untouched by the DF tint).

**The fix (committed; freeze rides the window tail):**
`tools/build_donovan.sh` root `0x926e4:0x11e:t0x922f0` (vh2 oracle:
6/0x11E diffs, ALL reconciled operands — the anim pointer + three +6
engine deltas; helpers 0x13778/0x13724/0x1581A already mapped) +
`huitzil.toml [[code_ptr]] beam_effect_class31` at PRG:0x080B28.
Superset: slot measured DEAD in vanilla — 0 reads over 02/07/09/30
**+ 21_don_mash + 26_don_arcade_mash** (the type-6-lesson marathons,
included on purpose), 2418-hit row-0 control.

**Verification (RH-43 order respected):**
`tests/audit_clone_beam_lines.sh` (NEW) built FIRST and PASSED in
defect mode on merged-m4 (burst-control 20, lines 0 — the frozen
defect signature); probe `build/hui_probe_row31` (1a7249d6) built;
fix mode PASS (14 line entries, group C 0x486D0/0x48790 = raw
0x0CD0/0x0D90 + the takeover compose — the strip band already held
the tiles); **snapshots show the beams RENDERING** (green/blue strobe
phases, sent to the maintainer). Defect mode re-verified still-PASS
on merged-m4 after the predicate fix (two line families: pal 05 AND
pal 0c — the audit's first fix-mode run taught it).

**Remaining for the window tail:** the close-range damage/hitstun A/B
(the issue's verification pair — needs a close-range rig variant);
rebuild all four + merged (**the root changes EXTRACTION — the merged
pipeline's pinned extract inputs must be REGENERATED deliberately;
create-if-absent will not pick the new root up**); full battery,
run_suite, re-freeze m10/m19/m13/merged-m5 with the standard
re-pointing; the B-sweep inventory freeze.

## Session 14z-102 — THE #107+#109 WINDOW OPENED ON THE MAINTAINER'S GO
## ("follow the plan"), AND #109's PREPPED MECHANISMS DIED BY MEASUREMENT
## IN THE FIRST INSTRUMENT RUN: the defect re-derived from scratch is a
## MISSING SCREEN-PALETTE EVENT plus a tint/occlusion compound — no
## missing art, no bias defect, no data_port. The fix now waits on the
## ruling; #107's row flip is COMMITTED (window step 1).

**#107 executed and re-derived first (RH-2):** the twin claim was
re-measured this session before the flip — vs2 `0x448a6` vs vsavj
`0x4367A` = 6/0x2E diffs, every one inside a verified reconciled
operand pair (`0x2711c->0x27ec8`, `0x25eba->0x26d36` + the local bpl);
vs `0x2563e` = 24 diffs; vs `0x45fcc` = 7; farm callsites unique both
games (`0x5c51a`/`0x5437e`). Row flipped to `0x04367a`
status=verified. **The rebuild/re-freeze DELIBERATELY rides the #109
resolution so the window freezes once — until then
`test_m3a_reproducible` AND `test_phasec_spaces` are EXPECTED RED (both measure the manifest ahead of the frozen artifacts; phasec's stock rebuild now yields 883e7d17 vs the pinned 16da59b6 — the flip moves STOCK bytes too, the shared-map/#103 class) vs the frozen artifacts (the
14z-99 W-commit rhythm, paused mid-window on a ruling).**

**#109: the prep's A1 and A2 both RETRACTED by measurement** (full
chain on the issue, 14z-102 comment). The load-bearing links, each
measured on merged-m4 (df/100) vs native vsav2 (df/102):
- The shared table `0x89CF8`'s ONLY consumer is the per-fighter HUD
  stager `PRG:0x89608+` (whole-run read tap, both address spaces);
  the "cycling segments" rows of the 14z-101 (8) A/B were the two
  games' STOCK-PIP animations — the piece counts match the rigs'
  poked stocks (3 vs 5). Red herring.
- A2's "pointer lists to art" are 16-color PALETTE RAMP rows — the
  beam's row-0 ramp (ours warm, native BLUE; live palette dumps match
  the ROM lists exactly).
- Ours EMITS THE FULL NATIVE BURST SET correctly (piece-for-piece,
  group C `a19 0x44xxx`, tiles byte-identical to vs2) — the drawing
  side has no defect. It is (a) rendered BEHIND the 4-copy train
  (CPS-2 draws the list back-to-front; MAME cps2_render_sprites
  iterates last->0) and (b) repainted by the DF GOLD TINT: our own
  14z-84 df_gold_variant_id block rewrites P1 row 0A at activation
  (pre-DF row is byte-identical to native's; native's clone-mode EX
  never touches the row — in vs2 the DF gold and the EX clones never
  coexist). Tint-off probe rehearsed: `build/hui_probe_tint`
  (90e2982e, thunk upload-tail -> rts, manifest edit REVERTED after
  the measurement); it recolors P1 but does not alone surface the
  beam.
- **The visually dominant beam = full-screen PALETTE-LINE SWEEP** —
  native writes a +0x20-stepped word series across consecutive rows
  ($90C73E..$90C9xx, 258 words vs ours' 2) at beam time; writers =
  the engine palette fade stepper (vs2 `0x1282C`, PCs 012852/0129b6)
  whose vsavj twin EXISTS (`~0x14168`, content-identical). **Ours
  never invokes it** — the vs2 clone-attack script's screen-palette
  event is dropped on our leg (the #101 script-carried-id class).
  THE REMAINING HUNT: the native stepper's caller chain during the
  beam -> the twin comparison on ours.
- Bonus finds: a live 0xA00-bias pair at the attack (ours 0x3CE0/E2
  vs native 0x46E0/E4, raw 0x04E0-family ground flashes) — real but
  small; the constant mode-ornament strips (raw 0x0490/0x0698) COMPOSE
  ONTO ART VSAVJ CARRIES at its biased positions (same streak shapes)
  — benign on both legs.
- **B sweep reviewed by bytes:** anim rows 0x2499F0/0x249B18 = census
  FPs (anim-node stream); x2b7ef4 0x2BC09A/0x2BC0F8 = real type-4
  strips (11x tile 0x0090, flip pair) on a looping 6-node effect anim,
  no data-scan referent — reachability open, carried as review items.

**Decisions pending (maintainer):** (1) the DF gold tint during his
clone mode — keep (vsavj-DF identity) vs neuter (native-EX look;
one-line change in OUR thunk, rehearsed); (2) go/no-go on the
palette-event hunt as the #109 fix path. Captures sent in-session
(native blue beams vs ours).

**Method gotchas paid (in docs/project/gotchas.md this commit):**
attack-window entry-set A/Bs MUST be presence-profiled over quiet
frames too (the pip red herring survived one session because the
14z-101 (8) A/B never checked the pieces' presence OUTSIDE the
attack); MAME palette RAM at $90C000 ignores Lua/space pokes for
RENDERING while accepting them for readback (game writes recolor,
poked bytes read back but never reach the screen — a poke-based
palette A/B is a dead instrument, use a probe build).

## Session 14z-101 CLOSE — ritual complete

The session, in one line: the agreed #108→#107→#106 sequence executed
windowless with #108 INVERTED to not-a-defect and #106 closed; the
guard-corpus soak built and green 316/316; the build-dir decision
package delivered; the field passes closed strengths/timeout-wins/D+P
DF; and the DF investigation found, root-caused (through two in-place
retractions and the maintainer's confirmation loop), and fully prepped
#109 — leaving the next session a completely specified #107+#109
window.

The ritual's items, each done this close:
- **STATE**: this entry; the ROLLOVER executed (14z-98's group, 531
  lines, moved verbatim to STATE_HISTORY + ledger line; diff-verified
  lossless; STATE 128 KB).
- **NEXT_SESSION**: rewritten — the state in one breath + the WINDOW
  plan (#107 row flip; #109 A1 compose thunk / A2 pointer rows / B
  all-sites sweep; verification pair; the re-freeze checklist) as the
  banner, gating and pending rulings named.
- **HANDOFF**: hardening block current (audit_guard_corpus + the
  re-framed projectile-clash rows added earlier this session).
- **GOTCHAS**: two paid in this session (grep-patch.json-before-
  calling-a-table-unpatched; identify-moves-by-effects).
- **Issues**: #106 closed, #108 closed (maintainer), #107 window-ready,
  #109 filed→corrected→prepped (the full design is the prep comment).
- **Suite**: 96/0/0 at the last full run; portable tier re-verified at
  this close. Commits local only — push on the maintainer's word.

Where the next session starts: NEXT_SESSION's banner — the #107+#109
window, after the maintainer's projectile-collision pass and their go.

## Session 14z-101 (11) — #109 WINDOW PREP COMPLETE: the defect
## decomposes into TWO located sub-defects, the fix designs are chosen,
## and the sweep tool is committed. The window session starts from the
## issue's prep comment.
## [A1 AND A2 BOTH RETRACTED 14z-102, measured in the window's first
## instrument runs: the "segments" were the two games' STOCK PIPS
## (constant fixtures — presence-profiling gotcha), the "pointer
## lists" are the beam's PALETTE RAMPS, and the burst draws correctly
## from group C. The real defect = the screen palette-line sweep never
## invoked on ours + the DF tint/occlusion compound. See 14z-102 and
## the issue's 14z-102 comment; the sweep-tool (B) findings below
## stand.]

**A1 (segments): a SHARED ENGINE emitter, art simply absent.** The
cycling pieces come from a byte-identical shared table — **vsavj
`0x89CF8` == vs2 `0x99542`** (seven `(0x0B00..0x0B0C, 0x0103)`
entries, twin blocks identical 0x2B7 bytes around the anchor,
diverging only at the per-game pointer lists that follow). The engine
applies its generation bias at draw (+0x3800 → ours 0x43xx; +0x4200 →
native 0x4Dxx); vsavj ships NO art at its composed positions (the
measured invisibility is the blank-occupancy proof). FIX: the 14z-85
owner-tag-gated compose thunk (tenant object → group-C bank + shifted
codes; else vanilla byte-for-byte) + the 14z-71 strip-tiles copy.
REJECTED by default: writing art into vsav.zip's own banks (fixed
positions; would regress pristine-vsav.zip). Remaining: the compose
site's PC (ref-scan 0x89CF8 + read tap during df/100), bank word.

**A2 (body/muzzle): pointer-selected art, a separate sub-defect.**
Native `0x4DD0 pal0A 6x2` vs ours `0x3D64/6C pal03 2x3` is NOT bias:
each game's emitter follows ITS OWN pointer list (vj 0x39A7E0/
0x3A94E0-family vs v2 0x3B091C/0x3BDC1C-family — the twin blocks'
exact divergence point) to its own era's art. FIX: standard data_port
(identify consumed rows by read tap, port rows + art to group C).
Also explains ours' one already-correct piece (0x4DA7).

**B (the confirmed all-sites sweep): `tools/enum_biased_lists.py`
COMMITTED** — every type-4/6/8/12 list across ALL placed regions,
classified against the retype machinery; FP caveats in the header
(hitbox/aux hits are census-heuristic FPs). hui45: 24 covered children
(matches the takeover's own count) + 22 UNCOVERED of which anim
0x2499F0/0x249B18 and x2b7ef4 0x2BC09A/0x2BC0F8 are the real review
items; don_m9: the known 1 + FP noise. Window: filter, resolve, freeze
as a gate.

**C (verification, already built):** rig df/100 flips (native-family
codes + visible + close-range damage A/B vs df/102); the paired-draw
census as the generalized instrument; #107's row flip rides the same
window. Full design: the #109 prep comment.

## Session 14z-101 (8) — #109's MECHANISM FINALLY MEASURED against the
## TRUE native clone-mode reference: ours draws the clone beams 0xA00
## LOW — the 14z-71 bias class through a path the ray fix never covered
## [RETRACTED 14z-102: the A/B table below compared CONSTANT FIXTURES —
## the "cycling segments" rows are the two games' STOCK-METER PIPS
## (counts match the rigs' poked stocks, 3 vs 5), the "body" 0x3D6x is
## an always-on fixture, and the one "partially correct" muzzle row was
## the only actual beam piece. No 0xA00 defect exists in the beam
## family. The real mechanism: STATE 14z-102.]

**The identification chain (maintainer + sweep):** the clone-mode EX
is **263+2P** (any two punches, 1 stock — sweep attempt B, seq 0x12,
the PINK transform); my earlier "236+2P reference" was the ES (the
buffer folds 6236 to 236, exactly as the maintainer explained); sweep
A (green orbs) = the ES's charge; C (DF,DF+2P, seq 0x18 multi-body,
no stock) remains unidentified/possibly a state interaction — not
needed further.

**The native reference (rig `tests/replays/df/102_clone_mode_native.rpl`
— activation, movement, three spaced attacks):** 1 stock at
activation; 2× type-0x48 clones PERSIST without movement (the
263-entry differs from ours' DF in that respect); the clones VISIBLY
fire on Phobos' attacks (snapshots: segmented green bursts, then a
long solid beam — sent to the maintainer), with cooldown across the
attack spacing.

**The sprite-level A/B (per-clone ×2 entry sets at the attack):**
| piece | native | ours | verdict |
|---|---|---|---|
| cycling segments 2x1 pal 03 | 0x4D00/02/06/08/0C | 0x4302/0A/0C | **0xA00 LOW** |
| muzzle 2x1 pal 0A | 0x4DA7, 0x4DB0 | 0x4DA7 | partially correct |
| beam body | 0x4DD0 pal 0A 6x2 | 0x3D64/6C pal 03 2x3 | wrong family+size |
`-0xA00` is the project's NAMED signature (14z-71: "ported vs2 data
drew art 0xA00 low", vsav bias 0x3800 vs vs2 0x4200). The pieces
reach the drawer through a path the ray fix's per-child dispatch
never covered; 0x4DA7 being already-correct shows the existing remap
machinery grazes the family. Fix + verification pair on #109 (window
work, beside #107): ours' codes must match native's family, render
visibly, and the close-range damage A/B (damage+hitstun, no freeze,
cooldown) must agree.

**Retraction bookkeeping:** (5)'s "drawn-but-invisible markers" and
(7)'s "never drawn" were each half-right; both carry in-place marks
pointing here. The marker-train fixture (pal-00, both games) stays a
recorded curiosity. #109 retitled to the measured mechanism.

## Session 14z-101 (continued) — DF MECHANICS MEASURED ours-vs-native
## (the field pass's named unknown): the GAMES' DF FRAMEWORKS DIFFER
## (cost 1 vs 2 stocks, per-char durations vs uniform 332, activation
## seq vs none) — proven on the LEGACY CONTROL — and Phobos' clone
## train exists ONLY on our leg; the native reading AWAITS THE
## MAINTAINER'S CONFIRMATION (captures sent, loop open)

**Field results recorded first (maintainer, 2026-08-21):** the five
historically-broken Phobos moves × EVERY strength confirmed correct by
hand (closes the hardening §5 strengths item); all moves correct except
guard-cancel exclusives (rig-only by setup); timeout wins correct for
all three tenants; Donovan's and Pyron's DF correct; Phobos' DF correct
for movement and clones, **clone ATTACKS unclear** (mechanical vs
beams-not-rendering — their investigation ongoing, and the measurement
below is aimed at exactly that).

**Instruments: rigs `tests/replays/df/97_df_mech.rpl` (idle-expiry),
`98_df_attack.rpl` (stationary ray), `99_df_move_attack.rpl` (walk
then ray)** — all replay-85-doctrine (run unchanged on native vsav2
and the merged build; tenant chosen by pokes; stocks poked so DF is
never the seq-0x0A downgrade). Traced with field_trace (df flag
$FF802E, stocks +0x109, p1seq +0x06, +0x60 base as the rig-liveness
signature — every leg verified loading its own character).

**THE FRAMEWORK TABLE (df/97, idle to natural expiry):**
| leg | cost | duration | activation seq |
|---|---|---|---|
| native vs2 — Demitri/Phobos/Pyron/Donovan | **2 stocks** | **332** (uniform) | none visible |
| ours (merged-m4) — same four | **1 stock** | 360/377/360/360 | 0x16 (+0x18 Phobos) |
| pristine vsavj Demitri | 1 | 360 | 0x16 |
- **Ours == pristine vsavj EXACTLY on the legacy control** (same
  onset/dur/cost/seq) — the deltas vs native are CROSS-GAME framework
  differences, not porting defects, by construction.
- **vsavj durations are PER-CHARACTER** (legacy sweep, all 16 ids:
  269/360/377/383/398/411/540 — e.g. 0x0a=540, 0x0d=411, 0x02=269),
  where vs2 measures uniform 332 across four characters. The tenants
  read 360/377/360 on ours. **[DECIDED 2026-08-21 (maintainer, verbatim intent): "we absolutely, categorically, keep vsavj DF durations" — per-character, 1 stock, the vsavj framework as-is. If doubts ever arise about the exact per-tenant lengths, the MAINTAINER researches the period sources (Vampire Hunter, Vampire Collection, etc.); nothing is ours to retune.]** Original queue entry: **Fidelity question for the ruling queue:
  keep vsavj-framework durations or port vs2's 332.**
- **Phobos' 0x16→0x18 is a LEGITIMATE vsavj DF class**: legacy ids
  0x0C and 0x0F (Jedah) also enter 0x18, both at dur 377 — exactly his
  numbers. His activation-window flag flicker (3289-3307) remains his
  one unique tell.

**THE CLONE QUESTION (df/98 + df/99, snapshots + seq traces, both legs
instrument-verified DF-ACTIVE with stocks spent):**
- Stationary: NO clones on either game; the DF-window ray is a single
  beam on both.
- Walking (df/99): **OURS enters and STAYS IN seq 0x18 — an AIRBORNE
  4-copy clone-train formation** (the maintainer's "clones"), firing
  rays from the mode (seq 0xE at f3476/f3636); **NATIVE stays in
  ordinary grounded states (walk 0x4, same rays at the same frames),
  no clones, no visible mode** — cost 2, dur 332, mechanically
  passive as far as these rigs can see.
- ~~HELD OPEN~~ **RESOLVED BY THE MAINTAINER (2026-08-21, the
  confirmation loop working as designed):** vs2's 2-meter DF IS a
  universal buff — my native leg measured vs2's real DF correctly —
  and "what used to be characters' DF in VS is now an EX move" in
  vs2. So Phobos' clone train is his vs2 EX-move content correctly
  living on our vsavj DF activation: **clones + movement buff ruled
  "excellent in our build."** The framework table above stands as the
  cross-game fact it measured.

**No shipped byte moved.** The pool censuses (types 0x48×2 + 0x82 ours
vs 0x75 native mid-DF) are recorded in the scratch logs; instrument
promotion (an audit freezing the framework table) can now proceed on
the confirmed reading.

## Session 14z-101 (continued) — THE CLONE-BEAM QUESTION ANSWERED IN
## ONE ARC: the beams are DRAWN-BUT-INVISIBLE (bank 0 / pal 0 / vs2-raw
## code 0x3e00 — the 14z-71 strip-handler class). GitHub #109 filed.
## [MECHANISM RETRACTED same session, 14z-101 (7): the 0x3e00/0x4800
## marker trains are INVISIBLE ON NATIVE TOO (pal-00 blank markers,
## a pulsing in-mode fixture both games share — even during the
## visible ray, even post-DF). NOT the beams. The defect stands
## sharper: sound fires per clone, NO beam visual is EVER drawn on
## ours; mechanism open pending the true native clone-mode leg. The
## bias/bank arithmetic below is real about the MARKERS, wrong about
## the defect. See (7) and the corrected #109.]
## [AND (7)'s "no beam visual is EVER drawn" OVER-CORRECTED — final
## mechanism at (8): ours DOES emit the per-clone beam pieces at the
## attack, with codes 0xA00 LOW (0x43xx where native uses 0x4Dxx) +
## one mis-familied body piece — the 14z-71 "art 0xA00 low" bias
## class through a path the ray fix never covered. See (8).]

**The maintainer's precise question** ("I can hear some beam sound but
don't see the beams — graphically unrendered, or fully missing except
the sound?") **is answered on merged-m4** with rig
`tests/replays/df/100_df_clone_beams.rpl` (DF → clone train → whiffed
normals at range) instrumented on three layers in parallel:
- **ring_tap:** the in-mode attack enqueues id `0x7F` TWICE — one per
  clone — the beam event fires;
- **obj_records_dump (decisive):** f3585 carries TWO 9-segment
  horizontal beam trains at the clones' altitude, one per clone
  (left / X-flipped right) — every segment
  `code=3e00 attr-bank=0 pal=00 → a18=a19=0x13E00`: **bank bits zero,
  palette zero, vs2-raw code — resolves to blank vanilla bank-0
  space. Drawn, invisible.** Gone by f3620 (the cooldown).
- **pools:** no new pool objects — the beams ride the clones' own
  procedural strip lists, like the 236P ray (whose visible beam also
  never transits those pools — measured in the same session, so the
  pool-blindness is a property of beams, not evidence of absence).
**The class is the 14z-71 strip family** (a strip handler composing
its own bank word instead of the object's; the ray's fix never
covered this handler). Fix = the ray treatment: tenant strip-handler
copy with correct bank/bias + segment tiles into group C + palette —
shipped bytes, rides a window (natural bundle with #107).
**Damage half deliberately unresolved:** zero P2 contact in every rig,
but the trains span ~144px at flying-clone altitude over a standing
opponent at 176-278px — geometry excuses it; "no damage" is NOT
evidence of "no hitbox". Needs visible beams or the native EX leg
(the vs2 EX-move input is the maintainer's to supply) for the
damage/hitstun/chip check. All on GitHub #109.

## Session 14z-101 (continued) — THE HYPOTHESIS CONFIRMED TO THE BYTE
## and the NATIVE EX REFERENCE MEASURED (maintainer supplied the input)
## [PARTIALLY RETRACTED same session, 14z-101 (7): "236+2P = the EX
## clone mode" is WRONG — the maintainer corrected it (236+2P is the
## ES: transform + massive freezing beam) and the activation snapshots
## confirm ("3 HIT" massive beam, clone-form transform). So the
## "native EX reference" below actually measured THE ES, and the
## beam-train byte arithmetic is about the shared INVISIBLE markers,
## not the visible beams. What survives: the t48 clone-object type
## identity, the marker composition delta, and the ES observations
## (1 stock, 3-tick hit, no freeze on that leg). The true native
## clone-mode leg is still to be produced — three candidate moves
## captured (seq 0x10 / 0x12 / 0x18), maintainer identifying.]

The maintainer's read ("the clone rays are likely the same sprite
tiles as 236+P/K's — the ray fix missed that they were missing for ALL
uses") is EXACT: native segments = `0x4800` = raw `0x0600` + vs2 bias
`0x4200`; ours = `0x3e00` = **the same raw `0x0600`** + vanilla bias
`0x3800` + self-composed bank 0. The 14z-71 ported handler is
dispatched per-child to the RAY's objects only; clone strips fall
through to vanilla. Even pal 00 is correct (native uses it). Fix =
widen the tenant strip-handler dispatch to the clone children + settle
the segment tile's composed group-C address (0x5800 is currently band
content, `vs2B` src 0x15800 — the ray machinery's strip-tiles/bias
negotiation, at the window).

**Native EX reference (rig `tests/replays/df/101_ex_clone_native.rpl`
+ a scratch input sweep):** activation is **236+2P** (623/263 shapes
whiffed in-script; the maintainer's "both work done fast" presumably
folds through the same accept window); clone objects = **2× type 0x48
in $FF9400 — identical to ours**; cost 1 stock; the activation itself
hits (~13 over three ticks, hitstun, NO freeze — the maintainer's
spec); **native beams are short too** (no contact at 320px), so the
earlier no-damage results match native geometry. vs2 has no background
change — framework, not defect. Full table on #109; verification pair
for the window written there (composed 0x5800-family codes + bank-4
attrs + visible render + close-range damage A/B).

## Session 14z-101 — THE #108 WRITER HUNT RAN AND INVERTED THE FINDING:
## NOT A DEFECT. The satellites' +0x18 is OUR OWN bank-word row; the
## sweep gate never reads it; and NATIVE vs2's satellites are equally
## sweep-inert at the byte that decides (+0x94 == 0, both games).

**The sequence banner's step 1 executed (the non-debug tap), and the
measurement chain resolved #108 in the opposite direction from the
ticket. No shipped byte moves; the next-window bundle drops #108.**

The chain, each link measured this session:
1. **The tap (FBNEO_HTAP `ff8418-ff841b`, rig 106, merged-m4, whole
   run):** exactly ONE match-window writer of the fighter's `+0x18` —
   f2363 `+0x18 := 0x1000` PC `0x0282C6`, `+0x1A := 0xe000` PC
   `0x02831E`. The same vanilla per-class init the -debug trace saw.
   No second writer exists.
2. **The archaeology (one grep of patch.json — the check the 14z-100
   hunt skipped):** the merged patch carries `code` ops
   `0x282F4/0x282F6/0x282FA := 0x1000` — the three tenants'
   **`obj_bank_word_slot`** variant rows (14z-62c). `PRG:0x282D4` is
   the per-char OBJ BANK-WORD table; 0x1000 is the WIDE group-C bank-4
   word, deliberate and LOAD-BEARING (its absence is the measured
   grey-block garble that created the row). The ticket's "no patch op
   covers the table" is FALSE; the "-debug instrument paradox" was
   never a disagreement — the -debug "0x6000" was INFERRED from the
   PRISTINE table (trace_writes logs registers, not the datum — the
   14z-76 gotcha shape; project gotcha updated in place).
3. **The sweep gate, disassembled in BOTH games (vsavj `0x1A734`, vs2
   twin `0x19144` — instruction-identical):** entry requires alive
   `+0x00==1` on both pool objects, team `+0x70` DIFFERING, and
   hit-row `+0x94` NONZERO ON BOTH; boxes via `+0x80`. **`+0x18` is
   not read anywhere in the gate.**
4. **The deciding byte, A/B'd whole-run (FBNEO_HTAP on all 8 slots'
   +0x94 lanes, rig 106, ours vs native vsav2):** cosmo satellites
   carry `+0x94 == 0` in BOTH games, re-written to 0 every live frame
   from their own record data (ours `PRG:0x545DC`, native sibling
   `0x5C7BC`); only the legacy-flare control hit-activates (`0x1f`,
   both games). **Native satellites cannot enter vs2's own sweep** —
   ours match native at the mechanism level. The satellites' `+0x80`
   box pointer is the ported region (`0x4ADDB2`), so the box TABLE
   travelled fine; there is simply no hit-row to index it with, natively.
5. **Breadth (the owed Huitzil/Donovan `+0x18` item): answered by
   inspection** — H row 0x10 and D row 0x13 are the same documented
   0x1000 bank rows; no mine/missile exposure through this word.

**Consequences executed:**
- `tests/audit_projectile_clash.sh` RE-FRAMED: the frozen signature is
  NATIVE PARITY (control >=100 fires; tenant satellites word 0x1000 /
  `+0x94==0` / zero fires) plus a NEW NATIVE ANCHOR leg (vsav2, same
  replay: word 0x6000 / `+0x94==0` — if a native satellite ever reads
  hit-active, the parity claim is dead and #108 reopens). The former
  EXPECT_SAT_SWEEP=1 "fix mode" is REFUSED with the reason: word :=
  0x6000 would regress rendering (the 14z-62c garble) and buy nothing.
  AUDIT PASS on merged-m4 + refusal path verified. Note the anchor leg
  runs on MAME while the writer hunt ran on FBNeo — the deciding byte
  is confirmed on two emulators.
- hardening_register.md §5 rewritten; STATE 14z-100 H4 header marked
  RESOLVED in place; NEXT_SESSION banner corrected (the window bundle
  is now #107 ONLY); gotchas (project + index) updated: the
  "-debug/non-debug disagreement" instance resolved — new rule, grep
  patch.json for the table's range BEFORE calling a table unpatched.
- GitHub #108 carries the full chain; close is the maintainer's call
  (recommended: NOT-A-DEFECT). The banner's field question (c) now has
  an instrumented answer: the prediction is NO visible difference —
  native satellites don't trade with projectiles either.

**Method note, paid for again:** BUG ARCHAEOLOGY FIRST. The 14z-100
hunt spent a -debug trace, dumps, and an "instrument paradox" write-up
on a question one `grep patch.json 0x282f` answers. The write attribution
was never the missing piece — the missing piece was checking what our
own build does to the table before reasoning from the pristine one.

## Session 14z-101 (continued) — #107 PRE-WORK EXECUTED: the twin trace
## answered STATICALLY (the engines' own farms bind slot-for-slot), and
## the tie-refusal policy is landed, gated, and proven build-inert

**The twin question needed no rig.** Both games carry the ANALOGOUS farm
natively, and it is a static `jmp abs.l` sequence — the operand IS the
dispatch, nothing is computed:
- vs2 farm `0x5C508+`: cases jmp `0x2711C / 0x271C4 / 0x44860 /
  0x448A6 / 0x448D4`; vsavj farm `0x5436C+`: jmp `0x27EC8 / 0x27F70 /
  0x43634 / 0x4367A / 0x436A8` — identical preludes (`move.b #1,$136(a6);
  moveq #0x1d`) and epilogues (modulo one reconciled jsr,
  0x156D6↔0x16F8E). Slot-for-slot: vs2 `0x448A6` ↔ vsavj **`0x4367A`**.
  The verified sibling row (0x44860→0x43634) is the previous slot ✓.
- The DATA tables corroborate independently: vsavj `0xBF330+` / vs2
  `0xD94D0+` pointer rows slot-align the same way — and **`0x45FCC` is
  NOT an interchangeable twin**: it occupies the NEXT slot, pairing
  with vs2 `0x471E8`. It has ZERO code refs in vsavj (data refs only,
  `0xBF3BE/0xBF3FE`); `0x4367A` has the farm's code ref at `0x054380`.
- Content: `0x448A6` vs `0x4367A` = 6 diffs over the full 0x2E-byte
  routine, EVERY one a reconciled operand (incl. `jmp 0x2711C→0x27EC8`
  — farm case 0's own verified pair, internal cross-corroboration);
  vs `0x45FCC` = 7; vs the committed `0x2563E` = 24. **The window row
  is: `0x0448a6 → 0x04367A`, status verified, callsite-anchored.**
- **Bonus, honestly negative:** the adjacent OPEN row `0x448D4` farm-
  aligns to vsavj `0x436A8` by ROLE, but the routines genuinely drifted
  (vs2's clears 2 fields and rts; vsavj's clears 9) — 22+ diffs
  immediately, so it stays OPEN legitimately. Role-anchor recorded on
  the issue for whenever it is wanted; NOT part of the #107 fix.

**The matcher-hardening assertion landed (the inert half, pre-window):**
- `tools/reconcile_batch.py`: the pattern ladder is module-level now
  (`pick_window_hits` + `pattern_ladder`), and **a tied top is refused
  at ANY window** — the ladder keeps trying richer windows; a target
  whose usable windows all tie lands OPEN with the tie NAMED
  (`TIE-4x0.94-w0x20`), which under --allow-plausible becomes a loud
  tripwire instead of a silently-shipped wrong sibling. The other
  plausible emitters (callsite-votes, farm-helper-xN) already disclose
  ambiguity in their notes and are unchanged.
- `test_reconcile_matcher.sh` section 6 (NEW): unit outcomes, ladder
  behavior both directions, an end-to-end two-site tie through the
  REAL matcher refused + a single-site must-fire control. Gate PASS.
- **Live ground truth:** a fresh resolution of the real vs2 `0x448a6`
  under the new policy returns `(None, open, TIE-4x0.94-w0x20)` — the
  literal defect input is now refused with the tie named.
- **Inertness proven, not argued:** existing rows win, and
  `test_m3a_reproducible` PASS after the change — all five frozen
  artifacts + merged rebuild bit-exact (2343607a).

**What remains for #107 is WINDOW WORK only:** flip the row to
`vsavj = 0x04367A, status = "verified", note = "callsite-anchored
(farm 0x5C51A↔0x5437E + data-table slot + content 6/0x2E all-operand
diffs; 14z-101)"`, rebuild, battery, re-freeze — bundled per the
agreed sequence (now the window's ONLY content, #108 having resolved).

## Session 14z-101 (continued) — #106 CLOSED: the merged image is INSIDE
## the pcrel-escape freeze, per tenant, by reference — and the sequence's
## windowless prep is COMPLETE

**The tool extension (the issue's own fix shape, executed):**
- `tools/verify_pcrel_data.py` gains `--extract <dir>` (a tenant's
  pinned extract — merged builds carry none) and `--placement-suffix`
  (`@huitzil`/`@pyron`: merged placements key non-reference tenants'
  regions that way; donovan is the unsuffixed reference). An absent
  extract dir is a named refusal, not a traceback.
- **A latent instrument defect fixed on the way:** the tool took
  `zips[0]` of an UNORDERED listdir from the rompath — on this
  filesystem that happens to be `vsavjw.zip`, but `vsav.zip` (the
  pristine GFX DONOR) sorts first alphabetically, so on another
  machine the tool would have silently verified the WRONG image. The
  program-zip choice is now deliberate (excludes `vsav.zip`).
  Solo control after both edits: hui45 inventory IDENTICAL.

**The measurement:** all three tenants' escape inventories on
`build/m3b_merged11` (each through its own extract + suffix) are
**IDENTICAL to the frozen solo sections** — 69/10/10, and all 89 are
still BROKEN on the merged placements too (none accidentally resolves
through a merged delta). The 14z-100 worry — "what each escape reads on
the MERGED placements has never been measured" — is answered: same
inventory, same accepted-dead status.

**The freeze:** `pcrel_escapes.toml` gains `[merged_don]/[merged_hui]/
[merged_pyr]` — frozen BY REFERENCE (`same_as` a solo section, no
second copy to drift), each carrying its build/extract/suffix; the
gate (`test_pcrel_escapes.sh`) runs the three merged legs, compares
against the referenced solo inventory, keeps the x06cac0 regression
control on the merged image, and carries a wrong-suffix MUST-FIRE
control (0 escapes vs 69 frozen — a rotted suffix or extract cannot
present as green). Gate PASS end to end. RE-POINT the `[merged_*]`
sections at every merged freeze (noted in the manifest).

**Sequence status: steps 1-3 all executed windowless, as agreed.**
#108 resolved not-a-defect; #107's window action is mechanical
(row → 0x04367A); #106 closed with the merged inventory frozen — so
the next window's `[merged]` coverage exists BEFORE the window, which
was the point of doing #106 first. The window itself (#107 only —
GREW to #107 + #109 later in 14z-101, see the (8) entry) waits
on the maintainer's in-depth field pass on merged-m4, per the ruling.

## Session 14z-101 (continued) — while the maintainer field-tests:
## a STALE roadmap claim retired (#10 was DONE at 14z-94), the
## AUTHORITATIVE-GUARD CORPUS SOAK built and GREEN 316/316, and the
## build-dir decision package delivered

**#10 was already fully executed — the "ripe" carry was STALE.** The
check-history discipline caught it one command into "going forward"
with the item: commit `00b3777` (14z-94) unified the staging split
10 → 0 and re-measured all five consuming gates, and `92d0266` is the
maintainer-ruled 0621 trap-parity re-freeze — the tail included. The
GitHub issue closed 2026-08-17; NEXT_SESSION's banner had carried
"#10 ripe" forward from pre-14z-94 history (and my 14z-101 roadmap
summary repeated it). Both stale copies corrected in place; grep clean.

**The authoritative-guard corpus soak (hardening §5's queued item) is
BUILT, CONTROLLED, AND GREEN:** `tests/audit_guard_corpus.sh` — every
replay in tests/replays (79 rigs, ~472k script frames) under the crash
guard on the build under test, FOUR legs each: unpoked + P1 forced to
0x10/0x11/0x13 over the standard commit window (poking later frames is
deliberately avoided — +0x382 is the voice-flavor class in match, the
kill-poke lesson; a leg whose replay commits elsewhere degrades to a
legacy run and the header says so). MUST-FIRE CONTROL before any green
was trusted: the known 14z-93 crash reproduces on hui41 and is NAMED
(CRASH 14767 vec4 PC 0fb6e0 → the 0x494de tripwire fragment line).
**First full run on merged-m4: 316/316 END-clean, zero vectors, zero
dead legs** — including 26_don_arcade_mash at END 40620 on all four
legs. Verdict map kept: build/guard_corpus/m3b_merged11.1787265955.tsv.
JOBS=2 + nice so a playtest can share the machine.

**The ~200-build-dirs decision package is DELIVERED** (maintainer has
the file; tracked copy: `docs/project/build_dir_triage.md`): 143 dirs,
11.7 GB, classified — A1 current/operational 0.5 GB; A2 the pinned
merged-pipeline extract inputs m5_wide/hui32/pyron21 (regenerable via
ensure_merged_inputs but operationally live); A3 evidence/ground-truth
references; A4 live-referenced pending role check (2.6 GB); B1 the
previous freeze generation (tagged — suggest keep until the #107
window lands); B2 probe evidence (reproducible from STATE, 0.8 GB);
B3 scratch (1.9 GB); B4 doc/history-only (2.1 GB); C zero-reference
(2.5 GB). **~7.3 GB reclaimable pending the ruling**; the proposed
procedure is a reversible attic-move + `run_all_static --strict` +
battery, so anything that quietly depended on a dir names itself.
DECISION PENDING (maintainer): which classes go.

## Session 14z-100 CLOSE — ritual complete

The session, in one line: the 14z-99 window went from freshly-frozen to
FIELD-CONFIRMED-AND-CLOSED (#43/#99/#102/#103/#104/#105 all retired, the
in-depth pass clean through DF and every throw class), and the
maintainer-directed HARDENING PROGRAM ran H1-H4 end to end, producing
two real findings (#107, #108), one instrument-gap ticket (#106), five
new committed instruments, and the re-pointing of three rotted guards.

The ritual's items, each done this close:
- **STATE**: this entry; **THE ROLLOVER EXECUTED for the first time**
  under the split's rule — 14z-97 (790 lines) moved verbatim to
  STATE_HISTORY.md with its ledger line; both moves diff-verified
  LOSSLESS; STATE is 130 KB (cap ~150).
- **NEXT_SESSION**: rewritten as the close orientation — the state in
  one breath + THE SEQUENCE (#108 -> #107 -> #106, then ONE window
  bundling the two fixes, after the field pass) as the top banner.
- **HANDOFF**: the hardening program block added (register pointer +
  the new instrument inventory + the re-pointed guards).
- **GOTCHAS**: five paid traps appended to the project bucket + the
  index (mid-operand probe PCs; shared dump dirs; `grep -c || echo 0`;
  the -debug/non-debug write-attribution disagreement — open on #108;
  zsh `=`-leading args).
- **patch docs**: no shipped byte moved after the freeze, so
  patch_notes owes nothing; patch_index's suite-count cell refreshed
  (94 -> 96). Retraction sweep: stale "PASS 94" current-tense claims
  fixed; the #108 first-comparison hitstun confound is retracted IN
  PLACE where it was written.
- **Suite**: grew 94 -> 96 (test_pointer_flow, test_escape_triage), all
  green; the persistent-suite doctrine held — every measurement rig
  from this session lives in tests/ (the contact rig, the continue rig,
  the triage tools with frozen verdicts and must-fire controls).

Where the next session starts: NEXT_SESSION's SEQUENCE banner — the
#108 writer hunt with the NON-debug tap.

## Session 14z-100 (continued) — HARDENING H4: THE CONTACT RIG IS BUILT,
## AND IT FOUND #108 — Pyron's satellites carry the WRONG COLLISION WORD
## and never enter the projectile sweep
## [RESOLVED NOT-A-DEFECT 14z-101 — the header above is WRONG on both
## counts: +0x18 is the OBJ BANK WORD and 0x1000 is OUR OWN deliberate
## obj_bank_word_slot row (0x282F4/F6/FA, 14z-62c, load-bearing for
## rendering); the sweep gate never reads +0x18 (the deciding byte is
## +0x94, and NATIVE vs2's satellites carry +0x94==0 too — sweep-inert
## in both games, whole-run taps both legs). The "instrument paradox"
## below also dissolves: the -debug "0x6000" was inferred from the
## PRISTINE table, not observed. See the 14z-101 entry.]

**The census gap is closed as a rig and opened as a defect.**
`tests/audit_projectile_clash.sh` + replays 105 (control) / 106 (tenant):

- **The control proves the path**: Demitri-vs-Demitri head-on flares on
  the merged build fire the hitclass-map thunk probe **468 times** —
  pool-vs-pool projectile interaction transits the map every frame of
  coexistence. The old census-zero readings now have a live denominator.
- **The tenant leg found #108**: Pyron cosmo satellites (type 0x42)
  never fire the probe even with a legacy flare passing ~10px through
  the field. Root: the satellites inherit collision word `+0x18` from
  the SPAWNING FIGHTER (vanilla copier `PRG:0x545F0`,
  `move.l $18(A6),$18(A4)`), and our Pyron's word reads **0x1000 where
  native vs2 reads 0x6000** — clean-leg A/B with P1 untouched (the
  FIRST comparison was polluted by the rig's own hitstun and is
  RETRACTED; the v4 legs have no interference).
- **An instrument paradox, recorded not hidden**: on the same build and
  replay, the -debug write-trace shows exactly ONE write to the
  fighter's word (f2365, the vanilla per-class init at `PRG:0x282C0`,
  index 0x22 → the PRISTINE table says 0x6000; no patch op covers the
  table) — while non-debug dumps read 0x1000 by f2400. Two instruments
  disagree about one event; the "-debug is its own TIMELINE" class.
  Named next instrument: FBNEO_HTAP (non-debug write tap, PC
  attribution) on `$FF8418` over f2300-2400. On the issue.
- The audit freezes the defect signature (EXPECT_SAT_SWEEP=0: word
  0x1000, zero tenant fires, control >=100) and carries the fix mode
  (=1: word 0x6000, fires >=1) — the #103-audit flip pattern.
- Rig traps paid: probe PCs must sit on INSTRUCTION boundaries (the
  first reachability probe sat mid-operand and measured nothing while
  green); shared dump dirs between rig iterations destroy the previous
  iteration's evidence (v3 overwrote v2's satellite frames);
  `grep -c || echo 0` double-prints on zero (the audit's first verdict
  run failed on its own counter).

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to the archive; entries within them are marked DECIDED/FIXED
  in place, as always.

## Session 14z-100 (continued) — THE HARDENING PROGRAM OPENED
## (maintainer-directed): the pointer/flow comb built and frozen, three
## stale guards re-pointed, the risk register written. #99 CLOSED
## (maintainer-ruled); #106 filed.

**The maintainer's ask:** comb the merged image for crash candidates
(vanilla code -> non-vanilla targets, tenant overrides, bad pointers),
partition by risk, triage candidates. **Program plan: 4 phases (H1-H4),
docs/project/hardening_register.md is the living deliverable.**

**H1 SHIPPED — `tools/audit_pointer_flow.py` + `tests/test_pointer_flow.sh`
(ci_static) + `tests/expected/pointer_flow/` baselines.** The comb
classifies every address the patch introduces (~166k on merged-m4: op
extents, poke32 repoint values, code abs.l operands via scan_code_refs,
data bare longs) against the op map AND the shipped image bytes.
Findings: **2 STRONG, both reviewed BENIGN** — the win_pal thunk's
sparse-block BIASED BASES (`a0 = block - id*0xA0`; verified via the
5*row markers on the shipped image: hui 0x37, pyr 0x50). ~1,130 WEAK
(packed-data noise, frozen by count). Verdict logic ground-truthed both
directions (synthetic hole-pointer + off-image op must fail; clean
synthetic must not). TWO comb lessons paid for and encoded: (a) the
vsw.* members carry gfx-channel PRG content patch.json never writes, so
"hole" must be decided on the ARTIFACT's bytes; (b) poke32 values with
a nonzero high byte are packed data (hud_name_entry pairs), not
addresses.

**H2 EXECUTED — the stale-guard sweep (the sharpest survey finding:
three guards rotted across the freeze):**
- `audit_tripwire_reach.sh` re-pointed (was hui41/pyron26/don_m7/
  m3b_merged8 — so the shipping build's 113 tripwires had ZERO
  reachability measurement). Run on the current freeze: SIX marathon
  legs END 40620, zero fires.
- `test_pcrel_escapes.sh` + `pcrel_escapes.toml` re-pointed to
  hui45/pyron29/don_m9 — inventories MEASURED IDENTICAL (69/10/10,
  zero drift; source-side keys). **The merged image remains outside
  this freeze — filed as GitHub #106** (verify_pcrel_data needs
  extract/, merged builds have none).
- `build_merged.sh`'s README template made generation-neutral (it
  stamped "753-op / NOT REGISTERED" into every build dir forever);
  merged-m4's on-disk copy corrected.

**H3 EXECUTED (same day) — the two candidate classes TRIAGED, one real
finding (#107):**
- **H3.1 escapes: CLOSED, ZERO LIVE.** `tools/triage_pcrel_escapes.py`
  + `tests/test_escape_triage.sh` (ci_static; 25 verdicts frozen,
  269-verdict must-fire control): the 20-site hui cluster is
  ADJACENT-OK by construction (same-delta landing in x057456);
  x028122+0x112 is the reviewed jump-table framing ambiguity (note
  mirrored to H/P manifests); x068c78+0x1ca is a census FALSE POSITIVE
  (the 0x6000 word is the immediate low-half in `move.l #$00026000,d3`
  — frame-anchored; the x065c22 class).
- **H3.2 plausible rows: 9 of 13 CONSUMER-LESS** (incl. the 0.90 and
  both multi-candidate 1.00 data rows — score is not risk, CONSUMPTION
  is; measured by reading the shipped longs at every consuming site).
  Of the 4 live: three VERIFIED-BY-REVIEW (dispatch-family twins,
  sparse table-word drift). **The fourth is #107: `0x0448a6→0x02563e`
  is the WRONG SIBLING** — the 0.94 came from the batch's last-resort
  0x20 window where FOUR candidates tie on the family prologue and the
  first was taken (M2a-stage-4 era). Neighbor-anchoring gives the right
  target: the farm's case-2 sibling is the VERIFIED `0x044860→0x043634`
  and our source sits exactly 0x46 later → `0x04367A` (content-twin
  0x45fcc; runtime trace picks at fix time). COLD on the corpus
  (GUARD_PROBE zero fires over 21_don_mash + the 40,620f marathon —
  lesson paid: the first probe sat MID-INSTRUCTION at +0x3088; the jmp
  is at +0x308a, and a wrong probe PC measures nothing while looking
  green). Fix rides the next window.
- **H3.3 tripwires:** reach measured zero on the marathon (H2); further
  ranking rides H4's rig growth.
**H4 (next):** pool-vs-pool contact rig, 2P rig diversity, one
authoritative-guard corpus soak. Full detail: hardening_register.md.

## Session 14z-100 (2026-08-20, same day as the freeze) — THE #99 RIG
## RUNS END TO END: continue + switch + tenant-vs-tenant, 2x 40,620
## guarded frames, ZERO trips. And a live reference-rot catch: the
## TENANT HITBOX BASES MOVED with the window.

**The 14z-97 (7) doctrine debt is PAID: `tests/audit_continue_switch.sh`
is committed** — the #99 continue-with-switch rig as a guarded audit.
Measured on merged-m4 (two identical runs, deterministic):

- **Phase 1 (mapping, replay.lua)**: forced Phobos, coin-boosted
  marathon, no HP pokes. His natural mash loss at f15540 **JUDGES** (KO
  -> mode 6 f15780 -> mode 8 f15860 -> new match f16420, ~880f end to
  end) — the SAME rig froze 9,500+ frames at that KO before the window
  (14z-97 (7)). Instrument-level #103 confirmation on the path it used
  to block. A natural continue+switch also occurred (the mash re-picked
  Bishamon), full 40,620 frames clean.
- **Phase 2 (guarded, GUARD_DEBUG=0)**: same rig + forced switch to
  DONOVAN at the measured re-select window (ff8782:13 @ f16100-16280 —
  LANDED: match 3 plays P1=Donovan). Trajectory: Phobos (L1 Bulleta W,
  L2 Q-Bee LOSS) -> continue+SWITCH -> Donovan vs Bishamon (LOSS) ->
  continue + mash switch -> Pyron vs Anakaris (W) -> **match 5: PYRON vs
  CPU-DONOVAN — a tenant-vs-tenant CPU match at fight start reached
  through continue-with-switch, the #99 context shape — WON, clean** ->
  Victor -> **END 40620, zero CRASH/PCWEEDS/SOFTRESET**. Two continues,
  two switches. Run 2 bit-identical (checksums match).
- **THE LITERAL #99 PAIRING WAS EXERCISED AND PLAYED CLEAN.** The
  committed audit drops the $FF8114 pokes (measured: they do not STEER
  the opponent — two different poke sets gave bit-identical runs — but
  they DO perturb the lottery, because removing them changed the
  trajectory), and the poke-free trajectory delivers **match 4 = P1
  DONOVAN vs CPU-PHOBOS (f22420) — the exact reported #99 context,
  reached through continue-with-switch — and the run continues past it
  to END 40620 with zero trips.** Frozen as the audit's assertion 5.
  (If a future freeze's lottery loses the pairing, the fallback is the
  read_tap.lua loader/consumer serialization from issue #99 — header.)
- **#99 status after this**: the reported crash context — 5th-match-era
  tenant-vs-tenant CPU fight at fight start, reached by
  continue-with-switch after losing as Phobos, INCLUDING the literal
  Donovan-vs-CPU-Phobos pairing — is exercised clean under guard, and
  the maintainer's field pass is clean. The crash has not reproduced
  since the #103 fix; the evidence now strongly leans "the racy
  lose-flow trigger was removed with #103." Closing is the maintainer's
  call (the original was intermittent, so clean runs are evidence, not
  proof).

**THE REFERENCE-ROT CATCH (the #94 class, live): tenant hitbox bases
moved with the 14z-99 window and `bases.tsv` still carried merged-m3
values.** Observed in the rig (+0x60.l): phobos `0x4477b0 -> 0x4594a0`,
pyron `0x49ab7c -> 0x4ac7dc`, donovan HELD `0x3fa9d0` (his #103 rows
relocate net-zero; the H/P moves are the capture_kf insertions shifting
their placements). Verified against the image's own table
(PRG:0x0BD97A, member `prg/vm3j.04d` @ 0x3D97A) — exact match, legacy
rows untouched. `bases.tsv` re-derived + a RE-DERIVE-AT-EVERY-FREEZE
note added; `test_tenant_pairings` re-run green on the corrected rows;
the new audit derives bases from the BUILD'S OWN table at runtime so it
can never rot this way. The freeze itself never caught it because
test_tenant_pairings was not in the freeze battery — only its BUILD
default was re-pointed.

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

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

## Decisions made (maintainer, 2026-08-05): two ratifications

**1. CLAUDE.md §4 comparison class v3 — "bounded re-convergent window".**
Ratified for the select screen, which the roster deliberately alters. A
replay qualifies only when all four hold, frozen per replay: a single
CONTIGUOUS run, a fixed ONSET frame, full RE-CONVERGENCE, and match state
UNTOUCHED. Measured over five replays before the ruling (onset 890 in every
one, one run each, 2469-10498 identical frames afterwards including a full
timeout match). It is STRICTER than the frozen first-divergence constant it
sits beside, which never re-converges at all — a narrower licence for one
screen, not a loosening. §4 amended; checker `tools/compare_window.py`,
ground-truthed both directions by `tests/test_compare_window.sh` including
that a bit-identical pair is NOT a silent pass (the expectation asserts the
divergence exists).

**2. The `[[tenant]]` schema.** Ratified, and already implemented for a
single tenant (14z-60t/u) byte-identically on both tracks with the tenant
still at `0x0F`. `docs/project/tenant_manifest.md` moves PROPOSAL -> RATIFIED; its
wheel/ladder/folds sub-tables stay proposal-only because that work is not
done.

Maintainer: "I validate the two items, I don't need testing to see that they
hold on principle." The measurements above were taken before the ruling
regardless — the class's four clauses are what was measured, not what was
hoped for.

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

"vsav vanilla is always better when we can." **When a console port and
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

## Decision made (maintainer, 2026-08-05): new cells SNAP to vsav's lattice

"It feels safer to conform to arcade vsav and snap to it. As long as the UX
is good enough, I don't even mind if the look is not great." So the three
appended cells take positions derived from vsav's own hexagon rather than
PS1's pixel coordinates.

Derived layout (`build/manifest/wheel_layout_proposed.json`): vsav's wheel
is a clean hexagon, rows 1-2-3-4-3-2-1 at y=64..144 every 16, then a single
centre-line cell at y=152 (+8). Mirroring that bottom signature downward:

| cell | id | position |
|---|---|---|
| random (unchanged) | `0x0B` | (248, 152) |
| Huitzil/Phobos | `0x10` | (224, 168) |
| Donovan | `0x13` | (272, 168) |
| Pyron | `0x11` | (248, 176) |

This is geometrically IDENTICAL to the PS1 port's shape (pair, then single
on the centre line); only the id assignment differs, per the maintainer's
amendment — random keeps its vsav cell and Pyron goes to the very bottom.
28 bytes of TABLE B change. Adjacency is still a geometric DRAFT pending
the cursor-movement video.

## Decision made (maintainer, 2026-08-05): 0x360+id anim block = INHERIT

Option A: the newcomers inherit their base character's animation from the
shared 16-wide block `0x360-0x36F` (a tenant at `0x13` plays `0x363`),
exactly as vsav2 ships — Capcom left both those folds in place. Sites
`PRG:0x003E40` / `PRG:0x004082` therefore stay folded, recorded as
`inherit` in `docs/project/tenant_manifest.md`. **Fallback, if a playtest shows the
inherited animation is wrong for a newcomer: option B**, relocate the block
to a free 32-wide anim-number range and widen both masks.

## Decision made (maintainer, 2026-08-04): M5 voice samples = A then B

"A then B, gates stay strict, option C is rejected." Ship the unfaithful
voice lines silent now; revisit growing the QSound region at M3 within the
measured 16 MB `device_rom_interface<24>` ceiling; never overwrite vsav
content for sample room. Recorded in full under "Decisions pending" above,
where the option analysis lives.

## Decision made (maintainer, 2026-07-31): electrocute arc colors

Keep vsavj-native shock styling for all victims including Donovan
(option A of the 14z-20 write-up): the arcs/glow are engine-global and
victim-independent; vs2's yellow was a game-wide re-theme, not per-char
data. "Less work, less risk, and we can always come back to it after
all the more important work." LOCKED in tests/test_don_accent.sh
section 3 (shock-window vanilla lock, frozen from a vanilla run) —
revisiting requires changing that gate deliberately.

## Decision made (maintainer, 2026-08-02, round 65): M2b+ASSETS freeze

Freeze `b91647c7` as `donovan-m2c` before starting M5 sounds —
"mechanically sound as far as we can tell" (rounds 52-64 playtest
arc + full battery + suite). Frozen basis: three masked windows.

## Decision made (maintainer, 2026-08-02, round 64): third mask window

`RAM:$FF4182-$FF41A1` (palette-fade staging slot for select block-A
row 14) RATIFIED into the masked legacy basis — option A of the
14z-49b write-up, after the recolor-necessity A/B (14z-49d) showed
options B and C strictly worse. Condition attached and honored:
detailed documentation + a standing confirmation path
(`tests/audit_mask_window_ff4182.sh`; spec in docs/game/atlas/ram.md).
Extension policy stands: future palette-block ports extend the
window per measured slot, never pre-widen.

## Decision made (maintainer, 2026-08-06): select art = option A

Option A of the 14z-62e write-up: the per-hover bank thunk for the
portrait-record object + the tenant's select art in WIDE group C at
native codes; `vsav.zip` leaves the rompath entirely pristine. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/project/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

## Decisions pending (human)

- ~~**ADOPT THE HIT-CLASS MAP EXTENSION + RE-FREEZE huitzil & pyron
  (14z-82b).**~~ **DECIDED 2026-08-12 (maintainer): ADOPTED** — shipped as
  huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322), 14z-82c. Original entry: The generated `hitclass_map_extend` site_thunk fixes a
  playtest-reachable crash LATENT IN BOTH FROZEN TENANT BUILDS (pyron's
  satellite type-64 contact = the f7997 vec3, measured on pyron-m2 solo;
  Huitzil's 68/72 share the pool). Numbers, all measured on a probe build
  (tests/audit_hitclass_map_cost.sh, rerunnable): fix holds through the
  11,017-frame soak that crashes the frozen build; LEGACY BIT-IDENTICAL
  over 30,284 frames on four replays, with a fire census showing legacy
  never enters the map at all [**THAT FIGURE IS RETRACTED — 14z-92 M4
  measured 230 legacy entries corpus-wide; the adoption still stands and
  the argument is "legacy enters and gets vanilla answers"**]. Cost of
  adoption: the row goes in
  huitzil.toml + pyron.toml (shared, dedups on the merge) → BOTH
  verticals re-freeze (new fingerprints; registry rows; their frozen
  masked legacy self-logs re-measured — expected unchanged given the
  zero-fire census, but measured is the standard). Donovan/stock
  untouched. RECOMMENDATION: adopt — it is the third instance of the
  "vs2 widened an index consumer" class (14z-26, 14z-35 precedents) and
  the crash needs one satellite contact to fire in a real match.
- ~~**DONOVAN's map entries 61/62 (14z-82b, separate and smaller).**~~
  **DECIDED 2026-08-12 (maintainer): (a) KEEP VANILLA'S ZEROS** — his
  sword-companion objects' hit-class reactions stay as every shipped
  build has had them; measured unexercised (0 map entries in his
  replays). Revisit only if his satellite hits ever feel wrong in
  playtest — then it is 2 bytes in the generator's policy + a Donovan
  re-freeze. Original entry:
  MEASURED SINCE: his types 59-63 are the projectile-pool objects his
  SWORD-COMPANION machine spawns (61 = the sword-routine region
  x065e5a's family; spawns measured in both his replays), and they enter
  the hit-class map ZERO times in his replays — the missing reaction is
  UNEXERCISED, so (a) costs nothing observable today. Original entry: vs2
  gives his satellite types 61/62 hit classes 0x0E/0x04 where vsavj
  holds the do-nothing 0 — so his type-61/62 projectile hits currently
  produce NO hit-class reaction on every shipped build, and always have.
  The fix above deliberately keeps vanilla's zeros (donovan-m3a
  byte-untouched). Options: (a) keep zeros — shipped behavior, nothing
  moves; (b) adopt vs2's two bytes in the same thunk body — vs2-faithful
  hit reactions for his satellite, at the cost of a Donovan re-freeze
  and a battery re-measure. If (b) is ever wanted, it is a 2-byte change
  to the generator's policy plus the measurements; playtest feel decides
  whether the missing reaction is real. RECOMMENDATION: (a) for now;
  revisit if his satellite hits ever feel wrong in playtest.

- **IF `anim` CANNOT LEAVE THE CRYPT WINDOW — the fallback order is set
  (maintainer, 2026-08-10).** Framing recorded verbatim in effect: *"we'll see
  if and how we can grow the crypt window and still have everything work, or
  if we need to cut down access to a character (in which case I'll leave Pyron
  aside, but that's kind of a last resort)"*.

  So the ladder, best to worst:
  1. **Make `anim` movable** — root-cause the odd pointer. If this works, no
     decision is needed at all, which is why it is the active task.
  2. **Grow the crypt window in the WIDE profile.** A profile change, so
     maintainer-approved by construction, and it must be shown not to break
     anything (the profile's whole justification is the emulator superset
     invariant — `tests/test_wide_profile.sh` / `test_mame_wide.sh` are the
     gates, plus `test_crypt_boundary.sh` since the window's EDGE is what
     would move). Deficit to cover if nothing else changes: **125,560 bytes**.
  3. **Ship two tenants, Pyron aside.** Explicitly a LAST RESORT. Note the
     measured irony: Pyron's reach-constrained set is **0 bytes** — he is the
     cheapest tenant on every axis except his `anim` (111,872). Dropping any
     one tenant frees roughly its own anim, so on space grounds alone the
     choice between them is close to arbitrary; it is a roster decision, not
     an engineering one.

- ~~**THE MERGED BUILD'S `[init_shim]`: ONE SHIM, THREE TENANTS (14z-77)**~~
  **DECIDED 2026-08-10 (maintainer): the recommendation below, in full** —
  adopt phase mode, dispatch flavor per id, gate the write so Pyron stays
  untouched until his polarity is measured against native, then run Donovan's
  battery on a phase-mode build before trusting the merge. **IMPLEMENTED as
  slice G** (14z-77e); the two measurements it names remain OPEN and are
  listed there. Original entry follows.

  Surfaced by slice F's collision measurement — it was one of the three real
  merge blockers, and unlike the other two it was not purely mechanical.

  **The mechanics, measured.** The shim is emitted ONCE per build at ONE site
  (`dispatch_00`'s seed hook, `seed_entry = 0x016C64` — identical in both
  manifests that declare it). It (a) seeds the object pool if the latch is
  clear, and (b) writes the VS2/VH2 **flavor** byte to `+0x3C2` of the player
  struct being initialised, or `flavor_held` when that player's Start is held.

  Three things follow, and only the first is mechanical:

  1. **Flavor polarity is per tenant and already ratified.** D1 (VS2 default)
     means `0x01` for Donovan and `0x00` for Phobos — the polarity differs
     because the engine branch each character tests differs (14z-66 measured
     it against native). A merged shim must write the id-appropriate byte,
     i.e. the same N-way dispatch the thunks need. No decision required.
  2. **`latch_mode = "phase"` is NOT per tenant — the seeder is shared, so a
     merged build either has the gate or does not.** Phobos NEEDS it: without
     it his ecosystem drains pool 0 and the round-2 char re-init re-runs the
     seeder over LIVE pools (14z-65 measured the f4890 wipe, orphaned queues,
     and a freed slot dispatched into palette space). He is in the merged
     build, so **the merged build must carry the gate**, and Donovan's shim
     bytes therefore change — the generator's own comment says his frozen
     bytes stand "until his own re-freeze adopts the mode". The gate only
     narrows WHEN the seed runs (to `$FF800C == 0x40000`, the char-load
     phase), and Donovan's first init is at that phase, so it SHOULD be inert
     for him — but that is an argument, not a measurement, and this project
     does not ship arguments. **Required before the merged build is trusted:
     Donovan's replay battery on a phase-mode build, compared to
     donovan-m3a.**
  3. **Pyron declares NO `[init_shim]` at all.** In a merged build the shim
     runs at char-init for whatever the hosted dispatch covers, so he could
     be given a `+0x3C2` flavor byte he has never had. Whether he reads that
     byte is UNMEASURED. Options: give him an explicit row (needs his own
     polarity measured against native vs2, the 14z-66 procedure), or gate the
     flavor write so only tenants that declare one receive it.

  **Recommendation:** adopt phase mode for the merged build (2 is forced),
  dispatch the flavor bytes per id (1), and gate the write so Pyron is
  untouched until his polarity is measured (3, the conservative half) — then
  measure Donovan's battery before trusting the merged build. The alternative
  worth the maintainer's attention: if Donovan's battery DOES move under phase
  mode, the fallback is a per-id gate on the phase check itself, which is more
  emitted code at a shared site and wants explicit sign-off.

- ~~**THE BEAM'S LIST-TYPE 12: FLATTEN, OR RATIFY THE HOOK? (14z-71)**~~
  **DECIDED 2026-08-09 (maintainer): NEITHER — take over the dead
  list-type 6**, with the explicit condition that the deadness assumption
  must not be load-bearing. Built as `build/hui20`; see the 14z-71
  RESOLVED section. The maintainer's framing, kept because it generalises:
  *"there is almost always a chance it actually wasn't dead and we just
  missed how it was used... if we encounter regressions in vanilla
  assets/engine, this is one of the first places to check, and should we
  ever encounter something that uses list-type 6 that we didn't know of,
  we should stop, analyse and assess the situation before continuing."*
  That is now enforced by construction (the vanilla fallback) and by a
  gate (the `$FF010C` tripwire), not by memory. See THE DEADNESS REGISTER
  below.

- **THE 14z-62e SELECT-ART ANALYSIS (decided above).** The
  last visual-de-substitution piece: the tenant's select-art subset (101
  bank-1 tiles + 4 placeholder label tiles + the 6-tile medallion) still
  overwrites Jedah's bank-1 select-figure art, garbling his select-screen
  BODY (face/name/match art are all back). Two measured options:

  **A — a per-hover bank thunk + group C (recommended).** The select
  FIGURE object's bank already follows the hovered char through the
  engine table (measured: `PRG:0x05F9EC` jsr's the bank helper; hovering
  the tenant writes 0x1000 and his standing figure draws from group C
  TODAY). The PORTRAIT-record object instead gets bank 1 ONCE at venue
  init (`PRG:0x07C428`). Option A thunks the per-hover record-pointer
  consumers (`PRG:0x05F328`/`0x06C0E0`) to also set that object's bank:
  hovered==tenant -> 0x1000, else -> 0x2000 (the value it already holds,
  so pure-legacy RAM is byte-identical; after a tenant visit the restore
  re-converges). Select art then lives in group C at native codes — NO
  fit problem — and `vsav.zip` leaves the rompath ENTIRELY PRISTINE.
  Cost: a new engine hook on the select path (cycle-only for legacy; the
  ratified hook class, but the re-freeze's flicker/window inventory must
  be re-measured with it in — the standing watch applies). The name/
  highlight-piece objects' banks need the same treatment (their sites
  are one measurement away, same method).

  **B — relocate into blank bank-1 space, no hooks.** Vanilla bank 1 has
  2,917 blank tiles (largest runs: 881 at 0xBE90-0xC200, 460 at 0x3634,
  357 at 0x6C9C — measured). Placing the ~117 tiles there needs a NEW
  greedy fit (block-geometry aware), a reference-exclusivity proof for
  the chosen ranges (blank != unreferenced: a legacy record could use
  blank tiles as transparent filler, and art there would APPEAR — the
  proof method is the medallion's whole-image scan), and `vsav.zip`
  stays patched-but-additive (nothing of Jedah's overwritten). Zero
  engine hooks, zero legacy cycle cost.

  **Recommendation: A.** It finishes the artifact story (pristine
  vsav.zip — the strongest possible provenance), reuses the established
  thunk pattern and the already-poked bank table, and avoids a new fit +
  exclusivity-proof toolchain for a one-off. The hook's legacy cost is
  cycles only, in the class the basis already tolerates; it will be
  measured before the re-freeze ratifies anything. B stays the fallback
  if the measured hook cost violates the standing watch.


- ~~**RATIFY A COMPOSITE §4 CLASS? (14z-61)**~~ **RATIFIED 2026-08-06
  (maintainer: "Your proposal is ratified").** CLAUDE.md §4 amended: the
  `composite` class is the strict CONJUNCTION of flicker-tolerated and
  bounded re-convergent window, adding no tolerance to either. The seven
  `.pending` expectations became `.masked` `composite` specs carrying the
  shapes they had already printed, and the WIDE reference freeze is
  complete — `run_suite.sh` on `donovan-m5w` is GREEN, all 63 replays
  validated or explicitly skipped. Original entry below.

- **RATIFY A COMPOSITE §4 CLASS? (14z-61) — the analysis behind the
  decision above.** Seven legacy replays measure as the frozen
  hook-flicker inventory PLUS one bounded re-convergent window per
  select-screen ENTRY (table in 14z-61). Both halves are already ratified —
  `flicker` (§4 v2) and `window` (§4 v3) — but no single class expresses
  their conjunction, so those replays cannot be frozen without either a new
  class or a fudge. They are `.pending` and fail the suite meanwhile.

  **Proposal: `composite <baseset> <flicker-csv> <window-list>`**, defined
  as the strict CONJUNCTION of the two: every divergent run must be
  accounted for by name, the flicker set must match the frozen inventory
  exactly, the window list must match exactly, and the run must fully
  re-converge. It tolerates nothing that `flicker` and `window` do not each
  tolerate, and it is strictly stronger than either alone.

  Implemented and ground-truthed ahead of the decision so ratification is
  one word rather than a session: `tools/compare_composite.py`,
  `tests/test_compare_composite.sh` (7 synthetic cases + a no-loophole
  check — extra flicker frame FAILS, missing flicker frame FAILS, onset
  moved one frame FAILS, no re-convergence FAILS, bit-identical FAILS, an
  unfrozen second window FAILS). **Nothing validates against it until you
  say so**: accepting means turning each `.pending` file into a `.masked`
  one carrying the spec it already prints.

  **Recommendation: ratify.** The alternative readings are worse — calling
  these replays `skip` hides a real comparison, and widening `flicker` to
  swallow a 900-frame run would be the loosening §4's standing watch exists
  to prevent.

- ~~**FREEZE THE WIDE TRACK? (14z-61).**~~ **DONE 2026-08-05 (maintainer:
  "yes freeze and register as wide reference first, then we resume").**
  `9bac6ee3 -> donovan-m5w`; see 14z-61. Original entry below.

- **FREEZE THE WIDE TRACK? (14z-61) — the analysis behind the decision.** `build/m5_wide` (`9bac6ee3`) is now
  playtest-confirmed with and without Donovan, both WIDE profile gates are
  green, and the new rendering + member-identity gates are green. The
  registry convention is that rows are added at FREEZE time as a STATE.md
  decision, so this is not mine to do.
  **Recommendation: freeze and register it** as the WIDE reference
  (`donovan-m5w` alongside `donovan-m2c`), for one specific reason beyond
  bookkeeping: M3a moves the tenant from `0x0F` to `0x13` and will churn
  the select records, the thunk id and the bank-table row at once. Without
  a registered WIDE reference, a regression during that work has nothing to
  bisect against on this track — which is exactly the position that made
  the sprite garble expensive.
  Cost if we skip it: none today; the risk is only felt later, and by then
  the build may not be reproducible from the tree.

- **THE SELECT SCREEN AND THE SUPERSET INVARIANT (14z-60r).** Drawing three
  new medallions requires the wheel OBJ record to grow from 18 to 21
  entries and its coordinate list likewise. Measured: neither can grow in
  place (another record starts immediately at `0x272ABA`; the coord list is
  immediately followed by the shared global pool), so both must relocate —
  cheap, one referrer at `PRG:0x2689FE`. **The problem is not placement, it
  is the invariant.**

  The record's `count` word changes and its `budget` word is debited from
  the OBJ emitter's shared per-frame budget — GOTCHAS records that exact
  coupling flipping a borderline skip decision into a one-byte work-RAM
  divergence. Three more sprites also render. **So any legacy replay that
  reaches the select screen will diverge in RAM.** M2b's select work avoided
  this by strict in-place replacement preserving the host's budget word;
  adding CELLS makes that impossible by construction.

  CLAUDE.md §1 covers "any match, **menu path**, or attract sequence", so
  this needs an explicit ruling rather than an assumption:

  **A — a bounded select-screen carve-out (recommended).** Legacy replays
  are compared as today up to select entry, and the select-screen
  divergence is MEASURED, mechanism-attributed and frozen per replay, in
  the same style as the existing `diverge` constants and masked windows.
  Rationale: the invariant's purpose is that vanilla *gameplay* is
  untouched, and a select screen that offers three more characters is by
  definition content that involves them. Condition: the divergence is
  measured and frozen BEFORE acceptance, never accepted blind, and must not
  extend past the select screen into match state.

  **B — keep the wheel vanilla**, reach the newcomers by another mechanism
  (the option-2 hold-Start alternates the maintainer already ranked lower).
  Preserves the invariant literally; costs the decided roster UX.

  **C — attempt a RAM-neutral extension.** Not viable: the budget word must
  cover the entries actually emitted, and three extra sprites change OBJ RAM
  regardless. Recorded so it is not re-proposed.

  **Recommendation: A**, with the measurement done first so the ruling is
  made on a number rather than on a prediction.

  **MEASURED 2026-08-05 (14z-60s), and the number is good.** Built
  (`select_wheel roster21`) and compared against the previous WIDE build on
  the masked basis, so the wheel change is the only variable:

  | replay | frames | divergent | window | after |
  |---|---|---|---|---|
  | `04_select_fuzz` | 3520 | 162 | 890-1051 | 2469 identical |
  | `02_demitri_vs_cpu` | 5520 | 733 | 890-1622 | 3898 identical |
  | `03_two_player_vs` | 5320 | 913 | 890-1802 | 3518 identical |
  | `09_mirror_pick` | 4720 | 993 | 890-1882 | 2838 identical |
  | `05_timeout_idle` | 12120 | 733 | 890-1622 | 10498 identical |

  Every replay: **onset at frame 890 — select-screen entry — exactly ONE
  contiguous run, and FULL RE-CONVERGENCE.** Match state is bit-identical
  in all five, including a complete timeout match (10,498 identical frames
  after the window closes). The divergence is confined to the screen we
  deliberately changed and reaches nothing else.

  That is a **stronger** guarantee than the existing frozen-`diverge`
  class, which never re-converges at all. The proposal for ratification is
  therefore a new comparison class: **"bounded select-screen window,
  re-convergent"** — onset frame, window end and run-count frozen per
  replay, with re-convergence and match-state identity as the assertions.
  Mechanism: select-screen init caches the record pointer we repointed
  (`GOTCHAS` class 4), which is why onset is identical across replays.

- ~~**THE `0x360+id` ANIM BLOCK (14z-60)**~~ **DECIDED 2026-08-05
  (maintainer): option A, INHERIT — "since we can. If it fails, we'll
  fall back to option B (relocation)."** So a newcomer at `0x13` plays
  anim `0x363` from the shared `0x360-0x36F` block, exactly as vsav2
  ships; sites `PRG:0x003E40` and `PRG:0x004082` stay folded and are
  recorded as `inherit` in the tenant manifest. Fallback if playtest shows
  the inherited animation is wrong for a newcomer: relocate the block to a
  free 32-wide anim-number range and widen both masks. Original write-up
  kept below.

- **THE `0x360+id` ANIM BLOCK (14z-60) — the analysis behind the decision
  above** — of the seven sites that fold the
  character id to 4 bits, five are ordinary porting work; two
  (`PRG:0x003E40`, `PRG:0x004082`) compute a per-character anim number in a
  block that is genuinely 16 wide (`0x360-0x36F`, with `0x370+` already
  occupied). **Option A: inherit** — a newcomer at `0x13` plays `0x363`,
  which is exactly what vsav2 ships, Capcom having left both folds in
  place. **Option B: relocate** the block to a free 32-wide range and widen
  both sites — a numbering audit plus shared-engine edits, for a family we
  cannot yet name. **Recommendation: A**, on the strength of vs2 being a
  shipped existence proof; revisit only if a playtest shows the inherited
  animation is wrong for a newcomer. Detail in session 14z-60 and
  `docs/game/atlas/id_space.md`.

- ~~**M5 SOUND NEEDS A DATA HOME (14z-52)**~~ **SETTLED 2026-08-04 by the
  dual-track decision below: it lives in `wide_ext`.** Two corrections to
  the record that got it there:
  **(a) Option B was DEAD and the recommendation was wrong.** It proposed
  reclaiming the "inert since 14z-31" `weapon_accent_t0/_t1/rowd_slot`
  rows. Measured 14z-59g: those are `data_port` rows writing 0x20 bytes
  each to `0x39FBE0-0x39FC40`, which is in NEITHER hole (`hole_a`
  `0x0BF6A0-0x100000`, `hole_b` `0x3EC720-0x400000`). They are in-place
  palette overwrites, not hole allocations, so reclaiming them frees
  **zero** of the 352 bytes needed. The original entry mistook them for
  hole tenants.
  **(b) Option C stopped being expensive.** It was rejected as "larger
  blast radius" before WIDE existed; WIDE is now demonstrated on both
  emulators, so it is the cheap option — and option A (Jedah's anim
  region) keeps its unaudited dead space AND stays available for the
  ported select web, which was its earmarked purpose all along.

- ~~**M5 VOICE SAMPLES (14z-51)**~~ **DECIDED 2026-08-04 (maintainer):
  "A then B, gates stay strict, option C is rejected."** Ship M5 with those
  specific sounds silent now (option A — it matches the current
  silent-by-design behaviour for exactly the sounds that cannot be
  faithful); revisit growing the QSound sample region (option B) at M3,
  when Huitzil and Pyron force the same question at scale, inside the
  measured 16 MB ceiling. **Option C (overwriting low-value vsav content)
  is rejected** and may not be re-proposed — it is superset-invariant-
  adjacent. Original entry with the full option analysis kept below.

- **M5 VOICE SAMPLES (14z-51) — the analysis behind the decision above:**
  6-8 of Donovan's sounds (his voice
  lines / vs2-new sfx: ids 0x71D/0x73E/0x753-0x756, likely the "Change
  Immortal" family) do not exist in vsav's sample ROMs, which are
  byte-full. Options: A) ship M5 with those specific sounds silent
  (shared sfx all restorable regardless); B) grow the QSound sample
  region via driver descriptor (vm3.11m/12m from 4MB->8MB members or
  add members; CLAUDE.md rule 1 permits load-map changes; MiSTer
  impact unknown); C) overwrite low-value vsav content (risky,
  superset-invariant-adjacent). Recommendation: A now (matches the
  current "silent by design" behavior for exactly the sounds that
  cannot be faithful), revisit B at M3 when Huitzil/Pyron force the
  same question at scale.
  **UPDATED 14z-59f — option B now has a measured hard ceiling.** CPS-2
  WIDE v1 already declares QSound at **16 MB, which is MAME's maximum**
  (`qsound_device` is a `device_rom_interface<24>`, 24 address bits). So
  B is available and proven on both emulators up to 16 MB and NOT ONE
  BYTE further: growing past it would mean widening a SHARED MAME device,
  which is outside Rule 1 v2. If Donovan + Huitzil + Pyron voice banks do
  not fit in the 8 MB the profile adds, the answer has to be exclusivity
  or banking, not more region. Worth sizing that before committing to B
  at M3. (Two duplicate copies of this entry were merged here.)

- ~~**ROSTER ACCESS MECHANISM**~~ **DECIDED 2026-08-04: option 1, an
  altered select screen keeping the existing cells and appending the three
  newcomers; hold-Start alternates are the fallback. See 14z-59l.**
- See SPEC §7 for the rest. Nothing blocks current work.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
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
- **OPEN (cosmetic):** Huitzil's win QUOTE text — root-caused, not built.
  The consumer's `lea -4(a0,d0.w)` bias means it reads index 0x60+id-1.
- **OPEN:** FG pacing — untouched.

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
