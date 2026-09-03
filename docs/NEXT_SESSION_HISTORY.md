# NEXT_SESSION — HISTORY (superseded openers, moved verbatim from `NEXT_SESSION.md`)

# NEXT SESSION — orientation (rewritten at the 14z-128 CLOSE, 2026-09-03)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. THE SWEEP IS COMPLETE.** 14z-128 built the emulator-tier runner
> ## and ran the whole tier in one command:
> ##
> ##     PASS 136   SKIP 0   FAIL 19   TIMEOUT 0   MISSING 0     (155 gates)
> ##     164 emulator-tier gates, 164 registered, 0 unregistered, 0 dead rows
> ##     working tree NOT dirtied by the run
> ##
> ## **ZERO SKIPS is the number that matters** — under the release policy a skip
> ## is a hard fail, and the tier ran without one. **NOT ONE of the 19 reds was a
> ## defect in the shipped artifact**; eight were closed in-session. Full results:
> ## `build/emu_sweep_14z128/results.tsv`, per-gate logs beside it.
> ##
> ## **Strict static is 129/0/0/0** — 126 at the 14z-127 close plus the three
> ## gates this session added (`test_emulator_runner`, `test_header_defaults`,
> ## `test_expectation_provenance`). Run it when the machine is QUIET: under
> ## sweep load it timed out at two minutes.
> ##
> ## **TO RE-RUN IT** (drop a row from results.tsv to re-ask just that gate):
> ##
> ##     ROMDIR=... tests/run_all_emulator.sh --lane fbneo --lane mame \
> ##         --scope all --jobs 3 --resume --timeout 14400 \
> ##         --log build/emu_sweep_14z128
> ##
> ## **`--timeout 14400` IS NOT OPTIONAL for this lane.** The 5400 s default is
> ## too low for the corpus soaks — `audit_guard_corpus` alone is 79 replays x 4
> ## legs = 316 guarded MAME runs, ~2 h at `JOBS=2`. A TIMEOUT row there means
> ## the runner's default, not the build. A per-row timeout in
> ## `ci_emulator.tsv` would be the real fix.
> ##
> ## Per-gate logs are `build/emu_sweep_14z128/<gate>.log`. Nothing is red that
> ## was not adjudicated below. No build byte moved this session.
> ##
> ## # WHAT THE RUNNER IS, in one paragraph
> ##
> ## `tests/run_all_emulator.sh` is `run_all_static.sh`'s twin for the tier that
> ## needs MAME, FBNeo or the simulator; `tests/ci_emulator.tsv` is its registry,
> ## one row per gate (`gate / lane / scope / cadence / args / note`), completeness enforced
> ## BOTH ways on every run. Lanes: `prereq` (instruments — runs FIRST,
> ## sequentially, and a red there STOPS the run, [CPE-24]), `fbneo`, `mame`,
> ## `mister` (opt-in, HOURS). `--scope all` adds the out-of-release-scope rows.
> ## Ground truth: `tests/test_emulator_runner.sh`. Read [VSP-164].
> ##
> ## **PREREQ LANE WAS 20/20 GREEN**, `test_mame_parity` included — so the
> ## instruments are sound and everything measured after them is evidence.
> ##
> ## # THE THREE REDS, ALREADY ADJUDICATED — do not re-freeze any of them
> ##
> ## **(1) `test_wide_profile` — WAS real, FIXED AND GREEN.** The reference
> ## binary was three days older than the harness patch; both binaries were
> ## rebuilt from one tree state and the gate PASSES in full — section 1, the
> ## emulator superset invariant, 12/12 replays bit-identical in work RAM AND
> ## framebuffer, plus inertness 12/12 and the B4 canary 12/12. The reference
> ## now lives at the canonical path the gate defaults to, and the gate refuses
> ## it if it ever falls behind the harness again. Kept here for the record:** The only FBNeo
> ## reference binary on this machine (`~/.cache/vampire-saved/fbneo_ref`) was
> ## built 2026-08-14 while harness patch `0001` last changed 2026-08-17. The gate
> ## now defaults to that path AND REFUSES it as stale, with the commands in its
> ## own failure message. **DO THIS FIRST WHEN NO LANE IS USING FBNeo:**
> ##
> ##     WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo ~/.cache/vampire-saved/fbneo_ref
> ##     tools/setup_fbneo.sh            # restore the WIDE binary — do not skip
> ##     ROMDIR=... tests/test_wide_profile.sh
> ##
> ## It cannot be done while the mame lane runs: reverting the profile patch hands
> ## `test_m2a_stage4_xemu` (position 14 of that lane) a non-WIDE binary.
> ##
> ## **(2) `test_phasec_image` — two STALE PREMISES, neither a defect in the
> ## build.** Section 1 compares against a hardcoded donovan-m2c-era stock
> ## fingerprint; the value it measured, `e86e1d04`, is exactly the M13 stock twin,
> ## so the pipeline reproduces correctly and the CONSTANT is what is wrong (fix it
> ## at the M13 registration, ideally by resolving through `registry.tsv` instead of
> ## a 40-hex literal). Section 4 zeroes CPU:$400010 expecting the Phase-C sound
> ## table, but wide_ext's first placement is now region `x101aca` = DONOVAN'S CPU
> ## AI SCRIPT BLOCK, which replay `12_donovan_vs_cpu` never reads because Donovan
> ## is the PLAYER there. Needs a zeroing target that replay reads, or a replay
> ## where a tenant is CPU-controlled.
> ##
> ## **(3) `audit_legacy_pairings` — WAS a real hole, now CLOSED, the spec
> ## ACCEPTED by `run_suite` on all three builds, and the gate itself RE-RUN
> ## GREEN (`LEGACY-PAIRING COVERAGE: PASS`). Its FAIL row in the sweep log is
> ## the pre-fix state — do not re-triage it.** `105_legacy_2pwin_auto` sat in the corpus from 14z-123 as LEGACY
> ## content guarded by NOTHING. Basis frozen, shape measured identical on all
> ## three builds, both flickers attributed, `composite vsavj/masked-v2 2713,5868
> ## 889-2491` authored in all three sets. A census says it was the only such hole
> ## of 88 replays.
> ##
> ## **(4) `audit_merged_vec3` — FIXED, and it was never the game.** It reported
> ## "rig dead — the replay or pokes moved" since 14z-109, when `A1`/`A3` were
> ## added to the PROBE line and its A0 extractor still required `A6` to follow
> ## `A0` directly. Parses by field name now; PASSES, and confirms the 14z-81
> ## satellite defect stays fixed. Its FAIL row in the sweep log is pre-fix.
> ##
> ## # THE SEVENTEEN REDS, BY WHAT THEY NEED — the whole triage, done
> ##
> ## 132 PASS / 17 FAIL of 149 recorded (prereq 20 + fbneo 6 + mame 129 = 155;
> ## the six unrecorded are all `out` scope). **NOT ONE was a defect in the
> ## shipped artifact.** Seven are already CLOSED:
> ##
> ## | gate | state |
> ## |---|---|
> ## | `test_wide_profile` | **FIXED, GREEN** — reference rebuilt; 12/12 superset invariant |
> ## | `audit_legacy_pairings` | **FIXED, GREEN** — the five-session hole, spec authored + accepted |
> ## | `audit_merged_vec3` | **FIXED, GREEN** — its parser; confirms the 14z-81 defect stays fixed |
> ## | `test_m2a_stage4_oracle` | **FIXED, GREEN** — re-pointed off an M2a build |
> ## | `test_hui_oracle` | **FIXED, GREEN** — re-pointed off pre-v1.1 `build/hui4` |
> ## | `audit_walker_repoint` | **VERIFIED PASS** — needed an operand; vanilla walkers take 0 hits |
> ## | `audit_empty_tiles` | **VERIFIED PASS** — needed an operand; no blank group-C tile |
> ## | `audit_mask_window_ff42a2` | **FIXED** — an instrument; SKIPs with its reason now |
> ##
> ## **STILL OPEN, and what each needs:**
> ## * `test_m2b_stage6` + `test_phasec_image` — **ONE cause: register M13** (b).
> ## * `test_pyron_soak` + `test_pyron_ladder` — **the only CRASH class**, on
> ##   stage-image builds the gates make themselves. `audit_guard_corpus` PASSED
> ##   on the MERGED build (1727 s, corpus x 4 legs), so the artifact is not
> ##   implicated. Needs a bisect; the select flow they force id 0x11 through has
> ##   changed three times since the soak was last clean (14z-67).
> ## * `audit_continue_switch` — the frozen arcade trajectory moved ([VSP-132]);
> ##   re-measure it, do not re-freeze the verdict.
> ## * **TWO DEAD MUST-FIRE CONTROLS, and this is the class to take most
> ##   seriously** — a dead control is how a gate goes GREEN while asserting
> ##   nothing, which is the failure [VSP-19] exists for. Both gates caught
> ##   their own and refused to give a verdict, which is the system working.
> ##   `audit_qs_voice_wav`: the LAST-voice control does not fire (a last-window
> ##   boundary in the checker; the audio itself is clean, 74 windows 0
> ##   suspects). `audit_hitclass_map_cost`: the no-thunk twin does NOT crash,
> ##   so an END-clean run proves nothing about the thunk — and its own message
> ##   forbids re-pointing the control until section 4's map probe says why.
> ##   **Neither is fixed by relaxing the control.**
> ## * ~~`audit_type_dispatch_range`~~ — **DROPPED 14z-129** (maintainer:
> ##   "better no test than a bad one"). Its probe site survived 14z-91's
> ##   walker relocation; its VERDICT CONTROL did not. [VSP-166].
> ## * `audit_region_movability`, `test_m2a_stage2_data` — `out` scope; a
> ##   duplicate manifest key and a half-pruned M2a dir, both diagnosed in the
> ##   registry rows.
> ##
> ## **THE CLASSES OF HARNESS ROT ARE NOW A DOCUMENT:**
> ## `docs/project/harness_hardening_history.md` (HIST) — seven classes, the
> ## runtime-vs-header diagnostic, and one entry per hardening pass back to
> ## 14z-94. **Read the classes before triaging a red gate.** The section
> ## below is this sweep's instance of them.
> ##
> ## # THE PATTERN IN THE SWEEP'S REDS, so the next batch is quick
> ##
> ## Ten reds by the time the lane was a third done, and **every one was the
> ## suite, not the build**. Four shapes, in falling frequency:
> ## 1. **A STALE DEFAULT BUILD** — the gate names an M2a-era dir nothing has
> ##    maintained (`test_m2a_stage4_oracle`, `test_m2a_stage2_data`). Re-point,
> ##    or give it `args` in the registry, then RE-RUN before believing it.
> ## 2. **A REQUIRED OPERAND WITH NO DEFAULT** — dies on its own usage line in
> ##    0 s (`audit_walker_repoint`, `audit_empty_tiles`). **That class is now
> ##    CLOSED**: a census found exactly two and both have `args`.
> ## 3. **A PARSER OR AN INJECTION THE TREE OUTGREW** — `audit_merged_vec3`
> ##    (PROBE line gained registers at 14z-109), `audit_region_movability`
> ##    (injects a `region_space` key donovan.toml has carried since 14z-111),
> ##    `audit_type_dispatch_range` (scraped a thunk 14z-91 deleted; DROPPED
> ##    14z-129 once the control proved unrebuildable).
> ## 4. **A FROZEN CONSTANT THE RULING MOVED** — `test_phasec_image`'s
> ##    donovan-m2c stock fingerprint, against a stock twin that legitimately
> ##    moves at every freeze ([VSP-94]).
> ## **A 0-SECOND FAIL IS ALWAYS SHAPE 1 OR 2**, and a fail far shorter than the
> ## gate's own quoted runtime means it bailed before measuring — read that
> ## number first, it is the cheapest triage signal in the log.
> ##
> ## # THEN, IN ORDER
> ##
> ## **(a) FINISH THE SWEEP** and triage what it finds. Adjudicate, never
> ## re-freeze: *"to know if we should fix the gate or what it caught, we must use
> ## data we can trust"*. `tests/expected/PROVENANCE.md` (new) answers the first
> ## question — which side rests on a measurement — in seconds.
> ## **(b) REGISTER THE M13 FREEZE — AND IT IS NOT HOUSEKEEPING: IT CLEARS TWO
> ## RELEASE-SCOPE REDS.** `test_m2b_stage6` and `test_phasec_image` section 1
> ## both fail for ONE reason — the current manifests build the M13 generation
> ## (fingerprint `e86e1d04`, the M13 stock twin) and M13 is not in
> ## `registry.tsv`, so the fingerprint dispatch finds no expectation set.
> ## Everything else in `test_m2b_stage6` passed: five guarded soaks END-clean,
> ## three pixel frames identical.** (`don_m19` / `hui53` / `pyron37` /
> ## `m5_stock14` / `m3b_merged22`, boot title SAVED): `run_suite.sh --freeze` per
> ## track (~5 h), registry rows, `freeze/*` tags, HANDOFF's build-registry row and
> ## "Current WIDE builds", and the one-line shared-writes re-point it owes (three
> ## `boot_title_saved_*` rows per tenant, already reviewed at 14z-127).
> ## **(c) NO RELEASE** — still deliberately held back.
> ##
> ## # DECISIONS — BOTH RULED 2026-09-03 (STATE "Decisions pending")
> ##
> ## **THE `gap_be27a` BANK-MAP ROW — RULED: FOLD IT INTO (b).** The maintainer,
> ## 2026-09-03: *"if folding it in allows us to pay only once, that's an easy
> ## choice: fold it in!"* Three couplings make one window cheaper than two, all
> ## verified: `charmap_gen.py` reads `bank_map.toml` and its pages are
> ## hash-locked; `test_m3a_reproducible` pins fingerprints per generation, so a
> ## post-registration change makes them stale; and `shared_writes.toml` is
> ## per-build reviewed and already owes M13 a re-point, which the exemption
> ## change would make a second pass. The M13 dirs exist but are NOT in
> ## `registry.tsv` — nothing is locked to them yet. Rebuild one track and diff
> ## `patch.json` FIRST: a named op delta gets understood before the ~5 h freeze
> ## suite runs, not after.
> ##
> ## **THE RELEASE SCOPE — RULED IN FULL, AND IMPLEMENTED.** 141 release / 23
> ## out, plus a NEW `cadence` column in `ci_emulator.tsv`. (a) The two #113
> ## gates -> `release` ("51s is basically nothing for a release"). (b) The
> ## MiSTer lane keeps release scope but splits onto a BITSTREAM cadence: it
> ## runs at every release, and at a freeze only when the freeze targets MiSTer
> ## — `tests/run_all_emulator.sh --freeze` drops the six and NAMES them, so
> ## the question is asked by the runner rather than remembered.
> ## `test_mister_sdram_census` and `test_mister_gfxc_fetch` follow the ROMSET
> ## and stay on every freeze. (c) The four `dev-ladder` gates stay `out`.
> ## Ground truth: `test_emulator_runner.sh` 6b + the section-10 validator.
> ## **TWO STANDING READINGS OF THE COLUMN, affirmed by the maintainer:** `out`
> ## is NOT "resolved" (`audit_hitclass_map_cost` is `out` and is a DEAD
> ## must-fire control) and `out` is NOT "quietly green"
> ## (`audit_region_movability`, `audit_phase_mode_cost` are red with exact
> ## diagnoses). *"keeping ourselves honest and rely on measurements, not
> ## inference or likeliness at all stages."*
> ##
> ## # OPERATIONAL, and each was paid for tonight
> ##
> ## * **Never edit a running `.sh`** — sh reads by byte offset ([VSP-110]). Two
> ##   runner fixes needed the sweep stopped first; killing it and relaunching with
> ##   `--resume` costs only the gates in flight.
> ## * **Do not run the static tier while the sweep runs** — it timed out at two
> ##   minutes under load. Batch static work, run it when the machine is quiet.
> ## * **Name `MAME_BIN` for a `vsavjw` run.** A bare `run_replay_mame.sh vsavjw`
> ##   with the default binary produces NO dumps and NO error.
> ## * **Name the SET for `run_suite.sh`, and READ THE DISPATCH LINE it prints.**
> ##   `tests/run_suite.sh` with no `[set]` argument defaults to `vsavj`, so a
> ##   WIDE rompath chain falls through to the pristine set in `$ROMDIR` and it
> ##   dispatches to the `vsavj` expectation set — [VSP-58] in a new tool. It
> ##   SAYS SO (`build fingerprint -> expectation set '...'`); that line is the
> ##   check.
> ## * The runner batches `--jobs` gates and waits for ALL of them before the next
> ##   batch, so one slow gate idles the other slots. A proper slot loop would help
> ##   throughput; it is not a correctness problem.
> ## * `test_build_ref_rot.sh` has NO synthetic must-fire control — its
> ##   extraction and verdict logic are inline and can only be exercised against
> ##   the real tree. Its pattern was extended twice (14z-97, 14z-128) by
> ##   hand-verification. Factoring the block behind a root override would let it
> ##   be controlled properly; small, and it is the one gate about rot that
> ##   cannot demonstrate it detects rot.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index --check`
> ## + `gen_gotchas_index --check` + `doc_anchor_census --check`, exit statuses
> ## captured directly. Regenerate the GENERATED indexes in the commit that changes
> ## what they index, and AFTER the prose (a 14z-128 red came from exactly that
> ## ordering slip — the shared-writes re-freeze moved `annotations.md` by 16
> ## addresses).


# NEXT SESSION — orientation (rewritten at the 14z-127 CLOSE, 2026-09-03)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. Strict static 126/0/0/0.** The tree carries a
> ## BUILT BUT UNREGISTERED freeze: `SAVIOR` -> `SAVED` on the boot name screen,
> ## five tracks (`don_m19` `8065bc92` / `hui53` `08944a7e` / `pyron37`
> ## `a43da974` / `m5_stock14` `e86e1d04` / **`m3b_merged22` `f42f7569`**, mark
> ## M13). `patch_index` records them **active, UNREGISTERED**: the expectation
> ## sets are the ~5h battery and were deliberately deferred. **Check
> ## `git status -sb`, not this line.**
> ##
> ## # THIS SESSION IS THE EMULATOR-TIER SWEEP (maintainer-ruled, overnight)
> ##
> ## *"at release time, ALL tests should be run ... unless explicitly approved
> ## AT release time, anything red, anything skipped is a hard fail of the
> ## release process"* — and *"we may not need ALL the tests for every small
> ## change but how could we not run them when we release, since we have them!"*
> ## Full policy in STATE's standing sections.
> ##
> ## **THE GAP (measured 14z-127): 167 emulator-tier gates; 29 reachable from a
> ## runner; 138 ORPHANED** — reachable only by typing a filename, so nothing
> ## would even ask them at release. **CAVEAT: that 138 is a GREP of mine**
> ## (tier from the generated index, "reachable" = a runner mentions the
> ## basename). Good enough to size the arc, not to plan against — **re-derive
> ## it inside the runner, where it becomes a maintained check.**
> ##
> ## **BUILD** `tests/run_all_emulator.sh` on the `run_all_static.sh` pattern:
> ## registries, PASS/SKIP/FAIL counted SEPARATELY, `--strict`, and the
> ## ANTI-ORPHAN registry-coverage check (without it the runner is just a
> ## smaller thing to forget to update). A missing prerequisite is a HARD FAIL,
> ## never a silent `exit 0` — `bat` counts a bare exit 0 as PASS, which is how
> ## "BATTERY GREEN" becomes a lie.
> ##
> ## **FIRST TARGET, ALREADY IN HAND — the worked example.**
> ## `test_shared_writes.sh` has been GREEN AGAINST 14z-91 BUILDS FOR TEN
> ## FREEZES (its inventory pins `don_m7`/`hui41`/`pyron26`). Current builds:
> ## **donovan 108 writes vs 90 frozen (18 NEW), huitzil 106 vs 87 (19), pyron
> ## 94 vs 76 (18)** — only 3 per tenant are 14z-127's; the rest is shipped work
> ## nobody was forced to review (`0x020B9C` Oboro hook, `0x020C74/80` random
> ## select, `0x0BE27A..96` — CORRECTED 14z-128: the #104 CAPTURE-KEYFRAME
> ## rows, not the #99 AI unpark). **DO NOT re-point and
> ## re-freeze** — that launders an unreviewed inventory into the gate that
> ## exists to review it ([VSP-97]). Establish whose bytes each lands on, record
> ## the `why`, THEN re-point. The inventory is marked STALE in place.
> ##
> ## **HOW A RED IS ADJUDICATED** (maintainer, and it governs the whole sweep):
> ## *"to know if we should fix the gate or what it caught, we must use data we
> ## can trust ... measuring or relying on data that is known to be true for it
> ## was vetted by measurements."* **A RED GATE IS A QUESTION, NOT AN ANSWER.**
> ## Establish which side's expectation rests on MEASUREMENT before choosing
> ## fix-the-gate / fix-what-it-caught / delete-as-valueless. **30 of 45 frozen
> ## expectation files name their provenance; 15 do NOT** (listed in STATE) —
> ## that is where the thinking time goes. The worked warning is 14z-127's own:
> ## `test_don_reactions` was GREEN on `native == 10`, a constant of playtest
> ## testimony presented as measurement. It happened to be right, which is luck.
> ##
> ## **EXPECT REDS AND ROT — that is the deliverable:** *"anything stale will be
> ## either updated or dropped so it'll be either more safety or less time spent
> ## on valueless tests, both a win."*
> ##
> ## **OPERATIONAL:** land every commit BEFORE starting the run — the suite
> ## asserts a clean tree during a run, and a run was voided that way on
> ## 2026-09-02. `pgrep -f` waiters match their own command line; wait on a log
> ## verdict line instead. The shell is zsh: `${=var}`.
> ##
> ## **THEN, WHEN THE MACHINE IS FREE: REGISTER THE FREEZE.** `run_suite.sh
> ## --freeze` per track (~88 expectation entries each, ~5h total), registry
> ## rows, `freeze/*` tags, HANDOFF's build-registry row and "Current WIDE
> ## builds". **NO RELEASE** — the release is the pipeline's first real
> ## exercise, deliberately held back.
> ##
> ## **SMALL, OPEN, NOT URGENT:**
> ## **(1) THE ONE-BYTE IDENTIFICATION.** The name-screen display script's
> ## record is read as `<row> <col> 01 <string>` at `PRG:0x01C806`. The ROW
> ## reading is CORROBORATED (`0x0a` = 10 matched the tilemap decode's first
> ## glyph row) and the COLUMN is INFERRED — what is proven about `0x24` is only
> ## that changing it to `0x25` faults (`RAM:$FF0000`=`0x0001` = vector 3,
> ## ADDRESS ERROR, `D0`=`'V'`). **The confirming test is ONE BYTE: change the
> ## ROW (`0x0a` -> `0x0c`) in a scratch ROM and see whether the title moves
> ## DOWN two cells.** ~10 min, nothing in the tree. It would turn the record's
> ## field semantics from inference into fact.
> ## **(2) #112 fix option (B)** — kept OPEN by the maintainer; needs the
> ## half-session scoping (is there a FREE PALETTE ROW; do pool objects carry
> ## `+0x30`/`+0x382`/`+0x3AE`/`+0x18B`?). (C) do-nothing stands meanwhile.
> ## **(3) THE MIZUUMI CORPUS ARC** — 26 wiki pages in `../community/`, barely
> ## opened. Measurement stays king; a constant offset validates ours, an
> ## inconsistent pattern means re-check OURS first.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index
> ## --check` + `gen_gotchas_index --check` + `doc_anchor_census --check`, exit
> ## statuses captured directly. Regenerate the GENERATED indexes in the commit
> ## that changes what they index — and regenerate them AFTER the prose, not
> ## before (a 14z-127 red came from exactly that ordering slip).

