# NEXT SESSION — orientation (written at the close of 14z-82, 2026-08-12)

> ## START HERE
>
> **THE MERGED HUITZIL VEC3 IS FIXED AND F2 IS FIXED — both measured
> through the full ladder.** Per-tenant TYPE NUMBERS shipped
> (maintainer-decided at plan review: first resolver keeps originals):
> non-first tenants' stamps are rewritten at build time from a FROZEN
> census and the union grows per-tenant entries into each tenant's OWN
> copy. Both former Huitzil crashers are guard-clean over full replays;
> donovan/12_vs_cpu (the withdrawn-design killer) is guard-clean; all
> four frozen fingerprints bit-exact throughout; leg (a) 13/14 ratified
> classes VERBATIM. The merged shim now serves BOTH declaring tenants
> (per-owner handler exits, tripwire fall-through; pyron direct by
> decision).
>
> **FIRST PRIORITY: Pyron's f7997 vec3 — now with a named route and a
> measured elimination.** Crash-time history (GUARD_PROBE_HIST fires
> from the guard's crash handler now): vanilla dispatcher 0x1A77E →
> `0x1A790 move.b (2,A6),d0` → byte map 0x1A888 → word table → computed
> jmp → garbage → vec3 on odd $FF31B5. A `b@(a6+2) >= 0x72` probe at the
> mapper recorded **ZERO hits** while the crash fired identically — NOT
> the type-numbering class, and not a census gap. What's implicated:
> A3 = 0x49bAEA inside PYRON'S OWN wide_ext feeding that vanilla path,
> and the fault address = $FF310A + 0xAB (an ODD table-derived offset
> into a RAM record) — the shape of a pyron-placed data/table defect
> (data_in_code / pcrel / placement class), one level removed. Start
> from build/gate_failures/merged1_b_70_pyron_mash.log; the
> single-tenant pyron20 build runs this replay CLEAN, so diff the legs
> (index_watch / GUARD watches on the $FF310A record chain; what fills
> its +0xAB-ish field, and from which placed table?).

## The state in one paragraph

`build/merged1` (rebuilt by every audit run — do NOT pin its fingerprint;
591 ops; gfx-skipped LEGACY-ONLY instrument, never playtest) carries both
14z-82 fixes. The one leg-(a) deviation is still `04_select_fuzz`'s extra
deterministic flicker frame 2005 — HELD un-ratified per the maintainer's
standing decision, but its mechanism is now NAMED: $FF0460 is the sound
driver's record-pointer spill (writer PRG:0x0011E2; scripted lock
`tests/audit_ff0460_writer.sh`; atlas row added), and the flicker is a
mid-scan sample — the ratified hook-flicker family. Leg (b): huitzil
70/83 guard-clean, donovan 12/20 guard-clean (20 re-converges 890..3667),
pyron 72 guard-clean, pyron 70 = f7997 (above).

## Then, in order

2. **The 04/2005 ratification decision** (maintainer): the whole merged
   flicker/window table wants re-measuring and ratifying once f7997 is
   fixed — the mechanism input is ready (named owner, scripted audit).
3. **Then the gfx half** (M3b Phase 3) and the tenant batteries on a
   merged build — unchanged from 14z-80's list, now behind ONE remaining
   crash instead of two.
4. The 0x54470 family (types 59-75) stays FIRST-WINS/deferred, but its
   measurement is attached: the frozen inventory maps its stamps, and
   the embedded TRUNCATED walker copy at src 0x5C602 (inside all three
   tenants' spans, table cut at every region end) is a named hazard for
   any future renumbering THERE. Un-defer only on measurement.

## New instruments this session (all in the suite)

```sh
tests/test_type_stamp_census.sh     # ~5 s: static census vs the frozen
                                    # inventory (build/manifest/
                                    # type_stamps.toml); 2 verdict controls
tests/audit_type_writes.sh          # ~8 min: dynamic writer-PC census on
                                    # the ground-truth builds (run BEFORE
                                    # trusting any renumber-path change)
tests/audit_type_dispatch_range.sh  # ~8 min: merged build — zero
                                    # original-range dispatches on later
                                    # tenants' replays; renumbered live
tests/audit_ff0460_writer.sh        # ~1 min: the $FF0460 owner lock
```
`GUARD_PROBE_HIST` now also dumps history at CRASH time (replay_guard);
`tests/lua/type_write_census.lua` is the filtered pool-write tap.

## Still open from earlier sessions, unchanged

- Phobos' own palette-seq block (KNOWN-OPEN RED on
  `tests/test_variant_dispatch.sh`, table 0x02a8a4 row 0x10).
- Pyron's Zodiac Fire has no rig (guard-cancel only).
- `80_pyron_cosmo_pairsweep.rpl` resets at f4840 — independent, low.
- The three NEW select medallions: polish.
- `region_space` rows on the manifests — re-freeze, maintainer's call.
- Op-tagging so `test_shared_writes.sh` can name what a new write is.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/test_m3a_reproducible.sh             # ~4 min, all four fingerprints
tests/test_tenant_loop.sh                  # ~17 s, the merge gate (437/591)
tests/audit_merged_vec3.sh                 # ~4 min: GREEN since 14z-82
tests/audit_merged_legacy.sh               # ~45 min: rebuilds build/merged1 +
                                           # the whole two-leg measurement
                                           # (fails BY DESIGN on 04's held
                                           # inventory + pyron f7997)
```
