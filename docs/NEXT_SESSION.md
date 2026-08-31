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
> ## **WHAT TO DO NEXT — the maintainer's call between three:**
> ## (a) **FINISH THE CROSS-CHECK'S OPEN HALVES** (all named on the page):
> ## arbitrate the residual ~4% outliers in-emulator (`field_trace`, per-frame
> ## hitbox state, ours re-measured FIRST); derive dealt damage through the
> ## [VSE-40] scaler so `red damage` becomes comparable at all; then the
> ## specials/supers/throws, each needing its own vsavj naming rig — that is
> ## the bulk of the workbook's 730 rows.
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
