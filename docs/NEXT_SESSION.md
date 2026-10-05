# NEXT SESSION — orientation (rewritten at the 14z-191 CLOSE, 2026-10-05)

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
A recommendation leans only on the maintainer's OWN words. When no ruling covers it, ask plainly instead.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle and run independent
work there in parallel.**

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-191 close found and did is in its
   CLOSE row (STATE 14z-191 row (12)).
1. **#222 — TO BUILD: Phobos's air dash takes vs2's minimum height (the maintainer's ruling)** (STATE 14z-191 rows (8), (11);
   `DECISIONS_HISTORY.md`, the 14z-191 report's rulings). vs2's mask at the air-dash
   site carries bit `0x10` (ours `PRG:0x022AF2` `$28102810`, vs2 `$28112810`) and vs2's height row `0x10` is
   `0x0018` (ours 0). Before building: whether any legacy fighter carries id `0x10` on our builds (the mask bit
   would reach it), the superset invariant, and which manifest owns the row. `tests/audit_air_dash_height.sh`
   flips from `--expect gap` to `--expect same` in the commit that lands it; ships at the next freeze.
2. **#223 — TO BUILD WITH #222: the landing sounds swap to match vs2** (the maintainer, after the samples:
   *"#223 I confirm the sound effects should be swapped to match VS2"*; `DECISIONS_HISTORY.md` "Ruled 2026-10-05
   (14z-191) — #223"): vs2's mask high half (bit `0x10` set, `0x13` clear) at ours `PRG:0x00395E` and `0x003B36`.
   Check first whether any legacy fighter carries id `0x13` on our builds (vsavj's bit was Victor's mirror).
   `tests/audit_landing_sound.sh` flips in the commit that lands it.
3. **#217 — A PACKET PER FORK, IN THE TOOL** (the maintainer, after the close: *"smaller packetes per fork makes sense
   only pragramatically to me, not as just a rule which is inherently prone to slippage"*; `DECISIONS_HISTORY.md` "Ruled
   2026-10-05 (14z-191, after the close) — #217"): a `tools/rulecheck.py` change — a merge packet cites each fork's run,
   and the tool refuses a cited run that is not OK or resolved, or whose staged artifacts changed since — implemented
   and tested (`tests/test_rule_checker.sh`, with controls) when a session takes it up.
4. **#226 — THE LINUX RELEASE AS A PLAYER GETS IT:** steps 1 and 4 pass headless on PILOT and ERIS WSL2 (STATE
   14z-191 row (9)); left: step 2 (a desktop session — the maintainer), step 3 (the `-recipe` asset built from
   `EMULATOR.md` on a clean host), the scripted headless case under `tests/`. Whether the parked ticket for the
   dedicated server's Linux binaries is now answered by PILOT is a question for the maintainer.
5. **#214 and #227 ship with the next release** (#214: the MiSTer README's emulator claims, fixed in the generator;
   #227: a MAME README note that the four "clone of nonexistent driver megaman" lines are harmless).
6. **#216** — Lei-Lei 6HP and the other #117 gaps against the Japanese community wiki (the maintainer: *"let's keep it
   for next session"*).
7. **Smaller open tickets:** #210 (the pre-push hook's sample command lacks `--session`), #211 (`--stale` selecting 0
   gates prints GREEN and becomes the run of record), #213 (`dispatch_census.lua`'s input clock under breakpoints).
8. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- `tools/homes_tracked.py "<row>" [out]` / `--newest [out]`: the second word is an OUTPUT path — run as
  `--newest STATE.md` it overwrote STATE.md (it now refuses its state file or any tracked file).
- A gate that echoes a sub-tool's per-item lines can carry a verdict word (`SKIP  (b) ...`) the static runner's
  classifier reads as the gate's own: echo the sub-tool's verdict line only.
- vsavj `0x027B80` is the minimum AIR-DASH height (every caller enters seq `0x14`); `+0x113` is the air-dash latch
  (P1's block is `$FF8400`: `+0x113` is `$FF8513`, not `$FF8113` — a first rig traced the wrong address).
- A read tap on `+0x382` with `RPCS` set to a site's own read PC lists every frame an engine site runs, per game.
- PILOT and ERIS have no `xdelta3` (package releases on the Mac); PILOT has no password-less sudo.
- `tools/naming_pair_sheet.sh` labels must not contain `:`; it takes `RIG_DIR` for a rig outside the corpus.
- `tools/trace_static_reads.py all` on PILOT: about 7 minutes for 203 gates at 6 jobs.
- An edit to `tools/applier/*.mjs`, a comment too, makes every published `apply_release.html` stale.

## WHAT CLOSED THIS SITTING (14z-191)

**#188**, **#206**, **#215**, **#218**, **#219**, **#221**, **#224**, **#225** `done`. Filed: #226, #227. Measured in
play: #222 (air dash at height 21), #223 (the landing sound, by ear). PILOT's Linux records adopted; ERIS's clone reset.
