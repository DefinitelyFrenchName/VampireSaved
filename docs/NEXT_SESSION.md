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
