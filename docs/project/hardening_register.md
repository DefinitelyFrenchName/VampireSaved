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
    in both games. Right answer: `0x04367A`.** Reachability: COLD —
    GUARD_PROBE at the farm entry's PC fired ZERO times over
    21_don_mash + the full 40,620f marathon.
    **PRE-WORK EXECUTED 14z-101 — the twin question is answered
    STATICALLY, no rig needed:** both games carry the analogous farm
    natively as `jmp abs.l` sequences (vs2 `0x5C508+` ↔ vsavj
    `0x5436C+`, identical preludes/epilogues), and slot-for-slot vs2
    `0x448A6` ↔ vsavj **`0x4367A`** (code ref `0x054380`). The data
    tables (vsavj `0xBF330+` ↔ vs2 `0xD94D0+`) corroborate — and show
    `0x45FCC` is NOT an interchangeable twin: it holds the NEXT slot
    (pairs with vs2 `0x471E8`) and has zero vsavj code refs. Content:
    6 diffs / 0x2E bytes vs `0x4367A` (all reconciled operands) vs 24
    for the committed `0x2563E`. The adjacent OPEN row `0x448D4`
    farm-aligns to `0x436A8` by role but the routines genuinely
    drifted (22+ diffs) — it stays open, role-anchor recorded.
    The matcher-hardening half is LANDED inert: `reconcile_batch`
    refuses a tied top at any window (open + `TIE-Nxs.ss-wN` note;
    gate `test_reconcile_matcher` §6; live control: fresh `0x448a6`
    now returns open/TIE-4x0.94-w0x20; `test_m3a_reproducible` PASS —
    build-inert). **GitHub #107**; the row flip to `0x04367A`
    (verified, callsite-anchored) moves shipped bytes → the next
    window, alongside #109 (the clone-beam 0xA00-low fix).
    **SHIPPED 14z-102 (donovan-m10 / huitzil-m19 / pyron-m13 /
    merged-m5): #107 CLOSED; the row reads `0x04367A` on every build
    since.** (Status added 14z-114; the paragraph above is as written.)

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
not safe. **THE MERGED GAP IS CLOSED (14z-101, GitHub #106):**
`verify_pcrel_data.py` takes `--extract` (a tenant's pinned extract) +
`--placement-suffix` (`@huitzil`/`@pyron` — merged placement keys), and
the gate's three `[merged_*]` legs freeze the merged image BY REFERENCE
to the solo sections (measured IDENTICAL on m3b_merged11, 89/89 still
BROKEN on the merged placements too; wrong-suffix must-fire control).
Also made deliberate on the way: the tool's program-zip choice (it
picked `vsavjw.zip` over the gfx donor `vsav.zip` by listdir accident).
Re-point the `[merged_*]` sections at every merged freeze.

### 5. Known-uncovered DYNAMIC surfaces (H4)
- **pool-vs-pool projectile contact: RIG BUILT — and #108 RESOLVED
  NOT-A-DEFECT (14z-101 writer hunt; measured NATIVE PARITY).** The
  14z-100 finding here read "satellites carry collision word `+0x18 =
  0x1000` where native carries `0x6000` and consequently never enter
  the sweep" — **the causal chain is RETRACTED on every link**:
  - `+0x18` is the per-char **OBJ BANK WORD** (table `PRG:0x282D4`,
    writer `PRG:0x282C0` — the 14z-62c row). Ours reads 0x1000 because
    our own `obj_bank_word_slot` variant rows PATCH the table
    (0x282F4/F6/FA := 0x1000, all three tenants — deliberate and
    load-bearing: WIDE group C bank 4; 0x6000 there re-garbles tenant
    sprites). The 14z-100 "no patch op covers the table" claim was
    false — the -debug analysis read the PRISTINE table, and the
    "instrument paradox" dissolves: the two instruments never
    disagreed about the write; the -debug leg's "0x6000" was INFERRED
    from the wrong image (trace_writes logs registers, not the datum).
  - The sweep entry gate (vsavj `0x1A734` / vs2 twin `0x19144`,
    instruction-identical) never reads `+0x18`. It requires alive
    (+0x00==1) on both, team `+0x70` DIFFERING, and hit-row `+0x94`
    NONZERO ON BOTH, then the box overlap via `+0x80`.
  - **Native vs2's satellites also carry `+0x94 == 0`**, refreshed to
    0 every live frame from their own record data (ours `PRG:0x545DC`,
    native sibling `0x5C7BC`; whole-run FBNEO_HTAP on all 8 slots'
    +0x94 lanes, both legs — only the flare control hit-activates,
    `0x1f` in both games). Cosmo satellites are projectile-sweep-inert
    NATIVELY; ours match native behavior at the deciding byte.
  The Huitzil/Donovan `+0x18` breadth item is answered by inspection:
  their words are their own bank rows by the same design (H row 0x10 and
  D row 0x13 = 0x1000, documented in their manifests) — no exposure.
  `tests/audit_projectile_clash.sh` now freezes the PARITY signature
  (control >=100 fires; tenant word 0x1000 / +0x94==0 / 0 fires; a
  NATIVE anchor leg proving vs2's satellites 0x6000 / +0x94==0) and
  REFUSES the former fix mode. The census's tenant-zero remains a
  contact-coverage fact, not a defect artifact.
- **THE FOREIGN-DRAW CLASS (named at #109, 14z-101) — the instrument
  gap behind "why did only Phobos' beams break".** Two sprite-defect
  classes exist and only ONE has an instrument: (a) remapped-but-
  uncopied (bank rewritten, tile empty → solid rectangle) — caught by
  `audit_empty_tiles`, complete over what its replays draw; (b)
  **never-remapped procedural codes** (a self-composing list handler
  emits vanilla-bias/vanilla-bank codes for ported art → draws from
  the WRONG SPACE, structurally healthy-looking) — #109's class, and
  `audit_empty_tiles` PASSES on the defect event (measured 14z-101,
  all three tenants on rig df/100). Exposure is census-bounded:
  Phobos 26 type-4 procedural lists / Donovan 1 / Pyron 0
  (`test_list_type_census`), which is WHY the class bit him
  exclusively. QUEUED INSTRUMENT: the paired-draw census — ours-vs-
  native drawn-code-family A/B at anchors (the manual method that
  caught #109, generalized); natural home = the #109 fix's
  verification. **CONFIRMED BY THE MAINTAINER (2026-08-21): the #109
  window covers ALL 26 sites' composition plus Donovan's single site
  — the class retires by enumeration, not just the beam symptom.
  Pyron safe by census (0 sites).**
- Shadow/Marionette with tenants (§4 names it "once enabled"; never
  exercised).
- ~~L/M/H strengths of Phobos' historically-broken moves~~
  **FIELD-CONFIRMED CLOSED (maintainer, 2026-08-21):** the five moves
  (236+P, 236+K, j.214+K, 236+2K, 214+2K) worked through EACH button
  strength by hand — correct; "as are all moves except guard cancel
  exclusives" (GC-exclusives are rig-only by the maintainer's setup —
  Phobos' Reflect Wall is covered by test_hui_pairs; see the GC
  coverage note below). Timeout wins also field-confirmed for all
  three tenants. The rigs-vs-hands routing argument above held: the
  structural half was already closed by H1/H3 + test_index_space, and
  the hands closed the behavioral half in one pass.
- **DF MECHANICAL ACCURACY vs VS2 — MEASURED 14z-101** (rigs
  tests/replays/df/97-100; framework table in STATE 14z-101): the
  GAMES' DF systems differ by design (vs2 = 2-stock universal buff,
  332f uniform, maintainer-confirmed; vsavj = 1-stock per-character
  modes — ours == pristine vsavj exactly on the legacy control).
  D/P DF field-confirmed correct; Phobos' clone train + movement
  ruled "excellent". ONE defect found and filed — **GitHub #109.
  [THE 0xA00-LOW MECHANISM RETRACTED 14z-102: the compared "segment"
  rows were the two games' STOCK-METER PIPS, constant fixtures. The
  re-derived mechanism (STATE 14z-102 + the issue's 14z-102 comment):
  ours emits the full native burst set CORRECTLY (group C, tiles
  byte-identical); the missing beam = the full-screen palette-line
  sweep never invoked on ours (the vsavj fade-stepper twin ~0x14168
  exists; the script's screen-palette event is dropped — the #101
  script-carried-id class) + the DF gold tint (our 14z-84 block;
  native's EX never tints) + burst occlusion behind the 4-copy train
  (CPS-2 back-to-front list render).]** **#109 SHIPPED 14z-102 as
  effect-class ROW 31 (the DF clone-mode beam emitter vsavj shipped as a
  stub; gate `audit_clone_beam_lines.sh`), CLOSED; the gold tint KEPT by
  maintainer ruling 2026-08-21.** As written before that landed: fix waits on the tint ruling
  and the palette-event hunt. (History: the earlier intermediate
  readings — "drawn-but-invisible markers", "never drawn", "0xA00
  low" — are all retracted in place in STATE 14z-101 (5)/(7)/(8).)
  ~~OPEN DECISION queued~~ DECIDED 2026-08-21 (maintainer, verbatim intent): "we absolutely, categorically, keep vsavj DF durations" — per-character, 1 stock, the vsavj framework as-is. If doubts ever arise about the exact per-tenant lengths, the MAINTAINER researches the period sources (Vampire Hunter, Vampire Collection, etc.); nothing is ours to retune.
  (The queued alternative — porting vs2's uniform 332 — is REJECTED.) Field pass still ongoing:
  projectile collisions.
- **the authoritative-guard corpus soak: BUILT AND GREEN (14z-101)** —
  `tests/audit_guard_corpus.sh`: the whole replay corpus (79 rigs,
  ~472k script frames) under the crash guard on the build under test,
  four legs (unpoked + P1 forced per tenant over the standard
  commit window; honest limits in the header). First full run on
  merged-m4: **316/316 END-clean, zero vectors, zero dead legs** —
  including 26_don_arcade_mash × 4 legs at END 40620. Must-fire
  control: the known hui41 crash reproduces and is NAMED (vec4 →
  unresolved 0x494de tripwire). Verdict maps kept under
  build/guard_corpus/. 2P diversity is partially covered by the
  forced legs + audit_continue_switch; dedicated 2P-diverse marathon
  rigs remain queued behind the two items above.

## Guard currency (the H2 sweep, 2026-08-20)
- `audit_tripwire_reach.sh` → current freeze artifacts; six legs green.
- `test_pcrel_escapes.sh` + `pcrel_escapes.toml` → hui45/pyron29/don_m9
  (inventories identical; merged gap filed). **Now hui49/pyron33/don_m15
  + `[merged_*]` on m3b_merged18 (re-pointed 14z-115, the select-wheel
  separation; inventories measured IDENTICAL again — no region moved).**
  `test_pointer_flow` baselines re-frozen 14z-115 with attribution (the two
  STRONG win_pal bases shifted +0x20 with the grown wheel record; WEAK
  data:long DROPPED 1-2 per build).
  **14z-117 (the Pyron-medallion freeze): hui50/pyron34/don_m16 +
  `[merged_*]` on m3b_merged19; inventories IDENTICAL (no region moved — ten
  in-place thunk bytes + one glyph); `test_pointer_flow` baselines re-frozen
  as merged-m12 / donovan-m16 / huitzil-m23 / pyron-m17: WEAK data:long +1
  on every build (the one new 4-byte glyph coord pair), STRONG unchanged;
  escape triage 25 verdicts identical.**
  **14z-117b (the random-select freeze): hui51/pyron35/don_m17 +
  `[merged_*]` on m3b_merged20; pcrel inventories IDENTICAL; escape triage
  25 verdicts identical with three merged landing addresses shifted (+0xC0
  Phobos / +0x30 Pyron — the two hole-b thunk bodies are allocated per
  tenant iteration ahead of the ext placements); `test_pointer_flow`
  baselines merged-m13 / donovan-m17 / huitzil-m24 / pyron-m18: solos
  IDENTICAL, merged's two STRONG win_pal bases +0x30, WEAK unchanged.**
  **14z-119 (the physics-port freeze): hui52/pyron36/don_m18 + `[merged_*]`
  on m3b_merged21; pcrel inventories IDENTICAL; escape triage 25 verdicts
  identical, NO landing address moved (three data value ops, no allocation);
  `test_pointer_flow` baselines merged-m14 / donovan-m18 / huitzil-m25 /
  pyron-m19: ALL IDENTICAL to their predecessors (STRONG and WEAK).**
- `test_pointer_flow.sh` NEW (ci_static): the comb, frozen baselines,
  synthetic must-fail controls both directions.
- `bases.tsv` re-derived + re-derive-at-every-freeze note (14z-100).
- `build_merged.sh` README template made generation-neutral (it stamped
  "753-op / NOT REGISTERED" into every build dir forever).

**[VSP-93]** Maintenance rule: this register is updated in the same commit as any
change to the classes above (a new tripwire, a resolved row, a rig that
covers a listed surface). A register that lags its classes is the
reference-rot disease this program exists to cure.
