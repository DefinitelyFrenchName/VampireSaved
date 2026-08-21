# STATE — living progress log

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
  read 360/377/360 on ours. **Fidelity question for the ruling queue:
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
was the point of doing #106 first. The window itself (#107 only) waits
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

## 14z-99 FIELD RESULTS (maintainer, 2026-08-20) — THE WHOLE WINDOW IS
## FIELD-CONFIRMED: #103 + #104 + #105 all CLOSED; #99 UN-PARKED

Maintainer's early field pass of merged-m4 (`build/m3b_merged11`):
- **#105 CONFIRMED**: AUTO-mode tenant portraits colored. CLOSED.
- **#103 CONFIRMED on its exact scenario**: no stalling/freeze at win or
  lose with ANY VS2 character, including Donovan losing to Lilith. No
  crash. CLOSED. (Its audits stay as regression locks; #99's rig is now
  unblocked in fact, not just on paper.)
- **#104 CONFIRMED, broader than asked**: all three VS2 characters show
  correct sprites during Victor's AND Bulleta's 6+HP throws. Bulleta was
  never named in the ticket — her grab holding correctly is the ruled
  option (a) ("all sixteen" attackers ported) paying off on a surface no
  rig targeted. CLOSED.
- **The window is therefore field-confirmed END TO END** and **#99
  UN-PARKS** (comment posted): the continue rig's blocker is gone in
  fact; next concrete step is re-running the rig to the exact
  continue+switch → match-5 context. Held loosely: if the racy-lose-flow
  hypothesis was #99's mechanism, #103's fix may have removed its
  trigger — the clean pass is weak evidence for that, not proof.
