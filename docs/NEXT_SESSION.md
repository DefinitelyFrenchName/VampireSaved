# NEXT SESSION — orientation (rewritten at the 14z-187 + 14z-187b CLOSE, 2026-10-02)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line with one label per violated question
(never chained with the next `prepare`). Say so at the opener. Never spawn any agent at `max`.
`prepare` now runs the claim lint (#185 item 3): tie every every/only/none/all/the one to a check in its
sentence, or put it under NOT TESTED, or pass `--untied-ok "<why>"`.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-187 + 14z-187b close found and did is in
   its CLOSE row (STATE 14z-187).
1. **#195 — THE DISCRIMINATOR NEEDS A RULING BEFORE ANY BYTE MOVES.** Option A (two hooks) is ruled; the mark
   byte (`+0x293` / `+0x2C9`) and the tail site (`0x24D92`) are measured. Open: how the hit-time hook tells the
   seven remapped-from-0x51 records from the other class-0x44 records — the record's `+0x1D` is NOT spare (the hit
   test reads it), no single record byte separates them, and the generator substitutes only the tenant id into a
   thunk. Options on #195: a data-address placeholder in the generator; attacker id + class (the session's lean;
   measure first whether the attacker's id is reachable at `0x01868C` for a projectile hit); a box-coordinate
   signature (fragile).
2. **ERIS (the WSL2 box) — ITS GAPS BEFORE THE NEXT EMULATOR TIER.** `sudo apt install python3-pil
   python3-capstone` (asked, not yet done); the build directories it lacks (`m5_wide`, `donovan`, `donovan5`,
   `merged1`, `m3b_merged27`, `hui30`, `hui41`, `don_m5`, `m3b_merged26`); five failures not yet explained
   (`audit_type_writes`, `test_hitbox_encoding`, `test_select_wheel` segfault, `test_random_select_tenants` whose
   control run finds no ROMs, `audit_qs_voice_wav`'s 5,400 s timeout, which also left two MAME children running).
   ERIS's main clone is at `e3f0d7c2`; a second clone `~/vs201` carries the later commits by `git bundle`.
3. **#188 — ROUTE A'S TRACED TEST IS NOT FINISHED.** Every static gate was traced under `strace` on ERIS
   (`~/t188/st/`, at `e3f0d7c2`); the analysis (`~/t188/analyse_mp.py`) ran 3.5 h with one gate stuck in the
   predictor's per-read regex and was stopped. Restarted at the close (2026-10-02, 05:24 ERIS time) as `~/t188/analyse_capped.py`: each gate in its own process
   under a 600 s cap, one line per gate in `~/t188/capped.tsv` (TIMEOUT names the stuck gate). Next: read it; route A stays
   unwired until the test shows no miss (an early sample found one: `audit_mister_map_fit` reads two tracked files
   under `build/m3b_merged29/patch/` the predictor does not flag).
4. **#194 IS STAGED** (`build/manifest/staged/194_cosmo44.patch`) for the next freeze; M21 is frozen, not released.
5. **THE OPEN QUEUE:** #195 (above), #198 (forbid the record-differing P2 chains), #200 (Lightning Sword ES's
   pursuit flag at hit), #133 (the ERIS figure is on the issue; re-measure on a green tier), #187 (built; its
   close-loop figure is in this close's CLOSE row), #185 (items 1 and 2 done as #189/#190, item 4 carried by #187,
   item 5 a property of #190's gates, item 3 built — close it with #187), #196, #199. The full list is
   `docs/project/tickets.md`.
6. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- `tests/lua/rom_poke.lua` pokes PROGRAM-ROM bytes at boot, each verified through the program space; an own-value
  write always "verifies", so its inert control is a trace comparison, not the ok line.
- The POKES grammar takes ranges `F1-F2:addr:hex` (`tests/lua/pokes_spec.lua`, every instrument); build pins as
  ranges — Linux refuses one environment string over 128 KiB. `DUMPS`, `DSPEC`, `ANCHOR_SPEC` are still per frame.
- On Linux `/bin/sh` is dash (no `$((16#..))`), and the pinned MAME logs its ini lookups only with `-verbose`.
- `tools/audit_latch_readers.py` sees immediate stores now; its census of any offset is a starting list, never a
  proof of freeness — small offsets are displacements into other structures too; measure with `read_tap.lua`.
- `tools/demitri_split_sheet.sh` is the capture instrument for #192's Chaos Flare; name sheets by their event.
- The close's checks are in `build/agent187b/close/checks.tsv` (start the next close from it).

## WHAT CLOSED THIS SITTING (14z-187 + 14z-187b)

**#191** `not-ours` (mechanism corrected: vs2 lowered Demitri's records), **#192** `not-ours` (Chaos Flare's hold
node and fireball records), **#197** `done`, **#171** `done`, **#201** `done`, **#126** `declined` (the maintainer's
GitHub close), **#189** `done`, **#190** `done`. Built: #187's reader fix, #190 P3, #185 item 3, #201. Filed: #196-#201.
