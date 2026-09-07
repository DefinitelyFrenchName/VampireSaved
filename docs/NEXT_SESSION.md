# NEXT SESSION — orientation (rewritten at the 14z-142 CLOSE, 2026-09-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE ORDER OF WORK IS THE MAINTAINER'S (2026-09-06): THE HARNESS, THEN LIVING DOCS, THEN THE OPEN ITEMS

*"I need the generic reusable test harness and the living documentation
effort. After that we'll tackle the open items lined up."* **The harness and
its skill are DONE (14z-135..139). LIVING DOCS: L1 and L4 landed 14z-140, L2
landed 14z-141, and L3 — the last slice — is HALF LANDED: its framework
shipped 14z-142 and its atlas ROM tier finishes next.**

## L3 STEP 3 IS NEXT — no STOP left; the rulings are in

All seven decisions are settled (§11.7, four ruled 2026-09-07 and three taken
as defaults), so **this one is EXECUTION, not a scoping beat.** The record is
`docs/project/living_docs_scope.md` §11 — §11.2 the census, §11.3 the six
findings, §11.5 the seed set, §11.9 the sequencing. Step 3:

1. **Seed checks 9-15** — `id_space.md`'s select-commit site `PRG:0x020A80`
   and the CPU picker, the attract table `PRG:0x005C08`; `select_screen.md`'s
   `PRG:0x020A98` and tables A/B (`PRG:0x0211D4` / `PRG:0x0211E4`);
   `sprite_lists.md`'s drawer entries and a list terminator bit;
   `venue_assets.md`'s `PRG:0x38C198` (32 longs) and the mugshot/name strides.
   All fifteen claims were verified PRESENT in the documents at the 14z-142
   opener, so none needs an atlas fix first — but re-read each before quoting.
2. **`--uncovered`'s listing** recorded in §11 as the next-work list.
3. **The frozen covered set** `tests/expected/checkdocs_rom_covered.tsv` with
   its `PROVENANCE.md` row (evidence class `derived`) — a dropped check or
   address FAILs, growth re-freezes.
4. **The [VSP-13] grep** for §2.3's "No tool re-derives an atlas claim from the
   decrypted image" (S1) and `atlas/README.md`'s "this is the only place it is
   checked" (S4), then §4's L3 row and §11's STATUS to LANDED, the HANDOFF row
   amended, static tier ALONE, close.

## WHAT 14z-142 LEFT THE NEXT SITTING

- **`tools/checkdocs_rom.py` is live**: 8 checks, 9 table controls, `NOTE:
  checkdocs_rom.coverage 13/346`. A check QUOTES its claim (`says()`) and
  DERIVES the fact; a reworded document is a STALE verdict, never a silent
  pass. Add a check by writing it — **coverage cannot be grown automatically**
  (of 36 atlas instruction spans, ONE sits in a paragraph naming exactly one
  address and 27 name none, so the pairing is prose).
- **`PARAPHRASE` is a declared, printed class.** When an atlas sentence is a
  faithful SUMMARY rather than a transcription — the palette blitter's `or.l
  #$F000F000` against the image's `or.l d0,(a1)+` — the check asserts the
  literal fact it summarises. Never silently skipped; a must-fire control
  perturbs a paraphrase's literal fact.
- **All three sets are read** (ruled): `decrypt_view` is set-generic, and the
  atlas's spine is a three-set comparison table.
- **The atlas is corrected BEFORE a check is written against it**, in its own
  commit — the order S3 requires. It happened once already: `id_space.md`'s
  `PRG:0x04FFA8` range claim had an unstated slot-`0x8` exception.
- **A classifier over prose lies quietly** (both gotchas of this session): 68k
  mnemonics are English words, so scope to code spans and demand operand
  syntax; and `\|` is a literal pipe to `grep -E`, which made six present
  claims read as missing.

## OPEN, IN ORDER

1. **L3 step 3** — the atlas ROM tier, then the slice lands and the whole
   living-docs effort is delivered in all four forms.
2. Then the open items below.

## OPEN ITEMS

Unchanged: `PRG:0x028D50` carries THREE names (`effect_map_5051` in
`huitzil.toml`, `hit_class_props_ext_hi/_lo` in `donovan.toml`, and the
guard-MASH RNG mask table at `ram.md` line 156 — mizuumi's Tech-Hit Chance
Tables); establishing which is right is a measurement on a gameplay surface,
so the call is the maintainer's ([VSP-10]). Also: the deferred
`audit_mask_window_ff42a2` ruling (deprecated or case-specific),
`test_header_defaults` and the positional `[name]` default,
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
