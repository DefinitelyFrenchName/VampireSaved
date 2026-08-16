# NEXT SESSION — orientation (written at the close of 14z-89, 2026-08-15)

> ## TASK ZERO (maintainer, session close) — AN ADVERSARIAL CODE REVIEW of
> ## the project has been done and its findings are being addressed.
> ## Corrections only: nothing about the project's nature or its parts
> ## changes. But some findings touch THE TEST HARNESS and the tooling this
> ## session's conclusions rest on, so before resuming the fix below, go
> ## over what was fixed and decide whether it moves the state of the work.
> ## The bugfixes are worth it — this is an assessment, not a rollback.
>
> **WHY IT MATTERS HERE, CONCRETELY.** 14z-89 authored 93 `.masked` specs,
> 35 vanilla basis logs, a frozen dispatch census and two root-cause
> attributions — ALL of it produced by the harness. If a review fix changed
> how a log is produced or compared, some of that is re-derived, not
> re-argued. Exposure, worst first:
>   1. `tests/lua/replay.lua` — MASK_RANGES semantics (masked bytes are
>      SKIPPED from the stream), the per-frame checksum, input staging
>      (`held[frame+1]`). A change here moves EVERY frozen log: the whole
>      49-log masked-v2 basis and every `.sha1` would need re-deriving.
>   2. The comparators — `compare_window.py`, `compare_composite.py`,
>      `compare_flicker.py`, `check_diverge.py` — the 93 promoted specs are
>      only "PASS" relative to these.
>   3. `tools/describe_masked_shape.py` — every one of those 93 spec lines
>      was COPIED from its output; a threshold change re-writes them.
>   4. `tools/gen_donovan_patch.py` / `build_donovan.sh` — if the generator
>      moved, the four frozen fingerprints move with it and every
>      expectation set is orphaned (registry rows included).
>   5. `tests/lua/field_trace.lua` vs `replay.lua` — the coverage gate's
>      LEGACY/TENANT verdicts assume these two stage inputs IDENTICALLY
>      (`held[frame+1]`). A fix applied to one and not the other silently
>      re-classifies replays.
>   6. `tests/lua/dispatch_census.lua` — the frozen free-index counts
>      (50 / 83) behind the option-(b) fix.
>
> **THE CHECK, IN ORDER — instrument first, then data, then suites.** Each
> step is cheap and each one localises the blast radius:
> ```sh
> VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh >     tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m5/mask)" >     16_xemu_2p                      # THE canary: re-derives a frozen basis
>                                     # log and demands bit-identity (~1 min)
> tests/test_mame_parity.sh           # the pinned MAME build still reproduces
>                                     # every frozen oracle log bit-for-bit
> tests/test_describe_masked_shape.sh # 11 assertions incl. both thresholds
> tests/test_compare_window.sh ; tests/test_compare_composite.sh
> tests/test_compare_flicker.sh ; tests/test_suite_dispatch.sh
> tests/test_m3a_reproducible.sh      # all four fingerprints bit-exact (~4 min)
> tests/audit_dispatch_census.sh      # census still matches its frozen set
> tests/audit_legacy_pairings.sh      # coverage gate + its 7 static controls
> # then the three suites + audit_merged_legacy (the acceptance)
> ```
> **IF THE CANARY FAILS, DO NOT RE-FREEZE TO MAKE IT GREEN** — that silently
> redefines the baseline the superset invariant rests on (HANDOFF says this
> about the migration gate; it applies identically here). Re-derive
> deliberately, and say in STATE which artifacts moved and why.
>
> **WHAT SURVIVES A HARNESS FIX REGARDLESS** (so it does not get re-litigated):
> the legacy regression itself was confirmed with RAW FULL-RAM DUMPS — replay
> 38 P2 HP 87 vs 88, replay 24 P1 X 324 vs 570 / HP 144 vs 115 — which is
> comparator-independent evidence. The two root-cause attributions are
> likewise removal experiments (remove the hook, the divergence goes away),
> not comparator verdicts. A harness fix could change the SHAPES we froze; it
> cannot make those measurements not have happened.

