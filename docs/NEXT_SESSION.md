# NEXT SESSION — orientation (written at the close of 14z-94, 2026-08-17)

> ## **#91 AND #92 ARE FIXED ON THE SOLOS (14z-94), each verified against a
> ## LIVE CRASH on its pre-fix build.** The 8 bytes scheduled the Donovan
> ## match at **REVENGER'S ROOST**, vsav2's thirteenth stage, which vsav does
> ## not have; retargeted to **`0x0a` ABARAYA** on the maintainer's ruling.
> ##
> ## **STILL OPEN: the merged build and the re-freeze.** `build_merged.sh`
> ## stops at its own guard — 752 ops against the frozen 753 — and the delta
> ## is attributed to ONE `4afc` ILLEGAL, #91's tripwire disappearing.
> ## `tests/test_tenant_loop.sh:217` needs 753 -> 752, a frozen merge-gate
> ## constant, so it is a maintainer call. Then the merged gates, then the
> ## single re-freeze of huitzil + merged.

## Where it stands

| leg (40,620-frame arcade marathon, forced pick, sparse probe at `0x05ffb6`) | verdict |
|---|---|
| `pyron26` pre-fix (FROZEN) | **CRASH 15079** `vec3 PC 01afb6` — #92 |
| `pyron27` post-fix | **END 40620** |
| `hui41` pre-fix (FROZEN) | **CRASH 18337** `vec4 PC 0fb6e0` — #91 |
| `hui43` post-fix | **END 40620** |

The probe fired 3 times per leg, so it is armed rather than dead. New builds
`hui43` `da734d49` / `pyron27` `e29cac23`, both UNREGISTERED and UNFROZEN;
`hui41`/`pyron26` are untouched.

`tests/test_voice_row_range.sh` is now GREEN on the new builds (it stays RED
on the frozen ones, correctly). The historical shape it caught:

```
hui41/hui42 row 0x10: 0x18 at +0x01, +0x1a, +0x29, +0x31
pyron26     row 0x11: 0x18 at +0x01, +0x1a, +0x29, +0x31
don_m7      row 0x13: clean  (his row never lists his own class 0x13)
```

All eight are ONE shape: the paired table-A byte is class `0x13` (Donovan)
every time, 4/4 on both tenants and 0/12 elsewhere. Across vs2's 32 rows,
`0x18` appears 50 times and **all 50** sit opposite class `0x13`.

Vanilla never emits above **`0x16`** across all 1024 bytes of table B, and
`0x16` is exactly what the downstream table can service (derived
independently; the gate cross-checks the two and fails if they disagree).

**DECIDED 2026-08-17 (maintainer): ABARAYA (`0x0a`)** — "any stage except
Fetus of God, take the one that implies the least impact". Applied.
`tools/decode_stage_banners.py` names the twelve vsav stages, and poking the
word changes the venue on screen (measured: same match, same frame, different
stage). Once chosen: patch `huitzil.toml` + `pyron.toml` -> gate green ->
re-run `audit_tripwire_reach` -> **the single re-freeze of huitzil +
merged**, which also clears #91.

**CORRECTED 14z-94 — the 14z-93 close called this "a voice, so it is
audible" and predicted the round-end flashing would correlate with voice
events.** It is not a voice. `$FF8100` is the ladder's STAGE index: it drives
the stage-name banner on the arcade map screen AND the venue you then fight
in. The flashing prediction rested on the voice reading and does not follow
from the corrected one — treat it as open, not as supported.

## The chain, if you need to re-derive it

```
authored table-B row (0x18) -> stage list $FF1E50
  -> selector loop (0x00aee2) picks index 2 -> $FF8100 = 24
  -> 0x05ffa6: A0 = 0x26775A + 2*24 - 4 = banner-table row 0x1A, STORED to $1c(a6)
  -> consumer derefs the FOLLOWING row = 0x00400000, that table's TERMINATOR
  -> [0x400000] reads 0x7080 -> jmp (4,PC,D0.w) -> vec3
```

