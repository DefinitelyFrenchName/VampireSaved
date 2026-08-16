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
| 32 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | A dropped write is not under-reporting: `SekMapHandler` replaces the default handler, so it is neither performed nor forwarded. Reachable from *legal* input via #37's coalescing. Fixed as per-span validation on top of #37 — validating named ranges alone leaves the gap between them. |
| 33 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | Fixed by REFUSING OBJ taps, not per-frame re-install: re-installing still loses the remainder of any flipping frame, turning a silent null into a plausible-but-incomplete log. |
| 34 | medium | UPHELD medium | **FIXED** 2e4bf24, closed | Wrong logged address was live on every call site. Third defect found in the same five lines: odd-length hex silently truncated. |
| 36 | medium | UPHELD | **FIXED** 441f05c, closed | The filed check (`git apply -R --check`) fails open on the issue's own scenario — measured. Gate reconstructs from pin + patches and compares whole files. Deliberately NOT wired into the build path: a hard gate ahead of untested changes is rule 2 backwards. |
| 37 | medium | UPHELD, re-rated **low** | **FIXED** 2e4bf24, closed | No independent failure mode — the demonstrated harm is #32's. Landed because #32's validation is unsound without it. |
| 64 | low | UPHELD low | **FIXED** 2e4bf24, closed | Both stated triggers refuted. The suggested bare `continue` was rejected: it downgrades a *caught* segfault to an uncaught silent skip. |
| 65 | low | UPHELD low | **FIXED** 2e4bf24, closed | The sandbox missed the input that decides *which set is measured*. Clearing is guarded on `./roms` existing, else an ad-hoc invocation loses ROM resolution. |

*(remaining rows appended as they are ruled)*

## Issues opened by this pass

| # | Why |
|---|---|
| [#75](https://github.com/DefinitelyFrenchName/VampireSaved/issues/75) | REVEALED by the #14 fix: the merged build fails its own gfx verification for Huitzil, and has since merged6. Not caused by the fix — exposed by it. |

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
