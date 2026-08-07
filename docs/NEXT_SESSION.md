# NEXT SESSION — orientation (written at the close of 14z-65, 2026-08-07)

**Start here: M3b IS OPEN (the roster tenants) — plan in
`docs/M3b_plan.md`, three maintainer decisions pending (STATE.md 14z-65
"Decisions pending": D1 Huitzil default flavor, D2 Pyron source version,
D3 arcade-ladder membership).** The frozen references are unchanged:
donovan-m3a `4b7d0dc7` / m5_stock `6c93cfa8`, and
`tests/test_m3a_reproducible.sh` must stay green after EVERY M3b
machinery commit.

## What 14z-65 delivered (all gates green, all committed)

1. **Phase 0 rails**: `patch_prg.py` hard-fails op overlaps (it caught a
   real latent collision in the frozen build — tail_data_ptr vs the
   sound_table row, correct only by emission order — and then caught the
   M2a scaffold double-repoint on Huitzil's first stage-2 build); the
   reproducibility gate.
2. **Phase 1**: extraction de-Donovanized — per-char anchors, charid scan
   on src_char, and the piecewise-shift/dead-filler/sibling-insertion
   model of the appended code window (atlas: character_tables.md
   "piecewise" section). Both new tenants EXTRACT oracle-validated
   (`tests/test_extract_hp.sh`).
3. **The Huitzil ladder is open**: `build/manifest/huitzil.toml` (native
   0x10, variant-id only), driver TENANT_MANIFEST/TENANT_CHAR, stages
   1-3 GREEN with THE OP INVARIANT (every op = free space or variant
   row) and a legacy replay BIT-IDENTICAL to vanilla
   (`tests/test_hui_ladder.sh`).

## Build / validate

```sh
export ROMDIR=/Users/koneko/Developer/Vampire_Saved/ROMS
tests/test_m3a_reproducible.sh          # after every machinery change
tests/test_extract_hp.sh                # H/P extraction shapes
tests/test_hui_ladder.sh                # the Huitzil ladder
# a Huitzil ladder build by hand:
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
GEN_FLAGS="--profile cps2-wide-v1" tools/build_donovan.sh 3 build/hui3
```

## The road (docs/M3b_plan.md; sequencing adjusted 14z-65)

1. **HUITZIL BOOTS (build 9252ce62) — next: the behavioral frontier.**
   The wedge fell to three measured fixes (fall-through layout group at
   the 0x57456 mid-handler split, [init_shim], five stubbed_sound rows
   — patch_notes 14z-65 (5); gate tests/test_hui_boot.sh). A live match
   forms with HIS data, sprite-garbled until the gfx rung. NEXT:
   in-match input soaks over his moveset (each tripwire hit = the next
   R1 item; 18 remain), then the vsav2-as-oracle stage-4 battery
   analog, then HUD/select rungs and Phase 2. Prior wording follows:
   Huitzil stage 4 BUILDS — The R1 loop ran (census: 0x55478, the velocity
   rings 0xd143e+0x900, the shared zones with x088512 at its TRUE
   0x3B40 extent; 0x8ACD8 = his aux init in the shared zone, mystery
   closed; 23 classified tripwires remain — STATE 14z-65). The
   forced-boot probe (`tools/force_pick_probe.sh`, validated both ways:
   vanilla ids load everywhere, and stage-3 + forced 0x10 loads
   HUITZIL'S OWN placed data — the passive rungs are live-verified)
   shows stage 4's ported INIT PATH HANGS at id 0x10 and the machine
   WATCHDOG-REBOOTS (snapshots: select -> black garble -> QSound
   splash; GOTCHAS 14z-65 — a reboot masquerades as a clean non-load).
   Hang-hunt next: GUARD_BREAK on his placed dispatch_00 handler, then
   GUARD_PC_LOG over f2300-2900, then GUARD_PROBE down the init chain.
   Prime suspects: the aux-init path through the shared zone (0x8ACD8
   family) and a missing [init_shim] analog (Donovan's init NEEDED the
   pool-seeding shim; huitzil.toml has none yet). Then: the sound-farm
   five (M5-style triage, never blind-resolve), companion family by
   guarded runs, flavor wiring (D1 = VS2 provisionally, maintainer
   2026-08-07; final after a playtestable build + a written "flavor
   differences to hunt for" note from the fork-consumer measurement).
2. **Phase 2 — the multi-tenant merge** (docs/M3b_plan.md Phase 2):
   unify two WORKING single-tenant builds in one generator process.
   Known hazards on record: shared-span region dedup (H's +0x30 region
   overlaps P's and D's zones), charid rewrites on shared spans need
   tenant attribution, engine hooks emit once as unions, site_thunk
   gates become id-dispatched.
3. **Phase 3 — group C bank-4 coexistence** (measure H/P native tile
   ranges first), then Pyron's ladder, then the shared registries
   (arcade ladder D3, fold audit).

## Standing facts (do not re-derive)

- The appended newcomer code window has PIECEWISE sibling shifts
  (+0x36/+0x30/+0x34), dead junk filler, and at least one vs2-only
  insertion — atlas character_tables.md + GOTCHAS 14z-65. Never probe
  alignment with a lax classifier (opcode-word match + zero unexplained).
- A variant-id tenant's ladder gate is TOTAL bit-identity on legacy
  replays (no divergence-frame pinning needed — rows 0x10-0x1F are
  legacy-unreachable, and the op invariant checks it per op).
- Ownership rule: a manifest section that pokes a row itself suppresses
  the generic repoint (sound_table claims; scaffold repoints stage-1
  only). Two ops on one word = build error, never reorder.
- Stage >= 6 for a non-Donovan tenant is refused by the driver (his gfx
  constants); Phase 3/4 generalizes the gfx half.
- QSound sizing (three voice banks vs the added 8 MB, 16 MB MAME
  ceiling) should be measured BEFORE any sound work commits (M5/M3b
  shared watch item).
