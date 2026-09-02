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
