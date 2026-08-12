# NEXT SESSION — orientation (written at the close of 14z-81, 2026-08-12)

> ## START HERE
>
> **The merged-legacy measurement ran. Split verdict: LEGACY IS SAFE — the
> merged image lands on donovan-m3a's ratified classes 13/14 VERBATIM — but
> TWO TENANTS BREAK on their own content.** Huitzil crashes at char-init;
> Pyron crashes mid-mash-storm. Nothing here touches a frozen build; all
> four references rebuild bit-exact.
>
> **THE VEC3 SLOT IS NAMED (14z-81b): a MULTI-OWNER obj_hook type has ONE
> extended-table entry.** Type 117's handler lives in x088512, which ALL
> tenants port; the merged union routed everyone into tenant-0's
> internally tenant-reconciled copy, and Huitzil's object consumed
> Donovan's planted tripwire ADDRESS as a data base (hence vec3, not the
> tripwire's own ILLEGAL).
>
> **A STUB FIX WAS IMPLEMENTED, MEASURED GREEN FOR HUITZIL, AND WITHDRAWN
> the same day (14z-81c)** — dispatch-time owner reads have two MEASURED
> timing failure modes (stale/recycled parent chains broke donovan/12;
> spawn-instant field transience is the 115 census), and two
> counterexamples from six replays means the space is not enumerated.
> The merged instrument is back to bit-identical pre-fix bytes
> (7a9eabb3, verified). All machinery was kept: the detection + 19
> FIRST-WINS notes (zero image bytes), the hand-verified stub builder,
> the census rig, GUARD_PROBE_TRACE.
>
> **FIRST PRIORITY: the spawn-time TAG design** — each tenant's own copy
> stamps its spawns, so a tag byte (or per-tenant TYPE NUMBERS rewritten
> in the copies' stamp immediates) makes dispatch timing-proof with NO
> runtime owner read. Measure first: the full stamp-site census (x088512
> immediates cover only 116/117/119 — where do 114/115/118/120 get
> stamped?) and a type-COMPARISON census inside the family regions.
> `tests/audit_merged_vec3.sh` (~4 min) is the unchanged regression gate;
> it FAILS by design until the real fix lands.

## The state in one paragraph

`build/merged1` (fingerprint 7a9eabb3, gfx-skipped, group C zero-filled —
LEGACY-ONLY, never playtest, no registry row on purpose) is the first merged
image ever to run. Section 0 proved all three tenants' char-init entries
execute; two masked runs are bit-identical (first merged determinism check);
leg (a) matched every ratified legacy class except ONE extra deterministic
flicker frame (04_select_fuzz, frame 2005, two live bytes at $FF0462-3 = the
low word of an unidentified pointer at $FF0460 — "sound cursor" was
speculation, WITHDRAWN). Leg (b): Donovan guard-clean (divergences vs m3a
unattributed but placement-shaped), Huitzil vec3 at f2886 (4/4 runs), Pyron
vec3 at f7997 (2/2 runs, evidence in build/gate_failures/).

## 1. THE VEC3 FIX — first priority; the slot is NAMED, the design is
##    written (STATE 14z-81b)

Root cause, verified end to end: the merged obj_hook union gives a
MULTI-OWNER type (117 — its handler lives in x088512, which all three
tenants port) ONE extended-table entry, and routed every tenant into
tenant-0's copy. The copies are internally tenant-reconciled (per-tenant
anim literals; cross-tenant pointers are planted tripwires), so Huitzil's
object executed `movea.l #$cb9c0,A0; jmp $15084` — Donovan's TRIPWIRE
ADDRESS consumed as a data base. (Note the 0xC0114+0xB8AC decomposition in
the first-pass chase was a red herring — the literal is the tripwire
address directly.)

THE DESIGN QUESTION IS SETTLED BY MEASUREMENT (14z-81c): the owner-walk
stub family — design (a) — was implemented and WITHDRAWN; dispatch-time
owner reads are structurally fragile at spawn instants (full record in
STATE 14z-81c; the withdrawn code and its measured owner-read rows live
in `OBJ_HOOK_OWNER_READ`'s comment in gen_donovan_patch.py, and the
hand-verified `owner_dispatch_stub()` builder is kept for reuse).

**The spawn-time TAG design is what remains, and it starts with two
censuses:**

