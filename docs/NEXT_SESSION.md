# NEXT SESSION — orientation (rewritten at the 14z-129 CLOSE, 2026-09-03)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

> ## **START HERE. THE NEXT TASK IS THE M13 REGISTRATION, AND IT IS THE ONLY
> ## THING LEFT.** Everything the 14z-128 sweep left open is closed: five gates
> ## triaged red -> green, one deleted on measured ground, both pending
> ## decisions ruled and implemented. **No build byte has moved since 14z-127.**
> ##
> ## THE SESSION WAS DELIBERATELY CLOSED BEFORE STARTING M13 — a freeze is a
> ## RITUAL and a half-finished one is the worst state to be in (14z-126b spent
> ## a session on three tags a skipped step had left unwritten). M13 needs a
> ## full tank: the ~5 h suite, five tracks, registry rows, tags, and a docs
> ## sweep.
> ##
> ## # M13, IN ORDER — AND STEP 1 IS ALREADY MEASURED
> ##
> ## **(1) THE `gap_be27a` FOLD-IN IS NOT A MANIFEST TIDY. PROBED 14z-129 so
> ## you do not meet it cold** (full detail: STATE "Decisions pending"):
> ##   * `kind = "data_ptr"` + `stride = 0x80` **DOES NOT BUILD** — a `data_ptr`
> ##     row also needs `region`, and `extract_char.py:1291` dies
> ##     `KeyError: 'region'`. `region = "auto"` is the right value.
> ##   * With it: ops 342 -> 343 and the builder catches
> ##     `OP OVERLAP at 0x0BE2C6` — longword row **0x13, DONOVAN's slot** —
> ##     written by BOTH the corrected table and `donovan.toml`'s
> ##     `throw_victim_keyframes` (`slot_ptr_table = 0xBE27A`, :831). The two
> ##     values disagree: `0x003fbda2` vs `0x004010e0`.
> ##   * **So it needs an explicit OWNERSHIP rule**, and which pointer his
> ##     capture keyframes use may be a [VSP-10] call rather than a generator
> ##     detail. Settle that BEFORE the freeze suite runs, not five hours in.
> ##   * The tree is UNCHANGED — bank_map.toml was reverted and verified
> ##     byte-identical.
> ##
> ## **(2) THEN REGISTER.** `don_m19` / `hui53` / `pyron37` / `m5_stock14` /
> ## `m3b_merged22` (boot title SAVED, built 14z-127, on disk, NOT registered):
> ## `run_suite.sh --freeze` per track (~5 h), registry rows, `freeze/*` tags,
> ## HANDOFF's build-registry row and "Current WIDE builds", the shared-writes
> ## re-point (three `boot_title_saved_*` rows per tenant, reviewed 14z-127)
> ## plus whatever `gap_be27a` moves, and a charmap re-freeze (charmap_gen reads
> ## bank_map, and those pages are hash-locked).
> ## **IT CLEARS THE LAST TWO REDS**: `test_m2b_stage6` and `test_phasec_image`
> ## §1 fail for ONE reason — M13 is not in `registry.tsv`, so the fingerprint
> ## dispatch finds no expectation set. (`test_phasec_image` §4 is a SEPARATE
> ## stale premise that registration does NOT fix — it zeroes CPU:$400010
> ## expecting the Phase-C sound table, but wide_ext's first placement is now
> ## Donovan's AI script block, which `12_donovan_vs_cpu` never reads because
> ## Donovan is the PLAYER there.)
> ##
> ## **(3) NO RELEASE** — still deliberately held back.
> ##
> ## # THE STATE OF THE SUITE
> ##
> ## Strict static **65/0/0 portable** (run it with ROMDIR for the static tier).
> ## Emulator-tier registry **163 rows** (was 164; `audit_type_dispatch_range`
> ## dropped), anti-orphan clean both ways. All five triaged gates verified
> ## green by running them, not by reading them.
> ##
> ## # THE LAW THIS SESSION ADDED — READ IT BEFORE TOUCHING ANY INSTRUMENT
> ##
> ## [VSP-166] (`docs/project/gotchas.md`, distilled into the
> ## `vampire-saved-port` skill): re-targeting an instrument from the build's
> ## own metadata is writing the test from the algorithm. Before re-pointing a
> ## probe, state what the new expectation is ANCHORED to and check the anchor
> ## sits OUTSIDE the artifact under test. The maintainer's words: *"we don't
> ## write that what we coded is indeed what we coded."*
> ## It caught a re-target of mine before it was built, and the measurement
> ## then proved it would have been a permanent false green (D0 = 0 at the site
> ## I proposed, 8,990 times). **NOT promoted into CLAUDE.md — the law is not
> ## edited unprompted; if it belongs beside [VSP-19] in §4 that is the
> ## maintainer's call, and it is still open.**
> ##
> ## # OPERATIONAL, each paid for this session
> ##
> ## * **`GUARD_DEBUG=0` INSTALLS NO EXCEPTION BREAKPOINTS.** A crash is
> ##   INVISIBLE in cheap mode — both legs of an A/B reported END clean while
> ##   the twin was faulting. Name `GUARD_DEBUG=1` for any crash question.
> ## * **Name `MAME_BIN` for a `vsavjw` run.** A stock binary exits "Unknown
> ##   system" before the machine starts, and the guard reports that as a trip —
> ##   i.e. as a crash in YOUR build. `force_pick_probe.sh` now refuses it.
> ## * **Poll the process, never the notification.** A `nohup`'d gate returns
> ##   immediately and the completion notice fires for the WRAPPER; `pgrep` is
> ##   the truth. Prefer `run_in_background` on the gate itself.
> ## * **The hit-class map lives in the OPCODE view.** Reading it from the data
> ##   view gives `map[64] = 0xf4` and a confident wrong answer; the opcode view
> ##   gives `0x4e`, which is what 14z-82b measured.
> ## * A gate's corpus is an EXPLICIT TABLE, not a glob — a new rig is invisible
> ##   to it until listed, however true its verdict line sounds.
> ##
> ## **IF A DOC IS TOUCHED:** census `--check` + `checkdocshape --no-pending` +
> ## checkdocs + checkskills + `gen_annotations --check` + `gen_gate_index
> ## --check` + `gen_gotchas_index --check` + `doc_anchor_census --check`,
> ## exit statuses captured directly. Regenerate the GENERATED indexes in the
> ## commit that changes what they index, and AFTER the prose.
