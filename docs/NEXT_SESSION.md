# NEXT SESSION — orientation (rewritten at the 14z-147c CLOSE, 2026-09-10)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE MUST-FIRE MACHINE IS COMPLETE ACROSS ALL THREE TIERS. NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state (the close ends with a push
when all is green).

Landed this sitting (STATE 14z-147c): **must-fire PASS 3, the emulator tier** —
the 34 gates of the census's `retrofit-debt` class now declare their must-fire
control(s) under R10, print `CONTROL FIRED`/`DEAD`, and honour a
`CONTROL=<name>` mode that perturbs the gate's REAL measured input (a trace,
table, dump or image) and reaches the gate's own FAIL. The census is re-frozen
**83 declaring / 0 header-only / 0 retrofit-debt** — the retrofit is done across
portable, static and emulator tiers. Static strict 145/0/0 GREEN (the identity
bar, unchanged: the 34 are emulator-tier). VERIFIED end to end on 14 cheap gates
spanning every shape; two fixes caught (the `CONTROL`-env collision in
`test_random_select_tenants`, renamed `PREV_BUILD` and made self-contained; and
`audit_walker_repoint`'s positional-arg mode). Commit `f8b8ee28`.

## START HERE — what is open

- **Verify the 34 emulator-tier modes HONOURED at the next freeze/release sweep.**
  This is the designed completion of pass 3: `run_all_emulator.sh --controls`
  runs each declared control as a `CONTROL=<name>` mode and requires the gate's
  own FAIL. The ~20 expensive gates (the reducers, the four MiSTer/Verilator
  gates ~1h each, `audit_guard_corpus` ~41 min) were NOT run this sitting —
  their modes reuse shapes already verified on the 14 cheap gates. Watch for a
  mode that REFUSES because a prerequisite is pruned on the host (a control build,
  a recording, no Verilator/jtcores): that is a dead mode, not a pass, and the
  runner counts it. `test_mister_prg_window`, `test_mister_sdram_census`,
  `test_mister_obj_oracle`, `test_mister_tenant_oracle`, `test_pod_black_foot_palette`,
  `audit_guard_corpus` all REFUSE cleanly when their prereq is absent.
- ~~**The open decision** (STATE "Decisions pending", the must-fire entry): the
  cadence of `run_all_emulator.sh --controls` at release — recommendation (a),
  the release checklist, measured first at the next release run.~~ **DECIDED
  2026-09-10 (14z-148): (a)** — `--controls` is part of every RELEASE run, not
  the freeze sweep; the invocation is in HANDOFF "THE EMULATOR-TIER COMMAND".
  Still to be MEASURED at the next release run (its cost).
- **Lift the controls reader into bbh** (`~/Developer/blackbox-harness`): bbh's
  `run-static` prints no controls block; the lineage's runner prints it only when
  a tier declares or executes something (F1 exact). F2 carries the known delta
  until bbh gains the reader (its `rebaselines.md` is where a re-baseline is
  declared, loudly).
- **Define what is IN a release, and ship the end-user how-to README**
  (maintainer, 2026-09-10): an explicit inventory of what ships and what never
  does (no ROM, no copyrighted asset — the user supplies their own dumps, as with
  SMS), a README with the per-platform how-to, and the roundtrip gate asserting
  both. Start from `docs/project/release_format.md`; present the inventory before
  writing it (STATE "Decisions pending").
- **Zabel j.LK proximity guard** — its own session (recording first).
- **The community cross-check**: specials/supers/throws still have no naming
  rigs on vsavj; every cell on the page is arbitrated.
- Smaller: `audit_mask_window_ff42a2` deprecated-vs-case-specific;
  `release/merged-m15` never packaged; #112 option (B); the living-docs
  generalisation (ruled, not scheduled); the wider-host re-measure of the
  pull queue's gain; the `hit` rigs' LP events whiff at contact range.

## TRAPS PAID FOR THIS SITTING — read before the next retrofit or fork fan-out

1. **A gate that uses `CONTROL` as its OWN env var collides with the must-fire
   mode selector** — `vs_ctl_mode` REFUSES the gate's default `CONTROL` value and
   the plain run dies; rename the gate's variable (project gotcha, 14z-147c).
2. **Prefer a self-contained control over one that depends on a second build dir**
   — a pruned build makes the mode REFUSE on every host that pruned it, reading as
   a sweep failure; perturb the gate's own data instead.
3. **Fork editing parallelises the tedium but its observability is poor** — a
   killed fork leaves a half-edited file, and a confused fork can misreport (one
   fork this sitting hallucinated being the parent). Audit the tree with `git
   diff` and `sh -n`, never the fork's self-report; disjoint file sets prevent
   real conflict but do not prevent partial files.
4. **A mode that would SKIP or exit 0 under `CONTROL=<name>` is LIES, not a pass**
   — where a prerequisite is absent, REFUSE (exit 3), never self-skip.
5. **`vs_ctl_dead` returns 1** — under `set -e` guard it (`|| fail=1`) or use a
   plain `echo "CONTROL DEAD: …"`; a bare `[ ] && f` as a statement still aborts.

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
