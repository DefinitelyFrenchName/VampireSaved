# The legacy oracle classes — the ratified comparison vocabulary

> **STATUS (14z-124, CLAUDE.md pass 2, maintainer-ruled 2026-08-31): REFERENCE —
> the SPEC OF RECORD for CLAUDE.md §4's comparison classes.** The four
> paragraphs below ARE the law, moved here VERBATIM from CLAUDE.md §4 (the
> Rule 1 v2 principle: the spec is not copied — two copies drift); §4 keeps
> the class NAMES, the reclassification law, the standing watch ([VSP-31])
> and a pointer here. Every `**[VSP-N]**` anchor moved with its paragraph
> (`tools/checkskills.py`, `tests/test_doc_anchor_census.sh` lock them). A
> class is never loosened here without a new measured mechanism and
> maintainer sign-off; a change is dated in place, and the superseded text
> is kept struck (CLAUDE.md §5 [VSP-13]).

The basis every class is measured on is the MASKED live-RAM basis of v1
(`docs/game/atlas/ram.md` "Masked windows"; `tools/freeze_masked_basis.sh`),
and the two thresholds every class shares live in ONE place,
`tools/s4_thresholds.py` (`FLICKER_MAX = 2`, `RECONVERGE = 60`). Which
emulator runs which oracle, the dual-track meaning of inertness and the two
FBNeo-only phase classes stay in CLAUDE.md §4 ([VSP-24]..[VSP-26]).

## v1/v2 — the masked basis, and the classes exact / flicker-tolerated / frozen first-divergence constant (approved 2026-07-25 and 2026-07-27)

**[VSP-27]** **Hooked-build legacy comparison** (v1 2026-07-25, v2
2026-07-27, both maintainer-approved): for builds carrying engine hooks
(code the vanilla game executes routed through added instructions), the
legacy oracle compares **live RAM**: all work RAM except two named windows,
both documented in `docs/game/atlas/ram.md` — the dead-stack window
`RAM:$FF7F00-$FF7FFF` (below resting SP at the frame-done sample point) and
the QSound handshake latch `RAM:$FF043C` (one-frame phase). On that masked
basis, per-replay comparison classes: **exact** by default;
**flicker-tolerated** where measurement shows isolated ≤2-frame
divergences that fully re-converge (≥60 frames) with ≤8 divergent frames
total (`tools/compare_flicker.py`, ground-truth tested — the
input-accept/spawn-boundary phase artifact); **frozen first-divergence
constant** where a masked byte's phase provably propagates into live state
on a path with no gameplay surface (test mode reading the sound latch).

## v3 — the bounded re-convergent window (approved 2026-08-05)

**[VSP-28]** **v3 (2026-08-05, maintainer-approved): the bounded
re-convergent window** — for a screen the roster work deliberately alters.
A replay may sit in this class only when all four hold, each frozen per
replay: a single CONTIGUOUS divergent run; a fixed ONSET frame; full
RE-CONVERGENCE to bit-identical; and **match state untouched**. Introduced
for the select screen, whose wheel gains three cells for the roster;
ratified on five replays — onset 890 in every one, one run each, windows
ending 1051/1622/1802/1882/1622, 2469-10498 bit-identical frames after
(mechanism: select-screen init caches the record pointer the wheel extension
repoints, `docs/GOTCHAS.md` class 4). STRICTER than the first-divergence
constant, which never re-converges — a narrower licence for one screen.
Checker `tools/compare_window.py`, ground truth `tests/test_compare_window.sh`.

## v4 — composite (ratified 2026-08-06)

**[VSP-29]** **v4 (2026-08-06, maintainer-ratified): composite** — the
strict CONJUNCTION of flicker-tolerated and bounded re-convergent window,
for replays that exhibit both. It adds NO tolerance: every divergent run
must be accounted for by name, the flicker set must match its frozen
inventory exactly, the window list must match exactly, and the run must
fully re-converge; it permits nothing that either component permits alone,
and a bit-identical pair FAILS it. On a build carrying BOTH engine hooks and
the extended wheel, every select-reaching legacy replay measures as "the
frozen hook-flicker inventory + one bounded window per select-screen ENTRY"
(seven replays at 14z-61; a challenger join re-enters the screen and gives
TWO windows; a mid-attract start moves the onset to 3190). Checker
`tools/compare_composite.py`, ground truth `tests/test_compare_composite.sh`.

## v5 — the ≥60 rule is INTRA-MECHANISM (ruled 2026-08-16)

