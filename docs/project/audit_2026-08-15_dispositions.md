# Adversarial audit of 2026-08-15 — dispositions

The 2026-08-15 multi-agent review filed 73 issues (index: GitHub #74). This is
the ruling on each, produced by a second, independent adversarial pass in
14z-90: per issue a VERIFIER (re-prove the claim at HEAD, with bug archaeology)
and a DEVIL'S ADVOCATE (refute by default), from clean contexts, then an
ADJUDICATOR ruling on the pair.

**Filing a finding and acting on it are different decisions.** The first review
asked "is this true?". This pass asked "should we act, now, given the superset
invariant, the frozen-expectation economy, rule 6's halt, and what only the
maintainer may decide?". Several findings are correct and were still narrowed,
deferred, or escalated — the reason is recorded per row.

## Standing constraints applied to every ruling

1. **No fix may move a built ROM byte.** Program fingerprints must stay
   `3c599fb6 / 6c93cfa8 / 2629561c / 94ce9a48`. Whole-set (gfx+QSound) baselines
   captured from the pre-fix tree at session start: don_m5 `68caa5e3`, hui40
   `17f26a11`, pyron25 `9c543004`, m5_stock `c6d396d9`, merged7 `87079ee3`,
   plus a 198-member per-member SHA-1 manifest.
2. **No fix may silently re-freeze an expectation.** The re-freeze surface is
   wider than `tests/lua/replay.lua`: it includes comparator verdict strings
   frozen as `.masked` args, the mask↔baseset pairing, and the frozen frame
   constants in the instrument-consuming gates.
3. **Rule 6 is live** — 6 `.pending` replays. This pass is maintainer-authorised
   but does not displace that as the first task.
4. **A newly RED gate is classified before it is reverted**: REGRESSION (revert),
   REVEALED (the fix works and exposed a real pre-existing defect — file it, keep
   the fix), or RE-FREEZE-REQUIRED (maintainer).

## Verdicts

| # | Filed | Ruled | Disposition | Note |
|---|---|---|---|---|
| 1 | critical | UPHELD critical | **FIXED** b4df1ff, closed | Refutation conceded and inverted: `test_m2a_stage1_nullreloc.sh:35` states the no-pipe rule verbatim. Judging found a third variant (fresh outbase → `run_mame.sh` resolves pristine `$ROMDIR`, so the legacy gate measures vanilla). `rompath.tmp` staging deferred. |
| 2 | critical | UPHELD, re-rated **medium** | **FIXED (growth-only)**, closed | The mechanical finding is real — `run_battery_m2.sh:12` advertises a frozen-inventory watch over code that watches nothing. But the *proposed remedy* was refuted: inventories legitimately move per build (m2b `2 3507,3807` → m2c `1 3507`), so pinning m2c's numbers into a helper that runs on unfrozen builds manufactures false REDs. Implemented as the standing watch's literal text — fail on GROWTH, advise on shrink/EXACT, refuse to invent an inventory. |
| 3 | high | UPHELD, re-rated **medium** | **FIXED** 8caa98e, closed | False green reproduced: a run breaking permanently at 3000, truncated at 2500, was certified "fully re-convergent". Judging found the same idiom in `check_diverge.py:34`, which the filing had credited as a mitigation. Severity down: no automated path produces a short gate log. |
| 4 | high | **MAINTAINER**, re-rated medium | Partial fix; **2 questions escalated**, open | Both judges independently scanned all 121 `composite` specs and agreed. 97 of 102 sub-60 gaps are flicker→window — two separately attributed mechanisms — so applying flicker's single-mechanism rule across that boundary is a class-definition question, not a defect. Real anomaly is 5 specs. Landed the free parts; escalated the boundary rule and the five 55-frame pairs. |
| 5 | high | UPHELD, re-rated **medium** | **FIXED** 435b43d, closed | Pre-fix, a never-started emulator produced exit 0 and the full PASS text including the crypt-window budget. The filing's consequence claim is corrected: 72c4338 shows anim's `runs` came from a three-way probe comparison, not from this gate. What was broken was the reproduction contract. |
| 6 | high | UPHELD, re-rated **medium** | **FIXED (rompath only)**, closed | The `SET=vsavjw` half of the filed fix is **rejected**: the goldens are vanilla renders and the WIDE wheel adds three medallions outside the single mask, so it would be a guaranteed false failure — and the battery structurally cannot build WIDE at any outbase (its prefix `GEN_FLAGS` carries no `--profile`). |
| 7 | high | UPHELD, re-rated **medium** | **FIXED** 8a2b4b6, closed | Gate was RED on a clean checkout. Fixed with a kind→owner table, not by teaching `run_suite.sh` to skip a file it never reads. Refuter's refinement adopted: each row declares its run-chain and a battery claim must be earned. |
| 8 | high | UPHELD, re-rated **medium** | Manifest landed **advisory**; hard-fail deferred to the re-freeze, closed | Coverage measured at 8.1% of the shipped artifact. Two corrections: `--full` is rompath-dependent so it cannot be the assertion, and the in-build `audit_romset_identity.py` / `verify_gfx_build.py` narrow the gap to frozen-content drift. Hard-failing now would add a measured +156% re-freeze tax. |
| 9 | high | UPHELD, re-rated **medium** | **FIXED (one file)**, closed | Both judges independently measured the extract dirs byte-identical (hui30/31/32/27 ≡ hui40, pyron21 ≡ pyron25), so ~38 of 39 sites are provable no-ops. One real false green: `test_region_overlap.sh` asserts 2000 conflicting bytes measured on builds nobody ships (current trio: 2012). The 2000 measurement is **kept**, relabelled historical — it is the retired evidence that killed the shared-span dedup item. No constants file; it would sweep deliberate must-fail controls. |
| 10 | high | UPHELD, re-rated **medium** | Retraction pass landed e83f564; code edits **deferred**, open | 10 of 20 instruments drift; 3 are timing-sensitive, 7 are passive observers. Correcting them re-dates ~14-18 frozen frame constants across 12 gates — a re-freeze during a halt, to fix an off-by-one with no demonstrated victim. Every divergence-attribution instrument is already canonical. |
| 11 | high | UPHELD as a defect | **Deferred** into the FBNeo batch, open | `harness_mem()` ignores `nCpsObjectBank`, confirmed from core source. Latent: the only FBNeo OBJ dump's assertion is unaffected, and every load-bearing OBJ measurement runs on MAME, which handles the bank. Batches with #32/#33/#34/#37/#64/#65 behind #36 — seven hand-regenerated patch cycles on one file is how tree and patch drift apart. |
| 12 | high | UPHELD, **held** high | Shell half **FIXED** acb6623; C++ half batched, open | `main()` returns 0 unconditionally, and the runner's completion check is an *artifact* check that never cleared the artifact. Committed gates are saved by mktemp-fresh paths — but the documented *interactive* recipe uses a fixed reusable path, and the emulator's error text is hidden in the sandbox log. |
| 13 | high | UPHELD, **held** high | Sequenced into the FBNeo rebuild batch, open | `0x75660aac` is the real CRC of a 512 KB zero-fill on all four PRG rows. Not a "skip verification" sentinel — the opposite: a correct CRC that **mis-resolves**, because `FindRomByCrc` returns the first match with no entry de-duplication. Archaeology: this is 14z-62d's *original* defect at the one site that sweep missed. MAME shadows identically, so dual-emulator agreement is blind here. Fix is a proven no-op on every set in the tree. |
| 14 | high | UPHELD, **held** high | **FIXED** 94268e5, closed → **revealed #75** | Both verdict-bearing verifiers were unconditionally green. Repairing it exposed a live failure: `verify_gfx_build --tenant huitzil` fails on `m3b_merged7` (parity 1374,14911 vs 1375,14978; 34 tile codes out of window), printed and unread since merged6. Classified REVEALED — the fix stands, the defect is tracked separately. |
| 15 | high | UPHELD, re-rated **medium** | **FIXED** 5d2a9ca, closed | Reproduced under dash. The filing's `dash -n` census is unsound — it returns 0 on the very file proven dead. Re-censused with heredocs stripped: exactly one bashism in one file, so no 148-shebang migration. HANDOFF's "runs unchanged" claim, written 3 days after pipefail landed, corrected. |
| 16 | high | UPHELD, **held** high | Docs + field set landed a5494ef; checkers **open** | 3 of 5 flagged tools refuted (static ROM scans, no RAM read). Scope wider the other way: 4 live in-match readers, not 2, including the dual-emulator field set. Mechanism misattributed by leg — ours is protected by the shipped keep-tenant thunk; native is not. Checker fix blocked on freezing our tenant hitbox bases. |
| 17 | high | UPHELD, re-rated **medium** | **FIXED** 02fb94d, closed | Leg (a) measured 43 of 45 legacy pairings and reported the gap nowhere; the script's own header claimed 47. The two dropped are the **only two** that expose the open regression. Ruled report-don't-include: a `.pending` file is prose, no class exists in any set to borrow, and a merged-only line would be override #4. |
| 18 | medium | UPHELD, re-rated **low** | Narrowed; actionable half is **#28**, open | Headline fix rejected by both judges: expected-old-bytes already exist one layer up (207 `old_hex` + 23 `dst_old_head` rows, semantically reviewable), and inlining them is +698 KB / a 22x `patch.json`. The primary path is netted — `build_fingerprint` uses the *identical* `_PRG_RE` selector patch_prg writes through. Real hole: `build_merged.sh` reaches patch_prg with an unaudited ROMDIR and an unregenerated cache. |
| 19 | medium | CONFIRMED, re-rated **low** | Retraction landed a45a560; regex left, open | Corruption chain unreachable — `patch_prg` never reads a WIDE zip, and a `--gfx 8` build would produce an *unregistered* digest that `build_fingerprint` exits 2 on, so it could not silently redefine the frozen constants. The finding's sole load-bearing evidence was a plan branch that was NEVER TAKEN; retracting it was the real fix. |
| 20 | medium | CONFIRMED-PARTIAL, re-rated **low** | **Deferred** to the re-freeze, open | Check genuinely missing at both sites; **zero** length mismatches across 543 manifest hex pairs. The assertion lands in the generator — on the shipped-byte path — so rule 2 needs a rebuild that rule 6 reserves. The 14z-65 op-overlap assertion partly nets it meanwhile. |
| 21 | medium | UPHELD-PARTIAL medium | **FIXED** a45a560, closed | Both sides resolved to the SAME file when two logs share a directory: bit-identical by construction, returning 0. Fix refuses only the collision; a genuine zero-diff between distinct files stays a note, because there the identity is a measurement. |
| 22 | medium | **CONTESTED** | Recommendation recorded, open | The filed fix inverts under measurement: `verify_pcrel_data.py` reports **100% BROKEN on every shipped build** (hui40 69/69, don_m5 10/10). It is a triage survey with no pass state; wiring it in halts the project. Honest fix is the #2 pattern — advisory with a frozen accepted-BROKEN inventory — which needs 89 rows triaged first. |
| 23 | medium | UPHELD medium | **FIXED** a45a560, closed | The corpus is a glob over produced `.field` files and `leg()` ends in `|| true`, so a dead leg vanished and COVERAGE still printed PASS. Dead legs now leave a `.DEAD` marker and the classifier refuses. Zero occurrences in ~450 recorded legs; the 14z-89 run reconciles 55/55/56 delta 0. |
| 24 | medium | UPHELD | **CLOSED 2026-08-17 (maintainer)** | Its part (a) IS #29's fix; splitting flips the `exit 0` contract twice across the same files. Two premises fail: `BATTERY GREEN` occurs exactly once in the repo (the echo), in no log or STATE entry; and all nine cited skips actually run on this machine. |
| 25 | medium | UPHELD, re-rated **low** | Open, not fixed | Null-as-evidence is real, but this is a retired one-shot already ratified downstream by other means, and the published A3 value *is* the null signature — fixing it now cannot recover the measurement. A hard-FAIL has unmeasured false-failure risk. |
| 26 | medium | UPHELD medium(upper) | **FIXED** af557e1 + d465b19, closed | `run_battery_m2.sh build/don_m5` would repack STOCK over the registered WIDE reference. Guard is a TRACK-MISMATCH check, not a frozen-reference check — the latter blocked HANDOFF's own documented recipe. Then MOVED before the first write after my own test destroyed `build/don_m5/patch/`: generation runs before the `rm`. |
| 27 | medium | **CONTESTED**, re-rated low | **RULED 2026-08-18: ONE COMMAND — FIXED 14z-95** (`tools/ensure_merged_inputs.sh`, create-if-absent so no collision with #26; regenerated inputs yield a byte-identical merged patch, gated by `tests/test_merged_inputs.sh`) | A documented prerequisite of an on-demand builder, with producers and recipe in-tree and a loud failure. Also in direct conflict with #26: this asks for the pinned dirs to become derived, #26 asks for them to be protected. Maintainer call. |
| 28 | medium | UPHELD medium | Open — actionable half deferred | The named checksum line is the smaller half; neither path re-derives `build/out/*.bin`, which the generator reads at 30+ sites, regenerated only on ABSENCE with no provenance. Landing only the cheap half would close the issue and leave the gap. |
| 29 | medium | UPHELD, re-rated **low** | Open; `exit 77` REJECTED | Cited exemplar already fixed by #9. Nothing can skip on this machine. And `exit 77` would abort the battery under `set -eu` at a gate whose skip is correct-by-construction. Real defect is a runner TALLY (= #24), not a 34-script contract flip. |
| 30 | medium | PARTIAL, re-rated **low** | **MAINTAINER**, open | The metric reports the top-level runner as an orphan. Both scripts cited as callerless appear by name in NEXT_SESSION's recipes; `test_m3a_reproducible.sh` ran 3x this pass. 114/144 have no in-tree caller but exactly ONE is undiscoverable. |
| 31 | medium | PARTIAL, re-rated **low** | Half **FIXED** (as #58), rest open | No gate makes the masked swap, so worst case is a phantom RED not a false green. Header is falser than filed — five ignored vars, not three. |
| 32 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | A dropped write is not under-reporting: `SekMapHandler` replaces the default handler, so it is neither performed nor forwarded. Reachable from *legal* input via #37's coalescing. Fixed as per-span validation on top of #37 — validating named ranges alone leaves the gap between them. |
| 33 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | Fixed by REFUSING OBJ taps, not per-frame re-install: re-installing still loses the remainder of any flipping frame, turning a silent null into a plausible-but-incomplete log. |
| 34 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | Wrong logged address was live on every call site. Third defect found in the same five lines: odd-length hex silently truncated. |
| 35 | medium | **MAINTAINER** | Brief posted, open | The governing document contradicts a ratified amendment in the file every session reads first. Recommendation: retitle + a two-line bounded exception, not a copy of the spec. |
| 36 | medium | UPHELD | **FIXED** 441f05c, closed | The filed check (`git apply -R --check`) fails open on the issue's own scenario — measured. Gate reconstructs from pin + patches and compares whole files. Deliberately NOT wired into the build path: a hard gate ahead of untested changes is rule 2 backwards. |
| 37 | medium | UPHELD, re-rated **low** | **FIXED** 2e4bf24, closed | No independent failure mode — the demonstrated harm is #32's. Landed because #32's validation is unsound without it. |
| 38 | medium | UPHELD medium | Destructive half **FIXED** 8e6e2d0, rest open | Judging found worse than filed: `rm -f "$PLAY/roms"/*.zip` globs THROUGH a symlink and could delete the reference dumps — a class that already cost this project `qsound_hle.zip` once. |
| 39 | medium | **MAINTAINER** (PARTIAL) | Brief posted, open | "8 MiB ROM-derived" is FALSE — measured 0xFF fill, 12 of 16 a single repeated byte. The missing `vsw.*` rule is real. No history rewrite. |
| 40 | medium | **MAINTAINER** (PARTIAL) | Brief posted, open | Rule-7 half prospective; the real, already-paid cost is 471 MB of duplicate trees defeating every retraction-discipline grep. |
| 41 | medium | **MAINTAINER** | Brief posted, open | Static CI would have caught #15 the day it landed. Must fail on SKIP, and must not be called "tests". |
| 42 | medium | UPHELD medium | Open, deferred | Parsers cannot disagree here (py3.9, no tomllib) — the safety is an interpreter version, not an assertion. Fix stops the switching; needs the reserved rebuild. |
| 43 | medium | UPHELD medium | **RULED 2026-08-18: SPLIT. (a) FIXED 14z-95** — one matcher in `find_equiv.py`, `reconcile_batch`'s copy deleted, parameters pinned to measured values; 1640/1640 probes identical, gated by `tests/test_reconcile_matcher.sh`. **(b) still open** — freeing the parameters moves 2 of the 41 `open` rows (both to `plausible`), rides the next re-freeze | The lost fallback PREDATES the copy, so restoring is not inventing. Control needs no re-resolve: `allow_fallback=False` reproduces all 271 rows; `True` moves exactly 3. |
| 44 | medium | UPHELD, re-rated **HIGH** | Partly fixed (#53); rest **MAINTAINER**, open | The only issue whose severity ROSE. Proposer and checkers disagree THREE ways; §4 v4's "permits nothing either component permits alone" is false at HEAD. |
| 45 | low | **INVALID** | Closed, not planned | Timestamps real, conclusion false: nothing hashes a container. Both fingerprint tools are per-member and timestamp-free by construction. |
| 46 | low | UPHELD low | Open, deferred | Its own refutation is wrong in the filer's favour: `select_port.py` mutates `build/m5_stock`, a FROZEN reference, not a scratch dir. |
| 47 | low | UPHELD, severity **none** | Open, unfixed | 25 sites (not 19), all normalising to one shape, ZERO drift. Duplication without divergence is a maintainability note. |
| 48 | low | **CONTESTED** low | Open | Scenario disproven; a FOURTH copy found; the real bug there is a missing `--set`. |
| 49 | low | **CONTESTED**, severity none | Open | Byteswap verified identical exhaustively; `effect_tail.json` bit-reproducible. Enumeration note only. |
| 50 | low | **CONTESTED** low | Open | "None reachable by a test" is false — allocator/code_ptr/overlay are covered. Splitting a 5,400-line generator function is the highest-risk refactor in the tree. |
| 51 | low | UPHELD low | Open, deferred | Real off-by-one at FIVE sites, not two; measured no-op on every live span. |
| 52 | low | UPHELD low | **FIXED 14z-95** — exemption dropped, `END` off-by-one fixed, distinct `FAIL-SHORT` verdict; measured smallest live tail 1325 frames so nothing redded | The exemption spans the final SIXTY frames, not two. Zero frozen specs affected. |
| 53 | low | UPHELD low | **FIXED** 336a0f2, closed | Proposer refused a 60-frame tail, enforcer accepts it. The ground truth asserted the WRONG side — flipped, boundary now pinned from both sides. |
| 54 | low | UPHELD low | **FIXED** 070e225, closed | Two zero-frame logs: equal length, no differing rows, `EXACT` + exit 0 having compared nothing. |
| 55 | low | UPHELD low | **FIXED** 070e225, closed | Worse than filed: on `--merge` the empty stage is filled with REFERENCE members, so the artifact fingerprints as VANILLA and dispatches to the vanilla expectations. |
| 56 | low | **STALE** | Closed | Already fixed as #3's companion earlier in this same pass. |
| 57 | low | UPHELD low | Open | Fix is groundable from the driver (`IP_ACTIVE_LOW`, `PORT_SERVICE_NO_TOGGLE`) but changes what every replay asserts at frame 0 — wants one measured pass. |
| 58 | low | UPHELD low | **FIXED** 070e225, closed | Found independently by the #31 panel while I fixed it from #58's side — two panels converging from opposite directions. |
| 59 | low | UPHELD low | Open | Dumps and inputs ARE frame-aligned; only pokes are not, and no gate makes a poked cross-emulator comparison. Doc defect. |
| 60 | low | UPHELD low | Open | The real finding is the FALSE "SINGLE slot" rationale, not the ordering — a wrong rationale outlives a wrong loop. |
| 61 | low | UPHELD low | Open | Census of every mask string: zero leaked or double-read bytes. Fix belongs in the runner, not `replay.lua` (which would put 216 golden logs in scope). |
| 62 | low | UPHELD low | Open | Went from theoretical to live: masked-v3 is PARKED on disk, so a basis under an unused mask now exists. |
| 63 | low | UPHELD low | **FIXED** 070e225, closed | Residual left open on the issue: both guards share one predicate, so they fail together. |
| 64 | low | UPHELD low | **FIXED** 2e4bf24, closed | Both stated triggers refuted. The suggested bare `continue` was rejected: it downgrades a *caught* segfault to an uncaught silent skip. |
| 65 | low | UPHELD low | **FIXED** 2e4bf24, closed | The sandbox missed the input that decides *which set is measured*. Clearing is guarded on `./roms` existing, else an ad-hoc invocation loses ROM resolution. |
| 66 | low | UPHELD low | Open | Robustness, not security — no threat model. The misleading empty-`$NOPS` message (reads as "re-freeze") is the costly part; three uncited copies exist. |
| 67 | low | UPHELD low | Open | Portability papercut, not rule 7 (a path is not content). Dead on every scripted path. |
| 68 | low | UPHELD trivial | Open | Nine sites, not two. No threat model on either platform; every site already traps. Hygiene, not security. |
| 69 | low | **CONTESTED** low | Open | The title's fix is INVERTED: `build/out` regenerates only on absence with no provenance, so standardising on it spreads an unverified dependency. Narrow half (a `|| true` on a decrypt) is real. |
| 70 | low | **MAINTAINER** low | Open | Verbatim the decision already recorded as 14z-90 (3); premise moved when #2 landed. Two build GENERATIONS, not a forked copy. |
| 71 | low | UPHELD low | Open | The duplication is the smaller half — five gates each run their own full build of the same thing. |
| 72 | low | UPHELD low | **FIXED** 070e225, closed | Deleted. Larger half filed: all five tracked `build/scratch/*.py` omit the SHA-1 print, and two are cited as run instructions in the atlas. |
| 73 | low | **MAINTAINER** | Brief posted, open | A SHA-256 of the masked buffer is verdict-IDENTICAL to the current pixel compare, so conversion is clean if ruled inside rule 7. Record it either way. |

## Issues opened by this pass

| # | Why |
|---|---|
| [#75](https://github.com/DefinitelyFrenchName/VampireSaved/issues/75) | REVEALED by the #14 fix: the merged build fails its own gfx verification for Huitzil, and has since merged6. Not caused by the fix — exposed by it. |

## Tally

73 issues ruled. **32 closed** (30 fixed, 1 invalid, 1 stale), **41 open** with
a posted ruling: 9 awaiting a maintainer decision, the rest deferred with a
named blocker — almost all of them "the fix is on the shipped-byte path and
needs the rebuild rule 6 reserves for the legacy re-freeze".

**Severity moved on 24 of them.** One rose (#44, medium → high: the proposer
and the checkers disagree three ways and §4 v4 states a property the
implementation does not have). The rest fell, mostly because a defect that is
real but unreachable, or whose consequence is already netted downstream, is not
the same as one that has produced a wrong number.

**Nine fixes are NOT what the issue asked for**, because the filed remedy was
measured to be wrong or worse: #2 (would manufacture false REDs), #6 (would
fail by design), #8 (`--full` is rompath-dependent), #17 (would need a fourth
override), #22 (would red every build), #29 (would abort the battery), #33
(partial-frame coverage is worse than none), #36 (fails open on its own
scenario), #64 (downgrades a caught crash to a silent skip).

**One new defect was revealed** by a fix: #75.

## What this pass changed about how the harness is tested

Every fix here shipped with a negative control that **fails on the pre-fix
tree**, because three of them would otherwise have been indistinguishable from
no change:

- `tests/test_build_gate_status.sh` — exit status is *not* the discriminating
  assertion; whether the gate proceeds to measure a refused artifact is.
- `tests/test_suite_dispatch_selftest.sh` — caught its own fixture bug on first
  run (an anchored `sed` against a table row carrying the closing quote).
- `tests/test_movability_liveness.sh` — the positive leg caught a bug in the
  stub itself, which had made both negative legs pass for the wrong reason.

That pattern is the finding underneath the findings: a control without a
positive leg, and a control that has never been seen to fail, are both
decorations.
