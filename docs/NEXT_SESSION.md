# NEXT SESSION — orientation (rewritten at the 14z-142 CLOSE, 2026-09-08)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE MAINTAINER'S ORDER IS COMPLETE THROUGH ITS SECOND ITEM: THE OPEN ITEMS ARE NEXT

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* (2026-09-06)

**Both are DONE.** The harness and its skill landed 14z-135..139
(`~/Developer/blackbox-harness`, public, every slice plus `blackbox-harness`).
**The living-documentation effort landed in ALL FOUR FORMS**: L1 routing
enforcement and L4 the rendered site (14z-140), L2 the rule-5 fact census
(14z-141), L3 the ROM re-derivation (14z-142). The record is
`docs/project/living_docs_scope.md` — §8/§9/§10/§11, one plan section per
slice, each with its census, its rulings and what execution changed.

**So the next session starts the OPEN ITEMS, and the first question for the
maintainer is which one.** None is started; none is urgent; several are
gameplay calls that are theirs ([VSP-10]).

## THE OPEN ITEMS

**Needs a ruling before work, because it is a gameplay surface:**
- **`PRG:0x028D50` carries THREE names** — `effect_map_5051` (`huitzil.toml`),
  `hit_class_props_ext_hi/_lo` (`donovan.toml`), and the guard-MASH RNG mask
  table (`docs/game/atlas/ram.md` line 156), which the mizuumi corpus calls
  the Tech-Hit Chance Tables. `audit_rule5.py` classifies the band GAMEPLAY
  conservatively and carries the conflict in `AUX_POKE_BANDS`. Establishing
  which name is right is a MEASUREMENT, not a reading.

**Measured and waiting on a decision:**
- **Pyron's capture-keyframe row `0x11` is unported** — a real, grossly
  visible 2P defect (measured 14z-131, two independent ways). But the
  MECHANISM is not established: the victim's POSE RECORD also differs and the
  positioner cannot do that, so a second mechanism is in play. The named next
  measurement is the pose installer at `PRG:0x27FAA`. **No port
  recommendation until that is answered.**
- **The Phobos ±1 damage residue** — 5 of 54 victim/throw cells, ruled WITHIN
  TOLERANCE and kept open as a KNOWLEDGE item, not a bug. The cheap first step
  is whether `0x0A` (Sasquatch, a legacy victim) is a cross-generation data
  difference rather than anything of ours.
- **The community cross-check aerials** — needs a two-direction jump rig;
  mizuumi distinguishes neutral- from forward-jump variants where our slot map
  carries one chain per aerial button.

**Its own session by ruling:**
- **Zabel j.LK proximity guard** — a deliberate LEGACY-content patch, so
  outside the superset invariant's untouched set: it needs its own ratified
  expectation class and its own build flag, a hand-played recording FIRST
  ([VSP-20]), and archaeology before any theory ([VSP-14]).

**Smaller, and none blocking:**
- the deferred `audit_mask_window_ff42a2` ruling (deprecated or case-specific);
- `test_header_defaults` and the positional `[name]` default;
- `release/merged-m15` was never packaged;
- #112 option (B), explicitly kept open.

## WHAT L3 LEFT, IF COVERAGE IS GROWN

`tools/checkdocs_rom.py`: 15 checks, 12 table controls,
`NOTE: checkdocs_rom.coverage 30/346`, frozen at
`tests/expected/checkdocs_rom_covered.tsv` (31 rows, MULTISET-compared).
`--uncovered` prints the next-work list per document.

- **Add a check by WRITING it.** Coverage cannot be grown automatically: of 36
  atlas instruction spans, ONE sits in a paragraph naming exactly one address
  and 27 name none, so the instruction-to-address pairing is prose.
- **Declare the VIEW per claim.** Inside `PRG:0x000000-0x0FFFFF` a PC-relative
  read sees the OPCODE image and an `(An,Dn)` read the DATA image; the wrong
  one returns plausible garbage, not an error. **Grep `tests/` for the address
  first** — a gate that already froze it has answered the view and usually the
  stride ([VSP-155]).
- **The atlas is corrected BEFORE a check quotes it**, in its own commit. Done
  twice now: `id_space.md`'s `PRG:0x04FFA8` range exception, and
  `atlas/README.md`'s "only place it is checked" sentence, which the digest
  check quotes — so document and checker moved in one commit.
- `engine_internals.md` is the next document by ruling; `ram.md` never.

## OPEN, IN ORDER

1. **Ask the maintainer which open item to take** — the `PRG:0x028D50` naming
   conflict is the one that most needs their call.
2. Coverage growth on `checkdocs_rom` is available as filler work at a handful
   of checks per session, with the frozen set growing each time.

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
