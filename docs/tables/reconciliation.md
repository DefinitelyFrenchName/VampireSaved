# R1 reconciliation — vsav2 engine references resolved to vsavj

Human twin of `build/manifest/reconciliation.toml` (the machine map the
patch generator consumes; regenerate rows with `tools/reconcile_batch.py`,
hand rows are preserved). Update both in the same commit.

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

Statuses: `verified` rows are used by the generator; `plausible` only with
`--allow-plausible` (experiment builds); `open` rows route to per-target
planted-ILLEGAL TRIPWIRES (`--tripwire-open`) whose fault PC names exactly
which unresolved target actually fires. The stage-4 behavior gates
(vsav2-as-oracle field comparison, dual-emulator agreement, crash guard)
are the backstop for wrong mappings.

## Structural findings the map rests on

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
  extended-table engine hooks (see docs/patch_notes.md).
- **PC-relative reads are decrypted** (docs/GOTCHAS.md) — governs which
  view any engine table is read from.

## OPEN FRONTIER (stage 4, end of session 4)

The companion-object (Anita) spawn chain: Donovan's init hook
(vsav2-only code at 0x8A5A8-zone, ported source-only) allocates pool nodes
and writes a spawn record in **VS2's node protocol**; vsavj's consumer
(node/category dispatch at `PRG:0x0155D0-0x015650`, jump table on
`(0x9,A6)`) crashes on it (vec3, odd ptr 0x17685 via a corrupted list
head). Root cause to resolve next: the **pool-index correspondence is not
identity** (vsav2 pools 2/4 map to which vsavj pools?) and the node field
layout may differ. All instruments (guard traces, write watches, native
vsav2 ground-truth replay `R×2` pick) are in place; see STATE.md.
