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
