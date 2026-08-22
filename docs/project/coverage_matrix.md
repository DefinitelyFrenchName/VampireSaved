# §4 COVERAGE MATRIX — the mandate vs the corpus, measured (14z-104)

CLAUDE.md §4: "Minimum coverage for a ported character: vs each of the 18
(both sides), each stage, Dark Force activation/expiry, life-marker
transition, timeout, throw/tech situations, pursuit attacks,
Shadow/Marionette interaction once enabled."

This file is the census of that mandate against what actually exists, per
cell, with the EVIDENCE named (a gate, a rig, or a field report — a field
report alone does not close a cell; the persistent-suite doctrine wants a
rerunnable instrument). Update it in the same commit as any change to the
instruments it names. Scope note (maintainer, 2026-08-22): cosmetic and
single-player-only surfaces are DEFERRED INDEFINITELY — cells here are
judged on the 2P-competitive surface.

| cell | status | evidence |
|---|---|---|
| vs each of the 18, both sides | **COVERED** | `audit_roster_pairings.sh` — 111 guarded pairings incl. mirrors + verdict controls, ROM-derived expectations. Green on merged-m3 (14z-97) and merged-m5 (14z-104: re-run, 111/111, control rejected). ~5 min: run it at every freeze. |
| tenant vs tenant, all orderings | **COVERED** | `test_tenant_pairings.sh` (14z-95), six orderings; mirrors covered by roster_pairings. |
| each stage | **COVERED 14z-104** | `audit_stage_sweep.sh` — every tenant x all 12 stages WITH CONTACT (the $FF8100 poke at f2150/2200, measured load-bearing on the venue assets; 36/36 green on merged-m5 + no-poke and palette-distinctness controls). |
| Dark Force activation/expiry | **COVERED (rigs) — audit promoted 14z-104** | rigs `df/97-104` (framework, attacks, clones, contact A/B); gates `audit_df_gold`, `test_hui_df_style`, `audit_clone_beam_lines`. The 14z-101 framework table (cost 1 stock / durations 360/377/360) frozen as `audit_df_framework.sh` (green on merged-m5; legacy control + Phobos' documented activation flicker handled). |
| life-marker transition | **D covered; H/P GAP → rigs 14z-104** | D: `20_don_round2`, `23_don_matchwin`, `54_don_matchend_ko`. H/P: nothing existed — now `audit_tenant_downwin.sh` (rig `judge/01_timeout_lead.rpl` + KO pokes): every tenant as down-WINNER and as down-VICTIM, 8 legs + no-poke control, green on merged-m5. The victim legs are the direct #103-class lock (a tenant's death must be judgeable). |
| timeout | **legacy covered; tenants were FIELD-ONLY → rigs 14z-104** | legacy: `05_timeout_idle` (masked). Tenants: field-confirmed 14z-101 but no instrument — now `audit_tenant_timeout.sh` (HP-lead timeout via the $FF8109 timer poke; the judge must award the down to the leader on $FF8120; lead-existence asserted; inverted control judged the other way; green on merged-m5). |
| throw/tech: tenant as attacker | **D/H covered; P GAP → rig 14z-104** | D: `65_don_mirror_throw`, `27_don_throw_*`; H: `80_hui_grab_2p` + `test_hui_grab_victim`. P: nothing existed — now `audit_tenant_throws.sh` (rig `judge/02_throw.rpl`): every tenant THROWS the dummy (strength-independent toss verified as the throw discriminator vs the groundbound strike) — green on merged-m5. |
| throw/tech: tenant as victim | **D covered; H/P thin** | D: `96_don_victor_grab` + `audit_don_grab_pose` (#104). H/P as victims of a legacy command grab: #104 ported every attacker's capture_kf block and the maintainer field-confirmed Victor's grab on tenants; instrument legs for ALL tenants as victims are `audit_tenant_throws.sh`'s v-legs (Victor throws each tenant; capture pose + thrown reaction), green on merged-m5. |
| tech-hit (throw escape) | **GAP — OPEN** | no rig anywhere produces a throw tech. Needs a 2P rig with simultaneous-window inputs on both sides (edge-case-bias class). Queued; see "Remaining gaps". |
| pursuit attacks | **COVERED as DOWN-ATTACKS 14z-104 — naming question OPEN** | zero coverage existed. `audit_down_attack.sh` (rig `judge/03_down_attack.rpl`): every tenant hits a downed victim and every tenant IS hit while downed (8 legs + early-invuln control, green on merged-m5). MEASURED: the engine serves grounded heavies on downed opponents (11-14 dmg, per-character windows: Phobos wakes in 24f); a 12-candidate input screen produced NO leaping Night-Warriors-style pursuit. MAINTAINER QUESTION: does vsav carry a distinct leaping pursuit under some other grammar? If yes it gets its own rig; if no, this cell is closed as-is. |
| Shadow/Marionette | **N/A-until-enabled (recorded decision, not new measurement)** | class 0x0B is engine machinery, excluded from the roster matrix (`tests/expected/roster_pairings/README.md`). See the measurement note below. |

## Remaining gaps, in priority order

1. **Tech-hit (throw escape) rigs** — both directions (tenant teches a
   legacy throw; legacy teches a tenant throw). Simultaneous-press
   windows; the edge-case-bias class §4 calls out. No instrument yet.
   The TECH ROLL (moving recovery on knockdown — maintainer 2026-08-22)
   belongs to the same family and would also unlock the pursuit-connect
   refinement (a rolled victim is the pursuit's whiff case).
1b. **Pursuit CONNECT** — see the pursuit row: needs a rig where the
   flat window outlasts the flight on both games.
2. **KO-frame / corner / frame-1 edge cases per tenant** — §4's
   edge-case bias is served incidentally (mash/fuzz rigs, the guard
   corpus) but no tenant rig deliberately targets KO-frame events or
   corner interactions.
3. Shadow/Marionette interaction rigs — only if the modes are ever
   enabled (see the measurement note).

## Shadow/Marionette measurement note (14z-104)

Class 0x0B is the Shadow/Marionette machinery slot; the roster census
(`tests/expected/roster_pairings/README.md`, 14z-97) records it as "not
one of the 18 and not a selectable character" — a recorded decision this
matrix cites rather than re-measures. §4's clause is conditional ("once
enabled"), and nothing in the roster hack touches that machinery. If a future decision enables them, the interaction cells
(Marionette morphing INTO a tenant is the sharp one — it loads the
opponent's character data through a path no rig has run) go straight to
the top of the gap list.