1. **Stamp sites** — where does each of types 114-120 get its type byte
   written? x088512's `move.l #$01xxTTxx,(A4)` immediates cover
   116 (+0x20b0), 117 (+0x27ce), 119 (+0x1dc4, +0x2138) only;
   114/115/118/120 are stamped elsewhere (x06cac0?) or computed. The
   pattern-scan that found these is in the 14z-81b session record; run
   it over the other family regions, and cross-check dynamically (tap
   writes of the type byte on hui29 — FBNEO_HTAP on a live object's +0x02
   or a GUARD watch).
2. **Type comparisons** — code inside the family regions that compares
   type bytes (`cmpi.b #type` / sibling-type checks). Renumbering or
   tagging must not break them; vanilla engine code cannot reference
   types ≥114 (vsavj's table ends at 113), so the exposure is bounded to
   the ported regions themselves.

Then pick the variant: a tag byte in a known-free object field (needs a
free-field census; dispatch = one `cmpi.b (off,A6)`), or per-tenant TYPE
NUMBERS via blob transform of the stamp immediates + per-tenant table
entries (no dispatch code at all; table grows; obj_hook_extra is the
blessed facility for exactly this — see its comment at
gen_donovan_patch.py's authored-union block).

Inertness argument stays the same: nothing emits at N=1; assert all four
frozen fingerprints FIRST, then `tests/audit_merged_vec3.sh` flips green,
then the full `tests/audit_merged_legacy.sh` (~45 min) — and this time
also re-run `donovan/12_vs_cpu` specifically: it is the replay that
caught the withdrawn design, and any new dispatch layer must keep it
guard-clean.

## Then, in order

2. **Pyron's f7997 vec3** (build/gate_failures/merged1_b_70_pyron_mash.log:
   PC 01ab10, odd RAM ptr $FF31B5, A3=0x49bb8a in his own wide_ext) —
   possibly the same class one level removed; check after the H fix, it may
   dissolve.
3. **F2 — the merged shim serves only tenant 0** (confirmed statically;
   merged-H skips pool seed/phase gate/flavor). Fix shape: the shim's tail
   jmp targets ONE handler and later tenants aren't placed on iteration 0,
   so this is the site_thunk assemble-after-the-loop pattern (14z-80h).
   Maintainer recommendation queued: fix after the vec3 slot is named —
   same emit path, one re-measure covers both.
4. **The 2005 flicker's owner** — identify the $FF0460 writer
   (FBNEO_HTAP="0460-0463" is the cheap instrument) so the ratification
   decision is about a NAMED mechanism. Then the maintainer decides
   (decision 1 in STATE 14z-81); recommendation is to re-measure the whole
   table after the crashes are fixed anyway.
5. **Then the gfx half** (M3b Phase 3) and the tenant batteries on a merged
   build — unchanged from 14z-80's list, now explicitly behind the fixes.

## Decisions — MADE by the maintainer 2026-08-12 (full text in STATE 14z-81)

1. The widened 04 flicker inventory is NOT ratified — hold, re-measure the
   whole table after the fixes.
2. F2 is fixed AFTER the vec3 slot is named (same emit path, one
   re-measure covers both).
3. The vec3 slot comes first; Phase 3 gfx stands behind the leg-(b) fixes.

## Still open from 14z-79/-80, unchanged

- Phobos' own palette-seq block (KNOWN-OPEN RED on
  `tests/test_variant_dispatch.sh`, table 0x02a8a4 row 0x10).
- Pyron's Zodiac Fire has no rig (guard-cancel only).
- `80_pyron_cosmo_pairsweep.rpl` resets at f4840 — independent, low.
- The three NEW select medallions: polish.
- `region_space` rows on the manifests (deliberate placement vs alloc
  spill) — re-freeze, maintainer's call.
- Op-tagging so `test_shared_writes.sh` can name what a new write is.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
tests/audit_merged_vec3.sh                 # ~4 min: the crash probe (FAILS by
                                           # design until the fix lands)
tests/audit_merged_legacy.sh               # ~45 min: rebuilds build/merged1 +
                                           # the whole two-leg measurement
tests/test_tenant_loop.sh                  # ~17s, the merge gate
tests/test_m3a_reproducible.sh             # ~4 min, all four fingerprints
```
