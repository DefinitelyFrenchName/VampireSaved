# NEXT SESSION — orientation (rewritten at the 14z-141 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* **The harness and
its skill are DONE (14z-135..139). LIVING DOCS IS THREE SLICES OF FOUR: L1 and
L4 landed 14z-140, L2 landed 14z-141. L3 the ROM re-derivation is the last
one, and it is next.**

## L3 IS NEXT — scope it first, then STOP for the rulings

The record is **`docs/project/living_docs_scope.md`**: §4's slice table
(status in place), §6 the standing decisions, and one plan section per slice —
**§8 L1, §9 L4, §10 L2, all LANDED**. §11 is L3's and is written at its own
opener.

**THE EXECUTION PLAN IS STILL THE BRIEF: `build/living_docs_plan_14z139.md`**
(untracked, a copy of `~/.claude/plans/well-i-m-almost-out-glimmering-koala.md`).
**Read it in full after this file.** §0 is the standing frame every
living-docs session runs inside — the opener, the eight-check doc battery with
exit codes captured directly, the ALONE rule, the four beats (measure → write
the slice's plan section → **STOP for the rulings** → execute in a fixed
order), the close, and eleven paid-for traps. §4 is L3's section:
`tools/checkdocs_rom.py`, quoting an atlas claim and re-deriving it from the
decrypted image, `--uncovered` as the coverage number. It is scoped as TWO
sessions for the framework plus the atlas ROM tier.

**RE-MEASURE AT THE OPENER RATHER THAN READING THE SCOPE DOCUMENT. All THREE
censuses so far disagreed with it** — L1 found four unlisted documents where
§2.2 said two; L4 found six structural constructs where the plan listed four,
one of which could not have worked; L2's found the canon has subdirectories
the plan never names, a kind census counted tree-wide instead of over the
canon, provenance living in paragraphs rather than on value lines, and a
GAMEPLAY seed naming keys that do not exist. §0.6 lists what dates.

## WHAT L2 LEFT THE NEXT SLICE

- **The NOTE class exists now** — a gate prints `NOTE: <key> <value>` at
  COLUMN 0, exits 0 with its usual PASS, and `run_all_static.sh` surfaces it
  in an advisory block. L3's coverage number is specified NOTE-class, so it
  plugs straight in. `tests/test_static_runner.sh` §9 is the ground truth, and
  the convention's one home is `tests/lib/classify.sh`'s header. **Emit at
  column 0 or the runner cannot see it** — that mistake shipped once already.
- **`tools/audit_rule5.py` is the precedent for a census tool here**: an
  explicit KNOWN-pair list so a NEW key FAILS rather than defaulting;
  exclusions explicit in the tool rather than implied by `git ls-files`; a
  multiset diff; a progress guard at the TOP of a scan loop.
- **A change to `run_all_static.sh` or the shared libs will move
  `test_bbh_fidelity` F1**, which demands byte-identical output against the
  harness's `bbh run-static`. Mirror the change into `~/Developer/blackbox-harness`
  (push is standing-authorised) rather than re-baselining, unless it is
  genuinely lineage-specific.

## OPEN, IN ORDER

1. **L3 the ROM re-derivation** — scoped first, stopping for the rulings.
2. Then the open items below.

## OPEN ITEMS

**NEW, from 14z-141 — `PRG:0x028D50` CARRIES THREE NAMES** and it is a
gameplay surface, so the call is the maintainer's ([VSP-10]):
`effect_map_5051` (`huitzil.toml`), `hit_class_props_ext_hi/_lo`
(`donovan.toml`), and the guard-MASH RNG mask table (`docs/game/atlas/ram.md`
line 156 — 3: 8/32, 4: 16/32, 5: 24/32, 6+: always), which is what the
mizuumi corpus calls the Tech-Hit Chance Tables. `audit_rule5.py` classifies
that band GAMEPLAY conservatively and carries the conflict in
`AUX_POKE_BANDS`. Establishing which name is right is a measurement, not a
reading.

Unchanged: the deferred `audit_mask_window_ff42a2` ruling (deprecated or
case-specific), `test_header_defaults` and the positional `[name]` default,
`release/merged-m15` never packaged, Pyron's row 0x11 (mechanism not
established; no port recommendation), the Phobos ±1 residue (a knowledge
item), the community cross-check aerials, the Zabel j.LK session, #112
option (B).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited — not in the main tree, not in a
worktree** ([MSC-54]). **The static tier is never run beside another gate run
in this tree, and nothing here is edited while it runs** — and it can be
KILLED by the OS under memory pressure, which shows up as a gate FAILing with
`exit 143` (SIGTERM) and NO `GREEN`/`NOT GREEN` line: that run is worth
nothing, re-run it.
