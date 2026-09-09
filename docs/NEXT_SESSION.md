# NEXT SESSION — orientation (rewritten at the 14z-144 CLOSE, 2026-09-09)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M18 IS FROZEN AND RELEASED. THE OPEN-ITEMS LIST LOST ITS "START HERE".

The maintainer ruled the Donovan/Jedah cell (option (a)) and it shipped the
same session as **M18** — `donovan-m22 / huitzil-m29 / pyron-m23 / merged-m18`,
mark **M18**, `build/don_m22` `build/hui56` `build/pyron41` `build/m3b_merged26`,
stock twin `build/m5_stock17` (byte-identical, so `donovan-m19-stock` carries).
Static **142/0/0 GREEN strict**; suite GREEN 88/88 on all three solo tracks;
release `merged-m18` packaged for three platforms and round-tripping.
**Committed, NOT pushed** (nine commits).

**THE ONE THING THAT MAY STILL BE IN FLIGHT:** the 165-gate release sweep
(`--scope all --lane all --cadence all --strict`, log `build/emu_release_m18/`).
Check `results.tsv` before anything else — if it did not finish, resume it, and
if it is green the release run is COMPLETE.

## START HERE — pick from the open items; none is blocked on a measurement

- **`PRG:0x028D50` carries THREE names** — `effect_map_5051` (`huitzil.toml`),
  `hit_class_props_ext_hi/_lo` (`donovan.toml`), and the guard-MASH RNG mask
  table (`atlas/ram.md:156`). Establishing which is right is a MEASUREMENT.
  Still the item that most needs a ruling.
- **The runner's barrier vs a pull queue** — the maintainer's stated preference,
  agreed in shape, NOT built. Measured: the mame lane would go **1.90h -> 0.90h**
  at `--jobs 4`, and `--jobs 8` would actually pay. The design (a FIFO token
  semaphore whose TOKEN IS THE CLONE NAME) and the two things to establish
  first are in STATE "Decisions pending". Harness only; ~half a session.
- **The [VSP-178] recurrence** — two consecutive freezes shipped a stale
  romset-following artifact. The cadence column tells the RUNNER what to run and
  says nothing to the FREEZE about what to refresh. A static freeze-ritual check
  would have caught both. STATE "Decisions pending".
- **The Phobos ±1 damage residue** — 5 of 54 cells, WITHIN TOLERANCE, a
  KNOWLEDGE item. Cheap first step: is `0x0A` (Sasquatch) a cross-generation
  data difference rather than ours?
- **The community cross-check aerials** — needs a two-direction jump rig.
- **Zabel j.LK proximity guard** — its own session: a LEGACY patch, so its own
  expectation class and build flag, a recording FIRST ([VSP-20]), archaeology
  before theory ([VSP-14]).
- Smaller: the deferred `audit_mask_window_ff42a2` deprecated-vs-case-specific
  ruling; `release/merged-m15` never packaged; #112 option (B) kept open.

## WHAT M18 ESTABLISHED THAT OUTLIVES IT

**Enumeration finds omissions; targeted testing structurally cannot** ([VSP-179]).
Both capture-geometry defects were found by inventories — Pyron's row `0x11` by
the bank-map ownership audit, Donovan's `[0x0F]` by the full 640-cell matrix on
its first run, after seventeen sessions of throw work. A green targeted gate
covering three cells said nothing about the other 637.

**A gate that "caught the change" may have the defect written into it.**
`test_capture_kf_ownership` section 3 asserted the 14z-64 fix rides row `0x13`
on EVERY track — which IS the unconditional application that caused the bug.
Rewritten two-sided and ground-truthed BOTH ways (PASS on M18, FAIL on the
pre-fix M17 pair). Its must-fire control had been vacuous: it wrote a value
then asserted the value was not something else, never running the predicate.

## FOUR TRAPS PAID FOR HERE — read before the next freeze or sweep

1. **Build references exist in FOUR forms**, and a sweep matching only
   `${VAR:-…}` misses three: positional `${1:-…}`, bare `$REPO/build/…`, and
   **python literal lists inside embedded scripts**. The last is why
   `test_pcrel_escapes` reported "69 NEW escapes".
2. **`(verbatim; …)` suppression is per COMMENT BLOCK, not per file.** Scoping
   it per file silences every replacement below the first archive block.
3. **Never rewrite a `freeze-name (build/dir)` pairing** — "merged-m17
   (build/m3b_merged25)" is a dated FACT; rewriting the dir makes it
   self-contradictory. The 14z-130 trap, hit again.
4. **`BUILD=` is silently ignored by gates whose variable is `MERGED=`** or a
   positional ([VSP-107]) — grep the gate's own default line before quoting any
   per-build result. And `build_fingerprint.py --sha-only` SHORT-CIRCUITS before
   `--set-key`, so the two flags together silently return the program key.
   The release gate's `NAME` default is a RELEASE NAME, not a build dir, so no
   sweep or lock can see it — re-point it by hand at every freeze ([VSP-100]).

**IF A DOC IS TOUCHED:** `doc_anchor_census --check` + `checkdocshape
--no-pending` + `checkdocs` + `checkskills` + `gen_annotations --check` +
`gen_gate_index --check` + `gen_gotchas_index --check` + `gen_skill_guide
--check`, exit statuses captured directly — and in zsh, loop with `${=cmd}`.
**A running script is never edited** ([MSC-54]). **The static tier is never run
beside another gate run in this tree.**