**[VSP-30]** **v5 (2026-08-16, maintainer-ruled): THE ≥60 RULE IS
INTRA-MECHANISM.** The 60-frame non-propagation figure is a
single-mechanism proof: it governs the RE-CONVERGENCE TAIL after the last
divergence, and it does NOT bind across the gap between two SEPARATELY
ATTRIBUTED mechanisms. So a flicker run followed by a window onset, or one
flicker run followed by another, is not constrained by it.
`--min-converge-flicker` in `tools/compare_composite.py` implements the
alternative and stays DEFAULT-OFF, opted into by no spec (nothing measured
suggests the mechanisms interact, and applying it across a boundary would
have redded 99 of 121 composite specs when the select-window onset moved
890 -> 889 at 14z-63). **Two NAMED EXEMPTIONS are recorded against the day
the flag is ever turned on**, both 56 frames apart (55 identical between)
and both the palette-fade staging family: `donovan-m7/22_don_dualmash`
(11862/11918) and `huitzil-m15/26_don_arcade_mash` (8744/8800). A third
would mean the gap is a property of the mechanism, and the right response
is to measure the real minimum, not to lengthen this list. (No current spec
exercises the boundary: the flicker that opened the question, frame 829,
was the obj_hook cycle-skew removed at 14z-91.)

## v6 — the dual-track FROZEN OFFSETS (ruled 2026-09-05)

**v6 (2026-09-05, maintainer-ruled, 14z-133b): THE DUAL-TRACK GATE'S
"BIT-IDENTICAL UP TO SELECT ENTRY" IS MEASURED OUTSIDE SIX FROZEN
EXECUTION-POSITION OFFSETS, NEVER OUTSIDE A WINDOW.** `test_dualtrack.sh`
compares the stock-size and WIDE builds of the SAME content on FBNeo, so only
profile-gated changes can separate its legs; its target is profile inertness
before the roster is reached, with the select-entry onsets frozen per replay
([VSP-25]: 890, 3190 for the mid-attract replay, 4267 for the attract
divergence). Re-pointed to the MERGED build, three tenants' hooks skew
interrupt timing enough that raw checksums differ before the onsets. Measured
whole (every checksum-differing frame before every frozen onset, on all ten
legacy replays and both attract-based ones, dumped and diffed byte by byte;
`build/dualtrack_merged_14z133b/`, STATE 14z-133b): every differing byte is
one of SIX offsets and the onsets themselves are unmoved —
`$FF055B-$FF055D`, the sound-driver work area, the FBNeo phase inventory
[VSP-26] already freezes for the sampled legacy oracle; and
`$FF7FF3-$FF7FF5`, the dead-stack return address inside the `$FF7F00-$FF7FFF`
window every ratified MAME masked basis already ignores. So the class adds no
tolerance the project does not already carry: the six bytes were invisible to
both other oracles before this ruling. **The STATE ONSET is the first frame
with any byte outside the six, and it must equal the frozen onset**; frames
before it that differ only in the six are reported as flickers with their
offsets. **The offsets are the inventory, never the windows** — a seventh byte
anywhere, inside a window included, is GROWTH and fails; `FROZEN_FLICKER=` may
override only after a measured re-ratification. Ground truth is inside the
gate: section 1b flips ONE byte outside the six in a dumped pair and requires
a state onset there. Sections 2-4 (the profile is live; the attract
divergence starts in the effect-channel pointer; same writer set on both legs)
are unchanged. The maintainer's rationale for keeping the gate, recorded in
STATE "Decisions pending": parallel runs compare things known to be the same,
and these two are the same by construction except for the profile — which is
exactly the claim worth a gate.

## Checkers and their ground truth

| class | expectation kind | checker | ground truth |
|---|---|---|---|
| exact | `.masked` (exact) | `tests/lib/masked_compare.sh` | `tests/test_masked_compare.sh` |
| flicker-tolerated (v2) | `.masked` flicker | `tools/compare_flicker.py` | `tests/test_compare_flicker.sh` |
| frozen first-divergence constant | `.diverge` | `tools/check_diverge.py` | `tests/test_suite_dispatch.sh` |
| bounded re-convergent window (v3) | `.masked` window | `tools/compare_window.py` | `tests/test_compare_window.sh` |
| composite (v4) | `.masked` composite | `tools/compare_composite.py` | `tests/test_compare_composite.sh` |
| v5 (`--min-converge-flicker`, default OFF) | — | `tools/compare_composite.py` | `tests/test_compare_composite.sh` |
| dual-track frozen offsets (v6) | `FROZEN_FLICKER` in the gate | `tests/test_dualtrack.sh` (`classify.py`, generated per run) | `tests/test_dualtrack.sh` §1b (must-fire) |

A PROPOSED expectation line in this vocabulary comes from
`tools/describe_masked_shape.py` / `tools/propose_masked_specs.sh`; the frozen
specs live under `tests/expected/<set>/`; the comparator-vs-text trap ([VSP-37]:
three artifacts agreeing with each other is not ratification — check the
comparator against THIS text) is the reason every checker has a ground-truth
test that exercises PASS and FAIL.