- **In-depth pass, later the same day (maintainer):** Dark Force
  activation AND end clean for all three VS2 characters (§4 coverage
  item, field-confirmed). **All throws on the VS2 characters confirmed
  good — INCLUDING the transformation throws (Demitri's Midnight Bliss,
  Zabel's Hell Dunk).** The transformation class is a notably strong
  #104 corroboration: those swap the victim's ART entirely through
  per-victim records, exactly the record family capture_kf ported.
- **Sound observation, recorded and attributed**: Phobos's boy-sidekick
  voice at fight start/end reported better/tighter, more faithful to
  VS2. The 14z-99 window shipped ZERO audio-affecting rows (#103
  relocations / #104 keyframes / #105 palettes), so this is anterior to
  the window as the maintainer suspected — most plausibly the 14z-96
  #101 kernel voice port noticed in new contexts. Nothing to chase; NOT
  evidence of a window-induced audio change.

## 14z-99 CLOSE (executed post-freeze, 2026-08-20) — the skipped ritual,
## caught up while the maintainer field-passes merged-m4

The freeze session ended without the end-of-session ritual; this pass
(same day, next session) executed it. **No shipped byte moved.**
- **patch_index.md + patch_notes.md caught up** with the window (the
  CLAUDE.md §5 "same commit" rule was missed at W1/W2/FREEZE — same
  class as the 14z-94 late-recording finding): new 14z-99 rows/section
  (#103 / #104 / #105 / #43(b)), bundle-row statuses moved off their
  2026-08-06-era fingerprints, patch_notes' misfiled 14z-96 section
  moved up to restore newest-first.
- **HANDOFF.md**: run_wide "WHAT TO LOOK AT FIRST" block rewritten for
  merged-m4 (was still narrating the 14z-96 grunt fix); the 14z-99
  window row added to the build-registry table; the battery-rows
  paragraph and stray command comments moved m8 -> m9.
- **registry.tsv**: the two superseded battery rows (donovan-m8-stock/
  -stage4) annotated CARRIED->m9 (notes column only; no dispatch field
  moved).
- **Issues**: #99 got the status comment (blocker #103 landed; the #102
  branch resolved NOT-OURS) — it un-parks after the field pass.
  #103/#104/#105 stay OPEN awaiting that pass; #43 already CLOSED.
- Verification: retraction-discipline grep sweep clean (remaining hits
  are marked history); `run_all_static.sh` re-run green before commit.

## Session 14z-99 FREEZE — THE WINDOW EXECUTED END TO END: donovan-m9 /
## huitzil-m18 / pyron-m12 / merged-m4. #43(b) + #103 + #104 + #105 all
## landed; every gate that saw the new artifacts is green.

**Maintainer "go" 2026-08-20; every piece was rehearsed before landing
(14z-99 (9)); the merged artifact is BIT-FOR-BIT the rehearsal
(2343607a == build/probe_window).**

**The new reference state:**
| artifact | build dir | fingerprint | ops |
|---|---|---|---|
| donovan-m9 | build/don_m9 | 428fc0c9 | 323 |
| donovan-m9-stock | build/m5_stock4 | 16da59b6 | — |
| donovan-m9-stage4 | build/don_m9_s4 | 35e948a1 | — |
| huitzil-m18 | build/hui45 | c4bbb375 | 361 |
| pyron-m12 | build/pyron29 | 4c3c072b | 296 |
| merged-m4 | build/m3b_merged11 | 2343607a | 802 |

**THE STOCK TWIN MOVED for the first time since 14z-91** (a054de5c ->
16da59b6): #103's pcrel rows are not profile-gated — the stock track
gets the stall fix too, by design. #104/#105 rows are variant-gated.

**What landed (each its own commit):**
- W1 #43(b): ALLOW_FALLBACK=True; the ruled 3-row movement measured as
  ONE row (0x028122 -> 0x028e42 plausible-0.90) with ZERO build effect
  (no live consumer; merged patch bit-identical). Wholesale map regen
  measured DESTRUCTIVE and avoided (gotcha in the row note).
- W2 #103+#104+#105: manifests uncommented + colors sed; the tracked
  manifests regenerate the rehearsed patch BYTE-IDENTICALLY; audit
  defaults flipped with WEAKEN_P1 tied to the EXPECTs.

**The freeze verification, all green:**
- test_m3a_reproducible: all five artifacts rebuild bit-exact from the
  tree (pins re-pointed; whole-artifact manifests updated).
- run_suite x3, freeze + verify passes: every legacy masked replay on
  its EXACT frozen class (the f890 content change sits inside the
  ratified select windows); the moved self-frozen tenant/select .sha1s
  re-frozen (60 across the sets); SUITE GREEN x3.
- NEW REPLAYS CLASSIFIED (the 14z-78 "replay added after a freeze"
  ruling honoured at the freeze itself): 96_don_victor_grab and
  104_1p_auto_ko_win measure as PURE LEGACY pairings unpoked (Demitri
  vs Morrigan / Demitri vs Lilith — signature-checked on +0x60.l), so
  per the audit_legacy_pairings doctrine they got MASKED classes vs the
  vanilla basis, not self-frozen sha1s: window 889..1871 and 889..1494
  (the ratified §4 v3 select-window class, onset matching all nine
  siblings; identical measurements on all three builds; vanilla basis
  logs frozen with the 16_xemu_2p instrument control).
  103_tenant_2pwin_auto is tenant content (Donovan cell) -> .sha1.
- tenant_loop re-frozen 323/361/296 + 596/646 + 802/899, every delta
  attributed; manifest_merge pcrel tuple re-frozen (2,5,2)/5/2 measured.
- Merged gates: select-bank PASS (thunks at their new window
  addresses), trap parity PASS, FG parity PASS (native-exact staircase
  — the x028122-adjacent damage path, extra assurance for #43(b)),
  render-content PASS (bands byte-equal to the NEW solos,
  de-substitution held, poison controls fired), audit_merged_legacy
  PASS (leg a 47/47 on the ratified classes, leg b guard-clean).
- The four flip-audits green at their new defaults (and previously on
  the identical rehearsal bytes).
- M2 battery: 23/23 gates PASS + the structural wide-render skip on a
  stock-track run, covered by direct invocation on the window pair
  (m5_stock4 + don_m9): PASS incl. the de-substitution invariant.
  Getting there surfaced and fixed FOUR latent instrument defects, none
  a window regression (each A/B'd against pre-window bytes):
  1. build_donovan.sh never cleared prg/ before patch_prg, so any
     in-place STOCK rebuild tripped select_port's #46 idempotence stamp
     — fixed at the root (rm -rf prg/ like rompath).
  2-3. THREE copies of a stale row-0x0F literal (test_don_accent x2,
     test_don_colors) frozen before 14z-91's ratified fixture-override
     deletion — re-frozen to the measured post-14z-91 value; the first
     fix missed the copies because I fixed files instead of GREPPING THE
     CLAIM (the 14z-71 standing order, re-learned live).
  4. test_don_sound's id inventories were frozen on ae701ffb (14z-52,
     NINE generations stale; drift identical on pre-window bytes) —
     re-frozen; the music-range tripwire (the gate's real property) was
     green throughout. Also: a deterministic MAME TEARDOWN segfault
     (host-side, after ring_tap's END marker, pre-window builds too) is
     now tolerated ONLY behind the instrument's own completion marker —
     a mid-run death still fails.

**Pins re-pointed (the reference-rot discipline):** m3a_reproducible
EXPECT_*/MANI_*; test_merged_render_content D/H/P rows -> don_m9/hui45/
pyron29; audit_merged_legacy leg-b solos; the nine audits' BUILD
defaults m3b_merged10 -> m3b_merged11; audit_hui_grunt gains the
m3b_merged11 frozen row (kernel rows untouched by the window);
registry.tsv +5 rows; expectation sets carried-renamed (m8->m9,
m17->m18, m11->m12, + the two battery rows).

**Issues:** #103, #104, #105 — **ALL THREE FIELD-CONFIRMED AND CLOSED
(2026-08-20, see the FIELD RESULTS entry above); #99 un-parked.**
#43 CLOSED
((a) 14z-95, (b) here; the thread carries the (b) write-up). Play:
`tools/run_wide.sh build/m3b_merged11 fbneo` — or record the session:
`WIDE_RECORD=<name> tools/run_wide.sh build/m3b_merged11 mame`.


## Session 14z-99 (9) — THE WINDOW IS FULLY REHEARSED ON ONE COMBINED
## ARTIFACT: #103 + #104 + #105 together, all four flip-audits green,
## legacy cost = ONE frame. The window action is "uncomment + one sed +
## battery + freeze".

**build/probe_window (fingerprint 2343607a, UNREGISTERED)** = the EXACT
window recipe on scratch copies of the tracked manifests: #103's staged
pieces uncommented (recon_overlay INSIDE [[tenant]] + the two
pcrel_escape_fix rows), #104's 15 capture_kf rows uncommented, #105's
colors=10 sed applied. **802 ops** (764 + 32 #104 + 6 #105; #103's pieces net 0 — its relocations move ops, not add them) [CORRECTED from "807": that count was the FAILED first build with the doc-root overlay hijack],
GENERATION OK, ZERO tripwires, merged-with-gfx built end to end.

**The four flip-audits, all green on it:**
| audit | mode | result |
|---|---|---|
| audit_don_grab_pose | EXPECT_MATCH=1 | all three tenants hold native's records (11/26/11) |
| audit_win_pal_auto | EXPECT_WHITE=0 | all four legs COLORED |
| audit_don_lilith_ko | WEAKEN_P1=1 EXPECT_STALL=0 | FLOWED 2880 (KO 6600 -> stage 9480); Victor control FLOWED 560 |
| audit_don_ko_writer | WEAKEN_P1=1 EXPECT_DEFECT=0 | HEALTHY kill-commit f6561; Victor control healthy |

**Legacy A/B vs frozen merged-m3** (replays 03/16/96 whole-run): **ONE
differing frame — f890 — bit-identical from f891**, all three. The
combined window's entire legacy cost is #104's class-4 pointer-cache
frame; #103 and #105 contribute zero.

**WEAKEN_P1 (NEW mode on both #103 audits, fix-verification only —
refused with the defect EXPECTs):** the natural-mash death is
LOTTERY-BOUND per build, and on the FIXED build the mash-Donovan WINS
(measured: weakened to 30hp he still never took a hit — the CPU dies at
f7000/f13900; his old losing trajectory WAS the escape's perturbation).
The mode cuts his inputs at f6100 and pins hp/white to 5 once
(both-words, no re-pin can land on a corpse); the CPU's own hit kills
through the real judge. The natural-mash NO-KO on the fixed build is
itself corroborating evidence for the fix, and it is also why the
14z-98 audits' "flip the default when the fix lands" now reads: flip
the default AND set WEAKEN_P1=1.

**THE WINDOW CHECKLIST (supersedes the per-fix notes; everything below
is rehearsed):**
1. Uncomment #103's pieces in donovan.toml — recon_overlay goes INSIDE
   [[tenant]] after src_char (the staged comment is now correct; the
   old "top-level" wording was a MEASURED trap — doc-root placement
   hijacks every tenant's overlay on a merged build).
2. Uncomment the 15 capture_kf rows in ALL THREE manifests (bare-#
   strip; the round-trip is byte-exact).
3. `colors = 8` -> `colors = 10` in all three (one sed, staged comment
   names it).
4. Rebuild all four artifacts + merged (expect solo op counts +32+2
   each; merged 764 -> 802 (#103's pieces relocate, net 0)).
5. Flip defaults: audit_don_grab_pose EXPECT_MATCH=1;
   audit_win_pal_auto EXPECT_WHITE=0; audit_don_lilith_ko
   EXPECT_STALL=0 (+WEAKEN_P1=1); audit_don_ko_writer EXPECT_DEFECT=0
   (+WEAKEN_P1=1); audit_kill_poke_shape unchanged (engine facts).
6. Full battery + run_suite + re-freeze expectation sets (the select
   window class contents re-measure; the f890 window carries #104's
   new pointer values) + registry rows + tags.
7. One-look checks at the window: 0xBE27A row 0x11 (Pyron-as-attacker
   aliases Demitri's block — fix only if he has a capture move);
   re-point test_merged_render_content's D/P reference rows if those
   tenants re-freeze.

**No shipped byte moved.** The 14z-96 freeze stands. probe_104,
probe_105, probe_105f, probe_window are UNREGISTERED probes (scratch
recipes reproducible from STATE (7)-(9) + the staged blocks).


## Session 14z-99 (8) — #105 ROOT-CAUSED AND FIXED: the port carried 8 of
## the 10 color sets, and sel 8/9 ARE the AUTO sets. One constant. Probed
## solo and in the COMBINED window rehearsal — which caught a staging bug
## in #103's block that only a merged build could show.

**THE MECHANISM, measured end to end (canonical-timeline instruments —
the -debug legs diverged on the mash-driven AUTO match and were
discarded per the 14z-98 gotcha):**
1. The 0x5F1B6 win-pal thunk fires IDENTICALLY on both legs (same frame,
   same registers) — the load call is not the difference.
2. The staging loader (the engine copy helper `0x1C3A4`, writer PC
   `0x1C3B6`) writes the staging buffer `$FF41A2+` at the SAME frame on
   both legs — real colors on the no-AUTO leg, `0xFFFF` on the AUTO leg:
   same code, different SOURCE.
3. The winner-struct diff between legs is 7 bytes, and one is the
   selector the vanilla source math consumes: **`+0x3AE` = 8 under AUTO,
   0 without** (vsav encodes AUTO as +8 in the color-select byte).
   Vanilla source = `0x3AD700 + (sel*0x11 + id)*0xA0` (site disasm at
   0x5F1A6-0x5F1FA; note the *5 then *0x20 = *0xA0 per (sel,id)).
4. **Both games' pools carry exactly TEN sets (sel 0-9)** — heads
   identical across sets 0-9, garbage from 10; sets 8/9 are the AUTO
   colors, real and distinct in both games. `win_pal_variant` ported
   `colors = 8`, so an AUTO tenant winner indexed the sparse block at
   `blk + 8*0xAA0` — past `blk_len = 7*0xAA0 + 0xA0` — into hole fill
   = the white portraits. Vanilla covers sel 8/9 natively, which is why
   vanilla+AUTO renders fine (the not-ours control).

**THE FIX: `colors = 8 -> 10`** in all three tenants' win_pal_variant
rows (pure data — vs2's own AUTO sets ride the existing port machinery;
+2 data ops per tenant; sparse blocks grow 0x4B20 -> 0x6040).

**Probed solo (build/probe_105 gfx-free, then build/probe_105f FULL
merged):** audit_win_pal_auto EXPECT_WHITE=0 — ALL FOUR legs COLORED on
both probes; the win screen and the VS/challenger screen RENDER
correctly on the full probe (Donovan+Anita in the AUTO color set;
snapshots kept); the staging/palette timeline shows the full correct
set from f5450. **Legacy A/B vs frozen merged-m3: BIT-IDENTICAL
whole-run** (replays 03/16) — not even an f890 frame; nothing
select-init caches moves under this fix.

**AN INSTRUMENT ARTIFACT CAUGHT BEFORE PUBLICATION:** the first render
check ran on the GFX-FREE probe — the portrait is TENANT ART, so it
drew blank/pale and the VS-splash side art read "white", which briefly
looked like a SECOND sel-indexed defect. Both observations were VOID
(the full-gfx probe renders both correctly). Render verdicts need a
build with gfx; palette/RAM verdicts do not. Recorded as a gotcha.

**THE COMBINED WINDOW REHEARSAL (build/probe_window, fingerprint
2343607a, UNREGISTERED — the exact window recipe: #103's two pieces +
overlay, #104's 15 rows, #105's colors=10):** ~~807~~ **802 ops**
[corrected at W2: 807 was the FAILED doc-root build], GENERATION OK,
zero tripwires. **It caught a real staging bug on its FIRST build:**
the #103 staged comment said recon_overlay is "a top-level key" —
placed at DOC ROOT it works on a SOLO build but HIJACKS EVERY tenant's
overlay on a MERGED build (`recon_for()` reads
`port.get("recon_overlay")` FIRST and `port` is the merged doc), so
huitzil lost its own overlay rows and generation died on
`x022400+0xb74` — the EXACT failure the 14z-80 scoping fix quotes. The
correct placement is INSIDE [[tenant]], like huitzil's; the staged
comment in donovan.toml is corrected and the trap recorded. The 14z-98
solo probe could never have seen this — solo builds read the root key
fine. Window flip-audits on the combined probe: grab-pose
EXPECT_MATCH=1 GREEN; win-pal / lilith-ko / ko-writer running at this
entry's close (results in (9)).

**STAGED IN THE TRACKED MANIFESTS (inert, parse-verified, colors still
8):** the #105 window action as an edit instruction beside each
`colors = 8` line (a staged VALUE swap cannot ride the uncomment rule —
a duplicate key would refuse to parse; the window action is one sed,
written in the comment).

**No shipped byte moved.** The 14z-96 freeze stands.


## Session 14z-99 (7) — #104's FIX IS AUTHORED, PROBED AND STAGED: the 15
## capture-keyframe blocks port clean, all three tenants hold native's
## records, and the legacy cost is ONE frame — the ratified class-4 cache

Executed per the (6) directive. **No shipped byte moved** — the machinery
landed inert, the rows are staged comments, and the probe is unregistered.

**Generator machinery (landed, PROVEN INERT — test_m3a_reproducible green
on all four frozen references + merged, twice, after each edit):**
- `[[data_port]]` gains **`slot_rows`** — "row:expected_vanilla_ptr" pairs
  naming EXPLICIT slot_ptr_table rows to repoint at the placed blob (the
  owner-row branch serves only a tenant's own row and cannot express a
  LEGACY-row repoint). Every entry is old-verified against the pristine
  image (the #18 discipline); dst/dst_old_head anchor the superseded
  vanilla block by content; dst_end is deliberately not checked (nothing
  is written at dst, and the placed blob is LONGER by design).
- The `_span_collisions` identity for a slot_rows row extends with its
  slot_rows string — keying by dst alone made capture_kf_jedah "collide"
  with throw_victim_keyframes (both ANCHOR 0xB19F8 while writing disjoint
  bytes). Two slot_rows rows poking the same table row would dodge the
  scan and die downstream at patch_prg's op-overlap assertion.

**The 15 rows** (generated from the measured inventory, vs2 verbatim,
vhunt2 as `orc` — every block byte-identical vs2==vh2 over its whole
span, verified before authoring): capture_kf_{bulleta..jedah}, Zabel's
blob serving rows 0x04+0x0B (vs2 shares one block where vsavj
interleaves two tables), Bishamon's serving 0x08+0x18 (Oboro).
`only_variant_slot` keeps the stock twin bit-identical by construction.

**THE PROBE (build/probe_104, UNREGISTERED, scratch manifests =
tracked + the rows uncommented; merged1-style gfx-free pack against
wide0 — the audit reads RAM, not pixels):** 796 ops = 764 + 15 blobs +
17 pokes, GENERATION OK, zero tripwires.
- `audit_don_grab_pose EXPECT_MATCH=1`: **green on ALL THREE tenants** —
  Donovan holds native's 0x287418 (idx 11), Phobos 0x2481EA (idx 26),
  Pyron 0x26614C (idx 11) — with the legacy control agreeing (Demitri
  11/11 both engines).
- **Legacy A/B vs frozen merged-m3** (replays 03/16/96 whole-run,
  MAME): **EXACTLY ONE differing frame — f890 — then bit-identical to
  the end** (5,320/4,320/5,520 frames), including replay 96 UNPOKED — a
  grab-heavy pure-legacy match whose captures execute through the
  RELOCATED blocks. f890 is the ratified §4 class-4 mechanism
  (select-init caches the record pointers the fix repoints); one sampled
  frame, single contiguous run, full re-convergence, match state
  untouched. At the re-freeze vs VANILLA this rides the existing
  select-window class; the frozen window contents re-measure as always.
- Ordinary hits: covered by the same A/B — non-capture reactions never
  transit the positioner ($134(a4) gate), and replay 96's full match is
  bit-identical from f891.

**STAGED:** the rows sit COMMENTED at the end of all THREE manifests
(the #103 bare-# convention; the mechanical uncomment reproduces the
probed recipe byte-for-byte — round-trip asserted over all 180 row
lines). Window action: uncomment in all three + flip
audit_don_grab_pose's EXPECT_MATCH default to 1; expect +32 ops per
artifact (merged 764 -> 796) and the select-window class contents to
re-measure.

**#104 is now window-ready end to end.** Remaining open on the ticket:
nothing — the row 0x11 (Pyron-as-attacker) observation stays recorded on
the issue as a separate check at the window.


## Session 14z-99 (6) — THE FREEZE PHILOSOPHY, stated by the maintainer
## (2026-08-20), and the directive: do #104 and #105

**Maintainer, verbatim intent:** "a freeze should ideally reflect a
reference state. It need not be perfect, but it needs to be good enough
that it would be the reference for upcoming builds, reference against
which to test." Consequence for the pending window: it should land with
the KNOWN in-scope defects fixed — #103 (staged), #104 (ruled (a),
feasibility measured), #105 (locked, fix hunt open) — rather than freeze
around them. **Directive: do #104 and #105** (author + probe the fixes;
input needed only where a real decision surfaces). They are also happy
to test the record/playback system.

## Session 14z-99 (2) — #105 REPRODUCED from the maintainer's captures:
## the 2P victory screen, and the gate is AUTO SELECTED BY THE WINNER.
## Vanilla renders the same flow COLORED — the defect is ours.

The captures landed (`../Images/white_win_portraits`, three screens:
Phobos, Pyron-read, Donovan+Anita — all the same surface) and named it:
the **2P victory screen** — winner portrait + win quote over the loser's
CONTINUE countdown. Reproduced deterministically the same session.

**The hunt, in order (each step measured, snapshots kept in scratch):**
1. ~~The 1P arcade flow CANNOT show this screen~~ **RETRACTED SAME
   SESSION, maintainer-corrected: the screen shows after match wins in
   BOTH 1P-vs-COM and 2P** — reproduced in 1P (white Phobos portrait,
   PRESS START corner, field-confirmed "one of the offending screens"),
   frozen as replay 104 + audit leg D. The wrong reading came from two
   rig traps, both now game gotchas: coarse post-KO sampling lands on
   the MAP/tally screens that come AFTER the win screen ("the screen
   you check after the round end is ALWAYS the map screen that comes
   after the win screen" — maintainer), and buttons pressed past the KO
   skip the victory surfaces. The 14z-98 (8) rig missed the surface for
   the same reasons, not because the flow lacks it.
2. **vsav's AUTO is AUTO-GUARD (a handicap; the human still plays), NOT
   autoplay** — measured: an idle AUTO character auto-blocks and never
   attacks (8,000+ frames, zero hits dealt). The menu cursor was
   snapshot-PROVEN on AUTO before concluding anything.
3. The discriminating triple, same replay skeleton, MAME:
   - merged-m3 + tenant winner + no AUTO (replay 61): **COLORED**;
   - merged-m3 + tenant winner + AUTO (replay 61 + D,D,confirm at the
     2P mode menu, up ~f1950): **WHITE** — the maintainer's captures,
     pixel for pixel (fade completes, portrait stays white, quote and
     background correct);
   - **pristine vsavj + AUTO winner, same replay: COLORED** — the #102
     discipline (vanilla leg before blaming the port); NOT the engine's
     own AUTO behavior.
   - merged + LEGACY winner + AUTO: **UNMEASURED** — the leg's mash ran
     past the KO and pressed through the win screen (the rig trap
     above), so its "skips the portrait screen" reading is VOID, not a
     flow fact. Re-measure with inputs ended at the KO if the fix needs
     the legacy-AUTO datum.
4. **Record-level:** the win-pal window `0x90C2A0` holds all-`0xFFFF`
   DURING the screen, and the real colors arrive ~f5850 — AFTER the
   screen has left. **The upload is LATE, not absent** — suspect the
   `0x5F1B6` win-pal path's SCHEDULE under the AUTO flag, not a wrong
   palette source.

**Locks (the #98 discipline):** `tests/replays/103_tenant_2pwin_auto.rpl`
(= 61 + three AUTO lines) + `tests/replays/104_1p_auto_ko_win.rpl` (the
1P-vs-COM flavor, real-KO win, inputs ending at the KO) +
`tests/audit_win_pal_auto.sh` (~10 min, 4 legs): A merged+AUTO 2P
freezes the defect (EXPECT_WHITE=1, flip at the fix); B merged no-AUTO
must stay COLORED (whiting = the defect grew past the AUTO gate); C
vanilla+AUTO must stay COLORED (whiting = the not-ours premise is dead,
re-derive); D merged+AUTO 1P freezes the maintainer's own flavor
(field-confirmed against the rig's snapshot). Verdicts SCAN the dump
window — no pinned frame constants (the #10 lesson). AUDIT PASS on
merged-m3, all four legs.

**Field-confirmed (maintainer, same session):** the capture triple is
"exactly the auto mode bug vs the correct screen, as I experience it";
the 1P leg's white snapshot is "one of the offending screens"; and their
1P-vs-COM datum is what caught my flow claims (they also noted they
never play or test in AUTO — why nobody saw this before).

**NEW INFRASTRUCTURE (maintainer-requested, 14z-99):** MAME input
recording wired into the playtest launcher — `WIDE_RECORD=<name>
tools/run_wide.sh <build> mame` records the session as a `.inp` with a
fresh NAMED nvram start state under `~/.cache/vampire-saved/inp/<name>/`
(hand off the directory + the build name = a frame-exact replay protocol
on the pinned binary; `WIDE_PLAYBACK=<name>` replays against a throwaway
nvram COPY). Control mappings untouched; host keys never enter the .inp.
Round-trip smoke-tested (8s attract, record + clean playback); the first
real session file gets the instrumented frame-exactness validation.
FBNeo's SDL frontend has no equivalent — record on MAME.

**Next measurement (not started):** probe `0x5F1B6` on the A/B legs —
same PC both legs? where does the AUTO flag defer the upload? The
winner-id/TT path vs the schedule decides the fix shape.

**Rig notes paid for (kept versus re-derivation):** the weakening poke
is `ff8850:00050005` — BOTH words, never the 2-byte shape
(audit_kill_poke_shape), and never re-poked on a corpse (a 300f cadence
revived a dead body mid-settle once — visible as hp 0 -> 5 in the
timeline); the 2P mode menu is up ~f1950 in the replay-61 skeleton (the
1P menu is ~f1250-2100 and 14z-98 (8)'s "2P timing ~f2800" was this
skeleton's IN-MATCH frame); heal pokes `ff8450:01200120` keep an idle
auto-guard P1 alive through a timeout round.

**No shipped byte moved.** The 14z-96 freeze stands.


## Session 14z-99 — #102 CLOSED; #104 RE-ROOT-CAUSED (the variant-row
## alias class, not an index-space drift), its mechanism LOCATED at
## PRG:0x02802E, the fix RULED option (a) and MEASURED FEASIBLE on every
## axis (premises frozen in test_capture_pose_sources.sh). Three of my own
## claims retracted along the way, one an instrument bug.

**#102 CLOSED** (maintainer-ruled 2026-08-19, not ours). The discriminator
had already answered in 14z-98 (4); the ruling was taken and executed:
issue commented + closed, NEXT_SESSION banner moved it out of Open into a
CLOSED block, STATE's pending item marked DECIDED in place,
`audit_continue_ladder.sh` and its HANDOFF row re-scoped as the REGRESSION
LOCK (leg A red ⇒ the behavior was ours after all ⇒ #102 reopens).

**#104: the staged fix design was falsified BEFORE it was built.** The
14z-98 (9) shape — "generation drift in the reaction-index space; derive
the permutation from the legacy twins; REORDER 5 sibling tables x 3
tenants" — rests on a premise that measures false, caught by a static
pre-check that cost two commands:

- The legacy twins the permutation was to be derived FROM are
  **byte-identical**: `anim_index_c` row 3 (Victor), vsavj `0x157A50` vs
  vs2 `0x13FAA2`, entry for entry over 32 entries; 10 of the 16 base rows
  match the same way. A permutation derived from them is the IDENTITY, so
  the reorder is a no-op.
- One permutation could not explain both tenants anyway (Donovan resolved
  to index 6, Pyron to a non-entry — the latter turned out to be my own
  instrument bug, below).

**THE REAL MECHANISM, measured over seven victims on both engines.** The
capture pose is selected PER VICTIM, through 32-row per-character
structures whose rows `0x10-0x1F` are byte-copies of `0x00-0x0F` (verbatim
the variant-row alias class, `docs/game/atlas` passim). A tenant victim is
served the BASE character it folds onto. Index installed at victim `+0x1C`,
ours vs native vsav2:

| victim | id → fold | ours | native | verdict |
|---|---|---|---|---|
| Bulleta | 0x00 | 12 | 12 | legacy — engines AGREE |
| Demitri | 0x01 | 11 | 11 | legacy — engines AGREE |
| Victor | 0x03 | 6 | 6 | legacy — engines AGREE |
| Lilith | 0x0e | 9 | 9 | legacy — engines AGREE |
| **Phobos** | 0x10 → 0x00 | **12** | 26 | **WRONG (Bulleta's)** |
| Pyron | 0x11 → 0x01 | 11 | 11 | right BY COINCIDENCE |
| **Donovan** | 0x13 → 0x03 | **6** | 11 | **WRONG (Victor's)** |

The legacy rows are the load-bearing part: **the reaction-index convention
is SHARED between the engines**, which is what kills the drift reading. And
the fold predicts the field report exactly — the maintainer named Donovan
and Phobos and not Pyron, because Pyron's fold value coincides with his
correct one.

**MY OWN INSTRUMENT WAS THE OTHER DEFECT.** `audit_don_grab_pose.sh`
resolved every tenant's record through `placements["regions"]["anim"]`,
which on a MERGED build is DONOVAN's placement — so the 14z-98 (7)
"Pyron mismatches too, ours 0x26654C" was an artifact. Through
`anim@pyron` his record maps to `0x26614C`, identical to native. Retracted
at the issue, in STATE 14z-98 (7), in NEXT_SESSION and in the audit header.

**The gate is rebuilt and stronger:** per-victim region resolution; a
**LEGACY-VICTIM CONTROL as section 0** (if the two engines ever install
different indices for a legacy victim, the shared-convention premise is
dead and every tenant verdict in the file is meaningless — it fails loudly
and says so); per-tenant frozen expectations including Pyron's coincidence;
and the hold is now detected from hp-DROP samples rather than a tuned 48px
window, so there is one less victim-specific constant to rot. A modal that
is not a strict majority reports NO-HOLD — a split reading is not a
measurement. AUDIT PASS on merged-m3.

**LOCATED — the mechanism is CLOSED end to end (later the same session).**
The resolving structure is the head of the ATTACKER's own keyframe block,
and the defect is seven instructions at `PRG:0x02802E`:
`move.b $382(a4),d1 ; add.w d1,d1 ; add.w (a0,d1.w),d0 ; lea (a0,d0.w),a0`
— **the first 32 words of every attacker's keyframe block are a per-victim
offset table indexed by the victim's char id UNMASKED**, and in vsavj
**all sixteen blocks alias the variant half onto the base half** —
fourteen by OFFSET, two (Zabel `0x04`, special `0x0B`) by MATERIALIZATION
(32 distinct offsets whose variant CONTENT byte-copies the base
sub-blocks, 15/16 rows, `0x1F` the exception both times — measured after
the "the two exceptions are the useful part / populated 32-entry shape"
reading, which is RETRACTED: they are the same defect stored differently,
not tenant data). The tenant lands in the base character's capture sub-block and
takes BOTH its position keyframes and its record index — exactly the "half
right, half knocked-down, very horizontal" the field reported.
Static and dynamic agree five for five: Victor's block `0x098C28` has
`block[0x13]==block[0x03]=0x0568`, `block[0x10]==block[0x00]=0x0040`,
`block[0x11]==block[0x01]=0x01F8`, and every measured A0 is
`block + block[victim] + 0x106`.
**vs2 already holds the data**: its twin blocks are NOT aliased and carry
real rows for the newcomers (vs2 Victor `0x0A8824`: 0x10=`0x1A08`,
0x11=`0x1BC0`, 0x13=`0x1D78`).

**FEASIBILITY MEASURED (post-ruling, same session) — CLEAN ON EVERY
AXIS; option (a) proceeds. Premises frozen in
`tests/test_capture_pose_sources.sh` (NEW, ci_static):**
1. Source data exists for ALL 16 attackers in BOTH vs2 and vhunt2:
   tenant rows `0x10/0x11/0x13` distinct, sub-block stride EQUAL to
   vsavj's per attacker, vs2 == vhunt2 on every tenant sub-block
   (cross-oracle: the content is real and stable).
2. Every BASE sub-block is BYTE-IDENTICAL vsavj vs vs2, 16/16 —
   legacy capture data never changed between generations. (Zabel's
   table LAYOUT differs — vs2 merges Zabel+special into one shared
   block `0x0ABC56` — but the content each game's offsets reach is
   equal.) A wholesale vs2 port is therefore legacy-safe by CONTENT,
   and the addresses never enter work RAM (the positioner emits
   VALUES; the victim's `+0x1C` comes from anim_index_c, untouched).
3. The signed-16-bit bound holds everywhere (worst extended blob
   `0x3730` < `0x8000`).
4. All 1,632 tenant keyframe record-words are sane.
5. Exactly FIVE code sites consume `0xBE27A`, all through the table
   (`0x02804e/0x0280c6/0x028140` the positioner family +
   `0x05316c/0x06e78a`), so repointing rows covers every consumer.
**IMPLEMENTATION = the shipped `throw_victim_keyframes` mechanism, 15
times:** port the 15 DISTINCT vs2 blocks (Zabel+special share one) into
`wide_ext` — `0x11BD0` bytes, ~71 KiB — and repoint `0xBE27A` rows
`0x00-0x0F` + `0x18` (Oboro is a real attacker id; his row must follow
`0x08`'s new block). Rows `0x10/0x13` are already tenant-ported;
**row `0x11` (Pyron-as-attacker) still aliases Demitri's block** — open
observation for the window (matters only if Pyron has a capture move).
The repointed rows are LEGACY-DEREFERENCED — the 14z-91 walker
relocation is the precedent; the probe build's legacy A/B is the proof
the window must produce.

**The superseded sizing note, kept for the record:** cost was first
stated as 3 sub-blocks for each of "the FOURTEEN aliasing attackers"
(~10.4 KB) under the stitch shape. The offset is added as a WORD and
consumed by `lea (a0,d0.w)`, i.e. **signed 16-bit**, so a sub-block must
sit within ±32 KB of its block base: it CANNOT simply be placed in
`wide_ext` and pointed at. The blocks are packed with no gaps, so each
affected block must be RELOCATED with its table and sub-blocks contiguous
and `0xBE27A[attacker]` repointed — the same mechanism
`throw_victim_keyframes` / `grab_hold_keyframes` already use, but applied
to LEGACY attackers' rows.

**DECIDED 2026-08-19 (maintainer): "the ideal goal is option (a),
measure first: if option (a) is not feasible, then we reassess our
options."** So the scope question is closed in favor of (a) full,
CONDITIONED on the feasibility measurements below coming back clean —
infeasibility reopens the options, nothing else does. The original
options, kept for the record:
 (a) **Full**: relocate the 14 aliasing legacy attacker blocks, port 42
     tenant sub-blocks from vs2. Every legacy grab holds every tenant
     correctly; 14 legacy rows repointed (base halves byte-identical, so legacy work
     RAM should stay bit-identical — that must be MEASURED, not assumed).
 (b) **Scoped**: only the attackers whose capture is common in 2P play.
     Smaller legacy surface, but leaves a defect whose trigger is "which
     character grabbed you".
 (c) **Defer**: in-scope 2P visual, not game-breaking.
**Recommendation: (a)** — the mechanism is uniform, the data exists
verbatim in vs2, and a partial fix leaves a defect that is hard to reason
about later. It rides the same re-freeze window.
**Not yet measured, and it sizes (b):** how many of the sixteen attackers
actually reach this path (a block exists for all 16; that is not the same
as all 16 having a live capture move). Measure before choosing (b).

**Eliminated on the way** (controls, not assumption):
- the `anim_index` family (a/a2/b/c/proj) **and all 14 per-character
  dispatch tables** have rows 0x10/0x11/0x13 MOVED OFF the vanilla alias
  for all three tenants on merged-m3 (built-vs-vanilla diff of every such
  row). That is the elimination needed here — none of them is handing a
  tenant its fold row. It is NOT a claim that each points at the right
  target;
- `0xBE27A` is **ATTACKER**-indexed, not victim-indexed: A0 sat inside
  Victor's block while row 0x13 pointed at the tenant's own `0x400010`.
The selector is reached inside the ATTACKER's own anim node walk —
`0x27F70` (node walker, `($1c,A6)`, 0x18 stride) → the capture positioner
at `0x02802E..0x0280A0`, whose tail `move.w (A0),D0; bra $27fa0` supplies
the index to the shared installer at `0x27FA0`. A0 is per-victim and
IDENTICAL for Victor and Donovan (`0x099296`), for Bulleta and Phobos
(`0x098d6e`), and Demitri's is `0x098f26` — [ANSWERED above: A0 =
block + block[victim] + keyframe*8, and block[] is the aliased table].
**The bisect that was planned here is superseded** — the node-sequence
diff is confounded (the whole match diverges from the frame the opponent
differs: first differing attacker node install is f2807, long before the
grab). Reading the positioner backwards from `0x028072` answered it in one
disassembly instead. Recorded because "diff the two runs" looked like the
obvious move and is the wrong one when the runs differ in an input.

**Two probe facts worth keeping.** `0x27FAA` (the four-sibling selector
entry) is NEVER executed — 0 hits over a full replay while `0x27FA0`
(which loads `anim_index_c` directly) takes 904. And the documented
"RET (SP) lies for jmp-reached code" gotcha bit here exactly as written:
every PROBE line reported `RET 00ff02dc`, a RAM address, because the
positioner tail-branches into the installer; `GUARD_PROBE_HIST` is what
named the caller.

**A CLAIM I RAISED AND KILLED MYSELF, recorded so nobody re-derives it:**
"setting POKES silently disables GUARD_PROBE". Reproduced twice at
`0x2AD82` (501 hits without pokes, 0 with) and it looked like a serious
instrument defect. It is not: at the LIVE site `0x27FA0` the same poked run
gives 904 hits. The palette-seq resolver simply is not reached in a
forced-pick Donovan/Victor run. Tested before publishing, per the
verdict-logic doctrine.

**No shipped byte moved.** The 14z-96 freeze stands.

**Decisions pending (maintainer):** unchanged from the 14z-98 list except
that #102 is now closed and #104 is fully resolved to a ruled, measured,
feasible fix — RULED option (a) 2026-08-19 ("the ideal goal is option (a),
measure first: if option (a) is not feasible, then we reassess"), the
feasibility measurements came back clean and are frozen in
test_capture_pose_sources.sh, and the 15-block port + 17-row repoint rides
the same re-freeze window as #103's staged rows. What remains for #104 is
window WORK, not a decision: author the 15 data_port rows + the 0xBE27A
repoints, probe-build, flip audit_don_grab_pose to EXPECT_MATCH=1, and
produce the legacy A/B proof.


## Session 14z-98 CLOSE — ritual complete (the full session: (1)-(9))

The largest-yield session since the review triage: **#103 root-caused,
causally confirmed, fix staged** (window = "uncomment + battery", rides
#43(b)); **#102 answered** (vanilla's own continue resets the ladder;
awaiting the close ruling); **#104 found, reproduced, capture-confirmed
and mechanism-CLOSED same day** (reaction-index generation drift; fix
designed, same window); **#105 filed** (AUTO win screens; AUTO
selection solved+proven; awaiting the maintainer's captures naming the
surface); "instance 2" retracted (the 2-byte-poke class, now a frozen
audit); the maintainer's full MAME field session recorded clean (no
crash, no regression — both emulators now). **NO SHIPPED BYTE MOVED
ALL SESSION**; the 14z-96 freeze stands untouched.

**Ritual state:** NEXT_SESSION current through (9) (rewritten
incrementally at each arc); HANDOFF rows for all five new instruments;
GOTCHAS 14z-98 block (3 entries) indexed; retraction passes run per
arc (grep clean each time); suite green at every commit (full tier
PASS 93/0/0 x4, portable after each close); memory extended
(rig-must-produce-the-real-event: the poke-shape trap).

**New instruments this session:** audit_don_ko_writer,
audit_kill_poke_shape, audit_continue_ladder, audit_don_grab_pose (+
replay 96), trace_writes DUMPS. **Staged for the window:**
reconciliation_donovan.toml + the commented donovan.toml block
(inertness proven by test_m3a_reproducible).

**Decisions pending (maintainer), the complete list:**
1. The re-freeze window (#43(b) + #103's staged rows + #104's fix rows
   once derived) — scheduling is yours.
   [14z-99: the "#104 table reorder" shape named here is WITHDRAWN — its
   premise measures false; see the 14z-99 entry.]
2. #102's close ruling (the discriminator answered "not ours").
   **DECIDED 2026-08-19 (maintainer): CLOSE IT — NOT OURS.** Executed
   14z-99; audit_continue_ladder.sh stays as the regression lock.
3. The two battery-target registry rows (14z-97, proposed).
4. The ~200 tracked build dirs (carried).
5. #105: your captures of the white-portrait screens (offered — bring
   them to the next session).
   **DELIVERED 14z-99 (../Images/white_win_portraits) and PROCESSED:**
   the defect is reproduced, discriminated (AUTO on the winner; vanilla
   clean) and locked (audit_win_pal_auto.sh + replay 103). See the
   14z-99 (2) entry.

**For whoever opens next session:** read NEXT_SESSION's banner. Three
ranked starts: (a) #105 from the maintainer's captures; (b) #104's fix
derivation (the legacy-twin permutation — pure measurement, no ruling
needed); (c) if the window is ruled open, the #103/#43(b) re-freeze.

## Session 14z-98 (9) — #104's MECHANISM CLOSED: a GENERATION DRIFT IN
## THE VICTIM-REACTION INDEX SPACE. The tables were ported and repointed
## RIGHT; the engine indexes them with the other generation's meanings.
## [RETRACTED 14z-99 — the header above is WRONG and the fix it designs is
## a no-op. The index space is NOT generation-drifted: the legacy twins
## this entry proposes deriving the permutation FROM (Victor row 3,
## vsavj 0x157A50 vs vs2 0x13FAA2) are BYTE-IDENTICAL entry for entry, and
## a legacy victim installs the SAME index on both engines (measured over
## Bulleta/Demitri/Victor/Lilith). The real mechanism is the VARIANT-ROW
## ALIAS class — the capture set is selected PER VICTIM and a tenant folds
## to its base character. Point 3 below is the measurement that misled:
## "vsavj passes 6 where vs2 passes 11" is true, but 6 is VICTOR's value,
## reached because Donovan 0x13 folds to 0x03 — not because the table is
## ordered differently. See 14z-99.]

One tap pair finished it (read_tap ff881c both legs, PC-attributed):

1. Install writers: ours PRG:0x27FCE, native vs2 0x27222 — the engine's
   twin victim-record installers (0x27FA0/0x271F4 blocks, instruction-
   parallel): per-char table from the anim_index family by victim
   $382<<2, then record = table + word[REACTION INDEX from the
   attacker], installed at +0x1C.
2. The family is ALREADY KNOWN AND HANDLED: anim_index_a/b/c/proj +
   0x0BCEFA (bank_map data_ptr rows, region anim; ram.md:189 calls it
   the Midnight-Bliss/capture-pose family). All five row-0x13 entries
   on the build are CORRECTLY repointed (anim_index_c -> 0x0DACBA =
   the placed copy of vs2 0x287192; checked against verify_data.bin).
   vs2's newcomer tables live INSIDE the ported anim regions (D
   0x287192, P 0x265FD0, H 0x247E66) — nothing is missing.
3. THE DEFECT IS THE INDEX: for Victor's grab-hold, vsavj's engine
   passes index 6 where vs2's passes index 11 (ours installs
   table+0x1DE = idx 6; native table+0x286 = idx 11). The ported
   tables' CONTENTS are in vs2's index order; vsavj's engine reads
   them with vsavj meanings — the electric-shake generation-drift
   class (ram.md +0x5C), in the index space. Coinciding indices render
   fine ("half right"); drifted ones select neighbors.

FIX DESIGN (rides the re-freeze window, with #103's rows): derive the
vs2->vsavj index permutation from the LEGACY twins (Victor row 3:
vsavj 0x157A50 vs vs2 0x13FAA2 — matching record content across the
two engines gives the map, measured); REORDER the tenants' ported
offset tables (5 siblings x 3 tenants, data-only, inside the anim
copies); probe with audit_don_grab_pose EXPECT_MATCH=1 + ordinary-hit
no-regression legs. Open question for the derivation: whether all four
sibling tables share one permutation, and whether it is a clean shift
over a range (6->11 suggests +5 in the hold family) or per-index.

## Session 14z-98 (8) — #105's rig: AUTO selection SOLVED AND PROVEN;
## the scripted flow shows NO white surface; awaiting the maintainer's
## captures to name the screen. #104 capture pair CONFIRMED.

The maintainer answered both opens. #104: the capture pair is confirmed
("this AND worse frames than these" — consistent with the hold cycling
a record family and ours mis-selecting per phase; noted on the issue).
#105: AUTO = character with LP, then at the play-mode list DOWN, DOWN
(NORMAL -> TURBO -> AUTO; AUTO&TURBO exists below), confirm any button
— numpad notation ("2,2") decoded after two literal-button misreads.

Rig results (merged-m3): the 1P MODE MENU overlays the select wheel at
~f1250-2100 — every earlier guess used the 2P timing (~f2800) and
landed inside a running match; the menu TIMES OUT into NORMAL when
unconfirmed; confirming at f1420 pulls the whole timeline ~600f
earlier. With the cursor snapshot-PROVEN on AUTO and the match won in
AUTO: every post-match surface in the fast-KO scripted flow renders
CORRECTLY (paired same-frame MANUAL control identical). The
white-portrait screen lives on a path the rig does not take — likely
gated by real-KO/win-pose flow the 3-HP poke KOs skip, or a different
surface entirely. THE MAINTAINER IS PROVIDING CAPTURES; the rig resumes
from the named surface. All scratch (no tracked instrument yet — the
event has not been produced; the #98 lock comes when it is).

## Session 14z-98 (7) — TWO MORE FIELD REPORTS PROCESSED: #104 extended
## to the Pyron victim (victim-side, grabber-independent), #105 filed
## (AUTO-mode win screens white) — and the wider field verdict recorded:
## NO CRASH, NO REGRESSION across the whole MAME session

**The maintainer's addendum, recorded:** "no crash during all the
testing on mame, no regression to report either." Merged-m3 has now
taken a full MAME field session clean (the earlier FBNeo wide-array
report said the same). #99 remains parked-not-reproduced on both
emulators' field sessions.

**#104, extended and sharpened (same-day):**
[RETRACTED 14z-99: PYRON'S HELD RECORD IS CORRECT — ours maps to
0x26614C, identical to native. The 0x26654C below is an INSTRUMENT
ARTIFACT: audit_don_grab_pose.sh resolved every tenant through
placements["regions"]["anim"], which on a MERGED build is DONOVAN's
placement. Fixed 14z-99 (the region is resolved per victim). Pyron is
right because his fold 0x11->0x01 lands on Demitri's index 11, which is
also his correct one — which is why the field report named Donovan and
Phobos and not him.]
the Victor-grab rig run
against P2 PYRON — his held record mismatches too: ours (mapped)
vs2-src 0x26654C vs native 0x26614C, a DIFFERENT delta than Donovan's
(-0xA8 vs +0x400) -> per-victim wrong row selection, victim-side and
grabber-independent; the field's Bulleta x Pyron pair is the same class.
Bonus: the held-victim shake amplitude is per-victim (Donovan 32px,
Pyron 43px) — audit_don_grab_pose's hold window widened to the measured
48px (its 40px draft missed native-Pyron by 3px; all documented in the
classifier comment). Bulleta-rig lesson recorded on the issue: her 6+HP
is the universal throw with a tight range — the walk-in rig yields
NORMALS (-13 each, measured both legs, v1 and the continuous-push v2);
one grabber per victim suffices since the mechanism is victim-side.

**#105 FILED (AUTO-mode win screens, all three tenants: correct shapes,
white fill — the wrong/unloaded-palette signature).** Reproduction
blocked on ONE fact: how AUTO is selected (kick-confirm and speed-menu-
DOWN both produced no AUTO tell; asked the maintainer). Measured on the
way: the 2P flow with the loser holding credits SKIPS the win screen
(winner -> arcade map + loser continue), and the scripted 1P arcade
flow also skipped it — replays 61/62 (real 2P victories, the
tenant_winpal rigs) are the win-screen-reaching bases to adapt once the
AUTO input is known. Prior art fenced on the issue (engine_internals
WIN SCREEN section, test_hui_winscreen's 5*row marker,
test_tenant_winpal).

Rig notes paid for in this block (on the issues): the win screen does
NOT appear in a 2P flow whose loser banks a continue, nor in the
scripted 1P flow measured here; P2-side class pokes in 1P arcade do not
survive the ladder's own opponent assignment (Q-Bee appeared where
Victor was poked) — poke P1 only, let the ladder pick.

## Session 14z-98 (6) — #104 REPRODUCED, CAPTURE-CONFIRMED, AND LOCATED
## AT THE RECORD LEVEL within the hour: the tenant victim of Victor's
## headbutt grab is held on THE WRONG ANIM RECORD

Rig: NEW `tests/replays/96_don_victor_grab.rpl` (replay-03 skeleton;
P1 Victor walks in, spaced 6+HP attempts on an idle P2 tenant) — FOUR
grab connects per run, no HP pokes. Same replay on merged-m3 (MAME)
and native vsav2; snapshots + dumps in one pass.

**Captures (sent to the maintainer for the confirmation loop):** native
holds Donovan UPRIGHT; ours lays him HORIZONTAL, upper body roughly
right, the rest a lying/squished assembly — the report on sight.

**The record level (from the same runs' dumps):** during the hold
(victim stationary ~150f, hp ticking -2 per headbutt), victim +0x1C:
    native:  0x287418 (upright held pose)
    ours:    placed 0x0DAE98 = vs2 src 0x287370 (renders horizontal)
Release records mismatch too (ours 0x2879C8 vs native 0x2873A0) — NOT a
uniform shift, so the record CONTENT is fine (the #103 chain proved it
byte-exact); the SELECTION is wrong. Suspect class: engine-generation
drift in victim-reaction ids — vsavj's engine (Victor's grab is vsavj
data) passes ITS generation's reaction id into the victim's ported
vs2-shaped table (the electric-shake 0x18/0x0B vs 0x0C/0x04 precedent,
ram.md +0x5C). Both tenants affected fits: every tenant's table is
vs2-shaped.

**Instrument:** `tests/audit_don_grab_pose.sh` (NEW, ~5 min, 2 parallel
runs): leg B anchors native at 0x287418 + proves the rig makes the
hold; leg A freezes the defect (ours maps to 0x287370, EXPECT_MATCH=0,
the #98 discipline — flip when the fix lands). The ours->vs2 mapping is
DERIVED from the build's own placements.json anim row, never hardcoded
(placements move at every re-freeze, including the staged #103 window).

**Next measurement (after the maintainer confirms the captures):** trace
the reaction-id value at the victim's record selection on both legs
(read_tap on the victim +0x54 family at the connect) — if native
receives a different id for the same grab, the fix is a per-row remap
in the ported victim tables (data rows, tenant-scoped, the Cosmo-81->79
class) and rides the same re-freeze window as #103's rows.

## Session 14z-98 (5) — FIELD RESULTS (maintainer MAME retest, 2026-08-19):
## no stall for EITHER tenant — instance 2 CLOSED as the rig artifact, the
## Donovan trigger model refined — and a NEW defect: Victor's headbutt
## grab garbles the tenant victim's pose

**The retest, as given:** "Testing on mame did not yield any stalling at
round lost for either Phobos or Donovan. It did however rise a Donovan
and Phobos graphical issue that we never caught before: When Donovan or
Phobos are the victim of Victor's headbutting grab (6+HP), their
animation is partly wrong (seems like the sprites used are half right
and half a knocked down or squished sprite as the position of the
sprite is very horizontal). Not game-breaking per se but truly in scope."

**Phobos: CLEAN.** Real no-poke losses judge on MAME — the outcome the
(2) analysis predicted. "#103 instance 2" is CLOSED as the continue
rig's own 2-byte-poke artifact (audit_kill_poke_shape is its mechanism
lock). #103 is DONOVAN-ONLY; the staged x026142 fix closes the whole
ticket at the window.

**Donovan: no stall in ORGANIC play — the trigger model is refined, the
root cause is untouched.** The stall needs the hp:=1 pin (his node-op
escape) to fire in the round BEFORE the death. The mash arms it ~2x per
9,000 frames (every rig loss stalled, deterministically — the audits
stay as they are); the maintainer's organic losses never walked the
culprit anim, so they judged. "Lose any round as Donovan" was
mash-tuned phrasing — corrected in the audit header and the (9) marker
(grep clean). Field frequency is therefore LOWER than the rig
frequency; the defect and its fix are unchanged (causally proven both
directions). OPTIONAL follow-up, not started: name the culprit move by
scanning his anim region's node streams for records invoking the
escaping op — would turn "some anim" into a named move for the field
recipe.

**NEW DEFECT, filed as its own issue (the #93/#101 discipline): Victor's
headbutt grab (6+HP) victim pose on BOTH tenants** — half-correct,
half knocked-down/squished sprite, very horizontal. In scope
(2P-versus surface). PRIOR ART pointers for whoever rigs it:
- the victim's pose during a legacy throw is driven per-char (the 14z-2
  mirror-victim class — test_don_throw_mirror: "base-slot mirror throws
  use the Donovan-victim block");
- the variant-row alias class (rows 0x10-0x1F aliasing 0x00-0x0F) is
  the most common defect shape in this port — a victim-pose table row
  serving Bulleta/Victor data to a tenant would produce exactly
  "half right, half wrong sprite assembly";
- test_hui_grab_victim (14z-73) is the existing grab-victim instrument
  family (that one is tenant-as-ATTACKER; this is tenant-as-VICTIM);
- BOTH tenants affected -> a shared table/row family, not one tenant's
  port rows.
Next steps per the capture discipline (show captures BEFORE analysis):
rig P1 Victor 6+HP grab on P2 tenant, snapshot ours AND native vs2
(Victor exists in vs2 — the native leg is directly capturable), send
the pair to the maintainer for the confirmation loop, THEN measure.

## Session 14z-98 (4) — #102's DISCRIMINATOR RAN: the venue drift is the
## ENGINE'S OWN CONTINUE BEHAVIOR, measured on pristine vanilla with a
## legacy character. Locked as a two-leg audit.

The ticket's pre-registered test ("run the loss/continue/switch chain
with LEGACY characters only; drifts the same -> not ours") is built and
measured — it became reachable the moment the natural mash + banked
credits replaced the kill-poke rigs (no pokes touch HP: the (2) lesson).

Rig: the committed marathon with 4 extra C1 presses spliced into the
attract (derived at run time, #48 discipline), P1 Victor forced, MAME.

**Pristine vsavj:** venues 06 -> 0E -> 12; P1 loses match 3 (healthy
white-HP judge, phase 6->8 in-sample); CONTINUE (~960f KO->next match,
$8004=000E continue mode observed — a restart would take far longer);
**the in-use mask $FF8110 CLEARS 1 -> 0 at the continue**, and the pool
restarts: 04 -> 0A -> 06 (a venue REPEAT). Later matches on earlier
venues + more matches than the norm — ON VANILLA, LEGACY-ONLY.

**Merged-m3, same rig:** frame-identical through match 3's start (the
first three venues and their frames match vanilla exactly), then the
lottery diverges (P1 WINS match 3 — the mask is sound-state-fed, the
documented between-build lottery): 06 -> 0E -> 12 -> 02 with the mask
healthily ACCUMULATING (1 -> 0x401) — **venue DOWN with NO continue: the
ladder is not venue-monotonic even in healthy play** (the venue follows
the scan index, not the match number) — then a loss at match 4,
continue, **mask cleared 0x401 -> 0**, restart at 08. Same mechanism.

**Verdict: both #102 symptoms are the vanilla envelope.** The tenant
correlation in the field report is explained by "switching requires
continuing". Posted to #102; severity collapses per the ticket's own
framing. Honest bounds stated there: one loss point per leg, mash-driven
picks, venue VALUES are lottery draws — the reset SHAPE is the finding.

**Instrument:** `tests/audit_continue_ladder.sh` (on-demand, ~20 min,
2 parallel marathons). Leg A asserts VANILLA shows the continue-reset —
if that ever goes red, the behavior was ours after all and #102 reopens;
leg B asserts the merged build shows the same mechanism. Its own FIRST
run removed an over-engineered third assertion (post-continue mask
re-accumulation) that refused real data in the safe direction — the
80f dump cadence cannot reliably sample the short-lived post-continue
mask states. The verdict-logic-is-tested doctrine working as designed;
documented in the header. AUDIT PASS on the committed script.

## Session 14z-98 (3) — THE FIX WINDOW IS STAGED AND FULLY PRE-FLIGHTED:
## risks assessed per the maintainer's conditional ruling, every shipped
## target verified, the window action reduced to "uncomment + battery"

**Maintainer ruling taken (2026-08-19): the #103 fix rides the re-freeze
with #43(b) "unless you see risks". Risks assessed, both retired:**
1. **Attribution overlap** — x028122 is touched by both changes (#43(b)
   moves its recon row; the census names an escape in the region).
   Retired two ways: land as separate commits with per-change evidence,
   AND the x028122 escape is now DEFERRED (below), so the two changes no
   longer touch the same region at all.
2. **Unresolved targets as tripwires** — retired by scoping the row set
   to fully-resolved regions only: ZERO tripwires in the shipped shape.

**The evidence-based window scope (donovan.toml, staged as comments):**
- `[[pcrel_escape_fix]] x026142 pad 0x60` — the #103 closer (9 sites ->
  6 trampolines, 0 tripwired).
- `[[pcrel_escape_fix]] x05c800 pad 0x20` — H-proven sibling (same
  source span; verified twin 0x635fc -> 0x5b25c; H ships this row).
- `recon_overlay = build/manifest/reconciliation_donovan.toml` — NEW
  tracked file, 8 verified rows carried verbatim from H's overlay.
  INERT until declared (proven: test_m3a_reproducible PASS with the
  file present and the block commented — all four frozen references +
  merged ac3d0618 rebuild bit-exact).

**REVIEWED AND DEFERRED, with the evidence in the manifest comment:**
- **x065c22's "+0x5e escape" is a CENSUS FALSE POSITIVE** — the 0x6000
  word is the immediate of `move.l #$6000,d3` (vs2 0x65C7C). A row here
  would have the escape pass REWRITE THE IMMEDIATE (the 14z-74 D5 table
  corruption class, documented in pyron.toml's HISTORY note). Recorded
  loudly so the fix window does not add it.
- x028122 "+0x112": the site sits in the (pc,d2) jump-table data at vs2
  0x2822C (framing-ambiguous), and the object-hit damage path is HOT
  and healthy across 17 sessions (audit_fg_parity) — no live branch
  escapes. Byte-twin 0x2cc64 -> 0x2d478 (0x40 identical, unique)
  recorded in case it is ever proven live.
- x088512 "+0x2e1c" (`beq.w 0x8b6ea`): target is vs2 match-flow code
  with NO vsavj byte-twin (generation drift; the anchor block
  `546d0008 426d0010 4e75 302d0010` has zero vsavj hits); the site is
  next-stage-screen territory (single-player, cosmetic scope), unfired
  in every rig. Deferred with H/P's leftovers (0x6b644 likewise has no
  byte twin).

**The window rehearsal, run against the EXACT recipe** (scratch copy of
donovan.toml with the three pieces mechanically uncommented ->
build/probe_103_don2, fingerprint cb1b04c3, UNREGISTERED):
- generator: x026142 9 escapes -> 6 trampolines, x05c800 2 -> 1, ZERO
  tripwired (every target through the tracked overlay);
- audit_don_lilith_ko EXPECT_STALL=0: **leg A FLOWED 560**, control 560;
- audit_don_ko_writer EXPECT_DEFECT=0: **healthy kill commit f12730**;
- **legacy A/B vs don_m8: BIT-IDENTICAL on all four legs** — replays
  02/03/16 whole-run and the Victor-forced marathon head (18,122
  frames). The fix is measurably legacy-invisible; the re-freeze's
  legacy expectations are expected NOT to move (the cascade's ~83 moved
  ops are free-space placements + operand values at unchanged sites).

**The window action is now:** uncomment the three pieces in
donovan.toml (move recon_overlay to the top-level keys), rebuild all
four artifacts + merged, run the full battery + run_suite + the two
flipped audits (EXPECT_STALL=0 / EXPECT_DEFECT=0 become the defaults),
freeze, carry-rename expectation sets. #43(b) lands beside it as its
own commit.

**One correction to (1)'s fix-shape note:** it said x028122/x065c22/
x088512 "need site-twin work or ship as loud tripwires". Superseded by
the review above: x065c22 must NEVER get a row (false positive), and
the other two are deferred-with-evidence rather than tripwired.

## Session 14z-98 (2) — "#103 INSTANCE 2" IS NOW UNVERIFIED: a 2-byte HP
## kill poke manufactures the unjudgeable state on ANY character, and the
## continue rig's poke width was never committed

Follow-on from the root cause. Since the judge kills on WHITE HP's sign
and the pipeline keeps white <= hp, a poke writing ONLY the 2-byte hp
word creates the hp<0/white>=0 state by instrument. MEASURED on a
pure-legacy Victor leg (merged-m3, kill pokes at round-1 start +100f,
three 20f apart, hands off):

    2-byte  f:ff8450:0001      -> UNRESOLVED >= 8,760f (hp=-5, white=277,
                                  phase pinned 6 — the exact #103 shape)
    4-byte  f:ff8450:00010001  -> FLOWED 600 (kill commit, both -1)

Frozen both ways in tests/audit_kill_poke_shape.sh (NEW; ~7 min; both
verdicts are engine facts, stable across builds).

**Consequences, each carried to its record:**
- **"#103 instance 2" (Phobos KO'd by Bishamon, 14z-97 (7)) is
  UNVERIFIED** — that rig "set HP to 1 at round start" and the poke's
  byte-width was never committed, so the stall may have been the rig's
  own. Independent evidence his real losses judge: his natural
  early-round losses (14z-97 (7)); his near-death commits (0x18A54)
  firing healthily on today's tap; his x026142 escapes are FIXED; and
  the maintainer's real no-poke Bishamon loss reached the continue
  screen. The maintainer's pending MAME retest decides it (no pokes
  involved). Donovan's #103 is UNAFFECTED — reproduces with zero pokes.
- **The 14z-97 (9) Q-Bee/opponent-independence RE-MEASURE is
  CONTAMINATED** (RH-4): it used "kill pokes at round start" of
  unrecorded width. Its CONCLUSION survives on other evidence — the
  root cause fires from Donovan's own move during ordinary play, so
  opponent-independence follows from the mechanism, and the natural
  no-poke Lilith leg stands — but the (9) measurement itself is not to
  be cited.
- The #99 continue rig, when revived post-fix, must use the 4-byte
  idiom (on #99's record via the #103 comment).

**Escape-census sweep completed across all three tenants** (raw counts;
adjacency-safe/benign triage belongs to the fix window): donovan 14
sites/5 regions ALL uncovered (14z-98 (1)); huitzil UNCOVERED = x028122
-> 0x2cc64, code -> 0x574b0/b6/bc/c2 (20 sites, consecutive — likely the
adjacency class the census gate already reviews), x068c78 -> 0x6b644;
pyron UNCOVERED = x028122 -> 0x2cc64, x068c78 -> 0x6b644. The fix window
should sweep all three, not just Donovan.

## Session 14z-98 — #103 ROOT-CAUSED AND CAUSALLY CONFIRMED: a pc-rel
## escape in Donovan's x026142 pins his HP to 1, and the round judge
## kills on WHITE HP's sign. The parked bank-tail rows are ELIMINATED.

The banner's consumer trace ran and answered NO — and the hunt moved one
level up and closed the mechanism end to end. **No shipped byte moved**;
the fix is designed, probe-confirmed, and waits on the re-freeze window.
Full measurement chain on GitHub #103 (14z-98 comment); the chronology:

1. **Preflight + anchors reproduced exactly:** suite PASS 93/0/0;
   audit_don_lilith_ko UNRESOLVED 8960 / Victor FLOWED 560 (merged-m3 AND
   solo don_m8 — same KO frame, deterministic); native vs2 walk
   0x2873A0→0x287BA8 + clear at KO+240 (poke-free — the natural mash
   loses on vs2 too); NEW: native flips phase $FF800C 6→8 in the same
   40f sample as the KO, and so does a legacy loser on OUR build (Victor,
   f9960); Donovan's death never flips it — KO RECOGNITION, not
   settle, was the missing step.
2. **The banner's question answered with controls:** read-watches on
   0x0BF01A-0x0BF21A and 0x0BF59A-0x0BF61A during a tuned -debug stall,
   BOTH spaces. Opcodes: zero (wposet control 80b40,4,r,o = 1845 hits).
   Program: sole consumer = PRG:0x02CCC4/F8/0x02CD4E (movea.l #$bf01a;
   row = in-match $382<<2; feeds fighter +0x210/214/218/224) — fires
   ONLY on the CPU-side struct, both legs, never a loser at death.
   0x0BF59A unread. **The "author the four per-char rows" fix shape is
   WITHDRAWN** (marked in 14z-97 (9), the issue, bank_map.toml).
3. **The engine mechanism:** in-match machine PRG:0x93CE (table 0x93C0),
   phase-6 handler 0x97DC tests THE SIGN OF +0x52 (white) at
   0x97FC/0x9804 — never +0x50. vs2's twin 0x800C/0x8014: same offsets.
   The pipeline keeps white <= hp (applier 0x18AB0, staged $FF3442/44),
   so white crosses 0 first; kill commit (0x18A7C / 0x18B12 / live
   0x2980A+0x29810) writes both -1 + deathflag +0x11F. Measured healthy:
   Victor f9924 hp 17→6, white 15→-3, commit same frame. Atlas rows
   added (+0x52 judge note, +0x54, +0x11F); engine_internals gained
   "THE ROUND JUDGE" section.
4. **The port defect:** non-debug read_tap (canonical timeline): W f8938
   PC 0cd286 ff8450 := 0001 (white ~210), W f8951 the applier underflows
   1-9 = fff8, white 210→196 stays positive → unjudgeable. PC 0x0CD286 =
   region x066ec4 +0x1B2 = vs2 0x67076 — a POOL-OBJECT durability init.
   GUARD_PROBE_HIST names the path: the ported walker's node op at
   x026142+0x162 (vs2 0x262A4) ends `bra.w $25F9A` — target 0x1A8 BEFORE
   the region start; the preserved displacement lands it at placed
   0x0CD1E8 = x066ec4's child-object INIT, executed with A6 = the
   FIGHTER (also clobbers +0x30 owner link, +0x39/98/B1, velocities).
   NATIVE CONTROL: 13,400f on vsav2, same tap — vs2 0x67076 writes the
   fighter's HP zero times. vs2's branch legitimately reaches 0x25F9A
   (status-reset helper; vsavj twin PRG:0x26E16, 0x174 identical bytes,
   unique — and ALREADY a verified 14z-66 row in reconciliation_huitzil).
5. **Why only Donovan:** his extraction predates the 14z-66/67 escape
   census — huitzil.toml has 5 [[pcrel_escape_fix]] rows, pyron.toml 2,
   donovan.toml 0. Census rerun on his extract: 14 word-form escape
   sites over 5 regions (x026142: 9 sites/6 targets incl. 0x25F9A) + 10
   pcrel DATA escapes + 4 data_in_code — ALL uncovered.
6. **Causal confirmation (probe build, throwaway, scratch manifests, no
   tracked edits):** build/probe_103_don (fingerprint 8426ee14,
   UNREGISTERED) = donovan.toml + [[pcrel_escape_fix]] x026142 pad 0x60
   + a scratch overlay carrying H's 7 verified twins. Generator: 9
   escapes → 6 trampolines, 0 tripwired. audit_don_lilith_ko
   EXPECT_STALL=0: **leg A FLOWED 560** — the healthy legacy constant
   (KO moves 8960→12760: the escape also perturbed ordinary play).
   audit_don_ko_writer EXPECT_DEFECT=0: his death takes the KILL COMMIT
   (f12730). Both rehearsals green; both defect-locks green on merged-m3.

**Suite doctrine:** tests/audit_don_ko_writer.sh NEW (the root-cause
lock: leg A = the defect shape PC-attributed, EXPECT_DEFECT=1; leg B =
Victor kill-commit control; both modes rehearsed, incl. its own RH-19
window trap caught by the EXPECT_DEFECT=0 rehearsal and documented in
the leg-A window comment). trace_writes.lua gained DUMPS (self-
documenting -debug runs — see the 14z-98 gotcha). Two gotchas appended
(project bucket): every -debug watch configuration is its own TIMELINE;
GUARD_PROBE's RET (SP) lies for jmp-reached code.

**The fix, for the re-freeze window (decision pending, joins #43(b)):**
donovan.toml [[pcrel_escape_fix]] rows — x026142 (closes #103; overlay
rows exist verified in reconciliation_huitzil.toml: 0x210c0→0x226dc,
0x219c4→0x22fc0, 0x21c64→0x23244, 0x22008→0x23500, 0x24cba→0x26058,
0x25f9a→0x26e16, 0x27542→0x282ee) + x05c800 (0x635fc→0x5b25c verified
there too) + x028122/x065c22/x088512 (targets 0x2cc64/0x689fe/0x8b6ea
UNRESOLVED — site-twin work, or ship as loud tripwires; both strictly
better than today's silent wrong-code execution). Donovan is the
reference tenant (no recon_overlay): the rows land either in a new
overlay or the shared map — his fingerprint moves either way. The
probe's recipe is reproducible from this entry + the scratch manifests
described in it.

**Parked findings from the trace (recorded, not chased):**
- x026142's 5 lea DATA escapes (+0xe3e/e48/e52/f02/f4c → 0x2783c-0x27f78
  past region end) — the placed copy reads whatever follows it; separate
  latent class, same fix window.
- The 0x02CCxx consumer serves a tenant-as-P2 the ALIASED bank-tail rows
  (content-wrong, measured non-crashing — Phobos vs CPU-Donovan match 3
  completes).
- **Phobos' Bishamon-leg stall (#103 instance 2) is NOT yet traced:** his
  x026142 copy IS escape-fixed, so it is another region's escape or a
  second mechanism. First measurement: his white-vs-hp state at the
  stall (audit_don_ko_writer's classifier applies as-is with his class).

**Decisions pending (maintainer), updated:**
1. **#103's fix window** — unchanged in substance but the fix is now
   AIMED: the pcrel_escape_fix row set above, probe-confirmed. Still
   rides a re-freeze window with #43(b).
2. #43(b) — unchanged.
3. The two battery-target registry rows — carried (proposed, 14z-97).
4. The ~200 tracked build dirs — carried.
5. #99's rig protocol / the MAME retest datum — carried; note the retest
   question is now sharper: a Phobos round that sits on the KO tableau
   would be instance 2 of the WHITE-HP class, and his +0x52 at that
   moment decides it.



---

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

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
