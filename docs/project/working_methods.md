# WORKING METHODS — retraction, bug archaeology, field reports, the regression runner and when to commit, in full

The full text of CLAUDE.md rules on how work is done, moved here verbatim on 2026-10-15 (#282 item D, the
maintainer: *"Rule + pointer (Recommended)"*). CLAUDE.md keeps each rule's `**[VSP-N]**` anchor and its statement;
this file holds its reasons, history and steps.

## [VSP-20] Field reports are recordings

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-20], unbolded.)*

- [VSP-20] **FIELD REPORTS ARE RECORDINGS (maintainer-ruled 2026-08-27, 14z-111).**
  Every reproducible crash or misbehaviour a human can produce — on the
  board or on MAME — is captured FIRST as a hand-played MAME recording
  (the commands: HANDOFF, [VSP-119]), BEFORE any mechanism theory, and
  tracked under `tests/inp/<name>/` (force-added,
  with a one-line `NOTE`). **NAMING: `<what>-<freeze set>-NN`** — the
  freeze the recording was PLAYED on, never the mark or the session
  (`crash-merged-m8-01`; a mark can cover two freezes and a session two
  freezes). **CLEANUP:** the `~/.cache/vampire-saved/inp/<name>/` copy is
  deleted once tracked; a recording neither tracked nor named by any gate or
  doc (grep first) is deleted, not kept. `tools/run_inp_guarded.sh` plays a
  recording back with a write tap on the game's OWN exception-code store
  (`RAM:$FF0000`) — no debugger, faithful playback — and yields the vector,
  fault PC, registers and stack. **`tests/test_inp_corpus.sh`
  replays EVERY tracked recording on the current merged build at every
  freeze and fails on the first exception** (a captured-but-unfixed defect is
  declared by a `DEFECT` file so the capture cannot rot). The cost that made
  this law: 14z-109..111 spent three sessions and two shipped fixes on a
  rig-derived mechanism that was never the field crash; the first recording
  found the real one (#99) in an evening — win-fast rigs never give a CPU
  opponent's AI time to reach its rarer scripts.

## The auto-detecting regression runner

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D.)*

- **Auto-detecting regression runner:** the suite runner fingerprints the
  build under test (which features/patches are present) and selects
  expectations accordingly, so one command validates any build variant
  (SMS `test_regression.lua` pattern). Engine-invariant "rule locks" for
  vanilla behavior run on every build. The index of every gate is
  `docs/project/gate_index.md` (generated); the pre-commit command is
  `tests/run_all_static.sh` (HANDOFF "How to test").

## [VSP-13] Retraction discipline

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-13], unbolded.)*

- [VSP-13] **RETRACTION DISCIPLINE (standing order, 14z-71): when a claim changes,
  GREP FOR THE CLAIM — not for the files you remember writing it in.**
  A finding does not live in one place. It propagates into section
  HEADERS, summary lines, registry rows, gate comments, the GOTCHAS index
  and `NEXT_SESSION`, and the copies outlive the correction. Fixing "where
  I remember writing it" is how a document ends up asserting the opposite
  of the subsection directly beneath it (measured twice in one session:
  `engine_internals.md` carried "the 214+P explosion is NOT a tile-inventory
  defect" as a HEADER above the subsection proving it was, and a corrected
  effect-family finding survived in five other places). The procedure, in
  order:
  1. `grep -rn "<the old claim>" docs HANDOFF.md STATE.md STATE_HISTORY.md DECISIONS_HISTORY.md tests build/manifest`
     — search the assertion's WORDING, and its paraphrases, across the repo.
     The archives are in the list on purpose: archived entries are not
     rewritten, but a claim that ONLY survives there must still be found so
     its live carriers can be traced. (DECISIONS_HISTORY.md: resolved
     decisions move there verbatim from STATE.md once they stop shaping
     active work.)
  2. Fix the **HEADER and the summary line** first. A skimmer reads those;
     an appended "actually, it turned out…" subsection does not reach them.
  3. Re-grep afterwards and show the empty result. The pass is not done
     because it feels done.
  4. Keep the superseded analysis, marked RESOLVED/RETRACTED with what
     replaced it — the eliminations usually stay valid even when the
     conclusion does not. **Status headers track reality; historical
     entries are not rewritten.**
  A claim that cannot be found cannot be corrected, and a stale claim in a
  header is worse than no documentation: it is confidently wrong, and it
  is what a future session will act on.

