# NEXT SESSION — orientation (rewritten at the 14z-212 CLOSE, 2026-10-30)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path` (zsh reads `:t` as a modifier; it cost 14z-207 a wrong hash table). An adapting worker that is not `measurer`/`reader` is called `general-purpose` with `model: opus` (the call gate refuses it without a model).
- **The rule-checker runs ONLY BEFORE AN ACTION** (a freeze, a build, an expectation, a recommendation, a ticket closure; `docs/project/rule_checker.md`), **as soon as that action's work is done, never held for the close** (ruled 2026-10-16). The pinned `rule-checker`, the prompt files pasted VERBATIM, then `record --session <the CURRENT transcript's prefix>` and `resolve` on ONE line answering every violated question by its label. Prepare the next run only after the last one is resolved; a reader whose answer runs over six lines is asked to restate it in six (14z-207, run `2026-10-24-1240`).
- **THE GREEN GUARD (#290):** a commit needs a strict GREEN whole-tier row for the staged tree; tier the STAGED tree on a snapshot (`tests/run_on_snapshot.sh --commit "$(git commit-tree "$(git write-tree)" -p HEAD -m …)"`), then commit. Base a `--confirm` on a recent run of record.
- **WHEN TO COMMIT (ruled 2026-10-17):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches IN A CLEAN CHECKOUT of the staged tree (`git worktree add --detach` of a commit-tree object): the main tree holds #229's untracked gates, which break the generators.
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04, disk at 80%, 50 GB free; checked 14z-212 close) carries xdelta3, Node and
`strace`. Its checkout `~/vampire-saved` sits at `e68f8842`. Deletable scratch, 16 GB in 72 entries: 14z-212's
`~/t212*` (bundles, re-trace clones `~/t212_tr*`, `~/t212_trace`, `~/t212r*`) and `~/t336*` (#336's fresh clone), and
14z-211's `~/t334`, `~/p334_knobs.*`, `~/p334_tools.*`. **ERIS** (WSL2, 5% used) runs the release shape; its scratch
`~/e212*` and `~/e333` is deletable. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a
COMMIT (a bare commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s'
< script`.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-212's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Concurrent controls:** a gate on `tests/controls_concurrent_emu.txt` (60 of 61, from a PILOT write trace) runs each
  control as a pool job of its own; a listed gate whose script changed must be re-traced on PILOT before it stays listed
  (`tests/test_controls_concurrent.sh`), and the static list `tests/controls_concurrent.txt` the same.
- **`--order <an earlier run>/results.tsv`** starts a pooled lane longest first.
- **Temp files on disk:** unless the caller set `TMPDIR`, a run's gates write under `build/tmp/emu_<stamp>.<pid>/`
  (removed at the end); the run refuses to start with under 10 GB free there (`VS_TMP_MIN_GB`).
- **Three verdict holes closed:** a control mode stopped by its host (full disk, failed mktemp) is DIED, never HONOURED;
  a selected gate, or a passing gate's declared control, with no row is a FAIL ("LOST"); `tests/lib/measures.sh` no longer
  shares a scratch file across pooled subshells. **Before trusting a runner change, run its gate on PILOT as well as the
  Mac** — the `$$` race showed only on Linux.
- **ERIS's release shape:** `--scope all --strict --controls --jobs 8 --skip test_mame_parity --reuse <freeze run>
  --order <the previous release's results>`, about 2 h 12 min with TMPDIR on disk (7,947 s at `86d1ca10`). `--jobs 12`
  gains nothing.