# NEXT SESSION — orientation (rewritten at the 14z-126b CLOSE (3), 2026-09-02)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD BYTE MOVED ALL SESSION — the tree
> ## is still the M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`),
> ## FIELD-VERIFIED GREEN, and PUSHED. Strict static floor is **126**. Check
> ## `git status -sb`, not this line.**
> ##
> ## **THE ONE STANDING LESSON FROM 14z-126b, and it cost three separate
> ## corrections in one session: THE RECORD CAN OVERSTATE WHAT WAS VERIFIED.**
> ## A STATE entry said MiSTer option B was "not done" when it had shipped
> ## thirteen freezes earlier; `test_don_reactions.sh`'s `native == 10` reads
> ## as measurement and came from playtest; and my own #112 "root cause" was a
> ## correlation until an intervention proved it. **A gate header is a claim
> ## like any other — check its provenance before you build on it, and run the
> ## archaeology ([VSP-14]) before building anything.**
> ##
> ## **OPEN WORK, IN THE ORDER IT IS LIKELY TO BE AVAILABLE:**
> ##
> ## **READY TO BUILD AT THE NEXT FREEZE (decided 2026-09-02, not yet built):**
> ## the boot name screen `SAVIOR` -> `SAVED`. ONE data op,
> ## **`PRG:0x01C822`, 6 bytes, `" I O R"` -> `" E D  "`** (3 bytes differ),
> ## JAPAN entry only, column byte UNTOUCHED. Measured free: work-RAM
> ## checksums identical to pristine over 1,621 frames. **DO NOT touch the
> ## start-column byte — an odd value is a 68k ADDRESS ERROR that soft-boots
> ## and looks exactly like a real CPU exception** (`game/gotchas.md`).
> ## Credits, other regions and the title screen are ruled OUT OF SCOPE.
> ##
> ## **(0) THE EMULATOR-TIER AGGREGATOR — RULED THE NEXT ARC (maintainer,
> ## 2026-09-02), EXPECTED TO RUN OVERNIGHT.** *"we need this in another
> ## session, likely to run tonight during the night. I know it'll be hours but
> ## that's the price of accuracy and quality."*
> ## **THE GAP, MEASURED 14z-127: 167 emulator-tier gates; 29 reachable from a
> ## runner (battery or static aggregator); 138 ORPHANED** — reachable only by
> ## typing a filename, so under the release rule (anything red or skipped is a
> ## hard fail) nothing would even ask them.
> ## **FIRST FINDING, ALREADY IN HAND — `test_shared_writes.sh` IS GREEN
> ## AGAINST BUILDS FROM TEN FREEZES AGO.** Its inventory pins `don_m7` /
> ## `hui41` / `pyron26` (14z-91). Audited against the 14z-127 builds:
> ## **donovan 108 writes vs 90 frozen (18 NEW), huitzil 106 vs 87 (19),
> ## pyron 94 vs 76 (18)** — only 3 per tenant are 14z-127's; the rest is
> ## shipped work from m8..m14 that the gate never showed anyone
> ## (`0x020B9C` Oboro hook, `0x020C74/80` random select, `0x0BE27A..96` the
> ## #99 AI unpark). **DO NOT re-point and re-freeze** — that launders an
> ## unreviewed inventory into the gate that exists to review it ([VSP-97]).
> ## Establish whose bytes each lands on, record the `why`, THEN re-point.
> ## This is the shape the whole sweep will find; treat it as the worked example.
> ##
> ## **BUILD:** `tests/run_all_emulator.sh` on the `run_all_static.sh` pattern —
> ## registry files, PASS/SKIP/FAIL counted SEPARATELY, `--strict`, and the
> ## ANTI-ORPHAN registry-coverage check (without that last piece the runner is
> ## just a smaller thing to forget to update — the static runner's own stated
> ## reason for having it). A missing prerequisite is a HARD FAIL, never a
> ## silent `exit 0`.
> ## **EXPECT REDS AND ROT, AND THAT IS THE DELIVERABLE:** *"anything stale will
> ## be either updated or dropped so it'll be either more safety or less time
> ## spent on valueless tests, both a win."* Each finding resolves as FIX THE
> ## GATE / FIX WHAT IT CAUGHT / DELETE AS VALUELESS — **decided on measured
> ## data, never on the gate's own say-so** (see STATE "HOW A RED IS
> ## ADJUDICATED"; 15 of 45 frozen expectations do not name their provenance).
> ## **OPERATIONAL:** land every commit BEFORE starting it — the suite asserts a
> ## clean tree during a run, and a run was voided that way on 2026-09-02.
> ##
> ## **(1) GitHub #114 — CLOSED 2026-09-02 by the maintainer. Kept here only
> ## so it is not re-opened.** Their verdict: *"Ceilings are the same, mash
> ## rate required slightly under VS2 for everything but LP ... not a bad thing
> ## given how stringent VS2 is for max damage ... Close enough, leverages VS
> ## engine, good tradeoff."* **READ THE §5 NUMBERS THAT WAY: ours saturating
> ## at a lower mash rate is an ACCEPTED POSITIVE, not a neutral fact.** The
> ## investigation, the mechanism and the gate are in STATE and in
> ## `test_don_immortal_native.sh`. **The static wheel/track gate was DECLINED
> ## the same day** — 26 false positives; the defence is [VSP-163] instead.
> ##
> ## **(2) THE MIZUUMI CORPUS ARC — barely opened, and it is the next big
> ## one.** `../community/` now holds 26 wiki pages (HTML + PDF) including all
> ## three TENANTS (Donovan, Phobos, Pyron), Oboro, Esoterics, Dark Force,
> ## Controls, Secrets, vs2. The maintainer's framing: we built from scratch on
> ## purpose so we would look for our own answers; NOW is when we check both
> ## ways and learn from both. It already earned its keep once — mizuumi
> ## distinguishes `8J`/`9J` (neutral vs forward jump) variants of the same
> ## button where our slot map carries ONE chain, which is the named (NOT
> ## measured) hypothesis for the aerial outliers. **Measurement stays king:
> ## a perfect match or a CONSTANT OFFSET validates ours; an INCONSISTENT
> ## pattern means re-check OUR measurement first.**
> ##
> ## **(3) THE SEVEN AERIAL OUTLIERS — PART-RESOLVED.** `tick_durations.py`
> ## separates move from jump for chains that LOOP (BI 5/6 exact, and the miss
> ## is the flagged `J.HP`: ours 28, engine 27; BU `J.LK`/`J.LP` exact). NOT
> ## separable: aerials whose last node HOLDS with no further pointer write
> ## before landing (VI, FE, SA) — they still report AIRTIME. Test the `8J`/`9J`
> ## hypothesis with a two-direction jump rig.
> ##
> ## **(4) ZABEL j.LK — STILL BLOCKED ON THE MAINTAINER'S RECORDING.** Ask
> ## FIRST; build no rig before it exists ([VSP-20]). `WIDE_RECORD=zabel-jlk-m14-01
> ## tools/run_wide.sh build/m3b_merged21 mame`. It is a LEGACY-content patch:
> ## its own track, flag and ratified expectation class.
> ##
> ## **(5) #113's DESIGN "WHY" — open, and deliberately separated.** The
> ## MECHANISM is measured and gated (a palette-BASE swap: CPS-A `0x80410a`
> ## `0x90c0` → `0x9240` for one frame, `0x924000` all `ffff`). WHY Capcom
> ## flashes the screen at all is NOT known; all four occurrences sit at STATE
> ## TRANSITIONS (observation, not theory) and no bulk palette reload happens
> ## around the flash.
> ##
> ## **(6) #112 fix option (B) — RULED OPEN, NOT CLOSED (maintainer,
> ## 2026-09-02).** (C) do-nothing is the ruling for the build; **(B) "the
> ## effect owns its palette" is explicitly KEPT as a future option** — *"it
> ## may still be a valuable option"* depending on the scoping. That scoping
> ## is the half-session gate: is there a FREE PALETTE ROW, and do pool
> ## objects carry `+0x30`/`+0x382`/`+0x3AE`/`+0x18B`? It uses the owner
> ## branch the port already ships (`PRG:0x3FFAF0`).
> ##
> ## **FUTURE ARCS the maintainer has named (not scheduled):** the harness
> ## itself — this project is an exploratory PoC, and the intent is to REDO it
> ## from a mature harness and the documentation, to (a) make the romhack
> ## structurally better and (b) produce ARCHITECTURAL GUIDELINES FOR THE
> ## WIDE-SPEC CPS-2. The living-documentation effort and the rebuild option in
> ## STATE's decisions are the same thread.
> ##
> ## **INSTRUMENT TRAPS PAID FOR IN 14z-126b — all four are gotchas now, and
> ## each returned a CLEAN, PLAUSIBLE, WRONG answer:**
> ## a **1-BYTE TAP** misses word accesses on this 16-bit bus and its zero
> ## survives a control taken at another address (tap EVEN and WORD-ALIGNED,
> ## and control ON THE RANGE YOU USE); **IDENTICAL NUMBERS ACROSS DIFFERENT
> ## MOVES** is the tell that segmentation failed, not a result; an **ART-KEYED
> ## DETECTOR** cannot locate a defect in the art; and `0x800100` is the
> ## driver's "Mirror (sfa)" block this game NEVER writes — the live CPS
> ## registers are `0x804100-0x80417f`.
> ##
> ## **AND THE DEFECT CLASS THAT COST THE MOST:** a defect living in a
> ## RELATIONSHIP BETWEEN TWO TIMELINES is invisible to every single-frame
> ## instrument. When a reproducible defect's clean and bad instances compare
> ## EQUAL on every state you can dump, that equality IS the finding — stop
> ## diffing states, start measuring DURATIONS AND ORDERINGS.
> ##
> ## **SEARCH BY COST (the maintainer's ordering, corrected 2026-09-01):**
> ## inputs (cheap, reliable — start here unless you cannot); memory watching
> ## (dearer, reliable unless the pattern is not); art (expensive FOR CLAUDE
> ## but **cheap the moment the maintainer is shown a capture — so show them**).
> ## The list is NOT closed. It is an ordering, never a prohibition.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations.py` + `gen_gate_index --check`
> ## + `gen_gotchas_index --check`, exit statuses captured directly. Do NOT run
> ## individual gates while `run_all_static.sh` runs, do not edit tracked files
> ## during it, and a `pgrep -f` waiter matches its own command line and never
> ## exits — wait on the log's verdict line. The shell is zsh: use `${=var}`.
> ## **`run_inp_probe.sh`/`run_inp_guarded.sh` now REFUSE a bad ROMDIR and
> ## resolve it to an absolute path** — a relative one used to yield a silent
> ## zero-frame run.
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`, `hui51/52`,
> ## `pyron35/36`, `m3b_merged20/21` (+ `merged19` control), `m5_stock12/13`.
> ## The MiSTer bundle `../mister_fieldtest_14z119/` IS this freeze. **The next
> ## freeze picks up the new MRA name and the main-MRA fix automatically** —
> ## fork pin `5fd9bb9a6`, both pushed.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; the FBNeo two-run-family
> ## question; the tenant CPU AI "lackluster" note; win quotes forgone; the
> ## COSMETIC BACKLOG. `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`; `test_hui_df_style.sh`'s header still describes its
> ## 14z-79 `differs` expectation.



<!-- superseded at the 14z-126b CLOSE (2) -->

# NEXT SESSION — orientation (rewritten at the 14z-126b close, 2026-09-01)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN, and PUSHED. Strict static floor is now **126**. Check
> ## `git status -sb`, not this line.**
> ##
> ## **OPEN WORK, IN THE ORDER IT IS LIKELY TO BECOME AVAILABLE:**
> ##
> ## **(1) ZABEL j.LK — STILL BLOCKED ON THE MAINTAINER'S RECORDING.** Ask for
> ## it FIRST; do not build a rig before it exists ([VSP-20]; the 14z-109..111
> ## cost was three sessions on a rig-derived mechanism that was never the
> ## field crash). Command: `WIDE_RECORD=zabel-jlk-m14-01 tools/run_wide.sh
> ## build/m3b_merged21 mame`, play the j.LK that fails to trigger proximity
> ## guard, hand over `~/.cache/vampire-saved/inp/zabel-jlk-m14-01/`. Then
> ## archaeology ([VSP-14]), then vanilla's proximity-guard test measured
> ## against every other normal. Zabel has NO proximity variants and his
> ## standing-normal slots are known exactly
> ## (`tests/expected/vanilla_normal_slots.tsv`). It is a LEGACY-content patch:
> ## outside the superset invariant's "untouched" set by definition, so it
> ## needs its own track/flag and its own ratified expectation class.
> ##
> ## **(2) #112 IS ROOT-CAUSED — an OVERWRITE RACE on palette row `0b`
> ## index 14 (2026-09-01). Nothing is blocked on it; it stays COSMETIC and
> ## ACCEPTED.** The foot is row `0b` idx 14, NOT row 05. Idx 14's default is
> ## `f111` (near-black); the effect loads `fcff` (cyan). Over f13400-14375
> ## there are 24 writes to it and only TWO are `fcff`, one per Press of
> ## Death: the CLEAN one (f13589) survives 56 frames to the foot at f13645;
> ## the BLACK one (f14313) is OVERWRITTEN back to `f111` at f14341, 29
> ## frames before the foot at f14370. Same writer PC both times
> ## (`PRG:0x02AD64`/`0x02AD78`, vanilla code), so it is the SOURCE that
> ## differs — two palette-seq requests racing. **DO NOT re-derive the
> ## eliminations**: the tile codes, the composed `a18`/`a19` addresses, the
> ## OBJ entries and row 05 are all IDENTICAL between a clean and the black
> ## instance; three earlier claims are retracted in STATE's #112 entry.
> ## **THE FOOT<->ROW LINK IS CAUSAL, not correlational** (the maintainer
> ## asked "is it truly complete?" and it was not): forcing `$90C17C`=`fcff`
> ## moves EXACTLY 7,007 px, all rgb(17,17,17)->rgb(204,255,255), and the
> ## sole and toes vanish; the control on the neighbouring entry moves 8,898
> ## DISJOINT px, none black. Gated: `test_pod_black_foot_palette.sh`.
> ## "Race" was too strong — an OVERWRITE with an ordering is what is
> ## measured; whether it truly races is not established.
> ## Only remaining question, and it is optional: which palette-seq request
> ## writes the f14341 `f111`. Rig: `tests/lua/tap_writes.lua` with
> ## `TAP=90c17c,2` over `tests/inp/pod-black-m14-01`.
> ##
> ## **(3) THE #113 WHITE-FRAME MECHANISM — ANSWERED 2026-09-01, the same
> ## day it was opened. Nothing to do; do NOT re-derive it.** The one-frame
> ## white-out is a DELIBERATE PALETTE-BASE SWAP: CPS-A `0x80410a`
> ## (`CPS1_PALETTE_BASE`) goes from its normal `0x90c0` to `0x9240` for one
> ## frame, and `0x924000` is filled entirely with `ffff`, so every layer
> ## resolves to white. Both candidates the record named (palette RAM
> ## blanked / a CPS-B layer register) are RETRACTED — palette contents are
> ## untouched. Discriminator 4/4 (`0x9240` occurs exactly four times in
> ## 6,700 frames, one frame before each white frame); FBNeo reproduces the
> ## inventory. **HOW is answered; WHY CAPCOM FLASHES THE SCREEN AT ALL IS
> ## NOT** (maintainer, 2026-09-01: "I still don't understand why would
> ## Capcom want to blink the screen, but now we at least know how"). The
> ## base swap explains the IMPLEMENTATION, not the design intent. Only
> ## observation: all four occurrences sit at STATE TRANSITIONS; a bulk
> ## palette reload was looked for and not found. Open, and nothing depends
> ## on it. Detail + the two instrument traps: STATE's #113 entry.
> ##
> ## **(4) JEDAH'S CROUCHING RECOVERY — BLOCKED ON AN INSTRUMENT.** His whole
> ## crouching family (and Lilith's `2MK`) reads recovery +3 where everyone
> ## else reads +2. A frame-rate trace CANNOT resolve a one-frame convention
> ## (16% of `field_trace` frames carry two engine ticks), so the precondition
> ## is a TICK-ACCURATE instrument — a `-debug` trace or a Lua hook on the
> ## engine tick — not another rig.
> ##
> ## **(5) THE MIZUUMI CHARACTER DATA — NEW, queued into no session yet.** The
> ## maintainer has found the character data on the mizuumi wiki (2026-09-01)
> ## and wants it checked against ours in a future session. It joins the
> ## community cross-check's existing two sources (the frame-data workbook, the
> ## 146 player-struct offsets of which ~90 remain `[C]`). The rule is
> ## unchanged: **measurement is king** — a perfect match or a CONSTANT OFFSET
> ## validates ours, an INCONSISTENT pattern means re-check OUR measurement
> ## first.
> ##
> ## **THE METHOD FROM 14z-126b — RESTATED CORRECTLY BY THE MAINTAINER
> ## 2026-09-01, because the first version of it was WRONG AND HARMFUL.** It
> ## is a **COST ORDERING, not a prohibition.** The bad version said "search
> ## the INPUTS, never the art" and attributed that to the maintainer; they
> ## never said it. What they said:
> ## **(1) INPUT SEARCH — cheap and reliable, so START HERE UNLESS YOU
> ## CANNOT.** A `.inp` IS an input recording and `inp_probe.lua` already logs
> ## `in=IN0,IN1,IN2` on every `V` line (CPS-2 P1, active LOW: IN0 bit0 R /
> ## bit1 L / bit2 D / bit3 U, bits 4-6 LP/MP/HP; IN1 bits 0-2 LK/MK/HK). A
> ## motion is a PARTIAL ORDER over mandatory steps, so a human's
> ## non-frame-perfect input is absorbed by an ordered-subsequence match.
> ## Allow for the input->effect LAG (63 frames for that super).
> ## **(2) MEMORY WATCHING — more expensive; reliable UNLESS THE PATTERN IS
> ## NOT RELIABLE.**
> ## **(3) ART SEARCH — very hard and very expensive FOR CLAUDE, BUT the
> ## maintainer can confirm or infirm a capture IMMEDIATELY, so SHOWING THEM
> ## ONE makes it much more cost-effective.** Art search has a place; do not
> ## refuse it, and do not pay Claude's price for it alone when a human
> ## glance is available.
> ## **(4) THE LIST IS NOT CLOSED** — other means likely exist per use-case.
> ## The `#112` detector keyed on the CLEAN art is still the cautionary tale
> ## (ten confident clean instances, blind to the defect), but the lesson is
> ## "do not key a DETECTOR on the thing under investigation", not "avoid
> ## art".
> ##
> ## **AND: A RECORDING'S FRAME NUMBERS ARE A CLAIM ABOUT ITS BUILD.**
> ## `run-merged-m9-05` replays on merged-m14 length-exact (END 7490) and
> ## guard-clean but CONTENT-DIVERGENT. Length matching is not evidence of
> ## reproduction. Both facts are gotchas now.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations.py` from a CLEAN WORKTREE +
> ## `gen_gate_index.py --check` + `gen_gotchas_index.py --check`, exit
> ## statuses captured directly. **Do NOT run individual gates while
> ## `run_all_static.sh` is running** (a collision produced a red
> ## `gen_annotations --check` that re-ran green), do NOT edit tracked files
> ## during it (its last section asserts the tree did not move), and **a
> ## `pgrep -f` waiter matches its own command line and never exits** — wait on
> ## the log's verdict line. The shell is zsh: use `${=var}`.
> ##
> ## **CLOSED 2026-09-01: #113** — the maintainer's board check agreed with
> ## the emulator measurement and they closed it ("the behavior is indeed
> ## vanilla"). Do NOT reopen or re-derive it.
> ## **FIELD: merged-m14 (mark M12) RE-VERIFIED GREEN on MiSTer 2026-09-01**
> ## — a SECOND independent field pass on the same build (the first was
> ## 2026-08-30, 14z-121). No build changed.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; the FBNeo two-run-family question; the
> ## tenant CPU AI "lackluster" note; win quotes forgone; the COSMETIC BACKLOG.
> ## `test_random_select_tenants.sh`'s CONTROL is still `build/m3b_merged19`;
> ## `test_hui_df_style.sh`'s header still describes its 14z-79 `differs`
> ## expectation (a stale gate header, not a defect).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`. The MiSTer bundle `../mister_fieldtest_14z119/` IS this
> ## freeze — verified by hash (`vsavjw.zip` sha1 `3b34d35f…`).


> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN, and PUSHED through the 14z-126b close. Check `git status -sb`, not
> ## this line.**
> ##
> ## **THE NEXT THING IS STILL ITEM (2), ZABEL j.LK — AND IT STILL NEEDS THE
> ## MAINTAINER'S RECORDING.** Ask for it FIRST; do not build a rig before it
> ## exists ([VSP-20], and the 14z-109..111 cost: three sessions on a
> ## rig-derived mechanism that was never the field crash). The command for
> ## them is `WIDE_RECORD=zabel-jlk-m14-01 tools/run_wide.sh
> ## build/m3b_merged21 mame`, play the j.LK that fails to trigger proximity
> ## guard, then hand over `~/.cache/vampire-saved/inp/zabel-jlk-m14-01/`.
> ## Then: archaeology ([VSP-14]: `git log --grep`, `grep -n "proximity guard"
> ## STATE_HISTORY.md docs/game/*.md`), then vanilla's proximity-guard test
> ## measured against every other normal so the fix is bounded by a measured
> ## difference. **Facts already in hand:** Zabel has NO proximity variants at
> ## all and his standing-normal slots are known exactly
> ## (`tests/expected/vanilla_normal_slots.tsv`, 14z-125). It is a
> ## LEGACY-content patch: outside the superset invariant's "untouched" set by
> ## definition, so it needs its OWN track/flag and its own ratified
> ## expectation class (STATE "Decisions pending").
> ##
> ## **AFTER THAT: (3) Jedah's crouching recovery — BLOCKED ON AN INSTRUMENT.**
> ## His whole crouching family (and Lilith's `2MK`) reads recovery +3 where
> ## everyone else reads +2. 14z-125b measured that a frame-rate trace CANNOT
> ## resolve a one-frame convention (16% of `field_trace` frames carry two
> ## engine ticks), so the precondition is a TICK-ACCURATE instrument — a
> ## `-debug` trace or a Lua hook on the engine tick — not another rig.
> ##
> ## **WHAT 14z-126b SETTLED, so it is not re-derived:** HANDOFF's eight
> ## `Previous batch` blocks are DELETED (−140 lines) and will not come back —
> ## `test_docshape` now bars a bold paragraph that LEADS with chronology and
> ## carries a session token, calibrated so it fires on those eight and none of
> ## the other 611 bold openers. **A REFERENCE doc's chronology now has two
> ## gates on it, headers and bold paragraphs; if the log reappears in a THIRD
> ## shape, extend the same checker rather than starting a list.**
> ##
> ## **AND THE FREEZE-TAG LEDGER IS WHOLE, WITH NOTHING GRANDFATHERED:** the
> ## 14z-91 batch (`donovan-m7` / `huitzil-m15` / `pyron-m9`) had registry rows
> ## but no `freeze/*` tag for 35 sessions; the three tags now exist at
> ## `271838e` (two MEASURED against surviving `rompath` artifacts, donovan-m7
> ## not — its rompath was pruned). Then the three 14z-102 tags whose messages
> ## named no fingerprint (`donovan-m10` / `huitzil-m19` / `pyron-m13`) were
> ## AMENDED and force-pushed at the maintainer's word (commit unchanged,
> ## `MESSAGE AMENDED 2026-09-01` in each). So
> ## **`tests/test_freeze_tag_coverage.sh` now runs all three sections HARD
> ## with NO allow-list**: every build row has an annotated tag, no tag is
> ## lightweight, every message names its fingerprint. **If you ever need to
> ## grandfather something there, delete the allowance the moment its reason
> ## dies — this one lived less than a day and was still worth removing.**
> ##
> ## **STILL OPEN FROM THE CROSS-CHECK:** Jedah's crouching family above; the
> ## seven aerial startup/active outliers; and the specials/supers/throws —
> ## the bulk of the workbook's 730 rows — each needing its own vsavj naming
> ## rig. **The WIKI half is queued into no session yet:** 146 mizuumi
> ## player-struct offsets vs `ram.md`, of which four were adopted 14z-126 and
> ## ~90 remain [C] candidates.
> ##
> ## **THE FRAME-DATA RULE IS LAW (ruled 14z-126, option (b)):** every
> ## per-move ROM-derived table — OURS AND THIRD-PARTY ALIKE — is generator
> ## output under `../charpages/framedata/`, regenerated by
> ## `tools/framedata_pages.sh`; the tree ships the READERS and the VERDICTS,
> ## currency hash-locked. **Route new per-move data through that script from
> ## the START.** The three character artifacts are published FROM that
> ## out-of-tree output — regenerate before republishing, and get the
> ## maintainer's word on the publish BEFORE spending the ~50 k-context reads
> ## per page.
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check` +
> ## `gen_gotchas_index.py --check`, exit statuses captured directly; wrapped
> ## `##` headers are house style. **The shell is zsh: `python3 tools/$c` does
> ## NOT word-split — use `${=c}`.** **And do NOT run individual gates while
> ## `run_all_static.sh` is running** — a collision produced a red
> ## `gen_annotations --check` that re-ran green (14z-126b). **A `pgrep -f`
> ## waiter matches its own command line and never exits: wait on the log's
> ## verdict line.**
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG. `test_random_select_tenants.sh`'s CONTROL
> ## is still `build/m3b_merged19`; `test_hui_df_style.sh`'s header still
> ## describes its 14z-79 `differs` expectation (a stale gate header, not a
> ## defect).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.

<!-- superseded at the 14z-126b close -->

# NEXT SESSION — orientation (rewritten at the 14z-126 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN, and PUSHED through the 14z-126 close. Check `git status -sb`, not
> ## this line.**
> ##
> ## **THE NEXT THING IS ITEM (2), ZABEL j.LK — AND IT NEEDS THE MAINTAINER'S
> ## RECORDING, WHICH THEY WILL PROVIDE IN THIS SESSION OR A LATER ONE.** Ask
> ## for it FIRST; do not build a rig before it exists ([VSP-20], and the
> ## 14z-109..111 cost: three sessions on a rig-derived mechanism that was
> ## never the field crash). The command for them is
> ## `WIDE_RECORD=zabel-jlk-m14-01 tools/run_wide.sh build/m3b_merged21 mame`,
> ## play the j.LK that fails to trigger proximity guard, then hand over
> ## `~/.cache/vampire-saved/inp/zabel-jlk-m14-01/`. Then: archaeology
> ## ([VSP-14]: `git log --grep`, `grep -n "proximity guard" STATE_HISTORY.md
> ## docs/game/*.md`), then vanilla's proximity-guard test measured against
> ## every other normal so the fix is bounded by a measured difference.
> ## **Facts already in hand:** Zabel has NO proximity variants at all and his
> ## standing-normal slots are known exactly
> ## (`tests/expected/vanilla_normal_slots.tsv`, 14z-125). It is a
> ## LEGACY-content patch: outside the superset invariant's "untouched" set by
> ## definition, so it needs its OWN track/flag and its own ratified
> ## expectation class (STATE "Decisions pending").
> ##
> ## **AFTER THAT: (3) Jedah's crouching recovery — BLOCKED ON AN INSTRUMENT.**
> ## His whole crouching family (and Lilith's `2MK`) reads recovery +3 where
> ## everyone else reads +2. 14z-125b measured that a frame-rate trace CANNOT
> ## resolve a one-frame convention (16% of `field_trace` frames carry two
> ## engine ticks), so the precondition is a TICK-ACCURATE instrument — a
> ## `-debug` trace or a Lua hook on the engine tick — not another rig.
> ##
> ## **WHAT 14z-126 SETTLED, so it is not re-derived:** the DF startup window
> ## is `+0x147`, armed PER CHARACTER by the seq-0x16 handler — neither global
> ## nor inherited (`tests/audit_df_startup_invuln.sh`, all 18 frozen). And the
> ## values are Capcom's: vs2 AND vh2 carry VS-style DF handlers for all 18 and
> ## never reach them, so the port RESTORED them
> ## (`tests/test_df_startup_provenance.sh`, `tests/audit_df_dead_family.sh`).
> ## That class now has its own document, **`docs/game/preserved_data.md`** —
> ## add to it when the next "the ROM already had this" turns up.
> ##
> ## **THE FRAME-DATA RULE IS LAW NOW (ruled 14z-126, option (b)):** every
> ## per-move ROM-derived table — OURS AND THIRD-PARTY ALIKE — is generator
> ## output under `../charpages/framedata/`, regenerated by
> ## `tools/framedata_pages.sh`; the tree ships the READERS and the VERDICTS,
> ## currency hash-locked (`tests/expected/charmap_pages.sha256`,
> ## `vanilla_hit_damage.sha256`). **Route new per-move data through that
> ## script from the START** rather than committing a table and moving it
> ## later. The three character artifacts are published FROM that out-of-tree
> ## output — regenerate before republishing, and get the maintainer's word on
> ## the publish BEFORE spending the ~50 k-context reads per page (the
> ## auto-mode classifier refused it once).
> ##
> ## **STILL OPEN FROM THE CROSS-CHECK:** Jedah's crouching family above; the
> ## seven aerial startup/active outliers; and the specials/supers/throws —
> ## the bulk of the workbook's 730 rows — each needing its own vsavj naming
> ## rig. **The WIKI half is queued into no session yet:** 146 mizuumi
> ## player-struct offsets vs `ram.md`, of which four were adopted 14z-126 and
> ## ~90 remain [C] candidates.
> ##
> ## **THE HANDOFF SHAPE ITEM, still owed** (measured 14z-125b): HANDOFF is
> ## REFERENCE yet carries 8 `**Previous batch (14z-N…)**` blocks, ~93 lines of
> ## chronology already held richer in `HANDOFF_HISTORY.md` — DELETE-AND-POINT,
> ## not a move. The durable half: teach `test_docshape` to catch
> ## session-token-led BOLD PARAGRAPHS, not just headers, or it comes back.
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check` +
> ## `gen_gotchas_index.py --check`, exit statuses captured directly; wrapped
> ## `##` headers are house style. **The shell is zsh: `python3 tools/$c` does
> ## NOT word-split — use `${=c}`** (paid again this session).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG. `test_random_select_tenants.sh`'s CONTROL
> ## is still `build/m3b_merged19`; `test_hui_df_style.sh`'s header still
> ## describes its 14z-79 `differs` expectation (a stale gate header, not a
> ## defect).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.

<!-- superseded at the 14z-126 close -->

# NEXT SESSION — orientation (rewritten at the 14z-126 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. PUSHED through `4d97ec9` (the 14z-126 close); check
> ## `git status -sb`, not this line.**
> ##
> ## **ITEM (1) OF THE ORDER IS DONE — THE DF-STARTUP INVINCIBILITY QUESTION IS
> ## ANSWERED (14z-126).** The window is `+0x147` (the victim's invincibility
> ## timer, the hit test's gate at `PRG:0x018064`), armed PER CHARACTER by the
> ## seq-0x16 handler `dispatch_16` selects — **neither a global property of the
> ## activation (the shared body arms only `+0x143` = 0x14, throw immunity) nor
> ## inherited from the shell**: the tenants' rows are repointed to their own vs2
> ## handlers, which arm Donovan 64 / Huitzil 79 / Pyron 41 ticks (shells 59 / 41
> ## / 41). All 15 vanilla windows measured and frozen for the first time
> ## (`tests/expected/df_startup_invuln.tsv`, gate `tests/audit_df_startup_invuln.sh`
> ## — 22 trace legs + 4 contact legs, ~3 min, `REUSE=1` re-checks kept traces).
> ## Natively on vs2 there is NO window ([VSE-69]). No gameplay change proposed:
> ## the tenants already ship with their own; retuning one is a single byte.
> ## Read engine_internals "Dark Force" -> "The STARTUP INVINCIBILITY window".
> ## **And the PRESERVATION FINDING that followed:** vs2/vh2 carry the VS-style
> ## DF handlers for ALL 18, switched off; the vanilla rows arm the same value
> ## in all three ROMs, the tenants' the same in vs2 and vh2 — so the port
> ## RESTORED Capcom's own values (the maintainer's reading, recorded as
> ## assessment). Locked by `tests/test_df_startup_provenance.sh` (ci_static);
> ## the class now has its own small document, `docs/game/preserved_data.md`.
> ##
> ## **THE ARTIFACT REPUBLISH IS DONE (14z-126, second pass):** all three
> ## character pages are current (Donovan `85d7fd52`, Huitzil `f0dddc83`,
> ## Pyron `ad618f12`). Note for next time: the first publish was refused by
> ## the auto-mode classifier and went through after the maintainer's explicit
> ## word — ask BEFORE spending the ~50k-context reads per page.
> ##
> ## **THE FRAME-DATA RULE IS RULED AND SHIPPED (14z-126, option (b)):** every
> ## per-move ROM-derived table — OURS AND THIRD-PARTY ALIKE — is generator
> ## output under `../charpages/framedata/`, regenerated by the new
> ## `tools/framedata_pages.sh`; the tree ships the READERS and the VERDICTS,
> ## with currency hash-locked (`tests/expected/charmap_pages.sha256`,
> ## `vanilla_hit_damage.sha256`). Seven files left the tree; the committed
> ## `community_crosscheck.md` is the VERDICT-ONLY page. **The three character
> ## artifacts are now published FROM the out-of-tree output** — regenerate
> ## before republishing. Public history was ACCEPTED, not rewritten.
> ## The ruling and what moved: STATE "Decisions pending" -> FRAME DATA IN A
> ## PUBLIC REPO.
> ##
> ## **THE ORDER CONTINUES (maintainer, 2026-08-31): (2) the Zabel j.LK proximity
> ## guard, (3) Jedah's crouching recovery.** (2) STARTS WITH A RECORDING
> ## ([VSP-20]) that only the maintainer can produce: `WIDE_RECORD=zabel-jlk-m14-01
> ## tools/run_wide.sh build/m3b_merged21 mame`, play the whiffing j.LK against a
> ## few opponents, hand over the `~/.cache/vampire-saved/inp/` directory. Ask for
> ## it FIRST; then archaeology ([VSP-14]: `grep -n "proximity guard"
> ## STATE_HISTORY.md docs/game/*.md`), then the measured comparison against every
> ## other normal's proximity-guard test. Facts already in hand: Zabel's
> ## standing-normal slots are exact and he has NO proximity variants
> ## (`tests/expected/vanilla_normal_slots.tsv`); it is a LEGACY-content patch
> ## needing its own track/flag and expectation class (STATE "Decisions
> ## pending"). (3) needs a TICK-ACCURATE instrument first (a `-debug` trace or
> ## a Lua hook on the engine tick) — 14z-125b measured that a frame-rate trace
> ## cannot resolve a one-frame convention.
> ##
> ## **FOUND ON THE WAY, ALREADY CORRECTED (14z-126):** `0x2246E` is the System
> ## Timer Reducer, not "the class-0xFF block handler" (the block-entry handler
> ## `0x2395A`-`0x23966` opens the advancing-guard window) — mizuumi was right;
> ## and `+0x161` is a per-character DF work byte (Sasquatch's accumulator AND
> ## Bishamon/Oboro's flag). Both disagreements from the 14z-124 wiki inventory
> ## are closed; four wiki rows adopted into `ram.md` (`+0x134`, `+0x145`,
> ## `+0x143`, `+0x1B3`); the other ~90 candidates stay [C], unadopted.
> ## Project gotcha: a write tap on a COUNTDOWN names the decrementer, not the
> ## opener — and `field_trace` samples one reducer tick after an opener's write.
> ##
> ## **TWO CARRIED FORWARD FROM 14z-125b, unchanged:** when the frame-data
> ## findings go to the community, the damage finding is solid (the workbook
> ## double-counts records sharing the `+0x10` dedup key, 75/78) but `startup +1`
> ## / `recovery +2` are NAMED CONVENTIONS, not corrections; and the HANDOFF
> ## shape item — 8 `**Previous batch (14z-N…)**` blocks (~93 lines of chronology
> ## in a REFERENCE doc, held richer in `HANDOFF_HISTORY.md`) to DELETE-AND-POINT,
> ## plus teaching `test_docshape` to catch session-token-led BOLD PARAGRAPHS.
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check` +
> ## `gen_gotchas_index.py --check`, exit statuses captured directly; wrapped
> ## `##` headers are house style.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG. `test_random_select_tenants.sh`'s CONTROL
> ## is still `build/m3b_merged19`; `test_hui_df_style.sh`'s header still
> ## describes its 14z-79 `differs` expectation (a stale gate header, not a
> ## defect).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.


<!-- superseded at the 14z-126 close -->

