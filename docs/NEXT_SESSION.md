# NEXT SESSION — orientation (written at the close of 14z-91, 2026-08-16)

> ## THE LEGACY REGRESSION IS FIXED AND RULE 6 HAS LIFTED. The six
> ## `.pending` replays are gone, the three suites are GREEN, and forward
> ## work is unblocked for the first time in three sessions. What you pick
> ## up next is a choice again, not a halt — see "START HERE".

## What 14z-91 was

The open legacy regression (CLAUDE.md §1/§2.6) closed. Three changes in one
re-freeze, four new fingerprints, and a corpus-wide re-measurement that came
out **stricter** than what it replaced.

| # | change | cleared |
|---|---|---|
| A | the two `fixture_row0f_override` site_thunks DELETED | `38_victor_p1_vsavj` |
| B | obj_hook dispatch sites left VANILLA — the WALKERS are relocated | `24_don_winmash` (all 3 sets) |
| C | the `beam_list_type6` fallback stops writing `$FF010C` | `21_don_mash`, `26_don_arcade_mash` |

**Current builds:** `build/don_m7` = **donovan-m7 `c90b60c3`**,
`build/hui41` = **huitzil-m15 `4531af1e`**, `build/pyron26` = **pyron-m9
`fac4a777`**, stock twin `build/m5_stock2` `a054de5c`. All four moved (the
fix is not profile-gated). m6/m14/m8 are BURNED by the 14z-88 withdrawal.

## What moved, that you will notice

- **`tools/freeze_masked_basis.sh` had a live defect and it is fixed.** The
  canary command this file used to document re-derived the frozen basis
  bit-for-bit **and then overwrote it** (4248/4321 lines): `freeze_one`
  derived its MAME sandbox from the replay NAME, the command names the same
  replay twice, and the freeze leg inherited the verify leg's EEPROM. Both
  legs were internally deterministic so every guard stayed green. Fixed;
  gated by `tests/test_freeze_basis_sandbox.sh`. **The canary command below
  is now safe to run as written.**
- **The obj_hook site hook is gone.** Anything that assumed a thunk at
  `0x54470`/`0x5E542` is stale — `audit_objhook_owner_census.sh` is flagged
  in HANDOFF as needing its probe re-pointed at the relocated walker.
- **`dispatch_census.toml`'s "free list" was retracted.** The complement of
  `observed` is NOT free (true free lists: 1 and 6, not 50 and 83). It stays
  as a drift detector for what legacy spawns.
- **`test_m3a_reproducible.sh` member CONTENT is now a HARD FAIL** (issue #8
  promotion, which was scheduled for exactly this re-freeze).
- **5 new gates**, all registered in HANDOFF's table: `audit_walker_ghost`,
  `audit_walker_repoint`, `test_obj_walker_relocation`,
  `audit_walker_callers`, `test_freeze_basis_sandbox`.

## Your decisions — ALL EIGHT RULED AND APPLIED at the 14z-91 close

Nothing is waiting. For the record: the merged build got its own class table
(and leg (b) was repointed at the post-fix solo builds); CLAUDE.md §4 gained
v5, the >=60 rule is intra-mechanism, with the two remaining 55-frame pairs
recorded as named exemptions; #35, #39/#40 and #73 are applied; #41 is
drafted at `ci/static-and-groundtruth.yml` and deliberately NOT enabled —
moving it into `.github/workflows/` is the whole act.

The superseded framing, kept because it explains the shapes above:

- **#4 (the ≥60 flicker→window boundary) no longer ARISES on these builds.**
  It was about flicker 829 sitting 59 frames before window onset 889. Frame
  829 is gone corpus-wide; no remaining flicker frame precedes any window
  onset. Still worth codifying for the class table, but it gates nothing.
- **The five 55-frame pairs moved.** donovan 22 keeps `11862,11918` and
  huitzil 26 has `8744,8800`, but donovan 26 lost 8800 and huitzil 22 lost
  11918. The inventory the ruling addresses is not the one it was written
  against.
- **#2 (does the M2 battery still target the m2c generation?)** unchanged —
  and note change A removed the only surface `tests/test_don_accent.sh`
  asserted, on a track that gate does not run against. Its header now says
  it is pinned to the parked m2c track.

Five policy calls are unchanged and still open: #35 (CLAUDE.md vs Rule 1
v2), #39/#40 (.gitignore + untracking), #41 (CI), #73 (the PNG goldens).

## START HERE — the open list, in order

- **GitHub #75 — `build_merged.sh` ABORTS on huitzil.** Now the top
  blocker: `verify_gfx_build.py --tenant huitzil` fails on m3b_merged7
  (record/entry parity 1374,14911 != 1375,14978; 34 tile codes outside the
  placed window; regression window merged5 -> merged6, 14z-86). It blocks a
  new merged-WITH-GFX build, which is what the S6 freeze and playtesting
  need. It did NOT block this session's legacy work, because
  `audit_merged_legacy.sh` builds its own gfx-free instrument.
- **The merged PROGRAM image is already validated** — `audit_merged_legacy.sh`
  is FULL GREEN on this batch (leg (a) 47/47, leg (b) 6/6, 753 ops). What
  #75 blocks is the merged build WITH GFX, which is what the S6 freeze and
  playtesting need. The merged build now has its own class table,
  `tests/expected/merged1/` — read its README before touching a spec there.
- **M4, not yet run: `audit_hitclass_map_cost.sh` over the FULL corpus.**
  `hitclass_map_extend` IS adopted (huitzil.toml:2048, pyron.toml:1044 — the
  "ADOPTION PENDING" in engine_internals was stale and is corrected), so it
  is a live hook on a shared engine site whose "legacy never enters" evidence
  is four replays. Same coverage shape that produced this session's
  regression. Cheap insurance, not a known defect.
- The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- Round-end flicker (parked; needs the maintainer's recording).
- OPTIONAL / cosmetic (maintainer 2026-08-15): the merged-only
  P2-ring-on-Donovan medallion whitening; win-screen QUOTE (both tenants);
  region_space re-freeze; op-tagging for test_shared_writes. **Donovan's
  venue palette row 0x0F** joins this list — change A traded vs2's red
  statue ramp for vsavj's, which the scope ruling makes optional; the
  cost-neutral route back (init shim → the engine's own copy helper
  `0x1C3A4` → staging row 0x0F, i.e. the fade's SOURCE) is written up in
  `build/manifest/donovan.toml` above the retired rows.
- H-vs-P stuck-direction (~1/30) — possible; not reproduced recently.
- Then MiSTer core surgery (stretch, DECIDED) — after the roster.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2

# the canary — safe as written since 14z-91
VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
  tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m7/mask)" 16_xemu_2p

MAME_ROMPATH="$PWD/build/don_m7/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_m3a_reproducible.sh                 # ~6 min, all four, now hard on content
tests/audit_walker_ghost.sh                    # ~5 min — the mask assumption
tests/audit_walker_repoint.sh build/don_m7     # ~5 min — caller completeness
tests/test_obj_walker_relocation.sh build/don_m7   # seconds, ROM-free
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
tools/build_merged.sh build/m3b_merged8        # BLOCKED on #75
```

## Rebuild recipes

```sh
KEY_SET=vsavj WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
  GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
  tools/build_donovan.sh 6 build/don_m7
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 ... build/hui41
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 ... build/pyron26
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock2
```
