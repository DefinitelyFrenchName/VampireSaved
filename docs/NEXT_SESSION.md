# NEXT SESSION — orientation (rewritten at the 14z-137 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* Both are SCOPED
(`docs/project/harness_scope.md`, `docs/project/living_docs_scope.md`);
harness slices H1-H5 and H7 are LANDED. Nothing in this tree's own harness
changes; it "stays as it is".

## WHERE THE HARNESS IS: H1-H5 + H7 LANDED (`803f372`, `ef7e899`, `c26ba45`, `81ad426`, `b533715`, `8867dbb`)

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository, PUBLIC at
https://github.com/DefinitelyFrenchName/blackbox-harness (branch `main`;
pushing it is standing-authorised since 14z-135b). `bin/bbh run-static |
run-sweep | run-suite | fingerprint | rpl | classify | tier | config | demand-after-trap
| compare-* | check-diverge | describe-shape | gate-index | header-defaults | ref-rot
| provenance | compare-fields | check-dumps | doctor | selftest`. Read its
`README.md`, `docs/gate_contract.md`, `docs/config.md`, `docs/hygiene.md`,
`drivers/README.md` (THE DRIVER CONTRACT), `docs/method/oracle_classes.md`,
`example/README.md` (the fake machine, run green / break a control / freeze;
the hygiene checks and the dual-implementation protocol as a consumer runs
them); the consumer config for THIS tree is `example/consumers/bbh.vampire.toml`.
`bbh selftest` is 26 gates, 26 PASS (~4 min; the slice pre-commit is
`BBH_FIDELITY_F5=1 BBH_FIDELITY_F6=all BBH_FIDELITY_F7=all bbh selftest`
with `ROMDIR` set, ~15 min — do that at every slice). Fidelity so far: F1
identical, F3 exact, F4 exact, F5 exact (1,891/1,891), F6 exact, F7 exact,
F9 exact (the five hygiene tools over this tree; the gate index
byte-identical), F10 exact (the field comparator and the dump checker,
every mode) — all in `selftest/test_fidelity_vampire.sh`, which runs against
this tree at every selftest run; F2 is opt-in (`BBH_FIDELITY_F2=1`) and never
beside another gate run here.

## NEXT: H6 (the MAME Lua layer + the real drivers), the largest remaining slice — a fresh window

Read `harness_scope.md` §2.4 (I1, I3-I9), §3.3 (the machine profile), §4's
H6 row and §6 items 4-5 first. **H6** lifts `tests/lua/replay.lua` and its
siblings (`replay_guard.lua`, `snapshot_frames.lua`, `trace_writes.lua`,
`tap_writes.lua`, `read_tap.lua`, `inp_guard.lua`) under a MACHINE PROFILE
(`lua/mame/profiles/cps2.lua` + `TEMPLATE.lua`; `profile.lua` refuses a
missing key), `rpl_parse.lua` as one module with the equality selftest
against `rpl.py` (SKIP with reason when no standalone `lua` — this host has
none), `tools/run_mame.sh` + `run_replay_mame.sh` + `run_replay_guarded.sh`
+ `run_replay_fbneo.sh` as `drivers/mame.sh` / `mame_guarded.sh` /
`fbneo.sh` under the contract (a driver that cannot honour a variable
REFUSES), `bbh-inp-corpus` (recordings: the NOTE / DEFECT / naming rules,
the liveness check). **F8 is the only MAME-side parity**: one masked replay
through `run_replay_mame.sh` and `drivers/mame.sh` with `BBH_PROFILE=cps2.lua`,
logs `cmp`'d, then `VIDEO_OUT` / `DUMPS` / `POKES` / `SNAP_FRAMES` parity and
the guard's CRASH lines on `test_crash_guard`'s positive control — needs
`ROMDIR` and the pinned MAME (`MAME_BIN`, [VSP-24]'s pin rule). The MiSTer
driver STAYS here (decision 6).
- Then **H9** (`tests/test_bbh_fidelity.sh` in THIS tree — `ci_static`,
  `$BBH_HOME` default `../blackbox-harness`, SKIP when absent; the first
  full fidelity run recorded here; `ci_static` line + gate-index row; the
  ONLY file this tree gains), the harness SKILL, living docs L1 → L4 → L2 →
  L3 (`living_docs_scope.md` §4), then the open items.

## OPEN, IN ORDER

1. **H6** (above), then H9, the skill, living docs, then the open items below.
2. The eight defaults of `harness_scope.md` §7 are open to VETO — none
   blocks H6.
3. **A finding about this tree, not fixed (14z-135):** `run_all_static.sh`
   has no exit-0-after-shell-error branch (the sweep runner has, since
   14z-134); the demand-after-trap lint is what prevents the shape. Fix it
   here only if the maintainer wants the two runners identical.
4. **A second finding about this tree, not fixed (14z-136):**
   `tests/lib/enumerate_expectations.sh` has no `diverge` case — a live
   `.diverge` expectation would be reported UNKNOWN-KIND by
   `audit_legacy_pairings`. Harmless today (zero live `.diverge` files);
   the harness's copy has the case.
5. **A third finding about this tree, not fixed (14z-137):**
   `tests/test_build_ref_rot.sh` picks the image it judges by DIRECTORY
   ORDER when no `vsavjw` zip is present — on this host `vsavj.zip` happens
   to list before `vsav.zip`, so a stock build is judged by its own image;
   on another filesystem the same dir could be judged by the parent's 21
   members and read as a different set. The harness's `ref-rot` names the
   preference (`image_prefer = ["vsavjw", "vsavj"]`); the fix here is the
   same one-line preference in the gate's `zips` selection. Latent, not
   live.
6. **A fourth finding, not fixed (14z-137):** `tests/run_battery_m2.sh`'s
   `bat` wrapper reads exit 0 as PASS-or-SKIP by grep only, so an exit-0
   shell error (`${VAR:?}` after the trap) and a killed gate (exit 124)
   would read as PASS / abort the battery without naming the class; the
   harness's `accounting.sh` takes the verdict from the one classifier.
   The demand-after-trap lint already bars the cause in this tree.
7. The standing items unchanged: the deferred `audit_mask_window_ff42a2`
   ruling (deprecated or case-specific), `test_header_defaults` and the
   positional `[name]` default, `release/merged-m15` never packaged
   (recorded, not owed), Pyron's row 0x11 (measured; the port decision is
   the maintainer's; the pose-installer question first), the Phobos ±1
   residue, the community cross-check aerials, the Zabel j.LK session, #112
   option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate
run in this tree, and nothing here is edited while it runs.**
