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
> ## **(1) GitHub #114 — 421+P DOES NOT REPRODUCE NATIVE. THE LIVE THREAD.**
> ## MEASURED on both games with the gate's own rig: native vsav2 lands **6
> ## hits / 10 damage and HOLDS the victim at x=728** to f2685; ours lands
> ## **3 hits / 11 damage and pushes it 728 → 852**, ending f2640. Positions
> ## are byte-identical until contact, so there is NO confound. **Our reaction
> ## does not hold the victim** — this is not hit-count tuning. NEXT: why, at
> ## the reaction/pushback path (`0x2783C[record +0xC]`, `+0x50`/`+0x144`),
> ## then mizuumi's Donovan page as a third opinion. **THE GATE IS GREEN AND
> ## CANNOT SEE IT** (all legs `vsavj`; window starts f2630 while our first
> ## hit is f2627, so it sums 7 of the true 11; bounds one-sided). Tightening
> ## it turns the tree RED and halts work ([VSP-7]) — MAINTAINER'S CALL, not
> ## Claude's. Full analysis and resources on the issue.
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
> ## **(6) #112 fix option (B)** — "the effect owns its palette", using the
> ## owner branch the port already ships (`PRG:0x3FFAF0`). Needs half a session
> ## first: is there a FREE PALETTE ROW, and do pool objects carry
> ## `+0x30`/`+0x382`/`+0x3AE`/`+0x18B`? (C) do-nothing is agreed for now.
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
