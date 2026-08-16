# NEXT SESSION — orientation (written at the close of 14z-93, 2026-08-16)

> ## `merged-m1` IS FROZEN AND FIELD-CONFIRMED. All 18 characters in one
> ## image (`build/m3b_merged8`, `952fc731`, 753 ops); every merged gate
> ## green; the maintainer played it — "no obvious regression", beam
> ## "100% clean, as is its sound", Phobos' historically-broken moveset
> ## incl. ES variants all good. **S6 IS CLOSED.**
> ##
> ## Nothing is blocked. No build byte moved in 14z-93.

## What 14z-93 was, in one line

**The M4 keep-or-drop question is answered, and the answer needed a second
number.** The tenant enters the hit-class map **0 times** over all 37 rigs —
which alone reads like "drop it" — but the same corpus puts **121 objects of
type >= 64 into the projectile pool**. The gap is CONTACT, not absence, so
the recommendation is **KEEP**, and what is actually missing is a
pool-vs-pool contact RIG. A zero measured against no denominator is the same
shape that produced the retracted "legacy never enters the map" claim.

Also: the 14z-92 retraction had **not** fully propagated — the retracted
sentence was still live in `engine_internals.md` four lines below its own
retraction. Fixed, plus patch_notes, registry.tsv, and a `patch_index.md`
row that had never existed for a shipped patch.

## What 14z-92 was, in one line

**Five instruments had quietly stopped measuring**, and four of them were
GREEN or unrun rather than red. A decayed gate does not fail — it stops
disagreeing.

| instrument | broken since | presented as |
|---|---|---|
| `obj_records.walk` pointer pass | fired 14z-86 | a build defect (#75) |
| `test_merged_render_content` H legs | 14z-86 | a CONTENT REGRESSION |
| `audit_hitclass_map_cost` reference | 14z-86 / 14z-82c | would have blamed the thunk |
| `test_pyron_ladder` tenant selection | always | **built Donovan**, green (#84) |
| `test_pyron_blink` guard | 14z-87 | could false-REFUSE |

If you read one thing before touching a gate: **`docs/project/gotchas.md`,
"A frozen build stops being a usable REFERENCE when the profile bumps"** —
three references rotted this session (`hui31`, `pyron20`, `pyron17`).

## Two beliefs that changed

1. **Legacy DOES enter the hit-class map — 230 times, not zero.** The old
   census was two replays, both of which score zero. The fix is still sound
   (all indices far below 64, so legacy reads vanilla's own bytes); the
   ARGUMENT was wrong and is corrected everywhere it appeared.
2. **The tree contradicted itself on the QSound terminal byte** (#82):
   `build_qs_songs.py` says INCLUSIVE (packing law #3 — the sword-plant
   beep), `audit_qs_voice_batch.py` still justifies EXCLUSIVE with the
   pre-14z-87b belief.

## Do not repeat these

- #75's blocker **had already dissolved** before the fix — merged8 verifies
  green with the pre-fix tool. The fix removed a dice roll, not a blocker.
- "It may feel better" was **emulator-sided**. The project has NO measured
  performance-positive result. Do not cite the obj_hook cycles for it.

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
- ~~"IT MAY FEEL BETTER"~~ **CLOSED (maintainer, 2026-08-16): it was
  EMULATOR-SIDED**, not the ROM. No headroom/overrun A/B is needed and the
  obj_hook-cycle mechanism is NOT the explanation. Recorded so nobody
  re-opens it as a performance claim: the project has no measured
  performance-positive result, and this was not one.
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
- ~~M4: `audit_hitclass_map_cost.sh` over the FULL corpus~~ **RUN 14z-92 —
  AND IT FALSIFIED THE CLAIM IT WAS FILED TO CHECK.** `hitclass_map_extend`'s
  adoption rested on "legacy never enters the map", measured over TWO
  replays — both of which happen to score zero. Corpus-wide (46) legacy
  enters **230 times** (`26_don_arcade_mash` 228, `24_don_winmash` 2). The
  fix is still sound: every legacy index is 0x02/0x04/0x09/0x0b, far below
  64, so legacy reads VANILLA's own bytes out of the thunk. The argument is
  now "legacy enters and gets vanilla answers". Section 1: 43/46
  bit-identical, 3 transient re-convergent, 0 dead. Claim retracted in
  engine_internals, HANDOFF, and both manifests.
- **OPEN from #78 — needs a ruling: two FBNeo-only phase classes.** The new
  `tests/test_fbneo_legacy_oracle.sh` (the agreed partial) found, on its
  first run, differences that MAME does NOT show at the same frames:
  `$FF055B-$FF055D` (sound-driver work area, ram.md:74) and
  `$FF06D1/D4/DB` (OBJ-builder secondary stack, ram.md:62 "execution
  POSITION, not state"). Both are attributed and bounded to two named
  windows; neither is gameplay state. They are reported as `open:` lines,
  NOT as tolerances. **The ruling needed:** ram.md:62 records that class as
  appearing only on tenant-content replays where no vanilla oracle applies —
  it appears here on LEGACY content under FBNeo, which extends it. Per §4 a
  new tolerance needs sign-off. `FBNEO_ORACLE_EXPECT=exact` is the
  post-ruling target.
- ~~**OPEN from M4 — is the thunk still load-bearing?**~~ **MEASURED 14z-93.
  RECOMMENDATION: KEEP.** The tenant enters the map **0 times** over all 37
  hui+pyron rigs — while putting **121 objects of type >= 64 into the
  projectile pool** (9 distinct types, 64-72, in 22 of the 37 rigs). The gap
  is CONTACT, not absence: the sweep is POOL-vs-POOL, so a tenant projectile
  hitting a FIGHTER never transits the map. Each of those 121 is one
  collision away from indexing past vanilla's 64 entries.
  **The dead crash control is diagnosed, not mysterious** (section 4): the
  soak rig reaches the map 0 times, so the no-thunk twin has nothing to crash
  on — yet that same rig still spawns 13 type-64/67 objects. A RIG failure.
  Do NOT drop the row on it, and do not re-point it at a new crash address.
  **Count the rows carefully:** 93 stamp rows carry `type >= 64`, but only
  **36** are in the 64-75 projectile-pool band that can over-index this map;
  the other 57 are the 114-120 obj_hook family (owner-tag served, never
  reaches the sweep). 93 overstates the exposure 2.6x.
- **THE WORK THIS TURNED THE RULING INTO: author a pool-vs-pool contact
  rig.** No rig in the corpus produces one.
  `tests/replays/hui/88_hui_plasma_trap_contact.rpl`'s header names what is
  needed — "an opposing PROJECTILE to clash with, e.g. P2 Victor doing a
  pool-object move into the mine — not a walking fighter". Pyron's cosmo rigs
  are the richest source (17-28 type-66 spawns each), so a Pyron-vs-
  projectile-character pairing is the likeliest route. With one, section 3
  answers keep-or-drop outright and section 0's crash control can be revived.
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
