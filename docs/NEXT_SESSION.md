# NEXT SESSION — orientation (rewritten at the 14z-126 close, 2026-08-31)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. NOTHING IS RED. NO BUILD CHANGED — the tree is still the
> ## M12 freeze (merged-m14 `6649523a`, `build/m3b_merged21`), FIELD-VERIFIED
> ## GREEN. Commits are LOCAL past the pushed `26255a9` — push at the
> ## maintainer's word; check `git status -sb`, not this line.**
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
> ## **ONE THING BEFORE ANY NEW WORK, waiting on the maintainer:**
> ## **THE FRAME-DATA-IN-A-PUBLIC-REPO RULING** — the maintainer proposed
> ## (2026-08-31) removing the public documents that carry per-move frame data
> ## and shipping regenerating tools instead; the assessment and the options are
> ## in STATE "Decisions pending" (recommendation: option (b), the class rule —
> ## every per-move ROM-derived table, ours AND the workbook's, becomes generator
> ## output under `../charpages/`; verdicts/mechanisms/hashes stay in-tree; the
> ## public HISTORY is accepted, not rewritten). Half a session once ruled.
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
