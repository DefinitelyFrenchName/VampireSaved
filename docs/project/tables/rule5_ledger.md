# Rule-5 migration ledger — what moved out of a manifest and into a table, session by session

CLAUDE.md rule 5: *"Behavioral values live in documented tables, not in code."*
`tools/audit_rule5.py` measures how far that holds; this file records every
step taken toward it. One row per session, newest last. The numbers come from
the tool's own NOTE lines, never from memory.

**What a migration IS here (option B, maintainer-ruled 2026-09-07).** The
value STAYS in the manifest and gains a documented table row carrying its
provenance, with a `# in-table: tables/<doc>.md` pointer joining the two; a
check asserts the table really carries the value, so the pair cannot drift.
The build keeps ONE source of truth and a documentation edit can never move a
shipped ROM byte. The rejected alternative (A) — the build reading the table —
would have made prose load-bearing for the artifact; it is not foreclosed, and
would be its own decision, per value, with its own gate.

**The provenance vocabulary** a migrated row must use, one of:
`measured 14z-N (rig)` · `derived (tool)` · `testimony (who, date)` ·
`ruled (date)`.

## The ledger

| session | column | in-table | baked | what moved | rulings cited |
|---|---|---|---|---|---|
| 14z-141 | gameplay | 0 → 0 | 202 | the census opens; nothing migrated yet. The baseline is honest: no manifest value carried a table pointer, so IN-TABLE is 0 by measurement, not by assumption | the four L2 rulings of 2026-09-07 (`living_docs_scope.md` §10.8) |
| 14z-141 | code | 0 → 0 | 30 | module-level generator constants, counted for the first time | ruling 4: option (a), the blind spot stated |
| 14z-141 | gameplay | 0 → 15 | 217 → 202 | THE FIRST MIGRATION: the select wheel's five INBOUND edges (`edges_in`, 15 values) into [`select_wheel.md`](select_wheel.md), each row carrying the ruling behind it. The manifest keeps the values and gains a `_in_table` pointer per edge; the check asserts the table really carries them. The frozen inventory did not grow — the 15 went straight to IN-TABLE | ruled 2026-08-05 ("vanilla wins ties", the three `0x0B` edges kept for UX); measured 14z-60o (`tools/select_wheel.py`) |
| 14z-143 | gameplay | 15 → 15 | 202 → 203 | **A GROWTH, declared.** `pyron.toml` gains `[[data_port]] pyron_capture_keyframes` (Pyron's capture row `0x11`, patch_notes 14z-143) and with it the 144th `only_variant_slot = true`. NOT migrated: it is a build-GATE flag — it selects which track a row applies to, not a value a player feels — and 143 identical instances are already baked, so a table row for this one would be inconsistent and would make nothing reviewable. Re-frozen with `--allow-growth`, the reason in the file | ruled 2026-09-07 (option B, migration keeps the value); the port itself maintainer-selected 2026-09-08 |
| 14z-170 | gameplay | 15 → 15 | 203 → 209 | **A GROWTH, declared.** The M19 fixes (patch_notes 14z-170): the four `[[data_port]]` defense rows (`huitzil.toml`, `donovan.toml` — each tenant's curve row and rally-threshold word) carry `only_variant_slot = true`, instances 145-148; and Phobos's two trap `[[region_fix]]` rows carry the NEW key `unless_composed = "donovan"` (the class-0x52 fix scoped S1), classified gameplay beside `only_variant_slot` in `tools/audit_rule5.py`: it selects which COMPOSITION a row applies to, not a value a player feels. NOT migrated, for the 14z-143 reason. Re-frozen with `--allow-growth`, the reason in the file | the four fixes ruled 2026-09-18 (`DECISIONS_HISTORY.md`); S1 ruled 2026-09-18 |

`fact` is not frozen and has no ledger column: ordinary port work adds
addresses and hex every session, so a shrink-only signal over it would fire on
every commit. It is reported as a NOTE-class number
(`NOTE: rule5.fact …`) so it cannot rot silently either.