> ## FIRST TASK — THE LEGACY REGRESSION IN (1) BELOW, then (2) in the
> ## SAME re-freeze. All four 14z-89 findings ruled on by the maintainer
> ## 2026-08-15: (1) conditional ratification offered and REFUSED BY
> ## MEASUREMENT (it reaches gameplay state) — still an open regression;
> ## (2) DECIDED, tripwire goes diagnostic-only (designed, not built);
> ## (3) DECIDED, the 61/62 exemption stands; (4) DECIDED and APPLIED.
> ## STATE carries the full record.
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
>    **THIS IS THE FIRST TASK** (CLAUDE.md §2.6 halts forward work) — but
>    the DIAGNOSIS IS DONE: both root causes are named and confirmed
>    complete, so what remains is designing the fix.
>      - CONTROL: `build/wide0` (the WIDE romset carrying the UNPATCHED
>        program) is BIT-IDENTICAL to vanilla on replay 38 — the profile,
>        the descriptor and the container are inert; the cost is in the
>        program patch.
>      - **38 <- `fixture_row0f_override_bank0/1`.** The pair replaces
>        `movea.l #0x3B5940,a0` at the venue fixture-load sites 0x01C586 /
>        0x01C59A with two `cmpi.b #id,abs.l` + branches, and its OWN
>        manifest comment says those sites are "shared by match intro AND
>        attract" — legacy runs them on every venue load, on a frame
>        already at the VBL edge. Remove -> the ratified 2P shape, 2909
>        identical frames after. (Eliminated first, one probe build each:
>        the 6 palette/accent thunks, the 3 drawer bank gates, the 4
>        select_companion thunks.)
>      - **24 <- the two `[[obj_hook]]` type-dispatch extensions**
>        (per-object dispatch, hot every frame). Remove -> re-converges,
>        5787 identical frames after.
>      - BOTH removed: 38 -> `window 889 2091`, 24 -> `composite
>        12313,12733 889-2091`. The causes are COMPLETE for donovan-m5, and
>        the shapes come out CLEANER than the frozen classes (38 loses its
>        829 flicker frame too), so the fix will re-freeze more than these
>        two replays.
>    **FIX = OPTION (b), DECIDED (maintainer): move the work OFF the
>    legacy path.** (c) is out on the gameplay evidence; (a) is cheaper but
>    "may just move the goalpost" — it is a cycle BUDGET, so a leaner guard
>    relocates the tipping point instead of removing it. Only (b) is zero
>    by construction. The two halves are NOT equally easy:
>      - **fixture (tractable).** Stop intercepting the shared venue
>        fixture-load; re-assert palette row 0x0F from TENANT-OWNED code
>        (char-init / his own per-frame handler), which vanilla never runs.
>        MEASURE FIRST: does tenant init run AFTER the venue fixture load?
>        (The thunk's comment says the char id is set before those sites
>        run, so the order is the open question.) Residual risk is a
>        one-frame stale colour at a venue transition = cosmetic = optional
>        under the scope ruling.
>      - **obj_hook (hard).** Repointing is NOT available: the dispatch is
>        `movea.l (0x12,PC,D0.w),A0` and BOTH tables are followed by LIVE
>        CODE (0x054570, 0x05E71E — measured), so the table can grow
>        neither in place nor to a new base without adding an instruction.
>        The dead-entry takeover that worked for effect-class row 16 has no
>        cheap candidate: both tables are ALL-DISTINCT with zero RTS stubs
>        (59/59, 114/114). Two routes, each needing measurement first:
>        (i) the RUNTIME DEADNESS CENSUS — **RUN, and the answer is YES on
>        the numbers**: `tests/audit_dispatch_census.sh` over all 49 legacy
>        replays on vanilla gives 0x054470 = 9 types observed / **50 free**
>        (17 needed) and 0x05E542 = 31 observed / **83 free** (10 needed),
>        frozen in `build/manifest/dispatch_census.toml` so a newly-seen
>        index FAILS. CAVEAT, same shape as the row we falsified today:
>        0x054470 fires in only 5 of 49 replays (the long mash/arcade rigs)
>        and the curve has NOT converged — 26_don_arcade_mash alone added
>        types 51 and 55. So before shipping a repoint, add the STATIC
>        complement (enumerate every type value vsavj's code can stamp —
>        `tools/audit_type_stamps.py`, today pointed at vs2's 114-120
>        family) and keep a tripwire that does NOT write live work RAM
>        (ruling (2)'s design — watch EXECUTION — so both fixes share one
>        mechanism);
>        (ii) give the tenant's secondary objects their own pool walked by
>        tenant code so they never enter the shared dispatcher — cleanest
>        and zero-cost by construction, much the largest change.
>    VALIDATE whichever lands by re-running the promoted legacy replays.
>    Instrument: `tools/probe_hook_removal.sh <tag> <replay> <hook>...`
>    (rebuild with named hooks removed, re-measure; ~5 min per probe).
> 2. **DECIDED (maintainer): make the tripwire diagnostic-only.** Design
>    recorded in STATE: drop the `$FF010C` write from the fallback path and
>    have `audit_effect_class_rows.sh` §4 watch the fallback's EXECUTION
>    instead (it already PC-attributes every hit, so it needs the event and
>    never the counter's value) — zero legacy RAM perturbation, no new mask
>    window. NOT implemented, deliberately: it re-fingerprints huitzil and
>    the merged build, and (1) will likely need a build change too, so both
>    should land in ONE re-freeze.
> 4. **DECIDED (maintainer): "Validated."** Merged override #3 applied in
>    `audit_merged_legacy.sh` (`composite vsavj/masked-v2 2836,5713
>    889-2415`), with both frames' attributions in the comment. It also
>    flags that a FOURTH exception should prompt "does the merged build want
>    its own class table?" rather than a longer list.
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
