# NEXT SESSION — orientation (rewritten at the 14z-194 CLOSE, 2026-10-07)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session <transcript id>`, `resolve` on ONE line with one label per
violated question, and only AFTER the work it names exists (14z-194 resolved run 718 before its work landed).
Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle and run independent
work there in parallel** — the maintainer's standing wish (14z-194: *"if and only if you don't need ERIS or
PILOT for the release, please put them to use"*).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** **merged-m23 is PUBLISHED** (Latest on GitHub, nine
   assets; M22 and M19 emptied). What the close found and did is in STATE 14z-194's CLOSE row.
1. **#237 FIRST — the staleness audit's whole-file registry dependency.** Every emulator gate declares
   `tests/ci_emulator.tsv`, so one row edit stales all 214. Two registry edits wait on it:
   `audit_release_linux_desktop`'s row (#226's scripted case, merged `dbaed3a0`; the proposed row is in that
   gate's commit message) and `audit_tenant_throw_geometry`'s description (it still names only the standard
   throws). Fix the audit (judge the registry per gate row), gate it with its control, then add the rows.
2. **#129 — PUT THE DECISION** (STATE 14z-194 row (3); facts in `docs/game/engine_internals.md` "The CPU AI
   action-script system"): behaviour A (Phobos's continuation-check guard: a private clone, 0 legacy bytes, at
   most 92 cycles a frame) and behaviour B (vs2's crouch-guard test in shared engine code: 30 legacy bytes, about
   80 cycles static estimate). Gameplay feel is the maintainer's ([VSP-10]); captures first, then the options
   through the rule-checker.
3. **THE NEXT VERSION** carries #124's map fix, name and portrait (approved, documented on #124: name records, relocated
   portrait tiles, vs2's pool rows — its two owed checks first: whether the select screen reads the tenant
   records' `+0x0A`/`+0x0E`, and a reader census of pool rows 0x10/0x11/0x13) and the release-tooling fixes
   already merged (#236, #238-#240, `5a5205c5`). A freeze, then a release.
4. **Open, scoped:** #118 (63 of 75 measured and homed in `atlas/ram.md`; 12 left, each naming the state it
   needs; the six scratch-script promotions proposed in the #118 worktree's `HOMING.md`), #229 (pursuits done for
   all 15; next families in `families.tsv` order: ground throws, then the rest), #241 (the derivation's bit-7
   flag on Zabel's pursuit records), #226 (a clean host remains; step 2 complete by the maintainer's own test),
   #228 (breakpoint instruments on the frame_done clock — deferred by the maintainer: *"well do these long
   tickets later"*).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- `ssh eris` lands in Windows `cmd`: it splits on `|` and mangles `\$`. Write scripts on the Mac, `scp` them to
  `C:\Users\chaton`, run `ssh eris 'wsl.exe -e bash /mnt/c/Users/chaton/<file>'`; `export ROMDIR=/home/koneko/roms`
  inside WSL (unexported, `tools/run_mame.sh` refuses every leg). `scp eris:` cannot reach WSL home paths: tar
  into `/mnt/c` first.
- `rulecheck.py record --session` takes the TRANSCRIPT id (`37644128` this sitting), not the session key.
- A commit message quoting "close #N" is refused by the hook even inside a quotation: reword.
- PILOT's desktop runs PipeWire with a null sink; `pw-record -P '{ stream.capture.sink=true }' --target auto_null`
  records the emulator; gnome-shell's event sounds share the sink, so judge the emulator's own stream.
- In zsh, `echo ===` fails (`=cmd` expansion).

## WHAT CLOSED THIS SITTING (14z-194)

**#214**, **#227**, **#234** (shipped in merged-m23), **#235** `done`. Filed: #237, #238, #239, #240, #241. Fixed for the
next version, open until it ships: #236, #238, #239, #240. merged-m23 PUBLISHED.