# NEXT SESSION — orientation (rewritten at the 14z-125 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. Commits are LOCAL past the pushed `44bc6f5` — push at the
> ## maintainer's word; check `git status -sb`, not this line.**
> ##
> ## **THE COMMUNITY CROSS-CHECK'S PHASE 1 IS DONE (14z-125, the maintainer's
> ## order "start with item 2 to get proper confirmed data").** All 15 VANILLA
> ## characters now have derived frame data for the first time
> ## (`tools/vanilla_frames.py`), compared against the workbook and classified:
> ## **startup 274/281 (97%) at +1 · active 271/281 (96%) at +0 · recovery
> ## 190/197 (96%) at +2 · white 268/281 (95%) at +0 · gauge 274/281 (97%) at
> ## +0.** Page: `docs/project/tables/community_crosscheck.md` (GENERATED, with
> ## a "What is NOT known"). Gates `test_community_crosscheck` (ci_static) and
> ## `test_vanilla_frame_join` (emulator, 30 legs, ~28 s).
> ##
> ## **TWO THINGS WERE FOUND, AND BOTH WERE OURS.** (1) `active` counted
> ## NON-attacking gap nodes — 18 tenant chains inflated (Huitzil 5LP read 13,
> ## true 6). Fixed: `tools/frame_data.py` is now THE one derivation for all
> ## three renderers, and it emits the community runs grammar (`3(7)3`). **The
> ## three published character-page artifacts carry the OLD numbers and should
> ## be re-published.** (2) The standing-normal JOIN is per character, not a
> ## fixed even/odd layout — a model fitted against the workbook being checked
> ## was overturned by measuring all 15 in-emulator. Zabel has NO proximity
> ## variants; on the fixed model he was INCONSISTENT on all five columns, on
> ## the measured join he is clean on all five.
> ##
> ## **THE OPEN HALVES WERE FINISHED (14z-125b).** `red damage` is comparable
> ## after all — 266/281 (94%): the workbook's column is our `+8` PLUS `+9`, and
> ## 14z-125's "needs the [VSE-40] scaler" is RETRACTED. The damage residue is
> ## settled AGAINST the workbook: it sums attack records that share the engine's
> ## `+0x10` dedup key, which can only land once — a hit rig confirms our count on
> ## 75/78 connecting events. And the duration bytes are the engine's (334/380),
> ## though 16% of sampled frames carry two engine ticks, so a frame-rate trace
> ## CANNOT adjudicate a one-frame convention: `startup +1` / `recovery +2` stay
> ## named conventions.
> ##
> ## **FIRST, A 10-MINUTE ERRAND: RE-PUBLISH THE THREE CHARACTER-PAGE
> ## ARTIFACTS.** They are **five generator commits stale**, not just missing
> ## 14z-125's `active` fix: the live pages are byte-exact `9b8844d` output
> ## (verified by diffing the fetched artifact against every commit that touched
> ## the file), so they also lack the per-strength strip labels, the detached-hit
> ## handling and the sprite/composite styles. **Nothing was hand-edited in the
> ## artifact UI — there is nothing to merge, just republish the committed file.**
> ##   Donovan https://claude.ai/code/artifact/85d7fd52-9b14-4b19-b3a1-d76334f2cb3e
> ##   Huitzil https://claude.ai/code/artifact/f0dddc83-5b9b-4139-a637-91c55695fdf7
> ##   Pyron   https://claude.ai/code/artifact/ad618f12-5166-4a88-94e8-d89625a3500e
> ## For each: Artifact `action: "read"` the URL, Read the saved file IN FULL
> ## (the publish is refused otherwise), then publish with that `url` and
> ## `file_path: docs/project/tables/chars/<tenant>.html`. Omit `favicon` — the
> ## icons (🗡️ etc.) must not change. **BUDGET ~50k CONTEXT PER PAGE** (the
> ## Donovan file alone reads as 46,719 tokens); that is why 14z-125b deferred
> ## it — doing one of three would leave the set inconsistent. Do all three in a
> ## fresh session, before anything else.
> ##
> ## **THE ORDER IS SET (maintainer, 2026-08-31): (1) the DF-startup
> ## invincibility question, (2) the Zabel j.LK proximity guard, (3) Jedah's
> ## crouching recovery.** The maintainer also SHARPENED (1): if the tenants do
> ## have the startup invincibility, **is it a global property of DF activation
> ## or INHERITED FROM THE SHELL CHARACTER?** The tenants' variant ids alias
> ## base-half rows, so a flag read from an id-indexed row would give Phobos
> ## Bulleta's, Pyron Demitri's, Donovan Victor's — the rig therefore needs
> ## THREE legs (tenant, its shell, a legacy control), not the two the 14z-124
> ## plan named. Detail in STATE "Decisions pending".
> ##
> ## **The cross-check page is published as a PRIVATE artifact** (internal only,
> ## like the character pages that carry IP):
> ## https://claude.ai/code/artifact/f572a468-2e35-441c-aa1a-130353e9c9ff
> ## The maintainer is forwarding the frame-data findings to the community.
> ##
> ## **TWO CARRIED FORWARD FROM THE 14z-125b CLOSE.** (1) **THE MAINTAINER IS
> ## CHECKING THE LEGALITY of carrying the workbook's per-move values.** The
> ## committed `community_crosscheck.md` prints their figures beside ours in the
> ## per-move tables and is PUSHED; the artifact is private, which does not help
> ## if the repo is public. **If the ruling is "don't carry them", the fix is
> ## scoped and ready: cut their raw values from the generated page — keep ours,
> ## the verdicts and the mechanisms, print the DELTA only** (one change in
> ## `render_md`, then regenerate + re-freeze `test_community_crosscheck`).
> ## (2) **When the findings go to the community, carry the caveat:** the damage
> ## finding is solid (the workbook double-counts records sharing the engine's
> ## `+0x10` dedup key; hit counts 75/78 behind it), but `startup +1` /
> ## `recovery +2` are NAMED CONVENTIONS, not corrections — we measured that our
> ## instrument cannot resolve a one-frame question. Do not present them as the
> ## workbook being wrong.
> ##
> ## **A DOC-SHAPE ITEM, MEASURED 14z-125b (maintainer's question: does HANDOFF
> ## need STATE's rollover?).** NEXT_SESSION does NOT — it is `ORIENT` with a
> ## HIST twin and already rolls at every close (119 live lines vs 3,022
> ## archived; the mechanism works). **HANDOFF does not need a rollover either —
> ## it needs its declared shape enforced.** It is `REFERENCE`, and [VSP-12] bars
> ## chronology from a reference document, yet it carries **8 `**Previous batch
> ## (14z-N…)**` blocks, ~93 lines**, whose content `HANDOFF_HISTORY.md`
> ## "Build registry narratives" ALREADY holds in richer form. So the fix is
> ## DELETE-AND-POINT, not a move: keep the current batch, replace the eight with
> ## one pointer to the twin and the registry table. **And the durable half:
> ## `test_docshape` bars session-shaped HEADERS from a REFERENCE doc but not
> ## session-token-led BOLD PARAGRAPHS, which is why this accreted unseen — teach
> ## the lint that shape, or it comes back.**
> ##
> ## **WHAT TO DO NEXT — the maintainer's call between three:**
> ## (a) **WHAT THE CROSS-CHECK STILL LEAVES OPEN:** Jedah's whole crouching
> ## family (and Lilith's `2MK`) reads recovery +3 where everyone else reads +2,
> ## unexplained; the seven aerial startup/active outliers; and the
> ## specials/supers/throws, each needing its own vsavj naming rig — the bulk of
> ## the workbook's 730 rows. A TICK-ACCURATE instrument (a `-debug` trace or a
> ## Lua hook on the engine tick) is the precondition for the first two.
> ## (b) **ITEM 1, DF-STARTUP INVINCIBILITY FOR THE TENANTS** — unchanged in
> ## STATE "Decisions pending"; its lead `+0x1B3 "Dark Force Startup"` sits in
> ## the mizuumi player-struct table, and **the WIKI half of item 2 was
> ## DEFERRED into that session**: 146 offsets vs `ram.md` (94 new candidates,
> ## evidence class [C]), with two disagreements to measure — `+0x161` "Oboro
> ## Fight Flag" vs our measured Sasquatch DF accumulator, and `0x2246E`
> ## "System Timer Reducers" vs our class-0xFF block handler. The page carries
> ## no per-move frame data, so it is a RAM/ROM source only (`oldid 416342`,
> ## 2025-07-31, region unqualified).
> ## (c) **THE ZABEL j.LK PROXIMITY GUARD** — its own session; a LEGACY-content
> ## patch needing its own track/flag and expectation class; START WITH A
> ## RECORDING ([VSP-20]), then archaeology ([VSP-14]). **NOTE: 14z-125 now
> ## knows Zabel's standing-normal slots exactly, and that he has no proximity
> ## variants at all — read `tests/expected/vanilla_normal_slots.tsv` first.**
> ##
> ## **THE TWO COMMUNITY SOURCES STAY OUT OF THE TREE** (`../community/`),
> ## cited never committed. `tools/xlsx_read.py` reads the workbook with the
> ## stdlib alone (validated against openpyxl on 28,234 cells).
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check`, exit
> ## statuses captured directly; wrapped `##` headers are house style.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG. `test_random_select_tenants.sh`'s CONTROL
> ## is still `build/m3b_merged19`; `test_hui_df_style.sh`'s header still
> ## describes its 14z-79 `differs` expectation (a stale gate header, not a
> ## defect).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.


<!-- superseded at the 14z-125 close -->

# NEXT SESSION — orientation (rewritten at the 14z-124 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER (since 14z-122):
> the previous opener moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md`
> — this file holds ONLY the live orientation. Session state, not knowledge:
> facts belong in the docs, status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. Five commits are LOCAL past the pushed `719c560` (14z-124) — push
> ## at the maintainer's word; check `git status -sb`, not this line.**
> ##
> ## **THE DOCUMENTATION RATIONALIZATION PASS IS DONE (14z-124, G7 closed).**
> ## `docs/doc_shape.tsv` has ZERO PENDING rows and `tests/test_docshape.sh`
> ## now runs `checkdocshape --no-pending` — a new document is classified at
> ## birth or the suite goes red; the ci floor is `n >= 60` portable gates.
> ## `engine_internals.md` is REFERENCE (STATUS banner, Atlas rows + Gates on
> ## every `##`; its chronology is `engine_internals_history.md`).
> ## `inferred_claims.md` is CLOSED (row 11 alone ruled-parked, #113).
> ##
> ## **CLAUDE.md PASS 2 IS DONE TOO** (ruled and executed 2026-08-31): 344
> ## lines; the oracle-class spec of record is `docs/project/oracle_classes.md`
> ## ([VSP-27..30] live there — edit a class THERE, never in §4); the document
> ## roster is `docs/README.md` "The documents, by role".
> ##
> ## **OPEN THE SESSION WITH THE COMMUNITY CROSS-CHECK (item 2 below —
> ## the maintainer's order, 2026-08-31: "start with item 2 to get proper
> ## confirmed data").** First steps, in order: load `vampire-savior-engine`
> ## + `cps2-emulation`; read STATE "Decisions pending" → the cross-check
> ## entry (the rule, both sources, the first-pass inventory); (a) the
> ## VANILLA derivation — make `tools/charmap_gen.py` (or a sibling) walk a
> ## vsavj vanilla character's bank and emit the same per-chain
> ## startup/active/recovery the tenants' `chars/<t>_anim.md` carries;
> ## (b) a comparator against `../community/vsav-framedata.xlsx` (tab =
> ## first two letters of the Japanese name; the id map is in STATE) that
> ## classifies every column's deltas EXACT / CONSTANT OFFSET / INCONSISTENT
> ## per character; (c) the INCONSISTENT rows measured in-emulator on a
> ## vanilla replay (`field_trace`, hitbox state per frame) — the emulator
> ## arbitrates; (d) the wiki's player-struct map (146 offsets, 94 not in
> ## `ram.md`) against the atlas the same way, starting with the two
> ## disagreements (`+0x161`, `0x2246E`). Deliverable
> ## `docs/project/tables/community_crosscheck.md` + a gate; both sources
> ## stay OUT of the tree (cite them). Then item (1), whose lead — `+0x1B3`
> ## "Dark Force Startup" — the cross-check will have measured.
> ##
> ## **THREE ITEMS ARE QUEUED (maintainer, 2026-08-31), none started** —
> ## all in STATE "Decisions pending": (1) **DF-STARTUP INVINCIBILITY FOR
> ## THE TENANTS** — measure the [VSE-69] seam (shared activation body vs
> ## the per-character seq-0x16 handler) on replay 97's rig with a hit timed
> ## into the window, Demitri control + a positive control; (2) **THE
> ## COMMUNITY CROSS-CHECK** — our DERIVED tenant frame data
> ## (`chars/<tenant>_anim.md`) and a vanilla derivation to build vs the
> ## maintainer's `../community/vsav-framedata.xlsx` (15 vanilla characters,
> ## inventoried) and the mizuumi RE page (received as a PDF, text at
> ## `../community/mizuumi_reverse_engineering.txt`, inventoried — 146
> ## player-struct offsets, 94 not in `ram.md`; `+0x1B3` "Dark Force
> ## Startup" is item (1)'s lead; the 14z-123 advancing guard is their
> ## "Tech Hit", field for field); UNBLOCKED. THE RULE: EXACT or a
> ## CONSTANT OFFSET validates ours, an INCONSISTENT pattern means re-measure
> ## OURS in-emulator — the emulator arbitrates, never the sheet; (3) the
> ## **ZABEL j.LK
> ## PROXIMITY GUARD** — its own session; a LEGACY-content patch needing its
> ## own track/flag and expectation class; START WITH A RECORDING ([VSP-20]),
> ## then archaeology ([VSP-14]), then measure vanilla's proximity-guard test
> ## on every other normal before touching a byte.
> ##
> ## **IF A DOC IS TOUCHED:** the per-commit battery is census `--check`
> ## (`--freeze` only after reviewing renames) + `checkdocshape --no-pending`
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check`, exit
> ## statuses captured directly; wrapped `##` headers are house style and any
> ## new section-level check must be wrap-aware (14z-124's tooling fix).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## forgone; the COSMETIC BACKLOG (incl. the 1P roulette-tag row).
> ## `test_random_select_tenants.sh`'s CONTROL is still `build/m3b_merged19`;
> ## `test_hui_df_style.sh`'s header still describes its 14z-79 `differs`
> ## expectation (a stale gate header, not a defect — the DF section says so).
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.

Moved at 14z-122 by the documentation rationalization pass. This file holds
every superseded orientation opener, newest first, exactly as each was
written at its session's close — kept for the census anchors, eliminations
and traps they carry; superseded as orientation. Historical entries are
never rewritten (CLAUDE.md §5 [VSP-13] step 4); a stale claim inside one is
corrected at its live carrier, never here. ROLLOVER RULE (part of the
session-close ritual since 14z-122): when `NEXT_SESSION.md` is rewritten,
the previous opener moves to the TOP of this file's body, marked
`## (HISTORY) … — superseded by the <session> opener`. No `**[PFX-N]**`
anchor lives in this file.

---

## (HISTORY) NEXT SESSION orientation (the 14z-123 close opener — superseded by the 14z-124 close rewrite)

> Rewritten at every session close ([VSP-17]). ROLLOVER (since 14z-122):
> the previous opener moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md`
> — this file holds ONLY the live orientation. Session state, not knowledge:
> facts belong in the docs, status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. 14z-123 is PUSHED (maintainer's word, 2026-08-30: `f7d4781..719c560`);
> ## check `git status -sb`, not this line.**
> ##
> ## **THE DOCUMENTATION RATIONALIZATION PASS IS ONE COMMIT FROM DONE.** 14z-123
> ## did T1, G2 (all three rigs — every claim RETRACTED), the T2s, G3 (a)+(b),
> ## G4, G6 (1)+(2), CLAUDE.md pass 1, G7 partial (STATE 14z-123). ONE document
> ## is still PENDING in `docs/doc_shape.tsv`: **`docs/game/engine_internals.md`**.
> ##
> ## **OPEN THE SESSION WITH G3 (c)** — `engine_internals.md` :2948-end, the
> ## method of `g3a.py`/`g3b.py` (memory `doc-rationalization-pass`): the Dark
> ## Force header + its 14z-79 blockquote (`inferred_claims.md` row 10) → one
> ## header + dated facts; the grenade's six 14z-70x passes → the history twin,
> ## keeping the ANCHOR METHOD and the 14z-70f conclusion; the beam family →
> ## history; Atlas rows + Gates on every `##`. Then flip the row to REFERENCE
> ## (requires: banner, atlas-rows), `python3 tools/checkdocshape.py
> ## --no-pending` green, bump the ci floor (`ci.yml`) = **G7 DONE**. Per-commit:
> ## census `--check`/`--freeze` (renames re-freeze after review) + checkdocshape
> ## + checkdocs + checkskills + `gen_annotations.py` regenerated from a CLEAN
> ## WORKTREE of the commit's files + `gen_gate_index.py --check`, exit statuses
> ## captured DIRECTLY; the [VSP-13] grep in the commit body; review the diff
> ## PER HUNK. Load `vampire-saved-port` first.
> ##
> ## **TWO RULINGS WAIT** (STATE "Decisions pending"): CLAUDE.md PASS 2 (the
> ## structural cut — the oracle-class spec to its own document, the taxonomy
> ## list to docs/README — moves anchored law out of the constitution; pass 1
> ## took it 441 → 414 lines), and the ZABEL j.LK PROXIMITY GUARD (its own
> ## session; START WITH A RECORDING, [VSP-20]).
> ##
> ## **NEW INDEXES, both generated and gated:** `docs/annotations.md` (every
> ## program address → its carriers; the CODE-ONLY tail is the documentation
> ## gap) and `docs/project/gate_index.md` (every `tests/*.sh`; families in
> ## `tests/gate_index.tsv` — a new script needs a row or the gate fails).
> ## HANDOFF's gate fence is gone: a gate's WHY is in its header.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## (forgone); the COSMETIC BACKLOG gained the 1P roulette-tag row.
> ## `test_random_select_tenants.sh`'s CONTROL is still `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.

## (HISTORY) NEXT SESSION orientation (the 14z-122 close (2) opener — superseded by the 14z-123 close rewrite)

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. 10 commits are LOCAL past the pushed `f7d4781` — push at the
> ## maintainer's word; check `git status -sb`, not this line.**
> ##
> ## **THE WORK IS THE DOCUMENTATION RATIONALIZATION PASS** (STATE 14z-122 +
> ## its post-close entry). Tooling T1-T5, G0 and G1 are DONE; the SPECIMEN
> ## is RATIFIED ("it's good"). 6 docs PENDING in `docs/doc_shape.tsv`:
> ## README, HANDOFF, engine_internals, platform/mister, mister_core,
> ## mister_map. The live worklist: `docs/project/inferred_claims.md`.
> ##
> ## **OPEN THE SESSION WITH THE ANNOTATIONS CHECK (T1, maintainer-ruled
> ## 2026-08-30):** does an address→label/comment STREAM exist beyond the
> ## atlas + manifest comments (look at `re/ghidra/` first)? Covered → the
> ## CLAUDE.md row's retirement stands, reworded to say where; a real gap →
> ## CREATE `docs/annotations.md` and the row returns. Then **G2 — the three
> ## T3 measurements** (the Aulbath-victim DF accumulator rig; the
> ## attract-palette VS-screen surface; the throw mash-escape rig) BEFORE
> ## engine_internals (G3, three commits, never (a) and (c) in one session);
> ## the T2s batch by instrument; then G4 mister, G6 HANDOFF, **the
> ## CLAUDE.md CONDENSING PASS (new, maintainer-directed — "Decisions
> ## pending"; 30 VSP anchors, keep every marker with its fact)**, G7 close
> ## (`checkdocshape --no-pending`, ci floor). Per-commit verification:
> ## census `--check`/`--freeze` + `checkdocshape` + checkdocs + checkskills
> ## with exit statuses captured DIRECTLY, and the [VSP-13] grep in the
> ## commit body. Load `vampire-saved-port` first.
> ##
> ## **THE OTHER FUTURE ITEM — ZABEL j.LK PROXIMITY GUARD — is RECORDED,
> ## not started** (STATE "Decisions pending"): a surgical vanilla+WIDE
> ## patch, its own session; START WITH A RECORDING ([VSP-20]).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.


## (HISTORY) NEXT SESSION orientation (the 14z-122 opener, amended in-session after G1 — superseded by the close rewrite)

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. 14z-122 is NOT pushed (main is ahead of origin by the session's
> ## commits) — push at the maintainer's word.**
> ##
> ## **THE WORK IS THE DOCUMENTATION RATIONALIZATION PASS (maintainer-ruled,
> ## STATE 14z-122).** Tooling T1-T5 + G0 are DONE: the anchor census, the
> ## key-liveness locks, the doc-shape lint (`docs/doc_shape.tsv` — 19 rows
> ## still PENDING, each flips in its own document's commit), the generated
> ## GOTCHAS index, the SPECIMEN (`docs/project/tables/reconciliation.md` +
> ## its `_history.md` twin), the NEXT_SESSION split, and the worklist
> ## `docs/project/inferred_claims.md` (16 rows; its T3 rigs gate the
> ## engine_internals commits).
> ##
> ## **THE SPECIMEN IS RATIFIED ("it's good", maintainer 2026-08-30) and G1
> ## IS DONE (post-close, same day — STATE 14z-122 post-close entry): eight
> ## document commits; 6 docs remain PENDING (README, HANDOFF,
> ## engine_internals, platform/mister, mister_core, mister_map). STILL
> ## AWAITING THE RULING: the CLAUDE.md annotations-row retirement (asked,
> ## answered, open to veto).** **NEXT, in order:** G2 — the three T3
> ## measurements (the Aulbath-victim DF accumulator rig, the
> ## attract-palette VS-screen surface, the throw mash-escape rig) BEFORE
> ## engine_internals (G3, three commits, never (a) and (c) in one
> ## session); the T2s batch by instrument (inferred_claims); then G4
> ## mister, G6 HANDOFF (gate index + WHY-to-script-header migration),
> ## G7 close (`checkdocshape --no-pending` green, ci floor bumped).
> ## Per-commit verification: portable tier + census `--check`/`--freeze` +
> ## `checkdocshape --only <path>` + the [VSP-13] moved-block grep in the
> ## commit body. Load `vampire-saved-port` first.
> ##
> ## **THE SECOND FUTURE ITEM — ZABEL j.LK PROXIMITY GUARD — is RECORDED,
> ## not started** (STATE "Decisions pending"): a surgical patch for BOTH
> ## vanilla vsav and WIDE; legacy content, so it needs its own ratified
> ## class and build track; START WITH A RECORDING ([VSP-20]), never a
> ## theory, then the [VSP-14] archaeology.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`,
> ## `hui51/52`, `pyron35/36`, `m3b_merged20/21` (+ `merged19` control),
> ## `m5_stock12/13`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-121 close, 2026-08-30 — superseded by the 14z-122 opener)

> ## **START HERE. NOTHING IS RED, NOTHING IS PENDING ON HARDWARE, EVERYTHING
> ## IS PUSHED. M12 (merged-m14 `6649523a`, `build/m3b_merged21`) is
> ## FIELD-VERIFIED GREEN. No build has changed since that freeze.**
> ##
> ## **WHAT 14z-121 DID, one breath:** the M12 verdict recorded; the Killshread
> ## ruling (Summon has no ES; Killshread (ES)'s effect is the two-way summon —
> ## MEASURED, `test_killshread_es`); the phase-3 remainder — the attack
> ## record decoded from its READERS (`+0xC/+0xD` = the PUSHBACK STEP-TABLE
> ## index, `+0x13` freeze class, `+0x1B` recovery class, `+0x1A` scaling row,
> ## `+0x1C` an Aulbath-victim accumulator — "scales the pushback" RETRACTED),
> ## the "unindexed lying/wake nodes" = a chain-decoder BOUND BUG (fixed; all
> ## three tenants share the same canonical `b:` reaction seqs — "own table"
> ## RETRACTED), every `$FF9400` projectile's parameters (`test_projectile_params`,
> ## ours == vs2), the 17 `gap_*` rows resolved; the residue (Plasma Trap =
> ## jump phase, `0x3d` = `0x3c`'s loop body, `+0x392` not a meter); the map
> ## carries projectiles; THE CHARACTER PAGES — public artifacts (no art) and
> ## INTERNAL pages with sprites + outlined boxes + detached hits, regenerable
> ## from a user's own dumps: `ROMDIR=... tools/charpages_internal.sh` ->
> ## `../charpages/` (above the tree). URLs in `docs/project/tables/README.md`.
> ##
> ## **NEXT, the maintainer's pick:** more refinements to the character pages
> ## (point at what looks off; the sprite pipeline is `sprite_capture.lua` ->
> ## `charpages_frames.py` -> `sprite_render.py` -> `charmap_html.py --sprites`);
> ## or the small engine opens: the a2 mid-chain ENTRY index picker, the throw
> ## mash-escape step family (`0x27082`), the `x2b7ef4` effect-tail residue.
> ## Load `vampire-saved-port` first.
> ##
> ## **RULED 14z-122 (maintainer): TWO FUTURE ITEMS.** (1) THE DOCUMENTATION
> ## RATIONALIZATION PASS — in progress from 14z-122 (STATE 14z-122; plan:
> ## enforcement tooling first, then one commit per document, chronology to
> ## `<name>_history.md` twins, inferred claims RE-MEASURED). (2) ZABEL j.LK
> ## PROXIMITY GUARD — a surgical patch for BOTH vanilla vsav and WIDE, its
> ## own session, NOT started; the record and its constraints are in STATE
> ## "Decisions pending". Start it with a recording ([VSP-20]), never a theory.
> ##
> ## **TRAPS PAID 14z-121 (`project/gotchas.md`):** a table bound that tests a
> ## word AFTER appending it; "the only writer" names the tap's WINDOW; a
> ## filter naming a BUILD's property (group C) is not a property of the game;
> ## a tile set is within-bank until the bank word says otherwise; zsh does not
> ## word-split `$var` (`${=var}`); a rig that never fires is deleted.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win quotes
> ## (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`, `hui51/52`,
> ## `pyron35/36`, `m3b_merged20/21` (+ `merged19` control), `m5_stock12/13`.


# HISTORY BELOW — the 14z-121 mid-day openers, the 14z-120 close opener and older;
# kept for the census anchors, eliminations and traps, superseded as the opener.

## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-120 close, updated through 14z-121 (4) — superseded by the 14z-121 close opener above)

> ## **START HERE. NOTHING IS RED, NOTHING IS PENDING ON HARDWARE. M12 IS
> ## FIELD-VERIFIED GREEN (maintainer, MiSTer, 2026-08-30, STATE 14z-121) —
> ## merged-m14 `6649523a`, `build/m3b_merged21`, Donovan walks and jumps
> ## with VS2's values on silicon too. No build has changed since that
> ## freeze. Check `git status -sb`, not this line, for the push state.**
> ##
> ## **WHAT 14z-121 DID:** recorded the verdict (one row + the sweep of its
> ## "not yet field-tested" twins) and took the maintainer's Killshread
> ## ruling: `Killshread Summon (ES)` DROPPED from `moves_donovan.toml`
> ## (53 rows; no ES — measured 14z-120, confirmed); the stance pair's ES is
> ## **Killshread (ES)** (`a2:0x46`) and its effect plays DURING THE SUMMON —
> ## the sword attacks both going away and coming back (stated, not measured;
> ## a phase-3 measurement if wanted: the summon's attack records under ES).
> ##
> ## **WHAT 14z-120 DID, one breath — the character-data map from the move
> ## lists to phase 3:** the three move lists in
> ## `build/manifest/moves_{donovan,pyron,huitzil}.toml`; EVERY chain of the
> ## three tenants NAMED on native vs2 (`tools/name_moves.py`,
> ## `tests/test_move_naming.sh`); PHASE 2 the hitbox encoding (`(x, y, hw,
> ## hh)` authored facing LEFT; `+0x8C` = attack records, `+0x90` = push;
> ## class `+0x17`, `+0x14` attacker meter, `+0x1C` pushback —
> ## `tools/hitbox_records.py`, `tests/test_hitbox_encoding.sh`); PHASE 3 the
> ## reaction sets (~~own table per character~~ — SHARED canonical `b:` seqs, 14z-121 (2); block = `0xFF` on shared
> ## `b:0x0c`, stun = freeze + chain + a HOLD released when the pushbox
> ## separation settles — `tools/reaction_map.py`, `tests/test_reactions.sh`),
> ## projectile parameters inline per type handler, the projectile-type
> ## census. The maps (`docs/project/tables/chars/`) carry it all.
> ##
> ## **RULINGS ON RECORD:** Dark Force at VS cost is on purpose (DECIDED);
> ## Genocide Vulcan is 421+P; Planet Burning ES confirmed; Killshread as above.
> ##
> ## **NEXT, the maintainer's pick:** (B) the phase-3 remainder — how `+0x1C`
> ## couples to the separation ~~the lying/wake nodes reached by a COMPUTED
> ## address~~ ~~per-type projectile handlers~~ ~~the `gap_*` tables~~ (ALL FOUR DONE
> ## 14z-121 (2) — see STATE), ~~the Killshread (ES) two-way attack~~ (MEASURED
> ## + gated 14z-121 (3)), ~~the accumulator's states~~ (Aulbath's, 14z-121 (3));
> ## the pushback's carrier is record `+0xC` (14z-121 (3)); ~~(C) the small naming opens (Donovan's `0x3d`, Plasma
> ## Trap's HK chain)~~ (BOTH RESOLVED 14z-121 (4)). Load `vampire-saved-port` first; the maps' "What is
> ## NOT decoded" is the worklist.
> ##
> ## **TRAPS PAID 14z-120 (`project/gotchas.md`):** a throw leaves P2 behind
> ## P1 and mirrors every later motion — pin far, walk in, sample the facing
> ## byte; a poked near pair overlapping pushboxes CROSSES the fighters;
> ## "+0x1D" and "+0x17" were one byte counted from two bases; a table below
> ## the crypt boundary is read through the DATA view; "hold away" for a
> ## left-facing P2 is R.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged from 14z-119 — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`, `hui51/52`,
> ## `pyron35/36`, `m3b_merged20/21` (+ `merged19` control), `m5_stock12/13`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-120 close, 2026-08-30 — superseded by the 14z-121 opener above)

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED SINCE THE M12 FREEZE
> ## (merged-m14 `6649523a`, `build/m3b_merged21`; bundle
> ## `../mister_fieldtest_14z119/`, tell "M12"). The maintainer's board test
> ## of M12 was IN PROGRESS at the close — record the verdict FIRST (one row,
> ## STATE + `mister_field.md`; the 14z-118 gotcha "a field verdict lands in
> ## one row"). Everything is PUSHED.**
> ##
> ## **WHAT 14z-120 DID, one breath — the character-data map from the move
> ## lists to phase 3, in one day:** the maintainer's three move lists live
> ## in `build/manifest/moves_{donovan,pyron,huitzil}.toml`; EVERY chain of
> ## the three tenants is NAMED on native vs2 (`tools/name_moves.py`,
> ## `tests/test_move_naming.sh`: 412 frozen lines, each row's seq entered
> ## by an event of its own name on the sampled id); PHASE 2 measured the
> ## hitbox encoding (`(x, y, hw, hh)` authored facing LEFT; `+0x8C` =
> ## attack records = base[4], `+0x90` = push = base[3]; family `hb8`,
> ## record `hbA>>8`; class `+0x17` on every path, `+0x14` attacker meter,
> ## `+0x1C` pushback — `tools/hitbox_records.py`,
> ## `tests/test_hitbox_encoding.sh`); PHASE 3 measured the reaction sets
> ## (each class enters the character's own table, block = `0xFF` on the
> ## shared `b:0x0c`, stun = freeze + chain + a HOLD released when the
> ## ~~pushbox separation settles~~ pushback STEP LIST `0x2783C[record +0xC]` ends (14z-121 (3)) — `tools/reaction_map.py`,
> ## `tests/test_reactions.sh`), projectile parameters inline per type
> ## handler, and the projectile-type census (`test_projectile_census.sh`).
> ## The maps (`docs/project/tables/chars/`) carry it all: named chains,
> ## attack records, frame data, reactions.
> ##
> ## **RULINGS:** Dark Force at VS cost is on purpose (DECIDED); Genocide
> ## Vulcan is 421+P (confirmed); Planet Burning ES confirmed as measured.
> ##
> ## **TRAPS PAID (`project/gotchas.md`):** a throw leaves P2 behind P1 and
> ## mirrors every later motion — pin far, walk in, sample the facing byte;
> ## a poked near pair overlapping pushboxes CROSSES the fighters; "+0x1D"
> ## and "+0x17" were one byte counted from two bases; a table below the
> ## crypt boundary is read through the DATA view; "hold away" for a
> ## left-facing P2 is R; macOS `wc -l` pads.
> ##
> ## **NEXT, the maintainer's pick:** (A) the M12 verdict; (B) the phase-3
> ## remainder — how `+0x1C` couples to the separation, the lying/wake nodes
> ## reached by a COMPUTED address (no long pointer in vs2's program space),
> ## per-type projectile handlers beyond Blizzard, the `gap_*` tables; (C)
> ## the small naming opens (Donovan's `0x3d` / Killshread Summon (ES),
> ## Plasma Trap's HK chain). Load `vampire-saved-port` first; the maps'
> ## "What is NOT decoded" is the worklist.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`.
> ##
> ## **STATE OF THE BUILDS:** unchanged from 14z-119 — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`, `hui51/52`,
> ## `pyron35/36`, `m3b_merged20/21` (+ `merged19` control), `m5_stock12/13`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-120 close, 2026-08-30; updated at 14z-120 (2) — superseded by the fresh-session opener above)

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), NOT PUSHED
> ## (main is ahead of origin by the 14z-119 freeze + close and the 14z-120
> ## commits), NOT FIELD-TESTED (bundle `../mister_fieldtest_14z119/`, tell
> ## "M12"; pick Donovan, walk, jump; `.rbf` unchanged).**
> ##
> ## **WHAT 14z-120 DID, one breath:** the maintainer's three move lists live
> ## in `build/manifest/moves_{donovan,pyron,huitzil}.toml` (conventions in
> ## the Donovan header), and DONOVAN'S NAMING STEP IS DONE: 53 chain ids
> ## measured on native vs2 by `tools/name_moves.py` (eight rigs, P1's
> ## `obj+0x1C` per frame onto the decoded graph), frozen by
> ## `tests/test_move_naming.sh`, labelled in `docs/project/tables/chars/
> ## donovan_anim.md`. Found on the way: the SWORDLESS normal set
> ## (`a2:0x1e-0x23`, `0x25/0x26`); ES = its own chain for every special;
> ## Slay Shred has no fighter chain (2 stocks natively); `$FF8109` is a
> ## BINARY timer (a `0x99` poke ends the round — `project/gotchas.md`).
> ##
> ## **UPDATE, same day (STATE 14z-120 (2)):** PYRON'S AND HUITZIL'S NAMING
> ## STEPS ARE DONE TOO — 41 + 49 chain ids, both TOMLs filled, the gate
> ## loops the three tenants, the appendices are labelled. The rig learned
> ## to PIN BOTH FIGHTERS' X before every event (a throw had put P2 behind
> ## P1 and half the first pass measured MIRRORED motions — `project/
> ## gotchas.md`). TWO QUESTIONS FOR THE MAINTAINER: Genocide Vulcan measured
> ## as 421+P (the list says 421+K, which never fired in nine cadences); the
> ## guard cancel spent no banked stock. (An earlier "no ES Planet Burning"
> ## reading was the rig facing LEFT — retracted; 63214+PP up close IS the ES
> ## grapple, same chains as the throw with class byte 16.)
> ##
> ## **PHASE 2 DONE (STATE 14z-120 (5)):** the hitbox encoding and the attack
> ## record are MEASURED — boxes `(x, y, hw, hh)` authored facing LEFT (x
> ## negated when flip_x = 1), `+0x8C` = attack records (base[4]) / `+0x90`
> ## = push (base[3]), node `hb8` = the vuln/push family, `hbA>>8` = the
> ## attack record, class = record `+0x17` on every path (the "+0x1D" was
> ## the same byte from the wrong base). `tools/hitbox_records.py`,
> ## `tests/test_hitbox_encoding.sh`, the maps' "Hitboxes and attack
> ## records" section and per-chain startup/active/recovery.
> ##
> ## **PHASE 3 (reactions) DONE (STATE 14z-120 (7)):** each tenant's reaction
> ## SET measured as the victim (`tests/test_reactions.sh`, the maps'
> ## "Reactions as the victim"): the classes enter the character's own
> ## table (`c` Donovan/Huitzil, `b` Pyron), a block is class `0xFF` on the
> ## shared `b:0x0c`, the stun lengths are an engine counter (light 19 /
> ## medium 23 / heavy 35 / blocked 22-26 / sweep ~70 on all three).
> ## Record fields `+0x14` (attacker meter) and `+0x1C` (pushback) measured.
> ##
> ## **Also measured (STATE 14z-120 (8)-(12)):** the stun = freeze + the
> ## reaction chain + a HOLD released when the victim stops sliding — and
> ## the light/medium slide is the PUSHBOX SEPARATION routine (vs2
> ## `0x17D30`) settling the reaction nodes' push boxes, not a velocity;
> ## projectile parameters are INLINE in each type's handler (Blizzard
> ## Sword xv/yv by strength at vs2 `0x670C0`, ported region); the
> ## projectile-type census per move is gated (`test_projectile_census.sh`).
> ##
> ## **NEXT, the maintainer's pick:** (A) the board verdict on M12; (B) the
> ## phase-3 remainder: how `+0x1C` couples to the separation, the
> ## unindexed lying/wake nodes (NO long pointer to them anywhere in vs2's
> ## program space — a computed address), per-type projectile handlers,
> ## the `gap_*` tables; (C) the
> ## small opens: Donovan's `0x3d` / Killshread Summon (ES); Plasma Trap's
> ## HK chain. Load `vampire-saved-port` first.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19`. New small ones (STATE 14z-120 "open"): Change
> ## Immortal's `0x3d`; the unentered `a2` ids; the `Killshread Summon (ES)`
> ## row (measured: no ES — drop it?).
> ##
> ## **STATE OF THE BUILDS:** unchanged from 14z-119 — play `tools/run_wide.sh
> ## build/m3b_merged21 fbneo`; current + one back: `don_m17/m18`, `hui51/52`,
> ## `pyron35/36`, `m3b_merged20/21` (+ `merged19` control), `m5_stock12/13`.



## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-119 close, 2026-08-30 — superseded by the 14z-120 opener above)

> ## **START HERE. NOTHING IS RED. THE M12 FREEZE IS DONE — donovan-m18 /
> ## huitzil-m25 / pyron-m19 / merged-m14 (`build/m3b_merged21`, `6649523a`,
> ## 826 ops), mark M12: DONOVAN WALKS AND JUMPS WITH VS2's VALUES on every
> ## shipping track (maintainer-ruled 2026-08-29). The two red-by-design
> ## gates are re-pinned. NOT PUSHED — push at the maintainer's word; NOT
> ## FIELD-TESTED — the next event is the BOARD VERDICT on
> ## `../mister_fieldtest_14z119/` (the tell is "M12"; pick Donovan, walk,
> ## jump; `.rbf` unchanged, flash nothing).**
> ##
> ## **WHAT 14z-119 DID, one breath:** the whole 14z-115 battery in one
> ## session (~6 h wall-clock, legs in parallel). The change was 17 bytes
> ## in three bank rows and NO address moved, so every frozen structural
> ## expectation (pointer_flow, pcrel, escape_triage, bases.tsv) came out
> ## IDENTICAL; huitzil/pyron suites bit-identical to m24/m18; Donovan's
> ## six tenant rigs moved and were attributed AT THE ONSET FRAME
> ## (`$FF8441/42` = his X-velocity word, `0x0280 -> 0x0300` = 2.5 -> 3.0 —
> ## the port itself). **TWO THINGS THE PLAN DID NOT PREDICT:** (1) THE STOCK
> ## TWIN MOVED (`d29fd062 -> 38e9cb2c`): `port_param32` is a per-row
> ## data_port, not profile-gated, so the substituted track writes his VS2
> ## rows onto stock slot 0x0F too (six ops; no legacy row); (2) huitzil/
> ## pyron program fingerprints did NOT change (the glyph is group C), so
> ## the registry's m24/pyron-m18 rows are commented out and m25/m19 added
> ## with the same sha (first-match resolver). Both in STATE 14z-119.
> ##
> ## **TRAP PAID (`project/gotchas.md`):** a re-point stamp trailing a TOML
> ## section header / key line breaks the gates' regex parsers, and a blind
> ## name sweep rewrites HISTORY in comments — after every sweep, read the
> ## comment-line hits.
> ##
> ## **NEXT, the maintainer's pick:** the board verdict on M12; then (B)
> ## phase 2 of the character-data map (hitbox rectangles + attack records
> ## by MEASUREMENT on native vs2; settles the `+0x17` vs `+0x1D` class-byte
> ## disagreement) or (C) the move lists -> `build/manifest/moves_<tenant>.toml`
> ## (phase 1 naming; the chain decoder is live-verified). Load
> ## `vampire-saved-port` first; the map's "What is NOT decoded" is the worklist.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is still
> ## `build/m3b_merged19` (kept on disk for it).
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged21
> ## fbneo`. Current + one back: `don_m17/m18`, `hui51/52`, `pyron35/36`,
> ## `m3b_merged20/21` (+ `m3b_merged19` control), `m5_stock12/13`. The
> ## physics probe dirs are gone (their evidence is the freeze).


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-118 close, 2026-08-29, for a FRESH session — superseded by the 14z-119 opener above)

> ## **START HERE. TWO GATES ARE RED BY DESIGN — not a defect: after Donovan's
> ## physics port (`port_param32 = true`, maintainer-ruled) the tree
> ## reproduces the probe `7109f835`, not the frozen donovan-m17, so
> ## `test_m3a_reproducible` and `test_tenant_loop` (339/615/826 ops) stay red
> ## until the M12 FREEZE BATTERY re-pins them. Everything else is green and
> ## PUSHED.**
> ##
> ## **THE MAINTAINER CHOOSES THE ORDER: (A) the M12 battery first** (~5 h;
> ## STATE 14z-115 has the order; it also regenerates the three
> ## `docs/project/tables/{donovan,huitzil,pyron}.md` AND the six
> ## `docs/project/tables/chars/*` pages — `test_tables_current` /
> ## `test_charmap_current` gate them; mark M11 -> M12; expect the Donovan
> ## tenant-rig `.sha1`s to move — his walk and jumps are VS2's now —
> ## attribute by DUMPS as always) **or (B) phase 2 of the character-data
> ## map first** (hitbox rectangles + attack records by MEASUREMENT on
> ## native vs2; settles the `+0x17` vs `+0x1D` class-byte disagreement).
> ## **(C) the move lists**, when the maintainer provides them ->
> ## `build/manifest/moves_<tenant>.toml` (template committed) = phase 1's
> ## naming; the chain decoder is already live-verified.
> ##
> ## **WHAT EXISTS (one breath):** the character-data map — `tools/charmap_gen.py`
> ## -> `docs/project/tables/chars/<tenant>.json` (agents) + `.md` and
> ## `_anim.md` (humans); overrides in `build/manifest/charmap_<tenant>.toml`
> ## compiled by `tools/charmap_compile.py` into a marked block of the tenant
> ## manifest; `tools/anim_nodes.py` + `tests/test_anim_node_walk.sh` (3,638/
> ## 3,638 node pointers on the graph, Donovan on native vs2). Every ours-vs-
> ## VS2 difference on the three solos is attributed (bank 0, dispatch 0,
> ## anim nodes 0 unattributed; 692/342/342 bytes in the effect tail named).
> ## Load `vampire-saved-port` first; the map's "What is NOT decoded" is the
> ## worklist.
> ##
> ## **CURRENT (frozen):** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`),
> ## stock twin `d29fd062`; bundle 14z117b FIELD-VERIFIED GREEN (M11).
> ## UNFROZEN: Donovan's physics rows (probe `build/don_phys_probe`).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone). `test_random_select_tenants.sh`'s CONTROL is
> ## `build/m3b_merged19` — re-point or accept its SKIP when it rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`; plus the probe `don_phys_probe`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-118 audit close, 2026-08-29 — superseded by the fresh-session opener above)

> ## **START HERE. NOTHING IS RED. TWO ARCS CLOSED THIS SESSION: the
> ## documentation audit (16 commits, STATE 14z-118 CLOSE + CLOSE (2)) and
> ## PHASE 0 OF THE CHARACTER-DATA MAP (STATE 14z-118 (charmap)):
> ## `docs/project/tables/chars/<tenant>.{json,md}`, overrides in
> ## `build/manifest/charmap_<tenant>.toml`, gates `test_charmap_current` /
> ## `test_charmap_overrides`. **RULED AND BUILT, UNFROZEN: Donovan's physics
> ## rows now port VS2's values (`port_param32`, probe `don_phys_probe`
> ## `7109f835`, validated) — THE NEXT FREEZE BATTERY carries it (M12). UNTIL
> ## THEN `test_m3a_reproducible` + `test_tenant_loop` are RED BY DESIGN (339/615/826
> ## ops). Phase 1's node chains are decoded AND live-verified
> ## (`test_anim_node_walk`); `<tenant>_anim.md` pages exist.**
> ## Next phases: (1) anim node dumper + move naming (needs the maintainer's
> ## move lists) + derived frame data; (2) hitbox rectangles + attack records
> ## by measurement; (3) stun / projectile / auto tables. Check `git status -sb`.**
> ##
> ## **WHAT NOW EXISTS:** `tools/checkdocs.py` + `docs/doc_locks.tsv` (16
> ## cross-document number locks, `test_checkdocs`, ci_portable — ADD A ROW
> ## whenever a number is quoted in a second document); `tools/tables_char_md.py`
> ## + `test_tables_current` (ci_static — the three community tables follow
> ## the build; REGENERATE THEM IN EVERY FREEZE COMMIT, the re-point sweep
> ## moves their build names). Both are in the HANDOFF gate index.
> ##
> ## **WHAT THE PASS FOUND, one breath:** nearly every "guessed" claim was
> ## settled by CITING a gate that already existed — the docs measured more
> ## than they said. The one-hop class showed up inside single files
> ## (`character_tables.md` L45 vs L128) and inside the audit's own survey
> ## (three false leads, struck; `project/gotchas.md` "THE AUDIT'S OWN
> ## INVENTORY IS ONE HOP AWAY TOO").
> ##
> ## **WHAT IS LEFT, in order (STATE 14z-118 CLOSE "NOT done"):** ~~(a)~~
> ## DONE the same day (AUDIT (9)): Anakaris's DF measured — `0xAA` has NO
> ## Dark Force requester in the whole roster, the "very probably his" claim
> ## retracted, census frozen (`tests/expected/df_palette_seq_census.txt`;
> ## rerun with `DFRPL=tests/replays/df/97_df_mech.rpl CHARS="00 .. 0f"`).
> ## Still open from (a): whether a NON-DF path requests `0xAA` — a whole-
> ## corpus phase-A census before anyone calls the block free. ~~(b)~~ DONE
> ## (AUDIT (10)): the fourteen gotchas re-filed with their anchors;
> ## ~~(c)~~ DONE (AUDIT (11)): the attract roster decoded, traced and gated
> ## (`test_attract_roster`); `$FF8127`'s 14z-104 reading was WRONG — it marks a
> ## P2-won down, not a P1-won one, and flips at the refill (semantics OPEN);
> ## the real side codes are `$FF8105`/`$FF810C`; ~~(d)~~ DONE (AUDIT (12)); ~~(e)~~
> ## RULED 2026-08-29 (AUDIT (13)): STOCK CONTROL kept, run once per NEW `.rbf`.
> ## **THE 14z-118 LIST IS CLOSED**, and the `0xAA` question with it (AUDIT (14)):
> ## the whole-corpus census ran (73 legs) and `0xAA-0xAD` is SASQUATCH's —
> ## palette-seq blocks are 8 ids, `BASE + ($381<<2) + phase`, and a free one
> ## is found by reading `0x02A8A4`'s routines, never by a census. `+0x381` is
> ## the PLAYER-SIDE index (tapped: set at init, AUDIT (15)) — so a block is 4
> ## ids per SIDE. `$FF8127` RESOLVED (AUDIT (16)): a per-frame comparator of
> ## the two fighters' object byte `+0x10` (writer `0x02228E`), not match state.
> ## Open, only if it ever matters: what object byte `+0x10` is.
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`; bundle 14z117b
> ## FIELD-VERIFIED GREEN (M11, 2026-08-29). Fork `f997cfe1` (27 commits).
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-118 VERDICT, 2026-08-29 — superseded by the 14z-118 close above)

> ## **START HERE. NOTHING IS RED. THE M11 BOARD VERDICT IS GREEN
> ## ("behavior identical to emulation", maintainer, MiSTer, 2026-08-29 —
> ## STATE 14z-118). Nothing is pending on hardware. THE WORK IS THE
> ## DOCUMENTATION AUDIT, ruled by the maintainer: every claim MEASURED not
> ## guessed, everything consistent, nothing stale. The Sailor Moon S
> ## discipline.**
> ##
> ## **THE AUDIT ALREADY HAS ITS FIRST SPECIMEN, from recording the verdict:**
> ## the M9 and M10 verdicts had each been written into ONE row while nine
> ## "not field-tested / pending" lines stayed alive in headers, registry
> ## rows and `mister_field.md` — the file whose job is the verdict log.
> ## Retired 14z-118 (`project/gotchas.md` "A FIELD VERDICT LANDS IN ONE
> ## ROW"). Expect the same shape everywhere: a claim right at its source
> ## and wrong one hop away.
> ##
> ## **HOW TO SHAPE THE AUDIT** (the 14z-113/114 staleness passes are the
> ## template — S1-S20 for MiSTer, S-C1..S-C12 for the game docs, S-D for
> ## the port docs; one commit per document): INVENTORY FIRST —
> ## `docs/project/doc_audit_14z118.md`, one row per document in
> ## `docs/game/`, `docs/platform/`, `docs/project/`, HANDOFF and the six
> ## skills (~29,000 lines), each claim marked MEASURED (name the log, gate
> ## or dump) / DERIVED (from a measured fact by a stated rule) / GUESSED
> ## (nothing behind it). Re-measure or RETRACT the third class; grep every
> ## retraction across the repo ([VSP-13]: headers and summary lines first).
> ## Lock cross-document numbers (addresses, counts, fingerprints, pins)
> ## with a script where one is cheap — `checkskills.py` already locks the
> ## skills to the docs; extend that idea to the atlas↔engine_internals
> ## pairs. Start with the specimen family: `character_tables.md` ↔
> ## `id_space.md` ↔ `engine_internals.md`'s character-bank section ↔ the
> ## data-architecture artifact
> ## (https://claude.ai/code/artifact/98d586db-1a69-49eb-b421-5085db07b707).
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle
> ## `../mister_fieldtest_14z117b/` — FIELD-VERIFIED. Everything pushed
> ## — check `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 FINAL close, 2026-08-29 — superseded by the 14z-118 opener above)

> ## **START HERE. NOTHING IS RED. TWO FREEZES SHIPPED AND PUSHED TODAY
> ## (merged-m12 M10, merged-m13 M11). THE NEXT SESSION IS RULED BY THE
> ## MAINTAINER: their board results on bundle 14z117b, then — the real
> ## work — A FULL DOCUMENTATION AUDIT: every claim MEASURED not guessed,
> ## everything consistent, nothing stale. The Sailor Moon S discipline.**
> ##
> ## **HOW TO SHAPE THE AUDIT** (the 14z-113/114 staleness passes are the
> ## template — S1-S20 for MiSTer, S-C1..S-C12 for the game docs, S-D for
> ## the port docs; one commit per document): for each document in
> ## `docs/game/`, `docs/platform/`, `docs/project/`, HANDOFF and the six
> ## skills, inventory its claims and mark each MEASURED (name the log,
> ## gate or dump that measured it) / DERIVED (from a measured fact by a
> ## stated rule) / GUESSED (nothing behind it). Re-measure or RETRACT the
> ## third class; grep every retraction across the repo ([VSP-13]: headers
> ## and summary lines first). Check cross-document consistency on the
> ## load-bearing numbers (addresses, counts, fingerprints, pins) with a
> ## script where one is cheap — `checkskills.py` already locks the skills
> ## to the docs; extend that idea to the atlas↔engine_internals pairs.
> ## **Today's specimen of the failure class:** the data-architecture page
> ## drew the character bank wrong (0x12 as real data, vsav2's vacated
> ## wheel cells as missing rows) while the atlas beneath it was right —
> ## a claim can be correct at the source and wrong one hop away.
> ##
> ## **WHAT 14z-117 DID, one breath:** the medallion-fix freeze (M10, cheap
> ## as predicted); the random-select feature (two thunks, one table,
> ## `roster_subst`; the walker's non-tick path re-reads the table — a
> ## bound-only thunk crashed, fixed; the Shadow rig re-timed) and its
> ## freeze (M11); the VS/VS2 data-architecture artifact, corrected after
> ## the maintainer's read: https://claude.ai/code/artifact/98d586db-1a69-49eb-b421-5085db07b707
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle
> ## `../mister_fieldtest_14z117b/` (`.rbf` unchanged). Everything pushed
> ## except the final close commit — check `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** the 1:1 wheel mockup; #112/#113 parked; the FBNeo
> ## two-run-family question; the tenant CPU AI "lackluster" note; win
> ## quotes (forgone, clean-way-only). `test_random_select_tenants.sh`'s
> ## CONTROL is `build/m3b_merged19` — re-point or accept its SKIP when
> ## that directory rolls off.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 SECOND close, 2026-08-29 — superseded by the final close above)

> ## **START HERE. NOTHING IS RED. TWO FREEZES SHIPPED TODAY — merged-m12
> ## (M10, the Pyron-medallion fix) and then merged-m13 (M11, RANDOM SELECT
> ## INCLUDES THE TENANTS) — and the next event is the BOARD VERDICT on
> ## `../mister_fieldtest_14z117b/` (the tell is "M11"; park on "?" and
> ## the draw cycles all 18).**
> ##
> ## **WHAT 14z-117 DID, one breath:** the freeze battery for the medallion
> ## fix (cheap as predicted: three ops changed content, no address moved),
> ## pushed at the maintainer's word; then, at their word, the random-select
> ## item: TWO profile-gated site_thunks at `0x020C74` (the bound) and
> ## `0x020C80` (the table read + rts + an 18-entry table), one table filled
> ## per build by the new generator feature `roster_subst`. **The trap paid
> ## for:** the walker re-reads the table on its NON-tick frames — a
> ## bound-only thunk crashed the figure refresh with a code byte as id
> ## (`game/gotchas.md`, `select_screen.md` "THE WALKER HAS TWO PATHS").
> ## Confirm semantics are vanilla's (what shows is what you get), the
> ## harness stages inputs one frame ahead, nine legacy select replays are
> ## bit-identical (none hovers "?"), stock twin unchanged both times.
> ## The Shadow rig (`113`) was RE-TIMED (confirm 1450 -> 1521-1522) because
> ## the wider draw made it a mirror match on the solos.
> ##
> ## **CURRENT:** donovan-m17 `90a225ce` / huitzil-m24 `ae953657` /
> ## pyron-m18 `1222df18` / merged-m13 `a1b7cb82` (`build/m3b_merged20`,
> ## 823 ops), stock twin `m5_stock12` = `d29fd062`. Fork `f997cfe1` (27
> ## commits / patch 0027), `release/merged-m13/`, bundle 14z117b (`.rbf`
> ## unchanged). Gates: `test_random_select_tenants.sh` (emulator tier,
> ## CONTROL = the previous merged; when `m3b_merged19` rolls off, re-point
> ## or accept its SKIP). Full numbers: STATE 14z-117 (2) and its CLOSE.
> ## **Everything PUSHED at the maintainer's word (fork, main, tags) — check
> ## `git status -sb`, not this line.**
> ##
> ## **OPEN, unchanged:** the maintainer's 1:1 wheel mockup; #112/#113
> ## parked; the FBNeo two-run-family question; the tenant CPU AI
> ## "lackluster" note; the win quotes (forgone, clean-way-only).
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged20
> ## fbneo`. Current + one back: `don_m16/m17`, `hui50/51`, `pyron34/35`,
> ## `m3b_merged19/20`, `m5_stock11/12`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-117 FIRST close, 2026-08-29 — superseded by the second close above)

> ## **START HERE. NOTHING IS RED. THE PYRON-MEDALLION FREEZE IS DONE —
> ## merged-m12 (M10) is frozen, tagged, released and bundled; the next
> ## event is the BOARD VERDICT on `../mister_fieldtest_14z117/` (the tell
> ## is "M10" bottom-right, three glyphs).**
> ##
> ## **WHAT 14z-117 DID, one breath:** rebuilt the four tracks with the mark
> ## M9 -> M10 (`version_x` 340 -> 324 — a third glyph at 340 clips at pixel
> ## 384), ran the whole 14z-115 battery, and froze donovan-m16 `7950c844` /
> ## huitzil-m23 `7ade3180` / pyron-m17 `01b39c39` / merged-m12 `cde712e1`
> ## (`build/m3b_merged19`, 819 ops), stock twin `m5_stock11` = `d29fd062`
> ## UNCHANGED. **The battery WAS cheap, as predicted:** on every build only
> ## three ops changed content and NO address moved; every masked legacy
> ## class passed on all three suites; the moved `.sha1`s were exactly the
> ## 14z-115 tenant/select-rig inventory (+ `113_shadow_vs_tenant`, frozen
> ## for the first time), attributed on 103 and 92 by DUMPS diff — execution
> ## position + dead stack, zero bytes past the victory screen. Pointer-flow
> ## WEAK +1 per build (the new coord pair); MiSTer bank-5 census 6,272 /
> ## extent `0xFE42` (the third glyph). merged_legacy 47/47, guard corpus
> ## 344/344, roster pairings 111/111, legacy pairings and strict — STATE
> ## 14z-117 CLOSE has the final numbers.
> ##
> ## **THE MiSTer TAIL WAS NOT EMPTY** (the program moved): fork `80e08111`
> ## (catalogue: six CRCs), patch 0026, pin bumped, `release/merged-m12/`,
> ## bundle `../mister_fieldtest_14z117/` (STOCK CONTROL MRA byte-identical
> ## to 14z-115's, `.rbf` unchanged — flash nothing). **Fork, main and the
> ## four tags PUSHED** at the maintainer's word (they took the bundle to
> ## the board); check `git status -sb`, not this line.
> ##
> ## **ONE TRAP PAID FOR, in `project/gotchas.md`:** the re-point sweep
> ## stamped four lines ending in `\` — `test_pointer_flow` PASSED with a
> ## truncated `for` list. Read a re-pointed gate's PASS by its per-item
> ## lines, and grep `'\\ *# re-pointed'` after every sweep.
> ##
> ## **OPEN, unchanged:** the maintainer's 1:1 wheel mockup (replaces the
> ## outline tiles through the same knobs); random select "include the
> ## tenants" (shape in STATE 14z-116, not built); #112/#113 parked; the
> ## FBNeo two-run-family question; the tenant CPU AI "lackluster" note.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged19
> ## fbneo`. Current + one back: `don_m15/m16`, `hui49/50`, `pyron33/34`,
> ## `m3b_merged18/19`, `m5_stock10/11`.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-116 close, 2026-08-29 — superseded by the 14z-117 opener above)

