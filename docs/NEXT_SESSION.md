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

*(The two carry-forward items are DONE — see the struck rows below.)*

- **`PRG:0x028D50` carries THREE names** — `effect_map_5051` (`huitzil.toml`),
  `hit_class_props_ext_hi/_lo` (`donovan.toml`), and the guard-MASH RNG mask
  table (`atlas/ram.md:156`). Establishing which is right is a MEASUREMENT.
  Still the item that most needs a ruling.
- ~~**The runner's barrier vs a pull queue**~~ **DONE 14z-144.** A FIFO token
  semaphore; co-residency established over 130/130 gates under a different
  pairing; measured **3.48x, 1.90h -> 1.21h, 41 min saved per sweep**. Note the
  absolute, not just the ratio: sustained four-way concurrency makes each gate
  ~35% slower on THIS host, so a model assuming constant per-gate cost
  over-promises. **That 35% is the MacBook's (8P+4E, 16 GB), not the queue's** —
  on a wider host the penalty shrinks and the queue's advantage GROWS, and
  `--jobs` above 4 starts paying. The number to RE-MEASURE on a new host is the
  mame lane's serial sum at N-way: if it stays near 3.13h where this one
  inflated to 4.23h, the contention was ours. Hosts on offer: the Ryzen 9 3900X
  (12c/24t) and the coming 5700G / 64 GB; `test_mame_parity` gates any move.
- ~~**The [VSP-178] recurrence**~~ **DONE 14z-144** —
  `tests/test_freeze_artifacts_current.sh`, ground-truthed on the three real
  historical stale states. Add a row when an artifact is tracked, derived from
  the build set, and not already covered by a ci_static staleness gate.
- **EXTEND the freeze-artifact check to `docs/project/patch_index.md`'s
  registration cells** — a NAMED candidate, small, and it has evidence rather
  than a hunch. That table has now gone stale in the same way TWICE: it says of
  itself that a cell read "UNREGISTERED … expectation sets NOT yet frozen" from
  14z-127 until 14z-132, and the Pyron capture row did exactly the same from
  14z-143 until 14z-144, when the close-ritual audit caught it. The Donovan WIDE
  cell was worse — it still read "KNOWN OPEN DEFECT ON THIS TRACK" hours after
  the defect was fixed, frozen, released and pushed, which is [VSP-13]'s worst
  case: a header asserting the opposite of reality is what the next session acts
  on. **It fits the discriminator exactly**: the cells are derived from the build
  set (fingerprints, build dirs, freeze names, registration status) and NO
  ci_static gate checks them. **Shape:** parse the fingerprints and `build/<dir>`
  tokens out of the table and require the ones marked CURRENT to be the current
  freeze's — the registry and `run_all_emulator.sh`'s defaults already say what
  that is. **Beware** the same trap the re-point sweep hit: a `<freeze-name>
  (build/<dir>)` pairing and a `prior …` clause are HISTORY, never targets, so
  the check must key on the CURRENT-marked cells only.
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

0. **Never edit `tests/` or `tools/` while a tier runs.** The runner detected
   this on 2026-09-09 and named the file, and the wrong conclusion was drawn
   anyway — so it now offers BOTH causes, marks the affected failures
   **SUSPECT** by name, and puts that in the SUMMARY. If a run says SUSPECT,
   re-run on a quiet tree before treating anything as a finding.
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
