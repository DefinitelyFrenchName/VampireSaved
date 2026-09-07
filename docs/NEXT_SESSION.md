# NEXT SESSION — orientation (rewritten at the 14z-138 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* Both are SCOPED
(`docs/project/harness_scope.md`, `docs/project/living_docs_scope.md`);
**every harness slice is LANDED — H1-H7 and H9 (H8 was decided out).** Nothing
in this tree's own harness changed; it "stays as it is". The one file it
gained is `tests/test_bbh_fidelity.sh`.

## WHERE THE HARNESS IS: COMPLETE THROUGH H9 (`803f372` H1, `ef7e899` H2, `c26ba45` H3, `81ad426` H4, `b533715` H5, `8867dbb` H7, `512747b` H6)

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository, PUBLIC at
https://github.com/DefinitelyFrenchName/blackbox-harness (branch `main`;
pushing it is standing-authorised since 14z-135b). **It sits beside
`~/Developer/Vampire_Saved/`, the PARENT of this tree** — `../../blackbox-harness`
from here, not `../` (the scope's "sibling" default was one level short;
the gate searches both). `bin/bbh run-static | run-sweep | run-suite |
fingerprint | rpl | classify | tier | config | demand-after-trap | compare-* |
check-diverge | describe-shape | gate-index | header-defaults | ref-rot |
provenance | compare-fields | check-dumps | inp-play | inp-corpus | doctor |
selftest`; the drivers `drivers/{fake,mame,mame_guarded,fbneo}.sh`; the Lua
layer `lua/mame/` under `profiles/{cps2,cps2w,TEMPLATE}.lua`. Read its
`README.md`, `docs/gate_contract.md`, `docs/config.md`, `docs/hygiene.md`,
`docs/lua.md` (the Lua layer and the machine profile), `drivers/README.md`
(THE DRIVER CONTRACT), `docs/method/oracle_classes.md`, `example/README.md`;
the consumer config for THIS tree is `example/consumers/bbh.vampire.toml`.
`bbh selftest` is 31 gates: 30 PASS / 1 SKIP on this host (`test_rpl_lua`
needs a standalone `lua`; the same equality runs under MAME in F8), ~4 min;
the slice pre-commit is `BBH_MAME_FIDELITY=1 BBH_FIDELITY_F8=all
BBH_FIDELITY_F5=1 BBH_FIDELITY_F6=all BBH_FIDELITY_F7=all bbh selftest` with
`ROMDIR`, ~20 min. Fidelity: F1 identical, F3-F7, F9, F10 exact (ROM-free
but F6), **F8 exact** (the Lua layer, the drivers and the recording tools on
the real emulators — `selftest/test_fidelity_mame.sh`, opt-in). **In THIS
tree: `ROMDIR=... tests/test_bbh_fidelity.sh`** (`ci_static`, ~65 s alone;
`BBH_MAME_FIDELITY=1` adds F8, ~1 min, never beside another gate run here).

## NEXT: THE HARNESS SKILL, then living docs

1. **The skill** — the maintainer's order: *"then distill the skill that goes
   with that generic harness"* (a skill distils something that EXISTS; it
   does now). The precedent is `docs/project/skills_scope.md` and the six
   in-tree skills (`.claude/skills/<name>/SKILL.md`, rules `[PFX-N]` anchored
   in the paragraph each distils, locked by `tools/checkskills.py`; the
   level-0 skills carry a GENERATED guide). The harness's own docs are the
   paragraphs to anchor in — `docs/gate_contract.md`, `drivers/README.md`,
   `docs/config.md`, `docs/hygiene.md`, `docs/lua.md`,
   `docs/method/oracle_classes.md`, the README's doctrine — so the skill's
   anchors live in the HARNESS repository (its `skill/` placeholder), not
   here; decide at the plan stage whether `checkskills.py` travels with it
   or the harness gets its own lock. Scope first, as every slice was.
2. Then living docs L1 → L4 → L2 → L3 (`living_docs_scope.md` §4).
3. Then the open items below.

## OPEN, IN ORDER

1. The skill (above), then living docs, then the open items.
2. The eight defaults of `harness_scope.md` §7 are open to VETO; §7.3's
   default location is now stated as measured (two levels).
3. **Findings about this tree, recorded, not fixed:** (14z-135)
   `run_all_static.sh` has no exit-0-after-shell-error branch (the sweep
   runner has); (14z-136) `tests/lib/enumerate_expectations.sh` has no
   `diverge` case; (14z-137) `tests/test_build_ref_rot.sh` picks its image by
   DIRECTORY ORDER when no `vsavjw` zip is present; (14z-137) `run_battery_m2.sh`'s
   `bat` reads exit 0 by grep only; **(14z-138) `tests/lua/replay_guard.lua`
   carries the STOCK code window `0x400000` in `rom_plausible` and the
   handler filter while `inp_guard.lua` carries the WIDE `0x600000`** — a
   crash whose return addresses sit in the program extension draws a shorter
   STACK sketch under the replay guard than under the recording guard, and
   a handler placed above 4 MB would not be trapped by it at all (none is
   today: the vectors point into the crypt range). Latent on every replay
   run so far (F8's positive control crashes at `PRG:0x0BF800`). The
   harness's `cps2w` profile is the fix shape; here it is one constant in
   one file, if the maintainer wants the two guards to agree.
4. The standing items unchanged: the deferred `audit_mask_window_ff42a2`
   ruling, `test_header_defaults` and the positional `[name]` default,
   `release/merged-m15` never packaged, Pyron's row 0x11, the Phobos ±1
   residue, the community cross-check aerials, the Zabel j.LK session, #112
   option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate
run in this tree, and nothing here is edited while it runs.**
