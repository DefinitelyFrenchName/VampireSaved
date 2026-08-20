# THE HARDENING REGISTER — crash-candidate inventory of the merged build

Opened 14z-100 (2026-08-20, maintainer-directed): "comb the merged image
for things that might cause a crash — vanilla code pointing at non-vanilla
targets, tenant code overriding existing calls/hooks, bad pointers —
identify candidate areas, then triage." This page is the living register:
what the classes are, what is measured, what is reviewed, what is queued.
Instrument: `tools/audit_pointer_flow.py` + `tests/test_pointer_flow.sh`
(frozen baselines in `tests/expected/pointer_flow/`).

## The partition (why "the immense majority is safe" is measurable)

Rule-4 provenance makes the maintainer's intuition mechanical. On
merged-m4 (`build/m3b_merged11`, 802 ops), the comb classified **~166,000
addresses** introduced or referenced by the patch:

| class | count | verdict |
|---|---|---|
| VANILLA (target < 0x400000, untouched) | 125,610 | presumed safe — the masked oracle corpus proves behavior continuously (the superset invariant) |
| PATCHED (target inside patch-written bytes) | 31,315 | ported/generated content referencing itself — extraction is oracle-validated |
| RAM | 6,929 | data targets; behavior-gated |
| PATCHED-TRIPWIRE | 185 | references deliberately parked on planted ILLEGALs (loud by design — see below) |
| HW (CPS-2 registers/VRAM/QSound, per MAME's map) | 141 | normal hardware I/O |
| SENTINEL (exactly 0x00400000) | 16 | the vanilla table-terminator value; a consumer walking PAST its family dereferences it — the #92 crash class. Not flagged; counted so growth is visible |
| WIDE-CONTENT (gfx-channel content patch.json never writes) | 1 | the reason "hole" is decided on the ARTIFACT's bytes, not the op list |
| WIDE-HOLE flagged | 2 STRONG + ~1,130 WEAK | see below |

**STRONG findings (each individually reviewed before freezing):**

| finding | verdict |
|---|---|
| `movea.l #0x4C41E0` / `#0x4CA180` in the win_pal thunk at `0x4D0C60` | **BENIGN — BIASED BASES.** The sparse-block design: `a0 = block − id*0xA0`, so the engine's own arithmetic lands inside the real block above. Verified on the shipped image: hui block `0x4C4BE0` marker `0x37` = 5*0x0B, pyron `0x4CAC20` marker `0x50` = 5*0x10 (engine_internals "WIN SCREEN", the 5*row self-check). The only two deliberately-biased pointers in the patch — and the comb found exactly them, which is its negative-control story. |

**WEAK tier** (frozen by count, growth fails): 3 `move.l #imm` with odd
values in 0x4C-space (constants, not pointers) + ~1,127 bare longs in
data payloads whose values fall in WIDE range — packed non-pointer data
(byte-pair structures; the odd-valued ones are not even dereferenceable).

## The candidate classes for triage (H3 queue, priority order)

### 1. Uncovered word-form pc-rel escapes — the #103 class: **CLOSED
14z-100 H3.1, ZERO LIVE** (`tools/triage_pcrel_escapes.py`, verdicts
frozen by `tests/test_escape_triage.sh`, 25 sites):
- the 20-site huitzil `code` cluster: **ADJACENT-OK BY CONSTRUCTION** —
  every branch lands inside `x057456` at the SAME merged delta, so the
  pc-rel arithmetic resolves to the identical vs2 content;
- `x028122+0x112` (all three tenants): the reviewed jump-table framing
  ambiguity (donovan.toml note, mirrored to the H/P manifests); path
  hot-and-healthy 17 sessions; byte-twin recorded if ever proven live;
- `x068c78+0x1ca → 0x6b644` (hui/pyr): **census FALSE POSITIVE of the
  x065c22 class** — the 0x6000 word is the LOW HALF of the immediate in
  `move.l #$00026000,d3`, frame-anchored from +0x1c0 (a coherent
  interpolation loop; evidence in the manifests' notes).
The gate fails on any drift (a new escape, a placement turning
ADJACENT-OK foreign, a lost pcrel row) and carries a 269-verdict
must-fire control.

### 2. The 13 plausible reconciliation rows — TRIAGED 14z-100 H3.2
**Liveness measured first (the lesson: score is not risk; CONSUMPTION
is).** Method: for every ref in the tenants' extracts targeting a
plausible row's vs2 source, read the long actually SHIPPED at the
consuming site in each artifact's patch payloads.
- **9 of 13 rows are CONSUMER-LESS on all four artifacts** — including
  the score-ordered "top three" (the 0.90 `0x028122` row, both
  multi-candidate 1.00 data rows). Zero risk today; exposure is only a
  future region whose refs resolve through them.
- **4 rows are LIVE** (consumed by all three tenants — a per-strength
  dispatch-handler family, the `102e0007 323b0006 4efb1002` prologue):
  - `0x042e92→0x041c7e` (0.98), `0x042f3a→0x041d26` (0.98),
    `0x043cba→0x042aa6` (0.98): **VERIFIED-BY-REVIEW** — identical
    dispatch headers, diffs are sparse jump-table words + cross-game
    body drift, candidates unique or clearly leading.
  - `0x0448a6→0x02563e` (0.94): **SUSPECT — likely WRONG SIBLING.**
    Archaeology: the row dates to M2a stage 4; the batch's window
    ladder shows the match came from the LAST-RESORT 0x20 window where
    FOUR candidates tie at 0.94 (family prologue only) and the first
    was taken. Every richer window (0x40/0x60/0x80) unambiguously
    prefers `0x45fcc`/`0x4367a` (mutual vsavj content-twins — the #91
    twin-trap shape; first 24 bytes IDENTICAL to the vs2 source where
    `0x2563e` diverges immediately, 11/32 bytes). Ships as one entry of
    a `jmp abs.l` dispatch farm in all three tenants (donovan
    code+0x3088; the sibling entry targets 0x43634 — the SAME
    neighborhood as the better candidates). **Neighbor-anchoring settles
    the target: the farm's case-2 sibling is the VERIFIED row
    `0x044860→0x043634`; our source sits exactly 0x46 after 0x044860 and
    `0x43634+0x46 = 0x4367A` — routine boundaries align at that spacing
    in both games. Right answer: `0x04367A` (with 0x45fcc its vsavj
    content-twin — the runtime trace picks between the twins at fix
    time).** Reachability: COLD — GUARD_PROBE at the farm entry's PC
    fired ZERO times over 21_don_mash + the full 40,620f marathon.
    **GitHub #107**; the re-resolution moves shipped bytes → the next
    window.

### 3. The 113 planted tripwires, ranked by reachability (MEDIUM)
69 distinct unresolved vs2 targets (donovan 23 / huitzil 46 / pyron 44),
inventory in `patch/patch_notes_fragment.md`. **Reachability now
measured on the current freeze** (14z-100, `audit_tripwire_reach.sh`
re-pointed): six marathon legs END 40620, zero fires. Rig-bounded — the
next ranking signal is crossing the fragment's per-target attributions
with `dispatch_census.toml` + wider rigs (H4).

### 4. The 89 accepted-broken pc-rel DATA escapes (LOW-MEDIUM, frozen)
`build/manifest/pcrel_escapes.toml` (69 hui / 10 pyr / 10 don): "an
escape whose table did not travel resolves elsewhere BY CONSTRUCTION" —
accepted dead paths, frozen since 14z-94, inventories measured IDENTICAL
on the m9/m18/m12 generation (14z-100 re-point). A pass means unchanged,
not safe. **KNOWN GAP: the MERGED image is outside this freeze** —
`verify_pcrel_data.py` needs `extract/`, which merged builds don't carry
(they compose the solos' extracts). Extension = teach it an external
extract + merged placements. Filed on GitHub.

### 5. Known-uncovered DYNAMIC surfaces (H4 rigs, not pointer bugs)
- pool-vs-pool projectile contact (121 type≥64 objects one collision
  away from the hit-class map; no rig produces a clash — the census
  denominator is 0 by rig failure, not absence).
- Shadow/Marionette with tenants (§4 names it "once enabled"; never
  exercised).
- L/M/H strengths of Phobos' historically-broken moves (field covered
  the moves, not every strength).

## Guard currency (the H2 sweep, 2026-08-20)
- `audit_tripwire_reach.sh` → current freeze artifacts; six legs green.
- `test_pcrel_escapes.sh` + `pcrel_escapes.toml` → hui45/pyron29/don_m9
  (inventories identical; merged gap filed).
- `test_pointer_flow.sh` NEW (ci_static): the comb, frozen baselines,
  synthetic must-fail controls both directions.
- `bases.tsv` re-derived + re-derive-at-every-freeze note (14z-100).
- `build_merged.sh` README template made generation-neutral (it stamped
  "753-op / NOT REGISTERED" into every build dir forever).

Maintenance rule: this register is updated in the same commit as any
change to the classes above (a new tripwire, a resolved row, a rig that
covers a listed surface). A register that lags its classes is the
reference-rot disease this program exists to cure.
