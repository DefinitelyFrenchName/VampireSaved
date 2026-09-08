# NEXT SESSION — orientation (rewritten at the 14z-143 CLOSE, 2026-09-08)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE OPEN ITEMS ARE UNDER WAY. ONE SHIPPED; THE SWEEP IT PROMPTED FOUND THE NEXT ONE.

The maintainer took **Pyron's capture row `0x11`** from the open-items list and
it is **PORTED AND FROZEN as M17** — `donovan-m21 / huitzil-m28 / pyron-m22 /
merged-m17`, mark **M17**, `build/don_m21` `build/hui55` `build/pyron40`
`build/m3b_merged25`, stock twin `build/m5_stock16` (byte-identical, so
`donovan-m19-stock` carries). Suite GREEN 88/88 on all three solo tracks;
static 142/0/0; release `merged-m17` packaged; MiSTer tail done (fork
`b92bd2a9` pushed, series `0033`, pin bumped). **Committed, NOT pushed.**

Then the maintainer asked for the whole throw matrix rather than targeted
cases, and `tests/audit_capture_matrix.sh` — 640 cells, ~2 s — **found a
second defect of the same family on its first run**.

## START HERE — the one that is measured and waiting on a ruling

**DONOVAN THROWING JEDAH USES DONOVAN'S OWN VICTIM KEYFRAMES on every WIDE
build.** `donovan.toml`'s 14z-64 mirror-victim `fixes = "0x1E:0b30:0d88"`
rewrites victim entry `[0x0F]`: right on the STOCK track (Donovan occupies
`0x0F` there), wrong on WIDE (`0x0F` is Jedah, restored). 225 of 408 bytes
differ; the last keyframe is `(-61,166)` against Jedah's `(-76,32)`.
**PRE-EXISTING since 14z-64, identical on merged23 — not from the M17 freeze.**
Full entry with options in STATE "Decisions pending"; the cell is frozen as a
KNOWN-OPEN divergence in `audit_capture_matrix.sh`, so it cannot rot.

**RECOMMENDED FIRST STEP, ~4 minutes:** run the existing rig with attacker
`0x13` and victim `0x0F` —
`BUILD=build/m3b_merged25 VICTIM=0f tests/audit_pyron_capture_block.sh` needs
an attacker override, or copy its `run_pair` with `a=13`. The numbers above are
ROM bytes ([VSP-116]); the static read predicted the in-emulator result exactly
for Pyron, which is the licence to quote them, but the confirming run has not
been done. Then the fix is a one-line manifest change (gate the `fixes=` row to
the base-slot track) — and it MOVES SHIPPED BYTES, so it is another freeze.

## THE REST OF THE OPEN ITEMS, unchanged

- **`PRG:0x028D50` carries THREE names** — `effect_map_5051` (`huitzil.toml`),
  `hit_class_props_ext_hi/_lo` (`donovan.toml`), and the guard-MASH RNG mask
  table (`atlas/ram.md:156`, the mizuumi Tech-Hit Chance Tables). Establishing
  which is right is a MEASUREMENT. Still the item that most needs a ruling.
- **The Phobos ±1 damage residue** — 5 of 54 cells, WITHIN TOLERANCE, a
  KNOWLEDGE item. Cheap first step: is `0x0A` (Sasquatch) a cross-generation
  data difference rather than ours?
- **The community cross-check aerials** — needs a two-direction jump rig.
- **Zabel j.LK proximity guard** — its own session: a LEGACY patch, so its own
  expectation class and build flag, a recording FIRST ([VSP-20]), archaeology
  before theory ([VSP-14]).
- Smaller: the deferred `audit_mask_window_ff42a2` ruling; `test_header_defaults`
  and the positional `[name]` default; `release/merged-m15` never packaged;
  #112 option (B) kept open.

## OWED FROM THIS SESSION

- **The emulator tier has not been run on M17.** Static is green and the three
  solo suites are green, but `tests/run_all_emulator.sh` was not swept. Past
  freezes ran it (14z-130: "emulator tier 131/1"). Do it before any release.
- ~~`audit_legacy_pairings` on `build/m3b_merged25`~~ **RUN AND GREEN at the
  close: `LEGACY-PAIRING COVERAGE: PASS`** (`build/legacy_pairings_m17.log`), so
  the merged set — CARRIED from merged-m16 — is verified by the gate its own
  README names.
- **Widen the in-emulator anchors.** The static matrix now says which cells are
  worth an emulator run; the three behavioural gates still cover three cells.

## TWO TRAPS PAID FOR HERE — read them before the next freeze

1. **`run_suite.sh --freeze` into an EMPTY expectation dir self-freezes the
   whole legacy corpus**, greenly. The CARRY step is load-bearing:
   `cp <old>/*.masked <old>/*.skip <old>/mask <new>/` FIRST. Tell: a correct
   freeze prints `authored .masked expectation — not self-frozen` for ~52 of 88.
   Acceptance: the new set's `.masked` count equals its predecessor's.
   `docs/GOTCHAS.md` + HANDOFF's "Build registry" freeze block.
2. **The re-point sweep's "grep FOUR places" ([VSP-96]) is now FIVE** — the
   harness repo `~/Developer/blackbox-harness` carries this project's build
   literals as defaults (`lib/py/bbh/config.py`), so a lineage freeze rots it.
   `test_bbh_fidelity` is what catches it.

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited** ([MSC-54]). **The static tier is never run
beside another gate run in this tree, and nothing here is edited while it
runs** — it can be KILLED by the OS under memory pressure, which shows up as
`exit 143` with NO `GREEN`/`NOT GREEN` line: that run is worth nothing.
