# M3b — the roster tenants: multi-tenant machinery + Huitzil/Phobos (0x10) + Pyron (0x11)

Written 2026-08-07 (session 14z-65 open), from a three-way recon over the
generator/build machinery, the docs corpus, and the STATE history, plus two
baseline extraction dry-runs. This is the working plan; STATE.md carries
progress and the decisions-pending register. Prior facts are cited, not
restated — follow the pointers.

## Mission

Both remaining vs2 newcomers selectable and correct in ONE WIDE build,
alongside Donovan, with donovan-m3a semantics preserved: every tenant at its
native id, host slots untouched, stock track unchanged, superset invariant
holding on the frozen masked bases (extended only by measured, per-slot
windows).

Deliverable shape: a build with three `[[tenant]]` rows whose single-tenant
degenerate case reproduces **donovan-m3a (4b7d0dc7) bit-exact** — the frozen
reference stays reproducible from the tree at every intermediate commit
(the M3a lesson: a reference that cannot be rebuilt is not a reference).

## What recon established (2026-08-07)

- **Placeholders are real.** Wheel cells, TABLE B rows, highlight bases,
  ring rows, medallion art (group C bank 5) and palette rows (Phobos 0x19,
  Pyron 0x1A) are shipped and maintainer-ratified in donovan-m3a
  (`build/manifest/wheel_layout_proposed.json`; docs/game/atlas/select_screen.md).
- **Locations are pinned** (docs/game/atlas/character_tables.md:103-104,174-175,
  210-211): Huitzil vsav2 handler 0x057450 / anim 0x245872 / hitbox
  0x0C4370; Pyron 0x059424 / 0x264086 / 0x0C75FE; vhunt2 twins recorded.
- **Space:** hole_a is full, hole_b has 272 bytes; both new tenants live
  entirely in `wide_ext` ($400010-$5FFFFF, 2 MB, ~24 KiB used). At ~340 KiB
  per character the program side is comfortable. The REAL constraints are
  group C bank 4 tile-code coexistence (undesigned — see Phase 3) and
  QSound (16 MB is MAME's hard ceiling; three voice banks vs the added
  8 MB is unsized — see Watch items).
- **The generator refuses >1 tenant by design** (gen_donovan_patch.py:87-93,
  "M3 Phase 3"). Everything downstream closes over ONE `dst_slot`. The
  gating vocabulary (only_base_slot / only_variant_slot / new_hex_variant /
  slot_table / TT-substitution) is id-parameterized but single-valued.
- **Merge-of-independent-patches is unsound; single-process N-tenant loop
  is the design** (decided by analysis, recorded here):
  1. `alloc()` verifies destination bytes against PRISTINE vsavj
     (gen:342-345) — a second independent run cannot see the first run's
     allocations;
  2. `patch_prg.py:82-101` applies ops with NO overlap detection — merge
     collisions are silent;
  3. the engine hooks (obj_hook/state_hook/reaction_hook, the wheel record
     repoint, the bank-5 flip, 20 site_thunks) each rewrite one site —
     replacement-shaped, not additive; two patches = last write wins.
- **obj_hook is already union-shaped** (gen:1460-1483): the extended table
  is [vanilla] + [every vs2 extra], each entry resolved independently,
  tripwired when unported. Huitzil/Pyron's types 64-75 (+ companion types
  121-123, vs2 handler addresses recorded in
  build/m5_wide/patch/patch_notes_fragment.md:213-244) resolve the moment
  their roots are extracted. state_hook's five no-op stubs (0xBC-0xC8) and
  reaction_hook widen the same way — by union, at their one site.
- **Extractor is de-facto Donovan-tuned in exactly three places:**
  the char-id immediate scan matches literal `0x0013`
  (scan_code_refs.py:103-110, gen:801-805 rewrites only `00 13`);
  `DONOVAN_ANCHORS` asserts only for char 0x13 (extract_char.py:61-62,
  323-327) so other chars run un-anchored; and the code-region similarity
  scan fails for both new chars (measured 2026-08-07, scratch logs):
  Huitzil's region ends +0x400 with dispatch targets to +0x46a, Pyron's
  +0x200 with targets to +0x1fa2. Note Pyron's scan STARTS at 0x0574C0 —
  inside the Huitzil-adjacent appended zone, far from his 0x059424 handler
  — so H/P code interleaves with the shared newcomer stubs Donovan already
  ports (his `code` region is 0x059490+0x3200). Shared-span handling is
  load-bearing, not an edge case.
- **Huitzil has the VS2/VH2 Start-hold flavor fork; Pyron does not**
  (docs/game/atlas/character_tables.md:229-233, community-confirmed). The
  Donovan wiring (`[init_shim] flavor_disp=0x3C2`, default 0x01=VS2,
  Start-mask $FF8060) is the template.
- **"Selectable is not fightable"**: the arcade opponent ladder (order
  list at RAM a5-0x61B8, length $138(a5)) and the VS-screen palette pool
  (PRG:0x3A3CA0 + id*32) have NO tenant support — including Donovan, whose
  VS-pool entry is a placeholder grey ramp (docs/game/atlas/id_space.md:265-276).
