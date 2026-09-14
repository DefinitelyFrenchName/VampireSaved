# NEXT SESSION — orientation (rewritten at the 14z-154 CLOSE, 2026-09-14)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## AN OPEN LIST NOW HOLDS ONLY WHAT IS OPEN: EVERY BUG, COSMETIC ITEM AND EVOLUTION IS A TICKET, STATE.md IS 55 KB, AND THE STATIC TIER'S CONTROLS RUN AT THE CLOSE. NO SHIPPED ROM BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state.

**THE NEW SHAPE:**

- **Tickets** (CLAUDE.md [VSP-182]). The LIST is `docs/project/tickets.tsv` (its
  header is the spec; `docs/project/tickets.md` is the rendered page), the STORY is
  the GitHub issue, the FACTS are the subject docs. Every ticket answers four
  questions locally — repro, decided, learned, wrong — and learned/wrong link LIVE
  docs only. A new ticket: the issue first, then `python3 tools/tickets.py refresh`,
  then its row. Gate `tests/test_tickets.sh`.
- **STATE.md** (CLAUDE.md [VSP-17]). The newest session groups plus four standing
  sections: Standing rulings (one line each, the entry in DECISIONS_HISTORY),
  STANDING PRINCIPLE, Decisions pending (undecided items only), THE DEADNESS
  REGISTER. THE LEDGER is at the head of STATE_HISTORY.md. Gate
  `tests/test_state_open_lists.sh`.
- **Commits.** Mid-session: `tests/run_all_static.sh --strict --exec-controls none`
  (~20 min on a quiet Mac) plus `CONTROL=<name>` for each gate the commit adds or
  changes. The close runs every control (~37 min). The readout prints `time: gates
  … controls … wall …` when controls run.

## START HERE — what is open

- **FIRST: BACKFILL THE 114 PRE-EXISTING TICKET ROWS** (maintainer, 2026-09-14).
  `tests/expected/tickets_debt.txt` lists them; each needs its kind, status and the
  four answers as resolving links or `none`. The 74 audit rows (#1-#74) are mostly
  mechanical from `docs/project/audit_2026-08-15_dispositions.md`, whose links their
  `decided` column already carries. The 40 others (#75-#114) need each thread read
  against the tree: a ruling or a learning left only on GitHub is copied into its
  proper local home with its origin and date, and whichever side is behind is
  reconciled. An issue leaves the debt file in the commit that answers its row's
  last `?`.
- **Then #135, the VS-vs-VS2 tick cadence**: the archaeology and the agreed plan are
  in the issue body.
- **Every other open ticket** is on `docs/project/tickets.md` ("Open and parked"):
  #115 Zabel j.LK · #116 capture-matrix widening · #117/#118 community cross-check ·
  #119/#120 living docs · #121/#122 the dedicated Linux server · #123-#128 cosmetic ·
  #129 tenant CPU AI · #130 bundle_win_dlls · #131 audit_mask_window_ff42a2 · #132
  merged-m15 never packaged · #133 pull-queue re-measure · #134 LP whiff at contact.

## TRAPS PAID THIS SITTING

1. **A hand-edited TSV row can lose a tab silently** — write rows with a script that
   asserts the column count; the pass-2 dry run caught #117's.
2. **A tier's wall clock measures the host** — another Claude session's 24 CPU
   burners made a 20-minute run take 51. Read `ps` (parent, working directory) before
   calling a slowdown ours, and never kill what is not ours.
3. **Editing an anchored paragraph stales a generated skill guide**, in bbh as in
   this tree: run `skill-guide --check` after any doc edit.
4. **A citation by rule ID can point at the wrong rule for months** — six carriers
   cite `[VSE-83]`, the attract-demo rule, for the tick cadence; #135 fixes them with
   the fact.
5. **A control that plants its perturbation at END OF FILE depends on the file's
   layout** — the clean-up made THE DEADNESS REGISTER STATE.md's last section, and
   `test_checkskills`' `state-anchor-outside` (which appended its anchor) died: the
   anchor now sat inside an allowed section. The gate's in-gate control run caught
   it in a mid-session tier. Plant where the input is wrong BY CONSTRUCTION.

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
