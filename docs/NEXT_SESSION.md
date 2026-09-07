# NEXT SESSION — orientation (rewritten at the 14z-139 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* **The harness
and its skill are DONE (14z-135..139). Living docs is next, in a fresh
session, scoped first.**

## WHERE THE HARNESS IS: COMPLETE THROUGH H10, WITH ITS SKILL

`~/Developer/blackbox-harness` (`bbh`), a SEPARATE public repository
(pushing it is standing-authorised), beside this tree's PARENT —
`../../blackbox-harness` from here. Every slice landed (H1-H7, H9, H10; H8
decided out); fidelity F1-F11 exact (F8 opt-in on the real emulators); the
eight defaults RULED and registered in its `docs/conventions.md`; a
verdict-text change is LOUD (`docs/rebaselines.md` there, its newest line
printed by every fidelity run); its docs are lean and anchored with
`_history.md` twins as the complete log (`docs/doctrine.md` §3 there).
**The skill `blackbox-harness` (`[BBH-1..87]`, `skill/blackbox-harness/`,
locked by `bbh check-skills --config skill/skills.toml`, `GUIDE.md`
generated) is installed as the symlink `~/.claude/skills/blackbox-harness`
and loads in every session on this machine — load it before any work ON
the harness.** Its pre-commit: `bbh selftest` with `ROMDIR` (~6 min, 30
PASS / 2 SKIP); never beside a gate run in this tree. This tree never
consumes it; its one gate is `tests/test_bbh_fidelity.sh` (`ci_static`),
which passes its location as `BBH_FIDELITY_ROOT`. The whole record:
`docs/project/harness_scope.md` (§4 the slices, §5 the fidelity rows, §7
the rulings, §9 the skill).

## NEXT: LIVING DOCS — L1 routing, then L4 site, L2 fact census, L3 ROM re-derivation

1. **Living docs** — `docs/project/living_docs_scope.md`, all three forms
   ruled (a rendered site, routing enforcement in the markdown, fact tables
   with provenance), in the order L1 routing → L4 site → L2 fact census →
   L3 ROM re-derivation (§4 argues the order). **Scope each slice first, as
   every harness slice was**, then the maintainer rules, then the work.
   L1 starts from a shared vocabulary: the harness's documentation
   convention (lean anchored pages + `_history.md` twins) is the one this
   tree's `doc_shape.tsv` already enforces.
2. Then the open items below.

## OPEN, IN ORDER

1. Living docs (above), then the open items.
2. ~~The eight defaults of `harness_scope.md` §7 are open to VETO~~ ALL
   RULED 14z-139 (2), each DECIDED in place in §7.
3. ~~The findings about this tree recorded at 14z-135..138~~ ALL FIXED
   14z-139 (one classifier `tests/lib/classify.sh` for the three runners;
   the enumerator's `.diverge` case; `test_build_ref_rot`'s named image
   preference with `test_ref_rot_image_pick`; the battery's stop; the
   guards' code window).
4. The standing items unchanged: the deferred `audit_mask_window_ff42a2`
   ruling (deprecated or case-specific), `test_header_defaults` and the
   positional `[name]` default, `release/merged-m15` never packaged,
   Pyron's row 0x11 (mechanism not established; no port recommendation),
   the Phobos ±1 residue (a knowledge item), the community cross-check
   aerials, the Zabel j.LK session, #112 option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate
run in this tree, and nothing here is edited while it runs.**