- **Masked basis discipline for the new tenants is pre-written**
  (docs/game/atlas/ram.md:31, STATE 2526-2531): any select palette-block change
  surfaces in the fade-staging family ($FF3F02 + row*0x20) — EXTEND the
  window with measured slots per edited row, never pre-widen, and re-run
  `tests/audit_mask_window_ff4182.sh` first.

## Phases

Ordering rule: machinery refactors land only with the bit-exactness gate
green (Phase 0); content lands only through the refactored machinery.

### Phase 0 — safety rails (before any refactor)

1. **Op-overlap assertion.** patch_prg.py (or generator emit) hard-fails
   when two ops write one byte, with named ops. Ground-truth test with a
   synthetic overlapping pair + a clean control
   (`tests/test_patch_overlap.sh`). This converts every collision class in
   this plan from silent corruption into a build error. Do first.
2. **Reproducibility gate.** A scripted check that the tree still rebuilds
   donovan-m3a `4b7d0dc7` (WIDE) and m5_stock `6c93cfa8` bit-exact
   (`tests/test_m3a_reproducible.sh`, fingerprint compare only — cheap).
   Runs after every machinery commit in this milestone.

### Phase 1 — de-Donovanize extraction (unblocks everything)

1. Parameterize the char-id immediate scan on `src_char`
   (scan_code_refs.py + the gen rewrite side). Without it a 0x10/0x11
   tenant ships vs2 ids inside ported code, silently.
2. Per-char anchors: move DONOVAN_ANCHORS into a per-char table (atlas has
   the vsav2/vhunt2 values for all three) so every tenant extraction is
   anchor-asserted.
3. Diagnose and fix the code-region similarity scan for 0x10/0x11.
   First measurement: is the early stop genuine vs2↔vh2 behavioral
   divergence (balance forks — feeds the flavor-policy decision) or a
   tooling artifact (wrong region seed — Pyron's scan starting at 0x0574C0
   argues tooling)? Instrument, then fix. The extractor's oracle doctrine
   (every sibling diff byte classifies as pointer-under-shift) must either
   hold for H/P or gain a measured, documented exception class.
4. R1 root census per tenant (the Donovan sessions 4-6 loop): run the
   guarded build/probe cycle until each tenant's extra-roots list closes.
   Expect large overlap with Donovan's shared-stub roots and the recorded
   handler addresses for types 64-75 / 121-123.
   Exit gate: extraction completes for 0x10 and 0x11 with 0 UNRESOLVED,
   oracle-clean; scripted as tests.

### Phase 2 — multi-tenant generator (one process, N tenants)

1. Tenant loop: per-tenant record replaces the `dst_slot`/`mirror`
   module scalars; per-tenant sections (regions/palettes/value rows/
   data_port/aux_poke/port_patch/code_word/select_records/win_pal) iterate;
   `spaces`/`ops`/fragments stay process-global (one cursor, one ledger).
2. Region identity: key regions by `(src_set, src_addr, len)`; a shared
   span (the newcomer stubs, shared support zones) is placed ONCE and all
   tenants' relocations resolve through the shared placement. Fixes the
   name-collision problem (`x{addr}` names) and the PC-reach constraints in
   one move.
3. Engine-extension manifest: hoist obj_hook ×2 / state_hook /
   reaction_hook out of the per-tenant manifest into a shared
   `build/manifest/engine_ext.toml`, emitted ONCE per build as the union
   over tenants (+ tripwires for the still-unported). seq_ids and reaction
   cases become per-tenant contributions merged at emit.
4. site_thunk gating: replace single `cmpi.b #TT` gates with id-dispatched
   forms — a generated 32-row table where the site is semantically a
   per-char lookup (matches the engine's own convention), a compare-chain
   where it is genuinely a small set. Manifest declares bodies; generator
   owns gates. Same for win_pal_variant's rebase.
5. Per-tenant outputs: `tenant.json` et al become arrays (or per-tenant
   files) with the gfx/verify consumers updated in the same commit.
   Exit gate: the 3-tenant manifest with ONLY Donovan enabled reproduces
   4b7d0dc7 bit-exact; enabling a second tenant is additive under the
   overlap assertion; new dispatch/suite gates green.

### Phase 3 — gfx coexistence in group C (the named "new mechanism")

1. MEASURE first: H/P native tile-code ranges in vs2 (obj_records walk of
   their anim regions, as build_donovan.sh:123 does for Donovan) and their
   overlap with each other and with Donovan's bank-4 band (0x863F-0xC2EF
   band + 0xAD8F-0xEA3F/shelf layout). Decide from data:
   - if the three bands pack into bank 4's 0x10000 codes with per-tenant
     deltas → per-tenant sub-band allocator (promote build_gfx's `written`
     set to a cross-tenant tile allocator + collision gate);
   - else → grow group C (8 members, banks 6-7): build_wide_romset --gfx 8,
     gfx_tiles GROUP/bank_word extension, BOTH emulator descriptor patches
     (member-for-member identical — the standing rule), profile version
     bump per docs/project/cps2_wide.md governance.
   Estimate says packing fits (~50K of 64K codes for three tenants), so
   plan A unless measurement disagrees.