> ## **START HERE. THE WORK IS THE FREEZE BATTERY, and it is the whole
> ## session — start it fresh, on a full context budget. 14z-110b closed at
> ## the context ceiling with three validations in flight and cost 14z-111
> ## an opening audit; do not repeat that.**
> ##
> ## **WHAT IS WAITING TO BE FROZEN:** `build/m3b_merged19`
> ## (fingerprint `af21bc88`) — merged18 PLUS one fix: **Pyron's medallion
> ## white-out**. `PRG:0x05F9D0`'s P2 branch no longer writes palette row
> ## `0x1A` (`tst.b $381(a4)` -> `bne` to the pop/rts, two NOPs where
> ## `adda.w #$60,a1` was; SAME byte count, so no allocation ripple and
> ## **no re-point sweep for the thunk itself**). FIELD-VALIDATED on the
> ## board: medallion correct, the P2 select sword now orange, select
> ## screen only, "a good tradeoff". Detail: `donovan.toml`'s
> ## `select_sword_pal_variant_id` comment; gate
> ## `tests/test_pyron_medallion_2p.sh`.
> ##
> ## **WHY THE BATTERY SHOULD BE CHEAP THIS TIME, and where to check that
> ## assumption first:** the change is TEN BYTES inside one already-existing
> ## thunk body, on a path that runs only on a P2 TENANT HOVER. Measured at
> ## 14z-116: `38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select`
> ## are **BIT-IDENTICAL** between merged18 and merged19. Replay 38 is the
> ## one whose one-main-loop slip forced the 14z-88 revert, so that is the
> ## meaningful control. **EXPECT the solos to move** (they rebuild) and
> ## expect the tenant select rigs' self-frozen `.sha1`s to move on the
> ## P2-hover ones; attribute them by DUMPS diff as always.
> ##
> ## **THE BATTERY, in the 14z-115 order** (STATE 14z-115 has the full
> ## list): rebuild solos + merged + the stock twin (expect the stock twin
> ## UNCHANGED — the thunk is `only_variant_slot`) -> `run_suite` verify on
> ## the three sets -> `audit_merged_legacy` 47/47 -> `audit_guard_corpus`
> ## -> `audit_roster_pairings` 111/111 (**re-derive `bases.tsv` first** —
> ## it has rotted twice) -> `audit_legacy_pairings` -> `test_dualtrack`,
> ## `test_m3a_reproducible`, `test_fbneo_legacy_oracle`, `test_pointer_flow`
> ## (re-freeze WITH attribution), `pcrel`/`escape_triage`, `inp corpus`,
> ## the wheel/MiSTer/release gates -> `run_all_static --strict` -> tags,
> ## registry row, re-point sweep, N-2 build-dir sweep -> **the MiSTer tail
> ## (group C does NOT move, but the PROGRAM does: `gen_vsavjw_xml.py
> ## --check` will go red, so a new fork catalogue commit + patch + pin bump
> ## + bundle + `release/merged-m12/` are all needed)** -> docs.
> ## **NEW GATES TO INCLUDE, none in ci_static:**
> ## `tests/test_pyron_medallion_2p.sh`, `tests/test_shadow_tenant.sh`
> ## (both emulator tier, HANDOFF-indexed), and `test_win_quote_decode`
> ## (ci_static, already registered).
> ##
> ## **MARK: M9 -> M10** (`version_text` in all three manifests).
> ##
> ## **WHAT 14z-116 SETTLED, so none of it is re-derived:**
> ## **WIN QUOTES — FORGONE** by ruling, parked CLEAN-WAY-ONLY (the 14z-76
> ## whole-bank relocation is ruled OUT: it moves `RAM:$FFF230` on legacy
> ## win screens). A data-only fix is impossible (zero free bytes at BOTH
> ## hops); the real cost is ~330 GLYPH TILES. Tools + gate in the tree.
> ## **RANDOM SELECT** cannot pick a tenant — fixed 15-entry table at
> ## `PRG:0x020C88`, hard bounds; **the maintainer ADDED "include the
> ## tenants" to the list** (fix shape recorded in STATE, not built).
> ## **SHADOW** is armed by FIVE START PRESSES on the "?" cell and takes the
> ## character he JUST BEAT (`PRG:0x009BB2`, round end, unmasked) — he takes
> ## the TENANT, not the shell, confirmed on emulator and on the board in
> ## 2P vs. **MARIONETTE is a vs2 character**, parked. **No legacy character
> ## meets a tenant in 1P arcade** — ruled NOT A PROBLEM.
> ##
> ## **TWO TRAPS THIS SESSION PAID FOR, both in gate headers now:** the
> ## wheel route to the "?" cell is **Down, Down, Down-RIGHT** on a WIDE
> ## build (our port re-pointed cell `0x08`'s Down edge to Phobos, so
> ## vanilla's D,D,D is wrong); and Shadow's five STARTs are PRESSES, with
> ## the 6th DISARMING.
> ##
> ## **OPEN:** the maintainer's 1:1 wheel mockup (replaces the outline tiles
> ## through the same knobs, nothing to undo); #113 parked; #112 and the
> ## tenant CPU AI "lackluster" observation recorded, unscheduled. The
> ## FBNeo instrument question is NARROWED (the "unidentified writer" is
> ## retired — the binary's mtime is 2026-08-17, eleven days before the
> ## session that flagged it) but the two run families are still unexplained.
> ##
> ## **STATE OF THE BUILDS:** play `tools/run_wide.sh build/m3b_merged19
> ## fbneo`. merged18 is the last FROZEN set (merged-m11, M9); merged19 is
> ## the candidate. Everything is PUSHED (`origin/main` = `8055a27`).


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-114 close, 2026-08-28 — superseded by the 14z-115 opener above)

> ## **START HERE. NOTHING IS RED. SIX SKILLS EXIST AND ARE LOCKED TO THE
> ## DOCS — load the relevant one BEFORE the work, every session.**
> ##
> ## **WHAT EXISTS NOW (`.claude/skills/<name>/SKILL.md`):**
> ## `mister-cps2-wide-core` (`[MSC-1..73]`, level 1) and `mister-vampire-saved`
> ## (`[MSV-1..36]`) for the FPGA lane; `cps2-hardware` (`[CPH-1..30]`) and
> ## `cps2-emulation` (`[CPE-1..42]`) for the board and the two emulators as
> ## instruments; `vampire-savior-engine` (`[VSE-1..83]`, the game's laws, NO
> ## ROM addresses); `vampire-saved-port` (`[VSP-1..161]`, THIS port's
> ## discipline — CLAUDE.md by citation, the oracle classes, the pipeline law,
> ## freezes/releases/the suite, every rig and how it lied). 425 rules. Each
> ## rule is anchored `**[PFX-N]**` at the doc paragraph it distils and
> ## `tools/checkskills.py` (`tests/test_checkskills.sh`, ci_portable, eight
> ## must-fire controls) locks both directions, lints level 1 for game words,
> ## refuses any number not in a LOG, resolves cross-references, and refuses
> ## a VSP anchor anywhere in STATE.md outside "STANDING PRINCIPLE" / "THE
> ## DEADNESS REGISTER" (the file rolls). Plan and boundaries — now the
> ## record — `docs/project/skills_scope.md`; five decisions OPEN TO VETO in
> ## STATE "Decisions pending".
> ##
> ## **THE ONE RULE THIS ADDS TO EDITING DOCS:** an anchored paragraph carries
> ## its marker — rewrite the fact and keep the marker with it, or move the
> ## rule; delete the paragraph and the gate goes red, on purpose. Four
> ## staleness passes (MiSTer S1-S20 in 14z-113; A+B, C, D in 14z-114) ran
> ## BEFORE distilling, each its own commit; the docs the skills cite are the
> ## corrected ones.
> ##
> ## **NOT PUSHED:** everything after `bb8ecde` (the MiSTer skills) is local —
> ## six commits + the close. Push only at the maintainer's word; check
> ## `git status -sb`, not this line.
> ##
> ## **OPEN, unchanged:** #113 stays OPEN (camera evidence in progress — do
> ## not close, do not re-derive); two D staleness items flagged UNVERIFIED
> ## (skills_scope §4 row D); re-filing candidates for the maintainer
> ## (fourteen emulator-fact entries in `project/gotchas.md`, the 14z-90
> ## onset entry in `game/gotchas.md`); housekeeping deferred
> ## (`build/m3b_merged15` referenced by `test_inp_crash_merged_m8_01` defect
> ## mode; STOCK CONTROL once-per-`.rbf`, unruled; the cosmetic backlog —
> ## DISASSEMBLE, NEVER SCAN).
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17` (M8 mark;
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`); solos `don_m14` /
> ## `hui48` / `pyron32`, stock twin `m5_stock9`; bitstream seed 18269 at
> ## `release/bitstreams/CURRENT`. Strict static at close: 111/0/0/0.


## (HISTORY) NEXT SESSION orientation (written mid-14z-114 after C, 2026-08-28 — superseded by the close opener above)

> ## **START HERE. NOTHING IS RED. THE MiSTer SKILLS EXIST AND ARE LOCKED
> ## TO THE DOCS — load them before any MiSTer work.**
> ##
> ## **WHAT 14z-114 DID, one breath:** a retraction first (the merged-m10
> ## registry row still called the `.rbf` "on the synthesis box"); then the
> ## distillation. **Two skills**: `mister-cps2-wide-core` (level 1,
> ## game-independent, `[MSC-1..73]`, sections 1.1-1.7 + 1.8 "what is NOT
> ## known") and `mister-vampire-saved` (level 2, `[MSV-1..36]`, 2.1-2.5),
> ## one section per `mister_scope.md` row. **The checker shape, decided
> ## before a rule was written: the docs ARE the human rendition.** Each rule
> ## is anchored `**[MSC-N]**` at the paragraph it distils and
> ## `tools/checkskills.py` (`tests/test_checkskills.sh`, ci_portable) locks
> ## it both ways, lints level 1 for game names/ceilings/build dirs, and
> ## refuses any number not present in a LOG. **Its first real run found
> ## that every 14z-108/109 measurement was missing from `platform/mister.md`**
> ## — entered there now — and that skill 2.5 had no live carrier:
> ## `docs/project/mister_field.md` (field test + triage) is new.
> ##
> ## **THE ONE RULE THIS ADDS TO EDITING DOCS:** an anchored paragraph carries
> ## its marker — rewrite the fact and keep the marker with it, or move the
> ## rule; delete the paragraph and the gate goes red, on purpose.
> ##
> ## **SAME SESSION, LATER — THE PLAN FOR THE REST AND PAIR A+B SHIPPED:**
> ## `docs/project/skills_scope.md` plans four more skills (five decisions
> ## under stated assumptions, OPEN TO VETO in STATE); `cps2-hardware`
> ## (`[CPH-1..30]`) and `cps2-emulation` (`[CPE-1..42]`) are distilled and
> ## locked; **then C shipped too**: `vampire-savior-engine` (`[VSE-1..83]`,
> ## no ROM addresses) after the game staleness pass S-C1..S-C12 (the DF
> ## "palette OPEN", the capture-pose "feasible" and win-screen "#105 open"
> ## headers were all years-of-sessions stale; the game gotchas' title line
> ## had an entry spliced into it). **264 rules / 5 skills, `checkskills`
> ## ALL PASS, seven controls. NEXT: D, the port skill `vampire-saved-port`**
> ## — its staleness pass first (`project/gotchas.md` 179 entries with
> ## RESOLVED cross-refs, `hardening_register.md` and `build_dir_triage.md`
> ## dated to the 14z-102/103 sweeps, HANDOFF playtest defaults), then rules
> ## that ANCHOR INTO CLAUDE.md and never restate it (decision 3).
> ##
> ## **OPEN, unchanged:** #113 stays OPEN (camera evidence in progress — do
> ## not close, do not re-derive); housekeeping deferred (`build/m3b_merged15`
> ## referenced by `test_inp_crash_merged_m8_01` defect mode; STOCK CONTROL
> ## re-scoped to once-per-`.rbf`, recommendation unruled; the cosmetic
> ## backlog — DISASSEMBLE, NEVER SCAN). **FUTURE, unscheduled:** the other
> ## skills the maintainer sketched (CPS-II emulation, VS/VS2/VH2) — reuse
> ## this checker pattern; the living-documentation effort.
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17`
> ## (`tools/run_wide.sh build/m3b_merged17 fbneo`); bitstream seed 18269 at
> ## `release/bitstreams/CURRENT`; everything pushed once this session's
> ## commit lands (check `git ls-remote`, not this line).


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-113 close, 2026-08-28)

> ## **START HERE. NOTHING IS RED. EVERYTHING IS PUSHED. THE OPENER IS THE
> ## MiSTer SKILLS — and the reason this is a fresh session is the method:
> ## the skills are distilled from the docs AS THEY NOW READ, not from any
> ## session's memory of them.**
> ##
> ## **WHAT 14z-113 SETTLED, one breath:** the scope document
> ## (`docs/project/mister_scope.md`) and its three rulings; the S1-S20
> ## staleness pass (every MiSTer doc's STATUS line is current — pin
> ## `63496069`, 24 fork patches registered, "hardware: never" retired,
> ## `cps2_wide.md` says RATIFIED); bundle 14z112 field-verified ("no
> ## regression", stock coexists, STOCK CONTROL boots); **merged-m10
> ## FROZEN** (`build/m3b_merged17`, M8 + fingerprint `32007911` unchanged,
> ## packaging only, tag pushed, MiSTer tail empty); **the RELEASE FORMAT
> ## ruled and shipped** — `release/merged-m10/{fbneo,mame,mister}/`, each
> ## self-sufficient, every version releases every platform
> ## (`docs/project/release_format.md`, `tools/package_release_platforms.py`,
> ## `test_release_roundtrip.sh` §4).
> ##
> ## **THE WORK: THE MiSTer SKILLS, per `mister_scope.md` §2-§3** — level 1
> ## CPS-II/WIDE core (1.1 separate-core mechanism, 1.2 the runtime profile
> ## bit, 1.3 SDRAM tiers/slots/placement RULES, 1.4 the format caps + the
> ## nine gated sites, 1.5 the simulation lane + instruments, 1.6
> ## synthesis/release, 1.7 MRA/`.rom` mechanics) and level 2 VS-specific
> ## (2.1 the roster's demand, 2.2 the placement NUMBERS, 2.3 catalogue/
> ## MRA/bundle generation — now `release_format.md`, 2.4 the WIDE oracles,
> ## 2.5 field test + triage). Each row names its sources BY SECTION and its
> ## gates: **read those sections, not this file.** The liftability test
> ## decides every placement: if it names `vsav`, a tenant, `0xEE73`/
> ## `0xFFDB`, a fingerprint or a build dir, it is level 2.
> ## **A SKILL SHIPS WITH ITS CHECKER** (STATE "Decisions pending", the SMS
> ## `checkskills.py` pattern): ID-lock each skill to the doc sections it
> ## distils so the two cannot drift; a skill that quotes a number cites the
> ## LOG (`mister.md` / `mister_map.md` / `mister_fit.md`), never the
> ## synthesis — that is `mister_core.md`'s own staleness rule. Decide the
> ## checker's shape FIRST; it is the design question of the session.
> ## `mister_scope.md` §7 lists the holes a skill must state rather than
> ## hide (pixels and audio never MEASURED, timing a seed lottery, bank 1
> ## on one replay, silicon's decryption window inferred).
> ##
> ## **THE `.rbf` IS IN THE TREE (post-close, same day):** canonical at
> ## `release/bitstreams/18269/` (+ `CURRENT`), hash-verified into every
> ## release's `mister/` by the packager, never copied release-to-release;
> ## `merged-m10/mister/` regenerated from it. A NEW bitstream = a new seed
> ## dir + a `CURRENT` bump, never an overwrite.
> ## **ONE SMALL THING MAY LAND FIRST: #113** — OPEN by the maintainer's
> ## instruction: camera evidence in progress that hardware may DISAGREE
> ## with the emulator finding. Do not close it, do not re-derive the
> ## emulator measurement; if the board shows something the emulators do
> ## not, that is a rendering finding (palette / CPS-B layer register at the
> ## white frame — never measured), not a game-data one.
> ##
> ## **HOUSEKEEPING, deferred:** `build/m3b_merged15` (N-2) still referenced
> ## by `test_inp_crash_merged_m8_01` defect mode — re-point or keep, the
> ## maintainer's call; the STOCK CONTROL MRA kept, re-scoped to
> ## once-per-new-`.rbf` (recommendation, unruled); the cosmetic backlog
> ## (win-quote text for the three tenants, ladder names/pictures, wheel
> ## polish, #112 — DISASSEMBLE, NEVER SCAN) parked as one later pass.
> ##
> ## **STATE OF THE BUILDS:** merged-m10 = `build/m3b_merged17` (play:
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`); the field bundle
> ## `../mister_fieldtest_14z112/` IS this set. `run_all_static --strict`
> ## PASS 110/0/0/0 at close.


## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-112 close, 2026-08-27; updated during 14z-113)

> ## **START HERE. NOTHING IS RED. #99 IS CLOSED. The tree is green
> ## (`run_all_static --strict` PASS 110/0/0) and everything is pushed.**
> ##
> ## **TWO THINGS ARE WAITING ON THE MAINTAINER'S HARDWARE — do not
> ## re-derive them, just read the answer when it comes:**
> ## **(1) #113** — the one-frame white-out at a down is MEASURED VANILLA
> ## (identical on stock `vsavj` AND `vsav2`; gate
> ## `tests/test_down_flash_vanilla.sh`). His MiSTer double-check closes it.
> ## **(2) BUNDLE `../mister_fieldtest_14z112/` — ANSWERED 14z-113
> ## (maintainer, 2026-08-28): NO REGRESSION.** Stock renders correctly on
> ## Jotego's own core from the shared pristine `vsav.zip`, WIDE runs on
> ## ours, the STOCK CONTROL boots too. One-zip packaging is field-proven
> ## and **FROZEN as merged-m10 (14z-113): `build/m3b_merged17`, M8 mark
> ## and fingerprint `32007911` UNCHANGED, tag `freeze/merged-m10`,
> ## `release/merged-m10/` with the first in-tree `mister/` layer (MRAs +
> ## BITSTREAM.txt; the `.rbf` itself is not in the tree yet — the RELEASE
> ## FORMAT is the open item *[HISTORY — both done post-close 14z-113, see the
> ## live opener above]*). Play with
> ## `tools/run_wide.sh build/m3b_merged17 fbneo`.**
> ## **#113 stays OPEN: the maintainer is gathering camera evidence that
> ## original hardware/MiSTer may DISAGREE with the emulation finding —
> ## do not close it, do not re-derive the emulator measurement.**
> ## The STOCK CONTROL's remaining use is the superset invariant ON SILICON
> ## — run it once per new `.rbf`, not per release (STATE "Decisions
> ## pending"). **Next by the maintainer's own sequencing: the S1-S20
> ## staleness pass, then the MiSTer release format, then the skills.**
> ##
> ## **THE MiSTer SCOPE DOCUMENT IS DONE (14z-113):
> ## `docs/project/mister_scope.md`** — the two-level split with each
> ## skill's boundary/sources/gates, the doc dependency map, and the
> ## **known-stale inventory S1-S20** (file:line). All ~5,000 lines were
> ## read; NOTHING was corrected (scope only). **THREE DECISIONS SIT IN
> ## STATE "Decisions pending"**: confirm the split; run the staleness pass
> ## BEFORE the skills (recommended — `mister_core.md` still says "hardware:
> ## never" and `patch_index.md` registers 7 of 24 fork patches); and where
> ## the `.rbf` lives (cited by three docs, tracked by none). The
> ## `mister_mra.sh` HEADER correction 14z-112 asked about IS in place.
> ## **If the pass is approved, it is the next session's work: one commit,
> ## retraction discipline, headers and summary lines first.** Note S20:
> ## every HANDOFF MiSTer example still names `build/m3b_merged13`, which
> ## the 14z-112 sweep DELETED — those commands are non-runnable as written.
> ##
> ## **THE COSMETIC BACKLOG (STATE, parked as ONE later pass):** win-quote
> ## TEXT for ALL THREE tenants (each still shows its SHELL's quote; art is
> ## already native), arcade ladder MAP NAMES + PICTURES, SELECT WHEEL
> ## polish, and **#112** (Press of Death black foot — DECIDED cosmetic).
> ## None is competitive-2P surface.
> ##
> ## **IF YOU TOUCH #112 AGAIN, THE METHOD IS THE FINDING: DISASSEMBLE,
> ## NEVER SCAN.** 14z-112 produced TWO retractions, both from byte scans
> ## matching across instruction boundaries (`e768 7105` in base territory;
> ## `0028394E` = a displacement word plus the next opcode). What IS
> ## measured: the entire draw path is VANILLA down to the writer
> ## instruction `PC 0x01B2BE` (byte-identical to stock), and WHY a tenant
> ## runs that vanilla sequence is UNKNOWN. Do not re-derive the
> ## eliminations — they are listed in STATE 14z-112.
> ##
> ## **STATE OF THE BUILDS:** `build/m3b_merged17` is the repackaged set —
> ## NOT registered, NOT frozen; freezing is a separate decision once the
> ## board confirms. `build/` was swept to 2.9 GB (current + one back per
> ## track). **Before deleting any build dir, grep FOUR places** — `tests/`,
> ## `tools/`, **`build/manifest/`** and `docs/` — excluding comment lines,
> ## and run `--strict` BEFORE committing: a fixture loss shows up as a
> ## gate degrading to SKIP, not as a failure
> ## (`docs/project/build_dir_triage.md`).
> ##
> ## **RECORDINGS ARE INFRASTRUCTURE NOW:** playback stops at the end of
> ## HUMAN input (`-exit_after_playback`, `PLAYBACK <n>` in every log), so
> ## the attract demo can no longer be scored as play. Instruments:
> ## `tools/run_inp_probe.sh` (video hash, HP/death, OBJ counts, snapshots,
> ## OBJ dumps, `GFXRANGE`, `RECT_AUDIT`, `WRITETAP`, `FINDBYTES`),
> ## `tools/run_inp_guarded.sh` (crash capture), `tools/audit_effect_rects.py`
> ## (an INSTRUMENT, not a gate — read its header).



## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-109 CLOSE, 2026-08-26)

> ## **START HERE. THE OPENER IS THE #99 FIX WINDOW — census, remap rule,
> ## the #111 coverage repairs, then the re-freeze. Everything is ruled;
> ## nothing is open except the work.**
> ##
> ## **WHAT HAPPENED IN 14z-109, one breath:** the FIELD TEST PASSED — the
> ## core boots on a real DE10-Nano, tenants selectable and playable,
> ## TENANT VOICES PLAY ("fetched is not heard" is retired), select screen
> ## emulator-identical, feel better than emulator — with ONE
> ## 100%-reproducible crash, which was ROOT-CAUSED the same day: **#99 =
> ## vs2 type byte `0x51` at node `ROM 0x3FB899` inside DONOVAN'S ported
> ## block**, walked by Donovan's OPPONENT (any — Phobos AND Bishamon both
> ## crashed it in the field), indexing past vsavj's 80-entry FSM jump
> ## table at `PRG:0x018510` -> word `0x0001` -> odd jump -> vec3 -> the
> ## game's own exception handler soft-boots to the NAME SCREEN. Every
> ## field observation is downstream of this. Full trail: STATE 14z-109
> ## (3)-(8); mechanism docs: engine_internals "CPU exceptions" + "The
> ## object-script state dispatcher"; GitHub #99 is current.
> ##
> ## **THE RULING IS TAKEN (maintainer, 2026-08-26) — (a)+(b)+(c):**
> ## (a) fix shape A: DATA-SIDE EXTRACTION REMAP — the dispatcher (vanilla
> ## code on the legacy path) is NEVER patched. (b) `0x51 -> 0x19`:
> ## vs2's `0x51` aliases vs2's DEFAULT handler (`move.b (0x17,a3),
> ## (0x54,a1); rts`) and vsavj's default at table offset `0x17C` (handler
> ## `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
> ## BYTE-IDENTICAL — the remap is instruction-level exact, zero gameplay
> ## surface. (c) THE CENSUS with the ESCALATION CLAUSE: scan ALL THREE
> ## tenants' node streams (0x18-byte nodes, next-state byte at +0x17) for
> ## values `>= 0x28`; default-alias hits auto-remap by the same
> ## handler-equivalence proof; **anything else returns to the maintainer
> ## as its own decision.**
> ## **THE STANDING CAVEAT ON ESCALATED HITS (maintainer's own
> ## instruction, also a persistent memory):** "port the handler" LOOKS
> ## best but is NOT FREE — memory, cycles, side-effects. Order: measure
> ## what the state DOES and how often content reaches it -> consider
> ## neutralize-to-default -> port ONLY if feel demonstrably needs it.
> ## **Raise this point if the maintainer seems too eager to approve a
> ## port.**
> ##
> ## **HOW THE FIX LANDS (the mechanism already exists):** the extraction's
> ## `data_port` rows carry a `fixes = "off:old:new"` field — the #92 stage
> ## bytes shipped exactly this way (`voice_borrow_voicenums_b`,
> ## patch_notes 14z-94). The census names the offsets; the remap becomes
> ## `fixes` entries (or a dedicated family-aware rule if the hits are
> ## many) on the ops that port each tenant's block. **The census must be
> ## FAMILY-AWARE — walk the node streams the way the FSM does; a blanket
> ## byte replace would corrupt nodes whose +0x17 is not a state.** Anchor
> ## facts for the walker: our node `0x3FB882` = vs2 `0x0C9CAA` (verbatim,
> ## unique content hit); Donovan base `0x3FA9D0`; the vs2 FSM table is
> ## `0x016D34` (0x54=84 entries), ours `0x018510` (80 entries; valid
> ## 0x00-0x4F — vs2's 84 make 0x50-0x53 the renumber gap). CORRECTED
> ## 14z-110: was "~0x28".
> ##
> ## **#111 LANDS IN THE SAME WINDOW:** re-point `26_don_arcade_mash`'s
> ## navigation (U,U,R lands on JEDAH on the 21-cell wheel; L,L,D,D
> ## reaches Donovan — measured), re-measure `audit_continue_switch.sh`'s
> ## trajectory per its own header, and ADD the missing gate: Donovan vs
> ## CPU-Phobos (and ideally each tenant vs each tenant CPU). **The venue
> ## byte `$FF8121` makes that DETERMINISTIC: the draw pool is
> ## `row[venue..venue+7]` (measured 12/12) — venue `0x02` = Phobos first
> ## on his paired stage, venue `0x10` = Bishamon-then-Phobos, the two
> ## field contexts.** A 2P replay exists too: `109_2p_don_vs_phobos.rpl`
> ## (P2 scripting landed this session — fork `4dfc3734`, bits 12+,
> ## frozen sha1s provably unmoved).
> ##
> ## **THEN THE RE-FREEZE (donovan-m12 / huitzil-m21 / pyron-m15 /
> ## merged-m7), and its MiSTer TAIL:** a romset rebuild moves CRCs ->
> ## `tools/gen_vsavjw_xml.py --check` goes red -> the fork's catalogue
> ## entry needs a NEW COMMIT and the MRA/bundle for the board must be
> ## REGENERATED (`../mister_fieldtest_14z108/` becomes stale the moment
> ## the freeze lands). Budget it; the field crash is the whole reason for
> ## the window, so the maintainer will want the new bundle on the SD card.
> ##
> ## **CRASH-TRIAGE KIT, if anything else ever "flaky-resets":**
> ## name-screen reboot = CPU exception (code at `$FF0000`, regs at
> ## `$FF0018-53` — but ONLY if the handler runs; under the guard read
> ## regs via `GUARD_PROBE`, the RAM block stays stale); gold full test =
> ## cold/watchdog. Method: deterministic lab rat -> vector+ADDR ->
> ## `GUARD_PROBE_HIST` -> conditional register probe (PROBE prints
> ## A1/A3 since 14z-109). Three guarded runs took #99 from "flaky" to a
> ## named byte.
> ##
> ## **ALSO NEW THIS SESSION, so it is not re-derived:** the OBJ-LIST
> ## ORACLE — first cross-implementation video-determining agreement
> ## (promoted subset field-identical at match anchor AND select screen;
> ## M6 mark identical; `test_mister_obj_oracle.sh` + `test_obj_records.sh`,
> ## HANDOFF rows); the DECISIONS CLEANUP — resolved rulings live in
> ## `DECISIONS_HISTORY.md` (topic-greppable, retraction grep covers it),
> ## STATE keeps only live items; the repo-root dump litter moved to
> ## `../dumps/` (README inside; all regenerable).
> ##
> ## **PUSH STATE: everything is pushed** — `origin/main` current at the
> ## close commit, fork at `4dfc3734` (20 commits, public). Check
> ## `git ls-remote`, not prose. **Scratch:** the jtsim clone
> ## `/tmp/vampire-saved-jtsim-14z108` was SWEPT at this close (field test
> ## reported; rebuild is one `setup` command); `../mister_fieldtest_14z108/`
> ## is DURABLE but goes STALE at the re-freeze; `../dumps/` is the
> ## maintainer's, safe to delete wholesale per its README.



## (HISTORY) NEXT SESSION orientation (rewritten at the 14z-108 CLOSE, 2026-08-25)

> ## **THE OPENER IS THE FIELD TEST, AND IT IS THE MAINTAINER'S.**
> ## Simulation is EXHAUSTED for this arc. A tenant fights on the core and
> ## fights CORRECTLY against MAME; the QSound extension is fetched; bank 1
> ## under load is GO; scroll is structurally cleared; the core fits a
> ## Cyclone V. **Nothing further in Verilator moves the arc** — the three
> ## things still never done all need hardware or a different surface:
> ## PIXELS compared, a tenant's voice HEARD, and anything at all on real
> ## silicon.
> ## **THE BUNDLE IS BUILT AND VERIFIED**: `../mister_fieldtest_14z108/`
> ## (outside the repo, rule 7) — the WIDE MRA, `vsavjw.zip`, the PATCHED
> ## `vsav.zip`, `qsound.zip`, and a README. All 31 CRC-identified parts
> ## were checked to resolve, because an unresolved part is filled with
> ## `0xFF` rather than refused.
> ## **THE `.rbf` IS NOT IN IT** — it comes from the Windows box, and its
> ## sha256 must be checked first (`46fc74af…`, seed 18269): **a
> ## timing-FAILING seed emits a bitstream indistinguishable from a good
> ## one**, and 4 of 12 seeds fail.
> ## **AND THE BUNDLED `vsav.zip` IS PATCHED** — four members carry the
> ## ported art, everything resolves by CRC, so a stock CPS-2 MRA pointed
> ## at it gets wrong art SILENTLY. Back up the pristine copy first.
> ##
> ## **WHAT THE FIELD TEST ANSWERS THAT NOTHING HERE CAN:** whether a
> ## tenant's VOICE PLAYS (we have proved those samples are FETCHED out of
> ## DSP bank `0x83`; "heard" is not reachable from simulation), whether
> ## the picture is right (no frame has ever been compared and VRAM turned
> ## out to be a dead end for that — see below), and whether any of it
> ## survives real SDRAM, real timing and the analog chain.
> ## **IF IT DOES NOT BOOT, report the failure MODE** — black screen vs
> ## RAM-test pattern vs a boot loop and its period. A ~1,580-frame loop is
> ## what the pre-D5 decryption bug looked like (**= about 26.5 s at the
> ## real 59.6374 Hz — a stopwatch is a valid instrument for this**).
> ##
> ## **UPDATED 14z-109: THE BUNDLE NOW CARRIES A NEGATIVE CONTROL AND A
> ## TRIAGE CARD.** The field test was about to be run WITHOUT a control,
> ## which by this project's own standard is not a measurement.
> ## `_Arcade/Vampire Savior (Japan 970519) [STOCK CONTROL].mra` runs stock
> ## `vsavj` on the SAME `.rbf` with the profile bit left at the `0xFF`
> ## fill, so **"does STOCK boot?"** separates a fault in our profile from
> ## one in the bitstream, the card, the SDRAM module or the video chain.
> ## `games/mame/vsavj.zip` added (1.5 MB); the control ALSO needs the
> ## maintainer's PRISTINE `vsav.zip` in place of the bundled patched one.
> ## **MEASURED, not assumed: against the bundle as shipped that MRA loses
> ## 8 of its 22 parts** — the four patched art members AND four program
> ## members — and unresolved parts are `0xFF`-filled rather than refused,
> ## so it would "run" and show nonsense. Both configurations were then
> ## checked part-by-part: **WIDE 31/31 resolve, STOCK 22/22 after the
> ## swap.** New `tools/check_mra_parts.py` + gate `tests/test_mra_parts.sh`
> ## (ci_portable, verdict logic ground-truthed with three refusals).
> ## `FIELD_TRIAGE.txt` is the symptom -> meaning -> next-action card.
> ## **AND THE BUNDLE README'S ITEM 5 WAS STALE AND IS FIXED** — it still
> ## called the identical 128 KB "scroll tilemap", still said the
> ## layer-enable registers were undocumented, and still invited the
> ## maintainer to treat a wrong-looking background as "the first hard
> ## evidence either way". All three were corrected LATER in 14z-108 than
> ## the README was written. **The bundle lives OUTSIDE the repo, so the
> ## retraction-discipline grep over `docs tests` could never have found
> ## it** — when a claim is corrected, the sweep has to cover artifacts
> ## that have already left the tree.
> ##

