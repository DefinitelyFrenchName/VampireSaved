# NEXT SESSION — orientation (rewritten at the 14z-145 CLOSE, 2026-09-10)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THREE OPEN ITEMS CLOSED (1, 2, 4 of the list, in the maintainer's order). NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release; nothing shipped changed this session. Static strict green at every
commit; the new emulator gates ran and reproduced. All commits on `main`,
**check `git status -sb` for the push state** (14z-144's opener said "NOT
pushed" of commits that were).

- **Item 1 — `test_freeze_artifacts_current` section 4** reads
  `patch_index.md`'s registration cells; it found the four track rows FOUR
  freezes stale (last moved at 14z-119) on the day it was written.
- **Item 2 — `PRG:0x028D50`**: all three names are right; two tables overlap
  by Capcom's own layout (the reaction byte map's entries 0x50-0x53 ARE the
  guard-mash mask table's longword 0, which the pre-incremented count never
  indexes). Measured in-emulator: `tests/audit_guard_mask_reads.sh`.
- **Item 4 — the aerial cross-check**: a2 has TWO aerial slot sets
  (`0x12-0x17` neutral jump, `0x18-0x1D` forward jump), measured on all 15
  characters (`tests/test_vanilla_aerial_join.sh`); the workbook's rows for
  the split moves are the forward variant and had been joined to the neutral
  chain. BI/BU/FE/VI's active and damage columns are EXACT now.

## THE SECOND LIST, ALSO CLOSED (the maintainer's "4 first open items", in order)

- **The tenants' forward-jump set** — measured: Donovan's and Huitzil's `0x18-0x1d`
  alias their neutral chains; Pyron's `0x18` is a distinct LP chain his forward jump
  does not enter (`test_move_naming` parts 14/6/10).
- **The Phobos ±1 residue** — root-caused: the defense-curve row the victim's id
  selects, swapped for 0x10/0x13 by the 2026-08-14 ruling, retuned for Sasquatch
  between generations (`tests/audit_defense_row_residue.sh`).
- **Zabel's `0x18-0x1D`** are his D+button aerials (`J.2x`, now joined); **Anakaris**
  has a private jump handler at `PRG:0x02678C` (his hover); Aulbath's `J.2HK` is
  `a2:0x51`. The aerial gate measures THREE directions now (270 rows).
- **Bishamon's 5MK startup** — the workbook's, not ours: node 0 spends the 5
  engine ticks its byte says (`test_tick_durations`, BI standing leg, per node).

## START HERE — what remains

- **Small residues left by the above, all named:** one Zabel `J.2x` gauge cell
  (−6, `ZA gauge_hit` 23/24); Anakaris's D+button chain `a:0x36` unnamed; Pyron's
  distinct `0x18` unentered; BU/FE/LI's remaining single-cell startup/white
  outliers on the cross-check page.
- **Zabel j.LK proximity guard** — its own session: a LEGACY patch, so its own
  expectation class and build flag, a recording FIRST ([VSP-20]), archaeology
  before theory ([VSP-14]).
- **NEW, from item 4 — the TENANTS' forward-jump set.** `engine_internals`
  said Donovan's ids `0x18-0x1d` are "entered by nothing" from a naming rig
  that tried GROUND inputs only; on every vanilla character that range is the
  forward-jump attack set. Add a forward-jump part to `tools/name_moves.py`
  for the three tenants (the tenant pages label `0x12-0x17` "jumping" and
  say nothing of `0x18-0x1D`). One rig, three characters, ~10 minutes.
- **NEW, from item 4 — two vanilla facts with an open edge.** Zabel's forward
  jump enters his NEUTRAL set although his `0x1B-0x1D` hold 18/12-frame
  no-recovery chains — what enters those is unmeasured. Anakaris's neutral
  jump is a hover that takes no normal — declared and asserted, not
  explained. And BI's startup column stays INCONSISTENT 17/18 (one move,
  spread +0..+1).
- **The must-fire run-time contract (step two) — RULED in shape 2026-09-10, waits on
  BBX's R10 for the line and env name.** Step one (`test_must_fire_census`) is in;
  the ten header-only gates are the named debt. When R10 settles: executable
  controls (`CONTROL=<name> gate` must FAIL), identity as the acceptance bar,
  no fourth verdict. STATE "Decisions pending" has the four points.
- Smaller: the deferred `audit_mask_window_ff42a2` deprecated-vs-case-specific
  ruling; `release/merged-m15` never packaged; #112 option (B) kept open; the
  living-docs generalisation (ruled, not scheduled).

## FIVE TRAPS PAID FOR HERE — read before the next rig or freeze

1. **A Lua `DUMPS` read through a read-watched range IS a watched read.** It
   logs one hit at dump-frame+1 with the CPU's incidental PC; take the dump
   inside the window the reducer discards (`docs/platform/gotchas.md`). The
   watchpoint's PC is the POST-instruction one.
2. **"The first new chain after the event" is the JUMP when the recipe jumps
   first.** Observe from the button window; the must-fire control (a swapped
   table must differ) is what refused the vacuous 180-row freeze.
3. **A table-a chain with no terminator walks into a2** — a first-seen node
   map mislabels the normal the game entered (AU `a:0x34`). The rig's map
   walks a2 before a; the standing and crouching tables were re-proven.
4. **Which variant a community row documents is a fact about the ROW, not
   about which of our chains fits.** A blanket "the workbook row is the
   forward one" put ZA and LI into INCONSISTENT; the answer came from the
   corpus's own move lists (`FORWARD_ROWS`), never from the numbers
   ([VSP-166]).
5. **A COMMENT edit to a manifest moves the charmap pages** — they record the
   manifest file's SHA-1. Regenerate per `test_charmap_current`'s own
   instruction; the review diff must be the hash lines only.

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited** ([MSC-54]). **The static tier is never run
beside another gate run in this tree.**
