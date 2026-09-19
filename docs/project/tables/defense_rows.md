# Tenant DEFENSE-side rows — vs2's rows, as ruled, SHIPPED IN M19 (merged-m19)

**RULED 2026-09-18 (14z-168): Phobos and Donovan take their vs2 rows** —
the maintainer: *"given the measurements we should take the vs2 rows. I hope
we can do it in a way that doesn't cost frames and that doesn't create
side-effects/regression elsewhere (e.g. it would be wrong to make changes that
correct the 3 tenants but break vanilla characters)"* (`DECISIONS_HISTORY.md`
"Ruled 2026-09-18 (14z-168) — the tenants' DEFENSE rows become vs2's"). **BUILT
14z-170** as four `[[data_port]]` rows (Phobos's in `huitzil.toml`, Donovan's in
`donovan.toml`): each tenant's 32-byte curve row from vs2, and its threshold as a WORD —
`patch_prg` writes words — with the neighbour byte asserted unchanged (a same-value `fixes`
entry: Pyron's 0x11 and id 0x12, the legacy-reachable Dark Gallon, are 0x30 in vsavj, vs2
and vh2); `only_variant_slot`, so the stock twin's rows stay vanilla; `orc` against vh2's
copies (vh2's curve table `PRG:0x0D2350`, its threshold table `PRG:0x0D66B0`). The program delta is exactly 66 bytes; the fixed build answers vs2's bytes at every
read (`tests/audit_defense_row_residue.sh`, which reads ours from the build since 14z-170).
The rows below are the values before the fix, kept as the record.
~~Maintainer ruling (2026-08-14, 14z-85f): option (b) — the tenants keep
vanilla vsavj's defender-side rows.~~ SUPERSEDED by the ruling above. This
file records the exact values on both sides and the recipe for the change.

**The measurements the 2026-09-18 ruling rests on** (both data views, vsavj
`d82320a0…` / vs2 `ac31740c…`, 14z-168): the 15 legacy characters' rows and
thresholds are byte-identical between the games except Sasquatch's row; vsavj
fills every variant-id row with a COPY of its base character's row (Oboro 0x18
alone has its own), so the tenants' current rows are their SHELLS' — Phobos
rides Bulleta's, Pyron Demitri's, Donovan Victor's; the two curves differ by
exactly 2 rows at every attacker column (±1 on throws, +2 on Demitri's 5HP
against Phobos, +1 on Victor's 5HP). The damage code reads the victim's own
row (full id), so rows 0x10/0x13 are the tenants' own storage and no legacy
character reads them — the possible data-only route (the 14z-118 port_param32
pattern); ~~the threshold read's index is NOT yet measured~~ **both reads' indexes MEASURED
14z-169 (`tests/audit_defense_row_reads.sh`): over the whole corpus — the naming victim and
attacker parts and every suite replay on our build, every suite replay on pristine vsavj — each
defense and threshold read took the VICTIM'S OWN id, tenants included (Donovan 394 hits, Phobos
38, Pyron 28), identified by the hitbox base `+0x60`, never by `+0x382`.**

## What this covers

