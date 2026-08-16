# NEXT SESSION — orientation (updated at the close of 14z-92, 2026-08-16)

> ## `merged-m1` IS FROZEN — THE FIRST FROZEN MERGED BUILD. All 18
> ## characters in one image (`build/m3b_merged8`, `952fc731`, 753 ops),
> ## every merged gate green including `audit_merged_legacy` AUDIT-EXIT 0
> ## (leg a 47/47, leg b 6/6). S6 is complete.
> ##
> ## **PLAYED AND FIELD-CONFIRMED** (maintainer, 2026-08-16): "no obvious
> ## regression", and the game "may even feel better" — flagged by the
> ## maintainer as feeling, not fact, and recorded that way. S6 is closed.
> ## Two threads left dangling by that verdict are the first two items
> ## under START HERE.

## What 14z-92 was

`verify_gfx_build.py --tenant huitzil` was aborting every merged build. It was
a verifier artifact of the 14z-74 phantom class, in the ONE pass 14z-74 did
not harden — the pointer pass re-derived record structure from the relocated
image, and the merged placement window happened to contain a straddled datum's
value. Fixed (`ptr_allow`), gated (`tests/test_obj_record_walk.sh`), and
`build/m3b_merged8` built clean.

**The caveat that matters:** the abort had already dissolved on its own. 14z-91
moved `anim@huitzil` and the coincidence went away, so merged8 verifies green
with the pre-fix tool too. The fix removes a dice roll that re-rolls on every
allocator change; it did not unblock today's build. Full detail in STATE.

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


## START HERE — the open list, in order

- ~~**GitHub #75 — `build_merged.sh` ABORTS on huitzil.**~~ **CLOSED 14z-92.**
  It was a VERIFIER artifact, not a build defect: `obj_records.walk`'s pointer
  pass re-derived record structure from the relocated image, so a straddled
  datum inside a real record became a valid record head under the merged
  placement window (+1 record, +67 entries, 34 out-of-band tiles). Fixed with
  the same `ptr_allow` treatment 14z-74 gave the sweep pass; gated by
  `tests/test_obj_record_walk.sh` (4 verdict controls, ROM-free, in
  ci_portable).
  **Read this part too:** the abort had ALREADY stopped happening. 14z-91
  moved `anim@huitzil` 0x41a7e0 -> 0x41a6e0 and the coincidence dissolved —
  merged8 verifies green with the pre-fix tool too (measured). Nobody knew
  because nobody re-ran `build_merged.sh` after 14z-91. **`build/m3b_merged8`
  (`952fc731`, 753 ops) now exists** and is the first merged build carrying
  the 14z-91 legacy fix — UNREGISTERED, and no merged CONTENT gate has run on
  it. That is the S6 list below.
- ~~THE BEAM VISUAL ON A MERGED IMAGE~~ **CLOSED** (maintainer,
  2026-08-16): *"beam visual is 100% clean, as is its sound."* The S6
  carry-forward is done, and the effect family — three defects, three
  root causes across 14z-70/71 — is closed end to end on the shipping
  artifact.
- **PHOBOS' HISTORICALLY-DEFECTIVE MOVESET IS FIELD-CONFIRMED ON THE
  MERGED BUILD** (maintainer, 2026-08-16): 236+P, 236+K, jump214+K,
  236+2K, 214+2K "in the variants that broke or were incomplete in the
  past and their ES variants". That is the beam family (14z-70/71, three
  root causes) and the Plasma Trap (out-of-range entry 82, the LOUD one),
  ES included — and an ES that fires is a stronger statement than it
  looks, because an empty meter silently downgrades.
  Combined with the rigs, the whole danger set for table 0x018468 is
  covered by whichever instrument can reach it: entry 82 by the
  maintainer AND `audit_trap_parity`; entry 83 (Reflect Wall, SILENT) by
  `test_hui_pairs` only — it is guard-cancel-only, so a rig is the ONLY
  way it can ever be confirmed. `test_index_space` /
  `test_variant_dispatch` / `test_index_window_thunk` all PASS on
  merged8 besides. **Remaining L/M/H strengths are unknown-unknowns, not
  a named mechanism — a nice-to-have, not a risk item.**
- **"IT MAY FEEL BETTER" — measurable, and worth measuring once.** The
  maintainer flagged it as feeling, not fact, and it is recorded as an
  impression only. But a mechanism exists: 14z-91 left the two obj_hook
  dispatch sites VANILLA (relocating the walker instead), removing
  per-dispatch thunk cycles from a path `audit_walker_ghost` measured at
  **279,577 dispatches across the corpus**. Saved cycles do not speed a
  fixed-rate machine up — they widen main-loop headroom, and vsav's
  visible slowdown is what eats headroom, so "snappier under load" is the
  predicted shape. The test is a headroom/overrun A/B of merged8 vs
  merged7 on a heavy-object replay. If it measures out it is the
  project's first performance-POSITIVE result; if it does not, the
  impression stays an impression and gets written down as refuted. **Do
  not repeat "it's faster" until one of those happens.**
- **`build/m3b_merged8` IS FROZEN as `merged-m1` (14z-92):**
  render-content, trap parity, FG parity, select-bank-gates and
  `audit_merged_legacy` (AUDIT-EXIT 0, leg a 47/47, leg b 6/6) all PASS.
  Frozen by TAG + HANDOFF row with **no `registry.tsv` row on purpose** —
  the legacy-only instrument `build/merged1` shares its program
  fingerprint, so a row would register the blanks build too. Read the
  `tests/expected/registry.tsv` header before touching that.
  Repaired in the process: `test_merged_render_content` named `build/hui31`
  as its huitzil reference — a pre-WIDE-v1.1 build MAME refuses — so H/P's
  only render gate had produced **no huitzil measurement since 14z-86**, and
  printed the dead leg as a content mismatch. Now points at `hui41` and
  reports an empty operand as a DEAD LEG. **D and P still name `m5_wide` /
  `pyron21`; re-point a row whenever that tenant is re-frozen.**
- ~~OPTIONAL, ~2 h: `tests/audit_merged_legacy.sh`~~ **RUN at the freeze,
  AUDIT-EXIT 0** (leg a 47/47 with 0 NOT-EVALUATED, leg b 6/6 guard-clean
  vs don_m7 / hui41 / pyron26). It was a re-run on this tree by
  construction; what it bought is the determinism confirmation — it
  rebuilt its instrument from scratch and reproduced 753 ops and the same
  fingerprint.
- The merged build now has its own class table, `tests/expected/merged1/` —
  read its README before touching a spec there, and do not copy a tenant
  set's line into it: the two tables are measurably not interchangeable,
  which is why it exists.
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
tests/test_obj_record_walk.sh                  # seconds, ROM-free — the #75 gate
tools/build_merged.sh build/m3b_merged9        # ~1 min; m3b_merged8 already built
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
