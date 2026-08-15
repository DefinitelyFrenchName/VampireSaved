# NEXT SESSION — orientation (written at the close of 14z-89, 2026-08-15)

> ## FIRST TASK — THE LEGACY REGRESSION IN (1) BELOW. Ruled on by the
> ## maintainer 2026-08-15: (3) decided, (2) correction accepted (its FIX
> ## still unruled), (1) offered conditional ratification which MEASUREMENT
> ## REFUSED, (4) still open. STATE carries the full record.
>
> 14z-89 closed the coverage gap 14z-88 exposed: every replay whose loaded
> characters equal vanilla's is now compared against the VANILLA masked
> basis instead of against itself, on all three sets, and
> `tests/audit_legacy_pairings.sh` fails if that ever stops being true.
> The gap was **35 of the ~43 self-frozen replays per set**, not the 10 the
> 14z-88 note predicted — the `*_don_*`/`*_victor_*` families were authored
> when select cell 0x0F was Donovan, and M3a made them legacy content.
> 93 (set, replay) pairs are now `.masked`; 69 sit on the ratified 2P shape
> `composite 829 889-2091` verbatim.
>
> **Closing it found 6 replays that never re-converge with vanilla.** All
> deterministic, all attributed, all `.pending` (so the three suites read RED
> on exactly those and nothing else). They need a ruling:
>
> 1. **RESOLVED AGAINST RATIFYING — IT IS AN OPEN REGRESSION.** The
>    maintainer offered conditional ratification ("if ratifying solves the
>    issues with no known or forecast issues"); the condition was checked
>    and FAILS. The divergence is not a phase artifact and not display-only:
>    it grows (replay 38: 3 live bytes at f2400 -> 232 at f3000 -> 450 at
>    f4500) and reaches GAMEPLAY state — 38 P2 HP 87 vs 88 at f4500, P1 X
>    797 vs 796 at f3000; 24 at f17500 P1 X 324 vs 570 / HP 144 vs 115, P2
>    X 655 vs 335 / HP 144 vs 157, facings flipped. Replay inputs are
>    scheduled by FRAME, so one lost logic step re-aligns every later input.
>    **THIS IS THE FIRST TASK** (CLAUDE.md §2.6 halts forward work).
>    Cheapest next measurement, before designing any fix: 24 fails
>    IDENTICALLY on all three sets, so the cause is SHARED — do the
>    14z-88-style A/B with the edited palette rows' CONTENT reverted to
>    vanilla and see whether 24's onset moves. That names the cost source
>    (edited palette content vs the extended wheel vs the shared hooks)
>    before anything is engineered.
> 2. **The type-6 deadness claim is FALSE — and the fallback held.** Legacy
>    lists reach the taken-over list-type 6 on huitzil-m13: the `$FF010C`
>    tripwire arms 387x on `21_don_mash` and 948x on `26_don_arcade_mash`,
>    PC-attributed inside the thunk. Nothing rendered wrong — that is the
>    safe-and-loud design working, and it is the DEADNESS REGISTER's first
>    real hit. Residual cost is the counter itself (live work RAM vanilla
>    does not keep). Recommendation: make the tripwire diagnostic-only
>    (latch inside an already-masked window) so those two return to a strict
>    basis without losing the signal.
> 4. **Merged `12_donovan_vs_cpu`** (small, mechanical): leg (a) now covers
>    45 replays and is 42 PASS / 3 FAIL — 21/26 are ruling 2 above, and 12
>    measures the UNION of the two solo shapes (`composite 2836,5713
>    889-2415`; both frames already attributed). Same species as the 04 and
>    11 inline overrides you ratified. Recommendation: ratify as override #3.
>
> 3. **DECIDED (maintainer, 2026-08-15): the 61/62 exemption stands.**
>    They navigate to cell 0x13, which neither vanilla nor those builds
>    back; `<set>/<name>.legacy-exempt` carries the reason and the audit
>    prints it every run. No further action.
>
> After the rulings: implement whichever fix each implies, re-run the three
> suites + `tests/audit_legacy_pairings.sh` + `tests/audit_merged_legacy.sh`
> (leg (a) is glob-driven and now covers 47 replays, ~2 h).
>
> **BATTERY AT CLOSE.** The three suites are RED on exactly those 6
> `.pending` replays and NOTHING else — donovan-m5 53 PASS / 2 PENDING /
> 18 SKIP, huitzil-m13 52 / 3 / 18, pyron-m7 55 / 1 / 17, with **0 FAIL and
> 0 nondeterministic runs** across all three, every one of the 93 promoted
> specs passing and the 13 pre-existing masked classes byte-unchanged.
> `test_m3a_reproducible` PASS (all four fingerprints bit-exact — no build
> byte moved this session); `test_describe_masked_shape` PASS (11/11).

> ## SCOPE RULING (maintainer, 2026-08-15): the build targets 2P
> ## COMPETITIVE play. Shadow/Marionette/Oboro interaction with the
> ## tenants and single-player ENDINGS for the new three are
> ## NICE-TO-HAVE, not blockers (like the medallion tint and win quotes).
> ## Mandatory core = legacy fidelity + the tenants' 2P match correctness
> ## (18x18 matrix crash-free), then release engineering.

> ## START HERE — the open list, in order
> - The three rulings above (and the merged audit re-run after them).
> - The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
> - FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
> - Round-end flicker (parked; needs the maintainer's recording).
> - OPTIONAL / cosmetic (maintainer 2026-08-15): the merged-only
>   P2-ring-on-Donovan medallion whitening (fix Donovan's P2-hover PORTRAIT
>   row, not Pyron's medallion — and MEASURE THE FADE COST FIRST, that is
>   what 14z-88 cost); win-screen QUOTE (both tenants); region_space
>   re-freeze; op-tagging for test_shared_writes.
> - H-vs-P stuck-direction (~1/30) — possible; not reproduced recently.
> - Then MiSTer core surgery (stretch, DECIDED) — after the roster.

> ## WHAT 14z-89 LEFT YOU (harness)
> - `tests/audit_legacy_pairings.sh` — the coverage gate. Run it whenever a
>   replay is added, a cell mapping moves, or a tenant changes id. Signature
>   is +0x60.l (hitbox base), NOT +0x382 (the voice class in match).
>   Reports land in `build/legacy_pairings/*.tsv`.
> - `tools/describe_masked_shape.py` (+ `tests/test_describe_masked_shape.sh`)
>   — the shape→proposed-spec classifier, lifted out of the merged audit's
>   heredoc and now ground-truthed on both threshold boundaries.
> - `tools/propose_masked_specs.sh` — measure named replays masked on a build
>   and print drop-in `.masked` lines.
> - `tools/freeze_masked_basis.sh` — now REFUSES a mask that disagrees with
>   the basis's `MASK` record, scrubs perturbing env vars, and takes
>   `VERIFY_BASIS=<name>` (re-derive an already-frozen log, require
>   bit-identity, write nothing if it moves). Use that on every extension.
> - `tests/expected/vsavj/masked-v2/` is now 49 logs + a `MASK` record.
>   Adding LOGS to a basis is not a basis change; adding a WINDOW is.

## Current builds (registry) — UNCHANGED by 14z-89 (no build byte moved)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged7 | UNREGISTERED (pending S6 freeze) | moves with generator (738 ops) |
| build/don_m5 | **donovan-m5** | 3c599fb6 |
| build/hui40 | **huitzil-m13** | 2629561c |
| build/pyron25 | **pyron-m7** | 94ce9a48 |
| build/m5_stock | stock twin | 6c93cfa8 |
| build/don_m4, hui39, pyron24 | superseded m4/m12/m6 (tags are the way back; don_m4 = audit_voice_borrow's lottery ground-truth reference) | — |

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
MAME_ROMPATH="$PWD/build/don_m5/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_describe_masked_shape.sh            # ~1 s
tests/audit_voice_borrow.sh                    # ~6 min — own-class on build/don_m5
tools/build_merged.sh build/m3b_merged7        # ~15 min (738-op fixture)
tests/audit_trap_parity.sh build/m3b_merged7   # ~5 min — ejection+chirp
tests/test_tenant_loop.sh                      # generator gate (538/738)
tests/test_m3a_reproducible.sh                 # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged7 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh                 # ~2 h since 14z-89 (leg a = 47)
```