## [VSP-24] Which emulator runs which oracle

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-24], unbolded.)*

  [VSP-24] **Which emulator runs which oracle** (corrected 2026-08-16,
  GitHub #78): the per-frame whole-corpus legacy oracle is **MAME**
  (`tests/lib/m2a_common.sh`, the frozen `.masked` classes below). FBNeo
  carries the **emulator superset invariant** on pristine `vsavj`
  (`test_wide_profile.sh`, reference vs patched binary), **dual-track**
  inertness on one binary (`test_dualtrack.sh`), and a **sampled**
  hacked-vs-vanilla legacy check (`test_fbneo_legacy_oracle.sh`: 4 replays ×
  5 frames, each frame a measured-clean override chosen clear of every
  ratified divergence — 14z-92/110b). The **full** FBNeo legacy track is
  ACCEPTED-AND-DEFERRED: every FBNeo gate is a live A/B by design (no frozen
  corpus), which is what makes them machine-independent. Its revisit point,
  MiSTer, has passed: the MiSTer lane answered with its own oracles (the
  simulator anchor, FPGA inertness, the tenant oracle), and #141, which held
  the track, is closed `declined` (2026-09-29, maintainer-ruled): a measured
  FBNeo-vs-MAME disagreement on legacy content opens a new ticket (restated
  2026-09-15, maintainer-agreed).

## [VSP-25] Dual-track inertness

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-25], unbolded.)*

  [VSP-25] **Dual-track "inertness" means bit-identical UP TO SELECT
  ENTRY, not for the whole replay** (ratified 2026-08-17, GitHub #95). The
  stock and WIDE builds carry DIFFERENT ROSTERS by construction — a
  stock-size ROM can only hold Donovan by substituting over someone, which is
  why WIDE exists — so every select-reaching replay must differ. Onsets are
  frozen per replay; an onset moving EARLIER is the failure. **Amended
  2026-09-05 (14z-133b, maintainer-ruled): "bit-identical" is measured
  OUTSIDE six frozen execution-position offsets — `$FF055B-$FF055D`, the
  [VSP-26] sound-driver phase inventory, and `$FF7FF3-$FF7FF5`, the
  dead-stack return address every ratified masked basis already ignores —
  never outside a window; the STATE onset, the first frame with any other
  byte, is what must equal the frozen onset. Class v6,
  `docs/project/oracle_classes.md`.**

## [VSP-26] The two FBNeo-only phase classes

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-26], unbolded.)*

  [VSP-26] **The two FBNeo-only phase classes** (ratified 2026-08-16,
  GitHub #78): the sound-driver work area `$FF0500-$FF05FF` and the
  OBJ-builder secondary stack `$FF06D0-$FF06EF` may differ on FBNeo where MAME
  shows none — execution POSITION, not state (`atlas/ram.md`), on legacy as
  well as tenant content. **The window is NOT the tolerance:** the
  expectation is FROZEN as the measured offset inventory
  (`$FF055B-$FF055D`, `$FF06D1/D4/DB`, in `test_fbneo_legacy_oracle.sh`) and
  a byte differing inside a window but OUTSIDE it FAILS as GROWTH — stop and
  root-cause, never widen. `FBNEO_ORACLE_EXPECT=exact` demands bit-identity.

## The hooked-build legacy comparison classes and [VSP-31]

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D; the same for [VSP-31].)*

- **The hooked-build legacy comparison classes** — the ratified vocabulary
  every `.masked` expectation uses: **exact** (default), **flicker-tolerated**
  (v2), **frozen first-divergence constant**, the **bounded re-convergent
  window** (v3), **composite** (v4 — the strict conjunction of flicker and
  window, no added tolerance), and the v5 ruling that the ≥60-frame rule is
  INTRA-MECHANISM. **The spec of record is `docs/project/oracle_classes.md`**
  — every definition with its date, frozen figures, named exemptions,
  checker and ground-truth test; NOT copied here on purpose (the Rule 1 v2
  principle: two copies drift). Every non-exact class must be
  mechanism-attributed and its expectation frozen; a replay may not be
  reclassified to a looser class without a new measured mechanism and
  maintainer sign-off. [VSP-31] **Standing watch
  (maintainer, 2026-07-27): if flickers grow beyond the frozen inventory or
  divergences turn systematic, stop and root-cause — that pattern would
  indicate a deeper issue, not tolerance noise.** Rationale (measured,
  session 7, `docs/GOTCHAS.md`): hooks cost cycles; interrupts land at skewed
  instruction boundaries in otherwise-vanilla frames; zero-cycle hooking is
  impossible on this engine. Whole-RAM frame-exact remains the standard for
  vanilla oracles, run-to-run determinism, and hook-free builds.

## [VSP-32] Dual-emulator agreement

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-32], unbolded.)*

- [VSP-32] **Dual-emulator agreement** (amended 2026-07-25,
  maintainer-approved): for new-character content (no vanilla oracle exists),
  the same replay is run on patched FBNeo and patched MAME and the two must
  agree on **mapped gameplay state compared at sync anchors** (match start,
  round transitions): character IDs, HP, positions, timer, meter, and the
  other fields in `docs/game/atlas/ram.md` — not whole-work-RAM checksums
  frame-by-frame. Rationale (measured, session 2): the emulators traverse
  identical states on slightly different frame indices after boot, so
  frame-exact whole-RAM equality is unachievable between codebases;
  field-level agreement at anchors preserves the original intent — a bug
  would still have to manifest identically in two unrelated codebases to slip
  through. Whole-RAM frame-exact checksums remain the standard **within**
  each emulator (vanilla-vs-patched superset oracle, run-to-run determinism).
