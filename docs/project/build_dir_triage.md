# build_dir_triage — the build-directory policy and its current inventory

> **STATUS (14z-122):** LIVE reference; canonical home of the build-dir
> POLICY (adopted 14z-102, maintainer-ruled) and the CURRENT per-track
> inventory. The 14z-101 decision package, the A4 pin-cleanup record and
> superseded sweep records are verbatim in `build_dir_triage_history.md`.

## The policy

- **N-2 per track** (standing, maintainer-ruled 14z-102): at every freeze
  the N-2 generation's build dirs are deleted — keep CURRENT + ONE BACK per
  track (`don_*`, `hui*`, `pyron*`, `m3b_merged*`, `m5_stock*`). This is
  what keeps the 14z-101 decision package (history) from regrowing.
- A DELIBERATE EVIDENCE PIN is exempt and annotated in its gate
  (`don_m5` = audit_walker_repoint's required un-relocated negative
  control; `pyron26` + `hui41` = test_decode_stage_banners' frozen #92
  carriers; `m5w` = the known-bad 14z-60y shadow artifact).
- A CONTROL dir outlives its slot while a gate names it:
  `build/m3b_merged19` is `test_random_select_tenants.sh`'s CONTROL (the
  last merged WITHOUT the draw thunks — the must-fire leg); when it rolls
  off, re-point CONTROL at the next tenant-less merged or accept the SKIP.

## **[VSP-98]** Recordings under `tests/inp/` and the cache (maintainer-ruled 14z-111)

- A hand-played MAME recording is tracked under `tests/inp/<what>-<freeze set>-NN/`
  (the freeze it was played on; `NOTE` says what it exercises) the moment it
  has a consumer (`tests/test_inp_corpus.sh` replays all of them at every
  freeze). The `~/.cache/.../inp/<name>/` original is deleted once tracked.
- A recording with no consumer — a plain-play attempt, an aborted take, a
  smoke run nothing names — is deleted after `grep -rn <name> tests tools
  docs HANDOFF.md STATE.md CLAUDE.md` comes back empty. Applied at close
  14z-111: `crash_m8` (82 KB, plays clean on merged-m8), `crash_m9` (~500
  frames, abort), `smoketest` (14z-9x, unreferenced) deleted; `crash_m10`
  renamed to `crash-merged-m8-01` and its cache copy deleted.

## **[VSP-96]** BEFORE DELETING A BUILD DIR, GREP FOUR PLACES — NOT TWO (14z-112, paid for)

The N-2 sweep of 14z-112 deleted 27 generations and broke one gate, because
the reference scan covered `tests/` and `tools/` only. The complete list:

1. `tests/` and `tools/` — **excluding comment lines**. A first pass that
   counted `#` mentions made almost every dir look load-bearing (31 of 62)
   and hid the 2.5 GB that was actually free. Filtering comments is what made
   the sweep possible at all.
2. **`build/manifest/`** — this is the one that bit. `shared_writes.toml`
   carries `build = "build/don_m7"` rows that `tests/test_shared_writes.sh`
   consumes, so deleting `don_m7` turned that gate into a SKIP — and under
   `--strict` a SKIP is a failure, because a skipped gate asserts nothing.
   The gate did not fail loudly; it quietly stopped testing.
3. `docs/` — but READ the hit before acting: `gfx_layout3.toml`'s
   `build/hui43` and `build/pyron27` are provenance notes ("measured on"),
   not inputs, and those dirs were correctly deleted.
4. The freeze policy itself: keep CURRENT + ONE BACK per track
   (`don_*`, `hui*`, `pyron*`, `m3b_merged*`, `m5_stock*`), whatever the
   grep says.

**And run `tests/run_all_static.sh --strict` BEFORE committing the deletion.**
It is the only instrument that catches a gate degrading to SKIP. Deleting is
cheap to redo — `git checkout HEAD -- build/<dir>` restores a tracked one in
seconds — so the sweep is safe as long as the suite gates the commit.

### **[VSP-97]** THE DEEPER FLAW THE SWEEP EXPOSED: "tracked" build dirs are only PARTLY tracked

`build/don_m7` is a TRACKED build dir — 18 files — but
`tests/test_shared_writes.sh` needs the 23 generator outputs
(`patch/fixed_*.bin`, `effect_lists.bin`, …) that are NOT tracked. Deleting
the dir therefore removed a gate fixture that git could not restore:
`git checkout HEAD -- build/don_m7` brought back the 18 and the gate went
from SKIP (14z-112's first strict run) to FAIL (its second).

**It was recoverable, and the recovery is the recipe if it happens again:**

    git worktree add --detach <tmp> 05ce63a          # the commit that froze don_m7
    cp -R build/wide0 <tmp>/build/                   # the WIDE overlay it merges
    cd <tmp> && ROMDIR=... KEY_SET=vsavj \
      GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
      tools/build_donovan.sh 6 build/don_m7_rb
    # -> fingerprint c90b60c3 = donovan-m7 exactly; copy the missing
    #    patch/* into build/don_m7/patch/, tracked files untouched.

The frozen inventory matching afterwards is what PROVES the rebuild was
right — the gate validated its own fixture.

**The standing lesson:** a gate whose fixture is an old build dir depends on
UNTRACKED bytes, and no policy in this repo protects those. Before deleting
any tracked build dir, either confirm no gate consumes it or accept that
restoring it means a historical rebuild. The cheap alternative — re-pointing
the gate at a current build — was measured and REFUSED here: `don_m14` shows
103 shared-surface writes against the frozen row's reviewed set, so
re-freezing would have laundered an unreviewed inventory into the very gate
that exists to prevent exactly that.


## The current inventory (as of the 14z-119 sweep; updated at every freeze)

Current + one back per track: `don_m17/m18`, `hui51/52`, `pyron35/36`,
`m3b_merged20/21` (+ `m3b_merged19` control, see the policy), `m5_stock12/13`.
The latest sweep record follows; every older one is in
`build_dir_triage_history.md`.

## The latest sweep record, applied under the policy (the 14z-119 physics-port freeze)

Deleted at the freeze (N-2 per track): `don_m16`, `hui50`, `pyron34`,
`m5_stock11` (tracked metadata `git rm`'d; recoverable via `freeze/*` tags).
Grep-four-places before deletion: zero non-comment references in `tests/`
and `tools/`, manifest references are the `pcrel_escapes.toml` re-point
HISTORY comments only. `build/m3b_merged19` STAYS again (the
`test_random_select_tenants.sh` CONTROL — see the 14z-117b note below);
`build/don_phys_probe` (the validated physics probe, program-identical to
`don_m18`) and the two attribution probes `build/don_stage4_m18` (the stage-4
fingerprint `108f7523`) are deleted at the close — their evidence is the
freeze itself. Current + one back per track: `don_m17/m18`, `hui51/52`,
`pyron35/36`, `m3b_merged20/21` (+ `m3b_merged19` control), `m5_stock12/13`.