2. build_gfx_donovan.py → multi-tenant: per-tenant band/delta/bank from
   manifest (constants demoted), repeatable --tenant/--tiles, group-C pass
   chains over prior output like the group-A passes already do, cross-
   tenant tile-collision gate, one member-write at the end.
3. Driver: the hardcoded obj_records span (Donovan's anim table) becomes
   per-tenant from the extraction; same for select/HUD art anchors (free-
   pool allocation instead of hand-picked constants where possible).
   Exit gate: `test_wide_render_content.sh`-class pixel A/B for Donovan
   unchanged; per-tenant render gates for H/P once their content lands.

### Phase 4 — Huitzil (0x10) content

Through the new machinery only: his `[[tenant]]` row (+ extraction, R1
map, engine-hook contributions — his types among 64-75/121-123, his state
stubs upgraded to real vs2 shapes, his reaction ids), Start-hold flavor
wiring (Donovan template; decision D1 below), HUD rows (slot-table
parameterized aux_pokes + art anchors), win-pal sparse block rows,
select-records already placeholder-backed, palette-staging window
extension (measured per edited row), sprite/effect palette tables, sword/
accent-analog audit (his weapon rows unknown — measure). New replays per
CLAUDE.md §4 minimum coverage; dual-emulator gates; battery; playtest
cycles. Mirror-match and Donovan-vs-Huitzil interaction replays (first
ever tenant-vs-tenant coverage).

### Phase 5 — Pyron (0x11) content

Same shape minus the flavor fork. Extra attention: his medallion palette
row 0x1A carries the known 2P-sword-row residual — his content work is
the natural point to land a proper palette-row design if one emerges
(NEXT_SESSION parked item), else the residual stays documented. His
victim-side spark special-casing (GOTCHAS:601-604) and any companion-class
objects need the measured treatment Donovan's Anita got.

### Phase 6 — shared registries (all three tenants at once)

1. Arcade ladder: RE the ROM source of the opponent order list (work-RAM
   list is written from somewhere; find the writer), design the extension,
   author VS-pool palette entries at 0x3A3CA0-family for 0x10/0x11/0x13
   (Donovan's is placeholder grey today). Gameplay surface → decision D3.
2. Fold-site handling for 0x10/0x11 where inherit is wrong: their folds
   land on Bulleta/Demitri (more visible than Donovan's Victor case).
   The anim-number fold (0x3E40/0x4082, INHERIT ratified for Donovan)
   gets a playtest verdict per tenant; fallback B (relocate + widen) is
   pre-designed in STATE 5902-5910.
3. QSound sizing (see Watch items) feeds the M5-family sound work; not
   gated on this milestone but sized during it.

## Decisions pending (maintainer) — registered in STATE.md

- **D1 — Huitzil default flavor**: VS2 vs VH2 as the shipped default (the
  Start-hold selector then offers the other). Recommendation: VS2 default,
  identical to the ratified Donovan precedent and SPEC §3.
- **D2 — Pyron source version**, IF Phase 1 measurement shows real
  vs2↔vh2 behavioral divergence in his code (he has no Start-hold fork, so
  the shipped version is the only version). Recommendation: VS2 base per
  SPEC §3; revisit only if the measured delta list says the VH2 build
  fixed something.
- **D3 — arcade-ladder membership**: do the three tenants join the CPU
  opponent pool, and with what placement/weighting? Recommendation: yes,
  uniformly, once the mechanism is REd — but order/weighting is a feel
  decision and stays open until the mechanism is on the table.

## Watch items (measure early, not decisions yet)

- **QSound at scale**: size three voice banks against the profile's added
  8 MB before any sound work commits to option B (STATE 6191-6200: the
  16 MB ceiling is MAME's `device_rom_interface<24>`; overflow means
  exclusivity or banking, and option C is rejected and may not return).
- **Phobos palette row 0x19 2P case**: flagged unmeasured
  (docs/project/patch_notes.md:1633-1635); measure during Phase 4 select work.
- **The $130(a5) fold's deep-arcade ending gap**: still the one unmeasured
  flow; H/P venue work must not silently depend on it.
- **Wheel record budget word**: 85 covers 21 cells; any future growth
  re-opens the $FF811B skip-decision hazard (select_screen.md:434-440).
  No growth planned in M3b.

## Standing constraints (non-negotiable, from the freeze)

- Frozen censuses (accent-march 4 sites, mid-row 3 dests) fail loudly on
  growth; a new site anywhere is a stop-and-root-cause event.
- Sentinel CRCs 0xdec0de31..37 stay sentinels; audit_romset_identity gates
  every build.
- 0x2AD44 is the in-match palette funnel and must never be thunked.
- Reserved ids 0x12/0x18 are shipped-secret territory; `_cell()` and the
  id-resolution guards already refuse them — keep it that way.
- Every non-exact legacy class stays mechanism-attributed and frozen;
  reclassification needs measurement + maintainer sign-off.