> ## **14z-109 (2): THE SELECT SCREEN CONFIRMS THE PROMOTE-BIT SPLIT IS
> ## THE RIGHT CUT, NOT A CONVENIENCE.** At select NO CPU OPPONENT HAS BEEN
> ## DRAWN, so the lottery that limits the match-anchor comparison is
> ## ABSENT — which makes it an independent test of the split itself.
> ## **Measured over 81 core frames vs 111 MAME frames, both NON-CONSTANT
> ## (21 and 31 distinct lists, so agreement is not cheap):**
> ## **the PROMOTED subset has an exact MAME twin on ALL 81 frames (100%),
> ## with 67-72 promoted entries — more than twice the match anchor's 31.**
> ## The WHOLE list matches on 55 of 81 (68%), **and every shortfall is in
> ## the UNPROMOTED (vanilla) part** — so our content agrees everywhere and
> ## the vanilla remainder carries some phase noise. **THAT REMAINDER IS AN
> ## OPEN QUESTION, NOT A DEFECT CLAIM: it is not the lottery (no opponent
> ## exists here), most likely a sub-frame sampling phase, and it has not
> ## been root-caused.** It is REPORTED, never asserted.
> ## **AND THE AUTHORED "M6" VERSION MARK IS IDENTICAL ACROSS
> ## IMPLEMENTATIONS** — codes `fe40`/`fe41` (the authored glyph tiles),
> ## palette row 0x19, same coordinates on both. The naked-eye A/B tell is
> ## now a MEASURED agreement rather than a picture.
> ## Gate: `tests/test_mister_obj_oracle.sh` section 3
> ## (`--select-sim-dir/--select-mame-log`), helper
> ## `tools/obj_select_compare.py`. Its 3z check FAILS if the select list
> ## is constant — a static screen would make agreement meaningless.
> ##

> ## **14z-109: A VIDEO-DETERMINING SURFACE FINALLY AGREES ACROSS
> ## IMPLEMENTATIONS — THE OBJ LIST.** 14z-108 ruled VRAM out as an oracle
> ## (two implementations legitimately differ there, the palette by HALF,
> ## and the legacy control reproduced it on stock `vsavj`) and named three
> ## candidate successors. The OBJ list is one of them; it was tried and it
> ## WORKS, because it is what the 68k BUILDS rather than something each
> ## implementation stages its own way.
> ## **THE RESULT, at the frozen tenant anchor (MAME 2886 / sim 3546):
> ## the PROMOTED subset is 31 entries on BOTH legs, ORDERED AND
> ## FIELD-FOR-FIELD IDENTICAL, and the 19-bit tile addresses slice D3
> ## computes are the SAME SET, `0x4b0c4-0x4ecda`.** The promote, the
> ## group-C redirect and the 3-bit bank are now confirmed against an
> ## unrelated codebase at the sprite-list level. **STILL NOT PIXELS** —
> ## this is the LIST, not the rendered frame.
> ## **THE TRAP THAT NEARLY PRODUCED A FALSE FINDING, and it is worth more
> ## than the result:** the raw lists do NOT match — 40 entries vs 129 —
> ## and the first reading of that was "the core draws a third of the
> ## sprites". **WRONG. A 1P replay's CPU opponent is the SOUND-STATE-FED
> ## LOTTERY** (`atlas/ram.md:99`; `test_mister_tenant_oracle` already
> ## excludes the P2 fields BY NAME for this reason), so the two legs fight
> ## DIFFERENT opponents and most of the list is their sprites. **An OBJ
> ## list cannot be filtered "by P2" the way a field table can — sprites
> ## carry no owner.** What rescues it is that OUR content IS labelled:
> ## y bit 12, the CPS-2 Turbo promote, is set on exactly the group-C
> ## sprites this port adds and on nothing vanilla can emit. Compare that
> ## subset and it is exact; the remainder is REPORTED, never asserted.
> ## **A LEGACY CONTROL WAS RUN AND IS ALSO CONFOUNDED** — `05_timeout_idle`
> ## is a 1P arcade replay, so it draws different opponents too (counts
> ## agree 52/57 vs 61, codes barely overlap). **Do not read that run as
> ## evidence either way; the lottery is in both.** A clean whole-list
> ## comparison needs a PINNED OPPONENT, which needs P2 scripting in
> ## `SimInputs` — still the deferred COVERAGE item.
> ## **Instruments: `tools/oram_obj_records.py` (calibrated byte-for-byte,
> ## 1153/1153 lines, against `tests/lua/obj_records_dump.lua` BEFORE any
> ## core data was read), gates `tests/test_obj_records.sh` (~2 min, MAME
> ## only) and `tests/test_mister_obj_oracle.sh` (~65 min, `--sim-dir/
> ## --mame-log` re-analyses finished runs).**
> ##

> ## **START HERE. THE ARC IS MiSTer. A TENANT HAS FOUGHT ON THE CORE,
> ## AND THE CORE FITS A CYCLONE V — BUT DOES NOT RELIABLY CLOSE TIMING.**
> ## Download -> boot -> select -> the extended wheel -> a tenant picked ->
> ## a tenant FIGHTING, with its fighter art coming out of SDRAM. Six RTL
> ## slices (D0-D5), the stock legs green, every control firing — and as of
> ## 14z-108 it SYNTHESISES and FITS, at +206 ALMs — but TWO SEEDS IN FOUR
> ## MISS TIMING, and the flow's own retry-until-pass hid that.
> ## **WHAT HAS NEVER HAPPENED IS HARDWARE.** No `.rbf` has been loaded
> ## onto a DE10-Nano, no MRA has run on real silicon, no analog output
> ## has been seen. Read those two halves together: the design is proven
> ## CORRECT in simulation and BUILDABLE on the toolchain, and it has
> ## never been switched on.
> ##
> ## **QUARTUS IS DONE — 14z-108. FIT: YES. TIMING: NOT RELIABLY.**
> ## Cyclone V 5CSEBA6U23I7, Quartus 20.1.1 Lite via `jotego/jtcore20x`,
> ## pin `7b9a0d2d`, **`cps2` built FIRST as the reference leg**.
> ## **FIT IS UNAMBIGUOUS AND GOOD:** +206 ALMs (+1.1%, 44% of 41,910),
> ## +2,048 memory bits, RAM blocks / DSPs / PLLs UNCHANGED, nothing near
> ## overflow. That half is settled.
> ## **TIMING IS A SEED LOTTERY, MEASURED AT n=12.**
> ##   `cps2w` (12): -0.545 -0.313 -0.110 -0.039 | 0.008 0.009 0.066
> ##                 0.067 0.147 0.167 0.202 0.396   -> 4 FAIL, med +0.038
> ##   `cps2`  ( 5):                 0.144 0.287 0.431 0.511 0.665
> ##                                                  -> 0 FAIL, med +0.431
> ## **The BEST of twelve `cps2w` seeds is worse than the MEDIAN of five
> ## `cps2` seeds; `cps2`'s WORST beats EIGHT of twelve.** Two `cps2w`
> ## passes are +0.008 and +0.009 — a quarter of the passing placements
> ## clear by under 10 PICOSECONDS. Failure rate 4/12, 95% CI ~14-61%:
> ## say "commonly", not "a third". FAILs are jtframe's OWN gate on runs
> ## Quartus called "successful, 0 errors".
> ## **`xjtcore.sh` CALLS `jtseed 4`, WHICH RETRIES AND BREAKS ON FIRST
> ## SUCCESS — AND BE PRECISE ABOUT WHAT THAT HIDES.** It does NOT ship
> ## failing bitstreams (~99% of invocations produce a passing `.rbf`).
> ## **It hides FRAGILITY: the artifact is a CHERRY-PICKED PLACEMENT.** A
> ## green run certifies "one placement was found that closes", never
> ## "this design closes with margin" — and only the second is a basis
> ## for building on.
> ## **WHERE IT IS MARGINAL:** every failing path is inside
> ## `jtframe_sdram64`, terminating at an SDRAM address pin, and the
> ## worst path RESHUFFLES between seeds (different source register AND
> ## destination pin each time). So it is not one slow path but the SDRAM
> ## controller's ADDRESS-GENERATION CONE AS A WHOLE — shared jtframe
> ## infrastructure the fork does not touch. **NOT WIDE's own logic**;
> ## WIDE loads that cone enough to lose the lottery, the control keeps
> ## enough margin to absorb the same variance.
> ## **WHAT IT DOES AND DOES NOT BLOCK.** It does NOT block shipping by
> ## itself — we distribute a PREBUILT `.rbf` and the baseline is a
> ## passing draw. It DOES mean +0.066 is not real headroom: a future
> ## slice cannot assume it, any rebuild is a lottery, and a jtframe
> ## uprev or Quartus version change could move it to mostly-failing.
> ## **Spending margin back (pipelining the SDRAM address path, reducing
> ## WIDE's load on that cone) is a DESIGN decision under Rule 1 v2 and
> ## is the MAINTAINER'S — not something to fix by seed-hunting.**
> ## **A FAILING SEED STILL EMITS AN `.rbf`**, indistinguishable from a
> ## good one by inspection — same size class, same filename, same
> ## published path. A sweep overwrote `release/mister/jtcps2w.rbf` with
> ## the WORST failing seed before it was restored. **VERIFY BEFORE
> ## FLASHING.** The shipping baseline is sha256 `46fc74af…`, **SEED
> ## 18269**, slack +0.066, gate PASS — jtseed's own random draw and the
> ## +0.066 row of the n=12 table, i.e. a passing draw from the
> ## distribution in which a third fail, NOT a privileged build.
> ## Rebuild it with `jtcore cps2w -mister --nodbg --seed 18269`, NOT
> ## with `xjtcore.sh` (which re-draws at random).
> ## **AND THE HASH WILL NOT MATCH ON A DIFFERENT DAY:** `build_id.tcl`
> ## compiles a `%y%m%d` datestamp in (`260825` here), so the same seed
> ## reproduces the PLACEMENT and TIMING exactly and a different
> ## bitstream. **The hash identifies the ARTIFACT, the seed identifies
> ## the RESULT** — never read a hash mismatch as a failed reproduction.
> ##
> ## **THE OPENER IS NOW HARDWARE — AND IT IS THE MAINTAINER'S, NOT
> ## MINE.** Synthesis settles BUILDABILITY and nothing else: no `.rbf`
> ## has been loaded onto a DE10-Nano, no MRA has run on real silicon, no
> ## analog output has been seen. That is a field test (`mister_core.md`
> ## §1: MiSTer + 128 MB module + Jammix -> CRT at native timing) and it
> ## needs the maintainer at the board. **Before it: MiSTer PACKAGING is
> ## still unanswered** — which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours (STATE "Decisions
> ## pending"). Both must be settled before anything ships.
> ##
> ## **THE §4 TENANT ORACLE IS DONE — 14z-108, AND IT AGREES.** A tenant
> ## does not merely fetch art on the core, it FIGHTS CORRECTLY: MAME
> ## anchor 2886, sim 3546, skew 660 (= the 659-frame transfer PLUS ONE,
> ## the same +1 the legacy replay shows on a 462-frame transfer, so the
> ## boot offset is a CONSTANT). **`p1_hitbox_base` is `0x003FA9D0` on
> ## BOTH legs** — the core loaded the tenant's RELOCATED character record
> ## from above `CPU:$400000`. HP, white HP, timer, position, meter,
> ## `ptr64` and `word132` all agree; the only disagreement is
> ## `p2_hitbox_base`, the sound-fed CPU draw, excluded by name for a
> ## measured reason and proven LIVE by a control. Gate:
> ## `tests/test_mister_tenant_oracle.sh` (emulator, ~65 min).
> ##
> ## **THE QSOUND EXTENSION IS FETCHED — 14z-108.** 210,180 reads over 76
> ## distinct blocks in the 1 MB HIGH window, DSP bank `0x83`, first at
> ## frame 3783 (inside the match, during the mash); control leg ZERO
> ## while still issuing 54 M QSound LOW reads. Confirms D1's width fix
> ## and D2's split end to end, and that the `SLOT5_AW=20` mask is
> ## lossless in practice. Gate: `tests/test_mister_qsound_ext.sh`.
> ## **FETCHED IS NOT HEARD** — no audio has been rendered or compared,
> ## and nothing in this lane ever has.
> ##
> ## **BOTH REMAINING SIMULATION ITEMS WERE ADVANCED 14z-108.**
> ## **SCROLL — structurally cleared.** Every scroll-path line in
> ## `cps2w`'s `jtcps1_sdram.v` override (`SCR_OFFSET = 0`, `rom1_cs`,
> ## `rom1_addr[19:0]`, `gfx1_addr`, the `slot1_*` bindings) is
> ## byte-identical to the shared `cores/cps1` original, and the scroll
> ## slot still sits in `u_bank2`/`u_bank3` in BOTH. The only slot1 the
> ## fork adds anywhere is `gfxc4_cs` on `u_bank1` — a different bank.
> ## **D2 cannot have moved scroll, by construction.** Rendering is still
> ## untested.
> ## **VIDEO — the first cross-implementation comparison of a
> ## video-determining surface, and it ended as a DEAD END worth
> ## knowing about.** Pixels need infrastructure neither side has, but
> ## VRAM `$900000-$93FFFF` is dumpable on both — by address on MAME, and
> ## on the core because D2 maps it to bank 0 byte `0x600000`. Compared
> ## at the frozen anchors, then RE-CUT along the real layer map once the
> ## video registers were documented. **(An intermediate reading called
> ## the identical `$910000-$92FFFF` "scroll tilemap" — that was WRONG:
> ## no layer base points there, it is UNCLAIMED VRAM.)**
> ##
> ## **THE VIDEO REGISTERS ARE NOW DOCUMENTED** (`atlas/ram.md`, "CPS-2
> ## VIDEO REGISTERS"): CPS-A at `$804100` is **WRITE-ONLY** so it needs
> ## the emulator's `cps_a_regs` SHARE, not a bus dump; CPS-B layer
> ## control is `+26`; every CPS-2 game shares one config. At the match
> ## anchor: scroll1 `$900000`, scroll3 `$904000`, scroll2 `$908000`,
> ## palette `$90C000`, **layer_control `0x2d0e` = ALL THREE SCROLL
> ## LAYERS ENABLED.**
> ## **RE-CUT ALONG THAT MAP, the diff reads: scroll1 22.3%, scroll3
> ## 2.9%, scroll2 17.7%, PALETTE 52.7% — and row-scroll plus every
> ## UNCLAIMED region (204,800 bytes, not zero) BYTE-IDENTICAL.** An
> ## earlier reading calling the identical 128 KB "scroll tilemap" was
> ## WRONG: no layer base points there.
> ##
> ## **THE LEGACY CONTROL WAS RUN AND IT SETTLES IT: THE DIFFERENCE IS
> ## NOT OURS.** Same core, same region, but STOCK `vsavj` and the legacy
> ## replay `05_timeout_idle` — scroll1 35.4%, scroll3 3.8%, scroll2
> ## 15.1%, palette 51.2%, row-scroll and unclaimed 0%. **Same pattern,
> ## same magnitudes, on vanilla content with the roster nowhere in
> ## sight.** A general MAME-vs-jtcps2 implementation difference; it says
> ## nothing about the profile, the roster or any slice.
> ## **THE USEFUL NEGATIVE RESULT — DO NOT REPEAT THIS APPROACH: VRAM IS
> ## NOT A VIABLE CROSS-IMPLEMENTATION VIDEO ORACLE.** Two unrelated
> ## implementations legitimately hold different bytes in the palette and
> ## all three scroll tilemaps (the palette by HALF), so that surface can
> ## never separate "our port broke something" from "these are different
> ## implementations". **A future video oracle needs a DIFFERENT surface:
> ## rendered frames, the OBJ list, or the palette AFTER the hardware's
> ## own conversion.** Row-scroll and every unclaimed region are
> ## byte-identical in BOTH runs (204,800 non-zero bytes, two romsets, two
> ## replays), so the transfer and dump paths are sound.
> ## **PIXELS remain never compared — and the cheapest route to that is
> ## now the FIELD TEST, where you simply look at the screen.**
> ##
> ## **THE SEED SWEEP IS DONE and is what produced the finding above.**
> ## It was commissioned because the attribution showed a five-path
> ## cluster at the limit on a term that is ROUTING. That reasoning was
> ## right and a single build would never have shown it. **More seeds are
> ## cheap (~12 min each) if the failing fraction is ever worth pinning
> ## down properly; with n=4 no pass RATE is quoted.**
> ##
> ## **QUEUED, ONE FORK COMMIT: `cores/cps2w/README.md` IS STALE.** It
> ## still says "Status: slice D1" and calls D2-D4 "not here yet", with a
> ## file table of FIVE `hdl/` files against the tree's THIRTEEN — written
> ## at `4840df8a` and never updated after `0df6f000`. Found by the
> ## Quartus session, which stopped and asked before building. Not fixed
> ## during 14z-108 because a README commit moves the pin out from under
> ## a build in flight; do it once the synthesis numbers land.
> ##
> ## **WHAT 14z-108 MEASURED, so it is not re-measured.**
> ## **(1) THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END**,
> ## not transposed in two. Measured on ALL FOUR against the game's own P1
> ## mirror `RAM:$FF8058.w` (`tests/replays/107_four_directions.rpl`,
> ## attract-only on STOCK `vsavj`, MAME vs `cps2w`, both dump sets
> ## integrity-checked): Up arrived as Right, Down as Left, Left as Down,
> ## Right as Up. 14z-107 (12) had two data points and inferred a two-bit
> ## SWAP leaving Up and Right untouched — **that was wrong, and a two-bit
> ## fix would have left half the defect in the tree.** Mechanism:
> ## `test.cpp:380` copies file bits 4-7 straight onto `joystick1[3:0]`
> ## and jtframe's port is MSB-FIRST (`jtframe_keyboard.v:107-110`), so
> ## the file map is `bit4=Right bit5=Left bit6=Down bit7=Up`. Fault is
> ## OURS, not jtframe's — one dict in `tools/rpl2siminputs.py`, no fork
> ## commit, no RTL. **The fork pin is unchanged at `7b9a0d2d`.**
> ## **(2) A TENANT FIGHTING.** `test_mister_gfxc_fetch --rpl
> ## 36_pick_tenant_cell --frames 4400` PASSES in full: obj bank 4
> ## **9,388,928 reads / 1,735 distinct codes `0xAD8F-0xEE42`**, 843
> ## traffic frames after match start; obj bank 5 206 codes; both inside
> ## their frozen extents; the control leg (header byte 41 `0xFE`->`0xFF`)
> ## at ZERO on both windows while still reading 105 M in bank 3.
> ## **(3) BANK 1 UNDER LOAD: GO.** Same run, `--stats`: ba1 peaks at
> ## 15,496 acc/frame (**12.5%** of ceiling) with the fighter art sharing
> ## the bank with QSound, and **ZERO `SDRAM reads clashed` in 3,738
> ## frames**. ba0 peaks 54,363 (43.9%), unchanged from stock.
> ##
> ## **THE ANCHOR DID NOT MOVE, AND THAT WAS PROVEN RATHER THAN ASSUMED.**
> ## `test_rpl2siminputs` freezes two values and the record said a bit-map
> ## fix moved BOTH. **It moved one.** `05_timeout_idle` scripts NO
> ## direction token, so its sha1 `eb3e1d04…` cannot change — and since
> ## that is `test_mister_sim_anchor`'s replay, its `sim_inputs.hex` is
> ## byte-identical across the fix and the frozen anchor (MAME 2146 / sim
> ## 2609 / skew 463) **could not move**. The 45-minute gate was NOT
> ## re-run, and the gate header states that as the reason. Corrected in
> ## five documents.
> ##
> ## **STANDING WARNINGS. ALL PAID FOR AGAIN THIS SESSION.**
> ## **(1) SUSPECT THE INSTRUMENT BEFORE THE RTL** — the count is now
> ## EIGHT, and 14z-108 added four more caught BEFORE use, all in one new
> ## analysis block: cumulative counters read as per-interval; a
> ## picosecond timestamp read as an index; a clash counter matching this
> ## report's OWN PROSE about clashes; and a "peak" that was the ROM
> ## DOWNLOAD on all four banks at once. A fifth — a `05`-independence
> ## check that PASSED because gawk's `and()`/`strtonum()` do not exist on
> ## BWK awk, so awk exited 2 and the `else` arm read as success — was
> ## caught only by writing its positive control first. **THE INSTRUMENT
> ## PROTOCOL (`docs/project/gotchas.md`) IS THE MOST LOAD-BEARING
> ## DOCUMENT IN THIS LANE.**
> ## **(2) NEVER EDIT A SCRIPT WHILE A RUN IS IN FLIGHT** — `sh` reads by
> ## byte offset. `tests/` and `tools/` were frozen for the whole 2.5-hour
> ## tenant run and all edits were made before it launched.
> ## **(3) CONFIRM THE RIG ON MAME BEFORE PAYING FOR THE SIM.**
> ## `36_pick_tenant_cell` was verified to reach P1 `+0x382 = 0x13` under
> ## MAME (a ~2-minute run) BEFORE the 2.5-hour simulation, so a zero from
> ## the sim would have been a finding about the CORE rather than about
> ## the replay.
> ##
> ## **AFTER QUARTUS, IN ORDER.** The QSound extension has never been
> ## heard; the scroll path with a wide GFX map is untouched; no frame has
> ## ever been compared programmatically against MAME's (the two committed
> ## select-screen images are a naked-eye pair, not a verdict);
> ## `mister_core.md` §12 is the honest ledger of all of it. **And the
> ## placement's margins remain thin: 0.125 MB of slack in 64 MB, SDRAM
> ## bank 1 EXACTLY FULL, and the group-C ROMSET REGION cannot grow at
> ## all** — tenant art may grow freely inside the existing 16 MB, but a
> ## fifth group-C member has nowhere to go.
> ##
> ## **STILL OPEN FOR THE MAINTAINER: MiSTer PACKAGING** — which MRA is
> ## the core's MAIN one, and how a release carries both `vsav.zip`
> ## flavours (STATE "Decisions pending"). Both must be answered before a
> ## release; nothing above blocks on them. **FUTURE, UNSCHEDULED:** the
> ## LIVING-DOCUMENTATION effort and DISTILLING AI SKILLS from the
> ## project's learnings. Both follow MiSTer.
> ##
> ## **THE GAME SIDE IS PARKED AND GREEN.** 14z-105 frozen as donovan-m11
> ## / huitzil-m20 / pyron-m14 / merged-m6, field-confirmed and pushed
> ## 2026-08-22; play with `tools/run_wide.sh build/m3b_merged13 fbneo`.
> ## Release packaging is done (`release/merged-m6/`).
> ##
> ## **THE LANE, IN TWO COMMANDS** (`HANDOFF.md` "MiSTer" has the rest;
> ## `export JTSIM_SCRATCH=/tmp/vampire-saved-jtsim`, NEVER inside the
> ## repo; ~1 s per simulated frame; the WIDE transfer is **659** frames
> ## and the stock one 462, so every absolute frame moves by 197; and
> ## `--wram` dumps an SDRAM address — `RAM:$FF0000` is bank 0 byte
> ## `0x600000` on `cps2`, **`0x648000` on `cps2w`**):
> ## `tools/run_sim_jtcps2.sh <rpl> <outdir> --frames N --wram A B` and
> ## `tools/mister_mra.sh --core cps2w --wide build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THE FORK: `DefinitelyFrenchName/jtcores@vampire-saved`, remote at
> ## `c97e3d14`, NINETEEN commits, PUBLIC AND CURRENT** — the 14z-109
> ## README update is pushed (maintainer-authorised 2026-08-26, with the
> ## note that the README and the rest of this test build can be
> ## removed or updated later if needed). Fork pushes are
> ## standing-authorised.
> ## **THE MAIN REPO: `origin/main` holds `10cf9ce` and NOTHING IS LOCAL**
> ## — re-checked with `git ls-remote` at the 14z-109 push, not read off a
> ## tracking ref. **The "one commit held back / push the fork first"
> ## situation earlier in 14z-109 is RESOLVED and no longer applies**: the
> ## fork went up first, then the pin bump, in that order, and the
> ## stranded state is gone.
> ## The 14z-107 close recorded "the main repo is NEVER pushed", which was
> ## true WHEN WRITTEN and has since been false three times. Do not repeat
> ## a push figure from prose — **CHECK `git ls-remote`**: a tracking ref
> ## is a claim about the last fetch, and prose is a claim about the day it
> ## was written. This paragraph is prose too.


> ## **SLICE LOG — 14z-107 (11)+(12): THE BOOT FAILURE ROOT-CAUSED AND
> ## FIXED (D5), THE FIRST TENANT TILE EVER FETCHED, BANK 0 ANSWERED, AND
> ## THE FIGHTER HALF BLOCKED BY THE HARNESS.**
> ## **D3 — the CPS-2 Turbo object promote** (fork `b9899fa8`),
> ## `cores/cps2w/hdl/jtcps2w_obj_bank.v`:
> ## `assign bank = { wide_en & table_y[12], table_y[14:13] };` read in the
> ## ELSE arm of the sprite-list terminator test, which is the reference
> ## core's VERBATIM (the ORDER is the rule: `table_y[15]` IS the
> ## terminator). `rom0_bank[2]` UNTIED, the bank three bits wide at every
> ## port from the frame table to SDRAM — which cost FOUR override files,
> ## three of them nothing but a width. **Swept over its whole input
> ## space:** 131,072 vectors, bank[2] set 32,768 times wide / **0** stock,
> ## the six `gfx_tiles.py` encodings each decoding to their own bank, none
> ## of them setting y bit 15. Two must-fire controls fire.
> ## **D4 — the 6 MB program window** (fork `dd242a65`):
> ## `wide_en & RnW & (A[23:21]==3'b010)`,
> ## `rom_addr`/`main_rom_addr`/`SLOT3_AW` 21->22, and the `one_wait`
> ## boundary `wide_en ? 4'h6 : 4'h5`. **It shipped WITH D3 because D3
> ## cannot be demonstrated without it:** the select screen's roster record
> ## is allocated in `wide_ext` above `CPU:$400000`, so a 4 MB decode
> ## cannot read the table that names the tenant cells and the promote has
> ## nothing to promote.
> ## **D5 — THE DECRYPTION RANGE, and it is the finding of the arc** (fork
> ## `c00d7ce7`; the retraction of D4's old claim is `7b9a0d2d`). See the
> ## banner above. The measurement that produced it is the 68k
> ## program-ROM read probe (`JTCPS2W_PRGPROBE`, fork `72738d51`,
> ## sim-only): ten completed reads above `$400000`, all at
> ## `CPU:$4BE7C0-$4BE7C8`, all `fc = 2` (USER PROGRAM — opcode fetches),
> ## every RAW word the `.rom`'s byte for byte and **every latched word
> ## different**; 54,961,148 reads below `$400000` as the must-fire
> ## control; a `wide_en`-clear leg completing zero. With D5 in, the same
> ## fetches arrive as memory holds them, completed reads above `$400000`
> ## go to **1,189,750** spanning `CPU:$412BA0-$4D100E` (= `wide_ext` to
> ## the byte) with 20,000/20,000 sampled records matching the `.rom`, and
> ## the boot reaches the select screen.
> ## **THE PAYOFF: 9,038,400 reads over 105 DISTINCT TILE CODES
> ## `0x74D6-0xFE41` in group-C obj bank 5** — the select-wheel tenant art
> ## — first at simulated frame 1556, every code inside the roster's frozen
> ## live extent `0xFFDB`, control leg at zero.
> ## `tests/test_mister_gfxc_fetch.sh`'s WHEEL half is GREEN.
> ## **BOTH STOCK LEGS GREEN WITH D5 IN** (the FPGA superset invariant on
> ## the one change that could have moved it): `test_mister_wide_inert`
> ## bit-identical work RAM 101/101 with its control firing, and
> ## `test_mister_sim_anchor` at 2609 / 2146 / 463. True by construction as
> ## well as by measurement — `rng_eff` IS `addr_rng` with `wide_en` clear.
> ## **BANK 0 UNDER THE REDIRECT: ANSWERED, GO** (14z-107 (12),
> ## `mister_map.md` §9 open question 1). 40,717 accesses/frame through the
> ## select screen = **32.9%** of its 123,825 all-miss ceiling, 41,535
> ## in-match, whole-run peak 54,363 (**43.9%**), data bus 16-18%, **ZERO
> ## `SDRAM reads clashed` in 3,500 frames**; the redirect costs ~1,000
> ## accesses/frame (~2.5%) against stock. The instrument verified its own
> ## phase boundaries — the run's anchor at **2806** = the frozen 2609 +
> ## the 197-frame WIDE/stock transfer difference.
> ## **OBJ BANK 4 IS STILL UNPROVEN AND THE REASON IS THE HARNESS** — see
> ## the opener. A tenant has still never fought on the core.
> ## **FOUR NEW GATES / INSTRUMENTS:**
> ## `tests/test_mister_prg_probe.sh` (ci_portable, ~3 s) — the probe's
> ## contract and `tools/prgprobe_verdict.py`'s VERDICT LOGIC, on synthetic
> ## logs whose answer is known by construction: three answers plus FOUR
> ## refusals, two of them frozen from the real defects.
> ## `tests/test_mister_prg_window.sh` (emulator, ~2 x 40 min) — the
> ## measured pair, frozen, two `.rom` images differing in ONE BYTE.
> ## `tests/test_mister_gfxc_fetch.sh` (emulator, ~2 x 65 min) — the
> ## demonstration; its first real measurement found TWO defects IN ITSELF
> ## (the tile code computed from the ABSOLUTE SDRAM address rather than
> ## relative to the armed window's base; a liveness control demanding
> ## vanilla obj traffic in a leg that cannot boot by construction).
> ## `tests/audit_sdram_bank_load.sh` gained the WIDE leg's real run.
> ## **AND TWO HARNESS INSTRUMENTS FROM (10), still the workhorses:**
> ## `JTFRAME_SIM_RDPROBE` (fork `17a5dc2b`) — FOUR SDRAM read counters,
> ## each a bank plus a half-open byte window, reporting reads / DISTINCT
> ## 128-byte blocks (which on CPS-2 graphics IS a tile-code list) / first
> ## frame / address range. Four slots and not two ON PURPOSE: two arm the
> ## windows under test and two arm windows that MUST see traffic, so a
> ## zero is evidence about the CORE and not about the probe. Units are
> ## burst BEATS, not ACTIVATEs. `JTFRAME_SIM_VIDEO_FIRST/_LAST/_STRIDE`
> ## (fork `fd454393`) bounds the frame writer, so a 4,000-frame run
> ## writes a filmstrip instead of ~3,000 jpgs.