## [VSP-14] Bug archaeology first

*(Moved verbatim from CLAUDE.md 2026-10-15, #282 item D. Its anchor marker stays on CLAUDE.md's statement of the rule, so here the marker reads [VSP-14], unbolded.)*

- [VSP-14] **BUG ARCHAEOLOGY FIRST (standing order, 14z-75): before fixing a bug,
  check whether it has already been fixed once — and if you are unsure, ASK
  THE MAINTAINER.** They were there and will usually remember.
  1. `git log --oneline --grep="<symptom>"`, `git log -S "<manifest row>"`,
     and `grep STATE_HISTORY.md` for the symptom's wording
     BEFORE forming a theory. A defect the maintainer reports may be a
     REGRESSION of something already solved, and the old fix (or its
     withdrawal) is the fastest route to the mechanism.
  2. Find the build where it was last known good and **diff it against its
     predecessor.** The delta is the answer, and it is cheap.
  3. **If the record is ambiguous about whether it was ever fixed, ask before
     measuring.** One sentence from the maintainer beats an afternoon of
     rigs, and a wrong assumption here is expensive in both directions:
     re-fixing something already fixed, or declaring "never fixed" about
     something that was.
  Paid for in 14z-75: a "never fixed" conclusion published from rigs that
  never fired the move, corrected by the maintainer who remembered the fix
  working; the archaeology took two commands, the wrong conclusion took
  hours and reintroduced the crash.

## When to commit

Ruled 2026-10-17 (14z-203), the maintainer: *"Adopt as proposed (Recommended)"* (`DECISIONS_HISTORY.md` "Ruled
2026-10-17 (14z-203) — when to commit: …"). Since #290 every commit needs a strict GREEN run of the whole static tier on
the exact staged tree (`tools/git-hooks/green_guard.py`). With `--confirm` that tier re-runs only the gates a change
reaches, and on 2026-10-16/17 it still took 12 to 40 minutes on an awake machine. Eight tiers ran for four commits, and
four of the eight were red from a slip the gates below catch.

1. **Commit only at a boundary that needs a commit:**
   - a ticket closure: its closing comment cites the commit;
   - a freeze or a release: the tag sits on a commit;
   - work handed to PILOT or ERIS: a bundle of a commit;
   - the close (`docs/project/session_close.md`).

   Everything else stays in the working tree and rides the next boundary's one tier. The guard checks only at commit,
   so uncommitted work costs no tier.
2. **Before every tier, regenerate the generated files, then run the bookkeeping gates the change touches:**
   - a gate added or removed, or its header or `# MUST-FIRE:` lines changed: `test_must_fire_census`,
     `test_gate_descriptions`, `test_gate_coverage_current`, `test_gate_index_current`;
   - a file under `build/manifest/`: `test_rule5_census`;
   - `docs/project/tickets.tsv`, or an issue closed or filed: `test_tickets`;
   - a rule-checker run recorded: `test_rule_checker`, with every run directory the ledger names staged;
   - `STATE.md` or `docs/NEXT_SESSION.md`: `test_state_open_lists`, `test_live_budget`;
   - a gate or tool changed: that gate, and the gates whose reach includes that tool, run directly;
   - a file added to, renamed in or removed from `tests/expected/`: `test_expectation_provenance` (its row in
     `tests/expected/PROVENANCE.md`);
   - any live document, manifest, gate script or tool changed (the carriers `tools/gen_annotations.py` reads, so nearly
     every change): `test_annotations_current`.

   Each of the four reds of 2026-10-16/17 was one of these gates, and so was each of the three reds of the 14z-204
   close's first tier (2026-10-18: `test_expectation_provenance`, `test_gate_coverage_current`,
   `test_annotations_current`, about 30 minutes of re-run against about 3 seconds of gates). The tier then confirms;
   it should not discover.
3. **The tier's base** is the newest run that executed its controls. A confirm based on a run made without controls
   re-runs every gate whose controls that run did not execute.

