# Harness hardening — the passes, and what each one found

**STATUS: HIST (opened 14z-128).** One entry per pass that hardened the TEST
HARNESS itself rather than the port. Newest first. The standing part is the
class list below: it is what makes the next pass fast, and every class in it
was paid for.

**Why this file exists.** The harness is this project's most valuable artifact
(CLAUDE.md §4), and it rots in ways the port does not — because it is measured
against a tree that keeps moving underneath it. Those failures do not look like
bugs. They look like a gate that has always been green, or a gate nobody has
run since the thing it measures was renamed. Each pass below rediscovered part
of the same taxonomy from scratch; writing it down is cheaper than a sixth
rediscovery.

## THE CLASSES — how a harness rots

1. **THE ORPHAN.** A gate no runner calls. It can only be run by remembering a
   filename, so it is never run, so its verdict is unknown. The cure is a
   registry with completeness enforced BOTH ways (an unregistered gate and a
   dead row both fail), re-derived on every run — never a hand-maintained list,
   which becomes a smaller thing to forget to update.
2. **THE SILENT DOWNGRADE.** A verdict that is quietly softened: a SKIP counted
   as a PASS (#29), a non-zero exit read as a SKIP because the output contained
   a skip marker, a lane silently dropped by an argument parser that assigns
   where it should accumulate. The cure is that the strongest signal wins —
   exit status decides before text — and that every count is reported
   separately.
3. **THE DEAD CONTROL.** A must-fire control that no longer fires. This is the
   worst class, because it is the only one that is SILENT: the gate goes green
   while asserting nothing. Every other class is loud. The cure is that gates
   check their own controls and refuse a verdict when one is dead — and the
   fix is never to relax the control.
4. **THE STALE REFERENCE.** A default build dir, a reference binary, or a
   frozen constant that the tree moved past. Symptoms range from "no dump
   files" to alarming-looking total divergence; the tell is that the numbers
   are about an artifact nobody maintains. The cure is a rot gate that can see
   EVERY form a reference is written in, and a re-point at every freeze.
5. **THE OUTGROWN PARSER.** A consumer that reads an instrument's output by
   position, after the instrument gained a field. Extending a debug line is as
   harmless a change as exists, and it silently kills every consumer that
   parses by adjacency. The cure is to parse by FIELD NAME.
6. **THE DELETED MECHANISM.** A gate that probes something a later design
   removed. It cannot be re-pointed, only re-targeted or dropped — and which
   one is a coverage decision, not a repair.
7. **THE MISSING OPERAND.** An instrument that needs operands describing a
   change under investigation, invoked bare by a sweep. It is not a gate and
   should say so, by skipping with its reason rather than dying on a shell
   error.

**The diagnostic that beats all of them:** compare a red gate's RUNTIME against
the runtime its own header quotes. A gate that fails far faster than it can
possibly run bailed BEFORE measuring anything, which makes it class 4, 6 or 7 —
never a defect in the build.

---

## 14z-128 (2026-09-03) — the emulator tier gets a runner, and it finds 19

**Built:** `tests/run_all_emulator.sh`, `tests/ci_emulator.tsv` (164 rows,
completeness enforced both ways), `tests/test_emulator_runner.sh` (10
ground-truth sections). Also `tests/test_header_defaults.sh` (a gate's header
must state the default its code uses) and `tests/expected/PROVENANCE.md` +
`tests/test_expectation_provenance.sh` (every frozen expectation names its
EVIDENCE CLASS).

**Why now:** the maintainer ruled that at release all tests run and "anything
red, anything skipped is a hard fail". That policy cannot operate over a set
nobody enumerates. Measured: 164 emulator-tier gates, 32 reachable from any
runner.

**The runner found three defects in ITSELF before it found any in the suite** —
all class 2: `--lane` assigned instead of accumulating (six FBNeo gates dropped
silently, including the superset invariant); `^ *SKIP` matched before the exit
status, so `test_wide_profile`'s exit-2 "PARTIAL: the emulator superset
invariant was NOT run" filed as a benign skip (**the same defect was in
`run_all_static.sh`**); and a `| while read` loop put the gate-launching in a
SUBSHELL, so the `wait` after it waited for nothing and a lane announced itself
finished with gates still running.

**The sweep's result: 155 gates, 136 PASS, 19 FAIL, ZERO SKIP, ZERO TIMEOUT,
ZERO MISSING — and NOT ONE red was a defect in the shipped artifact.**

The nineteen, by class:

