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
> ## **(1) GitHub #114 — PREMISE REFUTED, SCOPE MEASURED, MASH OPEN
> ## (14z-127).** The 14z-126b "ours" leg was **JEDAH** — replay 48's
> ## substituted-wheel path on the separated WIDE wheel. Measured against
> ## native at four strengths, no mash, both tracks: **LP 3h/7d · MP 5h/9d ·
> ## HP 6h/10d · ES 9h/13d, ours EQUALS native in every cell**, victim held,
> ## identity asserted from `bases.tsv`. Gate
> ## `tests/test_don_immortal_native.sh` (native measured in-run, the Jedah
> ## artefact as its must-fire control).
> ## **THE FRAME-CADENCE GAP IS THE HOST ENGINE'S** — vanilla Victor,
> ## Demitri, Morrigan and Bishamon all drain `+0x5C` = 11 in 9 frames on
> ## vsav2 and 10 on vsavj. **RULING (maintainer, 2026-09-02): the engine,
> ## being vanilla vsav, takes precedence** — so assert hit COUNT and DAMAGE,
> ## never vsav2's frame numbers. Frozen as §4 of the gate.
> ## **THE MASH ARC — OPENED 14z-127, THE RIG DESIGN IS NOW EVIDENCE-BASED.**
> ## Mash extension is multi-level by rate (maintainer: at least two extra
> ## levels). **DO NOT measure it by mash RATE: that is confounded** — presses
> ## fire at fixed absolute frames while our move runs on the slower host
> ## clock, so ours absorbs MORE presses for the same script and the legs are
> ## never given equal input. It produced non-monotonic cells (MP at the
> ## SLOWEST rate reading FEWER hits than no-mash), which no mechanic does.
> ## **THE INDEPENDENT VARIABLE IS PRESSES CONSUMED DURING THE MOVE.**
> ## **WHAT IS ALREADY MEASURED (14z-127, data on disk):**
> ## `RAM:$FF840A` = P1 `+0x0A`, the ATTACK ID (`ram.md`:135), climbs once per
> ## consumed press — a usable proxy for presses-delivered-into-the-move.
> ## Against it: **native looks CAPPED — HP stays 8 hits across attack-ids
> ## 8→21, ES stays 11 across 8→27 — while ours reaches 10 (HP, id 23) and 13
> ## (ES, id 27).** A cap difference is the live hypothesis; it is NOT
> ## established, because the legs never received equal press counts.
> ## **RULED OUT, so it is not re-derived:** `+0x12e` is not the counter (0
> ## with no mash, saturates at 3 whenever mashing happens at all, while hits
> ## range 3..13). The other press-frame-correlated bytes found by a whole
> ## work-RAM sweep are input mirrors (`$FF8058` and friends).
> ## **THE ORDER THAT MATTERS:** find/confirm the counter FIRST, then build the
> ## phase-anchored rig around it, then assert native vs ours on the
> ## press→level curve. Building the rig first means guessing what to anchor
> ## to, which is how the rate table came out non-monotonic.
> ## **THE SAME RIG UNBLOCKS THE CROSS-REGION CONTROL:** `vsav`'s match starts
> ## ~200+ frames after `vsavj`'s, so an absolute-frame replay lands in the
> ## round intro (both sets DO place P1 at x=552 at round start and load the
> ## same record — consistent with the maintainer's rule that regional
> ## variants have no mechanical differences, but far short of testing it).
> ##
> ## **THE CLASS TO CARRY FORWARD:** a tenant replay is a claim about the
> ## build it was authored for ([VSP-156]); **a confound check on POSITIONS
> ## does not establish IDENTITY**; and **a duration in VIDEO FRAMES is not
> ## comparable between the sibling games** — counts, damage and engine ticks
> ## are. **32 replays carry the substituted-wheel path.**
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
