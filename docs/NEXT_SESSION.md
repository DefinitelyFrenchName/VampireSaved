# NEXT SESSION — orientation (written at the close of 14z-82b, 2026-08-12)

> ## START HERE
>
> **Two fixes this day, one adopted, one awaiting the maintainer.**
>
> **ADOPTED (14z-82, commit 33c2c70): the merged Huitzil vec3 + F2.**
> Per-tenant TYPE NUMBERS (first resolver keeps originals): both former
> Huitzil crashers guard-clean over full replays, donovan/12_vs_cpu
> guard-clean, leg (a) 13/14 ratified classes VERBATIM, all four frozen
> fingerprints bit-exact throughout. The merged shim now serves both
> declaring tenants (per-owner handler exits; pyron direct by decision).
>
> **AWAITING DECISION (14z-82b): the f7997 fix — and the crash was NEVER
> a merged defect.** Frozen pyron-m2 crashes at f7997 SOLO (measured; the
> leg-b harness used to bail before measuring the ref leg — fixed — and
> the covering soak builds stage 4, so the frozen artifact was never
> soaked). Mechanism: vsavj's projectile-pool hit sweep maps both
> colliding objects' TYPE bytes through one 64-entry byte map at
> `PRG:0x1A888` (seven callers); pyron's type-64 satellite landing a hit
> over-indexes it (map[64] = the following rts's 0x4E — the crash D0).
> vs2's sibling map has 80 entries. Huitzil spawns 68/72 into the same
> pool (exposed, unexercised). The fix is GENERATED
> (tools/gen_hitclass_map_thunk.py), gated
> (tests/test_hitclass_map_thunk.sh), and MEASURED on a probe build
> (tests/audit_hitclass_map_cost.sh): the 11,017-frame soak that crashes
> frozen pyron-m2 runs END-clean, legacy BIT-IDENTICAL over 30,284
> frames, fire census = legacy never enters the map at all.
> **Manifests deliberately untouched — adopting the row re-freezes
> huitzil + pyron (STATE Decisions pending, with a recommendation).**

## First priorities (in order)

1. **The maintainer's two 14z-82b decisions** (STATE Decisions pending):
   adopt `hitclass_map_extend` + re-freeze huitzil/pyron (recommended);
   and Donovan's map[61]/[62] zeros (keep, recommended). On adoption:
   add the row to both manifests (generate the hex with the tool, never
   hand-type), re-freeze fingerprints + registry rows + their masked
   legacy self-logs, re-run test_hitclass_map_thunk (its section 2 then
   locks the committed rows) and both tenants' batteries.
2. **The 04/2005 ratification** (maintainer): with BOTH leg-(b) crashes
   now explained/fixed, the merged flicker/window table can be
   re-measured and ratified; the 2005 mechanism is named ($FF0460 =
   sound-driver record-pointer spill; tests/audit_ff0460_writer.sh).
3. **Then the gfx half** (M3b Phase 3) and the tenant batteries on a
   merged build.
4. Deferred with measurements attached: the 0x54470 family's FIRST-WINS
   notes (frozen stamp map + the truncated embedded walker at 0x5C602);
   type 120 (no reachable stamp; first-wins + the dispatch-range gate).

## New instruments (14z-82 + 14z-82b, all in the suite)

```sh
tests/test_type_stamp_census.sh     # static census vs frozen inventory
tests/audit_type_writes.sh          # dynamic writer-PC census (~8 min)
tests/audit_type_dispatch_range.sh  # merged: zero original-range dispatches
tests/audit_ff0460_writer.sh        # the $FF0460 owner lock (~1 min)
tests/test_hitclass_map_thunk.sh    # 14z-82b fix reconstruction gate (~2 s)
tests/audit_hitclass_map_cost.sh    # 14z-82b decision numbers (~20 min)
```
`GUARD_PROBE_HIST` also dumps history at CRASH time; `audit_merged_legacy`
leg-b now always measures the REF leg on a crash (MERGE-SPECIFIC vs
LATENT verdict — the gap that mis-attributed f7997 for two sessions).

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
tests/audit_merged_legacy.sh               # ~45 min (fails BY DESIGN on 04's
                                           # held inventory + pyron f7997
                                           # until the 14z-82b fix is adopted)
```
