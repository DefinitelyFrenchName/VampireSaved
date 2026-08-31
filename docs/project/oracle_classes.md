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

## Checkers and their ground truth

| class | expectation kind | checker | ground truth |
|---|---|---|---|
| exact | `.masked` (exact) | `tests/lib/masked_compare.sh` | `tests/test_masked_compare.sh` |
| flicker-tolerated (v2) | `.masked` flicker | `tools/compare_flicker.py` | `tests/test_compare_flicker.sh` |
| frozen first-divergence constant | `.diverge` | `tools/check_diverge.py` | `tests/test_suite_dispatch.sh` |
| bounded re-convergent window (v3) | `.masked` window | `tools/compare_window.py` | `tests/test_compare_window.sh` |
| composite (v4) | `.masked` composite | `tools/compare_composite.py` | `tests/test_compare_composite.sh` |
| v5 (`--min-converge-flicker`, default OFF) | — | `tools/compare_composite.py` | `tests/test_compare_composite.sh` |

A PROPOSED expectation line in this vocabulary comes from
`tools/describe_masked_shape.py` / `tools/propose_masked_specs.sh`; the frozen
specs live under `tests/expected/<set>/`; the comparator-vs-text trap ([VSP-37]:
three artifacts agreeing with each other is not ratification — check the
comparator against THIS text) is the reason every checker has a ground-truth
test that exercises PASS and FAIL.
