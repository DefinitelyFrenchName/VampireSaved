# NEXT SESSION — orientation (rewritten at the 14z-180 CLOSE, 2026-09-24)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #171 IS THE WORK, ON THE #172 SETUP

#172 is closed and this sitting ran on it: a plain Fable 5.1 session, every quoted
figure from a `measurer` spec (`docs/project/worker_spec.md`, spawned with NO model),
every recommendation through the pinned `rule-checker` and `rulecheck.py record --session`.
The maintainer asked for confirmation that every further session uses it: say so at the
opener, and route figures through workers from the first measurement, not after (14z-180
ran its opener inline and had to say so).

#171's shape is RULED (`DECISIONS_HISTORY.md` "Ruled 2026-09-24 (14z-180)",
`docs/project/gate_qualification_scope.md` §4-§6): seven slices in the order
**Q0, Q1 (landed), Q3+Q4 (Q5 inside), Q2, Q6.** Q0 is the maintainer's addition and the
foundation of their supervision: every gate carries `# WHAT:` / `# HOW:` / `# EXPECTS:`
(`docs/project/gate_header_contract.md`), rendered from the headers into the GENERATED
`docs/project/gate_coverage.md` (the site page `docs/site/project/gate_coverage.html` after
`python3 tools/mk_docs_site.py`), which the maintainer reviews family by family — a wrong
description is corrected IN THE GATE.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`**, not a `ps` grep.
0b. **CARRIED FROM 14z-180:** its procedure check (run `2026-09-24-146`) stopped at the
   check itself; cut `extract.py --session 63442647 --from 3458` and put the span after it
   — the tier's result, the push — through this close's procedure run beside the session's own
   extract, as 14z-180 did for 14z-179.
1. **Q0 IS WRITTEN — 385 of 385 gates described, census frozen 385/0** (380 at `6e6be0c9`, plus
   the five gates the sitting added; `tests/expected/gate_descriptions.tsv` is the count, this
   line is narrative). The
   maintainer reviews `docs/site/project/gate_coverage.html` (re-render `python3
   tools/mk_docs_site.py`; source `docs/project/gate_coverage.md`) family by family, in
   the ruled order; every correction is a header edit in the gate script, followed by
   `python3 tools/gen_gate_coverage.py` and `tests/test_gate_descriptions.sh` (a reworded
   field needs no re-freeze; only the declares/undeclared sets are frozen). The
   maintainer's corrections come before any new slice.
2. **#171: the seven slices are built (14z-180); what is open is the maintainer's.** Q0 the
   descriptions (385/385, reviewed family by family on `docs/site/project/gate_coverage.html`),
   Q1 the module references, Q2 the MEASURES contract (five gates, six floors, the freeze
   guard), Q3 the FOLLOWS declarations (199, three reconciliation classes), Q4+Q5 the commit
   of record, the staleness gate and `--stale`, Q6 the poke read-back CENSUS. Open, and the
   maintainer's: the 73 UNCLASSIFIED rows of `tests/expected/poke_readback.tsv` (STATE
   "Decisions pending" carries them as one item — rule each OBSERVES or READS-BACK; a
   READS-BACK column is then dropped from its gate's compare or labelled a rig record in
   the header), and any correction to a description or a declaration (a header edit).
   The first emulator run after these commits is the first run of record for the
   staleness gate; `test_release_binaries` has not yet printed its declared measurement in
   a run. #171 closes when the rulings are given and recorded (the four local answers in
   `tickets.tsv`).
3. **#145 Windows binaries**, **no Windows launcher**, **#170**, **#161**, **#169**,
   **#157 / #159 / #163** — unchanged, the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-180)

1. **A worker figure can contradict its own list.** Worker C returned "13" where its C6 list
   had 14 entries and the command prints 14. Re-derive any worker figure that disagrees with
   another of its own before quoting it; keep the wrong one beside the correction.
2. **A control that perturbs the wrong root perturbs nothing and passes.** The census gate's
   `perturb` ran the tool with `--root tests` (the tool appends `/tests`), found no declaring
   gate, printed REFUSED inside a `$(...)` and the modes exited 0. Run every mode and read
   its exit before trusting a CONTROL FIRED line.
3. **A pros-and-cons written ABOVE a question dialog is not seen.** The maintainer: *"I don't
   see the pros and cons anywhere"*. Put the comparison inside the question text.
4. **A stray `*` in generated prose pairs into an `<em>` on the site.** `tests/*.sh` twice in
   a cell broke `test_docs_site`; the renderer now code-spans asterisk-bearing tokens.
5. **Never edit during the tier.** The mid-session tier ran ~35 min; the next family's
   descriptions were drafted under build/ and applied after it.
6. **A reconciliation that checks an extractor against itself agrees by construction.** "0
   uncovered" said nothing about reach until a SECOND witness read the same thing another way
   (the description prose naming the replay). Rule-checker run 142, Q3 — look for the second
   witness before quoting a census as coverage.
7. **A floor taken from a file's line count includes its header lines.** 51 for a 49-row table;
   the gate RUN on MAME printed 49. Take a floor from the gate's own MEASURED line in a real run,
   and derive it once more from a different file.
8. **A known-bad plant reads its poke back BY DESIGN.** A census that joins pokes to samples
   without the leg they sit on lists a control's plant as the measuring leg's finding (run 144).
   Attribute the leg, and say what the attribution rests on.
9. **Run `test_bbh_fidelity` alone.** Beside a MAME gate it read FAIL; alone, PASS (the known
   flake, memory `bbh-fidelity-flake`).
10. **A completion notice is not a result.** "The tier is alive and passing" was said on a
   liveness task's completion alone, its output unread (procedure run 146, QP2). Read the
   output, then say what it showed.
11. **Read a worker's tool calls against its COMMANDS, not only its figures.** Two measurers
   ran `git rev-parse HEAD` outside their spec, one did not STOP on an error, both appended
   a conclusion; the orchestrator's read caught the wrong figure and missed the rest (run
   146, QP5). The extract's WT lines against WS is the read.
12. **`rulecheck.py resolve --how "…"` eats backticks** like any double-quoted shell string:
   run 146's resolution has two holes and cannot be re-resolved. Write the text to a file.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`, `test_docs_site`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