vsav's banner family is rows `0x0F..0x1A` (12 stages, values `0x00..0x16`);
vs2's is rows `0x13..0x1F` (13, values `0x00..0x18`). **Both games number
`v=0x00` at their own first row, so the twelve shared stages are identical at
identical values and the port owes NO renumber** — which is why the defect is
four bytes and not a whole table. Every ENGINE site is vanilla and unpatched;
only the authored ROW is ours.

**THE ANCHOR IS THE TRAP.** Each game's site anchors at the address of its
family's FIRST ROW, not the pointer table base (vsavj `0x26775a` = table+0x3C;
vs2 `0x2a0a96` = table+0x4C). Decoding vs2 from its base invents a tidy "+8
renumber between the games" that does not exist — believed for part of 14z-94
until both code sites were read. `tests/test_decode_stage_banners.sh` section
3 reproduces that mistake and requires it to fail loudly.

## Do not repeat these — five of my conclusions died by measurement

| published | killed by |
|---|---|
| "element-table base is 4 bytes low" | a probe at that writer got ZERO hits while the crash reproduced |
| "0x400000 is a stock sentinel WIDE makes live" | stock and WIDE both read `0x7080` |
| "the crash is HUITZIL-ONLY" | **Pyron crashes identically** under a sparse probe — it is a RACE |
| "the selector loop exhausts" | selector 2 < bound 6; it found a real candidate |
| "the value is tenant-specific" | Pyron computes the same pointer; the SLOT differs |

