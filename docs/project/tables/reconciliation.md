# R1 reconciliation — vsav2 engine references resolved to vsavj

Human twin of `build/manifest/reconciliation.toml` (the machine map the
patch generator consumes; regenerate rows with `tools/reconcile_batch.py`,
hand rows are preserved). Update both in the same commit.

> **STATUS (14z-122, the documentation rationalization pass — its SPECIMEN):**
> LIVE reference; canonical home of HOW vs2 engine references are resolved to
> vsavj and the structural findings the map rests on. The machine map —
> `build/manifest/reconciliation.toml` — is the ledger of record for every
> row (its per-row `note` fields carry each row's evidence and fate); this
> page explains it. Chronology: `reconciliation_history.md`. Where this page
> and the toml disagree, the toml wins.

## Covers / does not cover

- Covers: the six resolution methods, row statuses and what consumes them,
  the map's measured shape, the structural findings and case law that govern
  new rows, the sound-row classes, what is still open.
- Does not cover: the patch MECHANISMS that consume rows
  (`docs/project/patch_index.md`); per-change byte detail
  (`docs/project/patch_notes.md`); the engine subsystems themselves
  (`docs/game/engine_internals.md`).

## How rows are produced (methods, in application order)

1. **pattern** — masked instruction-pattern search (operands wildcarded via
   scan_code_refs), window ladder 0x20-0x80. `pattern-1.00-unique` =
   verified.
2. **stub-deref** — `jmp abs.l`/`bra.w` stubs dereferenced to the real
   routine, which is then pattern-resolved (a matching vsavj stub is
   preferred when unique).
3. **callsite anchoring (veteran parallelism)** — the same engine routine is
   referenced from shared veteran/engine code present in BOTH games;
   each vsav2 reference site's context is pattern-matched in vsavj and the
   vsavj operand read out. Unanimous votes = verified.
4. **codebytes/databytes** — exact byte match for position-independent
   stubs / data blobs, unique-hit required.
5. **farm-helper matching** — predicate-farm entries (`lea (d16,PC),A3;
   bra.w common`) matched by their 8-byte parameter-block CONTENT (raw
   view — the blocks are data), since the farms differ in size between
   games and are pure PC-relative.
6. **hand rows** — individually verified (see notes in the toml), e.g. the
   bank delta rule with byte-identity, the allocator family map.


## The map at a glance (measured from the toml at 14z-122)

272 rows: **220 verified / 12 plausible / 40 open**. By kind: engine_data
146, engine_sub 81, sound_stub 15, sound_farm 13, stubbed_sound 6,
farm_port 5, bank_ref 5, patched_clone 1. `verified` rows drive the
generator; `plausible` rows require `--allow-plausible` (every shipping
build passes it — GitHub #43(b) reduced the delta to one row with zero
build effect); `open` rows become per-target planted-ILLEGAL tripwires
(`--tripwire-open`) whose fault PC names the unresolved target that fired
— `tests/audit_tripwire_reach.sh` and the guard corpus watch them
([M: audit_tripwire_reach.sh, 14z-93]).

## Structural findings the map rests on

- **THE ALLOCATOR -> POOL MAP, MEASURED (14z-93).** The six helpers
  `vs2 0x156D6 + k*0x16` / `vsavj 0x016F8E + k*0x16` each pop from their own
  free list; the pool BASE is not in the body, so it was measured at runtime
  (breakpoint after the `movea.w (a0)+,a4` pop, reading A4):

  | k | vs2 | vsavj | pool | `alloc_wrap`ped by all three tenants |
  |---|---|---|---|---|
  | 0 | `0x156d6` | `0x16f8e` | `$FF94xx` (projectile) | no |
  | 1 | `0x156ec` | `0x16fa4` | `$FFB4xx-$FFB6xx` | no |
  | 2 | `0x15702` | `0x16fba` | `$FFB8xx-$FFBFxx` | **yes** |
  | 3 | `0x15718` | `0x16fd0` | `$FFC8xx` | no |
  | 4 | `0x1572e` | `0x16fe6` | `$FFD4xx-$FFD6xx` | **yes** |
  | 5 | `0x15744` | `0x16ffc` | `$FFE4xx` | no |

  **Probe the pop at helper+0x10, not helper+0x0C** — +0x0C is inside the
  `movea.l (0x7966,A5),a0` and a breakpoint there never fires, reading as a
  clean zero (the mid-instruction dead-instrument trap, `docs/GOTCHAS.md`).
  Measured 14z-93: the wrong offset returned 0 hits over 4,000 frames and
  looked like "these allocators are never called".

- **Allocator/pool family (MUST map, never port):** vsav2 secondary-object
  pool helpers `0x156D6 + k*0x16` (count `A5+0x7A42+k`, free list
  `A5+0x79E6+4k`) correspond to vsavj `0x016F8E + k*0x16` (count
  `A5+0x79BE+k`, list `A5+0x7966+4k`). Pool-0 was independently verified by
  call-site anchoring. Allocators read the game's own RAM bookkeeping —
  a ported copy sees an empty pool forever.
- **Type-dispatch tables (obj_hook):** seven `movea.l (d8,PC,D0.w),A0`
  dispatch sites exist in both games; five have equal-sized tables, two are
  extended in vsav2 (59→76 at vsavj site 0x054470, 114→124 at 0x05E542) —
  the extras are the newcomers' secondary-object handlers. Handled by the
  extended-table engine hooks (see docs/project/patch_notes.md).
- **PC-relative reads are decrypted** (docs/GOTCHAS.md) — governs which
  view any engine table is read from.
- **Pool GEOMETRIES are identical in both games, pool-for-pool**
  ($FF9400/0x100/cat4, $FFB400/0x80/cat8, $FFB800/0x80/catC
  [+0x3C=0xFF seeded], $FFD400/0x80/cat14) — measured while decoding the
  companion spawn chain. Atlas rows: `docs/game/atlas/ram.md` "Projectiles".

## The damage pipeline twins (measured, session 10 + 14z-85f)

Located by the KO-write signature (`move.w #$FFFF,$50(a1); …,$52(a1)` —
two hits per game, positions parallel); vsavj's wrapper `0x189BA` is
instruction-for-instruction byte-parallel with vs2's `0x17330`. Every
`bsr` position votes:

| vs2 | vsavj | role |
|---|---|---|
| 0x17522 | 0x18B8C | per-char defense-scaling calc (5-bit id, 32B table) |
| 0x17422 | 0x18AB0 | damage post-process |
| 0x17B22 | 0x19128 | KO handler |
| 0x173DE | 0x18A6C | halve-damage helper |
| 0x17806 | 0x18E46 | (positional) |
| 0x175AE | 0x18C08 | damage apply |
| 0x28A6A | 0x29738 | the OBJECT-HIT damage applier (jsr-scaler signature, unique both images) |

Plus five engine_data rows for the scaler-chain tables (attack
`0xD22BE↔0xB8140`, defense `0xD2ABE↔0xB8940`, final maps
`0xD32DE↔0xB9140` / `0xD435E↔0xBA1C0`, low-HP `0xD6E1E↔0xBCC80`).
Consequence, still the law: ported char code CALLS vsavj's own damage
machinery (the allocator rule — engine subsystems reading the game's own
RAM/tables are MAPPED, never ported), so a tenant scales by vsavj's
defense table, the correct superset semantics. NOTE the applier's
A5-relative staging displacements are same-value class #4 — corrected by
each tenant's `[[port_patch]]` rows, never by a jsr reconciliation
([VSP-82]).

## Sound rows — three classes (statuses live in the toml's own notes)

The old standing instruction "RESTORE AT M5" is SUPERSEDED: M5 shipped at
14z-86 (authored vsavj voice ids + the facing-alias thunk), and each row's
`note` in the toml records its actual fate:

1. **RESTORED (14z-86)** — `sound_stub` rows remapped to authored ids
   ("M5 VOICE RESTORED"), e.g. vs2 sfx `0x73c` → authored `0x84`.
2. **KEPT SILENT for a MEASURED reason** — same-id keys different content,
   or the sample is absent from vsav's ROMs ("M5 KEPT SILENT (14z-52)",
   evidence `docs/project/m5/don_id_plan.json`); restoring would play the
   WRONG sound. Revisit only with ported samples.