**THE STATIC TIER:** unchanged since 14z-209 (#312, #315, #324, #304; `tests/lib/static_pool.py`). A strict run fails on a
file it leaves behind outside `build/`, and `build/`'s top-level directories are classed in `tests/expected/build_dirs.tsv`
(a new one fails `test_build_dirs`; `build/tmp/` was added as scratch this sitting).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **THE LEDGER PAGE (#267) AND THE DASHBOARD'S ACTIONS (#335): CHECK THEM LIVE, THEN CLOSE EACH ON ITS RULE-CHECKER RUN.**
   - #267: the close's `ledger-page` push was REFUSED by the pre-push green guard (#290): the page's orphan commit is not
     a repository tree, so no tier covers it. The maintainer: "Fix the guard next session (Recommended)" — the guard
     skips `refs/heads/gh-pages` (or `publish_ledger.sh` pushes in a way the guard knows), with a gate control
     (`tests/test_green_guard.sh`, and `tests/test_ledger_page.sh` pushing through the hook); nothing bypasses #290. Then
     publish (`tools/publish_ledger.sh --push --own-site-if-set`; `DEPLOY_TARGET` was unset), ask the maintainer to
     switch Pages on (Settings → Pages, `gh-pages`; the session account has no admin), and read the live page.
   - **THE WORKING TREE CARRIES UNCOMMITTED RECORDS** written after the 14z-212 push: this ruling's
     `DECISIONS_HISTORY.md` entry, this bullet, STATE 14z-212's CLOSE note, and #338's entry and ticket row. They ride this session's close.
   - #335: this close uploaded `actions.json` to the dashboard (artifact `RVSkG4CZX44wgJaJT2vDag`) as a fifth dataset,
     `datasets/actions`, but the dashboard's page (`index.html` in its store) has no panel reading it yet: add one (the
     first-run OK rate per decision, the questions on first runs), check it renders, then close #335.
2. **Clear PILOT's and ERIS's scratch** (the list above) once nothing cites it.
3. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - medium: none.
   - low: #118, #310 (the UNJUDGED census; deferred, ruled "Record and defer"), #337 (the mktemp census does not check
     EXIT-trap order; split from #333).
   - low, filed after the push: #338 (a web build of the proof sheets for the community; the design ruled 14z-212).
   - evolution, unlabelled: #267, #335 (item 1).
   - parked: #123, #124, #125, #127, #128, #129, #162, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.** #333's
     closing comment names one: the 11 sites guarded after run 1366 have not yet run in a release-shape emulator tier.
4. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A fresh clone's `build/` is not the main tree's** (`docs/project/gotchas.md`): tracked files under build dirs
  (`hui30`, `merged1`) and `emu/jtcores` must be topped up, and a patch's mtime differs, before a clone's gate result
  means anything.
- **A pooled gate that globs its outputs cannot see a lost run** (`docs/project/gotchas.md`): name every leg and fail on a
  missing one; `tests/audit_pool_drop.sh` (ondemand, `harness:`) drops each pool's first run to prove it.
- **A shell's write-error text is its own** (`docs/platform/gotchas.md`, #336): dash says `I/O error`, bash `Broken pipe`.
- **`git ls-files "tools/*.sh"` matches subdirectories** (its `*` matches `/`): an evidence script must list files the
  way the instrument it checks does (#333 found two real sites this way).
- **A new `DECISIONS_HISTORY.md` entry shifts every cited line range by one** once `tools/gen_history_index.py` adds its
  index line: re-cite a packet's ranges after regenerating.
- **The census is a lint over shell text** (`tools/tmp_hygiene.py`; the maintainer: "Fix these + state the limit"); a
  form outside its known answers is untested. EXIT-trap order is checked since 14z-213 (#337: TRAPPED, an EXIT trap set
  before a guarded site that names "$X/...").

## WHAT CLOSED THIS SITTING (14z-212)

- **Closed `done`**, each on its rule-checker run with its closing comment: #330 (run `2026-10-29-1370`), #334
  (`-1378`), #336 (`-1393`), #333 (`2026-10-30-1404`, after 21 earlier runs).
- **Filed:** #336 (found and fixed), #337 (from #333's trap-order limit).
- **Built:** #335 (the ledger's actions) and #267 (the ledger as a public page; the close's new `ledger-page` step).
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-212 entries): #333 "Finish it now", "Fix when back", "Fix all four now", "Fix both
  forms, name (c)", "Fix these + state the limit", "Restate + name", "Guard both, name scope", "Ruling stands, fix record",
  "Stands, use exact wording", "Keep checking, then close", "State it as a limit + ticket"; #334 "Ondemand, new 'harness:'";
  #330 "No whiff", "Yes, it is the whiff", "Yes, it stands"; #335 "Link, else wording", "Every question", "Excluded, shown
  apart"; #267 "Unpark #267 and build it", "gh-pages is fine", "All but your own figures", "Keep both for now", "both is
  good", "At the close", "The close uploads it"; the deploy "Fail or ignore the deploy".