**Method traps that produced those, all now in GOTCHAS:** probes must stay
SPARSE (one firing 17,616 times made the crash vanish); `l@()` memory
conditions silently do not work in `GUARD_PROBE_COND`; never cross-correlate
frames between `-debug` and non-debug runs; do not use `bp_regs.lua` on a
timing question (it is a #10 +1 staging deviant); An-relative reads inside the
crypt window need the DATA view.

**"Huitzil-only" was also my argument for retracting the 14z-85f Sasquatch
link. Since Pyron IS in that recipe, that link is OPEN again.**

## Also settled in 14z-93

- **hitclass thunk: KEEP** (maintainer). Tenant census: **0 map entries over
  37 rigs against 121 pooled type >= 64 objects** — the gap is CONTACT.
- **#78 ratified**, **#90 fixed**, **#44 fixed**, **#41 CI added**, **#82
  fixed**, **#84 closed**, **H-vs-P stuck direction closed**.
- **#10** re-verified: NOT fixed, deliberately, now `deferred-with-reason`
  and gated. Its precondition (the legacy re-freeze) HAS been met, so it is
  ripe. Budget the RE-MEASUREMENT of five gates' frame constants, not the
  one-line edits. **Re-freeze nothing** — replay.lua is untouched.

## What 14z-92 was, in one line

**Five instruments had quietly stopped measuring**, and four of them were
GREEN or unrun rather than red. A decayed gate does not fail — it stops
disagreeing.

| instrument | broken since | presented as |
|---|---|---|
| `obj_records.walk` pointer pass | fired 14z-86 | a build defect (#75) |
| `test_merged_render_content` H legs | 14z-86 | a CONTENT REGRESSION |
| `audit_hitclass_map_cost` reference | 14z-86 / 14z-82c | would have blamed the thunk |
| `test_pyron_ladder` tenant selection | always | **built Donovan**, green (#84) |
| `test_pyron_blink` guard | 14z-87 | could false-REFUSE |

If you read one thing before touching a gate: **`docs/project/gotchas.md`,
"A frozen build stops being a usable REFERENCE when the profile bumps"** —
three references rotted this session (`hui31`, `pyron20`, `pyron17`).

## Two beliefs that changed

1. **Legacy DOES enter the hit-class map — 230 times, not zero.** The old
   census was two replays, both of which score zero. The fix is still sound
   (all indices far below 64, so legacy reads vanilla's own bytes); the
   ARGUMENT was wrong and is corrected everywhere it appeared.
2. **The tree contradicted itself on the QSound terminal byte** (#82):
   `build_qs_songs.py` says INCLUSIVE (packing law #3 — the sword-plant
   beep), `audit_qs_voice_batch.py` still justifies EXCLUSIVE with the
   pre-14z-87b belief.

## Do not repeat these

- #75's blocker **had already dissolved** before the fix — merged8 verifies
  green with the pre-fix tool. The fix removed a dice roll, not a blocker.
- "It may feel better" was **emulator-sided**. The project has NO measured
  performance-positive result. Do not cite the obj_hook cycles for it.

## START HERE — the open list, in order

### THE REQUALIFIED AUDIT BACKLOG (maintainer cleared `contested`, 2026-08-16)

Eleven findings from the 2026-08-15 adversarial review are now ACCEPTED.
Ordered by severity, and split by whether they can be started without a
ruling. The 21 still carrying `contested` are NOT in this list.

**NEEDS A RULING FIRST — 3 items, and two of them are one decision**

- **#30 + #24 + #29 ARE ONE CLUSTER, not three tickets.** #29 (~28 gates
  `exit 0` when their build inputs are absent) and #24 (the battery prints
  `BATTERY GREEN` anyway) are the same defect seen from both ends, which is
  why #24 carries `duplicate`; and BOTH fixes need the thing #30 says does
  not exist — a runner. Both handoffs propose the same mechanism: give SKIP
  a distinct exit (77, the automake convention) and have a runner tally
  PASS/SKIP/FAIL and refuse GREEN when anything skipped.
  **The ruling needed is #30's:** what runs the suite? The 14z-93 CI covers
  the 18 ROM-free gates and already fails on SKIP, so the pattern exists —
  the open question is the ~90 gates that need `$ROMDIR`, which CI cannot
  run. Note the blast radius both handoffs flag: flipping `exit 0` -> 77
  changes the contract for every existing caller, including HANDOFF's own
  documented command lines.
- **#27 — `build_merged.sh` cannot run from a clean checkout** (needs three
  untracked `build/*/extract` dirs). Rule 3 says the output set must be
  reproducible from pristine inputs at any commit; today the merged artifact
  is reproducible only on this machine. The ruling is what the recipe should
  be, since the script never calls `build_donovan.sh` and the knowledge
  lives as prose in HANDOFF.
- **#43 — `reconcile_batch.masked_search` is a drifted copy of
  `find_equiv`'s core.** Needs a ruling because the fix MOVES ROWS: the
  handoff measured several currently-`verified` rows becoming `plausible`
  under the canonical (uncapped) matcher. 357 rows across the three
  reconciliation manifests were generated by the drifted copy.
  **READ THIS AGAINST #91/#92 BEFORE SCHEDULING ANYTHING ELSE:** the handoff
  states at least TWO of the 41 `open` rows resolve with the canonical
  matcher, one at score 1.00. #91 was a missing reconciliation row that
  crashed the shipping build, and #92 is what resolving it exposed. So #43
  is not backlog hygiene here — it may be load-bearing on the current
  blocker.

**MEDIUM — no ruling needed**

- **#28** — `build_merged.sh` reads `$ROMDIR` without the mandatory
  `audit_roms.py` checksum gate. CLAUDE.md §3 is explicit; a builder that
  skips it can produce an artifact from an unaudited dump, unattributable
  under rule 4. Small, self-contained.
- **#38** — `run_replay_fbneo.sh` leaves a stale overlay `roms/` dir on the
  non-overlay branch. Same class as the 14z-90 runner-hygiene fix.
- **#42** — `_minitoml.loads()` silently switches parser by host Python and
  the guard exists in 1 of 11 manifest consumers. Rule 3 again: a
  host-dependent manifest parser makes "the build" a function of the
  developer's interpreter. Hit live this session — `tomllib` is absent on
  this box's python3. Fix without a ruling: a gate asserting both parsers
  agree on every tracked manifest.

**LOW — no ruling needed**

- **#18** — `patch_prg.py` applies every op with no expected-old-bytes and
  no source-set identity check. The old-byte verification lives in the
  GENERATOR against cached decrypted views; nothing joins that image to the
  one actually patched. Adding the check is inert if the tree is sound —
  and a finding if it is not.
- **#20** — `port_patch`/`data_port` do not assert `len(new) == len(old)`,
  so a hex-count typo silently resizes the emitted blob. Same shape: cheap
  assertion, possible finding.
- **#19** — `_PRG_RE` matches gfx members `vsw.41m`/`vsw.43m`, which the
  documented `--gfx 8` growth path creates. Inert today, wrong at the next
  member count the project has already written down.
- **#25** — `audit_wide_phase_a` A3 lets a dead measurement stand as a
  `note` and then publishes the permissive decision — against the rule the
  file's own A1 comment states.
- **#31** — `replay_guard.lua` ignores `MASK_RANGES` and has no
  input-integrity check while its header claims it "can substitute for
  replay.lua in any gate". Cheapest correct fix per the handoff is to make
  the claim TRUE (abort loudly when `MASK_RANGES`/`NO_INPUT_CHECK` is set)
  rather than porting the mask reader. Named blast radius:
  `test_crash_guard.sh` compares a guarded log to an UNMASKED expectation,
  so masking must stay opt-in or that gate goes red.

**DEFERRED WITH A REASON, AND NOW RIPE — #10 (severity HIGH)**
*"10 of 21 replay instruments feed inputs a frame later than replay.lua."*
Re-verified at HEAD 14z-93 and CONFIRMED maintainer-deliberate: the finding
is correct, it is mitigated, and the fix is deferred for a real reason.
Label `deferred-with-reason`; it stays open and stays `contested` by
decision, not by neglect.

- **State:** 21 replay-driving instruments, **10 deviant / 11 canonical** —
  the same 10 files, same two flavours the issue lists. Nothing fixed.
- **Why deferred:** the frame constants of the consuming gates
  (`test_beam_variants` DUMP_FRAMES, `test_tenant_hud` 3100/3110,
  `test_hui_df_style` OBJFR/PALFR, `audit_trap_parity` WINDOWS,
  `audit_voice_borrow` WINDOW=3985,4005) were tuned UNDER the drifted
  timing. Correcting the staging alone does not make them right, it
  silently RE-DATES them. The staging fix and the re-measurement are ONE
  change — which is also this issue's own handoff.
- **THE PRECONDITION IS NOW MET.** The gotcha scheduled it "after the
  legacy re-freeze"; that completed in 14z-91. It is ripe, not blocked —
  waiting on scheduling and on #91/#92 clearing under rule 6. **When it is
  scheduled, budget the re-measurement, not the one-line edits:** the code
  fix is one line per file in two flavours (group (i) stage
  `held[frame + 1]`; group (ii) parse `held[fr]`), and all the cost is in
  re-deriving those five gates' constants.
- **Mitigation is now real** (it was not): the gotcha promised every
  drifted instrument carried a banner and THREE did not — `bp_regs.lua`
  (none, and its header asserted the opposite), `ring_tap.lua` (none, and
  its output is frame-addressed), `read_tap.lua` (backwards direction).
  Fixed 14z-93.
- **Gated:** `tests/test_replay_stage_census.sh` pins the split at 10/11, a
  NEW instrument copying the wrong flavour FAILS, every deviant must carry
  the banner, and `replay.lua` must stay canonical. Set `EXPECT_DEVIANT=0`
  when the fix lands and it flips to asserting uniformity. **Strip Lua
  comments before censusing** — the banners quote `held[frame + 1]`, so a
  naive grep reads a drifted file as canonical (measured: it turned 10
  deviants into 3).
- **Do NOT re-freeze anything from this fix.** `replay.lua` and
  `replay_guard.lua` are both canonical and untouched, so no frozen log
  moves.

**STILL CONTESTED — 20 further items, deliberately not scheduled.** #22
(medium, `verify_pcrel_data.py` run by nothing), #77, and 18 low items.


- **#91 — A PLANTED ILLEGAL IS REACHABLE ON `merged-m1`. RULE 6: this is
  the only forward task until it is green.** Deterministic and reproduced:
  `hui41` CRASH 14767 and `m3b_merged8` CRASH 8887, both the tripwire for
  **unresolved vs2 `0x494de`**. **NOT Huitzil-only** — that was retracted
  14z-93: Pyron and Donovan's clean `END 40620` legs are a TIMING accident,
  and under a sparse probe Pyron crashes identically (#92). It is a RACE. Rig: `26_don_arcade_mash` (40,620-frame
  arcade marathon) with the forced pick — the suite's tenant rigs are too
  short to reach it and that replay picks a legacy character on its own,
  which is why this was invisible.
  **`0x494de` is a 32-bit software DIVIDE helper** (11 callers in vs2) and
  **vsavj has the byte-identical routine at `0x47fb6`** — a missing
  reconciliation row, not a missing feature. Choose the LIVE twin by
  tracing (it appears twice; content-twin trap). Do NOT remove or widen the
  tripwire — it is the detector, and 51 other deferred targets sit behind it.
  Costs a huitzil + merged re-freeze, so the row is a maintainer decision.
  Instrument: `tests/audit_tripwire_reach.sh`. **NOT the 14z-85f flaky crash
  reset** for the TRIPWIRE half (#91): Phobos was not in that recipe and the
  tripwire is Huitzil-only. **But #92 (the `0x1afb6` vec3) reproduces on
  PYRON, who IS in that recipe — so a 14z-85f/#92 link is OPEN.**

- ~~**GitHub #75 — `build_merged.sh` ABORTS on huitzil.**~~ **CLOSED 14z-92.**
  It was a VERIFIER artifact, not a build defect: `obj_records.walk`'s pointer
  pass re-derived record structure from the relocated image, so a straddled
  datum inside a real record became a valid record head under the merged
  placement window (+1 record, +67 entries, 34 out-of-band tiles). Fixed with
  the same `ptr_allow` treatment 14z-74 gave the sweep pass; gated by
  `tests/test_obj_record_walk.sh` (4 verdict controls, ROM-free, in
  ci_portable).
  **Read this part too:** the abort had ALREADY stopped happening. 14z-91
  moved `anim@huitzil` 0x41a7e0 -> 0x41a6e0 and the coincidence dissolved —
  merged8 verifies green with the pre-fix tool too (measured). Nobody knew
  because nobody re-ran `build_merged.sh` after 14z-91. **`build/m3b_merged8`
  (`952fc731`, 753 ops) now exists** and is the first merged build carrying
  the 14z-91 legacy fix — UNREGISTERED, and no merged CONTENT gate has run on
  it. That is the S6 list below.
- ~~THE BEAM VISUAL ON A MERGED IMAGE~~ **CLOSED** (maintainer,
  2026-08-16): *"beam visual is 100% clean, as is its sound."* The S6
  carry-forward is done, and the effect family — three defects, three
  root causes across 14z-70/71 — is closed end to end on the shipping
  artifact.
- **PHOBOS' HISTORICALLY-DEFECTIVE MOVESET IS FIELD-CONFIRMED ON THE
  MERGED BUILD** (maintainer, 2026-08-16): 236+P, 236+K, jump214+K,
  236+2K, 214+2K "in the variants that broke or were incomplete in the
  past and their ES variants". That is the beam family (14z-70/71, three
  root causes) and the Plasma Trap (out-of-range entry 82, the LOUD one),
  ES included — and an ES that fires is a stronger statement than it
  looks, because an empty meter silently downgrades.
  Combined with the rigs, the whole danger set for table 0x018468 is
  covered by whichever instrument can reach it: entry 82 by the
  maintainer AND `audit_trap_parity`; entry 83 (Reflect Wall, SILENT) by
  `test_hui_pairs` only — it is guard-cancel-only, so a rig is the ONLY
  way it can ever be confirmed. `test_index_space` /
  `test_variant_dispatch` / `test_index_window_thunk` all PASS on
  merged8 besides. **Remaining L/M/H strengths are unknown-unknowns, not
  a named mechanism — a nice-to-have, not a risk item.**
- ~~"IT MAY FEEL BETTER"~~ **CLOSED (maintainer, 2026-08-16): it was
  EMULATOR-SIDED**, not the ROM. No headroom/overrun A/B is needed and the
  obj_hook-cycle mechanism is NOT the explanation. Recorded so nobody
  re-opens it as a performance claim: the project has no measured
  performance-positive result, and this was not one.
- **`build/m3b_merged8` IS FROZEN as `merged-m1` (14z-92):**
  render-content, trap parity, FG parity, select-bank-gates and
  `audit_merged_legacy` (AUDIT-EXIT 0, leg a 47/47, leg b 6/6) all PASS.
  Frozen by TAG + HANDOFF row with **no `registry.tsv` row on purpose** —
  the legacy-only instrument `build/merged1` shares its program
  fingerprint, so a row would register the blanks build too. Read the
  `tests/expected/registry.tsv` header before touching that.
  Repaired in the process: `test_merged_render_content` named `build/hui31`
  as its huitzil reference — a pre-WIDE-v1.1 build MAME refuses — so H/P's
  only render gate had produced **no huitzil measurement since 14z-86**, and
  printed the dead leg as a content mismatch. Now points at `hui41` and
  reports an empty operand as a DEAD LEG. **D and P still name `m5_wide` /
  `pyron21`; re-point a row whenever that tenant is re-frozen.**
- ~~OPTIONAL, ~2 h: `tests/audit_merged_legacy.sh`~~ **RUN at the freeze,
  AUDIT-EXIT 0** (leg a 47/47 with 0 NOT-EVALUATED, leg b 6/6 guard-clean
  vs don_m7 / hui41 / pyron26). It was a re-run on this tree by
  construction; what it bought is the determinism confirmation — it
  rebuilt its instrument from scratch and reproduced 753 ops and the same
  fingerprint.
- The merged build now has its own class table, `tests/expected/merged1/` —
  read its README before touching a spec there, and do not copy a tenant
  set's line into it: the two tables are measurably not interchangeable,
  which is why it exists.
- ~~M4: `audit_hitclass_map_cost.sh` over the FULL corpus~~ **RUN 14z-92 —
  AND IT FALSIFIED THE CLAIM IT WAS FILED TO CHECK.** `hitclass_map_extend`'s
  adoption rested on "legacy never enters the map", measured over TWO
  replays — both of which happen to score zero. Corpus-wide (46) legacy
  enters **230 times** (`26_don_arcade_mash` 228, `24_don_winmash` 2). The
  fix is still sound: every legacy index is 0x02/0x04/0x09/0x0b, far below
  64, so legacy reads VANILLA's own bytes out of the thunk. The argument is
  now "legacy enters and gets vanilla answers". Section 1: 43/46
  bit-identical, 3 transient re-convergent, 0 dead. Claim retracted in
  engine_internals, HANDOFF, and both manifests.
- ~~**OPEN from #78 — two FBNeo-only phase classes.**~~ **RATIFIED
  2026-08-16 (maintainer) and implemented 14z-93.** Both are now a named §4
  class bounded by a FROZEN offset inventory (`$FF055B-D`; `$FF06D1`,
  `$FF06D4-D5`, `$FF06D9`, `$FF06DB-DD`), measured rather than transcribed —
  the 14z-92 note had recorded only the first byte of each run. Gate green.
  `ram.md:62` extended: the class is NOT tenant-content-only. Original entry: The new
  `tests/test_fbneo_legacy_oracle.sh` (the agreed partial) found, on its
  first run, differences that MAME does NOT show at the same frames:
  `$FF055B-$FF055D` (sound-driver work area, ram.md:74) and
  `$FF06D1/D4/DB` (OBJ-builder secondary stack, ram.md:62 "execution
  POSITION, not state"). Both are attributed and bounded to two named
  windows; neither is gameplay state. They are reported as `open:` lines,
  NOT as tolerances. **The ruling needed:** ram.md:62 records that class as
  appearing only on tenant-content replays where no vanilla oracle applies —
  it appears here on LEGACY content under FBNeo, which extends it. Per §4 a
  new tolerance needs sign-off. `FBNEO_ORACLE_EXPECT=exact` is the
  post-ruling target.
- ~~**OPEN from M4 — is the thunk still load-bearing?**~~ **DECIDED
  2026-08-16 (maintainer): KEEP `hitclass_map_extend`, at least for now** —
  *"we have more to lose by dropping it than keeping it."* Nothing to do; the
  row stays in `huitzil.toml` + `pyron.toml` and no build moves. The measured
  basis follows, and the ONE thing that would reopen it is named at the end.
  The tenant enters the map **0 times** over all 37
  hui+pyron rigs — while putting **121 objects of type >= 64 into the
  projectile pool** (9 distinct types, 64-72, in 22 of the 37 rigs). The gap
  is CONTACT, not absence: the sweep is POOL-vs-POOL, so a tenant projectile
  hitting a FIGHTER never transits the map. Each of those 121 is one
  collision away from indexing past vanilla's 64 entries.
  **The dead crash control is diagnosed, not mysterious** (section 4): the
  soak rig reaches the map 0 times, so the no-thunk twin has nothing to crash
  on — yet that same rig still spawns 13 type-64/67 objects. A RIG failure.
  Do NOT drop the row on it, and do not re-point it at a new crash address.
  **Count the rows carefully:** 93 stamp rows carry `type >= 64`, but only
  **36** are in the 64-75 projectile-pool band that can over-index this map;
  the other 57 are the 114-120 obj_hook family (owner-tag served, never
  reaches the sweep). 93 overstates the exposure 2.6x.
  **WHAT WOULD REOPEN IT (the "for now" clause):** a pool-vs-pool contact rig
  that section 3 then measures at 0 extension entries. Nothing else — and
  specifically not the dead crash control, which is a rig artefact.
- **OPTIONAL, and no longer blocking anything: author a pool-vs-pool contact
  rig.** No rig in the corpus produces one, which is why the census reads 0.
  `tests/replays/hui/88_hui_plasma_trap_contact.rpl`'s header names what is
  needed — "an opposing PROJECTILE to clash with, e.g. P2 Victor doing a
  pool-object move into the mine — not a walking fighter". Pyron's cosmo rigs
  are the richest source (17-28 type-66 spawns each), so a Pyron-vs-
  projectile-character pairing is the likeliest route. It would buy two
  things: the tenant census gets a real denominator, and section 0's crash
  control becomes revivable. With KEEP decided, this is coverage work rather
  than a decision blocker.
- The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- Round-end flicker (parked; needs the maintainer's recording).
- OPTIONAL / cosmetic (maintainer 2026-08-15): the merged-only
  P2-ring-on-Donovan medallion whitening; win-screen QUOTE (both tenants);
  region_space re-freeze; op-tagging for test_shared_writes. **Donovan's
  venue palette row 0x0F** joins this list — change A traded vs2's red
  statue ramp for vsavj's, which the scope ruling makes optional; the
  cost-neutral route back (init shim → the engine's own copy helper
  `0x1C3A4` → staging row 0x0F, i.e. the fade's SOURCE) is written up in
  `build/manifest/donovan.toml` above the retired rows.
- ~~H-vs-P stuck-direction (~1/30)~~ **CLOSED 2026-08-16 (maintainer):
  never reproduced on FBNeo at all, and not reproduced on any recent build.**
  Surmised to be either an emulator-side artefact or a symptom of the period
  when Pyron and Phobos SHARED code — which they no longer do (the 14z-85
  spawn-time owner tag gave the 0x54470 family per-tenant resolution, and the
  type_renumber path did the same for 114-119). Not carried forward. If it
  ever resurfaces, the first question is which emulator, and the second is
  whether any shared-resolver path has been reintroduced.
- Then MiSTer core surgery (stretch, DECIDED) — after the roster.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2

# the canary — safe as written since 14z-91
VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
  tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m7/mask)" 16_xemu_2p

MAME_ROMPATH="$PWD/build/don_m7/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_m3a_reproducible.sh                 # ~6 min, all four, now hard on content
tests/audit_walker_ghost.sh                    # ~5 min — the mask assumption
tests/audit_walker_repoint.sh build/don_m7     # ~5 min — caller completeness
tests/test_obj_walker_relocation.sh build/don_m7   # seconds, ROM-free
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
tests/test_obj_record_walk.sh                  # seconds, ROM-free — the #75 gate
tools/build_merged.sh build/m3b_merged9        # ~1 min; m3b_merged8 already built
```

## Rebuild recipes

```sh
KEY_SET=vsavj WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
  GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
  tools/build_donovan.sh 6 build/don_m7
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 ... build/hui41
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 ... build/pyron26
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock2
```
