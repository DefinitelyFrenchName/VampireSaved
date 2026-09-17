# NEXT SESSION — orientation (rewritten at the 14z-162 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SESSIONS ACT ON GITHUB AS `mechanyaa-ai` SINCE 14z-162 — an event, comment, commit or push by `DefinitelyFrenchName` IS the maintainer's, one by `mechanyaa-ai` is a session's; never attribute a GitHub state change to the maintainer without their words. If `gh auth status` shows any other account, stop and say so. A commit message must never put close/fix/resolve directly before `#N` (the hook and `test_commit_subject` refuse it; the shape closed #151 twice and was then recorded as the maintainer's act — the 14z-162 breach, STATE 14z-162 (1)).

## THE STATIC TIER RUNS BY CADENCE SINCE 14z-162 (#148 closed): `tests/run_all_static.sh` is the SESSION run (17 gates deferred BY NAME unless a path they depend on changed; ~5-8 min); a freeze runs `--cadence freeze`, a release `--cadence release`, on the commit they build from. The close is the session cadence with every control executed, then the push. `tests/ci_cadence.tsv` is the registry; a new listing is a reviewed event.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs (`don_m23`,
`hui58`, `pyron42`, `m3b_merged28`, `m5_stock18`, `don_stage4_m19`) are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148, then #152, then everything else — #148 is DONE)

- **#152 FIRST — the adversarial rule-checker at every decision point.** The 14z-162
  breach is its case study: a session inferred a maintainer decision from a timestamp
  and published it; #152 is redundancy on rule APPLICATION. Read `DECISIONS_HISTORY.md`
  "Ruled 2026-09-17 (14z-162)" entries and the project gotcha "A COMMIT SUBJECT THAT
  NAMES AN ISSUE AFTER A CLOSING KEYWORD" before designing it.
- **Measure the second cut** at this session's first tier run: a session run with
  nothing triggered was expected ~320 s (630 s measured before the second cut, 1,224 s
  before cadence); record the figure on the lever-B ticket / HANDOFF.
- **Lever B — scratch-clone tier runs** — is its own ticket (filed 14z-162; the number
  is in `docs/project/tickets.md`): integrity and traceability at freeze/release, as
  bbh/BBX do; session cadence stays on the working tree.
- **#136 — THE FULL RE-EXAMINATION CONTINUES.** The 13 DIVERGES rows are consolidated
  on #136 (comment 2026-09-17) with each move's first divergent event and family:
  Phobos — Plasma Trap (2, 9), Reflect Wall guard-cancels (5, 6, 8), Ray of Doom (4);
  Pyron 3, 4; Donovan 2, 3, 4, 6, 7 (3 and 4 fall on the maintainer's own rulings).
  Each family a root-cause with a capture first ([VSP-136]) and its own ticket. The
  apparatus is validated (#151 closed by ruling 2026-09-17).
- **#150** (the freeze ritual's silent-green modes) is filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A keyword count over a tier log is not a verdict**: `grep -c 'FAIL|SKIP'` counts the
   summary line `PASS 157 SKIP 0 FAIL 0`; read the tally.
2. **The closing-keyword lint trips on prose that DESCRIBES the mechanism** ("closed #151"
   in a commit body) — break the adjacency, or the guard refuses your own fix.
3. **A ticket's `sessions` column needs a STATE record for the key**: a mid-session
   correction cannot claim its own `14z-N` until the group exists at the close.
4. **A hook is advisory** (`--no-verify`, a fresh clone): the gate is the rule.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
