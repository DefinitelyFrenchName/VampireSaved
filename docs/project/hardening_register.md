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

### 1. Uncovered word-form pc-rel escapes — the #103 class (HIGH)
Ported code branching outside its region; #103's arcade-death stall was
one. The 14z-98 census (STATE 14z-98 (1)), minus the window's two fixes:
- huitzil: `x028122 → 0x2cc64`; `0x574b0/b6/bc/c2` (20 consecutive
  sites — suspected adjacency class); `x068c78 → 0x6b644`
- pyron: `x028122 → 0x2cc64`; `x068c78 → 0x6b644`
- donovan: the 14z-98 (1) residue (14 word-form sites/5 regions minus
  x026142+x05c800; plus 10 pc-rel DATA escapes, 4 data_in_code)
Reviewed-not-rowed precedent: `donovan.toml:2424-2437` (three sites,
each with the reason). Any fix row = shipped bytes = the next window.

### 2. The 13 plausible reconciliation rows (MEDIUM-HIGH)
Guessed equivalences shipping in the played artifact
(`--allow-plausible` hardcoded, `build_merged.sh:60`; enumerate with
`grep -n -B4 'status = "plausible"' build/manifest/reconciliation.toml`).
Top three for verification: `0x028122→0x028e42` (0.90 — and doubly soft:
its census escape is a reviewed false positive), `0x130610→0x13dc36` and
`0x13f64e→0x151fd8` (1.00 but multi-candidate). Path: byte/semantic
comparison per row → promote to `verified` / re-match / demote to
tripwire.

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
