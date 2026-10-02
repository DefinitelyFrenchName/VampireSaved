# NEXT SESSION — orientation (rewritten at the 14z-188 CLOSE, 2026-10-02)

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
A recommendation leans only on the maintainer's OWN words: a DECISIONS_HISTORY "What it means" paragraph is the
recorder's gloss (rule-checker run 2026-10-02-561 Q5). When no ruling covers it, ask plainly instead.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the 14z-188 close found and did is in its
   CLOSE row (STATE 14z-188).
1. **THE NEXT FREEZE APPLIES TWO STAGED PATCHES, IN ORDER:** `build/manifest/staged/194_cosmo44.patch`, then
   `195_pursuit_mark.patch` (#194 and #195). Rebuild every track, run `tests/audit_pursuit_flag.sh` (it reads
   the hooks from the build and turns over to equality by itself), re-freeze what the hooks move, and delete
   both files in the freeze commit. The solo tracks were not built with #195.
2. **#188 IS WIRED; USE IT.** After a red static tier, fix, then run `tests/run_all_static.sh --strict
   --confirm <results.tsv>`, where the red run's `results.tsv` is named on its last lines. It re-runs the
   failed, absent and STALE gates and CARRIES the rest. Measure what it saves at the next close. #188 stays
   open until then.
3. **#196 — THE FALLBACK INVENTORY:** FALLBACK_LINE
4. **#133 IS MEASURED ON A GREEN TIER** (STATE 14z-188 row 10: mame lane 7.13× at `--jobs 12`, bounded by
   `audit_guard_corpus`). Put the close or a follow-up to the maintainer.
5. **#202** (the keep-tenant thunk's possible 1P repeat): no rig yet; a 1P arcade run as a tenant past a tenant
   CPU opponent is the repro to write.
6. **SHELVED BY THE MAINTAINER:** the measurer/reader frontmatter change to Sonnet 5.5 at `xhigh`.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- `+0x382` is the character id. On a 1P CPU flow, the arcade ladder writes the CPU side's NEXT opponent there
  BEFORE it loads, over any forced pick. Identify a loaded fighter by `+0x60` ([VSE-62]).
- Build POKES pins as RANGES (`F1-F2:addr:hex`). A per-frame list over a long rig passes Linux's 128 KiB
  environment cap, and the legs go VOID on ERIS only.
- On Linux, MAME can segfault at TEARDOWN after a complete log. Judge a run by its END line or its dumps,
  never MAME's exit code ([MFI-12]).
- ERIS: the FBNeo reference belongs at `~/.cache/vampire-saved/fbneo_ref` (now a link there). Ship commits
  with a git bundle through the `bash -l -s` heredoc; `cat > ~/x` over a bare `ssh eris` lands in Windows
  `cmd` and does nothing.
- A ruled form is built as ruled. A "better" form found while building is a question, asked before any byte
  moves (docs/project/gotchas.md).

## WHAT CLOSED THIS SITTING (14z-188)

**#198** `invalid`, **#199** `done`, **#200** `invalid`, **#187** `done`, **#185** `done`. Staged: **#195** (on
top of #194). Filed: **#202**. Wired: **#188** route A. Retracted: 14z-87's "voice-class borrow".