> ## **SLICE LOG (history) — 14z-107 (9): MiSTer SLICE D2 IS DONE. THE WIDE ROMSET
> ## HAS A PLACE IN SDRAM AND EVERY BYTE OF IT WAS COUNTED.** Fork commit
> ## `0df6f000`, **PUSHED** (fork pushes are standing-authorised now; the
> ## MAIN repo is still never pushed *[CORRECTED 14z-108: not true any
> ## more — see the banner]*). `cores/cps1`/`cps2`/`cps15`
> ## BYTE-UNTOUCHED.
> ## **WHAT SHIPPED:** the bank-0 re-pack (VRAM `0x600000`, ORAM `0x640000`,
> ## WRAM `0x648000`, Z80 `0x658000`, making room for a 6 MB PRG), the
> ## group-C GFX redirect (obj bank 4 → SDRAM bank 1, obj bank 5 → bank 0),
> ## the QSound split across two banks on `pcm_addr[23]`, the PCM-high slot
> ## and the two GFX slots, and **ONE new jtframe file**
> ## `hdl/sdram/jtframe_ram1_7slots.v` — a mechanical sibling of
> ## `ram1_5slots.v`, pulled by `cores/cps2w`'s own `game.yaml` and NOT added
> ## to jtframe's shared `jtframe_sdram64.yaml` (that list is included by
> ## every core). `cores/cps2w/hdl` goes from four files to six.
> ## **EVERYTHING BEHAVIOURAL IS GATED — five `wide_en` sites now.** The one
> ## exception is declared, not hidden: the bank-0 re-pack is unconditional
> ## because `SLOTn_OFFSET` are elaboration-time parameters. It is a
> ## RELOCATION with no behavioural surface, and `test_mister_wide_inert`
> ## measures that (`cps2w` == `cps2`, bit-identical work RAM 540-640).
> ## **THE EVIDENCE IS AN SDRAM IMAGE CENSUS, NOT A REPLAY** — and it has to
> ## be: `rom0_bank[2]` is TIED LOW until D3, so D2 changes no fetch at all.
> ## `tools/mister_sdram_census.py` replays the download mapping (regions,
> ## the QSound split, the group-C redirect, the CPS-2 GFX scramble) and
> ## compares **all 67,108,864 bytes of all four banks**. PASS on every bank
> ## on the WIDE image (66,265,152 B, transfer complete at simulated frame
> ## 659). Controls: a 1 KiB shift of any constant is rejected; banks 1/2/3
> ## byte-identical between the two cores on a stock image with bank 0
> ## differing; banks 2+3 DIFFERING between them on the WIDE image, because
> ## without the redirect group C aliases onto vanilla's art.
> ## **AND THE CENSUS CONTRADICTED THE MAP. THE CENSUS WON.** The fit's slack
> ## is **0.125 MB, not 0.708**, and **SDRAM bank 1 is EXACTLY FULL**. The map
> ## sized the group-C obj banks by the art's live FOOTPRINT; the MRA
> ## downloads the whole declared region, so each reserves its full 8 MB.
> ## Both consequences point opposite ways: tenant art may now grow freely
> ## inside the existing 16 MB (one more tile overflows nothing), and the
> ## group-C ROMSET REGION cannot grow at all. Corrected in place in
> ## `mister_map.md` and in `tests/audit_mister_map_fit.sh`.
> ## **STOCK LEG GREEN:** `test_mister_sim_anchor` 2146 / 2609 / 463 on
> ## `cps2w`; `test_mister_wide_inert` bit-identical.
> ## **NEXT: slice D3** — the obj promote (`jtcps2_obj_scan.v:152`
> ## `st3_bank <= {table_y[12], table_y[14:13]}`, the CPS-2 Turbo rule) and
> ## the `dr_bank`/`obj_bank`/`rom_bank`/`rom0_bank` chain widened to 3 bits.
> ## D2 built the destination and the plumbing; D3 drives `rom0_bank[2]`.



> ## **SLICE LOG (history) — 14z-107 (8): THE SIMULATED CONTROLLER WAS PRESSING
> ## FOUR BUTTONS NOBODY SCRIPTED.** jtframe v1.7.3's `SimInputs` held
> ## **P1's AND P2's buttons 5 and 6 DOWN** on every 6-button core — two
> ## 8-bit constants on a `[9:0]` **ACTIVE-LOW** port: `parse_inputs()`
> ## masks with `&0xf0` (throwing away the bits the line above released) and
> ## the constructor seeds `joystick1..4 = 0xff`, which `parse_inputs()`
> ## never corrects for players 2-4. So the MAME leg and the sim leg of the
> ## §4 oracle had never been running the same inputs — a FIDELITY defect in
> ## the instrument, recorded in 14z-107 (7) and FIXED here.
> ## **VERIFIED BEFORE IT WAS FIXED, AGAINST A SECOND IMPLEMENTATION, NOT
> ## AGAINST THE SOURCE.** A MAME hold-vs-not differential located the
> ## game's own input mirror — `RAM:$FF8058`/`$FF805A` (P1 held / new-press)
> ## and `$FF805C`/`$FF805E` (P2), 0x40 = button 6, 0x20 = button 5, live
> ## from MAME frame ~92. The **pre-fix sim's `$FF8040-$FF8070` block is
> ## byte-identical to MAME running the same ROM with P1 AND P2 buttons 5+6
> ## physically held**; after the fix it is byte-identical to MAME's
> ## no-input leg. The fix's whole boot footprint is **8 bytes of 65,536**
> ## (`$FF8058/5A/5C/5E` 0x60→0x00, `$FF8060-63` 0x40→0x00).
> ## **FIX: fork commit `519aff8b` — `& ~0xf` and `0x3ff`, one file, no RTL,
> ## no macro, LOCAL ONLY** (push authorisation still held). It is a plain
> ## upstream bug and the commit reads as a clean upstream report; nothing
> ## was filed. Gate: `test_sim_wram_contract` check 12 (+ its control).
> ## **THE RE-FREEZE: NOTHING MOVED, AND THAT IS THE RESULT.** MAME 2146 /
> ## sim **2609** / skew **463**, re-measured on the REFERENCE core over
> ## 2100-3000 so the window could not box the answer in; band untouched at
> ## ±30. Mechanism: a button held from before boot produces no PRESS EDGE,
> ## and this replay's only inputs are a coin, a start and one button-1 tap.
> ## Every §4 field still agrees, and the sound-state-fed arcade draw is the
> ## same pair as before (MAME `$0AE9D4` / sim `$0A9518`).
> ## **`audit_sdram_bank_load`'s phase boundaries are keyed to the anchor
> ## and therefore did NOT move** (2608 / 2614); re-deriving the table from
> ## `build/sdram_bank_load_14z107.log` reproduces it exactly.
> ## **~~STILL DEFERRED (maintainer): the COVERAGE half~~ [P2 DONE 14z-109;
> ## buttons 4/5/6 still refused]** — making buttons 5/6
> ## and P2 SCRIPTABLE. `tools/rpl2siminputs.py` still refuses them loudly.
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots).


> ## **SLICE LOG (history) — 14z-107 (7): THE "VIDEO-SENSITIVE ANCHOR" IS
> ## ROOT-CAUSED, AND IT INVERTED A VERDICT.** The picture never touched
> ## the CPU. jtframe's Verilator harness forks an ImageMagick child per
> ## CHANGED frame — ALWAYS, `-video` is not what enables it — and that
> ## child ended with **`exit(0)`**, which runs the C stdio cleanup.
> ## **libc++'s `basic_filebuf` is a `FILE*`**, so the child `fclose()`d the
> ## copy it inherited of the parent's `sim_inputs.hex` stream, and POSIX
> ## makes `fclose()` on a read stream REWIND THE SHARED FILE OFFSET. The
> ## parent then re-read input lines it had already consumed: **the
> ## simulated CONTROLLER was being replayed, once per fork** — and the
> ## number of forks follows the PICTURE.
> ## **THE 2x2 (681 dumps per leg, all four sets asserted complete):** frame
> ## output OFF, LUT present vs absent → **bit-identical 681/681**; same
> ## core, frame output OFF vs FORK → **483 of 681 differ**, first at frame
> ## **2051**, ONE byte, `RAM:$FF8060`, the **START bitmask**; black-screen
> ## core OFF vs FORK → bit-identical (it forks once, not 1,348 times); fork
> ## mode run twice → bit-identical, so the corruption is DETERMINISTIC.
> ## **THE FROZEN ANCHOR WAS THE ARTIFACT: re-measured MAME 2146 / sim
> ## 2609 / skew 463**, and every leg that does not fork agrees on 2609.
> ## D1's RED 2609/463 was right; the green 2502/356 was the corrupted run.
> ## Band unchanged at +/- 30 — the centre moved onto a named mechanism.
> ## **FIXES (fork, LOCAL ONLY):** `7cf1eedb` the child now `_exit(0)`s (the
> ## real repair, one word); `692ba4d6` adds `JTFRAME_SIM_NOVIDEO` + reaps
> ## the children, and `tools/run_sim_jtcps2.sh --frame-output off` is the
> ## lane's DEFAULT so a state oracle does nothing with the pixels at all.
> ## **INTEGRITY:** `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS,
> ## so a lost dump used to just move the anchor. Every `--wram` run now
> ## asserts its set is complete, and the anchor gate checks BOTH legs and
> ## asserts the frame-output mode from the run's own log banner.
> ## **THE DUMPS WERE NEVER CORRUPTED** — they are written by the PARENT
> ## from an `ofstream` opened and closed inside one call, with no
> ## descriptor open across the fork. The INPUTS were.
> ## **AND ONE NEW FINDING, RECORDED NOT FIXED: v1.7.3's `SimInputs` HOLDS
> ## P1 BUTTONS 5 AND 6 DOWN** (`test.cpp:201`'s `& 0xf0` drops bits 9:8;
> ## active low; `jtcps2_main.v:266` wires them in). The MAME and sim legs
> ## are therefore not running identical inputs. The one-line fix moves the
> ## anchor again, so it belongs with the queued P2/6-button fork commit —
> ## that pending item is upgraded from COVERAGE to FIDELITY.
> ## **[FIXED 14z-107 (8), fork commit `519aff8b` — and P2's buttons 5/6
> ## were held too. The anchor did NOT move. See the newest block above.]**
> ## **NEXT: slice D2** (bank-0 repack, the group-C GFX redirect, the QSound
> ## bank split on `qsnd_addr[23]`, `jtframe_ram1_7slots`, the two new GFX
> ## slots) — and it can now change video output without the anchor going
> ## ambiguous, which was the whole point of this session.

> ## **SLICE LOG (history) — 14z-107 (6): MiSTer SLICE D1 IS DONE, and it is the
> ## slice where `cores/cps2w` STOPS BEING cfg-ONLY.** The QSound
> ## sample-bank width fix ships behind a **RUNTIME** profile gate: **MRA
> ## header byte 41, bit 0, ACTIVE LOW** (`0xFF` fill = profile OFF, the
> ## WIDE MRA writes `0xFE`). So stock `vsavj` on `jtcps2w.rbf` is a STOCK
> ## MACHINE by construction, which is what makes rule 1 v2's
> ## "profile-gated" a fact on FPGA rather than an inertness argument.
> ## Fork commit `4840df8a` — **LOCAL ONLY, NOT PUSHED** (the maintainer has
> ## not re-confirmed push authorisation; every other fork commit is
> ## public).
> ## **`cores/cps2w/hdl` now holds FOUR files** — two new
> ## (`jtcps2w_profile.v`, `jtcps2w_qsnd_bank.v`) and two OVERRIDES of
> ## SHARED files (`jtcps15_sound.v` from cps15, `jtcps2_game.v` from
> ## cps2). `cores/cps1`, `cores/cps2` and `cores/cps15` are BYTE-UNTOUCHED
> ## and that is now a `git diff` assertion (`test_jtcores_twin` 2e).
> ## **THREE THINGS THAT CHANGE HOW TO WORK HERE:**
> ## **(1) `PCM_AW` 23 → 24 DOES NOT COMPILE** and three documents said it
> ## did. `jtframe_romrq_bcache.v:74` replicates `SDRAMW-AW` zeroes, which
> ## goes NEGATIVE past `AW = SDRAMW = 23` — Verilator refuses to elaborate.
> ## An 8-bit jtframe slot reaches **8 MB of a 16 MB bank**, which is why
> ## the map splits QSound across two banks. Struck in place everywhere.
> ## **(2) `jtframe files` DEDUPS BY FULL PATH**, so overriding a shared
> ## file means DELETING it from the original core's list — and a `.yaml`
> ## pulled with `get:` drags the shared file with it, so cps2w had to
> ## INLINE cps15's `qsound.yaml` instead of pulling it.
> ## **(3) The bank bit IS `dsp_ab[7]`, validated against MAME's LLE
> ## qsound device** (`map(0x0000,0x7fff).mirror(0x8000)` +
> ## `m_rom_bank = (m_rom_bank & 0x8000U) | offset`), not against the
> ## commented-out permutation jtcps15 carries.
> ## **NEXT: slice D2** — the placement: bank-0 repack, the group-C GFX
> ## redirect in `jtcps1_prom_we`, the QSound bank split on
> ## `qsnd_addr[23]` (already produced and gated, just unrouted),
> ## `jtframe_ram1_7slots.v` (maintainer-ruled option A) and the two new
> ## GFX slots.
> ## **(4) A NEW CORE WITHOUT `hdl/pal_lut.hex` RENDERS A BLACK SCREEN**,
> ## `*.hex` is gitignored in jtcores so `git add` refuses it silently, and
> ## — through the Verilator harness's per-changed-frame `fork()` — that
> ## VIDEO defect MOVED the simulated match-start anchor by 107 frames and
> ## turned `test_mister_sim_anchor` RED. Four 50-minute runs to find. A
> ## 2x2 factorial put the whole effect on the `.hex` and none on the RTL.
> ## **So: never blame a red anchor on RTL until a core-vs-core RAM
> ## comparison says so** — that is what `test_mister_wide_inert` is for.
> ## **Gates:** `test_mister_wide_gate` (ci_portable, 22 s) is the RTL
> ## trust surface — a frozen line-by-line override delta, the missing-asset
> ## check that would have caught pal_lut, and two Verilator benches with
> ## four must-fire controls; `test_mister_wide_inert` (emulator, ~22 min) is
> ## the INERTNESS instrument (cps2 vs cps2w, bit-identical work RAM);
> ## `test_mister_sim_anchor` runs on **cps2w** by default
> ## (`SIM_CORE=cps2` for the reference leg) and is a cross-IMPLEMENTATION
> ## oracle, not an inertness test.

> ## **SLICE LOG (history) — 14z-107 (5): MiSTer SLICE D0 IS DONE.** The MRA that
> ## makes the WIDE image downloadable at all is written, pushed to the fork
> ## (`38acc638`) and gated. `rom/vsavjw.rom` = **66,265,152 B**, header
> ## words **6144 / 6400 / 15552 / 64704** — `docs/project/mister_map.md`
> ## §3 to the byte, verified region by region against the romset. The
> ## stock leg is untouched and now GATED: the `vsavj` MRA from `cps2w` is
> ## byte-identical to `cps2`'s except `<rbf>`, `cps2` emits NO WIDE MRA,
> ## and stock `vsavj.rom` is still 46,407,744 B.
> ## **Build it:** `ROMDIR=... tools/mister_mra.sh --core cps2w --wide
> ## build/m3b_merged13 --out <dir OUTSIDE the repo>`.
> ## **THREE THINGS D0 FOUND, all of which change how to work here:**
> ## **(1) The map's own proposed TOML row was WRONG and wrong SILENTLY** —
> ## `parts=` collapses a whole region into ONE `<interleave>`, so three
> ## QSound members all mapping "12" become the first one truncated. The
> ## fix is a SEPARATE `qsoundw` region (with a generic `skip=true` row, or
> ## the stock MRAs gain a comment line and the twin breaks). Corrected in
> ## place in §3, wrong row kept and labelled.
> ## **(2) jtframe finds zip members by CRC32 ALONE** (`mra2rom.go:163-172`)
> ## — FBNeo and MAME resolve by NAME and only warn, which is why our WIDE
> ## members carry SENTINEL CRCs there. **So the MiSTer MRA is pinned to one
> ## romset BUILD**: `tools/gen_vsavjw_xml.py` generates the fork's
> ## catalogue entry from the zip, and a romset rebuild that moves a CRC
> ## needs a new fork commit. `tests/test_mister_mra_map.sh` says so loudly.
> ## **(3) The WIDE set's PARENT is the BUILD's `vsav.zip`,** not the
> ## pristine dump (the merged build patches `vm3.13m/15m/17m/19m`), and
> ## `jtframe mra` reads a hard-coded `$HOME/.mame/roms/` — hence the
> ## private-`$HOME` staging in `tools/mister_mra.sh`.
> ## ~~**NEXT: slice D1** (the QSound width fix, `jtcps15_sound.v:47,416` +
> ## `PCM_AW` 24)~~ — **DONE, see the 14z-107 (6) block above; and `PCM_AW`
> ## 24 was wrong.**
> ## Two SHIPPING questions D0 surfaced, for the maintainer, in STATE
> ## "Decisions pending": which MRA is the core's MAIN one, and how a
> ## release carries both `vsav.zip` flavours.


> ## **14z-107 (4): THE MiSTer SDRAM PLACEMENT MAP EXISTS
> ## AND IT FITS, by 0.125 MB of 64 (0.708 MB RETRACTED 14z-107 (9) —
> ## see below).** Read `docs/project/mister_map.md`
> ## before any MiSTer RTL. Three things in it change what earlier
> ## entries below say:
> ## **(1) "6.39 MB of tenant art into bank 1's 7.1 MB spare" IS WRONG.**
> ## 6.39 MB is a LIVE-BYTE count; a CPS-2 tile code IS its SDRAM address
> ## (the download scramble at `jtcps1_prom_we.v:105` undoes the .rom's
> ## 4-way interleave), and the roster runs to code `0xEE73` in group-C
> ## obj bank 4 and `0xFFDB` in bank 5 -> **an ADDRESS FOOTPRINT of
> ## 15.45 MB**, needing the spare of BOTH banks 0 and 1.
> ## **(2) THE WIDE `.rom` DOES NOT DOWNLOAD AS DECLARED** — 70.26 MB
> ## overflows the 26-bit `ioctl_addr` GAME port
> ## (`jtframe_mem_ports.inc:1`) AND the 16-bit header start word. The
> ## MRA must trim QSound to 8.9375 MB; `mra2rom.go:177-196` +
> ## `parts=[...]` do that from the MRA alone, so the ONE-ROMSET ruling
> ## holds. **DONE in D0 — but NOT with the row §3 proposed; see the
> ## 14z-107 (5) block above.** QSound is then SPLIT across SDRAM banks 0 and 1 on
> ## `pcm_addr[23]` — without that split the map overflows bank 1 by
> ## 0.39 MB and nothing else closes it.
> ## **(3) THE PRG WINDOW IS RESOLVED:** `objcfg_cs` is WRITE-ONLY
> ## (`jtcps2_main.v:190 && !RnW`), so a 6 MB `rom_cs` gated on `RnW`
> ## has NO read collision; the 16-byte `$400000-$40000F` reservation is
> ## enough. Bonus defect found: `:167` would leave `$500000-$5FFFFF`
> ## ZERO-wait while all other ROM is one-wait.
> ## **Slice plan D0-D4 with a gate + must-fire control each is in §10.**
> ## New gate `tests/audit_mister_map_fit.sh` (ci_static, ~5 s) freezes
> ## the four extents the fit rests on; **one new tenant tile above
> ## `0xEE73`/`0xFFDB` breaks the map**, and this is what catches it.
> ## **Open for the maintainer: the bank-0 slot count** (add
> ## `jtframe_ram1_7slots` vs move the Z80 to bank 1) — Decisions
> ## pending.

> ## **THE STATE IN ONE BREATH: the 14z-105 window is FROZEN as
> ## donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 (stock twin
> ## m5_stock6 = `883e7d17`, UNCHANGED). PLAY:
> ## `tools/run_wide.sh build/m3b_merged13 fbneo`. FIELD-CONFIRMED and
> ## PUSHED 2026-08-22 (Oboro + the M6 mark both confirmed; Oboro's long
> ## intro is vanilla's own boss intro — accepted, not tournament-legal).**
>
> ## **WHAT THE WINDOW SHIPPED (both profile-gated, both inside the
> ## ratified select-window class):**
> ## **W1 — THE OBORO SELECT HOOK:** cursor on BISHAMON, hold START,
> ## confirm with any button -> vanilla vsavj's Oboro (id 0x18, base
> ## 0x0B3450; the pale colorway; HUD name stays "Bishamon" — aliased
> ## rows). P1 and P2. Without Start: plain Bishamon. The mechanism is
> ## vanilla's own Gallon-variant idiom at PRG:0x020B9C one cell over
> ## (`btst #7,$394(a6)` IS the Start test — measured before authoring).
> ## Gate `tests/test_oboro_select.sh` (5 legs incl. P2 and the stock
> ## twin). Atlas: select_screen.md "The Oboro select hook".
> ## **W2 — THE VERSION STRING:** "M6" at the select screen's bottom-
> ## right — THE NAKED-EYE A/B TELL (CLAUDE.md §5, open since 14z-92,
> ## now implemented). Two authored glyph sprites on the roster21 wheel
> ## record, tiles in group C 0x1FE40/41, pal row 0x19. Knobs on
> ## `[[select_wheel]] roster21` in all three manifests — **BUMP
> ## `version_text` AT EVERY FREEZE** (it names the generation). Gate
> ## `tests/test_version_string.sh` (pixel-exact snapshot). Font:
> ## `build/manifest/version_font.json` (0-9 A-Z - . space; add glyphs
> ## there if the text needs more).
>
> ## **THE FINDING ON THE WAY — the tile codec was mirrored.**
> ## `gfx_tiles.decode` had mapped plane bit i to pixel i since it was
> ## written; the hardware draws bit i at pixel 7-i of each 8-px half,
> ## and the transparent pen is 15. Nothing had ever consumed pixel
> ## ORDER until the first authored tile. Fixed both ways, gate
> ## `tests/test_gfx_tile_codec.sh`, platform gotcha. RULE: a
> ## synthesized tile is verified at the RENDER layer, never by a byte
> ## round-trip alone.
>
> ## **A PREDICTION THAT DIED:** the 14z-104 close said the select-window
> ## specs would MOVE with two more sprites. Measured over all 148
> ## window/composite specs: UNCHANGED. The window end is the VS-phase
> ## re-init, not the sprite count.
>
> ## **THE NEXT SESSION starts clean — the field test passed and the
> ## push is done.** Nothing is queued — every verification
> ## the 14z-102 freeze had is green on 14z-105 (incl. audit_merged_
> ## legacy 47/47 + leg b, and the guard-corpus soak 316/316, run while
> ## the maintainer tested; the Oboro pick also agrees on FBNeo, leg F).
> ## **RELEASE PACKAGING IS DONE (14z-105 (2)):** `release/merged-m6/`
> ## — xdelta3 patches against the four reference dumps, manifest,
> ## applier, README; gate `test_release_roundtrip.sh` (round trip
> ## byte-identical, applier refusals, rule-7 scan). Re-package at every
> ## freeze with `tools/package_release.py build/<merged>/rompath release
> ## --romdir $ROMDIR --name merged-mN --version <mark>`. RULED
> ## (maintainer, 2026-08-22): stays IN-TREE until MiSTer; a tagged GitHub
> ## release is cut then, covering both. MiSTer core surgery is next.
> ## **14z-106 (2026-08-22): housekeeping DONE** (w6 evidence logs +
> ## guard-corpus TSV committed; probes attic'd to `../build_attic_14z105`;
> ## `../build_attic_14z102` DELETED per policy; fbneo submodule content
> ## verified = patches 0001+0002). **MiSTer FRAMING RECORDED (maintainer):
> ## the deliverable is an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA
> ## re-implementation of the MAME emulation.** Before any RTL: the
> ## alignment questions in STATE "Decisions pending — MiSTer alignment"
> ## — ALL FIVE RULED 2026-08-22: separate core (GPL-3.0 fork of jtcores,
> ## own RBF), measure-then-choose profile, sim = gate / hardware = field
> ## test, MiSTer + Jammix available (SDRAM SIZE TO CONFIRM), MRA+RBF with
> ## a stock-vsavj reference-leg MRA. LICENSE: GPL-3.0 (done).
> ## **14z-106 (3): MiSTer SLICE A DONE** — fork `DefinitelyFrenchName/
> ## jtcores@vampire-saved` (core `cores/cps2w` → `jtcps2w.rbf`), submodule
> ## `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`;
> ## the vsavj reference-leg MRA measured byte-identical to stock except
> ## `<rbf>`. ("NO XL SDRAM tier exists" — TRUE OF OUR PIN ONLY; see
> ## the 14z-107 (2) block below.)
> ## **SLICE B MEASURED (`docs/project/mister_fit.md`): the roster's art
> ## is 6.39 MB vs 0.49 MB blank in vanilla's 32 MB — a wider GFX tier is
> ## REQUIRED; PRG needs 4.82 MB (+ a 30-B pin at 0x5FFF00); QSound ext =
> ## banks 0x80-0x8E (all aliasing → width fix required). ~~PENDING RULING:
> ## WIDE v1 VERBATIM on a 128 MB tier (recommended) vs a tighter MiSTer
> ## profile.~~ **RULED 2026-08-23: WIDE v1 VERBATIM. The "128 MB tier"
> ## half is superseded — see 14z-107 (2) below.** **SLICE C: THE SIM LANE WORKS** (stock jtcps2 + vsavj under
> ## Verilator on this Mac, ~1 s/frame, recipe in mister.md; `.rpl` →
> ## `sim_inputs.hex` translator gated).**
> ## **14z-107 (2026-08-23): THE MiSTer ORACLE IS REAL — the §4
> ## dual-emulator protocol now runs on a THIRD implementation and
> ## AGREES.** Fork commit 2 `553dd56` = `JTFRAME_SIM_WRAMDUMP`, 64
> ## macro-gated lines in the Verilator TESTBENCH `test.cpp` (no RTL);
> ## `emu/jtcores` pin bumped and the patch mirror is now a SERIES.
> ## `tools/run_sim_jtcps2.sh` is the whole lane in one command; gates
> ## `test_sim_wram_contract` (ci_portable) + `test_mister_sim_anchor`
> ## (emulator tier, ~55 min). MEASURED: work RAM = SDRAM bank 0 byte
> ## `0x600000`, 64 KB, 68k byte order; `05_timeout_idle` round-1
> ## match-start anchor MAME **2146** / sim **2502**, skew **+356** [RETRACTED 14z-107 (7): 2609 / +463]
> ## (NOT the +460 boot offset — the attract/select/VS path costs ~99
> ## fewer frames on the core, which is why §4 anchors exist). Every
> ## compared field agrees, P1 = Demitri `$093B6A` on both.
> ## **THE ONE DISAGREEMENT IS THE GAME'S OWN LOTTERY:** the 1P arcade
> ## draw is sound-state-fed (`ram.md:99`, the #110 mechanism), so the
> ## CPU opponent differs (`$0AE9D4` MAME vs `$0A9518` core) and the
> ## P2-identity fields are excluded BY NAME. Pinning it needs a 2P
> ## replay -> P2 SCRIPTING in `SimInputs` -> a queued fork commit
> ## [still queued at 14z-107 (8): commit 10 RELEASED P2's buttons, it did
> ## not make P2 scriptable; the draw is the same pair after the fix].
> ## **TWO RETRACTIONS:** `JTFRAME_SIM_IODUMP` dumps the EEPROM on CPS-2
> ## and `JTFRAME_SAVESDRAM` is Verilog-model-only — work RAM was never
> ## "reachable"; and **`-load` is MANDATORY** (the download latches the
> ## decryption key into core registers, so a preloaded run boots into
> ## ciphertext — 1,841 frames of ALL-ZERO RAM that still "agreed" with
> ## MAME on 99.2% of sampled bytes. Check NON-CONSTANCY first.)
> ## **14z-107 (2) — THE MEMORY-MAP TRUTH (docs + STATE only; no code, no
> ## RTL). The profile ruling STANDS (WIDE v1 verbatim, one romset); the
> ## implementation assumption attached to it is RETRACTED: "MiSTer work =
> ## width plumbing only" is FALSE and the 128 MB tier is NOT a flag away.**
> ## At our pin `v1.7.3` **64 MB is PHYSICAL** — jtframe's table stops at
> ## `AW 23`, the bank geometry has no AW=24 arm (`addr[9]` would never be
> ## driven, aliasing with `addr ^ 0x200`), and only 13 A / 2 BA / 1 nCS
> ## pins are assigned. **`JTFRAME_SDRAM_XL` (128 MB) IS real — UPSTREAM,
> ## 3057 commits away, untagged** — as TWO CHIPS on one module with chip
> ## select on **nCS POLARITY**, and reachable ONLY inside the
> ## `JTFRAME_SDRAM_CACHE` branch: setting it on `cps2w` today would
> ## compile, validate and silently alias (platform gotcha). That
> ## **partially UN-RETRACTS** 14z-106's "no XL tier" — true of the pin,
> ## false of jtframe; `cps2_wide.md` now carries the version qualifier.
> ## **The CPS-2 CORE caps GFX at 32 MB in the OBJECT FORMAT** (16-bit code
> ## + 2-bit bank — the SAME 19-bit promote WIDE v1 already makes on FBNeo),
> ## the 68k at a flat 4 MB `rom_cs` (with a real collision against the
> ## objcfg window at `0x400000`), scroll at 8 MB, QSound at a 7-bit latch.
> ## No SDRAM tier lifts any of them.
> ## **AND THE ROSTER FITS 64 MB BY TOTAL — ~56.1 MB** (`mister_fit.md` §6):
> ## PRG 6 MB fits bank 0 TODAY, QSound 16 MB fits bank 1 TODAY (PCM is
> ## alone in a 16 MB bank), and ONLY GFX overflows, by ~6.4 MB — into
> ## bank 1's ~7.1 MB of spare. ~~**NEW PENDING DECISION: THE MiSTer
> ## MEMORY-MAP ROUTE** — (1) uprev to untagged master + XL + `mem.yaml`
> ## cache lanes, or (2) stay at the pin and BANK-REPACK inside 64 MB.
> ## **Recommendation (2)**~~ **DECIDED (maintainer, 2026-08-23): (2), the
> ## BANK REPACK, measuring first; XL is the FALLBACK. Measured GO the same
> ## day and SHIPPED in D2.** And the "~6.4 MB into bank 1's ~7.1 MB spare"
> ## framing is RETRACTED twice over: 6.39 MB is LIVE BYTES, the address
> ## footprint is 15.45 MB, and the DECLARED REGION the download reserves is
> ## 16 MB — see the top banner.
> ## **THE SIM LANE'S SDRAM MODEL IS FIXED (14z-107 (3), fork commit 3).**
> ## It dropped `addr[22]` — which rides on `sdram_a[9]` as the tenth COLUMN
> ## bit, NOT `addr[9]` — so GFX banks 2/3 were half-aliased. The "~3
> ## constants / widen the column to 0x3ff" fix named earlier was WRONG.
> ## The anchor oracle never moved (bank 0 is entirely below WORD 0x400000)
> ## and still passes; the anchor moved 2507 -> 2502 (skew 361 -> 356) [both absolutes RETRACTED 14z-107 (7): the clean anchor is 2609]
> ## because `jtcps1_obj_draw.v:137` skips blank tiles, so OBJECT TIMING
> ## DEPENDS ON GFX CONTENT. Two more harness bugs had to be
> ## fixed before `-stats` produced anything (commits 4 and 5).
> ## NEXT OPENER: ~~**the MEMORY-MAP ROUTE ruling**~~ [TAKEN 2026-08-23 —
> ## bank repack], then the core-side format
> ## work; phase B (the round-transition anchor on the full 12,120-frame
> ## replay, ~3.5 h), the Verilator 8 MB-per-bank fix and P2/6-button
> ## `SimInputs` are the queued follow-ups. [8 MB-per-bank done 14z-107 (3);
> ## `SimInputs` FIDELITY done 14z-107 (8), COVERAGE still queued.]
> ## The N-2 build-dir
> ## deletion policy applies at the NEXT freeze (m10/m19/m13/merged-m5
> ## dirs are now one-back; m9/m18/m12/merged-m4 + m5_stock4 are N-2 and
> ## fall).