3. **The per-node sfx helper family** — where a character's whole move
   sound lives; enabled per tenant by the `[[sound_table]]` records row,
   one manifest field, never separately ([VSP-44]).

## Twin-choice case law

- **A byte-identical body appearing twice is a coin flip until the CALLERS
  vote**: vs2 `0x494de` (the 32-bit divide helper behind GitHub #91)
  matches vsavj `0x47fb6` AND `0x646de`; caller counts 10 / 0 (vs2: 11)
  and monotone caller correspondence decide it. A pure leaf cannot alter
  behaviour either way — the live copy is chosen for provenance
  ([M: audit_tripwire_reach.sh, 14z-93]).
- **Sibling twins can differ by ONE hoisted instruction** — `patched_clone`
  is the kind for that shape ([VSP-52]).
- **A per-value table's ANCHOR is not its table base** — read the anchor
  out of the consumer ([VSP-51]-family; the stage-banner instance is
  `docs/project/gotchas.md`).
- **Generic-handler alignment and site-twin interpolation** (the 14z-66
  air-system methods) resolve content-drifted escape targets; their rows
  are consumed by `[[pcrel_escape_fix]]` trampolines, never operand
  rewrites ([VSP-59]).

## What is NOT known

- **40 open rows** — each is a planted tripwire by design; the watchers are
  `tests/audit_tripwire_reach.sh` and `tests/audit_guard_corpus.sh`. A
  tripwire that fires in play is a rule-6 stop (GitHub #91 is the case
  study, in the history).
- **`0x269AC`** (operand-heavy float-body helper) — the one 14z-66 escape
  row never resolved; tripwired.
- **The 12 plausible rows** — ride `--allow-plausible`; promoting one is a
  measurement (the #43 matcher), not an edit.

## History

`reconciliation_history.md` — every session-dated block this file once
carried (sessions 4-13, 14z-65/66/85f/93), verbatim, with the frontier
language of its day. The eliminations there stay valid; the statuses do
not — this page and the toml carry the current ones.
