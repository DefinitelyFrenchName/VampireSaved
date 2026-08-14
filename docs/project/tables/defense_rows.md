# Tenant DEFENSE-side rows — DECIDED: keep the vanilla vsavj approximation

**Maintainer ruling (2026-08-14, 14z-85f): option (b) — the tenants
keep vanilla vsavj's defender-side rows.** This file records the
choice, the exact values on both sides, and the recipe for changing it
to native vs2 values if the ruling is ever revisited.

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
relative to native. The maintainer accepts this as the deliberate
vsavj-native approximation.

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

## What changing to native vs2 values would entail

The rejected option (a), kept here as the recipe should the ruling be
revisited (a player-feel report on tenant durability would be the
trigger):

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

## Cross-references

- `docs/game/engine_internals.md` — "The DAMAGE pipeline" (the port
  note there points here).
- `build/manifest/reconciliation.toml` — the table twin rows
  (`0x0D2ABE↔0x0B8940`, `0x0D6E1E↔0x0BCC80`, status verified).
- STATE 14z-85f — the decision brief and this ruling.