Two tables in the damage chain are indexed by the **victim's**
character id (see `docs/game/engine_internals.md` "The DAMAGE
pipeline"); they are the only chain tables that differ between the
games, and only on per-id rows (the roster shuffle):

| table | vsavj | vs2 | shape |
|---|---|---|---|
| defense curve | `PRG:0x0B8940` | `PRG:0x0D2ABE` | 32 B per id row |
| low-HP rally threshold | `PRG:0x0BCC80` | `PRG:0x0D6E1E` | 1 B per id |

Attack-side parity is CLOSED (14z-85f: tables byte-equivalent, the
x028122 staging fix); this decision is defender-side only — how much
damage the tenants **take**, and when their low-HP rally scaling
kicks in.

## The measured delta (build/out data views, 2026-08-13:
## vsavj d82320a0… / vs2 ac31740c…; re-derive with the snippet below)

**Pyron (0x11): NO delta at all** — his defense row and threshold are
byte-identical between the games. His defense is native under either
option; this decision does not touch him.

**Defense rows** (the two rows are exactly content-SWAPPED between the
games — the roster shuffle moved the curves, not the characters'
tuning classes):

```
id 0x10 Huitzil   vsavj: fefefefeffffffffffff00000000000000000001010102020203030304040405
                  vs2  : 0000000001010101010102020202020202020203030304040405050506060607
id 0x13 Donovan   vsavj: 0000000001010101010102020202020202020203030304040405050506060607
                  vs2  : fefefefeffffffffffff00000000000000000001010102020203030304040405
```

**Low-HP rally thresholds** (HP at/below which the rally lookup
engages; round-start HP is 0x120 = 288):

```
id 0x10 Huitzil   vsavj 0x38 (56 HP)   vs2 0x28 (40 HP)
id 0x11 Pyron     vsavj 0x30 (48 HP)   vs2 0x30 (48 HP)   — identical
id 0x13 Donovan   vsavj 0x28 (40 HP)   vs2 0x30 (48 HP)
```

The low-HP rally SPICE rows (`0x0B8D40`/`0x0D2EBE`) are identical for
all three ids — only the thresholds differ.

Mechanical reading (disassembly-derived, direction not play-measured):
the defense byte seeds d3, which selects the row of the final 2D
damage map — the `fe/ff/00…` curve indexes lower rows than the
`00…07` curve for the same incoming class. Under the kept vanilla
rows, Huitzil rides the lower-indexing curve and the earlier rally
threshold, Donovan the higher-indexing curve and the later threshold —
i.e., their defender-side identities are effectively exchanged
relative to native. (Recorded on 2026-08-14 as "DECIDED (maintainer)": keep
the approximation — the maintainer's own words were not kept; superseded by the
2026-09-18 ruling quoted at the top of this file.)

Re-derive the delta at any time:

```sh
python3 - <<'EOF'
vj = open("build/out/vsavj_data.bin","rb").read()
v2 = open("build/out/vsav2_data.bin","rb").read()
for i in (0x10, 0x11, 0x13):
    print(hex(i), "def:", vj[0xB8940+i*32:0xB8940+i*32+32] == v2[0xD2ABE+i*32:0xD2ABE+i*32+32],
          "thr:", hex(vj[0xBCC80+i]), hex(v2[0xD6E1E+i]))
EOF
```

## What changing to native vs2 values entails, and how it was built

**BUILT 14z-170** by the data-only route (four `[[data_port]]` rows, the head of this file), not by the reader-site thunks the
2026-08 recipe below proposes; the recipe is kept as written, for the record.

Option (a) of 2026-08-14, now the ruled change. The recipe below was written in 2026-08 and
proposes reader-site thunks. Since 14z-168 a DATA-ONLY route is the candidate: both reads index by
the victim's id byte (`docs/game/engine_internals.md`, the defense port note), so rows and
threshold bytes 0x10/0x13 are the tenants' own storage. ~~It must first be measured that every
hit on a tenant victim reads them.~~ Measured 14z-169 (above): every hit in the corpus does. The maintainer's condition: no new frame of lag from the
combined fixes, and no change to any legacy character. The 2026-08 recipe, kept as written:

1. **Shape:** a variant-gated table extension on the
   `hitclass_map_extend` precedent — a generated thunk at each of the
   two READER sites, never an edit of the vanilla rows (legacy
   characters share them; the superset invariant forbids it).
   Reader sites (from the pipeline disasm): defense read
   `PRG:0x18C1C-0x18C26` (`movea.l #$B8940,a0; move.b (a0,d0.w),d3`)
   and threshold read `PRG:0x18C7C-0x18C82` (`movea.l #$BCC80,a0`).
   Each thunk: `cmpi` the victim id against the tenant ids → serve the
   placed vs2 row from wide_ext, else fall through to the vanilla
   table. Same-site multi-tenant declarations merge via the site_thunk
   compare-chain grammar (the 14z-84 displaced-head machinery).
2. **Body generation:** a `tools/gen_*` script reconstructing the two
   placed rows + two threshold bytes from the reference images
   (transplant licence asserted in code, the hitclass pattern), never
   hand-typed hex.
3. **Scope:** only Huitzil and Donovan rows/bytes — Pyron needs
   nothing. NOTE Donovan's row lives in `donovan.toml`, so adopting
   would supersede donovan-m3a (a full four-reference re-freeze), not
   just the H build — the largest cost of the change.
4. **Verification:** a defender-side damage A/B on the
   `89_hui_ex_fg_vs2` rig shape with the roles reversed (legacy
   attacker, tenant defender, fixed move), native vs ours, before and
   after; plus the standard ladder (solos re-frozen, merged legacy
   audit, run_suite).

## The observable of this ruling, measured (14z-145)

`tests/audit_tenant_throw_geometry.sh` froze 5 of 54 (victim, throw) cells of
Phobos's three throws differing from native by EXACTLY ±1 total damage — victim
0x10 ours +1 on all three, 0x13 ours −1 on all three, 0x0A ours −1 on Circuit
Scrapper only; ruled within tolerance — the maintainer, 2026-09-04: *"+/- 1
damage is within tolerances... interesting to root-cause it to deepen our
understanding of the engines though so let's keep that open for a future
session"* (quoted in `tests/audit_tenant_throw_geometry.sh`) — and kept as a
knowledge item — the tenant cells of that residue are what the 2026-09-18 ruling
removes. `tests/audit_defense_row_residue.sh` (a `-debug` read watch on
the defense table, ours vs native, four victims) names the mechanism: each leg
reads `row[victim id][attacker id]` of this table — the same index on both
legs — and the byte answered differs on exactly the rows this page lists as
swapped (0x10: ours 0 / native 2; 0x13: ours 2 / native 0) plus Sasquatch's
row 0x0A (ours 1 / native 0), a cross-generation retune of a LEGACY character
that is nothing of the port's; the control victim 0x03 answers 2 / 2. The
defense byte seeds `d3`, the row of the final 2D damage map, so a one-row
shift is a ±1 on a throw's damage. Re-ruling option (a) would move the two
tenant cells and leave Sasquatch's, which is vanilla vsavj's own data.

**After the fix (14z-170, M19):** the two tenant cells are gone — `audit_tenant_throw_geometry`'s residue is
Sasquatch's 0x0A alone, re-frozen. **ONE RESIDUAL IS OPEN:** Demitri's 5HP takes 12 HP from Phobos where native vs2
takes 11 (merged-m18 13), deterministic across RNG pins, with Phobos's curve row AND threshold word already vs2's —
so the extra point enters elsewhere in the chain; cause unmeasured (GitHub #161). Reproducer:
`tests/audit_phobos_dmg_residual.sh`; the attribution class `PHOBOS-DMG-OPEN` (`tools/move_parity_attribution.py`).

## Cross-references

- `docs/game/engine_internals.md` — "The DAMAGE pipeline" (the port
  note there points here).
- `build/manifest/reconciliation.toml` — the table twin rows
  (`0x0D2ABE↔0x0B8940`, `0x0D6E1E↔0x0BCC80`, status verified).
- STATE 14z-85f — the decision brief and this ruling.
