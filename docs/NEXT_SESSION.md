# NEXT SESSION — orientation (rewritten at the 14z-126b CLOSE (2), 2026-09-01)

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
> ## **(2) #112's ONE REMAINING QUESTION — and it is now a SMALL one.** The
> ## premise is REFUTED: a tenant object does NOT run a vanilla sequence (see
> ## STATE 14z-126b addendum (2) for the three independent legs). The black
> ## foot is FOUND, reproducible and characterised: input `41236+MK` at
> ## **f14307** of `tests/inp/pod-black-m14-01`, rendering at **f14370-14375**,
> ## drawing `bbe5`/`bbea` at pal 05 where every clean instance draws
> ## `0xe768-0xe796`. **The open question is why THAT instance selects
> ## `0xbbxx` when nine earlier ones in the same fight did not.** Next step: a
> ## WRITE tap on the record behind the f14370 OBJ entry (read taps never fire,
> ## [CPE-14]). **Do NOT reach for `effect_map` membership as the answer** —
> ## `0xbbe5`, `0xbbea` AND the clean `0xe768` are all absent from it, so it
> ## does not discriminate. Cosmetic and maintainer-accepted, so this is
> ## knowledge work, not a fix.
> ##
> ## **(3) THE #113 WHITE-FRAME RESEARCH TOPIC — NEW, opened by the
> ## maintainer 2026-09-01, EXPLICITLY SEQUENCED AFTER (2).** #113 itself is
> ## CLOSED (the behaviour is vanilla, board-confirmed) — this is KNOWLEDGE
> ## work on vanilla, not a fix, and nothing may change a legacy frame. TWO
> ## questions: the MECHANISM (palette RAM zeroed vs a CPS-B layer/priority
> ## register at the white frame) and, the maintainer's actual curiosity, the
> ## REASON Capcom's engine does it at a down at all. The framebuffer half is
> ## already measured and gated (`test_down_flash_vanilla.sh`); the
> ## palette/register half never was, and a framebuffer hash CANNOT separate
> ## the two — so the precondition is a palette-RAM dump or CPS-B register
> ## read AT the white frame (write tap or frame-anchored dump; read taps
> ## never fire, [CPE-14]). Start from STATE's #113 entry and
> ## `inferred_claims` row 11; do NOT re-derive the eliminations.
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
