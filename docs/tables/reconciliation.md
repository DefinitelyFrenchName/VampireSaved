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

## Companion (Anita) chain — resolved mechanism (session 5)

The full spawn chain now decodes end-to-end:

1. Donovan init hook (ported, x088512 zone) allocates a pool-2 slot
   ($FFB800 family, 0x80 stride — GEOMETRIES ARE IDENTICAL in both games,
   pool-for-pool: $FF9400/0x100/cat4, $FFB400/0x80/cat8, $FFB800/0x80/catC
   [+0x3C=0xFF seeded], $FFD400/0x80/cat14) and writes the spawn record
   (header long [01,00,type,sub] at +0, owner at +0x30/+0x32, id at +0x39).
   The allocator FAMILY is mapped (vsav2 0x156D6+k*0x16 ↔ vsavj
   0x016F8E+k*0x16), including pool 4 (0x1572E ↔ 0x016FE6).
2. Creation handler (type 116 via the extended table-3 hook) state 0 loads
   Anita's anim table via `movea.l #$2B8060,A0` — the LAST unrelocated
   piece: a self-relative asset blob (table + scripts + sprite tables) with
   vhunt2 twin 0x2A4504 and per-sub-blob micro-shifts (−0x13B5C/−0x13B70
   family). Chunk-BFS over the pointer graph bounds her REACHABLE assets
   at ~44KB (0x2B8060-0x2C3100 + 0x2D6D00 straggler).
3. Class registration: vs2 inserted class 7 into dispatch-site-1 (8 cases
   vs vsavj's 7); site 2 = classes 7-10 (vsavj) / 8-11 (vs2). Class
   machinery: enqueue cases at 0x015618-table, pumps at 0x01ACAA+ (counts
   $FFF9C9+K, heads $FFF992+4K).
4. The +0x3C byte = render/update MODE (0xFF = direct-emit via +0x1C anim;
   managed modes 0-4 via a 5-case dispatch); the pump path that crashed
   dereferences +0x1C unconditionally in emit mode.

REMAINING WORK (space-constrained): extract Anita's 44KB asset graph as
self-pointer data regions and repack the holes — the FULL port needs
~332KB of the 336.6KB free (hole A 258K + hole B 78K): plan = drop the
stage-1 scaffolding ops from stage-4+ builds (~10KB), assign hitbox +
hitbox_proj + aux0_0-3 + Anita to hole B (~78K), everything else to hole A
(~253K). Margins are <4KB — placement needs the per-region hole hints in
donovan.toml. The port_patch subclass remap (0xE→0xC) becomes unnecessary
once she registers via her real machinery — REVERT it when the class-7
enqueue path is synthesized (site-1 word-table thunk design in this doc's
history) or keep class-6 if behavior gates pass.