## What 14z-105 did (the whole arc, one screen)

**Measure first:** Start held on the vanilla select screen -> struct
`+0x394` = `$8000`, `$FF8060` = 1 (both live at select; the template
bit is Start). **W1** authored as a 30-byte profile-gated site_thunk
(every manifest, deduped; +2 ops), rehearsed on a merged probe, gated
five ways. Stock twin rebuilt = `883e7d17` bit-identical (the profile
gate measured, not argued). **W2** authored as `version_*` knobs + a
5x7 font + `gfx_tiles.encode` + an `"authored"` list in
`wheel_bank5.json`; the first probe rendered mirrored glyphs in a black
box -> the OBJ list proved the sprites right and the TILE BYTES wrong ->
codec fixed both ways -> re-probe pixel-exact (0 mismatches). **The
freeze:** tenant_loop op counts re-frozen (325/365/298; 600/652;
806/907), five artifacts built from the tree (merged13 bit-for-bit the
probe), sets carried-renamed + registry rows, m3a pins + whole-artifact
manifests moved with member attribution (program + the four GROUP C
members = the glyph tiles; no QSound), the standing re-point sweep
executed (~70 defaults), placements +0x10 (hui) / +0x30 (pyron) ->
bases.tsv, pcrel [merged_*], pointer_flow baselines re-derived;
region_overlap section 5 still 2033. Every gate run at the freeze:
STATE 14z-105 CLOSE.

## What 14z-103/104 did — see STATE; the coverage matrix is fully green
(docs/project/coverage_matrix.md), #110 fixed, the A4 pin-cleanup done.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-104 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-103 did (the whole arc, one screen)

**The A4 pin-cleanup pass executed end to end** — every stale build-dir
reference re-pointed and run green, ruled a deliberate pin (don_m5 =
walker_repoint's un-relocated negative control; pyron26 + hui41 =
decode_stage_banners' frozen #92 carriers), or reclassed operational;
disposition table in `docs/project/build_dir_triage.md`. Findings: the
gate_failures litter class (the flicker-gate fixture wrote deliberate-
FAIL stubs into the evidence dir on every static run — fixed at the
root with M2A_KEEP_DIR, 141 files purged by content signature);
**GitHub #110** — audit_fg_damage + audit_pool_free_byte red since
14z-87 because that batch RE-ROLLED THE ARCADE DRAW (m6: char 0x0C /
stage 0x12; m7+: char 0x00 / 0x0E) — fixed by pinning the opponent
(2P-dummy rigs hui/74+75, EXPECT 69/69 bit-identical across
generations; pcosmo -> 106_pyron_cosmo_clash) and CLOSED; the 14z-88
self-frozen-sha1 hole live again on replays 94/103/105/106 — promoted
to `window vsavj/masked-v2 889 2091` (103 per-leg: tenant on don,
.legacy-exempt on hui/pyron); grab_victim's default was the pre-14z-73
expectation since birth (now `matches`, Δ=0); flicker_attribution had
been SKIPping on a removed set dir (now fingerprint-resolved). The
Circuit Scrapper report was measured NOT REPRODUCED (six-run A/B, MP/
HP/mash) and the maintainer confirmed it fine. Everything pushed
(bb79e18); suites GREEN x3, statics 97/0/0 strict.

## What 14z-102 did (the whole arc, one screen)

**The #107+#109 window frozen end to end** as donovan-m10 / huitzil-m19
/ pyron-m13 / merged-m5 (maintainer "go"; beams field-confirmed on the
rehearsal probe first; gold tint KEPT). #107 = the verified
reconciliation row 0x0448a6 -> 0x04367a (shared map — stock moved too).
#109 = the clone-beam fix: vsavj ships effect-class ROW 31 as a stub
(the DF clone-mode beam emitter); ported root 0x926e4:0x11e:t0x922f0 +
code_ptr at PRG:0x080B28; the root changed extraction (hui placements
shifted, op counts re-frozen 363/804, tenant bases re-derived). Every
verification green: run_suite x6, battery effectively 24/24,
guard-corpus soak 316/316 zero vectors, statics 97/0/0 strict.
PUSHED with #107/#109/#50 closed. Post-freeze rulings: DF durations
kept categorically (vsavj per-character, 1 stock); tint confirmed good;
#50 closed as standing policy; build-dir triage EXECUTED (85 dirs /
8.1 GB -> ../build_attic_14z102, reversible; N-2 generation-roll now
standing policy at every freeze).

## What 14z-101 did (the whole arc, one screen)

**The agreed #108→#107→#106 sequence, all executed windowless:** #108
INVERTED by the writer hunt (not-a-defect; the -debug "paradox" was a
pristine-table misread; audit re-framed to NATIVE PARITY + anchor leg);
#107 twin-anchored statically (both games' own farms bind slot-for-slot;
0x45FCC eliminated — next slot's routine; tie-refusal policy landed in
reconcile_batch + gate §6, live control: fresh 0x448a6 refuses as
TIE-4x0.94-w0x20; m3a bit-exact); #106 closed (verify_pcrel_data
--extract/--placement-suffix; merged inventories IDENTICAL to solos,
frozen by reference with a must-fire control; also fixed the tool's
listdir-accident zip pick).

**New standing instruments:** `audit_guard_corpus.sh` (79 replays × 4
legs under guard, 316/316 green, hui41-crash must-fire control);
`tools/enum_biased_lists.py`; rigs `df/97-102` (DF framework mechanics,
clone-attack discriminators, the NATIVE clone-mode reference).

**DF mechanics measured** (the field pass's named unknown): the GAMES'
DF frameworks differ by design — vs2 = 2-stock universal buff, uniform
332f (maintainer-confirmed); vsavj = 1-stock per-character modes
(legacy sweep spans 269-540f); ours == pristine vsavj EXACTLY on the
legacy control. Phobos' 0x18 clone-train mode is a legitimate vsavj DF
class (legacy 0x0C/0x0F use it at the same 377).

**#109 found and fully root-caused through the confirmation loop** (two
intermediate readings retracted in place — the layered-correction arc is
itself instructive: identify moves by measured EFFECTS, never the
script's input name — vs2's buffer folds 6236 to 236; gotcha paid).
The clone-mode EX = 263+2P (1 stock); the ES = 236+2P.

**The FOREIGN-DRAW class named** (register §5): audit_empty_tiles
measured PASSING on the #109 event — it audits group-C blanks, this
class draws from the WRONG SPACE; exposure census-bounded 26/1/0, the
paired-draw census queued as the instrument. [The #109 instance of the
class dissolved with the 14z-102 re-derivation (the beam draws
correctly); the CLASS and the census stay valid for the B-sweep
carries.]

**Also:** the ~200-build-dirs decision package delivered
(`docs/project/build_dir_triage.md`); the stale "#10 ripe" banner claim
retired; strengths/timeout-wins field items closed.

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-98 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-98 did

**#103 root-caused and causally confirmed; no shipped byte moved.** The
banner's consumer trace ran and ELIMINATED its own suspect (both spaces,
live controls), which moved the hunt one level up: the KO-recognition
step (phase 6->8) never fires for a Donovan death because the judge
tests WHITE HP's sign and his white never goes negative — a ported
pc-rel escape pins his hp to 1 mid-match. Chain, instruments, fix design
and rehearsals: STATE 14z-98; the issue carries the full write-up.

**New instruments:** `tests/audit_don_ko_writer.sh` (the root-cause
lock, both modes rehearsed); `trace_writes.lua` DUMPS (self-documenting
-debug runs). **New gotchas (project bucket):** every -debug watch
configuration is its own TIMELINE; GUARD_PROBE's RET (SP) lies for
jmp-reached code. **Atlas:** +0x52 judge note, +0x54, +0x11F rows;
engine_internals "THE ROUND JUDGE" section. **Retractions executed:**
the "author the four per-char rows" fix shape (issue, STATE (9) marker,
bank_map.toml trace note).

---

# HISTORY BELOW — carried for reference, not current

Everything from here down was written at the close of 14z-97 and
earlier. Kept because the eliminations and traps stay valid; read the
section above for the current state.

## What 14z-97 did

**Closed: #96** (maintainer-ruled option (a), executed). One arc, no build
bytes touched.

**The battery's legacy target now FOLLOWS THE BUILD.** It resolves the
expectation set from the build's own program fingerprint through
`tests/expected/registry.tsv` — the same auto-detecting mechanism
`run_suite.sh` has always used — so nothing in the gate names a generation,
and at the next freeze the registry row moves and the gate follows with no
edit. An unregistered fingerprint is now the rule-6 signal by construction,
and it stops the gate BEFORE any replay runs.

**First measurement, and it settles the ticket: the pipeline DOES reproduce
the freeze.** Rebuilt clean, stage 6 -> `a054de5c` (the stock twin named in
the donovan-m8 freeze record), stage 4 -> `22c804c8`. Every #96 symptom was
the dated `donovan-m2c` pin, exactly as the ruling said.

**The one open item, `08_challenger_join`'s 3807, is ATTRIBUTED:** full-RAM
dump diff at 3507 AND 3807 shows one differing live byte, **`$FF06E1`** —
the byte `docs/game/atlas/ram.md:62` names verbatim (OBJ-builder secondary
stack, "execution POSITION, not state"). Corroborated twice: `donovan-m2b`
measured the same pair one generation EARLIER than the pin, and on the WIDE
track that frame is a select-window onset (the challenger join re-enters
select). Not growth of an unknown kind.

**Constants that disappeared AS constants:** the V1 mask string (#70's other
half), the V1 basis path, `M2A_FLICKER_SPECS=donovan-m2c`, the two
generation-dependent class lists, and 700 / 4278 / 1080 (from the MASKED
gate — 4278 rightly stays in the unmasked stages-1-3 one, where it is a fact
about vanilla's attract demo). Those three are `.masked` `diverge` specs now,
which is STRICTER — `check_diverge.py` also asserts line-identity before the
frame.

**A PREDICATE WAS INVERTED, deliberately.** 14z-90 (#2) made the flicker
check fail on growth and merely ADVISE on shrink, because the battery ran on
UNFROZEN dev builds. That premise is gone: the target is a frozen
generation, so a shrink means the fresh build is not the frozen one, and
drift either way now fails. If you find yourself "fixing" that back, read
`tests/test_m2a_flicker_gate.sh`'s header first.

**The §4 vocabulary has ONE implementation:** `tests/lib/masked_compare.sh`
(exact/flicker/diverge/window/composite + the #62 baseset-mask guard),
shared by `run_suite.sh` and the battery. Proven three ways — textual
identity of every checker call and verdict string with the pre-lift block, a
synthetic ground truth over all five classes in both directions, and a
real-data re-check of `window`+`composite` on the shipping WIDE build.

**Two real defects found on the way, both of the "measured the wrong thing
quietly" class:** `tools/propose_masked_specs.sh` measured PRISTINE VANILLA
when given an absolute builddir (it existence-checked one path and handed
MAME another), and the lifted `diverge` branch would have reported
NO-BASE-LOG on every diverge spec (`check_diverge.py` derives the base log
from the spec FILE's stem). Both fixed, both gated. Also: a verdict control
in `test_baseset_mask_invariant.sh` was briefly passing because it CRASHED.

**Where the tenants stand:** unchanged. No build moved; the 14z-96 freeze
stands.

## What 14z-95 did

**Closed: #24, #27, #43(a), #52, #97, #98, #100.** Advanced: #96 (symptom
fixed, three items separated, root-caused to one constant), #99 (parked with a
cold-resume record), #100 (mechanism localised, then closed WON'T FIX under
the standing cosmetic ruling and re-scoped beyond MiSTer).

**Five new gates**, all with must-fire controls:

| gate | what it locks |
|---|---|
| `test_tenant_pairings.sh` | tenant-vs-tenant, all SIX orderings — the CLAUDE.md §4 coverage the suite never had, and the gap #99 walked through |
| `test_hui_electrocute.sh` | the FIRST electrocute rig in the project's history (STATE said twice no replay produced one) |
| `test_merged_inputs.sh` | the merged build's inputs are PRODUCED, not demanded — rule 3 is one command |
| `test_reconcile_matcher.sh` | one matcher, pinned inert (1640/1640 probes), parameters proven load-bearing |
| `audit_ladder_selector.sh` | the #99 ladder probe, and a regression lock on a hypothesis that DIED |

**THE SESSION'S REAL LESSON, worth more than any single fix: FOUR separate
defects were checks that had STOPPED CHECKING**, and each read as green or
quiet rather than red —

| what | how it hid |
|---|---|
| `test_dualtrack` | red for 11 days; no runner executed it |
| `audit_pyron_ring` | compared two builds that stop being comparable at f4741 |
| `test_m2a_stage4_code` | asserted a constant a ratified change had invalidated |
| `test_reconcile_matcher` | **mine** — disarmed itself the moment I committed the change it polices |

The last was caught ONLY because `run_all_static` counts SKIP as a third
outcome (#29/#30). That is an argument for spending time on gate
VERIFICATION, not only on gate COVERAGE.

**Generalise from the fourth:** any gate that reconstructs a "before" state
from git is dated by its own commit. `git log -S` answers "where did this
change", NOT "the last version that HAD this".

## Where the tenants stand

Unchanged this session — no build byte moved. `build/m3b_merged9` =
**merged-m2** (`081e2e53`, 752 ops), solos `hui43` = huitzil-m16
(`da734d49`) and `pyron27` = pyron-m10 (`e29cac23`), `build/don_m7` =
donovan-m7 (`c90b60c3`, unchanged since 14z-91). Maintainer playtest of
merged-m2: **no regression**, one crash (#99), one cosmetic (#100, now
won't-fix).

---

(Deeper history, 14z-92/93/94, follows — same caveat as above.)

## What changed in the triage, in one screen

Almost none of these were wrong logic. They were **checks that stopped
existing** under an ordinary condition — an env var, a wrong argument, a
phantom CLI option, a stale marker file, a literal constant — and in each case
the thing that should have caught it was disabled by the same stroke.

| # | the switch | what it turned off |
|---|---|---|
| 79 | `python -O` | `assert` is REMOVED, not weakened. Six tools, incl. the cipher round-trip self-check. |
| 76 | a wrong 2nd argument | `outdir == romdir` deletes the reference set. No undo (rule 7). |
| 80 | `MAME_BUILD_ROOT` | `rsync --delete` into any caller-supplied path. |
| 86 | a late replay failure | the oracle trust root left half old, half new. |
| 89 | `--dry-run`, which never existed | voice ids rebuilt from `wide0`, reported as a verdict on another build. |
| 88 | a leftover `.diverge` | the freeze you just took, silently ungoverned. |
| 85 | the literal `60` | 2.03 s drift by voice 79, against a 3.35 s window. |
| 83 | an absent TSV row | meter, which CLAUDE.md §4 names explicitly. |
| 81 | SIGKILL / a second terminal | tracked `gen_donovan_patch.py`, left perturbed. |
| 87 | nothing reading the field | `gfx_layout3.toml`'s bank words, collision rule and scatter bounds. |
| 77 | one mistyped `.rpl` frame | `nScriptFrames + 2` wraps -> `calloc(1,4)` with a ~4 GB write past it. |

**Three were hiding a second defect** — #87's scatter bound had already
drifted (huitzil: 246 codes outside it, re-measured to `0x0AF5`), #85's
control was aimed at the one window where the drift is smallest, #81's
self-check compared against a snapshot it took itself. **Two were latent**
(#89, #51): real defects that currently produce right answers, which is
exactly why they needed gates and not rebuilds.

**THE SUITE IS GREEN.** `test_dualtrack` — the one red thing — is fixed and
is now a STRONGER gate (**#95**, closed). It was never a regression: it
asserted two things the project had *deliberately* made false, and **no
runner ran it**, so nobody saw it go red 11 days ago.

| its claim | what invalidated it |
|---|---|
| 11 legacy replays bit-identical stock↔WIDE | **14z-64 M3a de-substitution** — the two builds carry DIFFERENT ROSTERS by construction (`m5_stock` id 0x0F over Jedah; `m5_wide` id 0x13, Jedah restored), so every select-reaching replay must differ |
| attract diff = 57 bytes, 0 gameplay, at frame 4400 | **14z-86 M5 voice block** — the WIDE sound delta grew and now propagates |

Re-derived: section 1 asserts **bit-identical up to select entry** with the
onset frozen per replay (890 ×9, 3190 for the mid-attract one, none for
`06_test_mode`) — the same constants §4 v3 ratifies, which corroborates that
it is select entry. Section 3 attributes the **onset**, not a late frame:
3 bytes at 4267, all in the P1 effect-channel record pointer. New section 4
is the load-bearing one — **the same writer PC on both legs**, so it is DATA,
not control flow; a different writer set is what would mean the profile
leaked into engine flow.

**DECIDED 2026-08-17 (maintainer):** the re-scoped section 1 is ratified —
*"agreed this is why wide exists and now that it exists we must take it into
account."* Nothing about it is open. `CLAUDE.md`'s FBNeo clause was updated
the same day, since it names this gate as one of FBNeo's three guarantees
and said "dual-track inertness" with no scope.

**AND THE REAL LESSON, worth more than the fix:** `grep -rn test_dualtrack`
finds no runner — only docs and **CLAUDE.md:112, which names it as one of
FBNeo's three guarantees.** A rule was resting on a gate nobody executed.
That is GitHub #30, and it is now the highest-value open issue.

**Three new tickets, deliberately NOT folded in:** **#93**
`audit_qs_voice_batch`'s keyon failure (proven pre-existing — identical under
both input stagings), **#94** `audit_pyron_ring`'s dead `build/pyron22` (the
FOURTH reference-rot instance, so it asks for a standing check rather than a
fourth one-line repair), and **#95**, now CLOSED. #94 remains: audits pinned to
untracked build dirs with nothing to notice.

**#30 IS DONE.** There is now ONE pre-commit command:

    ROMDIR=... tests/run_all_static.sh        # PASS 88 / SKIP 0 / FAIL 0
                                              # (measured 2026-08-18; the count
                                              #  moves — read the runner, not this)

It counts PASS/SKIP/FAIL separately (#29 — a SKIP is not a pass) and names any
emulator-free gate that is in neither registry, so the orphan problem cannot
regrow. On its FIRST full run it found three gates stale for weeks
(`test_census_regions`, `test_voice_row_range`, `test_phasec_spaces` — all
fixed, all detailed in STATE 14z-94 (9)) and a fourth now filed as **#96**.

**(history) Start here next time: #96** — [14z-95: the named symptom is FIXED; two items remain, see the top] — `test_m2a_stage4_code`'s `06_test_mode`
divergence disappeared (expected 700, got none). Either a stale constant or
something live gone inert; name the mechanism before touching the number.
**RULED 2026-08-18 (maintainer), so this list has moved:** **#24 CLOSED**;
**#52 fixed and landed** (14z-95); **#27 ruled — ONE COMMAND**, a documented
procedure only if a single command cannot work; **#43 ruled — SPLIT**, land
the inert refactor now and ship the row movement at the next re-freeze.
Remaining maintainer-owned: **#57**. Architecture backlog:
#47/#48/#49/#50, #69, #71, #46, #93, #94. None blocks the re-freeze.
**#99 is PARKED (see the banner). The Phobos sfx thread is measured but
NOT closed** — the extra voices found are at the PRE-MATCH phase, not at the
end of the electrocute where the report puts them, and a `+0x382` poke
confound is open. Both are on the issue and in STATE 14z-95.

## (HISTORY, 14z-94) Where it stood then

| leg (40,620-frame arcade marathon, forced pick, sparse probe at `0x05ffb6`) | verdict |
|---|---|
| `pyron26` pre-fix (FROZEN) | **CRASH 15079** `vec3 PC 01afb6` — #92 |
| `pyron27` post-fix | **END 40620** |
| `hui41` pre-fix (FROZEN) | **CRASH 18337** `vec4 PC 0fb6e0` — #91 |
| `hui43` post-fix | **END 40620** |
| `m3b_merged8` + Huitzil (FROZEN) | **CRASH 8887** `vec4 PC 456930` — #91 |
| `m3b_merged9`, all three tenants | **END 40620** |

**MERGED GATE SET, all green on `m3b_merged9` (752 ops, `081e2e53`):**
`audit_merged_legacy` AUDIT-EXIT 0 (leg a 47/47 with 0 NOT-EVALUATED, leg b
6/6 guard-clean), `test_merged_render_content` PASS,
`audit_trap_parity` PASS, `audit_fg_parity` PASS,
`audit_select_bank_gates` PASS, `verify_gfx_build` + `check_tenant_hud` PASS
on all three tenants.

The probe fired on every leg, so it is armed rather than dead: 3 hits on the
three legs that ran to 40,620, and 2 on `hui41` — which crashed at 18337,
before the third firing. New builds `hui43` `da734d49` / `pyron27`
`e29cac23`, both UNREGISTERED and UNFROZEN; `hui41`/`pyron26` are untouched.

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
stage). Chosen on three measured grounds — ABARAYA is one of only four values
already reachable in every affected group (so no rung gains a stage it could
not already produce), it is not another character's venue in these ladders
(`0x14` is Pyron's, `0x16` Jedah's), and it is the shortest banner record in
the family at 7 glyph sprites. **DONE:** `huitzil.toml` + `pyron.toml` patched
via the data_port `fixes` key, gate green, crash gone on the marathon with a
live control; the merged op-count constant re-frozen (-1, attributed) and
every merged gate green. **REMAINING:** only the re-freeze itself — registry
rows for huitzil + pyron + merged, which is a STATE decision.

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

## (HISTORY, 14z-94) The open list as it stood then — SEE THE TOP FOR THE CURRENT ONE

### THE REQUALIFIED AUDIT BACKLOG (maintainer cleared `contested`, 2026-08-16)

Eleven findings from the 2026-08-15 adversarial review are now ACCEPTED.
Ordered by severity, and split by whether they can be started without a
ruling. The 21 still carrying `contested` are NOT in this list.

**~~NEEDS A RULING FIRST — 3 items~~ ALL THREE RULED 2026-08-18 (maintainer).
The rulings are inline below; nothing in this block is open.**

- ~~**#30 + #24 + #29 ARE ONE CLUSTER, not three tickets.**~~ **ALL THREE
  CLOSED** — #30 and #29 in 14z-94, **#24 closed 2026-08-17 (maintainer)**.
  `tests/run_all_static.sh` is the runner the cluster needed, and
  `run_battery_m2.sh` now tallies PASS/SKIP and refuses GREEN at any skip.
  The original analysis, kept because the eliminations stay valid: #29 (~28 gates
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
- **#27 — RULED 2026-08-18 (maintainer): ONE COMMAND.** *"It should be one
  command; the procedure should be considered only if a single command cannot
  work."* So rule 3's "reproduce from pristine inputs" is NOT satisfied by a
  documented procedure a human follows. `build_merged.sh` regenerates its own
  missing inputs — the three `build/*/extract` dirs and `build/wide0` — and
  keeps using existing ones when present so the common path stays fast. No
  ROM-derived byte gets tracked, so rule 7 is untouched.
  **The constraint to respect while implementing:** this direction unfreezes
  the same pinned dirs #26's track-mismatch guard protects, so regeneration
  must be CREATE-IF-ABSENT and never rebuild-over, and the regenerated extract
  must be proven byte-identical to the pinned one — otherwise the merged
  fingerprint moves and that is rule 6, not a build convenience.
- **#43 — RULED 2026-08-18 (maintainer): SPLIT IT, land the inert half now.**
  The ticket bundles two things with different risk, and only one of them is
  rule-6 territory:
  **(a) the refactor** — move the matcher into `find_equiv.py` with
  `hit_cap`/`allow_fallback`, delete `reconcile_batch.masked_search`, import
  it. With `allow_fallback=False` it must reproduce all 271 rows exactly, so
  ZERO built bytes move. Rule 6 does not reach a change that provably moves
  nothing, which is why a clean freeze is not a precondition for it.
  **(b) flipping the fallback on** — moves 3 rows (`0x028122`, `0x1e744e`,
  `0x0448a6`) and therefore built bytes. Rides the next re-freeze.
  Why (a) goes first rather than after: #91 was a missing reconciliation row
  that crashed the shipping build in extended play, every build ships planted
  tripwires standing in for unresolved rows (merged-m2 ~69), and #99 is a
  crash on a path no rig has executed — so if #99 is a tripwire fire, the
  canonical matcher is what names the row. Waiting is also circular: the
  freeze waits on the crash, and the tool that may diagnose the crash would
  wait on the freeze.
  **Honest condition on (a):** it is inert *if* the 271-row control holds. If
  reproducing them exactly turns out to need drifted behaviour not yet
  enumerated, that is a finding — stop and report, do not nudge rows to make
  the control green.
  **Lands regardless of timing:** `reconcile_batch.py:14` says
  `--allow-plausible` is "for experiment builds only" while
  `tools/build_merged.sh:41` hardcodes it, so plausible rows ship in the
  artifact that gets played.

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
- ~~Round-end flicker~~ **CLOSED 2026-08-18 (maintainer).** It was carried
  as "parked, needs the maintainer's recording"; the merged-m2 playtest
  did NOT observe it and the maintainer ruled it closed. Not carried
  forward. If it ever resurfaces the first question is which build and
  which emulator — the 14z-93 prediction that it would correlate with
  voice events rested on the `$FF8100`-is-a-voice reading, which 14z-94
  corrected to the ladder STAGE index, so that link does not follow.
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
- **BEYOND MiSTer (scope extension, maintainer 2026-08-18):** **GitHub
  #100**, the next-stage screen showing Donovan with a Victor name and a
  blank portrait. Closed WON'T FIX for now under the standing cosmetic
  ruling (cosmetic + single-player-only surfaces are nice-to-have) and
  re-scoped to after MiSTer. **The mechanism is already measured, so
  whoever picks it up starts from the fix, not the hunt:** one writer
  (`PRG:0x00A446`, `andi.w #$000F` at `0x00A442`) feeding `RAM:$FF8130`,
  and FOURTEEN readers — eight of which RE-FOLD, so widening the writer
  alone changes nothing. Full detail on the issue and in STATE 14z-95.

## Build / validate

(paths refreshed to the 14z-99 freeze generation at the post-freeze close —
the commands are operational, not historical, even though they sit below the
history marker)

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2

# the canary — safe as written since 14z-91
VERIFY_BASIS=16_xemu_2p tools/freeze_masked_basis.sh \
  tests/expected/vsavj/masked-v2 "$(cat tests/expected/donovan-m9/mask)" 16_xemu_2p

MAME_ROMPATH="$PWD/build/don_m9/rompath;$ROMDIR" tests/run_suite.sh vsavjw
tests/test_m3a_reproducible.sh                 # ~6 min, all five, hard on content
tests/audit_walker_ghost.sh                    # ~5 min — the mask assumption
tests/audit_walker_repoint.sh build/don_m9     # ~5 min — caller completeness
tests/test_obj_walker_relocation.sh build/don_m9   # seconds, ROM-free
tests/audit_legacy_pairings.sh                 # ~30 min — the coverage gate
tests/test_obj_record_walk.sh                  # seconds, ROM-free — the #75 gate
tools/build_merged.sh build/m3b_merged11       # ~1 min
```

## Rebuild recipes

```sh
KEY_SET=vsavj WIDE_ROMSET="$PWD/build/wide0/rompath/vsavjw.zip" \
  GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
  tools/build_donovan.sh 6 build/don_m9
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 ... build/hui45
TENANT_MANIFEST=build/manifest/pyron.toml   TENANT_CHAR=0x11 ... build/pyron29
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/m5_stock4
```