| class | gates |
|---|---|
| 1 orphan (the hole it hid) | `audit_legacy_pairings` — replay `105_legacy_2pwin_auto` had been LEGACY content guarded by NOTHING for five sessions; a census of all 88 replays said it was the only one |
| 3 dead control | `audit_qs_voice_wav` (last-window boundary), `audit_hitclass_map_cost` (the no-thunk twin stopped crashing) |
| 4 stale reference | `test_wide_profile` (reference binary 3 days older than the harness patch), `test_m2a_stage4_oracle` + `test_m2a_stage2_data` (M2a-era dirs), `test_hui_oracle` (`build/hui4`, pre-WIDE-v1.1), `test_phasec_image` + `test_m2b_stage6` (one cause: M13 built and unregistered), `audit_phase_mode_cost` (a reference 25 freezes old) |
| 5 outgrown parser | `audit_merged_vec3` — `A1`/`A3` were added to the PROBE line at 14z-109 and its extractor required `A6` to follow `A0` directly, so for NINETEEN sessions it reported "rig dead — the replay or pokes moved" at a rig that was fine |
| 6 deleted mechanism | `audit_type_dispatch_range` — scrapes an `obj_hook thunk` that 14z-91 removed. **RESOLVED 14z-129 by DELETION** (maintainer: "better no test than a bad one"): the probe site was re-findable but the VERDICT CONTROL was not, and a re-target would have shipped a gate that cannot fail ([VSP-166]) |
| 7 missing operand | `audit_walker_repoint`, `audit_empty_tiles` (both PASS once given one), `audit_mask_window_ff42a2` (an instrument; now skips) |
| — | `audit_region_movability` (injects a `region_space` key `donovan.toml` has carried since 14z-111), `test_pyron_soak` + `test_pyron_ladder` (the only CRASH class, on self-built stage images; `audit_guard_corpus` PASSED on the merged build, so the artifact is not implicated), `audit_continue_switch` (a frozen arcade trajectory, [VSP-132]) |

**Eight closed in-session.** The legacy-pairing hole was closed end to end:
basis frozen with its instrument control, shape measured identical on all three
builds, both flicker frames attributed by dump diff, `composite ... 2713,5868
889-2491` authored, accepted by `run_suite` on all three, and the attribution
itself made ENFORCEABLE as two new cases plus a new named window
(`obj-builder-stack`) in `audit_flicker_attribution` — which then reproduced
the dump reading byte for byte.

**The rot gate needed a third and fourth form.** `test_build_ref_rot.sh` matched
`${1:-build/x}` and `${VAR:-build/x}`; it could not see a plain
`REF=build/hui30`, nor `"${1:-$REPO/build/x/rompath}"` — the latter being the
most common form in the suite (28 references) and the one hiding an actual rot.
Its read-as-romset test also missed the case where the variable IS the rompath.

**Also fixed:** 37 gate headers naming build dirs pruned freezes earlier; three
defect-lock headers still describing a pre-fix world (#103/#105 shipped fixed at
14z-99, only the prose was stale); `test_mister_gfxc_fetch`'s "NEVER BEEN GREEN"
(it passed in full at 14z-108 — its DEFAULT operands are why a bare run is red).

**And the emulator superset invariant ran for the first time in the sweep** and
is GREEN: 12/12 replays bit-identical in work RAM AND framebuffer between the
reference and patched binaries, plus inertness 12/12 and the B4 canary 12/12.

## 14z-127 (2026-09-02) — the release-time test scope is ruled

The maintainer's ruling that made the 14z-128 arc necessary: at release ALL
tests run; anything red or skipped is a hard fail unless explicitly approved;
the discriminator for scope is THE SUBJECT OF THE TEST, not the romsets it
touches. Its immediate consequence — a gate that self-skips on a missing
prerequisite has NOT been run — was applied to `test_don_immortal_native`,
which had two silent `exit 0`s. The gap it exposed (167 emulator-tier gates, 29
reachable) was measured the same session and handed forward.

## 14z-123 (2026-08-30) — the gate index becomes GENERATED

HANDOFF carried a hand-written fence of 168 gate entries, 113 scripts
unindexed, one duplicated. Replaced by `docs/project/gate_index.md`, generated
from each script's own header, with `tests/test_gate_index_current.sh` failing
on drift and on any script without a family row. The ruling that came with it —
**a gate's WHY lives in its header** — is what makes the generated index
possible, and what made the 14z-128 header-defaults gate worth writing.

## 14z-97 (2026-08-19) — the rot gate learns its second form

`test_build_ref_rot.sh` matched only the POSITIONAL default `VAR="${1:-build/x}"`.
Eleven references used the named-env idiom and were invisible. None of the
eleven was rotted, which the entry recorded as the reason it was cheap to close
then. Same session: the M2 battery's target stopped being a pinned set name and
began following the build via `registry.tsv` (#96).

## 14z-94 (2026-08-18) — the first runner, and the 11-day red

There was no CI, no aggregator, and 101 of 130 test scripts had no shell caller
at all. `tests/run_all_static.sh` was built with three verdicts counted
separately because **SKIP IS NOT PASS** (#29), and with the anti-orphan
registry-coverage check, "without which this script would simply become a new,
smaller thing to forget to update".

What it cost, and the reason this file exists: `tests/test_dualtrack.sh` had sat
RED FOR ELEVEN DAYS while CLAUDE.md §4 cited it as one of FBNeo's three
guarantees. It was found only because an unrelated fix happened to require
rebuilding the FBNeo binary.
