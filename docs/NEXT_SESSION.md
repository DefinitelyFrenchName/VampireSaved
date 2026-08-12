# NEXT SESSION — orientation (written at the close of 14z-81, 2026-08-12)

> ## START HERE
>
> **The merged-legacy measurement ran. Split verdict: LEGACY IS SAFE — the
> merged image lands on donovan-m3a's ratified classes 13/14 VERBATIM — but
> TWO TENANTS BREAK on their own content.** Huitzil crashes at char-init
> (deterministic vec3, localized to one still-unnamed pointer slot that
> holds a DONOVAN address); Pyron crashes mid-mash-storm. Nothing here
> touches a frozen build; all four references rebuild bit-exact.
>
> **FIRST PRIORITY: name the pointer slot behind the Huitzil vec3 crash and
> fix it.** The chase is already 90% done and captured — read the 14z-81
> STATE section, then run `tests/audit_merged_vec3.sh` (~4 min): it prints
> the healthy-vs-bad values and is the regression gate for the fix.

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

## 1. THE VEC3 SLOT — first priority, with the trail already blazed

Measured and ruled out (details + numbers in STATE 14z-81):

- Crash: satellite object $FFB800, vanilla anim walker entry 0x15084,
  fault at 0x15096; merged base A0=0xCB9C0 (unplaced gap), healthy would be
  anim@huitzil+0xB8AC = 0x425FFC (hui29 measures 0xE456C = his anim+0xB8AC).
- 0xCB9C0 is in NO rom byte and NO op — runtime-composed; minus the 0xB8AC
  offset it is 0xC0114 = TENANT-0's ported `code` + 0xA74.
- Already verified correct: all 15 anim_index rows; the x06cac0 blob's
  re-derived literals; the x026142+0x13E2 pc-rel stub (byte-identical).

Next probe: GUARD_PROBE at H's satellite spawn handler (x06cac0@huitzil is
at 0x415980 in merged; obj_hook types 64-75 dispatch there) and watch where
the 0xC0114 half is LOADED from — or `tests/lua/index_watch.lua`. Warning
from this session (gotcha filed): the pushed vec3 PC (0x15098) is
mid-instruction — probe ENTRY addresses, never the CRASH-line PC. And the
FBNeo tap is not comparable here (frame skew + slot recycling put the
satellite elsewhere; merged even survives the replay on FBNeo — MAME is the
instrument).

Fix lands → `tests/audit_merged_vec3.sh` flips green → re-run
`tests/audit_merged_legacy.sh` in full.

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
